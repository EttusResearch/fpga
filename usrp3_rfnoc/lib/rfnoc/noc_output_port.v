//
// Copyright 2014 Ettus Research LLC
//
// NoC Output port.  Implements source flow control on a single stream

module noc_output_port #(
  parameter SR_FLOW_CTRL_WINDOW_SIZE = 0,
  parameter SR_FLOW_CTRL_WINDOW_EN = 1,
  parameter PORT_NUM=0,
  parameter MTU=10,      // includes some extra space due to cascade fifo
  parameter USE_GATE=0   // Gate only necessary if partial packets can get to us.  axi_wrapper and chdr_framer don't need gates.
)(
  input clk, input reset, input clear,
  // Settings bus
  input set_stb, input [7:0] set_addr, input [31:0] set_data,
  // To NoC Shell
  output [63:0] dataout_tdata, output dataout_tlast, output dataout_tvalid, input dataout_tready,
  input [63:0] fcin_tdata, input fcin_tlast, input fcin_tvalid, output fcin_tready,
  // To CE
  input [63:0] str_src_tdata, input str_src_tlast, input str_src_tvalid, output str_src_tready
);

   wire [63:0] str_src_tdata_int;
   wire        str_src_tlast_int, str_src_tvalid_int, str_src_tready_int;

  generate
    if (USE_GATE) begin
      axi_packet_gate #(.WIDTH(64), .SIZE(MTU)) axi_packet_gate (
        .clk(clk), .reset(reset), .clear(clear),
        .i_tdata(str_src_tdata), .i_tlast(str_src_tlast), .i_terror(1'b0), .i_tvalid(str_src_tvalid), .i_tready(str_src_tready),
        .o_tdata(str_src_tdata_int), .o_tlast(str_src_tlast_int), .o_tvalid(str_src_tvalid_int), .o_tready(str_src_tready_int));
    end else begin
      assign str_src_tdata_int = str_src_tdata;
      assign str_src_tlast_int = str_src_tlast;
      assign str_src_tvalid_int = str_src_tvalid;
      assign str_src_tready = str_src_tready_int;
    end
  endgenerate

  source_flow_control #(
    .SR_FLOW_CTRL_WINDOW_SIZE(SR_FLOW_CTRL_WINDOW_SIZE),
    .SR_FLOW_CTRL_WINDOW_EN(SR_FLOW_CTRL_WINDOW_EN))
  source_flow_control (
    .clk(clk), .reset(reset), .clear(clear),
    .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
    .fc_tdata(fcin_tdata), .fc_tlast(fcin_tlast), .fc_tvalid(fcin_tvalid), .fc_tready(fcin_tready),
    .in_tdata(str_src_tdata_int), .in_tlast(str_src_tlast_int), .in_tvalid(str_src_tvalid_int), .in_tready(str_src_tready_int),
    .out_tdata(dataout_tdata), .out_tlast(dataout_tlast), .out_tvalid(dataout_tvalid), .out_tready(dataout_tready),
    .busy(),
    .debug());

endmodule // noc_output_port
