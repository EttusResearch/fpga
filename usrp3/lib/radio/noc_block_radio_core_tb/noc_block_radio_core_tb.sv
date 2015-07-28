//
// Copyright 2015 Ettus Research LLC
//
`timescale 1ns/1ps
`define SIM_RUNTIME_US 1000
`define NS_PER_TICK 1
`define NUM_TEST_CASES 2

`include "sim_exec_report.vh"
`include "sim_rfnoc_lib.vh"

module noc_block_radio_core_tb();
  `TEST_BENCH_INIT("noc_block_fft_tb",`NUM_TEST_CASES,`NS_PER_TICK);
  // Creates clocks (bus_clk, ce_clk), resets (bus_rst, ce_rst), 
  // AXI crossbar, and Export IO RFNoC block instance.
  // Export IO is a special RFNoC block used to expose the internal 
  // NoC Shell / AXI wrapper interfaces to the test bench.
  `RFNOC_SIM_INIT(1,166.67,200);
  // Instantiate & connect FFT RFNoC block

  `DEFINE_CLK(radio_clk, 61.44, 50);
  `DEFINE_RESET(radio_rst, 0, 1000);
  localparam [15:0] sid_noc_block_radio_core = {xbar_addr,4'd0,4'd0};
  reg rx_stb, tx_stb;
  reg [63:0] rx, tx;
  reg pps;
  wire [63:0] vita_time;
  wire [1:0] run_rx, run_tx;
  wire fe_set_stb;
  wire [7:0] fe_set_addr;
  wire [31:0] fe_set_data;
  wire [63:0] fe_set_vita, fe_rb_data;
  noc_block_radio_core #(
    .NUM_RADIOS(2),
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
    .fe_set_stb(fe_set_stb), .fe_set_addr(fe_set_addr), .fe_set_data(fe_set_data), .fe_set_vita(fe_set_vita), .fe_rb_data(fe_rb_data),
    .debug());

  wire [31:0] misc_outs, fp_gpio, db0_gpio, db1_gpio;
  wire [2:0] leds0, leds1;
  wire sen, sclk, mosi;
  wire miso = 1'b1;
  e3x0_db_control #(
    .SR_BUS_CLK_SPI(64),
    .BASE(128))
  e3x0_db_control (
    .radio_clk(radio_clk), .radio_rst(radio_rst),
    .fe_set_stb(fe_set_stb), .fe_set_addr(fe_set_addr), .fe_set_data(fe_set_data), .fe_set_vita(fe_set_vita), .fe_rb_data(fe_rb_data),
    .vita_time(vita_time), .run_rx(run_rx), .run_tx(run_tx),
    .bus_clk(bus_clk), .bus_rst(bus_rst),
    .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data), .rb_data(rb_data),
    
    .misc_outs(misc_outs), .sync(),
    .fp_gpio(fp_gpio), .db0_gpio(db0_gpio), .db1_gpio(db1_gpio),
    .leds0(leds0), .leds1(leds1),
    .sen(sen), .sclk(sclk), .mosi(mosi), .miso(miso));

  cvita_pkt_t  pkt;
  logic [63:0] header;
  logic last;
  logic [15:0] real_val, cplx_val;
  cvita_pkt_t response;

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

  initial begin : tb_main
      `TEST_CASE_START("Wait for reset");
    while (bus_rst) @(posedge bus_clk);
    while (ce_rst) @(posedge ce_clk);
    `TEST_CASE_DONE(~bus_rst & ~ce_rst);

    forever begin
      tb_axis_data.pull_word({real_val,cplx_val},last);
    end
  end

  initial begin
    `RFNOC_CONNECT(noc_block_tb,noc_block_radio_core,1024);
    `RFNOC_CONNECT(noc_block_radio_core,noc_block_tb,1024);

    header = flatten_chdr_no_ts('{pkt_type:CMD, has_time:0, eob:0, seqno:12'h0, length:8, sid:sid_noc_block_radio_core, timestamp:64'h0});
    tb_cvita_cmd.push_pkt({header, {32'd0, 32'hDEADBEEF}});
    tb_cvita_ack.pull_pkt(response);

    tb_cvita_cmd.push_pkt({header, {32'd255, 32'd3}});
    tb_cvita_ack.pull_pkt(response);
    $display("reponse: %d",response[1]);

    repeat (10) @(posedge bus_clk);

    forever begin
      tb_next_dst = sid_noc_block_radio_core;
      for (int i = 0; i < PKT_SIZE; i = i + 1) begin
        tb_axis_data.push_word(sine_wave_1_8th[i],(i == (PKT_SIZE-1))); 
      end
    end
  end

  integer k,l;
  initial begin
    k = 0;
    l = 3;
    rx_stb = 1'b0;
    tx_stb = 1'b0;
    forever begin
      rx[31:0]  = sine_wave_1_8th[k];
      rx[63:32] = sine_wave_1_8th[l];
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
      rx_stb = 1'b1;
      tx_stb = 1'b1;
      @(posedge radio_clk);
      rx_stb = 1'b0;
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