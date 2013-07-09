
module noc_shell
  #(parameter STR_SINK_FIFOSIZE = 10)
   (input clk, input reset,

    // RFNoC interfaces
    input [63:0] noci_tdata, input noci_tlast, input noci_tvalid, output noci_tready,
    output [63:0] noco_tdata, output noco_tlast, output noco_tvalid, input noco_tready,
    
    // Control Sink
    output [31:0] set_data, output [7:0] set_addr, output set_stb, input [63:0] rb_data,
    
    // Control Source
    
    // Stream Sink
    output [63:0] str_sink_tdata, output str_sink_tlast, output str_sink_tvalid, input str_sink_tready,
    
    // Stream Source
    input [63:0] str_src_tdata, input str_src_tlast, input str_src_tvalid, output str_src_tready
    );

   localparam SB_SFC = 0;   // 2 regs
   localparam SB_FCPG = 2;  // 2 regs
   
   wire [63:0] 	 ctrl_sink_resp_tdata, ctrl_sink_cmd_tdata, ctrl_src_resp_tdata, ctrl_src_cmd_tdata,
		 str_sink_data_tdata, str_sink_fbfc_tdata, str_src_data_tdata, str_src_fbfc_tdata;
   wire 	 ctrl_sink_resp_tlast, ctrl_sink_cmd_tlast, ctrl_src_resp_tlast, ctrl_src_cmd_tlast,
		 str_sink_data_tlast, str_sink_fbfc_tlast, str_src_data_tlast, str_src_fbfc_tlast;
   wire 	 ctrl_sink_resp_tvalid, ctrl_sink_cmd_tvalid, ctrl_src_resp_tvalid, ctrl_src_cmd_tvalid,
		 str_sink_fbfc_tvalid, str_sink_data_tvalid, str_src_data_tvalid, str_src_fbfc_tvalid;
   wire 	 ctrl_sink_resp_tready, ctrl_sink_cmd_tready, ctrl_src_resp_tready, ctrl_src_cmd_tready,
		 str_sink_data_tready, str_sink_fbfc_tready, str_src_data_tready, str_src_fbfc_tready;
   
   // ////////////////////////////////////////////////////////////////////////////////////
   // Mux and Demux to join/split streams going to/coming from RFNoC
   
   axi_mux4 #(.PRIO(0), .WIDTH(64), .BUFFER(1)) output_mux
     (.clk(clk), .reset(reset), .clear(1'b0),
      .i0_tdata(ctrl_sink_resp_tdata), .i0_tlast(ctrl_sink_resp_tlast), .i0_tvalid(ctrl_sink_resp_tvalid), .i0_tready(ctrl_sink_resp_tready),
      .i1_tdata(ctrl_src_cmd_tdata), .i1_tlast(ctrl_src_cmd_tlast), .i1_tvalid(ctrl_src_cmd_tvalid), .i1_tready(ctrl_src_cmd_tready),
      .i2_tdata(str_sink_fbfc_tdata), .i2_tlast(str_sink_fbfc_tlast), .i2_tvalid(str_sink_fbfc_tvalid), .i2_tready(str_sink_fbfc_tready),
      .i3_tdata(str_src_data_tdata), .i3_tlast(str_src_data_tlast), .i3_tvalid(str_src_data_tvalid), .i3_tready(str_src_data_tready),
      .o_tdata(noco_tdata), .o_tlast(noco_tlast), .o_tvalid(noco_tvalid), .o_tready(noco_tready));

   wire [63:0] 	 vheader;
   wire [1:0] 	 vdest = vheader[1:0];  // Switch by bottom 2 bits of SID

   axi_demux4 #(.ACTIVE_CHAN(4'b0111), .WIDTH(64)) input_demux
     (.clk(clk), .reset(reset), .clear(1'b0),
      .header(vheader), .dest(vdest),
      .i_tdata(noci_tdata), .i_tlast(noci_tlast), .i_tvalid(noci_tvalid), .i_tready(noci_tready),
      .o0_tdata(ctrl_sink_cmd_tdata), .o0_tlast(ctrl_sink_cmd_tlast), .o0_tvalid(ctrl_sink_cmd_tvalid), .o0_tready(ctrl_sink_cmd_tready),
      .o1_tdata(ctrl_src_resp_tdata), .o1_tlast(ctrl_src_resp_tlast), .o1_tvalid(ctrl_src_resp_tvalid), .o1_tready(ctrl_src_resp_tready),
      .o2_tdata(str_sink_data_tdata), .o2_tlast(str_sink_data_tlast), .o2_tvalid(str_sink_data_tvalid), .o2_tready(str_sink_data_tready),
      .o3_tdata(str_src_fbfc_tdata), .o3_tlast(str_src_fbfc_tlast), .o3_tvalid(str_src_fbfc_tvalid), .o3_tready(str_src_fbfc_tready));

   // ////////////////////////////////////////////////////////////////////////////////////
   // 4 Major Components
   // Control Sink (required)
   // Control Source
   // Stream Sink
   // Stream Source

   // ////////////////////////////////////////////////////////////////////////////////////
   // Control Sink (required)

   wire 	 ready = 1'b1;
   wire [63:0] 	 vita_time = 64'd0;
   
   radio_ctrl_proc radio_ctrl_proc
     (.clk(clk), .reset(reset), .clear(1'b0),
      .ctrl_tdata(ctrl_sink_cmd_tdata), .ctrl_tlast(ctrl_sink_cmd_tlast), .ctrl_tvalid(ctrl_sink_cmd_tvalid), .ctrl_tready(ctrl_sink_cmd_tready),
      .resp_tdata(ctrl_sink_resp_tdata), .resp_tlast(ctrl_sink_resp_tlast), .resp_tvalid(ctrl_sink_resp_tvalid), .resp_tready(ctrl_sink_resp_tready),
      .vita_time(vita_time),
      .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
      .ready(ready), .readback(rb_data),
      .debug());

   // ////////////////////////////////////////////////////////////////////////////////////
   // Control Source (skeleton for now)

   assign ctrl_src_resp_tready = 1'b1;  // Dump anything coming in
   
   
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
      .fc_tdata(str_src_fbfc_tdata), .fc_tlast(str_src_fbfc_tlast), .fc_tvalid(str_src_fbfc_tvalid), .fc_tready(str_src_fbfc_tready),
      .in_tdata(str_src_tdata_int), .in_tlast(str_src_tlast_int), .in_tvalid(str_src_tvalid_int), .in_tready(str_src_tready_int),
      .out_tdata(str_src_data_tdata), .out_tlast(str_src_data_tlast), .out_tvalid(str_src_data_tvalid), .out_tready(str_src_data_tready) );
   
   // ////////////////////////////////////////////////////////////////////////////////////
   // Stream Sink
   //      FIXME  do we follow the back of the fifo, or do we allow the device to generate
   //             its own packet_consumed signals?

   axi_fifo #(.WIDTH(65), .SIZE(STR_SINK_FIFOSIZE)) str_sink_fifo
     (.clk(clk), .reset(reset), .clear(1'b0),
      .i_tdata({str_sink_data_tlast,str_sink_data_tdata}), .i_tvalid(str_sink_data_tvalid), .i_tready(str_sink_data_tready),
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
   
   fc_packet_generator #(.BASE(SB_FCPG)) str_sink_fc_gen
     (.clk(clk), .reset(reset), .clear(1'b0),
      .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
      .packet_consumed(str_sink_tlast & str_sink_tvalid & str_sink_tready), .seqnum(seqnum_hold), .sid(sid_hold),
      .o_tdata(str_sink_fbfc_tdata), .o_tlast(str_sink_fbfc_tlast), .o_tvalid(str_sink_fbfc_tvalid), .o_tready(str_sink_fbfc_tready));
   
endmodule // noc_shell
