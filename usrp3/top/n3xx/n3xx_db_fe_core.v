//
// Copyright 2017 Ettus Research LLC
//

module n3xx_db_fe_core #(
  // Drive SPI core with input spi_clk instead of ce_clk. This is useful if ce_clk is very slow which
  // would cause spi transactions to take a long time. WARNING: This adds a clock crossing FIFO!
  parameter USE_SPI_CLK = 0,
  parameter [7:0] SR_DB_FE_BASE = 160,
  parameter [7:0] RB_DB_FE_BASE = 16
)(
  input clk, input reset,
  // Commands from Radio Core
  input  set_stb, input [7:0] set_addr, input  [31:0] set_data,
  output rb_stb,  input [7:0] rb_addr,  output [63:0] rb_data,
  input  time_sync,
  // Radio datapath
  input  tx_stb, input [31:0] tx_data_in, output [31:0] tx_data_out, input tx_running,
  input  rx_stb, input [31:0] rx_data_in, output [31:0] rx_data_out, input rx_running,
  // Frontend / Daughterboard I/O
  input [31:0] misc_ins, output [31:0] misc_outs,
  input [31:0] fp_gpio_in, output [31:0] fp_gpio_out, output [31:0] fp_gpio_ddr, input [31:0] fp_gpio_fab,
  input [31:0] db_gpio_in, output [31:0] db_gpio_out, output [31:0] db_gpio_ddr, input [31:0] db_gpio_fab,
  output [31:0] leds,
  input spi_clk, input spi_rst, output [7:0] sen, output sclk, output mosi, input miso
);


  db_control #(
    .USE_SPI_CLK(USE_SPI_CLK), .SR_BASE(SR_DB_FE_BASE), .RB_BASE(RB_DB_FE_BASE)
  ) db_control_i (
    .clk(clk), .reset(reset),
    .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
    .rb_stb(rb_stb), .rb_addr(rb_addr), .rb_data(rb_data),
    .run_rx(rx_running), .run_tx(tx_running),
    .misc_ins(misc_ins), .misc_outs(misc_outs),
    .fp_gpio_in(fp_gpio_in), .fp_gpio_out(fp_gpio_out), .fp_gpio_ddr(fp_gpio_ddr), .fp_gpio_fab(fp_gpio_fab),
    .db_gpio_in(db_gpio_in), .db_gpio_out(db_gpio_out), .db_gpio_ddr(db_gpio_ddr), .db_gpio_fab(db_gpio_fab),
    .leds(leds),
    .spi_clk(spi_clk), .spi_rst(spi_rst), .sen(sen), .sclk(sclk), .mosi(mosi), .miso(miso)
  );
  //TODO: Flesh out this module
  assign tx_data_out = tx_data_in;
  assign rx_data_out = rx_data_in;

endmodule
