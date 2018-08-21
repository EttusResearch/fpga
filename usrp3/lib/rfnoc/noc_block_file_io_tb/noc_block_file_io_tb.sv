//
// Copyright 2015 National Instruments
//

`timescale 1ns / 1ps

`define SIM_RUNTIME_US 1000
`define NS_PER_TICK 1
`define NUM_TEST_CASES 4

`include "sim_exec_report.vh"
`include "sim_rfnoc_lib.svh"
`include "sim_file_io.svh"

module noc_block_file_io_tb;
  `TEST_BENCH_INIT("noc_block_file_io_tb", `NUM_TEST_CASES, `NS_PER_TICK);
  localparam BUS_CLK_PERIOD = $ceil(1e9/166.67e6);
  localparam CE_CLK_PERIOD  = $ceil(1e9/200e6);
  localparam NUM_CE         = 1;  // Number of Computation Engines / User RFNoC blocks to simulate
  localparam NUM_STREAMS    = 1;  // Number of test bench streams
  `RFNOC_SIM_INIT(NUM_CE, NUM_STREAMS, BUS_CLK_PERIOD, CE_CLK_PERIOD);

  `RFNOC_ADD_BLOCK(noc_block_file_source, 0);
  defparam noc_block_file_source.FILENAME = `ABSPATH("test.mem");

  localparam SPP = 64;

  cvita_payload_t recv_payload;
  cvita_metadata_t md;

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
    tb_streamer.read_reg(sid_noc_block_file_source, RB_NOC_ID, readback);
    $display("Read NOC ID: %16x", readback);
    `ASSERT_ERROR(readback == noc_block_file_source.NOC_ID, "Incorrect NOC ID");
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 3 -- Connect RFNoC blocks
    ********************************************************/
    `TEST_CASE_START("Connect RFNoC blocks");
    `RFNOC_CONNECT(noc_block_tb, noc_block_file_source, SC16, SPP);
    `RFNOC_CONNECT(noc_block_file_source, noc_block_tb, SC16, SPP);
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 4 -- Test sequence
    ********************************************************/
    `TEST_CASE_START("Test sequence");
    tb_streamer.write_user_reg(sid_noc_block_file_source, noc_block_file_source.file_source.SR_PKT_LENGTH, SPP);
    tb_streamer.write_user_reg(sid_noc_block_file_source, noc_block_file_source.file_source.SR_SWAP_SAMPLES, 2);
    tb_streamer.write_user_reg(sid_noc_block_file_source, noc_block_file_source.file_source.SR_ENDIANNESS, 1);
    tb_streamer.write_user_reg(sid_noc_block_file_source, noc_block_file_source.file_source.SR_ENABLE, 1);
    for (int p = 0; p < 1024/SPP; p++) begin
      tb_streamer.recv(recv_payload, md);
      for (int i = 0; i < SPP; i++) begin
        `ASSERT_ERROR((recv_payload[i] == (i + (p * SPP))), "File data mismatch");
      end
    end
    `TEST_CASE_DONE(1);

    `TEST_BENCH_DONE;

  end

endmodule
