//
// Copyright 2018 Ettus Research, a National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//

`timescale 1ns/1ps
`define NS_PER_TICK 1
`define NUM_TEST_CASES 6

`define SIM_TIMEOUT_US 1000 // 1ms

`include "sim_exec_report.vh"
`include "sim_clks_rsts.vh"
`include "sim_rfnoc_lib.svh"

module noc_block_null_source_sink_tb();
  `TEST_BENCH_INIT("noc_block_null_source_sink",`NUM_TEST_CASES,`NS_PER_TICK);
  localparam BUS_CLK_PERIOD = $ceil(1e9/166.67e6);
  localparam CE_CLK_PERIOD  = $ceil(1e9/200e6);
  localparam NUM_CE         = 1;  // Number of Computation Engines / User RFNoC blocks to simulate
  localparam NUM_STREAMS    = 2;  // Number of test bench streams
  `RFNOC_SIM_INIT(NUM_CE, NUM_STREAMS, BUS_CLK_PERIOD, CE_CLK_PERIOD);
  `RFNOC_ADD_BLOCK(noc_block_null_source_sink, 0);

  defparam noc_block_null_source_sink.EN_TRAFFIC_COUNTER = 1;

  localparam SPP = 64; // Samples per packet
  localparam NUM_PACKETS = 10;

  wire [7:0] SR_LINES_PER_PACKET       = noc_block_null_source_sink.SR_LINES_PER_PACKET;
  wire [7:0] SR_LINE_RATE              = noc_block_null_source_sink.SR_LINE_RATE;
  wire [7:0] SR_ENABLE_STREAM          = noc_block_null_source_sink.SR_ENABLE_STREAM;
  wire [7:0] SR_COUNTER_ENABLE         = noc_block_null_source_sink.tc.traffic_counter.SR_COUNTER_ENABLE;

  wire [7:0] RB_SIGNATURE              = noc_block_null_source_sink.tc.traffic_counter.RB_SIGNATURE;
  wire [7:0] RB_BUS_CLK_TICKS          = noc_block_null_source_sink.tc.traffic_counter.RB_BUS_CLK_TICKS;

  wire [7:0] RB_XBAR_TO_SHELL_XFER_CNT = noc_block_null_source_sink.tc.traffic_counter.RB_XBAR_TO_SHELL_XFER_CNT;
  wire [7:0] RB_XBAR_TO_SHELL_PKT_CNT  = noc_block_null_source_sink.tc.traffic_counter.RB_XBAR_TO_SHELL_PKT_CNT;

  wire [7:0] RB_SHELL_TO_XBAR_XFER_CNT = noc_block_null_source_sink.tc.traffic_counter.RB_SHELL_TO_XBAR_XFER_CNT;
  wire [7:0] RB_SHELL_TO_XBAR_PKT_CNT  = noc_block_null_source_sink.tc.traffic_counter.RB_SHELL_TO_XBAR_PKT_CNT;

  wire [7:0] RB_SHELL_TO_CE_XFER_CNT   = noc_block_null_source_sink.tc.traffic_counter.RB_SHELL_TO_CE_XFER_CNT;
  wire [7:0] RB_SHELL_TO_CE_PKT_CNT    = noc_block_null_source_sink.tc.traffic_counter.RB_SHELL_TO_CE_PKT_CNT;

  wire [7:0] RB_CE_TO_SHELL_XFER_CNT   = noc_block_null_source_sink.tc.traffic_counter.RB_CE_TO_SHELL_XFER_CNT;
  wire [7:0] RB_CE_TO_SHELL_PKT_CNT    = noc_block_null_source_sink.tc.traffic_counter.RB_CE_TO_SHELL_PKT_CNT;

  /********************************************************
   ** Verification
   ********************************************************/
  initial begin : tb_main
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
    tb_streamer.read_reg(sid_noc_block_null_source_sink, RB_NOC_ID, readback);
    $display("Read NOC ID: %16x", readback);
    `ASSERT_ERROR(readback == noc_block_null_source_sink.NOC_ID, "Incorrect NOC ID");
    `TEST_CASE_DONE(1);

    /********************************************************
     ** Test 3 -- Connect RFNoC blocks
     ********************************************************/
    `TEST_CASE_START("Connect RFNoC blocks");
    `RFNOC_CONNECT_BLOCK_PORT(noc_block_tb,0,noc_block_null_source_sink,0,SC16,SPP);
    `RFNOC_CONNECT_BLOCK_PORT(noc_block_null_source_sink,0,noc_block_tb,0,SC16,SPP);
    `TEST_CASE_DONE(1);

    /********************************************************
     ** Test 4 -- Count read/write register transactions
     ********************************************************/
    `TEST_CASE_START("Count read/write register transactions");
    begin
      logic [63:0] xbar_to_shell_xfer, xbar_to_shell_pkt;
      logic [63:0] shell_to_xbar_xfer, shell_to_xbar_pkt;
      logic [63:0] shell_to_ce_xfer, shell_to_ce_pkt;

      logic [63:0] ce_to_shell_xfer, ce_to_shell_pkt;

      // Enable counters and do some register reads and writes to create traffic
      tb_streamer.write_user_reg(sid_noc_block_null_source_sink, SR_COUNTER_ENABLE, 1);
      tb_streamer.write_user_reg(sid_noc_block_null_source_sink, SR_LINE_RATE, 0);
      tb_streamer.read_user_reg(sid_noc_block_null_source_sink, RB_SIGNATURE, readback);
      $display("Read traffic counter signature: %16x", readback);
      `ASSERT_ERROR(readback == 64'h712AFF1C00000000, "Traffic counter not enabled");
      tb_streamer.write_user_reg(sid_noc_block_null_source_sink, SR_COUNTER_ENABLE, 0);

      // Read traffic counters and check their values
      tb_streamer.read_user_reg(sid_noc_block_null_source_sink, RB_SHELL_TO_XBAR_XFER_CNT, shell_to_xbar_xfer);
      tb_streamer.read_user_reg(sid_noc_block_null_source_sink, RB_SHELL_TO_XBAR_PKT_CNT, shell_to_xbar_pkt);
      tb_streamer.read_user_reg(sid_noc_block_null_source_sink, RB_XBAR_TO_SHELL_XFER_CNT, xbar_to_shell_xfer);
      tb_streamer.read_user_reg(sid_noc_block_null_source_sink, RB_XBAR_TO_SHELL_PKT_CNT, xbar_to_shell_pkt);
      tb_streamer.read_user_reg(sid_noc_block_null_source_sink, RB_CE_TO_SHELL_XFER_CNT, ce_to_shell_xfer);
      tb_streamer.read_user_reg(sid_noc_block_null_source_sink, RB_CE_TO_SHELL_PKT_CNT, ce_to_shell_pkt);
      tb_streamer.read_user_reg(sid_noc_block_null_source_sink, RB_SHELL_TO_CE_XFER_CNT, shell_to_ce_xfer);
      tb_streamer.read_user_reg(sid_noc_block_null_source_sink, RB_SHELL_TO_CE_PKT_CNT, shell_to_ce_pkt);


      // Should count one packet for each write and two for each read
      `ASSERT_ERROR(xbar_to_shell_pkt == 4, "Unexpected tx packet count");
      `ASSERT_ERROR(shell_to_xbar_pkt == 4, "Unexpected rx packet count");

      // Each write should have a data item plus a header
      `ASSERT_ERROR(xbar_to_shell_xfer == 8, "Unexpected tx data count");
      `ASSERT_ERROR(shell_to_xbar_xfer == 8, "Unexpected rx data count");

      // No data in either direction for the ce
      `ASSERT_ERROR(shell_to_ce_xfer == 0, "Unexpected CE transfer count");
      `ASSERT_ERROR(ce_to_shell_xfer == 0, "Unexpected CE transfer count");
      `ASSERT_ERROR(shell_to_ce_pkt == 0, "Unexpected CE transfer count");
      `ASSERT_ERROR(ce_to_shell_pkt == 0, "Unexpected CE transfer count");
    end
    `TEST_CASE_DONE(1);

    /*******************************************************
     ** Test 5 -- Write data
     ********************************************************/
    `TEST_CASE_START("Write data");
    begin
      cvita_metadata_t tx_md;
      cvita_payload_t send_payload;
      logic [63:0] bus_ticks;
      logic [63:0] ce_to_shell_xfer, ce_to_shell_pkt;
      logic [63:0] shell_to_ce_xfer, shell_to_ce_pkt;
      logic [63:0] xbar_to_shell_xfer, xbar_to_shell_pkt;
      integer data_transfer_cnt;

      tb_streamer.write_user_reg(sid_noc_block_null_source_sink, SR_COUNTER_ENABLE, 1);

      for (int i = 0; i < SPP/2; i++) begin
        send_payload.push_back(64'(i));
      end
      for (int i = 0; i < NUM_PACKETS; i++) begin
        tb_streamer.send(send_payload,tx_md);
      end

      tb_streamer.read_user_reg(sid_noc_block_null_source_sink, RB_SHELL_TO_CE_PKT_CNT, shell_to_ce_pkt);
      while (shell_to_ce_pkt < NUM_PACKETS) begin
        tb_streamer.read_user_reg(sid_noc_block_null_source_sink, RB_SHELL_TO_CE_PKT_CNT, shell_to_ce_pkt);
      end

      tb_streamer.write_user_reg(sid_noc_block_null_source_sink, SR_COUNTER_ENABLE, 0);

      tb_streamer.read_user_reg(sid_noc_block_null_source_sink, RB_BUS_CLK_TICKS, bus_ticks);
      tb_streamer.read_user_reg(sid_noc_block_null_source_sink, RB_CE_TO_SHELL_PKT_CNT, ce_to_shell_pkt);
      tb_streamer.read_user_reg(sid_noc_block_null_source_sink, RB_CE_TO_SHELL_XFER_CNT, ce_to_shell_xfer);
      tb_streamer.read_user_reg(sid_noc_block_null_source_sink, RB_SHELL_TO_CE_PKT_CNT, shell_to_ce_pkt);
      tb_streamer.read_user_reg(sid_noc_block_null_source_sink, RB_SHELL_TO_CE_XFER_CNT, shell_to_ce_xfer);
      tb_streamer.read_user_reg(sid_noc_block_null_source_sink, RB_XBAR_TO_SHELL_PKT_CNT, xbar_to_shell_pkt);
      tb_streamer.read_user_reg(sid_noc_block_null_source_sink, RB_XBAR_TO_SHELL_XFER_CNT, xbar_to_shell_xfer);

      $display("CE transferred %0d packets, %0d samples", shell_to_ce_pkt, (shell_to_ce_xfer-shell_to_ce_pkt)*2);

      // Check data count, should match number sent
      data_transfer_cnt = NUM_PACKETS * SPP/2 + NUM_PACKETS; // number of lines + header
      `ASSERT_ERROR(shell_to_ce_xfer == data_transfer_cnt, "Incorrect shell to ce count");
      `ASSERT_ERROR(shell_to_ce_pkt == NUM_PACKETS, "Incorrect shell to ce count");

      `ASSERT_ERROR(xbar_to_shell_pkt >= NUM_PACKETS, "Shell packet count is too small");
      `ASSERT_ERROR(xbar_to_shell_xfer >= data_transfer_cnt, "Shell data count is too small");

      // No data should go from CE to shell
      `ASSERT_ERROR(ce_to_shell_pkt == 0, "Unexpected packet from ce to shell");
      `ASSERT_ERROR(ce_to_shell_xfer == 0, "Unexpected data from ce to shell");
    end
    `TEST_CASE_DONE(1);

    /*******************************************************
     ** Test 6 -- Read data
     ********************************************************/
    `TEST_CASE_START("Read data");
    begin
      cvita_metadata_t rx_md;
      cvita_payload_t recv_payload;
      logic [63:0] ce_to_shell_xfer, ce_to_shell_pkt;
      logic [63:0] shell_to_ce_xfer, shell_to_ce_pkt;
      logic [63:0] shell_to_xbar_xfer, shell_to_xbar_pkt;
      integer min_data_transfer_cnt, min_packet_cnt;

      tb_streamer.write_user_reg(sid_noc_block_null_source_sink, SR_LINE_RATE, 0);
      tb_streamer.write_user_reg(sid_noc_block_null_source_sink, SR_LINES_PER_PACKET, SPP/2);
      tb_streamer.write_user_reg(sid_noc_block_null_source_sink, SR_ENABLE_STREAM, 1);
      tb_streamer.write_user_reg(sid_noc_block_null_source_sink, SR_COUNTER_ENABLE, 1);

      for (int i = 0; i < NUM_PACKETS; i++) begin
        tb_streamer.recv(recv_payload, rx_md);
      end

      tb_streamer.write_user_reg(sid_noc_block_null_source_sink, SR_COUNTER_ENABLE, 0);
      tb_streamer.write_user_reg(sid_noc_block_null_source_sink, SR_ENABLE_STREAM, 0);

      tb_streamer.read_user_reg(sid_noc_block_null_source_sink, RB_CE_TO_SHELL_PKT_CNT, ce_to_shell_pkt);
      tb_streamer.read_user_reg(sid_noc_block_null_source_sink, RB_CE_TO_SHELL_XFER_CNT, ce_to_shell_xfer);
      tb_streamer.read_user_reg(sid_noc_block_null_source_sink, RB_SHELL_TO_CE_PKT_CNT, shell_to_ce_pkt);
      tb_streamer.read_user_reg(sid_noc_block_null_source_sink, RB_SHELL_TO_CE_XFER_CNT, shell_to_ce_xfer);
      tb_streamer.read_user_reg(sid_noc_block_null_source_sink, RB_SHELL_TO_XBAR_PKT_CNT, shell_to_xbar_pkt);
      tb_streamer.read_user_reg(sid_noc_block_null_source_sink, RB_SHELL_TO_XBAR_XFER_CNT, shell_to_xbar_xfer);

      $display("CE transferred %0d packets, %0d samples", ce_to_shell_pkt, (ce_to_shell_xfer-ce_to_shell_pkt)*2);

      // Receive counters are harder to calculate exactly because of buffering,
      // so asserts here are looser than when writing data.

      // Both shell and ce should have transferred at least NUM_PACKETS
      min_data_transfer_cnt = NUM_PACKETS * SPP/2 + NUM_PACKETS; // number of lines + header
      `ASSERT_ERROR(ce_to_shell_pkt >= NUM_PACKETS, "CE packet count is too small");
      `ASSERT_ERROR(shell_to_xbar_pkt >= NUM_PACKETS, "Shell packet count is too small");
      `ASSERT_ERROR(ce_to_shell_xfer >= min_data_transfer_cnt, "CE data count is too small");
      `ASSERT_ERROR(shell_to_xbar_xfer >= min_data_transfer_cnt, "Shell data count is too small");

      // For ce, packet count * SPP/2 + packet count should be < data count
      // since each packet should contain SPP/2 data transfers plus a header.
      min_packet_cnt = ce_to_shell_pkt*SPP/2+ce_to_shell_pkt;
      `ASSERT_ERROR(ce_to_shell_xfer >= min_packet_cnt, "CE xfer count is too small");

      // No data should go from shell to CE
      `ASSERT_ERROR(shell_to_ce_pkt == 0, "Unexpected packet from shell to ce");
      `ASSERT_ERROR(shell_to_ce_xfer == 0, "Unexpected data from shell to ce");
    end
    `TEST_CASE_DONE(1);
    `TEST_BENCH_DONE;
    `TEST_BENCH_DONE;
  end
endmodule
