//
// Copyright 2016 Ettus Research
//
`timescale 1ns/1ps
`define SIM_TIMEOUT_US 40
`define NS_PER_TICK 1
`define NUM_TEST_CASES 5
`include "sim_exec_report.vh"
`include "sim_rfnoc_lib.svh"

module noc_block_fft_tb();
  `TEST_BENCH_INIT("noc_block_fft_tb",`NUM_TEST_CASES,`NS_PER_TICK);
  localparam BUS_CLK_PERIOD = $ceil(1e9/166.67e6);
  localparam CE_CLK_PERIOD  = $ceil(1e9/200e6);
  localparam NUM_CE         = 1;
  localparam NUM_STREAMS    = 1;
  `RFNOC_SIM_INIT(NUM_CE, NUM_STREAMS, BUS_CLK_PERIOD, CE_CLK_PERIOD);
  // Instantiate FFT RFNoC block
  `RFNOC_ADD_BLOCK(noc_block_fft, 0 /* xbar port 0 */);

  // FFT specific settings
  localparam [15:0] FFT_SIZE = 256;
  localparam FFT_BIN         = FFT_SIZE/8 + FFT_SIZE/2; // 1/8 sample rate freq + FFT shift
  wire [7:0] fft_size_log2   = $clog2(FFT_SIZE);        // Set FFT size
  wire fft_direction         = 0;                       // Set FFT direction to forward (i.e. DFT[x(n)] => X(k))
  wire [11:0] fft_scale      = 12'b011010101010;        // Conservative scaling of 1/N
  // Padding of the control word depends on the FFT options enabled
  wire [20:0] fft_ctrl_word  = {fft_scale, fft_direction, fft_size_log2};

  localparam NUM_ITERATIONS  = 10;

  /********************************************************
  ** Verification
  ********************************************************/
  initial begin : tb_main
    logic [63:0] readback;
    logic [15:0] real_val;
    logic [15:0] cplx_val;
    logic last;

    /********************************************************
    ** Test 1 -- Reset
    ********************************************************/
    `TEST_CASE_START("Wait for Reset");
    while (bus_rst) @(posedge bus_clk);
    while (ce_rst) @(posedge ce_clk);
    `TEST_CASE_DONE(~bus_rst & ~ce_rst);

    /********************************************************
    ** Test 2 -- Check for correct NoC IDs
    ********************************************************/
    `TEST_CASE_START("Check NoC ID");
    // Read NOC IDs
    tb_streamer.read_reg(sid_noc_block_fft, RB_NOC_ID, readback);
    $display("Read FFT NOC ID: %16x", readback);
    `ASSERT_ERROR(readback == noc_block_fft.NOC_ID, "Incorrect NOC ID");
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 3 -- Connect RFNoC blocks
    ********************************************************/
    `TEST_CASE_START("Connect RFNoC blocks");
    // Test bench -> FFT -> Test bench
    `RFNOC_CONNECT(noc_block_tb /* From */, noc_block_fft /* To */, SC16 /* Type */, FFT_SIZE /* Samples per packet */);
    `RFNOC_CONNECT(noc_block_fft,noc_block_tb,SC16,FFT_SIZE);
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 4 -- Setup FFT
    ********************************************************/
    `TEST_CASE_START("Setup FFT registers");
    // Setup FFT
    tb_streamer.write_reg(sid_noc_block_fft, noc_block_fft.SR_AXI_CONFIG_BASE, {11'd0, fft_ctrl_word});  // Configure FFT core
    tb_streamer.write_reg(sid_noc_block_fft, noc_block_fft.SR_FFT_SIZE_LOG2, fft_size_log2);             // Set FFT size register
    tb_streamer.write_reg(sid_noc_block_fft, noc_block_fft.SR_MAGNITUDE_OUT, noc_block_fft.COMPLEX_OUT); // Enable real/imag out
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 5 -- Test sine wave
    ********************************************************/
    `TEST_CASE_START("Send sine wave & check FFT data");
    // Send 1/8th sample rate sine wave
    fork
    begin
      for (int n = 0; n < NUM_ITERATIONS; n++) begin
        for (int i = 0; i < (FFT_SIZE/8); i++) begin
          tb_streamer.push_word({ 16'd32767,     16'd0},0);
          tb_streamer.push_word({ 16'd23170, 16'd23170},0);
          tb_streamer.push_word({     16'd0, 16'd32767},0);
          tb_streamer.push_word({-16'd23170, 16'd23170},0);
          tb_streamer.push_word({-16'd32767,     16'd0},0);
          tb_streamer.push_word({-16'd23170,-16'd23170},0);
          tb_streamer.push_word({     16'd0,-16'd32767},0);
          tb_streamer.push_word({ 16'd23170,-16'd23170},(i == (FFT_SIZE/8)-1)); // Assert tlast on final word
        end
      end
    end
    begin
      for (int n = 0; n < NUM_ITERATIONS; n++) begin
        for (int k = 0; k < FFT_SIZE; k++) begin
          tb_streamer.pull_word({real_val,cplx_val},last);
          if (k == FFT_BIN) begin
            // Assert that for the special case of a 1/8th sample rate sine wave input, 
            // the real part of the corresponding 1/8th sample rate FFT bin should always be greater than 0 and
            // the complex part equal to 0.
            `ASSERT_ERROR(real_val > 32'd0, "FFT bin real part is not greater than 0!");
            `ASSERT_ERROR(cplx_val == 32'd0, "FFT bin complex part is not 0!");
          end else begin
            // Assert all other FFT bins should be 0 for both complex and real parts
            `ASSERT_ERROR(real_val == 32'd0, "FFT bin real part is not 0!");
            `ASSERT_ERROR(cplx_val == 32'd0, "FFT bin complex part is not 0!");
          end
          // Check packet size via tlast assertion
          if (k == FFT_SIZE-1) begin
            `ASSERT_ERROR(last == 1'b1, "Detected late tlast!");
          end else begin
            `ASSERT_ERROR(last == 1'b0, "Detected early tlast!");
          end
        end
      end
    end
    join
    `TEST_CASE_DONE(1);
    `TEST_BENCH_DONE;
  end
endmodule
