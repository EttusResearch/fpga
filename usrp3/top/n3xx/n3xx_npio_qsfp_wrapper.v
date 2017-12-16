///////////////////////////////////////////////////////////////////
//
// Copyright 2017 Ettus Research, A National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0
//
// Module: n3xx_npio_qsfp_wrapper
// Description:
//   Aurora wrapper for up to 4 QSFP lanes 
//
//////////////////////////////////////////////////////////////////////

module n3xx_npio_qsfp_wrapper #(
   parameter LANES        = 4,      // Number of lanes of Aurora to instantiate (Supported = {1,2,3,4})
   parameter REG_BASE     = 32'h0,  // Base register address
   parameter PORTNUM_BASE = 4,      // Base port number for discovery
   parameter REG_DWIDTH   = 32,     // Width of regport address bus
   parameter REG_AWIDTH   = 14      // Width of regport data bus
)(
  // Clocks and Resets
  input                   areset,
  input                   bus_clk,
  input                   misc_clk,
  input                   bus_rst,
  input                   gt_refclk,
  input                   gt_clk156,
  // Serial lanes
  output [LANES-1:0]      txp,
  output [LANES-1:0]      txn,
  input  [LANES-1:0]      rxp,
  input  [LANES-1:0]      rxn,
  // AXIS input interface
  input  [(LANES*64)-1:0] s_axis_tdata,
  input  [LANES-1:0]      s_axis_tlast,
  input  [LANES-1:0]      s_axis_tvalid,
  output [LANES-1:0]      s_axis_tready,
  // AXIS output interface
  output [(LANES*64)-1:0] m_axis_tdata,
  output [LANES-1:0]      m_axis_tlast,
  output [LANES-1:0]      m_axis_tvalid,
  input  [LANES-1:0]      m_axis_tready,
  // Register ports
  input                   reg_wr_req,
  input  [REG_AWIDTH-1:0] reg_wr_addr,
  input  [REG_DWIDTH-1:0] reg_wr_data,
  input                   reg_rd_req,
  input  [REG_AWIDTH-1:0] reg_rd_addr,
  output                  reg_rd_resp,
  output [REG_DWIDTH-1:0] reg_rd_data,

  output [LANES-1:0]      link_up,
  output [LANES-1:0]      activity
);

   localparam REG_BLOCK_SIZE = 'h40;

  //--------------------------------------------------------------
  // Common clocking
  //--------------------------------------------------------------

  wire              qpllreset;
  wire              qplllock;
  wire              qplloutclk;
  wire              qplloutrefclk;
  wire              qpllrefclklost;
  wire [LANES-1:0]  qpllreset_ln;

  aurora_64b66b_pcs_pma_gt_common_wrapper gt_common_support (
    .gt_qpllclk_quad1_out      (qplloutclk),
    .gt_qpllrefclk_quad1_out   (qplloutrefclk),
    .GT0_GTREFCLK0_COMMON_IN   (gt_refclk), 
    .GT0_QPLLLOCK_OUT          (qplllock),
    .GT0_QPLLRESET_IN          (qpllreset),
    .GT0_QPLLLOCKDETCLK_IN     (misc_clk),
    .GT0_QPLLREFCLKLOST_OUT    (qpllrefclklost),
    .qpll_drpaddr_in           (8'h0),
    .qpll_drpdi_in             (16'h0),
    .qpll_drpclk_in            (1'b0),
    .qpll_drpdo_out            (), 
    .qpll_drprdy_out           (), 
    .qpll_drpen_in             (1'b0), 
    .qpll_drpwe_in             (1'b0)
  );

  assign qpllreset = |qpllreset_ln;

  wire [LANES-1:0]  gt_tx_out_clk;
  wire [LANES-1:0]  gt_pll_lock;
  wire              user_clk;
  wire              sync_clk;
  wire              mmcm_locked;

  aurora_phy_mmcm aurora_phy_mmcm (
    .aurora_tx_clk_unbuf(gt_tx_out_clk[0]),
    .mmcm_reset(~gt_pll_lock[0]),
    .user_clk(user_clk),
    .sync_clk(sync_clk),
    .mmcm_locked(mmcm_locked)
  );

  //--------------------------------------------------------------
  // Register bus
  //--------------------------------------------------------------

  wire [LANES-1:0]      reg_rd_resp_flat;
  wire [(LANES*32)-1:0] reg_rd_data_flat;

  regport_resp_mux #(
    .WIDTH      (REG_DWIDTH),
    .NUM_SLAVES (LANES)
  ) reg_resp_mux_i(
    .clk(bus_clk), .reset(bus_rst),
    .sla_rd_resp(reg_rd_resp_flat), .sla_rd_data(reg_rd_data_flat),
    .mst_rd_resp(reg_rd_resp), .mst_rd_data(reg_rd_data)
  );

  //--------------------------------------------------------------
  // Lanes
  //--------------------------------------------------------------

  genvar l;
  generate 
    for (l = 0; l < LANES; l = l + 1) begin: lanes
      n3xx_mgt_io_core #(
        .PROTOCOL       ("Aurora"),
        .REG_BASE       (REG_BASE + (REG_BLOCK_SIZE * l)),
        .REG_DWIDTH     (REG_DWIDTH),   // Width of the AXI4-Lite data bus (must be 32 or 64)
        .REG_AWIDTH     (REG_AWIDTH),   // Width of the address bus
        .MDIO_EN        (0),
        .PORTNUM        (PORTNUM_BASE + l)
      ) mgt_io_i (
        //must reset all channels on quad when sfp1 gtx core is reset
        .areset         (areset),
        .gt_refclk      (gt_refclk),
        .gb_refclk      (gt_clk156),
        .misc_clk       (misc_clk),
        .user_clk       (user_clk),
        .sync_clk       (sync_clk),
        .gt_tx_out_clk_unbuf(gt_tx_out_clk[l]),

        .bus_rst        (bus_rst),
        .bus_clk        (bus_clk),
        .qpllreset      (qpllreset_ln[l]),
        .qplllock       (qplllock),
        .qplloutclk     (qplloutclk),
        .qplloutrefclk  (qplloutrefclk),
        .qpllrefclklost (qpllrefclklost),
        .mmcm_locked    (mmcm_locked),
        .gt_pll_lock    (gt_pll_lock[l]),

        .txp            (txp[l]),
        .txn            (txn[l]),
        .rxp            (rxp[l]),
        .rxn            (rxn[l]),

        .sfpp_rxlos     (1'b0),
        .sfpp_tx_fault  (1'b0),
        .sfpp_tx_disable(),

        //RegPort
        .reg_wr_req     (reg_wr_req),
        .reg_wr_addr    (reg_wr_addr),
        .reg_wr_data    (reg_wr_data),
        .reg_rd_req     (reg_rd_req),
        .reg_rd_addr    (reg_rd_addr),
        .reg_rd_resp    (reg_rd_data_flat[((l+1)*REG_DWIDTH)-1:l*REG_DWIDTH]),
        .reg_rd_data    (reg_rd_resp_flat[l]),

        // User Interface (Synchronous to sys_clk)
        .s_axis_tdata   (s_axis_tdata[((l+1)*64)-1:l*64]),
        .s_axis_tuser   (4'h0),
        .s_axis_tlast   (s_axis_tlast[l]),
        .s_axis_tvalid  (s_axis_tvalid[l]),
        .s_axis_tready  (s_axis_tready[l]),
        .m_axis_tdata   (m_axis_tdata[((l+1)*64)-1:l*64]),
        .m_axis_tuser   (),
        .m_axis_tlast   (m_axis_tlast[l]),
        .m_axis_tvalid  (m_axis_tvalid[l]),
        .m_axis_tready  (m_axis_tready[l]),

        .link_up        (link_up[l]),
        .activity       (activity[l])
      );
    end
  endgenerate

endmodule
