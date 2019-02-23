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
  // Packet buffer and search/response FIFOs
  //----------------------------------------------------

  wire [WIDTH-1:0]  dbuff_i_tdata , dbuff_o_tdata ;
  wire              dbuff_i_tlast , dbuff_o_tlast ;
  wire              dbuff_i_tvalid, dbuff_o_tvalid;
  wire              dbuff_i_tready, dbuff_o_tready;
                    
  wire [15:0]       find_tdata;
  wire              find_tvalid, find_tready;

  wire [DEST_W-1:0] dest_i_tdata;
  wire              dest_i_tkeep, dest_i_tvalid, dest_i_tready;
  wire [DEST_W-1:0] dest_o_tdata;
  wire              dest_o_tkeep, dest_o_tvalid, dest_o_tready;

  axi_packet_gate #(.WIDTH(WIDTH), .SIZE(MTU)) pkt_gate_i (
    .clk(clk), .reset(reset), .clear(1'b0),
    .i_tdata(dbuff_i_tdata), .i_tlast(dbuff_i_tlast), .i_terror(1'b0),
    .i_tvalid(dbuff_i_tvalid), .i_tready(dbuff_i_tready),
    .o_tdata(dbuff_o_tdata), .o_tlast(dbuff_o_tlast),
    .o_tvalid(dbuff_o_tvalid), .o_tready(dbuff_o_tready)
  );

  axi_fifo #(.WIDTH(16), .SIZE(1)) find_fifo_i (
    .clk(clk), .reset(reset), .clear(1'b0),
    .i_tdata(find_tdata), .i_tvalid(find_tvalid), .i_tready (find_tready),
    .o_tdata(m_axis_find_tdata), .o_tvalid(m_axis_find_tvalid), .o_tready (m_axis_find_tready),
    .space(), .occupied()
  );

  axi_mux #(
    .WIDTH(DEST_W+1), .SIZE(2), .PRIO(1), .PRE_FIFO_SIZE(1), .POST_FIFO_SIZE(1)
  ) dest_mux_i (
    .clk(clk), .reset(reset), .clear(1'b0),
    .i_tdata({dest_i_tkeep, dest_i_tdata, s_axis_result_tkeep, s_axis_result_tdata}),
    .i_tlast(2'b11), .i_tvalid({dest_i_tvalid, s_axis_result_tvalid}),
    .i_tready({dest_i_tready, s_axis_result_tready}),
    .o_tdata({dest_o_tkeep, dest_o_tdata}), .o_tlast(),
    .o_tvalid(dest_o_tvalid), .o_tready(dest_o_tready)
  );

  //----------------------------------------------------
  // Dispatch logic
  //----------------------------------------------------

  // Input Logic
  // -----------
  // When a packet comes in, we may have to do one of the following:
  // 1) Lookup the tdest using the EPID
  // 2) Use the specified input tdest
  // 3) Use the NODE_ID as the tdest (to return the packet)

  reg s_axis_chdr_header = 1'b1;
  always @(posedge clk) begin
    if (reset) begin
      s_axis_chdr_header <= 1'b1;
    end else if (s_axis_chdr_tvalid & s_axis_chdr_tready) begin
      s_axis_chdr_header <= s_axis_chdr_tlast;
    end
  end

  reg aux_fifo_tready;
  always @(*) begin
    if (s_axis_chdr_header) begin
      case (s_axis_chdr_tid)
        CHDR_MGMT_ROUTE_EPID:
          aux_fifo_tready = find_tready;
        CHDR_MGMT_ROUTE_TDEST:
          aux_fifo_tready = dest_i_tready;
        CHDR_MGMT_RETURN_TO_SRC:
          aux_fifo_tready = dest_i_tready;
        default:
          aux_fifo_tready = 1'b0; // We should never get here
      endcase
    end else begin
      aux_fifo_tready = 1'b1;
    end
  end
  assign s_axis_chdr_tready = s_axis_chdr_tvalid && dbuff_i_tready && aux_fifo_tready;

  wire chdr_header_stb = s_axis_chdr_tvalid && s_axis_chdr_tready && s_axis_chdr_header;

  // ********************************************************************************
  //NOTE: The logic below violates AXI-Stream by having a tready -> tvalid dependency
  //      To ensure no deadlocks, we need to place FIFOs downstream of dbuff_i_*,
  //      find_* and dest_i_*
  //
  assign find_tdata     = chdr_get_dst_epid(s_axis_chdr_tdata[63:0]);
  assign find_tvalid    = chdr_header_stb && (s_axis_chdr_tid == CHDR_MGMT_ROUTE_EPID);

  assign dbuff_i_tdata  = s_axis_chdr_tdata;
  assign dbuff_i_tlast  = s_axis_chdr_tlast;
  assign dbuff_i_tvalid = s_axis_chdr_tready & s_axis_chdr_tvalid;

  assign dest_i_tdata  = (s_axis_chdr_tid == CHDR_MGMT_ROUTE_TDEST) ? s_axis_chdr_tdest : NODE_ID[DEST_W-1:0];
  assign dest_i_tkeep  = 1'b1;
  assign dest_i_tvalid = chdr_header_stb && (s_axis_chdr_tid != CHDR_MGMT_ROUTE_EPID);
  //
  // ********************************************************************************


  // Output Logic
  // ------------
  // The destination for the packet (tdest) must be valid before we allow
  // the header of the packet to pass. So the packet must be blocked until
  // the output of the dest_fifo is valid. The tdest and tkeep must remain
  // valid until the end of the packet

  assign m_axis_chdr_tdata  = dbuff_o_tdata;
  assign m_axis_chdr_tlast  = dbuff_o_tlast;
  assign m_axis_chdr_tdest  = dest_o_tdata;
  assign m_axis_chdr_tkeep  = dest_o_tkeep;
  assign m_axis_chdr_tvalid = dbuff_o_tvalid && dest_o_tvalid;

  assign dbuff_o_tready = m_axis_chdr_tvalid & m_axis_chdr_tready;
  assign dest_o_tready  = m_axis_chdr_tvalid & m_axis_chdr_tready & m_axis_chdr_tlast;

endmodule

