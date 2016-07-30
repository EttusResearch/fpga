//
// Copyright 2014-2016 Ettus Research LLC
//

module noc_block_fosphor #(
  parameter NOC_ID = 64'h666f_0000_0000_0000,
  parameter STR_SINK_FIFOSIZE = 11,
  parameter MTU = 11)
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
  inst_noc_shell (
    .bus_clk(bus_clk), .bus_rst(bus_rst),
    .i_tdata(i_tdata), .i_tlast(i_tlast), .i_tvalid(i_tvalid), .i_tready(i_tready),
    .o_tdata(o_tdata), .o_tlast(o_tlast), .o_tvalid(o_tvalid), .o_tready(o_tready),
    // Computer Engine Clock Domain
    .clk(ce_clk), .reset(ce_rst),
    // Control Sink
    .set_data(set_data), .set_addr(set_addr), .set_stb(set_stb),
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
  wire         s_axis_data_teob;

  localparam AXI_WRAPPER_BASE    = 128;

  axi_wrapper #(
    .SIMPLE_MODE(0),
    .MTU(MTU))
  inst_axi_wrapper (
    .clk(ce_clk), .reset(ce_rst),
    .clear_tx_seqnum(clear_tx_seqnum),
    .next_dst(next_dst),
    .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
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
    .m_axis_config_tready());

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

  // Decimation config
  localparam [7:0] SR_DECIM   = AXI_WRAPPER_BASE + 1;
  localparam [7:0] SR_OFFSET  = AXI_WRAPPER_BASE + 2;
  localparam [7:0] SR_SCALE   = AXI_WRAPPER_BASE + 3;
  localparam [7:0] SR_TRISE   = AXI_WRAPPER_BASE + 4;
  localparam [7:0] SR_TDECAY  = AXI_WRAPPER_BASE + 5;
  localparam [7:0] SR_ALPHA   = AXI_WRAPPER_BASE + 6;
  localparam [7:0] SR_EPSILON = AXI_WRAPPER_BASE + 7;
  localparam [7:0] SR_RANDOM  = AXI_WRAPPER_BASE + 8;
  localparam [7:0] SR_CLEAR   = AXI_WRAPPER_BASE + 9;

  wire [11:0] cfg_decim;
  wire cfg_decim_changed;
  wire [15:0] cfg_offset;
  wire [15:0] cfg_scale;
  wire [15:0] cfg_trise;
  wire [15:0] cfg_tdecay;
  wire [15:0] cfg_alpha;
  wire [15:0] cfg_epsilon;
  wire [ 1:0] cfg_random;
  wire clear_req;

  setting_reg #(
    .my_addr(SR_DECIM), .awidth(8), .width(12))
  sr_decim (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data), .out(cfg_decim), .changed(cfg_decim_changed));

  setting_reg #(
    .my_addr(SR_OFFSET), .awidth(8), .width(16))
  sr_offset (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data), .out(cfg_offset));

  setting_reg #(
    .my_addr(SR_SCALE), .awidth(8), .width(16))
  sr_scale (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data), .out(cfg_scale));

  setting_reg #(
    .my_addr(SR_TRISE), .awidth(8), .width(16))
  sr_trise (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data), .out(cfg_trise));

  setting_reg #(
    .my_addr(SR_TDECAY), .awidth(8), .width(16))
  sr_tdecay (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data), .out(cfg_tdecay));

  setting_reg #(
    .my_addr(SR_ALPHA), .awidth(8), .width(16))
  sr_alpha (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data), .out(cfg_alpha));

  setting_reg #(
    .my_addr(SR_EPSILON), .awidth(8), .width(16))
  sr_epsilon (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data), .out(cfg_epsilon));

  setting_reg #(
    .my_addr(SR_RANDOM), .awidth(8), .width(2))
  sr_random (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data), .out(cfg_random));

  setting_reg #(
    .my_addr(SR_CLEAR), .awidth(8), .width(1))
  sr_clear (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data), .out(), .changed(clear_req));

  // Core block
  f15_core inst_fosphor (
        .clk(ce_clk), .reset(ce_rst),
	.clear_req(clear_req),
        .cfg_random(cfg_random),
        .cfg_offset(cfg_offset), .cfg_scale(cfg_scale),
        .cfg_trise(cfg_trise), .cfg_tdecay(cfg_tdecay),
        .cfg_alpha(cfg_alpha), .cfg_epsilon(cfg_epsilon),
        .cfg_decim(cfg_decim), .cfg_decim_changed(cfg_decim_changed),
        .i_tdata(m_axis_data_tdata), .i_tlast(m_axis_data_tlast), .i_tvalid(m_axis_data_tvalid), .i_tready(m_axis_data_tready),
        .o_tdata(s_axis_data_tdata), .o_tlast(s_axis_data_tlast), .o_tvalid(s_axis_data_tvalid), .o_tready(s_axis_data_tready),
        .o_teob(s_axis_data_teob));

  // CHDR header handling
  reg chdr_cap_next, chdr_pending, chdr_cur_valid;
  wire chdr_cap_cur;
  reg [127:0] chdr_next;
  reg [127:0] chdr_cur;

  always @(posedge ce_clk)
  begin
    // When to capture Next
    if (ce_rst)
      chdr_cap_next <= 1'b1;
    else if (m_axis_data_tvalid & m_axis_data_tready)
      chdr_cap_next <= m_axis_data_tlast;

    // Next CHDR
    if (chdr_cap_next)
      chdr_next <= m_axis_data_tuser;

    // When to capture
    if (chdr_cap_next)
      chdr_pending <= 1'b1;
    else if (chdr_cap_cur)
      chdr_pending <= 1'b0;

    // Current CHDR
    if (chdr_cap_cur)
      chdr_cur <= chdr_next;

    if (ce_rst)
      chdr_cur_valid <= 1'b0;
    else if (chdr_cap_cur)
      chdr_cur_valid <= chdr_pending;
  end

  assign chdr_cap_cur = chdr_pending & ((s_axis_data_tlast & s_axis_data_tvalid & s_axis_data_tready) | ~chdr_cur_valid);

  assign s_axis_data_tuser = {
    chdr_cur[127:125],          // Type + has_time
    s_axis_data_teob,           // EOB
    chdr_cur[123:112],          // Seq Num
    2'b00, chdr_cur[111:98],    // length in bytes (input size / 4)
    src_sid,                    // SRC SID
    next_dst_sid,               // DST SID
    chdr_cur[63:0]              // Timestamp
  };

endmodule
