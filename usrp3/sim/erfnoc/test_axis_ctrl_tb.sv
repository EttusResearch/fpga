//
// Copyright 2019 Ettus Research, A National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// Module: test_axis_ctrl_tb
//
// Description: Simple demo of the AXIS-Ctrl BFM.
//

`default_nettype none


import PkgTestExec::*;
import PkgChdrUtils::*;
import PkgAxisCtrlBfm::*;



//-----------------------------------------------------------------------------
// Testbench Module
//-----------------------------------------------------------------------------


module test_axis_ctrl_tb;

  //---------------------------------------------------------------------------
  // Simulation Timing
  //---------------------------------------------------------------------------

  timeunit 1ns;
  timeprecision 1ps;


  //---------------------------------------------------------------------------
  // Parameters
  //---------------------------------------------------------------------------

  localparam WIDTH = 32;


  //---------------------------------------------------------------------------
  // Clock and Reset Definition
  //---------------------------------------------------------------------------

  bit chdr_clk, chdr_rst;

  sim_clock_gen #(5.0)  chdr_clk_gen (chdr_clk, chdr_rst);  // 200 MHz


  //---------------------------------------------------------------------------
  // Instantiate RFNoC BFM
  //---------------------------------------------------------------------------

  // CHDR and Control interfaces
  AxiStreamIf #(WIDTH) rfnoc_chdr_a2b (chdr_clk, chdr_rst);
  AxiStreamIf #(WIDTH) rfnoc_chdr_b2a (chdr_clk, chdr_rst);

  // BFM instance
  AxisCtrlBfm bfm_a;
  AxisCtrlBfm bfm_b;


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
    test = new("test_axis_ctrl_tb");
    test.start_tb();

    // Start the BFMs
    bfm_a = new(rfnoc_chdr_a2b, rfnoc_chdr_b2a);   // I expected to use .master and .slave, but that doesn't work with Vivado (does with modelsim)
    bfm_b = new(rfnoc_chdr_b2a, rfnoc_chdr_a2b);
    bfm_a.set_master_stall_prob(60);
    bfm_b.set_slave_stall_prob(60);
    bfm_a.run();
    bfm_b.run();

    // Start the clock
    chdr_clk_gen.start();


    //-------------------------------------------------------------------------
    // Reset
    //-------------------------------------------------------------------------

    // Assert reset
    chdr_clk_gen.reset();

    test.start_test("Wait for reset");
    test.start_timeout(timeout, 1us, "Waiting for reset");
    while (!chdr_rst) @(posedge chdr_clk);
    while (chdr_rst)  @(posedge chdr_clk);
    test.end_timeout(timeout);
    test.assert_error(!chdr_rst, "Reset did not deassert");
    test.end_test();


    //-------------------------------------------------------------------------
    // Test send and receive packets
    //-------------------------------------------------------------------------

    test.start_test("Test full packet BFM send/receive");
    begin
      AxisCtrlPacket tx_ctrl_packet, rx_ctrl_packet;
      axis_ctrl_header_t header;
      ctrl_op_word_t op_word;
      ctrl_word_t data[$];

      tx_ctrl_packet = new();

      // Build packet
      data = { 1, 2, 3, 4 };
      header = { $urandom(), $urandom(), $urandom() };
      tx_ctrl_packet.write_ctrl(header, op_word, data);

      test.start_timeout(timeout, 1us, "Waiting for packet to transfer");
      bfm_a.put_ctrl(tx_ctrl_packet.copy());
      bfm_b.get_ctrl(rx_ctrl_packet);
      test.end_timeout(timeout);

      // Check if the received packet
      test.assert_error(tx_ctrl_packet.equal(rx_ctrl_packet),
        "Received packet did not match transmitted packet");      
    end
    test.end_test();

    test.start_test("Test another BFM send/receive");
    begin
      AxisCtrlPacket tx_ctrl_packet, rx_ctrl_packet;

      // Build packet
      tx_ctrl_packet = new();
      tx_ctrl_packet.data = { 5, 6, 7, 8, 9 };
      tx_ctrl_packet.header = {$urandom(), $urandom()};
      tx_ctrl_packet.op_word = $urandom();
      tx_ctrl_packet.header.num_data = 5;

      test.start_timeout(timeout, 1us, "Waiting for packet to transfer");
      bfm_a.put_ctrl(tx_ctrl_packet.copy());
      bfm_b.get_ctrl(rx_ctrl_packet);
      test.end_timeout(timeout);

      // Check if the received packet
      test.assert_error(tx_ctrl_packet.equal(rx_ctrl_packet),
        "Received packet did not match transmitted packet");
    end
    test.end_test();



    //-------------------------------------------------------------------------
    // Finish Up
    //-------------------------------------------------------------------------

    // Display final statistics and results
    test.end_tb(0);
    
    // Stop the simulation
    chdr_clk_gen.kill();

  end

endmodule : test_axis_ctrl_tb
