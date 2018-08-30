//
// Copyright 2014 Ettus Research LLC
// Copyright 2016-2018 Ettus Research, a National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//

`timescale 1ns/1ps
`define NS_PER_TICK 1
`define NUM_TEST_CASES 8

`include "sim_exec_report.vh"
`include "sim_clks_rsts.vh"
`include "sim_rfnoc_lib.svh"

module noc_block_vector_iir_tb();
  `TEST_BENCH_INIT("noc_block_vector_iir",`NUM_TEST_CASES,`NS_PER_TICK);
  localparam BUS_CLK_PERIOD = $ceil(1e9/166.67e6);
  localparam CE_CLK_PERIOD  = $ceil(1e9/200e6);
  localparam NUM_CE         = 1;  // Number of Computation Engines / User RFNoC blocks to simulate
  localparam NUM_STREAMS    = 1;  // Number of test bench streams
  `RFNOC_SIM_INIT(NUM_CE, NUM_STREAMS, BUS_CLK_PERIOD, CE_CLK_PERIOD);
  `RFNOC_ADD_BLOCK(noc_block_vector_iir, 0);

  localparam SPP       = 512; // Samples per packet
  localparam NUM_PKTS  = 50;

  // Vector IIR settings
  localparam VECTOR_SIZE = SPP;
  localparam real ERROR  = (2.0 ** -12);  // Target 72dB of dynamic range

  // Types
  typedef struct {
    real alpha = 1.0;
    real beta = 0.0;
  } filt_coeff_t;

  real in_0[], in_1[], out_0[], out_1[];
  filt_coeff_t filt_def;

  // Tasks and functions
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

  // Golden filter model
  task automatic iir_filter (
    input filt_coeff_t coeff,
    input real in[],
    output real out[]);
  begin
    out = new[in.size()];
    for (int i = 0; i < in.size(); i=i+1) begin
      real x0 = in[i];
      real yd = i >= 1 ? out[i-1] : 0.0; 
      out[i] = in[i]*coeff.beta + yd*coeff.alpha;
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
    tb_streamer.read_reg(sid_noc_block_vector_iir, RB_NOC_ID, readback);
    $display("Read Vector IIR NOC ID: %16x", readback);
    `ASSERT_ERROR(readback == noc_block_vector_iir.NOC_ID, "Incorrect NOC ID");
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 3 -- Connect RFNoC blocks
    ********************************************************/
    `TEST_CASE_START("Connect RFNoC blocks");
    `RFNOC_CONNECT(noc_block_tb,noc_block_vector_iir,SC16,SPP);
    `RFNOC_CONNECT(noc_block_vector_iir,noc_block_tb,SC16,SPP);
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 4 -- Setup Vector IIR
    ********************************************************/
    `TEST_CASE_START("Setup Vector IIR");
    filt_def.alpha = 0.7;
    filt_def.beta = 0.3;
    tb_streamer.write_user_reg(sid_noc_block_vector_iir, noc_block_vector_iir.SR_VECTOR_LEN, VECTOR_SIZE);
    tb_streamer.write_user_reg(sid_noc_block_vector_iir, noc_block_vector_iir.SR_ALPHA, real2fxp(filt_def.alpha));
    tb_streamer.write_user_reg(sid_noc_block_vector_iir, noc_block_vector_iir.SR_BETA, real2fxp(filt_def.beta));
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 5 -- Test impulse and step response
    ********************************************************/
    `TEST_CASE_START("Check impulse and step response");
    // Generate input and golden output vector 
    in_0 = new[NUM_PKTS];
    in_1 = new[NUM_PKTS];
    for (int n = 0; n < NUM_PKTS; n++) begin
      // First half is an impulse, second half is a step
      in_0[n] = (n == 0 || n >= NUM_PKTS/2) ?  1.0 : 0.0;
      in_1[n] = (n == 0 || n >= NUM_PKTS/2) ? -1.0 : 0.0;
    end
    iir_filter(filt_def, in_0, out_0);
    iir_filter(filt_def, in_1, out_1);
    // Send, receive and validate data
    fork
      begin
        logic [31:0] send_word;
        for (int n = 0; n < NUM_PKTS; n++) begin
          for (int k = 0; k < VECTOR_SIZE; k++) begin
            tb_streamer.push_word({real2fxp(in_0[n]), real2fxp(in_1[n])}, (k == VECTOR_SIZE-1));
          end
        end
      end
      begin
        logic [31:0] recv_word;
        real recv_i, recv_q;
        logic last;
        for (int n = 0; n < NUM_PKTS; n++) begin
          for (int k = 0; k < VECTOR_SIZE; k++) begin
            tb_streamer.pull_word(recv_word, last);
            recv_i = fxp2real(recv_word[31:16]);
            recv_q = fxp2real(recv_word[15:0]);
            //$display("[%0d:%0d] Output: %f + %fj (expected %f + %fj)", n, k, recv_i, recv_q, out_0[n], out_1[n]);
            `ASSERT_ERROR(absval(recv_i - out_0[n]) < ERROR, "Incorrect I value");
            `ASSERT_ERROR(absval(recv_q - out_1[n]) < ERROR, "Incorrect Q value");
            `ASSERT_FATAL((k != VECTOR_SIZE-1) == (last == 1'b0), "Detected early tlast!");
            `ASSERT_FATAL((k == VECTOR_SIZE-1) == (last == 1'b1), "Detected late tlast!")
          end
        end
      end
    join
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 6 -- Test quarter rate sine response (vector stride)
    ********************************************************/
    `TEST_CASE_START("Check quarter rate complex sine response (vector stride)");
    filt_def.alpha = 0.9;
    filt_def.beta = 0.1;
    tb_streamer.write_user_reg(sid_noc_block_vector_iir, noc_block_vector_iir.SR_ALPHA, real2fxp(filt_def.alpha));
    tb_streamer.write_user_reg(sid_noc_block_vector_iir, noc_block_vector_iir.SR_BETA, real2fxp(filt_def.beta));
    // Generate input and golden output vector 
    in_0 = new[NUM_PKTS];
    in_1 = new[NUM_PKTS];
    for (int n = 0; n < NUM_PKTS; n++) begin
      // First half is an impulse, second half is a step
      in_0[n] = (n % 4 == 1 || n % 4 == 3) ? 0.0 : ((n % 4 == 0) ? 1.0 : -1.0); //cos
      in_1[n] = (n % 4 == 0 || n % 4 == 2) ? 0.0 : ((n % 4 == 1) ? 1.0 : -1.0); //sin
    end
    iir_filter(filt_def, in_0, out_0);
    iir_filter(filt_def, in_1, out_1);
    // Send, receive and validate data
    fork
      begin
        logic [31:0] send_word;
        for (int n = 0; n < NUM_PKTS; n++) begin
          for (int k = 0; k < VECTOR_SIZE; k++) begin
            tb_streamer.push_word({real2fxp(in_0[n]), real2fxp(in_1[n])}, (k == VECTOR_SIZE-1));
          end
        end
      end
      begin
        logic [31:0] recv_word;
        real recv_i, recv_q;
        logic last;
        for (int n = 0; n < NUM_PKTS; n++) begin
          for (int k = 0; k < VECTOR_SIZE; k++) begin
            tb_streamer.pull_word(recv_word, last);
            recv_i = fxp2real(recv_word[31:16]);
            recv_q = fxp2real(recv_word[15:0]);
            //$display("[%0d:%0d] Output: %f + %fj (expected %f + %fj)", n, k, recv_i, recv_q, out_0[n], out_1[n]);
            `ASSERT_ERROR(absval(recv_i - out_0[n]) < ERROR, "Incorrect I value");
            `ASSERT_ERROR(absval(recv_q - out_1[n]) < ERROR, "Incorrect Q value");
            `ASSERT_FATAL((k != VECTOR_SIZE-1) == (last == 1'b0), "Detected early tlast!");
            `ASSERT_FATAL((k == VECTOR_SIZE-1) == (last == 1'b1), "Detected late tlast!")
          end
        end
      end
    join
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 7 -- Test quarter rate sine response (sample stride)
    ********************************************************/
    `TEST_CASE_START("Check quarter rate complex sine response (sample stride)");
    filt_def.alpha = 0.01;
    filt_def.beta = 0.99;
    tb_streamer.write_user_reg(sid_noc_block_vector_iir, noc_block_vector_iir.SR_ALPHA, real2fxp(filt_def.alpha));
    tb_streamer.write_user_reg(sid_noc_block_vector_iir, noc_block_vector_iir.SR_BETA, real2fxp(filt_def.beta));
    // Generate input and golden output vector 
    in_0 = new[NUM_PKTS];
    in_1 = new[NUM_PKTS];
    for (int n = 0; n < NUM_PKTS; n++) begin
      // First half is an impulse, second half is a step
      in_0[n] = (n % 4 == 1 || n % 4 == 3) ? 0.0 : ((n % 4 == 0) ? 1.0 : -1.0); //cos
      in_1[n] = (n % 4 == 0 || n % 4 == 2) ? 0.0 : ((n % 4 == 1) ? 1.0 : -1.0); //sin
    end
    iir_filter(filt_def, in_0, out_0);
    iir_filter(filt_def, in_1, out_1);
    // Send, receive and validate data
    fork
      begin
        logic [31:0] send_word;
        for (int n = 0; n < NUM_PKTS; n++) begin
          for (int k = 0; k < VECTOR_SIZE; k++) begin
            if (k % 4 == 0)
              tb_streamer.push_word({real2fxp(in_0[n]), real2fxp(in_1[n])}, (k == VECTOR_SIZE-1));
            else if (k % 4 == 2)
              tb_streamer.push_word({real2fxp(in_1[n]), real2fxp(in_0[n])}, (k == VECTOR_SIZE-1));
            else
              tb_streamer.push_word({real2fxp(0.0), real2fxp(0.0)}, (k == VECTOR_SIZE-1));
          end
        end
      end
      begin
        logic [31:0] recv_word;
        real recv_i, recv_q;
        logic last;
        for (int n = 0; n < NUM_PKTS; n++) begin
          for (int k = 0; k < VECTOR_SIZE; k++) begin
            tb_streamer.pull_word(recv_word, last);
            recv_i = fxp2real(recv_word[31:16]);
            recv_q = fxp2real(recv_word[15:0]);
            if (k % 4 == 0) begin
              //$display("[%0d:%0d] Output: %f + %fj (expected %f + %fj)", n, k, recv_i, recv_q, out_0[n], out_1[n]);
              `ASSERT_ERROR(absval(recv_i - out_0[n]) < 0.01, "Incorrect I value"); //Fudge factor in error because of method
              `ASSERT_ERROR(absval(recv_q - out_1[n]) < 0.01, "Incorrect Q value");
            end else if (k % 4 == 2) begin
              //$display("[%0d:%0d] Output: %f + %fj (expected %f + %fj)", n, k, recv_i, recv_q, out_1[n], out_0[n]);
              `ASSERT_ERROR(absval(recv_i - out_1[n]) < 0.01, "Incorrect I value");
              `ASSERT_ERROR(absval(recv_q - out_0[n]) < 0.01, "Incorrect Q value");
            end else begin
              //$display("[%0d:%0d] Output: %f + %fj (expected %f + %fj)", n, k, recv_i, recv_q, 0.0, 0.0);
              `ASSERT_ERROR(absval(recv_i) < 0.01, "Incorrect I value");
              `ASSERT_ERROR(absval(recv_q) < 0.01, "Incorrect Q value");
            end 
            `ASSERT_FATAL((k != VECTOR_SIZE-1) == (last == 1'b0), "Detected early tlast!");
            `ASSERT_FATAL((k == VECTOR_SIZE-1) == (last == 1'b1), "Detected late tlast!")
          end
        end
      end
    join
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 8 -- Test test impulse response with gaps
    ********************************************************/
    `TEST_CASE_START("Check impulse and step response (with gaps in stream)");
    filt_def.alpha = 0.4;
    filt_def.beta = 0.6;
    tb_streamer.write_user_reg(sid_noc_block_vector_iir, noc_block_vector_iir.SR_ALPHA, real2fxp(filt_def.alpha));
    tb_streamer.write_user_reg(sid_noc_block_vector_iir, noc_block_vector_iir.SR_BETA, real2fxp(filt_def.beta));
    // Generate input and golden output vector 
    in_0 = new[NUM_PKTS];
    in_1 = new[NUM_PKTS];
    for (int n = 0; n < NUM_PKTS; n++) begin
      // First half is an impulse, second half is a step
      in_0[n] = (n == 0 || n >= NUM_PKTS/2) ?  1.0 : 0.0;
      in_1[n] = (n == 0 || n >= NUM_PKTS/2) ? -1.0 : 0.0;
    end
    iir_filter(filt_def, in_0, out_0);
    iir_filter(filt_def, in_1, out_1);
    // Send, receive and validate data
    fork
      begin
        logic [31:0] send_word;
        for (int n = 0; n < NUM_PKTS; n++) begin
          for (int k = 0; k < VECTOR_SIZE; k++) begin
            tb_streamer.push_word({real2fxp(in_0[n]), real2fxp(in_1[n])}, (k == VECTOR_SIZE-1));
            repeat($urandom_range(0, 15)) @(posedge bus_clk);
          end
        end
      end
      begin
        logic [31:0] recv_word;
        real recv_i, recv_q;
        logic last;
        for (int n = 0; n < NUM_PKTS; n++) begin
          for (int k = 0; k < VECTOR_SIZE; k++) begin
            tb_streamer.pull_word(recv_word, last);
            recv_i = fxp2real(recv_word[31:16]);
            recv_q = fxp2real(recv_word[15:0]);
            //$display("[%0d:%0d] Output: %f + %fj (expected %f + %fj)", n, k, recv_i, recv_q, out_0[n], out_1[n]);
            `ASSERT_ERROR(absval(recv_i - out_0[n]) < ERROR, "Incorrect I value");
            `ASSERT_ERROR(absval(recv_q - out_1[n]) < ERROR, "Incorrect Q value");
            `ASSERT_FATAL((k != VECTOR_SIZE-1) == (last == 1'b0), "Detected early tlast!");
            `ASSERT_FATAL((k == VECTOR_SIZE-1) == (last == 1'b1), "Detected late tlast!")
          end
        end
      end
    join
    `TEST_CASE_DONE(1);

    `TEST_BENCH_DONE;
  end
endmodule
