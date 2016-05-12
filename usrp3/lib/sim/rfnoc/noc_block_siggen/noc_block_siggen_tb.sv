//
// Copyright 2016 Ettus Research LLC
//
`timescale 1ns/1ps
`define NS_PER_TICK 1
`define NUM_TEST_CASES 5

`include "sim_exec_report.vh"
`include "sim_clks_rsts.vh"
`include "sim_rfnoc_lib.svh"

module noc_block_siggen_tb();
  `TEST_BENCH_INIT("noc_block_siggen",`NUM_TEST_CASES,`NS_PER_TICK);
  localparam BUS_CLK_PERIOD = $ceil(1e9/166.67e6);
  localparam CE_CLK_PERIOD  = $ceil(1e9/200e6);
  localparam NUM_CE         = 1;  // Number of Computation Engines / User RFNoC blocks to simulate
  localparam NUM_STREAMS    = 1;  // Number of test bench streams
  localparam TEST_LENGTH = 2000;

  `RFNOC_SIM_INIT(NUM_CE, NUM_STREAMS, BUS_CLK_PERIOD, CE_CLK_PERIOD);
  `RFNOC_ADD_BLOCK(noc_block_siggen, 0);

  localparam SPP = 16; // Samples per packet
  wire [15:0] phase ;
  wire [15:0] phase2 ;
  wire [31:0] cartesian;
  wire [31:0] pkt_size;
  
  logic error = 0;   
  real pi = $acos(-1);
  real gain_correction = 0.699;
  real expected_sine, expected_cosine;
  real phase_real, expected_sine_real, expected_cosine_real;
  integer freq = 1; // (In MHz)
  integer sample_rate = 100; // (In Msps)
 
  assign phase = 16'($floor(((2.0**13) * ((2.0*freq)/sample_rate)) + 0.5));
  assign phase2 = 16'($floor(((2.0**13) * (freq/(2.0*sample_rate))) + 0.5));
  assign phase_real = real'((phase/(2.0**13))* pi);
  assign cartesian = {16'b0,16'($floor((2.0**13) * (1.0/1.65)))};
  assign pkt_size = 140;


  task automatic check_wave;
     input real actual;
     input real expected;
     begin
        if (expected > 0) 
           error = (actual > expected) ? (((actual - expected)/expected) > 0.05) : (((expected - actual)/expected) > 0.05) ;
        //`ASSERT_FATAL(error != 1'b1, "Sine wave incorrectly generated");
        `ASSERT_ERROR(error != 1'b1, "Sine wave incorrectly generated");
     end
  endtask



  /********************************************************
  ** Verification
  ********************************************************/
  initial begin : tb_main
    string s;
    logic [15:0] real_val;
    logic [15:0] cplx_val;
    logic last;

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
    tb_streamer.read_reg(sid_noc_block_siggen, RB_NOC_ID, readback);
    $display("Read Sig Gen NOC ID: %16x", readback);
    `ASSERT_ERROR(readback == noc_block_siggen.NOC_ID, "Incorrect NOC ID");
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 3 -- Connect RFNoC blocks
    ********************************************************/
    `TEST_CASE_START("Connect RFNoC blocks");
    `RFNOC_CONNECT(noc_block_tb,noc_block_siggen,SC16,SPP);
    `RFNOC_CONNECT(noc_block_siggen,noc_block_tb,SC16,SPP);
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 4 -- Write / readback user registers
    ********************************************************/
    `TEST_CASE_START("Write / readback user registers");
    
//    random_word = $random();
//    tb_streamer.write_user_reg(sid_noc_block_siggen, noc_block_siggen.SR_FREQ, random_word);
//    tb_streamer.read_user_reg(sid_noc_block_siggen, 0, readback);
//    $sformat(s, "User register 0 incorrect readback! Expected: %0d, Actual 0", (readback[31:0] == random_word));
//    `ASSERT_ERROR(readback[31:0] == random_word, s);
//    
//    random_word = $random();
//    tb_streamer.write_user_reg(sid_noc_block_siggen, noc_block_siggen.SR_AMPLITUDE, random_word);
//    tb_streamer.read_user_reg(sid_noc_block_siggen, 1, readback);
//    $sformat(s, "User register 1 incorrect readback! Expected: %0d, Actual %0d", readback[31:0] == random_word);
//    `ASSERT_ERROR(readback[31:0] == random_word, s);
//    
//    random_word = $random();
//    tb_streamer.write_user_reg(sid_noc_block_siggen, noc_block_siggen.SR_CARTESIAN, random_word);
//    tb_streamer.read_user_reg(sid_noc_block_siggen, 2, readback);
//    $sformat(s, "User register 2 incorrect readback! Expected: %0d, Actual %0d", readback[31:0] == random_word);
//    `ASSERT_ERROR(readback[31:0] == random_word, s);
//    
//    random_word = $random();
//    tb_streamer.write_user_reg(sid_noc_block_siggen, noc_block_siggen.SR_WAVE, random_word);
//    tb_streamer.read_user_reg(sid_noc_block_siggen, 3, readback);
//    $sformat(s, "User register 3 incorrect readback! Expected: %0d, Actual %0d", readback[31:0] == random_word);
//    `ASSERT_ERROR(readback[31:0] == random_word, s);
    
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 5 -- Test sequence
    ********************************************************/
    `TEST_CASE_START("Test sequence");
    //Setting Enable value
    tb_streamer.write_user_reg(sid_noc_block_siggen, noc_block_siggen.SR_ENABLE ,1'b1 );
    //Packet Size should be set first
    tb_streamer.write_user_reg(sid_noc_block_siggen, noc_block_siggen.inst_packet_resizer.SR_PKT_SIZE, pkt_size);
    //FIXME: Cartersian should be programmed before the phase. Need to be fixed in the RTL
    //Setting Cartesian Value
    tb_streamer.write_user_reg(sid_noc_block_siggen, noc_block_siggen.SR_CARTESIAN,cartesian );
    //Setting Phase value
    tb_streamer.write_user_reg(sid_noc_block_siggen, noc_block_siggen.SR_FREQ + 1,phase );
    

    for (int i = 0; i < TEST_LENGTH - 1; ++i) begin
       tb_streamer.pull_word({real_val,cplx_val},last);
       expected_sine_real = $sin((i)*phase_real);
       expected_sine = $floor((gain_correction * ((2.0**13)* expected_sine_real)) + 0.5);
       if (noc_block_siggen.o_tready & noc_block_siggen.o_tvalid) 
         check_wave(real_val, expected_sine);
    end

    //Setting Phase value
    tb_streamer.write_user_reg(sid_noc_block_siggen, noc_block_siggen.SR_FREQ + 1,phase2 );
    
    for (int i = 0; i < TEST_LENGTH - 1; ++i) begin
       tb_streamer.pull_word({real_val,cplx_val},last);
       expected_sine_real = $sin((i)*phase_real);
       expected_sine = $floor((gain_correction * ((2.0**13)* expected_sine_real)) + 0.5);
       if (noc_block_siggen.o_tready & noc_block_siggen.o_tvalid) 
         check_wave(real_val, expected_sine);
    end
    
    `TEST_CASE_DONE(1);
    `TEST_BENCH_DONE;

  end
endmodule

