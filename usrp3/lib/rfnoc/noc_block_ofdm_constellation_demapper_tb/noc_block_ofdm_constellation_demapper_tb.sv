//
// Copyright 2015 Ettus Research
//
`timescale 1ns/1ps
`define SIM_RUNTIME_US 1000
`define NS_PER_TICK 1
`define NUM_TEST_CASES 2

`include "sim_exec_report.vh"
`include "sim_rfnoc_lib.vh"

module noc_block_ofdm_constellation_demapper_tb();
  `TEST_BENCH_INIT("noc_block_ofdm_constellation_demapper_tb",`NUM_TEST_CASES,`NS_PER_TICK);
  `RFNOC_SIM_INIT(1,166.67,200);
  `RFNOC_ADD_BLOCK(noc_block_ofdm_constellation_demapper,0);
  defparam noc_block_ofdm_constellation_demapper.NUM_SUBCARRIERS      = 64;
  defparam noc_block_ofdm_constellation_demapper.EXCLUDE_SUBCARRIERS  = 64'b1111_1100_0001_0000_0000_0000_0100_0000_1000_0001_0000_0000_0000_0100_0001_1111;
  defparam noc_block_ofdm_constellation_demapper.MAX_MODULATION_ORDER = 6;

  localparam [31:0] OFDM_SYMBOL_SIZE = 64;
  localparam NUM_SYMBOLS = 20;

  cvita_pkt_t  pkt;
  logic [63:0] header;
  logic [15:0] real_val;
  logic [15:0] cplx_val;
  logic last;

  /********************************************************
  ** Verification
  ********************************************************/
  initial begin : tb_main
    `TEST_CASE_START("Wait for reset");
    while (bus_rst) @(posedge bus_clk);
    while (ce_rst) @(posedge ce_clk);
    `TEST_CASE_DONE(~bus_rst & ~ce_rst);
    `TEST_CASE_START("Receive & check data");
    for (int n = 0; n < NUM_SYMBOLS; n = n + 1) begin
      for (int k = 0; k < OFDM_SYMBOL_SIZE; k = k + 1) begin
        tb_axis_data.pull_word({real_val,cplx_val},last);
      end
    end
    `TEST_CASE_DONE(1);
  end

  /*********************************************************************
   ** Connect and setup RFNoC blocks 
   *********************************************************************/
  reg [15:0] symbol_i = 0, symbol_q = 0;
  initial begin
    while (bus_rst) @(posedge bus_clk);
    while (ce_rst) @(posedge ce_clk);

    repeat (10) @(posedge bus_clk);

    // Test bench -> OFDM Constellation Demapper -> Test bench
    `RFNOC_CONNECT(noc_block_tb,noc_block_ofdm_constellation_demapper,OFDM_SYMBOL_SIZE*4);
    `RFNOC_CONNECT(noc_block_ofdm_constellation_demapper,noc_block_tb,OFDM_SYMBOL_SIZE*4);

    tb_cvita_ack.axis.tready = 1'b1;  // Drop all response packets

    // Setup OFDM constellation demapper
    header = flatten_chdr_no_ts('{pkt_type:CMD, has_time:0, eob:0, seqno:12'h0, length:8, src_sid:sid_noc_block_tb, dst_sid:sid_noc_block_ofdm_constellation_demapper, timestamp:64'h0});
    tb_cvita_cmd.push_pkt({header, {noc_block_ofdm_constellation_demapper.SR_MODULATION_ORDER, 32'd6}}); // QAM-64
    tb_cvita_cmd.push_pkt({header, {noc_block_ofdm_constellation_demapper.SR_SCALING, 32'd0 + 2**14}}); // QAM64 scaling, 1x

    repeat (10) @(posedge bus_clk);

    // Send random, scaled symbols
    tb_next_dst = sid_noc_block_ofdm_constellation_demapper;
    forever begin
      for (int n = 0; n < NUM_SYMBOLS; n = n + 1) begin
        for (int i = 0; i < OFDM_SYMBOL_SIZE; i = i + 1) begin
          symbol_i <= $floor((2**15)*(7 - 2*($random % 7))/8);
          symbol_q <= $floor((2**15)*(7 - 2*($random % 7))/8);
          tb_axis_data.push_word({symbol_i,symbol_q},(i == OFDM_SYMBOL_SIZE-1));
        end
      end
    end

  end
endmodule
