//
// Copyright 2018-2019 Ettus Research, A National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// Module: chdr_xport_adapter_generic
// Description:
//
// Parameters:
//   - CHDR_W: Width of the input CHDR bus in bits
//
// Signals:
//

module chdr_xport_adapter_generic #(
  parameter [15:0] PROTOVER  = {8'd1, 8'd0},
  parameter        CHDR_W    = 256,
  parameter        USER_W    = 16,
  parameter        TBL_SIZE  = 6,
  parameter        NODE_INST = 0
)(
  // Clock and reset
  input  wire               clk,
  input  wire               rst,
  // Context stream in (AXI-Stream)
  input  wire [CHDR_W-1:0]  s_axis_xport_tdata,
  input  wire [USER_W-1:0]  s_axis_xport_tuser,
  input  wire               s_axis_xport_tlast,
  input  wire               s_axis_xport_tvalid,
  output wire               s_axis_xport_tready,
  // Context stream out (AXI-Stream)
  output wire [CHDR_W-1:0]  m_axis_xport_tdata,
  output wire [USER_W-1:0]  m_axis_xport_tuser,
  output wire               m_axis_xport_tlast,
  output wire               m_axis_xport_tvalid,
  input  wire               m_axis_xport_tready,

  input  wire [CHDR_W-1:0]  s_axis_rfnoc_tdata,
  input  wire               s_axis_rfnoc_tlast,
  input  wire               s_axis_rfnoc_tvalid,
  output wire               s_axis_rfnoc_tready,
  // Context stream out (AXI-Stream)
  output wire [CHDR_W-1:0]  m_axis_rfnoc_tdata,
  output wire               m_axis_rfnoc_tlast,
  output wire               m_axis_rfnoc_tvalid,
  input  wire               m_axis_rfnoc_tready
);

  // ---------------------------------------------------
  // RFNoC Includes
  // ---------------------------------------------------
  `include "../core/rfnoc_chdr_utils.vh"
  `include "../core/rfnoc_chdr_internal_utils.vh"
  `include "rfnoc_xport_types.vh" // Include after rfnoc_chdr_internal_utils.vh

  // ---------------------------------------------------
  // Transport => RFNoC FW
  // ---------------------------------------------------
  wire        op_stb;
  wire [15:0] op_src_epid;

  chdr_mgmt_pkt_handler #(
    .PROTOVER(PROTOVER), .CHDR_W(CHDR_W),
    .NODEINFO(chdr_mgmt_build_node_info(0, 1, NODE_INST, NODE_TYPE_XPORT_GENERIC))
  ) mgmt_ep_i (
    .clk(clk), .rst(rst),
    .s_axis_chdr_tdata(s_axis_xport_tdata), .s_axis_chdr_tlast(s_axis_xport_tlast),
    .s_axis_chdr_tvalid(s_axis_xport_tvalid), .s_axis_chdr_tready(s_axis_xport_tready),
    .m_axis_chdr_tdata(m_axis_rfnoc_tdata), .m_axis_chdr_tlast(m_axis_rfnoc_tlast),
    .m_axis_chdr_tdest(/* unused */), .m_axis_chdr_tid(/* unused */),
    .m_axis_chdr_tvalid(m_axis_rfnoc_tvalid), .m_axis_chdr_tready(m_axis_rfnoc_tready),
    .m_axis_rtcfg_tdata(/* unused */), .m_axis_rtcfg_tdest(/* unused */),
    .m_axis_rtcfg_tvalid(/* unused */), .m_axis_rtcfg_tready(1'b1 /* unused */),
    .ctrlport_req_wr(/* unused */), .ctrlport_req_rd(/* unused */),
    .ctrlport_req_addr(/* unused */), .ctrlport_req_data(/* unused */),
    .ctrlport_resp_ack(/* unused */), .ctrlport_resp_data(/* unused */),
    .op_stb(op_stb), .op_dst_epid(), .op_src_epid(op_src_epid)
  );

  wire              find_tvalid, find_tready;
  wire [USER_W-1:0] result_tdata;
  wire              result_tkeep, result_tvalid, result_tready;

  axis_muxed_kv_map #(
    .KEY_WIDTH(16), .VAL_WIDTH(USER_W), .SIZE(TBL_SIZE), .NUM_PORTS(1)
  ) kv_map_i (
    .clk(clk), .reset(rst),
    .axis_insert_tdata(s_axis_xport_tuser), .axis_insert_tdest(op_src_epid),
    .axis_insert_tvalid(op_stb), .axis_insert_tready(/* Time between op_stb > Insertion time */),
    .axis_find_tdata(chdr_get_dst_epid(s_axis_rfnoc_tdata[63:0])),
    .axis_find_tvalid(find_tvalid), .axis_find_tready(find_tready),
    .axis_result_tdata(result_tdata), .axis_result_tkeep(result_tkeep),
    .axis_result_tvalid(result_tvalid), .axis_result_tready(result_tready)
  );

  // ---------------------------------------------------
  // RFNoC FW => Transport
  // ---------------------------------------------------

  wire s_axis_rfnoc_tvalid_tmp, s_axis_rfnoc_tready_tmp;
  wire m_axis_xport_tvalid_tmp, m_axis_xport_tready_tmp;

  axi_fifo #(.WIDTH(CHDR_W + 1), .SIZE(1)) ret_flop_i (
    .clk(clk), .reset(rst), .clear(1'b0),
    .i_tdata({s_axis_rfnoc_tlast, s_axis_rfnoc_tdata}),
    .i_tvalid(s_axis_rfnoc_tvalid_tmp), .i_tready(s_axis_rfnoc_tready_tmp),
    .o_tdata({m_axis_xport_tlast, m_axis_xport_tdata}),
    .o_tvalid(m_axis_xport_tvalid_tmp), .o_tready(m_axis_xport_tready_tmp),
    .space(), .occupied()
  );

  reg i_hdr = 1'b1;
  always @(posedge clk) begin
    if (rst)
      i_hdr <= 1'b0;
    else if (s_axis_rfnoc_tvalid && s_axis_rfnoc_tready)
      i_hdr <= s_axis_rfnoc_tlast;
  end

  reg o_hdr = 1'b1;
  always @(posedge clk) begin
    if (rst)
      o_hdr <= 1'b0;
    else if (m_axis_xport_tvalid && m_axis_xport_tready)
      o_hdr <= m_axis_xport_tlast;
  end

  assign s_axis_rfnoc_tready = s_axis_rfnoc_tvalid & 
    s_axis_rfnoc_tready_tmp & (i_hdr ? find_tready : 1'b1);
  // Note: This violates AXI-Stream but it's OK because there is at least one
  // register stage (FIFO) downstream
  assign s_axis_rfnoc_tvalid_tmp = s_axis_rfnoc_tvalid & s_axis_rfnoc_tready;
  assign find_tvalid = s_axis_rfnoc_tvalid & i_hdr & s_axis_rfnoc_tready;

  assign m_axis_xport_tvalid = m_axis_xport_tvalid_tmp & (o_hdr ? result_tvalid : 1'b0);
  assign m_axis_xport_tuser = result_tkeep ? result_tdata : {USER_W{1'b0}};
  assign result_tready = m_axis_xport_tready && m_axis_xport_tvalid;
  assign m_axis_xport_tready_tmp = m_axis_xport_tready && m_axis_xport_tvalid;

endmodule // chdr_xport_adapter_generic
