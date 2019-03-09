///////////////////////////////////////////////////////////////////
///
// Copyright 2016-2018 Ettus Research, A National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// Module: n3xx
// Description:
//   Top Level for N3xx devices
//
//////////////////////////////////////////////////////////////////////

module n3xx (
  inout [11:0] FPGA_GPIO,

  input FPGA_REFCLK_P,
  input FPGA_REFCLK_N,
  input REF_1PPS_IN,
  input NETCLK_REF_P,
  input NETCLK_REF_N,
  //input REF_1PPS_IN_MGMT,
  output REF_1PPS_OUT,

  //TDC
  inout UNUSED_PIN_TDCA_0,
  inout UNUSED_PIN_TDCA_1,
  inout UNUSED_PIN_TDCA_2,
  inout UNUSED_PIN_TDCA_3,
  inout UNUSED_PIN_TDCB_0,
  inout UNUSED_PIN_TDCB_1,
  inout UNUSED_PIN_TDCB_2,
  inout UNUSED_PIN_TDCB_3,

`ifdef NPIO_LANES
  input  NPIO_RX0_P,
  input  NPIO_RX0_N,
  output NPIO_TX0_P,
  output NPIO_TX0_N,
  //Uncomment if NPIO_LANES=2
  //input  NPIO_RX1_P,
  //input  NPIO_RX1_N,
  //output NPIO_TX1_P,
  //output NPIO_TX1_N,
`endif
`ifdef QSFP_LANES
  input  QSFP_RX0_P,
  input  QSFP_RX0_N,
  output QSFP_TX0_P,
  output QSFP_TX0_N,
/*  input  QSFP_RX1_P,
  input  QSFP_RX1_N,
  output QSFP_TX1_P,
  output QSFP_TX1_N,
  input  QSFP_RX2_P,
  input  QSFP_RX2_N,
  output QSFP_TX2_P,
  output QSFP_TX2_N,
  input  QSFP_RX3_P,
  input  QSFP_RX3_N,
  output QSFP_TX3_P,
  output QSFP_TX3_N,*/
 `endif
  //TODO: Uncomment when connected here
  //input NPIO_0_RXSYNC_0_P, NPIO_0_RXSYNC_1_P,
  //input NPIO_0_RXSYNC_0_N, NPIO_0_RXSYNC_1_N,
  //output NPIO_0_TXSYNC_0_P, NPIO_0_TXSYNC_1_P,
  //output NPIO_0_TXSYNC_0_N, NPIO_0_TXSYNC_1_N,
  //input NPIO_1_RXSYNC_0_P, NPIO_1_RXSYNC_1_P,
  //input NPIO_1_RXSYNC_0_N, NPIO_1_RXSYNC_1_N,
  //output NPIO_1_TXSYNC_0_P, NPIO_1_TXSYNC_1_P,
  //output NPIO_1_TXSYNC_0_N, NPIO_1_TXSYNC_1_N,
  //input NPIO_2_RXSYNC_0_P, NPIO_2_RXSYNC_1_P,
  //input NPIO_2_RXSYNC_0_N, NPIO_2_RXSYNC_1_N,
  //output NPIO_2_TXSYNC_0_P, NPIO_2_TXSYNC_1_P,
  //output NPIO_2_TXSYNC_0_N, NPIO_2_TXSYNC_1_N,

  //GPS
  input GPS_1PPS,
  //input GPS_1PPS_RAW,

  //Misc
  input ENET0_CLK125,
  //inout ENET0_PTP,
  //output ENET0_PTP_DIR,
  //inout ATSHA204_SDA,
  input FPGA_PL_RESETN, // TODO:  Add to reset logic
  // output reg [1:0] FPGA_TEST,
  //input PWR_CLK_FPGA, // TODO: check direction
  input FPGA_PUDC_B,

  //White Rabbit
  input WB_20MHZ_P,
  input WB_20MHZ_N,
  output WB_DAC_DIN,
  output WB_DAC_NCLR,
  output WB_DAC_NLDAC,
  output WB_DAC_NSYNC,
  output WB_DAC_SCLK,

  //LEDS
  output PANEL_LED_GPS,
  output PANEL_LED_LINK,
  output PANEL_LED_PPS,
  output PANEL_LED_REF,

  // ARM Connections (PS)
  inout [53:0]  MIO,
  inout         PS_SRSTB,
  inout         PS_CLK,
  inout         PS_PORB,
  inout         DDR_Clk,
  inout         DDR_Clk_n,
  inout         DDR_CKE,
  inout         DDR_CS_n,
  inout         DDR_RAS_n,
  inout         DDR_CAS_n,
  inout         DDR_WEB,
  inout [2:0]   DDR_BankAddr,
  inout [14:0]  DDR_Addr,
  inout         DDR_ODT,
  inout         DDR_DRSTB,
  inout [31:0]  DDR_DQ,
  inout [3:0]   DDR_DM,
  inout [3:0]   DDR_DQS,
  inout [3:0]   DDR_DQS_n,
  inout         DDR_VRP,
  inout         DDR_VRN,


  ///////////////////////////////////
  //
  // High Speed SPF+ signals and clocking
  //
  ///////////////////////////////////

  // These clock inputs must always be enabled with a buffer regardless of the build
  // target to avoid damage to the FPGA.
  input NETCLK_P,
  input NETCLK_N,
  input MGT156MHZ_CLK1_P,
  input MGT156MHZ_CLK1_N,

  input SFP_0_RX_P, input SFP_0_RX_N,
  output SFP_0_TX_P, output SFP_0_TX_N,
  input SFP_1_RX_P, input SFP_1_RX_N,
  output SFP_1_TX_P, output SFP_1_TX_N,


  ///////////////////////////////////
  //
  // DRAM Interface
  //
  ///////////////////////////////////
  /*
  inout [31:0] ddr3_dq,     // Data pins. Input for Reads, Output for Writes.
  inout [3:0] ddr3_dqs_n,   // Data Strobes. Input for Reads, Output for Writes.
  inout [3:0] ddr3_dqs_p,
  //
  output [15:0] ddr3_addr,  // Address
  output [2:0] ddr3_ba,     // Bank Address
  output ddr3_ras_n,        // Row Address Strobe.
  output ddr3_cas_n,        // Column address select
  output ddr3_we_n,         // Write Enable
  output ddr3_reset_n,      // SDRAM reset pin.
  output [0:0] ddr3_ck_p,         // Differential clock
  output [0:0] ddr3_ck_n,
  output [0:0] ddr3_cke,    // Clock Enable
  output [0:0] ddr3_cs_n,         // Chip Select
  output [3:0] ddr3_dm,     // Data Mask [3] = UDM.U26, [2] = LDM.U26, ...
  output [0:0] ddr3_odt,    // On-Die termination enable.
  //
  input sys_clk_p,          // Differential
  input sys_clk_n,          // 100MHz clock source to generate DDR3 clocking.
*/

  ///////////////////////////////////
  //
  // Supporting I/O for SPF+ interfaces
  //  (non high speed stuff)
  //
  ///////////////////////////////////

  //SFP+ 0, Slow Speed, Bank 13 3.3V
  input SFP_0_I2C_NPRESENT,
  output SFP_0_LED_A,
  output SFP_0_LED_B,
  input SFP_0_LOS,
  output SFP_0_RS0,
  output SFP_0_RS1,
  output SFP_0_TXDISABLE,
  input SFP_0_TXFAULT,

  //SFP+ 1, Slow Speed, Bank 13 3.3V
  //input SFP_1_I2C_NPRESENT,
  output SFP_1_LED_A,
  output SFP_1_LED_B,
  input SFP_1_LOS,
  output SFP_1_RS0,
  output SFP_1_RS1,
  output SFP_1_TXDISABLE,
  input SFP_1_TXFAULT,

  //USRP IO A
  //Comments next to wire name are the name on the EISCAT daughterboard schematic
  //HP Bank
  output DBA_ADC_A_SYNC_P, //ADCa_SYNCbABp
  output DBA_ADC_A_SYNC_N, //ADCa_SYNCbABm
  output DBA_ADC_A_SYSREF_P, //ADCa_SYSREFp_FPGA
  output DBA_ADC_A_SYSREF_N, //ADCa_SYSREFn_FPGA

  output DBA_ADC_B_SYNC_P, //ADCb_SYNCbABp
  output DBA_ADC_B_SYNC_N, //ADCb_SYNCbABn
  output DBA_ADC_B_SYSREF_P, //ADCa_SYSREFp_FPGA
  output DBA_ADC_B_SYSREF_N, //ADCa_SYSREFn_FPGA

  input DBA_ADC_A_SDOUT, //ADCa_SDOUT
  input DBA_ADC_B_SDOUT, //ADCb_SDOUT

  //HR Bank
  output DBA_ADC_SPI_EN, //ADC_SPI_ENB

  output DBA_ADC_A_RESET, //ADCa_RESET
  output DBA_ADC_A_SCLK, //ADCa_SCLK
  output DBA_ADC_A_CS_N, //ADCa_CS
  output DBA_ADC_A_SDI, //ADCa_SDI

  output DBA_ADC_B_RESET, //ADCb_RESET
  output DBA_ADC_B_SCLK, //ADCb_SCLK
  output DBA_ADC_B_CS_N, //ADCb_CS
  output DBA_ADC_B_SDI, //ADCb_SDI

  output DBA_LMK_SPI_EN, //LMK_SPI_ENB
  output DBA_LMK_SYNC, //LMK_SYNC
  output DBA_LMK_SCK, //LMK_SCK
  output DBA_LMK_CS_N, //LMK_CS
  output DBA_LMK_SDI, //LMK_SDI
  input DBA_LMK_READBACK, //LMK_ReadBack
  input DBA_LMK_STATUS, //LMK_Status

  output DBA_PDAC_SDI, //PDAC_SDI
  output DBA_PDAC_SCLK, //PDAC_SCLK
  output DBA_PDAC_CS_N, //PDAC_CSn

  output DBA_DB_CTRL_EN_N, //2.5V_DC_CTRL_ENB
  output DBA_DC_PWR_EN, //DC_PWR_EN
  output DBA_LNA_CTRL_EN, //LNA_CTRL_ENB

  output DBA_CH0_EN_N, //CH0_ENb
  output DBA_CH1_EN_N, //CH1_ENb
  output DBA_CH2_EN_N, //CH2_ENb
  output DBA_CH3_EN_N, //CH3_ENb
  output DBA_CH4_EN_N, //CH4_ENb
  output DBA_CH5_EN_N, //CH5_ENb
  output DBA_CH6_EN_N, //CH6_ENb
  output DBA_CH7_EN_N, //CH7_ENb

  input DBA_FPGA_CLK_P, //FPGA_SCLKp
  input DBA_FPGA_CLK_N, //FPGA_SCLKn
  //input DbaFpgaSysref_p, //FPGA_Sysref_p
  //input DbaFpgaSysref_n, //FPGA_Sysref_n

  input DBA_TMON_ALERT_N, //
  input DBA_VMON_ALERT, //



  //MGTs
  input USRPIO_A_MGTCLK_P, //MGTREFCLK_p
  input USRPIO_A_MGTCLK_N, //MGTREFCLK_n

  input [3:0] USRPIO_A_RX_P, //MGT_RXp[3:0]
  input [3:0] USRPIO_A_RX_N, //MGT_RXn[3:0]

  //USRP IO B
  //Comments next to wire name are the name on the EISCAT daughterboard schematic
  //HP Bank
  output DBB_ADC_A_SYNC_P, //ADCa_SYNCbABp
  output DBB_ADC_A_SYNC_N, //ADCa_SYNCbABm
  output DBB_ADC_A_SYSREF_P, //ADCa_SYSREFp_FPGA
  output DBB_ADC_A_SYSREF_N, //ADCa_SYSREFn_FPGA

  output DBB_ADC_B_SYNC_P, //ADCb_SYNCbABp
  output DBB_ADC_B_SYNC_N, //ADCb_SYNCbABn
  output DBB_ADC_B_SYSREF_P, //ADCa_SYSREFp_FPGA
  output DBB_ADC_B_SYSREF_N, //ADCa_SYSREFn_FPGA

  input DBB_ADC_A_SDOUT, //ADCa_SDOUT
  input DBB_ADC_B_SDOUT, //ADCb_SDOUT

  //HR Bank
  output DBB_ADC_SPI_EN, //ADC_SPI_ENB

  output DBB_ADC_A_RESET, //ADCa_RESET
  output DBB_ADC_A_SCLK, //ADCa_SCLK
  output DBB_ADC_A_CS_N, //ADCa_CS
  output DBB_ADC_A_SDI, //ADCa_SDI

  output DBB_ADC_B_RESET, //ADCb_RESET
  output DBB_ADC_B_SCLK, //ADCb_SCLK
  output DBB_ADC_B_CS_N, //ADCb_CS
  output DBB_ADC_B_SDI, //ADCb_SDI

  output DBB_LMK_SPI_EN, //LMK_SPI_ENB
  output DBB_LMK_SYNC, //LMK_SYNC
  output DBB_LMK_SCK, //LMK_SCK
  output DBB_LMK_CS_N, //LMK_CS
  output DBB_LMK_SDI, //LMK_SDI
  input DBB_LMK_READBACK, //LMK_ReadBack
  input DBB_LMK_STATUS, //LMK_Status

  output DBB_PDAC_SDI, //PDAC_SDI
  output DBB_PDAC_SCLK, //PDAC_SCLK
  output DBB_PDAC_CS_N, //PDAC_CSn

  output DBB_DB_CTRL_EN_N, //2.5V_DC_CTRL_ENB
  output DBB_DC_PWR_EN, //DC_PWR_EN
  output DBB_LNA_CTRL_EN, //LNA_CTRL_ENB

  output DBB_CH0_EN_N, //CH0_ENb
  output DBB_CH1_EN_N, //CH1_ENb
  output DBB_CH2_EN_N, //CH2_ENb
  output DBB_CH3_EN_N, //CH3_ENb
  output DBB_CH4_EN_N, //CH4_ENb
  output DBB_CH5_EN_N, //CH5_ENb
  output DBB_CH6_EN_N, //CH6_ENb
  output DBB_CH7_EN_N, //CH7_ENb

  input DBB_FPGA_CLK_P, //FPGA_SCLKp
  input DBB_FPGA_CLK_N, //FPGA_SCLKn
  //input DbaFpgaSysref_p, //FPGA_Sysref_p
  //input DbaFpgaSysref_n, //FPGA_Sysref_n


  input DBB_TMON_ALERT_N, //
  input DBB_VMON_ALERT, //


  //MGTs
  input USRPIO_B_MGTCLK_P, //MGTREFCLK_p
  input USRPIO_B_MGTCLK_N, //MGTREFCLK_n

  input [3:0] USRPIO_B_RX_P, //MGT_RXp[3:0]
  input [3:0] USRPIO_B_RX_N //MGT_RXn[3:0]


);

  localparam N_AXILITE_SLAVES = 4;
  localparam REG_AWIDTH = 14; // log2(0x4000)
  localparam REG_DWIDTH = 32;
  localparam FP_GPIO_OFFSET = 32;
  localparam FP_GPIO_WIDTH = 12;

`ifdef N310
  localparam NUM_RADIOS = 2;
  localparam NUM_CHANNELS_PER_RADIO = 2;
  localparam NUM_DBOARDS = 2;
`elsif N300
  localparam NUM_RADIOS = 1;
  localparam NUM_CHANNELS_PER_RADIO = 2;
  localparam NUM_DBOARDS = 1;
`endif
  localparam NUM_CHANNELS = NUM_RADIOS * NUM_CHANNELS_PER_RADIO;

  // Internal connections to PS
  // HP0 -- High Performance port 0, FPGA is the master
  wire [5:0]  S_AXI_HP0_AWID;
  wire [31:0] S_AXI_HP0_AWADDR;
  wire [2:0]  S_AXI_HP0_AWPROT;
  wire        S_AXI_HP0_AWVALID;
  wire        S_AXI_HP0_AWREADY;
  wire [63:0] S_AXI_HP0_WDATA;
  wire [7:0]  S_AXI_HP0_WSTRB;
  wire        S_AXI_HP0_WVALID;
  wire        S_AXI_HP0_WREADY;
  wire [1:0]  S_AXI_HP0_BRESP;
  wire        S_AXI_HP0_BVALID;
  wire        S_AXI_HP0_BREADY;
  wire [5:0]  S_AXI_HP0_ARID;
  wire [31:0] S_AXI_HP0_ARADDR;
  wire [2:0]  S_AXI_HP0_ARPROT;
  wire        S_AXI_HP0_ARVALID;
  wire        S_AXI_HP0_ARREADY;
  wire [63:0] S_AXI_HP0_RDATA;
  wire [1:0]  S_AXI_HP0_RRESP;
  wire        S_AXI_HP0_RVALID;
  wire        S_AXI_HP0_RREADY;
  wire        S_AXI_HP0_RLAST;
  wire [3:0]  S_AXI_HP0_ARCACHE;
  wire [7:0]  S_AXI_HP0_AWLEN;
  wire [2:0]  S_AXI_HP0_AWSIZE;
  wire [1:0]  S_AXI_HP0_AWBURST;
  wire [3:0]  S_AXI_HP0_AWCACHE;
  wire        S_AXI_HP0_WLAST;
  wire [7:0]  S_AXI_HP0_ARLEN;
  wire [1:0]  S_AXI_HP0_ARBURST;
  wire [2:0]  S_AXI_HP0_ARSIZE;

  // GP0 -- General Purpose port 0, FPGA is the master
  wire [4:0]  S_AXI_GP0_AWID;
  wire [31:0] S_AXI_GP0_AWADDR;
  wire [2:0]  S_AXI_GP0_AWPROT;
  wire        S_AXI_GP0_AWVALID;
  wire        S_AXI_GP0_AWREADY;
  wire [31:0] S_AXI_GP0_WDATA;
  wire [3:0]  S_AXI_GP0_WSTRB;
  wire        S_AXI_GP0_WVALID;
  wire        S_AXI_GP0_WREADY;
  wire [1:0]  S_AXI_GP0_BRESP;
  wire        S_AXI_GP0_BVALID;
  wire        S_AXI_GP0_BREADY;
  wire [4:0]  S_AXI_GP0_ARID;
  wire [31:0] S_AXI_GP0_ARADDR;
  wire [2:0]  S_AXI_GP0_ARPROT;
  wire        S_AXI_GP0_ARVALID;
  wire        S_AXI_GP0_ARREADY;
  wire [31:0] S_AXI_GP0_RDATA;
  wire [1:0]  S_AXI_GP0_RRESP;
  wire        S_AXI_GP0_RVALID;
  wire        S_AXI_GP0_RREADY;
  wire        S_AXI_GP0_RLAST;
  wire [3:0]  S_AXI_GP0_ARCACHE;
  wire [7:0]  S_AXI_GP0_AWLEN;
  wire [2:0]  S_AXI_GP0_AWSIZE;
  wire [1:0]  S_AXI_GP0_AWBURST;
  wire [3:0]  S_AXI_GP0_AWCACHE;
  wire        S_AXI_GP0_WLAST;
  wire [7:0]  S_AXI_GP0_ARLEN;
  wire [1:0]  S_AXI_GP0_ARBURST;
  wire [2:0]  S_AXI_GP0_ARSIZE;

  // HP1 -- High Performance port 1, FPGA is the master
  wire [5:0]  S_AXI_HP1_AWID;
  wire [31:0] S_AXI_HP1_AWADDR;
  wire [2:0]  S_AXI_HP1_AWPROT;
  wire        S_AXI_HP1_AWVALID;
  wire        S_AXI_HP1_AWREADY;
  wire [63:0] S_AXI_HP1_WDATA;
  wire [7:0]  S_AXI_HP1_WSTRB;
  wire        S_AXI_HP1_WVALID;
  wire        S_AXI_HP1_WREADY;
  wire [1:0]  S_AXI_HP1_BRESP;
  wire        S_AXI_HP1_BVALID;
  wire        S_AXI_HP1_BREADY;
  wire [5:0]  S_AXI_HP1_ARID;
  wire [31:0] S_AXI_HP1_ARADDR;
  wire [2:0]  S_AXI_HP1_ARPROT;
  wire        S_AXI_HP1_ARVALID;
  wire        S_AXI_HP1_ARREADY;
  wire [63:0] S_AXI_HP1_RDATA;
  wire [1:0]  S_AXI_HP1_RRESP;
  wire        S_AXI_HP1_RVALID;
  wire        S_AXI_HP1_RREADY;
  wire        S_AXI_HP1_RLAST;
  wire [3:0]  S_AXI_HP1_ARCACHE;
  wire [7:0]  S_AXI_HP1_AWLEN;
  wire [2:0]  S_AXI_HP1_AWSIZE;
  wire [1:0]  S_AXI_HP1_AWBURST;
  wire [3:0]  S_AXI_HP1_AWCACHE;
  wire        S_AXI_HP1_WLAST;
  wire [7:0]  S_AXI_HP1_ARLEN;
  wire [1:0]  S_AXI_HP1_ARBURST;
  wire [2:0]  S_AXI_HP1_ARSIZE;

  // GP1 -- General Purpose port 1, FPGA is the master
  wire [4:0]  S_AXI_GP1_AWID;
  wire [31:0] S_AXI_GP1_AWADDR;
  wire [2:0]  S_AXI_GP1_AWPROT;
  wire        S_AXI_GP1_AWVALID;
  wire        S_AXI_GP1_AWREADY;
  wire [31:0] S_AXI_GP1_WDATA;
  wire [3:0]  S_AXI_GP1_WSTRB;
  wire        S_AXI_GP1_WVALID;
  wire        S_AXI_GP1_WREADY;
  wire [1:0]  S_AXI_GP1_BRESP;
  wire        S_AXI_GP1_BVALID;
  wire        S_AXI_GP1_BREADY;
  wire [4:0]  S_AXI_GP1_ARID;
  wire [31:0] S_AXI_GP1_ARADDR;
  wire [2:0]  S_AXI_GP1_ARPROT;
  wire        S_AXI_GP1_ARVALID;
  wire        S_AXI_GP1_ARREADY;
  wire [31:0] S_AXI_GP1_RDATA;
  wire [1:0]  S_AXI_GP1_RRESP;
  wire        S_AXI_GP1_RVALID;
  wire        S_AXI_GP1_RREADY;
  wire        S_AXI_GP1_RLAST;
  wire [3:0]  S_AXI_GP1_ARCACHE;
  wire [7:0]  S_AXI_GP1_AWLEN;
  wire [2:0]  S_AXI_GP1_AWSIZE;
  wire [1:0]  S_AXI_GP1_AWBURST;
  wire [3:0]  S_AXI_GP1_AWCACHE;
  wire        S_AXI_GP1_WLAST;
  wire [7:0]  S_AXI_GP1_ARLEN;
  wire [1:0]  S_AXI_GP1_ARBURST;
  wire [2:0]  S_AXI_GP1_ARSIZE;

  // GP0 -- General Purpose port 0, FPGA is the slave
  wire        M_AXI_GP0_ARVALID;
  wire        M_AXI_GP0_AWVALID;
  wire        M_AXI_GP0_BREADY;
  wire        M_AXI_GP0_RREADY;
  wire        M_AXI_GP0_WVALID;
  wire [11:0] M_AXI_GP0_ARID;
  wire [11:0] M_AXI_GP0_AWID;
  wire [11:0] M_AXI_GP0_WID;
  wire [31:0] M_AXI_GP0_ARADDR;
  wire [31:0] M_AXI_GP0_AWADDR;
  wire [31:0] M_AXI_GP0_WDATA;
  wire [3:0]  M_AXI_GP0_WSTRB;
  wire        M_AXI_GP0_ARREADY;
  wire        M_AXI_GP0_AWREADY;
  wire        M_AXI_GP0_BVALID;
  wire        M_AXI_GP0_RLAST;
  wire        M_AXI_GP0_RVALID;
  wire        M_AXI_GP0_WREADY;
  wire [1:0]  M_AXI_GP0_BRESP;
  wire [1:0]  M_AXI_GP0_RRESP;
  wire [31:0] M_AXI_GP0_RDATA;

  wire        M_AXI_ETH_DMA0_ARVALID;
  wire        M_AXI_ETH_DMA0_AWVALID;
  wire        M_AXI_ETH_DMA0_BREADY;
  wire        M_AXI_ETH_DMA0_RREADY;
  wire        M_AXI_ETH_DMA0_WVALID;
  wire [11:0] M_AXI_ETH_DMA0_ARID;
  wire [11:0] M_AXI_ETH_DMA0_AWID;
  wire [11:0] M_AXI_ETH_DMA0_WID;
  wire [31:0] M_AXI_ETH_DMA0_ARADDR;
  wire [31:0] M_AXI_ETH_DMA0_AWADDR;
  wire [31:0] M_AXI_ETH_DMA0_WDATA;
  wire [3:0]  M_AXI_ETH_DMA0_WSTRB;
  wire        M_AXI_ETH_DMA0_ARREADY;
  wire        M_AXI_ETH_DMA0_AWREADY;
  wire        M_AXI_ETH_DMA0_BVALID;
  wire        M_AXI_ETH_DMA0_RLAST;
  wire        M_AXI_ETH_DMA0_RVALID;
  wire        M_AXI_ETH_DMA0_WREADY;
  wire [1:0]  M_AXI_ETH_DMA0_BRESP;
  wire [1:0]  M_AXI_ETH_DMA0_RRESP;
  wire [31:0] M_AXI_ETH_DMA0_RDATA;

  wire        M_AXI_NET0_ARVALID;
  wire        M_AXI_NET0_AWVALID;
  wire        M_AXI_NET0_BREADY;
  wire        M_AXI_NET0_RREADY;
  wire        M_AXI_NET0_WVALID;
  wire [11:0] M_AXI_NET0_ARID;
  wire [11:0] M_AXI_NET0_AWID;
  wire [11:0] M_AXI_NET0_WID;
  wire [31:0] M_AXI_NET0_ARADDR;
  wire [31:0] M_AXI_NET0_AWADDR;
  wire [31:0] M_AXI_NET0_WDATA;
  wire [3:0]  M_AXI_NET0_WSTRB;
  wire        M_AXI_NET0_ARREADY;
  wire        M_AXI_NET0_AWREADY;
  wire        M_AXI_NET0_BVALID;
  wire        M_AXI_NET0_RLAST;
  wire        M_AXI_NET0_RVALID;
  wire        M_AXI_NET0_WREADY;
  wire [1:0]  M_AXI_NET0_BRESP;
  wire [1:0]  M_AXI_NET0_RRESP;
  wire [31:0] M_AXI_NET0_RDATA;

  wire        M_AXI_ETH_DMA1_ARVALID;
  wire        M_AXI_ETH_DMA1_AWVALID;
  wire        M_AXI_ETH_DMA1_BREADY;
  wire        M_AXI_ETH_DMA1_RREADY;
  wire        M_AXI_ETH_DMA1_WVALID;
  wire [11:0] M_AXI_ETH_DMA1_ARID;
  wire [11:0] M_AXI_ETH_DMA1_AWID;
  wire [11:0] M_AXI_ETH_DMA1_WID;
  wire [31:0] M_AXI_ETH_DMA1_ARADDR;
  wire [31:0] M_AXI_ETH_DMA1_AWADDR;
  wire [31:0] M_AXI_ETH_DMA1_WDATA;
  wire [3:0]  M_AXI_ETH_DMA1_WSTRB;
  wire        M_AXI_ETH_DMA1_ARREADY;
  wire        M_AXI_ETH_DMA1_AWREADY;
  wire        M_AXI_ETH_DMA1_BVALID;
  wire        M_AXI_ETH_DMA1_RLAST;
  wire        M_AXI_ETH_DMA1_RVALID;
  wire        M_AXI_ETH_DMA1_WREADY;
  wire [1:0]  M_AXI_ETH_DMA1_BRESP;
  wire [1:0]  M_AXI_ETH_DMA1_RRESP;
  wire [31:0] M_AXI_ETH_DMA1_RDATA;

  wire        M_AXI_NET1_ARVALID;
  wire        M_AXI_NET1_AWVALID;
  wire        M_AXI_NET1_BREADY;
  wire        M_AXI_NET1_RREADY;
  wire        M_AXI_NET1_WVALID;
  wire [11:0] M_AXI_NET1_ARID;
  wire [11:0] M_AXI_NET1_AWID;
  wire [11:0] M_AXI_NET1_WID;
  wire [31:0] M_AXI_NET1_ARADDR;
  wire [31:0] M_AXI_NET1_AWADDR;
  wire [31:0] M_AXI_NET1_WDATA;
  wire [3:0]  M_AXI_NET1_WSTRB;
  wire        M_AXI_NET1_ARREADY;
  wire        M_AXI_NET1_AWREADY;
  wire        M_AXI_NET1_BVALID;
  wire        M_AXI_NET1_RLAST;
  wire        M_AXI_NET1_RVALID;
  wire        M_AXI_NET1_WREADY;
  wire [1:0]  M_AXI_NET1_BRESP;
  wire [1:0]  M_AXI_NET1_RRESP;
  wire [31:0] M_AXI_NET1_RDATA;

  wire        M_AXI_XBAR_ARVALID;
  wire        M_AXI_XBAR_AWVALID;
  wire        M_AXI_XBAR_BREADY;
  wire        M_AXI_XBAR_RREADY;
  wire        M_AXI_XBAR_WVALID;
  wire [11:0] M_AXI_XBAR_ARID;
  wire [11:0] M_AXI_XBAR_AWID;
  wire [11:0] M_AXI_XBAR_WID;
  wire [31:0] M_AXI_XBAR_ARADDR;
  wire [31:0] M_AXI_XBAR_AWADDR;
  wire [31:0] M_AXI_XBAR_WDATA;
  wire [3:0]  M_AXI_XBAR_WSTRB;
  wire        M_AXI_XBAR_ARREADY;
  wire        M_AXI_XBAR_AWREADY;
  wire        M_AXI_XBAR_BVALID;
  wire        M_AXI_XBAR_RLAST;
  wire        M_AXI_XBAR_RVALID;
  wire        M_AXI_XBAR_WREADY;
  wire [1:0]  M_AXI_XBAR_BRESP;
  wire [1:0]  M_AXI_XBAR_RRESP;
  wire [31:0] M_AXI_XBAR_RDATA;

  wire        M_AXI_JESD0_ARVALID;
  wire        M_AXI_JESD0_AWVALID;
  wire        M_AXI_JESD0_BREADY;
  wire        M_AXI_JESD0_RREADY;
  wire        M_AXI_JESD0_WVALID;
  wire [11:0] M_AXI_JESD0_ARID;
  wire [11:0] M_AXI_JESD0_AWID;
  wire [11:0] M_AXI_JESD0_WID;
  wire [31:0] M_AXI_JESD0_ARADDR;
  wire [31:0] M_AXI_JESD0_AWADDR;
  wire [31:0] M_AXI_JESD0_WDATA;
  wire [3:0]  M_AXI_JESD0_WSTRB;
  wire        M_AXI_JESD0_ARREADY;
  wire        M_AXI_JESD0_AWREADY;
  wire        M_AXI_JESD0_BVALID;
  wire        M_AXI_JESD0_RLAST;
  wire        M_AXI_JESD0_RVALID;
  wire        M_AXI_JESD0_WREADY;
  wire [1:0]  M_AXI_JESD0_BRESP;
  wire [1:0]  M_AXI_JESD0_RRESP;
  wire [31:0] M_AXI_JESD0_RDATA;

  wire        M_AXI_JESD1_ARVALID;
  wire        M_AXI_JESD1_AWVALID;
  wire        M_AXI_JESD1_BREADY;
  wire        M_AXI_JESD1_RREADY;
  wire        M_AXI_JESD1_WVALID;
  wire [11:0] M_AXI_JESD1_ARID;
  wire [11:0] M_AXI_JESD1_AWID;
  wire [11:0] M_AXI_JESD1_WID;
  wire [31:0] M_AXI_JESD1_ARADDR;
  wire [31:0] M_AXI_JESD1_AWADDR;
  wire [31:0] M_AXI_JESD1_WDATA;
  wire [3:0]  M_AXI_JESD1_WSTRB;
  wire        M_AXI_JESD1_ARREADY;
  wire        M_AXI_JESD1_AWREADY;
  wire        M_AXI_JESD1_BVALID;
  wire        M_AXI_JESD1_RLAST;
  wire        M_AXI_JESD1_RVALID;
  wire        M_AXI_JESD1_WREADY;
  wire [1:0]  M_AXI_JESD1_BRESP;
  wire [1:0]  M_AXI_JESD1_RRESP;
  wire [31:0] M_AXI_JESD1_RDATA;

  // White Rabbit
  wire wr_uart_txd;
  wire wr_uart_rxd;
  wire pps_wr_refclk;
  wire wr_ref_clk;

  // AXI bus from PS to WR Core
  wire m_axi_wr_clk;
  wire [31:0] m_axi_wr_araddr;
  wire [0:0]  m_axi_wr_arready;
  wire [0:0]  m_axi_wr_arvalid;
  wire [31:0] m_axi_wr_awaddr;
  wire [0:0]  m_axi_wr_awready;
  wire [0:0]  m_axi_wr_awvalid;
  wire [0:0]  m_axi_wr_bready;
  wire [1:0]  m_axi_wr_bresp;
  wire [0:0]  m_axi_wr_bvalid;
  wire [31:0] m_axi_wr_rdata;
  wire [0:0]  m_axi_wr_rready;
  wire [1:0]  m_axi_wr_rresp;
  wire [0:0]  m_axi_wr_rvalid;
  wire [31:0] m_axi_wr_wdata;
  wire [0:0]  m_axi_wr_wready;
  wire [3:0]  m_axi_wr_wstrb;
  wire [0:0]  m_axi_wr_wvalid;

  wire [63:0] ps_gpio_out;
  wire [63:0] ps_gpio_in;
  wire [63:0] ps_gpio_tri;

  wire [15:0] IRQ_F2P;
  wire        FCLK_CLK0;
  wire        FCLK_CLK1;
  wire        FCLK_CLK2;
  wire        FCLK_CLK3;
  wire        clk100;
  wire        clk40;
  wire        meas_clk_ref;
  wire        bus_clk;
  wire        gige_refclk;
  wire        gige_refclk_bufg;
  wire        xgige_refclk;
  wire        xgige_clk156;
  wire        xgige_dclk;

  wire        global_rst;
  wire        radio_rst;
  wire        bus_rst;
  wire        FCLK_RESET0_N;
  wire        clk40_rst;
  wire        clk40_rstn;

  wire [1:0]  USB0_PORT_INDCTL;
  wire        USB0_VBUS_PWRSELECT;
  wire        USB0_VBUS_PWRFAULT;

  wire        ref_clk;
  wire        wr_refclk_buf;
  wire        netclk_buf;
  wire        meas_clk;
  wire        ddr3_dma_clk;
  wire        meas_clk_reset;
  wire        meas_clk_locked;
  wire        pps_radioclk1x_iob;
  wire        pps_radioclk1x;
  wire [3:0]  pps_select;
  wire        pps_out_enb;
  wire [1:0]  pps_select_sfp;
  wire        pps_refclk;
  wire        export_pps_radioclk;
  wire        radio_clk;
  wire        radio_clk_2x;

  /////////////////////////////////////////////////////////////////////
  //
  // Resets
  //
  //////////////////////////////////////////////////////////////////////

  // Global synchronous reset, on the bus_clk domain. De-asserts after 85
  // bus_clk cycles. Asserted by default.
  por_gen por_gen(.clk(bus_clk), .reset_out(global_rst));

  // Synchronous reset for the radio_clk domain, based on the global_rst.
  reset_sync radio_reset_gen (
    .clk(radio_clk),
    .reset_in(global_rst),
    .reset_out(radio_rst)
  );

  // Synchronous reset for the bus_clk domain, based on the global_rst.
  reset_sync bus_reset_gen (
    .clk(bus_clk),
    .reset_in(global_rst),
    .reset_out(bus_rst)
  );


  // PS-based Resets //
  //
  // Synchronous reset for the clk40 domain. This is derived from the PS reset 0.
  reset_sync clk40_reset_gen (
    .clk(clk40),
    .reset_in(~FCLK_RESET0_N),
    .reset_out(clk40_rst)
  );
  // Invert for various modules.
  assign clk40_rstn = ~clk40_rst;


  /////////////////////////////////////////////////////////////////////
  //
  // Timing
  //
  //////////////////////////////////////////////////////////////////////

  // Clocks from the PS
  //
  // These clocks appear to have BUFGs already instantiated by the ip generator.
  // Simply rename them here for clarity.
  //   FCLK_CLK0 :      100 MHz
  //   FCLK_CLK1 :       40 MHz
  //   FCLK_CLK2 : 166.6667 MHz
  //   FCLK_CLK3 :      200 MHz
  assign clk100       = FCLK_CLK0;
  assign clk40        = FCLK_CLK1;
  assign meas_clk_ref = FCLK_CLK2;
  assign bus_clk      = FCLK_CLK3;

  //If bus_clk freq ever changes, update this paramter accordingly.
  localparam BUS_CLK_RATE = 32'd200000000; //200 MHz bus_clk rate.

  n3xx_clocking n3xx_clocking_i (
    .FPGA_REFCLK_P(FPGA_REFCLK_P),
    .FPGA_REFCLK_N(FPGA_REFCLK_N),
    .ref_clk(ref_clk),
    .WB_20MHz_P(WB_20MHZ_P),
    .WB_20MHz_N(WB_20MHZ_N),
    .wr_refclk_buf(wr_refclk_buf),
    .NETCLK_REF_P(NETCLK_REF_P),
    .NETCLK_REF_N(NETCLK_REF_N),
    .netclk_buf(netclk_buf),
    .NETCLK_P(NETCLK_P),
    .NETCLK_N(NETCLK_N),
    .gige_refclk_buf(gige_refclk),
    .MGT156MHZ_CLK1_P(MGT156MHZ_CLK1_P),
    .MGT156MHZ_CLK1_N(MGT156MHZ_CLK1_N),
    .xgige_refclk_buf(xgige_refclk),
    .misc_clks_ref(meas_clk_ref),
    .meas_clk(meas_clk),
    .ddr3_dma_clk(ddr3_dma_clk),
    .misc_clks_reset(meas_clk_reset),
    .misc_clks_locked(meas_clk_locked),
    .ext_pps_from_pin(REF_1PPS_IN),
    .gps_pps_from_pin(GPS_1PPS),
    .pps_select(pps_select),
    .pps_refclk(pps_refclk)
  );

  // Drive the rear panel connector with another controllable copy of the post-TDC PPS
  // that SW can enable/disable. The user is free to hack this to be whatever
  // they desire. Flop the PPS signal one more time in order that it can be packed into
  // an IOB. This extra flop stage matches the additional flop inside DbCore to allow
  // pps_radioclk1x and pps_out_radioclk to be in sync with one another.
  synchronizer #(
    .FALSE_PATH_TO_IN(0)
  ) pps_export_dsync (
    .clk(radio_clk), .rst(1'b0), .in(pps_out_enb), .out(export_pps_radioclk)
  );

  // The radio_clk rate is between [122.88M, 250M] for all known N3xx variants,
  // resulting in approximately [8ns, 4ns] periods. To pulse-extend the PPS output,
  // we create a 25 bit-wide counter, creating ~[.262s, .131s] long output high pulses,
  // variable depending on our radio_clk rate. Create two of the same output signal
  // in order that the PPS_OUT gets packed into an IOB for tight timing.
  reg [24:0] pps_out_count = 'b0;
  reg        pps_out_radioclk = 1'b0;
  reg        pps_led_radioclk = 1'b0;

  always @(posedge radio_clk) begin
    if (export_pps_radioclk) begin
      if (pps_radioclk1x_iob) begin
        pps_out_radioclk <= 1'b1;
        pps_led_radioclk <= 1'b1;
        pps_out_count <= {25{1'b1}};
      end else begin
        if (pps_out_count > 0) begin
          pps_out_count <= pps_out_count - 1'b1;
        end else begin
          pps_out_radioclk <= 1'b0;
          pps_led_radioclk <= 1'b0;
        end
      end
    end else begin
      pps_out_radioclk <= 1'b0;
      pps_led_radioclk <= 1'b0;
    end
  end
  // Local to output.
  assign REF_1PPS_OUT  = pps_out_radioclk;
  assign PANEL_LED_PPS = pps_led_radioclk;

  /////////////////////////////////////////////////////////////////////
  //
  // SFP, QSFP and NPIO MGT Connections
  //
  //////////////////////////////////////////////////////////////////////
  wire                    reg_wr_req_npio;
  wire [REG_AWIDTH-1:0]   reg_wr_addr_npio;
  wire [REG_DWIDTH-1:0]   reg_wr_data_npio;
  wire                    reg_rd_req_npio;
  wire [REG_AWIDTH-1:0]   reg_rd_addr_npio;
  wire                    reg_rd_resp_npio, reg_rd_resp_npio0, reg_rd_resp_npio1, reg_rd_resp_qsfp;
  wire [REG_DWIDTH-1:0]   reg_rd_data_npio, reg_rd_data_npio0, reg_rd_data_npio1, reg_rd_data_qsfp;

  localparam NPIO_REG_BASE = 14'h0200;
  localparam QSFP_REG_BASE = 14'h0280;

  regport_resp_mux #(
    .WIDTH      (REG_DWIDTH),
    .NUM_SLAVES (3)
  ) npio_resp_mux_i(
    .clk(bus_clk), .reset(bus_rst),
    .sla_rd_resp({reg_rd_resp_npio0, reg_rd_resp_npio1, reg_rd_resp_qsfp}),
    .sla_rd_data({reg_rd_data_npio0, reg_rd_data_npio1, reg_rd_data_qsfp}),
    .mst_rd_resp(reg_rd_resp_npio), .mst_rd_data(reg_rd_data_npio)
  );

  //--------------------------------------------------------------
  // SFP/MGT Reference Clocks
  //--------------------------------------------------------------

  // We support the HG, XG, XA, AA targets, all of which require
  // the 156.25MHz reference clock. Instantiate it here.
  ten_gige_phy_clk_gen xgige_clk_gen_i (
    .refclk_ibuf(xgige_refclk),
    .clk156(xgige_clk156),
    .dclk(xgige_dclk)
  );

  wire qpllreset;
  wire qpllreset_sfp0, qpllreset_sfp1, qpllreset_npio0, qpllreset_npio1;
  wire qplllock;
  wire qplloutclk;
  wire qplloutrefclk;

  // We reuse this GT_COMMON wrapper for both ethernet and Aurora because
  // the behavior is identical
  ten_gig_eth_pcs_pma_gt_common # (
    .WRAPPER_SIM_GTRESET_SPEEDUP("TRUE") //Does not affect hardware
  ) ten_gig_eth_pcs_pma_gt_common_block (
    .refclk(xgige_refclk),
    .qpllreset(qpllreset), //from 2nd sfp
    .qplllock(qplllock),
    .qplloutclk(qplloutclk),
    .qplloutrefclk(qplloutrefclk),
    .qpllrefclksel(3'b101 /*GTSOUTHREFCLK0*/)
  );

  // The quad's QPLL should reset if any of the channels request it
  // This should never really happen because we are not changing the reference clock
  // source for the QPLL.
  assign qpllreset = qpllreset_sfp0 | qpllreset_sfp1 | qpllreset_npio0 | qpllreset_npio1;

  // Use the 156.25MHz reference clock for Aurora
  wire aurora_refclk = xgige_refclk;
  wire aurora_clk156 = xgige_clk156;
  wire aurora_init_clk = xgige_dclk;

  // White Rabbit and 1GbE both use the same clocking
`ifdef SFP0_1GBE
  `define SFP0_WR_1GBE
`endif
`ifdef SFP0_WR
  `define SFP0_WR_1GBE
`endif

`ifdef SFP0_WR_1GBE
  // HG and WX targets require the 1GbE clock support
  BUFG bufg_gige_refclk_i (
    .I(gige_refclk),
    .O(gige_refclk_bufg)
  );
  assign SFP_0_RS0  = 1'b0;
  assign SFP_0_RS1  = 1'b0;
`else
  assign SFP_0_RS0  = 1'b1;
  assign SFP_0_RS1  = 1'b1;
`endif

  // SFP 1 is always set to run at ~10Gbps rates.
  assign SFP_1_RS0  = 1'b1;
  assign SFP_1_RS1  = 1'b1;

  // SFP port specific reference clocks
  wire  sfp0_gt_refclk, sfp1_gt_refclk;
  wire  sfp0_gb_refclk, sfp1_gb_refclk;
  wire  sfp0_misc_clk, sfp1_misc_clk;

`ifdef SFP0_10GBE
  assign sfp0_gt_refclk = xgige_refclk;
  assign sfp0_gb_refclk = xgige_clk156;
  assign sfp0_misc_clk  = xgige_dclk;
`endif
`ifdef SFP0_WR_1GBE
  assign sfp0_gt_refclk = gige_refclk;
  assign sfp0_gb_refclk = gige_refclk_bufg;
  assign sfp0_misc_clk  = gige_refclk_bufg;
`endif
`ifdef SFP0_AURORA
  assign sfp0_gt_refclk = aurora_refclk;
  assign sfp0_gb_refclk = aurora_clk156;
  assign sfp0_misc_clk  = aurora_init_clk;
`endif

`ifdef SFP1_10GBE
  assign sfp1_gt_refclk = xgige_refclk;
  assign sfp1_gb_refclk = xgige_clk156;
  assign sfp1_misc_clk  = xgige_dclk;
`endif
`ifdef SFP1_1GBE
  assign sfp1_gt_refclk = gige_refclk;
  assign sfp1_gb_refclk = gige_refclk_bufg;
  assign sfp1_misc_clk  = gige_refclk_bufg;
`endif
`ifdef SFP1_AURORA
  assign sfp1_gt_refclk = aurora_refclk;
  assign sfp1_gb_refclk = aurora_clk156;
  assign sfp1_misc_clk  = aurora_init_clk;
`endif

  // Instantiate Aurora MMCM if either of the SFPs
  // or NPIOs are Aurora
  wire au_tx_clk;
  wire au_mmcm_reset;
  wire au_user_clk;
  wire au_sync_clk;
  wire au_mmcm_locked;
  wire sfp0_tx_out_clk, sfp1_tx_out_clk;
  wire sfp0_gt_pll_lock, sfp1_gt_pll_lock;
  wire npio0_tx_out_clk, npio1_tx_out_clk;
  wire npio0_gt_pll_lock, npio1_gt_pll_lock;

  //NOTE: need to declare one of these defines in order to enable Aurora on
  //any SFP or NPIO lane. 
`ifdef SFP1_AURORA
  `define SFP_AU_MMCM
  assign au_tx_clk     = sfp1_tx_out_clk;
  assign au_mmcm_reset = ~sfp1_gt_pll_lock;
`elsif NPIO0
  `define SFP_AU_MMCM
  assign au_tx_clk     = npio0_tx_out_clk;
  assign au_mmcm_reset = ~npio0_gt_pll_lock;
`elsif NPIO1
  `define SFP_AU_MMCM
  assign au_tx_clk     = npio1_tx_out_clk;
  assign au_mmcm_reset = ~npio1_gt_pll_lock;
`endif


`ifdef SFP_AU_MMCM
  aurora_phy_mmcm au_phy_mmcm_i (
    .aurora_tx_clk_unbuf(au_tx_clk),
    .mmcm_reset(au_mmcm_reset),
    .user_clk(au_user_clk),
    .sync_clk(au_sync_clk),
    .mmcm_locked(au_mmcm_locked)
  );
`else
  assign au_user_clk = 1'b0;
  assign au_sync_clk = 1'b0;
  assign au_mmcm_locked = 1'b0;
`endif

  //--------------------------------------------------------------
  // NPIO-QSFP MGT Lanes (Example loopback config)
  //--------------------------------------------------------------

`ifdef QSFP_LANES

  localparam NUM_QSFP_LANES = `QSFP_LANES;

  wire [(NUM_QSFP_LANES*64)-1:0] qsfp_loopback_tdata;
  wire [NUM_QSFP_LANES-1:0]      qsfp_loopback_tlast;
  wire [NUM_QSFP_LANES-1:0]      qsfp_loopback_tvalid;
  wire [NUM_QSFP_LANES-1:0]      qsfp_loopback_tready;

  n3xx_npio_qsfp_wrapper #(
    .LANES          (NUM_QSFP_LANES),
    .REG_BASE       (QSFP_REG_BASE),
    .PORTNUM_BASE   (4),
    .REG_DWIDTH     (REG_DWIDTH),
    .REG_AWIDTH     (REG_AWIDTH)
  ) qsfp_wrapper_i (
    .areset         (global_rst),
    .bus_clk        (bus_clk),
    .bus_rst        (bus_rst),
    .gt_refclk      (aurora_refclk),
    .gt_clk156      (aurora_clk156),
    .misc_clk       (aurora_init_clk),
    //.txp            ({QSFP_TX3_P, QSFP_TX2_P, QSFP_TX1_P, QSFP_TX0_P}),
    //.txn            ({QSFP_TX3_N, QSFP_TX2_N, QSFP_TX1_N, QSFP_TX0_N}),
    //.rxp            ({QSFP_RX3_P, QSFP_RX2_P, QSFP_RX1_P, QSFP_RX0_P}),
    //.rxn            ({QSFP_RX3_N, QSFP_RX2_N, QSFP_RX1_N, QSFP_RX0_N}),
    .txp            ({QSFP_TX0_P}),
    .txn            ({QSFP_TX0_N}),
    .rxp            ({QSFP_RX0_P}),
    .rxn            ({QSFP_RX0_N}),
    .s_axis_tdata   (qsfp_loopback_tdata),
    .s_axis_tlast   (qsfp_loopback_tlast),
    .s_axis_tvalid  (qsfp_loopback_tvalid),
    .s_axis_tready  (qsfp_loopback_tready),
    .m_axis_tdata   (qsfp_loopback_tdata),
    .m_axis_tlast   (qsfp_loopback_tlast),
    .m_axis_tvalid  (qsfp_loopback_tvalid),
    .m_axis_tready  (qsfp_loopback_tready),
    .reg_wr_req     (reg_wr_req_npio),
    .reg_wr_addr    (reg_wr_addr_npio),
    .reg_wr_data    (reg_wr_data_npio),
    .reg_rd_req     (reg_rd_req_npio),
    .reg_rd_addr    (reg_rd_addr_npio),
    .reg_rd_resp    (reg_rd_resp_qsfp),
    .reg_rd_data    (reg_rd_data_qsfp),
    .link_up        (),
    .activity       ()
  );

`else

  assign reg_rd_resp_qsfp = 1'b0;
  assign reg_rd_data_qsfp = 'h0;

`endif

  //--------------------------------------------------------------
  // NPIO MGT Lanes (Example loopback config)
  //--------------------------------------------------------------

`ifdef NPIO_LANES

  wire [127:0]  npio_loopback_tdata;
  wire [1:0]    npio_loopback_tvalid;
  wire [1:0]    npio_loopback_tready;
  wire [1:0]    npio_loopback_tlast;

  //EISCAT wires to/from radio core
  wire [63:0]  npio2eiscat_tdata;
  wire         npio2eiscat_tvalid;
  wire         npio2eiscat_tready;
  wire         npio2eiscat_tlast;
  wire [63:0]  eiscat2npio_tdata;
  wire         eiscat2npio_tvalid;
  wire         eiscat2npio_tready;
  wire         eiscat2npio_tlast;

  n3xx_mgt_io_core #(
    .PROTOCOL       ("Aurora"),
    .REG_BASE       (NPIO_REG_BASE + 14'h00),
    .REG_DWIDTH     (REG_DWIDTH),         // Width of the AXI4-Lite data bus (must be 32 or 64)
    .REG_AWIDTH     (REG_AWIDTH),         // Width of the address bus
    .PORTNUM        (8'd2),
    .MDIO_EN        (0)
  ) npio_ln_0_i (
    .areset         (global_rst),
    .gt_refclk      (aurora_refclk),
    .gb_refclk      (aurora_clk156),
    .misc_clk       (aurora_init_clk),
    .user_clk       (au_user_clk),
    .sync_clk       (au_sync_clk),
    .gt_tx_out_clk_unbuf(npio0_tx_out_clk),

    .bus_clk        (bus_clk),//clk for status reg reads to mdio interface
    .bus_rst        (bus_rst),
    .qpllreset      (qpllreset_npio0),
    .qplloutclk     (qplloutclk),
    .qplloutrefclk  (qplloutrefclk),
    .qplllock       (qplllock),
    .qpllrefclklost (),

    .rxp            (NPIO_RX0_P),
    .rxn            (NPIO_RX0_N),
    .txp            (NPIO_TX0_P),
    .txn            (NPIO_TX0_N),

    .sfpp_rxlos     (1'b0),
    .sfpp_tx_fault  (1'b0),

    //RegPort
    .reg_wr_req     (reg_wr_req_npio),
    .reg_wr_addr    (reg_wr_addr_npio),
    .reg_wr_data    (reg_wr_data_npio),
    .reg_rd_req     (reg_rd_req_npio),
    .reg_rd_addr    (reg_rd_addr_npio),
    .reg_rd_resp    (reg_rd_resp_npio0),
    .reg_rd_data    (reg_rd_data_npio0),

    //DATA (loopback mode)
    .s_axis_tdata   (eiscat2npio_tdata), //Data to aurora core
    .s_axis_tuser   (4'b0),
    .s_axis_tvalid  (eiscat2npio_tvalid),
    .s_axis_tlast   (eiscat2npio_tlast),
    .s_axis_tready  (eiscat2npio_tready),
    .m_axis_tdata   (npio2eiscat_tdata), //Data from aurora core
    .m_axis_tuser   (),
    .m_axis_tvalid  (npio2eiscat_tvalid),
    .m_axis_tlast   (npio2eiscat_tlast),
    .m_axis_tready  (npio2eiscat_tready),

    .mmcm_locked    (au_mmcm_locked),
    .gt_pll_lock    (npio0_gt_pll_lock)
  );

`else

  assign reg_rd_resp_npio0 = 1'b0;
  assign reg_rd_data_npio0 = 'h0;
  assign reg_rd_resp_npio1 = 1'b0;
  assign reg_rd_data_npio1 = 'h0;
  assign npio0_gt_pll_lock = 1'b1;
  assign npio1_gt_pll_lock = 1'b1;
  assign qpllreset_npio0   = 1'b0;
  assign qpllreset_npio1   = 1'b0;

`endif


  // ARM ethernet 0 bridge signals
  wire [63:0] arm_eth0_tx_tdata;
  wire        arm_eth0_tx_tvalid;
  wire        arm_eth0_tx_tlast;
  wire        arm_eth0_tx_tready;
  wire [3:0]  arm_eth0_tx_tuser;
  wire [7:0]  arm_eth0_tx_tkeep;

  wire [63:0] arm_eth0_tx_tdata_b;
  wire        arm_eth0_tx_tvalid_b;
  wire        arm_eth0_tx_tlast_b;
  wire        arm_eth0_tx_tready_b;
  wire [3:0]  arm_eth0_tx_tuser_b;
  wire [7:0]  arm_eth0_tx_tkeep_b;

  wire [63:0] arm_eth0_rx_tdata;
  wire        arm_eth0_rx_tvalid;
  wire        arm_eth0_rx_tlast;
  wire        arm_eth0_rx_tready;
  wire [3:0]  arm_eth0_rx_tuser;
  wire [7:0]  arm_eth0_rx_tkeep;

  wire [63:0] arm_eth0_rx_tdata_b;
  wire        arm_eth0_rx_tvalid_b;
  wire        arm_eth0_rx_tlast_b;
  wire        arm_eth0_rx_tready_b;
  wire [3:0]  arm_eth0_rx_tuser_b;
  wire [7:0]  arm_eth0_rx_tkeep_b;

  wire        arm_eth0_rx_irq;
  wire        arm_eth0_tx_irq;

  // ARM ethernet 1 bridge signals
  wire [63:0] arm_eth1_tx_tdata;
  wire        arm_eth1_tx_tvalid;
  wire        arm_eth1_tx_tlast;
  wire        arm_eth1_tx_tready;
  wire [3:0]  arm_eth1_tx_tuser;
  wire [7:0]  arm_eth1_tx_tkeep;

  wire [63:0] arm_eth1_tx_tdata_b;
  wire        arm_eth1_tx_tvalid_b;
  wire        arm_eth1_tx_tlast_b;
  wire        arm_eth1_tx_tready_b;
  wire [3:0]  arm_eth1_tx_tuser_b;
  wire [7:0]  arm_eth1_tx_tkeep_b;

  wire [63:0] arm_eth1_rx_tdata;
  wire        arm_eth1_rx_tvalid;
  wire        arm_eth1_rx_tlast;
  wire        arm_eth1_rx_tready;
  wire [3:0]  arm_eth1_rx_tuser;
  wire [7:0]  arm_eth1_rx_tkeep;

  wire [63:0] arm_eth1_rx_tdata_b;
  wire        arm_eth1_rx_tvalid_b;
  wire        arm_eth1_rx_tlast_b;
  wire        arm_eth1_rx_tready_b;
  wire [3:0]  arm_eth1_rx_tuser_b;
  wire [7:0]  arm_eth1_rx_tkeep_b;

  wire        arm_eth1_tx_irq;
  wire        arm_eth1_rx_irq;

  // Vita to Ethernet
  wire  [63:0]  v2e0_tdata;
  wire          v2e0_tlast;
  wire          v2e0_tvalid;
  wire          v2e0_tready;

  wire  [63:0]  v2e1_tdata;
  wire          v2e1_tlast;
  wire          v2e1_tvalid;
  wire          v2e1_tready;

  // Ethernet to Vita
  wire  [63:0]  e2v0_tdata;
  wire          e2v0_tlast;
  wire          e2v0_tvalid;
  wire          e2v0_tready;

  wire  [63:0]  e2v1_tdata;
  wire          e2v1_tlast;
  wire          e2v1_tvalid;
  wire          e2v1_tready;

  // Ethernet crossover
  wire  [63:0]  e01_tdata, e10_tdata;
  wire  [3:0]   e01_tuser, e10_tuser;
  wire          e01_tlast, e01_tvalid, e01_tready;
  wire          e10_tlast, e10_tvalid, e10_tready;

  // ARM DMA
  wire [63:0] o_cvita_dma_tdata;
  wire        o_cvita_dma_tlast;
  wire        o_cvita_dma_tready;
  wire        o_cvita_dma_tvalid;

  wire [63:0] i_cvita_dma_tdata;
  wire        i_cvita_dma_tlast;
  wire        i_cvita_dma_tready;
  wire        i_cvita_dma_tvalid;

  // Misc
  wire [31:0] sfp_port0_info;
  wire [31:0] sfp_port1_info;

  /////////////////////////////////////////////////////////////////////
  //
  // SFP Wrapper 0: Network Interface (1/10G or Aurora)
  //
  //////////////////////////////////////////////////////////////////////

  n3xx_mgt_channel_wrapper #(
    .LANES(1),
  `ifdef SFP0_10GBE
    .PROTOCOL("10GbE"),
    .MDIO_EN(1'b1),
    .MDIO_PHYADDR(5'd4), // PHYADDR must match the "reg" property for PHY in DTS file
  `elsif SFP0_AURORA
    .PROTOCOL("Aurora"),
    .MDIO_EN(1'b0),
  `elsif SFP0_1GBE
    .PROTOCOL("1GbE"),
    .MDIO_EN(1'b1),
    .MDIO_PHYADDR(5'd4), // PHYADDR must match the "reg" property for PHY in DTS file
  `elsif SFP0_WR
    .PROTOCOL("WhiteRabbit"),
    .MDIO_EN(1'b0),
  `endif
    .REG_DWIDTH(REG_DWIDTH), // Width of the AXI4-Lite data bus (must be 32 or 64)
    .REG_AWIDTH(REG_AWIDTH), // Width of the address bus
    .PORTNUM_BASE(8'd0)
   ) sfp_wrapper_0 (
     .areset(global_rst),
     .gt_refclk(sfp0_gt_refclk),
     .gb_refclk(sfp0_gb_refclk),
     .misc_clk(sfp0_misc_clk),
     .user_clk(au_user_clk),
     .sync_clk(au_sync_clk),
     .gt_tx_out_clk_unbuf(sfp0_tx_out_clk),

     .bus_rst(bus_rst),
     .bus_clk(bus_clk),

     .qpllreset(qpllreset_sfp0),
     .qplllock(qplllock),
     .qplloutclk(qplloutclk),
     .qplloutrefclk(qplloutrefclk),
     .qpllrefclklost(),

     .mmcm_locked(au_mmcm_locked),
     .gt_pll_lock(sfp0_gt_pll_lock),

     .txp(SFP_0_TX_P),
     .txn(SFP_0_TX_N),
     .rxp(SFP_0_RX_P),
     .rxn(SFP_0_RX_N),

     .mod_present_n(SFP_0_I2C_NPRESENT),
     .mod_rxlos(SFP_0_LOS),
     .mod_tx_fault(SFP_0_TXFAULT),
     .mod_tx_disable(SFP_0_TXDISABLE),

     // Clock and reset
     .s_axi_aclk(clk40),
     .s_axi_aresetn(clk40_rstn),
     // AXI4-Lite: Write address port (domain: s_axi_aclk)
     .s_axi_awaddr(M_AXI_NET0_AWADDR[REG_AWIDTH-1:0]),
     .s_axi_awvalid(M_AXI_NET0_AWVALID),
     .s_axi_awready(M_AXI_NET0_AWREADY),
     // AXI4-Lite: Write data port (domain: s_axi_aclk)
     .s_axi_wdata(M_AXI_NET0_WDATA),
     .s_axi_wstrb(M_AXI_NET0_WSTRB),
     .s_axi_wvalid(M_AXI_NET0_WVALID),
     .s_axi_wready(M_AXI_NET0_WREADY),
     // AXI4-Lite: Write response port (domain: s_axi_aclk)
     .s_axi_bresp(M_AXI_NET0_BRESP),
     .s_axi_bvalid(M_AXI_NET0_BVALID),
     .s_axi_bready(M_AXI_NET0_BREADY),
     // AXI4-Lite: Read address port (domain: s_axi_aclk)
     .s_axi_araddr(M_AXI_NET0_ARADDR[REG_AWIDTH-1:0]),
     .s_axi_arvalid(M_AXI_NET0_ARVALID),
     .s_axi_arready(M_AXI_NET0_ARREADY),
     // AXI4-Lite: Read data port (domain: s_axi_aclk)
     .s_axi_rdata(M_AXI_NET0_RDATA),
     .s_axi_rresp(M_AXI_NET0_RRESP),
     .s_axi_rvalid(M_AXI_NET0_RVALID),
     .s_axi_rready(M_AXI_NET0_RREADY),

     // Ethernet to Vita
     .e2v_tdata(e2v0_tdata),
     .e2v_tlast(e2v0_tlast),
     .e2v_tvalid(e2v0_tvalid),
     .e2v_tready(e2v0_tready),

     // Vita to Ethernet
     .v2e_tdata(v2e0_tdata),
     .v2e_tlast(v2e0_tlast),
     .v2e_tvalid(v2e0_tvalid),
     .v2e_tready(v2e0_tready),

     // Crossover
     .xo_tdata(e01_tdata),
     .xo_tuser(e01_tuser),
     .xo_tlast(e01_tlast),
     .xo_tvalid(e01_tvalid),
     .xo_tready(e01_tready),
     .xi_tdata(e10_tdata),
     .xi_tuser(e10_tuser),
     .xi_tlast(e10_tlast),
     .xi_tvalid(e10_tvalid),
     .xi_tready(e10_tready),

     // Ethernet to CPU
     .e2c_tdata(arm_eth0_rx_tdata_b),
     .e2c_tkeep(arm_eth0_rx_tkeep_b),
     .e2c_tlast(arm_eth0_rx_tlast_b),
     .e2c_tvalid(arm_eth0_rx_tvalid_b),
     .e2c_tready(arm_eth0_rx_tready_b),

     // CPU to Ethernet
     .c2e_tdata(arm_eth0_tx_tdata_b),
     .c2e_tkeep(arm_eth0_tx_tkeep_b),
     .c2e_tlast(arm_eth0_tx_tlast_b),
     .c2e_tvalid(arm_eth0_tx_tvalid_b),
     .c2e_tready(arm_eth0_tx_tready_b),

      // White Rabbit Specific
`ifdef SFP0_WR
     .wr_reset_n   (~ps_gpio_out[48]), // reset for WR only
     .wr_refclk    (wr_refclk_buf),
     .wr_dac_sclk  (WB_DAC_SCLK),
     .wr_dac_din   (WB_DAC_DIN),
     .wr_dac_clr_n (WB_DAC_NCLR),
     .wr_dac_cs_n  (WB_DAC_NSYNC),
     .wr_dac_ldac_n(WB_DAC_NLDAC),
     .wr_eeprom_scl_o(), // storage for delay characterization
     .wr_eeprom_scl_i(1'b0), // temp
     .wr_eeprom_sda_o(),
     .wr_eeprom_sda_i(1'b0), // temp
     .wr_uart_rx(wr_uart_rxd), // to/from PS
     .wr_uart_tx(wr_uart_txd),
     .mod_pps(pps_wr_refclk), // out, reference clock and pps
     .mod_refclk(wr_ref_clk),
     // WR Slave Port to PS
     .wr_axi_aclk(m_axi_wr_clk), // out to PS
     .wr_axi_aresetn(1'b1), // in
     .wr_axi_awaddr(m_axi_wr_awaddr),
     .wr_axi_awvalid(m_axi_wr_awvalid),
     .wr_axi_awready(m_axi_wr_awready),
     .wr_axi_wdata(m_axi_wr_wdata),
     .wr_axi_wstrb(m_axi_wr_wstrb),
     .wr_axi_wvalid(m_axi_wr_wvalid),
     .wr_axi_wready(m_axi_wr_wready),
     .wr_axi_bresp(m_axi_wr_bresp),
     .wr_axi_bvalid(m_axi_wr_bvalid),
     .wr_axi_bready(m_axi_wr_bready),
     .wr_axi_araddr(m_axi_wr_araddr),
     .wr_axi_arvalid(m_axi_wr_arvalid),
     .wr_axi_arready(m_axi_wr_arready),
     .wr_axi_rdata(m_axi_wr_rdata),
     .wr_axi_rresp(m_axi_wr_rresp),
     .wr_axi_rvalid(m_axi_wr_rvalid),
     .wr_axi_rready(m_axi_wr_rready),
     .wr_axi_rlast(),
`else
     .wr_reset_n(1'b1),
     .wr_refclk(1'b0),
     .wr_eeprom_scl_i(1'b0),
     .wr_eeprom_sda_i(1'b0),
     .wr_uart_rx(1'b0),
`endif

     // Misc
     .port_info(sfp_port0_info),

     // LED
     .link_up(SFP_0_LED_B),
     .activity(SFP_0_LED_A)
   );

`ifndef SFP0_WR
  assign WB_DAC_SCLK  = 1'b0;
  assign WB_DAC_DIN   = 1'b0;
  assign WB_DAC_NCLR  = 1'b1;
  assign WB_DAC_NSYNC = 1'b1;
  assign WB_DAC_NLDAC = 1'b1;
  assign pps_wr_refclk = 1'b0;
  assign wr_ref_clk = 1'b0;
`endif


   /////////////////////////////////////////////////////////////////////
   //
   // SFP Wrapper 1: Network Interface (1/10G or Aurora)
   //
   //////////////////////////////////////////////////////////////////////

   n3xx_mgt_channel_wrapper #(
    .LANES(1),
  `ifdef SFP1_10GBE
    .PROTOCOL("10GbE"),
    .MDIO_EN(1'b1),
    .MDIO_PHYADDR(5'd4), // PHYADDR must match the "reg" property for PHY in DTS file
  `elsif SFP1_AURORA
    .PROTOCOL("Aurora"),
    .MDIO_EN(1'b0),
  `endif
    .REG_DWIDTH(REG_DWIDTH),     // Width of the AXI4-Lite data bus (must be 32 or 64)
    .REG_AWIDTH(REG_AWIDTH),     // Width of the address bus
    .PORTNUM_BASE(8'd1)
   ) sfp_wrapper_1 (
     .areset(global_rst),

     .gt_refclk(sfp1_gt_refclk),
     .gb_refclk(sfp1_gb_refclk),
     .misc_clk(sfp1_misc_clk),
     .user_clk(au_user_clk),
     .sync_clk(au_sync_clk),
     .gt_tx_out_clk_unbuf(sfp1_tx_out_clk),

     .bus_rst(bus_rst),
     .bus_clk(bus_clk),

     .qpllreset(qpllreset_sfp1),
     .qplllock(qplllock),
     .qplloutclk(qplloutclk),
     .qplloutrefclk(qplloutrefclk),
     .qpllrefclklost(),

     .mmcm_locked(au_mmcm_locked),
     .gt_pll_lock(sfp1_gt_pll_lock),

     .txp(SFP_1_TX_P),
     .txn(SFP_1_TX_N),
     .rxp(SFP_1_RX_P),
     .rxn(SFP_1_RX_N),

     .mod_rxlos(SFP_1_LOS),
     .mod_tx_fault(SFP_1_TXFAULT),
     .mod_tx_disable(SFP_1_TXDISABLE),

     // Clock and reset
     .s_axi_aclk(clk40),
     .s_axi_aresetn(clk40_rstn),
     // AXI4-Lite: Write address port (domain: s_axi_aclk)
     .s_axi_awaddr(M_AXI_NET1_AWADDR[REG_AWIDTH-1:0]),
     .s_axi_awvalid(M_AXI_NET1_AWVALID),
     .s_axi_awready(M_AXI_NET1_AWREADY),
     // AXI4-Lite: Write data port (domain: s_axi_aclk)
     .s_axi_wdata(M_AXI_NET1_WDATA),
     .s_axi_wstrb(M_AXI_NET1_WSTRB),
     .s_axi_wvalid(M_AXI_NET1_WVALID),
     .s_axi_wready(M_AXI_NET1_WREADY),
     // AXI4-Lite: Write response port (domain: s_axi_aclk)
     .s_axi_bresp(M_AXI_NET1_BRESP),
     .s_axi_bvalid(M_AXI_NET1_BVALID),
     .s_axi_bready(M_AXI_NET1_BREADY),
     // AXI4-Lite: Read address port (domain: s_axi_aclk)
     .s_axi_araddr(M_AXI_NET1_ARADDR[REG_AWIDTH-1:0]),
     .s_axi_arvalid(M_AXI_NET1_ARVALID),
     .s_axi_arready(M_AXI_NET1_ARREADY),
     // AXI4-Lite: Read data port (domain: s_axi_aclk)
     .s_axi_rdata(M_AXI_NET1_RDATA),
     .s_axi_rresp(M_AXI_NET1_RRESP),
     .s_axi_rvalid(M_AXI_NET1_RVALID),
     .s_axi_rready(M_AXI_NET1_RREADY),

     // Ethernet to Vita
     .e2v_tdata(e2v1_tdata),
     .e2v_tlast(e2v1_tlast),
     .e2v_tvalid(e2v1_tvalid),
     .e2v_tready(e2v1_tready),

     // Vita to Ethernet
     .v2e_tdata(v2e1_tdata),
     .v2e_tlast(v2e1_tlast),
     .v2e_tvalid(v2e1_tvalid),
     .v2e_tready(v2e1_tready),

     // Crossover
     .xo_tdata(e10_tdata),
     .xo_tuser(e10_tuser),
     .xo_tlast(e10_tlast),
     .xo_tvalid(e10_tvalid),
     .xo_tready(e10_tready),
     .xi_tdata(e01_tdata),
     .xi_tuser(e01_tuser),
     .xi_tlast(e01_tlast),
     .xi_tvalid(e01_tvalid),
     .xi_tready(e01_tready),

     // Ethernet to CPU
     .e2c_tdata(arm_eth1_rx_tdata_b),
     .e2c_tkeep(arm_eth1_rx_tkeep_b),
     .e2c_tlast(arm_eth1_rx_tlast_b),
     .e2c_tvalid(arm_eth1_rx_tvalid_b),
     .e2c_tready(arm_eth1_rx_tready_b),

     // CPU to Ethernet
     .c2e_tdata(arm_eth1_tx_tdata_b),
     .c2e_tkeep(arm_eth1_tx_tkeep_b),
     .c2e_tlast(arm_eth1_tx_tlast_b),
     .c2e_tvalid(arm_eth1_tx_tvalid_b),
     .c2e_tready(arm_eth1_tx_tready_b),

     // Misc
     .port_info(sfp_port1_info),

     // LED
     .link_up(SFP_1_LED_B),
     .activity(SFP_1_LED_A)
   );

  /////////////////////////////////////////////////////////////////////
  //
  // Ethernet DMA 0
  //
  //////////////////////////////////////////////////////////////////////

  assign  IRQ_F2P[0] = arm_eth0_rx_irq;
  assign  IRQ_F2P[1] = arm_eth0_tx_irq;

  assign {S_AXI_HP0_AWID, S_AXI_HP0_ARID} = 12'd0;
  assign {S_AXI_GP0_AWID, S_AXI_GP0_ARID} = 10'd0;

`ifdef SFP0_AURORA
  `define NO_ETH_DMA_0
`elsif SFP0_WR
  `define NO_ETH_DMA_0
`endif

`ifdef NO_ETH_DMA_0
  //If inst Aurora, tie off each axi/axi-lite interface
  axi_dummy #(
    .DEC_ERR(1'b0)
  ) inst_axi_dummy_sfp0_eth_dma (
    .s_axi_aclk(bus_clk),
    .s_axi_areset(bus_rst),

    .s_axi_awaddr(M_AXI_ETH_DMA0_AWADDR),
    .s_axi_awvalid(M_AXI_ETH_DMA0_AWVALID),
    .s_axi_awready(M_AXI_ETH_DMA0_AWREADY),

    .s_axi_wdata(M_AXI_ETH_DMA0_WDATA),
    .s_axi_wvalid(M_AXI_ETH_DMA0_WVALID),
    .s_axi_wready(M_AXI_ETH_DMA0_WREADY),

    .s_axi_bresp(M_AXI_ETH_DMA0_BRESP),
    .s_axi_bvalid(M_AXI_ETH_DMA0_BVALID),
    .s_axi_bready(M_AXI_ETH_DMA0_BREADY),

    .s_axi_araddr(M_AXI_ETH_DMA0_ARADDR),
    .s_axi_arvalid(M_AXI_ETH_DMA0_ARVALID),
    .s_axi_arready(M_AXI_ETH_DMA0_ARREADY),

    .s_axi_rdata(M_AXI_ETH_DMA0_RDATA),
    .s_axi_rresp(M_AXI_ETH_DMA0_RRESP),
    .s_axi_rvalid(M_AXI_ETH_DMA0_RVALID),
    .s_axi_rready(M_AXI_ETH_DMA0_RREADY)

  );
  //S_AXI_GP0 outputs from axi_eth_dma, so needs some sort of controller/tie off
  assign S_AXI_GP0_AWADDR = 32'h0;
  assign S_AXI_GP0_AWLEN = 8'h0;
  assign S_AXI_GP0_AWSIZE = 4'h0;
  assign S_AXI_GP0_AWBURST = 3'h0;
  assign S_AXI_GP0_AWPROT = 3'h0;
  assign S_AXI_GP0_AWCACHE = 4'h0;
  assign S_AXI_GP0_AWVALID = 1'b0;
  //S_AXI_GP0_AWREADY output from PS
  assign S_AXI_GP0_WDATA = 32'h0;
  assign S_AXI_GP0_WSTRB = 4'h0;
  assign S_AXI_GP0_WLAST = 1'b0;
  assign S_AXI_GP0_WVALID = 1'b0;
  //S_AXI_GP0_WREADY output from PS
  //S_AXI_GP0_BRESP
  //S_AXI_GP0_BVALID
  assign S_AXI_GP0_BREADY = 1'b1;
  assign S_AXI_GP0_ARADDR = 32'h0;
  assign S_AXI_GP0_ARLEN = 8'h0;
  assign S_AXI_GP0_ARSIZE = 3'h0;
  assign S_AXI_GP0_ARBURST = 2'h0;
  assign S_AXI_GP0_ARPROT = 3'h0;
  assign S_AXI_GP0_ARCACHE = 4'h0;
  assign S_AXI_GP0_ARVALID = 1'b0;
  //S_AXI_GP0_ARREADY
  //S_AXI_GP0_RDATA
  //S_AXI_GP0_RRESP
  //S_AXI_GP0_RLAST
  //S_AXI_GP0_RVALID
  assign S_AXI_GP0_RREADY = 1'b1;

  //S_AXI_HP0 from axi_eth_dma
  assign S_AXI_HP0_ARADDR = 32'h0;
  assign S_AXI_HP0_ARLEN = 8'h0;
  assign S_AXI_HP0_ARSIZE = 3'h0;
  assign S_AXI_HP0_ARBURST = 2'h0;
  assign S_AXI_HP0_ARPROT = 3'h0;
  assign S_AXI_HP0_ARCACHE = 4'h0;
  assign S_AXI_HP0_ARVALID = 1'b0;
  //S_AXI_HP0_ARREADY
  //S_AXI_HP0_RDATA
  //S_AXI_HP0_RRESP
  //S_AXI_HP0_RLAST
  //S_AXI_HP0_RVALID
  assign S_AXI_HP0_RREADY = 1'b1;
  assign S_AXI_HP0_AWADDR = 32'h0;
  assign S_AXI_HP0_AWLEN = 8'h0;
  assign S_AXI_HP0_AWSIZE = 3'h0;
  assign S_AXI_HP0_AWBURST = 2'h0;
  assign S_AXI_HP0_AWPROT = 3'h0;
  assign S_AXI_HP0_AWCACHE = 4'h0;
  assign S_AXI_HP0_AWVALID = 1'b0;
  //S_AXI_HP0_AWREADY
  assign S_AXI_HP0_WDATA = 64'h0;
  assign S_AXI_HP0_WSTRB = 8'h0;
  assign S_AXI_HP0_WLAST = 1'b0;
  assign S_AXI_HP0_WVALID = 1'b0;
  //S_AXI_HP0_WREADY
  //S_AXI_HP0_BRESP
  //S_AXI_HP0_BVALID
  assign S_AXI_HP0_BREADY = 1'b1;

`else

  axi_eth_dma inst_axi_eth_dma0 (
    .s_axi_lite_aclk(clk40),
    .m_axi_sg_aclk(clk40),
    .m_axi_mm2s_aclk(clk40),
    .m_axi_s2mm_aclk(clk40),
    .axi_resetn(clk40_rstn),

    .s_axi_lite_awaddr(M_AXI_ETH_DMA0_AWADDR),
    .s_axi_lite_awvalid(M_AXI_ETH_DMA0_AWVALID),
    .s_axi_lite_awready(M_AXI_ETH_DMA0_AWREADY),

    .s_axi_lite_wdata(M_AXI_ETH_DMA0_WDATA),
    .s_axi_lite_wvalid(M_AXI_ETH_DMA0_WVALID),
    .s_axi_lite_wready(M_AXI_ETH_DMA0_WREADY),

    .s_axi_lite_bresp(M_AXI_ETH_DMA0_BRESP),
    .s_axi_lite_bvalid(M_AXI_ETH_DMA0_BVALID),
    .s_axi_lite_bready(M_AXI_ETH_DMA0_BREADY),

    .s_axi_lite_araddr(M_AXI_ETH_DMA0_ARADDR),
    .s_axi_lite_arvalid(M_AXI_ETH_DMA0_ARVALID),
    .s_axi_lite_arready(M_AXI_ETH_DMA0_ARREADY),

    .s_axi_lite_rdata(M_AXI_ETH_DMA0_RDATA),
    .s_axi_lite_rresp(M_AXI_ETH_DMA0_RRESP),
    .s_axi_lite_rvalid(M_AXI_ETH_DMA0_RVALID),
    .s_axi_lite_rready(M_AXI_ETH_DMA0_RREADY),

    .m_axi_sg_awaddr(S_AXI_GP0_AWADDR),
    .m_axi_sg_awlen(S_AXI_GP0_AWLEN),
    .m_axi_sg_awsize(S_AXI_GP0_AWSIZE),
    .m_axi_sg_awburst(S_AXI_GP0_AWBURST),
    .m_axi_sg_awprot(S_AXI_GP0_AWPROT),
    .m_axi_sg_awcache(S_AXI_GP0_AWCACHE),
    .m_axi_sg_awvalid(S_AXI_GP0_AWVALID),
    .m_axi_sg_awready(S_AXI_GP0_AWREADY),
    .m_axi_sg_wdata(S_AXI_GP0_WDATA),
    .m_axi_sg_wstrb(S_AXI_GP0_WSTRB),
    .m_axi_sg_wlast(S_AXI_GP0_WLAST),
    .m_axi_sg_wvalid(S_AXI_GP0_WVALID),
    .m_axi_sg_wready(S_AXI_GP0_WREADY),
    .m_axi_sg_bresp(S_AXI_GP0_BRESP),
    .m_axi_sg_bvalid(S_AXI_GP0_BVALID),
    .m_axi_sg_bready(S_AXI_GP0_BREADY),
    .m_axi_sg_araddr(S_AXI_GP0_ARADDR),
    .m_axi_sg_arlen(S_AXI_GP0_ARLEN),
    .m_axi_sg_arsize(S_AXI_GP0_ARSIZE),
    .m_axi_sg_arburst(S_AXI_GP0_ARBURST),
    .m_axi_sg_arprot(S_AXI_GP0_ARPROT),
    .m_axi_sg_arcache(S_AXI_GP0_ARCACHE),
    .m_axi_sg_arvalid(S_AXI_GP0_ARVALID),
    .m_axi_sg_arready(S_AXI_GP0_ARREADY),
    .m_axi_sg_rdata(S_AXI_GP0_RDATA),
    .m_axi_sg_rresp(S_AXI_GP0_RRESP),
    .m_axi_sg_rlast(S_AXI_GP0_RLAST),
    .m_axi_sg_rvalid(S_AXI_GP0_RVALID),
    .m_axi_sg_rready(S_AXI_GP0_RREADY),

    .m_axi_mm2s_araddr(S_AXI_HP0_ARADDR),
    .m_axi_mm2s_arlen(S_AXI_HP0_ARLEN),
    .m_axi_mm2s_arsize(S_AXI_HP0_ARSIZE),
    .m_axi_mm2s_arburst(S_AXI_HP0_ARBURST),
    .m_axi_mm2s_arprot(S_AXI_HP0_ARPROT),
    .m_axi_mm2s_arcache(S_AXI_HP0_ARCACHE),
    .m_axi_mm2s_arvalid(S_AXI_HP0_ARVALID),
    .m_axi_mm2s_arready(S_AXI_HP0_ARREADY),
    .m_axi_mm2s_rdata(S_AXI_HP0_RDATA),
    .m_axi_mm2s_rresp(S_AXI_HP0_RRESP),
    .m_axi_mm2s_rlast(S_AXI_HP0_RLAST),
    .m_axi_mm2s_rvalid(S_AXI_HP0_RVALID),
    .m_axi_mm2s_rready(S_AXI_HP0_RREADY),

    .mm2s_prmry_reset_out_n(),
    .m_axis_mm2s_tdata(arm_eth0_tx_tdata),
    .m_axis_mm2s_tkeep(arm_eth0_tx_tkeep),
    .m_axis_mm2s_tvalid(arm_eth0_tx_tvalid),
    .m_axis_mm2s_tready(arm_eth0_tx_tready),
    .m_axis_mm2s_tlast(arm_eth0_tx_tlast),

    .m_axi_s2mm_awaddr(S_AXI_HP0_AWADDR),
    .m_axi_s2mm_awlen(S_AXI_HP0_AWLEN),
    .m_axi_s2mm_awsize(S_AXI_HP0_AWSIZE),
    .m_axi_s2mm_awburst(S_AXI_HP0_AWBURST),
    .m_axi_s2mm_awprot(S_AXI_HP0_AWPROT),
    .m_axi_s2mm_awcache(S_AXI_HP0_AWCACHE),
    .m_axi_s2mm_awvalid(S_AXI_HP0_AWVALID),
    .m_axi_s2mm_awready(S_AXI_HP0_AWREADY),
    .m_axi_s2mm_wdata(S_AXI_HP0_WDATA),
    .m_axi_s2mm_wstrb(S_AXI_HP0_WSTRB),
    .m_axi_s2mm_wlast(S_AXI_HP0_WLAST),
    .m_axi_s2mm_wvalid(S_AXI_HP0_WVALID),
    .m_axi_s2mm_wready(S_AXI_HP0_WREADY),
    .m_axi_s2mm_bresp(S_AXI_HP0_BRESP),
    .m_axi_s2mm_bvalid(S_AXI_HP0_BVALID),
    .m_axi_s2mm_bready(S_AXI_HP0_BREADY),

    .s2mm_prmry_reset_out_n(),
    .s_axis_s2mm_tdata(arm_eth0_rx_tdata),
    .s_axis_s2mm_tkeep(arm_eth0_rx_tkeep),
    .s_axis_s2mm_tvalid(arm_eth0_rx_tvalid),
    .s_axis_s2mm_tready(arm_eth0_rx_tready),
    .s_axis_s2mm_tlast(arm_eth0_rx_tlast),

    .mm2s_introut(arm_eth0_tx_irq),
    .s2mm_introut(arm_eth0_rx_irq),
    .axi_dma_tstvec()
  );

  axi_fifo_2clk #(
    .WIDTH(1+8+64),
    .SIZE(5)
  ) eth_tx_0_fifo_2clk_i (
    .reset(clk40_rst),
    .i_aclk(clk40),
    .i_tdata({arm_eth0_tx_tlast, arm_eth0_tx_tkeep, arm_eth0_tx_tdata}),
    .i_tvalid(arm_eth0_tx_tvalid),
    .i_tready(arm_eth0_tx_tready),
    .o_aclk(bus_clk),
    .o_tdata({arm_eth0_tx_tlast_b, arm_eth0_tx_tkeep_b, arm_eth0_tx_tdata_b}),
    .o_tvalid(arm_eth0_tx_tvalid_b),
    .o_tready(arm_eth0_tx_tready_b)
  );

  axi_fifo_2clk #(
    .WIDTH(1+8+64),
    .SIZE(5)
  ) eth_rx_0_fifo_2clk_i (
    .reset(bus_rst),
    .i_aclk(bus_clk),
    .i_tdata({arm_eth0_rx_tlast_b, arm_eth0_rx_tkeep_b, arm_eth0_rx_tdata_b}),
    .i_tvalid(arm_eth0_rx_tvalid_b),
    .i_tready(arm_eth0_rx_tready_b),
    .o_aclk(clk40),
    .o_tdata({arm_eth0_rx_tlast, arm_eth0_rx_tkeep, arm_eth0_rx_tdata}),
    .o_tvalid(arm_eth0_rx_tvalid),
    .o_tready(arm_eth0_rx_tready)
  );

`endif

  /////////////////////////////////////////////////////////////////////
  //
  // Ethernet DMA 1
  //
  //////////////////////////////////////////////////////////////////////

  assign  IRQ_F2P[2] = arm_eth1_rx_irq;
  assign  IRQ_F2P[3] = arm_eth1_tx_irq;

  assign {S_AXI_HP1_AWID, S_AXI_HP1_ARID} = 12'd0;
  assign {S_AXI_GP1_AWID, S_AXI_GP1_ARID} = 10'd0;

`ifdef SFP0_AURORA
  //If inst Aurora, tie off each axi/axi-lite interface
  axi_dummy #(.DEC_ERR(1'b0)) inst_axi_dummy_sfp1_eth_dma
  (
    .s_axi_aclk(bus_clk),
    .s_axi_areset(bus_rst),

    .s_axi_awaddr(M_AXI_ETH_DMA1_AWADDR),
    .s_axi_awvalid(M_AXI_ETH_DMA1_AWVALID),
    .s_axi_awready(M_AXI_ETH_DMA1_AWREADY),

    .s_axi_wdata(M_AXI_ETH_DMA1_WDATA),
    .s_axi_wvalid(M_AXI_ETH_DMA1_WVALID),
    .s_axi_wready(M_AXI_ETH_DMA1_WREADY),

    .s_axi_bresp(M_AXI_ETH_DMA1_BRESP),
    .s_axi_bvalid(M_AXI_ETH_DMA1_BVALID),
    .s_axi_bready(M_AXI_ETH_DMA1_BREADY),

    .s_axi_araddr(M_AXI_ETH_DMA1_ARADDR),
    .s_axi_arvalid(M_AXI_ETH_DMA1_ARVALID),
    .s_axi_arready(M_AXI_ETH_DMA1_ARREADY),

    .s_axi_rdata(M_AXI_ETH_DMA1_RDATA),
    .s_axi_rresp(M_AXI_ETH_DMA1_RRESP),
    .s_axi_rvalid(M_AXI_ETH_DMA1_RVALID),
    .s_axi_rready(M_AXI_ETH_DMA1_RREADY)

  );
  //S_AXI_GP0 outputs from axi_eth_dma, so needs some sort of controller/tie off
  assign S_AXI_GP1_AWADDR = 32'h0;
  assign S_AXI_GP1_AWLEN = 8'h0;
  assign S_AXI_GP1_AWSIZE = 4'h0;
  assign S_AXI_GP1_AWBURST = 3'h0;
  assign S_AXI_GP1_AWPROT = 3'h0;
  assign S_AXI_GP1_AWCACHE = 4'h0;
  assign S_AXI_GP1_AWVALID = 1'b0;
  //S_AXI_GP1_AWREADY output from PS
  assign S_AXI_GP1_WDATA = 32'h0;
  assign S_AXI_GP1_WSTRB = 4'h0;
  assign S_AXI_GP1_WLAST = 1'b0;
  assign S_AXI_GP1_WVALID = 1'b0;
  //S_AXI_GP1_WREADY output from PS
  //S_AXI_GP1_BRESP
  //S_AXI_GP1_BVALID
  assign S_AXI_GP1_BREADY = 1'b1;
  assign S_AXI_GP1_ARADDR = 32'h0;
  assign S_AXI_GP1_ARLEN = 8'h0;
  assign S_AXI_GP1_ARSIZE = 3'h0;
  assign S_AXI_GP1_ARBURST = 2'h0;
  assign S_AXI_GP1_ARPROT = 3'h0;
  assign S_AXI_GP1_ARCACHE = 4'h0;
  assign S_AXI_GP1_ARVALID = 1'b0;
  //S_AXI_GP1_ARREADY
  //S_AXI_GP1_RDATA
  //S_AXI_GP1_RRESP
  //S_AXI_GP1_RLAST
  //S_AXI_GP1_RVALID
  assign S_AXI_GP1_RREADY = 1'b1;

  //S_AXI_HP0 from axi_eth_dma
  assign S_AXI_HP1_ARADDR = 32'h0;
  assign S_AXI_HP1_ARLEN = 8'h0;
  assign S_AXI_HP1_ARSIZE = 3'h0;
  assign S_AXI_HP1_ARBURST = 2'h0;
  assign S_AXI_HP1_ARPROT = 3'h0;
  assign S_AXI_HP1_ARCACHE = 4'h0;
  assign S_AXI_HP1_ARVALID = 1'b0;
  //S_AXI_HP1_ARREADY
  //S_AXI_HP1_RDATA
  //S_AXI_HP1_RRESP
  //S_AXI_HP1_RLAST
  //S_AXI_HP1_RVALID
  assign S_AXI_HP1_RREADY = 1'b1;
  assign S_AXI_HP1_AWADDR = 32'h0;
  assign S_AXI_HP1_AWLEN = 8'h0;
  assign S_AXI_HP1_AWSIZE = 3'h0;
  assign S_AXI_HP1_AWBURST = 2'h0;
  assign S_AXI_HP1_AWPROT = 3'h0;
  assign S_AXI_HP1_AWCACHE = 4'h0;
  assign S_AXI_HP1_AWVALID = 1'b0;
  //S_AXI_HP1_AWREADY
  assign S_AXI_HP1_WDATA = 64'h0;
  assign S_AXI_HP1_WSTRB = 8'h0;
  assign S_AXI_HP1_WLAST = 1'b0;
  assign S_AXI_HP1_WVALID = 1'b0;
  //S_AXI_HP1_WREADY
  //S_AXI_HP1_BRESP
  //S_AXI_HP1_BVALID
  assign S_AXI_HP1_BREADY = 1'b1;

`else

  axi_eth_dma inst_axi_eth_dma1 (
    .s_axi_lite_aclk(clk40),
    .m_axi_sg_aclk(clk40),
    .m_axi_mm2s_aclk(clk40),
    .m_axi_s2mm_aclk(clk40),
    .axi_resetn(clk40_rstn),

    .s_axi_lite_awaddr(M_AXI_ETH_DMA1_AWADDR),
    .s_axi_lite_awvalid(M_AXI_ETH_DMA1_AWVALID),
    .s_axi_lite_awready(M_AXI_ETH_DMA1_AWREADY),

    .s_axi_lite_wdata(M_AXI_ETH_DMA1_WDATA),
    .s_axi_lite_wvalid(M_AXI_ETH_DMA1_WVALID),
    .s_axi_lite_wready(M_AXI_ETH_DMA1_WREADY),

    .s_axi_lite_bresp(M_AXI_ETH_DMA1_BRESP),
    .s_axi_lite_bvalid(M_AXI_ETH_DMA1_BVALID),
    .s_axi_lite_bready(M_AXI_ETH_DMA1_BREADY),

    .s_axi_lite_araddr(M_AXI_ETH_DMA1_ARADDR),
    .s_axi_lite_arvalid(M_AXI_ETH_DMA1_ARVALID),
    .s_axi_lite_arready(M_AXI_ETH_DMA1_ARREADY),

    .s_axi_lite_rdata(M_AXI_ETH_DMA1_RDATA),
    .s_axi_lite_rresp(M_AXI_ETH_DMA1_RRESP),
    .s_axi_lite_rvalid(M_AXI_ETH_DMA1_RVALID),
    .s_axi_lite_rready(M_AXI_ETH_DMA1_RREADY),

    .m_axi_sg_awaddr(S_AXI_GP1_AWADDR),
    .m_axi_sg_awlen(S_AXI_GP1_AWLEN),
    .m_axi_sg_awsize(S_AXI_GP1_AWSIZE),
    .m_axi_sg_awburst(S_AXI_GP1_AWBURST),
    .m_axi_sg_awprot(S_AXI_GP1_AWPROT),
    .m_axi_sg_awcache(S_AXI_GP1_AWCACHE),
    .m_axi_sg_awvalid(S_AXI_GP1_AWVALID),
    .m_axi_sg_awready(S_AXI_GP1_AWREADY),
    .m_axi_sg_wdata(S_AXI_GP1_WDATA),
    .m_axi_sg_wstrb(S_AXI_GP1_WSTRB),
    .m_axi_sg_wlast(S_AXI_GP1_WLAST),
    .m_axi_sg_wvalid(S_AXI_GP1_WVALID),
    .m_axi_sg_wready(S_AXI_GP1_WREADY),
    .m_axi_sg_bresp(S_AXI_GP1_BRESP),
    .m_axi_sg_bvalid(S_AXI_GP1_BVALID),
    .m_axi_sg_bready(S_AXI_GP1_BREADY),
    .m_axi_sg_araddr(S_AXI_GP1_ARADDR),
    .m_axi_sg_arlen(S_AXI_GP1_ARLEN),
    .m_axi_sg_arsize(S_AXI_GP1_ARSIZE),
    .m_axi_sg_arburst(S_AXI_GP1_ARBURST),
    .m_axi_sg_arprot(S_AXI_GP1_ARPROT),
    .m_axi_sg_arcache(S_AXI_GP1_ARCACHE),
    .m_axi_sg_arvalid(S_AXI_GP1_ARVALID),
    .m_axi_sg_arready(S_AXI_GP1_ARREADY),
    .m_axi_sg_rdata(S_AXI_GP1_RDATA),
    .m_axi_sg_rresp(S_AXI_GP1_RRESP),
    .m_axi_sg_rlast(S_AXI_GP1_RLAST),
    .m_axi_sg_rvalid(S_AXI_GP1_RVALID),
    .m_axi_sg_rready(S_AXI_GP1_RREADY),

    .m_axi_mm2s_araddr(S_AXI_HP1_ARADDR),
    .m_axi_mm2s_arlen(S_AXI_HP1_ARLEN),
    .m_axi_mm2s_arsize(S_AXI_HP1_ARSIZE),
    .m_axi_mm2s_arburst(S_AXI_HP1_ARBURST),
    .m_axi_mm2s_arprot(S_AXI_HP1_ARPROT),
    .m_axi_mm2s_arcache(S_AXI_HP1_ARCACHE),
    .m_axi_mm2s_arvalid(S_AXI_HP1_ARVALID),
    .m_axi_mm2s_arready(S_AXI_HP1_ARREADY),
    .m_axi_mm2s_rdata(S_AXI_HP1_RDATA),
    .m_axi_mm2s_rresp(S_AXI_HP1_RRESP),
    .m_axi_mm2s_rlast(S_AXI_HP1_RLAST),
    .m_axi_mm2s_rvalid(S_AXI_HP1_RVALID),
    .m_axi_mm2s_rready(S_AXI_HP1_RREADY),

    .mm2s_prmry_reset_out_n(),
    .m_axis_mm2s_tdata(arm_eth1_tx_tdata),
    .m_axis_mm2s_tkeep(arm_eth1_tx_tkeep),
    .m_axis_mm2s_tvalid(arm_eth1_tx_tvalid),
    .m_axis_mm2s_tready(arm_eth1_tx_tready),
    .m_axis_mm2s_tlast(arm_eth1_tx_tlast),

    .m_axi_s2mm_awaddr(S_AXI_HP1_AWADDR),
    .m_axi_s2mm_awlen(S_AXI_HP1_AWLEN),
    .m_axi_s2mm_awsize(S_AXI_HP1_AWSIZE),
    .m_axi_s2mm_awburst(S_AXI_HP1_AWBURST),
    .m_axi_s2mm_awprot(S_AXI_HP1_AWPROT),
    .m_axi_s2mm_awcache(S_AXI_HP1_AWCACHE),
    .m_axi_s2mm_awvalid(S_AXI_HP1_AWVALID),
    .m_axi_s2mm_awready(S_AXI_HP1_AWREADY),
    .m_axi_s2mm_wdata(S_AXI_HP1_WDATA),
    .m_axi_s2mm_wstrb(S_AXI_HP1_WSTRB),
    .m_axi_s2mm_wlast(S_AXI_HP1_WLAST),
    .m_axi_s2mm_wvalid(S_AXI_HP1_WVALID),
    .m_axi_s2mm_wready(S_AXI_HP1_WREADY),
    .m_axi_s2mm_bresp(S_AXI_HP1_BRESP),
    .m_axi_s2mm_bvalid(S_AXI_HP1_BVALID),
    .m_axi_s2mm_bready(S_AXI_HP1_BREADY),

    .s2mm_prmry_reset_out_n(),
    .s_axis_s2mm_tdata(arm_eth1_rx_tdata),
    .s_axis_s2mm_tkeep(arm_eth1_rx_tkeep),
    .s_axis_s2mm_tvalid(arm_eth1_rx_tvalid),
    .s_axis_s2mm_tready(arm_eth1_rx_tready),
    .s_axis_s2mm_tlast(arm_eth1_rx_tlast),

    .mm2s_introut(arm_eth1_tx_irq),
    .s2mm_introut(arm_eth1_rx_irq),
    .axi_dma_tstvec()
  );

  axi_fifo_2clk #(
    .WIDTH(1+8+64),
    .SIZE(5)
  ) eth_tx_1_fifo_2clk_i (
    .reset(clk40_rst),
    .i_aclk(clk40),
    .i_tdata({arm_eth1_tx_tlast, arm_eth1_tx_tkeep, arm_eth1_tx_tdata}),
    .i_tvalid(arm_eth1_tx_tvalid),
    .i_tready(arm_eth1_tx_tready),
    .o_aclk(bus_clk),
    .o_tdata({arm_eth1_tx_tlast_b, arm_eth1_tx_tkeep_b, arm_eth1_tx_tdata_b}),
    .o_tvalid(arm_eth1_tx_tvalid_b),
    .o_tready(arm_eth1_tx_tready_b)
  );

  axi_fifo_2clk #(
    .WIDTH(1+8+64),
    .SIZE(5)
  ) eth_rx_1_fifo_2clk_i (
    .reset(bus_rst),
    .i_aclk(bus_clk),
    .i_tdata({arm_eth1_rx_tlast_b, arm_eth1_rx_tkeep_b, arm_eth1_rx_tdata_b}),
    .i_tvalid(arm_eth1_rx_tvalid_b),
    .i_tready(arm_eth1_rx_tready_b),
    .o_aclk(clk40),
    .o_tdata({arm_eth1_rx_tlast, arm_eth1_rx_tkeep, arm_eth1_rx_tdata}),
    .o_tvalid(arm_eth1_rx_tvalid),
    .o_tready(arm_eth1_rx_tready)
  );
`endif

  /////////////////////////////////////////////////////////////////////
  //
  // Processing System
  //
  //////////////////////////////////////////////////////////////////////

  wire spi0_sclk;
  wire spi0_mosi;
  wire spi0_miso;
  wire spi0_ss0;
  wire spi0_ss1;
  wire spi0_ss2;
  wire spi0_ss3; //PDac driven by gpio
  wire spi1_sclk;
  wire spi1_mosi;
  wire spi1_miso;
  wire spi1_ss0;
  wire spi1_ss1;
  wire spi1_ss2;
  wire spi1_ss3; //PDac driven by gpio

  //Spi SS (Cs) for PDac
  assign spi0_ss3 = ps_gpio_out[0];
  assign spi1_ss3 = ps_gpio_out[1];

  // Processing System
  n310_ps_bd inst_n310_ps (
    .SPI0_SCLK_I(1'b0),
    .SPI0_SCLK_O(spi0_sclk),
    .SPI0_SCLK_T(),
    .SPI0_MOSI_I(1'b0),
    .SPI0_MOSI_O(spi0_mosi),
    .SPI0_MOSI_T(),
    .SPI0_MISO_I(spi0_miso),
    .SPI0_MISO_O(),
    .SPI0_MISO_T(),
    .SPI0_SS_I(1'b1),
    .SPI0_SS_O(spi0_ss0),
    .SPI0_SS1_O(spi0_ss1),
    .SPI0_SS2_O(spi0_ss2),
    .SPI0_SS_T(),

  `ifndef N300
    .SPI1_SCLK_I(1'b0),
    .SPI1_SCLK_O(spi1_sclk),
    .SPI1_SCLK_T(),
    .SPI1_MOSI_I(1'b0),
    .SPI1_MOSI_O(spi1_mosi),
    .SPI1_MOSI_T(),
    .SPI1_MISO_I(spi1_miso),
    .SPI1_MISO_O(),
    .SPI1_MISO_T(),
    .SPI1_SS_I(1'b1),
    .SPI1_SS_O(spi1_ss0),
    .SPI1_SS1_O(spi1_ss1),
    .SPI1_SS2_O(spi1_ss2),
    .SPI1_SS_T(),
  `else
    .SPI1_SCLK_I(1'b0),
    .SPI1_SCLK_O(),
    .SPI1_SCLK_T(),
    .SPI1_MOSI_I(1'b0),
    .SPI1_MOSI_O(),
    .SPI1_MOSI_T(),
    .SPI1_MISO_I(1'b0),
    .SPI1_MISO_O(),
    .SPI1_MISO_T(),
    .SPI1_SS_I(1'b1),
    .SPI1_SS_O(),
    .SPI1_SS1_O(),
    .SPI1_SS2_O(),
    .SPI1_SS_T(),
  `endif

    .bus_clk(bus_clk),
    .bus_rstn(~bus_rst),
    .clk40(clk40),
    .clk40_rstn(clk40_rstn),

    .M_AXI_ETH_DMA0_araddr(M_AXI_ETH_DMA0_ARADDR),
    .M_AXI_ETH_DMA0_arprot(),
    .M_AXI_ETH_DMA0_arready(M_AXI_ETH_DMA0_ARREADY),
    .M_AXI_ETH_DMA0_arvalid(M_AXI_ETH_DMA0_ARVALID),

    .M_AXI_ETH_DMA0_awaddr(M_AXI_ETH_DMA0_AWADDR),
    .M_AXI_ETH_DMA0_awprot(),
    .M_AXI_ETH_DMA0_awready(M_AXI_ETH_DMA0_AWREADY),
    .M_AXI_ETH_DMA0_awvalid(M_AXI_ETH_DMA0_AWVALID),

    .M_AXI_ETH_DMA0_wdata(M_AXI_ETH_DMA0_WDATA),
    .M_AXI_ETH_DMA0_wready(M_AXI_ETH_DMA0_WREADY),
    .M_AXI_ETH_DMA0_wstrb(M_AXI_ETH_DMA0_WSTRB),
    .M_AXI_ETH_DMA0_wvalid(M_AXI_ETH_DMA0_WVALID),

    .M_AXI_ETH_DMA0_rdata(M_AXI_ETH_DMA0_RDATA),
    .M_AXI_ETH_DMA0_rready(M_AXI_ETH_DMA0_RREADY),
    .M_AXI_ETH_DMA0_rresp(M_AXI_ETH_DMA0_RRESP),
    .M_AXI_ETH_DMA0_rvalid(M_AXI_ETH_DMA0_RVALID),

    .M_AXI_ETH_DMA0_bready(M_AXI_ETH_DMA0_BREADY),
    .M_AXI_ETH_DMA0_bresp(M_AXI_ETH_DMA0_BRESP),
    .M_AXI_ETH_DMA0_bvalid(M_AXI_ETH_DMA0_BVALID),

    .M_AXI_ETH_DMA1_araddr(M_AXI_ETH_DMA1_ARADDR),
    .M_AXI_ETH_DMA1_arprot(),
    .M_AXI_ETH_DMA1_arready(M_AXI_ETH_DMA1_ARREADY),
    .M_AXI_ETH_DMA1_arvalid(M_AXI_ETH_DMA1_ARVALID),

    .M_AXI_ETH_DMA1_awaddr(M_AXI_ETH_DMA1_AWADDR),
    .M_AXI_ETH_DMA1_awprot(),
    .M_AXI_ETH_DMA1_awready(M_AXI_ETH_DMA1_AWREADY),
    .M_AXI_ETH_DMA1_awvalid(M_AXI_ETH_DMA1_AWVALID),

    .M_AXI_ETH_DMA1_bready(M_AXI_ETH_DMA1_BREADY),
    .M_AXI_ETH_DMA1_bresp(M_AXI_ETH_DMA1_BRESP),
    .M_AXI_ETH_DMA1_bvalid(M_AXI_ETH_DMA1_BVALID),

    .M_AXI_ETH_DMA1_rdata(M_AXI_ETH_DMA1_RDATA),
    .M_AXI_ETH_DMA1_rready(M_AXI_ETH_DMA1_RREADY),
    .M_AXI_ETH_DMA1_rresp(M_AXI_ETH_DMA1_RRESP),
    .M_AXI_ETH_DMA1_rvalid(M_AXI_ETH_DMA1_RVALID),

    .M_AXI_ETH_DMA1_wdata(M_AXI_ETH_DMA1_WDATA),
    .M_AXI_ETH_DMA1_wready(M_AXI_ETH_DMA1_WREADY),
    .M_AXI_ETH_DMA1_wstrb(M_AXI_ETH_DMA1_WSTRB),
    .M_AXI_ETH_DMA1_wvalid(M_AXI_ETH_DMA1_WVALID),

    .M_AXI_JESD0_araddr(M_AXI_JESD0_ARADDR),
    .M_AXI_JESD0_arprot(),
    .M_AXI_JESD0_arready(M_AXI_JESD0_ARREADY),
    .M_AXI_JESD0_arvalid(M_AXI_JESD0_ARVALID),

    .M_AXI_JESD0_awaddr(M_AXI_JESD0_AWADDR),
    .M_AXI_JESD0_awprot(),
    .M_AXI_JESD0_awready(M_AXI_JESD0_AWREADY),
    .M_AXI_JESD0_awvalid(M_AXI_JESD0_AWVALID),

    .M_AXI_JESD0_bready(M_AXI_JESD0_BREADY),
    .M_AXI_JESD0_bresp(M_AXI_JESD0_BRESP),
    .M_AXI_JESD0_bvalid(M_AXI_JESD0_BVALID),

    .M_AXI_JESD0_rdata(M_AXI_JESD0_RDATA),
    .M_AXI_JESD0_rready(M_AXI_JESD0_RREADY),
    .M_AXI_JESD0_rresp(M_AXI_JESD0_RRESP),
    .M_AXI_JESD0_rvalid(M_AXI_JESD0_RVALID),

    .M_AXI_JESD0_wdata(M_AXI_JESD0_WDATA),
    .M_AXI_JESD0_wready(M_AXI_JESD0_WREADY),
    .M_AXI_JESD0_wstrb(M_AXI_JESD0_WSTRB),
    .M_AXI_JESD0_wvalid(M_AXI_JESD0_WVALID),

    .M_AXI_JESD1_araddr(M_AXI_JESD1_ARADDR),
    .M_AXI_JESD1_arprot(),
    .M_AXI_JESD1_arready(M_AXI_JESD1_ARREADY),
    .M_AXI_JESD1_arvalid(M_AXI_JESD1_ARVALID),

    .M_AXI_JESD1_awaddr(M_AXI_JESD1_AWADDR),
    .M_AXI_JESD1_awprot(),
    .M_AXI_JESD1_awready(M_AXI_JESD1_AWREADY),
    .M_AXI_JESD1_awvalid(M_AXI_JESD1_AWVALID),

    .M_AXI_JESD1_bready(M_AXI_JESD1_BREADY),
    .M_AXI_JESD1_bresp(M_AXI_JESD1_BRESP),
    .M_AXI_JESD1_bvalid(M_AXI_JESD1_BVALID),

    .M_AXI_JESD1_rdata(M_AXI_JESD1_RDATA),
    .M_AXI_JESD1_rready(M_AXI_JESD1_RREADY),
    .M_AXI_JESD1_rresp(M_AXI_JESD1_RRESP),
    .M_AXI_JESD1_rvalid(M_AXI_JESD1_RVALID),

    .M_AXI_JESD1_wdata(M_AXI_JESD1_WDATA),
    .M_AXI_JESD1_wready(M_AXI_JESD1_WREADY),
    .M_AXI_JESD1_wstrb(M_AXI_JESD1_WSTRB),
    .M_AXI_JESD1_wvalid(M_AXI_JESD1_WVALID),

    .M_AXI_NET0_araddr(M_AXI_NET0_ARADDR),
    .M_AXI_NET0_arprot(),
    .M_AXI_NET0_arready(M_AXI_NET0_ARREADY),
    .M_AXI_NET0_arvalid(M_AXI_NET0_ARVALID),

    .M_AXI_NET0_awaddr(M_AXI_NET0_AWADDR),
    .M_AXI_NET0_awprot(),
    .M_AXI_NET0_awready(M_AXI_NET0_AWREADY),
    .M_AXI_NET0_awvalid(M_AXI_NET0_AWVALID),

    .M_AXI_NET0_bready(M_AXI_NET0_BREADY),
    .M_AXI_NET0_bresp(M_AXI_NET0_BRESP),
    .M_AXI_NET0_bvalid(M_AXI_NET0_BVALID),

    .M_AXI_NET0_rdata(M_AXI_NET0_RDATA),
    .M_AXI_NET0_rready(M_AXI_NET0_RREADY),
    .M_AXI_NET0_rresp(M_AXI_NET0_RRESP),
    .M_AXI_NET0_rvalid(M_AXI_NET0_RVALID),

    .M_AXI_NET0_wdata(M_AXI_NET0_WDATA),
    .M_AXI_NET0_wready(M_AXI_NET0_WREADY),
    .M_AXI_NET0_wstrb(M_AXI_NET0_WSTRB),
    .M_AXI_NET0_wvalid(M_AXI_NET0_WVALID),

    .M_AXI_NET1_araddr(M_AXI_NET1_ARADDR),
    .M_AXI_NET1_arprot(),
    .M_AXI_NET1_arready(M_AXI_NET1_ARREADY),
    .M_AXI_NET1_arvalid(M_AXI_NET1_ARVALID),

    .M_AXI_NET1_awaddr(M_AXI_NET1_AWADDR),
    .M_AXI_NET1_awprot(),
    .M_AXI_NET1_awready(M_AXI_NET1_AWREADY),
    .M_AXI_NET1_awvalid(M_AXI_NET1_AWVALID),

    .M_AXI_NET1_bready(M_AXI_NET1_BREADY),
    .M_AXI_NET1_bresp(M_AXI_NET1_BRESP),
    .M_AXI_NET1_bvalid(M_AXI_NET1_BVALID),

    .M_AXI_NET1_rdata(M_AXI_NET1_RDATA),
    .M_AXI_NET1_rready(M_AXI_NET1_RREADY),
    .M_AXI_NET1_rresp(M_AXI_NET1_RRESP),
    .M_AXI_NET1_rvalid(M_AXI_NET1_RVALID),

    .M_AXI_NET1_wdata(M_AXI_NET1_WDATA),
    .M_AXI_NET1_wready(M_AXI_NET1_WREADY),
    .M_AXI_NET1_wstrb(M_AXI_NET1_WSTRB),
    .M_AXI_NET1_wvalid(M_AXI_NET1_WVALID),

    .M_AXI_WR_CLK(m_axi_wr_clk),
    .M_AXI_WR_RSTn(1'b1),
    .M_AXI_WR_araddr(m_axi_wr_araddr),
    .M_AXI_WR_arready(m_axi_wr_arready),
    .M_AXI_WR_arvalid(m_axi_wr_arvalid),
    .M_AXI_WR_awaddr(m_axi_wr_awaddr),
    .M_AXI_WR_awready(m_axi_wr_awready),
    .M_AXI_WR_awvalid(m_axi_wr_awvalid),
    .M_AXI_WR_bready(m_axi_wr_bready),
    .M_AXI_WR_bresp(m_axi_wr_bresp),
    .M_AXI_WR_bvalid(m_axi_wr_bvalid),
    .M_AXI_WR_rdata(m_axi_wr_rdata),
    .M_AXI_WR_rready(m_axi_wr_rready),
    .M_AXI_WR_rresp(m_axi_wr_rresp),
    .M_AXI_WR_rvalid(m_axi_wr_rvalid),
    .M_AXI_WR_wdata(m_axi_wr_wdata),
    .M_AXI_WR_wready(m_axi_wr_wready),
    .M_AXI_WR_wstrb(m_axi_wr_wstrb),
    .M_AXI_WR_wvalid(m_axi_wr_wvalid),

    .M_AXI_XBAR_araddr(M_AXI_XBAR_ARADDR),
    .M_AXI_XBAR_arprot(),
    .M_AXI_XBAR_arready(M_AXI_XBAR_ARREADY),
    .M_AXI_XBAR_arvalid(M_AXI_XBAR_ARVALID),

    .M_AXI_XBAR_awaddr(M_AXI_XBAR_AWADDR),
    .M_AXI_XBAR_awprot(),
    .M_AXI_XBAR_awready(M_AXI_XBAR_AWREADY),
    .M_AXI_XBAR_awvalid(M_AXI_XBAR_AWVALID),

    .M_AXI_XBAR_bready(M_AXI_XBAR_BREADY),
    .M_AXI_XBAR_bresp(M_AXI_XBAR_BRESP),
    .M_AXI_XBAR_bvalid(M_AXI_XBAR_BVALID),

    .M_AXI_XBAR_rdata(M_AXI_XBAR_RDATA),
    .M_AXI_XBAR_rready(M_AXI_XBAR_RREADY),
    .M_AXI_XBAR_rresp(M_AXI_XBAR_RRESP),
    .M_AXI_XBAR_rvalid(M_AXI_XBAR_RVALID),

    .M_AXI_XBAR_wdata(M_AXI_XBAR_WDATA),
    .M_AXI_XBAR_wready(M_AXI_XBAR_WREADY),
    .M_AXI_XBAR_wstrb(M_AXI_XBAR_WSTRB),
    .M_AXI_XBAR_wvalid(M_AXI_XBAR_WVALID),

    .S_AXI_GP0_ACLK(clk40),
    .S_AXI_GP0_ARESETN(clk40_rstn),
    .S_AXI_GP0_araddr(S_AXI_GP0_ARADDR),
    .S_AXI_GP0_arburst(S_AXI_GP0_ARBURST),
    .S_AXI_GP0_arcache(S_AXI_GP0_ARCACHE),
    .S_AXI_GP0_arid(S_AXI_GP0_ARID),
    .S_AXI_GP0_arlen(S_AXI_GP0_ARLEN),
    .S_AXI_GP0_arlock(1'b0),
    .S_AXI_GP0_arprot(S_AXI_GP0_ARPROT),
    .S_AXI_GP0_arqos(4'b0000),
    .S_AXI_GP0_arready(S_AXI_GP0_ARREADY),
    .S_AXI_GP0_arsize(S_AXI_GP0_ARSIZE),
    .S_AXI_GP0_arvalid(S_AXI_GP0_ARVALID),
    .S_AXI_GP0_awaddr(S_AXI_GP0_AWADDR),
    .S_AXI_GP0_awburst(S_AXI_GP0_AWBURST),
    .S_AXI_GP0_awcache(S_AXI_GP0_AWCACHE),
    .S_AXI_GP0_awid(S_AXI_GP0_AWID),
    .S_AXI_GP0_awlen(S_AXI_GP0_AWLEN),
    .S_AXI_GP0_awlock(1'b0),
    .S_AXI_GP0_awprot(S_AXI_GP0_AWPROT),
    .S_AXI_GP0_awqos(4'b0000),
    .S_AXI_GP0_awregion(4'b0000),
    .S_AXI_GP0_awready(S_AXI_GP0_AWREADY),
    .S_AXI_GP0_awsize(S_AXI_GP0_AWSIZE),
    .S_AXI_GP0_awvalid(S_AXI_GP0_AWVALID),
    .S_AXI_GP0_bid(),
    .S_AXI_GP0_bready(S_AXI_GP0_BREADY),
    .S_AXI_GP0_bresp(S_AXI_GP0_BRESP),
    .S_AXI_GP0_bvalid(S_AXI_GP0_BVALID),
    .S_AXI_GP0_rdata(S_AXI_GP0_RDATA),
    .S_AXI_GP0_rid(),
    .S_AXI_GP0_rlast(S_AXI_GP0_RLAST),
    .S_AXI_GP0_rready(S_AXI_GP0_RREADY),
    .S_AXI_GP0_rresp(S_AXI_GP0_RRESP),
    .S_AXI_GP0_rvalid(S_AXI_GP0_RVALID),
    .S_AXI_GP0_wdata(S_AXI_GP0_WDATA),
    .S_AXI_GP0_wlast(S_AXI_GP0_WLAST),
    .S_AXI_GP0_wready(S_AXI_GP0_WREADY),
    .S_AXI_GP0_wstrb(S_AXI_GP0_WSTRB),
    .S_AXI_GP0_wvalid(S_AXI_GP0_WVALID),

    .S_AXI_GP1_ACLK(clk40),
    .S_AXI_GP1_ARESETN(clk40_rstn),
    .S_AXI_GP1_araddr(S_AXI_GP1_ARADDR),
    .S_AXI_GP1_arburst(S_AXI_GP1_ARBURST),
    .S_AXI_GP1_arcache(S_AXI_GP1_ARCACHE),
    .S_AXI_GP1_arid(S_AXI_GP1_ARID),
    .S_AXI_GP1_arlen(S_AXI_GP1_ARLEN),
    .S_AXI_GP1_arlock(1'b0),
    .S_AXI_GP1_arprot(S_AXI_GP1_ARPROT),
    .S_AXI_GP1_arqos(4'b000),
    .S_AXI_GP1_arready(S_AXI_GP1_ARREADY),
    .S_AXI_GP1_arsize(S_AXI_GP1_ARSIZE),
    .S_AXI_GP1_arvalid(S_AXI_GP1_ARVALID),
    .S_AXI_GP1_awaddr(S_AXI_GP1_AWADDR),
    .S_AXI_GP1_awburst(S_AXI_GP1_AWBURST),
    .S_AXI_GP1_awcache(S_AXI_GP1_AWCACHE),
    .S_AXI_GP1_awid(S_AXI_GP1_AWID),
    .S_AXI_GP1_awlen(S_AXI_GP1_AWLEN),
    .S_AXI_GP1_awlock(1'b0),
    .S_AXI_GP1_awprot(S_AXI_GP1_AWPROT),
    .S_AXI_GP1_awqos(4'b0000),
    .S_AXI_GP1_awregion(4'b0000),
    .S_AXI_GP1_awready(S_AXI_GP1_AWREADY),
    .S_AXI_GP1_awsize(S_AXI_GP1_AWSIZE),
    .S_AXI_GP1_awvalid(S_AXI_GP1_AWVALID),
    .S_AXI_GP1_bid(),
    .S_AXI_GP1_bready(S_AXI_GP1_BREADY),
    .S_AXI_GP1_bresp(S_AXI_GP1_BRESP),
    .S_AXI_GP1_bvalid(S_AXI_GP1_BVALID),
    .S_AXI_GP1_rdata(S_AXI_GP1_RDATA),
    .S_AXI_GP1_rid(),
    .S_AXI_GP1_rlast(S_AXI_GP1_RLAST),
    .S_AXI_GP1_rready(S_AXI_GP1_RREADY),
    .S_AXI_GP1_rresp(S_AXI_GP1_RRESP),
    .S_AXI_GP1_rvalid(S_AXI_GP1_RVALID),
    .S_AXI_GP1_wdata(S_AXI_GP1_WDATA),
    .S_AXI_GP1_wlast(S_AXI_GP1_WLAST),
    .S_AXI_GP1_wready(S_AXI_GP1_WREADY),
    .S_AXI_GP1_wstrb(S_AXI_GP1_WSTRB),
    .S_AXI_GP1_wvalid(S_AXI_GP1_WVALID),

    .S_AXI_HP0_ACLK(clk40),
    .S_AXI_HP0_ARESETN(clk40_rstn),
    .S_AXI_HP0_araddr(S_AXI_HP0_ARADDR),
    .S_AXI_HP0_arburst(S_AXI_HP0_ARBURST),
    .S_AXI_HP0_arcache(S_AXI_HP0_ARCACHE),
    .S_AXI_HP0_arid(S_AXI_HP0_ARID),
    .S_AXI_HP0_arlen(S_AXI_HP0_ARLEN),
    .S_AXI_HP0_arlock(1'b0),
    .S_AXI_HP0_arprot(S_AXI_HP0_ARPROT),
    .S_AXI_HP0_arqos(4'b0000),
    .S_AXI_HP0_arready(S_AXI_HP0_ARREADY),
    .S_AXI_HP0_arsize(S_AXI_HP0_ARSIZE),
    .S_AXI_HP0_arvalid(S_AXI_HP0_ARVALID),
    .S_AXI_HP0_awaddr(S_AXI_HP0_AWADDR),
    .S_AXI_HP0_awburst(S_AXI_HP0_AWBURST),
    .S_AXI_HP0_awcache(S_AXI_HP0_AWCACHE),
    .S_AXI_HP0_awid(S_AXI_HP0_AWID),
    .S_AXI_HP0_awlen(S_AXI_HP0_AWLEN),
    .S_AXI_HP0_awlock(1'b0),
    .S_AXI_HP0_awprot(S_AXI_HP0_AWPROT),
    .S_AXI_HP0_awqos(4'b0000),
    .S_AXI_HP0_awready(S_AXI_HP0_AWREADY),
    .S_AXI_HP0_awsize(S_AXI_HP0_AWSIZE),
    .S_AXI_HP0_awvalid(S_AXI_HP0_AWVALID),
    .S_AXI_HP0_bid(),
    .S_AXI_HP0_bready(S_AXI_HP0_BREADY),
    .S_AXI_HP0_bresp(S_AXI_HP0_BRESP),
    .S_AXI_HP0_bvalid(S_AXI_HP0_BVALID),
    .S_AXI_HP0_rdata(S_AXI_HP0_RDATA),
    .S_AXI_HP0_rid(),
    .S_AXI_HP0_rlast(S_AXI_HP0_RLAST),
    .S_AXI_HP0_rready(S_AXI_HP0_RREADY),
    .S_AXI_HP0_rresp(S_AXI_HP0_RRESP),
    .S_AXI_HP0_rvalid(S_AXI_HP0_RVALID),
    .S_AXI_HP0_wdata(S_AXI_HP0_WDATA),
    .S_AXI_HP0_wlast(S_AXI_HP0_WLAST),
    .S_AXI_HP0_wready(S_AXI_HP0_WREADY),
    .S_AXI_HP0_wstrb(S_AXI_HP0_WSTRB),
    .S_AXI_HP0_wvalid(S_AXI_HP0_WVALID),

    .S_AXI_HP1_ACLK(clk40),
    .S_AXI_HP1_ARESETN(clk40_rstn),
    .S_AXI_HP1_araddr(S_AXI_HP1_ARADDR),
    .S_AXI_HP1_arburst(S_AXI_HP1_ARBURST),
    .S_AXI_HP1_arcache(S_AXI_HP1_ARCACHE),
    .S_AXI_HP1_arid(S_AXI_HP1_ARID),
    .S_AXI_HP1_arlen(S_AXI_HP1_ARLEN),
    .S_AXI_HP1_arlock(1'b0),
    .S_AXI_HP1_arprot(S_AXI_HP1_ARPROT),
    .S_AXI_HP1_arqos(4'b0000),
    .S_AXI_HP1_arready(S_AXI_HP1_ARREADY),
    .S_AXI_HP1_arsize(S_AXI_HP1_ARSIZE),
    .S_AXI_HP1_arvalid(S_AXI_HP1_ARVALID),
    .S_AXI_HP1_awaddr(S_AXI_HP1_AWADDR),
    .S_AXI_HP1_awburst(S_AXI_HP1_AWBURST),
    .S_AXI_HP1_awcache(S_AXI_HP1_AWCACHE),
    .S_AXI_HP1_awid(S_AXI_HP1_AWID),
    .S_AXI_HP1_awlen(S_AXI_HP1_AWLEN),
    .S_AXI_HP1_awlock(1'b0),
    .S_AXI_HP1_awprot(S_AXI_HP1_AWPROT),
    .S_AXI_HP1_awqos(4'b0000),
    .S_AXI_HP1_awready(S_AXI_HP1_AWREADY),
    .S_AXI_HP1_awsize(S_AXI_HP1_AWSIZE),
    .S_AXI_HP1_awvalid(S_AXI_HP1_AWVALID),
    .S_AXI_HP1_bid(),
    .S_AXI_HP1_bready(S_AXI_HP1_BREADY),
    .S_AXI_HP1_bresp(S_AXI_HP1_BRESP),
    .S_AXI_HP1_bvalid(S_AXI_HP1_BVALID),
    .S_AXI_HP1_rdata(S_AXI_HP1_RDATA),
    .S_AXI_HP1_rid(),
    .S_AXI_HP1_rlast(S_AXI_HP1_RLAST),
    .S_AXI_HP1_rready(S_AXI_HP1_RREADY),
    .S_AXI_HP1_rresp(S_AXI_HP1_RRESP),
    .S_AXI_HP1_rvalid(S_AXI_HP1_RVALID),
    .S_AXI_HP1_wdata(S_AXI_HP1_WDATA),
    .S_AXI_HP1_wlast(S_AXI_HP1_WLAST),
    .S_AXI_HP1_wready(S_AXI_HP1_WREADY),
    .S_AXI_HP1_wstrb(S_AXI_HP1_WSTRB),
    .S_AXI_HP1_wvalid(S_AXI_HP1_WVALID),

    // ARM DMA
    .o_cvita_dma_tdata(o_cvita_dma_tdata),
    .o_cvita_dma_tlast(o_cvita_dma_tlast),
    .o_cvita_dma_tready(o_cvita_dma_tready),
    .o_cvita_dma_tvalid(o_cvita_dma_tvalid),

    .i_cvita_dma_tdata(i_cvita_dma_tdata),
    .i_cvita_dma_tlast(i_cvita_dma_tlast),
    .i_cvita_dma_tready(i_cvita_dma_tready),
    .i_cvita_dma_tvalid(i_cvita_dma_tvalid),

    // Misc Interrupts, GPIO, clk
    .IRQ_F2P(IRQ_F2P),

    .GPIO_0_tri_i(ps_gpio_in),
    .GPIO_0_tri_o(ps_gpio_out),
    .GPIO_0_tri_t(ps_gpio_tri),

    .JTAG0_TCK(DBA_CPLD_JTAG_TCK),
    .JTAG0_TMS(DBA_CPLD_JTAG_TMS),
    .JTAG0_TDI(DBA_CPLD_JTAG_TDI),
    .JTAG0_TDO(DBA_CPLD_JTAG_TDO),

  `ifndef N300
    .JTAG1_TCK(DBB_CPLD_JTAG_TCK),
    .JTAG1_TMS(DBB_CPLD_JTAG_TMS),
    .JTAG1_TDI(DBB_CPLD_JTAG_TDI),
    .JTAG1_TDO(DBB_CPLD_JTAG_TDO),
  `else
    .JTAG1_TCK(),
    .JTAG1_TMS(),
    .JTAG1_TDI(),
    .JTAG1_TDO('b0),
  `endif

    .FCLK_CLK0(FCLK_CLK0),
    .FCLK_RESET0_N(FCLK_RESET0_N),
    .FCLK_CLK1(FCLK_CLK1),
    .FCLK_RESET1_N(),
    .FCLK_CLK2(FCLK_CLK2),
    .FCLK_RESET2_N(),
    .FCLK_CLK3(FCLK_CLK3),
    .FCLK_RESET3_N(),

    .WR_UART_txd(wr_uart_rxd), // rx <-> tx
    .WR_UART_rxd(wr_uart_txd), // rx <-> tx

    .USBIND_0_port_indctl(),
    .USBIND_0_vbus_pwrfault(),
    .USBIND_0_vbus_pwrselect(),

    // Outward connections to the pins
    .MIO(MIO),
    .DDR_cas_n(DDR_CAS_n),
    .DDR_cke(DDR_CKE),
    .DDR_ck_n(DDR_Clk_n),
    .DDR_ck_p(DDR_Clk),
    .DDR_cs_n(DDR_CS_n),
    .DDR_reset_n(DDR_DRSTB),
    .DDR_odt(DDR_ODT),
    .DDR_ras_n(DDR_RAS_n),
    .DDR_we_n(DDR_WEB),
    .DDR_ba(DDR_BankAddr),
    .DDR_addr(DDR_Addr),
    .DDR_VRN(DDR_VRN),
    .DDR_VRP(DDR_VRP),
    .DDR_dm(DDR_DM),
    .DDR_dq(DDR_DQ),
    .DDR_dqs_n(DDR_DQS_n),
    .DDR_dqs_p(DDR_DQS),
    .PS_SRSTB(PS_SRSTB),
    .PS_CLK(PS_CLK),
    .PS_PORB(PS_PORB)
  );

  ///////////////////////////////////////////////////////////////////////////////////
  //
  // Xilinx DDR3 Controller and PHY.
  //
  ///////////////////////////////////////////////////////////////////////////////////
/*
  wire         ddr3_axi_clk;           // 1/4 DDR external clock rate (200MHz)
  wire         ddr3_axi_rst;           // Synchronized to ddr_sys_clk
  wire         ddr3_running;           // DRAM calibration complete.
  wire [11:0]  device_temp;

  // Slave Interface Write Address Ports
  wire [3:0]   ddr3_axi_awid;
  wire [31:0]  ddr3_axi_awaddr;
  wire [7:0]   ddr3_axi_awlen;
  wire [2:0]   ddr3_axi_awsize;
  wire [1:0]   ddr3_axi_awburst;
  wire [0:0]   ddr3_axi_awlock;
  wire [3:0]   ddr3_axi_awcache;
  wire [2:0]   ddr3_axi_awprot;
  wire [3:0]   ddr3_axi_awqos;
  wire         ddr3_axi_awvalid;
  wire         ddr3_axi_awready;
  // Slave Interface Write Data Ports
  wire [255:0] ddr3_axi_wdata;
  wire [31:0]  ddr3_axi_wstrb;
  wire         ddr3_axi_wlast;
  wire         ddr3_axi_wvalid;
  wire         ddr3_axi_wready;
  // Slave Interface Write Response Ports
  wire         ddr3_axi_bready;
  wire [3:0]   ddr3_axi_bid;
  wire [1:0]   ddr3_axi_bresp;
  wire         ddr3_axi_bvalid;
  // Slave Interface Read Address Ports
  wire [3:0]   ddr3_axi_arid;
  wire [31:0]  ddr3_axi_araddr;
  wire [7:0]   ddr3_axi_arlen;
  wire [2:0]   ddr3_axi_arsize;
  wire [1:0]   ddr3_axi_arburst;
  wire [0:0]   ddr3_axi_arlock;
  wire [3:0]   ddr3_axi_arcache;
  wire [2:0]   ddr3_axi_arprot;
  wire [3:0]   ddr3_axi_arqos;
  wire         ddr3_axi_arvalid;
  wire         ddr3_axi_arready;
  // Slave Interface Read Data Ports
  wire         ddr3_axi_rready;
  wire [3:0]   ddr3_axi_rid;
  wire [255:0] ddr3_axi_rdata;
  wire [1:0]   ddr3_axi_rresp;
  wire         ddr3_axi_rlast;
  wire         ddr3_axi_rvalid;

  reg      ddr3_axi_rst_reg_n;

  // Copied this reset circuit from example design.
  always @(posedge ddr3_axi_clk)
    ddr3_axi_rst_reg_n <= ~ddr3_axi_rst;


  // Instantiate the DDR3 MIG core
  //
  // The top-level IP block has no parameters defined for some reason.
  // Most of configurable parameters are hard-coded in the mig so get
  // some additional knobs we pull those out into verilog headers.
  //
  // Synthesis params:  ip/ddr3_32bit/ddr3_32bit_mig_parameters.vh
  // Simulation params: ip/ddr3_32bit/ddr3_32bit_mig_sim_parameters.vh

  ddr3_32bit u_ddr3_32bit (
    // Memory interface ports
    .ddr3_addr                      (ddr3_addr),
    .ddr3_ba                        (ddr3_ba),
    .ddr3_cas_n                     (ddr3_cas_n),
    .ddr3_ck_n                      (ddr3_ck_n),
    .ddr3_ck_p                      (ddr3_ck_p),
    .ddr3_cke                       (ddr3_cke),
    .ddr3_ras_n                     (ddr3_ras_n),
    .ddr3_reset_n                   (ddr3_reset_n),
    .ddr3_we_n                      (ddr3_we_n),
    .ddr3_dq                        (ddr3_dq),
    .ddr3_dqs_n                     (ddr3_dqs_n),
    .ddr3_dqs_p                     (ddr3_dqs_p),
    .init_calib_complete            (ddr3_running),
    .device_temp_i                  (device_temp),

    .ddr3_cs_n                      (ddr3_cs_n),
    .ddr3_dm                        (ddr3_dm),
    .ddr3_odt                       (ddr3_odt),
    // Application interface ports
    .ui_clk                         (ddr3_axi_clk),  // 200Hz clock out
    .ui_clk_sync_rst                (ddr3_axi_rst),  // Active high Reset signal synchronised to 200 MHz.
    .aresetn                        (ddr3_axi_rst_reg_n),
    .app_sr_req                     (1'b0),
    .app_sr_active                  (),
    .app_ref_req                    (1'b0),
    .app_ref_ack                    (),
    .app_zq_req                     (1'b0),
    .app_zq_ack                     (),
    // Slave Interface Write Address Ports
    .s_axi_awid                     (ddr3_axi_awid),
    .s_axi_awaddr                   (ddr3_axi_awaddr),
    .s_axi_awlen                    (ddr3_axi_awlen),
    .s_axi_awsize                   (ddr3_axi_awsize),
    .s_axi_awburst                  (ddr3_axi_awburst),
    .s_axi_awlock                   (ddr3_axi_awlock),
    .s_axi_awcache                  (ddr3_axi_awcache),
    .s_axi_awprot                   (ddr3_axi_awprot),
    .s_axi_awqos                    (ddr3_axi_awqos),
    .s_axi_awvalid                  (ddr3_axi_awvalid),
    .s_axi_awready                  (ddr3_axi_awready),
    // Slave Interface Write Data Ports
    .s_axi_wdata                    (ddr3_axi_wdata),
    .s_axi_wstrb                    (ddr3_axi_wstrb),
    .s_axi_wlast                    (ddr3_axi_wlast),
    .s_axi_wvalid                   (ddr3_axi_wvalid),
    .s_axi_wready                   (ddr3_axi_wready),
    // Slave Interface Write Response Ports
    .s_axi_bid                      (ddr3_axi_bid),
    .s_axi_bresp                    (ddr3_axi_bresp),
    .s_axi_bvalid                   (ddr3_axi_bvalid),
    .s_axi_bready                   (ddr3_axi_bready),
    // Slave Interface Read Address Ports
    .s_axi_arid                     (ddr3_axi_arid),
    .s_axi_araddr                   (ddr3_axi_araddr),
    .s_axi_arlen                    (ddr3_axi_arlen),
    .s_axi_arsize                   (ddr3_axi_arsize),
    .s_axi_arburst                  (ddr3_axi_arburst),
    .s_axi_arlock                   (ddr3_axi_arlock),
    .s_axi_arcache                  (ddr3_axi_arcache),
    .s_axi_arprot                   (ddr3_axi_arprot),
    .s_axi_arqos                    (ddr3_axi_arqos),
    .s_axi_arvalid                  (ddr3_axi_arvalid),
    .s_axi_arready                  (ddr3_axi_arready),
    // Slave Interface Read Data Ports
    .s_axi_rid                      (ddr3_axi_rid),
    .s_axi_rdata                    (ddr3_axi_rdata),
    .s_axi_rresp                    (ddr3_axi_rresp),
    .s_axi_rlast                    (ddr3_axi_rlast),
    .s_axi_rvalid                   (ddr3_axi_rvalid),
    .s_axi_rready                   (ddr3_axi_rready),
    // System Clock Ports
    .sys_clk_p                      (sys_clk_p),
    .sys_clk_n                      (sys_clk_n),
    .clk_ref_i                      (bus_clk),

    .sys_rst                        (~global_rst) // IJB. Poorly named active low. Should change RST_ACT_LOW.
  );*/

  // Temperature monitor module
  mig_7series_v4_0_tempmon #(
     .TEMP_MON_CONTROL("INTERNAL"),
     .XADC_CLK_PERIOD(5000 /* 200MHz clock period in ps */)
  ) tempmon_i (
     .clk(bus_clk), .xadc_clk(bus_clk), .rst(bus_rst),
     .device_temp_i(12'd0 /* ignored */), .device_temp(device_temp)
  );

  ///////////////////////////////////////////////////////
  //
  // DB PS SPI Connections
  //
  ///////////////////////////////////////////////////////

  wire [3:0] adc_reset;

  //SPI stuff

  assign DBA_ADC_A_SCLK = spi0_sclk; //from PS
  assign DBA_ADC_A_CS_N = spi0_ss1; //check select 1
  assign DBA_ADC_A_SDI = spi0_mosi; //data Slave In

  assign DBA_ADC_B_SCLK = spi0_sclk; //from PS
  assign DBA_ADC_B_CS_N = spi0_ss2; //check select 2
  assign DBA_ADC_B_SDI = spi0_mosi; //data Slave In

  assign DBA_LMK_SCK = spi0_sclk;
  assign DBA_LMK_CS_N = spi0_ss0;
  assign DBA_LMK_SDI = spi0_mosi;
  assign DBA_LMK_SYNC = 1'b0;

  assign spi0_miso = (~spi0_ss1 & DBA_ADC_A_SDOUT) | (~spi0_ss2 & DBA_ADC_B_SDOUT) | (~spi0_ss0 & DBA_LMK_READBACK); //SPI Master In

  assign DBA_PDAC_SDI = spi0_ss3; //"heads up whenever you connect the phase dac lines, the SDI and CS are swapped on the DB" -D Jepson
  assign DBA_PDAC_SCLK = spi0_sclk;
  assign DBA_PDAC_CS_N = spi0_mosi; //"heads up whenever you connect the phase dac lines, the SDI and CS are swapped on the DB"

  assign DBB_ADC_A_SCLK = spi1_sclk; //from PS
  assign DBB_ADC_A_CS_N = spi1_ss1; //check select 1
  assign DBB_ADC_A_SDI = spi1_mosi; //data Slave In

  assign DBB_ADC_B_SCLK = spi1_sclk; //from PS
  assign DBB_ADC_B_CS_N = spi1_ss2; //check select 2
  assign DBB_ADC_B_SDI = spi1_mosi; //data Slave In

  assign DBB_LMK_SCK = spi1_sclk;
  assign DBB_LMK_CS_N = spi1_ss0;
  assign DBB_LMK_SDI = spi1_mosi;
  assign DBB_LMK_SYNC = 1'b0;

  assign spi1_miso = (~spi1_ss1 & DBB_ADC_A_SDOUT) | (~spi1_ss2 & DBB_ADC_B_SDOUT) | (~spi1_ss0 & DBB_LMK_READBACK); //SPI Master In

  assign DBB_PDAC_SDI = spi1_ss3; //"heads up whenever you connect the phase dac lines, the SDI and CS are swapped on the DB" -D Jepson
  assign DBB_PDAC_SCLK = spi1_sclk;
  assign DBB_PDAC_CS_N = spi1_mosi; //"heads up whenever you connect the phase dac lines, the SDI and CS are swapped on the DB"

  ///////////////////////////////////////////////////////
  //
  // N3xx CORE
  //
  ///////////////////////////////////////////////////////

  wire  rx_dbA_adcA_stb;
  wire  [63:0]     rx_dbA_adcA;
  wire  rx_dbA_adcB_stb;
  wire  [63:0]     rx_dbA_adcB;
  wire  rx_dbB_adcA_stb;
  wire  [63:0]     rx_dbB_adcA;
  wire  rx_dbB_adcB_stb;
  wire  [63:0]     rx_dbB_adcB;
  wire  sysref_pulse;
  reg   pps_radioclk2x;
  wire  sync_in;
  wire  sync_out;



  wire [31:0] build_datestamp;

  USR_ACCESSE2 usr_access_i (
    .DATA(build_datestamp), .CFGCLK(), .DATAVALID()
  );

  n3xx_core_eiscat #(
    .REG_AWIDTH(14),
    .BUS_CLK_RATE(BUS_CLK_RATE),
    .ENABLE_DDR3(0),
    .FP_GPIO_WIDTH(FP_GPIO_WIDTH),
    .NUM_RADIO_CORES(1),
    .NUM_CHANNELS_PER_RADIO(16),
    .NUM_CHANNELS(16),
    .NUM_DBOARDS(2)

  ) n3xx_core_eiscat (
    // Clocks and resets
  `ifdef NO_DB
    .radio_clk(bus_clk),
    .radio_rst(bus_rst),
  `else
    .radio_clk(radio_clk_2x),
    .radio_rst(radio_rst),
  `endif
    .bus_clk(bus_clk),
    .bus_rst(bus_rst),

    // Clocking and PPS Controls/Indicators
    .pps(pps_radioclk2x),
    .pps_select(pps_select),
    .pps_out_enb(pps_out_enb),
    .pps_select_sfp(pps_select_sfp),
    .ref_clk_reset(),
    .meas_clk_reset(meas_clk_reset),
    .ref_clk_locked(1'b1),
    .meas_clk_locked(meas_clk_locked),

    .s_axi_aclk(clk40),
    .s_axi_aresetn(clk40_rstn),
    // AXI4-Lite: Write address port (domain: s_axi_aclk)
    .s_axi_awaddr(M_AXI_XBAR_AWADDR),
    .s_axi_awvalid(M_AXI_XBAR_AWVALID),
    .s_axi_awready(M_AXI_XBAR_AWREADY),
    // AXI4-Lite: Write data port (domain: s_axi_aclk)
    .s_axi_wdata(M_AXI_XBAR_WDATA),
    .s_axi_wstrb(M_AXI_XBAR_WSTRB),
    .s_axi_wvalid(M_AXI_XBAR_WVALID),
    .s_axi_wready(M_AXI_XBAR_WREADY),
    // AXI4-Lite: Write response port (domain: s_axi_aclk)
    .s_axi_bresp(M_AXI_XBAR_BRESP),
    .s_axi_bvalid(M_AXI_XBAR_BVALID),
    .s_axi_bready(M_AXI_XBAR_BREADY),
    // AXI4-Lite: Read address port (domain: s_axi_aclk)
    .s_axi_araddr(M_AXI_XBAR_ARADDR),
    .s_axi_arvalid(M_AXI_XBAR_ARVALID),
    .s_axi_arready(M_AXI_XBAR_ARREADY),
    // AXI4-Lite: Read data port (domain: s_axi_aclk)
    .s_axi_rdata(M_AXI_XBAR_RDATA),
    .s_axi_rresp(M_AXI_XBAR_RRESP),
    .s_axi_rvalid(M_AXI_XBAR_RVALID),
    .s_axi_rready(M_AXI_XBAR_RREADY),

    //radio inputs from EISCAT daughtercards
    .rxAA_stb(rx_dbA_adcA_stb),//input        rxAA_stb,
    .rxAA(rx_dbA_adcA),//input [63:0] rxAA,
    .rxAB_stb(rx_dbA_adcB_stb),//input        rxAB_stb,
    .rxAB(rx_dbA_adcB),//input [63:0] rxAB,
    .rxBA_stb(rx_dbB_adcA_stb),//input        rxBA_stb,
    .rxBA(rx_dbB_adcA),//input [63:0] rxBA,
    .rxBB_stb(rx_dbB_adcB_stb),//input        rxBB_stb,
    .rxBB(rx_dbB_adcB),//input [63:0] rxBB,

    // ps gpio source
    //.ps_gpio_tri(ps_gpio_tri[FP_GPIO_WIDTH+FP_GPIO_OFFSET-1:FP_GPIO_OFFSET]),
    //.ps_gpio_out(ps_gpio_out[FP_GPIO_WIDTH+FP_GPIO_OFFSET-1:FP_GPIO_OFFSET]),
    //.ps_gpio_in(ps_gpio_in[FP_GPIO_WIDTH+FP_GPIO_OFFSET-1:FP_GPIO_OFFSET]),
    // FP_GPIO
    //.fp_gpio_inout(FPGA_GPIO),
    
    //DMA
    .dmao_tdata(i_cvita_dma_tdata),
    .dmao_tlast(i_cvita_dma_tlast),
    .dmao_tready(i_cvita_dma_tready),
    .dmao_tvalid(i_cvita_dma_tvalid),

    .dmai_tdata(o_cvita_dma_tdata),
    .dmai_tlast(o_cvita_dma_tlast),
    .dmai_tready(o_cvita_dma_tready),
    .dmai_tvalid(o_cvita_dma_tvalid),

    // VITA to Ethernet
    .v2e0_tdata(v2e0_tdata),
    .v2e0_tvalid(v2e0_tvalid),
    .v2e0_tlast(v2e0_tlast),
    .v2e0_tready(v2e0_tready),

    .v2e1_tdata(v2e1_tdata),
    .v2e1_tlast(v2e1_tlast),
    .v2e1_tvalid(v2e1_tvalid),
    .v2e1_tready(v2e1_tready),

    // Ethernet to VITA
    .e2v0_tdata(e2v0_tdata),
    .e2v0_tlast(e2v0_tlast),
    .e2v0_tvalid(e2v0_tvalid),
    .e2v0_tready(e2v0_tready),

    .e2v1_tdata(e2v1_tdata),
    .e2v1_tlast(e2v1_tlast),
    .e2v1_tvalid(e2v1_tvalid),
    .e2v1_tready(e2v1_tready),

    //from npio core 0 (to eiscat radio core)
    .npio2eiscat_tdata(npio2eiscat_tdata),
    .npio2eiscat_tlast(npio2eiscat_tlast),
    .npio2eiscat_tvalid(npio2eiscat_tvalid),
    .npio2eiscat_tready(npio2eiscat_tready),

    //to npio core 0 (from eiscat radio core)
    .eiscat2npio_tdata(eiscat2npio_tdata),
    .eiscat2npio_tlast(eiscat2npio_tlast),
    .eiscat2npio_tvalid(eiscat2npio_tvalid),
    .eiscat2npio_tready(eiscat2npio_tready),

    //regport interface to npio
    .reg_wr_req_npio(reg_wr_req_npio),
    .reg_wr_addr_npio(reg_wr_addr_npio),
    .reg_wr_data_npio(reg_wr_data_npio),
    .reg_rd_req_npio(reg_rd_req_npio),
    .reg_rd_addr_npio(reg_rd_addr_npio),
    .reg_rd_resp_npio(reg_rd_resp_npio),
    .reg_rd_data_npio(reg_rd_data_npio),

    .build_datestamp(build_datestamp),
    .xadc_readback({20'h0, device_temp}),
    .sfp_ports_info({sfp_port1_info, sfp_port0_info}),
    .sysref_pulse(sysref_pulse)
  );

  // //////////////////////////////////////////////////////////////////////
  //
  // Daughterboard Cores & SYSREF Generation Logic
  //
  // //////////////////////////////////////////////////////////////////////
  wire [49:0] bRegPortInFlatA;
  wire [33:0] bRegPortOutFlatA;
  wire [49:0] bRegPortInFlatB;
  wire [33:0] bRegPortOutFlatB;
  wire          sysref_fpga;

  wire          reg_portA_rd;
  wire          reg_portA_wr;
  wire [14-1:0] reg_portA_addr;
  wire [32-1:0] reg_portA_wr_data;
  wire [32-1:0] reg_portA_rd_data;
  wire          reg_portA_ready;
  wire          validA_unused;

  assign bRegPortInFlatA = {2'b0, reg_portA_addr, reg_portA_wr_data, reg_portA_rd, reg_portA_wr};
  assign {reg_portA_rd_data, validA_unused, reg_portA_ready} = bRegPortOutFlatA;


  wire          reg_portB_rd;
  wire          reg_portB_wr;
  wire [14-1:0] reg_portB_addr;
  wire [32-1:0] reg_portB_wr_data;
  wire [32-1:0] reg_portB_rd_data;
  wire          reg_portB_ready;
  wire          validB_unused;

  assign bRegPortInFlatB = {2'b0, reg_portB_addr, reg_portB_wr_data, reg_portB_rd, reg_portB_wr};
  assign {reg_portB_rd_data, validB_unused, reg_portB_ready} = bRegPortOutFlatB;


  wire          s2SysRefGoCombined;
  wire          s2SysRefGo;

  DbCore
    dba_core (
      .aReset                (~FCLK_RESET0_N)       ,   //: in  std_logic;
      .bReset                (clk40_rst)                ,   //: in  std_logic;
      .BusClk                (clk40)               ,   //: in  std_logic;
      .Clk40                 (clk40)               ,   //: in  std_logic;
      .MeasClk               (meas_clk)            ,   //: in  std_logic;
      .FpgaClk_p             (DBA_FPGA_CLK_P)      ,   //: in  std_logic;
      .FpgaClk_n             (DBA_FPGA_CLK_N)      ,   //: in  std_logic;
      .SampleClk1xOut        (radio_clk)           ,   //: out std_logic;
      .SampleClk1x           (radio_clk)           ,   //: in  std_logic;
      .SampleClk2xOut        (radio_clk_2x)        ,   //: out std_logic;
      .SampleClk2x           (radio_clk_2x)        ,   //: in  std_logic;
      .bRegPortInFlat        (bRegPortInFlatA),        //in  std_logic_vector(49:0)
      .bRegPortOutFlat       (bRegPortOutFlatA),      //out std_logic_vector(33:0)
      .kDbId                 (16'h180)             ,
      .kSlotId               (1'b0)                ,
      .sSysRefToFpgaCore     (sysref_fpga)         ,   //: in  std_logic;
      .JesdRefClk_p          (USRPIO_A_MGTCLK_P)   ,   //
      .JesdRefClk_n          (USRPIO_A_MGTCLK_N)   ,   //: in  std_logic;
      .aAdcRx_p              (USRPIO_A_RX_P)       ,   //
      .aAdcRx_n              (USRPIO_A_RX_N)       ,   //: in  std_logic_vector(3 downto 0);
      .aSyncAdcAOut_p        (DBA_ADC_A_SYNC_N)    ,   // NOTE: switched N and P pins here.
      .aSyncAdcAOut_n        (DBA_ADC_A_SYNC_P)    ,   //: out std_logic;
      .aSyncAdcBOut_p        (DBA_ADC_B_SYNC_N)    ,   //
      .aSyncAdcBOut_n        (DBA_ADC_B_SYNC_P)    ,   //: out std_logic;
      .aAdcASync             ()                    ,   // debug out
      .aAdcBSync             ()                    ,   // debug out
      .s2SysRefGo            (s2SysRefGo)          ,   // temporary connection from regport
      .s2AdcDataValidA       (rx_dbA_adcA_stb)     ,   //: out std_logic;
      .s2AdcDataSamples0A    (rx_dbA_adcA[63:48])  ,   //: out std_logic_vector(15 downto 0);
      .s2AdcDataSamples1A    (rx_dbA_adcA[47:32])  ,   //: out std_logic_vector(15 downto 0);
      .s2AdcDataSamples2A    (rx_dbA_adcA[31:16])  ,   //: out std_logic_vector(15 downto 0);
      .s2AdcDataSamples3A    (rx_dbA_adcA[15:0] )  ,   //: out std_logic_vector(15 downto 0);
      .s2AdcDataValidB       (rx_dbA_adcB_stb)     ,   //: out std_logic;
      .s2AdcDataSamples0B    (rx_dbA_adcB[63:48])  ,   //: out std_logic_vector(15 downto 0);
      .s2AdcDataSamples1B    (rx_dbA_adcB[47:32])  ,   //: out std_logic_vector(15 downto 0);
      .s2AdcDataSamples2B    (rx_dbA_adcB[31:16])  ,   //: out std_logic_vector(15 downto 0);
      .s2AdcDataSamples3B    (rx_dbA_adcB[15:0] )  ,   //: out std_logic_vector(15 downto 0);
      .RefClk                (ref_clk)             ,   //: in  std_logic;
      .rPpsPulse             (pps_refclk)          ,   //: in  std_logic;
      .rGatedPulseToPin      (UNUSED_PIN_TDCA_0)   ,   //inout std_logic
      .sGatedPulseToPin      (UNUSED_PIN_TDCA_1)   ,   //inout std_logic
      .rRpTransfer           ()                    ,   // debug out
      .sSpTransfer           ()                    ,   // debug out
      .sPps                  (pps_radioclk1x)      ,   //: out std_logic;
      .sPpsToIob             (pps_radioclk1x_iob)  ,   //out std_logic
      .WrRefClk              (wr_ref_clk)          ,   //in  std_logic
      .rWrPpsPulse           (pps_wr_refclk)       ,   //in  std_logic
      .rWrGatedPulseToPin    (UNUSED_PIN_TDCA_2)   ,   //inout std_logic
      .sWrGatedPulseToPin    (UNUSED_PIN_TDCA_3)   ,   //inout std_logic
      .rWrRpTransfer         ()                    ,   //out std_logic
      .sWrSpTransfer         ()                    ,   //out std_logic
      .aAdcSpiEn             (DBA_ADC_SPI_EN)      ,   //: out   std_logic;
      .aAdcAReset            (DBA_ADC_A_RESET)     ,   //: out   std_logic;
      .aAdcBReset            (DBA_ADC_B_RESET)     ,   //: out   std_logic;
      .aLmkStatus            (DBA_LMK_STATUS)      ,   //: in    std_logic;
      .aTmonAlert_n          (DBA_TMON_ALERT_N)    ,   //: in    std_logic;
      .aVmonAlert            (DBA_VMON_ALERT)      ,   //: in    std_logic;
      .aDbCtrlEn_n           (DBA_DB_CTRL_EN_N)    ,   //: out   std_logic;
      .aLmkSpiEn             (DBA_LMK_SPI_EN)      ,   //: out   std_logic;
      .aDbPwrEn              (DBA_DC_PWR_EN)       ,   //: out   std_logic;
      .aLnaCtrlEn            (DBA_LNA_CTRL_EN)     ,   //: out   std_logic;
      .aDbaCh0En_n           (DBA_CH0_EN_N)        ,   //: out   std_logic;
      .aDbaCh1En_n           (DBA_CH1_EN_N)        ,   //: out   std_logic;
      .aDbaCh2En_n           (DBA_CH2_EN_N)        ,   //: out   std_logic;
      .aDbaCh3En_n           (DBA_CH3_EN_N)        ,   //: out   std_logic;
      .aDbaCh4En_n           (DBA_CH4_EN_N)        ,   //: out   std_logic;
      .aDbaCh5En_n           (DBA_CH5_EN_N)        ,   //: out   std_logic;
      .aDbaCh6En_n           (DBA_CH6_EN_N)        ,   //: out   std_logic;
      .aDbaCh7En_n           (DBA_CH7_EN_N)            //: out   std_logic
    );

  DbCore
    dbb_core (
      .aReset                (~FCLK_RESET0_N)       ,   //: in  std_logic;
      .bReset                (clk40_rst)                ,   //: in  std_logic;
      .BusClk                (clk40)              ,   //: in  std_logic;
      .Clk40                 (clk40)               ,   //: in  std_logic;
      .MeasClk               (meas_clk)            ,   //: in  std_logic;
      .FpgaClk_p             (DBB_FPGA_CLK_P)        ,   //: in  std_logic;
      .FpgaClk_n             (DBB_FPGA_CLK_N)        ,   //: in  std_logic;
      .SampleClk1xOut        (radio_clkB)          ,   //: out std_logic;
      .SampleClk1x           (radio_clk)           ,   //: in  std_logic;
      .SampleClk2xOut        (radio_clk_2xB)       ,   //: out std_logic;
      .SampleClk2x           (radio_clk_2x)        ,   //: in  std_logic;
      .bRegPortInFlat        (bRegPortInFlatB),        //in  std_logic_vector(49:0)
      .bRegPortOutFlat       (bRegPortOutFlatB),      //out std_logic_vector(33:0)
      .kDbId                 (16'h180)             ,
      .kSlotId               (1'b1)                ,
      .sSysRefToFpgaCore     (sysref_fpga)         ,   //: in  std_logic;
      .JesdRefClk_p          (USRPIO_B_MGTCLK_P)   ,   //
      .JesdRefClk_n          (USRPIO_B_MGTCLK_N)   ,   //: in  std_logic;
      .aAdcRx_p              (USRPIO_B_RX_P)       ,   //
      .aAdcRx_n              (USRPIO_B_RX_N)       ,   //: in  std_logic_vector(3 downto 0);
      .aSyncAdcAOut_p        (DBB_ADC_A_SYNC_P)    ,   //
      .aSyncAdcAOut_n        (DBB_ADC_A_SYNC_N)    ,   //: out std_logic;
      .aSyncAdcBOut_p        (DBB_ADC_B_SYNC_P)    ,   //
      .aSyncAdcBOut_n        (DBB_ADC_B_SYNC_N)    ,   //: out std_logic;
      .aAdcASync             ()                    ,   // debug out
      .aAdcBSync             ()                    ,   // debug out
      .s2SysRefGo            ()                    ,   // temporary connection from regport
      .s2AdcDataValidA       (rx_dbB_adcA_stb)     ,   //: out std_logic;
      .s2AdcDataSamples0A    (rx_dbB_adcA[63:48])  ,   //: out std_logic_vector(15 downto 0);
      .s2AdcDataSamples1A    (rx_dbB_adcA[47:32])  ,   //: out std_logic_vector(15 downto 0);
      .s2AdcDataSamples2A    (rx_dbB_adcA[31:16])  ,   //: out std_logic_vector(15 downto 0);
      .s2AdcDataSamples3A    (rx_dbB_adcA[15:0] )  ,   //: out std_logic_vector(15 downto 0);
      .s2AdcDataValidB       (rx_dbB_adcB_stb)     ,   //: out std_logic;
      .s2AdcDataSamples0B    (rx_dbB_adcB[63:48])  ,   //: out std_logic_vector(15 downto 0);
      .s2AdcDataSamples1B    (rx_dbB_adcB[47:32])  ,   //: out std_logic_vector(15 downto 0);
      .s2AdcDataSamples2B    (rx_dbB_adcB[31:16])  ,   //: out std_logic_vector(15 downto 0);
      .s2AdcDataSamples3B    (rx_dbB_adcB[15:0] )  ,   //: out std_logic_vector(15 downto 0);
      .RefClk                (ref_clk)             ,   //: in  std_logic;
      .rPpsPulse             (pps_refclk)          ,   //: in  std_logic;
      .rGatedPulseToPin      (UNUSED_PIN_TDCB_0)   ,   //inout std_logic
      .sGatedPulseToPin      (UNUSED_PIN_TDCB_1)   ,   //inout std_logic
      .rRpTransfer           ()                    ,   //out std_logic
      .sSpTransfer           ()                    ,   //out std_logic
      .sPps                  ()                    ,   // only use the one from DB A
      .sPpsToIob             ()                    ,   //out std_logic
      .WrRefClk              (wr_ref_clk)          ,   //in  std_logic
      .rWrPpsPulse           (pps_wr_refclk)       ,   //in  std_logic
      .rWrGatedPulseToPin    (UNUSED_PIN_TDCB_2)   ,   //inout std_logic
      .sWrGatedPulseToPin    (UNUSED_PIN_TDCB_3)   ,   //inout std_logic
      .rWrRpTransfer         ()                    ,   //out std_logic
      .sWrSpTransfer         ()                    ,   //out std_logic
      .aAdcSpiEn             (DBB_ADC_SPI_EN)         ,   //: out   std_logic;
      .aAdcAReset            (DBB_ADC_A_RESET)        ,   //: out   std_logic;
      .aAdcBReset            (DBB_ADC_B_RESET)        ,   //: out   std_logic;
      .aLmkStatus            (DBB_LMK_STATUS)        ,   //: in    std_logic;
      .aTmonAlert_n          (DBB_TMON_ALERT_N)      ,   //: in    std_logic;
      .aVmonAlert            (DBB_VMON_ALERT)        ,   //: in    std_logic;
      .aDbCtrlEn_n           (DBB_DB_CTRL_EN_N)       ,   //: out   std_logic;
      .aLmkSpiEn             (DBB_LMK_SPI_EN)         ,   //: out   std_logic;
      .aDbPwrEn              (DBB_DC_PWR_EN)          ,   //: out   std_logic;
      .aLnaCtrlEn            (DBB_LNA_CTRL_EN)        ,   //: out   std_logic;
      .aDbaCh0En_n           (DBB_CH0_EN_N)          ,   //: out   std_logic;
      .aDbaCh1En_n           (DBB_CH1_EN_N)          ,   //: out   std_logic;
      .aDbaCh2En_n           (DBB_CH2_EN_N)          ,   //: out   std_logic;
      .aDbaCh3En_n           (DBB_CH3_EN_N)          ,   //: out   std_logic;
      .aDbaCh4En_n           (DBB_CH4_EN_N)          ,   //: out   std_logic;
      .aDbaCh5En_n           (DBB_CH5_EN_N)          ,   //: out   std_logic;
      .aDbaCh6En_n           (DBB_CH6_EN_N)          ,   //: out   std_logic;
      .aDbaCh7En_n           (DBB_CH7_EN_N)              //: out   std_logic
    );

  always @(posedge radio_clk_2x)
    if(radio_rst) begin
      pps_radioclk2x = 1'b0;
      //FPGA_TEST[0]   = 1'b0;
    end
    else begin
      pps_radioclk2x <= pps_radioclk1x;
      //FPGA_TEST[0]   <= pps_radioclk2x;
    end


  SysRefCore
    SysRefCorex (
      .aReset             (~FCLK_RESET0_N),   // in  std_logic;
      .SampleClk1xA       (radio_clk),        // in  std_logic;
      .SampleClk2xA       (radio_clk_2x),     // in  std_logic;
      .SampleClk2xB       (radio_clk_2xB),    // in  std_logic;
      .sSysRefToFpgaCore  (sysref_fpga),      // out std_logic;
      .s2SysRefDbaAdcA_p  (DBA_ADC_A_SYSREF_P),  //
      .s2SysRefDbaAdcA_n  (DBA_ADC_A_SYSREF_N),  // out std_logic;
      .s2SysRefDbaAdcB_p  (DBA_ADC_B_SYSREF_N),  //
      .s2SysRefDbaAdcB_n  (DBA_ADC_B_SYSREF_P),  // out std_logic;
      .s2SysRefDbbAdcA_p  (DBB_ADC_A_SYSREF_P),  //
      .s2SysRefDbbAdcA_n  (DBB_ADC_A_SYSREF_N),  // out std_logic;
      .s2SysRefDbbAdcB_p  (DBB_ADC_B_SYSREF_N),  //
      .s2SysRefDbbAdcB_n  (DBB_ADC_B_SYSREF_P),  // out std_logic;
      .s2SysRefGo         (s2SysRefGoCombined)   // in  std_logic From Radio!!!
    );

  // Combines assignment from DB A core (from the register bus) and the sysref_pulse
  // timed command coming from the Radio core. Both of these signals are in the
  // radio_clk_2x domain of DB A clock.
  assign s2SysRefGoCombined = s2SysRefGo | sysref_pulse;



  axil_to_ni_regport #(
    .RP_DWIDTH   (32),
    .RP_AWIDTH   (14),
    .TIMEOUT     (512)
  ) ni_regportA_inst (
    // Clock and reset
    .s_axi_aclk    (clk40),
    .s_axi_areset  (clk40_rst),
    // AXI4-Lite: Write address port (domain: s_axi_aclk)
    .s_axi_awaddr(M_AXI_JESD0_AWADDR),
    .s_axi_awvalid(M_AXI_JESD0_AWVALID),
    .s_axi_awready(M_AXI_JESD0_AWREADY),
    // AXI4-Lite: Write data port (domain: s_axi_aclk)
    .s_axi_wdata(M_AXI_JESD0_WDATA),
    .s_axi_wstrb(M_AXI_JESD0_WSTRB),
    .s_axi_wvalid(M_AXI_JESD0_WVALID),
    .s_axi_wready(M_AXI_JESD0_WREADY),
    // AXI4-Lite: Write response port (domain: s_axi_aclk)
    .s_axi_bresp(M_AXI_JESD0_BRESP),
    .s_axi_bvalid(M_AXI_JESD0_BVALID),
    .s_axi_bready(M_AXI_JESD0_BREADY),
    // AXI4-Lite: Read address port (domain: s_axi_aclk)
    .s_axi_araddr(M_AXI_JESD0_ARADDR),
    .s_axi_arvalid(M_AXI_JESD0_ARVALID),
    .s_axi_arready(M_AXI_JESD0_ARREADY),
    // AXI4-Lite: Read data port (domain: s_axi_aclk)
    .s_axi_rdata(M_AXI_JESD0_RDATA),
    .s_axi_rresp(M_AXI_JESD0_RRESP),
    .s_axi_rvalid(M_AXI_JESD0_RVALID),
    .s_axi_rready(M_AXI_JESD0_RREADY),
    // Register port
    .reg_port_in_rd    (reg_portA_rd),
    .reg_port_in_wt    (reg_portA_wr),
    .reg_port_in_addr  (reg_portA_addr),
    .reg_port_in_data  (reg_portA_wr_data),
    .reg_port_out_data (reg_portA_rd_data),
    .reg_port_out_ready(reg_portA_ready)
  );

  axil_to_ni_regport #(
    .RP_DWIDTH   (32),
    .RP_AWIDTH   (14),
    .TIMEOUT     (512)
  ) ni_regportB_inst (
    // Clock and reset
    .s_axi_aclk    (clk40),
    .s_axi_areset  (clk40_rst),
    // AXI4-Lite: Write address port (domain: s_axi_aclk)
    .s_axi_awaddr(M_AXI_JESD1_AWADDR),
    .s_axi_awvalid(M_AXI_JESD1_AWVALID),
    .s_axi_awready(M_AXI_JESD1_AWREADY),
    // AXI4-Lite: Write data port (domain: s_axi_aclk)
    .s_axi_wdata(M_AXI_JESD1_WDATA),
    .s_axi_wstrb(M_AXI_JESD1_WSTRB),
    .s_axi_wvalid(M_AXI_JESD1_WVALID),
    .s_axi_wready(M_AXI_JESD1_WREADY),
    // AXI4-Lite: Write response port (domain: s_axi_aclk)
    .s_axi_bresp(M_AXI_JESD1_BRESP),
    .s_axi_bvalid(M_AXI_JESD1_BVALID),
    .s_axi_bready(M_AXI_JESD1_BREADY),
    // AXI4-Lite: Read address port (domain: s_axi_aclk)
    .s_axi_araddr(M_AXI_JESD1_ARADDR),
    .s_axi_arvalid(M_AXI_JESD1_ARVALID),
    .s_axi_arready(M_AXI_JESD1_ARREADY),
    // AXI4-Lite: Read data port (domain: s_axi_aclk)
    .s_axi_rdata   (M_AXI_JESD1_RDATA),
    .s_axi_rresp   (M_AXI_JESD1_RRESP),
    .s_axi_rvalid  (M_AXI_JESD1_RVALID),
    .s_axi_rready  (M_AXI_JESD1_RREADY),
    // Register port
    .reg_port_in_rd    (reg_portB_rd),
    .reg_port_in_wt    (reg_portB_wr),
    .reg_port_in_addr  (reg_portB_addr),
    .reg_port_in_data  (reg_portB_wr_data),
    .reg_port_out_data (reg_portB_rd_data),
    .reg_port_out_ready(reg_portB_ready)
  );


  // //////////////////////////////////////////////////////////////////////
  //
  // LEDS
  //
  // //////////////////////////////////////////////////////////////////////

   assign PANEL_LED_LINK = ps_gpio_out[45];
   assign PANEL_LED_REF  = ps_gpio_out[46];
   assign PANEL_LED_GPS  = ps_gpio_out[47];


  /////////////////////////////////////////////////////////////////////
  //
  // PUDC Workaround
  //
  //////////////////////////////////////////////////////////////////////
  // This is a workaround for a silicon bug in Series 7 FPGA where a
  // race condition with the reading of PUDC during the erase of the FPGA
  // image cause glitches on output IO pins.
  //
  // Workaround:
  // - Define the PUDC pin in the XDC file with a pullup.
  // - Implements an IBUF on the PUDC input and make sure that it does
  //   not get optimized out.
  (* dont_touch = "true" *) wire fpga_pudc_b_buf;
  IBUF pudc_ibuf_i (
    .I(FPGA_PUDC_B),
    .O(fpga_pudc_b_buf));

endmodule
