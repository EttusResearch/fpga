//
// Copyright 2015 Ettus Research LLC
//


`timescale 1ns/1ps
`define NS_PER_TICK 1
`define NUM_TEST_CASES 5

`include "sim_clks_rsts.vh"
`include "sim_exec_report.vh"
`include "sim_cvita_lib.sv"
`include "sim_axi4_lib.sv"

`define USE_SRAM

module dram_fifo_tb();
  `TEST_BENCH_INIT("dram_fifo_tb",`NUM_TEST_CASES,`NS_PER_TICK)

  // Define all clocks and resets
  `DEFINE_CLK(sys_clk, 10, 50)            //100MHz sys_clk to generate DDR3 clocking
  `DEFINE_CLK(bus_clk, 1000/166.6667, 50) //166MHz bus_clk
  `DEFINE_RESET(bus_rst, 0, 100)          //100ns for GSR to deassert
  `DEFINE_RESET_N(sys_rst_n, 0, 100)      //100ns for GSR to deassert

  cvita_stream_t chdr_i (.clk(bus_clk));
  cvita_stream_t chdr_o (.clk(bus_clk));

  // Initialize DUT
  wire calib_complete;
`ifdef USE_SRAM

  axi_fifo #(.WIDTH(65), .SIZE(24)) dut_single (
    .clk(bus_clk),
    .reset(bus_rst),
    .clear(1'b0),
    
    .i_tdata({chdr_i.axis.tlast, chdr_i.axis.tdata}),
    .i_tvalid(chdr_i.axis.tvalid),
    .i_tready(chdr_i.axis.tready),
  
    .o_tdata({chdr_o.axis.tlast, chdr_o.axis.tdata}),
    .o_tvalid(chdr_o.axis.tvalid),
    .o_tready(chdr_o.axis.tready),
    
    .space(),
    .occupied()
  );
  assign calib_complete = 1;

`else

  axis_dram_fifo_single dut_single (
    .bus_clk(bus_clk),
    .bus_rst(bus_rst),
    .sys_clk(sys_clk),
    .sys_rst_n(sys_rst_n),
    
    .i_tdata(chdr_i.axis.tdata),
    .i_tlast(chdr_i.axis.tlast),
    .i_tvalid(chdr_i.axis.tvalid),
    .i_tready(chdr_i.axis.tready),
  
    .o_tdata(chdr_o.axis.tdata),
    .o_tlast(chdr_o.axis.tlast),
    .o_tvalid(chdr_o.axis.tvalid),
    .o_tready(chdr_o.axis.tready),
    
    .init_calib_complete(calib_complete)
  );
  
`endif

  //Testbench variables
  cvita_hdr_t   header, header_out;
  cvita_stats_t stats;
  logic [63:0]  crc_cache;

  //------------------------------------------
  //Main thread for testbench execution
  //------------------------------------------
  initial begin : tb_main

    `TEST_CASE_START("Wait for reset");
    while (bus_rst) @(posedge bus_clk);
    while (~sys_rst_n) @(posedge sys_clk);
    `TEST_CASE_DONE((~bus_rst & sys_rst_n));

    `TEST_CASE_START("Wait for initial calibration complete");
    while (~calib_complete) @(posedge bus_clk);
    `TEST_CASE_DONE(calib_complete);

    header = '{
      pkt_type:DATA, has_time:0, eob:0, seqno:12'h666,
      length:0, sid:$random, timestamp:64'h0};

    `TEST_CASE_START("Fill up empty FIFO then drain");
      chdr_o.axis.tready = 0;
      chdr_i.push_ramp_pkt(200, 64'd0, 64'd100, header);
      chdr_o.axis.tready = 1;
      chdr_o.wait_for_pkt_end_get_info(header_out, stats);
    `TEST_CASE_DONE((stats.count==200) && (header.sid==header_out.sid) && chdr_i.axis.tready);

    header = '{
      pkt_type:DATA, has_time:1, eob:0, seqno:12'h666, 
      length:0, sid:$random, timestamp:64'h0};

    `TEST_CASE_START("Concurrent read and write (single packet)");
      chdr_o.axis.tready = 1;
      fork
          begin
            chdr_i.push_ramp_pkt(100, 64'd0, 64'd100, header);
          end
          begin
            chdr_o.wait_for_pkt_start();
            chdr_o.wait_for_pkt_end_get_info(header_out, stats);
          end
      join
    crc_cache = stats.crc;    //Cache CRC for future test cases
    `TEST_CASE_DONE((stats.count==100));

    `TEST_CASE_START("Concurrent read and write (multiple packets)");
      chdr_o.axis.tready = 1;
      fork
          begin
            repeat (20) begin
              chdr_i.push_ramp_pkt(100, 64'd0, 64'd100, header);
            end
          end
          begin
            repeat (20) begin
              chdr_o.wait_for_pkt_start();
              chdr_o.wait_for_pkt_end_get_info(header_out, stats);
              `ASSERT_ERROR((stats.count==100)&&(crc_cache==stats.crc), "Bad/corrupt packet!");
            end
          end
      join
    `TEST_CASE_DONE(1);

  end

endmodule
