


module eth_jesd_gtp_phy #(
   parameter ETH_CLK_MASTER_PORT = 0,
   parameter SIM_SPEEDUP = "TRUE"
) (
   // Clock/reset
   input          areset,
   input          independent_clock,
//   input          jesd_refclk,
//   input          jesd_refclk_locked,
   // Clock inputs to the MGT
   input          gtrefclk0_p, gtrefclk0_n,
//   input          gtrefclk1_p, gtrefclk1_n,
   // SFP Transceiver lanes
   input          sfp0rx_p, sfp0rx_n,
   output         sfp0tx_p, sfp0tx_n,
   input          sfp1rx_p, sfp1rx_n,
   output         sfp1tx_p, sfp1tx_n,
   // JESD204A Transceiver lanes
//   output         jesd0tx_p, jesd0tx_n,
//   output         jesd0frame_p, jesd0_frame_n,
//   input          jesd0sync_p, jesd0_sync_n,
//   output         jesd1tx_p, jesd1tx_n,
//   output         jesd1frame_p, jesd1_frame_n,
//   input          jesd1sync_p, jesd1_sync_n,

   //Ethernet Common
   output         eth_gtrefclk_bufg,
   output         gmii_clk,
   //Eth0 GMII
   input          eth0gmii_tx_en,
   input          eth0gmii_tx_er,
   input [7:0]    eth0gmii_txd,
   output         eth0gmii_isolate,
   output         eth0gmii_rx_dv,
   output         eth0gmii_rx_er,
   output [7:0]   eth0gmii_rxd,
   //Eth0 MDIO
   input          eth0mdc,
   input          eth0mdio_i,
   output         eth0mdio_o,
   //Eth0 Misc
   output [15:0]  eth0status_vector,
   input          eth0signal_detect,
   output         eth0resetdone,
   //Eth1 GMII
   input          eth1gmii_tx_en,
   input          eth1gmii_tx_er, 
   input [7:0]    eth1gmii_txd,
   output         eth1gmii_isolate,
   output         eth1gmii_rx_dv,
   output         eth1gmii_rx_er, 
   output [7:0]   eth1gmii_rxd,
   //Eth1 MDIO
   input          eth1mdc,
   input          eth1mdio_i,
   output         eth1mdio_o, 
   //Eth1 Misc
   input          eth1signal_detect,
   output [15:0]  eth1status_vector,
   output         eth1resetdone
);
   //----------------------------------------------------------
   // Synchronize areset (from example design)

   wire eth_pma_reset;
   gige_phy_resets eth_pma_reset_t (.reset(areset), .independent_clock_bufg(independent_clock), .pma_reset(eth_pma_reset));

   //----------------------------------------------------------
   // Reference clocks for Ethernet

   wire eth0_txoutclk, eth1_txoutclk;
   wire eth_gtrefclk, eth_mmcm_refclk;
   wire eth_mmcm_locked;
   wire eth_userclk, eth_userclk2;
   
   assign gmii_clk = eth_userclk2;

   //Reference clock for Ethernet is connected to CLK0 of the GT Quad
   IBUFDS_GTE2 refbuf0(.CEB(1'b0), .I(gtrefclk0_p), .IB(gtrefclk0_n), .O(eth_gtrefclk), .ODIV2());
   BUFG erb(.I(eth_gtrefclk), .O(eth_gtrefclk_bufg));

   generate if (ETH_CLK_MASTER_PORT == 0) begin
     BUFG eth_mmcm_refclk_buf (.I(eth0_txoutclk), .O(eth_mmcm_refclk));
   end else begin
     BUFG eth_mmcm_refclk_buf (.I(eth1_txoutclk), .O(eth_mmcm_refclk));
   end endgenerate

   wire gt_pll0reset, gt_pll0lock, gt_pll0refclklost;
   wire gt_pll0outclk, gt_pll0outrefclk;
   wire eth0_gt_pll0reset, eth1_gt_pll0reset;

   //----------------------------------------------------------
   // Instantiate Ethernet PHY0

   gige_phy gig_phy_i0 (
      // Transceiver Interface
      .gtrefclk(eth_gtrefclk),            // 125MHz reference clock for GT transceiver.
      .gtrefclk_bufg(eth_gtrefclk_bufg),  // 125MHz reference clock for GT transceiver. (Global buffer)
      .txp(sfp0tx_p),                     // Differential +ve of serial transmission from PMA to PMD.
      .txn(sfp0tx_n),                     // Differential -ve of serial transmission from PMA to PMD.
      .rxp(sfp0rx_p),                     // Differential +ve for serial reception from PMD to PMA.
      .rxn(sfp0rx_n),                     // Differential -ve for serial reception from PMD to PMA.
      .txoutclk(eth0_txoutclk),           // 62.5 MHz from GT transciever to feed back to MMCM
      .rxoutclk(),                        // redundant, not used
      .resetdone(eth0resetdone),
      .cplllock(),                        // indicates reset done from transceiver, apparently NC
      .userclk(eth_userclk),              // 62.5 MHz global clock
      .userclk2(eth_userclk2),            // 125 MHz global clock
      .rxuserclk(eth_userclk),            // 62.5 MHz global clock
      .rxuserclk2(eth_userclk),           // 62.5 MHz global clock
      .independent_clock_bufg(independent_clock),
      .pma_reset(eth_pma_reset),              // reset syncd to system clock
      .mmcm_locked(eth_mmcm_locked),
      .gmii_txd(eth0gmii_txd),
      .gmii_tx_en(eth0gmii_tx_en),
      .gmii_tx_er(eth0gmii_tx_er),
      .gmii_rxd(eth0gmii_rxd),
      .gmii_rx_dv(eth0gmii_rx_dv),
      .gmii_rx_er(eth0gmii_rx_er),
      .gmii_isolate(eth0gmii_isolate),
      .mdc(eth0mdc),
      .mdio_i(eth0mdio_i),
      .mdio_o(eth0mdio_o),
      .mdio_t(1'b0),
      .configuration_vector(4'b0),
      .configuration_valid(1'b1),
      .status_vector(eth0status_vector),  // Core status.
      .reset(areset),                     // Asynchronous reset for entire core.
      .signal_detect(eth0signal_detect) , // Input from PMD to indicate presence of optical input.

      // connections with the GTPE2_COMMON:
      .gt0_pll0outclk_in(gt_pll0outclk),
      .gt0_pll0outrefclk_in(gt_pll0outrefclk),
      .gt0_pll0lock_in(gt_pll0lock),
      .gt0_pll0reset_out(eth0_gt_pll0reset),
      .gt0_pll0refclklost_in(gt_pll0refclklost),
      .gt0_pll1outclk_in(gt_pll1outclk),           // should be unused
      .gt0_pll1outrefclk_in(gt_pll1outrefclk)      // should be unused
   );

   //----------------------------------------------------------
   // Instantiate Ethernet PHY1

   gige_phy gig_phy_i1 (
      // Transceiver Interface
      .gtrefclk(eth_gtrefclk),            // 125MHz reference clock for GT transceiver.
      .gtrefclk_bufg(eth_gtrefclk_bufg),  // 125MHz reference clock for GT transceiver. (Global buffer)
      .txp(sfp1tx_p),                     // Differential +ve of serial transmission from PMA to PMD.
      .txn(sfp1tx_n),                     // Differential -ve of serial transmission from PMA to PMD.
      .rxp(sfp1rx_p),                     // Differential +ve for serial reception from PMD to PMA.
      .rxn(sfp1rx_n),                     // Differential -ve for serial reception from PMD to PMA.
      .txoutclk(eth1_txoutclk),           // 62.5 MHz from GT transciever to feed back to MMCM
      .rxoutclk(),                        // redundant, not used
      .resetdone(eth1resetdone),
      .cplllock(),                        // indicates reset done from transceiver, apparently NC
      .userclk(eth_userclk),              // 62.5 MHz global clock
      .userclk2(eth_userclk2),            // 125 MHz global clock
      .rxuserclk(eth_userclk),            // 62.5 MHz global clock
      .rxuserclk2(eth_userclk),           // 62.5 MHz global clock
      .independent_clock_bufg(independent_clock),
      .pma_reset(eth_pma_reset),              // reset syncd to system clock
      .mmcm_locked(eth_mmcm_locked),
      .gmii_txd(eth1gmii_txd),
      .gmii_tx_en(eth1gmii_tx_en),
      .gmii_tx_er(eth1gmii_tx_er),
      .gmii_rxd(eth1gmii_rxd),
      .gmii_rx_dv(eth1gmii_rx_dv),
      .gmii_rx_er(eth1gmii_rx_er),
      .gmii_isolate(eth1gmii_isolate),
      .mdc(eth1mdc),
      .mdio_i(eth1mdio_i),
      .mdio_o(eth1mdio_o),
      .mdio_t(1'b0),
      .configuration_vector(4'b0),
      .configuration_valid(1'b1),
      .status_vector(eth1status_vector),  // Core status.
      .reset(areset),                     // Asynchronous reset for entire core.
      .signal_detect(eth1signal_detect) , // Input from PMD to indicate presence of optical input.
      
      // connections with the GTPE2_COMMON:
      .gt0_pll0outclk_in(gt_pll0outclk),
      .gt0_pll0outrefclk_in(gt_pll0outrefclk),
      .gt0_pll0lock_in(gt_pll0lock),
      .gt0_pll0reset_out(eth1_gt_pll0reset),
      .gt0_pll0refclklost_in(gt_pll0refclklost),
      .gt0_pll1outclk_in(gt_pll1outclk), // should be unused
      .gt0_pll1outrefclk_in(gt_pll1outrefclk)  // should be unused
   );

   //----------------------------------------------------------
   // The GT transceiver provides a 62.5MHz clock to the FPGA fabric.  This is 
   // routed to an MMCM module where it is used to create phase and frequency
   // related 62.5MHz and 125MHz clock sources

   wire eth_mmcm_fbclk, eth_mmcm_clkout0, eth_mmcm_clkout1;

   MMCME2_ADV # (
      .BANDWIDTH            ("OPTIMIZED"),
      .CLKOUT4_CASCADE      ("FALSE"),
      .COMPENSATION         ("ZHOLD"),
      .STARTUP_WAIT         ("FALSE"),
      .DIVCLK_DIVIDE        (1),
      .CLKFBOUT_PHASE       (0.000),
      .CLKFBOUT_USE_FINE_PS ("FALSE"),
      .CLKOUT0_PHASE        (0.000),
      .CLKOUT0_DUTY_CYCLE   (0.5),
      .CLKOUT0_USE_FINE_PS  ("FALSE"),
      .CLKOUT1_PHASE        (0.000),
      .CLKOUT1_DUTY_CYCLE   (0.5),
      .CLKOUT1_USE_FINE_PS  ("FALSE"),
      .CLKIN1_PERIOD        (16.0),
      .CLKFBOUT_MULT_F      (16.000),
      .CLKOUT0_DIVIDE_F     (8.000),
      .CLKOUT1_DIVIDE       (16),
      .REF_JITTER1          (0.010)
   ) eth_mmcm_adv_inst (
      // Output clocks
      .CLKFBOUT             (eth_mmcm_fbclk),
      .CLKFBOUTB            (),
      .CLKOUT0              (eth_mmcm_clkout0),
      .CLKOUT0B             (),
      .CLKOUT1              (eth_mmcm_clkout1),
      .CLKOUT1B             (),
      .CLKOUT2              (),
      .CLKOUT2B             (),
      .CLKOUT3              (),
      .CLKOUT3B             (),
      .CLKOUT4              (),
      .CLKOUT5              (),
      .CLKOUT6              (),
      // Input clock control
      .CLKFBIN              (eth_mmcm_fbclk),
      .CLKIN1               (eth_mmcm_refclk),
      .CLKIN2               (1'b0),
      // Tied to always select the primary input clock
      .CLKINSEL             (1'b1),
      // Ports for dynamic reconfiguration
      .DADDR                (7'h0),
      .DCLK                 (1'b0),
      .DEN                  (1'b0),
      .DI                   (16'h0),
      .DO                   (),
      .DRDY                 (),
      .DWE                  (1'b0),
      // Ports for dynamic phase shift
      .PSCLK                (1'b0),
      .PSEN                 (1'b0),
      .PSINCDEC             (1'b0),
      .PSDONE               (),
      // Other control and status signals
      .LOCKED               (eth_mmcm_locked),
      .CLKINSTOPPED         (),
      .CLKFBSTOPPED         (),
      .PWRDWN               (1'b0),
      .RST                  (areset)
   );

   BUFG clk0bufg(.I(eth_mmcm_clkout0), .O(eth_userclk2));
   BUFG clk1bufg(.I(eth_mmcm_clkout1), .O(eth_userclk));

   //----------------------------------------------------------
   // Reset sequence from example design.
   // Addresses AR43482 and some other issues
   wire eth_gtpll0_reset, gt_pll0reset_in;
   gige_phy_common_reset #( .STABLE_CLOCK_PERIOD(5)) core_gt_common_reset_i (
      .STABLE_CLOCK               (independent_clock),
      .SOFT_RESET                 (eth_pma_reset),
      .COMMON_RESET               (eth_gtpll0_reset)
   );
   
   assign gt_pll0reset_in = eth_gtpll0_reset || eth0_gt_pll0reset || eth1_gt_pll0reset;

   //----------------------------------------------------------
   // Instantiate a GTPE2_COMMON block
   // (adapted from gige_phy_gt_common.v)

   (* equivalent_register_removal="no" *) reg [95:0]  cpll0_pd_wait    =  96'hFFFFFFFFFFFFFFFFFFFFFFFF;
   (* equivalent_register_removal="no" *) reg [127:0] cpll0_reset_wait = 128'h000000000000000000000000000000FF;
   always @(posedge eth_gtrefclk_bufg)
   begin
      cpll0_pd_wait    <= {cpll0_pd_wait[94:0], 1'b0};
      cpll0_reset_wait <= {cpll0_reset_wait[126:0], 1'b0};
   end

   wire cpll0_pd_i    = cpll0_pd_wait[95];
   wire cpll0_reset_i = cpll0_reset_wait[127];

   localparam PLL0_FBDIV_IN      = 4;
   localparam PLL1_FBDIV_IN      = 1;
   localparam PLL0_FBDIV_45_IN   = 5;
   localparam PLL1_FBDIV_45_IN   = 4;
   localparam PLL0_REFCLK_DIV_IN = 1;
   localparam PLL1_REFCLK_DIV_IN = 1;

   GTPE2_COMMON #
   (
      // Simulation attributes
      .SIM_RESET_SPEEDUP   (SIM_SPEEDUP),
      .SIM_PLL0REFCLK_SEL  (3'b001),
      .SIM_PLL1REFCLK_SEL  (3'b010),
      .SIM_VERSION         ("2.0"),
      // Common block attributes
      .BIAS_CFG            (64'h0000000000050001),
      .COMMON_CFG          (32'h00000000),
      // PLL Attributes
      .PLL0_CFG            (27'h01F03DC),
      .PLL0_DMON_CFG       (1'b0),
      .PLL0_INIT_CFG       (24'h00001E),
      .PLL0_LOCK_CFG       (9'h1E8),
      .PLL0_FBDIV          (PLL0_FBDIV_IN),   
      .PLL0_FBDIV_45       (PLL0_FBDIV_45_IN),  
      .PLL0_REFCLK_DIV     (PLL0_REFCLK_DIV_IN),  
      .PLL1_CFG            (27'h01F03DC),
      .PLL1_DMON_CFG       (1'b0),
      .PLL1_INIT_CFG       (24'h00001E),
      .PLL1_LOCK_CFG       (9'h1E8),
      .PLL1_FBDIV          (PLL1_FBDIV_IN),  
      .PLL1_FBDIV_45       (PLL1_FBDIV_45_IN),  
      .PLL1_REFCLK_DIV     (PLL1_REFCLK_DIV_IN),          
      .PLL_CLKOUT_CFG      (8'h00),
      //--------------------------Reserved Attributes----------------------------
      .RSVD_ATTR0          (16'h0000),
      .RSVD_ATTR1          (16'h0000)
   ) gtpe2_common_i (
      .DMONITOROUT         (),  
      //----------- Common Block  - Dynamic Reconfiguration Port (DRP) -----------
      .DRPADDR             (8'h00),
      .DRPCLK              (1'b0),
      .DRPDI               (16'h0000),
      .DRPDO               (),
      .DRPEN               (1'b0),
      .DRPRDY              (),
      .DRPWE               (1'b0),
      //--------------- Common Block - GTPE2_COMMON Clocking Ports ---------------
      .GTEASTREFCLK0       (1'b0),
      .GTEASTREFCLK1       (1'b0),
      .GTGREFCLK1          (1'b0),
      .GTREFCLK0           (eth_gtrefclk),
      .GTREFCLK1           (1'b0),
      .GTWESTREFCLK0       (1'b0),
      .GTWESTREFCLK1       (1'b0),
      .PLL0OUTCLK          (gt_pll0outclk),
      .PLL0OUTREFCLK       (gt_pll0outrefclk),
      .PLL1OUTCLK          (),
      .PLL1OUTREFCLK       (),
      //------------------------ Common Block - PLL Ports ------------------------
      .PLL0FBCLKLOST       (),
      .PLL0LOCK            (gt_pll0lock),
      .PLL0LOCKDETCLK      (independent_clock),
      .PLL0LOCKEN          (1'b1),
      .PLL0PD              (cpll0_pd_i),
      .PLL0REFCLKLOST      (gt_pll0refclklost),
      .PLL0REFCLKSEL       (3'b001),
      .PLL0RESET           (gt_pll0reset_in || cpll0_reset_i),
      .PLL1FBCLKLOST       (),
      .PLL1LOCK            (),
      .PLL1LOCKDETCLK      (1'b0),
      .PLL1LOCKEN          (1'b1),
      .PLL1PD              (1'b1),
      .PLL1REFCLKLOST      (),
      .PLL1REFCLKSEL       (3'b001),
      .PLL1RESET           (1'b0),
      //-------------------------- Common Block - Ports --------------------------
      .BGRCALOVRDENB       (1'b1),
      .GTGREFCLK0          (1'b0),
      .PLLRSVD1            (16'b0000000000000000),
      .PLLRSVD2            (5'b00000),
      .REFCLKOUTMONITOR0   (),
      .REFCLKOUTMONITOR1   (),
      //---------------------- Common Block - RX AFE Ports -----------------------
      .PMARSVDOUT          (),
      //------------------------------- QPLL Ports -------------------------------
      .BGBYPASSB           (1'b1),
      .BGMONITORENB        (1'b1),
      .BGPDB               (1'b1),
      .BGRCALOVRD          (5'b11111),
      .PMARSVD             (8'b00000000),
      .RCALENB             (1'b1)
   );


endmodule