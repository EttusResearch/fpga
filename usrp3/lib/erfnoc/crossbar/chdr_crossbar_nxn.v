//
// Copyright 2018 Ettus Research, A National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// Module: chdr_crossbar_nxn
// Description: 
//   This module implements a full-bandwidth NxN crossbar with N input and output ports
//   for CHDR traffic. It supports multiple optimization strategies for performance,
//   area and timing tradeoffs. It uses AXI-Stream for all of its links. The crossbar
//   has a dynamic routing table based on a Content Addressable Memory (CAM). The SID
//   is used to determine the destination of a packet and the routing table contains
//   a re-programmable SID to crossbar port mapping. The table is programmed using
//   special route config packets on the data input ports or using an optional
//   management port.
//   The topology, routing algorithms and the router architecture is 
//   described in README.md in this directory. 
// Parameters:
//   - WIDTH: Width of the AXI-Stream data bus
//   - NPORTS: Number of ports to instantiate
//   - DEFAULT_PORT: The failsafe port to forward a packet to is SID mapping is missing
//   - INGRESS_BUFF_SIZE: log2 of the ingress buffer size (in words)
//   - SID_OFFSET: The SID is assumed to be in the first line of a packet.
//     This is its starting bit position. 
//   - SID_WIDTH: Width of the SID
//   - ROUTE_TBL_SIZE: log2 of the number of mappings that the routing table can hold 
//     at any time. Mapping values are maintained in a FIFO fashion.
//   - MUX_ALLOC: Algorithm to allocate the egress MUX
//     * PRIO: Priority based. Lower port numbers have a higher priority
//     * ROUND-ROBIN: Round robin input port allocation
//   - OPTIMIZE: Optimization strategy for performance vs area vs timing tradeoffs
//     * AREA: Attempt to minimize area at the cost of performance (throughput) and/or timing
//     * PERFORMANCE: Attempt to maximize performance at the cost of area and/or timing
//     * TIMING: Attempt to maximize Fmax at the cost of area and/or performance
//   - MGMT_RTCFG_PORT: Enable a side-channel AXI-Stream management port to configure the
//     routing table
// Signals:
//   - s_axis_*: Slave port for router (flattened)
//   - m_axis_*: Master port for router (flattened)
//   - s_axis_mgmt_*: Management slave port
//

module chdr_crossbar_nxn #(
  parameter WIDTH             = 64,
  parameter NPORTS            = 8,
  parameter DEFAULT_PORT      = 0,
  parameter INGRESS_BUFF_SIZE = 9,
  parameter SID_OFFSET        = 0,
  parameter SID_WIDTH         = 16,
  parameter ROUTE_TBL_SIZE    = 6,
  parameter MUX_ALLOC         = "ROUND-ROBIN",
  parameter OPTIMIZE          = "AREA",
  parameter MGMT_RTCFG_PORT   = 0
) (
  input  wire                       clk,
  input  wire                       reset,
  // Inputs
  input  wire [(WIDTH*NPORTS)-1:0]  s_axis_tdata,
  input  wire [NPORTS-1:0]          s_axis_tlast,
  input  wire [NPORTS-1:0]          s_axis_tvalid,
  output wire [NPORTS-1:0]          s_axis_tready,
  // Output
  output wire [(WIDTH*NPORTS)-1:0]  m_axis_tdata,
  output wire [NPORTS-1:0]          m_axis_tlast,
  output wire [NPORTS-1:0]          m_axis_tvalid,
  input  wire [NPORTS-1:0]          m_axis_tready,
  // Management
  input  wire [31:0]                s_axis_mgmt_tdata,
  input  wire                       s_axis_mgmt_tvalid,
  output wire                       s_axis_mgmt_tready
);
  parameter NPORTS_W = $clog2(NPORTS);
  localparam CFG_W = SID_WIDTH + NPORTS_W;
  localparam CFG_PORTS = NPORTS + MGMT_RTCFG_PORT;

  localparam [0:0] PKT_ST_HEAD = 1'b0;
  localparam [0:0] PKT_ST_BODY = 1'b1;

  // The compute_mux_alloc function is the switch allocation function for the MUX 
  // i.e. it chooses which input port reserves the output MUX for packet transfer.
  function [NPORTS_W-1:0] compute_mux_alloc;
    input [NPORTS-1:0] pkt_waiting;
    input [NPORTS_W-1:0] last_alloc;
    reg signed [NPORTS_W:0] i;
  begin
    compute_mux_alloc = last_alloc;
    for (i = NPORTS-1; i >= 0; i=i-1) begin
      if (MUX_ALLOC == "PRIO") begin
        // Priority. Lower port index gets a higher priority.
        if (pkt_waiting[i])
          compute_mux_alloc = i;
      end else begin
        // Round-robin
        if (pkt_waiting[(last_alloc + i + 1) % NPORTS])
          compute_mux_alloc = (last_alloc + i + 1) % NPORTS;
      end
    end
  end
  endfunction

  wire [(SID_WIDTH*NPORTS)-1:0] find_tdata;
  wire [NPORTS-1:0]             find_tvalid;
  wire [NPORTS-1:0]             find_tready;
  wire [(NPORTS_W*NPORTS)-1:0]  result_tdata;
  wire [NPORTS-1:0]             result_tkeep;
  wire [NPORTS-1:0]             result_tvalid;
  wire [NPORTS-1:0]             result_tready;
  wire [SID_WIDTH-1:0]          insert_tdest;
  wire [NPORTS_W-1:0]           insert_tdata;
  wire                          insert_tvalid;
  wire                          insert_tready;
  wire [CFG_W*CFG_PORTS-1:0]    rtcfg_tdata;
  wire [CFG_PORTS-1:0]          rtcfg_tvalid;
  wire [CFG_PORTS-1:0]          rtcfg_tready;

  // Instantiate a single CAM-based routing table that will be shared between all
  // input ports. Configuration and lookup is performed using an AXI-Stream iface.
  // If multiple packets arrive simultaneously, only the headers of those packets will
  // be serialized in order to arbitrate this map. Selection is done round-robin.
  axis_muxed_kv_map #(
    .KEY_WIDTH(SID_WIDTH),
    .VAL_WIDTH(NPORTS_W),
    .SIZE     (ROUTE_TBL_SIZE),
    .NUM_PORTS(NPORTS)
  ) kv_map_i (
    .clk               (clk          ),
    .reset             (reset        ),
    .axis_insert_tdata (insert_tdata ),
    .axis_insert_tdest (insert_tdest ),
    .axis_insert_tvalid(insert_tvalid),
    .axis_insert_tready(insert_tready),
    .axis_find_tdata   (find_tdata   ),
    .axis_find_tvalid  (find_tvalid  ),
    .axis_find_tready  (find_tready  ),
    .axis_result_tdata (result_tdata ),
    .axis_result_tkeep (result_tkeep ),
    .axis_result_tvalid(result_tvalid),
    .axis_result_tready(result_tready)
  );

  axi_mux #(
    .WIDTH(CFG_W), .SIZE(CFG_PORTS),
    .PRE_FIFO_SIZE(0), .POST_FIFO_SIZE(0)
  ) rtcfg_mux_i (
    .clk(clk), .reset(reset), .clear(1'b0),
    .i_tdata(rtcfg_tdata), .i_tlast({CFG_PORTS{1'b1}}), .i_tvalid(rtcfg_tvalid), .i_tready(rtcfg_tready),
    .o_tdata({insert_tdata, insert_tdest}), .o_tlast(), .o_tvalid(insert_tvalid), .o_tready(insert_tready)
  );

  // Instantiate an additional input for the MUX if the config port is instantiated. 
  generate if (MGMT_RTCFG_PORT == 1) begin
    assign rtcfg_tdata[NPORTS*CFG_W+:CFG_W] = s_axis_mgmt_tdata[CFG_W-1:0];
    assign rtcfg_tvalid[NPORTS] = s_axis_mgmt_tvalid;
    assign s_axis_mgmt_tready = rtcfg_tready[NPORTS];
  end else begin
    assign s_axis_mgmt_tready = 1'b1;
  end endgenerate

  wire [WIDTH-1:0]          i_tdata [0:NPORTS-1];
  wire                      i_tlast [0:NPORTS-1];
  wire                      i_tvalid[0:NPORTS-1];
  wire                      i_tready[0:NPORTS-1];
  wire [WIDTH-1:0]          buf_tdata [0:NPORTS-1];
  wire [NPORTS_W-1:0]       buf_tdest [0:NPORTS-1], buf_tdest_tmp[0:NPORTS-1];
  wire                      buf_tkeep [0:NPORTS-1];
  wire                      buf_tlast [0:NPORTS-1];
  wire                      buf_tvalid[0:NPORTS-1];
  wire                      buf_tready[0:NPORTS-1];
  wire [WIDTH-1:0]          swi_tdata [0:NPORTS-1];
  wire [NPORTS_W-1:0]       swi_tdest [0:NPORTS-1];
  wire                      swi_tlast [0:NPORTS-1];
  wire                      swi_tvalid[0:NPORTS-1];
  wire                      swi_tready[0:NPORTS-1];
  wire [(WIDTH*NPORTS)-1:0] swo_tdata [0:NPORTS-1], muxi_tdata [0:NPORTS-1];
  wire [NPORTS-1:0]         swo_tlast [0:NPORTS-1], muxi_tlast [0:NPORTS-1];
  wire [NPORTS-1:0]         swo_tvalid[0:NPORTS-1], muxi_tvalid[0:NPORTS-1];
  wire [NPORTS-1:0]         swo_tready[0:NPORTS-1], muxi_tready[0:NPORTS-1];

  genvar n, i, j;
  generate
    for (n = 0; n < NPORTS; n = n + 1) begin: i_ports
      // For each input port, first check if we have a route configuration packet
      // arriving. If it arrives, the top config commands are extrated, sent to the
      // routing table for configuration, and the rest of the packet is forwarded
      // down to the router.
      // NOTE: We assume that the configuration is done before the packet is sent to
      // the router.
      chdr_route_config #(
        .CHDR_W(WIDTH), .CFG_DESTW(8), .CFG_DATAW(CFG_W)
      ) rt_cfg_i (
        .clk                 (clk                            ),
        .reset               (reset                          ),
        .s_axis_chdr_tdata   (s_axis_tdata [(n*WIDTH)+:WIDTH]),
        .s_axis_chdr_tlast   (s_axis_tlast [n]               ),
        .s_axis_chdr_tvalid  (s_axis_tvalid[n]               ),
        .s_axis_chdr_tready  (s_axis_tready[n]               ),
        .m_axis_chdr_tdata   (i_tdata      [n]               ),
        .m_axis_chdr_tlast   (i_tlast      [n]               ),
        .m_axis_chdr_tvalid  (i_tvalid     [n]               ),
        .m_axis_chdr_tready  (i_tready     [n]               ),
        .m_axis_rtcfg_tdata  (rtcfg_tdata  [(n*CFG_W)+:CFG_W]),
        .m_axis_rtcfg_tdest  (/* Unused */                   ),
        .m_axis_rtcfg_tuser  (/* Unused */                   ),
        .m_axis_rtcfg_tvalid (rtcfg_tvalid [n]               ),
        .m_axis_rtcfg_tready (rtcfg_tready [n]               )
      );

      // Ingress buffer module that does the following:
      // - Stores and gates an incoming packet
      // - Looks up destination in routing table and attaches a tdest for the packet
      chdr_xb_ingress_buff #(
        .WIDTH(WIDTH), .SIZE(INGRESS_BUFF_SIZE),
        .XB_NPORTS(NPORTS), .SID_OFFSET(SID_OFFSET), .SID_WIDTH(SID_WIDTH)
      ) buf_i (
        .clk                 (clk                                    ),
        .reset               (reset                                  ),
        .s_axis_chdr_tdata   (i_tdata      [n]                       ),
        .s_axis_chdr_tlast   (i_tlast      [n]                       ),
        .s_axis_chdr_tvalid  (i_tvalid     [n]                       ),
        .s_axis_chdr_tready  (i_tready     [n]                       ),
        .m_axis_chdr_tdata   (buf_tdata    [n]                       ),
        .m_axis_chdr_tdest   (buf_tdest_tmp[n]                       ),
        .m_axis_chdr_tkeep   (buf_tkeep    [n]                       ),
        .m_axis_chdr_tlast   (buf_tlast    [n]                       ),
        .m_axis_chdr_tvalid  (buf_tvalid   [n]                       ),
        .m_axis_chdr_tready  (buf_tready   [n]                       ),
        .m_axis_find_tdata   (find_tdata   [(n*SID_WIDTH)+:SID_WIDTH]),
        .m_axis_find_tvalid  (find_tvalid  [n]                       ),
        .m_axis_find_tready  (find_tready  [n]                       ),
        .s_axis_result_tdata (result_tdata [(n*NPORTS_W)+:NPORTS_W]  ),
        .s_axis_result_tkeep (result_tkeep [n]                       ),
        .s_axis_result_tvalid(result_tvalid[n]                       ),
        .s_axis_result_tready(result_tready[n]                       )
      );
      assign buf_tdest[n] = buf_tkeep[n] ? buf_tdest_tmp[n] : DEFAULT_PORT[NPORTS_W-1:0];

      // Pipeline state
      axi_fifo #(
        .WIDTH(WIDTH+1+NPORTS_W), .SIZE(1)
      ) pipe_i (
        .clk      (clk), 
        .reset    (reset), 
        .clear    (1'b0),
        .i_tdata  ({buf_tlast[n], buf_tdest[n], buf_tdata[n]}),
        .i_tvalid (buf_tvalid[n]),
        .i_tready (buf_tready[n]),
        .o_tdata  ({swi_tlast[n], swi_tdest[n], swi_tdata[n]}),
        .o_tvalid (swi_tvalid[n]),
        .o_tready (swi_tready[n]),
        .space    (),
        .occupied ()
      );

      // Ingress demux. Use the tdest field to determine packet destination
      axis_switch #(
        .DATA_W(WIDTH), .DEST_W(1), .IN_PORTS(1), .OUT_PORTS(NPORTS), .PIPELINE(1)
      ) demux_i (
        .clk           (clk                  ),
        .reset         (reset                ),
        .s_axis_tdata  (swi_tdata [n]        ),
        .s_axis_tdest  ({1'b0, swi_tdest [n]}), 
        .s_axis_tlast  (swi_tlast [n]        ),
        .s_axis_tvalid (swi_tvalid[n]        ),
        .s_axis_tready (swi_tready[n]        ),
        .s_axis_alloc  (1'b0                 ),
        .m_axis_tdata  (swo_tdata [n]        ),
        .m_axis_tdest  (/* Unused */         ),
        .m_axis_tlast  (swo_tlast [n]        ),
        .m_axis_tvalid (swo_tvalid[n]        ),
        .m_axis_tready (swo_tready[n]        )
      );
    end

    for (i = 0; i < NPORTS; i = i + 1) begin
      for (j = 0; j < NPORTS; j = j + 1) begin
        assign muxi_tdata [i][j*WIDTH+:WIDTH] = swo_tdata  [j][i*WIDTH+:WIDTH];
        assign muxi_tlast [i][j]              = swo_tlast  [j][i];
        assign muxi_tvalid[i][j]              = swo_tvalid [j][i];
        assign swo_tready [i][j]              = muxi_tready[j][i];
      end
    end

    for (n = 0; n < NPORTS; n = n + 1) begin: o_ports
      if (OPTIMIZE == "PERFORMANCE") begin
        // Use the axis_switch module when optimizing for performance
        // This logic has some extra levels of logic to ensure
        // that the switch allocation happens in 0 clock cycles which
        // means that Fmax for this implementation will be lower.

        wire mux_ready = |muxi_tready[n];   // Max 1 bit should be high
        wire mux_valid = |muxi_tvalid[n];
        wire mux_last  = |(muxi_tvalid[n] & muxi_tlast[n]);
  
        // Track the input packet state
        reg [0:0] pkt_state = PKT_ST_HEAD;
        always @(posedge clk) begin
          if (reset) begin
            pkt_state <= PKT_ST_HEAD;
          end else if (mux_valid & mux_ready) begin
            pkt_state <= mux_last ? PKT_ST_HEAD : PKT_ST_BODY;
          end
        end
  
        // The switch requires the allocation to stay valid until the
        // end of the packet. We also might need to keep the previous
        // packet's allocation to compute the current one
        reg  [NPORTS_W-1:0] prev_sw_alloc = {NPORTS_W{1'b0}};
        reg  [NPORTS_W-1:0] pkt_sw_alloc  = {NPORTS_W{1'b0}};
        wire [NPORTS_W-1:0] muxi_sw_alloc = (mux_valid && pkt_state == PKT_ST_HEAD) ? 
          compute_mux_alloc(muxi_tvalid[n], prev_sw_alloc) : pkt_sw_alloc;
  
        always @(posedge clk) begin
          if (reset) begin
            prev_sw_alloc <= {NPORTS_W{1'b0}};
            pkt_sw_alloc <= {NPORTS_W{1'b0}};
          end else if (mux_valid & mux_ready) begin
            if (pkt_state == PKT_ST_HEAD)
              pkt_sw_alloc <= muxi_sw_alloc;
            if (mux_last)
              prev_sw_alloc <= muxi_sw_alloc;
          end
        end
  
        axis_switch #(
          .DATA_W(WIDTH), .DEST_W(1), .IN_PORTS(NPORTS), .OUT_PORTS(1),
          .PIPELINE(0)
        ) mux_i (
          .clk           (clk                            ),
          .reset         (reset                          ),
          .s_axis_tdata  (muxi_tdata [n]                 ),
          .s_axis_tdest  ({NPORTS{1'b0}} /* Unused */    ),
          .s_axis_tlast  (muxi_tlast [n]                 ),
          .s_axis_tvalid (muxi_tvalid[n]                 ),
          .s_axis_tready (muxi_tready[n]                 ),
          .s_axis_alloc  (muxi_sw_alloc                  ),
          .m_axis_tdata  (m_axis_tdata [(n*WIDTH)+:WIDTH]),
          .m_axis_tdest  (/* Unused */                   ),
          .m_axis_tlast  (m_axis_tlast [n]               ),
          .m_axis_tvalid (m_axis_tvalid[n]               ),
          .m_axis_tready (m_axis_tready[n]               )
        );
      end else begin
        // axi_mux has an additional bubble cycle but the logic
        // to allocate an input port has fewer levels and takes
        // up fewer resources.
        axi_mux #(
          .PRIO(MUX_ALLOC == "PRIO"), .WIDTH(WIDTH), .SIZE(NPORTS),
          .PRE_FIFO_SIZE(OPTIMIZE == "TIMING" ? 1 : 0), .POST_FIFO_SIZE(1)
        ) mux_i (
          .clk      (clk                            ),
          .reset    (reset                          ),
          .clear    (1'b0                           ),
          .i_tdata  (muxi_tdata   [n]               ),
          .i_tlast  (muxi_tlast   [n]               ),
          .i_tvalid (muxi_tvalid  [n]               ),
          .i_tready (muxi_tready  [n]               ),
          .o_tdata  (m_axis_tdata [(n*WIDTH)+:WIDTH]),
          .o_tlast  (m_axis_tlast [n]               ),
          .o_tvalid (m_axis_tvalid[n]               ),
          .o_tready (m_axis_tready[n]               )
        );
      end
    end
  endgenerate


endmodule
