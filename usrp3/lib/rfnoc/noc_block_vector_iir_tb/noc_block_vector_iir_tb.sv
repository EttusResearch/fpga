//
// Copyright 2014 Ettus Research LLC
//
`timescale 1ns/1ps
`define NS_PER_TICK 1
`define NUM_TEST_CASES 5

`include "sim_exec_report.vh"
`include "sim_clks_rsts.vh"
`include "sim_rfnoc_lib.svh"

module noc_block_vector_iir_tb();
  `TEST_BENCH_INIT("noc_block_vector_iir",`NUM_TEST_CASES,`NS_PER_TICK);
  localparam BUS_CLK_PERIOD = $ceil(1e9/166.67e6);
  localparam CE_CLK_PERIOD  = $ceil(1e9/200e6);
  localparam NUM_CE         = 1;  // Number of Computation Engines / User RFNoC blocks to simulate
  localparam NUM_STREAMS    = 1;  // Number of test bench streams
  `RFNOC_SIM_INIT(NUM_CE, NUM_STREAMS, BUS_CLK_PERIOD, CE_CLK_PERIOD);
  `RFNOC_ADD_BLOCK(noc_block_vector_iir, 0);

  localparam SPP         = 256; // Samples per packet
  localparam NUM_PASSES  = 10;
  // Vector IIR settings
  localparam VECTOR_SIZE = SPP;
  localparam ALPHA       = int'($floor(1.0*(2**31-1)));
  localparam BETA        = int'($floor(1.0*(2**31-1)));

  /********************************************************
  ** Verification
  ********************************************************/
  initial begin : tb_main
    string s;
    logic [63:0] readback;

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
    tb_streamer.read_reg(sid_noc_block_vector_iir, RB_NOC_ID, readback);
    $display("Read Vector IIR NOC ID: %16x", readback);
    `ASSERT_ERROR(readback == noc_block_vector_iir.NOC_ID, "Incorrect NOC ID");
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 3 -- Connect RFNoC blocks
    ********************************************************/
    `TEST_CASE_START("Connect RFNoC blocks");
    `RFNOC_CONNECT(noc_block_tb,noc_block_vector_iir,SC16,SPP);
    `RFNOC_CONNECT(noc_block_vector_iir,noc_block_tb,SC16,SPP);
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 4 -- Setup Vector IIR
    ********************************************************/
    `TEST_CASE_START("Setup Vector IIR");
    tb_streamer.write_user_reg(sid_noc_block_vector_iir, noc_block_vector_iir.SR_VECTOR_LEN, VECTOR_SIZE);
    tb_streamer.write_user_reg(sid_noc_block_vector_iir, noc_block_vector_iir.SR_ALPHA, ALPHA);
    tb_streamer.write_user_reg(sid_noc_block_vector_iir, noc_block_vector_iir.SR_BETA, BETA);
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 5 -- Test vectors
    ********************************************************/
    `TEST_CASE_START("Send test vectors");
    // Send 1/8th sample rate sine wave
    fork
    begin
      logic [31:0] send_word;
      for (int n = 0; n < NUM_PASSES; n++) begin
        $display("Sending test vector %0d", n);
        for (int k = 0; k < VECTOR_SIZE; k++) begin
          send_word[31:16] = 16'(2*k);
          send_word[15:0]  = 16'(2*k+1);
          tb_streamer.push_word(send_word,(k == VECTOR_SIZE-1));
        end
      end
    end
    begin
      logic [31:0] received_payload;
      logic [31:0] expected_payload[0:VECTOR_SIZE-1] = '{VECTOR_SIZE{'d0}};
      logic last;
      for (int n = 0; n < NUM_PASSES; n++) begin
        $display("Checking test vector %0d", n);
        for (int k = 0; k < VECTOR_SIZE; k++) begin
          tb_streamer.pull_word(received_payload,last);
          expected_payload[k][31:16] = expected_payload[k][31:16] + 2*k;
          expected_payload[k][15: 0] = expected_payload[k][15: 0] + 2*k+1;
          $sformat(s, "Vector IIR output incorrect! Received: %08x Expected: %08x", received_payload, expected_payload[k]);
          `ASSERT_FATAL(expected_payload[k] == received_payload, s);
          `ASSERT_FATAL((k != VECTOR_SIZE-1) == (last == 1'b0), "Detected early tlast!");
          `ASSERT_FATAL((k == VECTOR_SIZE-1) == (last == 1'b1), "Detected late tlast!")
        end
      end
    end
    join
    `TEST_CASE_DONE(1);
    `TEST_BENCH_DONE;

  end
endmodule
