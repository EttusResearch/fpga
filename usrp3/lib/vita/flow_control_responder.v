//
// Copyright 2015 Ettus Research
// Copyright 2018 Ettus Research, a National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// Responds with flow control packets as input packets are consumed.
//
// Parameters:
//   WIDTH                      - Input width / Output width
//   SR_FLOW_CTRL_BYTES_PER_ACK - Settings register address for flow control bytes per ack
//   STR_SINK_FIFOSIZE          - Log2 depth of receive window buffer
//   USE_TIME                   - Append VITA time to outgoing flow control packets
//
// Settings Registers:
//   enable_consumed            - Enable flow control responder
//   bytes_per_ack              - Number of bytes to consume before acking
//
// Debug:
//   error_not_data_pkt         - Input packet was not data type
//   error_inconsistent_sid     - Input packet SRC or DST SID changed
//

module flow_control_responder #(
  parameter WIDTH = 64,
  parameter SR_FLOW_CTRL_BYTES_PER_ACK = 1,
  parameter USE_TIME = 0
)(
  input clk, input reset, input clear,
  input force_fc_pkt,
  input set_stb, input [7:0] set_addr, input [31:0] set_data,
  input [WIDTH-1:0] i_tdata, input i_tlast, input i_tvalid, output i_tready,
  output [WIDTH-1:0] o_tdata, output o_tlast, output o_tvalid, input o_tready,
  output [WIDTH-1:0] fc_tdata, output fc_tlast, output fc_tvalid, input fc_tready
);

  `include "chdr_pkt_types.vh"

  wire enable_consumed;
  wire [30:0] bytes_per_ack;
  setting_reg #(.my_addr(SR_FLOW_CTRL_BYTES_PER_ACK), .at_reset(0)) sr_bytes_per_ack (
    .clk(clk), .rst(reset), .strobe(set_stb), .addr(set_addr),
    .in(set_data), .out({enable_consumed, bytes_per_ack}), .changed());

  wire [WIDTH-1:0] flow_ctrl_tdata;
  wire [127:0] flow_ctrl_tuser;
  wire flow_ctrl_tlast, flow_ctrl_tready;
  reg flow_ctrl_tvalid;

  wire [1:0] pkt_type;
  wire has_time, eob;
  wire [15:0] src_sid;
  wire [15:0] dst_sid;
  wire [63:0] vita_time;
  wire is_fc_ack   = ({pkt_type,eob}  == FC_ACK_PKT);
  wire is_data_pkt = ({pkt_type,1'b0} == DATA_PKT);
  reg is_data_pkt_reg;

  // Extract header fields
  cvita_hdr_decoder cvita_hdr_decoder (
    .header({i_tdata,i_tdata}),
    .pkt_type(pkt_type), .eob(eob), .has_time(has_time),
    .seqnum(), .length(), .payload_length(),
    .src_sid(src_sid), .dst_sid(dst_sid),
    .vita_time(vita_time));

  reg [1:0] state;
  localparam ST_IDLE     = 0;
  localparam ST_TIME     = 1;
  localparam ST_PAYLOAD  = 2;
  localparam ST_DUMP     = 3;

  reg [15:0] pkt_count;
  reg [31:0] byte_count;
  reg [31:0] resp_byte_count;
  reg [15:0] resp_pkt_count;
  reg [15:0] fc_src_sid;
  reg [15:0] fc_dst_sid;
  reg [63:0] fc_vita_time;
  
  wire [31:0] byte_count_since_resp = byte_count - resp_byte_count;

  always @(posedge clk) begin
    if (reset | clear) begin
      resp_byte_count    <= 0;
      resp_pkt_count     <= 0;
      byte_count         <= 0;
      pkt_count          <= 0;
      flow_ctrl_tvalid   <= 1'b0;
      state              <= ST_IDLE;
    end else begin
      // State machine for generating FC RESPs and handling FC ACKs
      case (state)
        ST_IDLE : begin
          if (i_tvalid & i_tready) begin
            is_data_pkt_reg      <= is_data_pkt;
            if (is_fc_ack | is_data_pkt) begin
              fc_src_sid         <= dst_sid;
              fc_dst_sid         <= src_sid;
              byte_count         <= byte_count + WIDTH/8;
              // No payload...
              if (i_tlast) begin
                state            <= ST_IDLE;
              end else if (has_time) begin
                state            <= ST_TIME;
              end else begin
                state            <= ST_PAYLOAD;
              end
            // Not FC ack or a data packet? Should never happen, but dump anyways
            end else begin
              state              <= ST_DUMP;
            end
          end
        end
        ST_TIME : begin
          if (i_tvalid & i_tready) begin
            byte_count           <= byte_count + WIDTH/8;
            // No payload...
            if (i_tlast) begin
              state              <= ST_IDLE;
            end else begin
              state              <= ST_PAYLOAD;
            end
          end
        end
        ST_PAYLOAD : begin
          if (i_tvalid & i_tready) begin
            if (i_tlast) begin
              // Update local byte and packet counters depending on packet type
              if (is_data_pkt_reg) begin
                pkt_count          <= pkt_count + 1;
                byte_count         <= byte_count + WIDTH/8;
              end else begin
                pkt_count          <= i_tdata[47:32];  // Packet count in upper 32 bits
                byte_count         <= i_tdata[31:0];   // Byte count in lower 32 bits
              end
              state                <= ST_IDLE;
            end else begin
              byte_count           <= byte_count + WIDTH/8;
            end
          end
        end
        ST_DUMP : begin
          if (i_tvalid & i_tready & i_tlast) begin
            state <= ST_IDLE;
          end
        end
        default : begin
          state <= ST_IDLE;
        end
      endcase

      // Trigger FC RESP, either forced or due to consuming enough bytes
      if (byte_count_since_resp >= {1'b0,bytes_per_ack} | force_fc_pkt) begin
        flow_ctrl_tvalid  <= enable_consumed;
        resp_byte_count   <= byte_count;
        resp_pkt_count    <= pkt_count;
      end else if (flow_ctrl_tvalid & flow_ctrl_tready) begin
        flow_ctrl_tvalid  <= 1'b0;
      end

    end
  end

  // Dump non-Data packets
  wire dump = (state == ST_IDLE & ~is_data_pkt) | (state != ST_IDLE & ~is_data_pkt_reg);
  assign o_tvalid = dump ? 1'b0 : i_tvalid;
  assign i_tready = dump ? 1'b1 : o_tready;
  assign o_tdata  = i_tdata;
  assign o_tlast  = i_tlast;

  assign flow_ctrl_tdata = {resp_pkt_count, resp_byte_count};
  assign flow_ctrl_tlast = 1'b1;

  cvita_hdr_encoder cvita_hdr_encoder_fc (
    .pkt_type(FC_RESP_PKT[2:1]), .eob(FC_RESP_PKT[0]), .has_time(USE_TIME[0]),
    .seqnum(12'd0),         // Don't care, handled by chdr framer
    .payload_length(16'd0), // Don't care, handled by chdr framer
    .src_sid(fc_src_sid), .dst_sid(fc_dst_sid),
    .vita_time(USE_TIME[0] ? fc_vita_time : 64'd0),
    .header(flow_ctrl_tuser));

  // Create flow control packets
  chdr_framer #(.SIZE(1), .WIDTH(64)) chdr_framer (
    .clk(clk), .reset(reset), .clear(clear),
    .i_tdata(flow_ctrl_tdata), .i_tuser(flow_ctrl_tuser), .i_tlast(flow_ctrl_tlast), .i_tvalid(flow_ctrl_tvalid), .i_tready(flow_ctrl_tready),
    .o_tdata(fc_tdata), .o_tlast(fc_tlast), .o_tvalid(fc_tvalid), .o_tready(fc_tready));

endmodule
