//
// Copyright 2015 National Instruments
//

module noc_block_eq #(
  parameter NOC_ID = 64'hFF42_0000_0000_0000,
  parameter STR_SINK_FIFOSIZE = 11)
(
  input bus_clk,
  input bus_rst,

  input ce_clk,
  input ce_rst,

  input [63:0] i_tdata,
  input i_tlast,
  input i_tvalid,
  output i_tready,

  output [63:0] o_tdata,
  output o_tlast,
  output o_tvalid,
  input  o_tready,

  output [63:0] debug);

  //----------------------------------------------------------------------------
  // Constants
  //----------------------------------------------------------------------------

  // Settings registers addresses
  localparam SR_NEXT_DST   = 128;
  localparam SR_AXI_CONFIG = 129;
  localparam SR_READBACK   = 255;

  //----------------------------------------------------------------------------
  // Wires
  //----------------------------------------------------------------------------

  // Set next destination in chain
  wire [15:0] next_dst;

  // Readback register address
  wire rb_addr;

  // RFNoC Shell
  wire [31:0] set_data;
  wire [7:0]  set_addr;
  wire        set_stb;

  wire clear_tx_seqnum;

  wire [63:0] str_sink_tdata, str_src_tdata;
  wire str_sink_tlast, str_sink_tvalid, str_sink_tready;
  wire str_src_tlast, str_src_tvalid, str_src_tready;

  // AXI Wrapper
  wire [31:0]  m_axis_data_tdata, s_axis_data_tdata;
  wire [127:0] m_axis_data_tuser;
  wire m_axis_data_tlast, m_axis_data_tvalid, m_axis_data_tready;
  wire s_axis_data_tlast, s_axis_data_tvalid, s_axis_data_tready;

  // EOB flag from CHDR
  wire eob;

  //----------------------------------------------------------------------------
  // Registers
  //----------------------------------------------------------------------------

  // Readback register data
  reg [63:0] rb_data;

  //----------------------------------------------------------------------------
  // Instantiations
  //----------------------------------------------------------------------------

  // Set next destination in chain
  setting_reg #(
    .my_addr(SR_NEXT_DST),
    .width(16))
  sr_next_dst(
    .clk(ce_clk),
    .rst(ce_rst),
    .strobe(set_stb),
    .addr(set_addr),
    .in(set_data),
    .out(next_dst),
    .changed());

  // Readback registers
  setting_reg #(
    .my_addr(SR_READBACK),
    .width(1))
  sr_rdback (
    .clk(ce_clk),
    .rst(ce_rst),
    .strobe(set_stb),
    .addr(set_addr),
    .in(set_data),
    .out(rb_addr),
    .changed());

  // RFNoC Shell
  noc_shell #(
    .NOC_ID(NOC_ID),
    .STR_SINK_FIFOSIZE(STR_SINK_FIFOSIZE))
  noc_shell_inst (
    .bus_clk(bus_clk),
    .bus_rst(bus_rst),
    .i_tdata(i_tdata),
    .i_tlast(i_tlast),
    .i_tvalid(i_tvalid),
    .i_tready(i_tready),
    .o_tdata(o_tdata),
    .o_tlast(o_tlast),
    .o_tvalid(o_tvalid),
    .o_tready(o_tready),
    // Computer Engine Clock Domain
    .clk(ce_clk),
    .reset(ce_rst),
    // Control Sink
    .set_data(set_data),
    .set_addr(set_addr),
    .set_stb(set_stb),
    .rb_data(rb_data),
    // Control Source
    .cmdout_tdata(64'd0),
    .cmdout_tlast(1'b0),
    .cmdout_tvalid(1'b0),
    .cmdout_tready(),
    .ackin_tdata(),
    .ackin_tlast(),
    .ackin_tvalid(),
    .ackin_tready(1'b1),
    // Stream Sink
    .str_sink_tdata(str_sink_tdata),
    .str_sink_tlast(str_sink_tlast),
    .str_sink_tvalid(str_sink_tvalid),
    .str_sink_tready(str_sink_tready),
    // Stream Source
    .str_src_tdata(str_src_tdata),
    .str_src_tlast(str_src_tlast),
    .str_src_tvalid(str_src_tvalid),
    .str_src_tready(str_src_tready),
    .clear_tx_seqnum(clear_tx_seqnum),
    .debug(debug));

  // AXI Wrapper - Convert RFNoC Shell interface into AXI stream interface
  axi_wrapper #(
    .SR_AXI_CONFIG_BASE(SR_AXI_CONFIG))
  axi_wrapper_inst (
    .clk(ce_clk),
    .reset(ce_rst),
    // RFNoC Shell
    .clear_tx_seqnum(clear_tx_seqnum),
    .next_dst(next_dst),
    .set_stb(set_stb),
    .set_addr(set_addr),
    .set_data(set_data),
    .i_tdata(str_sink_tdata),
    .i_tlast(str_sink_tlast),
    .i_tvalid(str_sink_tvalid),
    .i_tready(str_sink_tready),
    .o_tdata(str_src_tdata),
    .o_tlast(str_src_tlast),
    .o_tvalid(str_src_tvalid),
    .o_tready(str_src_tready),
    // Internal AXI streams
    .m_axis_data_tdata(m_axis_data_tdata),
    .m_axis_data_tuser(m_axis_data_tuser),
    .m_axis_data_tlast(m_axis_data_tlast),
    .m_axis_data_tvalid(m_axis_data_tvalid),
    .m_axis_data_tready(m_axis_data_tready),
    .s_axis_data_tdata(s_axis_data_tdata),
    .s_axis_data_tlast(s_axis_data_tlast),
    .s_axis_data_tvalid(s_axis_data_tvalid),
    .s_axis_data_tready(s_axis_data_tready),
    .m_axis_config_tdata(),
    .m_axis_config_tlast(),
    .m_axis_config_tvalid(),
    .m_axis_config_tready(1'b1));

  // 1-Tap Equalizer
  one_tap_equalizer one_tap_equalizer_inst (
    .clk_i(ce_clk),
    .rst_i(ce_rst),
    .sof_i(eob), // Use the EOB flag to indicate the start of a frame - for now
    .i_tdata(m_axis_data_tdata),
    .i_tlast(m_axis_data_tlast),
    .i_tvalid(m_axis_data_tvalid),
    .i_tready(m_axis_data_tready),
    .o_tdata(s_axis_data_tdata),
    .o_tlast(s_axis_data_tlast),
    .o_tvalid(s_axis_data_tvalid),
    .o_tready(s_axis_data_tready));

  //----------------------------------------------------------------------------
  // Combinational Logic
  //----------------------------------------------------------------------------

  // Readback register values
  always @*
    case(rb_addr)
      1'd0    : rb_data <= 64'd0;
      default : rb_data <= 64'h0BADC0DE0BADC0DE;
    endcase

  // Extract the EOB flag from CHDR
  assign eob = m_axis_data_tuser[124];

endmodule
