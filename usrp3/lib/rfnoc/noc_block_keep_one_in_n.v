//
// Copyright 2016 Ettus Research
//

module noc_block_keep_one_in_n #(
  parameter NOC_ID = 64'h0246_0000_0000_0000,
  parameter STR_SINK_FIFOSIZE = 11)
(
  input bus_clk, input bus_rst,
  input ce_clk, input ce_rst,
  input  [63:0] i_tdata, input  i_tlast, input  i_tvalid, output i_tready,
  output [63:0] o_tdata, output o_tlast, output o_tvalid, input  o_tready,
  output [63:0] debug
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

  wire        clear_tx_seqnum;
  wire [15:0] src_sid, next_dst_sid;

  noc_shell #(
    .NOC_ID(NOC_ID),
    .STR_SINK_FIFOSIZE(STR_SINK_FIFOSIZE))
  noc_shell (
    .bus_clk(bus_clk), .bus_rst(bus_rst),
    .i_tdata(i_tdata), .i_tlast(i_tlast), .i_tvalid(i_tvalid), .i_tready(i_tready),
    .o_tdata(o_tdata), .o_tlast(o_tlast), .o_tvalid(o_tvalid), .o_tready(o_tready),
    // Computer Engine Clock Domain
    .clk(ce_clk), .reset(ce_rst),
    // Control Sink
    .set_data(set_data), .set_addr(set_addr), .set_stb(set_stb), .set_time(),
    .rb_stb(1'b1), .rb_data(64'd0), .rb_addr(),
    // Control Source
    .cmdout_tdata(cmdout_tdata), .cmdout_tlast(cmdout_tlast), .cmdout_tvalid(cmdout_tvalid), .cmdout_tready(cmdout_tready),
    .ackin_tdata(ackin_tdata), .ackin_tlast(ackin_tlast), .ackin_tvalid(ackin_tvalid), .ackin_tready(ackin_tready),
    // Stream Sink
    .str_sink_tdata(str_sink_tdata), .str_sink_tlast(str_sink_tlast), .str_sink_tvalid(str_sink_tvalid), .str_sink_tready(str_sink_tready),
    // Stream Source
    .str_src_tdata(str_src_tdata), .str_src_tlast(str_src_tlast), .str_src_tvalid(str_src_tvalid), .str_src_tready(str_src_tready),
    .clear_tx_seqnum(clear_tx_seqnum), .src_sid(src_sid), .next_dst_sid(next_dst_sid), .resp_in_dst_sid(), .resp_out_dst_sid(),
    .debug(debug));

  ////////////////////////////////////////////////////////////
  //
  // AXI Wrapper
  // Convert RFNoC Shell interface into AXI stream interface
  //
  ////////////////////////////////////////////////////////////
  wire [31:0]  m_axis_data_tdata;
  wire         m_axis_data_tlast;
  wire         m_axis_data_tvalid;
  wire         m_axis_data_tready;
  wire [127:0] m_axis_data_tuser;

  wire [31:0]  s_axis_data_tdata;
  wire         s_axis_data_tlast;
  wire         s_axis_data_tvalid;
  wire         s_axis_data_tready;
  wire [127:0] s_axis_data_tuser;

  axi_wrapper #(
    .SIMPLE_MODE(0))
  inst_axi_wrapper (
    .clk(ce_clk), .reset(ce_rst),
    .clear_tx_seqnum(clear_tx_seqnum),
    .next_dst(next_dst_sid),
    .set_stb(), .set_addr(), .set_data(),
    .i_tdata(str_sink_tdata), .i_tlast(str_sink_tlast), .i_tvalid(str_sink_tvalid), .i_tready(str_sink_tready),
    .o_tdata(str_src_tdata), .o_tlast(str_src_tlast), .o_tvalid(str_src_tvalid), .o_tready(str_src_tready),
    .m_axis_data_tdata(m_axis_data_tdata),
    .m_axis_data_tlast(m_axis_data_tlast),
    .m_axis_data_tvalid(m_axis_data_tvalid),
    .m_axis_data_tready(m_axis_data_tready),
    .m_axis_data_tuser(m_axis_data_tuser),
    .s_axis_data_tdata(s_axis_data_tdata),
    .s_axis_data_tlast(s_axis_data_tlast),
    .s_axis_data_tvalid(s_axis_data_tvalid),
    .s_axis_data_tready(s_axis_data_tready),
    .s_axis_data_tuser(s_axis_data_tuser),
    .m_axis_config_tdata(),
    .m_axis_config_tlast(),
    .m_axis_config_tvalid(),
    .m_axis_config_tready(),
    .m_axis_pkt_len_tdata(),
    .m_axis_pkt_len_tvalid(),
    .m_axis_pkt_len_tready());

  ////////////////////////////////////////////////////////////
  //
  // User code
  //
  ////////////////////////////////////////////////////////////

  // Control Source Unused
  assign cmdout_tdata  = 64'd0;
  assign cmdout_tlast  = 1'b0;
  assign cmdout_tvalid = 1'b0;
  assign ackin_tready  = 1'b1;

  localparam [7:0] SR_N           = 129;
  localparam [7:0] SR_VECTOR_MODE = 130;

  wire [15:0] n;
  setting_reg #(
    .my_addr(SR_N), .awidth(8), .width(16), .at_reset(1))
  sr_n (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data), .out(n), .changed());

  wire vector_mode;
  setting_reg #(
    .my_addr(SR_VECTOR_MODE), .awidth(8), .width(1), .at_reset(1) /* Drop vectors by default */)
  sr_vector_mode (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data), .out(vector_mode), .changed());

  // Modify packet header data, same as input except SRC / DST SID fields.
  cvita_hdr_modify cvita_hdr_modify (
    .header_in(m_axis_data_tuser),
    .header_out(s_axis_data_tuser),
    .use_pkt_type(1'b0),       .pkt_type(),
    .use_has_time(1'b0),       .has_time(),
    .use_eob(1'b0),            .eob(),
    .use_seqnum(1'b0),         .seqnum(),
    .use_length(1'b0),         .length(),
    .use_payload_length(1'b0), .payload_length(),
    .use_src_sid(1'b1),        .src_sid(src_sid),
    .use_dst_sid(1'b1),        .dst_sid(next_dst_sid),
    .use_vita_time(1'b0),      .vita_time());

  // Note: When dropping samples (i.e. vector_mode = 0), unless this block receives a multiple
  //       of N packets (where N is the decimation rate), there will be a partial formed output
  //       packet. This partial formed packet must be cleared before restarting the block. We
  //       can use clear_tx_seqnum for that purpose as it is strobed at block initialization.
  keep_one_in_n #(
    .WIDTH(32),
    .MAX_N(2**16-1))
  keep_one_in_n (
    .clk(ce_clk),
    .reset(ce_rst | clear_tx_seqnum),
    .vector_mode(vector_mode), .n(n),
    .i_tdata(m_axis_data_tdata), .i_tlast(m_axis_data_tlast), .i_tvalid(m_axis_data_tvalid), .i_tready(m_axis_data_tready),
    .o_tdata(s_axis_data_tdata), .o_tlast(s_axis_data_tlast), .o_tvalid(s_axis_data_tvalid), .o_tready(s_axis_data_tready));

endmodule
