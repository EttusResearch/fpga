//
// Copyright 2014 Ettus Research LLC
//
`timescale 1ns/1ps
`define NS_PER_TICK 1
`define NUM_TEST_CASES 5

`include "sim_exec_report.vh"
`include "sim_clks_rsts.vh"
`include "sim_rfnoc_lib.svh"

module noc_block_keep_one_in_n_tb();
  `TEST_BENCH_INIT("noc_block_keep_one_in_n",`NUM_TEST_CASES,`NS_PER_TICK);
  localparam BUS_CLK_PERIOD = $ceil(1e9/166.67e6);
  localparam CE_CLK_PERIOD  = $ceil(1e9/200e6);
  localparam NUM_CE         = 1;  // Number of Computation Engines / User RFNoC blocks to simulate
  localparam NUM_STREAMS    = 1;  // Number of test bench streams
  `RFNOC_SIM_INIT(NUM_CE, NUM_STREAMS, BUS_CLK_PERIOD, CE_CLK_PERIOD);
  `RFNOC_ADD_BLOCK(noc_block_keep_one_in_n, 0);

  localparam SPP   = 16; // Samples per packet
  localparam MAX_N = 16;

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
    tb_streamer.read_reg(sid_noc_block_keep_one_in_n, RB_NOC_ID, readback);
    $display("Read Keep One in N NOC ID: %16x", readback);
    `ASSERT_ERROR(readback == noc_block_keep_one_in_n.NOC_ID, "Incorrect NOC ID");
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 3 -- Connect RFNoC blocks
    ********************************************************/
    `TEST_CASE_START("Connect RFNoC blocks");
    `RFNOC_CONNECT(noc_block_tb,noc_block_keep_one_in_n,SC16,SPP);
    `RFNOC_CONNECT(noc_block_keep_one_in_n,noc_block_tb,SC16,SPP);
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 4 -- Test vector mode
    ********************************************************/
    `TEST_CASE_START("Test vector mode (keep one in n packets)");
    for (int n = 1; n <= MAX_N; n++) begin
      $display("Test N = %0d", n);
      tb_streamer.write_user_reg(sid_noc_block_keep_one_in_n,noc_block_keep_one_in_n.SR_N,n);
      tb_streamer.write_user_reg(sid_noc_block_keep_one_in_n,noc_block_keep_one_in_n.SR_VECTOR_MODE,1);
      fork
      begin
        cvita_metadata_t tx_md;
        cvita_payload_t send_payload;
        // Send N packets, all but the last should be dropped
        for (int l = 0; l < n; l++) begin
          send_payload.delete();
          for (int i = 0; i < SPP/2; i++) begin
            send_payload.push_back(64'(l*SPP/2+i));
          end
          tx_md.eob = (l == n-1);
          tb_streamer.send(send_payload,tx_md);
        end
      end
      begin
        cvita_metadata_t rx_md;
        cvita_payload_t recv_payload;
        logic [63:0] expected_value, received_value;
        tb_streamer.recv(recv_payload,rx_md);
        `ASSERT_ERROR(rx_md.eob == 1'b1, "EOB not asserted!");
        for (int i = 0; i < SPP/2; i++) begin
          expected_value = 64'((n-1)*SPP/2+i);
          received_value = recv_payload[i];
          $sformat(s, "N = %0d: Incorrect value received! Expected: %0d, Received: %0d", n, expected_value, received_value);
          `ASSERT_ERROR(received_value == expected_value, s);
        end
      end
      join
    end
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 5 -- Test sample mode
    ********************************************************/
    `TEST_CASE_START("Test sample mode (keep one in n samples)");
    for (int n = 1; n <= MAX_N; n++) begin
      $display("Test N = %0d", n);
      tb_streamer.write_user_reg(sid_noc_block_keep_one_in_n,noc_block_keep_one_in_n.SR_N,n);
      tb_streamer.write_user_reg(sid_noc_block_keep_one_in_n,noc_block_keep_one_in_n.SR_VECTOR_MODE,0);
      fork
        begin
          // Send N packets, only one packet should come out
          for (int l = 0; l < n; l++) begin
            for (int i = 0; i < SPP; i++) begin
              tb_streamer.push_word(32'(l*SPP+i),(i == SPP-1));
            end
          end
        end
        begin
          logic [31:0] expected_value, received_value;
          logic last;
          for (int i = 0; i < SPP; i++) begin
            expected_value = 32'(n*(i+1)-1);
            tb_streamer.pull_word(received_value,last);
            $sformat(s, "N = %0d: Incorrect value received! Expected: %0d, Received: %0d", n, expected_value, received_value);
            `ASSERT_ERROR(received_value == expected_value, s);
            if (i == SPP-1) begin
              `ASSERT_ERROR(last == 1'b1, "Incorrect packet length! End of packet not asserted!");
            end else begin
              `ASSERT_ERROR(last == 1'b0, "Incorrect packet length! End of packet asserted early!");
            end
          end
        end
      join
    end
    `TEST_CASE_DONE(1);
    `TEST_BENCH_DONE;

  end
endmodule
