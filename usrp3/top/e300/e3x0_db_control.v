//
// Copyright 2015 Ettus Research LLC
//

module e3x0_db_control #(
  parameter SR_BUS_CLK_SPI = 64,
  parameter BASE = 128)
(
  // Commands from Radio Core
  input radio_clk, input radio_rst,
  input fe_set_stb, input [7:0] fe_set_addr, input [31:0] fe_set_data, input [63:0] fe_set_vita, output reg [63:0] fe_rb_data,
  input [63:0] vita_time, input [1:0] run_rx, input [1:0] run_tx,
  // SPI commands for initialization only
  input bus_clk, input bus_rst,
  input set_stb, input [7:0] set_addr, input [31:0] set_data, output [31:0] rb_data,
  // Frontend / Daughterboard I/O
  output [31:0] misc_outs, output sync,
  inout [31:0] fp_gpio, output [31:0] db0_gpio, output [31:0] db1_gpio,
  output [2:0] leds0, output [2:0] leds1,
  output [7:0] sen, output sclk, output mosi, input miso
);
  /********************************************************
  ** Settings Bus Register Addresses
  ********************************************************/
  localparam SR_MISC_OUTS            = BASE + 8'd0;
  localparam SR_SYNC                 = BASE + 8'd1;
  localparam SR_FP_GPIO              = BASE + 8'd32; // 32-36
  localparam SR_LEDS0                = BASE + 8'd37; // 37-41
  localparam SR_LEDS1                = BASE + 8'd42; // 42-46
  localparam SR_DB0_GPIO             = BASE + 8'd47; // 47-51
  localparam SR_DB1_GPIO             = BASE + 8'd52; // 52-56
  localparam SR_SPI                  = BASE + 8'd64; // 64-66
  localparam SR_READBACK             = BASE + 8'd127;

  localparam RB_SPI                  = 3'd0;
  localparam RB_FP_GPIO              = 3'd1;

  /********************************************************
  ** Settings registers, GPIO, etc...
  ********************************************************/
  // Gate settings bus transactions based on VITA time
  wire set_stb_timed;
  wire [7:0] set_addr_timed;
  wire [31:0] set_data_timed;
  wire ready;
  settings_bus_timed_fifo settings_bus_timed_fifo (
    .clk(radio_clk), .rst(radio_rst),
    .vita_time(vita_time),
    .set_stb(fe_set_stb), .set_addr(fe_set_addr), .set_data(fe_set_data), .set_vita(fe_set_vita),
    .set_stb_timed(set_stb_timed), .set_addr_timed(set_addr_timed), .set_data_timed(set_data_timed), .ready(ready));

  setting_reg #(.my_addr(SR_MISC_OUTS), .width(32)) sr_misc_outs (
    .clk(clk), .rst(rst),
    .strobe(set_stb_timed), .addr(set_addr_timed), .in(set_data_timed),
    .out(misc_outs), .changed());

  setting_reg #(.my_addr(SR_SYNC), .width(1)) sr_sync (
    .clk(clk), .rst(rst),
    .strobe(set_stb_timed), .addr(set_addr_timed), .in(set_data_timed),
    .out(), .changed(sync_dacs));

  wire [31:0] rb_addr;
  setting_reg #(.my_addr(SR_READBACK), .width(32)) sr_readback (
    .clk(clk), .rst(rst),
    .strobe(set_stb_timed), .addr(set_addr_timed), .in(set_data_timed),
    .out(rb_addr), .changed());

  gpio_atr #(.BASE(SR_DB0_GPIO), .WIDTH(32)) db0_gpio_atr (
    .clk(radio_clk),.reset(radio_rst),
    .set_stb(set_stb_timed),.set_addr(set_addr_timed),.set_data(set_data_timed),
    .rx(run_rx[0]), .tx(run_tx[0]),
    .gpio(db0_gpio), .gpio_readback(gpio_readback));

  gpio_atr #(.BASE(SR_DB1_GPIO), .WIDTH(32)) db1_gpio_atr (
    .clk(radio_clk),.reset(radio_rst),
    .set_stb(set_stb_timed),.set_addr(set_addr_timed),.set_data(set_data_timed),
    .rx(run_rx[1]), .tx(run_tx[1]),
    .gpio(db1_gpio), .gpio_readback(gpio_readback));

  gpio_atr #(.BASE(SR_LEDS0), .WIDTH(3), .default_ddr(3'b111), .default_idle(3'b000)) leds0_gpio_atr (
    .clk(radio_clk),.reset(radio_rst),
    .set_stb(set_stb_timed),.set_addr(set_addr_timed),.set_data(set_data_timed),
    .rx(run_rx[0]), .tx(run_tx[0]),
    .gpio(leds0), .gpio_readback());

  gpio_atr #(.BASE(SR_LEDS1), .WIDTH(3), .default_ddr(3'b111), .default_idle(3'b000)) leds1_gpio_atr (
    .clk(radio_clk),.reset(radio_rst),
    .set_stb(set_stb_timed),.set_addr(set_addr_timed),.set_data(set_data_timed),
    .rx(run_rx[1]), .tx(run_tx[1]),
    .gpio(leds1), .gpio_readback());

  wire [31:0] fp_gpio_readback;
  gpio_atr #(.BASE(SR_FP_GPIO), .WIDTH(32)) fp_gpio_atr (
    .clk(radio_clk),.reset(radio_rst),
    .set_stb(set_stb_timed),.set_addr(set_addr_timed),.set_data(set_data_timed),
    .rx(run_rx), .tx(run_tx),
    .gpio(fp_gpio), .gpio_readback(fp_gpio_readback));

  wire [31:0] spi_readback;
  always @(posedge radio_clk) begin
    if (radio_rst) begin
      fe_rb_data <= 64'd0;
    end else begin
      case(rb_addr)
        RB_SPI      : fe_rb_data <= {32'd0,spi_readback};
        RB_FP_GPIO  : fe_rb_data <= {32'd0,fp_gpio_readback};
        default     : fe_rb_data <= 64'd0;
      endcase
    end
  end

  /********************************************************
  ** Mux SPIs
  ** One SPI core per clock (bus_clk, radio_clk)
  ** - Need bus_clk SPI for initial setup after power on
  ** - Need radio_clk SPI for timed commands
  ********************************************************/
  wire [1:0] sen_int, sclk_int, mosi_int;
  // Radio clock
  simple_spi_core #(.BASE(SR_SPI), .WIDTH(8), .CLK_IDLE(0), .SEN_IDLE(8'hFF)) radio_clk_spi (
    .clock(radio_clk), .reset(radio_rst),
    .set_stb(set_stb_timed), .set_addr(set_addr_timed), .set_data(set_data_timed),
    .readback(spi_readback), .ready(spi_ready),
    .sen(sen_int[0]), .sclk(sclk_int[0]), .mosi(mosi_int[0]), .miso(miso),
    .debug());
  // Bus clock
  simple_spi_core #(.BASE(SR_BUS_CLK_SPI), .WIDTH(8), .CLK_IDLE(0), .SEN_IDLE(8'hFF)) bus_clk_spi (
    .clock(bus_clk), .reset(bus_rst),
    .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
    .readback(rb_data), .ready(),
    .sen(sen_int[1]), .sclk(sclk_int[1]), .mosi(mosi_int[1]), .miso(miso),
    .debug());

  assign sen  = (~spi_ready) ? sen_int[0]  : sen_int[1];
  assign sclk = (~spi_ready) ? sclk_int[0] : sclk_int[1];
  assign mosi = (~spi_ready) ? mosi_int[0] : sclk_int[1];

endmodule