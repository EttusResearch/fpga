//
// Copyright 2014-2017 Ettus Research
//

`timescale 1ns/1ps
`define NS_PER_TICK 1
`define NUM_TEST_CASES 8

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

  localparam NUM_COEFFS  = 41;
  localparam COEFF_WIDTH = 16;
  localparam [COEFF_WIDTH*NUM_COEFFS-1:0] COEFFS_VEC_0 =
    {16'sd158,16'sd0,16'sd33,-16'sd0,-16'sd256,
     16'sd553,16'sd573,-16'sd542,-16'sd1012,16'sd349,
     16'sd1536,16'sd123,-16'sd2097,-16'sd1012,16'sd1633,
     16'sd1608,-16'sd3077,-16'sd5946,16'sd3370,16'sd10513,
     16'sd19295,
     16'sd10513,16'sd3370,-16'sd5946,-16'sd3077,16'sd1608,
     16'sd1633,-16'sd1012,-16'sd2097,16'sd123,16'sd1536,
     16'sd349,-16'sd1012,-16'sd542,16'sd573,16'sd553,
     -16'sd256,-16'sd0,16'sd33,16'sd0,16'sd158};
  localparam [COEFF_WIDTH*NUM_COEFFS-1:0] COEFFS_VEC_1 =
    {16'sd32767,16'sd0,-16'sd32767,16'sd0,16'sd32767,
     -16'sd32767,16'sd32767,-16'sd32767,16'sd32767,-16'sd32767,
     16'sd32767,16'sd32767,16'sd32767,16'sd32767,16'sd32767,
     -16'sd32767,-16'sd32767,-16'sd32767,-16'sd32767,-16'sd32767,
     16'sd32767,
     -16'sd32767,-16'sd32767,-16'sd32767,-16'sd32767,-16'sd32767,
     16'sd32767,16'sd32767,16'sd32767,16'sd32767,16'sd32767,
     -16'sd32767,16'sd32767,-16'sd32767,16'sd32767,-16'sd32767,
     16'sd32767,16'sd0,-16'sd32767,16'sd0,16'sd32767};

  // Setup FIR filter via RFNoC block parameters
  defparam noc_block_fir_filter.NUM_COEFFS                = NUM_COEFFS;
  defparam noc_block_fir_filter.COEFFS_VEC                = COEFFS_VEC_0;
  defparam noc_block_fir_filter.RELOADABLE_COEFFS         = 1;
  defparam noc_block_fir_filter.SYMMETRIC_COEFFS          = 1;
  defparam noc_block_fir_filter.SKIP_ZERO_COEFFS          = 1;
  defparam noc_block_fir_filter.USE_EMBEDDED_REGS_COEFFS  = 1;

  // Samples per packet, 2x filter length not strictly necessary,
  // but this is convient so we don't have to break up our 
  localparam SPP = 2*NUM_COEFFS;

  /********************************************************
  ** Verification
  ********************************************************/
  initial begin : tb_main
    string s;
    logic [31:0] random_word;
    logic [63:0] readback;
    longint num_coeffs, num_coeffs_to_send;
    logic [COEFF_WIDTH-1:0] coeffs[0:NUM_COEFFS-1];

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
    ** Test 4 -- Check filter length
    ********************************************************/
    `TEST_CASE_START("Test filter length");
    // Readback NUM_TAPS
    tb_streamer.read_user_reg(sid_noc_block_fir_filter, noc_block_fir_filter.RB_NUM_COEFFS, num_coeffs);
    $display("FIR Filter Length: %d", num_coeffs);
    `ASSERT_ERROR(num_coeffs == NUM_COEFFS, "Incorrect number of coefficients!");

    // If using symmetric coefficients, send half
    if (noc_block_fir_filter.SYMMETRIC_COEFFS) begin
      num_coeffs_to_send = num_coeffs/2 + num_coeffs[0]; // $ceil(num_coeffs/2)
    end else begin
      num_coeffs_to_send = num_coeffs;
    end

    // If using embedded register, coefficients must be preloaded
    if (noc_block_fir_filter.USE_EMBEDDED_REGS_COEFFS) begin
      for (int i = 0; i < num_coeffs_to_send-1; i++) begin
        tb_streamer.write_user_reg(sid_noc_block_fir_filter, noc_block_fir_filter.SR_RELOAD,
          COEFFS_VEC_0[COEFF_WIDTH*i +: COEFF_WIDTH]);
      end
      tb_streamer.write_user_reg(sid_noc_block_fir_filter, noc_block_fir_filter.SR_RELOAD_TLAST,
          COEFFS_VEC_0[COEFF_WIDTH*(num_coeffs_to_send-1) +: COEFF_WIDTH]);
    end
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 5 -- Impulse Response with default coefficients
    ********************************************************/
    // Sending an impulse will readback the FIR filter coefficients
    `TEST_CASE_START("Test impulse response");

    // Send and check impulse
    fork
      begin
        $display("Send impulse");
        tb_streamer.push_word({16'h7FFF,16'h7FFF}, 0);
        // Send impulse
        for (int i = 1; i < num_coeffs; i++) begin
          tb_streamer.push_word(0, (i == num_coeffs-1) /* Assert tlast on last word */);
        end
        // Send another two packets with 0s to push out the impulse from the pipeline
        // Why two? One to push out the data and one to overcome some pipeline registering
        for (int n = 0; n < 2; n++) begin
          for (int i = 0; i < num_coeffs; i++) begin
            tb_streamer.push_word(0, (i == num_coeffs-1) /* Assert tlast on last word */);
          end
        end
      end
      begin
        logic [31:0] recv_val;
        logic last;
        logic signed [15:0] i_samp, q_samp, i_coeff, q_coeff;
        $display("Receive FIR filter output");
        for (int i = 0; i < num_coeffs; i++) begin
          tb_streamer.pull_word({i_samp, q_samp}, last);
          i_coeff = $signed(COEFFS_VEC_0[COEFF_WIDTH*i +: COEFF_WIDTH]);
          q_coeff = i_coeff;
          // Check I / Q values, should be a ramp
          $sformat(s, "Incorrect I value received! Expected: %0d, Received: %0d",
            i_coeff, i_samp);
          `ASSERT_ERROR((i_samp == i_coeff) || (i_samp-1 == i_coeff) || (i_samp+1 == i_coeff), s);
          $sformat(s, "Incorrect Q value received! Expected: %0d, Received: %0d",
            q_coeff, q_samp);
          `ASSERT_ERROR((q_samp == q_coeff) || (q_samp-1 == q_coeff) || (q_samp+1 == q_coeff), s);
          // Check tlast
          if (i == num_coeffs-1) begin
            `ASSERT_ERROR(last, "Last not asserted on final word!");
          end else begin
            `ASSERT_ERROR(~last, "Last asserted early!");
          end
        end
      end
    join
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 6 -- Load new coefficients
    ********************************************************/
    `TEST_CASE_START("Load new conefficients");
    for (int i = 0; i < num_coeffs_to_send-1; i++) begin
      tb_streamer.write_user_reg(sid_noc_block_fir_filter, noc_block_fir_filter.SR_RELOAD,
        COEFFS_VEC_1[COEFF_WIDTH*i +: COEFF_WIDTH]);
    end
    tb_streamer.write_user_reg(sid_noc_block_fir_filter, noc_block_fir_filter.SR_RELOAD_TLAST,
        COEFFS_VEC_1[COEFF_WIDTH*(num_coeffs_to_send-1) +: COEFF_WIDTH]);
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 7 -- Impulse Response with default coefficients
    ********************************************************/
    // Sending an impulse will readback the FIR filter coefficients
    `TEST_CASE_START("Test impulse response");

    // Send and check impulse
    fork
      begin
        $display("Send impulse");
        tb_streamer.push_word({16'h7FFF,16'h7FFF}, 0);
        // Send impulse
        for (int i = 1; i < num_coeffs; i++) begin
          tb_streamer.push_word(0, (i == num_coeffs-1) /* Assert tlast on last word */);
        end
        // Send another two packets with 0s to push out the impulse from the pipeline
        // Why two? One to push out the data and one to overcome some pipeline registering
        for (int n = 0; n < 2; n++) begin
          for (int i = 0; i < num_coeffs; i++) begin
            tb_streamer.push_word(0, (i == num_coeffs-1) /* Assert tlast on last word */);
          end
        end
      end
      begin
        logic [31:0] recv_val;
        logic last;
        logic signed [15:0] i_samp, q_samp, i_coeff, q_coeff;
        $display("Receive FIR filter output");
        // Ignore the first two packets
        // Data is not useful until the pipeline is flushed
        for (int n = 0; n < 2; n++) begin
          for (int i = 0; i < num_coeffs; i++) begin
            tb_streamer.pull_word({i_samp, q_samp}, last);
          end
        end
        for (int i = 0; i < num_coeffs; i++) begin
          tb_streamer.pull_word({i_samp, q_samp}, last);
          i_coeff = $signed(COEFFS_VEC_1[COEFF_WIDTH*i +: COEFF_WIDTH]);
          q_coeff = i_coeff;
          // Check I / Q values, should be a ramp
          $sformat(s, "Incorrect I value received! Expected: %0d, Received: %0d",
            i_coeff, i_samp);
          `ASSERT_ERROR((i_samp == i_coeff) || (i_samp-1 == i_coeff) || (i_samp+1 == i_coeff), s);
          $sformat(s, "Incorrect Q value received! Expected: %0d, Received: %0d",
            q_coeff, q_samp);
          `ASSERT_ERROR((q_samp == q_coeff) || (q_samp-1 == q_coeff) || (q_samp+1 == q_coeff), s);
          // Check tlast
          if (i == num_coeffs-1) begin
            `ASSERT_ERROR(last, "Last not asserted on final word!");
          end else begin
            `ASSERT_ERROR(~last, "Last asserted early!");
          end
        end
      end
    join
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 8 -- Step Response
    ********************************************************/
    // Sending an step function will readback the sum of the FIR filter coefficients
    `TEST_CASE_START("Test step response");

    // Send step function and check output
    fork
      begin
        $display("Send step function");
        // Send step function two times, once to fill up the pipeline and another to get the actual response
        for (int n = 0; n < 2; n++) begin
          for (int i = 0; i < num_coeffs; i++) begin
            tb_streamer.push_word({16'h7FFF,16'h7FFF}, (i == num_coeffs-1) /* Assert tlast on last word */);
          end
        end
        // Send another two packets with 0s to push out impulse from the pipeline
        for (int n = 0; n < 2; n++) begin
          for (int i = 0; i < num_coeffs; i++) begin
            tb_streamer.push_word(0, (i == num_coeffs-1) /* Assert tlast on last word */);
          end
        end
      end
      begin
        logic [31:0] recv_val;
        logic last;
        logic signed [15:0] i_samp, q_samp;
        int coeff_sum;
        for (int i = 0; i < num_coeffs; i++) begin
            coeff_sum += $signed(COEFFS_VEC_1[COEFF_WIDTH*i +: COEFF_WIDTH]);
        end
        $display("Receive FIR filter output");
        // Ignore the first three packets
        // Data is not useful until the pipeline is completely flushed and filled with 1s
        for (int n = 0; n < 3; n++) begin
          for (int i = 0; i < num_coeffs; i++) begin
            tb_streamer.pull_word({i_samp, q_samp}, last);
          end
        end
        for (int i = 0; i < num_coeffs; i++) begin
          tb_streamer.pull_word({i_samp, q_samp}, last);
          // Check I / Q values, should be a ramp
          $sformat(s, "Incorrect I value received! Expected: %0d, Received: %0d", coeff_sum, i_samp);
          `ASSERT_ERROR((i_samp == coeff_sum) || (i_samp-1 == coeff_sum) || (i_samp+1 == coeff_sum), s);
          $sformat(s, "Incorrect Q value received! Expected: %0d, Received: %0d", coeff_sum, q_samp);
          `ASSERT_ERROR((q_samp == coeff_sum) || (q_samp-1 == coeff_sum) || (q_samp+1 == coeff_sum), s);
          // Check tlast
          if (i == num_coeffs-1) begin
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
