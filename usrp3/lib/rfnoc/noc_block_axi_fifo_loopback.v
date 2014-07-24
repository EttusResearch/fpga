module noc_block_axi_fifo_loopback #(
  parameter NOC_ID = 64'hDEAD_BEEF_0123_4567,
  parameter STR_SINK_FIFOSIZE = 10)
(
  input bus_clk, input bus_rst,
  input  [63:0] i_tdata, input  i_tlast, input  i_tvalid, output i_tready,
  output [63:0] o_tdata, output o_tlast, output o_tvalid, input  o_tready
);

  /////////////////////////////////////////////////////////////
  //
  // RFNoC Shell
  //
  ////////////////////////////////////////////////////////////
  wire [31:0] set_data;
  wire [7:0]  set_addr;
  wire        set_stb;

  wire [63:0] cmdout_tdata, ackin_tdata;
  wire        cmdout_tlast, cmdout_tvalid, cmdout_tready, ackin_tlast, ackin_tvalid, ackin_tready;

  wire [63:0] str_sink_tdata, str_src_tdata;
  wire        str_sink_tlast, str_sink_tvalid, str_sink_tready, str_src_tlast, str_src_tvalid, str_src_tready;

  noc_shell #(
    .NOC_ID(NOC_ID),
    .STR_SINK_FIFOSIZE(STR_SINK_FIFOSIZE))
  inst_noc_shell (
    .bus_clk(bus_clk), .bus_rst(bus_rst),
    .i_tdata(o_tdata), .i_tlast(o_tlast), .i_tvalid(o_tvalid), .i_tready(o_tready),
    .o_tdata(i_tdata), .o_tlast(i_tlast), .o_tvalid(i_tvalid), .o_tready(i_tready),
    // Computer Engine Clock Domain
    .clk(bus_clk), .reset(bus_rst),
    // Control Sink
    .set_data(set_data), .set_addr(set_addr_ce0), .set_stb(set_stb_ce0), .rb_data(64'd0),
    // Control Source
    .cmdout_tdata(cmdout_tdata), .cmdout_tlast(cmdout_tlast), .cmdout_tvalid(cmdout_tvalid), .cmdout_tready(cmdout_tready),
    .ackin_tdata(ackin_tdata), .ackin_tlast(ackin_tlast), .ackin_tvalid(ackin_tvalid), .ackin_tready(ackin_tready),
    // Stream Sink
    .str_sink_tdata(str_sink_tdata), .str_sink_tlast(str_sink_tlast), .str_sink_tvalid(str_sink_tvalid), .str_sink_tready(str_sink_tready),
    // Stream Source
    .str_src_tdata(str_src_tdata), .str_src_tlast(str_src_tlast), .str_src_tvalid(str_src_tvalid), .str_src_tready(str_src_tready));

  // Control Source Unused
  assign cmdout_tdata = 64'd0;
  assign cmdout_tlast = 1'b0;
  assign cmdout_tvalid = 1'b0;
  assign ackin_tready = 1'b1;

  /////////////////////////////////////////////////////////////
  //
  // User code
  //
  ////////////////////////////////////////////////////////////

  wire [31:0] pre_tdata, post_tdata;
  wire        pre_tlast, post_tlast, pre_tvalid, post_tvalid, pre_tready, post_tready;

  /*
  assign s2o_tready = 1'b1;  // dump everything coming to us
  assign s2i_tvalid = 1'b0;  // don't send anything
  */

  simple_axi_wrapper #(
    .BASE(8))
  axi_wrapper (
    .clk(bus_clk), .reset(bus_rst),
    .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
    .i_tdata(str_sink_tdata), .i_tlast(str_sink_tlast), .i_tvalid(str_sink_tvalid), .i_tready(str_sink_tready),
    .o_tdata(str_src_tdata), .o_tlast(str_src_tlast), .o_tvalid(str_src_tvalid), .o_tready(str_src_tready),
    .m_axis_data_tdata(pre_tdata),
    .m_axis_data_tlast(pre_tlast),
    .m_axis_data_tvalid(pre_tvalid),
    .m_axis_data_tready(pre_tready),
    .s_axis_data_tdata(post_tdata),
    .s_axis_data_tlast(post_tlast),
    .s_axis_data_tvalid(post_tvalid),
    .s_axis_data_tready(post_tready));

  axi_fifo #(
    .WIDTH(33), .SIZE(12))
  inst_axi_fifo (
    .clk(bus_clk), .reset(bus_rst),
    .i_tdata({pre_tlast,pre_tdata}), .i_tvalid(pre_tvalid), .i_tready(pre_tready),
    .o_tdata({post_tlast,post_tdata}), .o_tvalid(post_tvalid), .o_tready(post_tready),
    .space(), .occupied());

endmodule