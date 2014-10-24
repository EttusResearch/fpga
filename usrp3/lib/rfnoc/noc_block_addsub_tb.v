//
// Copyright 2014 Ettus Research LLC
//
`timescale 1ns/1ps

module noc_shell_addsub_tb();
  /*********************************************
  ** User variables
  *********************************************/
  localparam CLOCK_FREQ = 200e6;  // MHz
  localparam RESET_TIME = 100;    // ns

  /*********************************************
  ** Clock, Reset, & Testbench timeout
  *********************************************/
  reg clk;
  initial clk = 1'b0;
  localparam CLOCK_PERIOD = 1e9/CLOCK_FREQ;
  always
    #(CLOCK_PERIOD) clk = ~clk;

  reg rst;
  wire rst_n;
  assign rst_n = ~rst;
  initial
  begin
    rst = 1'b1;
    #(RESET_TIME) rst = 1'b0;
  end

  reg [63:0] i_tdata;
  reg i_tlast, i_tvalid;
  wire i_tready;
  wire [63:0] o_tdata;
  wire o_tlast, o_tvalid, o_tready;

  /*********************************************
  ** Helper Tasks
  *********************************************/
  `include "rfnoc_sim_lib.v"

  /*********************************************
  ** DUT
  *********************************************/
  noc_block_addsub inst_noc_block_addsub (
    .bus_clk(clk), .bus_rst(rst),
    .ce_clk(clk), .ce_rst(rst),
    .i_tdata(i_tdata), .i_tlast(i_tlast), .i_tvalid(i_tvalid), .i_tready(i_tready),
    .o_tdata(o_tdata), .o_tlast(o_tlast), .o_tvalid(o_tvalid), .o_tready(o_tready),
    .debug());

  assign o_tready = 1'b1;

  initial
  begin
    i_tdata = 64'd0;
    i_tvalid = 1'b0;
    i_tlast = 1'b0;
    @(negedge rst);
    @(posedge clk);

    // Port 0
    SendCtrlPacket(12'd0, 32'h0003_0000, {SR_FLOW_CTRL_PKTS_PER_ACK_BASE, 32'h8000_0001}); // Command packet to set up flow control
    SendCtrlPacket(12'd0, 32'h0003_0000, {SR_FLOW_CTRL_WINDOW_SIZE_BASE, 32'h0000_0004});  // Command packet to set up source control window size
    SendCtrlPacket(12'd0, 32'h0003_0000, {SR_FLOW_CTRL_WINDOW_EN_BASE, 32'h0000_0001});    // Command packet to set up source control window enable
    SendCtrlPacket(12'd0, 32'h0003_0000, {SR_NEXT_DST_BASE, 32'h0000_000A});               // Set next destination
    #10000;
    // Port 1
    SendCtrlPacket(12'd0, 32'h0003_0001, {SR_FLOW_CTRL_PKTS_PER_ACK_BASE+1, 32'h8000_0001}); // Command packet to set up flow control
    SendCtrlPacket(12'd0, 32'h0003_0001, {SR_FLOW_CTRL_WINDOW_SIZE_BASE+1, 32'h0000_0004});  // Command packet to set up source control window size
    SendCtrlPacket(12'd0, 32'h0003_0001, {SR_FLOW_CTRL_WINDOW_EN_BASE+1, 32'h0000_0001});    // Command packet to set up source control window enable
    SendCtrlPacket(12'd0, 32'h0003_0001, {SR_NEXT_DST_BASE+1, 32'h0000_000B});                 // Set next destination
    
    #10000;
    @(posedge clk);
    SendDataPacket(2'd0, 12'd0, 8*8, 32'h0003_0000, {16'd1, 16'd2, 16'd3, 16'd0});
    SendDataPacket(2'd0, 12'd0, 8*8, 32'h0003_0001, {16'd1, 16'd2, 16'd3, 16'd0});
  end

endmodule