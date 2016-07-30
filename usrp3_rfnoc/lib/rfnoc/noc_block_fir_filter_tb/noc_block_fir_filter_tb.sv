`timescale 1ns/1ps
`define NS_PER_TICK 1
`define NUM_TEST_CASES 4

`include "sim_exec_report.vh"
`include "sim_clks_rsts.vh"
`include "sim_rfnoc_lib.svh"

module noc_block_fir_filter_tb();
  `TEST_BENCH_INIT("noc_block_fir_filter",`NUM_TEST_CASES,`NS_PER_TICK);
  localparam BUS_CLK_PERIOD = $ceil(1e9/166.67e6);
  localparam CE_CLK_PERIOD  = $ceil(1e9/200e6);
  localparam NUM_CE         = 1;  // Number of Computation Engines / User RFNoC blocks to simulate
  localparam NUM_STREAMS    = 1;  // Number of test bench streams
  `RFNOC_SIM_INIT(NUM_CE, NUM_STREAMS, BUS_CLK_PERIOD, CE_CLK_PERIOD);
  `RFNOC_ADD_BLOCK(noc_block_fir_filter, 0);

  localparam SPP = 64; // Samples per packet

  /********************************************************
  ** Verification
  ********************************************************/
  initial begin : tb_main
    string s;
    logic [31:0] random_word;
    logic [63:0] readback;
    int num_taps;

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
    tb_streamer.read_reg(sid_noc_block_fir_filter, RB_NOC_ID, readback);
    $display("Read FIR Filter NOC ID: %16x", readback);
    `ASSERT_ERROR(readback == noc_block_fir_filter.NOC_ID, "Incorrect NOC ID");
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 3 -- Connect RFNoC blocks
    ********************************************************/
    `TEST_CASE_START("Connect RFNoC blocks");
    `RFNOC_CONNECT(noc_block_tb,noc_block_fir_filter,SC16,SPP);
    `RFNOC_CONNECT(noc_block_fir_filter,noc_block_tb,SC16,SPP);
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 4 -- Impulse Response
    ********************************************************/
    // Sending an impulse will readback the FIR filter coefficients
    `TEST_CASE_START("Test impulse response");

    /* Set filter coefficients via reload bus */
    // Read NUM_TAPS
    tb_streamer.read_reg(sid_noc_block_fir_filter, noc_block_fir_filter.RB_NUM_TAPS, num_taps);
    // Write a ramp to FIR filter coefficients
    for (int i = 0; i < num_taps-1; i++) begin
      tb_streamer.write_reg(sid_noc_block_fir_filter, noc_block_fir_filter.SR_RELOAD, i);
    end
    tb_streamer.write_reg(sid_noc_block_fir_filter, noc_block_fir_filter.SR_RELOAD_LAST, num_taps-1);
    // Load coefficients
    tb_streamer.write_reg(sid_noc_block_fir_filter, noc_block_fir_filter.SR_CONFIG, 0);

    /* Send and check impulse */
    fork
      begin
        $display("Send impulse");
        tb_streamer.push_word({16'h7FFF,16'h7FFF}, 0);
        for (int i = 0; i < num_taps-1; i++) begin
          tb_streamer.push_word(0, (i == num_taps-2) /* Assert tlast on last word */);
        end
      end
      begin
        logic [31:0] recv_val;
        logic last;
        logic [15:0] i_samp, q_samp;
        $display("Receive FIR filter output");
        for (int i = 0; i < num_taps; i++) begin
          tb_streamer.pull_word({i_samp, q_samp}, last);
          // Check I / Q values, should be a ramp
          $sformat(s, "Incorrect I value received! Expected: %0d, Received: %0d", i, i_samp);
          `ASSERT_ERROR(i_samp == i, s);
          $sformat(s, "Incorrect Q value received! Expected: %0d, Received: %0d", i, q_samp);
          `ASSERT_ERROR(q_samp == i, s);
          // Check tlast
          if (i == num_taps-1) begin
            `ASSERT_ERROR(last, "Last not asserted on final word!");
          end else begin
            `ASSERT_ERROR(~last, "Last asserted early!");
          end
        end
      end
    join
    `TEST_CASE_DONE(1);
    `TEST_BENCH_DONE;

  end
endmodule
