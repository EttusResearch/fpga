//
// Copyright 2018 Ettus Research, A National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// Module: biquad_filter
// Description: 
//   This module implements an second order section (SOS) a.k.a biquad filter
//   implemented using the direct-form I (DF1) structure. Multiple biquads can
//   connected in series to produce higher order filters while maintaining
//   numerical stability.
//
//   Transfer Function:          b0 + b1*z^-1 + b2*z^-2
//                        H(z) = ----------------------
//                                1 - a1*z^-1 - a2*z^-2
//   where:
//   - b0, b1, b2 are the feedforward taps
//   - a1, a2 are the feedback taps
//
// Parameters:
//   - DATA_W: Sample data width (signed, real). Complex doubles the width 
//   - COEFF_W: Width of the alpha (a) taps (signed)
//   - FEEDBACK_W: Number of bits in the feedback delay line (optimal = 25)
//   - ACCUM_HEADROOM: Number of bits of headroom in the feedback accumulator
// Signals:
//   - i_*  : Input sample stream, fixed-point real numbers (AXI-Stream)
//   - o_*  : Output sample stream, fixed-point real numbers (AXI-Stream)
//   - set_*: Static settings
//

module biquad_filter #(
  parameter DATA_W          = 16,
  parameter COEFF_W         = 16,
  parameter FEEDBACK_W      = 25,
  parameter ACCUM_HEADROOM  = 2
)(
  // Clocks and resets
  input  wire                   clk,
  input  wire                   reset,
  // Taps                       
  input  wire [COEFF_W-1:0]     set_b0,
  input  wire [COEFF_W-1:0]     set_b1,
  input  wire [COEFF_W-1:0]     set_b2,
  input  wire [COEFF_W-1:0]     set_a1,
  input  wire [COEFF_W-1:0]     set_a2,
  // Input data
  input  wire [(DATA_W*2)-1:0]  i_tdata,
  input  wire                   i_tlast,
  input  wire                   i_tvalid,
  output wire                   i_tready,
  // Output data
  output wire [(DATA_W*2)-1:0]  o_tdata,
  output wire                   o_tlast,
  output wire                   o_tvalid,
  input  wire                   o_tready
);

  // There are seven registers between the input and output
  // - 1 Input pipeline reg (reg_x0)
  // - 1 Feedforward product (reg_b0x0)
  // - 2 Feedforward sum (reg_ffsum_0 and reg_ffsum_1)
  // - 2 Feedback sum (reg_fbsum_0 and reg_ffsum_1)
  // - 1 Output pileline reg (data_out)
  localparam IN_TO_OUT_LATENCY = 7;

  // Pipeline settings for timing
  reg [COEFF_W-1:0] reg_b0 = 0, reg_b1 = 0, reg_b2 = 0;
  reg [COEFF_W-1:0] reg_a1 = 0, reg_a2 = 0;

  always @(posedge clk) begin
    reg_b0 <= set_b0;
    reg_b1 <= set_b1;
    reg_b2 <= set_b2;
    reg_a1 <= set_a1;
    reg_a2 <= set_a2;
  end

  //-----------------------------------------------------------
  // AXI-Stream wrapper
  //-----------------------------------------------------------
  wire [(DATA_W*2)-1:0]        dsp_data_in, dsp_data_out;
  wire [IN_TO_OUT_LATENCY-1:0] chain_en;

  // We are implementing an N-cycle DSP operation without AXI-Stream handshaking.
  // Use an axis_shift_register and the associated strobes to drive clock enables
  // on the DSP regs to ensure that data/valid/last sync up.
  axis_shift_register #(
    .WIDTH(2*DATA_W), .NSPC(1), .LATENCY(IN_TO_OUT_LATENCY),
    .SIDEBAND_DATAPATH(1), .PIPELINE("OUT")
  ) axis_shreg_i (
    .clk(clk), .reset(reset),
    .s_axis_tdata(i_tdata), .s_axis_tkeep(1'b1), .s_axis_tlast(i_tlast),
    .s_axis_tvalid(i_tvalid), .s_axis_tready(i_tready),
    .m_axis_tdata(o_tdata), .m_axis_tkeep(), .m_axis_tlast(o_tlast),
    .m_axis_tvalid(o_tvalid), .m_axis_tready(o_tready),
    .stage_stb(chain_en), .stage_eop(),
    .m_sideband_data(dsp_data_in), .m_sideband_keep(),
    .s_sideband_data(dsp_data_out)
  );

  //-----------------------------------------------------------
  // DSP datapath
  //-----------------------------------------------------------
  biquad_filter_impl #(
    .DATA_W(DATA_W), .COEFF_W(COEFF_W), .FEEDBACK_W(FEEDBACK_W),
    .FF_HEADROOM(2), .FB_HEADROOM(ACCUM_HEADROOM)
  ) impl_i_inst (
    .clk(clk), .reset(reset), .chain_en(chain_en),
    .set_b0(reg_b0), .set_b1(reg_b1), .set_b2(reg_b2),
    .set_a1(reg_a1), .set_a2(reg_a2),
    .data_in(dsp_data_in[(2*DATA_W)-1:DATA_W]), .data_out(dsp_data_out[(2*DATA_W)-1:DATA_W])
  );

  biquad_filter_impl #(
    .DATA_W(DATA_W), .COEFF_W(COEFF_W), .FEEDBACK_W(FEEDBACK_W),
    .FF_HEADROOM(2), .FB_HEADROOM(ACCUM_HEADROOM)
  ) impl_q_inst (
    .clk(clk), .reset(reset), .chain_en(chain_en),
    .set_b0(reg_b0), .set_b1(reg_b1), .set_b2(reg_b2),
    .set_a1(reg_a1), .set_a2(reg_a2),
    .data_in(dsp_data_in[DATA_W-1:0]), .data_out(dsp_data_out[DATA_W-1:0])
  );

endmodule // biquad_filter


module biquad_filter_impl #(
  parameter DATA_W      = 16,
  parameter COEFF_W     = 16,
  parameter FEEDBACK_W  = 25,
  parameter FF_HEADROOM = 2,
  parameter FB_HEADROOM = 2
)(
  input  wire                      clk,
  input  wire                      reset,
  input  wire        [6:0]         chain_en,
  input  wire signed [COEFF_W-1:0] set_b0,
  input  wire signed [COEFF_W-1:0] set_b1,
  input  wire signed [COEFF_W-1:0] set_b2,
  input  wire signed [COEFF_W-1:0] set_a1,
  input  wire signed [COEFF_W-1:0] set_a2,
  input  wire signed [DATA_W-1:0]  data_in,
  output reg  signed [DATA_W-1:0]  data_out
);

  localparam FF_PROD_W  = DATA_W + COEFF_W - 1;       // Feedforward product width (signed multiply)
  localparam FF_SUM_W   = FF_PROD_W + FF_HEADROOM;    // Feedforward sum width (3 term add)
  localparam FB_PROD_W  = FEEDBACK_W + COEFF_W - 1;   // Feedback product width (signed multiply)
  localparam FB_SUM_W   = FB_PROD_W + FB_HEADROOM;    // Feedback sum width (3 term add) 

  reg  signed [DATA_W-1:0]      reg_x0 = 0, reg_x1 = 0, reg_x2 = 0;
  reg  signed [FF_PROD_W-1:0]   reg_b0x0 = 0, reg_b1x1 = 0, reg_b2x2 = 0, reg_b2x2_del = 0;
  reg  signed [FF_SUM_W-1:0]    reg_ffsum_0 = 0, reg_ffsum_1 = 0;
  wire signed [FB_PROD_W-1:0]   prod_yxa1, prod_yxa2;
  reg  signed [FB_SUM_W-1:0]    reg_fb_sum0 = 0, reg_fb_sum1 = 0;
  wire signed [FEEDBACK_W-1:0]  fb_sum1_trunc;
  wire signed [DATA_W-1:0]      out_rnd;

  always @(posedge clk) begin
    if (reset) begin
      {reg_x2, reg_x1, reg_x0} <= 0;
      reg_b0x0 <= 0;
      reg_b1x1 <= 0;
      reg_b2x2 <= 0;
      reg_b2x2_del <= 0;
      reg_ffsum_0 <= 0;
      reg_ffsum_1 <= 0;
      reg_fb_sum0 <= 0;
      reg_fb_sum1 <= 0;
      data_out <= 0;
    end else begin
      if (chain_en[0]) begin
        // Input pipeline register and delay line
        {reg_x2, reg_x1, reg_x0} <= {reg_x1, reg_x0, data_in};
      end
      if (chain_en[1]) begin
        // Feedforward products
        reg_b0x0 <= reg_x0 * set_b0;
        reg_b1x1 <= reg_x1 * set_b1;
        reg_b2x2 <= reg_x2 * set_b2;
        reg_b2x2_del <= reg_b2x2;
      end
      // Feedforward sums (in two pipelined stages)
      if (chain_en[2]) begin
        reg_ffsum_0 <= reg_b0x0 + reg_b1x1;
      end
      if (chain_en[3]) begin
        reg_ffsum_1 <= reg_ffsum_0 + reg_b2x2_del;
      end
      // Feedback sums (in two pipelined stages)
      if (chain_en[4]) begin
        reg_fb_sum0 <= (reg_ffsum_1 <<< (FB_SUM_W-FF_SUM_W-FB_HEADROOM)) + prod_yxa2;
      end
      if (chain_en[5]) begin
        reg_fb_sum1 <= reg_fb_sum0 + prod_yxa1;
      end
      if (chain_en[6]) begin
        // Output pipeline register
        data_out <= out_rnd;
      end
    end
  end
  // Feedback products
  assign prod_yxa1 = fb_sum1_trunc * set_a1;
  assign prod_yxa2 = fb_sum1_trunc * set_a2;
  // Truncate feedback
  assign fb_sum1_trunc = (reg_fb_sum1 >>> (FB_SUM_W-FEEDBACK_W-FB_HEADROOM));

  round #(
    .bits_in(FB_SUM_W-FB_HEADROOM-FF_HEADROOM), .bits_out(DATA_W)
  ) round_i (
    .in(reg_fb_sum1[FB_SUM_W-FB_HEADROOM-FF_HEADROOM-1:0]), .out(out_rnd), .err()
  );

endmodule // biquad_filter_impl