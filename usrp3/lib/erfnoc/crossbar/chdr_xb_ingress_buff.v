//
// Copyright 2018 Ettus Research, A National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// Module: chdr_ingress_buff
// Description:
//   Ingress buffer module that does the following:
//   - Stores and gates an incoming packet
//   - Looks up destination in routing table and attaches a tdest for the packet

module chdr_xb_ingress_buff #(
  parameter       WIDTH   = 64,
  parameter       MTU     = 5,
  parameter       DEST_W  = 4,
  parameter [9:0] NODE_ID = 0
) (
  input  wire               clk,
  input  wire               reset,
  // CHDR input port
  input  wire [WIDTH-1:0]   s_axis_chdr_tdata,
  input  wire [DEST_W-1:0]  s_axis_chdr_tdest,
  input  wire [1:0]         s_axis_chdr_tid,
  input  wire               s_axis_chdr_tlast,
  input  wire               s_axis_chdr_tvalid,
  output wire               s_axis_chdr_tready,
  // CHDR output port (with a tdest and tkeep)
  output wire [WIDTH-1:0]   m_axis_chdr_tdata,
  output wire [DEST_W-1:0]  m_axis_chdr_tdest,
  output wire               m_axis_chdr_tkeep,
  output wire               m_axis_chdr_tlast,
  output wire               m_axis_chdr_tvalid,
  input  wire               m_axis_chdr_tready,
  // Find port going to routing table
  output wire [15:0]        m_axis_find_tdata,
  output wire               m_axis_find_tvalid,
  input  wire               m_axis_find_tready,
  // Result port from routing table
  input  wire [DEST_W-1:0]  s_axis_result_tdata,
  input  wire               s_axis_result_tkeep,
  input  wire               s_axis_result_tvalid,
  output wire               s_axis_result_tready
);

  // ---------------------------------------------------
  //  RFNoC Includes
  // ---------------------------------------------------
  `include "../core/rfnoc_chdr_utils.vh"
  `include "../core/rfnoc_chdr_internal_utils.vh"

  //----------------------------------------------------
  // Payload packet state tracker
  //----------------------------------------------------

  localparam [0:0] ST_HEAD = 1'd0;
  localparam [0:0] ST_BODY = 1'd1;

  reg [0:0] in_state = ST_HEAD, out_state = ST_HEAD;

  always @(posedge clk) begin
    if (reset) begin
      in_state <= ST_HEAD;
    end else if (s_axis_chdr_tvalid & s_axis_chdr_tready) begin
      if (in_state == ST_HEAD) begin
        in_state <= ST_BODY;
      end else begin
        in_state <= s_axis_chdr_tlast ? ST_HEAD : ST_BODY;
      end
    end
  end

  always @(posedge clk) begin
    if (reset) begin
      out_state <= ST_HEAD;
    end else if (m_axis_chdr_tvalid & m_axis_chdr_tready) begin
      if (out_state == ST_HEAD) begin
        out_state <= ST_BODY;
      end else begin
        out_state <= m_axis_chdr_tlast ? ST_HEAD : ST_BODY;
      end
    end
  end

  //----------------------------------------------------
  // Packet buffer and destination FIFO
  //----------------------------------------------------

  wire buff_i_tvalid, buff_i_tready;
  wire buff_o_tvalid, buff_o_tready;
  wire find_tvalid, find_tready;
  wire dest_i_tvalid, dest_i_tready, dest_o_tvalid;
  wire [DEST_W:0] dest_i_tdata;

  //NOTE: Violates AXIS but OK since FIFO downstream
  assign buff_i_tvalid = s_axis_chdr_tvalid & s_axis_chdr_tready;
  assign find_tvalid = (in_state == ST_HEAD) && buff_i_tvalid && (s_axis_chdr_tid == CHDR_MGMT_ROUTE_EPID);
  assign buff_o_tready = m_axis_chdr_tready;

  assign s_axis_chdr_tready = buff_i_tready &
    ((in_state != ST_HEAD) || ((s_axis_chdr_tid == CHDR_MGMT_ROUTE_EPID) ? find_tready : dest_i_tready));

  axi_packet_gate #(.WIDTH(WIDTH), .SIZE(MTU)) pkt_gate_i (
    .clk(clk), .reset(reset), .clear(1'b0),
    .i_tdata(s_axis_chdr_tdata), .i_tlast(s_axis_chdr_tlast),
    .i_tvalid(buff_i_tvalid), .i_tready(buff_i_tready),
    .i_terror(1'b0),
    .o_tdata(m_axis_chdr_tdata), .o_tlast(m_axis_chdr_tlast),
    .o_tvalid(buff_o_tvalid), .o_tready(buff_o_tready)
  );

  axi_fifo #(.WIDTH(16), .SIZE(1)) find_fifo_i (
    .clk(clk), .reset(reset), .clear(1'b0),
    .i_tdata(chdr_get_dst_epid(s_axis_chdr_tdata[63:0])),
    .i_tvalid(find_tvalid), .i_tready (find_tready),
    .o_tdata(m_axis_find_tdata),
    .o_tvalid(m_axis_find_tvalid), .o_tready (m_axis_find_tready),
    .space(), .occupied()
  );

  assign dest_i_tdata = s_axis_result_tvalid ? {s_axis_result_tkeep, s_axis_result_tdata} :
    {1'b1, (s_axis_chdr_tid == CHDR_MGMT_RETURN_TO_SRC) ? NODE_ID[DEST_W-1:0] : s_axis_chdr_tdest};
  assign dest_i_tvalid = s_axis_result_tvalid ||
    ((in_state == ST_HEAD) && buff_i_tvalid && (s_axis_chdr_tid != CHDR_MGMT_ROUTE_EPID));
  assign s_axis_result_tready = s_axis_result_tvalid && dest_i_tready;

  axi_fifo #(.WIDTH(DEST_W+1), .SIZE(1)) dest_fifo_i (
    .clk(clk), .reset(reset), .clear(1'b0),
    .i_tdata(dest_i_tdata), .i_tvalid(dest_i_tvalid), .i_tready(dest_i_tready),
    .o_tdata({m_axis_chdr_tkeep, m_axis_chdr_tdest}), .o_tvalid(dest_o_tvalid),
    .o_tready(m_axis_chdr_tready & m_axis_chdr_tvalid & (out_state == ST_HEAD)),
    .space(), .occupied ()
  );
  assign m_axis_chdr_tvalid = buff_o_tvalid & ((out_state != ST_HEAD) || dest_o_tvalid);

endmodule

