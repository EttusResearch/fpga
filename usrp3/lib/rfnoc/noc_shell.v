

// Issues
//   Inline vs. Async commands
//   Command and Response forwarding
//   Different seqnums on incoming and outgoing
//   Multiple streams
//   Seqnum for different types

module noc_shell
  #(parameter STR_SINK_FIFOSIZE = 10)
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
    input [63:0] str_src_tdata, input str_src_tlast, input str_src_tvalid, output str_src_tready
    );

   localparam SB_SFC = 0;   // 2 regs
   localparam SB_FCPG = 2;  // 2 regs
   
   wire [63:0] 	 dataout_tdata, datain_tdata, fcin_tdata, fcout_tdata,
		 cmdin_tdata, cmdout_tdata, ackout_tdata, ackin_tdata;
   wire 	 dataout_tlast, datain_tlast, fcin_tlast, fcout_tlast,
		 cmdin_tlast, cmdout_tlast, ackout_tlast, ackin_tlast;
   wire 	 dataout_tvalid, datain_tvalid, fcin_tvalid, fcout_tvalid,
		 cmdout_tvalid, cmdin_tvalid, ackout_tvalid, ackin_tvalid;
   wire 	 dataout_tready, datain_tready, fcin_tready, fcout_tready,
		 cmdin_tready, cmdout_tready, ackout_tready, ackin_tready;

   // ////////////////////////////////////////////////////////////////////////////////////
   // 2-clock fifos to get the computation engine on its own clock

   wire [63:0] 	 i_tdata_b, o_tdata_b;
   wire 	 i_tlast_b, o_tlast_b, i_tvalid_b, o_tvalid_b, i_tready_b, o_tready_b;
   
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
   
   radio_ctrl_proc radio_ctrl_proc
     (.clk(clk), .reset(reset), .clear(1'b0),
      .ctrl_tdata(cmdin_tdata), .ctrl_tlast(cmdin_tlast), .ctrl_tvalid(cmdin_tvalid), .ctrl_tready(cmdin_tready),
      .resp_tdata(ackout_tdata), .resp_tlast(ackout_tlast), .resp_tvalid(ackout_tvalid), .resp_tready(ackout_tready),
      .vita_time(vita_time),
      .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
      .ready(ready), .readback(rb_data),
      .debug());

   // ////////////////////////////////////////////////////////////////////////////////////
   // Control Source (skeleton for now)

   /*
   assign ackin_tready = 1'b1;    // Dump anything coming in
   assign cmdout_tdata = 64'd0;
   assign cmdout_tlast = 1'b0;
   assign cmdout_tvalid = 1'b0;
   */
   // ////////////////////////////////////////////////////////////////////////////////////
   // Stream Source
   //      FIXME need to pull out feedback from the FBFC bus before the source_flow_control block

   wire [63:0] 	 str_src_tdata_int;
   wire 	 str_src_tlast_int, str_src_tvalid_int, str_src_tready_int;
   
   axi_packet_gate #(.WIDTH(64), .SIZE(9)) str_src_gate
     (.clk(clk), .reset(reset), .clear(1'b0),
      .i_tdata(str_src_tdata), .i_tlast(str_src_tlast), .i_terror(1'b0), .i_tvalid(str_src_tvalid), .i_tready(str_src_tready),
      .o_tdata(str_src_tdata_int), .o_tlast(str_src_tlast_int), .o_tvalid(str_src_tvalid_int), .o_tready(str_src_tready_int));
   
   source_flow_control #(.BASE(SB_SFC)) sfc
     (.clk(clk), .reset(reset), .clear(1'b0),
      .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
      .fc_tdata(fcin_tdata), .fc_tlast(fcin_tlast), .fc_tvalid(fcin_tvalid), .fc_tready(fcin_tready),
      .in_tdata(str_src_tdata_int), .in_tlast(str_src_tlast_int), .in_tvalid(str_src_tvalid_int), .in_tready(str_src_tready_int),
      .out_tdata(dataout_tdata), .out_tlast(dataout_tlast), .out_tvalid(dataout_tvalid), .out_tready(dataout_tready) );
   
   // ////////////////////////////////////////////////////////////////////////////////////
   // Stream Sink
   //      FIXME  do we follow the back of the fifo, or do we allow the device to generate
   //             its own packet_consumed signals?

   axi_fifo #(.WIDTH(65), .SIZE(STR_SINK_FIFOSIZE)) str_sink_fifo
     (.clk(clk), .reset(reset), .clear(1'b0),
      .i_tdata({datain_tlast,datain_tdata}), .i_tvalid(datain_tvalid), .i_tready(datain_tready),
      .o_tdata({str_sink_tlast,str_sink_tdata}), .o_tvalid(str_sink_tvalid), .o_tready(str_sink_tready),
      .space(), .occupied());

   reg [11:0] 	 seqnum_hold;
   reg [31:0] 	 sid_hold;
   reg 		 firstline;
   
   always @(posedge clk)
     if(reset)
       firstline <= 1'b1;
     else if(str_sink_tvalid & str_sink_tready)
       firstline <= str_sink_tlast;

   always @(posedge clk)
     if(str_sink_tvalid & str_sink_tready & firstline)
       begin
	  seqnum_hold <= str_sink_tdata[59:48];
	  sid_hold <= str_sink_tdata[31:0];
       end
   
   tx_responder #(.BASE(SB_FCPG), .USE_TIME(0)) str_sink_fc_gen
     (.clk(clk), .reset(reset), .clear(1'b0),
      .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
      .ack(1'b0), .error(1'b0), .packet_consumed(str_sink_tlast & str_sink_tvalid & str_sink_tready),
      .seqnum(seqnum_hold), .error_code(32'd0), .sid(sid_hold),
      .vita_time(64'd0),
      .o_tdata(fcout_tdata), .o_tlast(fcout_tlast), .o_tvalid(fcout_tvalid), .o_tready(fcout_tready));
   
endmodule // noc_shell
