//
// Copyright 2015 Ettus Research LLC
//
`timescale 1ns/1ps
`define SIM_RUNTIME_US 1000
`define NS_PER_TICK 1
`define NUM_TEST_CASES 2
`include "sim_exec_report.vh"
`include "sim_rfnoc_lib.svh"

module noc_block_schmidl_cox_tb();
  // Initialize RFNoC test bench infrastructure
  `TEST_BENCH_INIT("noc_block_schmild_cox_tb",`NUM_TEST_CASES,`NS_PER_TICK);
  localparam BUS_CLK_PERIOD = $ceil(1e9/166.67e6);
  localparam CE_CLK_PERIOD  = $ceil(1e9/200e6);
  localparam NUM_CE         = 3;
  localparam NUM_STREAMS    = 1;
  `RFNOC_SIM_INIT(NUM_CE, NUM_STREAMS, BUS_CLK_PERIOD, CE_CLK_PERIOD);

  // Instiantiate RFNoC blocks in testbench
  `RFNOC_ADD_BLOCK(noc_block_file_source,0);
  defparam noc_block_file_source.FILENAME = "../../../../test-sc16.bin";
  `RFNOC_ADD_BLOCK(noc_block_schmidl_cox,1);
  `RFNOC_ADD_BLOCK(noc_block_fft,2);
  defparam noc_block_fft.EN_MAGNITUDE_OUT        = 0;
  defparam noc_block_fft.EN_MAGNITUDE_APPROX_OUT = 0;
  defparam noc_block_fft.EN_MAGNITUDE_SQ_OUT     = 0;
  defparam noc_block_fft.EN_FFT_SHIFT            = 1;

  localparam [31:0] OFDM_SYMBOL_SIZE = 64;
  localparam [31:0] PACKET_LENGTH    = 12;
  localparam [31:0] NUM_PACKETS      = 10;

  // FFT settings
  localparam [15:0] FFT_SIZE         = OFDM_SYMBOL_SIZE;
  localparam [31:0] FFT_SIZE_LOG2    = $clog2(FFT_SIZE);
  localparam [31:0] FFT_DIRECTION    = noc_block_fft.FFT_FORWARD;  // Forward
  localparam [31:0] FFT_SCALING      = 12'b010101010101;           // Aggressive scaling
  localparam [31:0] FFT_SHIFT_CONFIG = 1;                          // Reverse FFT shift, output negative frequencies first

  localparam MTU                     = 1440/8;                     // About the size of a 1500 byte Ethernet packet in 8 byte words

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
    tb_streamer.read_reg(sid_noc_block_schmidl_cox, RB_NOC_ID, readback);
    $display("Read Schmidl-Cox NOC ID: %16x", readback);
    `ASSERT_ERROR(readback == noc_block_schmidl_cox.NOC_ID, "Incorrect NOC ID");
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 3 -- Connect RFNoC blocks
    ********************************************************/
    `TEST_CASE_START("Connect RFNoC blocks");
    `RFNOC_CONNECT(noc_block_file_source,noc_block_schmidl_cox,SC16,MTU);
    `RFNOC_CONNECT(noc_block_schmidl_cox,noc_block_fft,SC16,OFDM_SYMBOL_SIZE);
    `RFNOC_CONNECT(noc_block_fft,noc_block_tb,SC16,OFDM_SYMBOL_SIZE);
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 4 -- Setup RFNoC Blocks
    ********************************************************/
    `TEST_CASE_START("Setup RFNoC Blocks");
    $display("Setup Schmidl-Cox");
    tb_streamer.write_reg(sid_noc_block_schmidl_cox, noc_block_schmidl_cox.schmidl_cox.SR_FRAME_LEN, OFDM_SYMBOL_SIZE);        // FFT Size
    tb_streamer.write_reg(sid_noc_block_schmidl_cox, noc_block_schmidl_cox.schmidl_cox.SR_GAP_LEN, 32'd16);                    // Cyclic Prefix length
    tb_streamer.write_reg(sid_noc_block_schmidl_cox, noc_block_schmidl_cox.schmidl_cox.SR_OFFSET, {32'd160+32+64-8});          // Skip short preamble + skip long preamble CP + skip first long preamble sym
    tb_streamer.write_reg(sid_noc_block_schmidl_cox, noc_block_schmidl_cox.schmidl_cox.SR_NUMBER_SYMBOLS_MAX, PACKET_LENGTH);  // Maximum number of symbols (excluding preamble)
    tb_streamer.write_reg(sid_noc_block_schmidl_cox, noc_block_schmidl_cox.schmidl_cox.SR_NUMBER_SYMBOLS_SHORT, 32'd0);        // Unused
    // Schmidl & Cox algorithm uses a metric normalized between 0.0 - 1.0.
    tb_streamer.write_reg(sid_noc_block_schmidl_cox, noc_block_schmidl_cox.schmidl_cox.SR_THRESHOLD, 16'd0, 16'd14335);        // Threshold (format Q1.14, Sign bit, 1 integer, 14 fractional), 14335 ~= +0.875
    $display("Done");
    $display("Setup FFT");
    tb_streamer.write_reg(sid_noc_block_fft, noc_block_fft.SR_FFT_SIZE_LOG2, FFT_SIZE_LOG2);                                   // FFT size
    tb_streamer.write_reg(sid_noc_block_fft, noc_block_fft.SR_FFT_DIRECTION, FFT_DIRECTION);                                   // FFT direction
    tb_streamer.write_reg(sid_noc_block_fft, noc_block_fft.SR_FFT_SCALING, FFT_SCALING);                                       // FFT scaling
    tb_streamer.write_reg(sid_noc_block_fft, noc_block_fft.SR_FFT_SHIFT_CONFIG, FFT_SHIFT_CONFIG);                             // FFT shift configuration
    tb_streamer.write_reg(sid_noc_block_fft, noc_block_fft.SR_MAGNITUDE_OUT, {30'd0, noc_block_fft.COMPLEX_OUT});              // Enable complex output
    $display("Done");
    $display("Setup File Source");
    tb_streamer.write_reg(sid_noc_block_file_source, noc_block_file_source.file_source.SR_PKT_LENGTH, MTU);
    tb_streamer.write_reg(sid_noc_block_file_source, noc_block_file_source.file_source.SR_RATE, 32'd10);    // Output every 10th cycle (assuming 200 MHz ce_clk => 20 MHz sample rate)
    tb_streamer.write_reg(sid_noc_block_file_source, noc_block_file_source.file_source.SR_ENABLE, 1'b1);    // Do this last to kick off test bench
    $display("Done");

    /********************************************************
    ** Test 5 -- Receive OFDM Frames
    ********************************************************/
    `TEST_CASE_START("Receive OFDM Frames");
    // TODO: This goes on until test bench timeout. Need to add self-checking tests.
    for (int n = 0; n < NUM_PACKETS; n = n + 1) begin
      for (int l = 0; l < PACKET_LENGTH; l = l + 1) begin
        for (int k = 0; k < OFDM_SYMBOL_SIZE; k = k + 1) begin
          tb_streamer.pull_word({real_val,cplx_val},last);
        end
      end
    end
    `TEST_CASE_DONE(1);
  end
endmodule
