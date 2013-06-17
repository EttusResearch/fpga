
module noc_shell
  (input clk, input reset,

   // RFNoC interfaces
   input [63:0] noci_tdata, input noci_tlast, input noci_tvalid, output noci_tready,
   output [63:0] noco_tdata, output noco_tlast, output noco_tvalid, input noco_tready,

   // Control Sink

   // Control Source

   // Stream Sink

   // Stream Source

   
   // DDR3 access
   input ddr3_clk, input ddr3_rst,
   // DDR3 write port
   output ddr3_axi_awid,
   output [31:0] ddr3_axi_awaddr,
   output [7:0] ddr3_axi_awlen,
   output [2:0] ddr3_axi_awsize,
   output [1:0] ddr3_axi_awburst,
   output ddr3_axi_awlock,
   output [3:0] ddr3_axi_awcache,
   output [2:0] ddr3_axi_awprot,
   output [3:0] ddr3_axi_awqos,
   output ddr3_axi_awvalid,
   input ddr3_axi_awready,
   output [63:0] ddr3_axi_wdata,
   output [7:0] ddr3_axi_wstrb,
   output ddr3_axi_wlast,
   output ddr3_axi_wvalid,
   input ddr3_axi_wready,

   input ddr3_axi_bid,
   input [1:0] ddr3_axi_bresp,
   input ddr3_axi_bvalid,
   output ddr3_axi_bready,

   // DDR3 read port
   output ddr3_axi_arid,
   output [31:0] ddr3_axi_araddr,
   output [7:0] ddr3_axi_arlen,
   output [2:0] ddr3_axi_arsize,
   output [1:0] ddr3_axi_arburst,
   output ddr3_axi_arlock,
   output [3:0] ddr3_axi_arcache,
   output [2:0] ddr3_axi_arprot,
   output [3:0] ddr3_axi_arqos,
   output ddr3_axi_arvalid,
   input ddr3_axi_arready,
   input ddr3_axi_rid,
   input [63:0] ddr3_axi_rdata,
   input [1:0] ddr3_axi_rresp,
   input ddr3_axi_rlast,
   input ddr3_axi_rvalid,
   output ddr3_axi_rready
   );

   wire [31:0] set_data;
   wire [7:0]  set_addr;
   wire        set_stb;
   
   wire [63:0] ctrl_sink_resp_tdata, ctrl_sink_cmd_tdata, ctrl_src_resp_tdata, ctrl_src_cmd_tdata,
	       str_sink_data_tdata, str_sink_fbfc_tdata, str_src_data_tdata, str_src_fbfc_tdata;
   wire        ctrl_sink_resp_tlast, ctrl_sink_cmd_tlast, ctrl_src_resp_tlast, ctrl_src_cmd_tlast,
	       str_sink_data_tlast, str_sink_fbfc_tlast, str_src_data_tlast, str_src_fbfc_tlast;
   wire        ctrl_sink_resp_tvalid, ctrl_sink_cmd_tvalid, ctrl_src_resp_tvalid, ctrl_src_cmd_tvalid,
	       str_sink_fbfc_tvalid, str_sink_data_tvalid, str_src_data_tvalid, str_src_fbfc_tvalid;
   wire        ctrl_sink_resp_tready, ctrl_sink_cmd_tready, ctrl_src_resp_tready, ctrl_src_cmd_tready,
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

   wire [63:0] vheader;
   wire [1:0]  vdest = vheader[1:0];  // Switch by bottom 2 bits of SID

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

   wire        ready;
   wire [63:0] rb_data;
   wire [63:0] vita_time;
   
   radio_ctrl_proc radio_ctrl_proc
     (.clk(clk), .reset(reset), .clear(1'b0),
      .ctrl_tdata(ctrl_sink_cmd_tdata), .ctrl_tlast(ctrl_sink_cmd_tlast), .ctrl_tvalid(ctrl_sink_cmd_tvalid), .ctrl_tready(ctrl_sink_cmd_tready),
      .resp_tdata(ctrl_sink_resp_tdata), .resp_tlast(ctrl_sink_resp_tlast), .resp_tvalid(ctrl_sink_resp_tvalid), .resp_tready(ctrl_sink_resp_tready),
      .vita_time(vita_time),
      .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
      .ready(ready), .readback(rb_data),
      .debug());

   // ////////////////////////////////////////////////////////////////////////////////////
   // Stream Source
   //      FIXME need to pull out feedback from the FBFC bus before the source_flow_control block

   source_flow_control #(.BASE()) sfc
     (.clk(clk), .reset(reset), .clear(1'b0),
      .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
      .fc_tdata(str_src_fbfc_tdata), .fc_tlast(str_src_fbfc_tlast), .fc_tvalid(str_src_fbfc_tvalid), .fc_tready(str_src_fbfc_tready),
      .in_tdata(tdata), .in_tlast(tlast), .in_tvalid(tvalid), .in_tready(tready),
      .out_tdata(str_src_data_tdata), .out_tlast(str_src_data_tlast), .out_tvalid(str_src_data_tvalid), .out_tready(str_src_data_tready) );
   
endmodule // noc_shell
