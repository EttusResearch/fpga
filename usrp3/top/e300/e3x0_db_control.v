//
// Copyright 2015 Ettus Research LLC
//

module e3x0_db_control #(
  parameter SR_BASE_BCLK = 64,
  parameter RB_BASE_BCLK = 6,
  parameter SR_BASE_RCLK = 128,
  parameter RB_BASE_RCLK = 1)
(
  // Commands from Radio Core
  input radio_clk, input radio_rst,
  input set_stb_rclk, input [7:0] set_addr_rclk, input [31:0] set_data_rclk, input [63:0] set_time_rclk, input [7:0] rb_addr_rclk, output reg [63:0] rb_data_rclk,
  input [63:0] vita_time, input [1:0] run_rx, input [1:0] run_tx,
  // SPI commands for initialization only
  input bus_clk, input bus_rst,
  input set_stb_bclk, input [7:0] set_addr_bclk, input [31:0] set_data_bclk, input [7:0] rb_addr_bclk, output reg [31:0] rb_data_bclk,
  // Frontend / Daughterboard I/O
  input [31:0] misc_ins, output [31:0] misc_outs, output sync,
  inout [31:0] fp_gpio, output [31:0] db0_gpio, output [31:0] db1_gpio,
  output [2:0] leds0, output [2:0] leds1,
  output [7:0] sen, output sclk, output mosi, input miso
);
  /********************************************************
  ** Settings Bus Register Addresses
  ********************************************************/
  localparam SR_MISC_OUTS_RCLK       = SR_BASE_RCLK + 8'd0;
  localparam SR_SYNC_RCLK            = SR_BASE_RCLK + 8'd1;
  localparam SR_FP_GPIO_RCLK         = SR_BASE_RCLK + 8'd32; // 32-36
  localparam SR_LEDS0_RCLK           = SR_BASE_RCLK + 8'd37; // 37-41
  localparam SR_LEDS1_RCLK           = SR_BASE_RCLK + 8'd42; // 42-46
  localparam SR_DB0_GPIO_RCLK        = SR_BASE_RCLK + 8'd47; // 47-51
  localparam SR_DB1_GPIO_RCLK        = SR_BASE_RCLK + 8'd52; // 52-56
  localparam SR_SPI_RCLK             = SR_BASE_RCLK + 8'd64; // 64-66
  localparam RB_SPI_RCLK             = RB_BASE_RCLK + 8'd0;
  localparam RB_MISC_IO_RCLK         = RB_BASE_RCLK + 8'd1;
  localparam RB_DB_GPIO_RCLK         = RB_BASE_RCLK + 8'd2;
  localparam RB_FP_GPIO_RCLK         = RB_BASE_RCLK + 8'd3;

  localparam SR_SPI_BCLK             = SR_BASE_BCLK + 8'd0;
  localparam SR_SPI_EN_BCLK          = SR_BASE_BCLK + 8'd1;
  localparam RB_SPI_BCLK             = RB_BASE_BCLK + 8'd0;

  /********************************************************
  ** Settings registers, GPIO, etc...
  ********************************************************/
  // Radio clock
  // Gate settings bus transactions based on VITA time
  wire set_stb_rclk_timed;
  wire [7:0] set_addr_rclk_timed;
  wire [31:0] set_data_rclk_timed;
  wire spi_ready_rclk;
  settings_bus_timed_fifo settings_bus_timed_fifo (
    .clk(radio_clk), .rst(radio_rst),
    .vita_time(vita_time),
    .set_stb(set_stb_rclk), .set_addr(set_addr_rclk), .set_data(set_data_rclk), .set_time(set_time_rclk),
    .set_stb_timed(set_stb_rclk_timed), .set_addr_timed(set_addr_rclk_timed), .set_data_timed(set_data_rclk_timed), .ready(spi_ready_rclk));

  setting_reg #(.my_addr(SR_MISC_OUTS_RCLK), .width(32)) sr_misc_outs (
    .clk(radio_clk), .rst(radio_rst),
    .strobe(set_stb_rclk_timed), .addr(set_addr_rclk_timed), .in(set_data_rclk_timed),
    .out(misc_outs), .changed());

  setting_reg #(.my_addr(SR_SYNC_RCLK), .width(1)) sr_sync (
    .clk(radio_clk), .rst(radio_rst),
    .strobe(set_stb_rclk_timed), .addr(set_addr_rclk_timed), .in(set_data_rclk_timed),
    .out(), .changed(sync_dacs));

  wire [31:0] db0_gpio_readback, db1_gpio_readback;
  gpio_atr #(.BASE(SR_DB0_GPIO_RCLK), .WIDTH(32)) db0_gpio_atr (
    .clk(radio_clk), .reset(radio_rst),
    .set_stb(set_stb_rclk_timed), .set_addr(set_addr_rclk_timed), .set_data(set_data_rclk_timed),
    .rx(run_rx[0]), .tx(run_tx[0]),
    .gpio(db0_gpio), .gpio_readback(db0_gpio_readback));

  gpio_atr #(.BASE(SR_DB1_GPIO_RCLK), .WIDTH(32)) db1_gpio_atr (
    .clk(radio_clk), .reset(radio_rst),
    .set_stb(set_stb_rclk_timed), .set_addr(set_addr_rclk_timed), .set_data(set_data_rclk_timed),
    .rx(run_rx[1]), .tx(run_tx[1]),
    .gpio(db1_gpio), .gpio_readback(db1_gpio_readback));

  gpio_atr #(.BASE(SR_LEDS0_RCLK), .WIDTH(3), .default_ddr(3'b111), .default_idle(3'b000)) leds0_gpio_atr (
    .clk(radio_clk), .reset(radio_rst),
    .set_stb(set_stb_rclk_timed), .set_addr(set_addr_rclk_timed), .set_data(set_data_rclk_timed),
    .rx(run_rx[0]), .tx(run_tx[0]),
    .gpio(leds0), .gpio_readback());

  gpio_atr #(.BASE(SR_LEDS1_RCLK), .WIDTH(3), .default_ddr(3'b111), .default_idle(3'b000)) leds1_gpio_atr (
    .clk(radio_clk), .reset(radio_rst),
    .set_stb(set_stb_rclk_timed), .set_addr(set_addr_rclk_timed), .set_data(set_data_rclk_timed),
    .rx(run_rx[1]), .tx(run_tx[1]),
    .gpio(leds1), .gpio_readback());

  wire [31:0] fp_gpio_readback;
  gpio_atr #(.BASE(SR_FP_GPIO_RCLK), .WIDTH(32)) fp_gpio_atr (
    .clk(radio_clk), .reset(radio_rst),
    .set_stb(set_stb_rclk_timed), .set_addr(set_addr_rclk_timed), .set_data(set_data_rclk_timed),
    .rx(|run_rx), .tx(|run_tx),
    .gpio(fp_gpio), .gpio_readback(fp_gpio_readback));

  // Bus clock
  wire spi_en_bclk;
  setting_reg #(.my_addr(SR_SPI_EN_BCLK), .width(1)) sr_spi_en_bclk (
    .clk(bus_clk), .rst(bus_rst),
    .strobe(set_stb_bclk), .addr(set_addr_bclk), .in(set_data_bclk),
    .out(spi_en_bclk), .changed());

  /********************************************************
  ** Readback
  ********************************************************/
  // Bus clock
  wire [31:0] spi_readback_bclk;
  wire spi_ready_bclk;
  always @(posedge bus_clk) begin
    if (bus_rst) begin
      rb_data_bclk <= 64'd0;
    end else begin
      case (rb_addr_bclk)
        RB_SPI_BCLK     : rb_data_bclk <= {30'd0, spi_en_bclk, spi_ready_bclk, spi_readback_bclk};
        default         : rb_data_bclk <= 64'h0BADC0DE0BADC0DE;
      endcase
    end
  end

  // Radio clock
  wire [31:0] spi_readback_rclk;
  always @(posedge radio_clk) begin
    if (radio_rst) begin
      rb_data_rclk <= 64'd0;
    end else begin
      case(rb_addr_rclk)
        RB_SPI_RCLK      : rb_data_rclk <= {31'd0, spi_ready_rclk, spi_readback_rclk};
        RB_MISC_IO_RCLK  : rb_data_rclk <= {misc_ins, misc_outs};
        RB_DB_GPIO_RCLK  : rb_data_rclk <= {db0_gpio_readback, db1_gpio_readback};
        RB_FP_GPIO_RCLK  : rb_data_rclk <= {32'd0, fp_gpio_readback};
        default          : rb_data_rclk <= 64'h0BADC0DE0BADC0DE;
      endcase
    end
  end

  /********************************************************
  ** Mux SPIs
  ** One SPI core per clock (bus_clk, radio_clk)
  ** - Need bus_clk SPI for initial setup after power on
  ** - Need radio_clk SPI for timed commands
  ********************************************************/
  wire [7:0] sen_int[0:1];
  wire [1:0] sclk_int, mosi_int;
  // Bus clock
  simple_spi_core #(.BASE(SR_SPI_BCLK), .WIDTH(8), .CLK_IDLE(0), .SEN_IDLE(8'hFF)) bus_clk_spi (
    .clock(bus_clk), .reset(bus_rst),
    .set_stb(set_stb_bclk), .set_addr(set_addr_bclk), .set_data(set_data_bclk),
    .readback(spi_readback_bclk), .ready(spi_ready_bclk),
    .sen(sen_int[0]), .sclk(sclk_int[0]), .mosi(mosi_int[0]), .miso(miso),
    .debug());

  // Radio clock
  simple_spi_core #(.BASE(SR_SPI_RCLK), .WIDTH(8), .CLK_IDLE(0), .SEN_IDLE(8'hFF)) radio_clk_spi (
    .clock(radio_clk), .reset(radio_rst),
    .set_stb(set_stb_rclk_timed), .set_addr(set_addr_rclk_timed), .set_data(set_data_rclk_timed),
    .readback(spi_readback_rclk), .ready(spi_ready_rclk),
    .sen(sen_int[1]), .sclk(sclk_int[1]), .mosi(mosi_int[1]), .miso(miso),
    .debug());

  assign sen  = spi_en_bclk ? sen_int[0]  : sen_int[1];
  assign sclk = spi_en_bclk ? sclk_int[0] : sclk_int[1];
  assign mosi = spi_en_bclk ? mosi_int[0] : mosi_int[1];

endmodule