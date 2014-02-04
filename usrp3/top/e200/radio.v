
// radio top level module
//  Contains all clock-rate DSP components, all radio and hardware controls and settings
//  Communication with outside world is exclusively via a single in/out axi cvita port
//  Paths are separated by the lower 2 bits of stream ID, as follows:
//
//     SID[1:0]   IN                                 OUT
//       0        Transmit Data           (DATA)     Transmit Flow Control, ACK/Error  (CTXT)
//       1        Control (SPI, settings) (CTXT)     Response (readback)               (CTXT)
//       2        Receive Flow Control    (CTXT)     Receive Data                      (DATA)
//       3        Receive Commands        (CTXT)     Receive Command ACK/ERROR         (CTXT)

module radio
  #(parameter chipscope = 0)
  (input radio_clk, input radio_clk_2x, input radio_rst,
   input [31:0] rx, output [31:0] tx, inout [31:0] db_gpio,
   inout [31:0] db_gpio2, //JAB
   output [7:0] sen, output sclk, output mosi, input miso,
   output [7:0] misc_outs, output [2:0] leds,

   input bus_clk, input bus_rst,
   input [63:0] in_tdata, input in_tlast, input in_tvalid, output in_tready,
   output [63:0] out_tdata, output out_tlast, output out_tvalid, input out_tready,
   input [63:0] tx_tdata_bi, input tx_tlast_bi, input tx_tvalid_bi, output tx_tready_bi,
   output [63:0] tx_tdata_bo, output tx_tlast_bo, output tx_tvalid_bo, input tx_tready_bo,
   
   output [31:0] debug
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

   // IJB. _b signals now unused since adding DRAM FIFO.
   wire [63:0] 	 tx_tdata_b, tx_tdata_r;
   wire 	 tx_tready_b, tx_tready_r, tx_tvalid_b, tx_tvalid_r;
   wire 	 tx_tlast_b, tx_tlast_r;

   wire [63:0] 	 txresp_tdata_b, txresp_tdata_r;
   wire 	 txresp_tready_b, txresp_tready_r, txresp_tvalid_b, txresp_tvalid_r;
   wire 	 txresp_tlast_b, txresp_tlast_r;

   wire [63:0] 	 rxfc_tdata_b;
   wire 	 rxfc_tready_b, rxfc_tvalid_b, rxfc_tlast_b;

    wire [63:0] 	 rx_mux_tdata_r;
   wire 	 rx_mux_tready_r, rx_mux_tvalid_r;
   wire 	 rx_mux_tlast_r;

   wire [63:0] 	 rx_err_tdata_r;
   wire 	 rx_err_tready_r, rx_err_tvalid_r;
   wire 	 rx_err_tlast_r;
   //IJB debug
   wire [63:0] 	 tx_tdata_bo_debug;
   wire 	 tx_tlast_bo_debug, tx_tvalid_bo_debug, tx_tready_bo_debug;
   
	      
   axi_mux4 #(.PRIO(0), .WIDTH(64), .BUFFER(1)) radio_mux
     (.clk(bus_clk), .reset(bus_rst), .clear(1'b0),
      .i0_tdata(txresp_tdata_b), .i0_tlast(txresp_tlast_b), .i0_tvalid(txresp_tvalid_b), .i0_tready(txresp_tready_b), // TX Flow Control/ACK
      .i1_tdata(resp_tdata_b), .i1_tlast(resp_tlast_b), .i1_tvalid(resp_tvalid_b), .i1_tready(resp_tready_b), // Control Response
      .i2_tdata(rx_tdata_b_fc), .i2_tlast(rx_tlast_b_fc), .i2_tvalid(rx_tvalid_b_fc), .i2_tready(rx_tready_b_fc), // RX Data
      .i3_tdata(), .i3_tlast(), .i3_tvalid(1'b0), .i3_tready(),   // RX Command ACK/ERR
      .o_tdata(out_tdata), .o_tlast(out_tlast), .o_tvalid(out_tvalid), .o_tready(out_tready));

   wire [63:0] 	 vheader;
   wire [1:0] 	 vdest = vheader[1:0];  // Switch by bottom 2 bits of SID

   axi_demux4 #(.ACTIVE_CHAN(4'b0111), .WIDTH(64)) radio_demux
     (.clk(bus_clk), .reset(bus_rst), .clear(1'b0),
      .header(vheader), .dest(vdest),
      .i_tdata(in_tdata), .i_tlast(in_tlast), .i_tvalid(in_tvalid), .i_tready(in_tready),
      .o0_tdata(tx_tdata_bo), .o0_tlast(tx_tlast_bo), .o0_tvalid(tx_tvalid_bo), .o0_tready(tx_tready_bo),  // TX Data
      .o1_tdata(ctrl_tdata_b), .o1_tlast(ctrl_tlast_b), .o1_tvalid(ctrl_tvalid_b), .o1_tready(ctrl_tready_b),  // Control
      .o2_tdata(rxfc_tdata_b), .o2_tlast(rxfc_tlast_b), .o2_tvalid(rxfc_tvalid_b), .o2_tready(rxfc_tready_b), // RX Flow Control
      .o3_tdata(), .o3_tlast(), .o3_tvalid(), .o3_tready(1'b1)); // RX Command
/* -----\/----- EXCLUDED -----\/-----
   axi_demux4 #(.ACTIVE_CHAN(4'b0011), .WIDTH(64)) radio_demux
     (.clk(bus_clk), .reset(bus_rst), .clear(1'b0),
      .header(vheader), .dest(vdest),
      .i_tdata(in_tdata), .i_tlast(in_tlast), .i_tvalid(in_tvalid), .i_tready(in_tready),
      .o0_tdata(tx_tdata_bo_debug), .o0_tlast(tx_tlast_bo_debug), .o0_tvalid(tx_tvalid_bo_debug), .o0_tready(tx_tready_bo_debug),  // TX Data
      .o1_tdata(ctrl_tdata_b), .o1_tlast(ctrl_tlast_b), .o1_tvalid(ctrl_tvalid_b), .o1_tready(ctrl_tready_b),  // Control
      .o2_tdata(rxfc_tdata_b), .o2_tlast(rxfc_tlast_b), .o2_tvalid(rxfc_tvalid_b), .o2_tready(rxfc_tready_b), // RX Flow Control
      .o3_tdata(), .o3_tlast(), .o3_tvalid(), .o3_tready(1'b1)); // RX Command
 -----/\----- EXCLUDED -----/\----- */

   axi_fifo_2clk #(.WIDTH(65), .SIZE(9)) ctrl_fifo
     (.reset(bus_rst),
      .i_aclk(bus_clk), .i_tvalid(ctrl_tvalid_b), .i_tready(ctrl_tready_b), .i_tdata({ctrl_tlast_b,ctrl_tdata_b}),
      .o_aclk(radio_clk), .o_tvalid(ctrl_tvalid_r), .o_tready(ctrl_tready_r), .o_tdata({ctrl_tlast_r,ctrl_tdata_r}));
 
   axi_fifo_2clk #(.WIDTH(65), .SIZE(13)) tx_fifo
     (.reset(bus_rst),
      .i_aclk(bus_clk), .i_tvalid(tx_tvalid_bi), .i_tready(tx_tready_bi), .i_tdata({tx_tlast_bi,tx_tdata_bi}),
      .o_aclk(radio_clk), .o_tvalid(tx_tvalid_r), .o_tready(tx_tready_r), .o_tdata({tx_tlast_r,tx_tdata_r}));
/* -----\/----- EXCLUDED -----\/-----
   axi_fifo_2clk #(.WIDTH(65), .SIZE(13)) tx_fifo
     (.reset(bus_rst),
      .i_aclk(bus_clk), .i_tvalid(tx_tvalid_bo_debug), .i_tready(tx_tready_bo_debug), .i_tdata({tx_tlast_bo_debug,tx_tdata_bo_debug}),
      .o_aclk(radio_clk), .o_tvalid(tx_tvalid_r), .o_tready(tx_tready_r), .o_tdata({tx_tlast_r,tx_tdata_r}));
 -----/\----- EXCLUDED -----/\----- */
   
   axi_fifo_2clk #(.WIDTH(65), .SIZE(9)) resp_fifo
     (.reset(radio_rst),
      .i_aclk(radio_clk), .i_tvalid(resp_tvalid_r), .i_tready(resp_tready_r), .i_tdata({resp_tlast_r,resp_tdata_r}),
      .o_aclk(bus_clk), .o_tvalid(resp_tvalid_b), .o_tready(resp_tready_b), .o_tdata({resp_tlast_b,resp_tdata_b}));
   
   axi_fifo_2clk #(.WIDTH(65), .SIZE(13)) rx_fifo
     (.reset(radio_rst),
      .i_aclk(radio_clk), .i_tvalid(rx_mux_tvalid_r), .i_tready(rx_mux_tready_r), .i_tdata({rx_mux_tlast_r,rx_mux_tdata_r}),
      .o_aclk(bus_clk), .o_tvalid(rx_tvalid_b), .o_tready(rx_tready_b), .o_tdata({rx_tlast_b,rx_tdata_b}));
   
   axi_fifo_2clk #(.WIDTH(65), .SIZE(9)) txresp_fifo
     (.reset(radio_rst),
      .i_aclk(radio_clk), .i_tvalid(txresp_tvalid_r), .i_tready(txresp_tready_r), .i_tdata({txresp_tlast_r,txresp_tdata_r}),
      .o_aclk(bus_clk), .o_tvalid(txresp_tvalid_b), .o_tready(txresp_tready_b), .o_tdata({txresp_tlast_b,txresp_tdata_b}));
         
   // /////////////////////////////////////////////////////////////////////////////////////
   // Setting bus and controls
   
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
   localparam SR_CODEC_IDLE = 8'd100;
   localparam SR_GPIO2      = 8'd116;


   wire 	set_stb;
   wire [7:0] 	set_addr;
   wire [31:0] 	set_data;
   wire 	set_stb_b;
   wire [7:0] 	set_addr_b;
   wire [31:0] 	set_data_b;
   
   wire [31:0] 	gpio_readback, spi_readback;
   wire 	run_rx, run_tx;
   wire 	strobe_tx;
   
   wire 	spi_ready;

   reg [63:0] 	rb_data;
   wire [1:0] 	rb_addr;
   wire [63:0] 	vita_time, vita_time_lastpps;
   wire [31:0] test_readback;

         

   radio_ctrl_proc radio_ctrl_proc
     (.clk(radio_clk), .reset(radio_rst), .clear(1'b0),
      .ctrl_tdata(ctrl_tdata_r), .ctrl_tlast(ctrl_tlast_r), .ctrl_tvalid(ctrl_tvalid_r), .ctrl_tready(ctrl_tready_r),
      .resp_tdata(resp_tdata_r), .resp_tlast(resp_tlast_r), .resp_tvalid(resp_tvalid_r), .resp_tready(resp_tready_r),
      .vita_time(vita_time),
      .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
      .ready(spi_ready), .readback(rb_data),
      .debug());

   always @*
     case(rb_addr)
       2'd0 : rb_data <= { spi_readback, test_readback };
       2'd1 : rb_data <= vita_time;
       2'd2 : rb_data <= vita_time_lastpps;
       2'd3 : rb_data <= {tx, rx};
       default : rb_data <= 64'd0;
     endcase // case (rb_addr)

   settings_bus_crossclock
     #(.FLOW_CTRL(0))
       (.clk_i(radio_clk), .rst_i(radio_rst), 
	.set_stb_i(set_stb), .set_addr_i(set_addr), .set_data_i(set_data),
	.clk_o(bus_clk), .rst_o(bus_rst), 
	.set_stb_o(set_stb_b), .set_addr_o(set_addr_b), .set_data_o(set_data_b), 
	.blocked(1'b0));

   
   setting_reg #(.my_addr(SR_TEST), .awidth(8), .width(32)) sr_test
     (.clk(radio_clk), .rst(radio_rst), .strobe(set_stb), .addr(set_addr), .in(set_data),
      .out(test_readback), .changed());

   setting_reg #(.my_addr(SR_READBACK), .awidth(8), .width(2)) sr_rdback
     (.clk(radio_clk), .rst(radio_rst), .strobe(set_stb), .addr(set_addr), .in(set_data),
      .out(rb_addr), .changed());
     
   setting_reg #(.my_addr(SR_MISC_OUTS), .awidth(8), .width(8), .at_reset(8'h0)) sr_misc
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

   gpio_atr #(.BASE(SR_LEDS), .WIDTH(3)) gpio_leds
     (.clk(radio_clk),.reset(radio_rst),
      .set_stb(set_stb),.set_addr(set_addr),.set_data(set_data),
      .rx(run_rx), .tx(run_tx),
      .gpio(leds), .gpio_readback() );

   timekeeper #(.BASE(SR_TIME)) timekeeper
     (.clk(radio_clk), .reset(radio_rst), .pps(),
      .set_stb(set_stb),.set_addr(set_addr),.set_data(set_data),
      .vita_time(vita_time), .vita_time_lastpps(vita_time_lastpps));

   wire [31:0] tx_idle;
   setting_reg #(.my_addr(SR_CODEC_IDLE), .awidth(8), .width(32)) sr_codec_idle
     (.clk(radio_clk), .rst(radio_rst), .strobe(set_stb), .addr(set_addr), .in(set_data),
      .out(tx_idle), .changed());

   gpio_atr #(.BASE(SR_GPIO2), .WIDTH(32)) gpio_atr2
     (.clk(radio_clk),.reset(radio_rst),
      .set_stb(set_stb),.set_addr(set_addr),.set_data(set_data),
      .rx(run_rx), .tx(run_tx),
      .gpio(db_gpio2), .gpio_readback() );

   // /////////////////////////////////////////////////////////////////////////////////
   //  TX Chain

   wire [175:0] txsample_tdata;
   wire 	txsample_tvalid, txsample_tready;
   wire [31:0] 	sample_tx;
   wire 	ack_or_error, packet_consumed;
   wire [11:0] 	seqnum;
   wire [63:0] 	error_code;
   wire [31:0] 	sid;
   wire [23:0] tx_fe_i, tx_fe_q;

   assign tx[31:16] = (run_tx)? tx_fe_i[23:8] : tx_idle[31:16];
   assign tx[15:0]  = (run_tx)? tx_fe_q[23:8] : tx_idle[15:0];

   new_tx_deframer tx_deframer
     (.clk(radio_clk), .reset(radio_rst), .clear(1'b0),
      .i_tdata(tx_tdata_r), .i_tlast(tx_tlast_r), .i_tvalid(tx_tvalid_r), .i_tready(tx_tready_r),
      .sample_tdata(txsample_tdata), .sample_tvalid(txsample_tvalid), .sample_tready(txsample_tready));

   new_tx_control #(.BASE(SR_TX_CTRL)) tx_control
     (.clk(radio_clk), .reset(radio_rst), .clear(1'b0),
      .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
      .vita_time(vita_time),
      .ack_or_error(ack_or_error), .packet_consumed(packet_consumed),
      .seqnum(seqnum), .error_code(error_code), .sid(sid),
      .sample_tdata(txsample_tdata), .sample_tvalid(txsample_tvalid), .sample_tready(txsample_tready),
      .sample(sample_tx), .run(run_tx), .strobe(strobe_tx),
      .debug());

   tx_responder #(.BASE(SR_TX_CTRL+2)) tx_responder
     (.clk(radio_clk), .reset(radio_rst), .clear(1'b0),
      .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
      .ack_or_error(ack_or_error), .packet_consumed(packet_consumed),
      .seqnum(seqnum), .error_code(error_code), .sid(sid),
      .vita_time(vita_time),
      .o_tdata(txresp_tdata_r), .o_tlast(txresp_tlast_r), .o_tvalid(txresp_tvalid_r), .o_tready(txresp_tready_r));

   duc_chain #(.BASE(SR_TX_DSP), .DSPNO(0), .WIDTH(24)) duc_chain
     (.clk(radio_clk), .rst(radio_rst), .clr(1'b0),
      .set_stb(set_stb),.set_addr(set_addr),.set_data(set_data),
      .tx_fe_i(tx_fe_i),.tx_fe_q(tx_fe_q),
      .sample(sample_tx), .run(run_tx), .strobe(strobe_tx),
      .debug() );

   // /////////////////////////////////////////////////////////////////////////////////
   //  RX Chain

   wire 	full, eob_rx;
   wire 	strobe_rx;
   wire [31:0] 	sample_rx;
   wire [31:0] 	  rx_sid;
   wire [11:0] 	  rx_seqnum;

   
   source_flow_control #(.BASE(SR_RX_CTRL+6)) rx_sfc
     (.clk(bus_clk), .reset(bus_rst), .clear(1'b0),
      .set_stb(set_stb_b), .set_addr(set_addr_b), .set_data(set_data_b),
      .fc_tdata(rxfc_tdata_b), .fc_tlast(rxfc_tlast_b), .fc_tvalid(rxfc_tvalid_b), .fc_tready(rxfc_tready_b),
      .in_tdata(rx_tdata_b), .in_tlast(rx_tlast_b), .in_tvalid(rx_tvalid_b), .in_tready(rx_tready_b),
      .out_tdata(rx_tdata_b_fc), .out_tlast(rx_tlast_b_fc), .out_tvalid(rx_tvalid_b_fc), .out_tready(rx_tready_b_fc) );
   
   new_rx_framer #(.BASE(SR_RX_CTRL+4)) new_rx_framer
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

   ddc_chain #(.BASE(SR_RX_DSP), .DSPNO(0), .WIDTH(24)) ddc_chain
     (.clk(radio_clk), .rst(radio_rst), .clr(1'b0),
      .set_stb(set_stb),.set_addr(set_addr),.set_data(set_data),
      .rx_fe_i({rx[31:16],8'd0}),.rx_fe_q({rx[15:0],8'd0}),
      .sample(sample_rx), .run(run_rx), .strobe(strobe_rx),
      .debug() );

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

    reg [19:0] ramp;
    always @(posedge radio_clk) ramp <= ramp + 1;

   //assign tx = {ramp[19:4], ramp[19:4]};
   assign debug = rx;

   generate
      if (chipscope) begin: chipscope_gen

   wire [35:0] CONTROL0;
   (* keep = "true", max_fanout = 10 *)   reg [5:0]	  debug_error_code;        // 174:169
   (* keep = "true", max_fanout = 10 *)   reg 		  debug_ack_or_error;      // 168
   (* keep = "true", max_fanout = 10 *)   reg 		  debug_run_tx;            // 167
   (* keep = "true", max_fanout = 10 *)   reg 		  debug_strobe_tx;         // 166
   (* keep = "true", max_fanout = 10 *)   reg 		  debug_txresp_tvalid_r;   // 165
   (* keep = "true", max_fanout = 10 *)   reg 		  debug_txresp_tready_r;   // 164
   (* keep = "true", max_fanout = 10 *)   reg 		  debug_txresp_tlast_r;    // 163
   (* keep = "true", max_fanout = 10 *)   reg 		  debug_tx_tvalid_r;   // 162
   (* keep = "true", max_fanout = 10 *)   reg 		  debug_tx_tready_r;   // 161
   (* keep = "true", max_fanout = 10 *)   reg 		  debug_tx_tlast_r;    // 160
   (* keep = "true", max_fanout = 10 *)   reg [31:0] 	  debug_sample_tx;         // 159:128
   (* keep = "true", max_fanout = 10 *)   reg [63:0] 	  debug_txresp_tdata_r;    // 127:64
   (* keep = "true", max_fanout = 10 *)   reg [63:0] 	  debug_tx_tdata_r;    // 63:0

   always @(posedge radio_clk) begin
      debug_error_code <= error_code[37:32];
      debug_ack_or_error <= ack_or_error;
      debug_run_tx <=  run_tx ;
      debug_strobe_tx <= strobe_tx;
      debug_txresp_tvalid_r <= txresp_tvalid_r;
      debug_txresp_tready_r <= txresp_tready_r;
      debug_txresp_tlast_r <=  txresp_tlast_r;
      debug_tx_tvalid_r <=  tx_tvalid_r ;
      debug_tx_tready_r <=   tx_tready_r;
      debug_tx_tlast_r <=  tx_tlast_r;
      debug_sample_tx[31:0] <=  sample_tx[31:0];
      debug_txresp_tdata_r[63:0] <= txresp_tdata_r[63:0];
      debug_tx_tdata_r[63:0] <= tx_tdata_r[63:0];
   end
   
   chipscope_icon chipscope_icon_i0
     (
      .CONTROL0(CONTROL0) // INOUT BUS [35:0]
      );

   chipscope_ila chipscope_ila_i0
     (
      .CONTROL(CONTROL0), // INOUT BUS [35:0]
      .CLK(radio_clk), // IN
      .TRIG0(
	     {
	
	      debug_error_code[5:0],         // 174:169
	      debug_ack_or_error,            // 168
	      debug_run_tx,                  // 167
	      debug_strobe_tx,               // 166
	      debug_txresp_tvalid_r,         // 165
	      debug_txresp_tready_r,         // 164
	      debug_txresp_tlast_r,          // 163
	      debug_tx_tvalid_r,         // 162
	      debug_tx_tready_r,         // 161
	      debug_tx_tlast_r,          // 160
	      debug_sample_tx[31:0],         // 159:128
	      debug_txresp_tdata_r[63:0],    // 127:64
	      debug_tx_tdata_r[63:0]     // 63:0
	      })
      );
end // block: chipscope
      endgenerate
   
      
   
endmodule // radio
