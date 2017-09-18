/////////////////////////////////////////////////////////////////////
//
// Copyright 2016-2017 Ettus Research
//
// Description: This module has the following blocks:
//
// - sfpp_io_core - Ethernet PHY and MAC
// - eth_switch - Route packets to ARM, CROSSOVER and AXI_CROSSBAR
// - regport - Control all registers - MDIO, MAC, IP/UDP
//
/////////////////////////////////////////////////////////////////////

module network_interface #(
  parameter DWIDTH  = 32,    // Width of the AXI4-Lite data bus (must be 32 or 64)
  parameter AWIDTH  = 14,    // Width of the address bus
  parameter PROTOCOL = "10GbE",    // Must be {10GbE, 1GbE, Aurora}
  parameter PORTNUM  = 8'd0,
  parameter MDIO_EN  = 0
  )(
  // Resets
  input         areset,
  input         bus_rst,

  // Clocks
  input         gt_refclk,
  input         gb_refclk,
  input         misc_clk,
  input         bus_clk,

  input                s_axi_aclk,
  input                s_axi_aresetn,
  input [AWIDTH-1:0]   s_axi_awaddr,
  input                s_axi_awvalid,
  output               s_axi_awready,

  input [DWIDTH-1:0]   s_axi_wdata,
  input [DWIDTH/8-1:0] s_axi_wstrb,
  input                s_axi_wvalid,
  output               s_axi_wready,

  output [1:0]         s_axi_bresp,
  output               s_axi_bvalid,
  input                s_axi_bready,

  input [AWIDTH-1:0]   s_axi_araddr,
  input                s_axi_arvalid,
  output               s_axi_arready,

  output [DWIDTH-1:0]  s_axi_rdata,
  output [1:0]         s_axi_rresp,
  output               s_axi_rvalid,
  input                s_axi_rready,

  // SFP high-speed IO
  output        txp,
  output        txn,
  input         rxp,
  input         rxn,

  // SFP low-speed IO
  input         sfpp_rxlos,
  input         sfpp_tx_fault,
  output        sfpp_tx_disable,

  output [15:0] sfp_phy_status,

  //GT Common
  input         gt0_qplloutclk,
  input         gt0_qplloutrefclk,
  output        pma_reset_out,
  output        qpllreset,
  output        qpllrefclklost,
  input         qplllock,
  input         qplloutclk,
  input         qplloutrefclk,

  // Vita router interface
  output  [63:0]  e2v_tdata,
  output          e2v_tlast,
  output          e2v_tvalid,
  input           e2v_tready,

  input   [63:0]  v2e_tdata,
  input           v2e_tlast,
  input           v2e_tvalid,
  output          v2e_tready,

  // Ethernet crossover
  output  [63:0]  xo_tdata,
  output  [3:0]   xo_tuser,
  output          xo_tlast,
  output          xo_tvalid,
  input           xo_tready,

  input   [63:0]  xi_tdata,
  input   [3:0]   xi_tuser,
  input           xi_tlast,
  input           xi_tvalid,
  output          xi_tready,

  // CPU
  output  [63:0]  e2c_tdata,
  output  [7:0]   e2c_tkeep,
  output          e2c_tlast,
  output          e2c_tvalid,
  input           e2c_tready,

  input   [63:0]  c2e_tdata,
  input   [7:0]   c2e_tkeep,
  input           c2e_tlast,
  input           c2e_tvalid,
  output          c2e_tready,

  // MISC
  output          activity_led
  );

  //////////////////////////////////////////////////////////////////////
  //
  // AXI4-Lite to RegPort (PS to PL Register Access)
  //
  //////////////////////////////////////////////////////////////////////

  wire                reg_wr_req;
  wire  [AWIDTH-1:0]  reg_wr_addr;
  wire  [DWIDTH-1:0]  reg_wr_data;
  wire                reg_rd_req;
  wire  [AWIDTH-1:0]  reg_rd_addr;
  wire                reg_rd_resp;
  wire  [DWIDTH-1:0]  reg_rd_data;

  wire  [DWIDTH-1:0]  reg_rd_data_misc;
  wire  [DWIDTH-1:0]  reg_rd_data_mdio;
  wire                reg_rd_resp_misc;
  wire                reg_rd_resp_mdio;

  axil_regport_master #(
     .DWIDTH   (DWIDTH),     // Width of the AXI4-Lite data bus (must be 32 or 64)
     .AWIDTH   (AWIDTH),     // Width of the address bus
     .WRBASE   (0),          // Write address base
     .RDBASE   (0),          // Read address base
     .TIMEOUT  (10)          // log2(timeout). Read will timeout after (2^TIMEOUT - 1) cycles
  ) network_regport_master_i (
     // Clock and reset
     .s_axi_aclk    (s_axi_aclk),
     .s_axi_aresetn (s_axi_aresetn),
     // AXI4-Lite: Write address port (domain: s_axi_aclk)
     .s_axi_awaddr  (s_axi_awaddr),
     .s_axi_awvalid (s_axi_awvalid),
     .s_axi_awready (s_axi_awready),
     // AXI4-Lite: Write data port (domain: s_axi_aclk)
     .s_axi_wdata   (s_axi_wdata),
     .s_axi_wstrb   (s_axi_wstrb),
     .s_axi_wvalid  (s_axi_wvalid),
     .s_axi_wready  (s_axi_wready),
     // AXI4-Lite: Write response port (domain: s_axi_aclk)
     .s_axi_bresp   (s_axi_bresp),
     .s_axi_bvalid  (s_axi_bvalid),
     .s_axi_bready  (s_axi_bready),
     // AXI4-Lite: Read address port (domain: s_axi_aclk)
     .s_axi_araddr  (s_axi_araddr),
     .s_axi_arvalid (s_axi_arvalid),
     .s_axi_arready (s_axi_arready),
     // AXI4-Lite: Read data port (domain: s_axi_aclk)
     .s_axi_rdata   (s_axi_rdata),
     .s_axi_rresp   (s_axi_rresp),
     .s_axi_rvalid  (s_axi_rvalid),
     .s_axi_rready  (s_axi_rready),
     // Register port: Write port (domain: reg_clk)
     .reg_clk       (bus_clk),
     .reg_wr_req    (reg_wr_req),
     .reg_wr_addr   (reg_wr_addr),
     .reg_wr_data   (reg_wr_data),
     .reg_wr_keep   (/*unused*/),
     // Register port: Read port (domain: reg_clk)
     .reg_rd_req    (reg_rd_req),
     .reg_rd_addr   (reg_rd_addr),
     .reg_rd_resp   (reg_rd_resp),
     .reg_rd_data   (reg_rd_data)
  );

  // Regport Mux for response
   regport_resp_mux #(
     .WIDTH      (DWIDTH),
     .NUM_SLAVES (2)
  ) network_reg_resp_mux_i(
     .clk(bus_clk), .reset(bus_rst),
     .sla_rd_resp({reg_rd_resp_misc, reg_rd_resp_mdio}),
     .sla_rd_data({reg_rd_data_misc, reg_rd_data_mdio}),
     .mst_rd_resp(reg_rd_resp), .mst_rd_data(reg_rd_data)
  );

  wire [3:0] e2c_tuser;

  assign e2c_tkeep = ~e2c_tlast ? 8'b1111_1111
                   : (e2c_tuser == 4'd0) ? 8'b1111_1111
                   : (e2c_tuser == 4'd1) ? 8'b0000_0001
                   : (e2c_tuser == 4'd2) ? 8'b0000_0011
                   : (e2c_tuser == 4'd3) ? 8'b0000_0111
                   : (e2c_tuser == 4'd4) ? 8'b0000_1111
                   : (e2c_tuser == 4'd5) ? 8'b0001_1111
                   : (e2c_tuser == 4'd6) ? 8'b0011_1111
                   : 8'b0111_1111;

  wire [3:0] c2e_tuser = ~c2e_tlast ? 4'd0
                   : (c2e_tkeep == 8'b1111_1111) ? 4'd0
                   : (c2e_tkeep == 8'b1111_1110) ? 4'd7
                   : (c2e_tkeep == 8'b1111_1100) ? 4'd6
                   : (c2e_tkeep == 8'b1111_1000) ? 4'd5
                   : (c2e_tkeep == 8'b1111_0000) ? 4'd4
                   : (c2e_tkeep == 8'b1110_0000) ? 4'd3
                   : (c2e_tkeep == 8'b1100_0000) ? 4'd2
                   : (c2e_tkeep == 8'b1000_0000) ? 4'd1
                   : 4'd0;

  //////////////////////////////////////////////////////////////////////
  //
  // SFP+ PORT
  //
  //////////////////////////////////////////////////////////////////////

  wire [63:0] sfp_rx_tdata, sfp_tx_tdata;
  wire [3:0]  sfp_rx_tuser, sfp_tx_tuser;
  wire        sfp_rx_tlast, sfp_tx_tlast, sfp_rx_tvalid, sfp_tx_tvalid, sfp_rx_tready, sfp_tx_tready;

  n310_sfpp_io_core #(
     .PROTOCOL(PROTOCOL),
     .REG_BASE(14'h0),
     .REG_DWIDTH (DWIDTH),         // Width of the AXI4-Lite data bus (must be 32 or 64)
     .REG_AWIDTH (AWIDTH),         // Width of the address bus
     .MDIO_EN(1'b1),
     .PORTNUM(8'd0)
  ) sfpp_io_i (
     .areset(areset),
     .gt_refclk(gt_refclk),
     .gb_refclk(gb_refclk),
     .misc_clk(misc_clk),

     .bus_rst(bus_rst),
     .bus_clk(bus_clk),
     .qpllreset(qpllreset),
     .qplllock(qplllock),
     .qplloutclk(qplloutclk),
     .qplloutrefclk(qplloutrefclk),
     .qpllrefclklost(qpllrefclklost),
     
     .txp(txp),
     .txn(txn),
     .rxp(rxp),
     .rxn(rxn),

     .sfpp_rxlos(sfpp_rxlos),
     .sfpp_tx_fault(sfpp_tx_fault),
     .sfpp_tx_disable(sfpp_tx_disable),

     //RegPort
     .reg_wr_req(reg_wr_req),
     .reg_wr_addr(reg_wr_addr),
     .reg_wr_data(reg_wr_data),
     .reg_rd_req(reg_rd_req),
     .reg_rd_addr(reg_rd_addr),
     .reg_rd_resp(reg_rd_resp_mdio),
     .reg_rd_data(reg_rd_data_mdio),

     .s_axis_tdata(sfp_tx_tdata),
     .s_axis_tuser(sfp_tx_tuser),
     .s_axis_tlast(sfp_tx_tlast),
     .s_axis_tvalid(sfp_tx_tvalid),
     .s_axis_tready(sfp_tx_tready),

     .m_axis_tdata(sfp_rx_tdata),
     .m_axis_tuser(sfp_rx_tuser),
     .m_axis_tlast(sfp_rx_tlast),
     .m_axis_tvalid(sfp_rx_tvalid),
     .m_axis_tready(sfp_rx_tready),

     .phy_status(sfp_phy_status)

  );

  //////////////////////////////////////////////////////////////////////
  //
  // Ethernet Soft Switch
  //
  //////////////////////////////////////////////////////////////////////

  eth_switch #(
    .BASE(14'h1000),
    .REG_DWIDTH (DWIDTH),        // Width of the AXI4-Lite data bus (must be 32 or 64)
    .REG_AWIDTH (AWIDTH)         // Width of the address bus
  ) eth_switch (
     .clk(bus_clk),
     .reset(bus_rst),
     .clear(1'b0),

     //RegPort
     .reg_clk(bus_clk),
     .reg_wr_req(reg_wr_req),
     .reg_wr_addr(reg_wr_addr),
     .reg_wr_data(reg_wr_data),
     .reg_wr_keep(/*unused*/),
     .reg_rd_req(reg_rd_req),
     .reg_rd_addr(reg_rd_addr),
     .reg_rd_resp(reg_rd_resp_misc),
     .reg_rd_data(reg_rd_data_misc),

     // SFP
     .eth_tx_tdata(sfp_tx_tdata),
     .eth_tx_tuser(sfp_tx_tuser),
     .eth_tx_tlast(sfp_tx_tlast),
     .eth_tx_tvalid(sfp_tx_tvalid),
     .eth_tx_tready(sfp_tx_tready),
     .eth_rx_tdata(sfp_rx_tdata),
     .eth_rx_tuser(sfp_rx_tuser),
     .eth_rx_tlast(sfp_rx_tlast),
     .eth_rx_tvalid(sfp_rx_tvalid),
     .eth_rx_tready(sfp_rx_tready),

     // Ethernet to Vita
     .e2v_tdata(e2v_tdata),
     .e2v_tlast(e2v_tlast),
     .e2v_tvalid(e2v_tvalid),
     .e2v_tready(e2v_tready),

     // Vita to Ethernet
     .v2e_tdata(v2e_tdata),
     .v2e_tlast(v2e_tlast),
     .v2e_tvalid(v2e_tvalid),
     .v2e_tready(v2e_tready),

     // Crossover
     .xo_tdata(xo_tdata),
     .xo_tuser(xo_tuser),
     .xo_tlast(xo_tlast),
     .xo_tvalid(xo_tvalid),
     .xo_tready(xo_tready),
     .xi_tdata(xi_tdata),
     .xi_tuser(xi_tuser),
     .xi_tlast(xi_tlast),
     .xi_tvalid(xi_tvalid),
     .xi_tready(xi_tready),

     // Ethernet to CPU, also endian swap here
     .e2c_tdata({e2c_tdata[7:0], e2c_tdata[15:8], e2c_tdata[23:16], e2c_tdata[31:24],
                 e2c_tdata[39:32], e2c_tdata[47:40], e2c_tdata[55:48], e2c_tdata[63:56]}),
     .e2c_tuser(e2c_tuser),
     .e2c_tlast(e2c_tlast),
     .e2c_tvalid(e2c_tvalid),
     .e2c_tready(e2c_tready),

     // CPU to Ethernet, also endian swap here
     .c2e_tdata({c2e_tdata[7:0], c2e_tdata[15:8], c2e_tdata[23:16], c2e_tdata[31:24],
                 c2e_tdata[39:32], c2e_tdata[47:40], c2e_tdata[55:48], c2e_tdata[63:56]}),
     .c2e_tuser(c2e_tuser),
     .c2e_tlast(c2e_tlast),
     .c2e_tvalid(c2e_tvalid),
     .c2e_tready(c2e_tready),
     .debug()
   );

  pulse_stretch inst_pulse_stretch0 (
    .clk(bus_clk),
    .rst(bus_rst),
    .pulse(sfp_rx_tvalid & sfp_rx_tready || sfp_tx_tvalid & sfp_tx_tready),
    .pulse_stretched(activity_led)
  );

endmodule
