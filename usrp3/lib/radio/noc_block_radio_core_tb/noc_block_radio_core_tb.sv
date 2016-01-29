//
// Copyright 2015 Ettus Research LLC
//

`timescale 1ns/1ps

`define NS_PER_TICK 1
`define NUM_TEST_CASES 14

`include "sim_exec_report.vh"
`include "sim_rfnoc_lib.vh"

module noc_block_radio_core_tb;
  /********************************************************
  ** RFNoC Initialization
  ********************************************************/
  `TEST_BENCH_INIT("noc_block_rado_core_tb",`NUM_TEST_CASES,`NS_PER_TICK);
  `RFNOC_SIM_INIT(2, 50, 61.44);
  `DEFINE_CLK(radio_clk, 61.44, 50);
  `DEFINE_RESET(radio_rst, 0, 1000);
  `RFNOC_ADD_TESTBENCH_BLOCK(tb2,1); // Add additional test bench block to test second radio core

  /********************************************************
  ** DUT, due to non-standard I/O we cannot use `RFNOC_ADD_BLOCK()
  ********************************************************/
  localparam NUM_RADIOS = 2;
  localparam BYPASS_TX_DC_OFFSET_CORR = 1;
  localparam BYPASS_RX_DC_OFFSET_CORR = 1;
  localparam BYPASS_TX_IQ_COMP = 1;
  localparam BYPASS_RX_IQ_COMP = 1;
  localparam [15:0] sid_noc_block_radio_core = {xbar_addr,4'd0,4'd0};
  logic rx_stb, tx_stb, rx_stb_int;
  logic [32*NUM_RADIOS-1:0] rx, tx, rx_int;
  logic pps;
  logic [NUM_RADIOS-1:0] sync;
  logic [NUM_RADIOS*32-1:0] misc_ins = 'd0;
  logic [NUM_RADIOS*32-1:0] misc_outs, leds;
  logic [NUM_RADIOS-1:0] fp_gpio_tri = 'd0;
  logic [NUM_RADIOS-1:0] db_gpio_tri = 'd0;
  logic [NUM_RADIOS*32-1:0] fp_gpio_in, db_gpio_in;
  tri   [NUM_RADIOS*32-1:0] fp_gpio, db_gpio;
  logic [NUM_RADIOS*8-1:0] sen;
  logic [NUM_RADIOS-1:0] sclk, mosi, miso = 'd0;
  noc_block_radio_core #(
    .NUM_RADIOS(NUM_RADIOS))
  noc_block_radio_core (
    .bus_clk(bus_clk), .bus_rst(bus_rst),
    .ce_clk(radio_clk), .ce_rst(radio_rst),
    .i_tdata(xbar_m_cvita[0].tdata), .i_tlast(xbar_m_cvita[0].tlast), .i_tvalid(xbar_m_cvita[0].tvalid), .i_tready(xbar_m_cvita[0].tready),
    .o_tdata(xbar_s_cvita[0].tdata), .o_tlast(xbar_s_cvita[0].tlast), .o_tvalid(xbar_s_cvita[0].tvalid), .o_tready(xbar_s_cvita[0].tready),
    .rx_stb(rx_stb), .rx(rx),
    .tx_stb(tx_stb), .tx(tx),
    .pps(pps),
    .misc_ins(misc_ins), .misc_outs(misc_outs), .sync(sync),
    .fp_gpio(fp_gpio), .db_gpio(db_gpio), .leds(leds),
    .sen(sen), .sclk(sclk), .mosi(mosi), .miso(miso),
    .debug());

  // Tristate outputs
  genvar m;
  generate
    for (m = 0; m < NUM_RADIOS; m++) begin
      assign fp_gpio[32*m +: 32] = fp_gpio_tri[m] ? 'bz : fp_gpio_in[32*m +: 32];
      assign db_gpio[32*m +: 32] = db_gpio_tri[m] ? 'bz : db_gpio_in[32*m +: 32];
    end
  endgenerate

  // Mux to emulate frontend loopback test
  logic rxtx_loopback;
  assign rx = rxtx_loopback ? tx : rx_int;
  assign rx_stb = rxtx_loopback ? tx_stb : rx_stb_int;

  logic set_rx = 1'b0;
  logic [31:0] set_rx_val[0:NUM_RADIOS-1];
  initial begin
    rx_stb_int = 1'b1;
    tx_stb = 1'b1;
    rx_int = {NUM_RADIOS{32'h00000001}};
    forever begin
      rx_stb_int = 1'b1;
      tx_stb = 1'b1;
      for (int i = 0; i < NUM_RADIOS; i++) begin 
        // Fixed value or ramp
        rx_int[32*i +: 32] = set_rx ? set_rx_val[i] : {rx_int[32*i +: 32]+32'h00020002};
      end
      @(posedge radio_clk);
      rx_stb_int = 1'b0;
      tx_stb = 1'b0;
      @(posedge radio_clk);
    end
  end

  initial begin
    pps = 1'b0;
    forever begin
      #50000 pps = ~pps;
    end
  end

  /********************************************************
  ** Useful Tasks / Functions
  ** Note: Several signals are created via 
  **       `RFNOC_SIM_INIT(). See sim_rfnoc_lib.vh.
  ********************************************************/
  localparam PKT_SIZE = 1024;   // In bytes
  localparam [31:0] TX_VERIF_WORD = 32'h12345678;
  logic [11:0] data_seqnum[NUM_RADIOS-1:0] = '{NUM_RADIOS{12'd0}};

  task automatic tb_send_cmd;
    input [15:0] dst_sid;
    input [7:0] addr;
    input [31:0] data;
    output [63:0] response;
    begin
      automatic cvita_hdr_t hdr;
      automatic cvita_pkt_t pkt_resp;
      //$display("Send Command - Addr: 0x%2x (%3d) Data: 0x%08x (%d)",addr, addr, data, data);
      hdr = flatten_chdr_no_ts('{pkt_type:CMD, has_time:0, eob:0, seqno:12'd0, length:8,
                                 src_sid:sid_noc_block_tb, dst_sid:dst_sid, timestamp:64'h0});
      tb_cvita_cmd.push_pkt({hdr, {24'd0, addr, data}});
      tb_cvita_ack.pull_pkt(pkt_resp);
      // Remove header from packet
      drop_chdr(pkt_resp);
      response = pkt_resp[0];
      //$display("Received Response - 0x%016x (%d)",response, response);
    end
  endtask

  task automatic tb_send_radio_cmd;
    input [$clog2(NUM_RADIOS)-1:0] radio_num;
    input [7:0] addr;
    input [31:0] data;
    output [63:0] response;
    begin
      tb_send_cmd({sid_noc_block_radio_core + radio_num},addr,data,response);
    end
  endtask

  task automatic tb_read_user_reg;
    input [15:0] dst_sid;
    input [7:0] addr; // Only 128 user registers (128-255)
    output [63:0] response;
    begin
      automatic logic [63:0] dummy_response;
      // Set user readback mux
      tb_send_cmd(dst_sid, noc_block_radio_core.noc_shell.SR_RB_ADDR_USER, addr, dummy_response);
      tb_read_reg(dst_sid, noc_block_radio_core.noc_shell.RB_USER_RB_DATA, response);
    end
  endtask

  // Used for reading NoC Shell registers
  task automatic tb_read_reg;
    input [15:0] dst_sid;
    input [7:0] addr;
    output [63:0] response;
    begin
      // Set NoC Shell readback mux, response packet will have readback data
      tb_send_cmd(dst_sid, noc_block_radio_core.noc_shell.SR_RB_ADDR, addr, response);
    end
  endtask

  task automatic tb_read_radio_reg;
    input [$clog2(NUM_RADIOS)-1:0] radio_num;
    input [7:0] addr;
    output [63:0] response;
    begin
      tb_read_reg({sid_noc_block_radio_core + radio_num},addr,response);
    end
  endtask

  task automatic tb_read_radio_core_reg;
    input [$clog2(NUM_RADIOS)-1:0] radio_num;
    input [7:0] addr;
    output [63:0] response;
    begin
      tb_read_user_reg({sid_noc_block_radio_core + radio_num},addr,response);
    end
  endtask

  task automatic tb_send_tx_packet;
    input [$clog2(NUM_RADIOS)-1:0] radio_num;
    input [15:0] num_samples;
    input has_time;
    input eob;
    input [63:0] timestamp;
    begin
      automatic logic [63:0] payload[$];
      automatic cvita_hdr_t hdr;
      automatic cvita_pkt_t response;
      // Set CODEC IDLE which sets TX output value when not actively transmitting
      tb_send_radio_cmd(radio_num, noc_block_radio_core.gen[0].radio_core.SR_CODEC_IDLE, TX_VERIF_WORD, resp);
      // Send TX burst
      payload = {};
      // Generate ramp pattern for TX samples
      for (int k = 0; k < num_samples/2; k = k + 1) begin
        payload.push_back({16'(4*k), 16'(4*k+1), 16'(4*k+2), 16'(4*k+3)});
      end
      $display("Radio %2d: Send TX burst, %5d samples",radio_num,num_samples);
      if (radio_num == 0) begin
        hdr = '{pkt_type:DATA, has_time:has_time, eob:eob, seqno:data_seqnum[radio_num], length:{8 + 8*payload.size() + has_time*8},
                src_sid:{sid_noc_block_tb+1}, dst_sid:{sid_noc_block_radio_core + radio_num}, timestamp:timestamp};
        if (has_time) begin
          tb_cvita_data.push_pkt({hdr[127:64],hdr[63:0],payload});
        end else begin
          tb_cvita_data.push_pkt({flatten_chdr_no_ts(hdr),payload});
        end
      $display("Radio %2d: TX burst sent",radio_num);
      end else begin
        hdr = '{pkt_type:DATA, has_time:has_time, eob:eob, seqno:data_seqnum[radio_num], length:{8 + 8*payload.size() + has_time*8},
                src_sid:{sid_noc_block_tb2+1}, dst_sid:{sid_noc_block_radio_core + radio_num}, timestamp:timestamp};
        if (has_time) begin
          tb2_cvita_data.push_pkt({hdr[127:64],hdr[63:0],payload});
        end else begin
          tb2_cvita_data.push_pkt({flatten_chdr_no_ts(hdr),payload});
        end
      end
      // Increment sequence number
      ++data_seqnum[radio_num];
    end
  endtask

  task automatic tb_start_rx;
    input [$clog2(NUM_RADIOS)-1:0] radio_num;
    input [15:0] num_samples;
    input chain_commands;
    input reload;
    begin
      if (chain_commands & reload) begin
        $display("Radio %2d: Start RX, continuous receive",radio_num);
      end else begin
        $display("Radio %2d: Start RX, receive %5d samples",radio_num,num_samples);
      end
      // Set number of samples per packet
      tb_send_radio_cmd(radio_num, noc_block_radio_core.gen[0].radio_core.SR_RX_CTRL_MAXLEN,
                        PKT_SIZE/4, // 4 bytes per sample
                        resp);
      // Receive a single packet immediately
      tb_send_radio_cmd(radio_num, noc_block_radio_core.gen[0].radio_core.SR_RX_CTRL_COMMAND,
                        {1'b1 /* Start immediately */, chain_commands, reload, 1'b0 /* Stop */, 28'(num_samples)},
                        resp);
      // Have to set time lower bytes to trigger the command being stored, although time is not used.
      tb_send_radio_cmd(radio_num, noc_block_radio_core.gen[0].radio_core.SR_RX_CTRL_TIME_LO, 32'd0, resp);
    end
  endtask

  task automatic tb_start_rx_timed;
    input [$clog2(NUM_RADIOS)-1:0] radio_num;
    input [15:0] num_samples;
    input chain_commands;
    input reload;
    input [63:0] start_time;
    begin
      if (chain_commands & reload) begin
        $display("Radio %2d: Start RX, continuous receive",radio_num);
      end else begin
        $display("Radio %2d: Start RX, receive %5d samples and stop",radio_num,num_samples);
      end
      // Set number of samples per packet
      tb_send_radio_cmd(radio_num, noc_block_radio_core.gen[0].radio_core.SR_RX_CTRL_MAXLEN,
                        PKT_SIZE/4, // 4 bytes per sample
                        resp);
      // Receive a single packet immediately
      tb_send_radio_cmd(radio_num, noc_block_radio_core.gen[0].radio_core.SR_RX_CTRL_COMMAND,
                        {1'b0 /* Start immediately */, chain_commands, reload, 1'b0 /* Stop */, 28'(num_samples)},
                        resp);
      // Set start time
      tb_send_radio_cmd(radio_num, noc_block_radio_core.gen[0].radio_core.SR_RX_CTRL_TIME_HI, start_time[63:32], resp);
      tb_send_radio_cmd(radio_num, noc_block_radio_core.gen[0].radio_core.SR_RX_CTRL_TIME_LO, start_time[31:0], resp);
    end
  endtask

  task automatic tb_stop_rx;
    input [$clog2(NUM_RADIOS)-1:0] radio_num;
    begin
      $display("Radio %2d: Stop RX",radio_num);
      tb_send_radio_cmd(radio_num, noc_block_radio_core.gen[0].radio_core.SR_RX_CTRL_COMMAND,
                        {1'b0 /* Start immediately */,1'b0 /* Chain commands */,1'b0 /* Reload */, 1'b1 /* Stop */, 28'(0)},
                        resp);
    end
  endtask

  task automatic tb_check_tx_resp;
    input [$clog2(NUM_RADIOS)-1:0] radio_num;
    input has_time;
    input eob;
    input [31:0] expected_resp_code;
    begin
      automatic logic [63:0] payload[$];
      automatic cvita_hdr_t header;
      automatic cvita_pkt_t response;
      tb_cvita_ack.pull_pkt(response);
      $display("Radio %2d: Checking TX response packet", radio_num);
      payload = response;
      extract_chdr(payload, header);
      `ASSERT_FATAL(header.pkt_type == cvita_pkt_type_t'(RESP),
        $sformatf("Incorrect response packet type! Received: 2'b%2b Expected: 2'b%2b", header.pkt_type, cvita_pkt_type_t'(RESP)));
      `ASSERT_FATAL(header.eob == eob,
        $sformatf("Incorrect response packet EOB value! Received: %1b Expected: %1b", header.eob, eob));
      `ASSERT_FATAL(header.has_time == has_time,
        $sformatf("Incorrect response packet 'has time' value! Received: %1b Expected: %1b", header.has_time, has_time));
      `ASSERT_FATAL(header.length == 8*response.size(),
        $sformatf("Incorrect packet length! Received: %5d Expected: %5d", header.length, 8*response.size()));
      `ASSERT_FATAL(header.src_sid == {sid_noc_block_radio_core + radio_num},
        $sformatf("Incorrect source SID! Received: %4x Expected: %4x", header.src_sid, {sid_noc_block_radio_core + radio_num}));
      `ASSERT_FATAL(payload[0][63:32] == expected_resp_code,
        $sformatf("Incorrect response packet code! Received: %8x Expected: %8x", payload[0][63:32], expected_resp_code));
      `ASSERT_FATAL(payload[0][11:0] == data_seqnum[radio_num]-12'd1,
        $sformatf("Incorrect response sequence number! Received: %4d Expected: %4d", payload[0][11:0], data_seqnum[radio_num]-12'd1));
      $display("Radio %2d: TX response packet correct", radio_num);
    end
  endtask

  task automatic tb_check_rx_resp;
    input [$clog2(NUM_RADIOS)-1:0] radio_num;
    input has_time;
    input eob;
    input [31:0] expected_resp_code;
    begin
      automatic logic [63:0] payload[$];
      automatic cvita_hdr_t header;
      automatic cvita_pkt_t response;
      tb_cvita_ack.pull_pkt(response);
      $display("Radio %2d: Checking RX response packet", radio_num);
      payload = response;
      extract_chdr(payload, header);
      `ASSERT_FATAL(header.pkt_type == cvita_pkt_type_t'(RESP),
        $sformatf("Incorrect response packet type! Received: 2'b%2b Expected: 2'b%2b", header.pkt_type, cvita_pkt_type_t'(RESP)));
      `ASSERT_FATAL(header.eob == eob,
        $sformatf("Incorrect response packet EOB value! Received: %1b Expected: %1b", header.eob, eob));
      `ASSERT_FATAL(header.has_time == has_time,
        $sformatf("Incorrect response packet 'has time' value! Received: %1b Expected: %1b", header.has_time, has_time));
      `ASSERT_FATAL(header.length == 8*response.size(),
        $sformatf("Incorrect packet length! Received: %5d Expected: %5d", header.length, 8*response.size()));
      `ASSERT_FATAL(header.src_sid == {sid_noc_block_radio_core + radio_num},
        $sformatf("Incorrect source SID! Received: %4x Expected: %4x", header.src_sid, {sid_noc_block_radio_core + radio_num}));
      `ASSERT_FATAL(payload[0][63:32] == expected_resp_code,
        $sformatf("Incorrect response packet code! Received: %8x Expected: %8x", payload[0][63:32], expected_resp_code));
      $display("Radio %2d: RX response packet correct", radio_num);
    end
  endtask

  task automatic tb_check_tx_burst;
    input [$clog2(NUM_RADIOS)-1:0] radio_num;
    input [15:0] num_samples;
    begin
      $display("Radio %2d: Checking TX output",radio_num);
      // Wait until output waveform changes. This does not test for consistent TX output latency.
      // Note: Using indexed part select syntax due to simulator complaining 'Range must be bounded by constant expressions'
      if (tx[32*radio_num +: 32] != TX_VERIF_WORD) begin
        while(tx[32*radio_num +: 32] != TX_VERIF_WORD) @(negedge radio_clk);
      end
      while(tx[32*radio_num +: 32] == TX_VERIF_WORD) begin
        // Using negedge so we align to the middle of the strobed TX output. Avoids false errors when checking TX output
        // and it transitions after radio_clk posedge.
        @(negedge radio_clk);
        while (~tx_stb) @(negedge radio_clk);
      end
      // Check ramp pattern
      for (int i = 0; i < num_samples; i++) begin
        `ASSERT_FATAL(tx[32*radio_num +: 32] == {16'(2*i), 16'(2*i+1)},
          $sformatf("Incorrect TX output! Received: %8x Expected: %8x",tx[32*radio_num +: 32],{16'(2*i), 16'(2*i+1)}));
        @(negedge radio_clk);
        while (~tx_stb) @(negedge radio_clk);
      end
      `ASSERT_FATAL(tx[32*radio_num +: 32] == TX_VERIF_WORD,
        $sformatf("Incorrect TX idle output! Received: %8x Expected: %8x",tx[32*radio_num +: 32],TX_VERIF_WORD));
      @(posedge radio_clk);
      $display("Radio %2d: TX output correct",radio_num);
    end
  endtask

  task automatic tb_check_tx_idle;
    input [$clog2(NUM_RADIOS)-1:0] radio_num;
    begin
      // Check that output does not change
      $display("Radio %2d: Checking TX output",radio_num);
      while (~tx_stb) @(negedge radio_clk);
      for (int i = 0; i < 200; i++) begin
        `ASSERT_FATAL(tx[32*radio_num +: 32] == TX_VERIF_WORD,
        $sformatf("Incorrect TX idle output! Received: %8x Expected: %8x",tx[32*radio_num +: 32],TX_VERIF_WORD));
        @(negedge radio_clk);
        while (~tx_stb) @(negedge radio_clk);
      end
      @(posedge radio_clk);
      $display("Radio %2d: TX output correct",radio_num);
    end
  endtask

  task automatic tb_flush_rx;
    input [$clog2(NUM_RADIOS)-1:0] radio_num;
    begin
      cvita_hdr_t header;
      cvita_pkt_t response;
      integer pkt_cnt = 0;
      header.eob = 1'b0;
      while (radio_num == 0 ? tb_cvita_data.s_cvita.axis.tvalid : tb2_cvita_data.s_cvita.axis.tvalid) begin
        if (radio_num == 0) begin
          tb_cvita_data.pull_pkt(response);
        end else begin
          tb2_cvita_data.pull_pkt(response);
        end
        extract_chdr(response, header);
        pkt_cnt = pkt_cnt + 1;
      end
      $display("Radio %2d: Flushed %3d RX packets", radio_num, pkt_cnt);
    end
  endtask

  task automatic tb_check_rx;
    input [$clog2(NUM_RADIOS)-1:0] radio_num;
    begin
      cvita_hdr_t header;
      cvita_pkt_t response;
      int payload_length = 0;
      $display("Radio %2d: Receiving RX packet", radio_num);
      if (radio_num == 0) begin
        tb_cvita_data.pull_pkt(response);
      end else begin
        tb2_cvita_data.pull_pkt(response);
      end
      extract_chdr(response, header);
      $display("Radio %2d: Checking received RX packet", radio_num);
      for (int k = 1; k < response.size(); k = k + 1) begin
        `ASSERT_FATAL(response[k] == {response[k-1][63:48]+16'd4, response[k-1][47:32]+16'd4, response[k-1][31:16]+16'd4, response[k-1][15:0]+16'd4},
          $sformatf("Incorrect RX input! Received: %8x Expected: %8x", response[k],
          {response[k-1][63:48]+16'd4, response[k-1][47:32]+16'd4, response[k-1][31:16]+16'd4, response[k-1][15:0]+16'd4}));
      end
      $display("Radio %2d: Received RX packet correct", radio_num);
    end
  endtask

  /********************************************************
  ** Test Bench Misc
  ********************************************************/
  logic [63:0] resp;

  /********************************************************
  ** Test Bench Main Thread
  ********************************************************/
  longint noc_id = 0;
  int num_radios = 0;

  initial begin : tb_main
    /* Initialization */
    rxtx_loopback = 0;
    set_rx = 0;
    for (int i = 0; i < NUM_RADIOS; i++) begin
      data_seqnum[i] = 0;
    end

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
    // Setup RFNoC connection: Test bench -> Radio Core 0 -> Test bench
    // Note: We want to be able to specify the packet header, so we use block port 1
    //       of the test bench block which corresponds to the tb_cvita_* signals.
    `RFNOC_CONNECT_BLOCK_PORT(noc_block_tb,1,noc_block_radio_core,0,PKT_SIZE);
    `RFNOC_CONNECT_BLOCK_PORT(noc_block_radio_core,0,noc_block_tb,1,PKT_SIZE);
    // Setup RFNoC connection: Test bench 2 -> Radio Core 1 -> Test bench 2
    // Note: We are hooking up the second radio core to an additional test bench
    //       block (i.e. noc_block_export_io) that was added with 
    //       `RFNOC_ADD_TESTBENCH_BLOCK() above.
    `RFNOC_CONNECT_BLOCK_PORT(noc_block_tb2,1,noc_block_radio_core,1,PKT_SIZE);
    `RFNOC_CONNECT_BLOCK_PORT(noc_block_radio_core,1,noc_block_tb2,1,PKT_SIZE);

    // Read NOC ID
    tb_read_radio_reg(0, noc_block_radio_core.noc_shell.RB_NOC_ID, noc_id);
    $display("Read NOC ID: %16x",noc_id);
    `ASSERT_FATAL(noc_id == noc_block_radio_core.NOC_ID, "Incorrect NOC ID");
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 3 -- Radio core settings register loopback
    **           Set & check radio core test register
    ********************************************************/
    `TEST_CASE_START("Settings Register Loopback");
    // Read number of radios
    tb_read_radio_reg(0, noc_block_radio_core.noc_shell.RB_GLOBAL_PARAMS, resp);
    num_radios = resp[3:0]; // Use number of output ports for number of radios
    $display("Found %2d Radio cores",num_radios);
    `ASSERT_FATAL(num_radios == noc_block_radio_core.NUM_RADIOS, "Incorrect Number of Radio Cores");

    // Settings register test readback on each radio core
    for (int i = 0; i < num_radios; i++) begin
      // Set test register
      tb_send_radio_cmd(i, noc_block_radio_core.gen[0].radio_core.SR_TEST, 32'hDEADBEEF, resp);
      // Readback test register
      tb_read_radio_core_reg(i, noc_block_radio_core.gen[0].radio_core.RB_TEST, resp);
      `ASSERT_FATAL(resp[31:0] == 32'hDEADBEEF, "Failed loopback test word #1");
      // Second test word
      tb_send_radio_cmd(i, noc_block_radio_core.gen[0].radio_core.SR_TEST, 32'hFEEDFACE, resp);
      tb_read_radio_core_reg(i, noc_block_radio_core.gen[0].radio_core.RB_TEST, resp);
      `ASSERT_FATAL(resp[31:0] == 32'hFEEDFACE, "Failed loopback test word #2");
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
    for (int i = 0; i < num_radios; i++) begin
      // Enable loopback mode
      tb_send_radio_cmd(i, noc_block_radio_core.gen[0].radio_core.SR_LOOPBACK, 32'h1, resp);
      // Set codec idle register with test word -- TX output will be set to the test word
      tb_send_radio_cmd(i, noc_block_radio_core.gen[0].radio_core.SR_CODEC_IDLE, 32'hCAFEF00D, resp);
      // Readback TX output and RX input. Both should be the test word due to loopback.
      tb_read_radio_core_reg(i, noc_block_radio_core.gen[0].radio_core.RB_TXRX, resp);
      `ASSERT_FATAL(resp[63:32] == 32'hCAFEF00D, "Incorrect TX idle word #1");
      `ASSERT_FATAL(resp[31:0] == 32'hCAFEF00D, "Incorrect RX loopback word #1");
      // Second test word
      tb_send_radio_cmd(i, noc_block_radio_core.gen[0].radio_core.SR_CODEC_IDLE, 32'h00C0FFEE, resp);
      tb_read_radio_core_reg(i, noc_block_radio_core.gen[0].radio_core.RB_TXRX, resp);
      `ASSERT_FATAL(resp[63:32] == 32'h00C0FFEE, "Incorrect TX idle word #2");
      `ASSERT_FATAL(resp[31:0] == 32'h00C0FFEE, "Incorrect RX loopback word #2");
      // Disable loopback mode
      tb_send_cmd(i, noc_block_radio_core.gen[0].radio_core.SR_LOOPBACK, 32'h0, resp);
    end
    rxtx_loopback = 0;
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 5 -- TX Burst
    **           Send a single TX sample packet.
    **           Check for correct TX output & EOB Ack packet
    ********************************************************/
    `TEST_CASE_START("TX Burst");
    for (int i = 0; i < num_radios; i++) begin
      fork
      begin
        tb_send_tx_packet(i,PKT_SIZE/4 /* 4 bytes per samples */,0 /* Has time */,1 /* EOB */,0);
        // Check for EOB ACK
        tb_check_tx_resp(i,1 /* Has time */,0 /* EOB */,noc_block_radio_core.gen[0].radio_core.tx_control_gen3.CODE_EOB_ACK[63:32]);
      end
      begin
        tb_check_tx_burst(i,PKT_SIZE/4);
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
    for (int i = 0; i < num_radios; i++) begin
      // Send burst without EOB, which should trigger an underflow.
      fork
      begin
        tb_send_tx_packet(i,PKT_SIZE/4,0,0,0);
        tb_check_tx_resp(i,1,1,noc_block_radio_core.gen[0].radio_core.tx_control_gen3.CODE_UNDERRUN[63:32]);
      end
      begin
        // Even with an underflow, TX output should still be valid.
        tb_check_tx_burst(i,PKT_SIZE/4);
      end
      join
      // Send normal TX burst to make sure we can properly restart after an underflow
      fork
      begin
        tb_send_tx_packet(i,PKT_SIZE/4,0,1,0);
        tb_check_tx_resp(i,1,0,noc_block_radio_core.gen[0].radio_core.tx_control_gen3.CODE_EOB_ACK[63:32]);
      end
      begin
        tb_check_tx_burst(i,PKT_SIZE/4);
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
    for (int i = 0; i < num_radios; i++) begin
      // *** Policy: Continue on next packet
      $display("Radio %2d: Check 'Continue on next packet' policy",i);
      fork
      begin
        tb_send_radio_cmd(i, noc_block_radio_core.noc_shell.gen_noc_input_port.loop[0].noc_input_port.noc_responder.packet_error_responder.SR_ERROR_POLICY,
                    {4'b0101}, // Set continue on next packet & send error packets
                    resp);
        // Erroneously increment sequence number 
        data_seqnum[i] = data_seqnum[i] + 1;
        tb_send_tx_packet(i,PKT_SIZE/4,0,1,0);
        // Check for seqnum error packet
        tb_check_tx_resp(i,0,1,noc_block_radio_core.noc_shell.gen_noc_input_port.loop[0].noc_input_port.noc_responder.packet_error_responder.CODE_SEQ_ERROR[63:32]);
      end
      begin
        tb_check_tx_idle(i);
      end
      join
      // Check that the next packet works without error
      fork
      begin
        tb_send_tx_packet(i,PKT_SIZE/4,0,1,0);
        tb_check_tx_resp(i,1,0,noc_block_radio_core.gen[0].radio_core.tx_control_gen3.CODE_EOB_ACK[63:32]);
      end
      begin
        tb_check_tx_burst(i,PKT_SIZE/4);
      end
      join
      // *** Policy: Continue on next burst
      $display("Radio %2d: Check 'Continue on next burst' policy",i);
      fork
      begin
        tb_send_radio_cmd(i, noc_block_radio_core.noc_shell.gen_noc_input_port.loop[0].noc_input_port.noc_responder.packet_error_responder.SR_ERROR_POLICY,
                    {4'b1001}, // Set continue on next burst & send error packets
                    resp);
        data_seqnum[i] = data_seqnum[i] + 1;
        tb_send_tx_packet(i,PKT_SIZE/4,0,0,0); // EOB specifically NOT set
        tb_check_tx_resp(i,0,1,noc_block_radio_core.noc_shell.gen_noc_input_port.loop[0].noc_input_port.noc_responder.packet_error_responder.CODE_SEQ_ERROR[63:32]);
      end
      begin
        tb_check_tx_idle(i);
      end
      join
      // This packet should not be passed through
      fork
      begin
        // EOB set, this will clear the error state (due to Continue on next burst policy),
        // BUT there will not be a reply!
        tb_send_tx_packet(i,PKT_SIZE/4,0,1,0);
      end
      begin
        tb_check_tx_idle(i);
      end
      join
      // Previous packet had EOB set, so this packet is the start of the next burst and should be passed through
      fork
      begin
        tb_send_tx_packet(i,PKT_SIZE/4,0,1,0);
        tb_check_tx_resp(i,1,0,noc_block_radio_core.gen[0].radio_core.tx_control_gen3.CODE_EOB_ACK[63:32]);
      end
      begin
        tb_check_tx_burst(i,PKT_SIZE/4);
      end
      join
      // *** Policy: Always continue
      $display("Radio %2d: Check 'Always continue' policy",i);
      fork
      begin
        tb_send_radio_cmd(i, noc_block_radio_core.noc_shell.gen_noc_input_port.loop[0].noc_input_port.noc_responder.packet_error_responder.SR_ERROR_POLICY,
                    {4'b0011}, // Set always continue & send error packets
                    resp);
        data_seqnum[i] = data_seqnum[i] + 1;
        tb_send_tx_packet(i,PKT_SIZE/4,0,1,0);
        // We expect to get two responses: Sequence number error and EOB ACK 
        tb_check_tx_resp(i,0,1,noc_block_radio_core.noc_shell.gen_noc_input_port.loop[0].noc_input_port.noc_responder.packet_error_responder.CODE_SEQ_ERROR[63:32]);
        tb_check_tx_resp(i,1,0,noc_block_radio_core.gen[0].radio_core.tx_control_gen3.CODE_EOB_ACK[63:32]);
      end
      begin
        // Even though there was a sequence number error, packet should still be passed through
        tb_check_tx_burst(i,PKT_SIZE/4);
      end
      join
      $display("Radio %2d: Return radio to default policy",i);
      // Reset policy back to default
      tb_send_radio_cmd(i, noc_block_radio_core.noc_shell.gen_noc_input_port.loop[0].noc_input_port.noc_responder.packet_error_responder.SR_ERROR_POLICY,
                  {4'b0101},
                  resp);
      // Make sure we did not break anything
      fork
      begin
        tb_send_tx_packet(i,PKT_SIZE/4,0,1,0);
        tb_check_tx_resp(i,1,0,noc_block_radio_core.gen[0].radio_core.tx_control_gen3.CODE_EOB_ACK[63:32]);
      end
      begin
        tb_check_tx_burst(i,PKT_SIZE/4);
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
    for (int i = 0; i < num_radios; i++) begin
      // Get current VITA time
      tb_read_radio_core_reg(i, noc_block_radio_core.gen[0].radio_core.RB_VITA_TIME, resp);
      // If VITA time is 0, it must be broken as even if a previous test reset it, reading the register will 
      // take enough time to have it be non-zero
      `ASSERT_FATAL(resp != 0, "VITA Time cannot be 0!");
      fork
      begin
        tb_send_tx_packet(i,PKT_SIZE/4,1,1,resp/2);  // VITA time/2, that is one late packet!
        tb_check_tx_resp(i,1,1,noc_block_radio_core.gen[0].radio_core.tx_control_gen3.CODE_TIME_ERROR[63:32]);
      end
      begin
        // We don't send out packets that are late
        tb_check_tx_idle(i);
      end
      join
      // Next normal packet should work
      fork
      begin
        tb_send_tx_packet(i,PKT_SIZE/4,0,1,0);
        tb_check_tx_resp(i,1,0,noc_block_radio_core.gen[0].radio_core.tx_control_gen3.CODE_EOB_ACK[63:32]);
      end
      begin
        tb_check_tx_burst(i,PKT_SIZE/4);
      end
      join
    end
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 9 -- RX
    ********************************************************/
    `TEST_CASE_START("RX");
    for (int i = 0; i < num_radios; i++) begin
      tb_start_rx(i,PKT_SIZE/4,0 /* Chain commands */, 0 /* Reload commands */);
      tb_check_rx(i);
    end
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 10 -- RX Overrun
    ********************************************************/
    `TEST_CASE_START("RX Overrun");
    for (int i = 0; i < num_radios; i++) begin
      tb_start_rx(i,PKT_SIZE/4,1,1);
      // Wait for an overflow
      #1000000;
      @(negedge ce_clk);
      // Check first RX packet to make sure it has not been corrupted
      tb_check_rx(i);
      // Clear out remaining RX packets
      $display("Radio %2d: Flush remaining RX packets", i);
      tb_flush_rx(i);
      // Check overflow packet
      tb_check_rx_resp(i,1,1,noc_block_radio_core.gen[0].radio_core.rx_control_gen3.ERR_OVERRUN);
      // Normal RX should work without any issues
      tb_start_rx(i,PKT_SIZE/4,0,0);
      tb_check_rx(i);
    end
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 11 -- RX Late Command
    ********************************************************/
    `TEST_CASE_START("RX Late Command");
    for (int i = 0; i < num_radios; i++) begin
      // Get current VITA time
      tb_read_radio_core_reg(i, noc_block_radio_core.gen[0].radio_core.RB_VITA_TIME, resp);
      // Start RX at VITA time/2, i.e. send a late command
      tb_start_rx_timed(i,PKT_SIZE/4,0,0,resp/2);
      // Wait for late command error packet
      tb_check_rx_resp(i,1,1,noc_block_radio_core.gen[0].radio_core.rx_control_gen3.ERR_LATECMD);
      // Normal RX should work without any issues
      tb_start_rx(i,PKT_SIZE/4,0,0);
      tb_check_rx(i);
    end
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 12 -- RX Broken Chain
    ********************************************************/
    `TEST_CASE_START("RX Broken Chain");
    for (int i = 0; i < num_radios; i++) begin
      // Get current VITA time
      tb_read_radio_core_reg(i, noc_block_radio_core.gen[0].radio_core.RB_VITA_TIME, resp);
      // Start RX with chain commands option, but don't send additional commands which will 'break' the chain
      tb_start_rx(i,PKT_SIZE/4,1,0);
      // Wait for broken chain error packet
      tb_check_rx_resp(i,1,1,noc_block_radio_core.gen[0].radio_core.rx_control_gen3.ERR_BROKENCHAIN);
      // Output should still be correct
      tb_check_rx(i);
      // Normal RX should work without any issues
      tb_start_rx(i,PKT_SIZE/4,0,0);
      tb_check_rx(i);
    end
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 13 -- SPI
    ********************************************************/
    `TEST_CASE_START("SPI Command");
    for (int i = 0; i < num_radios; i++) begin
      automatic logic [7:0] spi_shift_in = 8'h5A;
      automatic logic [7:0] spi_test_word = 8'hA5;
      fork
      begin
        // Set slk divider
        tb_send_radio_cmd(i, noc_block_radio_core.gen[0].radio_core.db_control.SR_SPI, 10, resp);
        // Set SPI parameters {dataout_edge[0], datain_edge[0], num_bits[5:0], slave_select[23:0]}
        tb_send_radio_cmd(i, noc_block_radio_core.gen[0].radio_core.db_control.SR_SPI+1,
                          {1'b1, 1'b1, 6'd8, 24'd1},
                          resp);
        // Set SPI output and trigger SPI transaction
        tb_send_radio_cmd(i, noc_block_radio_core.gen[0].radio_core.db_control.SR_SPI+2, {<<{spi_test_word}} /* Reverse bits */, resp);
      end
      begin
        // Verify spi output
        @(negedge sen[8*i]);
        for (int k = 0; k < 8; k++) begin
          miso[i] = spi_shift_in[k];
          @(negedge sclk[i]);
          `ASSERT_FATAL(sen[8*i +: 8] == 8'b1111_1110, "Incorrect SPI slave select!");
          `ASSERT_FATAL(mosi[i] == spi_test_word[7-k], "Incorrect SPI MOSI bit!");
        end
      end
      join
      tb_read_radio_core_reg(i, noc_block_radio_core.gen[0].radio_core.db_control.RB_SPI, resp);
      `ASSERT_FATAL(resp[7:0] == spi_shift_in, "Incorrect SPI readback!");
    end
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 14 -- GPIO
    ********************************************************/
    `TEST_CASE_START("GPIO Commands");
    for (int i = 0; i < num_radios; i++) begin
      automatic logic [31:0] test_word;
      // Check misc ins
      $display("Radio %2d: Check misc ins", i);
      test_word = $urandom();
      misc_ins[32*i +: 32] <= test_word;
      tb_read_radio_core_reg(i, noc_block_radio_core.gen[0].radio_core.db_control.RB_MISC_IO, resp);
      `ASSERT_FATAL(resp[63:32] == test_word, "Incorrect misc ins!");
      // Check misc outs
      $display("Radio %2d: Check misc outs", i);
      test_word = $urandom();
      tb_send_radio_cmd(i, noc_block_radio_core.gen[0].radio_core.db_control.SR_MISC_OUTS, test_word, resp);
      tb_read_radio_core_reg(i, noc_block_radio_core.gen[0].radio_core.db_control.RB_MISC_IO, resp);
      `ASSERT_FATAL(resp[31:0] == test_word, "Incorrect misc outs readback!");
      `ASSERT_FATAL(misc_outs[32*i +: 32] == test_word, "Incorrect misc outs output!");
      // Check sync
      $display("Radio %2d: Check SYNC", i);
      fork
      begin
        tb_send_radio_cmd(i, noc_block_radio_core.gen[0].radio_core.db_control.SR_SYNC, 32'b0, resp);
      end
      begin
        @(posedge sync[i]);
      end
      join
      // Check Front Panel GPIO ATR
      $display("Radio %2d: Check FP GPIO ATR input", i);
      // Enable tristate
      tb_send_radio_cmd(i, noc_block_radio_core.gen[0].radio_core.db_control.SR_FP_GPIO+4, 32'h0000_0000, resp);
      fp_gpio_tri[i] = 1'b0;
      test_word = $urandom();
      fp_gpio_in[32*i +: 32] = test_word;
      tb_read_radio_core_reg(i, noc_block_radio_core.gen[0].radio_core.db_control.RB_FP_GPIO, resp);
      `ASSERT_FATAL(resp[31:0] == test_word, "Incorrect FP GPIO readback!");
      $display("Radio %2d: Check FP GPIO ATR output", i);
      // Disable tristate
      tb_send_radio_cmd(i, noc_block_radio_core.gen[0].radio_core.db_control.SR_FP_GPIO+4, 32'hFFFF_FFFF, resp);
      fp_gpio_tri[i] = 1'b1;
      test_word = $urandom();
      tb_send_radio_cmd(i, noc_block_radio_core.gen[0].radio_core.db_control.SR_FP_GPIO, test_word, resp);
      `ASSERT_FATAL(fp_gpio[32*i +: 32] == test_word, "Incorrect FP GPIO output!");
      // Check Daughter board GPIO ATR
      $display("Radio %2d: Check DB GPIO ATR input", i);
      tb_send_radio_cmd(i, noc_block_radio_core.gen[0].radio_core.db_control.SR_DB_GPIO+4, 32'd0, resp);
      db_gpio_tri[i] = 1'b0;
      test_word = $urandom();
      db_gpio_in[32*i +: 32] = test_word;
      tb_read_radio_core_reg(i, noc_block_radio_core.gen[0].radio_core.db_control.RB_DB_GPIO, resp);
      `ASSERT_FATAL(resp[31:0] == test_word, "Incorrect DB GPIO readback!");
      $display("Radio %2d: Check DB GPIO ATR output", i);
      tb_send_radio_cmd(i, noc_block_radio_core.gen[0].radio_core.db_control.SR_DB_GPIO+4, 32'hFFFF_FFFF, resp);
      db_gpio_tri[i] = 1'b1;
      test_word = $urandom();
      tb_send_radio_cmd(i, noc_block_radio_core.gen[0].radio_core.db_control.SR_DB_GPIO, test_word, resp);
      `ASSERT_FATAL(db_gpio[32*i +: 32] == test_word, "Incorrect DB GPIO output!");
      // Check LEDs
      $display("Radio %2d: Check LEDs", i);
      test_word = $urandom();
      tb_send_radio_cmd(i, noc_block_radio_core.gen[0].radio_core.db_control.SR_LEDS, test_word, resp);
      tb_read_radio_core_reg(i, noc_block_radio_core.gen[0].radio_core.db_control.RB_LEDS, resp);
      `ASSERT_FATAL(resp[31:0] == test_word, "Incorrect LEDs readback!");
      `ASSERT_FATAL(leds[32*i +: 32] == test_word, "Incorrect LEDs output!");
    end
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 15 -- Reset VITA time via PPS
    ********************************************************/
    
    /********************************************************
    ** Test 16 -- Timed TX
    ********************************************************/
   
    /********************************************************
    ** Test 17 -- Reset VITA time via Sync
    *******************************************************/
    
    /********************************************************
    ** Test 18 -- Timed RX
    ********************************************************/
    
    /********************************************************
    ** Test 18 -- Timed Commands (SPI, GPIO)
    ********************************************************/
    $display("DONE!");
    while(1) @(posedge radio_clk);
  end

endmodule