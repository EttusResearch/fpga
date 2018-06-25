//
// Copyright 2015 Ettus Research LLC
// Copyright 2016 Ettus Research, a National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//

`timescale 1ns/1ps
`define SIM_RUNTIME_US 1000
`define NS_PER_TICK 1
`define NUM_TEST_CASES 2

`include "sim_exec_report.vh"
`include "sim_rfnoc_lib.svh"

module noc_block_conv_encoder_qpsk_tb();
  `TEST_BENCH_INIT("noc_block_conv_encoder_qpsk_tb",`NUM_TEST_CASES,`NS_PER_TICK);
  `RFNOC_SIM_INIT(1,1,50,56);
  `RFNOC_ADD_BLOCK(noc_block_conv_encoder_qpsk,0);

  // Set Convolutional Encoder parameters
  /* TODO: Test none-FIXED configurations
  defparam noc_block_conv_encoder_qpsk.FIXED_K = 0;
  defparam noc_block_conv_encoder_qpsk.FIXED_G_UPPER = 0;
  defparam noc_block_conv_encoder_qpsk.FIXED_G_LOWER = 0;
  defparam noc_block_conv_encoder_qpsk.FIXED_PUNCTURE_CODE_RATE = 0;
  defparam noc_block_conv_encoder_qpsk.FIXED_PUNCTURE_VECTOR = 0;
  defparam noc_block_conv_encoder_qpsk.FIXED_BITS_PER_SYMBOL = 2;
  defparam noc_block_conv_encoder_qpsk.MAX_K = 7;
  defparam noc_block_conv_encoder_qpsk.MAX_BITS_PER_SYMBOL = 2;
  defparam noc_block_conv_encoder_qpsk.MAX_PUNCTURE_CODE_RATE = 7;
  */

  // FIR Filter settings
  wire [31:0] rrc_filter_taps [40:0] = {-1368,17276,-20246,4310,25864,-32840,2186,31466,-49104,23056,
                                        62900,-97474,17128,80252,-213396,214748,478872,-1133180,-710020,5095420,
                                        9185516,5095420,-710020,-1133180,478872,214748,-213396,80252,17128,-97474,
                                        62900,23056,-49104,31466,2186,-32840,25864,4310,-20246,17276,-1368};

  localparam PKT_SIZE = 1024; // Bytes

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

    // TODO: Fill out
    `TEST_CASE_START("Check encoder output");
      // Test bench -> Conv Encoder -> Test bench
      `RFNOC_CONNECT(noc_block_tb,noc_block_conv_encoder_qpsk,SC16,PKT_SIZE);
      `RFNOC_CONNECT(noc_block_conv_encoder_qpsk,noc_block_tb,SC16,PKT_SIZE);

      // Setup QPSK constellation
      tb_streamer.write_reg(sid_noc_block_conv_encoder_qpsk, noc_block_conv_encoder_qpsk.SR_SYMBOL_LUT_ADDR, {30'd0, 2'b00});
      tb_streamer.write_reg(sid_noc_block_conv_encoder_qpsk, noc_block_conv_encoder_qpsk.SR_SYMBOL_LUT_DATA, {-16'sd32767,-16'sd32767});
      tb_streamer.write_reg(sid_noc_block_conv_encoder_qpsk, noc_block_conv_encoder_qpsk.SR_SYMBOL_LUT_ADDR, {30'd0, 2'b01});
      tb_streamer.write_reg(sid_noc_block_conv_encoder_qpsk, noc_block_conv_encoder_qpsk.SR_SYMBOL_LUT_DATA, {-16'sd32767,+16'sd32767});
      tb_streamer.write_reg(sid_noc_block_conv_encoder_qpsk, noc_block_conv_encoder_qpsk.SR_SYMBOL_LUT_ADDR, {30'd0, 2'b10});
      tb_streamer.write_reg(sid_noc_block_conv_encoder_qpsk, noc_block_conv_encoder_qpsk.SR_SYMBOL_LUT_DATA, {+16'sd32767,-16'sd32767});
      tb_streamer.write_reg(sid_noc_block_conv_encoder_qpsk, noc_block_conv_encoder_qpsk.SR_SYMBOL_LUT_ADDR, {30'd0, 2'b11});
      tb_streamer.write_reg(sid_noc_block_conv_encoder_qpsk, noc_block_conv_encoder_qpsk.SR_SYMBOL_LUT_DATA, {+16'sd32767,+16'sd32767});
  
      repeat (10) @(posedge bus_clk);
      fork 
        begin
          for (int i = 0; i < (PKT_SIZE/8); i = i + 1) begin
            tb_streamer.push_word({32'b1111_1111_1111_1111_0101_0101_0101_0101},0);
            tb_streamer.push_word({32'b0000_0000_0000_0000_1010_1010_1010_1010},(i == (PKT_SIZE/8)-1)); // Assert tlast on final word
          end
        end
        begin
          for (int i = 0; i < (PKT_SIZE/8); i = i + 1) begin
            tb_streamer.pull_word({real_val,cplx_val},last);
            tb_streamer.pull_word({real_val,cplx_val},last);
          end
        end
      join
    `TEST_CASE_DONE(1);
    
    `TEST_BENCH_DONE;
  end

endmodule
