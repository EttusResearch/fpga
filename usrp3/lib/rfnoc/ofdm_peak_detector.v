//
// Copyright 2015 Ettus Research
//

module ofdm_peak_detector
#(
  parameter WIDTH_D       = 16,
  parameter WIDTH_PHASE   = 32,
  parameter WIDTH_MAG     = 16,  // Not so useful due to fixed divider width
  parameter WIDTH_SAMPLE  = 16,  // sc16
  parameter PREAMBLE_LEN  = 160, // Short preamble length
  parameter AGC_REF_LEVEL = 16'd5000,
  parameter SR_THRESHOLD  = 5)
(
  input clk, input reset,
  input set_stb, input [7:0] set_addr, input [31:0] set_data,
  input [WIDTH_D-1:0] d_metric_tdata, input d_metric_tvalid, output d_metric_tready,
  input [WIDTH_PHASE-1:0] phase_in_tdata, input phase_in_tvalid, output phase_in_tready,
  input [WIDTH_MAG-1:0] magnitude_in_tdata, input magnitude_in_tvalid, output magnitude_in_tready,
  input [2*WIDTH_SAMPLE-1:0] sample_in_tdata, input sample_in_tvalid, output sample_in_tready,
  output [2*WIDTH_SAMPLE-1:0] sample_out_tdata, output  sample_out_tlast, output  sample_out_tvalid, input sample_out_tready,
  output [WIDTH_PHASE-1:0] phase_out_tdata, output phase_out_tlast, output phase_out_tvalid, input phase_out_tready
);

  /****************************************************************************
  ** Settings registers
  ****************************************************************************/
  wire [15:0] threshold; // Q1.14 (Signed bit, 1 integer bit, 14 fractional)
  setting_reg #(.my_addr(SR_THRESHOLD), .width(16)) sr_threshold (
    .clk(clk), .rst(reset), .strobe(set_stb), .addr(set_addr), .in(set_data),
    .out(threshold), .changed());

  /****************************************************************************
  ** Delay & gate sample data
  ****************************************************************************/
  localparam SAMPLE_DELAY = 511;
  wire consume;
  reg trigger;

  wire [2*WIDTH_SAMPLE-1:0] sample_dly_tdata;
  wire sample_dly_tvalid, sample_dly_tready;
  delay_fifo #(.MAX_LEN_LOG2($clog2(SAMPLE_DELAY)), .WIDTH(2*WIDTH_SAMPLE)) delay_samples (
    .clk(clk), .reset(reset), .clear(),
    .len(SAMPLE_DELAY),
    .i_tdata(sample_in_tdata), .i_tlast(1'b0), .i_tvalid(sample_in_tvalid), .i_tready(sample_in_tready),
    .o_tdata(sample_dly_tdata), .o_tlast(), .o_tvalid(sample_dly_tvalid), .o_tready(consume));

  wire [2*WIDTH_SAMPLE-1:0] sample_gate_tdata;
  wire sample_gate_tlast, sample_gate_tvalid, sample_gate_tready;
  axi_fifo_flop #(.WIDTH(2*WIDTH_SAMPLE+1)) axi_fifo_flop_sample_gate (
    .clk(clk), .reset(reset), .clear(),
    .i_tdata({trigger,sample_dly_tdata}), .i_tvalid(consume), .i_tready(sample_dly_tready),
    .o_tdata({sample_gate_tlast, sample_gate_tdata}), .o_tvalid(sample_gate_tvalid), .o_tready(sample_gate_tready),
    .occupied(), .space());

  /****************************************************************************
  ** Gain control
  ****************************************************************************/
  wire [15:0] gain_div_out, gain_frac_div_out;
  wire [30:0] gain_div_out_tdata = {gain_div_out,gain_frac_div_out[14:0]};
  wire gain_div_out_tvalid, gain_div_out_tready;
  divide_int16 divide_gain (
    .aclk(clk), .aresetn(~reset),
    .s_axis_divisor_tdata(AGC_REF_LEVEL), .s_axis_divisor_tlast(1'b0), .s_axis_divisor_tvalid(1'b1), .s_axis_divisor_tready(),
    .s_axis_dividend_tdata(magnitude_in_tdata), .s_axis_dividend_tlast(1'b0), .s_axis_dividend_tvalid(magnitude_in_tvalid), .s_axis_dividend_tready(magnitude_in_tready),
    .m_axis_dout_tdata({gain_div_out, gain_frac_div_out}), .m_axis_dout_tlast(), .m_axis_dout_tvalid(gain_div_out_tvalid), .m_axis_dout_tready(gain_div_out_tready),
    .m_axis_dout_tuser());

  localparam GAIN_NUM_INTEGER_BITS = 8;
  wire [15:0] gain_tdata;
  wire gain_tvalid, gain_tready;
  axi_round_and_clip #(
    .WIDTH_IN(31),
    .WIDTH_OUT(16),
    .CLIP_BITS(GAIN_NUM_INTEGER_BITS))
  round_mag (
    .clk(clk), .reset(reset),
    .i_tdata(gain_div_out_tdata), .i_tlast(1'b0), .i_tvalid(gain_div_out_tvalid), .i_tready(gain_div_out_tready),
    .o_tdata(gain_tdata), .o_tlast(), .o_tvalid(gain_tvalid), .o_tready(gain_tready));

  reg  [15:0] max_gain;
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
    .b_tdata(max_gain), .b_tlast(1'b0), .b_tvalid(1'b1), .b_tready(),
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
    .b_tdata(max_gain), .b_tlast(1'b0), .b_tvalid(1'b1), .b_tready(),
    .p_tdata(sample_agc_tdata[WIDTH_SAMPLE-1:0]), .p_tlast(), .p_tvalid(), .p_tready(sample_agc_tready));

  /****************************************************************************
  ** Use sample out stream to pace phase output stream
  ****************************************************************************/
  split_stream_fifo #(.WIDTH(32), .ACTIVE_MASK(4'b0011), .FIFOSIZE(0)) split_stream_fifo (
    .clk(clk), .reset(reset), .clear(clear),
    .i_tdata(sample_agc_tdata), .i_tlast(sample_agc_tlast), .i_tvalid(sample_agc_tvalid), .i_tready(sample_agc_tready),
    .o0_tdata(sample_out_tdata), .o0_tlast(sample_out_tlast), .o0_tvalid(sample_out_tvalid), .o0_tready(sample_out_tready),
    .o1_tdata(), .o1_tlast(phase_out_tlast), .o1_tvalid(phase_out_tvalid), .o1_tready(phase_out_tready),
    .o2_tdata(), .o2_tlast(), .o2_tvalid(), .o2_tready(),
    .o3_tdata(), .o3_tlast(), .o3_tvalid(), .o3_tready());

  /****************************************************************************
  ** Divide phase by window length
  ****************************************************************************/
  localparam [WIDTH_PHASE-1:0] PHASE_DIV_FACTOR = 2.0**(WIDTH_PHASE-1)*(1.0/(PREAMBLE_LEN/2.0))+0.5;
  reg  [WIDTH_PHASE-1:0] max_phase;
  wire [WIDTH_PHASE-1:0] phase_inc = ~max_phase + 1;
  reg phase_inc_valid;
  multiply #(
    .WIDTH_A(WIDTH_PHASE),
    .WIDTH_B(WIDTH_PHASE),
    .WIDTH_P(WIDTH_PHASE),
    .DROP_TOP_P(1),
    .LATENCY(2),
    .EN_SATURATE(1),
    .EN_ROUND(1))
  divide_window_len (
    .clk(clk), .reset(reset),
    .a_tdata(phase_inc), .a_tlast(1'b0), .a_tvalid(1'b1), .a_tready(),
    .b_tdata(PHASE_DIV_FACTOR), .b_tlast(1'b0), .b_tvalid(1'b1), .b_tready(),
    .p_tdata(phase_out_tdata), .p_tlast(), .p_tvalid(), .p_tready(1'b1));

  /****************************************************************************
  ** Algorithm State Machine
  ****************************************************************************/
  reg [1:0] state;
  localparam S_WAIT_EXCEED_THRESH   = 2'd0;
  localparam S_TRIGGER              = 2'd1;
  localparam S_ALIGN_OUTPUT         = 2'd2;

  reg  [$clog2(SAMPLE_DELAY)-1:0] peak_offset, trigger_cnt;

  reg  [WIDTH_D-1:0] max_d_metric;
  wire [WIDTH_D-1:0] max_d_metric_87_5 = max_d_metric - max_d_metric[WIDTH_D-1:3]; // 87.5%

  assign consume = sample_dly_tready & sample_dly_tvalid & d_metric_tvalid & phase_in_tvalid & gain_tvalid;
  assign d_metric_tready  = consume;
  assign phase_in_tready  = consume;
  assign gain_tready      = consume;

  wire threshold_exceeded = d_metric_tdata > threshold;

  always @(posedge clk) begin
    if (reset) begin
      trigger_cnt     <= 0;
      peak_offset     <= 0;
      max_d_metric    <= 'd0;
      max_phase       <= 'd0;
      max_gain        <= 'd0;
      trigger         <= 1'b0;
      phase_inc_valid <= 1'b0;
      state           <= S_WAIT_EXCEED_THRESH;
    end else begin
      case(state)
        // Wait for threshold to be exceeded
        S_WAIT_EXCEED_THRESH : begin
          trigger_cnt   <= 0;
          peak_offset   <= 0;
          max_d_metric  <= 'd0;
          if (consume) begin
            trigger     <= 1'b0;
            if (threshold_exceeded) begin
              max_d_metric <= d_metric_tdata;
              max_phase    <= phase_in_tdata;
              max_gain     <= gain_tdata;
              state        <= S_TRIGGER;
            end
          end
        end

        S_TRIGGER : begin
          if (consume) begin
            if (d_metric_tdata > max_d_metric) begin
              max_d_metric  <= d_metric_tdata;
              max_phase     <= phase_in_tdata;
              max_gain      <= gain_tdata;
              peak_offset   <= 0;
            end else begin
              peak_offset   <= peak_offset + 1;
            end
            if (d_metric_tdata < max_d_metric_87_5) begin
              phase_inc_valid <= 1'b1;
              state           <= S_ALIGN_OUTPUT;
            // Should never happen, but if it does go back to idle 
            end else if (peak_offset > PREAMBLE_LEN) begin
              state         <= S_WAIT_EXCEED_THRESH;
            end
          end
        end

        S_ALIGN_OUTPUT : begin
          if (consume) begin
            phase_inc_valid <= 1'b0;
            trigger_cnt     <= trigger_cnt + 1;
            if (trigger_cnt > SAMPLE_DELAY-PREAMBLE_LEN-peak_offset-1) begin
              trigger    <= 1'b1;
              state      <= S_WAIT_EXCEED_THRESH;
            end
          end
        end

        default : state <= S_WAIT_EXCEED_THRESH;
      endcase
    end
  end

endmodule