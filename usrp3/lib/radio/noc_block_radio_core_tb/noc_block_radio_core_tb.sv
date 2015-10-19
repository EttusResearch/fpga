//
// Copyright 2015 Ettus Research LLC
//

`timescale 1ns/1ps
`define SIM_RUNTIME_US 1000
`define NS_PER_TICK 1
`define NUM_TEST_CASES 5

`include "sim_exec_report.vh"
`include "sim_rfnoc_lib.vh"

module noc_block_radio_core_tb();
  /********************************************************
  ** RFNoC Initialization
  ********************************************************/
  `TEST_BENCH_INIT("noc_block_fft_tb",`NUM_TEST_CASES,`NS_PER_TICK);
  `RFNOC_SIM_INIT(2,166.67,200);
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
  wire rx_stb;
  reg tx_stb;
  wire [32*NUM_RADIOS-1:0] rx, tx;
  reg pps;
  wire [63:0] vita_time;
  wire [NUM_RADIOS-1:0] run_rx, run_tx;
  wire set_stb_rclk;
  wire [7:0] set_addr_rclk, rb_addr_rclk;
  wire [31:0] set_data_rclk;
  wire [63:0] set_time_rclk, rb_data_rclk;
  noc_block_radio_core #(
    .NUM_RADIOS(NUM_RADIOS),
    .BYPASS_TX_DC_OFFSET_CORR(1),
    .BYPASS_RX_DC_OFFSET_CORR(1),
    .BYPASS_TX_IQ_COMP(1),
    .BYPASS_RX_IQ_COMP(1))
  noc_block_radio_core (
    .bus_clk(bus_clk), .bus_rst(bus_rst),
    .ce_clk(radio_clk), .ce_rst(radio_rst),
    .i_tdata(xbar_m_cvita[0].tdata), .i_tlast(xbar_m_cvita[0].tlast), .i_tvalid(xbar_m_cvita[0].tvalid), .i_tready(xbar_m_cvita[0].tready),
    .o_tdata(xbar_s_cvita[0].tdata), .o_tlast(xbar_s_cvita[0].tlast), .o_tvalid(xbar_s_cvita[0].tvalid), .o_tready(xbar_s_cvita[0].tready),
    .rx_stb(rx_stb), .rx(rx),
    .tx_stb(tx_stb), .tx(tx),
    .pps(pps), .vita_time(vita_time), .run_rx(run_rx), .run_tx(run_tx),
    .fe_set_stb(set_stb_rclk), .fe_set_addr(set_addr_rclk), .fe_set_data(set_data_rclk), .fe_set_time(set_time_rclk),
    .fe_rb_addr(rb_addr_rclk), .fe_rb_data(rb_data_rclk),
    .debug());

  // Mux to emulate frontend loopback test
  reg rxtx_loopback;
  reg [32*NUM_RADIOS-31:0] sine_wave;
  reg [NUM_RADIOS-1:0] sine_wave_stb;
  assign rx = rxtx_loopback ? tx : sine_wave;
  assign rx_stb = rxtx_loopback ? tx_stb : sine_wave_stb;

  localparam SR_BASE_BCLK = 0;
  localparam RB_BASE_BCLK = 0;
  localparam SR_BASE_RCLK = 0;
  localparam RB_BASE_RCLK = 0;
  wire [31:0] misc_outs, fp_gpio, db0_gpio, db1_gpio;
  wire [2:0] leds0, leds1;
  wire [7:0] sen;
  wire sclk, mosi;
  wire miso = 1'b1;
  wire set_stb_bclk;
  wire [7:0] set_addr_bclk, rb_addr_bclk;
  wire [31:0] set_data_bclk;
  wire [31:0] rb_data_bclk;
  e3x0_db_control #(
    .SR_BASE_BCLK(SR_BASE_BCLK),
    .RB_BASE_BCLK(RB_BASE_BCLK),
    .SR_BASE_RCLK(SR_BASE_RCLK),
    .RB_BASE_RCLK(RB_BASE_RCLK))
  e3x0_db_control (
    .radio_clk(radio_clk), .radio_rst(radio_rst),
    .set_stb_rclk(set_stb_rclk), .set_addr_rclk(set_addr_rclk), .set_data_rclk(set_data_rclk), .set_time_rclk(set_time_rclk),
    .rb_addr_rclk(rb_addr_rclk), .rb_data_rclk(rb_data_rclk),
    .vita_time(vita_time), .run_rx(run_rx), .run_tx(run_tx),
    .bus_clk(bus_clk), .bus_rst(bus_rst),
    .set_stb_bclk(set_stb_bclk), .set_addr_bclk(set_addr_bclk), .set_data_bclk(set_data_bclk),
    .rb_addr_bclk(rb_addr_bclk), .rb_data_bclk(rb_data_bclk),
    .misc_ins(32'd0), .misc_outs(misc_outs), .sync(),
    .fp_gpio(fp_gpio), .db0_gpio(db0_gpio), .db1_gpio(db1_gpio),
    .leds0(leds0), .leds1(leds1),
    .sen(sen), .sclk(sclk), .mosi(mosi), .miso(miso));

  /********************************************************
  ** Useful Tasks
  ********************************************************/
  task automatic tb_send_cmd;
    input [15:0] dst_sid;
    input [7:0] addr;
    input [31:0] data;
    output [63:0] response;
    begin
      automatic cvita_hdr_t hdr;
      automatic cvita_pkt_t pkt_resp;
      hdr = flatten_chdr_no_ts('{pkt_type:CMD, has_time:0, eob:0, seqno:12'h0, length:8,
                                 src_sid:sid_noc_block_tb, dst_sid:dst_sid, timestamp:64'h0});
      tb_cvita_cmd.push_pkt({hdr, {24'd0, addr, data}});
      tb_cvita_ack.pull_pkt(pkt_resp);
      // Remove header from packet
      drop_chdr(pkt_resp);
      response = pkt_resp[0];
    end
  endtask

  /********************************************************
  ** Test Bench Misc
  ********************************************************/
  logic [63:0] payload[$];
  logic [63:0] hdr;
  logic [11:0] data_seqnum;
  logic last;
  logic [15:0] real_val, cplx_val;
  cvita_hdr_t header;
  cvita_pkt_t response;
  logic [63:0] resp;

  localparam PKT_SIZE = 256;

  wire [31:0] sine_wave_1_8th[0:7] = {
    { 16'd32767,     16'd0},
    { 16'd23170, 16'd23170},
    {     16'd0, 16'd32767},
    {-16'd23170, 16'd23170},
    {-16'd32767,     16'd0},
    {-16'd23170,-16'd23170},
    {     16'd0,-16'd32767},
    { 16'd23170,-16'd23170}};

  /********************************************************
  ** Test Bench Main Thread
  ********************************************************/
  longint noc_id = 0;
  int num_radios = 0;

  initial begin : tb_main
    /* Initialization */
    rxtx_loopback = 0;
    data_seqnum = 0;

    /********************************************************
    ** Test 1 -- Reset
    ********************************************************/
    `TEST_CASE_START("Wait for Reset");
    while (bus_rst) @(posedge bus_clk);
    while (ce_rst) @(posedge ce_clk);
    `TEST_CASE_DONE(~bus_rst & ~ce_rst);

    /********************************************************
    ** Test 2 -- Setup RFNoC Connections & Radio Core NoC Shell
    ********************************************************/
    `TEST_CASE_START("Setup RFNoC");
    // Setup RFNoC connection: Test bench -> Radio Core 0 -> Test bench
    // Note: We want to be able to specify the packet header, so we use block port 1 
    //       of the test bench block which corresponds to the tb_cvita_* signals.
    `RFNOC_CONNECT_BLOCK_PORT(noc_block_tb,1,noc_block_radio_core,1,PKT_SIZE*4);
    `RFNOC_CONNECT_BLOCK_PORT(noc_block_radio_core,1,noc_block_tb,1,PKT_SIZE*4);
    // Setup RFNoC connection: Test bench 2 -> Radio Core 1 -> Test bench 2
    // Note: We are hooking up the second radio core to an additional test bench
    //       block (i.e. noc_block_export_io) that was added with 
    //       `RFNOC_ADD_TESTBENCH_BLOCK() above.
    `RFNOC_CONNECT_BLOCK_PORT(noc_block_tb2,1,noc_block_radio_core,2,PKT_SIZE*4);
    `RFNOC_CONNECT_BLOCK_PORT(noc_block_radio_core,2,noc_block_tb2,1,PKT_SIZE*4);
    // Read NOC ID
    tb_send_cmd({sid_noc_block_radio_core + noc_block_radio_core.FE_CTRL_BLOCK_PORT[3:0]},
                noc_block_radio_core.noc_shell.SR_RB_ADDR, noc_block_radio_core.noc_shell.RB_NOC_ID,
                noc_id);
    $display("Read NOC ID: %x",noc_id);
    `ASSERT_FATAL(noc_id == noc_block_radio_core.NOC_ID, "Incorrect NOC ID");
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 3 -- Radio core settings register loopback
    ********************************************************/
    `TEST_CASE_START("Settings Register Loopback");
    // Read number of radios
    tb_send_cmd({sid_noc_block_radio_core + noc_block_radio_core.FE_CTRL_BLOCK_PORT[3:0]},
                noc_block_radio_core.noc_shell.SR_RB_ADDR, noc_block_radio_core.noc_shell.RB_GLOBAL_SETTINGS,
                resp);
    num_radios = resp[4:0]-1; // -1 as one block port is the frontend control port
    $display("Found %d Radio cores",num_radios);
    `ASSERT_FATAL(num_radios == noc_block_radio_core.NUM_RADIOS, "Incorrect Number of Radio Cores");

    // Settings register test readback on each radio core
    for (int i = 0; i < num_radios; i = i + 1) begin
      // Set user readback register as the register we want to readback
      tb_send_cmd({sid_noc_block_radio_core + i+1}, // offset by 1 due to frontend control on block port 0
                  noc_block_radio_core.noc_shell.SR_RB_ADDR, noc_block_radio_core.noc_shell.RB_USER_RB_DATA,
                  resp);
      // Set test register
      tb_send_cmd({sid_noc_block_radio_core + i+1},
                  noc_block_radio_core.gen[0].radio_core.SR_TEST, 32'hDEADBEEF,
                  resp);
      $display("Radio %d: Wrote test word %x",i,32'hDEADBEEF);
      // Readback test register
      tb_send_cmd({sid_noc_block_radio_core + i+1},
                  noc_block_radio_core.gen[0].radio_core.SR_READBACK, noc_block_radio_core.gen[0].radio_core.RB_RX,
                  resp);
      $display("Radio %d: Read test word %x",i,resp[31:0]);
      `ASSERT_FATAL(resp[31:0] == 32'hDEADBEEF, "Failed loopback test word #1");
      // Second test word
      tb_send_cmd({sid_noc_block_radio_core + i+1},
                  noc_block_radio_core.gen[0].radio_core.SR_TEST, 32'hFEEDFACE,
                  resp);
      $display("Radio %d: Wrote test word %x",i,32'hFEEDFACE);
      tb_send_cmd({sid_noc_block_radio_core + i+1},
                  noc_block_radio_core.gen[0].radio_core.SR_READBACK, noc_block_radio_core.gen[0].radio_core.RB_RX,
                  resp);
      $display("Radio %d: Read test word %x",i,resp[31:0]);
      `ASSERT_FATAL(resp[31:0] == 32'hFEEDFACE, "Failed loopback test word #2");
    end
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 3 -- RX/TX loopback
    ********************************************************/
    rxtx_loopback = 1;
    `TEST_CASE_START("RX/TX Loopback");
    for (int i = 0; i < num_radios; i = i + 1) begin
      // Enable loopback mode
      tb_send_cmd({sid_noc_block_radio_core + i+1},
                  noc_block_radio_core.gen[0].radio_core.SR_LOOPBACK, 32'h1,
                  resp);
      // Set user readback register as the register we want to readback
      tb_send_cmd({sid_noc_block_radio_core + i+1}, // offset by 1 due to frontend control on block port 0
                  noc_block_radio_core.noc_shell.SR_RB_ADDR, noc_block_radio_core.noc_shell.RB_USER_RB_DATA,
                  resp);
      // Set codec idle register with test word -- TX output will be set to the test word
      tb_send_cmd({sid_noc_block_radio_core + i+1},
                  noc_block_radio_core.gen[0].radio_core.SR_CODEC_IDLE, 32'hCAFEF00D,
                  resp);
      $display("Radio %d: Wrote TX idle word %x",i,32'hCAFEF00D);
      // Readback TX output and RX input. Both should be the test word due to loopback.
      tb_send_cmd({sid_noc_block_radio_core + i+1},
                  noc_block_radio_core.gen[0].radio_core.SR_READBACK, noc_block_radio_core.gen[0].radio_core.RB_TXRX,
                  resp);
      $display("Radio %d: Read TX idle word %x",i,resp[63:32]);
      $display("Radio %d: Read RX loopback word %x",i,resp[31:0]);
      `ASSERT_FATAL(resp[63:32] == 32'hCAFEF00D, "Incorrect TX idle word #1");
      `ASSERT_FATAL(resp[31:0] == 32'hCAFEF00D, "Incorrect RX loopback word #1");
      // Second test word
      tb_send_cmd({sid_noc_block_radio_core + i+1},
                  noc_block_radio_core.gen[0].radio_core.SR_CODEC_IDLE, 32'h00C0FFEE,
                  resp);
      $display("Radio %d: Wrote TX idle word %x",i,32'h00C0FFEE);
      tb_send_cmd({sid_noc_block_radio_core + i+1},
                  noc_block_radio_core.gen[0].radio_core.SR_READBACK, noc_block_radio_core.gen[0].radio_core.RB_TXRX,
                  resp);
      $display("Radio %d: Read TX idle word %x",i,resp[63:32]);
      $display("Radio %d: Read RX loopback word %x",i,resp[31:0]);
      `ASSERT_FATAL(resp[63:32] == 32'h00C0FFEE, "Incorrect TX idle word #2");
      `ASSERT_FATAL(resp[31:0] == 32'h00C0FFEE, "Incorrect RX loopback word #2");
      // Disable loopback mode
      tb_send_cmd({sid_noc_block_radio_core + i+1},
                 noc_block_radio_core.gen[0].radio_core.SR_LOOPBACK, 32'h0,
                 resp);
    end
    `TEST_CASE_DONE(1);
    rxtx_loopback = 0;

    /********************************************************
    ** Test 5 -- TX Burst
    ********************************************************/
    `TEST_CASE_START("TX Burst");
    for (int i = 0; i < num_radios; i = i + 1) begin
      // Set CODEC IDLE which sets TX output value when not actively transmitting
      tb_send_cmd({sid_noc_block_radio_core + i+1},
                  noc_block_radio_core.gen[0].radio_core.SR_CODEC_IDLE, 32'h12345678,
                  resp);
      // Set TX output mux for no I/Q swapping
      tb_send_cmd({sid_noc_block_radio_core + i+1},
                  noc_block_radio_core.gen[0].radio_core.SR_TX_MUX, {24'd0, 4'd1 /* Q => Q */, 4'd0 /* I => I */},
                  resp);
      fork
        // Send TX burst
        begin
          payload = {};
          // Generate ramp pattern for TX samples
          for (int k = 0; k < 1024; k = k + 4) begin
            payload.push_back({k[15:0]+16'd0, k[15:0]+16'd1, k[15:0]+16'd2, k[15:0]+16'd3});
          end
          // Set EOB so no underflow occurs, also we should get an EOB ACK reply packet
          hdr = flatten_chdr_no_ts('{pkt_type:DATA, has_time:0, eob:1, seqno:data_seqnum, length:{8 + 8*payload.size()},
                                     src_sid:{sid_noc_block_tb+1}, dst_sid:{sid_noc_block_radio_core + i+1}, timestamp:64'h0});
          data_seqnum = data_seqnum + 1;
          if (i == 0) begin
            tb_cvita_data.push_pkt({hdr,payload});
            // Check response packet is EOB Acknowledge
            tb_cvita_ack.pull_pkt(response);
          end else begin
            tb2_cvita_data.push_pkt({hdr,payload});
            // Check response packet is EOB Acknowledge
            tb2_cvita_ack.pull_pkt(response);
          end
          payload = response;
          extract_chdr(payload, header);
          `ASSERT_FATAL(header.pkt_type == cvita_pkt_type_t'(RESP),"Incorrect response packet type!");
          `ASSERT_FATAL(header.eob == 0,"Incorrect response packet EOB value!");
          `ASSERT_FATAL(header.length == 8*response.size(), "Incorrect packet length!");
          `ASSERT_FATAL(header.src_sid == {sid_noc_block_radio_core + i+1}, "Incorrect source SID!");
          `ASSERT_FATAL(payload[63:32] == noc_block_radio_core.gen[0].radio_core.tx_control_gen3.CODE_EOB_ACK, "Incorrect response -- Expected EOB ACK!");
          `ASSERT_FATAL(payload[31:0] == 32'd0, "Incorrect response sequence number"); // First TX packet, so seqnum should be 0
        end
        // Check TX burst
        begin
          // Wait until output waveform changes
          // Note: Using indexed part select syntax due to simulator complaining 'Range must be bounded by constant expressions'
          while(tx[16*i +: 16] != 32'd12345678) @(posedge radio_clk);
          while(tx[16*i +: 16] == 32'd12345678) @(posedge radio_clk);
          // Check ramp pattern
          for (int k = 0; i < 1024; k = k + 2) begin
            `ASSERT_FATAL(tx[32*i +: 16] == {k[15:0], k[15:0]+1}, "Incorrect TX output!");
          end
        end
      join
    end
    `TEST_CASE_DONE(1);
    
    /********************************************************
    ** Test 3 -- TX Underflow
    ********************************************************/
    
    /********************************************************
    ** Test 3 -- TX Sequence Error
    ********************************************************/
    
    /********************************************************
    ** Test 3 -- TX Late Packet
    ********************************************************/
    
    /********************************************************
    ** Test 3 -- TX IQ Swapping
    ********************************************************/
    
    /********************************************************
    ** Test 3 -- TX DC Offset Correction
    ********************************************************/
    
    /********************************************************
    ** Test 3 -- TX IQ Balance Correction
    ********************************************************/
    
    /********************************************************
    ** Test 3 -- RX
    ********************************************************/
    
    /********************************************************
    ** Test 3 -- RX Overflow
    ********************************************************/
    
    /********************************************************
    ** Test 3 -- RX IQ Swapping
    ********************************************************/
    
    /********************************************************
    ** Test 3 -- RX DC Offset Correction
    ********************************************************/
    
    /********************************************************
    ** Test 3 -- RX IQ Balance Correction
    ********************************************************/
    
    /********************************************************
    ** Test 3 -- Reset VITA time via PPS
    ********************************************************/
    
    /********************************************************
    ** Test 3 -- Timed TX
    ********************************************************/
   
    /********************************************************
    ** Test 3 -- Reset VITA time via Sync
    ********************************************************/
    
    /********************************************************
    ** Test 3 -- Timed RX
    ********************************************************/
    
    /********************************************************
    ** Test 3 -- Timed Commands
    ********************************************************/
    
    
    
/*
    forever begin
      tb_axis_data.pull_word({real_val,cplx_val},last);
    end

    forever begin
      tb_next_dst = sid_noc_block_radio_core;
      for (int i = 0; i < PKT_SIZE; i = i + 1) begin
        tb_axis_data.push_word(sine_wave_1_8th[i],(i == (PKT_SIZE-1))); 
      end
    end
*/
  end

  integer k,l;
  initial begin
    k = 0;
    l = 3;
    sine_wave_stb = 1'b0;
    tx_stb = 1'b0;
    forever begin
      sine_wave[31:0]  = sine_wave_1_8th[k];
      sine_wave[63:32] = sine_wave_1_8th[l];
      if (k < $size(sine_wave_1_8th)-1) begin
        k = k + 1;
      end else begin
        k = 0;
      end
      if (l < $size(sine_wave_1_8th)-1) begin
        l = l + 1;
      end else begin
        l = 0;
      end
      sine_wave_stb = 1'b1;
      tx_stb = 1'b1;
      @(posedge radio_clk);
      sine_wave_stb = 1'b0;
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

endmodule