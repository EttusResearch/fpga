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
`define NUM_TEST_CASES 19

`include "sim_exec_report.vh"
`include "sim_clks_rsts.vh"
`include "sim_rfnoc_lib.svh"

`default_nettype none


module noc_block_replay_tb ();

  //---------------------------------------------------------------------------
  // Declarations
  //---------------------------------------------------------------------------

  // Register offsets
  localparam [7:0] SR_REC_BASE_ADDR    = 128;
  localparam [7:0] SR_REC_BUFFER_SIZE  = 129;
  localparam [7:0] SR_REC_RESTART      = 130;
  localparam [7:0] SR_REC_FULLNESS     = 131;
  localparam [7:0] SR_PLAY_BASE_ADDR   = 132;
  localparam [7:0] SR_PLAY_BUFFER_SIZE = 133;
  localparam [7:0] SR_RX_CTRL_COMMAND  = 152; // Same offset as radio
  localparam [7:0] SR_RX_CTRL_TIME_HI  = 153; // Same offset as radio
  localparam [7:0] SR_RX_CTRL_TIME_LO  = 154; // Same offset as radio
  localparam [7:0] SR_RX_CTRL_HALT     = 155; // Same offset as radio
  localparam [7:0] SR_RX_CTRL_MAXLEN   = 156; // Same offset as radio

  // Memory burst size in 64-bit words, as defined in the axi_replay block.
  // This is essentially hard coded to match the maximum transfer size
  // supported by the DMA master.
  const int MEM_BURST_LEN =
    noc_block_replay.gen_replay_blocks[0].axi_replay_i.MEM_BURST_LEN;

  // Number of bytes per word
  localparam MEM_WORD_SIZE = 8;   // Bytes per word
  localparam SAMPLE_SIZE   = 4;   // Size of sc16 in bytes
  localparam SAMP_PER_WORD = MEM_WORD_SIZE / SAMPLE_SIZE;

  // AXI alignment boundary, in bytes
  localparam AXI_ALIGNMENT = 4096;

  // Configuration
  localparam RAM_MODEL = "AXI_RAM";  // Can be SRAM, DRAM, or AXI_RAM. DRAM
                                     // takes a long time to simulate. AXI_RAM
                                     // models stalls better than SRAM.
  localparam BUS_CLK_PERIOD = 6.0;   // 166.667 MHz
  localparam CE_CLK_PERIOD  = 4.667; // 214.286 MHz
  localparam NUM_CE         = 1;     // Number of Computation Engines / User RFNoC blocks to simulate
  localparam NUM_STREAMS    = 2;     // Number of test bench streams

  // Packet size to use by default
  localparam SPP = 256;                 // Number of sc16 samples per packet
  localparam BPP = SPP*SAMPLE_SIZE;     // Number of bytes per packet
  localparam WPP = BPP/MEM_WORD_SIZE;   // Number of 64-bit words per packet

  localparam USE_RANDOM = 1; // Use random instead of sequential data. Random
                             // is better for catching errors, but sequential
                             // is easier for debugging.

  localparam MEM_ADDR_W = 16;  // Address width for replay block
  localparam STALL_PROB = 25;  // Stall probability for memory model

  string test_step; // Current test, for tracking progress in waveform view


  //---------------------------------------------------------------------------
  // Testbench Initialization
  //---------------------------------------------------------------------------

  `TEST_BENCH_INIT("noc_block_replay_tb", `NUM_TEST_CASES, `NS_PER_TICK);
  `DEFINE_CLK(sys_clk, 10, 50)            // 100 MHz sys_clk to generate DDR3 clocking
  `DEFINE_RESET_N(sys_rst_n, 0, 100)      // 100 ns for GSR to deassert
  `RFNOC_SIM_INIT(NUM_CE, NUM_STREAMS, BUS_CLK_PERIOD, CE_CLK_PERIOD);
  `RFNOC_ADD_BLOCK_CUSTOM(noc_block_replay, 0);


  //---------------------------------------------------------------------------
  // Memory Model
  //---------------------------------------------------------------------------

  // AXI interconnect and MIG interfaces
  axi4_rd_t #(.DWIDTH(64),  .AWIDTH(32), .IDWIDTH(1)) dma0_axi_rd(.clk(ce_clk));
  axi4_wr_t #(.DWIDTH(64),  .AWIDTH(32), .IDWIDTH(1)) dma0_axi_wr(.clk(ce_clk));
  axi4_rd_t #(.DWIDTH(64),  .AWIDTH(32), .IDWIDTH(1)) dma1_axi_rd(.clk(ce_clk));
  axi4_wr_t #(.DWIDTH(64),  .AWIDTH(32), .IDWIDTH(1)) dma1_axi_wr(.clk(ce_clk));

  wire init_done;

  replay_sim_ram #(
    .RAM_MODEL  (RAM_MODEL),
    .MEM_ADDR_W (MEM_ADDR_W),
    .STALL_PROB (STALL_PROB)
  ) replay_sim_ram_i (
    .ce_clk      (ce_clk),
    .ce_rst      (ce_rst),
    .sys_clk     (sys_clk),
    .sys_rst_n   (sys_rst_n),
    .init_done   (init_done),
    .dma0_axi_rd (dma0_axi_rd),
    .dma0_axi_wr (dma0_axi_wr),
    .dma1_axi_rd (dma1_axi_rd),
    .dma1_axi_wr (dma1_axi_wr)
  );


  //---------------------------------------------------------------------------
  // DUT
  //---------------------------------------------------------------------------

  noc_block_replay #(
    .STR_SINK_FIFOSIZE (11),
    .MTU               (12),
    .NUM_REPLAY_BLOCKS (2),
    .MEM_ADDR_W        (MEM_ADDR_W)
  ) noc_block_replay (
    .bus_clk (bus_clk),
    .bus_rst (bus_rst),
    .ce_clk  (ce_clk),
    .ce_rst  (ce_rst),

    .i_tdata  (noc_block_replay_i_tdata),
    .i_tlast  (noc_block_replay_i_tlast),
    .i_tvalid (noc_block_replay_i_tvalid),
    .i_tready (noc_block_replay_i_tready),

    .o_tdata  (noc_block_replay_o_tdata),
    .o_tlast  (noc_block_replay_o_tlast),
    .o_tvalid (noc_block_replay_o_tvalid),
    .o_tready (noc_block_replay_o_tready),

    .m_axi_awid     ({dma1_axi_wr.addr.id,     dma0_axi_wr.addr.id}),
    .m_axi_awaddr   ({dma1_axi_wr.addr.addr,   dma0_axi_wr.addr.addr}),
    .m_axi_awlen    ({dma1_axi_wr.addr.len,    dma0_axi_wr.addr.len}),
    .m_axi_awsize   ({dma1_axi_wr.addr.size,   dma0_axi_wr.addr.size}),
    .m_axi_awburst  ({dma1_axi_wr.addr.burst,  dma0_axi_wr.addr.burst}),
    .m_axi_awlock   ({dma1_axi_wr.addr.lock,   dma0_axi_wr.addr.lock}),
    .m_axi_awcache  ({dma1_axi_wr.addr.cache,  dma0_axi_wr.addr.cache}),
    .m_axi_awprot   ({dma1_axi_wr.addr.prot,   dma0_axi_wr.addr.prot}),
    .m_axi_awqos    ({dma1_axi_wr.addr.qos,    dma0_axi_wr.addr.qos}),
    .m_axi_awregion ({dma1_axi_wr.addr.region, dma0_axi_wr.addr.region}),
    .m_axi_awuser   ({dma1_axi_wr.addr.user,   dma0_axi_wr.addr.user}),
    .m_axi_awvalid  ({dma1_axi_wr.addr.valid,  dma0_axi_wr.addr.valid}),
    .m_axi_awready  ({dma1_axi_wr.addr.ready,  dma0_axi_wr.addr.ready}),
    .m_axi_wdata    ({dma1_axi_wr.data.data,   dma0_axi_wr.data.data}),
    .m_axi_wstrb    ({dma1_axi_wr.data.strb,   dma0_axi_wr.data.strb}),
    .m_axi_wlast    ({dma1_axi_wr.data.last,   dma0_axi_wr.data.last}),
    .m_axi_wuser    ({dma1_axi_wr.data.user,   dma0_axi_wr.data.user}),
    .m_axi_wvalid   ({dma1_axi_wr.data.valid,  dma0_axi_wr.data.valid}),
    .m_axi_wready   ({dma1_axi_wr.data.ready,  dma0_axi_wr.data.ready}),
    .m_axi_bid      ({dma1_axi_wr.resp.id,     dma0_axi_wr.resp.id}),
    .m_axi_bresp    ({dma1_axi_wr.resp.resp,   dma0_axi_wr.resp.resp}),
    .m_axi_buser    ({dma1_axi_wr.resp.user,   dma0_axi_wr.resp.user}),
    .m_axi_bvalid   ({dma1_axi_wr.resp.valid,  dma0_axi_wr.resp.valid}),
    .m_axi_bready   ({dma1_axi_wr.resp.ready,  dma0_axi_wr.resp.ready}),
    .m_axi_arid     ({dma1_axi_rd.addr.id,     dma0_axi_rd.addr.id}),
    .m_axi_araddr   ({dma1_axi_rd.addr.addr,   dma0_axi_rd.addr.addr}),
    .m_axi_arlen    ({dma1_axi_rd.addr.len,    dma0_axi_rd.addr.len}),
    .m_axi_arsize   ({dma1_axi_rd.addr.size,   dma0_axi_rd.addr.size}),
    .m_axi_arburst  ({dma1_axi_rd.addr.burst,  dma0_axi_rd.addr.burst}),
    .m_axi_arlock   ({dma1_axi_rd.addr.lock,   dma0_axi_rd.addr.lock}),
    .m_axi_arcache  ({dma1_axi_rd.addr.cache,  dma0_axi_rd.addr.cache}),
    .m_axi_arprot   ({dma1_axi_rd.addr.prot,   dma0_axi_rd.addr.prot}),
    .m_axi_arqos    ({dma1_axi_rd.addr.qos,    dma0_axi_rd.addr.qos}),
    .m_axi_arregion ({dma1_axi_rd.addr.region, dma0_axi_rd.addr.region}),
    .m_axi_aruser   ({dma1_axi_rd.addr.user,   dma0_axi_rd.addr.user}),
    .m_axi_arvalid  ({dma1_axi_rd.addr.valid,  dma0_axi_rd.addr.valid}),
    .m_axi_arready  ({dma1_axi_rd.addr.ready,  dma0_axi_rd.addr.ready}),
    .m_axi_rid      ({dma1_axi_rd.data.id,     dma0_axi_rd.data.id}),
    .m_axi_rdata    ({dma1_axi_rd.data.data,   dma0_axi_rd.data.data}),
    .m_axi_rresp    ({dma1_axi_rd.data.resp,   dma0_axi_rd.data.resp}),
    .m_axi_rlast    ({dma1_axi_rd.data.last,   dma0_axi_rd.data.last}),
    .m_axi_ruser    ({dma1_axi_rd.data.user,   dma0_axi_rd.data.user}),
    .m_axi_rvalid   ({dma1_axi_rd.data.valid,  dma0_axi_rd.data.valid}),
    .m_axi_rready   ({dma1_axi_rd.data.ready,  dma0_axi_rd.data.ready}),

    .debug ()
  );


  //---------------------------------------------------------------------------
  // Tasks
  //---------------------------------------------------------------------------

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


  // Read out and discard all packets received, stopping after there's been no
  // packets for a delay of "timeout".
  task automatic flush_rx(input int  port,
                          input time timeout = CE_CLK_PERIOD*100);
    cvita_payload_t  recv_payload;
    cvita_metadata_t md;
    time             prev_time;

    begin
      prev_time = $time;

      while (1) begin
        // Check if there's a frame waiting
        if (noc_block_tb.str_sink_tvalid[port]) begin
          // Read frame
          tb_streamer.recv(recv_payload, md, port);
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
  task automatic wait_record_fullness(input int  port,
                                      input int  num_bytes,
                                      input time timeout = (10 + num_bytes) * BUS_CLK_PERIOD * 10);
    time         prev_time;
    logic [63:0] readback;

    begin
      // Poll SR_REC_FULLNESS until fullness is reached
      prev_time = $time;
      while (1) begin
        tb_streamer.read_user_reg(sid_noc_block_replay, SR_REC_FULLNESS, readback, port);
        if (readback >= num_bytes) break;

        // Check if it's taking too long
        if ($time - prev_time > timeout) begin
          `ASSERT_FATAL(0, "Timeout waiting for fullness to be reached");
        end
      end
    end
  endtask : wait_record_fullness


  // Read the data on the indicated port and check that it matches exp_items.
  // Also check that the length of the packets received add up to the length of
  // exp_items, if it takes multiple packets. An error string is returned if
  // there's an error, otherwise an empty string is returned.
  //
  //  port      : Port on which to receive and verify the data
  //  error_msg : Output string to write error message to, if any
  //  exp_items : Queue of the items you expect to receive
  //  eob       : Indicates if we expect EOB to be set for the last item (set
  //              to 1'bX to skip this check)
  // timestamp  : The timestamp we expect to receive for the first item (set to
  //              'X to skip timestamp checking)
  //
  task automatic verify_rx_data(input int             port = 0,
                                output string         error_msg,
                                input cvita_payload_t exp_payload,
                                input logic           eob = 1'b1,
                                input logic [63:0]    timestamp = 64'bX);
    cvita_payload_t  recv_payload;
    cvita_metadata_t md;
    int              word_count;
    int              packet_count;
    logic     [63:0] expected_value;
    logic     [63:0] actual_value;
    logic     [63:0] expected_time;

    begin
      word_count    = 0;
      packet_count  = 0;
      error_msg     = "";
      expected_time = timestamp;

      while (word_count < exp_payload.size()) begin
        // Grab the next frame
        while (recv_payload.size() > 0) void'(recv_payload.pop_back());
        tb_streamer.recv(recv_payload, md, port);

        // Check the packet length
        if (word_count + recv_payload.size() > exp_payload.size()) begin
          $sformat(error_msg,
                   "On packet %0d, size exceeds expected by %0d words",
                   packet_count,
                   (word_count + recv_payload.size()) - exp_payload.size());
          return;
        end

        // Check the EOB flag
        if (eob !== 1'bX) begin
          if (word_count + recv_payload.size() >= exp_payload.size()) begin
            // This is the last packet, so make sure EOB matches expected value
            if (md.eob != eob) begin
              $sformat(error_msg,
                       "On packet %0d, expected EOB to be %0b, actual is %0b",
                       packet_count, eob, md.eob);
              return;
            end
          end else begin
            // This is NOT the last packet, so EOB should be 0
            if (md.eob != 1'b0) begin
              $sformat(error_msg,
                       "On packet %0d, expected EOB to be 0 mid-burst, actual is %0b",
                       packet_count, md.eob);
              return;
            end
          end
        end

        // Check the time
        if (timestamp !== 64'bX) begin
          if (!md.timestamp) begin
            $sformat(error_msg,
                     "On packet %0d, timestamp is missing",
                     packet_count);
            return;
          end
          if (expected_time != md.timestamp) begin
            $sformat(error_msg,
                     "On packet %0d, expected timestamp %X but received %X",
                     packet_count, expected_time, md.timestamp);
            return;
          end
          expected_time = expected_time + recv_payload.size() * 2;  // Two samples per word
        end else begin
          // Make sure we don't have a timestamp unexpectedly
          if (md.timestamp) begin
            $sformat(error_msg,
                     "On packet %0d, expected no timestamp but received one",
                     packet_count);
          end
        end

        packet_count++;

        // Check the data
        for (int i = 0; i < recv_payload.size(); i++) begin
          expected_value = exp_payload[word_count];
          actual_value   = recv_payload[i];
          if (actual_value != expected_value) begin
            $sformat(error_msg,
                     "On word %0d (packet %0d, word offset %0d), Expected: 0x%x, Received: 0x%x",
                     word_count, packet_count, i, expected_value, actual_value);
            return;
          end
          word_count++;
        end
      end
    end
  endtask : verify_rx_data


  // Record data and start its playback
  //
  //   port         : Replay block port to use
  //   send_payload : Data to send to the replay block to be recorded
  //   buffer_size  : Buffer size in bytes to configure for record buffer
  //   num_words    : Number of words to play back
  //   wpp          : Words per packet for playback
  //   base_addr    : Base address to use for record buffer
  //   continuous   : Set to 1 for continuous playback, 0 for num_items only
  //   timestamp    : Timestamp to use for playback
  //
  task automatic start_replay (
    input int             port,
    input cvita_payload_t send_payload,
    input int unsigned    buffer_size = 1024 * MEM_WORD_SIZE,
    input int unsigned    num_words   = 1024,
    input int             wpp         = WPP,
    input int unsigned    base_addr   = 0,
    input bit             continuous  = 1'b0,
    input logic [63:0]    timestamp   = 64'bX);

    cvita_metadata_t md;
    logic     [31:0] cmd;
    bit              send_imm;
    int              expected_fullness;

    // Check for bad input arguments
    `ASSERT_FATAL(base_addr < 2**MEM_ADDR_W,
      "Base address is beyond available memory");
    `ASSERT_FATAL(longint'(base_addr) + buffer_size <= 2**MEM_ADDR_W,
      "Buffer size extends beyond available memory");

    // Update record buffer settings
    tb_streamer.write_reg(sid_noc_block_replay, SR_REC_BASE_ADDR, base_addr, port);
    tb_streamer.write_reg(sid_noc_block_replay, SR_REC_BUFFER_SIZE, buffer_size, port);
    tb_streamer.write_reg(sid_noc_block_replay, SR_PLAY_BASE_ADDR, base_addr, port);
    tb_streamer.write_reg(sid_noc_block_replay, SR_PLAY_BUFFER_SIZE, buffer_size, port);
    tb_streamer.write_reg(sid_noc_block_replay, SR_RX_CTRL_MAXLEN, wpp, port);

    // Restart the record buffer
    tb_streamer.write_reg(sid_noc_block_replay, SR_REC_RESTART, 0, port);

    // Write num_words to record buffer
    tb_streamer.send(send_payload, md, port);

    // Wait until all the data has been written (up to the size of the buffer)
    expected_fullness = send_payload.size() * MEM_WORD_SIZE < buffer_size ?
        send_payload.size() * MEM_WORD_SIZE : buffer_size;
    wait_record_fullness(port, expected_fullness);

    // Set the time for playback
    if (timestamp !== 64'bX) begin
      tb_streamer.write_user_reg(sid_noc_block_replay, SR_RX_CTRL_TIME_HI, timestamp[63:32], port);
      tb_streamer.write_user_reg(sid_noc_block_replay, SR_RX_CTRL_TIME_LO, timestamp[31: 0], port);
      send_imm = 1'b0;
    end else begin
      send_imm = 1'b1;
    end

    if (num_words != 0) begin
      // Send command to playback data
      cmd       = 0;
      cmd[31]   = send_imm;    // send_imm
      cmd[30]   = continuous;  // chain
      cmd[29]   = continuous;  // reload
      cmd[28]   = 0;           // stop
      cmd[27:0] = num_words;   // num_lines
      tb_streamer.write_user_reg(sid_noc_block_replay, SR_RX_CTRL_COMMAND, cmd, port);
    end
  endtask : start_replay


  task automatic stop_replay(int port);
    logic [31:0] cmd;
    cmd       = 0;
    cmd[31]   = 0;    // send_imm
    cmd[30]   = 0;    // chain
    cmd[29]   = 0;    // reload
    cmd[28]   = 1;    // stop
    cmd[27:0] = 0;    // num_lines
    tb_streamer.write_user_reg(sid_noc_block_replay, SR_RX_CTRL_COMMAND, cmd, port);

    // Keep reading frames until we've cleared them all
    flush_rx(port);
  endtask : stop_replay


  task automatic halt_replay(int port);
    tb_streamer.write_user_reg(sid_noc_block_replay, SR_RX_CTRL_HALT, 0, port);

    // Keep reading frames until we've cleared them all
    flush_rx(port);
  endtask : halt_replay


  //---------------------------------------------------------------------------
  // Test Registers
  //---------------------------------------------------------------------------

  task automatic test_registers();
    logic [63:0] readback;

    test_step = "Test Registers";
    `TEST_CASE_START(test_step);

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
    tb_streamer.write_reg(sid_noc_block_replay, SR_RX_CTRL_MAXLEN, WPP, 0);
    tb_streamer.write_reg(sid_noc_block_replay, SR_RX_CTRL_MAXLEN, WPP, 1);
    //
    tb_streamer.write_reg(sid_noc_block_replay, SR_RX_CTRL_MAXLEN, MEM_BURST_LEN, 0);
    tb_streamer.write_reg(sid_noc_block_replay, SR_RX_CTRL_MAXLEN, MEM_BURST_LEN, 1);
    tb_streamer.read_user_reg(sid_noc_block_replay, SR_RX_CTRL_MAXLEN, readback, 0);
    `ASSERT_FATAL(readback == MEM_BURST_LEN, "Incorrect packet size, block 0")
    tb_streamer.read_user_reg(sid_noc_block_replay, SR_RX_CTRL_MAXLEN, readback, 1);
    `ASSERT_FATAL(readback == MEM_BURST_LEN, "Incorrect packet size, block 1")

    `TEST_CASE_DONE(1);
  endtask : test_registers


  //---------------------------------------------------------------------------
  // Test Basic Recording and Playback of both FIFOs
  //---------------------------------------------------------------------------
  //
  // This tests basic functionality of two replay buffers. It also checks
  // that updates to an adjacent buffer don't affect the other.
  //
  //---------------------------------------------------------------------------

  task automatic test_basic();
    test_step = "Basic Recording and Playback";
    `TEST_CASE_START(test_step);

    // Configure the buffers so that they are adjacent, to catch any
    // encroachment on the other buffer. We'll put buffer 0 at a higher address
    // then see if changes to buffer 1 spill into buffer 0.
    tb_streamer.write_reg(sid_noc_block_replay, SR_REC_BASE_ADDR,  1024+SPP, 0);
    tb_streamer.write_reg(sid_noc_block_replay, SR_REC_BUFFER_SIZE,     SPP, 0);
    tb_streamer.write_reg(sid_noc_block_replay, SR_REC_BASE_ADDR,      1024, 1);
    tb_streamer.write_reg(sid_noc_block_replay, SR_REC_BUFFER_SIZE,     SPP, 1);
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
        while (send_payload.size() > 0) void'(send_payload.pop_back());

        num_words = SPP / MEM_WORD_SIZE;
        gen_payload(send_payload, num_words);

        // Save a copy of what goes into buffer 0
        if (buffer_num == 0) send_payload_buff0 = send_payload;

        // Send the payload
        tb_streamer.send(send_payload, md, buffer_num);

        // Wait until all the data has been written
        wait_record_fullness(buffer_num, num_words*MEM_WORD_SIZE);

        // Start replay
        cmd       = 0;
        cmd[31]   = 1;         // send_imm
        cmd[30]   = 0;         // chain
        cmd[29]   = 0;         // reload
        cmd[28]   = 0;         // stop
        cmd[27:0] = num_words; // num_lines
        tb_streamer.write_user_reg(sid_noc_block_replay, SR_RX_CTRL_COMMAND, cmd, buffer_num);

        // Check the output
        verify_rx_data(buffer_num, error_string, send_payload, 1);
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
          verify_rx_data(0, error_string, send_payload_buff0, 1);
          `ASSERT_FATAL(error_string == "", error_string);
        end
      end

    end  // for

    `TEST_CASE_DONE(1);

  endtask : test_basic


  //---------------------------------------------------------------------------
  // Test packet sizes
  //---------------------------------------------------------------------------
  //
  // Test boundary conditions where the packet size is close to the memory
  // burst size.
  //
  //---------------------------------------------------------------------------

  task automatic test_packet_sizes(int port = 0);
    cvita_payload_t send_payload;
    string          error_string;
    int             buffer_size;
    int             num_words;

    test_step = "Test packet size";
    `TEST_CASE_START(test_step);

    // Calculate 
    buffer_size = 2 * MEM_BURST_LEN * MEM_WORD_SIZE;
    num_words   = 2 * MEM_BURST_LEN;

    // Generate payload to use for testing
    gen_payload(send_payload, num_words);

    // For each test below, we record two memory bursts and playback two memory
    // bursts. Each time we change the playback packet size to test boundary
    // conditions.

    // Test packet size equals burst size
    start_replay(port, send_payload, buffer_size, num_words, MEM_BURST_LEN);
    verify_rx_data(port, error_string, send_payload, 1);
    `ASSERT_FATAL(error_string == "", error_string);

    // Test packet size one less than burst size
    start_replay(port, send_payload, buffer_size, num_words, MEM_BURST_LEN-1);
    verify_rx_data(port, error_string, send_payload, 1);
    `ASSERT_FATAL(error_string == "", error_string);

    // Test packet size one more than burst size
    start_replay(port, send_payload, buffer_size, num_words, MEM_BURST_LEN+1);
    verify_rx_data(port, error_string, send_payload, 1);
    `ASSERT_FATAL(error_string == "", error_string);

    // For each test below, we record two memory bursts and playback one memory
    // burst plus or minus one word, keeping the packet size the same.
    num_words = MEM_BURST_LEN;

    // Playback one less than burst/packet size
    start_replay(port, send_payload, buffer_size, num_words-1, MEM_BURST_LEN);
    verify_rx_data(port, error_string, send_payload[0:num_words-2], 1);
    `ASSERT_FATAL(error_string == "", error_string);

    // Playback one more than burst/packet size
    start_replay(port, send_payload, buffer_size, num_words+1, MEM_BURST_LEN);
    verify_rx_data(port, error_string, send_payload[0:num_words], 1);
    `ASSERT_FATAL(error_string == "", error_string);

    `TEST_CASE_DONE(1);
  endtask : test_packet_sizes


  //---------------------------------------------------------------------------
  // Test small replay
  //---------------------------------------------------------------------------
  //
  // Make sure the smallest possible replay size works correctly.
  //
  //---------------------------------------------------------------------------

  task automatic test_small_replay(int port = 0);
    cvita_payload_t send_payload;
    string          error_string;
    int             num_words;

    test_step = "Test small replay";
    `TEST_CASE_START(test_step);

    // Test single word playback
    num_words = 1;
    gen_payload(send_payload, num_words);
    start_replay(port, send_payload, BPP, num_words, WPP, 1024);
    verify_rx_data(port, error_string, send_payload, 1);
    `ASSERT_FATAL(error_string == "", error_string);

    `TEST_CASE_DONE(1);
  endtask : test_small_replay


  //---------------------------------------------------------------------------
  // Test playback that's larger than buffer
  //---------------------------------------------------------------------------
  //
  // We want to make sure that playback wraps as expected back to the beginning
  // of the buffer and that buffers that aren't a multiple of the burst size
  // wrap correctly.
  //
  //---------------------------------------------------------------------------

  task automatic test_oversized_playback(int port = 0);
    cvita_payload_t  send_payload;
    cvita_payload_t  exp_payload;
    string           error_string;
    int              buffer_size;
    int              num_words_rec;
    int              num_words_play;

    test_step = "Test oversized playback";
    `TEST_CASE_START(test_step);

    // Set number of words to test to the smallest size possible
    buffer_size    = (3 * MEM_BURST_LEN) / 2 * MEM_WORD_SIZE;  // 1.5 memory bursts in size (in bytes)
    num_words_rec  = buffer_size / MEM_WORD_SIZE;              // Same as buffer_size (in words)
    num_words_play = 2 * MEM_BURST_LEN;                        // 2 memory bursts in size (in words)

    // Start playback of data
    gen_payload(send_payload, num_words_rec);
    start_replay(port, send_payload, buffer_size, num_words_play);

    // Since we recorded 1.5 memory bursts and are playing back 2, we should
    // get the a repeat of the first third of data.
    exp_payload = { send_payload, send_payload[0:num_words_rec/3-1] };
    verify_rx_data(port, error_string, exp_payload, 1);
    `ASSERT_FATAL(error_string == "", error_string);

    `TEST_CASE_DONE(1);
  endtask : test_oversized_playback


  //---------------------------------------------------------------------------
  // Test chained mode
  //---------------------------------------------------------------------------

  task automatic test_chained(int port = 0);
    cvita_payload_t  send_payload;
    cvita_metadata_t md;
    string           error_string;
    int              num_words;
    logic [31:0]     cmd;

    test_step = "Test chain mode";
    `TEST_CASE_START(test_step);

    num_words = 70;

    // Update record buffer settings
    tb_streamer.write_reg(sid_noc_block_replay, SR_REC_BASE_ADDR, 0, port);
    tb_streamer.write_reg(sid_noc_block_replay, SR_REC_BUFFER_SIZE, num_words*MEM_WORD_SIZE, port);
    tb_streamer.write_reg(sid_noc_block_replay, SR_PLAY_BASE_ADDR, 0, port);
    tb_streamer.write_reg(sid_noc_block_replay, SR_PLAY_BUFFER_SIZE, num_words*MEM_WORD_SIZE, port);

    // Restart the record buffer
    tb_streamer.write_reg(sid_noc_block_replay, SR_REC_RESTART, 0, port);

    // Write num_words to record buffer
    gen_payload(send_payload, num_words);
    tb_streamer.send(send_payload, md, port);

    // Wait until all the data has been written
    wait_record_fullness(port, num_words*MEM_WORD_SIZE);

    // Send two commands, chained together, each sending half the data
    cmd       = 0;
    cmd[31]   = 1;           // send_imm
    cmd[30]   = 1;           // chain
    cmd[29]   = 0;           // reload
    cmd[28]   = 0;           // stop
    cmd[27:0] = num_words/2; // num_lines
    tb_streamer.write_user_reg(sid_noc_block_replay, SR_RX_CTRL_COMMAND, cmd, port);

    cmd       = 0;
    cmd[31]   = 0;           // send_imm
    cmd[30]   = 0;           // chain
    cmd[29]   = 0;           // reload
    cmd[28]   = 0;           // stop
    cmd[27:0] = num_words/2; // num_lines
    tb_streamer.write_user_reg(sid_noc_block_replay, SR_RX_CTRL_COMMAND, cmd, port);

    // Check the output, looking for the full set of data
    verify_rx_data(port, error_string, send_payload, 1);
    `ASSERT_FATAL(error_string == "", error_string);

    `TEST_CASE_DONE(1);
  endtask : test_chained


  //---------------------------------------------------------------------------
  // Test chained reload (continuous replay)
  //---------------------------------------------------------------------------

  task automatic test_chained_reload(int port = 0);
    cvita_payload_t  send_payload;
    string           error_string;
    int              buffer_words;
    int              replay_words;

    test_step = "Test chained reload (automatic replay)";
    `TEST_CASE_START(test_step);

    // Number of words to store in buffer
    buffer_words = 37;

    // Number of words to replay per command. Make it something different
    // form the buffer size (buffer_words) to verify that the data is
    // continuous between reloads of the original command.
    replay_words = 27;

    // Generate buffer_words of data to record
    gen_payload(send_payload, buffer_words);

    // Start playback of replay_words data in continuous mode (i.e., chained
    // reload).
    start_replay(port, send_payload, buffer_words*MEM_WORD_SIZE, replay_words, WPP, 0, 1);

    // Check the output, looking for the full set of data, multiple times
    repeat(5) begin
      verify_rx_data(port, error_string, send_payload, 0);
      `ASSERT_FATAL(error_string == "", error_string);
    end

    // Test stopping
    stop_replay(port);

    `TEST_CASE_DONE(1);
  endtask : test_chained_reload


  //---------------------------------------------------------------------------
  // Test halt
  //---------------------------------------------------------------------------

  task automatic test_halt(int port = 0);
    cvita_payload_t  send_payload;
    string           error_string;
    int              num_words;

    test_step = "Test halt";
    `TEST_CASE_START(test_step);

    num_words = 23;

    // Start playback of continuous data
    gen_payload(send_payload, num_words);
    start_replay(port, send_payload, num_words*MEM_WORD_SIZE, num_words, WPP, 0, 1);

    // Grab 3 packets, to make sure it's being repeated
    repeat (3) begin
      verify_rx_data(port, error_string, send_payload, 0);
      `ASSERT_FATAL(error_string == "", error_string);
    end

    // Send halt command
    tb_streamer.write_user_reg(sid_noc_block_replay, SR_RX_CTRL_HALT, 0, port);

    // Keep reading frames until we've cleared them all. If the halt failed
    // then this should timeout.
    flush_rx(port);

    // Send an extra halt to make sure that it gets properly ignored and
    // doesn't break the next command.
    tb_streamer.write_user_reg(sid_noc_block_replay, SR_RX_CTRL_HALT, 0, port);

    `TEST_CASE_DONE(1);
  endtask : test_halt


  //---------------------------------------------------------------------------
  // Test overfilled record buffer
  //---------------------------------------------------------------------------
  //
  // Record more words than the buffer can fit. Make sure we don't overfill our
  // buffer and make sure reading it back loops only the data that should have
  // been captured.
  //
  //---------------------------------------------------------------------------

  task automatic test_overfilled_record(int port = 0);
    cvita_payload_t  send_payload;
    string           error_string;
    int              num_words;
    int              buffer_words;
    int              buffer_size;
    logic [63:0]     readback;

    test_step = "Test overfilled record buffer";
    `TEST_CASE_START(test_step);

    // Number of words to record (num_words) is larger than buffer size.
    num_words    = 97;
    buffer_words = 43;                            // Buffer size in words
    buffer_size  = buffer_words * MEM_WORD_SIZE;  // Buffer size in bytes

    // Restart the record buffer
    tb_streamer.write_reg(sid_noc_block_replay, SR_REC_RESTART, 0, port);

    // Generate more record data than can fit in the buffer
    gen_payload(send_payload, num_words);

    // Start playback
    start_replay(port, send_payload, buffer_size, num_words);

    // We should get two frames of buffer_words, then one smaller frame to
    // bring us up to num_words total.
    send_payload = send_payload[0 : buffer_words-1];
    for (int i = 0; i < 2; i ++) begin
      verify_rx_data(port, error_string, send_payload, 0);
      `ASSERT_FATAL(error_string == "", error_string);
    end
    send_payload = send_payload[0 : (num_words % buffer_words)-1];
    verify_rx_data(port, error_string, send_payload, 1);
    `ASSERT_FATAL(error_string == "", error_string);

    // Make sure SR_REC_FULLNESS didn't keep increasing
    tb_streamer.read_user_reg(sid_noc_block_replay, SR_REC_FULLNESS, readback, port);
    `ASSERT_FATAL(readback == buffer_words*MEM_WORD_SIZE, "SR_REC_FULLNESS went beyond expected bounds");

    // Reset record buffer so that it accepts the rest of the data that's
    // stalled in the crossbar or input FIFO.
    tb_streamer.write_reg(sid_noc_block_replay, SR_REC_BUFFER_SIZE, num_words*MEM_WORD_SIZE, port);
    tb_streamer.write_reg(sid_noc_block_replay, SR_REC_RESTART, 0, port);

    // Wait until all the data has been written
    wait_record_fullness(port, (num_words - buffer_words)*MEM_WORD_SIZE);

    `TEST_CASE_DONE(1);

  endtask : test_overfilled_record


  //---------------------------------------------------------------------------
  // Test burst size
  //---------------------------------------------------------------------------
  //
  // Record amount of data that's larger than the configured RAM burst length
  // to make sure full-length bursts are handled correctly.
  //
  //---------------------------------------------------------------------------

  task automatic test_burst_size(int port = 0);
    cvita_payload_t  send_payload;
    string           error_string;
    int              num_words;
    int              buffer_size;

    test_step = "Test burst size";
    `TEST_CASE_START(test_step);

    num_words   = 4*MEM_BURST_LEN;           // Multiple of the burst size
    buffer_size = num_words * MEM_WORD_SIZE; // Size in bytes

    gen_payload(send_payload, num_words);
    start_replay(port, send_payload, buffer_size, num_words);
    verify_rx_data(port, error_string, send_payload, 1);
    `ASSERT_FATAL(error_string == "", error_string);

    `TEST_CASE_DONE(1);
  endtask : test_burst_size


  //---------------------------------------------------------------------------
  // Test 4k AXI boundary
  //---------------------------------------------------------------------------
  //
  // Make sure crossing the AXI 4k boundary is handled correctly.
  //
  //---------------------------------------------------------------------------

  task automatic test_4k_boundary(int port = 0);
    cvita_payload_t  send_payload;
    cvita_payload_t  temp_payload;
    string           error_string;
    int              num_words;
    int              buffer_size;
    int              base_addr;

    test_step = "Test 4k AXI Boundary";
    `TEST_CASE_START(test_step);

    //
    // Test bursting up to and after boundary
    //

    // Setup two bursts
    num_words   = 2*MEM_BURST_LEN;
    buffer_size = num_words * MEM_WORD_SIZE;    // Size in bytes

    // Choose a base address such that we end the first burst at the 4 KiB
    // boundary and start the next burst on the boundary.
    if (num_words/2 * MEM_WORD_SIZE >= AXI_ALIGNMENT) begin
      // In this case our memory burst size is bigger than 4K, so we're
      // guaranteed to cross the 4K alignment boundary.
      base_addr = 0;
    end else begin
      base_addr = AXI_ALIGNMENT - (num_words/2)*MEM_WORD_SIZE;
    end

    // Record data across the 4K boundary then play it back
    gen_payload(send_payload, num_words);
    start_replay(port, send_payload, buffer_size, num_words, WPP, base_addr);

    // Verify the data
    verify_rx_data(port, error_string, send_payload, 1);
    `ASSERT_ERROR(error_string == "", error_string);

    //
    // Test bursting across boundary
    //

    // Setup a single burst across the 4 KiB boundary
    num_words   = MEM_BURST_LEN;
    buffer_size = num_words * MEM_WORD_SIZE;    // Size in bytes

    // Choose a base address such that we end a burst on the 4 KiB boundary,
    // then continue on the other side.
    if (num_words/2 * MEM_WORD_SIZE >= AXI_ALIGNMENT) begin
      // In this case our memory burst size is bigger than 4K, so we're
      // guaranteed to cross the 4K alignment boundary.
      base_addr = 0;
    end else begin
      base_addr = AXI_ALIGNMENT - (num_words/2)*MEM_WORD_SIZE;
    end

    // Record data across the 4K boundary then play it back
    gen_payload(send_payload, num_words);
    start_replay(port, send_payload, buffer_size, num_words, WPP, base_addr);

    // Verify the data received
    verify_rx_data(port, error_string, send_payload, 1);
    `ASSERT_ERROR(error_string == "", error_string);

    `TEST_CASE_DONE(1);
  endtask : test_4k_boundary


  //---------------------------------------------------------------------------
  // Test small packet sizes
  //---------------------------------------------------------------------------

  task automatic test_small_packet(int port = 0);
    cvita_payload_t  send_payload;
    string           error_string;
    int              buffer_size;
    int              num_words;
    int              wpp;

    test_step = "Test small packet size";
    `TEST_CASE_START(test_step);

    //
    // Test smaller than burst size
    //

    // Set number of words to test to the smallest size possible
    buffer_size = 2 * MEM_BURST_LEN * MEM_WORD_SIZE;    // 2 memory bursts in size (in bytes)
    num_words   = buffer_size / MEM_WORD_SIZE;          // Same as buffer_size (in words)
    wpp         = MEM_BURST_LEN / 4;                    // Words per packet

    gen_payload(send_payload, num_words);
    start_replay(port, send_payload, buffer_size, num_words, wpp);

    // We should get 8 small packets instead of 2 large ones
    for (int k = 0; k < 8; k ++) begin
      verify_rx_data(port, error_string,
                     send_payload[wpp*k:wpp*(k+1)-1],
                     (k == 7 ? 1 : 0));
      `ASSERT_FATAL(error_string == "", error_string);
    end

    //
    // Test shortest supported packet size (WPP = 2)
    //
    
    wpp = 2;
    num_words = wpp*10;
    gen_payload(send_payload, num_words);
    start_replay(port, send_payload, BPP, num_words, wpp, 1024);
    for (int i=0; i < num_words; i+=2) begin
      verify_rx_data(port, error_string, send_payload[i:i+1], i == num_words-2 ? 1 : 0);
      `ASSERT_FATAL(error_string == "", error_string);
    end

    `TEST_CASE_DONE(1);
  endtask : test_small_packet


  //---------------------------------------------------------------------------
  // Test basic timed playback
  //---------------------------------------------------------------------------

  task automatic test_basic_timed(int port = 0);
    cvita_payload_t  send_payload;
    string           error_string;
    logic     [64:0] timestamp;
    int              num_words;
    int              buffer_size;
    int              wpp;

    test_step = "Test basic playback, timed";
    `TEST_CASE_START(test_step);

    num_words   = MEM_BURST_LEN;
    buffer_size = num_words * MEM_WORD_SIZE;
    timestamp   = 64'h0123456789ABCDEF;

    // Set the packet size small enough so that we get multiple packets
    // (multiple timestamps).
    wpp = num_words/8;

    gen_payload(send_payload, num_words);
    start_replay(port, send_payload, buffer_size, num_words, wpp, 0, 0, timestamp);

    verify_rx_data(port, error_string, send_payload, 1, timestamp);
    `ASSERT_FATAL(error_string == "", error_string);

    `TEST_CASE_DONE(1);
  endtask : test_basic_timed


  //---------------------------------------------------------------------------
  // Test chained playback, timed
  //---------------------------------------------------------------------------

  task automatic test_chained_timed(int port = 0);

    cvita_payload_t  send_payload;
    cvita_metadata_t md;
    string           error_string;
    logic     [64:0] timestamp;
    logic     [31:0] cmd;
    int              buffer_size;
    int              num_words;

    test_step = "Test chained playback, timed";
    `TEST_CASE_START(test_step);

    num_words   = 70;
    buffer_size = num_words * MEM_WORD_SIZE;

    // Update record buffer settings
    tb_streamer.write_reg(sid_noc_block_replay, SR_REC_BASE_ADDR, 0, port);
    tb_streamer.write_reg(sid_noc_block_replay, SR_REC_BUFFER_SIZE, buffer_size, port);
    tb_streamer.write_reg(sid_noc_block_replay, SR_PLAY_BASE_ADDR, 0, port);
    tb_streamer.write_reg(sid_noc_block_replay, SR_PLAY_BUFFER_SIZE, buffer_size, port);

    // Restart the record buffer
    tb_streamer.write_reg(sid_noc_block_replay, SR_REC_RESTART, 0, port);

    // Write num_words to record buffer
    gen_payload(send_payload, num_words);
    tb_streamer.send(send_payload, md, port);

    // Wait until all the data has been written
    wait_record_fullness(port, num_words*MEM_WORD_SIZE);

    // Set the time for playback
    timestamp = 64'h0123456789ABCDEF;
    tb_streamer.write_user_reg(sid_noc_block_replay, SR_RX_CTRL_TIME_HI, timestamp[63:32], port);
    tb_streamer.write_user_reg(sid_noc_block_replay, SR_RX_CTRL_TIME_LO, timestamp[31: 0], port);

    // Send command to playback data at specified time
    cmd       = 0;
    cmd[31]   = 0;           // send_imm
    cmd[30]   = 1;           // chain
    cmd[29]   = 0;           // reload
    cmd[28]   = 0;           // stop
    cmd[27:0] = num_words/2; // num_lines
    tb_streamer.write_user_reg(sid_noc_block_replay, SR_RX_CTRL_COMMAND, cmd, port);

    cmd       = 0;
    cmd[31]   = 0;           // send_imm
    cmd[30]   = 0;           // chain
    cmd[29]   = 0;           // reload
    cmd[28]   = 0;           // stop
    cmd[27:0] = num_words/2; // num_lines
    tb_streamer.write_user_reg(sid_noc_block_replay, SR_RX_CTRL_COMMAND, cmd, port);

    // Check the output, looking for the full set of data
    verify_rx_data(port, error_string, send_payload, 1, timestamp);
    `ASSERT_FATAL(error_string == "", error_string);

    `TEST_CASE_DONE(1);
  endtask : test_chained_timed


  //---------------------------------------------------------------------------
  // Test chained reload, timed (automatic replay)
  //---------------------------------------------------------------------------

  task automatic test_chained_reload_timed(int port = 0);
    cvita_payload_t  send_payload;
    string           error_string;
    logic     [64:0] timestamp;
    int              buffer_words;
    int              replay_words;

    test_step = "Test chained reload, timed";
    `TEST_CASE_START(test_step);

    // Number of words to store in buffer
    buffer_words = 37;

    // Number of words to replay per command. Make it something different
    // form the buffer size (buffer_words) to verify that the data is
    // continuous between reloads of the original command.
    replay_words = 27;

    // Generate buffer_words of data to record
    gen_payload(send_payload, buffer_words);

    // Start playback of replay_words data in continuous mode (i.e., chained
    // reload).
    timestamp = 64'h3210012332100123;
    start_replay(port, send_payload, buffer_words*MEM_WORD_SIZE, replay_words, WPP, 0, 1, timestamp);

    // Check the output, 3 times to make sure it's being repeated
    for (int k = 0; k < 3; k ++) begin
      verify_rx_data(port, error_string, send_payload, 0, timestamp);
      `ASSERT_FATAL(error_string == "", error_string);
      timestamp = timestamp + buffer_words*SAMP_PER_WORD;
    end

    // Test stopping
    stop_replay(port);

    `TEST_CASE_DONE(1);
  endtask : test_chained_reload_timed



  //---------------------------------------------------------------------------
  // Main Test Process
  //---------------------------------------------------------------------------

  initial begin : tb_main
    logic [31:0] random_word;
    logic [63:0] readback;
    string       str;
    static int   port = 1;


    //-------------------------------------------------------------------------
    // Test -- Reset
    //-------------------------------------------------------------------------

    test_step = "Wait for Reset";
    `TEST_CASE_START(test_step);
    while (bus_rst) @(posedge bus_clk);
    while (ce_rst) @(posedge ce_clk);
    `TEST_CASE_DONE(~bus_rst & ~ce_rst);


    //-------------------------------------------------------------------------
    // Test -- Check for correct NoC IDs
    //-------------------------------------------------------------------------

    test_step = "Check NoC ID";
    `TEST_CASE_START(test_step);

    // Read NOC IDs
    tb_streamer.read_reg(sid_noc_block_replay, RB_NOC_ID, readback);
    $display("Read NOC ID: %16x", readback);
    `ASSERT_ERROR(readback == noc_block_replay.NOC_ID, "Incorrect NOC ID");

    `TEST_CASE_DONE(1);


    //-------------------------------------------------------------------------
    // Test -- Connect RFNoC blocks
    //-------------------------------------------------------------------------

    test_step = "Connect RFNoC blocks";
    `TEST_CASE_START(test_step);
    `RFNOC_CONNECT_BLOCK_PORT(noc_block_tb,     0, noc_block_replay, 0, S8, SPP);
    `RFNOC_CONNECT_BLOCK_PORT(noc_block_replay, 0, noc_block_tb,     0, S8, SPP);
    `RFNOC_CONNECT_BLOCK_PORT(noc_block_tb,     1, noc_block_replay, 1, S8, SPP);
    `RFNOC_CONNECT_BLOCK_PORT(noc_block_replay, 1, noc_block_tb,     1, S8, SPP);
    `TEST_CASE_DONE(1);


    //-------------------------------------------------------------------------
    // Test -- Wait for DRAM calibration to complete
    //-------------------------------------------------------------------------

    test_step = "Wait for DRAM calibration to complete";
    `TEST_CASE_START(test_step);
    while (init_done !== 1'b1) @(posedge bus_clk);
    `TEST_CASE_DONE(init_done);


    //-------------------------------------------------------------------------
    // Test sequences
    //-------------------------------------------------------------------------

    // These tests check two replay ports
    test_registers();
    test_basic();

    // These tests check the port indicated
    port = 1;
    test_packet_sizes(port);
    test_small_replay(port);
    test_oversized_playback(port);
    test_chained(port);
    test_chained_reload(port);
    test_halt(port);
    test_overfilled_record(port);
    test_burst_size(port);
    test_4k_boundary(port);
    test_small_packet(port);
    test_basic_timed(port);
    test_chained_timed(port);
    test_chained_reload_timed(port);


    //-------------------------------------------------------------------------
    // Finish
    //-------------------------------------------------------------------------

    `TEST_BENCH_DONE;
  end : tb_main

endmodule : noc_block_replay_tb

`default_nettype wire
