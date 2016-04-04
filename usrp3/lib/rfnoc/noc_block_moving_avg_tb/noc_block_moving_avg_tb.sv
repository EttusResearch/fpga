//
// Copyright 2016 National Instruments
//

`timescale 1ns / 1ps
`define NS_PER_TICK 1
`define NUM_TEST_CASES 4

`include "sim_exec_report.vh"
`include "sim_rfnoc_lib.svh"

module noc_block_moving_avg_tb;
  `TEST_BENCH_INIT("noc_block_moving_avg_tb", `NUM_TEST_CASES, `NS_PER_TICK);
  localparam BUS_CLK_PERIOD = $ceil(1e9/166.67e6);
  localparam CE_CLK_PERIOD  = $ceil(1e9/200e6);
  localparam NUM_CE         = 1;
  localparam NUM_STREAMS    = 1;
  `RFNOC_SIM_INIT(NUM_CE, NUM_STREAMS, BUS_CLK_PERIOD, CE_CLK_PERIOD);
  `RFNOC_ADD_BLOCK(noc_block_moving_avg, 0);

  localparam SPP = 32;
  localparam MAX_SUM_LENGTH = SPP/2;

  /********************************************************
  ** Verification
  ********************************************************/
  initial begin : tb_main
    string s;
    shortint i_send[$], i_recv[$];
    shortint q_send[$], q_recv[$];
    shortint moving_avg_recv_i, moving_avg_recv_q;
    shortint moving_sum_i, moving_avg_i, moving_sum_q, moving_avg_q;
    logic [63:0] readback, recv_value;
    cvita_payload_t send_payload, recv_payload;
    cvita_metadata_t tx_md, rx_md;

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
    tb_streamer.read_reg(sid_noc_block_moving_avg, RB_NOC_ID, readback);
    $display("Read Moving Average NOC ID: %16x", readback);
    `ASSERT_ERROR(readback == noc_block_moving_avg.NOC_ID, "Incorrect NOC ID");
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 3 -- Connect RFNoC blocks
    ********************************************************/
    `TEST_CASE_START("Connect RFNoC blocks");
    `RFNOC_CONNECT(noc_block_tb,noc_block_moving_avg,SC16,SPP);
    `RFNOC_CONNECT(noc_block_moving_avg,noc_block_tb,SC16,SPP);
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 4 -- Test moving averages of various lengths
    ********************************************************/
    `TEST_CASE_START("Moving Averages");
    for (int n = 1; n <= MAX_SUM_LENGTH; n++) begin
      i_send.delete();
      q_send.delete();
      i_recv.delete();
      q_recv.delete();
      moving_sum_i = 0;
      moving_sum_q = 0;
      $display("Test moving average length %0d", n);
      tb_streamer.write_user_reg(sid_noc_block_moving_avg, noc_block_moving_avg.SR_SUM_LEN, n);
      tb_streamer.write_user_reg(sid_noc_block_moving_avg, noc_block_moving_avg.SR_DIVISOR, n);
      for (shortint k = 0; k < SPP; k++) begin
        i_send.push_back(k);
        q_send.push_back(-k);
      end
      send_payload.delete();
      for (int k = 0; k < SPP/2; k++) begin
        send_payload.push_back({i_send[2*k],q_send[2*k],i_send[2*k+1],q_send[2*k+1]});
      end
      tx_md.eob = 1;
      tb_streamer.send(send_payload,tx_md);
      tb_streamer.recv(recv_payload,rx_md);
      `ASSERT_ERROR(rx_md.eob == 1'b1, "EOB bit not set!");
      for (int k = 0; k < SPP/2; k++) begin
        recv_value = recv_payload[k];
        i_recv.push_back(recv_value[63:48]);
        i_recv.push_back(recv_value[31:16]);
        q_recv.push_back(recv_value[47:32]);
        q_recv.push_back(recv_value[15:0]);
      end
      for (int k = 0; k < SPP; k++) begin
        if (k < n) begin
          moving_sum_i = moving_sum_i + i_send[k];
          moving_sum_q = moving_sum_q + q_send[k];
        end else begin
          moving_sum_i = moving_sum_i + i_send[k] - i_send[k-n];
          moving_sum_q = moving_sum_q + q_send[k] - q_send[k-n];
        end
        // Same as round to nearest in axi_round
        moving_avg_i = shortint'($floor(real'(moving_sum_i)/n + 0.5));
        moving_avg_q = shortint'($floor(real'(moving_sum_q)/n + 0.5));
        moving_avg_recv_i = i_recv[k];
        moving_avg_recv_q = q_recv[k];
        $sformat(s, "Incorrect moving average on I! N: %0d, Expected %0d, Received: %0d", n, moving_avg_i, moving_avg_recv_i);
        `ASSERT_ERROR(moving_avg_i == moving_avg_recv_i, s);
        $sformat(s, "Incorrect moving average on Q! N: %0d, Expected %0d, Received: %0d", n, moving_avg_q, moving_avg_recv_q);
        `ASSERT_ERROR(moving_avg_q == moving_avg_recv_q, s);
      end
    end
    `TEST_CASE_DONE(1);

    `TEST_BENCH_DONE;
  end

endmodule
