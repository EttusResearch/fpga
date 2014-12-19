
// radio_core
//  Contains all clock-rate DSP components, all radio and hardware controls and settings
//  Designed to connect to a noc_shell

// FIXME Issues:
//   vita time fed to noc_shell for command timing?  or separate radio_ctrl_proc?
//   put rx and tx on separate ports?
//   multiple rx?

module radio_rx
  #(parameter BASE = 0,
    parameter DELETE_DSP = 1)
   (input clk, input reset,
    // Interface to the physical radio (ADC, DAC, controls)
    input [31:0] rx, output run,
    
    // Interface to the noc_shell
    input set_stb, input [7:0] set_addr, input [31:0] set_data, output reg [63:0] rb_data,
    input [63:0] vita_time,
    
    output [31:0] rx_tdata, output rx_tlast, output rx_tvalid, input rx_tready,
    output [127:0] rx_tuser,
    
    input [31:0] tx_loopback);

   // /////////////////////////////////////////////////////////////////////////////////////
   // Setting bus and controls

   localparam SR_LOOPBACK  = 8'd6;
   localparam SR_TEST      = 8'd7;
   localparam SR_SPI       = 8'd8;
   localparam SR_GPIO      = 8'd16;
   localparam SR_MISC_OUTS = 8'd24;
   localparam SR_READBACK  = 8'd32;
   localparam SR_TX_CTRL   = 8'd64;
   localparam SR_RX_CTRL   = 8'd96;
   localparam SR_TIME      = 8'd128;
   localparam SR_RX_DSP    = 8'd144;
   localparam SR_TX_DSP    = 8'd184;
   localparam SR_LEDS      = 8'd196;
   localparam SR_FP_GPIO   = 8'd200;
   localparam SR_RX_FRONT  = 8'd208;
   localparam SR_TX_FRONT  = 8'd216;
   localparam SR_CODEC_IDLE = 8'd100;

   wire 	loopback;
   
   // Set this register to loop TX data directly to RX data.
   setting_reg #(.my_addr(SR_LOOPBACK), .awidth(8), .width(1)) sr_loopback
     (.clk(clk), .rst(reset), .strobe(set_stb), .addr(set_addr), .in(set_data),
      .out(loopback), .changed());

   // /////////////////////////////////////////////////////////////////////////////////
   //  RX Chain

   wire 	strobe_rx;
   wire [31:0] 	sample_rx;

   rx_control_gen3 #(.BASE(SR_RX_CTRL)) rx_control_gen3
     (.clk(clk), .reset(reset), .clear(1'b0),
      .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
      .vita_time(vita_time),
      .strobe(strobe_rx), .sample(sample_rx), .run(run),
      .rx_tdata(rx_tdata), .rx_tlast(rx_tlast), .rx_tvalid(rx_tvalid), .rx_tready(rx_tready), .rx_tuser(rx_tuser));
   
   // ///////////////////////////////////////////////////////////////////////////////////
   // Signal Processing
   wire [23:0] 	  rx_corr_i, rx_corr_q;
   wire [31:0] 	  rx_fe = loopback ? tx_loopback : rx;    // Digital Loopback TX -> RX (Pipeline immediately inside rx_frontend)
   
   generate
      if (DELETE_DSP==0)
	begin:	rx_dsp
	   rx_frontend #(.BASE(SR_RX_FRONT)) rx_frontend
	     (.clk(clk),.rst(reset),
	      .set_stb(set_stb),.set_addr(set_addr),.set_data(set_data),
	      .adc_a(rx_fe[31:16]),.adc_ovf_a(1'b0),
	      .adc_b(rx_fe[15:0]),.adc_ovf_b(1'b0),
	      .i_out(rx_corr_i), .q_out(rx_corr_q),
	      .run(run), .debug());

	   ddc_chain_x300 #(.BASE(SR_RX_DSP), .DSPNO(0), .WIDTH(24)) ddc_chain
	     (.clk(clk), .rst(reset), .clr(1'b0),
	      .set_stb(set_stb),.set_addr(set_addr),.set_data(set_data),
	      .rx_fe_i(rx_corr_i),.rx_fe_q(rx_corr_q),
	      .sample(sample_rx), .run(run), .strobe(strobe_rx),
	      .debug() );
	end // block: rx_dsp
      else
	begin
	   assign sample_rx = rx_fe;
	   assign strobe_rx = run;
	end
   endgenerate

endmodule // radio_rx
