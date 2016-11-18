`timescale 1ns/1ps
`define NS_PER_TICK 1
`define NUM_TEST_CASES 5

`include "sim_exec_report.vh"
`include "sim_clks_rsts.vh"
`include "sim_rfnoc_lib.svh"

module noc_block_digital_gain_tb();
  `TEST_BENCH_INIT("noc_block_digital_gain",`NUM_TEST_CASES,`NS_PER_TICK);
  localparam BUS_CLK_PERIOD = $ceil(1e9/166.67e6);
  localparam CE_CLK_PERIOD  = $ceil(1e9/200e6);
  localparam NUM_CE         = 1;  // Number of Computation Engines / User RFNoC blocks to simulate
  localparam NUM_STREAMS    = 1;  // Number of test bench streams
  `RFNOC_SIM_INIT(NUM_CE, NUM_STREAMS, BUS_CLK_PERIOD, CE_CLK_PERIOD);
  `RFNOC_ADD_BLOCK(noc_block_digital_gain, 0);

  localparam SPP = 16; // Samples per packet

  /********************************************************
  ** Verification
  ********************************************************/
  initial begin : tb_main
    string s;
    logic [15:0] gain;
    logic [31:0] random_word;
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
    tb_streamer.read_reg(sid_noc_block_digital_gain, RB_NOC_ID, readback);
    $display("Read Digital Gain NOC ID: %16x", readback);
    `ASSERT_ERROR(readback == noc_block_digital_gain.NOC_ID, "Incorrect NOC ID");
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 3 -- Connect RFNoC blocks
    ********************************************************/
    `TEST_CASE_START("Connect RFNoC blocks");
    `RFNOC_CONNECT(noc_block_tb,noc_block_digital_gain,SC16,SPP);
    `RFNOC_CONNECT(noc_block_digital_gain,noc_block_tb,SC16,SPP);
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 4 -- Write / readback user registers
    ********************************************************/
    `TEST_CASE_START("Write / readback user registers");
    random_word = $random();
    tb_streamer.write_user_reg(sid_noc_block_digital_gain, noc_block_digital_gain.SR_GAIN, random_word);
    tb_streamer.read_user_reg(sid_noc_block_digital_gain, 0, readback);
    $sformat(s, "Gain incorrect readback! Expected: %0d, Actual %0d", readback[15:0] == random_word[15:0]);
    `ASSERT_ERROR(readback[15:0] == random_word[15:0], s);
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 5 -- Test sequence
    ********************************************************/
    `TEST_CASE_START("Test sequence");
    gain = 100;
    tb_streamer.write_user_reg(sid_noc_block_digital_gain, noc_block_digital_gain.SR_GAIN, gain);
    fork
      begin
        cvita_payload_t send_payload;
        for (int i = 0; i < SPP/2; i++) begin
          send_payload.push_back(64'(i));
        end
        tb_streamer.send(send_payload);
      end
      begin
        cvita_payload_t recv_payload;
        cvita_metadata_t md;
        logic [63:0] expected_value;
        tb_streamer.recv(recv_payload,md);
        for (int i = 0; i < SPP/2; i++) begin
          expected_value = gain*i;
          $sformat(s, "Incorrect value received! Expected: %0d, Received: %0d", expected_value, recv_payload[i]);
          `ASSERT_ERROR(recv_payload[i] == expected_value, s);
        end
      end
    join
    `TEST_CASE_DONE(1);
    `TEST_BENCH_DONE;

  end
endmodule
