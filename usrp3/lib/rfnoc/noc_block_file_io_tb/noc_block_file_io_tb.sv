//
// Copyright 2015 National Instruments
//

`timescale 1ns / 1ps

`define SIM_RUNTIME_US 1000
`define NS_PER_TICK 1
`define NUM_TEST_CASES 2

`include "sim_exec_report.vh"
`include "sim_rfnoc_lib.vh"

module noc_block_file_io_tb;
  `TEST_BENCH_INIT("noc_block_file_io_tb", `NUM_TEST_CASES, `NS_PER_TICK);
  `RFNOC_SIM_INIT(1, 166.67, 200);
  `RFNOC_ADD_BLOCK(noc_block_eq, 0);
  `RFNOC_ADD_BLOCK(noc_block_file_io, 1);
  defparam noc_block_file_io.SINK_FILENAME = "../../../../output.bin";

  localparam PACKET_SIZE = 64;

  //----------------------------------------------------------------------------
  // Stimulus
  //----------------------------------------------------------------------------

  shortint long_preamble[PACKET_SIZE] = '{0, 0, 0, 0, 0, 0, 1, 1, -1, -1,
    1, 1, -1, 1, -1, 1, 1, 1, 1, 1, 1, -1, -1, 1, 1, -1, 1, -1, 1, 1, 1, 1, 0,
    1, -1, -1, 1, 1, -1, 1, -1, 1, -1, -1, -1, -1, -1, 1, 1, -1, -1, 1, -1, 1,
    -1, 1, 1, 1, 1, 0, 0, 0, 0, 0};

  initial begin
    logic [63:0] header;
    cvita_pkt_t packet;
    reg [63:0] mem [0:65535];
    int file;
    int file_length;

    // Prepare preamble: Scale to full range
    foreach(long_preamble[i]) begin
      if(long_preamble[i] == 1)
        long_preamble[i] = 32767;
      else if(long_preamble[i] == -1)
        long_preamble[i] = -32768;
    end

    while(bus_rst) @(posedge bus_clk);
    while(ce_rst) @(posedge ce_clk);

    repeat(10) @(posedge bus_clk);

    // Test bench -> Equalizer -> Test bench
    `RFNOC_CONNECT_BLOCK_PORT(noc_block_tb, 1, noc_block_eq, 0, PACKET_SIZE*4);
    //`RFNOC_CONNECT_BLOCK_PORT(noc_block_eq, 0, noc_block_tb, 1, PACKET_SIZE*4);
    `RFNOC_CONNECT_BLOCK_PORT(noc_block_eq, 0, noc_block_file_io, 0, PACKET_SIZE*4);

    // Setup equalizer
    tb_next_dst = sid_noc_block_eq;

    repeat(10) @(posedge bus_clk);

    //-------------------------------------------------------------------------

    // Setup header
    header = flatten_chdr_no_ts('{pkt_type: DATA, has_time: 0, eob: 1,
      seqno: 12'h0, length: 8, src_sid: sid_noc_block_tb,
      dst_sid: sid_noc_block_eq, timestamp: 64'h0});

    packet.push_back(header);

    // Add preamble
    for(int i = 0; i < PACKET_SIZE - 1; i = i + 2) begin
      logic [63:0] preamble;
      preamble = {shortint'(long_preamble[i]), shortint'(0),
        shortint'(long_preamble[i + 1]), shortint'(0)};

      packet.push_back(preamble);
    end

    // Send preamble
    tb_cvita_data.push_pkt(packet);
    packet = {};

    //-------------------------------------------------------------------------

    // Change header
    header[60] = 0; // EOB
    packet.push_back(header);

    // Add data
    for(int i = 0; i < PACKET_SIZE / 2; ++i) begin
      logic [63:0] data;
      shortint pos;
      shortint neg;
      pos = 32767;
      neg = -32768;
      data = {pos, neg, neg, pos};
      packet.push_back(data);
    end

    // Send data
    tb_cvita_data.push_pkt(packet);
    packet = {};

    //-------------------------------------------------------------------------

    #100000;

    // Read file
    file = $fopen("../../../../test-int16.bin", "r");
    file_length = $fread(mem, file);
    $display("Read %d lines", file_length);
    $fclose(file);

    // Change header
    header[60] = 1; // EOB
    packet.push_back(header);

    // Add preamble
    for(int i = 0; i < PACKET_SIZE / 2; ++i) begin
      packet.push_back(mem[i]);
    end

    // Send preamble
    tb_cvita_data.push_pkt(packet);
    packet = {};

    //-------------------------------------------------------------------------

    // Change header
    header[60] = 0; // EOB
    packet.push_back(header);

    // Add data
    for (int i = PACKET_SIZE / 2; i < PACKET_SIZE; ++i) begin
      packet.push_back(mem[i]);
    end

    // Send data
    tb_cvita_data.push_pkt(packet);
    packet = {};

    //-------------------------------------------------------------------------

    #100000;
    $finish;
  end

  //----------------------------------------------------------------------------
  // Verification
  //----------------------------------------------------------------------------

  initial begin : tb_main
    logic [63:0] data;
    cvita_pkt_t packet;
    reg [63:0] comp [0:65535];
    int file;
    int file_length;

    // Read file
    file = $fopen("../../../../comp-int16.bin", "r");
    file_length = $fread(comp, file);
    $display("Read %d lines", file_length);
    $fclose(file);

    `TEST_CASE_START("Wait for reset");
    while (bus_rst) @(posedge bus_clk);
    while (ce_rst) @(posedge ce_clk);
    `TEST_CASE_DONE(~bus_rst & ~ce_rst);

    #70000;

    packet = {};
    `TEST_CASE_START("Receive data");
    tb_cvita_data.pull_pkt(packet);
    $display("Header: %H", packet.pop_front());
    foreach(packet[i]) begin
      data = packet[i];
      $display("Received[%d]: %d, %d | %d, %d (%h)", shortint'(i),
        shortint'(data[63:48]), shortint'(data[47:32]), shortint'(data[31:16]),
        shortint'(data[15:0]), data);
    end
    `TEST_CASE_DONE(1);

    packet = {};
    `TEST_CASE_START("Receive file data");
    tb_cvita_data.pull_pkt(packet);
    $display("Header: %H", packet.pop_front());
    foreach(packet[i]) begin
      data = packet[i];
      $display("Received[%d]: %d, %d | %d, %d (%h)", shortint'(i),
        shortint'(data[63:48]), shortint'(data[47:32]), shortint'(data[31:16]),
        shortint'(data[15:0]), data);
    end
    `TEST_CASE_DONE(1);

    // End simulation
    #1000;
    $finish;
  end

endmodule
