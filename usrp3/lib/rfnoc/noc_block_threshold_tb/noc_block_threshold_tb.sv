`timescale 1ns/1ps
`define NS_PER_TICK 1
`define NUM_TEST_CASES 5

`include "sim_exec_report.vh"
`include "sim_clks_rsts.vh"
`include "sim_rfnoc_lib.svh"

module noc_block_threshold_tb();
  `TEST_BENCH_INIT("noc_block_threshold",`NUM_TEST_CASES,`NS_PER_TICK);
  localparam BUS_CLK_PERIOD = $ceil(1e9/166.67e6);
  localparam CE_CLK_PERIOD  = $ceil(1e9/200e6);
  localparam NUM_CE         = 1;  // Number of Computation Engines / User RFNoC blocks to simulate
  localparam NUM_STREAMS    = 1;  // Number of test bench streams
  `RFNOC_SIM_INIT(NUM_CE, NUM_STREAMS, BUS_CLK_PERIOD, CE_CLK_PERIOD);
  `RFNOC_ADD_BLOCK(noc_block_threshold, 0);

  localparam SPP = 16; // Samples per packet

  /********************************************************
  ** Verification
  ********************************************************/
  initial begin : tb_main
    string s;
    logic [31:0] threshold;
    logic [15:0] num_samples;
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
    tb_streamer.read_reg(sid_noc_block_threshold, RB_NOC_ID, readback);
    $display("Read threshold NOC ID: %16x", readback);
    `ASSERT_ERROR(readback == noc_block_threshold.NOC_ID, "Incorrect NOC ID");
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 3 -- Connect RFNoC blocks
    ********************************************************/
    `TEST_CASE_START("Connect RFNoC blocks");
    `RFNOC_CONNECT(noc_block_tb,noc_block_threshold,SC16,SPP);
    `RFNOC_CONNECT(noc_block_threshold,noc_block_tb,SC16,SPP);
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 4 -- Write / readback threshold & num_samples
    ********************************************************/
    `TEST_CASE_START("Write / readback user registers");
    threshold = 10008;
    tb_streamer.write_user_reg(sid_noc_block_threshold, noc_block_threshold.SR_THRESHOLD, threshold);
    tb_streamer.read_user_reg(sid_noc_block_threshold, noc_block_threshold.RB_THRESHOLD, readback);
    $sformat(s, "threshold incorrect readback! Expected: %0d, Actual %0d", readback[31:0] == threshold);
    `ASSERT_ERROR(readback[31:0] == threshold, s);
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 5 -- Thresholding
    ** - Send a triangle wave across several packets
    ** - Check VITA time is correct
    ********************************************************/
    `TEST_CASE_START("Test thresholding");
    fork
      begin
        cvita_payload_t send_payload;
        cvita_metadata_t md;
        md.has_time  = 1'b1;
        md.timestamp = 64'd0;
        // Generate triangle wave across 5 packets
        // Pkt 1: Entire pkt below threshold
        //     2: Crosses above threshold midway in pkt
        //     3: Entire pkt above threshold
        //     4: Cross below threshold midway in pkt
        //     5: Entire pkt below threshold
        for (int i = 0; i < 5*SPP; i=i+2) begin
          // Up
          if (i < 5*SPP/2) begin
            send_payload.push_back({32'(10000 - SPP + i),32'(10000 - SPP + i+1)});
          // Down
          end else begin
            send_payload.push_back({32'(10000 + 4*SPP - i),32'(10000 + 4*SPP - i-1)});
          end
        end
        // Send packets
        tb_streamer.send(send_payload);
      end
      begin
        cvita_payload_t recv_payload;
        cvita_metadata_t md;
        // We expect to receive 3 packets, see generating code above
        for (int i = 0; i < 3; i++) begin
          tb_streamer.recv(recv_payload,md);
          for (int k = 0; k < recv_payload.size(); k++) begin
            $sformat(s, "Value less than threshold! Threshold: %0d, Received: %0d", threshold, recv_payload[k][63:32]);
            `ASSERT_ERROR(recv_payload[k] > threshold, s);
            $sformat(s, "Value less than threshold! Threshold: %0d, Received: %0d", threshold, recv_payload[k][31:0]);
            `ASSERT_ERROR(recv_payload[k] > threshold, s);
          end
        end
      end
    join
    `TEST_CASE_DONE(1);
    `TEST_BENCH_DONE;

  end
endmodule
