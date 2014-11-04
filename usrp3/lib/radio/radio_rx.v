
// radio_core
//  Contains all clock-rate DSP components, all radio and hardware controls and settings
//  Designed to connect to a noc_shell

// FIXME Issues:
//   vita time fed to noc_shell for command timing?  or separate radio_ctrl_proc?
//   same for spi_ready
//   put rx and tx on separate ports?
//   multiple rx?

module radio_rx
  #(parameter BASE = 0,
    parameter DELETE_DSP = 0)
   (input radio_clk, input radio_rst,
    // Interface to the physical radio (ADC, DAC, controls)
    input [31:0] rx,
    
    // Interface to the noc_shell
    input set_stb, input [7:0] set_addr, input [31:0] set_data, output reg [63:0] rb_data,
    input [63:0] vita_time,
    
    output [63:0] rx_tdata, output rx_tlast, output rx_tvalid, input rx_tready,
    output [127:0] rx_tuser,

    // To TX and ctrl
    output run_rx
    );

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

   wire 	spi_ready;

   wire 	loopback;
   
   // Set this register to loop TX data directly to RX data.
   setting_reg #(.my_addr(SR_LOOPBACK), .awidth(8), .width(1)) sr_loopback
     (.clk(radio_clk), .rst(radio_rst), .strobe(set_stb), .addr(set_addr), .in(set_data),
      .out(loopback), .changed());

   // /////////////////////////////////////////////////////////////////////////////////
   //  RX Chain

   wire 	full, eob_rx;
   wire 	strobe_rx;
   wire [31:0] 	sample_rx;
   wire [31:0] 	  rx_sid;
   wire [11:0] 	  rx_seqnum;

   new_rx_framer #(.BASE(SR_RX_CTRL+4),.CHIPSCOPE(0)) new_rx_framer
     (.clk(radio_clk), .reset(radio_rst), .clear(1'b0),
      .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
      .vita_time(vita_time),
      .strobe(strobe_rx), .sample(sample_rx), .run(run_rx), .eob(eob_rx), .full(full),
      .sid(rx_sid), .seqnum(rx_seqnum),
      .o_tdata(rx_tdata_r), .o_tlast(rx_tlast_r), .o_tvalid(rx_tvalid_r), .o_tready(rx_tready_r),
      .debug());

   new_rx_control #(.BASE(SR_RX_CTRL)) new_rx_control
     (.clk(radio_clk), .reset(radio_rst), .clear(1'b0),
      .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
      .vita_time(vita_time),
      .strobe(strobe_rx), .run(run_rx), .eob(eob_rx), .full(full),
      .sid(rx_sid), .seqnum(rx_seqnum),
      .err_tdata(rx_err_tdata_r), .err_tlast(rx_err_tlast_r), .err_tvalid(rx_err_tvalid_r), .err_tready(rx_err_tready_r),
      .debug());

   wire [23:0] 	  rx_corr_i, rx_corr_q;

   // Digital Loopback TX -> RX (Pipeline immediately inside rx_frontend).
   wire [31:0] 	  rx_fe = loopback ? tx : rx;
   
   generate
      if (DELETE_DSP==0)
	begin:	rx_dsp
	   rx_frontend #(.BASE(SR_RX_FRONT)) rx_frontend
	     (.clk(radio_clk),.rst(radio_rst),
	      .set_stb(set_stb),.set_addr(set_addr),.set_data(set_data),
	      .adc_a(rx_fe[31:16]),.adc_ovf_a(1'b0),
	      .adc_b(rx_fe[15:0]),.adc_ovf_b(1'b0),
	      .i_out(rx_corr_i), .q_out(rx_corr_q),
	      .run(run_rx), .debug());

	   ddc_chain_x300 #(.BASE(SR_RX_DSP), .DSPNO(0), .WIDTH(24)) ddc_chain
	     (.clk(radio_clk), .rst(radio_rst), .clr(1'b0),
	      .set_stb(set_stb),.set_addr(set_addr),.set_data(set_data),
	      .rx_fe_i(rx_corr_i),.rx_fe_q(rx_corr_q),
	      .sample(sample_rx), .run(run_rx), .strobe(strobe_rx),
	      .debug() );
	end
   endgenerate

   // /////////////////////////////////////////////////////////////////////////////////
   //  RX Channel Muxing

   axi_mux4 #(.PRIO(1), .WIDTH(64)) rx_mux
     (.clk(radio_clk), .reset(radio_rst), .clear(1'b0),
      .i0_tdata(rx_tdata_r), .i0_tlast(rx_tlast_r), .i0_tvalid(rx_tvalid_r), .i0_tready(rx_tready_r),
      .i1_tdata(rx_err_tdata_r), .i1_tlast(rx_err_tlast_r), .i1_tvalid(rx_err_tvalid_r), .i1_tready(rx_err_tready_r),
      .i2_tdata(), .i2_tlast(), .i2_tvalid(1'b0), .i2_tready(),
      .i3_tdata(), .i3_tlast(), .i3_tvalid(1'b0), .i3_tready(),
      .o_tdata(rx_mux_tdata_r), .o_tlast(rx_mux_tlast_r), .o_tvalid(rx_mux_tvalid_r), .o_tready(rx_mux_tready_r));

endmodule // radio_rx
