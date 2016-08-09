//
// Copyright 2016 Ettus Research
//
// Example test bench for a 1 input, 2 output block
//
`timescale 1ns/1ps
`define SIM_RUNTIME_US 1000
`define NS_PER_TICK 1
`define NUM_TEST_CASES 5

`include "sim_exec_report.vh"
`include "sim_rfnoc_lib.svh"

module noc_block_invert_tb();
  `TEST_BENCH_INIT("noc_block_invert_tb",`NUM_TEST_CASES,`NS_PER_TICK);
  localparam BUS_CLK_PERIOD = $ceil(1e9/166.67e6);
  localparam CE_CLK_PERIOD  = $ceil(1e9/200e6);
  localparam NUM_CE         = 1;
  localparam NUM_STREAMS    = 2; // One for normal data, one for inverted
  `RFNOC_SIM_INIT(NUM_CE,NUM_STREAMS,BUS_CLK_PERIOD,CE_CLK_PERIOD);
  `RFNOC_ADD_BLOCK(noc_block_invert, 0 /* xbar port 0 */);

  localparam SPP = 256; /* Samples per packet */

  /********************************************************
  ** Verification
  ********************************************************/
  initial begin : tb_main
    logic [63:0] readback;
    int random_word;
    cvita_payload_t send_payload;
    cvita_metadata_t tx_md;

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
    `TEST_CASE_START("Setup RFNoC");

    // Read NOC IDs
    tb_streamer.read_reg(sid_noc_block_invert, RB_NOC_ID, readback);
    $display("Read Invert NOC ID: %16x", readback);
    `ASSERT_FATAL(readback == noc_block_invert.NOC_ID, "Incorrect NOC ID");
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 3 -- Connect RFNoC blocks
    ********************************************************/
    `TEST_CASE_START("Connect RFNoC blocks");

    // 1 input, 2 output type connection
    //
    //          ------------------------------     ----------------------------------
    //         |          Test Bench          |   |        RFNoC Block Invert        |
    //         |                              |   |        (noc_block_invert)        |
    //         |                              |   |                                  |
    //  .----->| Stream 0 In     Stream 0 Out |-->| Block Port 0 In     Block Port 0 |-----.
    //  | .--->| Stream 1 In                  |   |                     Block Port 1 |---. |
    //  | |     ------------------------------     ----------------------------------    | |
    //  | |                                                                              | |
    //  | '------------------------------------------------------------------------------' |
    //  '----------------------------------------------------------------------------------'
    `RFNOC_CONNECT_BLOCK_PORT(noc_block_tb,0,noc_block_invert,0,SC16,SPP);
    `RFNOC_CONNECT_BLOCK_PORT(noc_block_invert,0,noc_block_tb,0,SC16,SPP);
    `RFNOC_CONNECT_BLOCK_PORT(noc_block_invert,1,noc_block_tb,1,SC16,SPP);
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 4 -- Register readback
    ********************************************************/
    `TEST_CASE_START("Test registers readback");
    random_word = $random();
    tb_streamer.write_user_reg(sid_noc_block_invert,noc_block_invert.SR_TEST_REG,random_word);
    tb_streamer.read_user_reg(sid_noc_block_invert,0,readback);
    `ASSERT_ERROR(readback == random_word, "Incorrect readback value on test register 0 block port 0!");
    random_word = $random();
    tb_streamer.write_user_reg(sid_noc_block_invert,noc_block_invert.SR_TEST_REG,random_word,1);
    tb_streamer.read_user_reg(sid_noc_block_invert,0,readback,1);
    `ASSERT_ERROR(readback == random_word, "Incorrect readback value on test register 0 block port 1!");
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 5 -- Send test ramp
    ********************************************************/
    `TEST_CASE_START("Send ramp");
    for (int i = 0; i < SPP/2; i++) begin
      send_payload.push_back({16'(4*i),16'(4*i+1),16'(4*i+2),16'(4*i+3)});
    end
    tx_md.eob = 1;
    tb_streamer.send(send_payload,tx_md);

    fork
      begin
        cvita_payload_t recv_payload;
        cvita_metadata_t rx_md;
        tb_streamer.recv(recv_payload,rx_md,0);
        `ASSERT_FATAL(rx_md.eob == 1, "Incorrect EOB value!");
        for (int i = 0; i < SPP/2; i++) begin
          `ASSERT_FATAL(recv_payload[i] == {16'(4*i),16'(4*i+1),16'(4*i+2),16'(4*i+3)},
                        "Incorrect non-inverted ramp data!");
        end
        $display("Non-inverted ramp data correct!");
      end
      begin
        cvita_payload_t recv_payload;
        cvita_metadata_t rx_md;
        tb_streamer.recv(recv_payload,rx_md,1);
        `ASSERT_FATAL(rx_md.eob == 1, "Incorrect EOB value!");
        for (int i = 0; i < SPP/2; i++) begin
          `ASSERT_FATAL(~recv_payload[i] == {16'(4*i),16'(4*i+1),16'(4*i+2),16'(4*i+3)},
                        "Incorrect inverted ramp data!");
        end
        $display("Inverted ramp data correct!");
      end
    join

    `TEST_CASE_DONE(1);
    `TEST_BENCH_DONE;
  end

endmodule
