`timescale 1ns/1ps
`define NS_PER_TICK 1
`define NUM_TEST_CASES 6

`include "sim_exec_report.vh"
`include "sim_clks_rsts.vh"
`include "sim_rfnoc_lib.svh"

module noc_shell_tb();
  `TEST_BENCH_INIT("noc_shell_tb",`NUM_TEST_CASES,`NS_PER_TICK);
  localparam BUS_CLK_PERIOD = $ceil(1e9/166.67e6);
  localparam CE_CLK_PERIOD  = $ceil(1e9/200e6);
  localparam NUM_CE         = 1;  // Number of Computation Engines / User RFNoC blocks to simulate
  localparam NUM_STREAMS    = 1;  // Number of test bench streams
  `RFNOC_SIM_INIT(NUM_CE, NUM_STREAMS, BUS_CLK_PERIOD, CE_CLK_PERIOD);
  `RFNOC_ADD_BLOCK(noc_block_skeleton, 0);

  localparam SPP = 64; // Samples per packet

  /********************************************************
  ** Verification
  ********************************************************/
  initial begin : tb_main
    string s;
    logic [31:0] random_word;
    logic [63:0] readback;
    logic [31:0] expected_resp_code;
    cvita_payload_t send_payload;
    cvita_metadata_t send_md;
    cvita_payload_t recv_payload;
    cvita_metadata_t recv_md;
    cvita_pkt_t response;
    cvita_pkt_type_t pkt_type;

    /********************************************************
    ** Test 1 -- Reset
    ********************************************************/
    `TEST_CASE_START("Wait for Reset");
    while (bus_rst) @(posedge bus_clk);
    while (ce_rst) @(posedge ce_clk);
    `TEST_CASE_DONE(~bus_rst & ~ce_rst);

    /********************************************************
    ** Test 2 -- Check for correct NoC IDs
    ********************************************************/
    `TEST_CASE_START("Check NoC ID");
    // Read NOC IDs
    tb_streamer.read_reg(sid_noc_block_skeleton, RB_NOC_ID, readback);
    $display("Read Skeleton NOC ID: %16x", readback);
    `ASSERT_ERROR(readback == noc_block_skeleton.NOC_ID, "Incorrect NOC ID");
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 3 -- Connect RFNoC blocks
    ********************************************************/
    `TEST_CASE_START("Connect RFNoC blocks");
    `RFNOC_CONNECT(noc_block_tb,noc_block_skeleton,SC16,SPP);
    `RFNOC_CONNECT(noc_block_skeleton,noc_block_tb,SC16,SPP);
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 4 -- Write / readback user registers
    ********************************************************/
    `TEST_CASE_START("Write / readback user registers");
    random_word = $random();
    tb_streamer.write_user_reg(sid_noc_block_skeleton, noc_block_skeleton.SR_TEST_REG_0, random_word);
    tb_streamer.read_user_reg(sid_noc_block_skeleton, 0, readback);
    $sformat(s, "User register 0 incorrect readback! Expected: %0d, Actual %0d", readback[31:0], random_word);
    `ASSERT_ERROR(readback[31:0] == random_word, s);
    random_word = $random();
    tb_streamer.write_user_reg(sid_noc_block_skeleton, noc_block_skeleton.SR_TEST_REG_1, random_word);
    tb_streamer.read_user_reg(sid_noc_block_skeleton, 1, readback);
    $sformat(s, "User register 1 incorrect readback! Expected: %0d, Actual %0d", readback[31:0], random_word);
    `ASSERT_ERROR(readback[31:0] == random_word, s);
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 5 -- Flow control ACK
    ********************************************************/
    `TEST_CASE_START("Test flow control ack");
    // Send and receive a packet
    for (int i = 0; i < SPP/2; i++) begin
      send_payload.push_back(64'(i));
    end
    tb_streamer.send(send_payload);
    tb_streamer.recv(recv_payload,recv_md);
    //
    // Force the next packet to be lost and check that the
    // producer block's flow control byte count does not
    // match consumer block's byte count
    //
    force noc_block_skeleton.i_tvalid = 1'b0;
    tb_streamer.send(send_payload);
    while (~noc_block_skeleton.i_tlast) @(posedge ce_clk);
    while (noc_block_skeleton.i_tlast) @(posedge ce_clk);
    `ASSERT_ERROR(noc_block_skeleton.noc_shell.gen_noc_input_port.noc_input_port.noc_responder.flow_control_responder.byte_count_running !=
                  noc_block_tb.noc_shell.gen_noc_output_port.noc_output_port.source_flow_control.current_byte,
                  "Producer's flow control byte count should not match consumer's byte count!");
    //
    // Allow next packet to be received, capture seqnum error packet,
    // and check that flow control was properly updated
    //
    release noc_block_skeleton.i_tvalid;
    tb_streamer.send(send_payload);
    // Check error response packet
    tb_streamer.pull_resp_pkt(response);
    pkt_type = response.hdr.pkt_type;
    $sformat(s, "Incorrect response packet type! Received: 2'b%0b Expected: 2'b%0b", pkt_type, RESP);
    `ASSERT_ERROR(pkt_type == RESP, s);
    $sformat(s, "Incorrect response packet EOB value! Received: %1b Expected: %1b", response.hdr.eob, 1'b1);
    `ASSERT_ERROR(response.hdr.eob == 1'b1, s);
    $sformat(s, "Incorrect response packet 'has time' value! Received: %1b Expected: %1b", response.hdr.has_time, 1'b0);
    `ASSERT_ERROR(response.hdr.has_time == 1'b0, s);
    $sformat(s, "Incorrect source SID! Received: %4x Expected: %4x", response.hdr.src_sid, sid_noc_block_skeleton);
    `ASSERT_ERROR(response.hdr.src_sid == sid_noc_block_skeleton, s);
    // No need to check dst_sid, otherwise how did we manage to receive the packet?
    expected_resp_code = noc_block_skeleton.noc_shell.gen_noc_input_port.noc_input_port.noc_responder.packet_error_responder.CODE_SEQ_ERROR_MIDBURST[63:32];
    $sformat(s, "Incorrect response packet code! Received: %8x Expected: %8x", response.payload[0][63:32], expected_resp_code);
    `ASSERT_ERROR(response.payload[0][63:32] == expected_resp_code, s);
    // Packet should have been dropped, wait awhile for FC packet to propagate and check FC byte counters, they should match
    repeat(100) @(posedge ce_clk);
    `ASSERT_ERROR(noc_block_skeleton.noc_shell.gen_noc_input_port.noc_input_port.noc_responder.flow_control_responder.byte_count_running ==
                  noc_block_tb.noc_shell.gen_noc_output_port.noc_output_port.source_flow_control.current_byte,
                  "Producer's flow control byte count should match consumer's byte count!");
    // Send and receive a few packets and make sure byte counters still match
    repeat(4) begin
      tb_streamer.send(send_payload);
      tb_streamer.recv(recv_payload,recv_md);
    end
    `ASSERT_ERROR(noc_block_skeleton.noc_shell.gen_noc_input_port.noc_input_port.noc_responder.flow_control_responder.byte_count_running ==
                  noc_block_tb.noc_shell.gen_noc_output_port.noc_output_port.source_flow_control.current_byte,
                  "Producer's flow control byte count should match consumer's byte count!");
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 6 -- Fill window buffer
    ********************************************************/
    `TEST_CASE_START("Test filling window buffer");
    fork
    begin
      int i;
      send_payload = {};
      for (int i = 0; i < SPP/2; i++) begin
        send_payload.push_back(64'(i));
      end
      // Send many packets so window buffer fills
      $display("Fill window buffer");
      repeat(400) begin
        tb_streamer.send(send_payload);
        i++;
      end
      $display("Sent %0d packets", i);
      send_md = '{eob:1'b1, has_time:1'b0, timestamp:64'd0};
      tb_streamer.send(send_payload,send_md);
    end
    begin
      int i;
      // Don't read packets for awhile so window buffer fills
      repeat(10000) @(posedge ce_clk);
      $display("Flush packets");
      tb_streamer.recv(recv_payload,recv_md);
      while (recv_md.eob != 1'b1) begin
        tb_streamer.recv(recv_payload,recv_md);
        i++;
      end
      $display("Received %0d packets",i);
    end
    join
    `ASSERT_ERROR(noc_block_skeleton.noc_shell.gen_noc_input_port.noc_input_port.noc_responder.flow_control_responder.byte_count_running ==
                  noc_block_tb.noc_shell.gen_noc_output_port.noc_output_port.source_flow_control.current_byte,
                  "Producer's flow control byte count should match consumer's byte count!");
    `TEST_CASE_DONE(1);
    `TEST_BENCH_DONE;

  end
endmodule
