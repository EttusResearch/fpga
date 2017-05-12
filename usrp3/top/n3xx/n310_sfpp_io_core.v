/////////////////////////////////////////////////////////////////////
//
// Copyright 2016-2017 Ettus Research
//
// sfpp_io_core
// - mdio_master
// - One Gige phy + MAC
// - Ten Gige phy + MAC
//
//////////////////////////////////////////////////////////////////////

module n310_sfpp_io_core #(
  parameter        PROTOCOL = "10GbE",    // Must be {10GbE, 1GbE, Aurora}
  parameter [13:0] REG_BASE = 14'h0,
  parameter        REG_DWIDTH = 32,
  parameter        REG_AWIDTH = 14,
  parameter        PORTNUM  = 8'd0,
  parameter        MDIO_EN  = 0
  )(
  // Resets
  input             areset,
  input             bus_rst,
  // Clocks
  input             gt_refclk,
  input             gb_refclk,
  input             misc_clk,
  input             bus_clk,
  // SFP high-speed IO
  output            txp,
  output            txn,
  input             rxp,
  input             rxn,
  // SFP low-speed IO
  input             sfpp_rxlos,
  input             sfpp_tx_fault,
  output            sfpp_tx_disable,
  // Data port: Ethernet TX
  input  [63:0]     s_axis_tdata,
  input  [3:0]      s_axis_tuser,
  input             s_axis_tlast,
  input             s_axis_tvalid,
  output            s_axis_tready,
  // Data port: Ethernet RX
  output [63:0]     m_axis_tdata,
  output [3:0]      m_axis_tuser,
  output            m_axis_tlast,
  output            m_axis_tvalid,
  input             m_axis_tready,
  // Register port
  input                       reg_wr_req,
  input  [REG_AWIDTH-1:0]     reg_wr_addr,
  input  [REG_DWIDTH-1:0]     reg_wr_data,
  input                       reg_rd_req,
  input  [REG_AWIDTH-1:0]     reg_rd_addr,
  output reg                  reg_rd_resp,
  output reg [REG_DWIDTH-1:0] reg_rd_data,
  // GT Common
  input             gt0_qplloutclk,
  input             gt0_qplloutrefclk,
  output            pma_reset_out,
  output [15:0]     phy_status,
  output            qpllreset,
  input             qplllock,
  input             qplloutclk,
  input             qplloutrefclk

);
  //-----------------------------------------------------------------
  // Registers
  //-----------------------------------------------------------------
  localparam REG_MAC_CTRL_STATUS = REG_BASE + 32'h0;
  localparam REG_PHY_CTRL_STATUS = REG_BASE + 32'h4;

  wire        reg_rd_resp_mdio;
  reg         reg_rd_resp_glob = 1'b0;
  wire [31:0] reg_rd_data_mdio;
  reg  [31:0] mac_ctrl_reg, phy_ctrl_reg, readback_reg;
  wire [8:0] mac_status;
  wire [31:0] mac_status_bclk, phy_status_bclk;

  synchronizer #( .STAGES(2), .WIDTH(32), .INITIAL_VAL(32'h0) ) mac_status_sync_i (
     .clk(bus_clk), .rst(1'b0), .in({23'b0, mac_status}), .out(mac_status_bclk)
  );

  synchronizer #( .STAGES(2), .WIDTH(32), .INITIAL_VAL(32'h0) ) phy_status_sync_i (
     .clk(bus_clk), .rst(1'b0), .in({16'b0, phy_status}), .out(phy_status_bclk)
  );

  always @(posedge bus_clk) begin
     if (bus_rst) begin
        mac_ctrl_reg <= {31'h0, 1'b1}; // tx_enable on reset?
     end else if (reg_wr_req) begin
        case(reg_wr_addr)
           REG_MAC_CTRL_STATUS:
              mac_ctrl_reg <= reg_wr_data;
           REG_PHY_CTRL_STATUS:
              phy_ctrl_reg <= reg_wr_data;
        endcase
     end
  end

  always @(posedge bus_clk) begin
     // No reset handling needed for readback
     if (reg_rd_req) begin
        reg_rd_resp_glob <= 1'b1;
        case(reg_rd_addr)
           REG_MAC_CTRL_STATUS:
              readback_reg <= mac_status_bclk;
           REG_PHY_CTRL_STATUS:
              readback_reg <= phy_status_bclk;
           default:
              reg_rd_resp_glob <= 1'b0;
        endcase
     end if (reg_rd_resp_glob) begin
        reg_rd_resp_glob <= 1'b0;
     end
  end

  always @(posedge bus_clk) begin
   reg_rd_resp <= reg_rd_resp_glob | reg_rd_resp_mdio;
   reg_rd_data <= reg_rd_resp_mdio ? reg_rd_data_mdio : readback_reg;
  end

  //-----------------------------------------------------------------
  // MDIO Master
  //-----------------------------------------------------------------
  wire mdc, mdio_m2s, mdio_s2m;

  generate if (MDIO_EN == 1) begin
     mdio_master #(
        .REG_BASE      (REG_BASE + 32'h10),
        .REG_AWIDTH    (REG_AWIDTH),
        .MDC_DIVIDER   (8'd200)
     ) mdio_master_i (
        .clk        (bus_clk),
        .rst        (bus_rst),
        .mdc        (mdc),
        .mdio_in    (mdio_s2m),
        .mdio_out   (mdio_m2s),
        .mdio_tri   (),
        .reg_wr_req (reg_wr_req),
        .reg_wr_addr(reg_wr_addr),
        .reg_wr_data(reg_wr_data),
        .reg_rd_req (reg_rd_req),
        .reg_rd_addr(reg_rd_addr),
        .reg_rd_data(reg_rd_data_mdio),
        .reg_rd_resp(reg_rd_resp_mdio)
     );
  end else begin
     assign mdc              = 1'b0;
     assign mdio_m2s         = 1'b0;
     assign reg_rd_resp_mdio = 1'b0;
     assign reg_rd_data_mdio = 32'h0;
  end endgenerate

generate
  if (PROTOCOL == "10GbE") begin
    //-----------------------------------------------------------------
    // 10 Gigabit Ethernet
    //-----------------------------------------------------------------
    wire [63:0] xgmii_txd;
    wire [7:0]  xgmii_txc;
    wire [63:0] xgmii_rxd;
    wire [7:0]  xgmii_rxc;
    wire [7:0]  xgmii_status;
    wire        xge_phy_resetdone;

    ten_gige_phy ten_gige_phy_i
    (
      // Clocks and Reset
      .areset	        	(areset | phy_ctrl_reg[0]), // Asynchronous reset for entire core.
      .refclk	        	(gt_refclk),              // Transciever reference clock: 156.25MHz
      .clk156		    	(gb_refclk),              // Globally buffered core clock: 156.25MHz
      .dclk		    	(misc_clk),                 // Management/DRP clock: 78.125MHz
      .sim_speedup_control(1'b0),
      // GMII Interface	(client MAC <=> PCS)
      .xgmii_txd			(xgmii_txd),          // Transmit data from client MAC.
      .xgmii_txc			(xgmii_txc),          // Transmit control signal from client MAC.
      .xgmii_rxd			(xgmii_rxd),          // Received Data to client MAC.
      .xgmii_rxc			(xgmii_rxc),          // Received control signal to client MAC.
      // Tranceiver Interface
      .txp		    	(txp),                       // Differential +ve of serial transmission from PMA to PMD.
      .txn		    	(txn),                       // Differential -ve of serial transmission from PMA to PMD.
      .rxp		    	(rxp),                       // Differential +ve for serial reception from PMD to PMA.
      .rxn		    	(rxn),                       // Differential -ve for serial reception from PMD to PMA.
      // Management: MDIO Interface
      .mdc		    	(mdc),                       // Management Data Clock
      .mdio_in			(mdio_m2s),              // Management Data In
      .mdio_out			(mdio_s2m),             // Management Data Out
      .mdio_tri			(),                     // Management Data Tristate
      .prtad		    	(5'd4),                    // MDIO address is 4
      // General IO's
      .core_status		(xgmii_status),     // Core status
      .resetdone			(xge_phy_resetdone),
      .signal_detect		(~sfpp_rxlos),     // Input from PMD to indicate presence of optical input.		(Undocumented, but it seems Xilinx expect this to be inverted.)
      .tx_fault			(sfpp_tx_fault),
      .tx_disable			(sfpp_tx_disable),
      .qpllreset			(qpllreset),
      .qplllock			(qplllock),
      .qplloutclk			(qplloutclk),
      .qplloutrefclk	    (qplloutrefclk)
    );

    n310_xge_mac_wrapper #(.PORTNUM(PORTNUM)) xge_mac_wrapper_i
    (
      // XGMII
      .xgmii_clk              (gb_refclk),
      .xgmii_txd              (xgmii_txd),
      .xgmii_txc              (xgmii_txc),
      .xgmii_rxd              (xgmii_rxd),
      .xgmii_rxc              (xgmii_rxc),
      // Client FIFO Interfaces
      .sys_clk                (bus_clk),
      .sys_rst                (bus_rst),
      .rx_tdata               (m_axis_tdata),
      .rx_tuser               (m_axis_tuser),
      .rx_tlast               (m_axis_tlast),
      .rx_tvalid              (m_axis_tvalid),
      .rx_tready              (m_axis_tready),
      .tx_tdata               (s_axis_tdata),
      .tx_tuser               (s_axis_tuser),   // Bit[3] (error) is ignored for now.
      .tx_tlast               (s_axis_tlast),
      .tx_tvalid              (s_axis_tvalid),
      .tx_tready              (s_axis_tready),
      // Other
      .phy_ready              (xge_phy_resetdone),
      .ctrl_tx_enable         (mac_ctrl_reg[0]),
      .status_crc_error       (mac_status[0]),
      .status_fragment_error  (mac_status[1]),
      .status_txdfifo_ovflow  (mac_status[2]),
      .status_txdfifo_udflow  (mac_status[3]),
      .status_rxdfifo_ovflow  (mac_status[4]),
      .status_rxdfifo_udflow  (mac_status[5]),
      .status_pause_frame_rx  (mac_status[6]),
      .status_local_fault     (mac_status[7]),
      .status_remote_fault    (mac_status[8])
    );

    // Remove Warning from XG build
    assign pma_reset_out = 1'b0;

    assign phy_status  = {8'h00, xgmii_status};

  end else if (PROTOCOL == "1GbE") begin

    //-----------------------------------------------------------------
    // 1 Gigabit Ethernet
    //-----------------------------------------------------------------
    wire [7:0]  gmii_txd, gmii_rxd;
    wire        gmii_tx_en, gmii_tx_er, gmii_rx_dv, gmii_rx_er;
    wire        gmii_clk;

    assign sfpp_tx_disable = 1'b0; // Always on.

    one_gige_phy one_gige_phy_i
    (
       .reset(areset | phy_ctrl_reg[0]),                  // Asynchronous reset for entire core.
       .pma_reset_out(pma_reset_out),
       .independent_clock(bus_clk),
       .gt0_qplloutclk_in(gt0_qplloutclk),
       .gt0_qplloutrefclk_in(gt0_qplloutrefclk),
       // Tranceiver Interface
       .gtrefclk(gt_refclk),            // Reference clock for MGT: 125MHz, very high quality.
       .gtrefclk_bufg(gb_refclk),       // Reference clock routed through a BUFG
       .txp(txp),                       // Differential +ve of serial transmission from PMA to PMD.
       .txn(txn),                       // Differential -ve of serial transmission from PMA to PMD.
       .rxp(rxp),                       // Differential +ve for serial reception from PMD to PMA.
       .rxn(rxn),                       // Differential -ve for serial reception from PMD to PMA.
       // GMII Interface (client MAC <=> PCS)
       .gmii_clk(gmii_clk),            // Clock to client MAC.
       .gmii_txd(gmii_txd),            // Transmit data from client MAC.
       .gmii_tx_en(gmii_tx_en),        // Transmit control signal from client MAC.
       .gmii_tx_er(gmii_tx_er),        // Transmit control signal from client MAC.
       .gmii_rxd(gmii_rxd),            // Received Data to client MAC.
       .gmii_rx_dv(gmii_rx_dv),        // Received control signal to client MAC.
       .gmii_rx_er(gmii_rx_er),        // Received control signal to client MAC.
       // Management: MDIO Interface
       .mdc(mdc),                      // Management Data Clock
       .mdio_i(mdio_m2s),              // Management Data In
       .mdio_o(mdio_s2m),              // Management Data Out
       .mdio_t(),                       // Management Data Tristate
       .configuration_vector(5'd0),     // Alternative to MDIO interface.
       .configuration_valid(1'b1),      // Validation signal for Config vector (MUST be 1 for proper functionality...undocumented)
       // General IO's
       .status_vector(phy_status),    // Core status.
       .signal_detect(1'b1 /*Optical module not supported*/) // Input from PMD to indicate presence of optical input.
    );

    simple_gemac_wrapper #(.RX_FLOW_CTRL(0), .PORTNUM(PORTNUM)) simple_gemac_wrapper_i
    (
       .clk125(gmii_clk),
       .reset(areset),

       .GMII_GTX_CLK(),
       .GMII_TX_EN(gmii_tx_en),
       .GMII_TX_ER(gmii_tx_er),
       .GMII_TXD(gmii_txd),
       .GMII_RX_CLK(gmii_clk),
       .GMII_RX_DV(gmii_rx_dv),
       .GMII_RX_ER(gmii_rx_er),
       .GMII_RXD(gmii_rxd),

       .sys_clk(bus_clk),
       .rx_tdata(m_axis_tdata),
       .rx_tuser(m_axis_tuser),
       .rx_tlast(m_axis_tlast),
       .rx_tvalid(m_axis_tvalid),
       .rx_tready(m_axis_tready),
       .tx_tdata(s_axis_tdata),
       .tx_tuser(s_axis_tuser),
       .tx_tlast(s_axis_tlast),
       .tx_tvalid(s_axis_tvalid),
       .tx_tready(s_axis_tready),
       // Debug
       .debug_tx(), .debug_rx()
    );

  end else begin

     //Invalid protocol

  end
endgenerate

endmodule
