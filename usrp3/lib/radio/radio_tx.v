
// radio_core
//  Contains all clock-rate DSP components, all radio and hardware controls and settings
//  Designed to connect to a noc_shell

// FIXME Issues:
//   vita time fed to noc_shell for command timing?  or separate radio_ctrl_proc?
//   same for spi_ready
//   put rx and tx on separate ports?
//   multiple rx?

module radio_tx
  #(parameter BASE = 0,
    parameter DELETE_DSP = 0)
   (input radio_clk, input radio_rst,
    // Interface to the physical radio (ADC, DAC, controls)
    output [31:0] tx, output run,
    
    // Interface to the noc_shell
    input set_stb, input [7:0] set_addr, input [31:0] set_data, output reg [63:0] rb_data,
    input [63:0] vita_time,
    
    input [63:0] tx_tdata, input tx_tlast, input tx_tvalid, output tx_tready,
    input [127:0] tx_tuser);

   // /////////////////////////////////////////////////////////////////////////////////////
   // Setting bus and controls

   localparam SR_DACSYNC   = 8'd5;
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

   wire 	strobe_tx;
   wire 	spi_ready;

   wire [2:0] 	rb_addr;
   wire [63:0] 	vita_time_lastpps;
   wire [31:0] 	test_readback;
   wire [31:0] 	tx_idle;
   
   setting_reg #(.my_addr(SR_CODEC_IDLE), .awidth(8), .width(32)) sr_codec_idle
     (.clk(radio_clk), .rst(radio_rst), .strobe(set_stb), .addr(set_addr), .in(set_data),
      .out(tx_idle), .changed());

   // /////////////////////////////////////////////////////////////////////////////////
   //  TX Chain

   wire [175:0] txsample_tdata;
   wire 	txsample_tvalid, txsample_tready;
   wire [31:0] 	sample_tx;
   wire 	tx_ack, tx_error, packet_consumed;
   wire [11:0] 	seqnum;
   wire [63:0] 	error_code;
   wire [31:0] 	sid;
   wire [23:0] 	tx_fe_i, tx_fe_q;

   new_tx_deframer tx_deframer
     (.clk(radio_clk), .reset(radio_rst), .clear(1'b0),
      .i_tdata(tx_tdata_r), .i_tlast(tx_tlast_r), .i_tvalid(tx_tvalid_r), .i_tready(tx_tready_r),
      .sample_tdata(txsample_tdata), .sample_tvalid(txsample_tvalid), .sample_tready(txsample_tready));

   new_tx_control #(.BASE(SR_TX_CTRL)) tx_control
     (.clk(radio_clk), .reset(radio_rst), .clear(1'b0),
      .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
      .vita_time(vita_time),
      .ack(tx_ack), .error(tx_error), .packet_consumed(packet_consumed),
      .seqnum(seqnum), .error_code(error_code), .sid(sid),
      .sample_tdata(txsample_tdata), .sample_tvalid(txsample_tvalid), .sample_tready(txsample_tready),
      .sample(sample_tx), .run(run), .strobe(strobe_tx),
      .debug());

   tx_responder #(.BASE(SR_TX_CTRL+2)) tx_responder
     (.clk(radio_clk), .reset(radio_rst), .clear(1'b0),
      .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
      .ack(tx_ack), .error(tx_error), .packet_consumed(packet_consumed),
      .seqnum(seqnum), .error_code(error_code), .sid(sid),
      .vita_time(vita_time),
      .o_tdata(txresp_tdata_r), .o_tlast(txresp_tlast_r), .o_tvalid(txresp_tvalid_r), .o_tready(txresp_tready_r));

   wire [15:0] 	tx_i_running, tx_q_running;
   
   generate
      if (DELETE_DSP==0) begin:	tx_dsp
	 duc_chain #(.BASE(SR_TX_DSP), .DSPNO(0), .WIDTH(24)) duc_chain
	   (.clk(radio_clk), .rst(radio_rst), .clr(1'b0),
	    .set_stb(set_stb),.set_addr(set_addr),.set_data(set_data),
	    .tx_fe_i(tx_fe_i),.tx_fe_q(tx_fe_q),
	    .sample(sample_tx), .run(run), .strobe(strobe_tx),
	    .debug() );
	 tx_frontend #(.BASE(SR_TX_FRONT), .WIDTH_OUT(16), .IQCOMP_EN(1)) tx_frontend
	   (.clk(radio_clk), .rst(radio_rst),
	    .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
	    .tx_i(tx_fe_i), .tx_q(tx_fe_q), .run(run),
	    .dac_a(tx_i_running), .dac_b(tx_q_running));
      end
   endgenerate

   assign tx[31:16] = run ? tx_i_running : tx_idle[31:16];
   assign tx[15:0]  = run ? tx_q_running : tx_idle[15:0];

endmodule // radio_tx
