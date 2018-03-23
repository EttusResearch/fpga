//
// Copyright 2017 Ettus Research, A National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0
//
// Module: noc_block_replay_tb
// Description: This is a testbench for the noc_block_replay component.

`timescale 1ns/1ps
`define NS_PER_TICK 1

// Number of test cases we plan to simulation
`define NUM_TEST_CASES 16

`include "sim_exec_report.vh"
`include "sim_clks_rsts.vh"
`include "sim_rfnoc_lib.svh"


module noc_block_replay_tb ();

  //---------------------------------------------------------------------------
  // Declarations
  //---------------------------------------------------------------------------

  // Configuration
  localparam USE_SRAM_MEMORY = 1;    // Set to 1 for faster simulation that
                                     // uses SRAM instead of DRAM.
  localparam BUS_CLK_PERIOD = 6.0;   // 166.667 MHz
  localparam CE_CLK_PERIOD  = 4.667; // 214.286 MHz
  localparam NUM_CE         = 1;     // Number of Computation Engines / User RFNoC blocks to simulate
  localparam NUM_STREAMS    = 2;     // Number of test bench streams
  localparam SPP            = 512;   // Number of byte samples per packet
  localparam USE_RANDOM     = 1;     // Use random instead of sequential data.
                                     // Random is better for catching errors, 
                                     // but sequential is easier for debugging.

  // Register offsets
  localparam [7:0] SR_REC_BASE_ADDR    = 128;
  localparam [7:0] SR_REC_BUFFER_SIZE  = 129;
  localparam [7:0] SR_REC_RESTART      = 130;
  localparam [7:0] SR_REC_FULLNESS     = 131;
  localparam [7:0] SR_PLAY_BASE_ADDR   = 132;
  localparam [7:0] SR_PLAY_BUFFER_SIZE = 133;
  localparam [7:0] SR_RX_CTRL_COMMAND  = 152; // Same offset as radio
  localparam [7:0] SR_RX_CTRL_HALT     = 155; // Same offset as radio
  localparam [7:0] SR_RX_CTRL_MAXLEN   = 156; // Same offset as radio

  // Memory burst size in 64-bit words, as defined in the axi_replay block. 
  // This is essentially hard coded to match the maximum transfer size 
  // supported by the DMA master.
  localparam MEM_BURST_SIZE = 256;

  // Number of bytes per word
  localparam WORD_SIZE = 8;

  // AXI alignment boundary, in bytes
  localparam AXI_ALIGNMENT = 4096;

  int test_step; // Current test number, for tracking progress in waveform view


  //---------------------------------------------------------------------------
  // Testbench Initialization
  //---------------------------------------------------------------------------

  `TEST_BENCH_INIT("noc_block_replay_tb", `NUM_TEST_CASES, `NS_PER_TICK);
  `DEFINE_CLK(sys_clk, 10, 50)            // 100 MHz sys_clk to generate DDR3 clocking
  `DEFINE_RESET_N(sys_rst_n, 0, 100)      // 100 ns for GSR to deassert
  `RFNOC_SIM_INIT(NUM_CE, NUM_STREAMS, BUS_CLK_PERIOD, CE_CLK_PERIOD);
  `RFNOC_ADD_BLOCK_CUSTOM(noc_block_replay, 0);

  
  //---------------------------------------------------------------------------
  // DUT
  //---------------------------------------------------------------------------

  wire init_done;

  replay_sim_wrapper #(
    .USE_SRAM_MEMORY(USE_SRAM_MEMORY)
  ) replay_sim_wrapper_i (
    .bus_clk   (bus_clk),
    .bus_rst   (bus_rst),
    .ce_clk    (ce_clk),
    .ce_rst    (ce_rst),
    .sys_clk   (sys_clk),
    .sys_rst_n (sys_rst_n),
    .i_tdata   (noc_block_replay_i_tdata),
    .i_tlast   (noc_block_replay_i_tlast),
    .i_tvalid  (noc_block_replay_i_tvalid),
    .i_tready  (noc_block_replay_i_tready),
    .o_tdata   (noc_block_replay_o_tdata),
    .o_tlast   (noc_block_replay_o_tlast),
    .o_tvalid  (noc_block_replay_o_tvalid),
    .o_tready  (noc_block_replay_o_tready),
    .init_done (init_done)
  );


  //---------------------------------------------------------------------------
  // Tasks
  //---------------------------------------------------------------------------

  // Read out and discard all packets received, stopping after there's been no 
  // packets for a delay of "timeout".
  task automatic flush_rx(input int  stream  = 0,
                          input time timeout = CE_CLK_PERIOD*100);
    cvita_payload_t  recv_payload;
    cvita_metadata_t md;
    time             prev_time;

    begin
      prev_time = $time;

      while (1) begin
        // Check if there's a frame waiting
        if (noc_block_tb.str_sink_tvalid[stream]) begin
          // Read frame
          tb_streamer.recv(recv_payload, md, stream); 
          // Restart timeout
          prev_time = $time;   

        end else begin
          // If timeout has expired, we're done
          if ($time - prev_time > timeout) break;
          // No frame, so wait a cycle
          #(CE_CLK_PERIOD);
        end
      end
    end
  endtask : flush_rx


  // Wait until the expected number of words are accumulated in the record 
  // buffer. Produce a failure if the data never arrives.
  task automatic wait_record_fullness(input int  num_bytes,
                                      input time timeout,
                                      input int  block_num = 0);
    time         prev_time;
    logic [63:0] readback;

    begin
      // Poll SR_REC_FULLNESS until fullness is reached
      prev_time = $time;
      while (1) begin
        tb_streamer.read_user_reg(sid_noc_block_replay, SR_REC_FULLNESS, readback, block_num);
        if (readback >= num_bytes) break;

        // Check if it's taking too long
        if ($time - prev_time > timeout) begin
          `ASSERT_FATAL(0, "Timeout waiting for fullness to be reached");
        end
      end
    end
  endtask : wait_record_fullness


  // Read the data on the indicated stream and check that it matches 
  // exp_payload. Also check that the length of the packets received add up to 
  // the length of exp_payload, if it takes multiple packets. An error string 
  // is returned if there's an error, otherwise an empty string.
  task automatic verify_rx_data(output string         error_msg,
                                input cvita_payload_t exp_payload,
                                input int             stream = 0);
    cvita_payload_t  recv_payload;
    cvita_metadata_t md;
    int              word_count;
    int              packet_count;
    logic     [63:0] expected_value;

    begin
      word_count   = 0;
      packet_count = 0;
      error_msg    = "";
  
      while (word_count < exp_payload.size()) begin
        // Grab the next frame
        while (recv_payload.size() > 0) recv_payload.pop_back();
        tb_streamer.recv(recv_payload, md, stream);

        // Check the size
        if (word_count + recv_payload.size() > exp_payload.size()) begin
          $sformat(error_msg, 
                   "On packet %0d, size exceeds expected by %0d words", 
                   packet_count, 
                   (word_count + recv_payload.size()) - exp_payload.size());
          return;
        end
        packet_count++;

        // Check the data
        for (int i = 0; i < recv_payload.size(); i++) begin
          expected_value = exp_payload[word_count];
          // FIXME Logical compares not supported yet?
          if (recv_payload[i] != expected_value) begin
            $sformat(error_msg, 
                     "On word %0d (packet %0d, word offset %0d), Expected: 0x%0x, Received: 0x%0x", 
                     word_count, packet_count, i, expected_value, recv_payload[i]);
            return;
          end
          word_count++;
        end
      end
    end
  endtask : verify_rx_data


  // Generate a payload that's either random or sequential data, depending on 
  // USE_RANDOM.
  task automatic gen_payload(output cvita_payload_t payload, 
                             input int              num_words);
    logic [63:0] word;

    static logic [63:0] count = 0;

    begin
      for (int i = 0; i < num_words; i += 1) begin
        if (USE_RANDOM) word = {$random, $random};
        else begin
          word = count;
          count++;
        end
        payload.push_back(word);
      end
    end
  endtask : gen_payload



  //---------------------------------------------------------------------------
  // Test Code
  //---------------------------------------------------------------------------
  
  initial begin : tb_main
    logic [31:0] random_word;
    logic [63:0] readback;
    string       str;


    //-------------------------------------------------------------------------
    // Test 1 -- Reset
    //-------------------------------------------------------------------------

    test_step = 1;
    `TEST_CASE_START("Wait for Reset");
    while (bus_rst) @(posedge bus_clk);
    while (ce_rst) @(posedge ce_clk);
    `TEST_CASE_DONE(~bus_rst & ~ce_rst);


    //-------------------------------------------------------------------------
    // Test 2 -- Check for correct NoC IDs
    //-------------------------------------------------------------------------

    test_step = 2;
    `TEST_CASE_START("Check NoC ID");

    // Read NOC IDs
    tb_streamer.read_reg(sid_noc_block_replay, RB_NOC_ID, readback);
    $display("Read NOC ID: %16x", readback);
    `ASSERT_ERROR(readback == noc_block_replay.NOC_ID, "Incorrect NOC ID");
    
    `TEST_CASE_DONE(1);


    //-------------------------------------------------------------------------
    // Test 3 -- Connect RFNoC blocks
    //-------------------------------------------------------------------------

    test_step = 3;
    `TEST_CASE_START("Connect RFNoC blocks");
    `RFNOC_CONNECT_BLOCK_PORT(noc_block_tb,     0, noc_block_replay, 0, S8, SPP);
    `RFNOC_CONNECT_BLOCK_PORT(noc_block_replay, 0, noc_block_tb,     0, S8, SPP);
    `RFNOC_CONNECT_BLOCK_PORT(noc_block_tb,     1, noc_block_replay, 1, S8, SPP);
    `RFNOC_CONNECT_BLOCK_PORT(noc_block_replay, 1, noc_block_tb,     1, S8, SPP);
    `TEST_CASE_DONE(1);


    //-------------------------------------------------------------------------
    // Test 4 -- Test Registers
    //-------------------------------------------------------------------------

    test_step = 4;
    `TEST_CASE_START("Test Registers");

    // Configure the RAM base addresses
    tb_streamer.write_reg(sid_noc_block_replay, SR_REC_BASE_ADDR,   8, 0);
    tb_streamer.write_reg(sid_noc_block_replay, SR_REC_BASE_ADDR,  16, 1);
    tb_streamer.write_reg(sid_noc_block_replay, SR_PLAY_BASE_ADDR, 24, 0);
    tb_streamer.write_reg(sid_noc_block_replay, SR_PLAY_BASE_ADDR, 32, 1);

    // Configure the RAM buffer sizes
    tb_streamer.write_reg(sid_noc_block_replay, SR_REC_BUFFER_SIZE,  40, 0);
    tb_streamer.write_reg(sid_noc_block_replay, SR_REC_BUFFER_SIZE,  48, 1);
    tb_streamer.write_reg(sid_noc_block_replay, SR_PLAY_BUFFER_SIZE, 56, 0);
    tb_streamer.write_reg(sid_noc_block_replay, SR_PLAY_BUFFER_SIZE, 64, 1);

    // Verify the registers
    tb_streamer.read_user_reg(sid_noc_block_replay, SR_REC_BASE_ADDR, readback, 0);
    `ASSERT_FATAL(readback == 8, "Incorrect base address, block 0")
    tb_streamer.read_user_reg(sid_noc_block_replay, SR_REC_BASE_ADDR, readback, 1);
    `ASSERT_FATAL(readback == 16, "Incorrect base address, block 1")
    tb_streamer.read_user_reg(sid_noc_block_replay, SR_PLAY_BASE_ADDR, readback, 0);
    `ASSERT_FATAL(readback == 24, "Incorrect base address, block 0")
    tb_streamer.read_user_reg(sid_noc_block_replay, SR_PLAY_BASE_ADDR, readback, 1);
    `ASSERT_FATAL(readback == 32, "Incorrect base address, block 1")
    //
    tb_streamer.read_user_reg(sid_noc_block_replay, SR_REC_BUFFER_SIZE, readback, 0);
    `ASSERT_FATAL(readback == 40, "Incorrect buffer size, block 0")
    tb_streamer.read_user_reg(sid_noc_block_replay, SR_REC_BUFFER_SIZE, readback, 1);
    `ASSERT_FATAL(readback == 48, "Incorrect buffer size, block 1")
    tb_streamer.read_user_reg(sid_noc_block_replay, SR_PLAY_BUFFER_SIZE, readback, 0);
    `ASSERT_FATAL(readback == 56, "Incorrect buffer size, block 0")
    tb_streamer.read_user_reg(sid_noc_block_replay, SR_PLAY_BUFFER_SIZE, readback, 1);
    `ASSERT_FATAL(readback == 64, "Incorrect buffer size, block 1")

    // Make sure the fullness is initially 0
    tb_streamer.read_user_reg(sid_noc_block_replay, SR_REC_FULLNESS, readback, 0);
    `ASSERT_FATAL(readback == 0, "Incorrect fullness, block 0")
    tb_streamer.read_user_reg(sid_noc_block_replay, SR_REC_FULLNESS, readback, 1);
    `ASSERT_FATAL(readback == 0, "Incorrect fullness, block 1")

    // Check the packet length
    tb_streamer.write_reg(sid_noc_block_replay, SR_RX_CTRL_MAXLEN, 13, 0);
    tb_streamer.write_reg(sid_noc_block_replay, SR_RX_CTRL_MAXLEN, 14, 1);
    //
    tb_streamer.read_user_reg(sid_noc_block_replay, SR_RX_CTRL_MAXLEN, readback, 0);
    `ASSERT_FATAL(readback == 13, "Incorrect packet size, block 0")
    tb_streamer.read_user_reg(sid_noc_block_replay, SR_RX_CTRL_MAXLEN, readback, 1);
    `ASSERT_FATAL(readback == 14, "Incorrect packet size, block 1")
    //
    tb_streamer.write_reg(sid_noc_block_replay, SR_RX_CTRL_MAXLEN, MEM_BURST_SIZE, 0);
    tb_streamer.write_reg(sid_noc_block_replay, SR_RX_CTRL_MAXLEN, MEM_BURST_SIZE, 1);
    tb_streamer.read_user_reg(sid_noc_block_replay, SR_RX_CTRL_MAXLEN, readback, 0);
    `ASSERT_FATAL(readback == MEM_BURST_SIZE, "Incorrect packet size, block 0")
    tb_streamer.read_user_reg(sid_noc_block_replay, SR_RX_CTRL_MAXLEN, readback, 1);
    `ASSERT_FATAL(readback == MEM_BURST_SIZE, "Incorrect packet size, block 1")

    `TEST_CASE_DONE(1);


    //-------------------------------------------------------------------------
    // Test 5 -- Wait for DRAM calibration to complete
    //-------------------------------------------------------------------------

    test_step = 5;
    `TEST_CASE_START("Wait for DRAM calibration to complete");
    while (init_done !== 1'b1) @(posedge bus_clk);
    `TEST_CASE_DONE(init_done);


    //-------------------------------------------------------------------------
    // Test 6 -- Basic Recording and Playback of both FIFOs
    //-------------------------------------------------------------------------
    //
    // This tests basic functionality of two replay buffers. It also checks 
    // that updates to an adjacent buffer don't affect the other.
    //
    //-------------------------------------------------------------------------

    test_step = 6;
    `TEST_CASE_START("Basic Recording and Playback");

    // Configure the buffers so that they are adjacent, to catch any 
    // encroachment on the other buffer. We'll put buffer 0 at a higher address 
    // then see if changes to buffer 1 spill into buffer 0.
    tb_streamer.write_reg(sid_noc_block_replay, SR_REC_BASE_ADDR, 1024+SPP, 0);
    tb_streamer.write_reg(sid_noc_block_replay, SR_REC_BUFFER_SIZE,    SPP, 0);
    tb_streamer.write_reg(sid_noc_block_replay, SR_REC_BASE_ADDR,     1024, 1);
    tb_streamer.write_reg(sid_noc_block_replay, SR_REC_BUFFER_SIZE,    SPP, 1);
    tb_streamer.write_reg(sid_noc_block_replay, SR_PLAY_BASE_ADDR, 1024+SPP, 0);
    tb_streamer.write_reg(sid_noc_block_replay, SR_PLAY_BUFFER_SIZE,    SPP, 0);
    tb_streamer.write_reg(sid_noc_block_replay, SR_PLAY_BASE_ADDR,     1024, 1);
    tb_streamer.write_reg(sid_noc_block_replay, SR_PLAY_BUFFER_SIZE,    SPP, 1);
    // Enable the record buffers
    tb_streamer.write_reg(sid_noc_block_replay, SR_REC_RESTART, 0, 0);
    tb_streamer.write_reg(sid_noc_block_replay, SR_REC_RESTART, 0, 1);

    for (int buffer_num = 0; buffer_num < 2; buffer_num++) begin
      begin
        cvita_payload_t  send_payload;
        cvita_payload_t  send_payload_buff0;
        cvita_metadata_t md;

        int           num_words;
        string        error_string;
        logic  [31:0] cmd;

        // Empty the payload queue
        while (send_payload.size() > 0) send_payload.pop_back();

        num_words = SPP / WORD_SIZE;
        gen_payload(send_payload, num_words);

        // Save a copy of what goes into buffer 0
        if (buffer_num == 0) send_payload_buff0 = send_payload;

        // Send the payload
        tb_streamer.send(send_payload, md, buffer_num);
  
        // Wait until all the data has been written
        wait_record_fullness(num_words*WORD_SIZE, BUS_CLK_PERIOD*num_words*WORD_SIZE);
  
        // Start replay
        cmd       = 0;
        cmd[31]   = 1;         // send_imm
        cmd[30]   = 0;         // chain
        cmd[29]   = 0;         // reload
        cmd[28]   = 0;         // stop
        cmd[27:0] = num_words; // num_lines
        tb_streamer.write_user_reg(sid_noc_block_replay, SR_RX_CTRL_COMMAND, cmd, buffer_num);
  
        // Check the output
        verify_rx_data(error_string, send_payload, buffer_num);
        `ASSERT_FATAL(error_string == "", error_string);

        if (buffer_num == 1) begin
          // Playback buffer 0 again, to make sure it's still unchanged
          cmd       = 0;
          cmd[31]   = 1;         // send_imm
          cmd[30]   = 0;         // chain
          cmd[29]   = 0;         // reload
          cmd[28]   = 0;         // stop
          cmd[27:0] = num_words; // num_lines
          tb_streamer.write_user_reg(sid_noc_block_replay, SR_RX_CTRL_COMMAND, cmd, 0);

          // Check the output
          verify_rx_data(error_string, send_payload_buff0, 0);
          `ASSERT_FATAL(error_string == "", error_string);
        end
      end

    end  // for

    `TEST_CASE_DONE(1);


    //-------------------------------------------------------------------------
    // Test 7 -- Test small frame
    //-------------------------------------------------------------------------

    test_step = 7;
    `TEST_CASE_START("Test small frame");

    begin
      cvita_payload_t  send_payload;
      cvita_metadata_t md;
      string           error_string;

      logic [31:0] cmd;

      // Set number of words to test to the smallest size possible
      static int num_words = 1;

      // Update record buffer settings
      tb_streamer.write_reg(sid_noc_block_replay, SR_REC_BASE_ADDR,  1024, 0);
      tb_streamer.write_reg(sid_noc_block_replay, SR_REC_BUFFER_SIZE, SPP, 0);
      tb_streamer.write_reg(sid_noc_block_replay, SR_PLAY_BASE_ADDR,  1024, 0);
      tb_streamer.write_reg(sid_noc_block_replay, SR_PLAY_BUFFER_SIZE, SPP, 0);

      // Restart the record buffer
      tb_streamer.write_reg(sid_noc_block_replay, SR_REC_RESTART, 0, 0);
   
      // Write a small amount then wait to make sure it gets committed, even 
      // though it's smaller than the burst size.
      gen_payload(send_payload, num_words);
      tb_streamer.send(send_payload, md, 0);

      $display("Size of payload is %0d", send_payload.size());

      // Wait until all the data has been written
      wait_record_fullness(num_words*WORD_SIZE, BUS_CLK_PERIOD*1000);

      // Start replay
      cmd       = 0;
      cmd[31]   = 1;         // send_imm
      cmd[30]   = 0;         // chain
      cmd[29]   = 0;         // reload
      cmd[28]   = 0;         // stop
      cmd[27:0] = num_words; // num_lines
      tb_streamer.write_user_reg(sid_noc_block_replay, SR_RX_CTRL_COMMAND, cmd, 0);
      
      // Check the output
      verify_rx_data(error_string, send_payload);
      `ASSERT_FATAL(error_string == "", error_string);

    end

    `TEST_CASE_DONE(1);
    

    //-------------------------------------------------------------------------
    // Test 8 -- Test playback that's larger than buffer
    //-------------------------------------------------------------------------
    //
    // We want to make sure that playback wraps as expected back to the 
    // beginning of the buffer and that buffers that aren't a multiple of the 
    // burst size wrap correctly.
    //
    //-------------------------------------------------------------------------

    test_step = 8;
    `TEST_CASE_START("Test oversized playback");

    begin
      cvita_payload_t  send_payload;
      cvita_metadata_t md;
      string           error_string;

      logic [31:0] cmd;

      // Set number of words to test to the smallest size possible
      static int buffer_size    = (3 * MEM_BURST_SIZE) / 2 * WORD_SIZE;   // 1.5 memory bursts in size (in bytes)
      static int num_words_rec  = buffer_size / WORD_SIZE;                // Same as buffer_size (in words)
      static int num_words_play = 2 * MEM_BURST_SIZE;                     // 2 memory bursts in size (in words)

      // Update record buffer settings
      tb_streamer.write_reg(sid_noc_block_replay, SR_REC_BASE_ADDR,  0, 0);
      tb_streamer.write_reg(sid_noc_block_replay, SR_REC_BUFFER_SIZE, buffer_size, 0);
      tb_streamer.write_reg(sid_noc_block_replay, SR_PLAY_BASE_ADDR,  0, 0);
      tb_streamer.write_reg(sid_noc_block_replay, SR_PLAY_BUFFER_SIZE, buffer_size, 0);

      // Restart the record buffer
      tb_streamer.write_reg(sid_noc_block_replay, SR_REC_RESTART, 0, 0);
    
      // Fill record buffer
      gen_payload(send_payload, num_words_rec);
      tb_streamer.send(send_payload, md, 0);

      // Wait until all the data has been written
      wait_record_fullness(buffer_size, BUS_CLK_PERIOD*buffer_size*2);

      // Start replay
      cmd       = 0;
      cmd[31]   = 1;              // send_imm
      cmd[30]   = 0;              // chain
      cmd[29]   = 0;              // reload
      cmd[28]   = 0;              // stop
      cmd[27:0] = num_words_play; // num_lines
      tb_streamer.write_user_reg(sid_noc_block_replay, SR_RX_CTRL_COMMAND, cmd, 0);
      
      // First two frames should be what we recorded (1.5 * MEM_BURST_SIZE)
      verify_rx_data(error_string, send_payload);
      `ASSERT_FATAL(error_string == "", error_string);

      // Then we should get another frame that's half a burst in length and 
      // matches the beginning of the record buffer.
      verify_rx_data(error_string, send_payload[0:MEM_BURST_SIZE/2-1]);
      `ASSERT_FATAL(error_string == "", error_string);

    end

    `TEST_CASE_DONE(1);


    //-------------------------------------------------------------------------
    // Test 9 -- Test chain mode
    //-------------------------------------------------------------------------

    test_step = 9;
    `TEST_CASE_START("Test chain mode");

    begin
      cvita_payload_t  send_payload;
      cvita_metadata_t md;
      string           error_string;

      logic [31:0] cmd;

      static int num_words = 70;

      // Update record buffer settings
      tb_streamer.write_reg(sid_noc_block_replay, SR_REC_BASE_ADDR, 0, 0);
      tb_streamer.write_reg(sid_noc_block_replay, SR_REC_BUFFER_SIZE, num_words*WORD_SIZE, 0);
      tb_streamer.write_reg(sid_noc_block_replay, SR_PLAY_BASE_ADDR, 0, 0);
      tb_streamer.write_reg(sid_noc_block_replay, SR_PLAY_BUFFER_SIZE, num_words*WORD_SIZE, 0);

      // Restart the record buffer
      tb_streamer.write_reg(sid_noc_block_replay, SR_REC_RESTART, 0, 0);
    
      // Write num_words to record buffer
      gen_payload(send_payload, num_words);
      tb_streamer.send(send_payload, md, 0);

      // Wait until all the data has been written
      wait_record_fullness(num_words*WORD_SIZE, BUS_CLK_PERIOD*num_words*5);

      // Send two commands, chained together, each sending half the data
      cmd       = 0;
      cmd[31]   = 1;           // send_imm
      cmd[30]   = 1;           // chain
      cmd[29]   = 0;           // reload
      cmd[28]   = 0;           // stop
      cmd[27:0] = num_words/2; // num_lines
      tb_streamer.write_user_reg(sid_noc_block_replay, SR_RX_CTRL_COMMAND, cmd, 0);

      cmd       = 0;
      cmd[31]   = 0;           // send_imm
      cmd[30]   = 0;           // chain
      cmd[29]   = 0;           // reload
      cmd[28]   = 0;           // stop
      cmd[27:0] = num_words/2; // num_lines
      tb_streamer.write_user_reg(sid_noc_block_replay, SR_RX_CTRL_COMMAND, cmd, 0);

      // Check the output, looking for the full set of data
      verify_rx_data(error_string, send_payload);
      `ASSERT_FATAL(error_string == "", error_string);

    end

    `TEST_CASE_DONE(1);


    //-------------------------------------------------------------------------
    // Test 10 -- Test reload (automatic replay)
    //-------------------------------------------------------------------------

    test_step = 10;
    `TEST_CASE_START("Test reload (automatic replay)");

    begin
      cvita_payload_t  send_payload;
      cvita_metadata_t md;
      string           error_string;

      logic [31:0] cmd;

      static int num_words = 37;

      // Update record buffer settings
      tb_streamer.write_reg(sid_noc_block_replay, SR_REC_BASE_ADDR, 0, 0);
      tb_streamer.write_reg(sid_noc_block_replay, SR_REC_BUFFER_SIZE, 37*WORD_SIZE, 0);
      tb_streamer.write_reg(sid_noc_block_replay, SR_PLAY_BASE_ADDR, 0, 0);
      tb_streamer.write_reg(sid_noc_block_replay, SR_PLAY_BUFFER_SIZE, 37*WORD_SIZE, 0);

      // Restart the record buffer
      tb_streamer.write_reg(sid_noc_block_replay, SR_REC_RESTART, 0, 0);
    
      // Write num_words to record buffer
      gen_payload(send_payload, num_words);
      tb_streamer.send(send_payload, md, 0);

      // Wait until all the data has been written
      wait_record_fullness(num_words*WORD_SIZE, BUS_CLK_PERIOD*1000);

      // Start replay, with chain+reload enabled
      cmd       = 0;
      cmd[31]   = 1;         // send_imm
      cmd[30]   = 1;         // chain
      cmd[29]   = 1;         // reload
      cmd[28]   = 0;         // stop
      cmd[27:0] = num_words; // num_lines
      tb_streamer.write_user_reg(sid_noc_block_replay, SR_RX_CTRL_COMMAND, cmd, 0);
      
      // Check the output, 3 times to make sure it's being repeated
      for (int k = 0; k < 3; k ++) begin
        verify_rx_data(error_string, send_payload);
        `ASSERT_FATAL(error_string == "", error_string);
      end

    end

    `TEST_CASE_DONE(1);


    //-------------------------------------------------------------------------
    // Test 11 -- Test stop
    //-------------------------------------------------------------------------
    //
    // This test assumes the replay is still running from test previous test.
    //
    //-------------------------------------------------------------------------

    test_step = 11;
    `TEST_CASE_START("Test stop");

    begin
      logic [31:0] cmd;

      // Send stop command
      cmd       = 0;
      cmd[31]   = 0; // send_imm
      cmd[30]   = 0; // chain
      cmd[29]   = 0; // reload
      cmd[28]   = 1; // stop
      cmd[27:0] = 0; // num_lines
      tb_streamer.write_user_reg(sid_noc_block_replay, SR_RX_CTRL_COMMAND, cmd, 0);

      // Keep reading frames until we've cleared them all
      flush_rx();
    end

    `TEST_CASE_DONE(1);


    //-------------------------------------------------------------------------
    // Test 12 -- Test halt
    //-------------------------------------------------------------------------

    test_step = 12;
    `TEST_CASE_START("Test halt");

    begin
      cvita_payload_t  recv_payload;
      cvita_metadata_t md;

      logic [31:0] cmd;

      static int num_words = 23;

      // Start replay, with chain+reload enabled
      cmd       = 0;
      cmd[31]   = 1;         // send_imm
      cmd[30]   = 1;         // chain
      cmd[29]   = 1;         // reload
      cmd[28]   = 0;         // stop
      cmd[27:0] = num_words; // num_lines
      tb_streamer.write_user_reg(sid_noc_block_replay, SR_RX_CTRL_COMMAND, cmd, 0);
      
      // Grab 3 packets, to make sure it's being repeated
      for (int k = 0; k < 3; k ++) begin
        tb_streamer.recv(recv_payload, md, 0);
      end

      // Send halt command
      tb_streamer.write_user_reg(sid_noc_block_replay, SR_RX_CTRL_HALT, 0, 0);

      // Keep reading frames until we've cleared them all
      flush_rx;
    end

    `TEST_CASE_DONE(1);


    //-------------------------------------------------------------------------
    // Test 13 -- Test overfilled record buffer
    //-------------------------------------------------------------------------
    //
    // Record more words than the buffer can fit. Make sure we don't overfill 
    // our buffer and make sure reading it back loops only the data that should 
    // have been captured.
    //
    //-------------------------------------------------------------------------

    test_step = 13;
    `TEST_CASE_START("Test overfilled record buffer");

    begin
      cvita_payload_t  send_payload;
      cvita_metadata_t md;
      string           error_string;

      logic [31:0] cmd;

      // Number of words to record (num_words) is larger than buffer size.
      static int num_words   = 97;
      static int buffer_size = 43;    // Size in bytes

      // Update record buffer settings
      tb_streamer.write_reg(sid_noc_block_replay, SR_REC_BASE_ADDR, 0, 0);
      tb_streamer.write_reg(sid_noc_block_replay, SR_REC_BUFFER_SIZE, buffer_size*WORD_SIZE, 0);
      tb_streamer.write_reg(sid_noc_block_replay, SR_PLAY_BASE_ADDR, 0, 0);
      tb_streamer.write_reg(sid_noc_block_replay, SR_PLAY_BUFFER_SIZE, buffer_size*WORD_SIZE, 0);

      // Restart the record buffer
      tb_streamer.write_reg(sid_noc_block_replay, SR_REC_RESTART, 0, 0);
    
      // Write more to record buffer than it can fit
      gen_payload(send_payload, num_words);
      tb_streamer.send(send_payload, md, 0);

      // Wait until all the data has been written
      wait_record_fullness(buffer_size*WORD_SIZE, BUS_CLK_PERIOD*1000);

      // Start replay
      cmd       = 0;
      cmd[31]   = 1;         // send_imm
      cmd[30]   = 0;         // chain
      cmd[29]   = 0;         // reload
      cmd[28]   = 0;         // stop
      cmd[27:0] = num_words; // num_lines
      tb_streamer.write_user_reg(sid_noc_block_replay, SR_RX_CTRL_COMMAND, cmd, 0);
      
      // We should get two frames of buffer_size, then one smaller frame to 
      // bring us up to num_words total.
      send_payload = send_payload[0 : buffer_size-1];
      for (int i = 0; i < 2; i ++) begin
        verify_rx_data(error_string, send_payload);
        `ASSERT_FATAL(error_string == "", error_string);
      end
      send_payload = send_payload[0 : (num_words % buffer_size)-1];
      verify_rx_data(error_string, send_payload);
      `ASSERT_FATAL(error_string == "", error_string);

      // Make sure SR_REC_FULLNESS didn't keep increasing
      tb_streamer.read_user_reg(sid_noc_block_replay, SR_REC_FULLNESS, readback, 0);
      `ASSERT_FATAL(readback == buffer_size*WORD_SIZE, "SR_REC_FULLNESS went beyond expected bounds");

      // Reset record buffer so that it accepts the rest of the data that's 
      // stalled in the crossbar or input FIFO.
      tb_streamer.write_reg(sid_noc_block_replay, SR_REC_BUFFER_SIZE, num_words*WORD_SIZE, 0);
      tb_streamer.write_reg(sid_noc_block_replay, SR_REC_RESTART, 0, 0);

      // Wait until all the data has been written
      wait_record_fullness((num_words - buffer_size)*WORD_SIZE, BUS_CLK_PERIOD*1000);
    end

    `TEST_CASE_DONE(1);


    //-------------------------------------------------------------------------
    // Test 14 -- Test burst size
    //-------------------------------------------------------------------------
    //
    // Record amount of data that's larger than the configured RAM burst length 
    // to make sure full-length bursts are handled correctly.
    //
    //-------------------------------------------------------------------------

    test_step = 14;
    `TEST_CASE_START("Test burst size");

    begin
      cvita_payload_t  send_payload;
      cvita_metadata_t md;
      string           error_string;

      logic [31:0] cmd;

      static int num_words   = 4*MEM_BURST_SIZE; // Multiple of the burst size
      static int buffer_size = 4*MEM_BURST_SIZE; // Size in bytes

      // Update record buffer settings
      tb_streamer.write_reg(sid_noc_block_replay, SR_REC_BASE_ADDR, 0, 0);
      tb_streamer.write_reg(sid_noc_block_replay, SR_REC_BUFFER_SIZE, buffer_size*WORD_SIZE, 0);
      tb_streamer.write_reg(sid_noc_block_replay, SR_PLAY_BASE_ADDR, 0, 0);
      tb_streamer.write_reg(sid_noc_block_replay, SR_PLAY_BUFFER_SIZE, buffer_size*WORD_SIZE, 0);

      // Restart the record buffer
      tb_streamer.write_reg(sid_noc_block_replay, SR_REC_RESTART, 0, 0);
    
      // Write data to record buffer
      gen_payload(send_payload, num_words);
      tb_streamer.send(send_payload, md, 0);

      // Wait until all the data has been written
      wait_record_fullness(num_words*WORD_SIZE, BUS_CLK_PERIOD*num_words*5);

      // Start replay
      cmd       = 0;
      cmd[31]   = 1;         // send_imm
      cmd[30]   = 0;         // chain
      cmd[29]   = 0;         // reload
      cmd[28]   = 0;         // stop
      cmd[27:0] = num_words; // num_lines
      tb_streamer.write_user_reg(sid_noc_block_replay, SR_RX_CTRL_COMMAND, cmd, 0);
      
      // Verify the data
      verify_rx_data(error_string, send_payload, 0);
      `ASSERT_FATAL(error_string == "", error_string);
    end

    `TEST_CASE_DONE(1);


    //-------------------------------------------------------------------------
    // Test 15 -- Test 4k AXI boundary
    //-------------------------------------------------------------------------
    //
    // Record larger than the configured RAM burst length to make sure 
    // full-length bursts are handled correctly.
    //
    //-------------------------------------------------------------------------

    test_step = 15;
    `TEST_CASE_START("Test 4k AXI Boundary");

    begin
      cvita_payload_t  send_payload;
      cvita_payload_t  temp_payload;
      cvita_metadata_t md;
      string           error_string;

      logic [31:0] cmd;

      static int num_words   = 2*MEM_BURST_SIZE; // Multiple of the burst size
      static int buffer_size = 4*MEM_BURST_SIZE; // Size in bytes

      // Update record buffer settings
      tb_streamer.write_reg(sid_noc_block_replay, SR_REC_BASE_ADDR, AXI_ALIGNMENT-(num_words/2)*WORD_SIZE, 0);
      tb_streamer.write_reg(sid_noc_block_replay, SR_REC_BUFFER_SIZE, buffer_size*WORD_SIZE, 0);
      tb_streamer.write_reg(sid_noc_block_replay, SR_PLAY_BASE_ADDR, AXI_ALIGNMENT-(num_words/2)*WORD_SIZE, 0);
      tb_streamer.write_reg(sid_noc_block_replay, SR_PLAY_BUFFER_SIZE, buffer_size*WORD_SIZE, 0);

      // Restart the record buffer
      tb_streamer.write_reg(sid_noc_block_replay, SR_REC_RESTART, 0, 0);

      // Write a large packet that crosses the 4k boundary
      gen_payload(send_payload, num_words);
      tb_streamer.send(send_payload, md, 0);

      // Wait until all the data has been written
      wait_record_fullness(num_words*WORD_SIZE, BUS_CLK_PERIOD*num_words*5);

      // Start replay
      cmd       = 0;
      cmd[31]   = 1;         // send_imm
      cmd[30]   = 0;         // chain
      cmd[29]   = 0;         // reload
      cmd[28]   = 0;         // stop
      cmd[27:0] = num_words; // num_lines
      tb_streamer.write_user_reg(sid_noc_block_replay, SR_RX_CTRL_COMMAND, cmd, 0);

      // Verify the data, making sure we get two packets, since the access 
      // should have been split due to crossing 4k boundary.
      for (int i = 0; i < 2; i++) begin
        temp_payload = send_payload[i*num_words/2 : (i+1)*(num_words/2)-1];
        verify_rx_data(error_string, temp_payload, 0);
        `ASSERT_FATAL(error_string == "", error_string);
      end

    end

    `TEST_CASE_DONE(1);


    //-------------------------------------------------------------------------
    // Test 16 -- Test different packet sizes
    //-------------------------------------------------------------------------

    test_step = 16;
    `TEST_CASE_START("Test small packet size");

    begin
      cvita_payload_t  send_payload;
      cvita_metadata_t md;
      string           error_string;

      logic [31:0] cmd;

      // Set number of words to test to the smallest size possible
      static int buffer_size = 2 * MEM_BURST_SIZE / WORD_SIZE;   // 2 memory bursts in size (in bytes)
      static int num_words   = buffer_size / WORD_SIZE;          // Same as buffer_size (in words)
      
      static int old_packet_size;

      // Read the current packet size, then change it to a small value
      tb_streamer.read_user_reg(sid_noc_block_replay, SR_RX_CTRL_MAXLEN, old_packet_size, 0);
      tb_streamer.write_reg(sid_noc_block_replay, SR_RX_CTRL_MAXLEN, MEM_BURST_SIZE/4, 0);

      // Update record buffer settings
      tb_streamer.write_reg(sid_noc_block_replay, SR_REC_BASE_ADDR,  0, 0);
      tb_streamer.write_reg(sid_noc_block_replay, SR_REC_BUFFER_SIZE, buffer_size, 0);
      tb_streamer.write_reg(sid_noc_block_replay, SR_PLAY_BASE_ADDR,  0, 0);
      tb_streamer.write_reg(sid_noc_block_replay, SR_PLAY_BUFFER_SIZE, buffer_size, 0);

      // Restart the record buffer
      tb_streamer.write_reg(sid_noc_block_replay, SR_REC_RESTART, 0, 0);
    
      // Fill record buffer
      gen_payload(send_payload, num_words);
      tb_streamer.send(send_payload, md, 0);

      // Wait until all the data has been written
      wait_record_fullness(buffer_size, BUS_CLK_PERIOD*buffer_size*2);

      // Start replay
      cmd       = 0;
      cmd[31]   = 1;         // send_imm
      cmd[30]   = 0;         // chain
      cmd[29]   = 0;         // reload
      cmd[28]   = 0;         // stop
      cmd[27:0] = num_words; // num_lines
      tb_streamer.write_user_reg(sid_noc_block_replay, SR_RX_CTRL_COMMAND, cmd, 0);
      
      // We should get 8 small packets instead of 2 large ones
      for (int k = 0; k < 8; k ++) begin
        verify_rx_data(error_string, send_payload[MEM_BURST_SIZE/4*k:MEM_BURST_SIZE/4*(k+1)-1]);
        `ASSERT_FATAL(error_string == "", error_string);
      end

      // Restore the packet size
      tb_streamer.write_reg(sid_noc_block_replay, SR_RX_CTRL_MAXLEN, old_packet_size, 0);

    end

    `TEST_CASE_DONE(1);


    //-------------------------------------------------------------------------
    // Finish
    //-------------------------------------------------------------------------

    `TEST_BENCH_DONE;
  end
endmodule
