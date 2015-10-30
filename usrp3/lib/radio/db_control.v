//
// Copyright 2015 Ettus Research LLC
//

module db_control #(
  parameter SR_BASE = 0,
  parameter RB_BASE = 0)
(
  // Commands from Radio Core
  input clk, input reset,
  input set_stb, input [7:0] set_addr, input [31:0] set_data, input [63:0] set_time, input [7:0] rb_addr, output reg [63:0] rb_data,
  input [63:0] vita_time, input run_rx, input run_tx,
  // Frontend / Daughterboard I/O
  input [31:0] misc_ins, output [31:0] misc_outs, output sync,
  inout [31:0] fp_gpio, inout [31:0] db_gpio, output [31:0] leds,
  output [7:0] sen, output sclk, output mosi, input miso
);
  /********************************************************
  ** Settings Bus Register Addresses
  ********************************************************/
  // Note: Only use addrs 0-63, as others are used in radio core
  localparam SR_MISC_OUTS  = SR_BASE + 8'd0;
  localparam SR_SYNC       = SR_BASE + 8'd1;
  localparam SR_CLEAR_FIFO = SR_BASE + 8'd2;
  localparam SR_SPI        = SR_BASE + 8'd16; // 16-18
  localparam SR_LEDS       = SR_BASE + 8'd24; // 24
  localparam SR_FP_GPIO    = SR_BASE + 8'd32; // 32-37
  localparam SR_DB_GPIO    = SR_BASE + 8'd48; // 48-53
  // Only use addrs 0-15
  localparam RB_MISC_IO    = RB_BASE + 8'd0;
  localparam RB_SPI        = RB_BASE + 8'd1;
  localparam RB_LEDS       = RB_BASE + 8'd2;
  localparam RB_DB_GPIO    = RB_BASE + 8'd3;
  localparam RB_FP_GPIO    = RB_BASE + 8'd4;

  /********************************************************
  ** Settings registers
  ********************************************************/
  // Gate settings bus transactions based on VITA time
  wire set_stb_timed;
  wire [7:0] set_addr_timed;
  wire [31:0] set_data_timed;
  wire spi_ready, clear_fifo;
  settings_bus_timed_fifo #(.BASE(SR_BASE), .RANGE(64))
  settings_bus_timed_fifo (
    .clk(clk), .reset(reset | clear_fifo),
    .vita_time(vita_time),
    .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data), .set_time(set_time),
    .set_stb_timed(set_stb_timed), .set_addr_timed(set_addr_timed), .set_data_timed(set_data_timed), .ready(spi_ready));

  setting_reg #(.my_addr(SR_MISC_OUTS), .width(32)) sr_misc_outs (
    .clk(clk), .rst(reset),
    .strobe(set_stb_timed), .addr(set_addr_timed), .in(set_data_timed),
    .out(misc_outs), .changed());

  setting_reg #(.my_addr(SR_SYNC), .width(1)) sr_sync (
    .clk(clk), .rst(reset),
    .strobe(set_stb_timed), .addr(set_addr_timed), .in(set_data_timed),
    .out(), .changed(sync));

  setting_reg #(.my_addr(SR_LEDS), .width(32)) sr_leds (
    .clk(clk), .rst(reset),
    .strobe(set_stb_timed), .addr(set_addr_timed), .in(set_data_timed),
    .out(leds), .changed());

  setting_reg #(.my_addr(SR_CLEAR_FIFO), .width(1)) sr_clear (
    .clk(clk), .rst(reset),
    .strobe(set_stb_timed), .addr(set_addr_timed), .in(set_data_timed),
    .out(), .changed(clear_fifo));

  // Readback
  wire [7:0] spi_readback;
  wire [31:0] fp_gpio_readback, db_gpio_readback, leds_readback;
  always @* begin
    case(rb_addr)
      RB_MISC_IO  : rb_data <= {misc_ins, misc_outs};
      RB_SPI      : rb_data <= {31'd0, spi_ready, 24'd0, spi_readback};
      RB_LEDS     : rb_data <= {32'd0, leds};
      RB_DB_GPIO  : rb_data <= {32'd0, db_gpio_readback};
      RB_FP_GPIO  : rb_data <= {32'd0, fp_gpio_readback};
      default     : rb_data <= 64'h0BADC0DE0BADC0DE;
    endcase
  end

  /********************************************************
  ** GPIO
  ********************************************************/
  gpio_atr #(.BASE(SR_FP_GPIO), .WIDTH(32), .default_ddr(32'hFFFF_FFFF), .default_idle(32'd0)) fp_gpio_atr (
    .clk(clk), .reset(reset),
    .set_stb(set_stb_timed), .set_addr(set_addr_timed), .set_data(set_data_timed),
    .rx(run_rx), .tx(run_tx),
    .gpio(fp_gpio), .gpio_readback(fp_gpio_readback));

  gpio_atr #(.BASE(SR_DB_GPIO), .WIDTH(32), .default_ddr(32'hFFFF_FFFF), .default_idle(32'd0)) db_gpio_atr (
    .clk(clk), .reset(reset),
    .set_stb(set_stb_timed), .set_addr(set_addr_timed), .set_data(set_data_timed),
    .rx(run_rx), .tx(run_tx),
    .gpio(db_gpio), .gpio_readback(db_gpio_readback));

  /********************************************************
  ** SPI
  ********************************************************/
  simple_spi_core #(.BASE(SR_SPI), .WIDTH(8), .CLK_IDLE(0), .SEN_IDLE(8'hFF)) simple_spi_core (
    .clock(clk), .reset(reset),
    .set_stb(set_stb_timed), .set_addr(set_addr_timed), .set_data(set_data_timed),
    .readback(spi_readback), .ready(spi_ready),
    .sen(sen), .sclk(sclk), .mosi(mosi), .miso(miso),
    .debug());

endmodule