//
// Copyright 2015 Ettus Research
//

module schmidl_cox #(
  parameter [$clog2(64+1)-1:0] WINDOW_LEN=64,
  parameter PREAMBLE_LEN=160,
  parameter SR_FRAME_LEN=0,
  parameter SR_GAP_LEN=1,
  parameter SR_OFFSET=2,
  parameter SR_NUMBER_SYMBOLS_MAX=3,
  parameter SR_NUMBER_SYMBOLS_SHORT=4,
  parameter SR_THRESHOLD=5,
  parameter SR_AGC_REF_LEVEL=6)
(
  input clk, input reset, input clear,
  input set_stb, input [7:0] set_addr, input [31:0] set_data,
  input [31:0] i_tdata, input i_tlast, input i_tvalid, output i_tready,
  output [31:0] o_tdata, output o_tlast, output o_tvalid, input o_tready,
  output sof,  // Start of frame, depends on offset setting, generally set to beginning of second long preamble symbol
  output eof   // End of frame, asserts at the beginning of the last symbol
);

  localparam PRE_DIV_GAIN = 2; // Calibrated value

  wire [31:0] n0_tdata, n1_tdata, n2_tdata, n3_tdata, n4_tdata, n8_tdata;
  wire [31:0] n10_tdata, n11_tdata, n12_tdata, n13_tdata, n14_tdata, n15_tdata;
  wire [31:0] n16_tdata, n17_tdata;
  wire [23:0] n18_tdata;
  wire [63:0] n5_tdata;
  wire [2*(32+$clog2(WINDOW_LEN+1))-1:0] n6_tdata;
  wire [63:0] n7_tdata;
  wire [39:0] n9_tdata;
  wire n0_tlast, n1_tlast, n2_tlast, n3_tlast, n4_tlast, n5_tlast, n6_tlast, n7_tlast, n8_tlast, n9_tlast;
  wire n10_tlast, n11_tlast, n12_tlast, n13_tlast, n14_tlast, n15_tlast, n16_tlast, n17_tlast, n18_tlast;
  wire n0_tvalid, n1_tvalid, n2_tvalid, n3_tvalid, n4_tvalid, n5_tvalid, n6_tvalid, n7_tvalid, n8_tvalid, n9_tvalid;
  wire n10_tvalid, n11_tvalid, n12_tvalid, n13_tvalid, n14_tvalid, n15_tvalid, n16_tvalid, n17_tvalid, n18_tvalid;
  wire n0_tready, n1_tready, n2_tready, n3_tready, n4_tready, n5_tready, n6_tready, n7_tready, n8_tready, n9_tready;
  wire n10_tready, n11_tready, n12_tready, n13_tready, n14_tready, n15_tready, n16_tready, n17_tready, n18_tready;

  split_stream_fifo #(.WIDTH(32), .ACTIVE_MASK(4'b1111), .FIFO_SIZE(8)) split_head (
    .clk(clk), .reset(reset), .clear(clear),
    .i_tdata(i_tdata), .i_tlast(i_tlast), .i_tvalid(i_tvalid), .i_tready(i_tready),
    .o0_tdata(n0_tdata), .o0_tlast(n0_tlast), .o0_tvalid(n0_tvalid), .o0_tready(n0_tready),
    .o1_tdata(n1_tdata), .o1_tlast(n1_tlast), .o1_tvalid(n1_tvalid), .o1_tready(n1_tready),
    .o2_tdata(n11_tdata), .o2_tlast(n11_tlast), .o2_tvalid(n11_tvalid), .o2_tready(n11_tready),
    .o3_tdata(n13_tdata), .o3_tlast(n13_tlast), .o3_tvalid(n13_tvalid), .o3_tready(n13_tready));

  split_stream_fifo #(.WIDTH(32), .ACTIVE_MASK(4'b0011), .FIFO_SIZE(8)) split_head_2 (
    .clk(clk), .reset(reset), .clear(clear),
    .i_tdata(n11_tdata), .i_tlast(n11_tlast), .i_tvalid(n11_tvalid), .i_tready(n11_tready),
    .o0_tdata(n16_tdata), .o0_tlast(n16_tlast), .o0_tvalid(n16_tvalid), .o0_tready(n16_tready),
    .o1_tdata(n17_tdata), .o1_tlast(n17_tlast), .o1_tvalid(n17_tvalid), .o1_tready(n17_tready),
    .o2_tdata(), .o2_tlast(), .o2_tvalid(), .o2_tready(),
    .o3_tdata(), .o3_tlast(), .o3_tvalid(), .o3_tready());

  delay_fifo #(.MAX_LEN(WINDOW_LEN), .WIDTH(32)) delay_input (
    .clk(clk), .reset(reset), .clear(clear),
    .len(WINDOW_LEN),
    .i_tdata(n0_tdata), .i_tlast(n0_tlast), .i_tvalid(n0_tvalid), .i_tready(n0_tready),
    .o_tdata(n2_tdata), .o_tlast(n2_tlast), .o_tvalid(n2_tvalid), .o_tready(n2_tready));

  conj #(.WIDTH(16)) conj (
    .clk(clk), .reset(reset), .clear(clear),
    .i_tdata(n2_tdata), .i_tlast(n2_tlast), .i_tvalid(n2_tvalid), .i_tready(n2_tready),
    .o_tdata(n4_tdata), .o_tlast(n4_tlast), .o_tvalid(n4_tvalid), .o_tready(n4_tready));

  cmul cmult1 (
    .clk(clk), .reset(reset),
    .a_tdata(n1_tdata), .a_tlast(n1_tlast), .a_tvalid(n1_tvalid), .a_tready(n1_tready),
    .b_tdata(n4_tdata), .b_tlast(n4_tlast), .b_tvalid(n4_tvalid), .b_tready(n4_tready),
    .o_tdata(n5_tdata), .o_tlast(n5_tlast), .o_tvalid(n5_tvalid), .o_tready(n5_tready));

  // moving sum of I & Q for S&C metric
  wire [32+$clog2(WINDOW_LEN+1)-1:0] i_ms, q_ms;
  moving_sum #(.MAX_LEN(WINDOW_LEN), .WIDTH(32)) moving_sum_corr_i (
    .clk(clk), .reset(reset), .clear(clear),
    .len(WINDOW_LEN),
    .i_tdata(n5_tdata[63:32]), .i_tlast(n5_tlast), .i_tvalid(n5_tvalid), .i_tready(n5_tready),
    .o_tdata(i_ms), .o_tlast(n6_tlast), .o_tvalid(n6_tvalid), .o_tready(n6_tready));
  moving_sum #(.MAX_LEN(WINDOW_LEN), .WIDTH(32)) moving_sum_corr_q (
    .clk(clk), .reset(reset), .clear(clear),
    .len(WINDOW_LEN),
    .i_tdata(n5_tdata[31:0]), .i_tlast(n5_tlast), .i_tvalid(n5_tvalid), .i_tready(),
    .o_tdata(q_ms), .o_tlast(), .o_tvalid(), .o_tready(n6_tready));

  assign n6_tdata = {i_ms, q_ms};

  wire [63:0] n6_round_tdata;
  wire        n6_round_tlast, n6_round_tvalid, n6_round_tready;
  axi_round_and_clip_complex #(
    .WIDTH_IN(32+$clog2(WINDOW_LEN+1)),
    .WIDTH_OUT(32),
    .CLIP_BITS(PRE_DIV_GAIN+1)) // +1 due to cmult causing a mag reduction by 2
  round_iq (
    .clk(clk), .reset(reset),
    .i_tdata(n6_tdata), .i_tlast(n6_tlast), .i_tvalid(n6_tvalid), .i_tready(n6_tready),
    .o_tdata(n6_round_tdata), .o_tlast(n6_round_tlast), .o_tvalid(n6_round_tvalid), .o_tready(n6_round_tready));

  // Magnitude of delay conjugate multiply
  complex_to_magphase_int32 complex_to_magphase_int32 (.aclk(clk), .aresetn(~reset),
    .s_axis_cartesian_tdata({n6_round_tdata[31:0], n6_round_tdata[63:32]}), // Reverse I/Q input to match Xilinx's format
    .s_axis_cartesian_tlast(n6_round_tlast), .s_axis_cartesian_tvalid(n6_round_tvalid), .s_axis_cartesian_tready(n6_round_tready),
    .m_axis_dout_tdata(n7_tdata), .m_axis_dout_tlast(n7_tlast), .m_axis_dout_tvalid(n7_tvalid), .m_axis_dout_tready(n7_tready));

  // Extract magnitude from cordic
  wire [63:0] n7_mag_tdata, n7_phase_tdata;
  wire [31:0] n7_mag_strip_tdata = n7_mag_tdata[31:0];
  wire [31:0] n7_phase_strip_tdata = n7_phase_tdata[63:32];
  wire n7_mag_tlast, n7_mag_tvalid, n7_mag_tready;
  wire n7_phase_tlast, n7_phase_tvalid, n7_phase_tready;
  split_stream_fifo #(.WIDTH(64), .ACTIVE_MASK(4'b0011), .FIFO_SIZE(8))
  n7_split_mag_phase_fifo (
    .clk(clk), .reset(reset), .clear(clear),
    .i_tdata(n7_tdata), .i_tlast(n7_tlast), .i_tvalid(n7_tvalid), .i_tready(n7_tready),
    .o0_tdata(n7_mag_tdata), .o0_tlast(n7_mag_tlast), .o0_tvalid(n7_mag_tvalid), .o0_tready(n7_mag_tready),
    .o1_tdata(n7_phase_tdata), .o1_tlast(n7_phase_tlast), .o1_tvalid(n7_phase_tvalid), .o1_tready(n7_phase_tready),
    .o2_tready(1'b0), .o3_tready(1'b0));

  wire [15:0] magnitude_approx_tdata;
  wire magnitude_approx_tvalid, magnitude_approx_tready;
  // Complex to mag
  complex_to_mag_approx #(.SAMP_WIDTH(16)) cmag (
    .clk(clk), .reset(reset), .clear(clear),
    .i_tdata(n16_tdata), .i_tlast(1'b0), .i_tvalid(n16_tvalid), .i_tready(n16_tready),
    .o_tdata(magnitude_approx_tdata), .o_tlast(), .o_tvalid(magnitude_approx_tvalid), .o_tready(magnitude_approx_tready));

  wire [22:0] magnitude_sum_tdata;
  wire magnitude_sum_tvalid, magnitude_sum_tready;
  moving_sum #(.MAX_LEN(80), .WIDTH(16)) moving_sum_mag (
    .clk(clk), .reset(reset), .clear(clear),
    .len(80),
    .i_tdata(magnitude_approx_tdata), .i_tlast(1'b0), .i_tvalid(magnitude_approx_tvalid), .i_tready(magnitude_approx_tready),
    .o_tdata(magnitude_sum_tdata), .o_tlast(), .o_tvalid(magnitude_sum_tvalid), .o_tready(magnitude_sum_tready));

  wire [15:0] magnitude_tdata;
  wire magnitude_tvalid, magnitude_tready;
  axi_round #(
    .WIDTH_IN(23),
    .WIDTH_OUT(16))
  round_mag (
    .clk(clk), .reset(reset),
    .i_tdata(magnitude_sum_tdata), .i_tlast(1'b0), .i_tvalid(magnitude_sum_tvalid), .i_tready(magnitude_sum_tready),
    .o_tdata(magnitude_tdata), .o_tlast(), .o_tvalid(magnitude_tvalid), .o_tready(magnitude_tready));

  // magnitude of input signal conjugate multiply
  complex_to_magsq #(.WIDTH(16)) cmag2 (
    .clk(clk), .reset(reset), .clear(clear),
    .i_tdata(n17_tdata), .i_tlast(n17_tlast), .i_tvalid(n17_tvalid), .i_tready(n17_tready),
    .o_tdata(n8_tdata), .o_tlast(n8_tlast), .o_tvalid(n8_tvalid), .o_tready(n8_tready));

  // moving average of magnitude squared
  moving_sum #(.MAX_LEN(2*WINDOW_LEN), .WIDTH(32)) moving_sum_energy (
    .clk(clk), .reset(reset), .clear(clear),
    .len(2*WINDOW_LEN),
    .i_tdata(n8_tdata), .i_tlast(n8_tlast), .i_tvalid(n8_tvalid), .i_tready(n8_tready),
    .o_tdata(n9_tdata), .o_tlast(n9_tlast), .o_tvalid(n9_tvalid), .o_tready(n9_tready));

  wire [31:0] mag_square_tdata;
  wire        mag_square_tlast, mag_square_tvalid, mag_square_tready;
  axi_round_and_clip #(
    .WIDTH_IN(40),
    .WIDTH_OUT(32),
    .CLIP_BITS(PRE_DIV_GAIN-1))
  round_mag_square (
    .clk(clk), .reset(reset),
    .i_tdata(n9_tdata), .i_tlast(n9_tlast), .i_tvalid(n9_tvalid), .i_tready(n9_tready),
    .o_tdata(mag_square_tdata), .o_tlast(mag_square_tlast), .o_tvalid(mag_square_tvalid), .o_tready(mag_square_tready));

  wire[31:0] d_metric_integer, d_metric_fractional;
  wire[62:0] d_metric;
  wire d_metric_tlast, d_metric_tvalid, d_metric_tready, div_by_zero;
  divide_int32 corr_sqr_div_energy_sqr(
    .aclk(clk), .aresetn(~reset),
    .s_axis_divisor_tdata(mag_square_tdata), .s_axis_divisor_tlast(mag_square_tlast), .s_axis_divisor_tvalid(mag_square_tvalid), .s_axis_divisor_tready(mag_square_tready),
    .s_axis_dividend_tdata(n7_mag_strip_tdata), .s_axis_dividend_tlast(n7_mag_tlast), .s_axis_dividend_tvalid(n7_mag_tvalid), .s_axis_dividend_tready(n7_mag_tready),
    .m_axis_dout_tdata({d_metric_integer, d_metric_fractional}), .m_axis_dout_tlast(d_metric_tlast), .m_axis_dout_tvalid(d_metric_tvalid), .m_axis_dout_tready(d_metric_tready),
    .m_axis_dout_tuser(div_by_zero));
  // Set to zero if divide by zero. Also, remove sign bit from fractional part
  assign d_metric = div_by_zero ? 63'd0 : {d_metric_integer, d_metric_fractional[30:0]};

  wire [15:0] d_metric_q1_14_tdata;  // Q1.14 (Sign bit, 1 integer, 14 fractional)
  wire        d_metric_q1_14_tlast, d_metric_q1_14_tvalid, d_metric_q1_14_tready;
  axi_round_and_clip #(
    .WIDTH_IN(63),  // In:  Q31.31
    .WIDTH_OUT(16), // Out: Q1.14
    .CLIP_BITS(30))
  clip_D_metric (
    .clk(clk), .reset(reset),
    .i_tdata(d_metric), .i_tlast(d_metric_tlast), .i_tvalid(d_metric_tvalid), .i_tready(d_metric_tready),
    .o_tdata(d_metric_q1_14_tdata), .o_tlast(d_metric_q1_14_tlast), .o_tvalid(d_metric_q1_14_tvalid), .o_tready(d_metric_q1_14_tready));

  ofdm_plateau_detector #(
    .WIDTH_D(16),
    .WIDTH_PHASE(32),
    .WIDTH_MAG(16),
    .WIDTH_SAMPLE(16),
    .PREAMBLE_LEN(160),
    .SR_THRESHOLD(SR_THRESHOLD),
    .SR_AGC_REF_LEVEL(SR_AGC_REF_LEVEL))
  ofdm_plateau_detector (
    .clk(clk), .reset(reset),
    .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
    .d_metric_tdata(d_metric_q1_14_tdata), .d_metric_tvalid(d_metric_q1_14_tvalid), .d_metric_tready(d_metric_q1_14_tready),
    .phase_in_tdata(n7_phase_strip_tdata), .phase_in_tvalid(n7_phase_tvalid), .phase_in_tready(n7_phase_tready),
    .magnitude_in_tdata(magnitude_tdata), .magnitude_in_tvalid(magnitude_tvalid), .magnitude_in_tready(magnitude_tready),
    .sample_in_tdata(n13_tdata), .sample_in_tvalid(n13_tvalid), .sample_in_tready(n13_tready),
    .sample_out_tdata(n14_tdata), .sample_out_tlast(n14_tlast), .sample_out_tvalid(n14_tvalid), .sample_out_tready(n14_tready),
    .phase_out_tdata(n10_tdata), .phase_out_tlast(n10_tlast), .phase_out_tvalid(n10_tvalid), .phase_out_tready(n10_tready));

  phase_accum #(
    .WIDTH_ACCUM(32), // Divide by WINDOW_LEN to get per sample phase offset
    .WIDTH_IN(32),
    .WIDTH_OUT(24))
  phase_accum (
    .clk(clk), .reset(reset), .clear(),
    .i_tdata(n10_tdata), .i_tlast(n10_tlast), .i_tvalid(n10_tvalid), .i_tready(n10_tready),
    .o_tdata(n18_tdata), .o_tlast(n18_tlast), .o_tvalid(n18_tvalid), .o_tready(n18_tready));

  // Flip I/Q to match Xilinx standard and divide by 2 to compensate for CORDIC gain (prevents clipping internally in Xilinx's CORDIC implementation).
  wire [47:0] n14_scaled_tdata = {n14_tdata[15],n14_tdata[15:0],7'd0,n14_tdata[31],n14_tdata[31:16],7'd0};
  cordic_rotate_int24_int16 cordic_freq_offset_correction (
    .aclk(clk), .aresetn(~reset),
    .s_axis_phase_tdata(n18_tdata), .s_axis_phase_tlast(n18_tlast), .s_axis_phase_tvalid(n18_tvalid), .s_axis_phase_tready(n18_tready),
    .s_axis_cartesian_tdata(n14_scaled_tdata), .s_axis_cartesian_tlast(n14_tlast), .s_axis_cartesian_tvalid(n14_tvalid), .s_axis_cartesian_tready(n14_tready),
    .m_axis_dout_tdata({n15_tdata[15:0],n15_tdata[31:16]}), .m_axis_dout_tlast(n15_tlast), .m_axis_dout_tvalid(n15_tvalid), .m_axis_dout_tready(n15_tready));

  periodic_framer  #(
    .SR_FRAME_LEN(SR_FRAME_LEN),
    .SR_GAP_LEN(SR_GAP_LEN),
    .SR_OFFSET(SR_OFFSET),
    .SR_NUMBER_SYMBOLS_MAX(SR_NUMBER_SYMBOLS_MAX),
    .SR_NUMBER_SYMBOLS_SHORT(SR_NUMBER_SYMBOLS_SHORT),
    .SKIP_GAPS(0),
    .WIDTH(32))
  periodic_framer (
    .clk(clk), .reset(reset), .clear(clear),
    .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
    .stream_i_tdata(n15_tdata), .stream_i_tlast(n15_tlast), .stream_i_tvalid(n15_tvalid), .stream_i_tready(n15_tready),
    .stream_o_tdata(o_tdata), .stream_o_tlast(o_tlast), .stream_o_tvalid(o_tvalid), .stream_o_tready(o_tready),
    .sof(sof), .eof(eof));

endmodule // schmidl_cox
