//
// Copyright 2014-2016 Ettus Research
// Copyright 2018 Ettus Research, a National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// This block implements credit based flow control using bytes as the
// credits.
// It throttles the input AXI Stream bus until the downstream RFNoC
// block has enough room in its receive window buffer to store the packet.
// If the downstream receive window buffer has enough free space to store
// the input packet, this block will release.
// Tracking the receive window buffer free space is done via flow control
// packets. The downstream block shares its current byte count via
// flow control packets to this block.
//
// This module can also perform flow control using a packet count. Effectively,
// this logic limits the number of packets in flight. In some cases this is
// necessary due to limitations in the transport and can be enabled/disabled as needed.
//
// Limitations:
// - Byte count is only 32 bits. Bit width will need to be increased
//   if receive buffer has a size greater than 2GB (i.e. 2^31).
//
// Parameters:
//   WIDTH                       - Input / Output width in bits
//                                 (must be a power of 2 that is at least 8)
//   SR_FLOW_CTRL_EN             - Settings register address for enabling flow control
//   SR_FLOW_CTRL_WINDOW_SIZE    - Settings register address for window_size
//   SR_FLOW_CTRL_PKT_LIMIT      - Settings register address for pkt_limit
//
// Settings Registers:
//   sfc_enable                 - Enable source flow control
//   window_enable              - Enable byte based flow control
//   pkt_limit_en               - Enable seqnum based flow control
//   window_size                - Size of receive window buffer / FIFO in bytes
//   pkt_limit                  - Maximum number of unack'd packets / packets in flight
//

module source_flow_control #(
  parameter WIDTH = 64,
  parameter SR_FLOW_CTRL_EN           = 0,
  parameter SR_FLOW_CTRL_WINDOW_SIZE  = 1,
  parameter SR_FLOW_CTRL_PKT_LIMIT    = 2
)(
  input clk, input reset, input clear,
  input set_stb, input [7:0] set_addr, input [31:0] set_data,
  input [63:0] fc_tdata, input fc_tlast, input fc_tvalid, output fc_tready,
  input [63:0] in_tdata, input in_tlast, input in_tvalid, output reg in_tready,
  output reg [63:0] out_tdata, output reg out_tlast, output reg out_tvalid, input out_tready,
  output busy,
  output [31:0] debug
);

  `include "chdr_pkt_types.vh"

  wire        window_reset;
  wire        sfc_enable;
  wire        window_enable;
  wire        pkt_limit_enable;
  wire        fc_ack_disable;

  reg  [15:0] last_pkt_consumed;
  reg  [31:0] last_byte_consumed;
  wire [31:0] window_size;

  wire [15:0] pkt_limit;

  // Setting to enable/disable the flow control window
  // When this register is hit, the window will reset.
  // As a part of the reset process, all FC blocked data upstream will be
  // dropped by this module and it will reset to the SFC_HEAD head state.
  // The reset sequence can take more than one cycle during which this
  // module will hold off all flow control data.
  setting_reg #(.my_addr(SR_FLOW_CTRL_EN), .width(4)) sr_enable (
    .clk(clk),.rst(reset),.strobe(set_stb),.addr(set_addr),.in(set_data),
    .out({fc_ack_disable,pkt_limit_enable,window_enable,sfc_enable}),.changed(window_reset));

  // Sets the size of the flow control window
  setting_reg #(.my_addr(SR_FLOW_CTRL_WINDOW_SIZE)) sr_window_size (
    .clk(clk),.rst(reset),.strobe(set_stb),.addr(set_addr),.in(set_data),
    .out(window_size),.changed());

  // Limit number of unack'd packets / packets in flight
  setting_reg #(.my_addr(SR_FLOW_CTRL_PKT_LIMIT), .width(16)) sr_pkt_limit (
    .clk(clk),.rst(reset),.strobe(set_stb),.addr(set_addr),.in(set_data),
    .out(pkt_limit),.changed());

  reg        window_reseting;
  reg [11:0] window_reset_cnt; //Counter to make reset tolerant to bubble cycles

  always @(posedge clk) begin
    if (reset | clear | window_reset) begin // Reset start
      window_reseting  <= 1'b1;
      window_reset_cnt <= 12'd0;
    end else if (window_reseting & ~in_tvalid) begin  // Reset end
      window_reset_cnt <= window_reset_cnt + 12'd1;
      window_reseting  <= (window_reset_cnt == 12'hFFF);
    end
  end

  wire fc_ack_inc, fc_ack_dec;
  reg [5:0] fc_ack_cnt;

  wire [1:0] fc_pkt_type;
  wire fc_eob;
  wire fc_has_time;
  wire [11:0] fc_pkt_seqnum;
  wire [15:0] fc_src_sid, fc_dst_sid;
  wire is_fc_resp_pkt = ({fc_pkt_type,fc_eob} == FC_RESP_PKT);
  cvita_hdr_parser #(.REGISTER(0)) cvita_hdr_parser_fc (
    .clk(clk), .reset(reset), .clear(clear),
    .hdr_stb(),
    .pkt_type(fc_pkt_type), .eob(fc_eob), .has_time(fc_has_time),
    .seqnum(fc_pkt_seqnum), .length(),
    .src_sid(fc_src_sid), .dst_sid(fc_dst_sid),
    .vita_time_stb(), .vita_time(),
    .i_tdata(fc_tdata), .i_tlast(fc_tlast), .i_tvalid(fc_tvalid), .i_tready(),
    .o_tdata(), .o_tlast(), .o_tvalid(), .o_tready(fc_tready));

  reg [1:0] sfc_state;
  localparam SFC_HEAD = 2'd0;
  localparam SFC_TIME = 2'd1;
  localparam SFC_BODY = 2'd2;
  localparam SFC_DUMP = 2'd3;

  reg [15:0] fc_ack_dst_sid, fc_ack_src_sid;
  reg [15:0] fc_resp_dst_sid, fc_resp_src_sid;

  always @(posedge clk) begin
    if (reset | clear | window_reseting) begin
      last_pkt_consumed     <= 0;
      last_byte_consumed    <= 0;
      sfc_state             <= SFC_HEAD;
    end else begin
      case(sfc_state)
        SFC_HEAD : begin
          if (fc_tvalid & fc_tready) begin
            if (fc_tlast) begin
              sfc_state <= SFC_HEAD; // Ignore CHDR packet with only a header.
            end else if (~is_fc_resp_pkt) begin
              sfc_state <= SFC_DUMP; // Drop non-FC packets
            end else begin
              // Hold on to these until the packet is verified
              fc_resp_dst_sid <= fc_dst_sid;
              fc_resp_src_sid <= fc_src_sid;
              if (fc_has_time) begin
                sfc_state <= SFC_TIME;
              end else begin
                sfc_state <= SFC_BODY;
              end
            end
          end
        end

        SFC_TIME : begin
          if (fc_tvalid & fc_tready) begin
            if (fc_tlast) begin
              sfc_state <= SFC_HEAD; // Error, FC response packet with only header and time is an error.
            end else begin
              sfc_state <= SFC_BODY;
            end
          end
        end

        SFC_BODY : begin
          if (fc_tvalid & fc_tready) begin
            if (fc_tlast) begin
              fc_ack_src_sid        <= fc_resp_dst_sid;
              fc_ack_dst_sid        <= fc_resp_src_sid;
              last_pkt_consumed     <= fc_tdata[47:32]; // 16-bit packet count is in upper 32 bits.
              last_byte_consumed    <= fc_tdata[31:0];  // Byte count is in lower 32 bits.
              sfc_state             <= SFC_HEAD;
            end else begin
              sfc_state             <= SFC_DUMP;       // Error. Malformed FC RESP packet?
            end
          end
        end

        SFC_DUMP : begin  // shouldn't ever need to be here, this is an error condition
          if (fc_tvalid & fc_tready & fc_tlast) begin
            sfc_state <= SFC_HEAD;
          end
        end
      endcase // case (sfc_state)
    end
  end

  reg [31:0] window_end, current_byte, window_free_space;
  reg [31:0] pkt_cnt_end, current_pkt_cnt, pkts_free_space;

  always @(posedge clk) begin
    // Calculate end byte / packet of downstream receive window buffer
    window_end        <= last_byte_consumed + window_size;
    pkt_cnt_end       <= last_pkt_consumed + pkt_limit;
    // Calculate downstream receive window buffer free space in both
    // bytes and packets. This works even with wrap around
    window_free_space <= window_end - current_byte;
    pkts_free_space   <= pkt_cnt_end - current_pkt_cnt;
  end

  wire [1:0] pkt_type;
  wire [15:0] pkt_len;
  wire is_data_pkt = (pkt_type == DATA_PKT[2:1]);
  cvita_hdr_parser #(.REGISTER(0)) cvita_hdr_parser_in (
    .clk(clk), .reset(reset), .clear(clear),
    .hdr_stb(),
    .pkt_type(pkt_type), .eob(), .has_time(),
    .seqnum(), .length(pkt_len),
    .src_sid(), .dst_sid(),
    .vita_time_stb(), .vita_time(),
    .i_tdata(in_tdata), .i_tlast(1'b0), .i_tvalid(1'b0), .i_tready(),
    .o_tdata(), .o_tlast(), .o_tvalid(), .o_tready(1'b0));

  reg [2:0] state;
  localparam ST_IDLE           = 0;
  localparam ST_FC_ACK_HEAD    = 1;
  localparam ST_FC_ACK_PAYLOAD = 2;
  localparam ST_DATA_PKT       = 3;
  localparam ST_IGNORE         = 4;

  reg        go;
  reg [31:0] pkt_len_reg;
  reg [11:0] fc_ack_seqnum;

   always @(posedge clk) begin
    if (reset | clear | window_reseting) begin
      go              <= 1'b0;
      current_pkt_cnt <= 0;
      current_byte    <= 0;
      fc_ack_seqnum   <= 0;
      state           <= ST_IDLE;
      pkt_len_reg     <= 0;
    end else begin
      case (state)
        ST_IDLE : begin
          // Round packet length up to nearest word
          pkt_len_reg <=  (pkt_len[15:$clog2(WIDTH/8)] +
                          (|pkt_len[$clog2(WIDTH/8)-1:0]))
                          << $clog2(WIDTH/8);
          if (sfc_enable) begin
            // Received a FC RESP packet, send a FC ACK packet
            if (~fc_ack_disable && fc_ack_cnt != 0) begin
              state         <= ST_FC_ACK_HEAD;
            end else if (in_tvalid) begin
              if (is_data_pkt) begin
                state       <= ST_DATA_PKT;
              end else begin
                state       <= ST_IGNORE;
              end
            end
          end
        end
        // Respond with flow control ack in line
        ST_FC_ACK_HEAD : begin
          // FC ACK packet requires 16 bytes of free space in window buffer
          go <= (~window_enable | (window_free_space >= 16)) & (~pkt_limit_enable | (pkts_free_space >= 1));
          if (out_tvalid & out_tready) begin
            // Header + 8 byte payload
            // Update counters early so they are available for the FC ACK payload
            current_byte    <= current_byte + 16;
            current_pkt_cnt <= current_pkt_cnt + 1;
            state           <= ST_FC_ACK_PAYLOAD;
          end
        end
        ST_FC_ACK_PAYLOAD : begin
          if (out_tvalid & out_tready) begin
            fc_ack_seqnum <= fc_ack_seqnum + 1;
            go            <= 1'b0;
            state         <= ST_IDLE;
          end
        end
        ST_DATA_PKT : begin
          go <= (~window_enable | (window_free_space >= pkt_len_reg)) & (~pkt_limit_enable | (pkts_free_space >= 1));
          if (out_tvalid & out_tready) begin
            if (out_tlast) begin
              go              <= 1'b0;
              current_byte    <= current_byte + pkt_len_reg;
              current_pkt_cnt <= current_pkt_cnt + 1;
              state           <= ST_IDLE;
            end
          end
        end
        // Not a data packet, don't track
        ST_IGNORE : begin
          if (out_tvalid & out_tready & out_tlast) begin
            state    <= ST_IDLE;
          end
        end
      endcase
    end
  end

  assign fc_ack_inc = (sfc_state == SFC_BODY) & fc_tvalid & fc_tready & fc_tlast;
  assign fc_ack_dec = (state == ST_FC_ACK_PAYLOAD) & out_tvalid & out_tready;

  always @(posedge clk) begin
    if (reset | clear | window_reseting) begin
      fc_ack_cnt <= 0;
    end else begin
      if (fc_ack_inc & ~fc_ack_dec & fc_ack_cnt < 63) begin
        fc_ack_cnt <= fc_ack_cnt + 1;
      end else if (~fc_ack_inc & fc_ack_dec) begin
        fc_ack_cnt <= fc_ack_cnt - 1;
      end
    end
  end


  wire [63:0] fc_ack_header;
  wire [63:0] fc_ack_time;
  cvita_hdr_encoder cvita_hdr_encoder_fc_ack (
    .pkt_type(FC_ACK_PKT[2:1]), .eob(FC_ACK_PKT[0]), .has_time(1'b0),
    .seqnum(fc_ack_seqnum),
    .payload_length(16'd8),
    .src_sid(fc_ack_src_sid),
    .dst_sid(fc_ack_dst_sid),
    .vita_time(64'd0),
    .header({fc_ack_header,fc_ack_time}));

  always @(*) begin
    if (window_reseting) begin
      out_tdata  <= in_tdata; // Don't care
      out_tlast  <= in_tlast; // Don't care
      out_tvalid <= 1'b0;
      in_tready  <= 1'b1;
    end else begin
      case (state)
        ST_IDLE : begin
          out_tdata  <= in_tdata;
          out_tlast  <= in_tlast;
          out_tvalid <= 1'b0;
          in_tready  <= 1'b0;
        end
        ST_FC_ACK_HEAD : begin
          out_tdata  <= fc_ack_header;
          out_tlast  <= 1'b0;
          out_tvalid <= go;
          in_tready  <= 1'b0;
        end
        ST_FC_ACK_PAYLOAD : begin
          out_tdata  <= {current_pkt_cnt,current_byte};
          out_tlast  <= 1'b1;
          out_tvalid <= 1'b1;
          in_tready  <= 1'b0;
        end
        ST_DATA_PKT : begin
          out_tdata  <= in_tdata;
          out_tlast  <= in_tlast;
          out_tvalid <= in_tvalid  & go;
          in_tready  <= out_tready & go;
        end
        default : begin  // ST_IGNORE
          out_tdata  <= in_tdata;
          out_tlast  <= in_tlast;
          out_tvalid <= in_tvalid;
          in_tready  <= out_tready;
        end
      endcase
    end
  end

  assign busy      = window_reseting;
  assign fc_tready = 1'b1; // FC RESP is a non-flow controlled path, so always accept packets

  // Debug signals
  reg fc_first_line;
  reg [47:0] fc_recv_cnt;
  reg [63:0] last_fc_header_recv;
  reg [31:0] last_byte_count_recv;
  reg [15:0] last_pkt_count_recv;
  always @(posedge clk) begin
    if (reset | clear | window_reseting) begin
      fc_recv_cnt           <= 48'd0;
      fc_first_line         <= 1'b1;
      last_fc_header_recv   <= 64'd0;
      last_byte_count_recv  <= 32'd0;
      last_pkt_count_recv   <= 16'd0;
    end else begin
      if (fc_tvalid & fc_tready) begin
        if (fc_first_line) begin
          fc_first_line        <= 1'b0;
          last_fc_header_recv  <= fc_tdata;
        end
        if (fc_tlast) begin
          fc_first_line        <= 1'b1;
          fc_recv_cnt          <= fc_recv_cnt + 1;
          last_pkt_count_recv  <= fc_tdata[47:32];
          last_byte_count_recv <= fc_tdata[31:0];
        end
      end
    end
  end

  assign debug     = 32'd0;

endmodule // source_flow_control
