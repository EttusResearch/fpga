//
// Copyright 2016 Ettus Research
//
// Sine Tone generator
//
`timescale 1ns/1ps

module sine_tone #(
  parameter WIDTH = 32,
  parameter SR_PHASE_INC_ADDR = 129,
  parameter SR_CARTESIAN_ADDR = 130)
(
  input clk, input reset, input clear, input enable,
  input set_stb, input [WIDTH-1:0] set_data, input [7:0] set_addr,
  output [WIDTH-1:0] o_tdata, output o_tlast, output o_tvalid, input o_tready
);

  wire [15:0] phase_in_tdata;
  wire phase_in_tlast;
  wire phase_in_tvalid ;
  wire phase_in_tready;

  wire [15:0] phase_out_tdata;
  wire phase_out_tlast;
  wire phase_out_tvalid;
  wire phase_out_tready;

  wire [WIDTH-1:0] cartesian_tdata;
  wire cartesian_tlast;
  wire cartesian_tvalid;
  wire cartesian_tready;

  wire [WIDTH-1:0] sine_out_tdata;
  wire sine_out_tlast;
  wire sine_out_tvalid;
  wire sine_out_tready;

//AXI settings bus for phase values
  axi_setting_reg #(
    .ADDR(SR_PHASE_INC_ADDR), .AWIDTH(8), .WIDTH(16), .STROBE_LAST(1), .REPEATS(1))
  set_phase_acc (
    .clk(clk), .reset(reset),
    .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
    .o_tdata(phase_in_tdata), .o_tlast(phase_in_tlast), .o_tvalid(phase_in_tvalid), .o_tready(phase_in_tready & enable));

//AXI settings bus for cartestian values
  axi_setting_reg #(
    .ADDR(SR_CARTESIAN_ADDR), .AWIDTH(8), .WIDTH(32), .REPEATS(1))
  set_axis_cartesian (
    .clk(clk), .reset(reset),
    .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
    .o_tdata(cartesian_tdata), .o_tlast(), .o_tvalid(cartesian_tvalid), .o_tready(cartesian_tready & enable));

  assign cartesian_tlast = 1;

//Phase Accumulator
  phase_accum phase_acc (
    .clk(clk), .reset(reset), .clear(clear),
    .i_tdata(phase_in_tdata), .i_tlast(phase_in_tlast), .i_tvalid(1'b1), .i_tready(phase_in_tready),
    .o_tdata(phase_out_tdata), .o_tlast(phase_out_tlast), .o_tvalid(phase_out_tvalid), .o_tready(phase_out_tready & enable));

//Cordic
   cordic_rotator cordic_inst (
    .aclk(clk), .aresetn(~(reset|clear)),
    .s_axis_phase_tdata(phase_out_tdata),
    .s_axis_phase_tvalid(phase_out_tvalid & cartesian_tvalid & enable),
    .s_axis_phase_tready(phase_out_tready),
    .s_axis_cartesian_tdata(cartesian_tdata),
    .s_axis_cartesian_tlast(cartesian_tlast),
    .s_axis_cartesian_tvalid(phase_out_tvalid & cartesian_tvalid & enable),
    .s_axis_cartesian_tready(cartesian_tready),
    .m_axis_dout_tdata(sine_out_tdata),
    .m_axis_dout_tlast(sine_out_tlast),
    .m_axis_dout_tvalid(sine_out_tvalid),
    .m_axis_dout_tready(sine_out_tready & enable));

  assign o_tdata = sine_out_tdata;
  assign o_tlast = sine_out_tlast;
  assign o_tvalid = sine_out_tvalid;
  assign sine_out_tready = o_tready;

endmodule  //sine_tone
