//
// Copyright 2016 Ettus Research
//
// CORDIC that supports timed commands via the settings bus

module cordic_timed #(
  parameter SR_FREQ_ADDR      = 0,
  parameter SR_SCALE_IQ_ADDR  = 1,
  parameter CMD_FIFO_SIZE     = 5,
  parameter WIDTH             = 16,
  parameter CORDIC_WIDTH      = 24,
  parameter PHASE_WIDTH       = 24,
  parameter PHASE_ACCUM_WIDTH = 32,
  parameter SCALING_WIDTH     = 18,
  parameter HEADER_WIDTH      = 128,
  parameter HEADER_FIFO_SIZE  = 5,
  parameter SR_AWIDTH         = 8,
  parameter SR_DWIDTH         = 32,
  parameter SR_TWIDTH         = 64
)(
  input clk, input reset, input clear,
  output timed_cmd_fifo_full,
  input set_stb, input [SR_AWIDTH-1:0] set_addr, input [SR_DWIDTH-1:0] set_data,
  input [SR_TWIDTH-1:0] set_time, input set_has_time,
  input [2*WIDTH-1:0] i_tdata, input i_tlast, input i_tvalid, output i_tready, input [HEADER_WIDTH-1:0] i_tuser,
  output [2*WIDTH-1:0] o_tdata, output o_tlast, output o_tvalid, input o_tready, output [HEADER_WIDTH-1:0] o_tuser
);

  /**************************************************************************
  * Track VITA time
  *************************************************************************/
  wire [2*WIDTH-1:0] int_tdata;
  wire [HEADER_WIDTH-1:0] int_tuser;
  wire int_tlast, int_tvalid, int_tready, int_tag;
  wire [SR_AWIDTH-1:0] out_set_addr, timed_set_addr;
  wire [SR_DWIDTH-1:0] out_set_data, timed_set_data;
  wire out_set_stb, timed_set_stb;

  axi_tag_time #(
    .WIDTH(2*WIDTH),
    .NUM_TAGS(1),
    .SR_TAG_ADDRS(SR_FREQ_ADDR))
  axi_tag_time (
    .clk(clk),
    .reset(reset),
    .clear(clear),
    .tick_rate(16'd1),
    .timed_cmd_fifo_full(timed_cmd_fifo_full),
    .s_axis_data_tdata(i_tdata), .s_axis_data_tlast(i_tlast),
    .s_axis_data_tvalid(i_tvalid), .s_axis_data_tready(i_tready),
    .s_axis_data_tuser(i_tuser),
    .m_axis_data_tdata(int_tdata), .m_axis_data_tlast(int_tlast),
    .m_axis_data_tvalid(int_tvalid), .m_axis_data_tready(int_tready),
    .m_axis_data_tuser(int_tuser), .m_axis_data_tag(int_tag),
    .in_set_stb(set_stb), .in_set_addr(set_addr), .in_set_data(set_data),
    .in_set_time(set_time), .in_set_has_time(set_has_time),
    .out_set_stb(out_set_stb), .out_set_addr(out_set_addr), .out_set_data(out_set_data),
    .timed_set_stb(timed_set_stb), .timed_set_addr(timed_set_addr), .timed_set_data(timed_set_data));

  wire [2*WIDTH-1:0] cordic_in_tdata, unused_tdata;
  wire [HEADER_WIDTH-1:0] header_in_tdata, header_out_tdata, unused_tuser;
  wire cordic_in_tlast, cordic_in_tvalid, cordic_in_tready, cordic_in_tag;
  wire header_in_tvalid, header_in_tready, header_in_tlast, unused_tag;
  wire header_out_tvalid, header_out_tready;

  split_stream #(
    .WIDTH(2*WIDTH+HEADER_WIDTH+1), .ACTIVE_MASK(4'b0011))
  split_head (
    .clk(clk), .reset(reset), .clear(clear),
    .i_tdata({int_tdata,int_tuser,int_tag}), .i_tlast(int_tlast),
    .i_tvalid(int_tvalid), .i_tready(int_tready),
    .o0_tdata({cordic_in_tdata,unused_tuser,cordic_in_tag}), .o0_tlast(cordic_in_tlast),
    .o0_tvalid(cordic_in_tvalid), .o0_tready(cordic_in_tready),
    .o1_tdata({unused_tdata,header_in_tdata,unused_tag}), .o1_tlast(header_in_tlast),
    .o1_tvalid(header_in_tvalid), .o1_tready(header_in_tready),
    .o2_tready(1'b0), .o3_tready(1'b0));

  axi_fifo #(
    .WIDTH(HEADER_WIDTH), .SIZE(HEADER_FIFO_SIZE))
  axi_fifo_header (
    .clk(clk), .reset(reset), .clear(clear),
    .i_tdata(header_in_tdata), .i_tvalid(header_in_tvalid & header_in_tlast), .i_tready(header_in_tready),
    .o_tdata(header_out_tdata), .o_tvalid(header_out_tvalid),
    .o_tready(header_out_tready), // Consume header on last output sample
    .space(), .occupied());

  /**************************************************************************
  * Settings Regs
  *************************************************************************/
  wire [PHASE_ACCUM_WIDTH-1:0] phase_inc_tdata, phase_inc_timed_tdata;
  wire phase_inc_tlast, phase_inc_tvalid, phase_inc_tready;
  wire phase_inc_timed_tlast, phase_inc_timed_tready , phase_inc_timed_tvalid;

  axi_setting_reg #(
    .ADDR(SR_FREQ_ADDR), .AWIDTH(SR_AWIDTH), .WIDTH(PHASE_ACCUM_WIDTH), .STROBE_LAST(1))
  set_freq (
    .clk(clk), .reset(reset),
    .set_stb(out_set_stb), .set_addr(out_set_addr), .set_data(out_set_data),
    .o_tdata(phase_inc_tdata), .o_tlast(phase_inc_tlast), .o_tvalid(phase_inc_tvalid), .o_tready(phase_inc_tready));

  axi_setting_reg #(
    .ADDR(SR_FREQ_ADDR), .USE_FIFO(1), .FIFO_SIZE(CMD_FIFO_SIZE), .AWIDTH(SR_AWIDTH), .WIDTH(PHASE_ACCUM_WIDTH), .STROBE_LAST(1))
  set_freq_timed (
    .clk(clk), .reset(reset),
    .set_stb(timed_set_stb), .set_addr(timed_set_addr), .set_data(timed_set_data),
    .o_tdata(phase_inc_timed_tdata), .o_tlast(phase_inc_timed_tlast), .o_tvalid(phase_inc_timed_tvalid), .o_tready(phase_inc_timed_tready));

  wire [SCALING_WIDTH-1:0] scaling_tdata;
  wire scaling_tvalid, scaling_tready;

  axi_setting_reg #(
    .ADDR(SR_SCALE_IQ_ADDR), .AWIDTH(SR_AWIDTH), .WIDTH(SCALING_WIDTH), .REPEATS(1))
  set_scale (
    .clk(clk), .reset(reset),
    .set_stb(out_set_stb), .set_addr(out_set_addr), .set_data(out_set_data),
    .o_tdata(scaling_tdata), .o_tlast(), .o_tvalid(scaling_tvalid), .o_tready(scaling_tready));

  /**************************************************************************
  * CORDIC + Phase Accumulator
  *************************************************************************/
  wire [PHASE_ACCUM_WIDTH-1:0] phase_inc_mux_tdata;
  wire phase_inc_mux_tlast, phase_inc_mux_tvalid, phase_inc_mux_tready;

  assign phase_inc_mux_tdata    = phase_inc_timed_tready ? phase_inc_timed_tdata : phase_inc_tdata;
  assign phase_inc_mux_tlast    = phase_inc_timed_tready ? phase_inc_timed_tlast : phase_inc_tlast;
  assign phase_inc_mux_tvalid   = cordic_in_tvalid & cordic_in_tready;
  assign phase_inc_tready       = cordic_in_tvalid & cordic_in_tready;
  assign phase_inc_timed_tready = cordic_in_tvalid & cordic_in_tready & cordic_in_tag;

  wire [PHASE_WIDTH-1:0] phase_tdata;
  wire phase_tvalid, phase_tready;

  phase_accum #(
    .REVERSE_ROTATION(1), .WIDTH_ACCUM(PHASE_ACCUM_WIDTH), .WIDTH_IN(PHASE_ACCUM_WIDTH), .WIDTH_OUT(PHASE_WIDTH))
  phase_accum (
    .clk(clk), .reset(reset), .clear(clear),
    .i_tdata(phase_inc_mux_tdata), .i_tlast(phase_inc_mux_tlast), .i_tvalid(phase_inc_mux_tvalid), .i_tready(),
    .o_tdata(phase_tdata), .o_tlast(), .o_tvalid(phase_tvalid), .o_tready(phase_tready));

  wire [PHASE_WIDTH-1:0] phase_sync_tdata;
  wire phase_sync_tvalid, phase_sync_tready;
  wire nc;
  wire [2*WIDTH-1:0] cordic_in_sync_tdata;
  wire cordic_in_sync_tvalid, cordic_in_sync_tready;

  // Sync the two path's pipeline delay.
  // This is needed to ensure that applying the phase update happens on the
  // correct sample regardless of differing downstream path delays.
  axi_sync #(
    .SIZE(2),
    .WIDTH_VEC({PHASE_WIDTH,2*WIDTH}), // Vector of widths, each width is defined by a 32-bit value
    .FIFO_SIZE(2))
  axi_sync (
    .clk(clk), .reset(reset), .clear(clear),
    .i_tdata({phase_tdata,cordic_in_tdata}),
    .i_tlast({1'b0,cordic_in_tlast}),
    .i_tvalid({phase_tvalid,cordic_in_tvalid}),
    .i_tready({phase_tready,cordic_in_tready}),
    .o_tdata({phase_sync_tdata,cordic_in_sync_tdata}),
    .o_tlast({nc,cordic_in_sync_tlast}),
    .o_tvalid({phase_sync_tvalid,cordic_in_sync_tvalid}),
    .o_tready({phase_sync_tready,cordic_in_sync_tready}));

  // Xilinx IP AXI CORDIC
  wire [CORDIC_WIDTH-1:0] cordic_in_i_tdata, cordic_in_q_tdata;
  wire [CORDIC_WIDTH-1:0] cordic_out_i_tdata, cordic_out_q_tdata;
  wire cordic_out_tlast, cordic_out_tvalid, cordic_out_tready;

  sign_extend #(
    .bits_in(WIDTH), .bits_out(CORDIC_WIDTH))
  sign_extend_cordic_i (
    .in(cordic_in_sync_tdata[2*WIDTH-1:WIDTH]), .out(cordic_in_i_tdata));

  sign_extend #(
    .bits_in(WIDTH), .bits_out(CORDIC_WIDTH))
  sign_extend_cordic_q (
    .in(cordic_in_sync_tdata[WIDTH-1:0]), .out(cordic_in_q_tdata));

  cordic_rotator24 cordic_rotator24 (
    .aclk(clk),
    .aresetn(~(reset | clear)),
    /* IQ input */
    .s_axis_cartesian_tlast(cordic_in_sync_tlast),
    .s_axis_cartesian_tvalid(cordic_in_sync_tvalid),
    .s_axis_cartesian_tready(cordic_in_sync_tready),
    .s_axis_cartesian_tdata({cordic_in_i_tdata,cordic_in_q_tdata}),
    /* Phase input from NCO */
    .s_axis_phase_tvalid(phase_sync_tvalid),
    .s_axis_phase_tready(phase_sync_tready),
    .s_axis_phase_tdata(phase_sync_tdata),
    /* IQ output */
    .m_axis_dout_tlast(cordic_out_tlast),
    .m_axis_dout_tvalid(cordic_out_tvalid),
    .m_axis_dout_tready(cordic_out_tready),
    .m_axis_dout_tdata({cordic_out_i_tdata, cordic_out_q_tdata}));

 /**************************************************************************
  * Perform scaling on the IQ output
  *************************************************************************/
  wire [CORDIC_WIDTH+SCALING_WIDTH-1:0] scaled_i_tdata, scaled_q_tdata;
  wire scaled_tlast, scaled_tvalid, scaled_tready;

  mult #(
   .WIDTH_A(CORDIC_WIDTH),
   .WIDTH_B(SCALING_WIDTH),
   .WIDTH_P(CORDIC_WIDTH+SCALING_WIDTH),
   .DROP_TOP_P(4),
   .LATENCY(2),
   .CASCADE_OUT(0))
  i_mult (
    .clk(clk), .reset(reset | clear),
    .a_tdata(cordic_out_i_tdata), .a_tlast(cordic_out_tlast), .a_tvalid(cordic_out_tvalid), .a_tready(cordic_out_tready),
    .b_tdata(scaling_tdata), .b_tlast(1'b0), .b_tvalid(scaling_tvalid), .b_tready(scaling_tready),
    .p_tdata(scaled_i_tdata), .p_tlast(scaled_tlast), .p_tvalid(scaled_tvalid), .p_tready(scaled_tready));

  mult #(
   .WIDTH_A(CORDIC_WIDTH),
   .WIDTH_B(SCALING_WIDTH),
   .WIDTH_P(CORDIC_WIDTH+SCALING_WIDTH),
   .DROP_TOP_P(4),
   .LATENCY(2),
   .CASCADE_OUT(0))
  q_mult (
    .clk(clk), .reset(reset | clear),
    .a_tdata(cordic_out_q_tdata), .a_tlast(), .a_tvalid(cordic_out_tvalid), .a_tready(),
    .b_tdata(scaling_tdata), .b_tlast(1'b0), .b_tvalid(scaling_tvalid), .b_tready(),
    .p_tdata(scaled_q_tdata), .p_tlast(), .p_tvalid(), .p_tready(scaled_tready));

  wire [2*WIDTH-1:0] sample_tdata;
  wire sample_tlast, sample_tvalid, sample_tready;

  axi_round_and_clip_complex #(
    .WIDTH_IN(CORDIC_WIDTH+SCALING_WIDTH), .WIDTH_OUT(WIDTH), .CLIP_BITS(12))
  axi_round_and_clip_complex (
    .clk(clk), .reset(reset | clear),
    .i_tdata({scaled_i_tdata, scaled_q_tdata}), .i_tlast(scaled_tlast), .i_tvalid(scaled_tvalid), .i_tready(scaled_tready),
    .o_tdata(sample_tdata), .o_tlast(sample_tlast), .o_tvalid(sample_tvalid), .o_tready(sample_tready));

  // Throttle output on last sample if header is not valid
  assign header_out_tready = sample_tlast & sample_tvalid & o_tready;
  assign sample_tready     = (sample_tvalid & sample_tlast) ? (header_out_tvalid & o_tready) : o_tready;
  assign o_tvalid          = (sample_tvalid & sample_tlast) ? header_out_tvalid : sample_tvalid;
  assign o_tlast           = sample_tlast;
  assign o_tdata           = sample_tdata;
  assign o_tuser           = header_out_tdata;

endmodule
