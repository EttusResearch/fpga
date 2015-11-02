//
// Copyright 2015 Ettus Research
//
// radio_core
//   Contains all clock-rate DSP components, all radio and hardware controls and settings
//   Designed to connect to a noc_shell

module radio_core #(
  parameter BASE = 0,
  parameter RADIO_NUM = 0
)(
  input clk, input reset,
  input [15:0] src_sid,             // Source stream ID of this block
  input [15:0] dst_sid,             // Destination stream ID destination of downstream block
  input [15:0] resp_dst_sid,        // Destination stream ID for error / response packets (i.e. host PC)
  // Interface to the physical radio (ADC, DAC, controls)
  input [31:0] rx, input rx_stb,
  output [31:0] tx, input tx_stb,
  // Interfaces to front panel and daughter board
  input pps,
  input [31:0] misc_ins, output [31:0] misc_outs, output sync,
  inout [31:0] fp_gpio, inout [31:0] db_gpio, output [31:0] leds,
  output [7:0] sen, output sclk, output mosi, input miso,
  // Interface to the NoC Shell
  input set_stb, input [7:0] set_addr, input [31:0] set_data, input [63:0] set_time, input [7:0] rb_addr, output reg [63:0] rb_data,
  input [31:0] tx_tdata, input tx_tlast, input tx_tvalid, output tx_tready, input [127:0] tx_tuser,
  output [31:0] rx_tdata, output rx_tlast, output rx_tvalid, input rx_tready, output [127:0] rx_tuser,
  output [63:0] resp_tdata, output resp_tlast, output resp_tvalid, input resp_tready
);

  /********************************************************
  ** Settings Bus Register Addresses
  ********************************************************/
  localparam SR_TIME_HI              = BASE + 8'd0;
  localparam SR_TIME_LO              = BASE + 8'd1;
  localparam SR_TIME_CTRL            = BASE + 8'd2;
  localparam SR_LOOPBACK             = BASE + 8'd3;
  localparam SR_TEST                 = BASE + 8'd4;
  localparam SR_CODEC_IDLE           = BASE + 8'd5;
  // TX / RX Control
  localparam SR_TX_CTRL_ERROR_POLICY = BASE + 8'd32;
  localparam SR_RX_CTRL_COMMAND      = BASE + 8'd48;
  localparam SR_RX_CTRL_TIME_HI      = BASE + 8'd49;
  localparam SR_RX_CTRL_TIME_LO      = BASE + 8'd50;
  localparam SR_RX_CTRL_HALT         = BASE + 8'd51;
  localparam SR_RX_CTRL_MAXLEN       = BASE + 8'd52;
  localparam SR_DB_CONTROL_BASE      = BASE + 8'd64;  // 64 - 127 Reserved for db control

  localparam RB_VITA_TIME            = 8'd0;
  localparam RB_VITA_LASTPPS         = 8'd1;
  localparam RB_RX                   = 8'd2;
  localparam RB_TXRX                 = 8'd3;
  localparam RB_RADIO_NUM            = 8'd4;
  localparam RB_DB_CONTROL_BASE      = 8'd16; // 16 - 32 reserved for db control

  /********************************************************
  ** Settings Bus / Readback Registers
  ********************************************************/
  wire [63:0] vita_time, vita_time_lastpps;
  wire        loopback;
  wire [31:0] test_readback;
  wire [63:0] db_rb_data;
  always @(posedge clk) begin
    if (reset) begin
      rb_data <= 64'd0;
    end else begin
      case (rb_addr)
        RB_VITA_TIME    : rb_data <= vita_time;
        RB_VITA_LASTPPS : rb_data <= vita_time_lastpps;
        RB_RX           : rb_data <= {rx, test_readback};
        RB_TXRX         : rb_data <= {tx, rx};
        RB_RADIO_NUM    : rb_data <= {32'd0, RADIO_NUM[31:0]};
        // All others default to daughter board control readback data
        default         : rb_data <= db_rb_data;
      endcase
    end
  end

  // Set this register to loop TX data directly to RX data.
  setting_reg #(.my_addr(SR_LOOPBACK), .width(1)) sr_loopback (
    .clk(clk), .rst(reset), .strobe(set_stb), .addr(set_addr), .in(set_data),
    .out(loopback), .changed());

  // Set this register to put a test value on the readback mux.
  setting_reg #(.my_addr(SR_TEST), .width(32)) sr_test (
    .clk(clk), .rst(reset), .strobe(set_stb), .addr(set_addr), .in(set_data),
    .out(test_readback), .changed());

  /********************************************************
  ** VITA Time
  ********************************************************/
  timekeeper #(
    .SR_TIME_HI(SR_TIME_HI),
    .SR_TIME_LO(SR_TIME_LO),
    .SR_TIME_CTRL(SR_TIME_CTRL))
  timekeeper (
    .clk(clk), .reset(reset), .pps(pps),
    .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
    .vita_time(vita_time), .vita_time_lastpps(vita_time_lastpps));

  /********************************************************
  ** Daughter board control
  ********************************************************/
  db_control #(.SR_BASE(SR_DB_CONTROL_BASE), .RB_BASE(RB_DB_CONTROL_BASE)) db_control (
    .clk(clk), .reset(reset),
    .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data), .set_time(set_time),
    .rb_addr(rb_addr), .rb_data(db_rb_data),
    .vita_time(vita_time), .run_rx(run_rx), .run_tx(run_tx),
    .misc_ins(misc_ins), .misc_outs(misc_outs), .sync(sync),
    .fp_gpio(fp_gpio), .db_gpio(db_gpio),
    .leds(leds),
    .sen(sen), .sclk(sclk), .mosi(mosi), .miso(miso));

  /********************************************************
  ** TX Chain
  ********************************************************/
  wire [31:0] tx_idle;
  setting_reg #(.my_addr(SR_CODEC_IDLE), .awidth(8), .width(32)) sr_codec_idle (
    .clk(clk), .rst(reset), .strobe(set_stb), .addr(set_addr), .in(set_data),
    .out(tx_idle), .changed());

  wire [31:0] sample_tx;
  wire [63:0] txresp_tdata;
  wire [127:0] txresp_tuser;
  wire txresp_tlast, txresp_tvalid, txresp_tready;
  tx_control_gen3 #(.SR_ERROR_POLICY(SR_TX_CTRL_ERROR_POLICY)) tx_control_gen3 (
    .clk(clk), .reset(reset), .clear(1'b0),
    .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
    .vita_time(vita_time), .resp_sid({src_sid, resp_dst_sid}),
    .tx_tdata(tx_tdata), .tx_tlast(tx_tlast), .tx_tvalid(tx_tvalid), .tx_tready(tx_tready), .tx_tuser(tx_tuser),
    .resp_tdata(txresp_tdata), .resp_tlast(txresp_tlast), .resp_tvalid(txresp_tvalid), .resp_tready(txresp_tready), .resp_tuser(txresp_tuser),
    .run(run_tx), .sample(sample_tx), .strobe(tx_stb));

  assign tx = run_tx ? sample_tx : tx_idle;

  /********************************************************
  ** RX Chain
  ********************************************************/
  wire [31:0] sample_rx     = loopback ? tx     : rx;     // Digital Loopback TX -> RX
  wire        sample_rx_stb = loopback ? tx_stb : rx_stb;

  wire [63:0] rxresp_tdata;
  wire [127:0] rxresp_tuser;
  wire rxresp_tlast, rxresp_tvalid, rxresp_tready;
  rx_control_gen3 #(
    .SR_RX_CTRL_COMMAND(SR_RX_CTRL_COMMAND),
    .SR_RX_CTRL_TIME_HI(SR_RX_CTRL_TIME_HI),
    .SR_RX_CTRL_TIME_LO(SR_RX_CTRL_TIME_LO),
    .SR_RX_CTRL_HALT(SR_RX_CTRL_HALT),
    .SR_RX_CTRL_MAXLEN(SR_RX_CTRL_MAXLEN))
  rx_control_gen3 (
    .clk(clk), .reset(reset), .clear(1'b0),
    .vita_time(vita_time), .sid({src_sid, dst_sid}), .resp_sid({src_sid, resp_dst_sid}),
    .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
    .rx_tdata(rx_tdata), .rx_tlast(rx_tlast), .rx_tvalid(rx_tvalid), .rx_tready(rx_tready), .rx_tuser(rx_tuser),
    .resp_tdata(rxresp_tdata), .resp_tlast(rxresp_tlast), .resp_tvalid(rxresp_tvalid), .resp_tready(rxresp_tready), .resp_tuser(rxresp_tuser),
    .strobe(sample_rx_stb), .sample(sample_rx), .run(run_rx));

  // Generate error response packets from TX & RX control
  axi_packet_mux #(.NUM_INPUTS(2), .FIFO_SIZE(5)) axi_packet_mux (
    .clk(clk), .reset(reset), .clear(1'b0),
    .i_tdata({txresp_tdata, rxresp_tdata}), .i_tlast({txresp_tlast, rxresp_tlast}),
    .i_tvalid({txresp_tvalid, rxresp_tvalid}), .i_tready({txresp_tready, rxresp_tready}), .i_tuser({txresp_tuser, rxresp_tuser}),
    .o_tdata(resp_tdata), .o_tlast(resp_tlast), .o_tvalid(resp_tvalid), .o_tready(resp_tready));

endmodule