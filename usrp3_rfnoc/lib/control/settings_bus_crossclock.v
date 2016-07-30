//
// Copyright 2011-2016 Ettus Research LLC
//
// This module takes the settings bus on one clock domain and crosses it over to another domain.

module settings_bus_crossclock #(
  parameter FLOW_CTRL=0,
  parameter SR_AWIDTH=8,
  parameter SR_DWIDTH=32,
  parameter RB_AWIDTH=8,
  parameter RB_DWIDTH=64
)(
  input clk_a, input rst_a,
  input set_stb_a, input [SR_AWIDTH-1:0] set_addr_a, input [SR_DWIDTH-1:0] set_data_a,
  output rb_stb_a, input [RB_AWIDTH-1:0] rb_addr_a, output [RB_DWIDTH-1:0] rb_data_a,
  input rb_ready,
  input clk_b, input rst_b,
  output set_stb_b, output [SR_AWIDTH-1:0] set_addr_b, output [SR_DWIDTH-1:0] set_data_b,
  input rb_stb_b, output [RB_AWIDTH-1:0] rb_addr_b, input [RB_DWIDTH-1:0] rb_data_b,
  input set_ready
);

  wire  sr_nfull, sr_nempty;
  wire  rb_nfull, rb_nempty;

  axi_fifo_2clk #(.WIDTH(SR_AWIDTH + SR_DWIDTH + RB_AWIDTH), .SIZE(0)) settings_fifo (
    .reset(rst_a),
    .i_aclk(clk_a), .i_tdata({set_addr_a,set_data_a,rb_addr_a}), .i_tvalid(set_stb_a), .i_tready(sr_nfull),
    .o_aclk(clk_b), .o_tdata({set_addr_b,set_data_b,rb_addr_b}), .o_tready(set_stb_b), .o_tvalid(sr_nempty));

  axi_fifo_2clk #(.WIDTH(RB_DWIDTH), .SIZE(0)) readback_fifo (
    .reset(rst_a),
    .i_aclk(clk_b), .i_tdata(rb_data_b), .i_tvalid(rb_stb_b), .i_tready(rb_nfull),
    .o_aclk(clk_a), .o_tdata(rb_data_a), .o_tready(rb_stb_a), .o_tvalid(rb_nempty));

  assign set_stb_b = sr_nempty & (set_ready | ~FLOW_CTRL);
  assign rb_stb_a  = rb_nempty & (rb_ready | ~FLOW_CTRL);

endmodule // settings_bus_crossclock
