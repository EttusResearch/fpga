//
// Copyright 2015 Ettus Research
//
// Normalizes signal level. Expects complex input.

module agc_feed_forward
#(
  parameter WIDTH_SAMPLE     = 16,
  parameter WIDTH_MAG        = 16, // Not useful at the moment due to fixed divider width
  parameter NUM_INTEGER_BITS = 3,  // Max gain up to 2^NUM_INTEGER_BITS - 1.
  parameter FIXED_REFERENCE  = 0,  // If non-zero, overrides setting register
  parameter SR_REFERENCE     = 0)  // 
(
  input clk, input reset,
  input set_stb, input [7:0] set_addr, input [31:0] set_data,
  input [WIDTH_MAG-1] magnitude_tdata, input magnitude_tvalid, output magnitude_tready,
  input [WIDTH-1:0] i_tdata, input i_tlast, input i_tvalid, output i_tready,
  output [WIDTH-1:0] o_tdata, output  o_tlast, output  o_tvalid, input o_tready
);

  /****************************************************************************
  ** Settings registers
  ****************************************************************************/
  wire [15:0] reference_level_sr; // Q1.14 (Signed bit, 1 integer bit, 14 fractional)
  wire [15:0] reference_level = (FIXED_REFERENCE == 0) ? reference_level_sr : FIXED_REFERENCE;
  setting_reg #(.my_addr(SR_THRESHOLD), .width(16)) sr_threshold (
    .clk(clk), .rst(reset), .strobe(set_stb), .addr(set_addr), .in(set_data),
    .out(reference_level_sr), .changed());

  /****************************************************************************
  ** Gain control
  ****************************************************************************/
  wire [15:0] gain_div_out, gain_frac_div_out;
  wire [30:0] gain_div_out_tdata = {gain_div_out,gain_frac_div_out[14:0]};
  wire gain_div_out_tvalid, gain_div_out_tready;
  divide_int16 divide_gain (
    .aclk(clk), .aresetn(~reset),
    .s_axis_divisor_tdata(reference_level), .s_axis_divisor_tlast(1'b0), .s_axis_divisor_tvalid(1'b1), .s_axis_divisor_tready(),
    .s_axis_dividend_tdata(magnitude_in_tdata), .s_axis_dividend_tlast(1'b0), .s_axis_dividend_tvalid(magnitude_in_tvalid), .s_axis_dividend_tready(magnitude_in_tready),
    .m_axis_dout_tdata({gain_div_out, gain_frac_div_out}), .m_axis_dout_tlast(), .m_axis_dout_tvalid(gain_div_out_tvalid), .m_axis_dout_tready(gain_div_out_tready),
    .m_axis_dout_tuser());

  wire [15:0] gain_round_tdata;
  wire gain_round_tvalid, gain_round_tready;
  axi_round_and_clip #(
    .WIDTH_IN(31),
    .WIDTH_OUT(16),
    .CLIP_BITS(NUM_INTEGER_BITS))
  round_mag (
    .clk(clk), .reset(reset),
    .i_tdata(gain_div_out_tdata), .i_tlast(1'b0), .i_tvalid(gain_div_out_tvalid), .i_tready(gain_div_out_tready),
    .o_tdata(gain_round_tdata), .o_tlast(), .o_tvalid(gain_round_tvalid), .o_tready(gain_round_tready));

  wire [15:0] gain_tdata;
  wire gain_tvalid, gain_tready;
  axi_repeat #(.WIDTH(WIDTH_MAG)) axi_repeat (
    .clk(clk), .reset(reset), .clear(),
    .i_tdata(gain_round_tdata), .i_tvalid(gain_round_tvalid), .i_tready(gain_round_tready),
    .o_tdata(gain_tdata), .o_tvalid(gain_tvalid), .o_tready(gain_tready),
    .occupied(), .space());

  reg  [15:0] max_gain;
  wire [2*WIDTH_SAMPLE-1:0] sample_agc_tdata;
  wire sample_agc_tlast, sample_agc_tvalid, sample_agc_tready;
  multiply #(
    .WIDTH_A(WIDTH_SAMPLE),
    .WIDTH_B(WIDTH_SAMPLE),
    .WIDTH_P(WIDTH_SAMPLE),
    .DROP_TOP_P(NUM_INTEGER_BITS),
    .LATENCY(2),
    .EN_SATURATE(1),
    .EN_ROUND(1))
  multiply_agc_i (
    .clk(clk), .reset(reset),
    .a_tdata(i_tdata[2*WIDTH_SAMPLE-1:WIDTH_SAMPLE]), .a_tlast(i_tlast), .a_tvalid(i_tvalid), .a_tready(i_tready),
    .b_tdata(gain_tdata), .b_tlast(1'b0), .b_tvalid(gain_tvalid), .b_tready(gain_tready),
    .p_tdata(o_tdata[2*WIDTH_SAMPLE-1:WIDTH_SAMPLE]), .p_tlast(o_tlast), .p_tvalid(o_tvalid), .p_tready(o_tready));

  multiply #(
    .WIDTH_A(WIDTH_SAMPLE),
    .WIDTH_B(WIDTH_SAMPLE),
    .WIDTH_P(WIDTH_SAMPLE),
    .DROP_TOP_P(NUM_INTEGER_BITS),
    .LATENCY(2),
    .EN_SATURATE(1),
    .EN_ROUND(1))
  multiply_agc_q (
    .clk(clk), .reset(reset),
    .a_tdata(i_tdata[WIDTH_SAMPLE-1:0]), .a_tlast(1'b0), .a_tvalid(i_tvalid), .a_tready(),
    .b_tdata(gain_tdata), .b_tlast(1'b0), .b_tvalid(gain_tvalid), .b_tready(),
    .p_tdata(o_tdata[WIDTH_SAMPLE-1:0]), .p_tlast(), .p_tvalid(), .p_tready(o_tready));

endmodule
