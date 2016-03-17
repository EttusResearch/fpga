//
// Copyright 2015 National Instruments
//

`timescale 1ns / 1ps

`define SIM_RUNTIME_US 1000
`define NS_PER_TICK 1
`define NUM_TEST_CASES 2

`include "sim_exec_report.vh"
`include "sim_rfnoc_lib.vh"

module noc_block_moving_avg_tb;
  `TEST_BENCH_INIT("noc_block_moving_avg_tb", `NUM_TEST_CASES, `NS_PER_TICK);
  localparam BUS_CLK_PERIOD = $ceil(1e9/166.67e6);
  localparam CE_CLK_PERIOD  = $ceil(1e9/200e6);
  localparam NUM_CE         = 1;
  `RFNOC_SIM_INIT(NUM_CE, BUS_CLK_PERIOD, CE_CLK_PERIOD);
  `RFNOC_ADD_BLOCK(noc_block_moving_avg, 0);

  localparam PACKET_SIZE = 16;
  localparam TEST_LENGTH = 1000;

  shortint iavg[$];
  shortint qavg[$];

  //----------------------------------------------------------------------------
  // Stimulus
  //----------------------------------------------------------------------------

  initial begin
    logic [63:0] header;
    static shortint ivalues[$] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
    static shortint qvalues[$] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
    int sent;

    while(bus_rst) @(posedge bus_clk);
    while(ce_rst) @(posedge ce_clk);

    repeat(10) @(posedge bus_clk);

    // Test bench -> Moving Average -> Test bench
    `RFNOC_CONNECT(noc_block_tb, noc_block_moving_avg, PACKET_SIZE*4);
    `RFNOC_CONNECT(noc_block_moving_avg, noc_block_tb, PACKET_SIZE*4);

    tb_cvita_ack.axis.tready = 1'b1;  // Drop all response packets

    // Setup registers
    header = flatten_chdr_no_ts('{pkt_type:CMD, has_time:0, eob:0, seqno:12'h0,
      length:8, src_sid:sid_noc_block_tb, dst_sid:sid_noc_block_moving_avg,
      timestamp:64'h0});

    tb_cvita_cmd.push_pkt({header, {int'(noc_block_moving_avg.SR_SUM_LEN), int'(10)}});
    tb_cvita_cmd.push_pkt({header, {int'(noc_block_moving_avg.SR_DIVISOR), int'(10)}});

    repeat (10) @(posedge bus_clk);

    // Setup destination
    tb_next_dst = sid_noc_block_moving_avg;

    sent = 0;
    for(int i = 0; i < TEST_LENGTH; ++i) begin
      shortint i, q;
      int isum, qsum;

      i = shortint'($random);
      q = shortint'($random);

      isum = 0;
      qsum = 0;

      ivalues.pop_front();
      ivalues.push_back(i);

      qvalues.pop_front();
      qvalues.push_back(q);

      foreach(ivalues[i])
        isum += ivalues[i];

      foreach(qvalues[i])
        qsum += qvalues[i];

      iavg.push_back(isum / 10);
      qavg.push_back(qsum / 10);

      tb_axis_data.push_word({i, q}, (sent == PACKET_SIZE - 1));
      if(sent == PACKET_SIZE - 1)
        sent = 0;
      else
        sent++;
    end

    #100000;
    $finish;
  end

  //----------------------------------------------------------------------------
  // Verification
  //----------------------------------------------------------------------------

  initial begin : tb_main
    `TEST_CASE_START("Wait for reset");
    while (bus_rst) @(posedge bus_clk);
    while (ce_rst) @(posedge ce_clk);
    `TEST_CASE_DONE(~bus_rst & ~ce_rst);

    `TEST_CASE_START("Check values");
    for(int i = 0; i < TEST_LENGTH - 1; ++i) begin
      shortint iref, qref, irec, qrec;
      logic eop;

      iref = iavg.pop_front();
      qref = qavg.pop_front();

      tb_axis_data.pull_word({irec, qrec}, eop);

      `ASSERT_ERROR(irec == iref, $sformatf("[Sample %0d] I average doesn't match! %d != %d", i, irec, iref));

      `ASSERT_ERROR(qrec == qref, $sformatf("[Sample %0d] Q average doesn't match! %d != %d", i, qrec, qref));
    end
    `TEST_CASE_DONE(1);
  end

endmodule
