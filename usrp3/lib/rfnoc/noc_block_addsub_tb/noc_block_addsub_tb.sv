//
// Copyright 2016 Ettus Research
//

`timescale 1ns/1ps
`define NS_PER_TICK 1
`define NUM_TEST_CASES 4

`include "sim_exec_report.vh"
`include "sim_clks_rsts.vh"
`include "sim_rfnoc_lib.svh"

module noc_block_addsub_tb();
  `TEST_BENCH_INIT("noc_block_addsub",`NUM_TEST_CASES,`NS_PER_TICK);
  localparam BUS_CLK_PERIOD = $ceil(1e9/166.67e6);
  localparam CE_CLK_PERIOD  = $ceil(1e9/200e6);
  localparam NUM_CE         = 1;  // Number of Computation Engines / User RFNoC blocks to simulate
  localparam NUM_STREAMS    = 2;  // Number of test bench streams
  `RFNOC_SIM_INIT(NUM_CE, NUM_STREAMS, BUS_CLK_PERIOD, CE_CLK_PERIOD);
  `RFNOC_ADD_BLOCK(noc_block_addsub, 0);

  localparam SPP = 256; // Samples per packet

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
    tb_streamer.read_reg(sid_noc_block_addsub, RB_NOC_ID, readback);
    $display("Read AddSub NOC ID: %16x", readback);
    `ASSERT_ERROR(readback == noc_block_addsub.NOC_ID, "Incorrect NOC ID");
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 3 -- Connect RFNoC blocks
    ********************************************************/
    `TEST_CASE_START("Connect RFNoC blocks");
    `RFNOC_CONNECT_BLOCK_PORT(noc_block_tb,0,noc_block_addsub,0,SC16,SPP);
    `RFNOC_CONNECT_BLOCK_PORT(noc_block_tb,1,noc_block_addsub,1,SC16,SPP);
    `RFNOC_CONNECT_BLOCK_PORT(noc_block_addsub,0,noc_block_tb,0,SC16,SPP);
    `RFNOC_CONNECT_BLOCK_PORT(noc_block_addsub,1,noc_block_tb,1,SC16,SPP);
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 4 -- Test adding and subtracting ramps
    ********************************************************/
    `TEST_CASE_START("Test adding and subtracting ramps");
    fork
      begin
        cvita_payload_t send_payload;
        cvita_metadata_t tx_md;
        for (int i = 0; i < SPP/2; i++) begin
          send_payload.push_back({16'(2*i+SPP),16'(2*i),16'(2*i+1+SPP),16'(2*i+1)});
        end
        tx_md.eob = 1'b1;
        tb_streamer.send(send_payload,tx_md,0);
        tb_streamer.send(send_payload,tx_md,1);
      end
      begin
        cvita_payload_t recv_payload[0:1];
        cvita_metadata_t rx_md[0:1];
        logic [63:0] expected_value, recv_value;
        tb_streamer.recv(recv_payload[0],rx_md[0],0);
        tb_streamer.recv(recv_payload[1],rx_md[1],1);
        for (int i = 0; i < SPP/2; i++) begin
          expected_value = 2*{16'(2*i+SPP),16'(2*i),16'(2*i+1+SPP),16'(2*i+1)};
          recv_value = recv_payload[0][i];
          $sformat(s, "Incorrect value received on add output! Expected: %0d, Received: %0d", expected_value, recv_value);
         `ASSERT_ERROR(recv_value == expected_value, s);
          expected_value = 'd0;
          recv_value = recv_payload[1][i];
          $sformat(s, "Incorrect value received on subtract output! Expected: %0d, Received: %0d", expected_value, recv_value);
         `ASSERT_ERROR(recv_value == expected_value, s);
        end
      end
    join
    `TEST_CASE_DONE(1);
    `TEST_BENCH_DONE;

  end
endmodule
