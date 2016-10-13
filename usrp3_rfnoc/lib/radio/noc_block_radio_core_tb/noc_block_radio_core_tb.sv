//
// Copyright 2016 Ettus Research
//

`timescale 1ns/1ps

`define SIM_TIMEOUT_US 10000
`define NS_PER_TICK 1
`define NUM_TEST_CASES 15

`include "sim_exec_report.vh"
`include "sim_rfnoc_lib.svh"

module noc_block_radio_core_tb;
  /********************************************************
  ** RFNoC Initialization
  ********************************************************/
  `TEST_BENCH_INIT("noc_block_rado_core_tb",`NUM_TEST_CASES,`NS_PER_TICK);
  localparam BUS_CLK_PERIOD   = $ceil(1e9/50e6);
  localparam CE_CLK_PERIOD    = $ceil(1e9/50e6);
  localparam RADIO_CLK_PERIOD = $ceil(1e9/56e6);
  localparam NUM_CE           = 1;
  localparam NUM_STREAMS      = 2;
  `RFNOC_SIM_INIT(NUM_CE, NUM_STREAMS, BUS_CLK_PERIOD, CE_CLK_PERIOD);
  `RFNOC_ADD_BLOCK_CUSTOM(noc_block_radio_core, 0 /* xbar port 0 */)
  `DEFINE_CLK(radio_clk, RADIO_CLK_PERIOD, 50);
  `DEFINE_RESET(radio_rst, 0, 1000);

  /********************************************************
  ** DUT, due to non-standard I/O we cannot use `RFNOC_ADD_BLOCK()
  ********************************************************/
  `include "radio_core_regs.vh"
  localparam NUM_CHANNELS = 2;
  localparam TX_STB_RATE = 2;
  localparam RX_STB_RATE = 2;
  logic rx_stb, tx_stb, rx_stb_int, tx_stb_dly;
  logic [32*NUM_CHANNELS-1:0] rx, tx, rx_int;
  logic pps = 1'b0;
  logic sync_in = 1'b0;
  logic [NUM_CHANNELS-1:0] sync;
  logic [NUM_CHANNELS*32-1:0] misc_ins = 'd0;
  logic [NUM_CHANNELS*32-1:0] misc_outs, leds;
  logic [NUM_CHANNELS*32-1:0] fp_gpio_in = 'd0;
  logic [NUM_CHANNELS*32-1:0] db_gpio_in = 'd0;
  logic [NUM_CHANNELS*32-1:0] fp_gpio_out, fp_gpio_ddr, db_gpio_out, db_gpio_ddr;
  logic [NUM_CHANNELS*8-1:0] sen;
  logic [NUM_CHANNELS-1:0] sclk, mosi, miso = 'd0;
  noc_block_radio_core #(
    .NUM_CHANNELS(NUM_CHANNELS),
    .USE_SPI_CLK(1))
  noc_block_radio_core (
    .bus_clk(bus_clk), .bus_rst(bus_rst),
    .ce_clk(radio_clk), .ce_rst(radio_rst),
    // noc_block_radio_core_* signals created by `RFNOC_BLOCK_CUSTOM() above
    .i_tdata(noc_block_radio_core_i_tdata), .i_tlast(noc_block_radio_core_i_tlast),
    .i_tvalid(noc_block_radio_core_i_tvalid), .i_tready(noc_block_radio_core_i_tready),
    .o_tdata(noc_block_radio_core_o_tdata), .o_tlast(noc_block_radio_core_o_tlast),
    .o_tvalid(noc_block_radio_core_o_tvalid), .o_tready(noc_block_radio_core_o_tready),
    .ext_set_stb(), .ext_set_addr(), .ext_set_data(),
    .rx_stb({NUM_CHANNELS{rx_stb}}), .rx(rx),
    .tx_stb({NUM_CHANNELS{tx_stb}}), .tx(tx),
    .pps(pps), .sync_in(sync_in), .sync_out(),
    .misc_ins(misc_ins), .misc_outs(misc_outs),
    .fp_gpio_in(fp_gpio_in), .fp_gpio_out(fp_gpio_out), .fp_gpio_ddr(fp_gpio_ddr),
    .db_gpio_in(db_gpio_in), .db_gpio_out(db_gpio_out), .db_gpio_ddr(db_gpio_ddr),
    .leds(leds),
    .spi_clk(bus_clk), .spi_rst(bus_rst), .sen(sen), .sclk(sclk), .mosi(mosi), .miso(miso),
    .debug());

  // Mux to emulate frontend loopback test
  logic rxtx_loopback;
  assign rx = rxtx_loopback ? tx : rx_int;
  assign rx_stb = rxtx_loopback ? tx_stb : rx_stb_int;

  // Create TX / RX strobes and RX input test data
  logic set_rx = 1'b0;
  logic [31:0] set_rx_val[0:NUM_CHANNELS-1];
  integer ramp_val, rx_stb_cnt, tx_stb_cnt;
  logic tx_capture_stb;
  logic [31:0] tx_capture[0:NUM_CHANNELS-1];
  always @(posedge radio_clk) begin
    if (radio_rst) begin
      ramp_val       <= 0;
      rx_int         <= {NUM_CHANNELS{32'h1}};
      rx_stb_int     <= 1'b0;
      tx_stb         <= 1'b0;
      tx_capture     <= '{NUM_CHANNELS{32'd0}};
      tx_capture_stb <= 1'b0;
      rx_stb_cnt     <= 1;
      tx_stb_cnt     <= 1;
    end else begin
      if (rx_stb_cnt == RX_STB_RATE) begin
        rx_stb_int   <= 1'b1;
        rx_stb_cnt   <= 1'b1;
      end else begin
        rx_stb_int   <= 1'b0;
        rx_stb_cnt   <= rx_stb_cnt + 1;
      end
      if (tx_stb_cnt == TX_STB_RATE) begin
        tx_stb       <= 1'b1;
        tx_stb_cnt   <= 1'b1;
      end else begin
        tx_stb       <= 1'b0;
        tx_stb_cnt   <= tx_stb_cnt + 1;
      end
      tx_capture_stb <= tx_stb;
      for (int i = 0; i < NUM_CHANNELS; i++) begin
        if (tx_stb) begin
          tx_capture[i] <= tx[32*i +: 32];
        end
      end
      if (rx_stb_int) begin
        ramp_val   <= ramp_val + 2;
      end
      for (int i = 0; i < NUM_CHANNELS; i++) begin 
        // Fixed value or ramp
        rx_int[32*i +: 32] <= set_rx ? set_rx_val[i] : {ramp_val[15:0],ramp_val[15:0]+1'b1};
      end
    end
  end

  /********************************************************
  ** Useful Tasks / Functions
  ** Note: Several signals are created via 
  **       `RFNOC_SIM_INIT(). See sim_rfnoc_lib.vh.
  ********************************************************/
  localparam SPP = 256;
  localparam PKT_SIZE_BYTES = SPP*4;   // In bytes
  localparam [31:0] TX_VERIF_WORD = 32'h12345678;

  task automatic send_radio_cmd_timed;
    input integer radio_num;
    input [7:0] addr;
    input [31:0] data;
    input [63:0] vita_time;
    output [63:0] readback;
    begin
      tb_streamer.write_reg_readback_timed(sid_noc_block_radio_core,addr,data,vita_time,readback,radio_num);
    end
  endtask

  task automatic send_radio_cmd;
    input integer radio_num;
    input [7:0] addr;
    input [31:0] data;
    output [63:0] readback;
    begin
      tb_streamer.write_reg_readback(sid_noc_block_radio_core,addr,data,readback,radio_num);
    end
  endtask

  task automatic read_radio_reg;
    input integer radio_num;
    input [7:0] addr;
    output [63:0] readback;
    begin
      tb_streamer.read_reg(sid_noc_block_radio_core,addr,readback,radio_num);
    end
  endtask

  task automatic read_radio_core_reg;
    input integer radio_num;
    input [7:0] addr;
    output [63:0] readback;
    begin
      tb_streamer.read_user_reg(sid_noc_block_radio_core,addr,readback,radio_num);
    end
  endtask

  task automatic send_tx_packet;
    input integer radio_num;
    input [15:0] num_samples;
    input has_time;
    input eob;
    input [63:0] timestamp;
    begin
      cvita_payload_t payload;
      cvita_metadata_t md = '{eob:eob, has_time:has_time, timestamp:timestamp};
      logic [63:0] readback;
      // Set CODEC IDLE which sets TX output value when not actively transmitting
      send_radio_cmd(radio_num, SR_CODEC_IDLE, TX_VERIF_WORD, readback);
      // Send TX burst
      payload = {};
      // Generate ramp pattern for TX samples
      for (int k = 0; k < num_samples/2; k = k + 1) begin
        payload.push_back({16'(4*k), 16'(4*k+1), 16'(4*k+2), 16'(4*k+3)});
      end
      if (has_time) begin
        $display("Radio %2d: Send timed TX burst, %0d samples at time %0d",radio_num,num_samples,timestamp);
        tb_streamer.send(payload,md,radio_num);
      end else begin
        $display("Radio %2d: Send TX burst, %0d samples",radio_num,num_samples);
        tb_streamer.send(payload,md,radio_num);
      end
      $display("Radio %2d: TX burst sent",radio_num);
    end
  endtask

  task automatic start_rx;
    input integer radio_num;
    input [15:0] num_samples;
    input chain_commands;
    input reload;
    begin
      logic [63:0] readback;
      if (chain_commands & reload) begin
        $display("Radio %2d: Start RX, continuous receive",radio_num);
      end else begin
        $display("Radio %2d: Start RX, receive %5d samples",radio_num,num_samples);
      end
      // Set number of samples per packet
      send_radio_cmd(radio_num, SR_RX_CTRL_MAXLEN, SPP, readback);
      // Receive a single packet immediately
      send_radio_cmd(radio_num, SR_RX_CTRL_COMMAND,
                     {1'b1 /* Start immediately */, chain_commands, reload, 1'b0 /* Stop */, 28'(num_samples)},
                     readback);
      // Have to set time lower bytes to trigger the command being stored, although time is not used.
      send_radio_cmd(radio_num, SR_RX_CTRL_TIME_LO, 32'd0, readback);
    end
  endtask

  task automatic start_rx_timed;
    input integer radio_num;
    input [15:0] num_samples;
    input chain_commands;
    input reload;
    input [63:0] start_time;
    begin
      logic [63:0] readback;
      if (chain_commands & reload) begin
        $display("Radio %2d: Start RX, continuous receive",radio_num);
      end else begin
        $display("Radio %2d: Start RX, receive %5d samples and stop",radio_num,num_samples);
      end
      // Set number of samples per packet
      send_radio_cmd(radio_num, SR_RX_CTRL_MAXLEN, SPP, readback);
      // Receive a single packet immediately
      send_radio_cmd(radio_num, SR_RX_CTRL_COMMAND,
                     {1'b0 /* Start immediately */, chain_commands, reload, 1'b0 /* Stop */, 28'(num_samples)},
                     readback);
      // Set start time
      send_radio_cmd(radio_num, SR_RX_CTRL_TIME_HI, start_time[63:32], readback);
      send_radio_cmd(radio_num, SR_RX_CTRL_TIME_LO, start_time[31:0], readback);
    end
  endtask

  task automatic stop_rx;
    input integer radio_num;
    begin
      logic [63:0] readback;
      $display("Radio %2d: Stop RX",radio_num);
      send_radio_cmd(radio_num, SR_RX_CTRL_COMMAND,
                     {1'b0 /* Start immediately */,1'b0 /* Chain commands */,1'b0 /* Reload */, 1'b1 /* Stop */, 28'(0)},
                     readback);
    end
  endtask

  task automatic check_resp;
    input has_time;
    input eob;
    input [15:0] src_sid;
    input [31:0] expected_resp_code;
    begin
      cvita_pkt_t response;
      cvita_pkt_type_t pkt_type;
      string s;
      tb_streamer.pull_resp_pkt(response);
      pkt_type = response.hdr.pkt_type;
      $sformat(s, "Incorrect response packet type! Received: 2'b%0b Expected: 2'b%0b", pkt_type, RESP);
      `ASSERT_ERROR(pkt_type == RESP, s);
      $sformat(s, "Incorrect response packet EOB value! Received: %1b Expected: %1b", response.hdr.eob, eob);
      `ASSERT_ERROR(response.hdr.eob == eob, s);
      $sformat(s, "Incorrect response packet 'has time' value! Received: %1b Expected: %1b", response.hdr.has_time, has_time);
      `ASSERT_ERROR(response.hdr.has_time == has_time, s);
      $sformat(s, "Incorrect source SID! Received: %4x Expected: %4x", response.hdr.src_sid, src_sid);
      `ASSERT_ERROR(response.hdr.src_sid == src_sid, s);
      $sformat(s, "Incorrect response packet code! Received: %8x Expected: %8x", response.payload[0][63:32], expected_resp_code);
      `ASSERT_ERROR(response.payload[0][63:32] == expected_resp_code, s);
    end
  endtask

  task automatic check_radio_resp;
    input integer radio_num;
    input has_time;
    input eob;
    input [31:0] expected_resp_code;
    begin
      $display("Radio %2d: Checking radio response packet", radio_num);
      check_resp(has_time, eob, (sid_noc_block_radio_core + radio_num), expected_resp_code);
      $display("Radio %2d: Radio response packet correct", radio_num);
    end
  endtask

  task automatic check_tx_burst;
    input integer radio_num;
    input [15:0] num_samples;
    begin
      string s;
      logic [31:0] tx_expected;
      $display("Radio %2d: Checking TX output",radio_num);
      if (tx_capture[radio_num] != TX_VERIF_WORD) begin
        while(tx_capture[radio_num] != TX_VERIF_WORD) @(posedge tx_capture_stb);
      end
      while(tx_capture[radio_num] == TX_VERIF_WORD) begin
        // Using negedge so we align to the middle of the strobed TX output. Avoids false errors when checking TX output
        // and it transitions after radio_clk posedge.
        @(negedge radio_clk);
        while (~tx_stb) @(negedge radio_clk);
      end
      // Check ramp pattern
      for (int i = 0; i < num_samples; i++) begin
        tx_expected[31:16] = 2*i;
        tx_expected[15:0]  = 2*i+1;
        $sformat(s, "Incorrect TX output! Received: %8x Expected: %8x",tx_capture[radio_num],tx_expected);
        `ASSERT_ERROR(tx_capture[radio_num] == tx_expected, s);
        @(negedge radio_clk);
        while (~tx_stb) @(negedge radio_clk);
      end
      $sformat(s, "Incorrect TX idle output! Received: %8x Expected: %8x",tx_capture[radio_num],TX_VERIF_WORD);
      `ASSERT_ERROR(tx_capture[radio_num] == TX_VERIF_WORD, s);
      @(posedge radio_clk);
      $display("Radio %2d: TX output correct",radio_num);
    end
  endtask

  task automatic check_tx_idle;
    input integer radio_num;
    begin
      string s;
      // Check that output does not change
      $display("Radio %2d: Checking TX output",radio_num);
      while (~tx_stb) @(negedge radio_clk);
      for (int i = 0; i < 200; i++) begin
        $sformat(s, "Incorrect TX idle output! Received: %8x Expected: %8x",tx[32*radio_num +: 32],TX_VERIF_WORD);
        `ASSERT_ERROR(tx[32*radio_num +: 32] == TX_VERIF_WORD, s);
        @(negedge radio_clk);
        while (~tx_stb) @(negedge radio_clk);
      end
      @(posedge radio_clk);
      $display("Radio %2d: TX output correct",radio_num);
    end
  endtask

  task automatic flush_rx;
    input integer radio_num;
    begin
      cvita_pkt_t pkt;
      integer pkt_cnt = 0;
      pkt.hdr.eob = 1'b0;
      while (~pkt.hdr.eob) begin
        tb_streamer.pull_pkt(pkt,radio_num);
        pkt_cnt = pkt_cnt + 1;
      end
      $display("Radio %2d: Flushed %3d RX packets", radio_num, pkt_cnt);
    end
  endtask

  task automatic check_rx;
    input integer radio_num;
    begin
      string s;
      cvita_payload_t payload;
      cvita_metadata_t md;
      logic eob;
      $display("Radio %2d: Receiving RX packet", radio_num);
      tb_streamer.recv(payload,md,radio_num);
      $display("Radio %2d: Checking received RX packet", radio_num);
      for (int k = 1; k < payload.size(); k = k + 1) begin
        $sformat(s, "Incorrect RX input! Received: %8x Expected: %8x", payload[k], 
            {payload[k-1][63:48]+16'd4, payload[k-1][47:32]+16'd4, payload[k-1][31:16]+16'd4, payload[k-1][15:0]+16'd4});
        `ASSERT_ERROR(payload[k] == {payload[k-1][63:48]+16'd4, payload[k-1][47:32]+16'd4, payload[k-1][31:16]+16'd4, payload[k-1][15:0]+16'd4}, s);
      end
      $display("Radio %2d: Received RX packet correct", radio_num);
    end
  endtask

  /********************************************************
  ** Test Bench Main Thread
  ********************************************************/
  initial begin : tb_main
    string s;
    logic [63:0] noc_id;
    int num_channels;
    logic [63:0] readback;

    /* Initialization */
    rxtx_loopback = 0;
    set_rx = 0;

    /********************************************************
    ** Test 1 -- Reset
    ********************************************************/
    `TEST_CASE_START("Wait for Reset");
    while (bus_rst) @(posedge bus_clk);
    while (ce_rst) @(posedge ce_clk);
    `TEST_CASE_DONE(~bus_rst & ~ce_rst);

    /********************************************************
    ** Test 2 -- Setup RFNoC Connections & Radio Core NoC Shell
    **           Check for correct NoC ID
    ********************************************************/
    `TEST_CASE_START("Setup RFNoC");
    // For each radio, setup RFNoC connection: Test bench -> Radio Core -> Test bench
    // - Test bench has one stream per radio channel (or technically noc_block_tb has one block port per stream)
    for (int i = 0; i < NUM_CHANNELS; i++) begin
      `RFNOC_CONNECT_BLOCK_PORT(noc_block_tb,i,noc_block_radio_core,i,SC16,SPP);
      `RFNOC_CONNECT_BLOCK_PORT(noc_block_radio_core,i,noc_block_tb,i,SC16,SPP);
    end

    // Read NOC ID
    $display("Read NOC ID");
    read_radio_reg(0, RB_NOC_ID, noc_id);
    $display("Read NOC ID: %16x",noc_id);
    `ASSERT_ERROR(noc_id == noc_block_radio_core.NOC_ID, "Incorrect NOC ID");
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 3 -- Radio core settings register loopback
    **           Set & check radio core test register
    ********************************************************/
    `TEST_CASE_START("Settings Register Loopback");
    // Read number of radios
    read_radio_reg(0, noc_block_radio_core.noc_shell.RB_GLOBAL_PARAMS, readback);
    num_channels = readback[3:0]; // Use number of output ports for number of radios
    $display("Found %2d Channels in Radio core",num_channels);
    `ASSERT_ERROR(num_channels == noc_block_radio_core.NUM_CHANNELS, "Incorrect Number of Channels in Radio core!");

    // Settings register test readback on each radio core
    for (int i = 0; i < num_channels; i++) begin
      // Set test register
      send_radio_cmd(i, SR_TEST, 32'hDEADBEEF, readback);
      // Readback test register
      read_radio_core_reg(i, RB_TEST, readback);
      $sformat(s, "Radio %2d: Failed loopback test word #1",i);
      `ASSERT_ERROR(readback[31:0] == 32'hDEADBEEF, s);
      // Second test word
      send_radio_cmd(i, SR_TEST, 32'hFEEDFACE, readback);
      read_radio_core_reg(i, RB_TEST, readback);
      $sformat(s, "Radio %2d: Failed loopback test word #2",i);
      `ASSERT_ERROR(readback[31:0] == 32'hFEEDFACE, s);
      $display("Radio %2d: Passed register loopback test", i);
    end
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 4 -- RX/TX loopback
    **           Set TX CODEC / idle register and loopback
    **           TX => RX externally. Readback RX value from
    **           settings bus register and check it equals TX.
    ********************************************************/
    `TEST_CASE_START("RX/TX Loopback");
    rxtx_loopback = 1;
    for (int i = 0; i < num_channels; i++) begin
      // Enable loopback mode
      send_radio_cmd(i, SR_LOOPBACK, 32'h1, readback);
      // Set codec idle register with test word -- TX output will be set to the test word
      send_radio_cmd(i, SR_CODEC_IDLE, 32'hCAFEF00D, readback);
      // Readback TX output and RX input. Both should be the test word due to loopback.
      read_radio_core_reg(i, RB_TXRX, readback);
      $sformat(s, "Radio %2d: Incorrect TX idle word #1", i);
      `ASSERT_ERROR(readback[63:32] == 32'hCAFEF00D, s);
      $sformat(s, "Radio %2d: Incorrect RX loopback word #1", i);
      `ASSERT_ERROR(readback[31:0] == 32'hCAFEF00D, s);
      // Second test word
      send_radio_cmd(i, SR_CODEC_IDLE, 32'h00C0FFEE, readback);
      read_radio_core_reg(i, RB_TXRX, readback);
      $sformat(s, "Radio %2d: Incorrect TX idle word #2", i);
      `ASSERT_ERROR(readback[63:32] == 32'h00C0FFEE, s);
      $sformat(s, "Radio %2d: Incorrect RX loopback word #2", i);
      `ASSERT_ERROR(readback[31:0] == 32'h00C0FFEE, s);
      // Disable loopback mode
      send_radio_cmd(i, SR_LOOPBACK, 32'h0, readback);
    end
    rxtx_loopback = 0;
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 5 -- TX Burst
    **           Send a single TX sample packet.
    **           Check for correct TX output & EOB Ack packet
    ********************************************************/
    `TEST_CASE_START("TX Burst");
    for (int i = 0; i < num_channels; i++) begin
      fork
      begin
        send_tx_packet(i,SPP,0 /* Has time */,1 /* EOB */,0);
        // Check for EOB ACK
        check_radio_resp(i,1 /* Has time */,0 /* EOB */,noc_block_radio_core.gen[0].radio_core.tx_control_gen3.CODE_EOB_ACK[63:32]);
      end
      begin
        check_tx_burst(i,SPP);
      end
      join
    end
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 6 -- TX Underflow
    **           Send TX packet without EOB, make sure
    **           we get an underflow error packet.
    ********************************************************/
    `TEST_CASE_START("TX Underflow");
    for (int i = 0; i < num_channels; i++) begin
      // Send burst without EOB, which should trigger an underflow.
      fork
      begin
        send_tx_packet(i,SPP,0,0,0);
        check_radio_resp(i,1,1,noc_block_radio_core.gen[0].radio_core.tx_control_gen3.CODE_UNDERRUN[63:32]);
      end
      begin
        // Even with an underflow, TX output should still be valid.
        check_tx_burst(i,SPP);
      end
      join
      // Send normal TX burst to make sure we can properly restart after an underflow
      fork
      begin
        send_tx_packet(i,SPP,0,1,0);
        check_radio_resp(i,1,0,noc_block_radio_core.gen[0].radio_core.tx_control_gen3.CODE_EOB_ACK[63:32]);
      end
      begin
        check_tx_burst(i,SPP);
      end
      join
    end
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 7 -- TX Sequence Number Error
    **           Send TX packets with incorrect Seqnums and
    **           test variations of packet error handling
    **           policies:
    **           - Continue on next packet
    **           - Continue on next burst
    **           - Always continue / ignore errors
    ********************************************************/
    `TEST_CASE_START("TX Sequence Number Error");
    for (int i = 0; i < num_channels; i++) begin
      // *** Policy: Continue on next packet
      $display("Radio %2d: Check 'Continue on next packet' policy",i);
      fork
      begin
        send_radio_cmd(i, noc_block_radio_core.noc_shell.gen_noc_input_port.loop[0].noc_input_port.noc_responder.packet_error_responder.SR_ERROR_POLICY,
                      {4'b0101}, // Set continue on next packet & send error packets
                      readback);
        // Forcibly reset expected RX sequence number which will cause a sequence number gap
        send_radio_cmd(i, SR_CLEAR_RX_FC, 0, readback);
        send_tx_packet(i,SPP,0,1,0);
        // Check for seqnum error packet
        check_radio_resp(i,0,1,noc_block_radio_core.noc_shell.gen_noc_input_port.loop[0].noc_input_port.noc_responder.packet_error_responder.CODE_SEQ_ERROR[63:32]);
      end
      begin
        check_tx_idle(i);
      end
      join
      // Check that the next packet works without error
      fork
      begin
        send_tx_packet(i,SPP,0,1,0);
        check_radio_resp(i,1,0,noc_block_radio_core.gen[0].radio_core.tx_control_gen3.CODE_EOB_ACK[63:32]);
      end
      begin
        check_tx_burst(i,SPP);
      end
      join
      // *** Policy: Continue on next burst
      $display("Radio %2d: Check 'Continue on next burst' policy",i);
      fork
      begin
        send_radio_cmd(i, noc_block_radio_core.noc_shell.gen_noc_input_port.loop[0].noc_input_port.noc_responder.packet_error_responder.SR_ERROR_POLICY,
                    {4'b1001}, // Set continue on next burst & send error packets
                    readback);
        send_radio_cmd(i, SR_CLEAR_RX_FC, 0, readback);
        send_tx_packet(i,SPP,0,0,0); // EOB specifically NOT set
        check_radio_resp(i,0,1,noc_block_radio_core.noc_shell.gen_noc_input_port.loop[0].noc_input_port.noc_responder.packet_error_responder.CODE_SEQ_ERROR[63:32]);
      end
      begin
        check_tx_idle(i);
      end
      join
      // This packet should not be passed through
      fork
      begin
        // EOB set, this will clear the error state (due to Continue on next burst policy),
        // BUT there will not be a reply!
        send_tx_packet(i,SPP,0,1,0);
      end
      begin
        check_tx_idle(i);
      end
      join
      // Previous packet had EOB set, so this packet is the start of the next burst and should be passed through
      fork
      begin
        send_tx_packet(i,SPP,0,1,0);
        check_radio_resp(i,1,0,noc_block_radio_core.gen[0].radio_core.tx_control_gen3.CODE_EOB_ACK[63:32]);
      end
      begin
        check_tx_burst(i,SPP);
      end
      join
      // *** Policy: Always continue
      $display("Radio %2d: Check 'Always continue' policy",i);
      fork
      begin
        send_radio_cmd(i, noc_block_radio_core.noc_shell.gen_noc_input_port.loop[0].noc_input_port.noc_responder.packet_error_responder.SR_ERROR_POLICY,
                       {4'b0011}, // Set always continue & send error packets
                       readback);
        send_radio_cmd(i, SR_CLEAR_RX_FC, 0, readback);
        send_tx_packet(i,SPP,0,1,0);
        // We expect to get two responses: Sequence number error and EOB ACK 
        check_radio_resp(i,0,1,noc_block_radio_core.noc_shell.gen_noc_input_port.loop[0].noc_input_port.noc_responder.packet_error_responder.CODE_SEQ_ERROR[63:32]);
        check_radio_resp(i,1,0,noc_block_radio_core.gen[0].radio_core.tx_control_gen3.CODE_EOB_ACK[63:32]);
      end
      begin
        // Even though there was a sequence number error, packet should still be passed through
        check_tx_burst(i,SPP);
      end
      join
      $display("Radio %2d: Return radio to default policy",i);
      // Reset policy back to default
      send_radio_cmd(i, noc_block_radio_core.noc_shell.gen_noc_input_port.loop[0].noc_input_port.noc_responder.packet_error_responder.SR_ERROR_POLICY,
                     {4'b0101},
                     readback);
      // Make sure we did not break anything
      fork
      begin
        send_tx_packet(i,SPP,0,1,0);
        check_radio_resp(i,1,0,noc_block_radio_core.gen[0].radio_core.tx_control_gen3.CODE_EOB_ACK[63:32]);
      end
      begin
        check_tx_burst(i,SPP);
      end
      join
    end
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 8 -- TX Late Packet
    **           Send a late packet, make sure we get
    **           an error packet back with no TX output.
    **           Send a normal packet and make sure we
    **           get correct TX output.
    ********************************************************/
    `TEST_CASE_START("TX Late Packet");
    for (int i = 0; i < num_channels; i++) begin
      // Get current VITA time
      read_radio_core_reg(i, RB_VITA_TIME, readback);
      // If VITA time is 0, it must be broken as even if a previous test reset it, reading the register will 
      // take enough time to have it be non-zero
      `ASSERT_ERROR(readback != 0, "VITA Time cannot be 0!");
      fork
      begin
        send_tx_packet(i,SPP,1,1,readback/2);  // VITA time/2, that is one late packet!
        check_radio_resp(i,1,1,noc_block_radio_core.gen[0].radio_core.tx_control_gen3.CODE_TIME_ERROR[63:32]);
      end
      begin
        // We don't send out packets that are late
        check_tx_idle(i);
      end
      join
      // Next normal packet should work
      fork
      begin
        send_tx_packet(i,SPP,0,1,0);
        check_radio_resp(i,1,0,noc_block_radio_core.gen[0].radio_core.tx_control_gen3.CODE_EOB_ACK[63:32]);
      end
      begin
        check_tx_burst(i,SPP);
      end
      join
    end
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 9 -- RX
    ********************************************************/
    `TEST_CASE_START("RX");
    for (int i = 0; i < num_channels; i++) begin
      start_rx(i,SPP,0 /* Chain commands */, 0 /* Reload commands */);
      check_rx(i);
    end
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 10 -- RX Overrun
    ********************************************************/
    `TEST_CASE_START("RX Overrun");
    for (int i = 0; i < num_channels; i++) begin
      start_rx(i,SPP,1,1);
      // Wait for an overflow
      #(100*RADIO_CLK_PERIOD*SPP);
      @(negedge ce_clk);
      // Check first RX packet to make sure it has not been corrupted
      check_rx(i);
      // Clear out remaining RX packets
      $display("Radio %2d: Flush remaining RX packets", i);
      flush_rx(i);
      // Check overflow packet
      check_radio_resp(i,1,1,noc_block_radio_core.gen[0].radio_core.rx_control_gen3.ERR_OVERRUN);
      // Normal RX should work without any issues
      start_rx(i,SPP,0,0);
      check_rx(i);
    end
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 11 -- RX Late Command
    ********************************************************/
    `TEST_CASE_START("RX Late Command");
    for (int i = 0; i < num_channels; i++) begin
      // Get current VITA time
      read_radio_core_reg(i, RB_VITA_TIME, readback);
      // Start RX at VITA time/2, i.e. send a late command
      start_rx_timed(i,SPP,0,0,readback/2);
      // Wait for late command error packet
      check_radio_resp(i,1,1,noc_block_radio_core.gen[0].radio_core.rx_control_gen3.ERR_LATECMD);
      // Normal RX should work without any issues
      start_rx(i,SPP,0,0);
      check_rx(i);
    end
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 12 -- RX Broken Chain
    ********************************************************/
    `TEST_CASE_START("RX Broken Chain");
    for (int i = 0; i < num_channels; i++) begin
      // Get current VITA time
      read_radio_core_reg(i, RB_VITA_TIME, readback);
      // Start RX with chain commands option, but don't send additional commands which will 'break' the chain
      start_rx(i,SPP,1,0);
      // Wait for broken chain error packet
      check_radio_resp(i,1,1,noc_block_radio_core.gen[0].radio_core.rx_control_gen3.ERR_BROKENCHAIN);
      // Output should still be correct
      check_rx(i);
      // Normal RX should work without any issues
      start_rx(i,SPP,0,0);
      check_rx(i);
    end
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 13 -- SPI
    ********************************************************/
    `TEST_CASE_START("SPI Command");
    for (int i = 0; i < num_channels; i++) begin
      automatic logic [7:0] spi_test_word = 8'hC8;
      fork
      begin
        // Set slk divider
        send_radio_cmd(i, SR_SPI, 10, readback);
        // Set SPI parameters
        send_radio_cmd(i, SR_SPI+1,
                       {1'b1, 1'b1, 6'd8, 24'd1}, // {dataout_edge[0], datain_edge[0], num_bits[5:0], slave_select[23:0]}
                       readback);
        // Set SPI output and trigger SPI transaction
        send_radio_cmd(i, SR_SPI+2, {spi_test_word,24'd0} /* Shift to upper bits */, readback);
      end
      begin
        automatic logic [7:0] spi_shift_in;
        spi_shift_in = 8'h5A;
        // Verify spi output
        @(negedge sen[8*i]);
        for (int k = 0; k < 8; k++) begin
          miso[i] = spi_shift_in[k];
          @(negedge sclk[i]);
          `ASSERT_ERROR(sen[8*i +: 8] == 8'b1111_1110, "Incorrect SPI slave select!");
          `ASSERT_ERROR(mosi[i] == spi_test_word[7-k], "Incorrect SPI MOSI bit!");
        end
      end
      join
      read_radio_core_reg(i, RB_SPI, readback);
      `ASSERT_ERROR(readback[7:0] == 8'h5A, "Incorrect SPI readback!");
    end
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 14 -- GPIO
    ********************************************************/
    `TEST_CASE_START("GPIO Commands");
    for (int i = 0; i < num_channels; i++) begin
      logic [31:0] test_word;
      // Check misc ins
      $display("Radio %2d: Check misc ins", i);
      test_word = $urandom();
      misc_ins[32*i +: 32] <= test_word;
      read_radio_core_reg(i, RB_MISC_IO, readback);
      `ASSERT_ERROR(readback[63:32] == test_word, "Incorrect misc ins!");
      // Check misc outs
      $display("Radio %2d: Check misc outs", i);
      test_word = $urandom();
      send_radio_cmd(i, SR_MISC_OUTS, test_word, readback);
      read_radio_core_reg(i, RB_MISC_IO, readback);
      `ASSERT_ERROR(readback[31:0] == test_word, "Incorrect misc outs readback!");
      `ASSERT_ERROR(misc_outs[32*i +: 32] == test_word, "Incorrect misc outs output!");
      // Check Front Panel GPIO ATR
      $display("Radio %2d: Check FP GPIO ATR input", i);
      // Enable tristate
      send_radio_cmd(i, SR_FP_GPIO+4, 32'h0000_0000, readback);
      test_word = $urandom();
      fp_gpio_in[32*i +: 32] = test_word;
      read_radio_core_reg(i, RB_FP_GPIO, readback);
      `ASSERT_ERROR(readback[31:0] == test_word, "Incorrect FP GPIO readback!");
      $display("Radio %2d: Check FP GPIO ATR output", i);
      // Disable tristate
      send_radio_cmd(i, SR_FP_GPIO+4, 32'hFFFF_FFFF, readback);
      test_word = $urandom();
      send_radio_cmd(i, SR_FP_GPIO, test_word, readback);
      `ASSERT_ERROR(fp_gpio_out[32*i +: 32] == test_word, "Incorrect FP GPIO output!");
      // Check Daughter board GPIO ATR
      $display("Radio %2d: Check DB GPIO ATR input", i);
      send_radio_cmd(i, SR_DB_GPIO+4, 32'd0, readback);
      test_word = $urandom();
      db_gpio_in[32*i +: 32] = test_word;
      read_radio_core_reg(i, RB_DB_GPIO, readback);
      `ASSERT_ERROR(readback[31:0] == test_word, "Incorrect DB GPIO readback!");
      $display("Radio %2d: Check DB GPIO ATR output", i);
      send_radio_cmd(i, SR_DB_GPIO+4, 32'hFFFF_FFFF, readback);
      test_word = $urandom();
      send_radio_cmd(i, SR_DB_GPIO, test_word, readback);
      `ASSERT_ERROR(db_gpio_out[32*i +: 32] == test_word, "Incorrect DB GPIO output!");
      // Check LEDs
      $display("Radio %2d: Check LEDs", i);
      test_word = $urandom();
      send_radio_cmd(i, SR_LEDS, test_word, readback);
      read_radio_core_reg(i, RB_LEDS, readback);
      `ASSERT_ERROR(readback[31:0] == test_word, "Incorrect LEDs readback!");
      `ASSERT_ERROR(leds[32*i +: 32] == test_word, "Incorrect LEDs output!");
    end
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 15 -- Timed Command
    ********************************************************/
    `TEST_CASE_START("FP GPIO Timed Command");
    for (int i = 0; i < num_channels; i++) begin
      automatic logic [31:0] rand32 = $random();
      automatic logic [63:0] vita_time_set;
      vita_time_set = 64'd1000000;
      pps = 1'b0;
      $display("Radio %2d: Clear FP GPIO", i);
      // Make sure GPIO is cleared
      send_radio_cmd(i, SR_FP_GPIO, 32'd0, readback);
      $sformat(s, "Radio %2d: FP GPIO output not cleared! Expected: %d, Actual: %d", i, 32'd0, fp_gpio_out[32*i +: 32]);
      `ASSERT_ERROR(fp_gpio_out[32*i +: 32] == 32'd0, s);
      // Clear VITA time
      send_radio_cmd(i, SR_TIME_HI, 32'd0, readback);
      send_radio_cmd(i, SR_TIME_LO, 32'd0, readback);
      send_radio_cmd(i, SR_TIME_CTRL, 3'd1 /* Set time now */, readback);
      // Get VITA time
      read_radio_core_reg(i, RB_VITA_TIME, readback);
      $sformat(s, "Radio %2d: VITA time not set. Expected: value <1000, Actual: %d", i, readback);
      `ASSERT_ERROR(readback < 1000, s);
      fork
      begin
        send_radio_cmd(i, SR_TIME_HI, vita_time_set[63:32], readback);
        send_radio_cmd(i, SR_TIME_LO, vita_time_set[31:0], readback);
        send_radio_cmd(i, SR_TIME_CTRL, 3'd2 /* Set time next pps */, readback);
        // Set GPIO to time that will be set on next PPS.
        $display("Radio %2d: Send timed command to set FP GPIO", i);
        send_radio_cmd_timed(i, SR_FP_GPIO /* Set idle register */, rand32, vita_time_set, readback);
      end
      begin
        // Give time for other thread to get setup
        repeat(500) @(posedge radio_clk);
        // Make sure FP GPIO did not prematurely change then assert PPS
        $display("Radio %2d: Check FP GPIO output before timed command epoch", i);
        $sformat(s, "Radio %2d: FP GPIO output changed before asserting PPS! Expected: %d, Actual: %d", i, 32'd0, fp_gpio_out[32*i +: 32]);
        `ASSERT_ERROR(fp_gpio_out[32*i +: 32] == 32'd0, s);
        #0; // VIVADO XSIM workaround. Need delay to make sure PPS asserts *after* rising edge
        pps = 1'b1;
        // Wait a few clocks for GPIO to output
        // Note: This is an exact count of 6 clock cycles so if future code changes this latency the sim will throw an error.
        repeat(6) @(posedge radio_clk);
        $sformat(s, "Radio %2d: FP GPIO output incorrect before timed command epoch! Expected: %d, Actual: %d", i, 32'd0, fp_gpio_out[32*i +: 32]);
        `ASSERT_ERROR(fp_gpio_out[32*i +: 32] == 32'd0, s);
        @(posedge radio_clk);
        pps = 1'b0;
        $display("Radio %2d: Check FP GPIO output after timed command epoch", i);
        $sformat(s, "Radio %2d: FP GPIO output incorrect after timed command epoch! Expected: %d, Actual: %d", i, rand32, fp_gpio_out[32*i +: 32]);
        `ASSERT_ERROR(fp_gpio_out[32*i +: 32] == rand32, s);
      end
      join
    end
    `TEST_CASE_DONE(1);
    `TEST_BENCH_DONE;
  end

endmodule
