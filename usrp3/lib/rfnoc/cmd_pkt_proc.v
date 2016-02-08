//
// Copyright 2016 Ettus Research LLC
//

// Command Packet Processor
//   Accepts 64-bit AXI stream with compressed VITA (CVITA) command packet data:
//     0: Header
//     1: Optional 64 bit VITA time
//     2: { 24'h0, settings bus address [7:0], data [31:0] }   Note: Address / data width are parameterized
//     Note: If long command packet (i.e. more than one settings bus transaction in payload),
//           additional settings bus transactions can follow.
//
// Generates a response packet with the same sequence number, the src/dst stream ID swapped,
// (optional) the actual time the setting was sent, and readback data as the payload.
//
// TODO: Should long command packets have one readback per settings bus transaction?
//       Should the response be a 'long' reponse packet or one packet per transaction?

module cmd_pkt_proc #(
  parameter SR_AWIDTH = 8,
  parameter SR_DWIDTH = 32,
  parameter RB_AWIDTH = 8,
  parameter RB_USER_AWIDTH = 8,
  parameter RB_DWIDTH = 64,
  parameter USE_TIME = 1,
  parameter NUM_SR_BUSES = 1,       // One per block port
  // TODO: Eliminate extra readback address output once NoC Shell / user register readback address spaces are merged
  parameter SR_RB_ADDR = 0,         // Settings bus address to set NoC Shell readback address register
  parameter SR_RB_ADDR_USER = 1,    // Settings bus address to set user readback address register
  parameter FIFO_SIZE = 5           // Depth of command FIFO
)(
  input clk, input reset, input clear,
  input [63:0] cmd_tdata, input cmd_tlast, input cmd_tvalid, output cmd_tready,
  output reg [63:0] resp_tdata, output reg resp_tlast, output reg resp_tvalid, input resp_tready,
  input [63:0] vita_time,
  output reg [NUM_SR_BUSES-1:0] set_stb, output reg [SR_AWIDTH-1:0] set_addr, output reg [SR_DWIDTH-1:0] set_data, output reg [63:0] set_time,
  input [NUM_SR_BUSES-1:0] rb_stb, input [NUM_SR_BUSES*RB_DWIDTH-1:0] rb_data,
  output reg [NUM_SR_BUSES*RB_AWIDTH-1:0] rb_addr, output reg [NUM_SR_BUSES*RB_USER_AWIDTH-1:0] rb_addr_user
);

  // Input FIFO
  wire [63:0] cmd_fifo_tdata;
  wire cmd_fifo_tlast, cmd_fifo_tvalid;
  reg cmd_fifo_tready;
  axi_fifo #(.WIDTH(65), .SIZE(FIFO_SIZE)) axi_fifo (
    .clk(clk), .reset(reset), .clear(clear),
    .i_tdata({cmd_tlast,cmd_tdata}), .i_tvalid(cmd_tvalid), .i_tready(cmd_tready),
    .o_tdata({cmd_fifo_tlast,cmd_fifo_tdata}), .o_tvalid(cmd_fifo_tvalid), .o_tready(cmd_fifo_tready),
    .space(), .occupied());

  localparam S_CMD_HEAD         = 4'd0;
  localparam S_CMD_TIME         = 4'd1;
  localparam S_CMD_DATA         = 4'd2;
  localparam S_SET_RB_ADDR      = 4'd3;
  localparam S_SET_RB_ADDR_USER = 4'd4;
  localparam S_SET_WAIT         = 4'd5;
  localparam S_READBACK         = 4'd6;
  localparam S_RESP_HEAD        = 4'd7;
  localparam S_RESP_TIME        = 4'd8;
  localparam S_RESP_DATA        = 4'd9;
  localparam S_DROP             = 4'd10;

  wire is_cmd_pkt  = cmd_fifo_tdata[63:62] == 2'b10;
  wire has_time    = cmd_fifo_tdata[61];
  reg has_time_reg, is_long_cmd_pkt;

  wire set_rb_addr      = cmd_fifo_tdata[SR_AWIDTH-1+32:32] == SR_RB_ADDR[SR_AWIDTH-1:0];
  wire set_rb_addr_user = cmd_fifo_tdata[SR_AWIDTH-1+32:32] == SR_RB_ADDR_USER[SR_AWIDTH-1:0];

  (* mark_debug = "true", dont_touch = "true" *) reg [3:0] rc_state;

  reg [11:0] seqnum_reg;
  reg [15:0] src_sid_reg, dst_sid_reg;
  reg [3:0] block_port_reg;
  wire [11:0] seqnum    = cmd_fifo_tdata[59:48];
  wire [31:0] sid       = cmd_fifo_tdata[31:0];
  wire [15:0] src_sid   = sid[31:16];
  wire [15:0] dst_sid   = sid[15:0];
  wire [3:0] block_port = sid[3:0];

  wire [63:0] resp_header = {4'hE, seqnum_reg, 16'd24, dst_sid_reg, src_sid_reg};

  reg [NUM_SR_BUSES-1:0] set_stb_hold;
  reg rb_stb_reg;
  reg [63:0] rb_data_reg, rb_data_hold;
  integer k;

  // Vectorize readback data
  wire [63:0] rb_data_vec[0:NUM_SR_BUSES-1];
  genvar i;
  generate
    for (i = 0; i < NUM_SR_BUSES; i = i + 1) begin
      assign rb_data_vec[i] = rb_data[64*i+63:64*i];
    end
  endgenerate

  // State machine
  always @(posedge clk) begin
    if (reset) begin
      state           <= S_CMD_HEAD;
      has_time_reg    <= 1'b0;
      seqnum_reg      <= 'd0;
      src_sid_reg     <= 'd0;
      dst_sid_reg     <= 'd0;
      block_port_reg  <= 'd0;
      cmd_fifo_tready <= 1'b0;
      resp_tvalid     <= 1'b0;
      resp_tlast      <= 1'b0;
      resp_tdata      <= 'd0;
      set_stb         <= 'd0;
      set_stb_hold    <= 'd0;
      set_data        <= 'd0;
      set_addr        <= 'd0;
      set_time        <= 'd0;
      rb_addr         <= 'd0;
      rb_addr_user    <= 'd0;
      rb_data_reg     <= 'd0;
      rb_data_hold    <= 'd0;
      rb_stb_reg      <= 1'b0;
      is_long_cmd_pkt <= 1'b0;
    end else begin
      case (state)
        S_CMD_HEAD : begin
          cmd_fifo_tready <= 1'b1;
          resp_tvalid     <= 1'b0;
          resp_tlast      <= 1'b0;
          set_stb         <= 'd0;
          if (cmd_fifo_tvalid & cmd_fifo_tready) begin
            src_sid_reg     <= src_sid;
            dst_sid_reg     <= dst_sid;
            block_port_reg  <= block_port;
            // Set strobe for addressed block port's settings register bus
            for (k = 0; k < NUM_SR_BUSES; k = k + 1) begin
              if (block_port == k) begin
                set_stb_hold[k] <= 1'b1;
              end else begin
                set_stb_hold[k] <= 1'b0;
              end
            end
            seqnum_reg   <= seqnum;
            has_time_reg <= has_time;
            // Packet must be of correct type and for an existing block port
            if (is_cmd_pkt & (block_port < NUM_SR_BUSES)) begin
              if (has_time) begin
                state <= S_CMD_TIME;
              end else begin
                set_time <= 64'd0;
                state <= S_CMD_DATA;
              end
            end else begin
              // Drop all non-command packets.
              if (~cmd_fifo_tlast) begin
                state <= S_DROP;
              end
            end
          end
        end

        S_CMD_TIME : begin
          if (cmd_fifo_tvalid & cmd_fifo_tready) begin
            set_time <= cmd_fifo_tdata;
            if (cmd_fifo_tlast) begin
              // Command packet with time but missing command? Drop it.
              cmd_fifo_tready <= 1'b0;
              state           <= S_DROP;
            end else begin
              cmd_fifo_tready <= 1'b1;
              state           <= S_CMD_DATA;
            end
          end
        end

        S_CMD_DATA : begin
          if (cmd_fifo_tvalid & cmd_fifo_tready) begin
            is_long_cmd_pkt <= ~cmd_fifo_tlast;
            set_addr        <= cmd_fifo_tdata[SR_AWIDTH-1+32:32];
            set_data        <= cmd_fifo_tdata[SR_DWIDTH-1:0];
            // If setting the readback address, need to delay set_stb so
            // the updated readback address and set_stb output together.
            if (set_rb_addr) begin
              cmd_fifo_tready <= 1'b0;
              state           <= S_SET_RB_ADDR;
            end else if (set_rb_addr_user) begin
              cmd_fifo_tready <= 1'b0;
              state           <= S_SET_RB_ADDR_USER;
            // Regular settings register write
            end else begin
              set_stb           <= set_stb_hold;
              if (cmd_fifo_tlast) begin
                cmd_fifo_tready <= 1'b0;
                state           <= S_SET_WAIT;
              // Long command packet support
              end else begin
                cmd_fifo_tready <= 1'b1;
                state           <= S_CMD_DATA;
              end
            end
          end
        end

        S_SET_RB_ADDR : begin
          rb_addr[RB_AWIDTH*block_port_reg +: RB_AWIDTH] <= set_data[RB_AWIDTH-1:0];
          set_stb <= set_stb_hold;
          if (is_long_cmd_pkt) begin
            cmd_fifo_tready <= 1'b1;
            state           <= S_CMD_DATA;
          end else begin
            state           <= S_SET_WAIT;
          end
        end

        // TODO: Remove this once NoC Shell / user register address spaces are merged
        S_SET_RB_ADDR_USER : begin
          rb_addr_user[RB_USER_AWIDTH*block_port_reg +: RB_USER_AWIDTH] <= set_data[RB_USER_AWIDTH-1:0];
          set_stb <= set_stb_hold;
          if (is_long_cmd_pkt) begin
            cmd_fifo_tready <= 1'b1;
            state           <= S_CMD_DATA;
          end else begin
            state           <= S_SET_WAIT;
          end
        end

        // Wait a clock cycle to allow settings register to output
        S_SET_WAIT : begin
          set_stb <= 1'b0;
          state   <= S_READBACK;
        end

        // Wait for readback data
        S_READBACK : begin
          set_stb <= 1'b0;
          if (rb_stb[block_port_reg]) begin
            rb_data_hold <= rb_data_vec[block_port_reg];
            resp_tlast   <= 1'b0;
            resp_tdata   <= resp_header;
            resp_tvalid  <= 1'b1;
            state        <= S_RESP_HEAD;
          end
        end

        S_RESP_HEAD : begin
          if (resp_tvalid & resp_tready) begin
            resp_tvalid <= 1'b1;
            if (USE_TIME) begin
              resp_tlast <= 1'b0;
              resp_tdata <= vita_time;
              state      <= S_RESP_TIME;
            end else begin
              resp_tlast <= 1'b1;
              resp_tdata <= rb_data_hold;
              state      <= S_RESP_DATA;
            end
          end
        end

        S_RESP_TIME : begin
          if (resp_tvalid & resp_tready) begin
            resp_tlast  <= 1'b1;
            resp_tdata  <= rb_data_hold;
            resp_tvalid <= 1'b1;
            state       <= S_RESP_DATA;
          end
        end

        S_RESP_DATA : begin
          if (resp_tvalid & resp_tready) begin
            resp_tlast  <= 1'b0;
            resp_tvalid <= 1'b0;
            state       <= S_CMD_HEAD;
          end
        end

        // Drop malformed / non-command packets
        S_DROP : begin
          if (cmd_fifo_tvalid & cmd_fifo_tready) begin
            if (cmd_fifo_tlast) begin
              cmd_fifo_tready <= 1'b0;
              state           <= S_CMD_HEAD;
            end
          end
        end

        default : state <= S_CMD_HEAD;
      endcase
    end
  end

endmodule
