//
// Copyright 2015 Ettus Research LLC
//
// NoC input port
//  Implements destination flow control and sequence number error handling for a single port

module noc_input_port #(
  parameter SR_FLOW_CTRL_CYCS_PER_ACK = 0,
  parameter SR_FLOW_CTRL_PKTS_PER_ACK = 1,
  parameter SR_ERROR_POLICY = 2,
  parameter STR_SINK_FIFOSIZE = 10)
(
  input clk, input reset, input clear,  // Note: Clear is used to clear the FIFO and flow control
  input [31:0] resp_sid,                // Stream ID used with response packets
  input set_stb, input [7:0] set_addr, input [31:0] set_data,
  // To / From NoC Shell
  input [63:0] i_tdata, input i_tlast, input i_tvalid, output i_tready,
  output [63:0] o_tdata, output o_tlast, output o_tvalid, input o_tready,
  // Flow control and error packets
  output [63:0] fc_tdata, output fc_tlast, output fc_tvalid, input fc_tready
);

  // Receive window / buffer
  wire [63:0] int_tdata;
  wire int_tlast, int_tvalid, int_tready;
  chdr_fifo_large #(.SIZE(STR_SINK_FIFOSIZE)) axi_fifo_receive_window (
    .clk(clk), .reset(reset), .clear(clear),
    .i_tdata(i_tdata), .i_tlast(i_tlast), .i_tvalid(i_tvalid), .i_tready(i_tready),
    .o_tdata(int_tdata), .o_tlast(int_tlast), .o_tvalid(int_tvalid), .o_tready(int_tready));

  // Flow control and error packet handling
  wire [63:0] fc_int_tdata, resp_int_tdata;
  wire fc_int_tlast, fc_int_tvalid, fc_int_tready, resp_int_tlast, resp_int_tvalid, resp_int_tready;
  noc_responder #(
    .SR_FLOW_CTRL_CYCS_PER_ACK(SR_FLOW_CTRL_CYCS_PER_ACK),
    .SR_FLOW_CTRL_PKTS_PER_ACK(SR_FLOW_CTRL_PKTS_PER_ACK),
    .SR_ERROR_POLICY(SR_ERROR_POLICY),
    .USE_TIME(0))
  noc_responder (
    .clk(clk), .reset(reset), .clear(clear),
    .resp_sid(resp_sid),
    .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
    .i_tdata(int_tdata), .i_tlast(int_tlast), .i_tvalid(int_tvalid), .i_tready(int_tready),
    .o_tdata(o_tdata), .o_tlast(o_tlast), .o_tvalid(o_tvalid), .o_tready(o_tready),
    .fc_tdata(fc_int_tdata), .fc_tlast(fc_int_tlast), .fc_tvalid(fc_int_tvalid), .fc_tready(fc_int_tready),
    .resp_tdata(resp_int_tdata), .resp_tlast(resp_int_tlast), .resp_tvalid(resp_int_tvalid), .resp_tready(resp_int_tready));

  axi_mux #(.PRIO(0), .WIDTH(64), .PRE_FIFO_SIZE(0), .POST_FIFO_SIZE(1), .SIZE(2)) axi_mux (
    .clk(clk), .reset(reset), .clear(clear),
    .i_tdata({fc_int_tdata, resp_int_tdata}), .i_tlast({fc_int_tlast, resp_int_tlast}),
    .i_tvalid({fc_int_tvalid, resp_int_tvalid}), .i_tready({fc_int_tready, resp_int_tready}),
    .o_tdata(fc_tdata), .o_tlast(fc_tlast), .o_tvalid(fc_tvalid), .o_tready(fc_tready));

endmodule