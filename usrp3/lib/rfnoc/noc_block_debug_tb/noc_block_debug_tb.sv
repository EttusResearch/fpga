//
// Copyright 2017 Ettus Research
//

`timescale 1ns/1ps
`define NS_PER_TICK 1
`define NUM_TEST_CASES 5

`include "sim_exec_report.vh"
`include "sim_clks_rsts.vh"
`include "sim_rfnoc_lib.svh"

module noc_block_debug_tb();
  `TEST_BENCH_INIT("noc_block_debug",`NUM_TEST_CASES,`NS_PER_TICK);
  localparam BUS_CLK_PERIOD = $ceil(1e9/166.67e6);
  localparam CE_CLK_PERIOD  = $ceil(1e9/200e6);
  localparam NUM_CE         = 1;  // Number of Computation Engines / User RFNoC blocks to simulate
  localparam NUM_STREAMS    = 2;  // Number of test bench streams
  `RFNOC_SIM_INIT(NUM_CE, NUM_STREAMS, BUS_CLK_PERIOD, CE_CLK_PERIOD);
  `RFNOC_ADD_BLOCK(noc_block_debug, 0);

  localparam SPP = 16; // Samples per packet

  /********************************************************
  ** Verification
  ********************************************************/
  initial begin : tb_main
    string s;
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
    tb_streamer.read_reg(sid_noc_block_debug, RB_NOC_ID, readback);
    $display("Read Skeleton NOC ID: %16x", readback);
    `ASSERT_ERROR(readback == noc_block_debug.NOC_ID, "Incorrect NOC ID");
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 3 -- Connect RFNoC blocks
    ********************************************************/
    `TEST_CASE_START("Connect RFNoC blocks");
    `RFNOC_CONNECT(noc_block_tb,noc_block_debug,SC16,SPP);
    `RFNOC_CONNECT(noc_block_debug,noc_block_tb,SC16,SPP);
    // Connect second output port back to test bench
    `RFNOC_CONNECT_BLOCK_PORT(noc_block_debug,1,noc_block_tb,1,SC16,SPP);
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 4 -- Write / readback user registers
    ********************************************************/
    `TEST_CASE_START("Write / readback user registers");
    random_word = $random();
    tb_streamer.write_user_reg(sid_noc_block_debug, noc_block_debug.SR_CONFIG, 2'b10);
    tb_streamer.read_user_reg(sid_noc_block_debug, noc_block_debug.RB_CONFIG, readback);
    $sformat(s, "Configuration word incorrect readback! Expected: %0d, Actual %0d", readback[1:0], 2'b0);
    `ASSERT_ERROR(readback[1:0] == 2'b0, s);
    random_word = $random();
    tb_streamer.write_user_reg(sid_noc_block_debug, noc_block_debug.SR_PAYLOAD_LEN, SPP);
    tb_streamer.read_user_reg(sid_noc_block_debug, noc_block_debug.RB_PAYLOAD_LEN, readback);
    $sformat(s, "Payload size incorrect readback! Expected: %0d, Actual %0d", readback[15:0], SPP[15:0]);
    `ASSERT_ERROR(readback[15:0] == SPP[15:0], s);
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 5 -- Test sequence
    ********************************************************/
    // Skeleton's user code is a loopback, so we should receive
    // back exactly what we send
    `TEST_CASE_START("Test sequence");
    fork
      begin
        cvita_payload_t send_payload;
        for (int k = 0; k < 32; k++) begin
          for (int i = 0; i < SPP/2; i++) begin
            send_payload.push_back({32'(2*i),32'(2*i+1)});
          end
        end
        tb_streamer.send(send_payload);
      end
      // Receive loopback data
      begin
        cvita_payload_t recv_payload;
        cvita_metadata_t md;
        logic [63:0] expected_value;
        for (int k = 0; k < 32; k++) begin
          tb_streamer.recv(recv_payload,md,0);
          for (int i = 0; i < SPP/2; i++) begin
            expected_value = {32'(2*i),32'(2*i+1)};
            $sformat(s, "Incorrect value received! Expected: %0d, Received: %0d", expected_value, recv_payload[i]);
            `ASSERT_ERROR(recv_payload[i] == expected_value, s);
          end
        end
      end
      // Receive packet stats
      begin
        cvita_payload_t recv_payload;
        cvita_metadata_t md;
        tb_streamer.recv(recv_payload,md,1);
        $sformat(s, "Incorrect payload size! Expected: %0d, Received: %0d", noc_block_debug.OUTPUT_PKT_LEN, 2*recv_payload.size());
        `ASSERT_ERROR(2*recv_payload.size() == noc_block_debug.OUTPUT_PKT_LEN, s);
      end
    join
    `TEST_CASE_DONE(1);
    `TEST_BENCH_DONE;

  end
endmodule
