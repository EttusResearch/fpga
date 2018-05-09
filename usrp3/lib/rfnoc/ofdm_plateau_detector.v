//
// Copyright 2015 Ettus Research
//
// Specifically designed to work with 802.11 short preamble & long preamble.
//
// Algorithm: 1) Correlate plateaus from both short & long preamble and wait until threshold is exceeded
//               - Correlating the plateaus creates one peak. This helps avoid false detects due to noise 
//                 spikes and prevents a false detect on one of the two plateaus
//            2) Once the threshold is exceeded, find max of averaged D metric and then use 87.5% of max value
//               to indicate that the peak has passed
//            3) Align sample data to peak (with max metric value's index) and release.
//               - Output is aligned to the start of the short preamble
//               - tlast used as the trigger to indicate the NEXT sample is the detected start
//                 of the short preamble
//            4) Apply gain correction to sample data based on magnitude at max metric value
//            5) Begin looking for another peak

module ofdm_plateau_detector
#(
  parameter WIDTH_D          = 16,
  parameter WIDTH_PHASE      = 32,
  parameter WIDTH_MAG        = 16,  // Not so useful due to fixed divider width
  parameter WIDTH_SAMPLE     = 16,  // sc16
  parameter PREAMBLE_LEN     = 160, // Short length
  parameter PLATEAU_WIDTH    = 32,  // Expected plateau width
  parameter AGC_REF_LEVEL    = 16'd4000,
  parameter SR_THRESHOLD     = 5,
  parameter SR_AGC_REF_LEVEL = 6)
(
  input clk, input reset,
  input set_stb, input [7:0] set_addr, input [31:0] set_data,
  input [WIDTH_D-1:0] d_metric_tdata, input d_metric_tvalid, output d_metric_tready,
  input [WIDTH_PHASE-1:0] phase_in_tdata, input phase_in_tvalid, output phase_in_tready,
  input [WIDTH_MAG-1:0] magnitude_in_tdata, input magnitude_in_tvalid, output magnitude_in_tready,
  input [2*WIDTH_SAMPLE-1:0] sample_in_tdata, input sample_in_tvalid, output sample_in_tready,
  output [2*WIDTH_SAMPLE-1:0] sample_out_tdata, output sample_out_tlast, output sample_out_tvalid, input sample_out_tready,
  output [WIDTH_PHASE-1:0] phase_out_tdata, output phase_out_tlast, output phase_out_tvalid, input phase_out_tready
);

  /****************************************************************************
  ** Settings registers
  ****************************************************************************/
  wire [15:0] threshold; // Q1.14 (Signed bit, 1 integer bit, 14 fractional)
  setting_reg #(.my_addr(SR_THRESHOLD), .width(16)) sr_threshold (
    .clk(clk), .rst(reset), .strobe(set_stb), .addr(set_addr), .in(set_data),
    .out(threshold), .changed());

  wire [15:0] agc_reference_level;
  setting_reg #(.my_addr(SR_AGC_REF_LEVEL), .width(16), .at_reset(AGC_REF_LEVEL)) sr_agc_ref_level (
    .clk(clk), .rst(reset), .strobe(set_stb), .addr(set_addr), .in(set_data),
    .out(agc_reference_level), .changed());

  /****************************************************************************
  ** Average phase and magnitude across plateau
  ****************************************************************************/
  wire [WIDTH_PHASE-1:0] phase_in_fifo_tdata;
  wire phase_in_fifo_tvalid, phase_in_fifo_tready;
  axi_fifo #(.WIDTH(WIDTH_PHASE), .SIZE(8)) axi_fifo_short_phase_in (
    .clk(clk), .reset(reset), .clear(),
    .i_tdata(phase_in_tdata), .i_tvalid(phase_in_tvalid), .i_tready(phase_in_tready),
    .o_tdata(phase_in_fifo_tdata), .o_tvalid(phase_in_fifo_tvalid), .o_tready(phase_in_fifo_tready),
    .occupied(), .space());

  // Moving average of phase
  wire [$clog2(PLATEAU_WIDTH)+WIDTH_PHASE-1:0] phase_in_sum_tdata;
  wire phase_in_sum_tvalid, phase_in_sum_tready;
  moving_sum #(.MAX_LEN(PLATEAU_WIDTH), .WIDTH(WIDTH_PHASE)) moving_sum_phase (
    .clk(clk), .reset(reset), .clear(clear),
    .len(PLATEAU_WIDTH),
    .i_tdata(phase_in_fifo_tdata), .i_tlast(1'b0), .i_tvalid(phase_in_fifo_tvalid), .i_tready(phase_in_fifo_tready),
    .o_tdata(phase_in_sum_tdata), .o_tlast(), .o_tvalid(phase_in_sum_tvalid), .o_tready(phase_in_sum_tready));

  wire [WIDTH_PHASE-1:0] phase_in_round_tdata;
  wire phase_in_round_tvalid, phase_in_round_tready;
  axi_round #(
    .WIDTH_IN($clog2(PLATEAU_WIDTH)+WIDTH_PHASE),
    .WIDTH_OUT(WIDTH_PHASE))
  round_phase (
    .clk(clk), .reset(reset),
    .i_tdata(phase_in_sum_tdata), .i_tlast(1'b0), .i_tvalid(phase_in_sum_tvalid), .i_tready(phase_in_sum_tready),
    .o_tdata(phase_in_round_tdata), .o_tlast(), .o_tvalid(phase_in_round_tvalid), .o_tready(phase_in_round_tready));

  wire [WIDTH_MAG-1:0] magnitude_in_fifo_tdata;
  wire magnitude_in_fifo_tvalid, magnitude_in_fifo_tready;
  axi_fifo #(.WIDTH(WIDTH_MAG), .SIZE(8)) axi_fifo_short_magnitude_in (
    .clk(clk), .reset(reset), .clear(),
    .i_tdata(magnitude_in_tdata), .i_tvalid(magnitude_in_tvalid), .i_tready(magnitude_in_tready),
    .o_tdata(magnitude_in_fifo_tdata), .o_tvalid(magnitude_in_fifo_tvalid), .o_tready(magnitude_in_fifo_tready),
    .occupied(), .space());

  wire [15:0] gain_div_out, gain_frac_div_out;
  wire [30:0] gain_tdata = {gain_div_out,gain_frac_div_out[14:0]};
  wire gain_tvalid, gain_tready;
  divide_int16 divide_gain (
    .aclk(clk), .aresetn(~reset),
    .s_axis_divisor_tdata(magnitude_in_fifo_tdata), .s_axis_divisor_tlast(1'b0), .s_axis_divisor_tvalid(magnitude_in_fifo_tvalid), .s_axis_divisor_tready(magnitude_in_fifo_tready),
    .s_axis_dividend_tdata(agc_reference_level), .s_axis_dividend_tlast(1'b0), .s_axis_dividend_tvalid(1'b1), .s_axis_dividend_tready(),
    .m_axis_dout_tdata({gain_div_out, gain_frac_div_out}), .m_axis_dout_tlast(), .m_axis_dout_tvalid(gain_tvalid), .m_axis_dout_tready(gain_tready),
    .m_axis_dout_tuser());

  // Moving average of gain
  wire [$clog2(PLATEAU_WIDTH)+30:0] gain_sum_tdata;
  wire gain_sum_tvalid, gain_sum_tready;
  moving_sum #(.MAX_LEN(PLATEAU_WIDTH), .WIDTH(31)) moving_sum_gain (
    .clk(clk), .reset(reset), .clear(clear),
    .len(PLATEAU_WIDTH),
    .i_tdata(gain_tdata), .i_tlast(1'b0), .i_tvalid(gain_tvalid), .i_tready(gain_tready),
    .o_tdata(gain_sum_tdata), .o_tlast(), .o_tvalid(gain_sum_tvalid), .o_tready(gain_sum_tready));

  localparam GAIN_NUM_INTEGER_BITS = 8;
  wire [15:0] gain_round_tdata;
  wire        gain_round_tvalid, gain_round_tready;
  axi_round_and_clip #(
    .WIDTH_IN($clog2(PLATEAU_WIDTH)+31),
    .WIDTH_OUT(16),
    .CLIP_BITS(GAIN_NUM_INTEGER_BITS))
  round_gain (
    .clk(clk), .reset(reset),
    .i_tdata(gain_sum_tdata), .i_tlast(1'b0), .i_tvalid(gain_sum_tvalid), .i_tready(gain_sum_tready),
    .o_tdata(gain_round_tdata), .o_tlast(), .o_tvalid(gain_round_tvalid), .o_tready(gain_round_tready));

  /****************************************************************************
  ** Delay & gate sample data
  ****************************************************************************/
  localparam SAMPLE_DELAY = 511;
  wire consume;
  reg trigger;

  wire [2*WIDTH_SAMPLE-1:0] sample_dly_tdata;
  wire sample_dly_tvalid, sample_dly_tready;
  delay_fifo #(.MAX_LEN(SAMPLE_DELAY), .WIDTH(2*WIDTH_SAMPLE)) delay_samples (
    .clk(clk), .reset(reset), .clear(),
    .len(SAMPLE_DELAY),
    .i_tdata(sample_in_tdata), .i_tlast(1'b0), .i_tvalid(sample_in_tvalid), .i_tready(sample_in_tready),
    .o_tdata(sample_dly_tdata), .o_tlast(), .o_tvalid(sample_dly_tvalid), .o_tready(consume));

  wire [2*WIDTH_SAMPLE-1:0] sample_gate_tdata;
  wire sample_gate_tlast, sample_gate_tvalid, sample_gate_tready;
  axi_fifo #(.WIDTH(2*WIDTH_SAMPLE+1), .SIZE(8)) axi_fifo_short_sample_gate (
    .clk(clk), .reset(reset), .clear(),
    .i_tdata({trigger,sample_dly_tdata}), .i_tvalid(consume), .i_tready(sample_dly_tready),
    .o_tdata({sample_gate_tlast, sample_gate_tdata}), .o_tvalid(sample_gate_tvalid), .o_tready(sample_gate_tready),
    .occupied(), .space());

  /****************************************************************************
  ** AGC
  ****************************************************************************/
  reg  [15:0] max_gain, max_gain_hold;
  wire [2*WIDTH_SAMPLE-1:0] sample_agc_tdata;
  wire sample_agc_tlast, sample_agc_tvalid, sample_agc_tready;
  multiply #(
    .WIDTH_A(WIDTH_SAMPLE),
    .WIDTH_B(WIDTH_SAMPLE),
    .WIDTH_P(WIDTH_SAMPLE),
    .DROP_TOP_P(GAIN_NUM_INTEGER_BITS),
    .LATENCY(2),
    .EN_SATURATE(1),
    .EN_ROUND(1))
  multiply_agc_i (
    .clk(clk), .reset(reset),
    .a_tdata(sample_gate_tdata[2*WIDTH_SAMPLE-1:WIDTH_SAMPLE]), .a_tlast(sample_gate_tlast), .a_tvalid(sample_gate_tvalid), .a_tready(sample_gate_tready),
    .b_tdata(max_gain_hold), .b_tlast(1'b0), .b_tvalid(1'b1), .b_tready(),
    .p_tdata(sample_agc_tdata[2*WIDTH_SAMPLE-1:WIDTH_SAMPLE]), .p_tlast(sample_agc_tlast), .p_tvalid(sample_agc_tvalid), .p_tready(sample_agc_tready));

  multiply #(
    .WIDTH_A(WIDTH_SAMPLE),
    .WIDTH_B(WIDTH_SAMPLE),
    .WIDTH_P(WIDTH_SAMPLE),
    .DROP_TOP_P(GAIN_NUM_INTEGER_BITS),
    .LATENCY(2),
    .EN_SATURATE(1),
    .EN_ROUND(1))
  multiply_agc_q (
    .clk(clk), .reset(reset),
    .a_tdata(sample_gate_tdata[WIDTH_SAMPLE-1:0]), .a_tlast(sample_gate_tlast), .a_tvalid(sample_gate_tvalid), .a_tready(),
    .b_tdata(max_gain_hold), .b_tlast(1'b0), .b_tvalid(1'b1), .b_tready(),
    .p_tdata(sample_agc_tdata[WIDTH_SAMPLE-1:0]), .p_tlast(), .p_tvalid(), .p_tready(sample_agc_tready));

  /****************************************************************************
  ** Use sample out stream to pace phase output stream
  ****************************************************************************/
  split_stream_fifo #(.WIDTH(32), .ACTIVE_MASK(4'b0011), .FIFO_SIZE(8)) split_stream_fifo (
    .clk(clk), .reset(reset), .clear(clear),
    .i_tdata(sample_agc_tdata), .i_tlast(sample_agc_tlast), .i_tvalid(sample_agc_tvalid), .i_tready(sample_agc_tready),
    .o0_tdata(sample_out_tdata), .o0_tlast(sample_out_tlast), .o0_tvalid(sample_out_tvalid), .o0_tready(sample_out_tready),
    .o1_tdata(), .o1_tlast(phase_out_tlast), .o1_tvalid(phase_out_tvalid), .o1_tready(phase_out_tready),
    .o2_tdata(), .o2_tlast(), .o2_tvalid(), .o2_tready(),
    .o3_tdata(), .o3_tlast(), .o3_tvalid(), .o3_tready());

  reg [WIDTH_PHASE-1:0] max_phase, max_phase_hold;
  assign phase_out_tdata = ~max_phase_hold + 1;

  /****************************************************************************
  ** Average Plateaus
  ****************************************************************************/
  wire [WIDTH_D-1:0] d_metric_fifo_tdata;
  wire d_metric_fifo_tvalid, d_metric_fifo_tready;
  axi_fifo #(.WIDTH(WIDTH_D), .SIZE(8)) axi_fifo_short_d_metric (
    .clk(clk), .reset(reset), .clear(),
    .i_tdata(d_metric_tdata), .i_tvalid(d_metric_tvalid), .i_tready(d_metric_tready),
    .o_tdata(d_metric_fifo_tdata), .o_tvalid(d_metric_fifo_tvalid), .o_tready(d_metric_fifo_tready),
    .occupied(), .space());

  // d metric moving average
  wire [WIDTH_D+$clog2(PLATEAU_WIDTH)-1:0] d_metric_sum;
  wire [WIDTH_D-1:0] d_metric_avg_tdata = d_metric_sum[20:$clog2(PLATEAU_WIDTH)]; // Truncate to average
  wire d_metric_avg_tvalid, d_metric_avg_tready;
  moving_sum #(.MAX_LEN(PLATEAU_WIDTH), .WIDTH(16)) moving_sum_d_metric (
    .clk(clk), .reset(reset), .clear(),
    .len(PLATEAU_WIDTH),
    .i_tdata(d_metric_fifo_tdata), .i_tlast(1'b0), .i_tvalid(d_metric_fifo_tvalid), .i_tready(d_metric_fifo_tready),
    .o_tdata(d_metric_sum), .o_tlast(), .o_tvalid(d_metric_avg_tvalid), .o_tready(d_metric_avg_tready));

  wire threshold_exceeded = d_metric_avg_tdata > threshold;

  /****************************************************************************
  ** Algorithm State Machine
  ****************************************************************************/
  reg [2:0] state;
  localparam S_WAIT_EXCEED_THRESH   = 3'd0;
  localparam S_FIND_FIRST_PEAK      = 3'd1;
  localparam S_WAIT_EXCEED_THRESH2  = 3'd2;
  localparam S_FIND_SECOND_PEAK     = 3'd3;
  localparam S_ALIGN_OUTPUT         = 3'd4;
  localparam S_WAIT_BELOW_THRESH    = 3'd5;

  reg  [$clog2(SAMPLE_DELAY)-1:0] peak_offset, trigger_cnt;

  reg  [WIDTH_D-1:0] max_d_metric;
  wire [WIDTH_D-1:0] max_d_metric_87_5 = max_d_metric - max_d_metric[WIDTH_D-1:3]; // 87.5%

  assign consume = sample_dly_tready & sample_dly_tvalid & d_metric_avg_tvalid & phase_in_round_tvalid & gain_round_tvalid;
  assign d_metric_avg_tready      = consume;
  assign phase_in_round_tready    = consume;
  assign gain_round_tready        = consume;

  always @(posedge clk) begin
    if (reset) begin
      trigger_cnt   <= 0;
      peak_offset   <= 0;
      max_d_metric  <= 'd0;
      max_phase     <= 'd0;
      max_gain      <= 'd0;
      max_phase_hold <= 'd0;
      max_gain_hold  <= 'd0;
      trigger       <= 1'b0;
      state         <= S_WAIT_EXCEED_THRESH;
    end else begin
      if (consume) begin
        case(state)
          // Wait for threshold to be exceeded
          S_WAIT_EXCEED_THRESH : begin
            trigger_cnt   <= 0;
            peak_offset   <= 0;
            max_d_metric  <= 'd0;
            trigger       <= 1'b0;
            if (threshold_exceeded) begin
              max_d_metric <= d_metric_avg_tdata;
              max_phase    <= phase_in_round_tdata >> 6;
              max_gain     <= gain_round_tdata;
              state        <= S_FIND_FIRST_PEAK;
            end
          end

          S_FIND_FIRST_PEAK : begin
            if (d_metric_avg_tdata > max_d_metric) begin
              max_d_metric  <= d_metric_avg_tdata;
              max_phase     <= phase_in_round_tdata >> 6;
              max_gain      <= gain_round_tdata;
              peak_offset   <= 0;
            end else begin
              peak_offset   <= peak_offset + 1;
            end
            if (d_metric_avg_tdata < max_d_metric_87_5) begin
              max_d_metric   <= 'd0;
              state          <= S_WAIT_EXCEED_THRESH2;
            // Avoid triggering on tones
            end else if (peak_offset > PREAMBLE_LEN/2) begin
              state         <= S_WAIT_BELOW_THRESH;
            end
          end

          S_WAIT_EXCEED_THRESH2 : begin
            peak_offset   <= peak_offset + 1;
            if (threshold_exceeded) begin
              max_d_metric <= d_metric_avg_tdata;
              state        <= S_FIND_SECOND_PEAK;
            end
            if (peak_offset > PREAMBLE_LEN) begin
              state         <= S_WAIT_BELOW_THRESH;
            end
          end

          S_FIND_SECOND_PEAK : begin
            if (d_metric_avg_tdata > max_d_metric) begin
              max_d_metric  <= d_metric_avg_tdata;
            end
            peak_offset   <= peak_offset + 1;
            if (d_metric_avg_tdata < max_d_metric_87_5) begin
              state         <= S_ALIGN_OUTPUT;
            // Avoid triggering on tones
            end else if (peak_offset > 2*PREAMBLE_LEN) begin
              state         <= S_WAIT_BELOW_THRESH;
            end
          end

          S_ALIGN_OUTPUT : begin
            trigger_cnt  <= trigger_cnt + 1;
            // Extra -3 to account for off by one for trigger_cnt, peak_offset, etc
            if (trigger_cnt > SAMPLE_DELAY-PREAMBLE_LEN-peak_offset-4) begin
              max_phase_hold <= max_phase;
              max_gain_hold  <= max_gain;
              trigger    <= 1'b1;
              state      <= S_WAIT_BELOW_THRESH;
            end
          end

          S_WAIT_BELOW_THRESH : begin
            trigger <= 1'b0;
            if (~threshold_exceeded) begin
              state <= S_WAIT_EXCEED_THRESH;
            end
          end

          default : state <= S_WAIT_EXCEED_THRESH;
        endcase
      end
    end
  end

endmodule