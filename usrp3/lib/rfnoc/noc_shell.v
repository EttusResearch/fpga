//
// Copyright 2014 Ettus Research LLC
//
// Issues
//   Inline vs. Async commands
//   Command and Response forwarding
//   Different seqnums on incoming and outgoing
//   Multiple streams
//   Seqnum for different types

module noc_shell
  #(parameter NOC_ID = 64'hDEAD_BEEF_0123_4567,
    parameter STR_SINK_FIFOSIZE = 10,
    parameter MTU = 10,
    parameter INPUT_PORTS = 1,
    parameter OUTPUT_PORTS = 1,
    parameter USE_GATE = 0)
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
    output [INPUT_PORTS*64-1:0] str_sink_tdata, output [INPUT_PORTS-1:0] str_sink_tlast,
    output [INPUT_PORTS-1:0] str_sink_tvalid, input [INPUT_PORTS-1:0] str_sink_tready,
    
    // Stream Source
    input [OUTPUT_PORTS*64-1:0] str_src_tdata, input [OUTPUT_PORTS-1:0] str_src_tlast,
    input [OUTPUT_PORTS-1:0] str_src_tvalid, output [OUTPUT_PORTS-1:0] str_src_tready,

    // Clear TX Sequence Number
    output clear_tx_seqnum,

    output [63:0] debug
    );

   // One register per port, spaced by 16 for 16 ports
   localparam SR_FLOW_CTRL_CYCS_PER_ACK_BASE = 0;
   localparam SR_FLOW_CTRL_PKTS_PER_ACK_BASE = 16;
   localparam SR_FLOW_CTRL_WINDOW_SIZE_BASE  = 32;
   localparam SR_FLOW_CTRL_WINDOW_EN_BASE    = 48;

   // One register per noc shell
   localparam SR_CLEAR_TX_FC                 = 126;
   localparam SR_RB_ADDR                     = 127;
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
   axi_fifo_2clk_cascade #(.WIDTH(65), .SIZE(5)) in_fifo   // Very little buffering needed here, only a clock domain crossing
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

   setting_reg #(.my_addr(SR_RB_ADDR), .width(2), .at_reset(0)) sr_rb_addr
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
   // Stream Source
 
   wire [64*OUTPUT_PORTS-1:0] dataout_ports_tdata;
   wire [OUTPUT_PORTS-1:0]    dataout_ports_tvalid, dataout_ports_tready, dataout_ports_tlast;
   
   wire [64*OUTPUT_PORTS-1:0] fcin_ports_tdata;
   wire [OUTPUT_PORTS-1:0]    fcin_ports_tvalid, fcin_ports_tready, fcin_ports_tlast;

   wire [63:0] 		      header_fcin;
   
   genvar 		      i;
   generate
      if(OUTPUT_PORTS == 1)
         noc_output_port
           #(.SR_FLOW_CTRL_WINDOW_SIZE(SR_FLOW_CTRL_WINDOW_SIZE_BASE),
             .SR_FLOW_CTRL_WINDOW_EN(SR_FLOW_CTRL_WINDOW_EN_BASE),
             .PORT_NUM(0), .MTU(MTU), .USE_GATE(USE_GATE))
         noc_output_port_0
	  (.clk(clk), .reset(reset),
	   .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
	   .dataout_tdata(dataout_tdata), .dataout_tlast(dataout_tlast), .dataout_tvalid(dataout_tvalid), .dataout_tready(dataout_tready),
	   .fcin_tdata(fcin_tdata), .fcin_tlast(fcin_tlast), .fcin_tvalid(fcin_tvalid), .fcin_tready(fcin_tready),
	   .str_src_tdata(str_src_tdata), .str_src_tlast(str_src_tlast), .str_src_tvalid(str_src_tvalid), .str_src_tready(str_src_tready));
      else
	begin
	   for(i=0 ; i < OUTPUT_PORTS ; i = i + 1)
         noc_output_port
           #(.SR_FLOW_CTRL_WINDOW_SIZE(SR_FLOW_CTRL_WINDOW_SIZE_BASE+i),
             .SR_FLOW_CTRL_WINDOW_EN(SR_FLOW_CTRL_WINDOW_EN_BASE+i),
             .PORT_NUM(i), .MTU(MTU), .USE_GATE(USE_GATE))
         noc_output_port_0
		 (.clk(clk), .reset(reset),
		  .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
		  .dataout_tdata(dataout_ports_tdata[64*i+63:64*i]), .dataout_tlast(dataout_ports_tlast[i]),
		  .dataout_tvalid(dataout_ports_tvalid[i]), .dataout_tready(dataout_ports_tready[i]),
		  .fcin_tdata(fcin_ports_tdata[64*i+63:64*i]), .fcin_tlast(fcin_ports_tlast[i]),
		  .fcin_tvalid(fcin_ports_tvalid[i]), .fcin_tready(fcin_ports_tready[i]),
		  .str_src_tdata(str_src_tdata[64*i+63:64*i]), .str_src_tlast(str_src_tlast[i]),
		  .str_src_tvalid(str_src_tvalid[i]), .str_src_tready(str_src_tready[i]));
	   axi_mux #(.PRIO(0), .WIDTH(64), .BUFFER(0), .SIZE(OUTPUT_PORTS)) mux_dataout
	     (.clk(clk), .reset(reset), .clear(0),
	      .i_tdata(dataout_ports_tdata), .i_tlast(dataout_ports_tlast), .i_tvalid(dataout_ports_tvalid), .i_tready(dataout_ports_tready),
	      .o_tdata(dataout_tdata), .o_tlast(dataout_tlast), .o_tvalid(dataout_tvalid), .o_tready(dataout_tready));
	   axi_demux #(.WIDTH(64), .SIZE(OUTPUT_PORTS)) demux_fcin
	     (.clk(clk), .reset(reset), .clear(0),
	      .header(header_fcin), .dest(header_fcin[3:0]),
	      .i_tdata(fcin_tdata), .i_tlast(fcin_tlast), .i_tvalid(fcin_tvalid), .i_tready(fcin_tready),
	      .o_tdata(fcin_ports_tdata), .o_tlast(fcin_ports_tlast), .o_tvalid(fcin_ports_tvalid), .o_tready(fcin_ports_tready));
	end
   endgenerate
   
   // ////////////////////////////////////////////////////////////////////////////////////
   // Stream Sink

   wire [64*INPUT_PORTS-1:0] datain_ports_tdata;
   wire [INPUT_PORTS-1:0]    datain_ports_tvalid, datain_ports_tready, datain_ports_tlast;
   
   wire [64*INPUT_PORTS-1:0] fcout_ports_tdata;
   wire [INPUT_PORTS-1:0]    fcout_ports_tvalid, fcout_ports_tready, fcout_ports_tlast;

   wire [63:0] 		      header_datain;
   wire 		      clear_tx_fc;
   // Clearing the flow control window can also be used to reset the sequence number
   assign clear_tx_seqnum = clear_tx_fc;
   
   setting_reg #(.my_addr(SR_CLEAR_TX_FC), .at_reset(0)) sr_clear_tx_fc
     (.clk(clk),.rst(reset),.strobe(set_stb),.addr(set_addr),
      .in(set_data),.out(),.changed(clear_tx_fc));

   genvar 	 j;
   generate
      if(INPUT_PORTS == 1)
	noc_input_port
     #(.SR_FLOW_CTRL_CYCS_PER_ACK(SR_FLOW_CTRL_CYCS_PER_ACK_BASE),
       .SR_FLOW_CTRL_PKTS_PER_ACK(SR_FLOW_CTRL_PKTS_PER_ACK_BASE),
       .PORT_NUM(0),
       .STR_SINK_FIFOSIZE(STR_SINK_FIFOSIZE))
    inst_noc_input_port
	  (.clk(clk), .reset(reset),
	   .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
	   .datain_tdata(datain_tdata), .datain_tlast(datain_tlast), .datain_tvalid(datain_tvalid), .datain_tready(datain_tready),
	   .fcout_tdata(fcout_tdata), .fcout_tlast(fcout_tlast), .fcout_tvalid(fcout_tvalid), .fcout_tready(fcout_tready),
	   .clear_tx_fc(clear_tx_fc),
	   .str_sink_tdata(str_sink_tdata), .str_sink_tlast(str_sink_tlast), .str_sink_tvalid(str_sink_tvalid), .str_sink_tready(str_sink_tready));
      else
	begin
	   for(j=0; j<INPUT_PORTS; j=j+1)
         noc_input_port
          #(.SR_FLOW_CTRL_CYCS_PER_ACK(SR_FLOW_CTRL_CYCS_PER_ACK_BASE+j),
            .SR_FLOW_CTRL_PKTS_PER_ACK(SR_FLOW_CTRL_PKTS_PER_ACK_BASE+j),
            .PORT_NUM(j),
            .STR_SINK_FIFOSIZE(STR_SINK_FIFOSIZE))
         inst_noc_input_port
		 (.clk(clk), .reset(reset),
		  .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
		  .datain_tdata(datain_ports_tdata[64*j+63:64*j]), .datain_tlast(datain_ports_tlast[j]),
		  .datain_tvalid(datain_ports_tvalid[j]), .datain_tready(datain_ports_tready[j]),
		  .fcout_tdata(fcout_ports_tdata[64*j+63:64*j]), .fcout_tlast(fcout_ports_tlast[j]),
		  .fcout_tvalid(fcout_ports_tvalid[j]), .fcout_tready(fcout_ports_tready[j]),
		  .clear_tx_fc(clear_tx_fc),
		  .str_sink_tdata(str_sink_tdata[64*j+63:64*j]), .str_sink_tlast(str_sink_tlast[j]),
		  .str_sink_tvalid(str_sink_tvalid[j]), .str_sink_tready(str_sink_tready[j]));
	   axi_demux #(.WIDTH(64), .SIZE(INPUT_PORTS)) demux_datain
	     (.clk(clk), .reset(reset), .clear(0),
	      .header(header_datain), .dest(header_datain[3:0]),
	      .i_tdata(datain_tdata), .i_tlast(datain_tlast), .i_tvalid(datain_tvalid), .i_tready(datain_tready),
	      .o_tdata(datain_ports_tdata), .o_tlast(datain_ports_tlast), .o_tvalid(datain_ports_tvalid), .o_tready(datain_ports_tready));
	   axi_mux #(.PRIO(0), .WIDTH(64), .BUFFER(0), .SIZE(INPUT_PORTS)) mux_fcout
	     (.clk(clk), .reset(reset), .clear(0),
	      .i_tdata(fcout_ports_tdata), .i_tlast(fcout_ports_tlast), .i_tvalid(fcout_ports_tvalid), .i_tready(fcout_ports_tready),
	      .o_tdata(fcout_tdata), .o_tlast(fcout_tlast), .o_tvalid(fcout_tvalid), .o_tready(fcout_tready));
	   
	end
   endgenerate
      
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
