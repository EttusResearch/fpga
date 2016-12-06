//
// Copyright 2016 Ettus Research
//


`timescale 1ns/1ps
`define SIM_TIMEOUT_US 120
`define NS_PER_TICK 1
`define NUM_TEST_CASES 6

`include "sim_clks_rsts.vh"
`include "sim_exec_report.vh"
`include "sim_cvita_lib.svh"
`include "sim_axi4_lib.svh"
`include "sim_set_rb_lib.svh"

//`define USE_SRAM_FIFO     //Use an AXI-Stream SRAM FIFO (for testing)
`define USE_SRAM_MIG 0      //Use the DMA engine from the DRAM FIFO but SRAM as the base memory
`define USE_BD_INTERCON 1     //Use the Block Design Axi Interconnect

module dram_fifo_tb();
  `TEST_BENCH_INIT("dram_fifo_tb",`NUM_TEST_CASES,`NS_PER_TICK)

  // Define all clocks and resets
  `DEFINE_CLK(sys_clk, 10, 50)            //100MHz sys_clk to generate DDR3 clocking
  `DEFINE_CLK(bus_clk, 1000/166.6667, 50) //166MHz bus_clk
  `DEFINE_RESET(bus_rst, 0, 100)          //100ns for GSR to deassert
  `DEFINE_RESET_N(sys_rst_n, 0, 100)      //100ns for GSR to deassert

  settings_bus_master #(.SR_AWIDTH(8),.SR_DWIDTH(32)) tst_set (.clk(bus_clk));
  cvita_master chdr_i (.clk(bus_clk));
  cvita_slave chdr_o (.clk(bus_clk));

  // Initialize DUT
  wire calib_complete;
`ifdef USE_SRAM_FIFO

  axi_fifo #(.WIDTH(65), .SIZE(18)) dut_single (
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

  axis_dram_fifo_single #(
  .USE_SRAM_MEMORY(`USE_SRAM_MIG),
  .USE_BD_INTERCON(`USE_BD_INTERCON) 
  ) dut_single
  (
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
    
    .set_stb(tst_set.settings_bus.set_stb),
    .set_addr(tst_set.settings_bus.set_addr),
    .set_data(tst_set.settings_bus.set_data),
    .rb_data(),

    .forced_bit_err(64'h0),
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
    string s;

    `TEST_CASE_START("Wait for reset");
    while (bus_rst) @(posedge bus_clk);
    while (~sys_rst_n) @(posedge sys_clk);
    `TEST_CASE_DONE((~bus_rst & sys_rst_n));
    
    tst_set.write(1, {16'h0, 12'd280, 2'b00, 1'b0, 1'b0});
    repeat (200) @(posedge sys_clk);

    `TEST_CASE_START("Wait for initial calibration to complete");
    while (calib_complete !== 1'b1) @(posedge bus_clk);
    `TEST_CASE_DONE(calib_complete);

    header = '{
      pkt_type:DATA, has_time:0, eob:0, seqnum:12'h666,
      length:0, src_sid:$random, dst_sid:$random, timestamp:64'h0};

    `TEST_CASE_START("Fill up empty FIFO then drain (short packet)");
      chdr_o.axis.tready = 0;
      chdr_i.push_ramp_pkt(16, 64'd0, 64'h100, header);
      chdr_o.axis.tready = 1;
      chdr_o.wait_for_pkt_get_info(header_out, stats);
      $sformat(s, "Bad packet: Length mismatch. Expected: %0d, Actual: %0d",16,stats.count);
      `ASSERT_ERROR(stats.count==16, s);
      $sformat(s, "Bad packet: Wrong SID. Expected: %08x, Actual: %08x",
        {header.src_sid,header.dst_sid},{header_out.src_sid,header_out.dst_sid});
      `ASSERT_ERROR({header.src_sid,header.dst_sid}=={header_out.src_sid,header_out.dst_sid}, s);
    `TEST_CASE_DONE(1);

    `TEST_CASE_START("Fill up empty FIFO then drain (long packet)");
      chdr_o.axis.tready = 0;
      chdr_i.push_ramp_pkt(1024, 64'd0, 64'h100, header);
      chdr_o.axis.tready = 1;
      chdr_o.wait_for_pkt_get_info(header_out, stats);
      $sformat(s, "Bad packet: Length mismatch. Expected: %0d, Actual: %0d",1024,stats.count);
      `ASSERT_ERROR(stats.count==1024, s);
      $sformat(s, "Bad packet: Wrong SID. Expected: %08x, Actual: %08x",
        {header.src_sid,header.dst_sid},{header_out.src_sid,header_out.dst_sid});
      `ASSERT_ERROR({header.src_sid,header.dst_sid}=={header_out.src_sid,header_out.dst_sid}, s);
    `TEST_CASE_DONE(1);

    header = '{
      pkt_type:DATA, has_time:1, eob:0, seqnum:12'h666, 
      length:0, src_sid:$random, dst_sid:$random, timestamp:64'h0};

    `TEST_CASE_START("Concurrent read and write (single packet)");
      chdr_o.axis.tready = 1;
      fork
        begin
          chdr_i.push_ramp_pkt(20, 64'd0, 64'h100, header);
        end
        begin
          chdr_o.wait_for_pkt_get_info(header_out, stats);
        end
      join
      crc_cache = stats.crc;    //Cache CRC for future test cases
      $sformat(s, "Bad packet: Length mismatch. Expected: %0d, Actual: %0d",20,stats.count);
      `ASSERT_ERROR(stats.count==20, s);
    `TEST_CASE_DONE(1);

    `TEST_CASE_START("Concurrent read and write (multiple packets)");
      chdr_o.axis.tready = 1;
      fork
        begin
          repeat (10) begin
            chdr_i.push_ramp_pkt(20, 64'd0, 64'h100, header);
            repeat (30) @(posedge bus_clk);
          end
        end
        begin
          repeat (10) begin
            chdr_o.wait_for_pkt_get_info(header_out, stats);
            $sformat(s, "Bad packet: Length mismatch. Expected: %0d, Actual: %0d",20,stats.count);
            `ASSERT_ERROR(stats.count==20, s);
            `ASSERT_ERROR(crc_cache==stats.crc, "Bad packet: Wrong CRC");
          end
        end
      join
    `TEST_CASE_DONE(1);
    `TEST_BENCH_DONE;

  end

endmodule
