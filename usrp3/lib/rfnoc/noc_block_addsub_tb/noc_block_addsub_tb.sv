//
// Copyright 2014 Ettus Research LLC
//
`timescale 1ns/1ps

module noc_block_addsub_tb();
  // rfnoc_sim_lib options
  `define NUM_CE 1          // Redefined to correct value
  `define RFNOC_SIM_LIB_INC_AXI_WRAPPER
  `define SIMPLE_MODE 0
  `include "rfnoc_sim_lib.v"

  /*********************************************
  ** DUT
  *********************************************/
  noc_block_addsub inst_noc_block_addsub (
    .bus_clk(bus_clk), .bus_rst(bus_rst),
    .ce_clk(ce_clk), .ce_rst(ce_rst),
    .i_tdata(ce_o_tdata[0]), .i_tlast(ce_o_tlast[0]), .i_tvalid(ce_o_tvalid[0]), .i_tready(ce_o_tready[0]),
    .o_tdata(ce_i_tdata[0]), .o_tlast(ce_i_tlast[0]), .o_tvalid(ce_i_tvalid[0]), .o_tready(ce_i_tready[0]),
    .debug());

  localparam [ 3:0] ADDSUB_XBAR_PORT = 4'd0;
  localparam [15:0] ADDSUB_SID       = {XBAR_ADDR, ADDSUB_XBAR_PORT, 4'd0};

  initial begin
    @(negedge ce_rst);
    @(posedge ce_clk);

    // Configure Block Port 0
    SendCtrlPacket(ADDSUB_SID, {24'd0, SR_FLOW_CTRL_PKTS_PER_ACK_BASE, 32'h8000_0001});              // Command packet to set up flow control
    SendCtrlPacket(ADDSUB_SID, {24'd0, SR_FLOW_CTRL_WINDOW_SIZE_BASE, 32'h0000_0FFF});               // Command packet to set up source control window size
    SendCtrlPacket(ADDSUB_SID, {24'd0, SR_FLOW_CTRL_WINDOW_EN_BASE, 32'h0000_0001});                 // Command packet to set up source control window enable
    SendCtrlPacket(ADDSUB_SID, {24'd0, SR_NEXT_DST_BASE, {16'd0, TESTBENCH_SID}});                   // Set next destination
    #10000;
    // Configure Block Port 1
    SendCtrlPacket(ADDSUB_SID, {24'd0, SR_FLOW_CTRL_PKTS_PER_ACK_BASE+1, 32'h8000_0001});              // Command packet to set up flow control
    SendCtrlPacket(ADDSUB_SID, {24'd0, SR_FLOW_CTRL_WINDOW_SIZE_BASE+1, 32'h0000_0FFF});               // Command packet to set up source control window size
    SendCtrlPacket(ADDSUB_SID, {24'd0, SR_FLOW_CTRL_WINDOW_EN_BASE+1, 32'h0000_0001});                 // Command packet to set up source control window enable
    SendCtrlPacket(ADDSUB_SID, {24'd0, SR_NEXT_DST_BASE+1, {16'd0, TESTBENCH_SID}});                 // Set next destination
    
    #10000;
    @(posedge ce_clk);
    // Send to block port 0
    tb_next_dst = ADDSUB_SID;
    SendAxi({16'd1,16'd2},0);
    SendAxi({16'd3,16'd4},1);
    // Send to block port 1
    tb_next_dst = ADDSUB_SID+1;
    SendAxi({16'd1,16'd2},0);
    SendAxi({-16'd3,-16'd4},1);
  end

  // Assertions
  reg [64:0] payload;
  reg last;
  initial begin
    @(negedge ce_rst);
    @(posedge ce_clk);
    $display("*****************************************************");
    $display("**              Begin Assertion Tests              **");
    $display("*****************************************************");
    RecvAxi(payload[64:32],last);
    assert(last == 1'b0) else begin $error("Detected early tlast!"); $stop(); end
    RecvAxi(payload[31:0],last);
    assert(last == 1'b1) else begin $error("Detected late tlast!"); $stop(); end
    assert(payload == 64'h0002000400000000) else begin $error("Addition result incorrect!"); $stop(); end
    $display("Addition test PASSED!");
    RecvAxi(payload[64:32],last);
    assert(last == 1'b0) else begin $error("Detected early tlast!"); $stop(); end
    RecvAxi(payload[31:0],last);
    assert(last == 1'b1) else begin $error("Detected late tlast!"); $stop(); end
    assert(payload == 64'h0000000000060008) else begin $error("Subtraction result incorrect!"); $stop(); end
    $display("Subtraction test PASSED!");
    $display("All tests PASSED!");
  end

endmodule