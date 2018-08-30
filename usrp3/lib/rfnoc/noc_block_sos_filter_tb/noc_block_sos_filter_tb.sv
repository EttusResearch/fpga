//
// Copyright 2014 Ettus Research LLC
// Copyright 2016-2018 Ettus Research, a National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//

`timescale 1ns/1ps
`define NS_PER_TICK 1
`define NUM_TEST_CASES 11

`include "sim_exec_report.vh"
`include "sim_clks_rsts.vh"
`include "sim_rfnoc_lib.svh"

module noc_block_sos_filter_tb();
  `TEST_BENCH_INIT("noc_block_sos_filter",`NUM_TEST_CASES,`NS_PER_TICK);
  localparam BUS_CLK_PERIOD = $ceil(1e9/166.67e6);
  localparam CE_CLK_PERIOD  = $ceil(1e9/200e6);
  localparam NUM_CE         = 1;  // Number of Computation Engines / User RFNoC blocks to simulate
  localparam NUM_STREAMS    = 1;  // Number of test bench streams
  `RFNOC_SIM_INIT(NUM_CE, NUM_STREAMS, BUS_CLK_PERIOD, CE_CLK_PERIOD);
  `RFNOC_ADD_BLOCK(noc_block_sos_filter, 0);
  defparam noc_block_sos_filter.NUM_SOS = 2;

  localparam SPP         = 64; // Samples per packet
  localparam NTAPS       = 1024;
  localparam real ERROR  = (2.0 ** -12);  // Target 72dB of dynamic range

  // Types
  typedef struct {
    real b0 = 1.0;
    real b1 = 0.0;
    real b2 = 0.0;
    real a1 = 0.0;
    real a2 = 0.0;
  } filt_coeff_t;

  real in_i[], in_q[], out_i[], out_q[];
  filt_coeff_t sos0, sos1;

  // Tasks and functions
  function [15:0] sr_addr;
    input [7:0] sr;
    input [7:0] inst;
  begin
    sr_addr =  noc_block_sos_filter.SR_COEFF_BASE + 
               (noc_block_sos_filter.SR_COEFF_REGS*inst) + 
               sr;
  end endfunction

  function logic [15:0] real2fxp;
    input real x;
  begin
    real2fxp = int'($floor(x*(2**15-1)));
  end endfunction

  function real fxp2real;
    input logic [15:0] x;
  begin
    fxp2real = real'($signed(x))/(2**15-1);
  end endfunction

  function real absval;
    input real x;
  begin
    absval = x > 0.0 ? x : -x;
  end endfunction

  // Generate test data
  task automatic gen_test_wfm (
    input integer ntaps,
    output real wfm_i[],
    output real wfm_q[]);
  begin
    for (int i = 0; i < ntaps; i=i+1) begin
      if (i < ntaps/4) begin
        // Impulse
        wfm_i[i] = (i == 0) ?  1.0 : 0.0;
        wfm_q[i] = (i == 0) ? -1.0 : 0.0;
      end else if (i < ntaps/2) begin
        // Step
        wfm_i[i] =  1.0;
        wfm_q[i] = -1.0;
      end else if (i < 3*ntaps/4) begin
        // Quarter rate complex sine
        wfm_i[i] = (i % 4 == 0) ?  1.0 : ((i % 4 == 2) ? -1.0 : 0.0);
        wfm_q[i] = (i % 4 == 1) ?  1.0 : ((i % 4 == 3) ? -1.0 : 0.0);
      end else begin
        // Quarter rate real sine
        wfm_i[i] = (i % 4 == 1) ?  1.0 : ((i % 4 == 3) ? -1.0 : 0.0);
        wfm_q[i] = 0.0;
      end
    end
  end endtask

  // Golden filter model
  task automatic sos_filter (
    input filt_coeff_t coeff,
    input real in[],
    output real out[]);
  begin
    out = new[in.size()];
    for (int i = 0; i < in.size(); i=i+1) begin
      real x0 = in[i];
      real x1 = i >= 1 ? in[i-1] : 0.0; 
      real x2 = i >= 2 ? in[i-2] : 0.0;
      real y1 = i >= 1 ? out[i-1] : 0.0; 
      real y2 = i >= 2 ? out[i-2] : 0.0; 
      out[i] = y1*coeff.a1 + y2*coeff.a2 +
        x0*coeff.b0 + x1*coeff.b1 + x2*coeff.b2;
      `ASSERT_FATAL(absval(out[i]) <= 1.0,
        "Assertion (this is a TB bug). Expected value for filtered data falls outside FXP range.");
    end
  end endtask

  /********************************************************
  ** Verification
  ********************************************************/
  initial begin : tb_main
    string s;
    logic [63:0] readback;

    `TEST_CASE_START("Wait for Reset");
    while (bus_rst) @(posedge bus_clk);
    while (ce_rst) @(posedge ce_clk);
    `TEST_CASE_DONE(~bus_rst & ~ce_rst);

    `TEST_CASE_START("Check NoC ID and Filter Info");
    // Read NOC IDs
    tb_streamer.read_reg(sid_noc_block_sos_filter, RB_NOC_ID, readback);
    $display("Read Vector IIR NOC ID: %16x", readback);
    `ASSERT_ERROR(readback == noc_block_sos_filter.NOC_ID, "Incorrect NOC ID");
    // Read filter info
    tb_streamer.read_user_reg(sid_noc_block_sos_filter, noc_block_sos_filter.RB_FILTER_INFO, readback);
    `ASSERT_ERROR(readback == {32'h0, 8'd16, 8'd16, 8'd2, 8'd0}, "Incorrect filter info");
    `TEST_CASE_DONE(1);

    `TEST_CASE_START("Connect RFNoC blocks");
    `RFNOC_CONNECT(noc_block_tb,noc_block_sos_filter,SC16,SPP);
    `RFNOC_CONNECT(noc_block_sos_filter,noc_block_tb,SC16,SPP);
    `TEST_CASE_DONE(1);

    `TEST_CASE_START("Configure Filter: Simple 1-tap FF and FB");
    sos0.b0 = 0.5;
    sos0.b1 = 0.0;
    sos0.b2 = 0.0;
    sos0.a1 = 0.5;
    sos0.a2 = 0.0;
    tb_streamer.write_user_reg(sid_noc_block_sos_filter, sr_addr(noc_block_sos_filter.COEFF_B0_OFFSET, 0), real2fxp(sos0.b0));
    tb_streamer.write_user_reg(sid_noc_block_sos_filter, sr_addr(noc_block_sos_filter.COEFF_B1_OFFSET, 0), real2fxp(sos0.b1));
    tb_streamer.write_user_reg(sid_noc_block_sos_filter, sr_addr(noc_block_sos_filter.COEFF_B2_OFFSET, 0), real2fxp(sos0.b2));
    tb_streamer.write_user_reg(sid_noc_block_sos_filter, sr_addr(noc_block_sos_filter.COEFF_A1_OFFSET, 0), real2fxp(sos0.a1));
    tb_streamer.write_user_reg(sid_noc_block_sos_filter, sr_addr(noc_block_sos_filter.COEFF_A2_OFFSET, 0), real2fxp(sos0.a2));

    sos1.b0 = 1.0;
    sos1.b1 = 0.0;
    sos1.b2 = 0.0;
    sos1.a1 = 0.0;
    sos1.a2 = 0.0;
    tb_streamer.write_user_reg(sid_noc_block_sos_filter, sr_addr(noc_block_sos_filter.COEFF_B0_OFFSET, 1), real2fxp(sos1.b0));
    tb_streamer.write_user_reg(sid_noc_block_sos_filter, sr_addr(noc_block_sos_filter.COEFF_B1_OFFSET, 1), real2fxp(sos1.b1));
    tb_streamer.write_user_reg(sid_noc_block_sos_filter, sr_addr(noc_block_sos_filter.COEFF_B2_OFFSET, 1), real2fxp(sos1.b2));
    tb_streamer.write_user_reg(sid_noc_block_sos_filter, sr_addr(noc_block_sos_filter.COEFF_A1_OFFSET, 1), real2fxp(sos1.a1));
    tb_streamer.write_user_reg(sid_noc_block_sos_filter, sr_addr(noc_block_sos_filter.COEFF_A2_OFFSET, 1), real2fxp(sos1.a2));
    `TEST_CASE_DONE(1);

    `TEST_CASE_START("Check impulse and step response");
    // Generate test and golden output vector 
    in_i = new[NTAPS];
    in_q = new[NTAPS];
    gen_test_wfm(NTAPS, in_i, in_q);
    sos_filter(sos0, in_i, out_i);
    sos_filter(sos0, in_q, out_q);
    // Input/output process
    fork
      begin
        for (int n = 0; n < NTAPS; n++) begin
          tb_streamer.push_word({real2fxp(in_i[n]), real2fxp(in_q[n])}, (n % SPP == SPP-1));
        end
      end
      begin
        logic [31:0] recv_word;
        real recv_i, recv_q;
        logic last;
        for (int n = 0; n < NTAPS; n++) begin
          tb_streamer.pull_word(recv_word, last);
          recv_i = fxp2real(recv_word[31:16]);
          recv_q = fxp2real(recv_word[15:0]);
          // $display("Output: %f + %fj (expected %f + %fj)", recv_i, recv_q, out_i[n], out_q[n]);
          `ASSERT_ERROR(absval(recv_i - out_i[n]) < ERROR, "Incorrect I value");
          `ASSERT_ERROR(absval(recv_q - out_q[n]) < ERROR, "Incorrect Q value");
          `ASSERT_FATAL((n % SPP != SPP-1) == (last == 1'b0), "Detected early tlast!");
          `ASSERT_FATAL((n % SPP == SPP-1) == (last == 1'b1), "Detected late tlast!")
        end
      end
    join
    `TEST_CASE_DONE(1);

    `TEST_CASE_START("Configure Filter: Multi-tap FF and FB (second bank)");
    sos0.b0 = 1.0;
    sos0.b1 = 0.0;
    sos0.b2 = 0.0;
    sos0.a1 = 0.0;
    sos0.a2 = 0.0;
    tb_streamer.write_user_reg(sid_noc_block_sos_filter, sr_addr(noc_block_sos_filter.COEFF_B0_OFFSET, 0), real2fxp(sos0.b0));
    tb_streamer.write_user_reg(sid_noc_block_sos_filter, sr_addr(noc_block_sos_filter.COEFF_B1_OFFSET, 0), real2fxp(sos0.b1));
    tb_streamer.write_user_reg(sid_noc_block_sos_filter, sr_addr(noc_block_sos_filter.COEFF_B2_OFFSET, 0), real2fxp(sos0.b2));
    tb_streamer.write_user_reg(sid_noc_block_sos_filter, sr_addr(noc_block_sos_filter.COEFF_A1_OFFSET, 0), real2fxp(sos0.a1));
    tb_streamer.write_user_reg(sid_noc_block_sos_filter, sr_addr(noc_block_sos_filter.COEFF_A2_OFFSET, 0), real2fxp(sos0.a2));

    sos1.b0 = 0.2;
    sos1.b1 = 0.2;
    sos1.b2 = 0.2;
    sos1.a1 = -0.1;
    sos1.a2 = 0.3;
    tb_streamer.write_user_reg(sid_noc_block_sos_filter, sr_addr(noc_block_sos_filter.COEFF_B0_OFFSET, 1), real2fxp(sos1.b0));
    tb_streamer.write_user_reg(sid_noc_block_sos_filter, sr_addr(noc_block_sos_filter.COEFF_B1_OFFSET, 1), real2fxp(sos1.b1));
    tb_streamer.write_user_reg(sid_noc_block_sos_filter, sr_addr(noc_block_sos_filter.COEFF_B2_OFFSET, 1), real2fxp(sos1.b2));
    tb_streamer.write_user_reg(sid_noc_block_sos_filter, sr_addr(noc_block_sos_filter.COEFF_A1_OFFSET, 1), real2fxp(sos1.a1));
    tb_streamer.write_user_reg(sid_noc_block_sos_filter, sr_addr(noc_block_sos_filter.COEFF_A2_OFFSET, 1), real2fxp(sos1.a2));
    `TEST_CASE_DONE(1);

    `TEST_CASE_START("Check impulse and step response");
    // Generate test and golden output vector 
    in_i = new[NTAPS];
    in_q = new[NTAPS];
    gen_test_wfm(NTAPS, in_i, in_q);
    sos_filter(sos1, in_i, out_i);
    sos_filter(sos1, in_q, out_q);
    // Input/output process
    fork
      begin
        for (int n = 0; n < NTAPS; n++) begin
          tb_streamer.push_word({real2fxp(in_i[n]), real2fxp(in_q[n])}, (n % SPP == SPP-1));
        end
      end
      begin
        logic [31:0] recv_word;
        real recv_i, recv_q;
        logic last;
        for (int n = 0; n < NTAPS; n++) begin
          tb_streamer.pull_word(recv_word, last);
          recv_i = fxp2real(recv_word[31:16]);
          recv_q = fxp2real(recv_word[15:0]);
          //$display("Output: %f + %fj (expected %f + %fj)", recv_i, recv_q, out_i[n], out_q[n]);
          `ASSERT_ERROR(absval(recv_i - out_i[n]) < ERROR, "Incorrect I value");
          `ASSERT_ERROR(absval(recv_q - out_q[n]) < ERROR, "Incorrect Q value");
          `ASSERT_FATAL((n % SPP != SPP-1) == (last == 1'b0), "Detected early tlast!");
          `ASSERT_FATAL((n % SPP == SPP-1) == (last == 1'b1), "Detected late tlast!")
        end
      end
    join
    `TEST_CASE_DONE(1);

    sos1.b0 = 1.0;
    sos1.b1 = 0.0;
    sos1.b2 = 0.0;
    sos1.a1 = 0.0;
    sos1.a2 = 0.0;
    tb_streamer.write_user_reg(sid_noc_block_sos_filter, sr_addr(noc_block_sos_filter.COEFF_B0_OFFSET, 1), real2fxp(sos1.b0));
    tb_streamer.write_user_reg(sid_noc_block_sos_filter, sr_addr(noc_block_sos_filter.COEFF_B1_OFFSET, 1), real2fxp(sos1.b1));
    tb_streamer.write_user_reg(sid_noc_block_sos_filter, sr_addr(noc_block_sos_filter.COEFF_B2_OFFSET, 1), real2fxp(sos1.b2));
    tb_streamer.write_user_reg(sid_noc_block_sos_filter, sr_addr(noc_block_sos_filter.COEFF_A1_OFFSET, 1), real2fxp(sos1.a1));
    tb_streamer.write_user_reg(sid_noc_block_sos_filter, sr_addr(noc_block_sos_filter.COEFF_A2_OFFSET, 1), real2fxp(sos1.a2));

    `TEST_CASE_START("Configure Filter: Lowpass Example");
    sos0.b0 = 0.18750000;
    sos0.b1 = 0.37500000;
    sos0.b2 = 0.18750000;
    sos0.a1 = 0.00000000;
    sos0.a2 = -0.25000000;
    tb_streamer.write_user_reg(sid_noc_block_sos_filter, sr_addr(noc_block_sos_filter.COEFF_B0_OFFSET, 0), real2fxp(sos0.b0));
    tb_streamer.write_user_reg(sid_noc_block_sos_filter, sr_addr(noc_block_sos_filter.COEFF_B1_OFFSET, 0), real2fxp(sos0.b1));
    tb_streamer.write_user_reg(sid_noc_block_sos_filter, sr_addr(noc_block_sos_filter.COEFF_B2_OFFSET, 0), real2fxp(sos0.b2));
    tb_streamer.write_user_reg(sid_noc_block_sos_filter, sr_addr(noc_block_sos_filter.COEFF_A1_OFFSET, 0), real2fxp(sos0.a1));
    tb_streamer.write_user_reg(sid_noc_block_sos_filter, sr_addr(noc_block_sos_filter.COEFF_A2_OFFSET, 0), real2fxp(sos0.a2));
    `TEST_CASE_DONE(1);

    `TEST_CASE_START("Check impulse and step response");
    // Generate test and golden output vector 
    in_i = new[NTAPS];
    in_q = new[NTAPS];
    gen_test_wfm(NTAPS, in_i, in_q);
    sos_filter(sos0, in_i, out_i);
    sos_filter(sos0, in_q, out_q);
    // Input/output process
    fork
      begin
        for (int n = 0; n < NTAPS; n++) begin
          tb_streamer.push_word({real2fxp(in_i[n]), real2fxp(in_q[n])}, (n % SPP == SPP-1));
        end
      end
      begin
        logic [31:0] recv_word;
        real recv_i, recv_q;
        logic last;
        for (int n = 0; n < NTAPS; n++) begin
          tb_streamer.pull_word(recv_word, last);
          recv_i = fxp2real(recv_word[31:16]);
          recv_q = fxp2real(recv_word[15:0]);
          // $display("Output: %f + %fj (expected %f + %fj)", recv_i, recv_q, out_i[n], out_q[n]);
          `ASSERT_ERROR(absval(recv_i - out_i[n]) < ERROR, "Incorrect I value");
          `ASSERT_ERROR(absval(recv_q - out_q[n]) < ERROR, "Incorrect Q value");
          `ASSERT_FATAL((n % SPP != SPP-1) == (last == 1'b0), "Detected early tlast!");
          `ASSERT_FATAL((n % SPP == SPP-1) == (last == 1'b1), "Detected late tlast!")
        end
      end
    join
    `TEST_CASE_DONE(1);

    `TEST_CASE_START("Configure Filter: Highpass Example");
    sos0.b0 = 0.27272727;
    sos0.b1 = -0.54545455;
    sos0.b2 = 0.27272727;
    sos0.a1 = 0.00000000;
    sos0.a2 = 0.09090909;
    tb_streamer.write_user_reg(sid_noc_block_sos_filter, sr_addr(noc_block_sos_filter.COEFF_B0_OFFSET, 0), real2fxp(sos0.b0));
    tb_streamer.write_user_reg(sid_noc_block_sos_filter, sr_addr(noc_block_sos_filter.COEFF_B1_OFFSET, 0), real2fxp(sos0.b1));
    tb_streamer.write_user_reg(sid_noc_block_sos_filter, sr_addr(noc_block_sos_filter.COEFF_B2_OFFSET, 0), real2fxp(sos0.b2));
    tb_streamer.write_user_reg(sid_noc_block_sos_filter, sr_addr(noc_block_sos_filter.COEFF_A1_OFFSET, 0), real2fxp(sos0.a1));
    tb_streamer.write_user_reg(sid_noc_block_sos_filter, sr_addr(noc_block_sos_filter.COEFF_A2_OFFSET, 0), real2fxp(sos0.a2));
    `TEST_CASE_DONE(1);

    `TEST_CASE_START("Check impulse and step response");
    // Generate test and golden output vector 
    in_i = new[NTAPS];
    in_q = new[NTAPS];
    gen_test_wfm(NTAPS, in_i, in_q);
    sos_filter(sos0, in_i, out_i);
    sos_filter(sos0, in_q, out_q);
    // Input/output process
    fork
      begin
        for (int n = 0; n < NTAPS; n++) begin
          tb_streamer.push_word({real2fxp(in_i[n]), real2fxp(in_q[n])}, (n % SPP == SPP-1));
        end
      end
      begin
        logic [31:0] recv_word;
        real recv_i, recv_q;
        logic last;
        for (int n = 0; n < NTAPS; n++) begin
          tb_streamer.pull_word(recv_word, last);
          recv_i = fxp2real(recv_word[31:16]);
          recv_q = fxp2real(recv_word[15:0]);
          // $display("Output: %f + %fj (expected %f + %fj)", recv_i, recv_q, out_i[n], out_q[n]);
          `ASSERT_ERROR(absval(recv_i - out_i[n]) < ERROR, "Incorrect I value");
          `ASSERT_ERROR(absval(recv_q - out_q[n]) < ERROR, "Incorrect Q value");
          `ASSERT_FATAL((n % SPP != SPP-1) == (last == 1'b0), "Detected early tlast!");
          `ASSERT_FATAL((n % SPP == SPP-1) == (last == 1'b1), "Detected late tlast!")
        end
      end
    join
    `TEST_CASE_DONE(1);


    `TEST_BENCH_DONE;
  end
endmodule
