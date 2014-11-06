
// radio_core
//  Contains all clock-rate DSP components, all radio and hardware controls and settings
//  Designed to connect to a noc_shell

// FIXME Issues:
//   vita time fed to noc_shell for command timing?  or separate radio_ctrl_proc?
//   same for spi_ready
//   put rx and tx on separate ports?
//   multiple rx?

module radio_core
  #(parameter BASE = 0,
    parameter DELETE_DSP = 0,
    parameter RADIO_NUM = 0)
   (input radio_clk, input radio_rst,
    // Interface to the physical radio (ADC, DAC, controls)
    input [31:0] rx, output [31:0] tx,
    inout [31:0] db_gpio,
    inout [31:0] fp_gpio,
    output [7:0] sen, output sclk, output mosi, input miso,
    output [7:0] misc_outs, output [2:0] leds,
    input pps,
    output sync_dacs,
    
    // Interface to the noc_shell
    input set_stb, input [7:0] set_addr, input [31:0] set_data, output reg [63:0] rb_data,
    output [63:0] vita_time,
    
    input [63:0] tx_tdata, input tx_tlast, input tx_tvalid, output tx_tready,
    input [127:0] tx_tuser,
    
    output [63:0] rx_tdata, output rx_tlast, output rx_tvalid, input rx_tready,
    output [127:0] rx_tuser,
    
    output [63:0] debug
    );

   wire [31:0] 	  fp_gpio_readback, gpio_readback, spi_readback;
   wire 	  run_rx, run_tx;
   wire 	  strobe_tx;
   wire 	  spi_ready;
   wire [31:0] 	  test_readback;

   // radio_ctrl
   //   most misc settings here, keeps time, etc.
   //   FIXME -- how do we handle conflict of this vs. toplevel noc_shell handling of settings bus?
   //   FIXME -- should timekeeping even be handled here, or should it be handled by ZPU or another NoC block?

   radio_ctrl #(.BASE(BASE_CTRL), .RADIO_NUM(RADIO_NUM)) radio_ctrl
     (.radio_clk(radio_clk), .radio_rst(radio_rst),
      .db_gpio(db_gpio), .fp_gpio(fp_gpio),
      .misc_outs(misc_outs), .leds(leds),
      .sen(sen), .sclk(sclk), .mosi(mosi), .miso(miso),
      .pps(pps),
      .sync_dacs(sync_dacs),
      .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
      .rb_data(rb_data), .spi_ready(spi_ready),
      .vita_time(vita_time),
      .run_rx(run_rx), .run_tx(run_tx));
   
   // radio_tx
   //   Takes in stream of tx sample packets
   //   Returns stream of tx ack packets, but no longer does its own flow control (noc_shell handles that)

   radio_tx #(.BASE(BASE_TX), .DELETE_DSP(DELETE_DSP_TX)) radio_tx
     (.radio_clk(radio_clk), .radio_rst(radio_rst),
      .tx(tx), .run(run_tx),
      .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data), .rb_data(rb_data_tx),
      .vita_time(vita_time),
      .tx_tdata(tx_tdata), .tx_tlast(tx_tlast), .tx_tvalid(tx_tvalid), .tx_tready(tx_tready),
      .tx_tuser(tx_tuser));
   
   // radio_rx
   //   Returns stream of rx sample packets
   //   Also sends rx error and ack packets back (in line?)
   //   Flow control handled by noc_shell

   radio_rx #(.BASE(BASE_RX), .DELETE_DSP(DELETE_RX_DSP)) radio_rx
     (.radio_clk(radio_clk), .radio_rst(radio_rst),
      .rx(rx), .run(run_rx)
      .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data), .rb_data(rb_data_rx),
      .vita_time(vita_time),
      .rx_tdata(rx_tdata), .rx_tlast(rx_tlast), .rx_tvalid(rx_tvalid), .rx_tready(rx_tready),
      .rx_tuser(rx_tuser));
   
endmodule // radio_core
