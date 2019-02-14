//
// Copyright 2019 Ettus Research, A National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// Module: test_tb
//
// Description: Simple demo of AXI Stream BFM.
//

`default_nettype none


import PkgTestExec::*;
import PkgAxiStreamBfm::*;



//-----------------------------------------------------------------------------
// Testbench Module
//-----------------------------------------------------------------------------


module test_axi_stream_tb;

  //---------------------------------------------------------------------------
  // Simulation Timing
  //---------------------------------------------------------------------------

  timeunit 1ns;
  timeprecision 1ps;


  //---------------------------------------------------------------------------
  // Parameters
  //---------------------------------------------------------------------------

  localparam DATA_W = 64;
  localparam USER_W = 16;


  //---------------------------------------------------------------------------
  // Clock and Reset Definition
  //---------------------------------------------------------------------------

  bit chdr_clk, chdr_rst;
  bit test_clk, test_rst;

  sim_clock_gen #(5.0)  chdr_clk_gen (chdr_clk, chdr_rst);  // 200 MHz
  sim_clock_gen #(10.0) test_clk_gen (test_clk, test_rst);  // 100 MHz


  //---------------------------------------------------------------------------
  // Instantiate RFNoC BFM
  //---------------------------------------------------------------------------

  // CHDR and Control interfaces
  AxiStreamIf #(DATA_W, USER_W) rfnoc_chdr_a2b (chdr_clk, chdr_rst);
  AxiStreamIf #(DATA_W, USER_W) rfnoc_chdr_b2a (chdr_clk, chdr_rst);

  // BFM instance
  AxiStreamBfm #(DATA_W, USER_W) stream_bfm_a, stream_bfm_b;

  // Import packet data types
  typedef AxiStreamBfm #(DATA_W, USER_W)::AxisPacket AxisPacket;
  

  //---------------------------------------------------------------------------
  // Instantiate DUT
  //---------------------------------------------------------------------------

  // Just BFMs for now


  //---------------------------------------------------------------------------
  // Test Process
  //---------------------------------------------------------------------------

  TestExec test;
  

  initial begin
    timeout_t timeout;


    //-------------------------------------------------------------------------
    // Initialize
    //-------------------------------------------------------------------------

    // Initialize test object for tracking test status results
    test = new("test_axi_stream_tb");
    test.start_tb();

    // Start the BFMs
    stream_bfm_a = new(rfnoc_chdr_a2b, rfnoc_chdr_b2a);   // I expected to use .master and .slave, but that doesn't work with Vivado (does with modelsim)
    stream_bfm_b = new(rfnoc_chdr_b2a, rfnoc_chdr_a2b);
    stream_bfm_a.set_master_stall_prob(60);
    stream_bfm_b.set_slave_stall_prob(60);
    stream_bfm_a.run();
    stream_bfm_b.run();

    // Start the clock
    chdr_clk_gen.start();
    #10ns;
    test_clk_gen.start();

    //-------------------------------------------------------------------------
    // Reset
    //-------------------------------------------------------------------------

    // Assert reset
    chdr_clk_gen.reset();
    #10ns;
    test_clk_gen.reset();

    test.start_test("Wait for reset");
    test.start_timeout(timeout, 1us, "Waiting for reset");
    while (chdr_rst || test_rst) @(posedge chdr_clk);
    test.end_timeout(timeout);
    test.assert_error(chdr_rst == 0, "chdr_rst didn't deassert");
    test.assert_error(test_rst == 0, "test_rst didn't deassert");
    test.end_test();


    //-------------------------------------------------------------------------
    // Send test packet
    //-------------------------------------------------------------------------

    test.start_test("Test packet BFM send/receive");
    begin
      AxisPacket tx_packet, rx_packet;

      tx_packet = new();
    
      // Create some data
      tx_packet.data  = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 };
      tx_packet.user  = { 9, 8, 7, 6, 5, 4, 3, 2, 1, 0 };
      tx_packet.keep  = { 3, 2, 1, 0, 1, 2, 3, 4, 5, 6 };
  
      test.start_timeout(timeout, 1us, test.current_test);

      // Send the data in a packet
      stream_bfm_a.put(tx_packet.copy());
  
      // Wait for the packet to be received by BFM B
      // This works in ModelSim but not Vivado:  wait(stream_bfm_b.recv_waiting());
      while (!stream_bfm_b.num_received()) chdr_clk_gen.clk_wait_r();
  
      // Read the data
      stream_bfm_b.get(rx_packet);

      test.end_timeout(timeout);

      $display("Sent:\n%s", tx_packet.sprint());
      $display("Received:\n%s", rx_packet.sprint());
      
      // Check if the data matches
      test.assert_error(stream_bfm_a.packets_equal(tx_packet, rx_packet), 
        "Received data did not match transmitted data");
    end
    test.end_test();


    //-------------------------------------------------------------------------
    // Play around
    //-------------------------------------------------------------------------

    test.start_test("Test clock changes");

    chdr_clk_gen.set_period(10);
    test_clk_gen.set_period(1);
    #0.5us;
    
    $display("Stopping the clock");
    chdr_clk_gen.stop();
    #0.5us;

    // Not testing anything for now
    test.assert_error(1, "Everything is AOK");

    test.end_test();


    //-------------------------------------------------------------------------
    // Finish Up
    //-------------------------------------------------------------------------

    // Display final statistics and results
    test.end_tb(0);
    
    // Stop the simulation
    chdr_clk_gen.kill();
    test_clk_gen.kill();

  end

endmodule
