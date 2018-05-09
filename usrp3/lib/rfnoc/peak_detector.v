//
// Copyright 2015 Ettus Research
//
// Algorithm: 1) Wait until threshold is exceeded
//            2) Record maximum value and start an peak offset counter
//            3) Wait until input falls below some percent of peak value. See OFF_PEAK_THRESHOLD
//            4) Since the input signal is delayed, output trigger as tlast on o_tdata on the peak
//               using the peak offset counter and PEAK_TRIGGER_OFFSET
//
// Note: May need to adjust INPUT_DELAY depending on how quickly the peak can be found
//       (i.e. slowly falling signals require more delay) and PEAK_TRIGGER_OFFSET setting.

module peak_detector
#(
  parameter WIDTH               = 16,
  parameter OFF_PEAK_THRESHOLD  = 3,   // 1 - 2^(-OFF_PEAK_THRESHOLD) -- <1: Invalid, 1: 50%, 2: 75%, 3: 87.5%, etc.
  parameter INPUT_DELAY         = 255, // Delay input signal to allow us to set tlast on the output at the peak
  parameter PEAK_TRIGGER_OFFSET = 0,   // Adjust peak trigger by a fixed offset before (positive value) or after (negative value) peak
  parameter FIXED_THRESHOLD     = 0,   // If non-zero, overrides settings register threshold
  parameter SR_THRESHOLD        = 5)   // Settings register address
(
  input clk, input reset,
  input set_stb, input [7:0] set_addr, input [31:0] set_data,
  input [WIDTH-1:0] i_tdata, input i_tlast, input i_tvalid, output i_tready,
  output [WIDTH-1:0] o_tdata, output  o_tlast, output  o_tvalid, input o_tready
);

  /****************************************************************************
  ** Settings registers
  ****************************************************************************/
  wire [15:0] threshold_sr;
  setting_reg #(.my_addr(SR_THRESHOLD), .width(16)) sr_threshold
     (.clk(clk), .rst(reset), .strobe(set_stb), .addr(set_addr), .in(set_data),
      .out(threshold_sr), .changed());

  /****************************************************************************
  ** Delay and gate input data
  ****************************************************************************/
  wire consume;
  reg trigger;

  wire [WIDTH-1:0] i_dly_tdata;
  wire i_dly_tvalid, i_dly_tready;
  delay_fifo #(.MAX_LEN_LOG2($clog2(INPUT_DELAY)), .WIDTH(WIDTH)) delay_samples (
    .clk(clk), .reset(reset), .clear(),
    .len(INPUT_DELAY),
    .i_tdata(i_tdata), .i_tlast(1'b0), .i_tvalid(i_tvalid), .i_tready(i_tready),
    .o_tdata(i_dly_tdata), .o_tlast(), .o_tvalid(i_dly_tvalid), .o_tready(consume));

  axi_fifo_flop #(.WIDTH(WIDTH+1)) axi_fifo_flop_sample_gate (
    .clk(clk), .reset(reset), .clear(),
    .i_tdata({trigger,i_dly_tdata}), .i_tvalid(i_dly_tvalid), .i_tready(i_dly_tready),
    .o_tdata({o_tlast, o_tdata}), .o_tvalid(o_tvalid), .o_tready(o_tready),
    .occupied(), .space());

  /****************************************************************************
  ** State Machine
  ****************************************************************************/
  reg [1:0] state;
  localparam S_WAIT_EXCEED_THRESH   = 2'd0;
  localparam S_TRIGGER              = 2'd1;
  localparam S_ALIGN_OUTPUT         = 2'd2;

  reg  [$clog2(INPUT_DELAY)-1:0] peak_offset, trigger_cnt;

  reg  [WIDTH-1:0] peak_val;
  wire [WIDTH-1:0] off_peak = i_tdata < (peak_val - peak_val[WIDTH-1:OFF_PEAK_THRESHOLD]);

  wire [15:0] threshold = (FIXED_THRESHOLD == 0) ? threshold_sr : FIXED_THRESHOLD;
  wire threshold_exceeded = i_tdata > threshold;

  always @(posedge clk) begin
    if (reset) begin
      trigger_cnt  <= 1;
      peak_offset  <= 1;
      peak_val     <= 'd0;
      trigger      <= 1'b0;
      state        <= S_WAIT_EXCEED_THRESH;
    end else begin
      if (i_tvalid & i_tready) begin
        case(state)
          // Wait for threshold to be exceeded
          S_WAIT_EXCEED_THRESH : begin
            trigger_cnt  <= 1;
            peak_offset  <= 1;
            peak_val     <= 'd0;
            trigger      <= 1'b0;
            if (threshold_exceeded) begin
              state      <= S_TRIGGER;
            end
          end

          S_TRIGGER : begin
            if (i_tdata > peak_val) begin
              peak_val     <= i_tdata;
              peak_offset  <= 1;
            end else begin
              peak_offset  <= peak_offset + 1;
            end
            if (off_peak) begin
              state        <= S_ALIGN_OUTPUT;
            // Not enough delay to report peak location
            end else if (peak_offset > INPUT_DELAY) begin
              state        <= S_WAIT_EXCEED_THRESH;
            end
          end

          S_ALIGN_OUTPUT : begin
            trigger_cnt  <= trigger_cnt + 1;
            // Extra -1 to offset trigger register delay
            if (trigger_cnt > INPUT_DELAY-PEAK_TRIGGER_OFFSET-peak_offset-2) begin
              trigger    <= 1'b1;
              state      <= S_WAIT_EXCEED_THRESH;
            end
          end

          default : state <= S_WAIT_EXCEED_THRESH;
        endcase
      end
    end
  end

endmodule