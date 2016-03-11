//
// Copyright 2014-2015 Ettus Research LLC
//
// Special NoC Block where the internal NoC Shell / AXI Wrapper interfaces are exposed via ports.
// Created for use with RFNoC test benches.

`include "sim_cvita_lib.svh"
`include "sim_set_rb_lib.svh"

module noc_block_export_io
#(
  parameter NOC_ID = 64'hFFFF_FFFF_FFFF_0000,
  parameter STR_SINK_FIFOSIZE = 11
)(
  input bus_clk, bus_rst,
  input ce_clk, ce_rst,
  // Interface to crossbar
  axis_t.slave s_cvita,
  axis_t.master m_cvita,
  output [63:0] debug,
  /* Export user signals */
  // NoC Shell
  settings_bus_t.master set_bus,
  readback_bus_t.master rb_bus,
  // Block port 1
  axis_t.slave s_cvita_data,
  axis_t.master m_cvita_data,
  axis_t.slave cvita_cmd,
  axis_t.master cvita_ack,
  // AXI Wrapper, block port 0
  axis_t.master m_axis_data, m_axis_config,
  axis_t.slave s_axis_data
);

  ////////////////////////////////////////////////////////////
  //
  // RFNoC Shell
  //
  ////////////////////////////////////////////////////////////
  wire [1:0] clear_tx_seqnum;
  wire [2*16-1:0] src_sid, next_dst_sid;

  wire [63:0] str_sink_tdata, str_src_tdata;
  wire        str_sink_tlast, str_sink_tvalid, str_sink_tready, str_src_tlast, str_src_tvalid, str_src_tready;

  wire unused_set_stb;
  wire [31:0] unused_set_data;
  wire [7:0] unused_set_addr, unused_rb_addr;

  // Block port 0 -> AXI Wrapper
  // Block port 1 -> Export to user
  noc_shell #(
    .NOC_ID(NOC_ID),
    .INPUT_PORTS(2),
    .OUTPUT_PORTS(2),
    .USE_GATE_MASK(2'b10), // AXI wrapper has built in packet gating
    .STR_SINK_FIFOSIZE({2{STR_SINK_FIFOSIZE[7:0]}}))
  noc_shell (
    .bus_clk(bus_clk), .bus_rst(bus_rst),
    .i_tdata(s_cvita.tdata), .i_tlast(s_cvita.tlast), .i_tvalid(s_cvita.tvalid), .i_tready(s_cvita.tready),
    .o_tdata(m_cvita.tdata), .o_tlast(m_cvita.tlast), .o_tvalid(m_cvita.tvalid), .o_tready(m_cvita.tready),
    // Computer Engine Clock Domain
    .clk(ce_clk), .reset(ce_rst),
    // Control Sink
    .set_data({set_bus.data,unused_set_data}), .set_addr({set_bus.addr,unused_set_addr}), .set_stb({set_bus.stb,unused_set_stb}), .set_time(),
    .rb_stb(2'b11), .rb_data({rb_bus.data,64'd0}), .rb_addr({rb_bus.addr,unused_rb_addr}),
    // Control Source
    .cmdout_tdata(cvita_cmd.tdata), .cmdout_tlast(cvita_cmd.tlast), .cmdout_tvalid(cvita_cmd.tvalid), .cmdout_tready(cvita_cmd.tready),
    .ackin_tdata(cvita_ack.tdata), .ackin_tlast(cvita_ack.tlast), .ackin_tvalid(cvita_ack.tvalid), .ackin_tready(cvita_ack.tready),
    // Stream Sink
    .str_sink_tdata({m_cvita_data.tdata, str_sink_tdata}), .str_sink_tlast({m_cvita_data.tlast, str_sink_tlast}),
    .str_sink_tvalid({m_cvita_data.tvalid, str_sink_tvalid}), .str_sink_tready({m_cvita_data.tready, str_sink_tready}),
    // Stream Source
    .str_src_tdata({s_cvita_data.tdata,str_src_tdata}), .str_src_tlast({s_cvita_data.tlast,str_src_tlast}),
    .str_src_tvalid({s_cvita_data.tvalid,str_src_tvalid}), .str_src_tready({s_cvita_data.tready,str_src_tready}),
    // Misc
    .clear_tx_seqnum(clear_tx_seqnum), .src_sid(src_sid), .next_dst_sid(next_dst_sid), .resp_in_dst_sid(), .resp_out_dst_sid(),
    .debug(debug));

  ////////////////////////////////////////////////////////////
  //
  // AXI Wrapper
  // Convert RFNoC Shell interface into AXI stream interface
  //
  ////////////////////////////////////////////////////////////

  localparam AXI_WRAPPER_BASE    = 128;
  localparam SR_NEXT_DST         = AXI_WRAPPER_BASE;
  localparam SR_AXI_CONFIG_BASE  = AXI_WRAPPER_BASE + 1;

  axi_wrapper #(
    .SR_AXI_CONFIG_BASE(SR_AXI_CONFIG_BASE),
    .NUM_AXI_CONFIG_BUS(1),
    .SIMPLE_MODE(0))
  inst_axi_wrapper (
    .clk(ce_clk), .reset(ce_rst),
    .clear_tx_seqnum(clear_tx_seqnum[0]),
    .next_dst(),
    .set_stb(set_bus.stb), .set_addr(set_bus.addr), .set_data(set_bus.data),
    .i_tdata(str_sink_tdata), .i_tlast(str_sink_tlast), .i_tvalid(str_sink_tvalid), .i_tready(str_sink_tready),
    .o_tdata(str_src_tdata), .o_tlast(str_src_tlast), .o_tvalid(str_src_tvalid), .o_tready(str_src_tready),
    .m_axis_data_tdata(m_axis_data.tdata),
    .m_axis_data_tlast(m_axis_data.tlast),
    .m_axis_data_tvalid(m_axis_data.tvalid),
    .m_axis_data_tready(m_axis_data.tready),
    .m_axis_data_tuser(), // Unused
    .s_axis_data_tdata(s_axis_data.tdata),
    .s_axis_data_tlast(s_axis_data.tlast),
    .s_axis_data_tvalid(s_axis_data.tvalid),
    .s_axis_data_tready(s_axis_data.tready),
    .s_axis_data_tuser({32'd0,src_sid[15:0],next_dst_sid[15:0],64'd0}),
    .m_axis_config_tdata(m_axis_config.tdata),
    .m_axis_config_tlast(m_axis_config.tlast),
    .m_axis_config_tvalid(m_axis_config.tvalid),
    .m_axis_config_tready(m_axis_config.tready),
    .m_axis_pkt_len_tdata(), // Unused
    .m_axis_pkt_len_tvalid(),
    .m_axis_pkt_len_tready());

endmodule