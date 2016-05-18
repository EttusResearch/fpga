//
// Copyright 2016 Ettus Research LLC
//
`timescale 1ns/1ps
`define NS_PER_TICK 1
`define NUM_TEST_CASES 5

`include "sim_exec_report.vh"
`include "sim_clks_rsts.vh"
`include "sim_rfnoc_lib.svh"

module noc_block_constant_tb();
  `TEST_BENCH_INIT("noc_block_constant",`NUM_TEST_CASES,`NS_PER_TICK);
  localparam BUS_CLK_PERIOD = $ceil(1e9/166.67e6);
  localparam CE_CLK_PERIOD  = $ceil(1e9/200e6);
  localparam NUM_CE         = 1;  // Number of Computation Engines / User RFNoC blocks to simulate
  localparam NUM_STREAMS    = 1;  // Number of test bench streams
  localparam TEST_LENGTH = 2000;

  `RFNOC_SIM_INIT(NUM_CE, NUM_STREAMS, BUS_CLK_PERIOD, CE_CLK_PERIOD);
  `RFNOC_ADD_BLOCK(noc_block_constant, 0);

  localparam SPP = 16; // Samples per packet
  wire [31:0] pkt_size;
  wire [31:0] amplitude1;
  wire [31:0] amplitude2;
  wire [31:0] amplitude3;
  logic error = 0;   
 
  assign pkt_size = 256;
  assign amplitude1 = 32'hbabababa; // constant_value
  assign amplitude2 = 32'hcacacaca; // constant_value
  assign amplitude3 = 32'hdadadada; // constant_value

  /********************************************************
  ** Verification
  ********************************************************/
  initial begin : tb_main
    string s;
    logic [31:0] actual_value1;
    logic [31:0] actual_value2;
    logic [31:0] actual_value3;
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
    tb_streamer.read_reg(sid_noc_block_constant, RB_NOC_ID, readback);
    $display("Read Sig Gen NOC ID: %16x", readback);
    `ASSERT_ERROR(readback == noc_block_constant.NOC_ID, "Incorrect NOC ID");
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 3 -- Connect RFNoC blocks
    ********************************************************/
    `TEST_CASE_START("Connect RFNoC blocks");
    `RFNOC_CONNECT(noc_block_tb,noc_block_constant,SC16,SPP);
    `RFNOC_CONNECT(noc_block_constant,noc_block_tb,SC16,SPP);
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 4 -- Write / readback user registers
    ********************************************************/
    `TEST_CASE_START("Write / readback user registers");
    
//    random_word = $random();
//    tb_streamer.write_user_reg(sid_noc_block_constant, noc_block_constant.SR_FREQ, random_word);
//    tb_streamer.read_user_reg(sid_noc_block_constant, 0, readback);
//    $sformat(s, "User register 0 incorrect readback! Expected: %0d, Actual 0", (readback[31:0] == random_word));
//    `ASSERT_ERROR(readback[31:0] == random_word, s);
//    
//    random_word = $random();
//    tb_streamer.write_user_reg(sid_noc_block_constant, noc_block_constant.SR_AMPLITUDE, random_word);
//    tb_streamer.read_user_reg(sid_noc_block_constant, 1, readback);
//    $sformat(s, "User register 1 incorrect readback! Expected: %0d, Actual %0d", readback[31:0] == random_word);
//    `ASSERT_ERROR(readback[31:0] == random_word, s);
//    
//    random_word = $random();
//    tb_streamer.write_user_reg(sid_noc_block_constant, noc_block_constant.SR_CARTESIAN, random_word);
//    tb_streamer.read_user_reg(sid_noc_block_constant, 2, readback);
//    $sformat(s, "User register 2 incorrect readback! Expected: %0d, Actual %0d", readback[31:0] == random_word);
//    `ASSERT_ERROR(readback[31:0] == random_word, s);
//    
//    random_word = $random();
//    tb_streamer.write_user_reg(sid_noc_block_constant, noc_block_constant.SR_WAVE, random_word);
//    tb_streamer.read_user_reg(sid_noc_block_constant, 3, readback);
//    $sformat(s, "User register 3 incorrect readback! Expected: %0d, Actual %0d", readback[31:0] == random_word);
//    `ASSERT_ERROR(readback[31:0] == random_word, s);
    
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 5 -- Test sequence
    ********************************************************/
    `TEST_CASE_START("Test sequence");
    //Packet Size should be set first
    tb_streamer.write_user_reg(sid_noc_block_constant, noc_block_constant.inst_packet_resizer.SR_PKT_SIZE, pkt_size);
    
    //Setting Constant Value through Amplitude 
    tb_streamer.write_user_reg(sid_noc_block_constant, noc_block_constant.SR_AMPLITUDE, amplitude1);
    //Setting Enable
    tb_streamer.write_user_reg(sid_noc_block_constant, noc_block_constant.SR_ENABLE, 1'b1);

    for (int i = 0; i < TEST_LENGTH - 1; ++i) begin
       tb_streamer.pull_word(actual_value1,last);
       if (noc_block_constant.o_tvalid) begin
            $sformat(s, "Constant Value doesnt match with output");
           `ASSERT_ERROR(amplitude1 == actual_value1 , s);
       end
    end

      //Setting Enable
      tb_streamer.write_user_reg(sid_noc_block_constant, noc_block_constant.SR_ENABLE, 1'b0);
      //force noc_block_constant.axi_wrapper.s_axis_data_tvalid = 1'b1;
      //Setting Constant Value through Amplitude 
      tb_streamer.write_user_reg(sid_noc_block_constant, noc_block_constant.SR_AMPLITUDE, amplitude2);
//      for (int i = 0; i < TEST_LENGTH - 1; ++i) begin
//         tb_streamer.pull_word(actual_value2,last);
//         //if (actual_value1 == actual_value2)
//         //     continue;
//       if (~noc_block_constant.enable) begin
//              $sformat(s, "Constant Value doesnt match with output", amplitude2 == actual_value2);
//             `ASSERT_ERROR(amplitude2 != actual_value2 , s);
//         end
//      end
       
      for (int i = 0; i < TEST_LENGTH - 1; ++i) begin
         $sformat(s, "The data output should not be valid if enable is 0.");
         `ASSERT_ERROR(noc_block_constant.o_tvalid == 1'b0,s);
      end

      //release noc_block_constant.axi_wrapper.s_axis_data_tvalid;
     
     //Setting Constant Value through Amplitude 
     tb_streamer.write_user_reg(sid_noc_block_constant, noc_block_constant.SR_AMPLITUDE, amplitude3);
     //Setting Enable
     tb_streamer.write_user_reg(sid_noc_block_constant, noc_block_constant.SR_ENABLE, 1'b1);
     for (int i = 0; i < TEST_LENGTH - 1; ++i) begin
        tb_streamer.pull_word(actual_value3,last);
        // Don't check for correctness during the delay to get to the output
        if (actual_value1 == actual_value3)
             continue;
        if (noc_block_constant.o_tvalid) begin
             $sformat(s, "Constant Value doesnt match with output");
            `ASSERT_ERROR(amplitude3 == actual_value3 , s);
        end
     end

    `TEST_CASE_DONE(1);
    `TEST_BENCH_DONE;

  end
endmodule

