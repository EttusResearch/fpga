//
// Copyright 2015 Ettus Research LLC
//


`timescale 1ns/1ps
`define NS_PER_TICK 1
`define NUM_TEST_CASES 14

`include "sim_clks_rsts.vh"
`include "sim_exec_report.vh"
`include "sim_cvita_lib.sv"
`include "sim_axi4_lib.sv"
`include "sim_set_rb_lib.sv"

`define USE_SRAM_MIG      //Use the DMA engine from the DRAM FIFO but SRAM as the base memory

module dram_fifo_bist_tb();
  `TEST_BENCH_INIT("dram_fifo_bist_tb",`NUM_TEST_CASES,`NS_PER_TICK)

  // Define all clocks and resets
  `DEFINE_CLK(sys_clk, 10, 50)            //100MHz sys_clk to generate DDR3 clocking
  `DEFINE_CLK(bus_clk, 1000/166.6667, 50) //166MHz bus_clk
  `DEFINE_RESET(bus_rst, 0, 100)          //100ns for GSR to deassert
  `DEFINE_RESET_N(sys_rst_n, 0, 100)      //100ns for GSR to deassert

  // Initialize DUT
  wire            calib_complete;
  wire            running, done;
  wire [1:0]      error;

  settings_t #(.AWIDTH(8),.DWIDTH(32)) tst_set (.clk(bus_clk));
  cvita_stream_t  cvita_fifo_in   (.clk(bus_clk));
  cvita_stream_t  cvita_fifo_out  (.clk(bus_clk));
  cvita_stream_t  cvita_test_in   (.clk(bus_clk));
  cvita_stream_t  cvita_test_out  (.clk(bus_clk));
  cvita_stream_t  cvita_user_in   (.clk(bus_clk));
  cvita_stream_t  cvita_user_out  (.clk(bus_clk));
  
  // Test Topology (Inline production BIST for DRAM FIFO):
  //
  // User Data ====> |---------|       |---------------|       |-----------| ====> User Data Out
  //                 | AXI MUX | ====> | AXI DRAM FIFO | ====> | AXI DEMUX |
  // BIST Data ====> |---------|       |---------------|       |-----------| ====> BIST Data Out
  //                                          ||
  //                                   |--------------|
  //                                   | MIG (D/S)RAM |
  //                                   |--------------|

  axis_dram_fifo_single 
`ifdef USE_SRAM_MIG
  #(.USE_SRAM_MEMORY(1)) 
`endif
  dut_single
  (
    .bus_clk(bus_clk),
    .bus_rst(bus_rst),
    .sys_clk(sys_clk),
    .sys_rst_n(sys_rst_n),
    
    .i_tdata(cvita_fifo_in.axis.tdata),
    .i_tlast(cvita_fifo_in.axis.tlast),
    .i_tvalid(cvita_fifo_in.axis.tvalid),
    .i_tready(cvita_fifo_in.axis.tready),
  
    .o_tdata(cvita_fifo_out.axis.tdata),
    .o_tlast(cvita_fifo_out.axis.tlast),
    .o_tvalid(cvita_fifo_out.axis.tvalid),
    .o_tready(cvita_fifo_out.axis.tready),
    
    .init_calib_complete(calib_complete)
  );

  axi_chdr_test_pattern axi_chdr_test_pattern_i (
    .clk(bus_clk),
    .reset(bus_rst),
  
    .i_tdata(cvita_test_in.axis.tdata),
    .i_tlast(cvita_test_in.axis.tlast),
    .i_tvalid(cvita_test_in.axis.tvalid),
    .i_tready(cvita_test_in.axis.tready),

    .o_tdata(cvita_test_out.axis.tdata),
    .o_tlast(cvita_test_out.axis.tlast),
    .o_tvalid(cvita_test_out.axis.tvalid),
    .o_tready(cvita_test_out.axis.tready),

    .set_stb(tst_set.stb),
    .set_addr(tst_set.addr),
    .set_data(tst_set.data),

    .running(running),
    .done(done),
    .error(error),
    .status_vtr()
  );

  axi_mux4 #(.PRIO(1), .WIDTH(64)) axi_mux (
    .clk(bus_clk), .reset(bus_rst), .clear(1'b0),
    .i0_tdata(cvita_user_in.axis.tdata), .i0_tlast(cvita_user_in.axis.tlast), .i0_tvalid(cvita_user_in.axis.tvalid), .i0_tready(cvita_user_in.axis.tready),
    .i1_tdata(cvita_test_in.axis.tdata), .i1_tlast(cvita_test_in.axis.tlast), .i1_tvalid(cvita_test_in.axis.tvalid), .i1_tready(cvita_test_in.axis.tready),
    .i2_tdata(64'h0), .i2_tlast(1'b0), .i2_tvalid(1'b0), .i2_tready(),
    .i3_tdata(64'h0), .i3_tlast(1'b0), .i3_tvalid(1'b0), .i3_tready(),
    .o_tdata(cvita_fifo_in.axis.tdata), .o_tlast(cvita_fifo_in.axis.tlast), .o_tvalid(cvita_fifo_in.axis.tvalid), .o_tready(cvita_fifo_in.axis.tready)
  );

  axi_demux4 #(.ACTIVE_CHAN(4'b0011), .WIDTH(64)) axi_demux(
    .clk(bus_clk), .reset(bus_rst), .clear(1'b0),
    .header(), .dest({1'b0, running}),
    .i_tdata(cvita_fifo_out.axis.tdata), .i_tlast(cvita_fifo_out.axis.tlast), .i_tvalid(cvita_fifo_out.axis.tvalid), .i_tready(cvita_fifo_out.axis.tready),
    .o0_tdata(cvita_user_out.axis.tdata), .o0_tlast(cvita_user_out.axis.tlast), .o0_tvalid(cvita_user_out.axis.tvalid), .o0_tready(cvita_user_out.axis.tready),
    .o1_tdata(cvita_test_out.axis.tdata), .o1_tlast(cvita_test_out.axis.tlast), .o1_tvalid(cvita_test_out.axis.tvalid), .o1_tready(cvita_test_out.axis.tready),
    .o2_tdata(), .o2_tlast(), .o2_tvalid(), .o2_tready(1'b0),
    .o3_tdata(), .o3_tlast(), .o3_tvalid(), .o3_tready(1'b0)
  );

  //Testbench variables
  cvita_hdr_t   header, header_out;
  cvita_stats_t stats;

  //------------------------------------------
  //Main thread for testbench execution
  //------------------------------------------
  initial begin : tb_main

    `TEST_CASE_START("Wait for reset");
    while (bus_rst) @(posedge bus_clk);
    while (~sys_rst_n) @(posedge sys_clk);
    `TEST_CASE_DONE(~bus_rst & sys_rst_n);
    
    repeat (200) @(posedge sys_clk);

    `TEST_CASE_START("Wait for initial calibration to complete");
    while (calib_complete !== 1'b1) @(posedge bus_clk);
    `TEST_CASE_DONE(calib_complete);

    header = '{
      pkt_type:DATA, has_time:0, eob:0, seqno:12'h666,
      length:0, sid:$random, timestamp:64'h0};

    `TEST_CASE_START("User Data: Fill up FIFO and then empty");
      cvita_user_out.axis.tready = 0;
      cvita_user_in.push_ramp_pkt(16, 64'd0, 64'h100, header);
      cvita_user_out.axis.tready = 1;
      cvita_user_out.wait_for_pkt_get_info(header_out, stats);
      `ASSERT_ERROR(stats.count==16,            "Bad packet: Length mismatch");
      `ASSERT_ERROR(header.sid==header_out.sid, "Bad packet: Wrong SID");
    `TEST_CASE_DONE(1);

    `TEST_CASE_START("Setup BIST: 10 x 40byte packets");
    tst_set.write(0, {2'd0, 1'b0});
    tst_set.write(3, 32'h01234567);
    tst_set.write(2, {8'd0, 8'd0});
    tst_set.write(1, {1'b0, 14'd40, 16'd10});
    `TEST_CASE_DONE(~done & ~running);

    `TEST_CASE_START("Run BIST");
    tst_set.write(0, {2'd3, 1'b1});
    while (~done) @(posedge bus_clk);
    `ASSERT_ERROR(error === 2'b00, "BIST failed!");
    @(posedge bus_clk);
    `TEST_CASE_DONE(done & ~running);

    `TEST_CASE_START("Run BIST ... again");
    tst_set.write(0, {2'd0, 1'b1});
    while (~done) @(posedge bus_clk);
    `ASSERT_ERROR(error === 2'b00, "BIST failed!");
    @(posedge bus_clk);
    `TEST_CASE_DONE(done & ~running);

    `TEST_CASE_START("Run BIST ... and again");
    tst_set.write(0, {2'd0, 1'b0});
    tst_set.write(0, {2'd2, 1'b1});
    while (~done) @(posedge bus_clk);
    `ASSERT_ERROR(error === 2'b00, "BIST failed!");
    @(posedge bus_clk);
    `TEST_CASE_DONE(done & ~running);

    `TEST_CASE_START("Setup BIST: 256 x 1000byte packets");
    tst_set.write(0, {2'd0, 1'b0});
    tst_set.write(3, 32'h0ABCDEF0);
    tst_set.write(2, {8'd8, 8'd8});
    tst_set.write(1, {1'b0, 14'd1000, 16'd256});
    `TEST_CASE_DONE(~done & ~running);

    `TEST_CASE_START("Run BIST");
    tst_set.write(0, {2'd1, 1'b1});
    while (~done) @(negedge bus_clk);
    `ASSERT_ERROR(error === 2'b00, "BIST failed!");
    @(posedge bus_clk);
    `TEST_CASE_DONE(done & ~running);

    `TEST_CASE_START("User DatA: Concurrent read and write");
      cvita_user_out.axis.tready = 1;
      fork
          begin
            cvita_user_in.push_ramp_pkt(20, 64'd0, 64'h100, header);
          end
          begin
            cvita_user_out.wait_for_pkt_get_info(header_out, stats);
          end
      join
    `ASSERT_ERROR(stats.count==20,      "Bad packet: Length mismatch");
    `TEST_CASE_DONE(1);

    `TEST_CASE_START("Setup BIST: 256 x 100byte ramping packets");
    tst_set.write(0, {2'd0, 1'b0});
    tst_set.write(3, 32'h01234567);
    tst_set.write(2, {8'd0, 8'd0});
    tst_set.write(1, {1'b0, 14'd100, 16'd256});
    `TEST_CASE_DONE(~done & ~running);

    `TEST_CASE_START("Run BIST");
    tst_set.write(0, {2'd0, 1'b1});
    while (~done) @(posedge bus_clk);
    `ASSERT_ERROR(error === 2'b00, "BIST failed!");
    @(posedge bus_clk);
    `TEST_CASE_DONE(done & ~running);

    `TEST_CASE_START("Setup BIST: 30 x 8000byte packets");
    tst_set.write(0, {2'd0, 1'b0});
    tst_set.write(3, 32'h0ABCDEF0);
    tst_set.write(2, {8'd0, 8'd0});
    tst_set.write(1, {1'b0, 14'd8000, 16'd30});
    `TEST_CASE_DONE(~done & ~running);

    `TEST_CASE_START("Run BIST");
    tst_set.write(0, {2'd1, 1'b1});
    while (~done) @(negedge bus_clk);
    `ASSERT_ERROR(error === 2'b00, "BIST failed!");
    @(posedge bus_clk);
    `TEST_CASE_DONE(done & ~running);

  end

endmodule
