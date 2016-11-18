//
// Copyright 2014 Ettus Research LLC
//
// radio top level module
//  Contains all clock-rate DSP components, all radio and hardware controls and settings
//  Communication with outside world is exclusively via a single in/out axi cvita port
//  Paths are separated by the lower 2 bits of stream ID, as follows:
//
//    CHDR[63:62] 
//       0        Data
//       1        Flow Control
//       2        Command
//       3        Response

module radio #(
   parameter CHIPSCOPE = 0,
   parameter DELETE_DSP = 0,
   parameter RADIO_NUM = 0,
   parameter TX_PRE_FIFO_SIZE = 0,
   parameter DATA_FIFO_SIZE = 10,
   parameter MSG_FIFO_SIZE = 9
) (
   input radio_clk, input radio_rst,
   input [31:0] rx, output [31:0] tx,
   input [31:0] db_gpio_in, output [31:0] db_gpio_out, output [31:0] db_gpio_ddr,
   input [31:0] fp_gpio_in, output [31:0] fp_gpio_out, output [31:0] fp_gpio_ddr,
   output [7:0] sen, output sclk, output mosi, input miso,
   output [31:0] misc_outs, input [31:0] misc_ins, output [2:0] leds,

   input bus_clk, input bus_rst,
   input [63:0] in_tdata, input in_tlast, input in_tvalid, output in_tready,
   output [63:0] out_tdata, output out_tlast, output out_tvalid, input out_tready,
   input [63:0] tx_tdata_bi, input tx_tlast_bi, input tx_tvalid_bi, output tx_tready_bi,
   output [63:0] tx_tdata_bo, output tx_tlast_bo, output tx_tvalid_bo, input tx_tready_bo,

   input pps,
   input time_sync,
   output sync_dacs,
   
   output [63:0] debug
   );

   // ///////////////////////////////////////////////////////////////////////////////
   // FIFO Interfacing to the bus clk domain
   // in_tdata splits to tx_tdata and ctrl_tdata
   // rx_tdata and resp_tdata get muxed to out_tdata
   // Everything except rx flow control must cross in to radio_clk domain before further use
   // _b signifies bus_clk domain, _r signifies radio_clk domain, _b_fc is bus_clk domain, post flow control

   wire [63:0] 	 ctrl_tdata_b, ctrl_tdata_r;
   wire 	 ctrl_tready_b, ctrl_tready_r, ctrl_tvalid_b, ctrl_tvalid_r;
   wire 	 ctrl_tlast_b, ctrl_tlast_r;

   wire [63:0] 	 resp_tdata_b, resp_tdata_r;
   wire 	 resp_tready_b, resp_tready_r, resp_tvalid_b, resp_tvalid_r;
   wire 	 resp_tlast_b, resp_tlast_r;

   wire [63:0] 	 rx_tdata_b, rx_tdata_b_fc, rx_tdata_r;
   wire 	 rx_tready_b, rx_tready_b_fc, rx_tready_r, rx_tvalid_b, rx_tvalid_b_fc, rx_tvalid_r;
   wire 	 rx_tlast_b, rx_tlast_b_fc, rx_tlast_r;

   wire [63:0] 	 tx_tdata_b, tx_tdata_r;
   wire 	 tx_tready_b, tx_tready_r, tx_tvalid_b, tx_tvalid_r;
   wire 	 tx_tlast_b, tx_tlast_r;

   wire [63:0] 	 txresp_tdata_b, txresp_tdata_fifo, txresp_tdata_r;
   wire 	 txresp_tready_b, txresp_tready_fifo, txresp_tready_r, txresp_tvalid_b, txresp_tvalid_fifo, txresp_tvalid_r;
   wire 	 txresp_tlast_b, txresp_tlast_fifo, txresp_tlast_r;

   wire [63:0] 	 rxfc_tdata_b;
   wire 	 rxfc_tready_b, rxfc_tvalid_b, rxfc_tlast_b;

   wire [63:0] 	 rx_mux_tdata_r;
   wire 	 rx_mux_tready_r, rx_mux_tvalid_r;
   wire 	 rx_mux_tlast_r;

   wire [63:0] 	 rx_err_tdata_r;
   wire 	 rx_err_tready_r, rx_err_tvalid_r;
   wire 	 rx_err_tlast_r;

   axi_mux4 #(.PRIO(0), .WIDTH(64), .BUFFER(1)) radio_mux
     (.clk(bus_clk), .reset(bus_rst), .clear(1'b0),
      .i0_tdata(txresp_tdata_b), .i0_tlast(txresp_tlast_b), .i0_tvalid(txresp_tvalid_b), .i0_tready(txresp_tready_b), // TX Flow Control/ACK
      .i1_tdata(resp_tdata_b), .i1_tlast(resp_tlast_b), .i1_tvalid(resp_tvalid_b), .i1_tready(resp_tready_b), // Control Response
      .i2_tdata(rx_tdata_b_fc), .i2_tlast(rx_tlast_b_fc), .i2_tvalid(rx_tvalid_b_fc), .i2_tready(rx_tready_b_fc), // RX Data
      .i3_tdata(txresp_tdata_fifo), .i3_tlast(txresp_tlast_fifo), .i3_tvalid(txresp_tvalid_fifo), .i3_tready(txresp_tready_fifo),   // TX Pre-Fifo FC ACK
      .o_tdata(out_tdata), .o_tlast(out_tlast), .o_tvalid(out_tvalid), .o_tready(out_tready));

   wire [63:0] 	 vheader;
   wire [1:0] 	 vdest = vheader[63:62];  // Switch by packet type

   axi_demux4 #(.ACTIVE_CHAN(4'b1111), .WIDTH(64)) radio_demux
     (.clk(bus_clk), .reset(bus_rst), .clear(1'b0),
      .header(vheader), .dest(vdest),
      .i_tdata(in_tdata), .i_tlast(in_tlast), .i_tvalid(in_tvalid), .i_tready(in_tready),
      .o0_tdata(tx_tdata_b), .o0_tlast(tx_tlast_b), .o0_tvalid(tx_tvalid_b), .o0_tready(tx_tready_b),  // TX Data
      .o1_tdata(rxfc_tdata_b), .o1_tlast(rxfc_tlast_b), .o1_tvalid(rxfc_tvalid_b), .o1_tready(rxfc_tready_b), // RX Flow Control
      .o2_tdata(ctrl_tdata_b), .o2_tlast(ctrl_tlast_b), .o2_tvalid(ctrl_tvalid_b), .o2_tready(ctrl_tready_b),  // Control
      .o3_tdata(), .o3_tlast(), .o3_tvalid(), .o3_tready(1'b1)); // No CTRL Resp coming back

   axi_fifo_2clk_cascade #(.WIDTH(65), .SIZE(MSG_FIFO_SIZE)) ctrl_fifo
     (.reset(bus_rst),
      .i_aclk(bus_clk), .i_tvalid(ctrl_tvalid_b), .i_tready(ctrl_tready_b), .i_tdata({ctrl_tlast_b,ctrl_tdata_b}),
      .o_aclk(radio_clk), .o_tvalid(ctrl_tvalid_r), .o_tready(ctrl_tready_r), .o_tdata({ctrl_tlast_r,ctrl_tdata_r}));

   axi_fifo #(.WIDTH(65), .SIZE(TX_PRE_FIFO_SIZE)) tx_data_fifo
     (.clk(bus_clk), .reset(bus_rst), .clear(1'b0),
      .i_tdata({tx_tlast_b,tx_tdata_b}), .i_tvalid(tx_tvalid_b), .i_tready(tx_tready_b),
      .o_tdata({tx_tlast_bo,tx_tdata_bo}), .o_tvalid(tx_tvalid_bo), .o_tready(tx_tready_bo),
      .space(), .occupied());

   axi_fifo_2clk #(.WIDTH(65), .SIZE(DATA_FIFO_SIZE)) tx_data_2clk_fifo
     (.reset(bus_rst),
      .i_aclk(bus_clk), .i_tvalid(tx_tvalid_bi), .i_tready(tx_tready_bi), .i_tdata({tx_tlast_bi,tx_tdata_bi}),
      .o_aclk(radio_clk), .o_tvalid(tx_tvalid_r), .o_tready(tx_tready_r), .o_tdata({tx_tlast_r,tx_tdata_r}));

   axi_fifo_2clk #(.WIDTH(65), .SIZE(MSG_FIFO_SIZE)) resp_fifo
     (.reset(radio_rst),
      .i_aclk(radio_clk), .i_tvalid(resp_tvalid_r), .i_tready(resp_tready_r), .i_tdata({resp_tlast_r,resp_tdata_r}),
      .o_aclk(bus_clk), .o_tvalid(resp_tvalid_b), .o_tready(resp_tready_b), .o_tdata({resp_tlast_b,resp_tdata_b}));

   axi_fifo_2clk #(.WIDTH(65), .SIZE(DATA_FIFO_SIZE)) rx_fifo
     (.reset(radio_rst),
      .i_aclk(radio_clk), .i_tvalid(rx_mux_tvalid_r), .i_tready(rx_mux_tready_r), .i_tdata({rx_mux_tlast_r,rx_mux_tdata_r}),
      .o_aclk(bus_clk), .o_tvalid(rx_tvalid_b), .o_tready(rx_tready_b), .o_tdata({rx_tlast_b,rx_tdata_b}));

   axi_fifo_2clk #(.WIDTH(65), .SIZE(MSG_FIFO_SIZE)) txresp_fifo
     (.reset(radio_rst),
      .i_aclk(radio_clk), .i_tvalid(txresp_tvalid_r), .i_tready(txresp_tready_r), .i_tdata({txresp_tlast_r,txresp_tdata_r}),
      .o_aclk(bus_clk), .o_tvalid(txresp_tvalid_b), .o_tready(txresp_tready_b), .o_tdata({txresp_tlast_b,txresp_tdata_b}));

   // /////////////////////////////////////////////////////////////////////////////////////
   // Setting bus and controls
   localparam SR_DACSYNC   = 8'd5;
   localparam SR_LOOPBACK  = 8'd6;
   localparam SR_TEST      = 8'd7;
   localparam SR_SPI       = 8'd8;
   localparam SR_GPIO      = 8'd16;
   localparam SR_MISC_OUTS = 8'd24;
   localparam SR_READBACK  = 8'd127;
   localparam SR_TX_CTRL   = 8'd64;
   localparam SR_RX_CTRL   = 8'd96;
   localparam SR_TIME      = 8'd128;
   localparam SR_RX_DSP    = 8'd144;
   localparam SR_TX_DSP    = 8'd184;
   localparam SR_LEDS      = 8'd195;
   localparam SR_FP_GPIO   = 8'd201;
   localparam SR_RX_FRONT  = 8'd208;
   localparam SR_TX_FRONT  = 8'd216;
   localparam SR_CODEC_IDLE = 8'd250;

   wire 	set_stb;
   wire [7:0] 	set_addr;
   wire [31:0] 	set_data;
   wire 	set_stb_b;
   wire [7:0] 	set_addr_b;
   wire [31:0] 	set_data_b;

   wire [31:0] 	fp_gpio_readback, gpio_readback, spi_readback;
   wire 	run_rx, run_tx;
   wire 	strobe_tx;

   wire 	spi_ready;

   reg [63:0] 	rb_data;
   wire [2:0] 	rb_addr;
   wire [63:0] 	vita_time, vita_time_lastpps;
   wire [31:0] test_readback;
   wire        loopback;
   
   wire [31:0] debug_sfc;
   

   radio_ctrl_proc radio_ctrl_proc
     (.clk(radio_clk), .reset(radio_rst), .clear(1'b0),
      .ctrl_tdata(ctrl_tdata_r), .ctrl_tlast(ctrl_tlast_r), .ctrl_tvalid(ctrl_tvalid_r), .ctrl_tready(ctrl_tready_r),
      .resp_tdata(resp_tdata_r), .resp_tlast(resp_tlast_r), .resp_tvalid(resp_tvalid_r), .resp_tready(resp_tready_r),
      .vita_time(vita_time),
      .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
      .ready(spi_ready), .readback(rb_data),
      .debug());

   // Radio Readback Mux
   always @*
     case(rb_addr)
       3'd0 : rb_data <= {spi_readback, gpio_readback};
       3'd1 : rb_data <= vita_time;
       3'd2 : rb_data <= vita_time_lastpps;
       3'd3 : rb_data <= {rx, test_readback};
       3'd4 : rb_data <= {misc_ins, fp_gpio_readback};
       3'd5 : rb_data <= {tx,rx};
       3'd6 : rb_data <= {32'h0,RADIO_NUM};
       default : rb_data <= 64'd0;
     endcase // case (rb_addr)

   settings_bus_crossclock
     #(.FLOW_CTRL(0))
       settings_bus_crossclock
       (.clk_a(radio_clk), .rst_a(radio_rst),
	.set_stb_a(set_stb), .set_addr_a(set_addr), .set_data_a(set_data),
	.clk_b(bus_clk), .rst_b(bus_rst),
	.set_stb_b(set_stb_b), .set_addr_b(set_addr_b), .set_data_b(set_data_b),
	.set_ready(1'b1));

   // Write this register with any value to create DAC sync operation
   setting_reg #(.my_addr(SR_DACSYNC), .awidth(8), .width(1)) sr_dacsync
     (.clk(radio_clk), .rst(radio_rst), .strobe(set_stb), .addr(set_addr), .in(set_data),
      .out(), .changed(sync_dacs));

   // Set this register to loop TX data directly to RX data.
   setting_reg #(.my_addr(SR_LOOPBACK), .awidth(8), .width(1)) sr_loopback
     (.clk(radio_clk), .rst(radio_rst), .strobe(set_stb), .addr(set_addr), .in(set_data),
      .out(loopback), .changed());

   // Set this register to put a test value on the readback mux.
   setting_reg #(.my_addr(SR_TEST), .awidth(8), .width(32)) sr_test
     (.clk(radio_clk), .rst(radio_rst), .strobe(set_stb), .addr(set_addr), .in(set_data),
      .out(test_readback), .changed());

   setting_reg #(.my_addr(SR_READBACK), .awidth(8), .width(3)) sr_rdback
     (.clk(radio_clk), .rst(radio_rst), .strobe(set_stb), .addr(set_addr), .in(set_data),
      .out(rb_addr), .changed());

   setting_reg #(.my_addr(SR_MISC_OUTS), .awidth(8), .width(32), .at_reset(32'h0)) sr_misc
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
      .gpio_in(db_gpio_in), .gpio_out(db_gpio_out), .gpio_ddr(db_gpio_ddr), .gpio_sw_rb(gpio_readback));

   gpio_atr #(.BASE(SR_FP_GPIO), .WIDTH(32)) fp_gpio_atr
     (.clk(radio_clk),.reset(radio_rst),
      .set_stb(set_stb),.set_addr(set_addr),.set_data(set_data),
      .rx(run_rx), .tx(run_tx),
      .gpio_in(fp_gpio_in), .gpio_out(fp_gpio_out), .gpio_ddr(fp_gpio_ddr), .gpio_sw_rb(fp_gpio_readback));

   gpio_atr #(.BASE(SR_LEDS), .WIDTH(3), .DEFAULT_DDR(3'b111), .DEFAULT_IDLE(3'b000)) gpio_leds
     (.clk(radio_clk),.reset(radio_rst),
      .set_stb(set_stb),.set_addr(set_addr),.set_data(set_data),
      .rx(run_rx), .tx(run_tx),
      .gpio_in(3'b000), .gpio_out(leds), .gpio_ddr(/*assumed outs*/), .gpio_sw_rb());

   timekeeper 
    #(.SR_TIME_HI(SR_TIME),
      .SR_TIME_LO(SR_TIME+1),
      .SR_TIME_CTRL(SR_TIME+2))
   timekeeper
     (.clk(radio_clk), .reset(radio_rst), .pps(pps), .sync(time_sync), .strobe(1'b1),
      .set_stb(set_stb),.set_addr(set_addr),.set_data(set_data),
      .vita_time(vita_time), .vita_time_lastpps(vita_time_lastpps));

   wire [31:0] tx_idle;
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
      .sample(sample_tx), .run(run_tx), .strobe(strobe_tx),
      .debug());

   tx_responder
    #(.SR_FLOW_CTRL_CYCS_PER_ACK(SR_TX_CTRL+2),
      .SR_FLOW_CTRL_PKTS_PER_ACK(SR_TX_CTRL+3))
   tx_responder
     (.clk(radio_clk), .reset(radio_rst), .clear(1'b0),
      .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
      .ack(tx_ack), .error(tx_error), .packet_consumed(packet_consumed),
      .seqnum(seqnum), .error_code(error_code), .sid(sid),
      .vita_time(vita_time),
      .o_tdata(txresp_tdata_r), .o_tlast(txresp_tlast_r), .o_tvalid(txresp_tvalid_r), .o_tready(txresp_tready_r));

   reg tx_tfirst_bo;
   always @(posedge bus_clk) begin
      if(bus_rst)
         tx_tfirst_bo <= 1'b1;
      else if(tx_tvalid_bo & tx_tready_bo)
         tx_tfirst_bo <= tx_tlast_bo;
   end

   reg [63:0] tx_theader_bo;
   always @(posedge bus_clk) begin
      if (tx_tvalid_bo & tx_tready_bo & tx_tfirst_bo)
         tx_theader_bo <= tx_tdata_bo;
   end

   tx_responder
    #(.SR_FLOW_CTRL_CYCS_PER_ACK(SR_TX_CTRL+4),
      .SR_FLOW_CTRL_PKTS_PER_ACK(SR_TX_CTRL+5))
   tx_responder_pre_fifo
     (.clk(bus_clk), .reset(bus_rst), .clear(1'b0),
      .set_stb(set_stb_b), .set_addr(set_addr_b), .set_data(set_data_b),
      .ack(1'b0), .error(1'b0), .packet_consumed(tx_tvalid_bo & tx_tready_bo & tx_tlast_bo),
      .seqnum(tx_theader_bo[59:48]), .error_code(64'd0), .sid(tx_theader_bo[31:0]),
      .vita_time(64'd0),  //Assumption: FC handler in software does not care about time.
      .o_tdata(txresp_tdata_fifo), .o_tlast(txresp_tlast_fifo), .o_tvalid(txresp_tvalid_fifo), .o_tready(txresp_tready_fifo));

   wire [15:0] 	tx_i_running, tx_q_running;

   generate
      if (DELETE_DSP==0) begin:	tx_dsp
	 duc_chain #(.BASE(SR_TX_DSP), .DSPNO(0), .WIDTH(24), .NEW_HB_INTERP(1),  .DEVICE("7SERIES")) duc_chain
	   (.clk(radio_clk), .rst(radio_rst), .clr(1'b0),
	    .set_stb(set_stb),.set_addr(set_addr),.set_data(set_data),
	    .tx_fe_i(tx_fe_i),.tx_fe_q(tx_fe_q),
	    .sample(sample_tx), .run(run_tx), .strobe(strobe_tx),
	    .debug() );
	 tx_frontend #(.BASE(SR_TX_FRONT), .WIDTH_OUT(16), .IQCOMP_EN(1)) tx_frontend
	   (.clk(radio_clk), .rst(radio_rst),
	    .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
	    .tx_i(tx_fe_i), .tx_q(tx_fe_q), .run(run_tx),
	    .dac_a(tx_i_running), .dac_b(tx_q_running));
      end
   endgenerate

   assign tx[31:16] = (run_tx)? tx_i_running : tx_idle[31:16];
   assign tx[15:0]  = (run_tx)? tx_q_running : tx_idle[15:0];


   // /////////////////////////////////////////////////////////////////////////////////
   //  RX Chain

   wire 	full, eob_rx;
   wire 	strobe_rx;
   wire [31:0] 	sample_rx;
   wire [31:0] 	  rx_sid;
   wire [11:0] 	  rx_seqnum;

   source_flow_control
    #(.SR_FLOW_CTRL_WINDOW_SIZE(SR_RX_CTRL+6),
      .SR_FLOW_CTRL_WINDOW_EN(SR_RX_CTRL+7))
    rx_sfc
     (.clk(bus_clk), .reset(bus_rst), .clear(1'b0),
      .set_stb(set_stb_b), .set_addr(set_addr_b), .set_data(set_data_b),
      .fc_tdata(rxfc_tdata_b), .fc_tlast(rxfc_tlast_b), .fc_tvalid(rxfc_tvalid_b), .fc_tready(rxfc_tready_b),
      .in_tdata(rx_tdata_b), .in_tlast(rx_tlast_b), .in_tvalid(rx_tvalid_b), .in_tready(rx_tready_b),
      .out_tdata(rx_tdata_b_fc), .out_tlast(rx_tlast_b_fc), .out_tvalid(rx_tvalid_b_fc), .out_tready(rx_tready_b_fc),
      .debug(debug_sfc));

   new_rx_framer #(.BASE(SR_RX_CTRL+4),.CHIPSCOPE(CHIPSCOPE)) new_rx_framer
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

   // /////////////////////////////////////////////////////////////////////////////////
   //  Debug

   assign debug[63:32] = debug_sfc;
   assign debug[31:0] = 32'd0;
   
endmodule // radio
