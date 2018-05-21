//
// Copyright 2018 Ettus Research, A National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// Module: chdr_route_config
// Description:
//  Check if we have a route configuration packet arriving. 
//  If so, the top config commands are extrated, sent to the
//  routing table for configuration, and the rest of the packet is forwarded
//  down to the router.

module chdr_route_config #(
  parameter CHDR_W     = 64,
  parameter CFG_DESTW  = 8,
  parameter CFG_DATAW  = 32
) (
  input  wire                 clk,
  input  wire                 reset,
  // CHDR input port
  input  wire [CHDR_W-1:0]    s_axis_chdr_tdata,
  input  wire                 s_axis_chdr_tlast,
  input  wire                 s_axis_chdr_tvalid,
  output wire                 s_axis_chdr_tready,
  // CHDR output port
  output wire [CHDR_W-1:0]    m_axis_chdr_tdata,
  output wire                 m_axis_chdr_tlast,
  output wire                 m_axis_chdr_tvalid,
  input  wire                 m_axis_chdr_tready,
  // Routing table config bus
  output wire [CFG_DATAW-1:0] m_axis_rtcfg_tdata,
  output wire [CFG_DESTW-1:0] m_axis_rtcfg_tdest,
  output wire [31:0]          m_axis_rtcfg_tuser,
  output wire                 m_axis_rtcfg_tvalid,
  input  wire                 m_axis_rtcfg_tready
);

  //----------------------------------------------------
  // Route def mux/demux
  //----------------------------------------------------

  wire [CHDR_W-1:0] s_axis_chdr_hdr;
  wire [CHDR_W-1:0] rtdef_i_tdata , rtdef_o_tdata , rest_tdata ;
  wire              rtdef_i_tlast , rtdef_o_tlast , rest_tlast ;
  wire              rtdef_i_tvalid, rtdef_o_tvalid, rest_tvalid;
  wire              rtdef_i_tready, rtdef_o_tready, rest_tready;

  axi_demux #(
    .WIDTH(CHDR_W), .SIZE(2),
    .PRE_FIFO_SIZE(1), .POST_FIFO_SIZE(0)
  ) pl_rtdef_demux_i (
    .clk      (clk),
    .reset    (reset),
    .clear    (1'b0),
    .header   (s_axis_chdr_hdr),
    .dest     (/*s_axis_chdr_hdr[55:54] == 2'd3 ? 1'b1 : */1'b0), //TODO (Ashish): Pull this from CHDR vheader
    .i_tdata  (s_axis_chdr_tdata ),
    .i_tlast  (s_axis_chdr_tlast ),
    .i_tvalid (s_axis_chdr_tvalid),
    .i_tready (s_axis_chdr_tready),
    .o_tdata  ({rtdef_i_tdata , rest_tdata }),
    .o_tlast  ({rtdef_i_tlast , rest_tlast }),
    .o_tvalid ({rtdef_i_tvalid, rest_tvalid}),
    .o_tready ({rtdef_i_tready, rest_tready})
  );

  axi_mux #(
    .PRIO(0), .WIDTH(CHDR_W), .SIZE(2),
    .PRE_FIFO_SIZE(0), .POST_FIFO_SIZE(1)
  ) mux_i (
    .clk      (clk),
    .reset    (reset),
    .clear    (1'b0),
    .i_tdata  ({rtdef_o_tdata , rest_tdata }),
    .i_tlast  ({rtdef_o_tlast , rest_tlast }),
    .i_tvalid ({rtdef_o_tvalid, rest_tvalid}),
    .i_tready ({rtdef_o_tready, rest_tready}),
    .o_tdata  (m_axis_chdr_tdata ),
    .o_tlast  (m_axis_chdr_tlast ),
    .o_tvalid (m_axis_chdr_tvalid),
    .o_tready (m_axis_chdr_tready)
  );

  //----------------------------------------------------
  // Route def processor
  //----------------------------------------------------
  localparam [3:0] ST_CHDR_HDR = 4'd0;
  localparam [3:0] ST_RTDEF_HDR = 4'd0;
  localparam [3:0] ST_HOP_CFG = 4'd0;
  localparam [3:0] ST_FWD_CHDR_HDR = 4'd0;
  localparam [3:0] ST_FWD_RTDEF_HDR = 4'd0;
  localparam [3:0] ST_FWD_HOP = 4'd0;
  localparam [3:0] ST_DROP = 4'd0;

  reg [3:0] state;
  reg [CHDR_W-1:0] in_chdr_hdr = {CHDR_W{1'b0}}, in_rtdef_hdr = {CHDR_W{1'b0}};

  always @(posedge clk) begin
    if (reset) begin
      state <= ST_CHDR_HDR;
    end else if (rtdef_i_tvalid) begin
      case (state)
        ST_CHDR_HDR: begin
          in_chdr_hdr <= rtdef_i_tdata;
          // TODO (Ashish): Pull this from CHDR vheader
          // Check if RTDEF has timestamp of mdata. If so, it is malformed
          if (rtdef_i_tready) begin
            if (rtdef_i_tdata[63] || rtdef_i_tdata[61:56] != 6'd0)
              state <= ST_DROP;
            else
              state <= rtdef_i_tlast ? ST_CHDR_HDR : ST_RTDEF_HDR;
          end
        end

        ST_RTDEF_HDR: begin
          in_rtdef_hdr <= rtdef_i_tdata;
          if (rtdef_i_tready) 
            state <= rtdef_i_tlast ? ST_CHDR_HDR : ST_HOP_CFG;
        end

        ST_HOP_CFG: begin
          // TODO (Ashish): Pull this from CHDR vheader
          // Check if this is the last hop (NumCfg = 0)
          if (rtdef_i_tready)
            if (rtdef_i_tlast) 
              state <= ST_CHDR_HDR;
            else
              state <= (rtdef_i_tdata[7:0] == 8'd0) ? ST_FWD_CHDR_HDR : ST_HOP_CFG;
        end

        ST_FWD_CHDR_HDR: begin
          if (rtdef_o_tready) 
            state <= ST_FWD_RTDEF_HDR;
        end

        ST_FWD_RTDEF_HDR: begin
          if (rtdef_o_tready) 
            state <= ST_FWD_HOP;
        end

        ST_FWD_HOP: begin
          if (rtdef_o_tready) 
            state <= rtdef_i_tlast ? ST_CHDR_HDR : ST_FWD_HOP;
        end

        ST_DROP: begin
          state <= rtdef_i_tlast ? ST_CHDR_HDR : ST_DROP;
        end
        default: begin
          // We should never get here.
          // Do nothing and rearm
          state <= ST_CHDR_HDR;
        end
      endcase
    end
  end

  assign m_axis_rtcfg_tdata  = rtdef_i_tdata[63:32];
  assign m_axis_rtcfg_tdest  = rtdef_i_tdata[15:8];
  assign m_axis_rtcfg_tuser  = in_rtdef_hdr[31:0];
  assign m_axis_rtcfg_tvalid = rtdef_i_tvalid && (state == ST_HOP_CFG);

  assign rtdef_i_tready = 
    (state == ST_CHDR_HDR) || (state == ST_RTDEF_HDR) ||
    (state == ST_HOP_CFG && m_axis_rtcfg_tready) ||
    (state == ST_FWD_HOP && rtdef_o_tready);

  assign rtdef_o_tvalid = 0;
//  assign rtdef_o_tvalid =
//    (state == ST_FWD_CHDR_HDR) || (state == ST_FWD_RTDEF_HDR) ||
//    (state == ST_FWD_HOP);
  assign rtdef_o_tlast = rtdef_i_tlast;

  // TODO (Ashish): Headers need to be modified when forwarding
  assign rtdef_o_tdata =
    (state == ST_FWD_CHDR_HDR) ? in_chdr_hdr : (
      (state == ST_FWD_RTDEF_HDR) ? in_rtdef_hdr : 
        rtdef_i_tdata);

endmodule

