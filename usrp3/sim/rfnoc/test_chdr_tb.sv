//
// Copyright 2019 Ettus Research, A National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// Module: test_chdr_tb
//
// Description: Simple demo of the CHDR testbench BFM.
//

`default_nettype none


import PkgTestExec::*;
import PkgChdrUtils::*;
import PkgChdrBfm::*;



//-----------------------------------------------------------------------------
// Testbench Module
//-----------------------------------------------------------------------------


module test_chdr_tb;

  //---------------------------------------------------------------------------
  // Simulation Timing
  //---------------------------------------------------------------------------

  timeunit 1ns;
  timeprecision 1ps;


  //---------------------------------------------------------------------------
  // Parameters
  //---------------------------------------------------------------------------

  localparam WIDTH = 256;


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
  ChdrBfm #(WIDTH) bfm_a, bfm_b;

  // Import packet data types
  typedef ChdrBfm #(WIDTH)::ChdrPacket ChdrPacket;
  typedef ChdrBfm #(WIDTH)::AxisPacket AxisPacket;
  

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
    test = new("test_chdr_tb");
    test.start_tb();

    // Start the BFMs
    bfm_a = new(rfnoc_chdr_a2b, rfnoc_chdr_b2a);   // I expected to use .master and .slave, but that doesn't work with Vivado (does with modelsim)
    bfm_b = new(rfnoc_chdr_b2a, rfnoc_chdr_a2b);
    bfm_a.set_master_stall_prob(60);
    bfm_b.set_slave_stall_prob(60);
    bfm_a.run();
    bfm_b.run();

    // Start the clock
    //chdr_clk_gen.start();


    //-------------------------------------------------------------------------
    // Reset
    //-------------------------------------------------------------------------

    // Assert reset
    chdr_clk_gen.reset();
    #10ns;

    test.start_test("Wait for reset");
    test.start_timeout(timeout, 1us, "Waiting for reset");
    while (chdr_rst) @(posedge chdr_clk);
    test.end_timeout(timeout);
    test.assert_error(chdr_rst == 0, "chdr_rst didn't deassert");
    test.end_test();


    //-------------------------------------------------------------------------
    // Test send and receive packets
    //-------------------------------------------------------------------------

    test.start_test("Test full packet send/receive");
    begin
      ChdrPacket tx_packet, rx_packet;
      chdr_header_t header;
      chdr_word_t data[$];
      chdr_word_t metadata[$];
      chdr_word_t timestamp;

      tx_packet = new();

      $display("*****************************************************************");
      $display("Packet bus width is %d", tx_packet.BUS_WIDTH);
      $display("*****************************************************************");

      // Build packet
      header = '{
        pkt_type  : CHDR_DATA_WITH_TS,
        seq_num   : 5678,
        dst_epid  : 'hABCD,
        default   : 0
      };
      data      = { 'hA000, 'hA001, 'hA002, 'hA003, 'hA004, 'hA005, 'hA006, 'hA007, 'hA008, 'hA009, 'hA00A, 'hA00B, 'hA00C, 'hA00D, 'hA00E, 'hA00F };
      metadata  = { 'hB000, 'hB001, 'hB002, 'hB003, 'hB004, 'hB005, 'hB006, 'hB007 };
      timestamp = 1234;
      tx_packet.write_raw(header, data, metadata, timestamp);

      test.start_timeout(timeout, 1us, test.current_test);

      bfm_a.put_chdr(tx_packet.copy());
      bfm_b.get_chdr(rx_packet);

      test.end_timeout(timeout);

      $display("Sent:\n%s", tx_packet.sprint());
      $display("Received:\n%s", rx_packet.sprint());

      // Check if the received packet
      test.assert_error(tx_packet.equal(rx_packet),
        "Received packet did not match transmitted packet");
    end
    test.end_test();


    test.start_test("Test stream status send/receive");
    begin
      ChdrPacket tx_packet, rx_packet;
      chdr_header_t header;
      chdr_str_status_t tx_status, rx_status;

      tx_packet = new();

      // Build packet
      header = '{
        seq_num  : 5678,
        dst_epid : 'hABCD,
        pkt_type : CHDR_STRM_STATUS,
        default  : 0
      };
      tx_status = '{
        status_info      : 1,
        buff_info        : 2,
        xfer_count_bytes : 3,
        xfer_count_pkts  : 4,
        capacity_pkts    : 5,
        capacity_bytes   : 6,
        reserved         : 7,
        status           : 8,
        src_epid         : 9
      };
      tx_packet.write_stream_status(header, tx_status);

      test.start_timeout(timeout, 1us, test.current_test);

      bfm_a.put_chdr(tx_packet.copy());
      bfm_b.get_chdr(rx_packet);

      test.end_timeout(timeout);

      $display("Sent packet:\n%s", tx_packet.sprint());
      $display("Received packet:\n%s", rx_packet.sprint());

      rx_packet.read_stream_status(header, rx_status);

      $display("Sent status:     %p", tx_status);
      $display("Received status: %p", rx_status);

      // Check if the received status matches
      test.assert_error(tx_status == rx_status, 
        "Received status did not match transmitted status");
    end
    test.end_test();


    test.start_test("Test stream command send/receive");
    begin
      ChdrPacket tx_packet, rx_packet;
      chdr_header_t header;
      chdr_str_command_t tx_command, rx_command;

      tx_packet = new();

      // Build packet
      header = '{
        seq_num  : 5678,
        dst_epid : 'hABCD,
        pkt_type : CHDR_STRM_CMD,
        default  : 0
      };
      tx_command = '{
        num_bytes   : 1,
        num_pkts    : 2,
        op_data     : 3,
        op_code     : 4,
        src_epid    : 5
      };

      tx_packet.write_stream_cmd(header, tx_command);

      test.start_timeout(timeout, 1us, test.current_test);

      bfm_a.put_chdr(tx_packet.copy());
      bfm_b.get_chdr(rx_packet);

      test.end_timeout(timeout);

      $display("Sent packet:\n%s", tx_packet.sprint());
      $display("Received packet:\n%s", rx_packet.sprint());

      rx_packet.read_stream_cmd(header, rx_command);

      $display("Sent command:     %p", tx_command);
      $display("Received command: %p", rx_command);

      // Check if the received command matches
      test.assert_error(tx_command == rx_command, 
        "Received command did not match transmitted command");
    end
    test.end_test();


    test.start_test("Test management send/receive");
    begin
      ChdrPacket tx_packet, rx_packet;
      chdr_header_t header;
      chdr_mgmt_t tx_mgmt, rx_mgmt;

      tx_packet = new();

      // Build packet
      header = '{
        seq_num  : 5678,
        dst_epid : 'hABCD,
        pkt_type : CHDR_MANAGEMENT,
        default  : 0
      };
      tx_mgmt.header = '{
        prot_ver   : 1,
        chdr_width : 2,
        reserved   : 3,
        num_hops   : 4,
        src_epid   : 5
      };
      tx_mgmt.ops[0] = '{
        op_payload  : 6,
        op_code     : 7,
        ops_pending : 8
      };
      tx_mgmt.ops[1] = '{
        op_payload  :  9,
        op_code     : 10,
        ops_pending : 11
      };
      tx_mgmt.ops[2] = '{
        op_payload  : 12,
        op_code     : 13,
        ops_pending : 14
      };

      tx_packet.write_mgmt(header, tx_mgmt);

      test.start_timeout(timeout, 1us, test.current_test);

      bfm_a.put_chdr(tx_packet.copy());
      bfm_b.get_chdr(rx_packet);

      test.end_timeout(timeout);

      $display("Sent packet:\n%s", tx_packet.sprint());
      $display("Received packet:\n%s", rx_packet.sprint());

      rx_packet.read_mgmt(header, rx_mgmt);

      $display("Sent command:     %p", tx_mgmt);
      $display("Received command: %p", rx_mgmt);

      // Check if the received management matches
      // Vivado can't compare queues correctly, so this is a little hokey
      test.assert_error(
        tx_mgmt.header == rx_mgmt.header && chdr_mgmt_op_queues_equal(tx_mgmt.ops, rx_mgmt.ops), 
        "Received management did not match transmitted management"
      );
    end
    test.end_test();

        
    test.start_test("Test AXI packet");
    begin
      AxisPacket tx_axis_packet, rx_axis_packet;
    
      // Create some data
      tx_axis_packet = new();
      for (int i = 0; i < 11; i++) begin
        tx_axis_packet.data.push_back($urandom());
        tx_axis_packet.user.push_back($urandom());
        tx_axis_packet.keep.push_back($urandom());
      end;
    
      test.start_timeout(timeout, 1us, test.current_test);
      bfm_a.put(tx_axis_packet.copy());
      bfm_b.get(rx_axis_packet);
      test.end_timeout(timeout);

      $display("Sent:\n%s", tx_axis_packet.sprint());
      $display("Received:\n%s", rx_axis_packet.sprint());

      // Check if the data matches
      test.assert_error(tx_axis_packet.equal(rx_axis_packet),
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

endmodule : test_chdr_tb
