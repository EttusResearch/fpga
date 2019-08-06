//
// Copyright 2019 Ettus Research, A National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// Module: chdr_xport_adapter_generic
// Description: A generic transport adapter module that can be used in
//   a veriety of transports. It does the following:
//   - Exposes a configuration port for mgmt packets to configure the node
//   - Implements a return-address map for packets with metadata other than
//     the CHDR. Additional metadata can be passed as a tuser to this module
//     which will store it in a map indexed by the SrcEPID in a management
//     packet. For all returning packets, the metadata will be looked up in
//     the map and attached as the outgoing tuser.
//   - Implements a loopback path for node-info discovery
//   - Converts data stream to/from "RFNoC Network Order" (64-bit-Big-Endian)
//
// Parameters:
//   - PROTOVER: RFNoC protocol version {8'd<major>, 8'd<minor>}
//   - CHDR_W: Width of the CHDR bus in bits
//   - USER_W: Width of the tuser bus in bits
//   - TBL_SIZE: Log2 of the depth of the routing table
//   - NODE_TYPE: The node type to return for a node-info discovery
//   - NODE_INST: The node type to return for a node-info discovery
//
// Signals:
//   - device_id     : The ID of the device that has instantiated this module
//   - s_axis_xport_*: The input CHDR stream from the transport (plus tuser metadata)
//   - m_axis_xport_*: The output CHDR stream to transport (plus tuser metadata)
//   - s_axis_rfnoc_*: The input CHDR stream from the rfnoc infrastructure
//   - m_axis_rfnoc_*: The output CHDR stream to the rfnoc infrastructure
//   - ctrlport_*    : The ctrlport interface for the configuration port
//

module chdr_xport_adapter_generic #(
  parameter [15:0] PROTOVER     = {8'd1, 8'd0},
  parameter        CHDR_W       = 256,
  parameter        USER_W       = 16,
  parameter        TBL_SIZE     = 6,
  parameter [7:0]  NODE_SUBTYPE = 8'd0,
  parameter        NODE_INST    = 0
)(
  // Clock and reset
  input  wire               clk,
  input  wire               rst,
  // Device info
  input  wire [15:0]        device_id,
  // Transport stream in (AXI-Stream)
  input  wire [CHDR_W-1:0]  s_axis_xport_tdata,
  input  wire [USER_W-1:0]  s_axis_xport_tuser,
  input  wire               s_axis_xport_tlast,
  input  wire               s_axis_xport_tvalid,
  output wire               s_axis_xport_tready,
  // Transport stream out (AXI-Stream)
  output wire [CHDR_W-1:0]  m_axis_xport_tdata,
  output wire [USER_W-1:0]  m_axis_xport_tuser,
  output wire               m_axis_xport_tlast,
  output wire               m_axis_xport_tvalid,
  input  wire               m_axis_xport_tready,
  // RFNoC stream in (AXI-Stream)
  input  wire [CHDR_W-1:0]  s_axis_rfnoc_tdata,
  input  wire               s_axis_rfnoc_tlast,
  input  wire               s_axis_rfnoc_tvalid,
  output wire               s_axis_rfnoc_tready,
  // RFNoC stream out (AXI-Stream)
  output wire [CHDR_W-1:0]  m_axis_rfnoc_tdata,
  output wire               m_axis_rfnoc_tlast,
  output wire               m_axis_rfnoc_tvalid,
  input  wire               m_axis_rfnoc_tready,
  // Control port endpoint
  output wire               ctrlport_req_wr,
  output wire               ctrlport_req_rd,
  output wire [15:0]        ctrlport_req_addr,
  output wire [31:0]        ctrlport_req_data,
  input  wire               ctrlport_resp_ack,
  input  wire [31:0]        ctrlport_resp_data
);

  // ---------------------------------------------------
  // RFNoC Includes
  // ---------------------------------------------------
  `include "../core/rfnoc_chdr_utils.vh"
  `include "../core/rfnoc_chdr_internal_utils.vh"

  // ---------------------------------------------------
  // Reverse groups of 64-bit words to translate
  // stream to "RFNoC Network Order" i.e. Big-Endian
  // in groups of 8 bytes
  // ---------------------------------------------------
  wire [CHDR_W-1:0]  i_xport_tdata;
  wire [USER_W-1:0]  i_xport_tuser;
  wire               i_xport_tlast, i_xport_tvalid, i_xport_tready;
  wire [CHDR_W-1:0]  o_xport_tdata;
  wire [USER_W-1:0]  o_xport_tuser;
  wire               o_xport_tdest;
  wire               o_xport_tlast, o_xport_tvalid, o_xport_tready;

  localparam [$clog2(CHDR_W)-1:0] SWAP_LANES = ((CHDR_W / 64) - 1) << 6;

  axis_data_swap #(
    .DATA_W(CHDR_W), .USER_W(USER_W), .STAGES_EN(SWAP_LANES), .DYNAMIC(0)
  ) xport_in_swap_i (
    .clk(clk), .rst(rst),
    .s_axis_tdata(s_axis_xport_tdata), .s_axis_tswap('h0),
    .s_axis_tuser(s_axis_xport_tuser), .s_axis_tlast(s_axis_xport_tlast),
    .s_axis_tvalid(s_axis_xport_tvalid), .s_axis_tready(s_axis_xport_tready),
    .m_axis_tdata (i_xport_tdata), .m_axis_tuser(i_xport_tuser),
    .m_axis_tlast (i_xport_tlast),
    .m_axis_tvalid(i_xport_tvalid), .m_axis_tready(i_xport_tready)
  );

  axis_data_swap #(
    .DATA_W(CHDR_W), .USER_W(USER_W), .STAGES_EN(SWAP_LANES), .DYNAMIC(0)
  ) xport_out_swap_i (
    .clk(clk), .rst(rst),
    .s_axis_tdata(o_xport_tdata), .s_axis_tswap('h0),
    .s_axis_tuser(o_xport_tuser), .s_axis_tlast(o_xport_tlast),
    .s_axis_tvalid(o_xport_tvalid), .s_axis_tready(o_xport_tready),
    .m_axis_tdata (m_axis_xport_tdata), .m_axis_tuser (m_axis_xport_tuser),
    .m_axis_tlast (m_axis_xport_tlast),
    .m_axis_tvalid(m_axis_xport_tvalid), .m_axis_tready(m_axis_xport_tready)
  );


  wire [CHDR_W-1:0] x2d_tdata;  // Xport => Demux
  reg  [USER_W-1:0] x2d_tuser;
  wire [1:0]        x2d_tid;
  wire              x2d_tlast, x2d_tvalid, x2d_tready;
  wire [CHDR_W-1:0] x2x_tdata;  // Xport => Xport (loopback)
  wire [USER_W-1:0] x2x_tuser;
  wire              x2x_tlast, x2x_tvalid, x2x_tready;
  wire [CHDR_W-1:0] m2x_tdata;  // Mux => Xport
  wire              m2x_tdest;  // 1: Return to src, 0: CHDR input
  wire [USER_W-1:0] m2x_tuser;
  wire              m2x_tlast, m2x_tvalid, m2x_tready;

  // ---------------------------------------------------
  // Transport => DEMUX
  // ---------------------------------------------------
  wire              op_stb;
  wire [15:0]       op_src_epid;
  wire [USER_W-1:0] op_data;
  wire              lookup_stb, lookup_res_stb, lookup_res_match;
  wire [15:0]       lookup_epid;
  wire [USER_W-1:0] lookup_res_val;
  reg  [USER_W-1:0] cam_tuser_cached = {USER_W{1'b0}};

  chdr_mgmt_pkt_handler #(
    .PROTOVER(PROTOVER), .CHDR_W(CHDR_W), .USER_W(USER_W), .MGMT_ONLY(0)
  ) mgmt_ep_i (
    .clk(clk), .rst(rst),
    .node_info(chdr_mgmt_build_node_info({10'h0, NODE_SUBTYPE}, NODE_INST, NODE_TYPE_TRANSPORT, device_id)),
    .s_axis_chdr_tdata(i_xport_tdata), .s_axis_chdr_tlast(i_xport_tlast),
    .s_axis_chdr_tvalid(i_xport_tvalid), .s_axis_chdr_tready(i_xport_tready),
    .s_axis_chdr_tuser(i_xport_tuser),
    .m_axis_chdr_tdata(x2d_tdata), .m_axis_chdr_tlast(x2d_tlast),
    .m_axis_chdr_tdest(/* unused */), .m_axis_chdr_tid(x2d_tid),
    .m_axis_chdr_tvalid(x2d_tvalid), .m_axis_chdr_tready(x2d_tready),
    .ctrlport_req_wr(ctrlport_req_wr), .ctrlport_req_rd(ctrlport_req_rd),
    .ctrlport_req_addr(ctrlport_req_addr), .ctrlport_req_data(ctrlport_req_data),
    .ctrlport_resp_ack(ctrlport_resp_ack), .ctrlport_resp_data(ctrlport_resp_data),
    .op_stb(op_stb), .op_dst_epid(/* unused */), .op_src_epid(op_src_epid), .op_data(op_data)
  );

  kv_map #(
    .KEY_WIDTH(16), .VAL_WIDTH(USER_W), .SIZE(TBL_SIZE)
  ) kv_map_i (
    .clk(clk), .reset(rst),
    .insert_stb(op_stb), .insert_key(op_src_epid), .insert_val(op_data),
    .insert_busy(/* Time between op_stb > Insertion time */),
    .find_key_stb(lookup_stb), .find_key(lookup_epid),
    .find_res_stb(lookup_res_stb),
    .find_res_match(lookup_res_match), .find_res_val(lookup_res_val),
    .count(/* unused */)
  );

  always @(posedge clk) begin
    if (lookup_res_stb)
      cam_tuser_cached <= lookup_res_match ? lookup_res_val : {USER_W{1'b0}};
  end

  reg i_xport_hdr = 1'b1;
  always @(posedge clk) begin
    if (rst)
      i_xport_hdr <= 1'b1;
    else if (i_xport_tvalid && i_xport_tready)
      i_xport_hdr <= i_xport_tlast;
  end

  // chdr_mgmt_pkt_handler does not buffer packets and has at least one cycle of delay
  // TODO: The tuser caching logic could be more robust
  always @(posedge clk) begin
    if (i_xport_tvalid && i_xport_tready && i_xport_hdr)
      x2d_tuser <= i_xport_tuser;
  end

  // ---------------------------------------------------
  // MUX and DEMUX for return path
  // ---------------------------------------------------

  wire [USER_W-1:0] dummy_tuser;
  axis_switch #(
    .DATA_W(CHDR_W+USER_W), .DEST_W(1), .IN_PORTS(1), .OUT_PORTS(2), .PIPELINE(0)
  ) rtn_demux_i (
    .clk(clk), .reset(rst),
    .s_axis_tdata({x2d_tuser, x2d_tdata}), .s_axis_alloc(1'b0),
    .s_axis_tdest(x2d_tid == CHDR_MGMT_RETURN_TO_SRC ? 2'b01 : 2'b00), 
    .s_axis_tlast(x2d_tlast), .s_axis_tvalid(x2d_tvalid), .s_axis_tready(x2d_tready),
    .m_axis_tdata({x2x_tuser, x2x_tdata, dummy_tuser, m_axis_rfnoc_tdata}),
    .m_axis_tdest(/* unused */),
    .m_axis_tlast({x2x_tlast, m_axis_rfnoc_tlast}),
    .m_axis_tvalid({x2x_tvalid, m_axis_rfnoc_tvalid}),
    .m_axis_tready({x2x_tready, m_axis_rfnoc_tready})
  );

  axi_mux #(
    .WIDTH(CHDR_W+USER_W+1), .SIZE(2), .PRE_FIFO_SIZE(0), .POST_FIFO_SIZE(0)
  ) rtn_mux_i (
    .clk(clk), .reset(rst), .clear(1'b0),
    .i_tdata({1'b1, x2x_tuser, x2x_tdata, 1'b0, {USER_W{1'b0}}, s_axis_rfnoc_tdata}),
    .i_tlast({x2x_tlast, s_axis_rfnoc_tlast}),
    .i_tvalid({x2x_tvalid, s_axis_rfnoc_tvalid}), .i_tready({x2x_tready, s_axis_rfnoc_tready}),
    .o_tdata({m2x_tdest, m2x_tuser, m2x_tdata}), .o_tlast(m2x_tlast),
    .o_tvalid(m2x_tvalid), .o_tready(m2x_tready)
  );

  // ---------------------------------------------------
  // MUX => Transport
  // ---------------------------------------------------

  // The map takes 3 cycles for a lookup and we add one more
  // register for a total of 4 cycles. We need to make sure
  // that the data-path has at least that much latency before
  // it hits the output.
  axis_shift_register #(
    .WIDTH(CHDR_W+1), .NSPC(1), .LATENCY(4),
    .SIDEBAND_DATAPATH(0), .GAPLESS(0),
    .PIPELINE("NONE")
  ) xport_delayline_i (
    .clk(clk), .reset(rst),
    .s_axis_tdata({m2x_tdest, m2x_tdata}), .s_axis_tkeep(1'b1), .s_axis_tlast(m2x_tlast),
    .s_axis_tvalid(m2x_tvalid), .s_axis_tready(m2x_tready),
    .m_axis_tdata({o_xport_tdest, o_xport_tdata}), .m_axis_tkeep(), .m_axis_tlast(o_xport_tlast),
    .m_axis_tvalid(o_xport_tvalid), .m_axis_tready(o_xport_tready),
    .stage_stb(), .stage_eop(),
    .m_sideband_data(), .m_sideband_keep(),
    .s_sideband_data('h0)
  );

  reg m2x_hdr = 1'b1;
  always @(posedge clk) begin
    if (rst)
      m2x_hdr <= 1'b1;
    else if (m2x_tvalid && m2x_tready)
      m2x_hdr <= m2x_tlast;
  end

  reg [USER_W-1:0] x2x_tuser_cached = {USER_W{1'b0}};
  always @(posedge clk) begin
    if (m2x_tvalid && m2x_tready && m2x_hdr)
      x2x_tuser_cached <= m2x_tuser;
  end

  // Lookup tuser in the map only if a packet is coming from the m_axis_rfnoc path
  assign lookup_stb = (!m2x_tdest) && m2x_hdr && m2x_tvalid && m2x_tready;
  assign lookup_epid = chdr_get_dst_epid(m2x_tdata[63:0]);

  // Pick tuser based on the source of the data
  assign o_xport_tuser = o_xport_tdest ? x2x_tuser_cached : cam_tuser_cached;

endmodule // chdr_xport_adapter_generic
