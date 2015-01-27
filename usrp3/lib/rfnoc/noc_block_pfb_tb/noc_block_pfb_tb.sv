//
// Copyright 2014 Ettus Research LLC
//
`timescale 1ns/1ps

module noc_block_pfb_tb();
  // rfnoc_sim_lib options
  `define NUM_CE 1          // Redefined to correct value
  `define RFNOC_SIM_LIB_INC_AXI_WRAPPER
  `define SIMPLE_MODE 0
  `include "rfnoc_sim_lib.v" 

  /*********************************************
  ** DUT
  *********************************************/
  noc_block_pfb inst_noc_block_pfb (
    .bus_clk(bus_clk), .bus_rst(bus_rst),
    .ce_clk(ce_clk), .ce_rst(ce_rst),
    .i_tdata(ce_o_tdata[0]), .i_tlast(ce_o_tlast[0]), .i_tvalid(ce_o_tvalid[0]), .i_tready(ce_o_tready[0]),
    .o_tdata(ce_i_tdata[0]), .o_tlast(ce_i_tlast[0]), .o_tvalid(ce_i_tvalid[0]), .o_tready(ce_i_tready[0]),
    .debug());

  localparam [ 3:0] PFB_XBAR_PORT = 4'd0;
  localparam [15:0] PFB_SID       = {XBAR_ADDR, PFB_XBAR_PORT, 4'd0};

  localparam [15:0] VECTOR_SIZE = 8;
  
  integer i;
  reg [31:0] payload = 32'd0;

  initial begin
    @(negedge ce_rst);
    @(posedge ce_clk);
    
    // Setup Vector IIR
    SendCtrlPacket(PFB_SID, {24'd0, SR_FLOW_CTRL_PKTS_PER_ACK_BASE, 32'h8000_0001});                  // Command packet to set up flow control
    SendCtrlPacket(PFB_SID, {24'd0, SR_FLOW_CTRL_WINDOW_SIZE_BASE, 32'h0000_0FFF});                   // Command packet to set up source control window size
    SendCtrlPacket(PFB_SID, {24'd0, SR_FLOW_CTRL_WINDOW_EN_BASE, 32'h0000_0001});                     // Command packet to set up source control window enable
    SendCtrlPacket(PFB_SID, {24'd0, SR_NEXT_DST_BASE, {16'd0, TESTBENCH_SID}});                       // Set next destination
     //SendCtrlPacket(PFB_SID, {24'd0, inst_noc_block_pfb.SR_VECTOR_LEN, {16'd0, VECTOR_SIZE}});  // Set Vector length register
    #1000;

    tb_next_dst = PFB_SID;
    @(posedge ce_clk);
    forever begin
      for (i = 0; i < VECTOR_SIZE; i = i + 1) begin
        payload[31:16] = 2*i;
        payload[15: 0] = 2*i+1;
        SendAxi(payload,(i == VECTOR_SIZE-1)); // Assert tlast on final word
      end
    end
  end

  // Assertions
  integer k, l;
  reg [31:0] expected_payload[0:VECTOR_SIZE-1];
  reg [31:0] received_payload;
  reg last;
  localparam NUM_PASSES = 20;
  initial begin
    // Initialize local verification vector to 0
    for (k = 0; k < VECTOR_SIZE; k = k + 1) begin
      expected_payload[k] = 32'd0;
    end
    @(negedge ce_rst);
    @(posedge ce_clk);
    $display("*****************************************************");
    $display("**              Begin Assertion Tests              **");
    $display("*****************************************************");
    for (l = 0; l < NUM_PASSES; l = l + 1) begin
      for (k = 0; k < VECTOR_SIZE; k = k + 1) begin
        RecvAxi(received_payload,last);
        expected_payload[k][31:16] = expected_payload[k][31:16] + 2*k;
        expected_payload[k][15: 0] = expected_payload[k][15: 0] + 2*k+1;
        assert(expected_payload[k] == received_payload) else begin $error("Vector IIR output incorrect! Received: %x Expected: %x",received_payload,expected_payload); $stop(); end
        assert((k != VECTOR_SIZE-1) == (last == 1'b0)) else begin $error("Detected early tlast!"); $stop(); end
        assert((k == VECTOR_SIZE-1) == (last == 1'b1)) else begin $error("Detected late tlast!"); $stop(); end
      end
      $display("Test loop %d PASSED!",l);
    end
    $display("All tests PASSED!");
  end

endmodule