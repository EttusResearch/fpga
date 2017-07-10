//
// Copyright 2015 Ettus Research
//

module noc_block_ofdm_constellation_demapper #(
  parameter NUM_SUBCARRIERS        = 64,
  // Bit mask of subcarriers to exclude, such as guard bands, pilot subcarriers, DC bin, etc. Neg freq -> Pos freq.
  parameter EXCLUDE_SUBCARRIERS    = 64'b1111_1100_0001_0000_0000_0000_0100_0000_1000_0001_0000_0000_0000_0100_0001_1111,
  parameter MAX_MODULATION_ORDER   = 6,  // Must be a power of 4, default QAM-64
  parameter BYTE_REVERSE           = 1,  // Reverse output bytes
  parameter NOC_ID = 64'h0FCD_0000_0000_0000,
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
  localparam SR_READBACK = 255;

  wire [31:0] set_data;
  wire [7:0]  set_addr;
  wire        set_stb;
  reg  [63:0] rb_data;

  wire [63:0] cmdout_tdata, ackin_tdata;
  wire        cmdout_tlast, cmdout_tvalid, cmdout_tready, ackin_tlast, ackin_tvalid, ackin_tready;

  wire [63:0] str_sink_tdata, str_src_tdata;
  wire        str_sink_tlast, str_sink_tvalid, str_sink_tready, str_src_tlast, str_src_tvalid, str_src_tready;

  wire        clear_tx_seqnum;

  noc_shell #(
    .NOC_ID(NOC_ID),
    .STR_SINK_FIFOSIZE(STR_SINK_FIFOSIZE))
  inst_noc_shell (
    .bus_clk(bus_clk), .bus_rst(bus_rst),
    .i_tdata(i_tdata), .i_tlast(i_tlast), .i_tvalid(i_tvalid), .i_tready(i_tready),
    .o_tdata(o_tdata), .o_tlast(o_tlast), .o_tvalid(o_tvalid), .o_tready(o_tready),
    .clk(ce_clk), .reset(ce_rst),
    .set_data(set_data), .set_addr(set_addr), .set_stb(set_stb), .rb_data(64'd0),
    .cmdout_tdata(cmdout_tdata), .cmdout_tlast(cmdout_tlast), .cmdout_tvalid(cmdout_tvalid), .cmdout_tready(cmdout_tready),
    .ackin_tdata(ackin_tdata), .ackin_tlast(ackin_tlast), .ackin_tvalid(ackin_tvalid), .ackin_tready(ackin_tready),
    .str_sink_tdata(str_sink_tdata), .str_sink_tlast(str_sink_tlast), .str_sink_tvalid(str_sink_tvalid), .str_sink_tready(str_sink_tready),
    .str_src_tdata(str_src_tdata), .str_src_tlast(str_src_tlast), .str_src_tvalid(str_src_tvalid), .str_src_tready(str_src_tready),
    .clear_tx_seqnum(clear_tx_seqnum),
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

  localparam SR_NEXT_DST         = 128;
  localparam SR_MODULATION_ORDER = 129;
  localparam SR_SCALING          = 130;
  localparam SR_OUTPUT_SYMBOLS   = 131;
  localparam SR_PKT_LEN          = 132;
  localparam SR_SET_EOB          = 133;

  // Set next destination in chain
  wire [15:0] next_dst;
  setting_reg #(
    .my_addr(SR_NEXT_DST), .width(16))
  sr_next_dst(
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data), .out(next_dst), .changed());

  wire [15:0] pkt_len;
  setting_reg #(
    .my_addr(SR_PKT_LEN), .width(16), .at_reset(16'd256))
  setting_reg_pkt_len (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data), .out(pkt_len), .changed());

  wire set_eob;
  setting_reg #(
    .my_addr(SR_SET_EOB), .width(1), .at_reset(1'b1))
  setting_reg_set_eob (
    .clk(ce_clk), .rst(ce_rst),
    .strobe(set_stb), .addr(set_addr), .in(set_data), .out(set_eob), .changed());

  // Register src sid
  reg [15:0] src_sid;
  reg src_sid_hold;
  always @(posedge ce_clk) begin
    if (ce_rst) begin
      src_sid       <= 16'd0;
      src_sid_hold  <= 1'b0;
    end else begin
      if (m_axis_data_tvalid & ~src_sid_hold) begin
        src_sid       <= m_axis_data_tuser[79:64];
        src_sid_hold  <= 1'b1;
      end
    end
  end

  // Setup header
  assign s_axis_data_tuser = {
    3'b000,     // Data Packet type, no time
    set_eob,   // EOB
    12'd0,     // Sequence number, don't care handled by AXI wrapper
    pkt_len+8, // Packet length
    src_sid,   // SRC SID
    next_dst,  // DST SID
    64'd0};    // VITA time

  axi_wrapper #(
    .SIMPLE_MODE(0),
    .RESIZE_OUTPUT_PACKET(1))
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
    .s_axis_data_tlast(s_axis_data_tlast), // Not used when RESIZE_OUTPUT_PACKET=1 as tlast is handled internally
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

  ofdm_constellation_demapper #(
    .NUM_SUBCARRIERS(NUM_SUBCARRIERS),
    .EXCLUDE_SUBCARRIERS(EXCLUDE_SUBCARRIERS),
    .MAX_MODULATION_ORDER(MAX_MODULATION_ORDER),
    .BYTE_REVERSE(BYTE_REVERSE),
    .SR_MODULATION_ORDER(SR_MODULATION_ORDER),
    .SR_SCALING(SR_SCALING),
    .SR_OUTPUT_SYMBOLS(SR_OUTPUT_SYMBOLS))
  ofdm_constellation_demapper (
    .clk(ce_clk), .reset(ce_rst), .clear(),
    .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
    .i_tdata(m_axis_data_tdata), .i_tlast(m_axis_data_tlast), .i_tvalid(m_axis_data_tvalid), .i_tready(m_axis_data_tready),
    .o_tdata(s_axis_data_tdata), .o_tlast(s_axis_data_tlast), .o_tvalid(s_axis_data_tvalid), .o_tready(s_axis_data_tready));

endmodule