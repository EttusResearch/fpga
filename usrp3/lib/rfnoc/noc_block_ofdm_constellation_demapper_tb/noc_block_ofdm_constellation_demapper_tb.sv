//
// Copyright 2015 Ettus Research
//
`timescale 1ns/1ps
`define SIM_RUNTIME_US 100
`define NS_PER_TICK 1
`define NUM_TEST_CASES 2

`include "sim_exec_report.vh"
`include "sim_rfnoc_lib.svh"

module noc_block_ofdm_constellation_demapper_tb();
  `TEST_BENCH_INIT("noc_block_ofdm_constellation_demapper_tb",`NUM_TEST_CASES,`NS_PER_TICK);
  `RFNOC_SIM_INIT(1,1,166.67,200);
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
  reg [15:0] symbol_i = 0, symbol_q = 0;
  initial begin : tb_main
    `TEST_CASE_START("Wait for reset");
      while (bus_rst) @(posedge bus_clk);
      while (ce_rst) @(posedge ce_clk);
    `TEST_CASE_DONE(~bus_rst & ~ce_rst);

    `TEST_CASE_START("Receive & check data");
      // Test bench -> OFDM Constellation Demapper -> Test bench
      `RFNOC_CONNECT(noc_block_tb,noc_block_ofdm_constellation_demapper,SC16,OFDM_SYMBOL_SIZE*4);
      `RFNOC_CONNECT(noc_block_ofdm_constellation_demapper,noc_block_tb,SC16,OFDM_SYMBOL_SIZE*4);
  
      // Setup OFDM constellation demapper
      $display("Setup noc_block_ofdm_constellation_demapper");
      tb_streamer.write_reg(sid_noc_block_ofdm_constellation_demapper, noc_block_ofdm_constellation_demapper.SR_MODULATION_ORDER, 32'd6); // QAM-64
      tb_streamer.write_reg(sid_noc_block_ofdm_constellation_demapper, noc_block_ofdm_constellation_demapper.SR_SCALING, 32'd0 + 2**14); // QAM64 scaling, 1x
  
      repeat (10) @(posedge bus_clk);

      $display("Send samples");
      fork 
        for (int n = 0; n < NUM_SYMBOLS; n = n + 1) begin
          for (int i = 0; i < OFDM_SYMBOL_SIZE; i = i + 1) begin
            symbol_i <= $floor((2**15)*(7 - 2*($random % 7))/8);
            symbol_q <= $floor((2**15)*(7 - 2*($random % 7))/8);
            tb_streamer.push_word({symbol_i,symbol_q},(i == OFDM_SYMBOL_SIZE-1));
          end
        end
        for (int n = 0; n < 2; n = n + 1) begin
          cvita_payload_t recv_payload;
          cvita_metadata_t md;
          tb_streamer.recv(recv_payload, md);
          //TODO: Add self-checking code here
        end
      join
    `TEST_CASE_DONE(1);

    `TEST_BENCH_DONE;
  end

endmodule
