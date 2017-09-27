//
// Copyright 2017 Ettus Research LLC
//

module n3xx_db_fe_core #(
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

  //TODO: Flesh out this module
  assign tx_data_out = tx_data_in;
  assign rx_data_out = rx_data_in;

  assign rb_stb = 1'b1;
  assign rb_data = 64'h0;

  assign misc_outs = 32'h0;
  assign fp_gpio_out = 32'h0;
  assign fp_gpio_ddr = 32'h0;
  assign db_gpio_out = 32'h0;
  assign db_gpio_ddr = 32'h0;
  assign leds = 32'h0;

  assign sen = 8'h0;
  assign sclk = 1'b0;
  assign mosi = 1'b0;

endmodule
