

// Issues
//   Inline vs. Async commands
//   Command and Response forwarding
//   Different seqnums on incoming and outgoing
//   Multiple streams
//   Seqnum for different types

module noc_shell
  #(parameter NOC_ID = 64'hDEAD_BEEF_0123_4567,
    parameter STR_SINK_FIFOSIZE = 10,
    parameter MTU = 10)
   (// RFNoC interfaces, to Crossbar, all on bus_clk
    input bus_clk, input bus_rst,
    input [63:0] i_tdata, input i_tlast, input i_tvalid, output i_tready,
    output [63:0] o_tdata, output o_tlast, output o_tvalid, input o_tready,

    // Computation Engine interfaces, all on local clock
    input clk, input reset,
    
    // Control Sink
    output [31:0] set_data, output [7:0] set_addr, output set_stb, input [63:0] rb_data,

    // Control Source
    input [63:0] cmdout_tdata, input cmdout_tlast, input cmdout_tvalid, output cmdout_tready,
    output [63:0] ackin_tdata, output ackin_tlast, output ackin_tvalid, input ackin_tready,
    
    // Stream Sink
    output [63:0] str_sink_tdata, output str_sink_tlast, output str_sink_tvalid, input str_sink_tready,
    
    // Stream Source
    input [63:0] str_src_tdata, input str_src_tlast, input str_src_tvalid, output str_src_tready,

    output [63:0] debug
    );

   localparam SB_INPUT_BASE  = 0;    // 2 regs per port, 16 ports
   localparam SB_OUTPUT_BASE = 32;   // 2 regs per port, 16 ports
   localparam SB_CLEAR_TX_FC = 126;  // 1 reg
   localparam SB_RB_ADDR = 127;      // 1 reg
   // Allocate all regs 128-255 to user device
   
   wire [63:0] 	  dataout_tdata, datain_tdata, fcin_tdata, fcout_tdata,
		  cmdin_tdata,  ackout_tdata;
   wire 	  dataout_tlast, datain_tlast, fcin_tlast, fcout_tlast,
		  cmdin_tlast,  ackout_tlast;
   wire 	  dataout_tvalid, datain_tvalid, fcin_tvalid, fcout_tvalid,
		  cmdin_tvalid, ackout_tvalid;
   wire 	  dataout_tready, datain_tready, fcin_tready, fcout_tready,
		  cmdin_tready,  ackout_tready;

   wire [31:0] 	  debug_sfc;
   
   // ////////////////////////////////////////////////////////////////////////////////////
   // 2-clock fifos to get the computation engine on its own clock

   wire [63:0] 	  i_tdata_b, o_tdata_b;
   wire 	  i_tlast_b, o_tlast_b, i_tvalid_b, o_tvalid_b, i_tready_b, o_tready_b;
   axi_fifo_2clk_cascade #(.WIDTH(65), .SIZE(9)) in_fifo
     (.reset(bus_rst),
      .i_aclk(bus_clk), .i_tvalid(i_tvalid), .i_tready(i_tready), .i_tdata({i_tlast,i_tdata}),
      .o_aclk(clk), .o_tvalid(i_tvalid_b), .o_tready(i_tready_b), .o_tdata({i_tlast_b,i_tdata_b}));
   
   axi_fifo_2clk_cascade #(.WIDTH(65), .SIZE(9)) out_fifo
     (.reset(bus_rst),
      .i_aclk(clk), .i_tvalid(o_tvalid_b), .i_tready(o_tready_b), .i_tdata({o_tlast_b,o_tdata_b}),
      .o_aclk(bus_clk), .o_tvalid(o_tvalid), .o_tready(o_tready), .o_tdata({o_tlast,o_tdata}));
   
   // ////////////////////////////////////////////////////////////////////////////////////
   // Mux and Demux to join/split streams going to/coming from RFNoC
   
   axi_mux4 #(.PRIO(0), .WIDTH(64), .BUFFER(1)) output_mux
     (.clk(clk), .reset(reset), .clear(1'b0),
      .i0_tdata(dataout_tdata), .i0_tlast(dataout_tlast), .i0_tvalid(dataout_tvalid), .i0_tready(dataout_tready),
      .i1_tdata(fcout_tdata), .i1_tlast(fcout_tlast), .i1_tvalid(fcout_tvalid), .i1_tready(fcout_tready),
      .i2_tdata(cmdout_tdata), .i2_tlast(cmdout_tlast), .i2_tvalid(cmdout_tvalid), .i2_tready(cmdout_tready),
      .i3_tdata(ackout_tdata), .i3_tlast(ackout_tlast), .i3_tvalid(ackout_tvalid), .i3_tready(ackout_tready),
      .o_tdata(o_tdata_b), .o_tlast(o_tlast_b), .o_tvalid(o_tvalid_b), .o_tready(o_tready_b));

   wire [63:0] 	 vheader;
   wire [1:0] 	 vdest = vheader[63:62];  // Switch by packet type

   axi_demux4 #(.ACTIVE_CHAN(4'b1111), .WIDTH(64)) input_demux
     (.clk(clk), .reset(reset), .clear(1'b0),
      .header(vheader), .dest(vdest),
      .i_tdata(i_tdata_b), .i_tlast(i_tlast_b), .i_tvalid(i_tvalid_b), .i_tready(i_tready_b),
      .o0_tdata(datain_tdata), .o0_tlast(datain_tlast), .o0_tvalid(datain_tvalid), .o0_tready(datain_tready),
      .o1_tdata(fcin_tdata), .o1_tlast(fcin_tlast), .o1_tvalid(fcin_tvalid), .o1_tready(fcin_tready), // FIXME may need
      .o2_tdata(cmdin_tdata), .o2_tlast(cmdin_tlast), .o2_tvalid(cmdin_tvalid), .o2_tready(cmdin_tready),
      .o3_tdata(ackin_tdata), .o3_tlast(ackin_tlast), .o3_tvalid(ackin_tvalid), .o3_tready(ackin_tready));

   // ////////////////////////////////////////////////////////////////////////////////////
   // Control Sink (required)

   wire 	 ready = 1'b1;
   wire [63:0] 	 vita_time = 64'd0;
   wire [1:0] 	 rb_addr;
   reg [63:0] 	 rb_data_int;
   wire [63:0] 	 buffer_alloc = { 56'h0, STR_SINK_FIFOSIZE[7:0] };
   
   radio_ctrl_proc radio_ctrl_proc
     (.clk(clk), .reset(reset), .clear(1'b0),
      .ctrl_tdata(cmdin_tdata), .ctrl_tlast(cmdin_tlast), .ctrl_tvalid(cmdin_tvalid), .ctrl_tready(cmdin_tready),
      .resp_tdata(ackout_tdata), .resp_tlast(ackout_tlast), .resp_tvalid(ackout_tvalid), .resp_tready(ackout_tready),
      .vita_time(vita_time),
      .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
      .ready(ready), .readback(rb_data_int),
      .debug());

   setting_reg #(.my_addr(SB_RB_ADDR), .width(2), .at_reset(0)) sr_rb_addr
     (.clk(clk),.rst(reset),.strobe(set_stb),.addr(set_addr),
      .in(set_data),.out(rb_addr),.changed());

   always @(posedge clk)
     case(rb_addr)
       2'd0 : rb_data_int <= NOC_ID;
       2'd1 : rb_data_int <= buffer_alloc;
       2'd2 : rb_data_int <= 64'h0;
       2'd3 : rb_data_int <= rb_data;
     endcase
      
   // ////////////////////////////////////////////////////////////////////////////////////
   // Control Source (skeleton for now)

   assign ackin_tready = 1'b1;    // Dump anything coming in
   assign cmdout_tdata = 64'd0;
   assign cmdout_tlast = 1'b0;
   assign cmdout_tvalid = 1'b0;

   // ////////////////////////////////////////////////////////////////////////////////////
   // Stream Source

   noc_output_port #(.BASE(SB_OUTPUT_BASE), .PORT_NUM(0), .MTU(MTU)) noc_output_port_0
     (.clk(clk), .reset(reset),
      .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
      .dataout_tdata(dataout_tdata), .dataout_tlast(dataout_tlast), .dataout_tvalid(dataout_tvalid), .dataout_tready(dataout_tready),
      .fcin_tdata(fcin_tdata), .fcin_tlast(fcin_tlast), .fcin_tvalid(fcin_tvalid), .fcin_tready(fcin_tready),
      .str_src_tdata(str_src_tdata), .str_src_tlast(str_src_tlast), .str_src_tvalid(str_src_tvalid), .str_src_tready(str_src_tready));
      
   // ////////////////////////////////////////////////////////////////////////////////////
   // Stream Sink

   wire 	 clear_tx_fc;
   
   setting_reg #(.my_addr(SB_CLEAR_TX_FC), .at_reset(0)) sr_clear_tx_fc
     (.clk(clk),.rst(reset),.strobe(set_stb),.addr(set_addr),
      .in(set_data),.out(),.changed(clear_tx_fc));
   
   noc_input_port #(.BASE(SB_INPUT_BASE), .PORT_NUM(0), .STR_SINK_FIFOSIZE(STR_SINK_FIFOSIZE)) noc_input_port_0
     (.clk(clk), .reset(reset),
      .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
      .datain_tdata(datain_tdata), .datain_tlast(datain_tlast), .datain_tvalid(datain_tvalid), .datain_tready(datain_tready),
      .fcout_tdata(fcout_tdata), .fcout_tlast(fcout_tlast), .fcout_tvalid(fcout_tvalid), .fcout_tready(fcout_tready),
      .clear_tx_fc(clear_tx_fc),
      .str_sink_tdata(str_sink_tdata), .str_sink_tlast(str_sink_tlast), .str_sink_tvalid(str_sink_tvalid), .str_sink_tready(str_sink_tready));
   
   // ////////////////////////////////////////////////////////////////////////////////////
   // Debug pins

   assign debug[31:0] = { // input side 16 bits
			  4'b0000,
			  i_tvalid_b, i_tready_b,
			  datain_tvalid, datain_tready,
			  fcin_tvalid, fcin_tready,
			  cmdin_tvalid, cmdin_tready,
			  ackin_tvalid, ackin_tready,
			  str_sink_tvalid, str_sink_tready,
			  // output side 16 bits
			  2'b00,
			  o_tvalid_b, o_tready_b,
			  dataout_tvalid, dataout_tready,
			  fcout_tvalid, fcout_tready,
			  cmdout_tvalid, cmdout_tready,
			  ackout_tvalid, ackout_tready,
			  2'b00,
			  str_src_tvalid, str_src_tready
			  };

   assign debug[63:32] = debug_sfc;
   
endmodule // noc_shell
