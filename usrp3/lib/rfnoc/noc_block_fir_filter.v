//
// Copyright 2014-2015 Ettus Research
//

module noc_block_fir_filter #(
  parameter NOC_ID = 64'hF112_0000_0000_0000,
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
  wire [31:0] set_data;
  wire [7:0]  set_addr;
  wire        set_stb;
  reg  [63:0] rb_data;
  wire [7:0]  rb_addr;

  wire [63:0] cmdout_tdata, ackin_tdata;
  wire        cmdout_tlast, cmdout_tvalid, cmdout_tready, ackin_tlast, ackin_tvalid, ackin_tready;

  wire [63:0] str_sink_tdata, str_src_tdata;
  wire        str_sink_tlast, str_sink_tvalid, str_sink_tready, str_src_tlast, str_src_tvalid, str_src_tready;

  wire        clear_tx_seqnum;
  wire [15:0] next_dst_sid;

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
    .rb_stb(1'b1), .rb_data(rb_data), .rb_addr(rb_addr),
    // Control Source
    .cmdout_tdata(cmdout_tdata), .cmdout_tlast(cmdout_tlast), .cmdout_tvalid(cmdout_tvalid), .cmdout_tready(cmdout_tready),
    .ackin_tdata(ackin_tdata), .ackin_tlast(ackin_tlast), .ackin_tvalid(ackin_tvalid), .ackin_tready(ackin_tready),
    // Stream Sink
    .str_sink_tdata(str_sink_tdata), .str_sink_tlast(str_sink_tlast), .str_sink_tvalid(str_sink_tvalid), .str_sink_tready(str_sink_tready),
    // Stream Source
    .str_src_tdata(str_src_tdata), .str_src_tlast(str_src_tlast), .str_src_tvalid(str_src_tvalid), .str_src_tready(str_src_tready),
    .clear_tx_seqnum(clear_tx_seqnum), .src_sid(), .next_dst_sid(next_dst_sid), .resp_in_dst_sid(), .resp_out_dst_sid(),
    .vita_time(), .debug(debug));

  // Control Source Unused
  assign cmdout_tdata = 64'd0;
  assign cmdout_tlast = 1'b0;
  assign cmdout_tvalid = 1'b0;
  assign ackin_tready = 1'b1;

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

  wire [31:0] s_axis_data_tdata;
  wire        s_axis_data_tlast;
  wire        s_axis_data_tvalid;
  wire        s_axis_data_tready;

  axi_wrapper #(
    .SIMPLE_MODE(1))
  inst_axi_wrapper (
    .clk(ce_clk), .reset(ce_rst),
    .clear_tx_seqnum(clear_tx_seqnum),
    .next_dst(next_dst_sid),
    .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
    .i_tdata(str_sink_tdata), .i_tlast(str_sink_tlast), .i_tvalid(str_sink_tvalid), .i_tready(str_sink_tready),
    .o_tdata(str_src_tdata), .o_tlast(str_src_tlast), .o_tvalid(str_src_tvalid), .o_tready(str_src_tready),
    .m_axis_data_tdata(m_axis_data_tdata),
    .m_axis_data_tlast(m_axis_data_tlast),
    .m_axis_data_tvalid(m_axis_data_tvalid),
    .m_axis_data_tready(m_axis_data_tready),
    .s_axis_data_tdata(s_axis_data_tdata),
    .s_axis_data_tlast(s_axis_data_tlast),
    .s_axis_data_tvalid(s_axis_data_tvalid),
    .s_axis_data_tready(s_axis_data_tready),
    .m_axis_pkt_len_tdata(),
    .m_axis_pkt_len_tvalid(),
    .m_axis_pkt_len_tready(),
    .m_axis_config_tdata(),
    .m_axis_config_tlast(),
    .m_axis_config_tvalid(),
    .m_axis_config_tready());

  ////////////////////////////////////////////////////////////
  //
  // FIR Filter Implementation
  //
  ////////////////////////////////////////////////////////////
  wire [79:0] s_axis_fir_tdata;
  wire        s_axis_fir_tlast;
  wire        s_axis_fir_tvalid;
  wire        s_axis_fir_tready;
  wire [15:0] m_axis_fir_reload_tdata;
  wire        m_axis_fir_reload_tvalid, m_axis_fir_reload_tready, m_axis_fir_reload_tlast;
  wire [7:0]  m_axis_fir_config_tdata;
  wire        m_axis_fir_config_tvalid, m_axis_fir_config_tready;

  localparam SR_RELOAD       = 128;
  localparam SR_RELOAD_LAST  = 129;
  localparam SR_CONFIG       = 130;
  localparam RB_NUM_TAPS     = 0;

  localparam NUM_TAPS = 41;

  // Readback register for number of FIR filter taps
  always @*
    case(rb_addr)
      RB_NUM_TAPS : rb_data <= {NUM_TAPS};
      default     : rb_data <= 64'h0BADC0DE0BADC0DE;
  endcase

  // FIR filter coefficient reload bus
  // (see Xilinx FIR Filter Compiler documentation)
  axi_setting_reg #(
    .ADDR(SR_RELOAD),
    .USE_ADDR_LAST(1),
    .ADDR_LAST(SR_RELOAD_LAST),
    .WIDTH(16),
    .USE_FIFO(1),
    .FIFO_SIZE(7))
  set_coeff (
    .clk(ce_clk),
    .reset(ce_rst),
    .set_stb(set_stb),
    .set_addr(set_addr),
    .set_data(set_data),
    .o_tdata(m_axis_fir_reload_tdata),
    .o_tlast(m_axis_fir_reload_tlast),
    .o_tvalid(m_axis_fir_reload_tvalid),
    .o_tready(m_axis_fir_reload_tready));

  // FIR filter config bus
  // (see Xilinx FIR Filter Compiler documentation)
  axi_setting_reg #(
    .ADDR(SR_CONFIG),
    .WIDTH(8))
  set_config (
    .clk(ce_clk),
    .reset(ce_rst),
    .set_stb(set_stb),
    .set_addr(set_addr),
    .set_data(set_data),
    .o_tdata(m_axis_fir_config_tdata),
    .o_tlast(),
    .o_tvalid(m_axis_fir_config_tvalid),
    .o_tready(m_axis_fir_config_tready));

  // Xilinx FIR Filter IP Core
  axi_fir inst_axi_fir (
    .aresetn(~(ce_rst | clear_tx_seqnum)), .aclk(ce_clk),
    .s_axis_data_tdata(m_axis_data_tdata),
    .s_axis_data_tlast(m_axis_data_tlast),
    .s_axis_data_tvalid(m_axis_data_tvalid),
    .s_axis_data_tready(m_axis_data_tready),
    .m_axis_data_tdata(s_axis_fir_tdata),
    .m_axis_data_tlast(s_axis_fir_tlast),
    .m_axis_data_tvalid(s_axis_fir_tvalid),
    .m_axis_data_tready(s_axis_fir_tready),
    .s_axis_config_tdata(m_axis_fir_config_tdata),
    .s_axis_config_tvalid(m_axis_fir_config_tvalid),
    .s_axis_config_tready(m_axis_fir_config_tready),
    .s_axis_reload_tdata(m_axis_fir_reload_tdata),
    .s_axis_reload_tvalid(m_axis_fir_reload_tvalid),
    .s_axis_reload_tready(m_axis_fir_reload_tready),
    .s_axis_reload_tlast(m_axis_fir_reload_tlast));

  // Clip extra bits for bit growth and round
  axi_round_and_clip_complex #(
    .WIDTH_IN(38),
    .WIDTH_OUT(16),
    .CLIP_BITS(6))
  inst_axi_round_and_clip (
    .clk(ce_clk), .reset(ce_rst | clear_tx_seqnum),
    .i_tdata({s_axis_fir_tdata[77:40],s_axis_fir_tdata[37:0]}),
    .i_tlast(s_axis_fir_tlast),
    .i_tvalid(s_axis_fir_tvalid),
    .i_tready(s_axis_fir_tready),
    .o_tdata(s_axis_data_tdata),
    .o_tlast(s_axis_data_tlast),
    .o_tvalid(s_axis_data_tvalid),
    .o_tready(s_axis_data_tready));

endmodule
