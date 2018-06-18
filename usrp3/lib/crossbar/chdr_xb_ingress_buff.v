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
  parameter WIDTH       = 64,
  parameter SIZE        = 5,
  parameter XB_NPORTS   = 8,
  parameter SID_OFFSET  = 0,
  parameter SID_WIDTH   = 16
) (
  input  wire                         clk,
  input  wire                         reset,
  // CHDR input port
  input  wire [WIDTH-1:0]             s_axis_chdr_tdata,
  input  wire                         s_axis_chdr_tlast,
  input  wire                         s_axis_chdr_tvalid,
  output wire                         s_axis_chdr_tready,
  // CHDR output port (with a tdest and tkeep)
  output wire [WIDTH-1:0]             m_axis_chdr_tdata,
  output wire [$clog2(XB_NPORTS)-1:0] m_axis_chdr_tdest,
  output wire                         m_axis_chdr_tkeep,
  output wire                         m_axis_chdr_tlast,
  output wire                         m_axis_chdr_tvalid,
  input  wire                         m_axis_chdr_tready,
  // Find port going to routing table
  output wire [SID_WIDTH-1:0]         m_axis_find_tdata,
  output wire                         m_axis_find_tvalid,
  input  wire                         m_axis_find_tready,
  // Result port from routing table
  input  wire [$clog2(XB_NPORTS)-1:0] s_axis_result_tdata,
  input  wire                         s_axis_result_tkeep,
  input  wire                         s_axis_result_tvalid,
  output wire                         s_axis_result_tready
);
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

  wire pkt_gate_i_tready, pkt_gate_o_tvalid, find_fifo_i_tready;
  axi_packet_gate #(.WIDTH(WIDTH), .SIZE(SIZE)) pkt_gate_i (
    .clk      (clk), 
    .reset    (reset), 
    .clear    (1'b0),
    .i_tdata  (s_axis_chdr_tdata),
    .i_tlast  (s_axis_chdr_tlast),
    .i_tvalid (s_axis_chdr_tvalid & s_axis_chdr_tready),  //NOTE: Violates AXIS but OK since FIFO downstream
    .i_tready (pkt_gate_i_tready),
    .i_terror (1'b0),
    .o_tdata  (m_axis_chdr_tdata),
    .o_tlast  (m_axis_chdr_tlast),
    .o_tvalid (pkt_gate_o_tvalid),
    .o_tready (m_axis_chdr_tready)
  );

  axi_fifo #(.WIDTH(SID_WIDTH), .SIZE(1)) find_fifo_i (
    .clk      (clk), 
    .reset    (reset), 
    .clear    (1'b0),
    .i_tdata  (s_axis_chdr_tdata[SID_OFFSET+:SID_WIDTH]),
    .i_tvalid ((in_state == ST_HEAD) & s_axis_chdr_tvalid & s_axis_chdr_tready),  //NOTE: Violates AXIS but OK since FIFO downstream
    .i_tready (find_fifo_i_tready),
    .o_tdata  (m_axis_find_tdata),
    .o_tvalid (m_axis_find_tvalid),
    .o_tready (m_axis_find_tready),
    .space    (),
    .occupied ()
  );
  assign s_axis_chdr_tready = pkt_gate_i_tready & (in_state == ST_HEAD ? find_fifo_i_tready : 1'b1);

  wire dst_fifo_o_tvalid;
  axi_fifo #(.WIDTH($clog2(XB_NPORTS)+1), .SIZE(1)) res_fifo_i (
    .clk      (clk), 
    .reset    (reset), 
    .clear    (1'b0),
    .i_tdata  ({s_axis_result_tkeep, s_axis_result_tdata}),
    .i_tvalid (s_axis_result_tvalid),
    .i_tready (s_axis_result_tready),
    .o_tdata  ({m_axis_chdr_tkeep, m_axis_chdr_tdest}),
    .o_tvalid (dst_fifo_o_tvalid),
    .o_tready (m_axis_chdr_tready & m_axis_chdr_tvalid & (out_state == ST_HEAD)),
    .space    (),
    .occupied ()
  );
  assign m_axis_chdr_tvalid = pkt_gate_o_tvalid & (out_state == ST_HEAD ? dst_fifo_o_tvalid : 1'b1);

endmodule

