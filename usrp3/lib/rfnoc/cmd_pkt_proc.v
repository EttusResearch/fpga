//
// Copyright 2016 Ettus Research LLC
//

// Command Packet Processor
//  Accepts compressed vita packets of the following form:
//       { VITA Compressed Header, Stream ID }
//       { Optional 64 bit time }
//       { 24'h0, settings bus address [7:0], data [31:0] }
//
//  Sends out setting to setting bus and generates a response packet
//  with the same sequence number, the src/dst stream ID swapped, and the actual time
//  the setting was sent.

module cmd_pkt_proc #(
  parameter AWIDTH = 8,
  parameter DWIDTH = 32,
  parameter NUM_SR_BUSES = 1, // One per block port
  parameter FIFO_SIZE = 5     // Depth of command FIFO
)(
  input clk, input reset, input clear,

  input [63:0] cmd_tdata, input cmd_tlast, input cmd_tvalid, output cmd_tready,
  (* mark_debug = "true", dont_touch = "true" *) output reg [63:0] resp_tdata, (* mark_debug = "true", dont_touch = "true" *) output reg resp_tlast, (* mark_debug = "true", dont_touch = "true" *) output resp_tvalid, (* mark_debug = "true", dont_touch = "true" *) input resp_tready,

  input [63:0] vita_time,

  output [NUM_SR_BUSES-1:0] set_stb, output [AWIDTH-1:0] set_addr, output [DWIDTH-1:0] set_data, output reg [63:0] set_time,
  input ready,

  input [NUM_SR_BUSES*64-1:0] readback
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

  localparam RC_HEAD      = 4'd0;
  localparam RC_TIME      = 4'd1;
  localparam RC_DATA      = 4'd2;
  localparam RC_DUMP      = 4'd3;
  localparam RC_RESP_WAIT = 4'd4;
  localparam RC_RESP_HEAD = 4'd5;
  localparam RC_RESP_TIME = 4'd6;
  localparam RC_RESP_DATA = 4'd7;

  wire IS_CMD_PKT = cmd_fifo_tdata[63:62] == 2'b10;
  wire HAS_TIME   = cmd_fifo_tdata[61];
  reg HAS_TIME_reg;

  (* mark_debug = "true", dont_touch = "true" *) reg [3:0] rc_state;

  reg [11:0] seqnum_reg;
  reg [31:0] sid_reg;
  reg [15:0] src_sid_reg, dst_sid_reg;
  reg [3:0] block_port_reg;
  wire [11:0] seqnum    = cmd_fifo_tdata[59:48];
  wire [31:0] sid       = cmd_fifo_tdata[31:0];
  wire [15:0] src_sid   = sid[31:16];
  wire [15:0] dst_sid   = sid[15:0];
  wire [3:0] block_port = sid[3:0];
  reg [NUM_SR_BUSES-1:0] block_port_stb;
  integer k;

  always @(posedge clk) begin
    if (reset) begin
      rc_state       <= RC_HEAD;
      HAS_TIME_reg   <= 1'b0;
      sid_reg        <= 'd0;
      seqnum_reg     <= 'd0;
      set_time       <= 'd0;
      src_sid_reg    <= 'd0;
      dst_sid_reg    <= 'd0;
      block_port_reg <= 'd0;
      block_port_stb <= 'd0;
    end else begin
      case (rc_state)
        RC_HEAD : begin
          if (cmd_fifo_tvalid) begin
            src_sid_reg <= src_sid;
            dst_sid_reg <= dst_sid;
            block_port_reg <= block_port;
            // Set strobe for addressed block port's settings register bus
            for (k = 0; k < NUM_SR_BUSES; k = k + 1) begin
              if (block_port == k) begin
                block_port_stb[k] <= 1'b1;
              end else begin
                block_port_stb[k] <= 1'b0;
              end
            end
            seqnum_reg <= seqnum;
            HAS_TIME_reg <= HAS_TIME;
            if (IS_CMD_PKT) begin
              if (HAS_TIME) begin
                rc_state <= RC_TIME;
              end else begin
                set_time <= 64'd0;
                rc_state <= RC_DATA;
              end
            end else begin
              if (~cmd_fifo_tlast) begin
                rc_state <= RC_DUMP;
              end
            end
          end
        end

        RC_TIME : begin
          if (cmd_fifo_tvalid) begin
            set_time <= cmd_fifo_tdata;
            if (cmd_fifo_tlast) begin
              rc_state <= RC_RESP_WAIT;
            end else begin
              rc_state <= RC_DATA;
            end
          end
        end

        RC_DATA : begin
          if (cmd_fifo_tvalid) begin
            if (ready) begin
              if (cmd_fifo_tlast) begin
                rc_state <= RC_RESP_WAIT;
              // Long command packet support
              end else begin
                rc_state <= RC_DATA;
              end
            end
          end
        end

        // This should never happen
        RC_DUMP : begin
          if (cmd_fifo_tvalid) begin
            if (cmd_fifo_tlast) begin
              rc_state <= RC_HEAD;
            end
          end
        end

        // Wait a clock cycle to ensure readback
        // has time to propagate
        RC_RESP_WAIT : begin
          rc_state <= RC_RESP_HEAD;
        end

        RC_RESP_HEAD : begin
          if (resp_tready) begin
            rc_state <= RC_RESP_TIME;
          end
        end

        RC_RESP_TIME : begin
          if (resp_tready) begin
            rc_state <= RC_RESP_DATA;
          end
        end

        RC_RESP_DATA : begin
          if (resp_tready) begin
            rc_state <= RC_HEAD;
          end
        end

        default : rc_state <= RC_HEAD;
      endcase // case (rc_state)
    end
  end

  always @* begin
    case (rc_state)
      RC_HEAD : cmd_fifo_tready <= 1'b1;
      RC_TIME : cmd_fifo_tready <= 1'b1;
      RC_DATA : cmd_fifo_tready <= ready;
      RC_DUMP : cmd_fifo_tready <= 1'b1;
      default : cmd_fifo_tready <= 1'b0;
    endcase // case (rc_state)
  end

  reg [63:0] readback_reg;
  wire [63:0] readback_mux[0:NUM_SR_BUSES-1];
  always @(posedge clk) begin
    if (reset | clear) begin
      readback_reg   <= 64'd0;
    end else begin
      if (block_port_reg > NUM_SR_BUSES-1) begin
        readback_reg <= 64'd0;
      end else begin
        readback_reg <= readback_mux[block_port_reg];
      end
    end
  end

  genvar i;
  generate
    for (i = 0; i < NUM_SR_BUSES; i = i + 1) begin
      assign set_stb[i] = (rc_state == RC_DATA) & ready & cmd_fifo_tvalid & block_port_stb[i];
      assign readback_mux[i] = readback[64*i+63:64*i];
    end
  endgenerate

  assign set_addr = cmd_fifo_tdata[AWIDTH-1+32:32];
  assign set_data = cmd_fifo_tdata[DWIDTH-1:0];

  always @* begin
    case (rc_state)
      RC_RESP_HEAD : { resp_tlast, resp_tdata } <= {1'b0, 4'hE, seqnum_reg, 16'd24, dst_sid_reg, src_sid_reg};
      RC_RESP_TIME : { resp_tlast, resp_tdata } <= {1'b0, vita_time};
      RC_RESP_DATA : { resp_tlast, resp_tdata } <= {1'b1, readback_reg};
      default : { resp_tlast, resp_tdata } <= 65'h0;
    endcase
  end

  assign resp_tvalid = (rc_state == RC_RESP_HEAD) | (rc_state == RC_RESP_TIME) | (rc_state == RC_RESP_DATA);

endmodule // radio_ctrl_proc
