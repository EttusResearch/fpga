//
// Copyright 2016 Ettus Research
//
// Example 1 input, 2 output block
//

module noc_block_invert #(
  parameter NOC_ID = 64'hAA55_0000_0000_0000,
  parameter STR_SINK_FIFOSIZE = 11)
(
  input bus_clk, input bus_rst,
  input ce_clk, input ce_rst,
  input  [63:0] i_tdata, input  i_tlast, input  i_tvalid, output i_tready,
  output [63:0] o_tdata, output o_tlast, output o_tvalid, input  o_tready,
  output [63:0] debug
);

  ////////////////////////////////////////////////////////////
  //
  // RFNoC Shell
  //
  ////////////////////////////////////////////////////////////
  wire [31:0] set_data[0:1];
  wire [7:0]  set_addr[0:1];
  wire [1:0]  set_stb;
  wire [7:0]  rb_addr[0:1];
  reg  [63:0] rb_data[0:1];

  wire [63:0] cmdout_tdata, ackin_tdata;
  wire        cmdout_tlast, cmdout_tvalid, cmdout_tready, ackin_tlast, ackin_tvalid, ackin_tready;

  wire [63:0] str_sink_tdata;
  wire        str_sink_tlast, str_sink_tvalid, str_sink_tready;
  wire [63:0] str_src_tdata[0:1];
  wire [1:0]  str_src_tlast, str_src_tvalid, str_src_tready;

  wire [1:0]  clear_tx_seqnum;
  wire [15:0] src_sid[0:1], next_dst_sid[0:1], resp_in_dst_sid, resp_out_dst_sid[0:1];

  noc_shell #(
    .INPUT_PORTS(1),
    .OUTPUT_PORTS(2),
    .NOC_ID(NOC_ID),
    .STR_SINK_FIFOSIZE({2{STR_SINK_FIFOSIZE[7:0]}}))
  noc_shell (
    .bus_clk(bus_clk), .bus_rst(bus_rst),
    .i_tdata(i_tdata), .i_tlast(i_tlast), .i_tvalid(i_tvalid), .i_tready(i_tready),
    .o_tdata(o_tdata), .o_tlast(o_tlast), .o_tvalid(o_tvalid), .o_tready(o_tready),
    // Computer Engine Clock Domain
    .clk(ce_clk), .reset(ce_rst),
    // Control Sink
    .set_data({set_data[1],set_data[0]}), .set_addr({set_addr[1],set_addr[0]}), .set_stb({set_stb[1],set_stb[0]}), .set_time(),
    .rb_stb(2'b11), .rb_addr({rb_addr[1],rb_addr[0]}), .rb_data({rb_data[1],rb_data[0]}),
    // Control Source
    .cmdout_tdata(cmdout_tdata), .cmdout_tlast(cmdout_tlast), .cmdout_tvalid(cmdout_tvalid), .cmdout_tready(cmdout_tready),
    .ackin_tdata(ackin_tdata), .ackin_tlast(ackin_tlast), .ackin_tvalid(ackin_tvalid), .ackin_tready(ackin_tready),
    // Stream Sink
    .str_sink_tdata(str_sink_tdata), .str_sink_tlast(str_sink_tlast), .str_sink_tvalid(str_sink_tvalid), .str_sink_tready(str_sink_tready),
    // Stream Source
    .str_src_tdata({str_src_tdata[1],str_src_tdata[0]}), .str_src_tlast(str_src_tlast), .str_src_tvalid(str_src_tvalid), .str_src_tready(str_src_tready),
    // Misc
    .vita_time(), .clear_tx_seqnum(clear_tx_seqnum),
    .src_sid({src_sid[1],src_sid[0]}), .next_dst_sid({next_dst_sid[1],next_dst_sid[0]}),
    .resp_in_dst_sid(resp_in_dst_sid), .resp_out_dst_sid({resp_out_dst_sid[1],resp_out_dst_sid[0]}),
    .debug(debug));

  ////////////////////////////////////////////////////////////
  //
  // AXI Wrapper
  // Convert RFNoC Shell interface into AXI stream interface
  //
  ////////////////////////////////////////////////////////////
  wire [31:0] m_axis_data_tdata;
  wire        m_axis_data_tlast;
  wire        m_axis_data_tvalid;
  wire        m_axis_data_tready;
  wire [127:0] m_axis_data_tuser;

  wire [31:0]  s_axis_data_tdata[0:1];
  wire [1:0]   s_axis_data_tlast;
  wire [1:0]   s_axis_data_tvalid;
  wire [1:0]   s_axis_data_tready;
  wire [127:0] s_axis_data_tuser[0:1];

  localparam SR_USER_REG_BASE   = 128;

  axi_wrapper #(
    .SIMPLE_MODE(0) /* Handle header internally */)
  axi_wrapper_0 (
    .clk(ce_clk), .reset(ce_rst),
    .clear_tx_seqnum(clear_tx_seqnum[0]),
    .next_dst(next_dst_sid[0]),
    .set_stb(), .set_addr(), .set_data(),
    .i_tdata(str_sink_tdata), .i_tlast(str_sink_tlast), .i_tvalid(str_sink_tvalid), .i_tready(str_sink_tready),
    .o_tdata(str_src_tdata[0]), .o_tlast(str_src_tlast[0]), .o_tvalid(str_src_tvalid[0]), .o_tready(str_src_tready[0]),
    .m_axis_data_tdata(m_axis_data_tdata),
    .m_axis_data_tlast(m_axis_data_tlast),
    .m_axis_data_tvalid(m_axis_data_tvalid),
    .m_axis_data_tready(m_axis_data_tready),
    .m_axis_data_tuser(m_axis_data_tuser),
    .s_axis_data_tdata(s_axis_data_tdata[0]),
    .s_axis_data_tlast(s_axis_data_tlast[0]),
    .s_axis_data_tvalid(s_axis_data_tvalid[0]),
    .s_axis_data_tready(s_axis_data_tready[0]),
    .s_axis_data_tuser(s_axis_data_tuser[0]),
    .m_axis_config_tdata(),
    .m_axis_config_tlast(),
    .m_axis_config_tvalid(),
    .m_axis_config_tready(),
    .m_axis_pkt_len_tdata(),
    .m_axis_pkt_len_tvalid(),
    .m_axis_pkt_len_tready());

  axi_wrapper  #(
    .SIMPLE_MODE(0))
  axi_wrapper_1 (
    .clk(ce_clk), .reset(ce_rst),
    .clear_tx_seqnum(clear_tx_seqnum[1]),
    .next_dst(next_dst_sid[1]),
    .set_stb(), .set_addr(), .set_data(),
    // Only using input to handle the header. Output data (m_axis_data_tdata) is unused and should be optimized out
    .i_tdata(), .i_tlast(), .i_tvalid(), .i_tready(),
    .o_tdata(str_src_tdata[1]), .o_tlast(str_src_tlast[1]), .o_tvalid(str_src_tvalid[1]), .o_tready(str_src_tready[1]),
    .m_axis_data_tdata(),
    .m_axis_data_tlast(),
    .m_axis_data_tvalid(),
    .m_axis_data_tready(),
    .m_axis_data_tuser(),
    .s_axis_data_tdata(s_axis_data_tdata[1]),
    .s_axis_data_tlast(s_axis_data_tlast[1]),
    .s_axis_data_tvalid(s_axis_data_tvalid[1]),
    .s_axis_data_tready(s_axis_data_tready[1]),
    .s_axis_data_tuser(s_axis_data_tuser[1]),
    .m_axis_config_tdata(),
    .m_axis_config_tlast(),
    .m_axis_config_tvalid(),
    .m_axis_config_tready(),
    .m_axis_pkt_len_tdata(),
    .m_axis_pkt_len_tvalid(),
    .m_axis_pkt_len_tready());

  // Handle headers
  cvita_hdr_modify cvita_hdr_modify_0 (
    .header_in(m_axis_data_tuser),
    .header_out(s_axis_data_tuser[0]),
    .use_pkt_type(1'b0),       .pkt_type(),
    .use_has_time(1'b0),       .has_time(),
    .use_eob(1'b0),            .eob(),
    .use_seqnum(1'b0),         .seqnum(),
    .use_length(1'b0),         .length(),
    .use_payload_length(1'b0), .payload_length(),
    .use_src_sid(1'b1),        .src_sid(src_sid[0]),
    .use_dst_sid(1'b1),        .dst_sid(next_dst_sid[0]),
    .use_vita_time(1'b0),      .vita_time());

  cvita_hdr_modify cvita_hdr_modify_1 (
    .header_in(m_axis_data_tuser),
    .header_out(s_axis_data_tuser[1]),
    .use_pkt_type(1'b0),       .pkt_type(),
    .use_has_time(1'b0),       .has_time(),
    .use_eob(1'b0),            .eob(),
    .use_seqnum(1'b0),         .seqnum(),
    .use_length(1'b0),         .length(),
    .use_payload_length(1'b0), .payload_length(),
    .use_src_sid(1'b1),        .src_sid(src_sid[1]),
    .use_dst_sid(1'b1),        .dst_sid(next_dst_sid[1]),
    .use_vita_time(1'b0),      .vita_time());

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

  /* Example dummy test registers */
  localparam [7:0] SR_TEST_REG = SR_USER_REG_BASE;

  wire [31:0] test_reg_0;
  setting_reg #(
    .my_addr(SR_TEST_REG), .awidth(8), .width(32))
  sr_test_reg_0 (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb[0]), .addr(set_addr[0]), .in(set_data[0]), .out(test_reg_0), .changed());

  always @*
    case(rb_addr[0])
      1'd0    : rb_data[0] <= {32'd0, test_reg_0};
      default : rb_data[0] <= 64'h0BADC0DE0BADC0DE;
  endcase

  wire [31:0] test_reg_1;
  setting_reg #(
    .my_addr(SR_TEST_REG), .awidth(8), .width(32))
  sr_test_reg_1 (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb[1]), .addr(set_addr[1]), .in(set_data[1]), .out(test_reg_1), .changed());

  always @*
    case(rb_addr[1])
      1'd0    : rb_data[1] <= {32'd0, test_reg_1};
      default : rb_data[1] <= 64'h0BADC0DE0BADC0DE;
  endcase

  /* Invert */
  pass_thru_and_invert pass_thru_and_invert (
  .clk(ce_clk), .reset(ce_rst),
  .i_tdata(m_axis_data_tdata), .i_tlast(m_axis_data_tlast), .i_tvalid(m_axis_data_tvalid), .i_tready(m_axis_data_tready),
  .pass_thru_tdata(s_axis_data_tdata[0]), .pass_thru_tlast(s_axis_data_tlast[0]), .pass_thru_tvalid(s_axis_data_tvalid[0]), .pass_thru_tready(s_axis_data_tready[0]),
  .invert_tdata(s_axis_data_tdata[1]), .invert_tlast(s_axis_data_tlast[1]), .invert_tvalid(s_axis_data_tvalid[1]), .invert_tready(s_axis_data_tready[1]));

endmodule
