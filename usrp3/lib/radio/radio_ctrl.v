
// radio_core
//  Contains all clock-rate DSP components, all radio and hardware controls and settings
//  Designed to connect to a noc_shell

// FIXME Issues:
//   vita time fed to noc_shell for command timing?  or separate radio_ctrl_proc?
//   same for spi_ready
//   put rx and tx on separate ports?
//   multiple rx?

module radio_ctrl
  #(parameter BASE = 0,
    parameter RADIO_NUM = 0)
   (input radio_clk, input radio_rst,
    // Interface to the physical radio (ADC, DAC, controls)
    inout [31:0] db_gpio,
    inout [31:0] fp_gpio,
    output [7:0] sen, output sclk, output mosi, input miso,
    output [7:0] misc_outs, output [2:0] leds,
    input pps,
    output sync_dacs,
    
    // Interface to the noc_shell
    input set_stb, input [7:0] set_addr, input [31:0] set_data, output reg [63:0] rb_data, output spi_ready,
    output [63:0] vita_time,

    // Interface to TX and RX
    input run_rx, input run_tx
    );

   // /////////////////////////////////////////////////////////////////////////////////////
   // Setting bus and controls

   localparam SR_DACSYNC   = 8'd5;
   localparam SR_LOOPBACK  = 8'd6;
   localparam SR_TEST      = 8'd7;
   localparam SR_SPI       = 8'd8;
   localparam SR_GPIO      = 8'd16;
   localparam SR_MISC_OUTS = 8'd24;
   localparam SR_READBACK  = 8'd32;
   localparam SR_TIME      = 8'd128;
   localparam SR_LEDS      = 8'd196;
   localparam SR_FP_GPIO   = 8'd200;

   wire [31:0] 	fp_gpio_readback, gpio_readback, spi_readback;

   wire 	spi_ready;

   wire [2:0] 	rb_addr;
   wire [63:0] 	vita_time_lastpps;
   wire [31:0] 	test_readback;
   wire 	loopback;
   
   // Radio Readback Mux
   always @*
     case(rb_addr)
       3'd0 : rb_data <= { spi_readback, gpio_readback};
       3'd1 : rb_data <= vita_time;
       3'd2 : rb_data <= vita_time_lastpps;
       3'd3 : rb_data <= {rx, test_readback};
       3'd4 : rb_data <= {32'h0, fp_gpio_readback};
       3'd5 : rb_data <= {tx,rx};
       3'd6 : rb_data <= {32'h0,RADIO_NUM};
       default : rb_data <= 64'd0;
     endcase // case (rb_addr)

   // Write this register with any value to create DAC sync operation
   setting_reg #(.my_addr(SR_DACSYNC), .width(1)) sr_dacsync
     (.clk(radio_clk), .rst(radio_rst), .strobe(set_stb), .addr(set_addr), .in(set_data),
      .out(), .changed(sync_dacs));

   // FIXME
   // Set this register to loop TX data directly to RX data.
   setting_reg #(.my_addr(SR_LOOPBACK), .width(1)) sr_loopback
     (.clk(radio_clk), .rst(radio_rst), .strobe(set_stb), .addr(set_addr), .in(set_data),
      .out(loopback), .changed());

   // Set this register to put a test value on the readback mux.
   setting_reg #(.my_addr(SR_TEST), .width(32)) sr_test
     (.clk(radio_clk), .rst(radio_rst), .strobe(set_stb), .addr(set_addr), .in(set_data),
      .out(test_readback), .changed());

   setting_reg #(.my_addr(SR_READBACK), .width(3)) sr_rdback
     (.clk(radio_clk), .rst(radio_rst), .strobe(set_stb), .addr(set_addr), .in(set_data),
      .out(rb_addr), .changed());

   setting_reg #(.my_addr(SR_MISC_OUTS), .width(8), .at_reset(8'h0)) sr_misc
     (.clk(radio_clk), .rst(radio_rst), .strobe(set_stb), .addr(set_addr), .in(set_data),
      .out(misc_outs), .changed());

   simple_spi_core #(.BASE(SR_SPI), .WIDTH(8), .CLK_IDLE(0), .SEN_IDLE(8'hFF)) radio_spi
     (.clock(radio_clk), .reset(radio_rst),
      .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
      .readback(spi_readback), .ready(spi_ready),
      .sen(sen), .sclk(sclk), .mosi(mosi), .miso(miso),
      .debug());

   gpio_atr #(.BASE(SR_GPIO), .WIDTH(32)) gpio_atr
     (.clk(radio_clk),.reset(radio_rst),
      .set_stb(set_stb),.set_addr(set_addr),.set_data(set_data),
      .rx(run_rx), .tx(run_tx),
      .gpio(db_gpio), .gpio_readback(gpio_readback) );

   gpio_atr #(.BASE(SR_FP_GPIO), .WIDTH(32)) fp_gpio_atr
     (.clk(radio_clk),.reset(radio_rst),
      .set_stb(set_stb),.set_addr(set_addr),.set_data(set_data),
      .rx(run_rx), .tx(run_tx),
      .gpio(fp_gpio), .gpio_readback(fp_gpio_readback) );

   gpio_atr #(.BASE(SR_LEDS), .WIDTH(3), .default_ddr(3'b111), .default_idle(3'b000)) gpio_leds
     (.clk(radio_clk),.reset(radio_rst),
      .set_stb(set_stb),.set_addr(set_addr),.set_data(set_data),
      .rx(run_rx), .tx(run_tx),
      .gpio(leds), .gpio_readback() );

   timekeeper #(.BASE(SR_TIME)) timekeeper
     (.clk(radio_clk), .reset(radio_rst), .pps(pps),
      .set_stb(set_stb),.set_addr(set_addr),.set_data(set_data),
      .vita_time(vita_time), .vita_time_lastpps(vita_time_lastpps));

endmodule // radio_ctrl
