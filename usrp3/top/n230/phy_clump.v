// Copyright 2014, Ettus Research
//
// This module bundles the PHY and clocking interfaces that utilize the GTP
// transcievers. This is convenient only because in the X7A100 Artix, there 
// is only one quad available, and all the PHYs need to share the two PLLs, so
// rather than manage a ratsnest of connections between the PHY IP, MMCMs, 
// and GTPE2_COMMON, those connections are contained here.
// 

module phy_clump(
reset,
gtrefclk0_p, gtrefclk0_n, 
gtrefclk1_p, gtrefclk1_n,
eth0rx_p, eth0rx_n,
eth0tx_p, eth0tx_n,
eth1rx_p, eth1rx_n,
eth1tx_p, eth1tx_n,
ethrefclk,
jesd1tx_p, jesd1tx_n,
jesd1frame_p, jesd1_frame_n,
jesd1sync_p, jesd1_sync_n,
jesd2tx_p, jesd2tx_n,
jesd2frame_p, jesd2_frame_n,
jesd2sync_p, jesd2_sync_n,
gmii_clk,
bus_clk,
radio_clk,
catclk_92_16,
eth0gmii_tx_en, eth0gmii_tx_er, eth0gmii_txd,
eth0gmii_rx_dv, eth0gmii_rx_er, eth0gmii_rxd,
eth0mdc, eth0mdio_i, eth0mdio_o, eth0status_vector,
eth0signal_detect,
eth1gmii_tx_en, eth1gmii_tx_er, eth1gmii_txd,
eth1gmii_rx_dv, eth1gmii_rx_er, eth1gmii_rxd,
eth1mdc, eth1mdio_i, eth1mdio_o, eth1status_vector,
eth1signal_detect,
   dbg_lck_0  // TODO: remove
// TODO: add remaminder of jesd signals
);

  input reset;
  input gtrefclk0_p, gtrefclk0_n, gtrefclk1_p, gtrefclk1_n;
  input eth0rx_p, eth0rx_n;
  output eth0tx_p, eth0tx_n;
  input eth1rx_p, eth1rx_n;
  output eth1tx_p, eth1tx_n;
  output jesd1tx_p, jesd1tx_n;
  output jesd1frame_p, jesd1_frame_n;
  input jesd1sync_p, jesd1_sync_n;
  output jesd2tx_p, jesd2tx_n;
  output jesd2frame_p, jesd2_frame_n;
  input jesd2sync_p, jesd2_sync_n;
  output gmii_clk;
  input bus_clk, radio_clk;
  input catclk_92_16;      // input clk_in1
  input eth0gmii_tx_en, eth1gmii_tx_en; 
  input eth0gmii_tx_er, eth1gmii_tx_er; 
  input [7:0] eth0gmii_txd, eth1gmii_txd;
//  output eth0gmii_isolate, eth1gmii_isolate; 
  wire eth0gmii_isolate, eth1gmii_isolate; 
  output eth0gmii_rx_dv, eth1gmii_rx_dv; 
  output eth0gmii_rx_er, eth1gmii_rx_er; 
  output [7:0] eth0gmii_rxd, eth1gmii_rxd;
  input eth0mdc, eth1mdc; 
  input eth0mdio_i, eth1mdio_i; 
  output eth0mdio_o, eth1mdio_o; 
  wire eth0mdio_t, eth1mdio_t; 
  output [15:0] eth0status_vector, eth1status_vector;
  input eth0signal_detect, eth1signal_detect;
  output ethrefclk;
  output dbg_lck_0;

  // placeholders:
   wire  jesdrefclk;
  OBUFDS frbuf1(.I(jesdrefclk), .O(jesd1frame_p), .OB(jesd1_frame_n));
  OBUFDS frbuf2(.I(jesdrefclk), .O(jesd2frame_p), .OB(jesd2_frame_n));

  // use PLL0 with the 125 MHz reference for eth0 and eth1
  wire lethrefclk;
  IBUFDS_GTE2 refbuf0(.CEB(1'b0), .I(gtrefclk0_p), .IB(gtrefclk0_n), .O(lethrefclk), .ODIV2());
  BUFG erb(.I(lethrefclk), .O(ethrefclk));

  // use PLL1 with the JESD reference clock -- for now assume it is sourced from
  // the external pins. This may need revisiting.
  IBUFDS_GTE2 refbuf1(.CEB(1'b0), .I(gtrefclk1_p), .IB(gtrefclk1_n), .O(jesdrefclk), .ODIV2());

  wire eth0outclk, eth0gclk;
  BUFG eth0outclkbuf(.I(eth0outclk), .O(eth0gclk));
  wire ethXclk_125, ethXclk_62_5; // TODO: check sharing with eth1 works!!!
  wire ethXmmcm_locked;

  // PHY connections with the GTPE2_COMMON PLL
  wire gt_pll0reset, gt_pll1reset;
  wire gt_pll0outclk, gt_pll0outrefclk;
  wire gt_pll1outclk, gt_pll1outrefclk; 
  wire gt_pll0refclklost, gt_pll1refclklost;
  wire gt_pll0lock, gt_pll1lock;

  wire eth0gt_pll0reset; 
  wire eth1gt_pll0reset; 
  // TODO: check these can OR-togehter
  assign gt_pll0reset = eth0gt_pll0reset | eth1gt_pll0reset; 

  wire eth0resetdone;

  wire pma_reset;
  reg [2:0] rd;

  always @(posedge bus_clk or posedge reset) begin
    if (reset) rd <= 3'b111;
    else rd <= { rd[1:0], 1'b0 };
  end
  assign pma_reset = rd[2];

  // ethernet PHY for sfp0
  gige_sfp0 gigephy0 (
    // Transceiver Interface
    .gtrefclk(lethrefclk), // 125MHz reference clock for GT transceiver.
    .txp(eth0tx_p), // Differential +ve of serial transmission from PMA to PMD.
    .txn(eth0tx_n), // Differential -ve of serial transmission from PMA to PMD.
    .rxp(eth0rx_p), // Differential +ve for serial reception from PMD to PMA.
    .rxn(eth0rx_n), // Differential -ve for serial reception from PMD to PMA.
    .txoutclk(eth0outclk), 
    // ^^^^  62.5 MHz from GT transciever to feed back to MMCM
    .rxoutclk(), // redundant, not used
    .resetdone(eth0resetdone),
    .cplllock(), // indicates reset done from transcever, apparently NC
    .userclk(ethXclk_62_5), // 62.5 MHz global clock
    .userclk2(ethXclk_125), // 125 MHz global clock
    .rxuserclk(ethXclk_62_5), // 62.5 MHz global clock
    .rxuserclk2(ethXclk_62_5), // 62.5 MHz global clock
    .independent_clock_bufg(bus_clk), // TODO: revisit
    .pma_reset(pma_reset), // reset syncd to system clock
    .mmcm_locked(ethXmmcm_locked),
    .gmii_txd(eth0gmii_txd),
    .gmii_tx_en(eth0gmii_tx_en),
    .gmii_tx_er(eth0gmii_tx_er),
    .gmii_rxd(eth0gmii_rxd),
    .gmii_rx_dv(eth0gmii_rx_dv),
    .gmii_rx_er(eth0gmii_rx_er),
    .gmii_isolate(eth0gmii_isolate),
    // Management: MDIO Interface
  //---------------------------
    .mdc(eth0mdc),
    .mdio_i(eth0mdio_i),
    .mdio_o(eth0mdio_o),
    .mdio_t(eth0mdio_t),
    .configuration_vector(4'b0),
    .configuration_valid(1'b1),
    // General IO's
    //-------------
    .status_vector(eth0status_vector), // Core status.
    .reset(reset), // Asynchronous reset for entire core.
    .signal_detect(eth0signal_detect) , // Input from PMD to indicate presence of optical input.

    // connections with the GTPE2_COMMON:
    .gt0_pll0outclk_in(gt_pll0outclk),
    .gt0_pll0outrefclk_in(gt_pll0outrefclk),
    .gt0_pll1outclk_in(gt_pll1outclk), // should be unused
    .gt0_pll1outrefclk_in(gt_pll1outrefclk), // should be unused
    .gt0_pll0refclklost_in(gt_pll0refclklost),
    .gt0_pll0lock_in(gt_pll0lock),
    .gt0_pll0reset_out(eth0gt_pll0reset)
  );

  wire eth1resetdone;

  // ethernet PHY for sfp1 (reuse same core)
  gige_sfp0 gigephy1 (
    // Transceiver Interface
    .gtrefclk(lethrefclk), // 125MHz reference clock for GT transceiver.
    .txp(eth1tx_p), // Differential +ve of serial transmission from PMA to PMD.
    .txn(eth1tx_n), // Differential -ve of serial transmission from PMA to PMD.
    .rxp(eth1rx_p), // Differential +ve for serial reception from PMD to PMA.
    .rxn(eth1rx_n), // Differential -ve for serial reception from PMD to PMA.
    .txoutclk(), // TODO: check ok to share with eth0
    // ^^^^  62.5 MHz from GT transciever to feed back to MMCM
    .rxoutclk(), // redundant, not used
    .resetdone(eth1resetdone),
    .cplllock(), // indicates reset done from transcever, apparently NC
    .userclk(ethXclk_62_5), // 62.5 MHz global clock
    .userclk2(ethXclk_125), // 125 MHz global clock
    .rxuserclk(ethXclk_62_5), // 62.5 MHz global clock
    .rxuserclk2(ethXclk_62_5), // 62.5 MHz global clock
    .independent_clock_bufg(bus_clk), // TODO: revisit
    .pma_reset(pma_reset), // reset syncd to system clock
    .mmcm_locked(ethXmmcm_locked),
    .gmii_txd(eth1gmii_txd),
    .gmii_tx_en(eth1gmii_tx_en),
    .gmii_tx_er(eth1gmii_tx_er),
    .gmii_rxd(eth1gmii_rxd),
    .gmii_rx_dv(eth1gmii_rx_dv),
    .gmii_rx_er(eth1gmii_rx_er),
    .gmii_isolate(eth1gmii_isolate),
    // Management: MDIO Interface
    .mdc(eth1mdc),
    .mdio_i(eth1mdio_i),
    .mdio_o(eth1mdio_o),
    .mdio_t(eth1mdio_t),
    .configuration_vector(4'b0),
    .configuration_valid(1'b1),
    // General IO's
    .status_vector(eth1status_vector), // Core status.
    .reset(reset), // Asynchronous reset for entire core.
    .signal_detect(eth1signal_detect) , // Input from PMD to indicate presence of optical input.

    // connections with the GTPE2_COMMON:
    .gt0_pll0outclk_in(gt_pll0outclk),
    .gt0_pll0outrefclk_in(gt_pll0outrefclk),
    .gt0_pll1outclk_in(gt_pll1outclk), // should be unused
    .gt0_pll1outrefclk_in(gt_pll1outrefclk), // should be unused
    .gt0_pll0refclklost_in(gt_pll0refclklost),
    .gt0_pll0lock_in(gt_pll0lock),
    .gt0_pll0reset_out(eth1gt_pll0reset)
  );

  // MMCM for eth0, and attempting to share with eth1 
  // takes 62.5 MHz from GT transceiver and produces phase aligned 62.5 & 125 Mhz outputs
    wire clkfbout;
    wire  clkout0, clkout1;

    MMCME2_ADV # (
      .BANDWIDTH("OPTIMIZED"),
      .CLKOUT4_CASCADE("FALSE"),
      .COMPENSATION("ZHOLD"),
      .STARTUP_WAIT("FALSE"),
      .DIVCLK_DIVIDE(1),
      .CLKFBOUT_MULT_F(16.000),
      .CLKFBOUT_PHASE(0.000),
      .CLKFBOUT_USE_FINE_PS("FALSE"),
      .CLKOUT0_DIVIDE_F(8.000),
      .CLKOUT0_PHASE(0.000),
      .CLKOUT0_DUTY_CYCLE(0.5),
      .CLKOUT0_USE_FINE_PS("FALSE"),
      .CLKOUT1_DIVIDE(16),
      .CLKOUT1_PHASE(0.000),
      .CLKOUT1_DUTY_CYCLE(0.5),
      .CLKOUT1_USE_FINE_PS("FALSE"),
      .CLKIN1_PERIOD(16.0),
      .REF_JITTER1(0.010)
    ) mmcm_ethXphy (
      // Output clocks
      .CLKFBOUT(clkfbout), .CLKFBOUTB(),
      .CLKOUT0(clkout0), .CLKOUT0B(),
      .CLKOUT1(clkout1), .CLKOUT1B(),
      .CLKOUT2(), .CLKOUT2B(),
      .CLKOUT3(), .CLKOUT3B(),
      .CLKOUT4(), .CLKOUT5(), .CLKOUT6(),
      // Input clock control
      .CLKFBIN(clkfbout),
      .CLKIN1(eth0gclk), // fed back from phy0 through a bufg
      .CLKIN2(1'b0),
      // Tied to always select the primary input clock
      .CLKINSEL(1'b1),
      // Ports for dynamic reconfiguration
      .DADDR(7'h0), .DCLK(1'b0), .DEN(1'b0), 
      .DI(16'h0), .DO(), .DRDY(), .DWE(1'b0),
      // Ports for dynamic phase shift
      .PSCLK(1'b0), .PSEN(1'b0), .PSINCDEC(1'b0), .PSDONE(),
      // Other control and status signals
      .LOCKED(ethXmmcm_locked),
      .CLKINSTOPPED(), .CLKFBSTOPPED(), .PWRDWN(1'b0),
      .RST(mmcm_reset)
      );

    BUFG clk0bufg(.I(clkout0), .O(ethXclk_125));
    BUFG clk1bufg(.I(clkout1), .O(ethXclk_62_5));

   assign gmii_clk=ethXclk_125;
// adapted from example file gige_sfp0_gt_common.v
   // ground and vcc signals
   wire            tied_to_ground_i;
   wire    [63:0]  tied_to_ground_vec_i;
   wire            tied_to_vcc_i;
   wire    [63:0]  tied_to_vcc_vec_i;
   
  localparam PLL0_FBDIV_IN      = 4;
  localparam PLL1_FBDIV_IN      = 1;
  localparam PLL0_FBDIV_45_IN   = 5;
  localparam PLL1_FBDIV_45_IN   = 4;
  localparam PLL0_REFCLK_DIV_IN = 1;
  localparam PLL1_REFCLK_DIV_IN = 1;
  localparam   WRAPPER_SIM_GTRESET_SPEEDUP    =   "FALSE";        


  assign tied_to_ground_i             = 1'b0;
  assign tied_to_ground_vec_i         = 64'h0000000000000000;
  assign tied_to_vcc_i                = 1'b1;
  assign tied_to_vcc_vec_i            = 64'hffffffffffffffff;



  GTPE2_COMMON # (
  // Simulation attributes
  .SIM_RESET_SPEEDUP   (WRAPPER_SIM_GTRESET_SPEEDUP),
  .SIM_PLL0REFCLK_SEL  (3'b001), // 125 MHz for ethernet
  .SIM_PLL1REFCLK_SEL  (3'b010), // JESD referencce
  .SIM_VERSION         ( "2.0"),
  .PLL0_FBDIV          (PLL0_FBDIV_IN     ),
  .PLL0_FBDIV_45       (PLL0_FBDIV_45_IN  ),
  .PLL0_REFCLK_DIV     (PLL0_REFCLK_DIV_IN),
  .PLL1_FBDIV          (PLL1_FBDIV_IN     ),
  .PLL1_FBDIV_45       (PLL1_FBDIV_45_IN  ),
  .PLL1_REFCLK_DIV     (PLL1_REFCLK_DIV_IN),
  //----------------COMMON BLOCK Attributes---------------
  .BIAS_CFG(64'h0000000000050001),
  .COMMON_CFG(32'h00000000),
  //--------------------------PLL Attributes----------------------------
  .PLL0_CFG(27'h01F03DC),
  .PLL0_DMON_CFG(1'b0),
  .PLL0_INIT_CFG(24'h00001E),
  .PLL0_LOCK_CFG(9'h1E8),
  .PLL1_CFG(27'h01F03DC),
  .PLL1_DMON_CFG(1'b0),
  .PLL1_INIT_CFG(24'h00001E),
  .PLL1_LOCK_CFG(9'h1E8),
  .PLL_CLKOUT_CFG(8'h00),
  //--------------------------Reserved Attributes----------------------------
  .RSVD_ATTR0(16'h0000),
  .RSVD_ATTR1(16'h0000)
  ) gtpe2_common_0_i (
  .DMONITOROUT(),    
  //----------- Common Block  - Dynamic Reconfiguration Port (DRP) -----------
  .DRPADDR(tied_to_ground_vec_i[7:0]),
  .DRPCLK(tied_to_ground_i),
  .DRPDI(tied_to_ground_vec_i[15:0]),
  .DRPDO(),
  .DRPEN(tied_to_ground_i),
  .DRPRDY(),
  .DRPWE(tied_to_ground_i),
  //--------------- Common Block - GTPE2_COMMON Clocking Ports ---------------
  .GTEASTREFCLK0(tied_to_ground_i),
  .GTEASTREFCLK1(tied_to_ground_i),
  .GTGREFCLK1(tied_to_ground_i),
  .GTREFCLK0(lethrefclk),
  .GTREFCLK1(jesdrefclk),
  .GTWESTREFCLK0(tied_to_ground_i),
  .GTWESTREFCLK1(tied_to_ground_i),
  .PLL0OUTCLK(gt_pll0outclk),
  .PLL0OUTREFCLK(gt_pll0outrefclk),
  .PLL1OUTCLK(gt_pll1outclk),
  .PLL1OUTREFCLK(gt_pll1outrefclk),
  //------------------------ Common Block - PLL Ports ------------------------
  .PLL0FBCLKLOST(),
  .PLL0LOCK(gt_pll0lock),
  .PLL0LOCKDETCLK(1'b0),
  .PLL0LOCKEN(tied_to_vcc_i), // enables lock detector
  .PLL0PD(tied_to_ground_i), // power down PLL when high for power saving
  .PLL0REFCLKLOST(gt_pll0refclklost),
  .PLL0REFCLKSEL(3'b001),
  .PLL0RESET(gt_pll0reset), // active high, resets dividers, lock indicator, and status blocks; asynchronous
  .PLL1FBCLKLOST(),
  .PLL1LOCK(gt_pll1lock),
  .PLL1LOCKDETCLK(1'b0),
  .PLL1LOCKEN(tied_to_vcc_i),
  .PLL1PD(tied_to_ground_i),
  .PLL1REFCLKLOST(gt_pll1refclklost),
  .PLL1REFCLKSEL(3'b010),
  .PLL1RESET(gt_pll1reset),
  //-------------------------- Common Block - Ports --------------------------
  .BGRCALOVRDENB(tied_to_vcc_i),
  .GTGREFCLK0(tied_to_ground_i),
  .PLLRSVD1(16'b0000000000000000),
  .PLLRSVD2(5'b00000),
  .REFCLKOUTMONITOR0(),
  .REFCLKOUTMONITOR1(),
  //---------------------- Common Block - RX AFE Ports -----------------------
  .PMARSVDOUT(),
  //------------------------------- QPLL Ports -------------------------------
  .BGBYPASSB(tied_to_vcc_i),
  .BGMONITORENB(tied_to_vcc_i),
  .BGPDB(tied_to_vcc_i),
  .BGRCALOVRD(5'b00000),
  .PMARSVD(8'b00000000),
  .RCALENB(tied_to_vcc_i)
  );
  assign dbg_lck_0=gt_pll0lock ; // TODO: remove DEBUG

  // TODO: add JESD PHY cores ...
 wire jesfb;
 wire clk_184_32;
 wire clk_92_16;
 wire clk_46_08;

      wire gt0_tx_mmcm_reset_out1, gt0_tx_mmcm_reset_out2;
      reg jesd_mmcm_reset;

     jesd_mmcm mmcm_jesd
     (
     // Clock in ports
      .clk_in1(catclk_92_16),      // input clk_in1
      .clkfb_in(jesfb),     // input clkfb_in
      // Clock out ports
      .clk_184_32(clk_184_32),     // output clk_184_32
      .clk_92_16(clk_92_16),     // output clk_92_16 HACK TODO: these need to be cut in half (46.08) -- see gt wizard
      .clk_46_08(clk_46_08),     // output clk_368_64
      .clkfb_out(jesfb),    // output clkfb_out
      // Status and control signals
      .reset(jesd_mmcm_reset),// input reset
      .locked(jesdmmcmlocked));      // output locked

    always @(posedge catclk_92_16) begin // TODO: unsure how to treat this -- FIXME
      jesd_mmcm_reset <= gt0_tx_mmcm_reset_out1 | gt0_tx_mmcm_reset_out2;
    end

    wire sync1, sync2;
    IBUFGDS jesdsync1(.I(jesd1sync_p), .IB(jesd1_sync_n), .O(sync1));
    IBUFGDS jesdsync2(.I(jesd2sync_p), .IB(jesd2_sync_n), .O(sync2));

    wire [31:0] gt_txdata_out1, gt_txdata_out2;
    wire [3:0] gt_txcharisk_out1, gt_txcharisk_out2;
    wire [2:0] gt_prbssel1, gt_prbssel2;

// HACK data generators
    wire [31:0] tx_data1, s_axi_wdata;
    wire tx_tready1, tx_tready2;
    dirtgen dg0(.clk(tx_aclk), .ena(tx_tready1), .dout(tx_data1));
    dirtgen dg1(.clk(tx_aclk), .ena(s_axi_awvalid), .dout(s_axi_wdata));
    wire [31:0] tx_data2, s_axi_wdata2;
    dirtgen dg2(.clk(tx_aclk2), .ena(s_axi_awvalid), .dout(s_axi_wdata2));
    dirtgen dg3(.clk(tx_aclk2), .ena(tx_tready2), .dout(tx_data2));

        // Cut from INSTANTIATION Template 
    jesd204_0 jesd_1 (
      .gt_txdata_out(gt_txdata_out1),                    // output [31 : 0] gt_txdata_out
      .gt_txcharisk_out(gt_txcharisk_out1),              // output [3 : 0] gt_txcharisk_out
      .tx_reset_done(tx_reset_done),                    // input tx_reset_done
      .gt_prbssel_out(gt_prbssel1),                  // output [2 : 0] gt_prbssel_out
      .tx_core_clk(clk_46_08),                        // input tx_core_clk
      .s_axi_aclk(s_axi_aclk),                          // input s_axi_aclk
      .s_axi_aresetn(s_axi_aresetn),                    // input s_axi_aresetn
      .s_axi_awaddr(s_axi_awaddr),                      // input [11 : 0] s_axi_awaddr
      .s_axi_awvalid(s_axi_awvalid),                    // input s_axi_awvalid
      .s_axi_awready(s_axi_awready),                    // output s_axi_awready
      .s_axi_wdata(s_axi_wdata),                        // input [31 : 0] s_axi_wdata
      .s_axi_wstrb(s_axi_wstrb),                        // input [3 : 0] s_axi_wstrb
      .s_axi_wvalid(s_axi_wvalid),                      // input s_axi_wvalid
      .s_axi_wready(s_axi_wready),                      // output s_axi_wready
      .s_axi_bresp(s_axi_bresp),                        // output [1 : 0] s_axi_bresp
      .s_axi_bvalid(s_axi_bvalid),                      // output s_axi_bvalid
      .s_axi_bready(s_axi_bready),                      // input s_axi_bready
      .s_axi_araddr(s_axi_araddr),                      // input [11 : 0] s_axi_araddr
      .s_axi_arvalid(s_axi_arvalid),                    // input s_axi_arvalid
      .s_axi_arready(s_axi_arready),                    // output s_axi_arready
      .s_axi_rdata(s_axi_rdata),                        // output [31 : 0] s_axi_rdata
      .s_axi_rresp(s_axi_rresp),                        // output [1 : 0] s_axi_rresp
      .s_axi_rvalid(s_axi_rvalid),                      // output s_axi_rvalid
      .s_axi_rready(s_axi_rready),                      // input s_axi_rready
      .tx_reset(reset),                              // input tx_reset
      .tx_sysref(1'b0),                            // input tx_sysref jk-subclass1 only
      .tx_start_of_frame(tx_start_of_frame),            // output [3 : 0] tx_start_of_frame
      .tx_start_of_multiframe(tx_start_of_multiframe),  // output [3 : 0] tx_start_of_multiframe
      .tx_aclk(tx_aclk),                                // output tx_aclk
      .tx_aresetn(tx_aresetn),                          // output tx_aresetn
      .tx_tdata(tx_data1),                              // input [31 : 0] tx_tdata
      .tx_tready(tx_tready1),                            // output tx_tready
      .tx_sync(sync1)                                // input tx_sync
    );
    
    
        //----------- Begin Cut here for INSTANTIATION Template ---// INST_TAG
    jesd204_1 jesd_2 (
      .gt_txdata_out(gt_txdata_out2),                    // output [31 : 0] gt_txdata_out
      .gt_txcharisk_out(gt_txcharisk_out2),              // output [3 : 0] gt_txcharisk_out
      .tx_reset_done(tx_reset_done),                    // input tx_reset_done
      .gt_prbssel_out(gt_prbssel2),                  // output [2 : 0] gt_prbssel_out
      .tx_core_clk(clk_46_08),                        // input tx_core_clk
      .s_axi_aclk(s_axi_aclk),                          // input s_axi_aclk
      .s_axi_aresetn(s_axi_aresetn),                    // input s_axi_aresetn
      .s_axi_awaddr(s_axi_awaddr),                      // input [11 : 0] s_axi_awaddr
      .s_axi_awvalid(s_axi_awvalid),                    // input s_axi_awvalid
      .s_axi_awready(s_axi_awready2),                    // output s_axi_awready
      .s_axi_wdata(s_axi_wdata2),                        // input [31 : 0] s_axi_wdata
      .s_axi_wstrb(s_axi_wstrb),                        // input [3 : 0] s_axi_wstrb
      .s_axi_wvalid(s_axi_wvalid),                      // input s_axi_wvalid
      .s_axi_wready(s_axi_wready2),                      // output s_axi_wready
      .s_axi_bresp(s_axi_bresp2),                        // output [1 : 0] s_axi_bresp
      .s_axi_bvalid(s_axi_bvalid2),                      // output s_axi_bvalid
      .s_axi_bready(s_axi_bready),                      // input s_axi_bready
      .s_axi_araddr(s_axi_araddr),                      // input [11 : 0] s_axi_araddr
      .s_axi_arvalid(s_axi_arvalid),                    // input s_axi_arvalid
      .s_axi_arready(s_axi_arready2),                    // output s_axi_arready
      .s_axi_rdata(s_axi_rdata2),                       // output [31 : 0] s_axi_rdata
      .s_axi_rresp(s_axi_rresp2),                        // output [1 : 0] s_axi_rresp
      .s_axi_rvalid(s_axi_rvalid2),                      // output s_axi_rvalid
      .s_axi_rready(s_axi_rready),                      // input s_axi_rready
      .tx_reset(reset),                              // input tx_reset
      .tx_sysref(1'b0),                            // input tx_sysref jk-sublass 1 only
      .tx_start_of_frame(tx_start_of_frame2),            // output [3 : 0] tx_start_of_frame
      .tx_start_of_multiframe(tx_start_of_multiframe2),  // output [3 : 0] tx_start_of_multiframe
      .tx_aclk(tx_aclk2),                                // output tx_aclk
      .tx_aresetn(tx_aresetn2),                          // output tx_aresetn
      .tx_tdata(tx_data2),                              // input [31 : 0] tx_tdata
      .tx_tready(tx_tready2),                            // output tx_tready
      .tx_sync(sync2)                                // input tx_sync
    );
    // INST_TAG_END ------ End INSTANTIATION Template ---------
    
    // INST_TAG_END ------ End INSTANTIATION Template ---------
    
    
    
    wire pll1reset0, pll1reset1;
    
    
        // Use the templates in this file to add the components generated by the wizard to your
    // design. 
   
    jesd204_0_gtwizard_0  jesd204_0_gtwizard_0_i (
      .sysclk_in(fooclk),
      .soft_reset_in(soft_reset),
      .dont_reset_on_data_error_in(dont_reset_on_data_error_in),
      .gt0_tx_fsm_reset_done_out(gt0_tx_fsm_reset_done_out),
      .gt0_rx_fsm_reset_done_out(gt0_rx_fsm_reset_done_out),
      .gt0_data_valid_in(gt0_data_valid_in),
      .gt0_tx_mmcm_lock_in(jesdmmcmlocked),
      .gt0_tx_mmcm_reset_out(gt0_tx_mmcm_reset_out1),
    
        //_________________________________________________________________________
        //GT0  (X0Y3)
        //____________________________CHANNEL PORTS________________________________
        //-------------------------- Channel - DRP Ports  --------------------------
      .gt0_drpaddr_in                 (gt0_drpaddr_in),
      .gt0_drpclk_in                  (clk_92_16),
      .gt0_drpdi_in                   (gt0_drpdi_in),
      .gt0_drpdo_out                  (gt0_drpdo_out),
      .gt0_drpen_in                   (gt0_drpen_in),
      .gt0_drprdy_out                 (gt0_drprdy_out),
      .gt0_drpwe_in                   (gt0_drpwe_in),
        //----------------------------- Loopback Ports -----------------------------
      .gt0_loopback_in                (gt0_loopback_in),
        //---------------------------- Power-Down Ports ----------------------------
      .gt0_rxpd_in                    (2'b11),
      .gt0_txpd_in                    (2'b00),
       //------------------- RX Initialization and Reset Ports --------------------
      .gt0_eyescanreset_in            (1'b1),
        //------------------------ RX Margin Analysis Ports ------------------------
      .gt0_eyescandataerror_out       (),
      .gt0_eyescantrigger_in          (1'b0),
        //----------------- Receive Ports - Pattern Checker Ports ------------------
      .gt0_rxprbserr_out              (),
      .gt0_rxprbssel_in               (gt_prbssel1),
        //----------------- Receive Ports - Pattern Checker ports ------------------
      .gt0_rxprbscntreset_in          (1'b1),
        //----------------- Receive Ports - RX Buffer Bypass Ports -----------------
      .gt0_rxbufreset_in              (1'b1),
      .gt0_rxbufstatus_out            (),
        //----------- Receive Ports - RX Initialization and Reset Ports ------------
      .gt0_gtrxreset_in               (1'b1),
        //---------------------- TX Configurable Driver Ports ----------------------
      .gt0_txpostcursor_in            (gt0_txpostcursor_in),
      .gt0_txprecursor_in             (gt0_txprecursor_in),
        //------------------- TX Initialization and Reset Ports --------------------
      .gt0_gttxreset_in               (gt0_gttxreset_in),
      .gt0_txuserrdy_in               (gt0_txuserrdy_in),
        //---------------- Transmit Ports - FPGA TX Interface Ports ----------------
      .gt0_txdata_in                  (gt_txdata_out1),
      .gt0_txusrclk_in                (clk_92_16),
      .gt0_txusrclk2_in               (clk_46_08),
        //---------------- Transmit Ports - Pattern Generator Ports ----------------
      .gt0_txprbsforceerr_in          (gt0_txprbsforceerr_in),
        //---------------- Transmit Ports - TX 8B/10B Encoder Ports ----------------
      .gt0_txcharisk_in               (gt_txcharisk_out1),
        //------------- Transmit Ports - TX Configurable Driver Ports --------------
      .gt0_gtptxn_out(jesd1tx_n),
      .gt0_gtptxp_out(jesd1tx_p),
      .gt0_txdiffctrl_in              (gt0_txdiffctrl_in),
        //--------- Transmit Ports - TX Fabric Clock Output Control Ports ----------
      .gt0_txoutclk_out               (gt0_txoutclk_out),
      .gt0_txoutclkfabric_out         (gt0_txoutclkfabric_out),
      .gt0_txoutclkpcs_out            (gt0_txoutclkpcs_out),
        //----------- Transmit Ports - TX Initialization and Reset Ports -----------
      .gt0_txresetdone_out            (tx_reset_done),
        //--------------- Transmit Ports - TX Polarity Control Ports ---------------
      .gt0_txpolarity_in              (gt0_txpolarity_in),
        //---------------- Transmit Ports - pattern Generator Ports ----------------
      .gt0_txprbssel_in               (gt_prbssel_out),
    
    
        //____________________________COMMON PORTS________________________________
      .gt0_pll0outclk_in(gt_pll0outclk),
      .gt0_pll0outrefclk_in(gt_pll0outrefclk),
      .gt0_pll1lock_in(gt_pll1lock),
      .gt0_pll1refclklost_in(gt_pll1refclklost),    
      .gt0_pll1outclk_in(gt_pll1outclk),
      .gt0_pll1outrefclk_in(gt_pll1outrefclk),
      
      .gt0_pll1reset_out(pll1reset0)
    );

        
    jesd204_0_gtwizard_1  jesd204_0_gtwizard_1_i (
      .sysclk_in(fooclk),
      .soft_reset_in(soft_reset),
      .dont_reset_on_data_error_in(dont_reset_on_data_error_inB),
      .gt0_tx_fsm_reset_done_out(gt0_tx_fsm_reset_done_outB),
      .gt0_rx_fsm_reset_done_out(gt0_rx_fsm_reset_done_outB),
      .gt0_data_valid_in(gt0_data_valid_inB),
      .gt0_tx_mmcm_lock_in(jesdmmcmlocked),
      .gt0_tx_mmcm_reset_out(gt0_tx_mmcm_reset_out2),
        
            //_________________________________________________________________________
            //GT0  (X0Y2)
            //____________________________CHANNEL PORTS________________________________
            //-------------------------- Channel - DRP Ports  --------------------------
      .gt0_drpaddr_in                 (gt0_drpaddr_inB),
      .gt0_drpclk_in                  (clk_92_16),
      .gt0_drpdi_in                   (gt0_drpdi_inB),
      .gt0_drpdo_out                  (gt0_drpdo_outB),
      .gt0_drpen_in                   (gt0_drpen_inB),
      .gt0_drprdy_out                 (gt0_drprdy_outB),
      .gt0_drpwe_in                   (gt0_drpwe_inB),
            //----------------------------- Loopback Ports -----------------------------
      .gt0_loopback_in                (gt0_loopback_inB),
            //---------------------------- Power-Down Ports ----------------------------
      .gt0_rxpd_in                    (gt0_rxpd_inB),
      .gt0_txpd_in                    (gt0_txpd_inB),
            //------------------- RX Initialization and Reset Ports --------------------
      .gt0_eyescanreset_in            (gt0_eyescanreset_inB),
            //------------------------ RX Margin Analysis Ports ------------------------
      .gt0_eyescandataerror_out       (gt0_eyescandataerror_outB),
      .gt0_eyescantrigger_in          (gt0_eyescantrigger_inB),
            //----------------- Receive Ports - Pattern Checker Ports ------------------
      .gt0_rxprbserr_out              (gt0_rxprbserr_outB),
      .gt0_rxprbssel_in               (gt0_rxprbssel2),
            //----------------- Receive Ports - Pattern Checker ports ------------------
      .gt0_rxprbscntreset_in          (gt0_rxprbscntreset_inB),
            //----------------- Receive Ports - RX Buffer Bypass Ports -----------------
      .gt0_rxbufreset_in              (gt0_rxbufreset_inB),
      .gt0_rxbufstatus_out            (gt0_rxbufstatus_outB),
            //----------- Receive Ports - RX Initialization and Reset Ports ------------
      .gt0_gtrxreset_in               (gt0_gtrxreset_inB),
            //---------------------- TX Configurable Driver Ports ----------------------
      .gt0_txpostcursor_in            (gt0_txpostcursor_inB),
      .gt0_txprecursor_in             (gt0_txprecursor_inB),
            //------------------- TX Initialization and Reset Ports --------------------
      .gt0_gttxreset_in               (gt0_gttxreset_inB),
      .gt0_txuserrdy_in               (gt0_txuserrdy_inB),
            //---------------- Transmit Ports - FPGA TX Interface Ports ----------------
      .gt0_txdata_in                  (gt_txdata_out2),
      .gt0_txusrclk_in                (clk_92_16),
      .gt0_txusrclk2_in               (clk_46_08),
            //---------------- Transmit Ports - Pattern Generator Ports ----------------
      .gt0_txprbsforceerr_in          (gt0_txprbsforceerr_inB),
            //---------------- Transmit Ports - TX 8B/10B Encoder Ports ----------------
      .gt0_txcharisk_in               (gt_txcharisk_out2),
            //------------- Transmit Ports - TX Configurable Driver Ports --------------
     .gt0_gtptxn_out(jesd2tx_n),
     .gt0_gtptxp_out(jesd2tx_p),
      .gt0_txdiffctrl_in              (gt0_txdiffctrl_inB),
            //--------- Transmit Ports - TX Fabric Clock Output Control Ports ----------
      .gt0_txoutclk_out               (gt0_txoutclk_outB),
      .gt0_txoutclkfabric_out         (gt0_txoutclkfabric_outB),
      .gt0_txoutclkpcs_out            (gt0_txoutclkpcs_outB),
            //----------- Transmit Ports - TX Initialization and Reset Ports -----------
      .gt0_txresetdone_out            (tx_reset_done2),
     //--------------- Transmit Ports - TX Polarity Control Ports ---------------
      .gt0_txpolarity_in              (gt0_txpolarity_inB),
     //---------------- Transmit Ports - pattern Generator Ports ----------------
      .gt0_txprbssel_in               (gt_prbssel2),
        
        
            //____________________________COMMON PORTS________________________________
      .gt0_pll0outclk_in(gt_pll0outclk),
      .gt0_pll0outrefclk_in(gt_pll0outrefclk),
      .gt0_pll1lock_in(gt_pll1lock),
      .gt0_pll1refclklost_in(gt_pll1refclklost),    
      .gt0_pll1outclk_in(gt_pll1outclk),
      .gt0_pll1outrefclk_in(gt_pll1outrefclk),
            
      .gt0_pll1reset_out(pll1reset1)
   );

   assign gt_pll1reset = pll1reset0 | pll1reset1;

endmodule

// generate some patterned data to feed the Tx
// TODO: replace with something real

module dirtgen(clk, ena, dout);
input clk;
input ena;
output reg [31:0] dout;

  always @(posedge clk) begin
    if (ena) begin
      dout[15:0] <= dout[15:0] + 1'b1;
      dout[31:16] <= dout[15:0] + 2'd2;
   //   dout[47:32] <= dout[15:0] + 1'b3;
   //   dout[63:48] <= dout[15:0] + 1'b4;
    end

  end

endmodule
