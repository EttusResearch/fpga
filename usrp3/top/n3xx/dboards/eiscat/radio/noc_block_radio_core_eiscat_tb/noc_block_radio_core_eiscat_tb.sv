//
// Copyright 2018 Ettus Research, a National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//

//
// Test bench for EISCAT radio core. similar to standard radio core, but there's more going on under the hood, 
//ie beamformer, multi-source beam combining, etc.
// If you want to run just a subset of the tb, comment out the tests you want to skip. Tests 1-5 are pretty necessary though. 
//

`timescale 1ns/1ps
`define NS_PER_TICK 1
`define NUM_TEST_CASES 14
//`define USE_NPIO_AURORA;

`include "sim_exec_report.vh"
`include "sim_clks_rsts.vh"
`include "sim_rfnoc_lib.svh"

module noc_block_radio_core_eiscat_tb();
  `TEST_BENCH_INIT("noc_block_radio_core_eiscat",`NUM_TEST_CASES,`NS_PER_TICK);
   
  // Define all clocks and resets for aurora
  `DEFINE_RESET(GSR, 0, 100)             //100ns for GSR to deassert

  localparam BUS_CLK_PERIOD = $ceil(1e9/166e6);
  localparam CE_CLK_PERIOD  = $ceil(1e9/208e6);
  localparam RADIO_CLK_PERIOD = $ceil(1e9/208e6);
  
  `DEFINE_CLK(XG_CLK_P, 1000/156.25, 50)  //156.25MHz GT transceiver clock
   wire XG_CLK_N = ~XG_CLK_P;


  localparam NUM_CE         = 2;  // Number of Computation Engines / User RFNoC blocks to simulate
  localparam NUM_STREAMS    = 5;  // Number of test bench streams
  localparam NUM_CHANNELS   = 16;
  localparam NUM_BEAMS      = 10;
  localparam ENABLE_BEAMFORM = 1;
  `ifdef USE_NPIO_AURORA
    localparam AURORA_DEBUG = 0;
  `else
    localparam AURORA_DEBUG = 1;
  `endif
  
  `RFNOC_SIM_INIT(NUM_CE, NUM_STREAMS, BUS_CLK_PERIOD, CE_CLK_PERIOD);
  //`RFNOC_ADD_BLOCK(noc_block_radio_core_eiscat, 0);
  `RFNOC_ADD_BLOCK_CUSTOM(noc_block_radio_core_eiscat_0, 0);
//  `RFNOC_ADD_BLOCK_CUSTOM(noc_block_radio_core_eiscat_1, 1);
  logic [NUM_CHANNELS-1:0] rx_stb;
  logic [NUM_CHANNELS*16-1:0] rx;
  reg rx_stb_reg;
  wire [7:0] rx_counter;
  wire counter_tvalid;
  wire link_up;
  wire [63:0] i_npio_tdata;
  wire i_npio_tvalid;
  wire i_npio_tlast;
  wire i_npio_tready;

  wire [63:0] o_npio_tdata;
  wire o_npio_tvalid;
  wire o_npio_tlast;
  wire o_npio_tready;
  
  wire aurora_refclk;
  wire aurora_clk156;
  wire aurora_init_clk;
   
  
  wire NPIO_LN_P, NPIO_LN_N;
  
  //aurora code
  `ifdef USE_NPIO_AURORA
  (* dont_touch = "true" *) IBUFDS_GTE2 aurora_refclk_ibuf (
      .ODIV2(),
      .CEB  (1'b0),
      .I (XG_CLK_P),
      .IB(XG_CLK_N),
      .O (aurora_refclk)
    );
  
    aurora_phy_clk_gen aurora_clk_gen_i (
      .refclk_ibuf(aurora_refclk),
      .clk156(aurora_clk156),
      .init_clk(aurora_init_clk)
    );
  
  n3xx_npio_qsfp_wrapper #(
     .LANES(1),      // Number of lanes of Aurora to instantiate (Supported = {1,2,3,4})
     .REG_BASE(32'h0),  // Base register address
     .PORTNUM_BASE(0),      // Base port number for discovery
     .REG_DWIDTH(32),     // Width of regport address bus
     .REG_AWIDTH(14)      // Width of regport data bus
  ) qsfp_wrapper_inst (
    // Clocks and Resets
    .areset(GSR),
    .bus_clk(bus_clk),
    .misc_clk(aurora_init_clk),
    .bus_rst(GSR),
    .gt_refclk(aurora_refclk),
    .gt_clk156(aurora_clk156),
    // Serial lanes
    .txp(NPIO_LN_P),
    .txn(NPIO_LN_N),
    .rxp(NPIO_LN_P),
    .rxn(NPIO_LN_N),
    // AXIS input interface
    .s_axis_tdata(o_npio_tdata),
    .s_axis_tlast(o_npio_tlast),
    .s_axis_tvalid(o_npio_tvalid),
    .s_axis_tready(o_npio_tready),
    // AXIS output interface
    .m_axis_tdata(i_npio_tdata),
    .m_axis_tlast(i_npio_tlast),
    .m_axis_tvalid(i_npio_tvalid),
    .m_axis_tready(i_npio_tready),
    // Register ports
    .reg_wr_req(0),  //input                   reg_wr_req,
    .reg_wr_addr(0), //input  [REG_AWIDTH-1:0] reg_wr_addr,
    .reg_wr_data(0), //input  [REG_DWIDTH-1:0] reg_wr_data,
    .reg_rd_req(0),  //input                   reg_rd_req,
    .reg_rd_addr(0), //input  [REG_AWIDTH-1:0] reg_rd_addr,
    .reg_rd_resp(), //output                  reg_rd_resp,
    .reg_rd_data(), //output [REG_DWIDTH-1:0] reg_rd_data,
  
    .link_up(link_up),
    .activity()
  );
  `else
   assign link_up = 1'b1;
  `endif
  
  noc_block_radio_core_eiscat
  #(.NUM_CHANNELS(NUM_CHANNELS), .NUM_BEAMS(NUM_BEAMS), .ENABLE_BEAMFORM(ENABLE_BEAMFORM), .AURORA_DEBUG(AURORA_DEBUG))
  noc_block_radio_core_eiscat_0( 
    .bus_clk(bus_clk), 
    .bus_rst(bus_rst), 
    .ce_clk(ce_clk), 
    .ce_rst(ce_rst), 
    .i_tdata(noc_block_radio_core_eiscat_0_i_tdata), 
    .i_tlast(noc_block_radio_core_eiscat_0_i_tlast), 
    .i_tvalid(noc_block_radio_core_eiscat_0_i_tvalid), 
    .i_tready(noc_block_radio_core_eiscat_0_i_tready), 
    .o_tdata(noc_block_radio_core_eiscat_0_o_tdata), 
    .o_tlast(noc_block_radio_core_eiscat_0_o_tlast), 
    .o_tvalid(noc_block_radio_core_eiscat_0_o_tvalid), 
    .o_tready(noc_block_radio_core_eiscat_0_o_tready),
      //i/o to NPIO MGT cores
    .i_npio_tdata(i_npio_tdata),
    .i_npio_tvalid(i_npio_tvalid),
    .i_npio_tlast(i_npio_tlast),
    .i_npio_tready(i_npio_tready),
  
    .o_npio_tdata(o_npio_tdata),
    .o_npio_tvalid(o_npio_tvalid),
    .o_npio_tlast(o_npio_tlast),
    .o_npio_tready(o_npio_tready),
    .debug(),
    .rx(rx),
    .rx_stb(rx_stb)
  );
  
 
  `RFNOC_ADD_BLOCK(noc_block_ddc_eiscat, 1 /* xbar port 0 */);

  assign rx_stb = {NUM_CHANNELS{counter_tvalid}};
  assign rx = {16{rx_counter, 8'h00}};
  
   counter #(.WIDTH(8)) counter_inst
        (.clk(ce_clk), .reset(ce_rst), .clear(0),
         .max(8'h0F),
         .i_tlast(1'b0), .i_tvalid(rx_stb_reg), .i_tready(),
         .o_tdata(rx_counter), .o_tlast(), .o_tvalid(counter_tvalid), .o_tready(1'b1));
  
  always @(posedge ce_clk) begin
    if(ce_rst) begin
      rx_stb_reg = 1'b0;
    end else
      rx_stb_reg <= ~rx_stb_reg;
  end

  localparam [15:0] SPP = 16'hF80; // Samples per packet 3968
  localparam [27:0] SPP1 = 28'hF80;
  localparam [27:0] SPP2 = 28'h1F00;
  localparam [27:0] SPP4 = 28'h3E00; 
  localparam [27:0] SPP6 = 28'h5D00; 
  
    // DDC
  wire [7:0] SR_N_ADDR           = noc_block_ddc_eiscat.gen_ddc_chains[0].axi_rate_change.SR_N_ADDR;
  wire [7:0] SR_M_ADDR           = noc_block_ddc_eiscat.gen_ddc_chains[0].axi_rate_change.SR_M_ADDR;
  wire [7:0] SR_CONFIG_ADDR      = noc_block_ddc_eiscat.gen_ddc_chains[0].axi_rate_change.SR_CONFIG_ADDR;
  wire [7:0] SR_FREQ_ADDR        = noc_block_ddc_eiscat.SR_FREQ_ADDR;
  wire [7:0] SR_SCALE_IQ_ADDR    = noc_block_ddc_eiscat.SR_SCALE_IQ_ADDR;
  wire [7:0] SR_DECIM_ADDR       = noc_block_ddc_eiscat.SR_DECIM_ADDR;
  wire [7:0] SR_MUX_ADDR         = noc_block_ddc_eiscat.SR_MUX_ADDR;
  wire [7:0] SR_COEFFS_ADDR      = noc_block_ddc_eiscat.SR_COEFFS_ADDR;
  wire [7:0] RB_NUM_HB           = noc_block_ddc_eiscat.RB_NUM_HB;
  wire [7:0] RB_CIC_MAX_DECIM    = noc_block_ddc_eiscat.RB_CIC_MAX_DECIM;

  
  task automatic send_prev_data;
    input integer stream_num;
    input [15:0] num_samples;
    input has_time;
    input eob;
    input [63:0] timestamp;
    begin
      cvita_payload_t payload;
      cvita_metadata_t md = '{eob:eob, has_time:has_time, timestamp:timestamp};
      logic [63:0] readback;
      // Send TX burst
      payload = {};
      // Generate ramp pattern for TX samples
      for (int k = 0; k < num_samples/4; k = k + 1) begin
        payload.push_back({16'(4*k), 16'(4*k+1), 16'(4*k+2), 16'(4*k+3)});
      end
      $display("Prev Beam %2d: Send timed prev beam, %0d samples at time %0d",stream_num,num_samples,timestamp);
      tb_streamer.send(payload,md,stream_num);
      $display("Beam %2d: prev beam sent",stream_num);
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
      //this print statement was getting annoying
     
//      for (int k = 1; k < payload.size(); k = k + 1) begin
//        $display("Received payload %8x", payload[k]);
//      end
      $display("Radio %2d: Received RX packet correct", radio_num);
    end
  endtask
  
  task automatic check_resp;
    input has_time;
    input eob;
    input [15:0] src_sid;
    input [63:0] expected_resp_code;
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
      $display("expected: %16x, received: %16x", expected_resp_code, response.payload[0]);
      $sformat(s, "Incorrect response packet code! Received: %8x Expected: %8x", response.payload[0][63:32], expected_resp_code[63:32]);
      `ASSERT_ERROR(response.payload[0][63:32] == expected_resp_code[63:32], s);
    end
  endtask
  
  task automatic check_radio_resp;
    input integer radio_num;
    input has_time;
    input eob;
    input [63:0] expected_resp_code;
    begin
      $display("Radio %2d: Checking radio response packet", radio_num);
      check_resp(has_time, eob, (sid_noc_block_radio_core_eiscat_0 + radio_num), expected_resp_code);
      $display("Radio %2d: Radio response packet correct", radio_num);
    end
  endtask

  task automatic flush_rx_check_for_error;
      input integer radio_num;
      input integer expect_resp_packet_when;
      input [63:0] expected_resp_code; 
      begin
        string s;
        logic [15:0] src_sid = (sid_noc_block_radio_core_eiscat_0 + radio_num);
        cvita_pkt_t pkt;
        integer pkt_cnt = 1;
        pkt.hdr.eob = 1'b0;
        tb_streamer.pull_pkt(pkt,radio_num);
        $display("Radio %2d: Checking radio packet", radio_num);
        $display("Checking packet type. Received: 2'b%0b", pkt.hdr.pkt_type);
        $display("Checking EOB value. Received: %1b ", pkt.hdr.eob);
        $display("Checking seqnum value. Received: %3h ", pkt.hdr.seqnum);
        $display("Checking timestamp value. Received: %16h ", pkt.hdr.timestamp);
        while (~(pkt.hdr.eob & pkt.hdr.pkt_type == DATA)) begin
          $display("Start of while loop. Iteration %d", pkt_cnt);         
          if(expect_resp_packet_when == pkt_cnt) begin
            $display("This should be a response packet.");
            check_radio_resp(radio_num,1,1,expected_resp_code);
          end else begin
            tb_streamer.pull_pkt(pkt,radio_num);
            $display("Radio %2d: Checking radio packet", radio_num);
            $display("Checking packet type. Received: 2'b%0b", pkt.hdr.pkt_type);
            $display("Checking EOB value. Received: %1b ", pkt.hdr.eob);
            $display("Checking seqnum value. Received: %3h ", pkt.hdr.seqnum);
            $display("Checking timestamp value. Received: %16h ", pkt.hdr.timestamp);
          end
          pkt_cnt = pkt_cnt + 1;
        end
        $display("Radio %2d: last packet on ", radio_num);
        $display("Checking packet type. Received: 2'b%0b", pkt.hdr.pkt_type);
        $display("Checking EOB value. Received: %1b ", pkt.hdr.eob);
        $display("Checking seqnum value. Received: %3h ", pkt.hdr.seqnum);
        $display("Checking timestamp value. Received: %16h ", pkt.hdr.timestamp);
        $display("Radio %2d: Flushed %3d RX packets", radio_num, pkt_cnt);
      end
    endtask

  /********************************************************
  ** Verification
  ********************************************************/
  initial begin : tb_main
    string s;
    cvita_payload_t payload;
    cvita_metadata_t md;
    logic [31:0] random_word;
    logic [63:0] readback;
    logic last;
    logic [15:0] samp1, samp2;
    int num_taps;
    int readback_test;
    int num_channels;
    int num_beams;
    int num_filters;
    logic [63:0] vita_time_now;
    logic [63:0] prev_send_time;


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
    tb_streamer.read_reg(sid_noc_block_radio_core_eiscat_0, RB_NOC_ID, readback);
    $display("Read EISCAT NOC ID: %16x", readback);
    `ASSERT_ERROR(readback == noc_block_radio_core_eiscat.NOC_ID, "Incorrect NOC ID");
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 3 -- Connect RFNoC blocks
    ********************************************************/
    `TEST_CASE_START("Connect RFNoC blocks");
    `RFNOC_CONNECT_BLOCK_PORT(noc_block_tb,0,noc_block_radio_core_eiscat_0,0,S16,SPP);
    `RFNOC_CONNECT_BLOCK_PORT(noc_block_tb,1,noc_block_radio_core_eiscat_0,1,S16,SPP);
    `RFNOC_CONNECT_BLOCK_PORT(noc_block_tb,2,noc_block_radio_core_eiscat_0,2,S16,SPP);
    `RFNOC_CONNECT_BLOCK_PORT(noc_block_tb,3,noc_block_radio_core_eiscat_0,3,S16,SPP);
    `RFNOC_CONNECT_BLOCK_PORT(noc_block_tb,4,noc_block_radio_core_eiscat_0,4,S16,SPP);
    `RFNOC_CONNECT_BLOCK_PORT(noc_block_radio_core_eiscat_0,0,noc_block_tb,0,S16,SPP);
    `RFNOC_CONNECT_BLOCK_PORT(noc_block_radio_core_eiscat_0,1,noc_block_tb,1,S16,SPP);
    `RFNOC_CONNECT_BLOCK_PORT(noc_block_radio_core_eiscat_0,2,noc_block_tb,2,S16,SPP);
    `RFNOC_CONNECT_BLOCK_PORT(noc_block_radio_core_eiscat_0,3,noc_block_tb,3,S16,SPP);
    `RFNOC_CONNECT_BLOCK_PORT(noc_block_radio_core_eiscat_0,4,noc_block_tb,4,S16,SPP);
    `TEST_CASE_DONE(1);
    
    /********************************************************
    ** Test 4 -- Do some initial configuration
    ********************************************************/
    // Sending an impulse will readback the FIR filter coefficients
    `TEST_CASE_START("READBACK REGS and set BRAM");
    /* Set filter coefficients via reload bus */
    // Read NUM_TAPS
    $display("COMPAT CHECK");
    tb_streamer.read_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.RB_COMPAT_NUM, readback_test, 0);
    $display("COMPAT = %h", readback_test);    
    $display("READBACK TEST");
    tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_TEST, 32'hDEAD, 0);
    tb_streamer.read_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.RB_TEST, readback_test, 0);
    $display("%h", readback_test);
    tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_TEST, 32'hDEAE, 0);
    tb_streamer.read_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.RB_TEST, readback_test, 1);
    $display("%h", readback_test);
    tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_TEST, 32'hDEAF, 0);
    tb_streamer.read_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.RB_TEST, readback_test, 2);
    $display("%h", readback_test);
    tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_TEST, 32'hDEAA, 0);
    tb_streamer.read_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.RB_TEST, readback_test, 3);
    $display("%h", readback_test);
    tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_TEST, 32'hDEAB, 0);
    tb_streamer.read_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.RB_TEST, readback_test, 4);
    $display("%h", readback_test);
    $display("CONFIRMING READBACK CAPABILITY ON ALL 5 NOC BLOCK PORTS.");
    $display("READ BACK NUM TAPS 0");
    tb_streamer.read_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.RB_NUM_TAPS, num_taps, 0);
    $display("%d", num_taps);
    $display("READ BACK NUM TAPS 1");    
    tb_streamer.read_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.RB_NUM_TAPS, num_taps, 1);
    $display("%d", num_taps);
    $display("READ BACK NUM TAPS 2");
    tb_streamer.read_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.RB_NUM_TAPS, num_taps, 2);
    $display("%d", num_taps);
    tb_streamer.read_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.RB_NUM_TAPS, num_taps, 3);
    $display("%d", num_taps);
    tb_streamer.read_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.RB_NUM_TAPS, num_taps, 4);
    $display("%d", num_taps);
    $display("READ BACK NUM CHANNELS");
    tb_streamer.read_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.RB_NUM_CHANNELS, num_channels, 0);
    $display("%d", num_channels);
    $display("READ BACK NUM BEAMS");
    tb_streamer.read_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.RB_NUM_BEAMS, num_beams , 0);
    $display("%d", num_beams);
    $display("READ BACK NUM FILTERS = NUM CHANNELS * NUM BEAMS");
    tb_streamer.read_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.RB_NUM_FILTERS, num_filters, 0);
    $display("%d", num_filters);
    $display("SET DIGITAL GAIN MULTIPLIERS");
    for (int c = 0; c < num_channels; c++) begin
      $display("c = %d", c);
      tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_CHANNEL_GAIN_BASE+c, 18'h1FFFF, 0);
    end
    $display("Set Time");
//    tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat, noc_block_radio_core_eiscat.SR_FIR_COMMANDS_CTRL_TIME_HI, 0, 0);
//    tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat, noc_block_radio_core_eiscat.SR_FIR_COMMANDS_CTRL_TIME_LO, 12'h800, 0);
   
    $display("LOAD TAPS FROM BRAM, starting with a timed command.");
    // Write a ramp to FIR filter coefficients
//    tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat, noc_block_radio_core_eiscat.SR_FIR_COMMANDS_RELOAD, 0, 0); //f=0, use the command ctrl time.
//    for (int c = 0; c < num_channels; c++) begin
//      for (int b = 0; b < num_beams; b++) begin
//        int d = 1002
//        $display("c = %d, b = %d, d = %d", c, b, d);
//        //c = channel_index 0-15, b = beam index 0-9
//        tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat, noc_block_radio_core_eiscat.SR_FIR_COMMANDS_RELOAD, (1<<22)+(c<<14)+(b<<18)+d*16, 0);
//      end
//    end
    tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_FIR_COMMANDS_RELOAD, (1<<22)+(0<<14)+(0<<18)+1002*16, 0);
    tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_FIR_COMMANDS_RELOAD, (1<<22)+(1<<14)+(1<<18)+1002*16, 0);
    tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_FIR_COMMANDS_RELOAD, (1<<22)+(2<<14)+(2<<18)+1002*16, 0);
    tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_FIR_COMMANDS_RELOAD, (1<<22)+(3<<14)+(3<<18)+1002*16, 0);
    tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_FIR_COMMANDS_RELOAD, (1<<22)+(4<<14)+(4<<18)+1002*16, 0);
    tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_FIR_COMMANDS_RELOAD, (1<<22)+(5<<14)+(5<<18)+1002*16, 0);
    tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_FIR_COMMANDS_RELOAD, (1<<22)+(6<<14)+(6<<18)+1002*16, 0);
    tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_FIR_COMMANDS_RELOAD, (1<<22)+(7<<14)+(7<<18)+1002*16, 0);
    tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_FIR_COMMANDS_RELOAD, (1<<22)+(8<<14)+(8<<18)+1002*16, 0);
    tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_FIR_COMMANDS_RELOAD, (1<<22)+(9<<14)+(9<<18)+1002*16, 0);

//    $display("SET COMMAND TO SEND IMM.");
    `TEST_CASE_DONE(1);
    
    /********************************************************
    ** Test 5 -- Wait for Aurora to go HIGH
    ********************************************************/
    `TEST_CASE_START("Wait for master channel to come up");
    while (link_up !== 1'b1) @(posedge ce_clk);
    `TEST_CASE_DONE(1'b1);
    
    
    /********************************************************
    ** Test 6 -- First Data Test. 5 beams direct to output
    ********************************************************/
    `TEST_CASE_START("First Data Test. DEBUG TEST MODE, bypass beamform function.");
    tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_BEAMS_TO_NEIGHBOR, 4'b0110); //set 5 beams directly to output
    tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_STREAM_ENABLE, 10'h01f); //only enable stream 0
    tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_MAXLEN, SPP); //set max length
    tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_OUTPUT_FORMAT, 1'b1); //use timestamps
    tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_COMMAND, 
      {1'b1 /* Start immediately */, 1'b1 /* chain */, 1'b1 /* reload */, 1'b0 /* Stop */, 28'b1 /*numlines*/ }, 0);
    tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_TIME_HI, {32'hfeaf8765}, 0); //how we store a command.
    tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_TIME_LO, {32'hdeadbeef}, 0); //how we store a command.

    $display("try to get some data from the module.");
    for (int r = 0; r < 5; r++) begin
      check_rx(r);
      check_rx(r);
    end
    $display("***Finished receiving data. Wait a bit...***");
    repeat (1000) @ (posedge ce_clk);
    
    $display("*** Sending stop command now.***");
    tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_COMMAND, 
      {1'b1 /* Start immediately */, 1'b0 /* chain */, 1'b0 /* reload */, 1'b1 /* Stop */, 28'h7654321 /*numlines*/ }, 0);
    tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_TIME_LO, {32'hdeadbeef}, 0); //how we store a command.
    
    for (int r = 0; r < 5; r++) begin
      flush_rx(r);
    end
    `TEST_CASE_DONE(1);
    
//    /********************************************************
//    ** Test 7 -- First Data Test. Test with DDC.
//    ********************************************************/    
    `TEST_CASE_START("2nd Data Test. DEBUG TEST MODE, to DDC, bypass beamform function.");
    `RFNOC_CONNECT_BLOCK_PORT(noc_block_tb, 0,noc_block_radio_core_eiscat_0,0,S16,SPP);
    `RFNOC_CONNECT_BLOCK_PORT(noc_block_radio_core_eiscat_0, 0, noc_block_ddc_eiscat, 0, S16, SPP);
    `RFNOC_CONNECT_BLOCK_PORT(noc_block_ddc_eiscat, 0, noc_block_tb, 0, SC16, SPP);
    tb_streamer.write_reg(sid_noc_block_ddc_eiscat, SR_CONFIG_ADDR, 32'd1);              // Enable clear EOB
    tb_streamer.write_reg(sid_noc_block_ddc_eiscat, SR_FREQ_ADDR, 32'd0);                // CORDIC phase increment
    tb_streamer.write_reg(sid_noc_block_ddc_eiscat, SR_SCALE_IQ_ADDR, (1 << 14)); // Scaling, set to 1
    tb_streamer.write_reg(sid_noc_block_ddc_eiscat, SR_N_ADDR, 2);                  // Set decimation rate in AXI rate change
    tb_streamer.write_reg(sid_noc_block_ddc_eiscat, SR_DECIM_ADDR, {2'b1,8'h1});   // Enable HBs, set CIC rate
    tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_BEAMS_TO_NEIGHBOR, 4'b0110); //set 5 beams directly to output
    tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_STREAM_ENABLE, 10'h001); //only enable stream 0
    tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_MAXLEN, SPP); //set max length
    tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_OUTPUT_FORMAT, 1'b1); //use timestamps
    tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_COMMAND, 
      {1'b1 /* Start immediately */, 1'b1 /* chain */, 1'b1 /* reload */, 1'b0 /* Stop */, 28'b1 /*numlines*/ }, 0);
    tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_TIME_LO, {32'hdeadbeef}, 0); //how we store a command.

    $display("try to get some data from the module.");
    for (int r = 0; r < 1; r++) begin
      check_rx(0);
      check_rx(0);
    end
    $display("***Finished receiving data. Wait a bit...***");
    repeat (2000) @ (posedge ce_clk);
    
    $display("*** Sending stop command now.***");
    tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_COMMAND, 
      {1'b1 /* Start immediately */, 1'b0 /* chain */, 1'b0 /* reload */, 1'b1 /* Stop */, 28'b1 /*numlines*/ }, 0);
    tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_TIME_LO, {32'hdeadbeef}, 0); //how we store a command.
    flush_rx(0);
    `TEST_CASE_DONE(1);
//    /********************************************************
//    ** Test 8 -- Create Overflow condition in simple debug mode
//    ********************************************************/
    `TEST_CASE_START("Test overflow w/ simple debug mode.");
    `RFNOC_CONNECT_BLOCK_PORT(noc_block_tb, 0,noc_block_radio_core_eiscat_0,0,S16,SPP);
    `RFNOC_CONNECT_BLOCK_PORT(noc_block_tb, 1,noc_block_radio_core_eiscat_0,1,S16,SPP);
    `RFNOC_CONNECT_BLOCK_PORT(noc_block_radio_core_eiscat_0, 0, noc_block_tb, 0, S16, SPP);
    `RFNOC_CONNECT_BLOCK_PORT(noc_block_radio_core_eiscat_0, 1, noc_block_tb, 1, S16, SPP);
    tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_BEAMS_TO_NEIGHBOR, 4'b0110); //set 5 beams directly to output counter
    tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_STREAM_ENABLE, 10'h003); //only enable stream 0
    tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_MAXLEN, SPP); //set max length
    tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_OUTPUT_FORMAT, 1'b1); //use timestamps
    tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_PREV_OR_NULL, 1'b0); //use null
    tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_COMMAND, 
      {1'b1 /* Start immediately */, 1'b1 /* chain */, 1'b1 /* reload */, 1'b0 /* Stop */, 28'b1 /*numlines*/ }, 0);
    tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_TIME_LO, {32'hdeadbeef}, 0); //how we store a command.
    $display("Generate data to force an overflow then wait . (t=%09d)", $time);
    repeat (50000) @ (posedge ce_clk);
    $display("Check response now (t=%09d)", $time);     // Check overflow packet
    check_radio_resp(0,1,1,noc_block_radio_core_eiscat.rx_control_eiscat_inst.ERR_OVERRUN);
     // Check first RX packet to make sure it has not been corrupted
    check_rx(0);
    check_rx(1);
    // Clear out remaining RX packets
    $display("Radio %2d: Flush remaining RX packets", 0);
    flush_rx(0);
    flush_rx(1);
    $display("restart radio with normal operation and get 1 packet");
    tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_COMMAND, 
    {1'b1 /* Start immediately */, 1'b0 /* chain */, 1'b0 /* reload */, 1'b0 /* Stop */, SPP1 /*numlines*/ }, 0);
    tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_TIME_LO, {32'hdeadbeef}, 0); //how we store a command.
    check_rx(0);
    check_rx(1);
    `TEST_CASE_DONE(1);
    
    /********************************************************
    ** Test 9 -- Test overflow - with DDC.
    ********************************************************/    
    `TEST_CASE_START("Test Overflow: simple debug WITH DDC. rx 2 beams...");
    `RFNOC_CONNECT_BLOCK_PORT(noc_block_tb, 0,noc_block_radio_core_eiscat_0,0,S16,SPP);
    `RFNOC_CONNECT_BLOCK_PORT(noc_block_tb, 0,noc_block_radio_core_eiscat_0,1,S16,SPP);
    `RFNOC_CONNECT_BLOCK_PORT(noc_block_radio_core_eiscat_0, 0, noc_block_ddc_eiscat, 0, S16, SPP);
    `RFNOC_CONNECT_BLOCK_PORT(noc_block_radio_core_eiscat_0, 1, noc_block_ddc_eiscat, 1, S16, SPP);
    `RFNOC_CONNECT_BLOCK_PORT(noc_block_ddc_eiscat, 0, noc_block_tb, 0, SC16, SPP);
    `RFNOC_CONNECT_BLOCK_PORT(noc_block_ddc_eiscat, 1, noc_block_tb, 1, SC16, SPP);
    tb_streamer.write_reg(sid_noc_block_ddc_eiscat, SR_CONFIG_ADDR, 32'd1);              // Enable clear EOB
    tb_streamer.write_reg(sid_noc_block_ddc_eiscat, SR_FREQ_ADDR, 32'd0);                // CORDIC phase increment
    tb_streamer.write_reg(sid_noc_block_ddc_eiscat, SR_SCALE_IQ_ADDR, (1 << 14)); // Scaling, set to 1
    tb_streamer.write_reg(sid_noc_block_ddc_eiscat, SR_N_ADDR, 2);                  // Set decimation rate in AXI rate change
    tb_streamer.write_reg(sid_noc_block_ddc_eiscat, SR_DECIM_ADDR, {2'b1,8'h1});   // Enable HBs, set CIC rate
    tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_BEAMS_TO_NEIGHBOR, 4'b0110); //set 5 beams directly to output
    tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_STREAM_ENABLE, 10'h003); //only enable stream 0
    tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_MAXLEN, SPP); //set max length
    tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_OUTPUT_FORMAT, 1'b1); //use timestamps
    tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_COMMAND, 
      {1'b1 /* Start immediately */, 1'b1 /* chain */, 1'b1 /* reload */, 1'b0 /* Stop */, 28'b1 /*numlines*/ }, 0);
    tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat.SR_RX_CTRL_TIME_LO, {32'hdeadbeef}, 0); //how we store a command.
 
    $display("Generate data to force an overflow then wait.");
    repeat (60000) @ (posedge ce_clk);
    //Check first RX packet to make sure it has not been corrupted
    $display("Check one data packet. (t=%09d). maybe this will clear things so we can receive the response too, who's to say...", $time); 
    check_rx(0);   
    check_rx(1);   
    $display("Radio %2d: Flush remaining RX packets (t=%09d).", 0, $time);
    flush_rx(0);
    flush_rx(1);
    $display("Check response. (t=%09d)", $time);
    // Check overflow packet
    check_radio_resp(0,1,1,noc_block_radio_core_eiscat_0.rx_control_eiscat_inst.ERR_OVERRUN);
     
    $display("restart radio with normal operation and get 1 packet");
    tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_COMMAND, 
    {1'b1 /* Start immediately */, 1'b0 /* chain */, 1'b0 /* reload */, 1'b0 /* Stop */, SPP1 /*numlines*/ }, 0);
    tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_TIME_LO, {32'hdeadbeef}, 0); //how we store a command.
    check_rx(0);   
    check_rx(1);   
    `TEST_CASE_DONE(1);
     /********************************************************
     ** Test 10 -- Integrate aurora (use internal counter as data source)
     ********************************************************/
     `TEST_CASE_START("Get data and use Aurora neighbor");
     `RFNOC_CONNECT_BLOCK_PORT(noc_block_tb, 0,noc_block_radio_core_eiscat_0, 0,S16,SPP);
     `RFNOC_CONNECT_BLOCK_PORT(noc_block_radio_core_eiscat_0, 0, noc_block_tb, 0, S16, SPP);     
     `RFNOC_CONNECT_BLOCK_PORT(noc_block_tb, 1,noc_block_radio_core_eiscat_0, 1,S16,SPP);
     `RFNOC_CONNECT_BLOCK_PORT(noc_block_radio_core_eiscat_0, 1, noc_block_tb, 1, S16, SPP);
     tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_BEAMS_TO_NEIGHBOR, 4'b0100); //set to counter, skip beamform, use aurora
     tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_STREAM_ENABLE, 10'h021); //enable streams 5 and 0 (to do a loopback on aurora neighbor)
     tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_MAXLEN, SPP); //set max length
     tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_OUTPUT_FORMAT, 1'b1); //use timestamps
     tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_COMMAND, 
      {1'b1 /* Start immediately */, 1'b0 /* chain */, 1'b0 /* reload */, 1'b0 /* Stop */, SPP4 /*numlines*/ }, 0);
     tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_PREV_OR_NULL, 1'b0); //use null
     tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_TIME_LO, {32'hdeadbeef}, 0); //how we store a command.
     
     $display("try to get some data from the module.");
     //flush_rx(0);
     check_rx(0);

     check_rx(0);

     check_rx(0);

     check_rx(0);

     `TEST_CASE_DONE(1);
     
      /********************************************************
      ** Test 11 -- Create overflow condition WITH aurora
      ********************************************************/
      `TEST_CASE_START("Test overflow with Aurora neighbor.");
      tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_BEAMS_TO_NEIGHBOR, 4'b1100); //set 5 beams directly to output
      tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_STREAM_ENABLE, 10'h021); //only enable streams 0-3
      tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_MAXLEN, SPP); //set max length
      tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_OUTPUT_FORMAT, 1'b1); //use timestamps
      tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_COMMAND, 
       {1'b1 /* Start immediately */, 1'b1 /* chain */, 1'b1 /* reload */, 1'b0 /* Stop */, SPP1 /*numlines*/ }, 0);
      tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_TIME_LO, {32'hdeadbeef}, 0); //how we store a command.

      $display("Generate data to force an overflow with aurora then wait.");
      #(20*RADIO_CLK_PERIOD*SPP);
      @(negedge ce_clk);
      // Check first RX packet to make sure it has not been corrupted
      $display("Check data.");
      // Check overflow packet
      check_radio_resp(0,1,1,noc_block_radio_core_eiscat_0.rx_control_eiscat_inst.ERR_OVERRUN);
      check_rx(0);
      // Clear out remaining RX packets
      $display("Radio %2d: Flush remaining RX packets", 0);
      flush_rx(0);
      $display("restart radio with normal operation and get 1 packet");
      tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_COMMAND, 
      {1'b1 /* Start immediately */, 1'b0 /* chain */, 1'b0 /* reload */, 1'b0 /* Stop */, SPP1 /*numlines*/ }, 0);
      tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_TIME_LO, {32'hdeadbeef}, 0); //how we store a command.
      check_rx(0);
      `TEST_CASE_DONE(1); 
      
      /********************************************************
      ** Test 10 -- Test with multiple beams (all 5!)
      ********************************************************/     
     `TEST_CASE_START("Get data and use Aurora neighbor (all 5 beams!)");
     tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_BEAMS_TO_NEIGHBOR, 4'b1100); //set to counter, skip beamform, use aurora
     tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_STREAM_ENABLE, 10'h03FF); //enable streams 5 and 0 (to do a loopback on aurora neighbor)
     tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_MAXLEN, SPP); //set max length
     tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_OUTPUT_FORMAT, 1'b1); //use timestamps
     tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_COMMAND, 
      {1'b1 /* Start immediately */, 1'b0 /* chain */, 1'b0 /* reload */, 1'b0 /* Stop */, SPP4 /*numlines*/ }, 0);
     tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_PREV_OR_NULL, 1'b0); //use null
     tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_TIME_LO, {32'hdeadbeef}, 0); //how we store a command.
     
     $display("try to get some data from the module.");
     flush_rx(0);
     flush_rx(1);
     flush_rx(2);
     flush_rx(3);
     flush_rx(4);
     `TEST_CASE_DONE(1);
     
      /********************************************************
      ** Test 11 -- Create overflow condition WITH aurora multi channel
      ********************************************************/
      `TEST_CASE_START("Test overflow with Aurora neighbor (multiple beams!).");
      tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_BEAMS_TO_NEIGHBOR, 4'b1100); //use counter and neighbors
      tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_STREAM_ENABLE, 10'h3ff); //only enable streams 0-3
      tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_MAXLEN, SPP); //set max length
      tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_OUTPUT_FORMAT, 1'b1); //use timestamps
      tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_COMMAND, 
       {1'b1 /* Start immediately */, 1'b1 /* chain */, 1'b1 /* reload */, 1'b0 /* Stop */, 28'h1 /*numlines*/ }, 0);
      tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_TIME_LO, {32'hdeadbeef}, 0); //how we store a command.

      $display("Generate data to force an overflow with aurora then wait.");
      #(20*RADIO_CLK_PERIOD*SPP);
      @(negedge ce_clk);
      // Check first RX packet to make sure it has not been corrupted
      $display("Check data.");
      // Check overflow packet
      check_radio_resp(0,1,1,noc_block_radio_core_eiscat.rx_control_eiscat_inst.ERR_OVERRUN);
      check_rx(0);
      check_rx(1);
      check_rx(2);      
      check_rx(3);      
      check_rx(4);      
      // Clear out remaining RX packets
      $display("Radio %2d: Flush remaining RX packets", 0);
      flush_rx(0);
      flush_rx(1);
      flush_rx(2);
      flush_rx(3);
      flush_rx(4);
      $display("restart radio with normal operation and get 1 packet");
      tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_COMMAND, 
      {1'b1 /* Start immediately */, 1'b0 /* chain */, 1'b0 /* reload */, 1'b0 /* Stop */, SPP1 /*numlines*/ }, 0);
      tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_TIME_LO, {32'hdeadbeef}, 0); //how we store a command.
      check_rx(0);
      check_rx(1);
      check_rx(2);
      check_rx(3);
      check_rx(4);
      `TEST_CASE_DONE(1); 
       /********************************************************
      ** Test 12 -- run module WITH aurora AND prev data multi channel
      ********************************************************/
      `TEST_CASE_START("Test with Aurora neighbor and Prev on all 5 beams.");
      tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_PREV_OR_NULL, 1'b1); //use prev
      tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_BEAMS_TO_NEIGHBOR, 4'b1100); //use counter and neighbors
      tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_STREAM_ENABLE, 10'h3ff); //stream on all channels
      tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_MAXLEN, SPP); //set max length
      tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_OUTPUT_FORMAT, 1'b1); //use timestamps
      tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_COMMAND, 
       {1'b0 /* Start immediately */, 1'b0 /* chain */, 1'b0 /* reload */, 1'b0 /* Stop */, SPP6 /*numlines*/ }, 0);
      tb_streamer.read_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.RB_VITA_TIME, vita_time_now, 0);
      tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_TIME_HI, {vita_time_now[63:32]}, 0); //how we store a command.
      tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_TIME_LO, {vita_time_now[31:0]+32'h0500}, 0); //how we store a command.
      #(1*RADIO_CLK_PERIOD*SPP); //wait a bit for stream command to trigger.

      $display("Generate data and send prev with aurora.");
      prev_send_time = {vita_time_now+64'h0502};
      send_prev_data(0,SPP,1 /* Has time */,0 /* EOB */, prev_send_time /* Time */); //has valid time right now.
      send_prev_data(1,SPP,1 /* Has time */,0 /* EOB */, prev_send_time /* Time */); //has valid time right now.
      send_prev_data(2,SPP,1 /* Has time */,0 /* EOB */, prev_send_time /* Time */); //has valid time right now.
      send_prev_data(3,SPP,1 /* Has time */,0 /* EOB */, prev_send_time /* Time */); //has valid time right now.
      send_prev_data(4,SPP,1 /* Has time */,0 /* EOB */, prev_send_time /* Time */); //has valid time right now.
      for(int p = 0; p < 5; p++) begin
        prev_send_time = 64'h1F00 + prev_send_time;
        $display("Sending prev beams set %0d", p);
        if(p == 4) begin
          send_prev_data(0,SPP,1 /* Has time */,1 /* EOB */, prev_send_time /* Time */); //has valid time right now.
          send_prev_data(1,SPP,1 /* Has time */,1 /* EOB */, prev_send_time /* Time */); //has valid time right now.
          send_prev_data(2,SPP,1 /* Has time */,1 /* EOB */, prev_send_time /* Time */); //has valid time right now.
          send_prev_data(3,SPP,1 /* Has time */,1 /* EOB */, prev_send_time /* Time */); //has valid time right now.
          send_prev_data(4,SPP,1 /* Has time */,1 /* EOB */, prev_send_time /* Time */); //has valid time right now.
        end else begin
          send_prev_data(0,SPP,1 /* Has time */,0 /* EOB */, prev_send_time /* Time */); //has valid time right now.
          send_prev_data(1,SPP,1 /* Has time */,0 /* EOB */, prev_send_time /* Time */); //has valid time right now.
          send_prev_data(2,SPP,1 /* Has time */,0 /* EOB */, prev_send_time /* Time */); //has valid time right now.
          send_prev_data(3,SPP,1 /* Has time */,0 /* EOB */, prev_send_time /* Time */); //has valid time right now.
          send_prev_data(4,SPP,1 /* Has time */,0 /* EOB */, prev_send_time /* Time */); //has valid time right now.
        end
      end
      // Check first RX packet to make sure it has not been corrupted
      $display("Check data.");
      // Check overflow packet
      check_rx(0);
      check_rx(1);
      check_rx(2);      
      check_rx(3);      
      check_rx(4);      
      // Clear out remaining RX packets
      $display("Radio %2d: Flush remaining RX packets", 0);
      flush_rx(0);
      flush_rx(1);
      flush_rx(2);
      flush_rx(3);
      flush_rx(4);
      `TEST_CASE_DONE(1); 
      
//       /********************************************************
//       ** Test 13 -- Create overflow condition WITH aurora AND prev data multi channel again to verify that overruns are fully recoverable
//       ********************************************************/
       `TEST_CASE_START("Test overflow with Aurora neighbor and Prev.");
       tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_PREV_OR_NULL, 1'b1); //use null
       tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_BEAMS_TO_NEIGHBOR, 4'b1100); //use counter and neighbors
       tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_STREAM_ENABLE, 10'h3ff); //only enable streams 0-3
       tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_MAXLEN, SPP); //set max length
       tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_OUTPUT_FORMAT, 1'b1); //use timestamps
       tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_COMMAND, 
        {1'b0 /* Start immediately */, 1'b1 /* chain */, 1'b1 /* reload */, 1'b0 /* Stop */, SPP1 /*numlines*/ }, 0);
       tb_streamer.read_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.RB_VITA_TIME, vita_time_now, 0);
       tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_TIME_LO, {vita_time_now[31:0]+32'h0500}, 0); //how we store a command.
 
       $display("Generate data to force an overflow with aurora then wait.");
       $display("... While waiting, send prev data with matching timestamps.");
       #(1*RADIO_CLK_PERIOD*SPP); //wait a bit for stream command to trigger.
       prev_send_time = {vita_time_now+64'h0502};
       send_prev_data(0,SPP,1 /* Has time */,0 /* EOB */, prev_send_time /* Time */); //has valid time right now.
       send_prev_data(1,SPP,1 /* Has time */,0 /* EOB */, prev_send_time /* Time */); //has valid time right now.
       send_prev_data(2,SPP,1 /* Has time */,0 /* EOB */, prev_send_time /* Time */); //has valid time right now.
       send_prev_data(3,SPP,1 /* Has time */,0 /* EOB */, prev_send_time /* Time */); //has valid time right now.
       send_prev_data(4,SPP,1 /* Has time */,0 /* EOB */, prev_send_time /* Time */); //has valid time right now.
       for(int p = 0; p < 10; p++) begin
         prev_send_time = 64'h1F30 + prev_send_time;
         $display("Sending prev beams set %0d", p);
         if(p == 9) begin
           send_prev_data(0,SPP,1 /* Has time */,1 /* EOB */, prev_send_time /* Time */); //has valid time right now.
           send_prev_data(1,SPP,1 /* Has time */,1 /* EOB */, prev_send_time /* Time */); //has valid time right now.
           send_prev_data(2,SPP,1 /* Has time */,1 /* EOB */, prev_send_time /* Time */); //has valid time right now.
           send_prev_data(3,SPP,1 /* Has time */,1 /* EOB */, prev_send_time /* Time */); //has valid time right now.
           send_prev_data(4,SPP,1 /* Has time */,1 /* EOB */, prev_send_time /* Time */); //has valid time right now.
         end else begin
           send_prev_data(0,SPP,1 /* Has time */,0 /* EOB */, prev_send_time /* Time */); //has valid time right now.
           send_prev_data(1,SPP,1 /* Has time */,0 /* EOB */, prev_send_time /* Time */); //has valid time right now.
           send_prev_data(2,SPP,1 /* Has time */,0 /* EOB */, prev_send_time /* Time */); //has valid time right now.
           send_prev_data(3,SPP,1 /* Has time */,0 /* EOB */, prev_send_time /* Time */); //has valid time right now.
           send_prev_data(4,SPP,1 /* Has time */,0 /* EOB */, prev_send_time /* Time */); //has valid time right now.
         end
       end
       #(5*RADIO_CLK_PERIOD*SPP);
       @(negedge ce_clk);
       // Check first RX packet to make sure it has not been corrupted
       // Check overflow packet
       $display("Check overfow response.");
       check_radio_resp(0,1,1,noc_block_radio_core_eiscat.rx_control_eiscat_inst.ERR_OVERRUN);  
       
       //this is actually cleared out in the fpga itself. All data after that overrun packet is trashed in uhd anyway.
       $display("Send some data and it should just disappear into oblivion.");
       send_prev_data(0,SPP,1 /* Has time */,0 /* EOB */, prev_send_time /* Time */); //has valid time right now.
       send_prev_data(1,SPP,1 /* Has time */,0 /* EOB */, prev_send_time /* Time */); //has valid time right now.
       send_prev_data(2,SPP,1 /* Has time */,0 /* EOB */, prev_send_time /* Time */); //has valid time right now.
       send_prev_data(3,SPP,1 /* Has time */,0 /* EOB */, prev_send_time /* Time */); //has valid time right now.
       send_prev_data(4,SPP,1 /* Has time */,0 /* EOB */, prev_send_time /* Time */); //has valid time right now.
       // Clear out remaining RX packets
       flush_rx(0);
       flush_rx(1);
       flush_rx(2);
       flush_rx(3);
       flush_rx(4);
       $display("Check other error responses.");
       check_radio_resp(0,1,1,64'h0000002000000000);  
       check_radio_resp(1,1,1,64'h0000002000000000);  
       check_radio_resp(2,1,1,64'h0000002000000000);  
       check_radio_resp(3,1,1,64'h0000002000000000);  
       check_radio_resp(4,1,1,64'h0000002000000000);  
       $display("restart radio with normal operation and get 1 packet");
       tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_COMMAND, 
       {1'b0 /* Start immediately */, 1'b1 /* chain */, 1'b1 /* reload */, 1'b0 /* Stop */, SPP1 /*numlines*/ }, 0);
       tb_streamer.read_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.RB_VITA_TIME, vita_time_now, 0);
       tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_TIME_LO, {vita_time_now[31:0]+32'h0500}, 0); //how we store a command.    
       prev_send_time = {vita_time_now+64'h0502};
       #(1*RADIO_CLK_PERIOD*SPP); //wait a bit for stream command to trigger.
       send_prev_data(0,SPP,1 /* Has time */,1 /* EOB */, prev_send_time /* Time */); //has valid time right now.
       send_prev_data(1,SPP,1 /* Has time */,1 /* EOB */, prev_send_time /* Time */); //has valid time right now.
       send_prev_data(2,SPP,1 /* Has time */,1 /* EOB */, prev_send_time /* Time */); //has valid time right now.
       send_prev_data(3,SPP,1 /* Has time */,1 /* EOB */, prev_send_time /* Time */); //has valid time right now.
       send_prev_data(4,SPP,1 /* Has time */,1 /* EOB */, prev_send_time /* Time */); //has valid time right now.
       check_rx(0);
       check_rx(1);
       check_rx(2);
       check_rx(3);
       check_rx(4);
       $display("STOP radio with cmd packet.");
       tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_COMMAND, 
       {1'b0 /* Start immediately */, 1'b0 /* chain */, 1'b0 /* reload */, 1'b1 /* Stop */, SPP1 /*numlines*/ }, 0);
       tb_streamer.read_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.RB_VITA_TIME, vita_time_now, 0);
       tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_TIME_LO, {vita_time_now[31:0]+32'h0500}, 0); //how we store a command.       
 
       `TEST_CASE_DONE(1); 
       $display("Wait a while to let things clear.");       
       #(5*RADIO_CLK_PERIOD*SPP); //wait a bit for stream command to trigger.

 
//       /********************************************************
//       ** Test 13b (14) -- Create overflow condition WITH aurora multi channel and prev AGAIN
//       ********************************************************/
       `TEST_CASE_START("Test overflow with Aurora neighbor and Prev.");
       tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_PREV_OR_NULL, 1'b1); //use null
       tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_BEAMS_TO_NEIGHBOR, 4'b1100); //use counter and neighbors
       tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_STREAM_ENABLE, 10'h3ff); //only enable streams 0-3
       tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_MAXLEN, SPP); //set max length
       tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_OUTPUT_FORMAT, 1'b1); //use timestamps
       tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_COMMAND, 
        {1'b0 /* Start immediately */, 1'b1 /* chain */, 1'b1 /* reload */, 1'b0 /* Stop */, 1 /*numlines*/ }, 0);
       tb_streamer.read_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.RB_VITA_TIME, vita_time_now, 0);
       tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_TIME_LO, {vita_time_now[31:0]+32'h0500}, 0); //how we store a command.
 
       $display("Generate data to force an overflow with aurora then wait.");
       $display("... While waiting, send prev data with matching timestamps.");
       #(1*RADIO_CLK_PERIOD*SPP); //wait a bit for stream command to trigger.
       prev_send_time = {vita_time_now+64'h0502};
       send_prev_data(0,SPP,1 /* Has time */,0 /* EOB */, prev_send_time /* Time */); //has valid time right now.
       send_prev_data(1,SPP,1 /* Has time */,0 /* EOB */, prev_send_time /* Time */); //has valid time right now.
       send_prev_data(2,SPP,1 /* Has time */,0 /* EOB */, prev_send_time /* Time */); //has valid time right now.
       send_prev_data(3,SPP,1 /* Has time */,0 /* EOB */, prev_send_time /* Time */); //has valid time right now.
       send_prev_data(4,SPP,1 /* Has time */,0 /* EOB */, prev_send_time /* Time */); //has valid time right now.
       for(int p = 0; p < 10; p++) begin
         prev_send_time = 64'h1F30 + prev_send_time;
         $display("Sending prev beams set %0d", p);
         if(p == 9) begin
           send_prev_data(0,SPP,1 /* Has time */,1 /* EOB */, prev_send_time /* Time */); //has valid time right now.
           send_prev_data(1,SPP,1 /* Has time */,1 /* EOB */, prev_send_time /* Time */); //has valid time right now.
           send_prev_data(2,SPP,1 /* Has time */,1 /* EOB */, prev_send_time /* Time */); //has valid time right now.
           send_prev_data(3,SPP,1 /* Has time */,1 /* EOB */, prev_send_time /* Time */); //has valid time right now.
           send_prev_data(4,SPP,1 /* Has time */,1 /* EOB */, prev_send_time /* Time */); //has valid time right now.
         end else begin
           send_prev_data(0,SPP,1 /* Has time */,0 /* EOB */, prev_send_time /* Time */); //has valid time right now.
           send_prev_data(1,SPP,1 /* Has time */,0 /* EOB */, prev_send_time /* Time */); //has valid time right now.
           send_prev_data(2,SPP,1 /* Has time */,0 /* EOB */, prev_send_time /* Time */); //has valid time right now.
           send_prev_data(3,SPP,1 /* Has time */,0 /* EOB */, prev_send_time /* Time */); //has valid time right now.
           send_prev_data(4,SPP,1 /* Has time */,0 /* EOB */, prev_send_time /* Time */); //has valid time right now.
         end
       end
       #(5*RADIO_CLK_PERIOD*SPP);
       @(negedge ce_clk);
       // Check first RX packet to make sure it has not been corrupted
       // Check overflow packet
       $display("Check overfow response.");
       check_radio_resp(0,1,1,noc_block_radio_core_eiscat_0.rx_control_eiscat_inst.ERR_OVERRUN);  
       //this is actually cleared out in the fpga itself. All data after that overrun packet is trashed in uhd anyway.
       $display("Send some data and it should just disappear into oblivion.");
       send_prev_data(0,SPP,1 /* Has time */,0 /* EOB */, prev_send_time /* Time */); //has valid time right now.
       send_prev_data(1,SPP,1 /* Has time */,0 /* EOB */, prev_send_time /* Time */); //has valid time right now.
       send_prev_data(2,SPP,1 /* Has time */,0 /* EOB */, prev_send_time /* Time */); //has valid time right now.
       send_prev_data(3,SPP,1 /* Has time */,0 /* EOB */, prev_send_time /* Time */); //has valid time right now.
       send_prev_data(4,SPP,1 /* Has time */,0 /* EOB */, prev_send_time /* Time */); //has valid time right now.
       // Clear out remaining RX packets
       flush_rx(0);
       flush_rx(1);
       flush_rx(2);
       flush_rx(3);
       flush_rx(4);
       $display("restart radio with normal operation and get 1 packet");
       tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_COMMAND, 
       {1'b0 /* Start immediately */, 1'b1 /* chain */, 1'b1 /* reload */, 1'b0 /* Stop */, SPP1 /*numlines*/ }, 0);
       tb_streamer.read_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.RB_VITA_TIME, vita_time_now, 0);
       tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_TIME_LO, {vita_time_now[31:0]+32'h0500}, 0); //how we store a command.      
       prev_send_time = {vita_time_now+64'h0502};
       #(1*RADIO_CLK_PERIOD*SPP); //wait a bit for stream command to trigger.
       send_prev_data(0,SPP,1 /* Has time */,1 /* EOB */, prev_send_time /* Time */); //has valid time right now.
       send_prev_data(1,SPP,1 /* Has time */,1 /* EOB */, prev_send_time /* Time */); //has valid time right now.
       send_prev_data(2,SPP,1 /* Has time */,1 /* EOB */, prev_send_time /* Time */); //has valid time right now.
       send_prev_data(3,SPP,1 /* Has time */,1 /* EOB */, prev_send_time /* Time */); //has valid time right now.
       send_prev_data(4,SPP,1 /* Has time */,1 /* EOB */, prev_send_time /* Time */); //has valid time right now.
       check_rx(0);
       check_rx(1);
       check_rx(2);
       check_rx(3);
       check_rx(4);
       tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_COMMAND, 
       {1'b0 /* Start immediately */, 1'b0 /* chain */, 1'b0 /* reload */, 1'b1 /* Stop */, SPP1 /*numlines*/ }, 0);
       tb_streamer.read_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.RB_VITA_TIME, vita_time_now, 0);
       tb_streamer.write_user_reg(sid_noc_block_radio_core_eiscat_0, noc_block_radio_core_eiscat_0.SR_RX_CTRL_TIME_LO, {vita_time_now[31:0]+32'h0500}, 0); //how we store a command.       
       // Clear out remaining RX packets
       `TEST_CASE_DONE(1); 
       //after test case, wait a bit...


    `TEST_BENCH_DONE;

  end
endmodule
