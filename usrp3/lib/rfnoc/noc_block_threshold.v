//
// Copyright 2016 Ettus Research
//
// Example thresholding block that also shows how to use
// cvita_async_stream to handle asynchronous data
//

module noc_block_threshold #(
  parameter NOC_ID = 64'h7412_0000_0000_0000,
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

  wire [15:0] src_sid;
  wire [15:0] next_dst_sid, resp_out_dst_sid;
  wire [15:0] resp_in_dst_sid;

  wire        clear_tx_seqnum;

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
    .set_data(set_data), .set_addr(set_addr), .set_stb(set_stb),
    .rb_stb(1'b1), .rb_data(rb_data), .rb_addr(rb_addr),
    // Control Source
    .cmdout_tdata(cmdout_tdata), .cmdout_tlast(cmdout_tlast), .cmdout_tvalid(cmdout_tvalid), .cmdout_tready(cmdout_tready),
    .ackin_tdata(ackin_tdata), .ackin_tlast(ackin_tlast), .ackin_tvalid(ackin_tvalid), .ackin_tready(ackin_tready),
    // Stream Sink
    .str_sink_tdata(str_sink_tdata), .str_sink_tlast(str_sink_tlast), .str_sink_tvalid(str_sink_tvalid), .str_sink_tready(str_sink_tready),
    // Stream Source
    .str_src_tdata(str_src_tdata), .str_src_tlast(str_src_tlast), .str_src_tvalid(str_src_tvalid), .str_src_tready(str_src_tready),
    // Stream IDs set by host 
    .src_sid(src_sid),                   // SID of this block
    .next_dst_sid(next_dst_sid),         // Next destination SID
    .resp_in_dst_sid(resp_in_dst_sid),   // Response destination SID for input stream responses / errors
    .resp_out_dst_sid(resp_out_dst_sid), // Response destination SID for output stream responses / errors
    // Misc
    .vita_time(64'd0), .clear_tx_seqnum(clear_tx_seqnum),
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
    .SIMPLE_MODE(0),
    .RESIZE_OUTPUT_PACKET(1))
  axi_wrapper (
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

  // Control Source Unused
  assign cmdout_tdata  = 64'd0;
  assign cmdout_tlast  = 1'b0;
  assign cmdout_tvalid = 1'b0;
  assign ackin_tready  = 1'b1;

  /////////////////////////////////////////////////////////////////////////////
  //
  // Settings and readback registers
  //
  /////////////////////////////////////////////////////////////////////////////
  localparam SR_THRESHOLD   = 128;
  localparam SR_NUM_SAMPLES = 129;

  localparam RB_THRESHOLD   = 0;
  localparam RB_NUM_SAMPLES = 1;

  wire [31:0] threshold;
  setting_reg #(
    .my_addr(SR_THRESHOLD), .awidth(8), .width(32))
  sr_threshold (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data), .out(threshold), .changed());

  // Readback registers
  always @(*) begin
    case(rb_addr)
      RB_THRESHOLD   : rb_data <= {32'd0, threshold};
      default        : rb_data <= 64'h0BADC0DE0BADC0DE;
    endcase
  end

  /////////////////////////////////////////////////////////////////////////////
  //
  // Thresholding
  //
  /////////////////////////////////////////////////////////////////////////////
  wire [31:0] threshold_tdata        = m_axis_data_tdata;
  wire        threshold_tvalid       = m_axis_data_tvalid;
  wire        threshold_tkeep        = $signed(m_axis_data_tdata) > $signed(threshold);
  wire        threshold_tlast        = m_axis_data_tlast;
  assign      m_axis_data_tready     = threshold_tready;

  /////////////////////////////////////////////////////////////////////////////
  //
  // Form header from asynchronous data
  //
  /////////////////////////////////////////////////////////////////////////////
  cvita_async_stream #(
    .WIDTH(32))
  cvita_async_stream (
    .clk(ce_clk),
    .reset(ce_rst),
    .clear(clear_tx_seqnum),
    .src_sid(src_sid),
    .dst_sid(next_dst_sid),
    .tick_rate(1), // TODO: Needs to be set by the host, add a noc shell register
    // From AXI Wrapper
    .s_axis_data_tdata(m_axis_data_tdata),
    .s_axis_data_tlast(m_axis_data_tlast),
    .s_axis_data_tvalid(m_axis_data_tvalid),
    .s_axis_data_tready(m_axis_data_tready),
    .s_axis_data_tuser(m_axis_data_tuser),
    // User code interface
    .i_tdata(threshold_tdata),
    .i_tlast(threshold_tlast),
    .i_tvalid(threshold_tvalid),
    .i_tready(threshold_tready),
    .i_tkeep(threshold_tkeep),
    // To AXI Wrapper
    .m_axis_data_tdata(s_axis_data_tdata),
    .m_axis_data_tlast(s_axis_data_tlast),
    .m_axis_data_tvalid(s_axis_data_tvalid),
    .m_axis_data_tready(s_axis_data_tready),
    .m_axis_data_tuser(s_axis_data_tuser));

endmodule