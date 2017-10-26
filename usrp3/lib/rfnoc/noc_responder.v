//
// Copyright 2015 Ettus Research
// Copyright 2018 Ettus Research, a National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// Generates flow control and error packets

module noc_responder #(
  parameter SR_FLOW_CTRL_BYTES_PER_ACK = 1,
  parameter SR_ERROR_POLICY = 2,
  parameter USE_TIME = 0
)(
  input clk, input reset, input clear,
  input [31:0] resp_sid,          // Stream ID used with response packets
  input set_stb, input [7:0] set_addr, input [31:0] set_data,
  input [63:0] i_tdata, input i_tlast, input i_tvalid, output i_tready,
  output [63:0] o_tdata, output o_tlast, output o_tvalid, input o_tready,
  output [63:0] fc_tdata, output fc_tlast, output fc_tvalid, input fc_tready,
  output [63:0] resp_tdata, output resp_tlast, output resp_tvalid, input resp_tready
);

  /********************************************************
  ** WARNING: Order is important here! We must reply
  **          with flow control packets first before
  **          potentially dropping the packets due to
  **          an error.
  ********************************************************/
  wire [63:0] int_tdata;
  wire int_tlast, int_tvalid, int_tready;
  wire seqnum_error;
  flow_control_responder #(
    .SR_FLOW_CTRL_BYTES_PER_ACK(SR_FLOW_CTRL_BYTES_PER_ACK),
    .USE_TIME(USE_TIME))
  flow_control_responder (
    .clk(clk), .reset(reset), .clear(clear),
    .force_fc_pkt(seqnum_error),
    .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
    .i_tdata(i_tdata), .i_tlast(i_tlast), .i_tvalid(i_tvalid), .i_tready(i_tready),
    .o_tdata(int_tdata), .o_tlast(int_tlast), .o_tvalid(int_tvalid), .o_tready(int_tready),
    .fc_tdata(fc_tdata), .fc_tlast(fc_tlast), .fc_tvalid(fc_tvalid), .fc_tready(fc_tready));

  packet_error_responder #(
    .SR_ERROR_POLICY(SR_ERROR_POLICY),
    .USE_TIME(USE_TIME))
  packet_error_responder (
    .clk(clk), .reset(reset), .clear(clear),
    .sid(resp_sid),
    .seqnum_error(seqnum_error),
    .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
    .i_tdata(int_tdata), .i_tlast(int_tlast), .i_tvalid(int_tvalid), .i_tready(int_tready),
    .o_tdata(o_tdata), .o_tlast(o_tlast), .o_tvalid(o_tvalid), .o_tready(o_tready),
    .resp_tdata(resp_tdata), .resp_tlast(resp_tlast), .resp_tvalid(resp_tvalid), .resp_tready(resp_tready));

endmodule
