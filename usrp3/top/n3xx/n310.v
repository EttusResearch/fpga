//
// Copyright 2016-2017 Ettus Research
//
module n310
(

   //inout [11:0] FpgaGpio,
   //output FpgaGpioEn,

   input FPGA_REFCLK_P,
   input FPGA_REFCLK_N,
   input REF_1PPS_IN,
   //input REF_1PPS_IN_MGMT,
   output REF_1PPS_OUT,

   //input NPIO_0_RX0_P,
   //input NPIO_0_RX0_N,
   //input NPIO_0_RX1_P,
   //input NPIO_0_RX1_N,
   //output NPIO_0_TX0_P,
   //output NPIO_0_TX0_N,
   //output NPIO_0_TX1_P,
   //output NPIO_0_TX1_N,
   //input NPIO_1_RX0_P,
   //input NPIO_1_RX0_N,
   //input NPIO_1_RX1_P,
   //input NPIO_1_RX1_N,
   //output NPIO_1_TX0_P,
   //output NPIO_1_TX0_N,
   //output NPIO_1_TX1_P,
   //output NPIO_1_TX1_N,
   //input NPIO_2_RX0_P,
   //input NPIO_2_RX0_N,
   //input NPIO_2_RX1_P,
   //input NPIO_2_RX1_N,
   //output NPIO_2_TX0_P,
   //output NPIO_2_TX0_N,
   //output NPIO_2_TX1_P,
   //output NPIO_2_TX1_N,
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
   //input [1:0] FPGA_TEST,// TODO :Check this ??
   //input PWR_CLK_FPGA, // TODO: check direction

   //White Rabbit
   //input WB_20MHZ_P,
   //input WB_20MHZ_N,
   //output WB_DAC_DIN,
   //output WB_DAC_NCLR,
   //output WB_DAC_NLDAC,
   //output WB_DAC_NSYNC,
   //output WB_DAC_SCLK,
   //output PWREN_CLK_WB_20MHZ,

   //LEDS
   output PANEL_LED_GPS,
   output PANEL_LED_LINK,
   output PANEL_LED_PPS,
   output PANEL_LED_REF,

   // ARM Connections
   inout [53:0]  MIO,
   input         PS_SRSTB,
   input         PS_CLK,
   input         PS_PORB,
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

   //input WB_CDCM_CLK1_P,
   //input WB_CDCM_CLK1_N,

`ifdef BUILD_1G
   input WB_CDCM_CLK2_P,
   input WB_CDCM_CLK2_N,
`endif

`ifdef BUILD_10G
   input MGT156MHZ_CLK1_P,
   input MGT156MHZ_CLK1_N,
`endif

   input SFP_0_RX_P, input SFP_0_RX_N,
   output SFP_0_TX_P, output SFP_0_TX_N,
   input SFP_1_RX_P, input SFP_1_RX_N,
   output SFP_1_TX_P, output SFP_1_TX_N,

   ///////////////////////////////////
   //
   // Supporting I/O for SPF+ interfaces
   //  (non high speed stuff)
   //
   ///////////////////////////////////

   //SFP+ 0, Slow Speed, Bank 13 3.3V
   //input SFP_0_I2C_NPRESENT,
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

   //USRP IO
   output         DBA_CPLD_RESET_N,
   output  [2:0]  DBA_CPLD_ADDR,
   input          DBA_CPLD_SPI_SDO,
   output         DBA_CPLD_SEL_ATR_SPI_N,
   output         DBA_CPLD_SYNC_ATR_RX1,
   output         DBA_CPLD_SPI_SDI_ATR_TX2,
   output         DBA_CPLD_SPI_CSB_ATR_TX1,
   output         DBA_CPLD_SPI_SCLK_ATR_RX2,

   output         DBA_CH1_TX_DSA_LE,
   output  [5:0]  DBA_CH1_TX_DSA_DATA,
   output         DBA_CH1_RX_DSA_LE,
   output  [5:0]  DBA_CH1_RX_DSA_DATA,

   output         DBA_CH2_TX_DSA_LE,
   output  [5:0]  DBA_CH2_TX_DSA_DATA,
   output         DBA_CH2_RX_DSA_LE,
   output  [5:0]  DBA_CH2_RX_DSA_DATA,

//   output         DbaPDacSync_n,
//   output         DbaPDacDin,
//   output         DbaPDacSclk,

//   output         DbaMykGpio0,
//   output         DbaMykGpio1,
//   output         DbaMykGpio3,
//   output         DbaMykGpio4,
//   output         DbaMykGpio12,
//   output         DbaMykGpio13,
//   output         DbaMykGpio14,
//   output         DbaMykGpio15,
   input          DBA_MYK_SPI_SDO,
   output         DBA_MYK_SPI_SDIO,
   output         DBA_MYK_SPI_CS_N,
   output         DBA_MYK_SPI_SCLK,
//   input          DBA_MykIntrq,

   output         DBA_CPLD_JTAG_TDI,
   input          DBA_CPLD_JTAG_TDO,
   output         DBA_CPLD_JTAG_TMS,
   output         DBA_CPLD_JTAG_TCK,

   output         DBA_MYK_SYNC_IN_P,
   output         DBA_MYK_SYNC_IN_N,
   input          DBA_MYK_SYNC_OUT_P,
   input          DBA_MYK_SYNC_OUT_N,
   input          DBA_FPGA_CLK_P,
   input          DBA_FPGA_CLK_N,
   input          DBA_FPGA_SYSREF_P,
   input          DBA_FPGA_SYSREF_N,

   input USRPIO_A_MGTCLK_P,
   input USRPIO_A_MGTCLK_N,
   //input USRPIO_A_SW_CLK, //TODO: Check direction
   input USRPIO_A_RX_0_P, USRPIO_A_RX_1_P, USRPIO_A_RX_2_P, USRPIO_A_RX_3_P,
   input USRPIO_A_RX_0_N, USRPIO_A_RX_1_N, USRPIO_A_RX_2_N, USRPIO_A_RX_3_N,
   output USRPIO_A_TX_0_P, USRPIO_A_TX_1_P, USRPIO_A_TX_2_P, USRPIO_A_TX_3_P,
   output USRPIO_A_TX_0_N, USRPIO_A_TX_1_N, USRPIO_A_TX_2_N, USRPIO_A_TX_3_N,

   //inout  USRPIO_B_GP_0_P, USRPIO_B_GP_1_P, USRPIO_B_GP_2_P, USRPIO_B_GP_3_P,
   //inout  USRPIO_B_GP_0_N, USRPIO_B_GP_1_N, USRPIO_B_GP_2_N, USRPIO_B_GP_3_N,
   //inout  USRPIO_B_GP_4_P, USRPIO_B_GP_5_P, USRPIO_B_GP_6_P, USRPIO_B_GP_7_P,
   //inout  USRPIO_B_GP_4_N, USRPIO_B_GP_5_N, USRPIO_B_GP_6_N, USRPIO_B_GP_7_N,
   //inout  USRPIO_B_GP_8_P, USRPIO_B_GP_9_P, USRPIO_B_GP_10_P, USRPIO_B_GP_11_P,
   //inout  USRPIO_B_GP_8_N, USRPIO_B_GP_9_N, USRPIO_B_GP_10_N, USRPIO_B_GP_11_N,
   //inout  USRPIO_B_GP_12_P, USRPIO_B_GP_13_P, USRPIO_B_GP_14_P, USRPIO_B_GP_15_P,
   //inout  USRPIO_B_GP_12_N, USRPIO_B_GP_13_N, USRPIO_B_GP_14_N, USRPIO_B_GP_15_N,
   //inout  USRPIO_B_GP_16_P, USRPIO_B_GP_17_P, USRPIO_B_GP_18_P, USRPIO_B_GP_19_P,
   //inout  USRPIO_B_GP_16_N, USRPIO_B_GP_17_N, USRPIO_B_GP_18_N, USRPIO_B_GP_19_N,
   //inout  USRPIO_B_GP_20_P, USRPIO_B_GP_21_P, USRPIO_B_GP_22_P, USRPIO_B_GP_23_P,
   //inout  USRPIO_B_GP_20_N, USRPIO_B_GP_21_N, USRPIO_B_GP_22_N, USRPIO_B_GP_23_N,
   //inout  USRPIO_B_GP_24_P, USRPIO_B_GP_25_P, USRPIO_B_GP_26_P, USRPIO_B_GP_27_P,
   //inout  USRPIO_B_GP_24_N, USRPIO_B_GP_25_N, USRPIO_B_GP_26_N, USRPIO_B_GP_27_N,
   //inout  USRPIO_B_GP_28_P, USRPIO_B_GP_29_P, USRPIO_B_GP_30_P, USRPIO_B_GP_31_P,
   //inout  USRPIO_B_GP_28_N, USRPIO_B_GP_29_N, USRPIO_B_GP_30_N, USRPIO_B_GP_31_N,
   //inout  USRPIO_B_GP_32_P,
   //inout  USRPIO_B_GP_32_N,
   input USRPIO_B_MGTCLK_P,
   input USRPIO_B_MGTCLK_N
   //input USRPIO_B_SW_CLK, //TODO: Check direction
   //input USRPIO_B_RX_0_P, USRPIO_B_RX_1_P, USRPIO_B_RX_2_P, USRPIO_B_RX_3_P,
   //input USRPIO_B_RX_0_N, USRPIO_B_RX_1_N, USRPIO_B_RX_2_N, USRPIO_B_RX_3_N,
   //output USRPIO_B_TX_0_P, USRPIO_B_TX_1_P, USRPIO_B_TX_2_P, USRPIO_B_TX_3_P,
   //output USRPIO_B_TX_0_N, USRPIO_B_TX_1_N, USRPIO_B_TX_2_N, USRPIO_B_TX_3_N

);
  localparam N_AXILITE_SLAVES = 4;

  localparam REG_AWIDTH = 14; // log2(0x4000)
  localparam REG_DWIDTH = 32;

   //TODO: Add bus_clk_gen, bus_rst, sw_rst
   wire bus_clk;
   wire bus_rst;
   wire global_rst;

  // Internal connections to PS
  //   HP0 -- High Performance port 0, FPGA is the master
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
  wire [3:0]  S_AXI_HP0_ARCACHE;
  wire [7:0]  S_AXI_HP0_AWLEN;
  wire [2:0]  S_AXI_HP0_AWSIZE;
  wire [1:0]  S_AXI_HP0_AWBURST;
  wire [3:0]  S_AXI_HP0_AWCACHE;
  wire        S_AXI_HP0_WLAST;
  wire [7:0]  S_AXI_HP0_ARLEN;
  wire [1:0]  S_AXI_HP0_ARBURST;
  wire [2:0]  S_AXI_HP0_ARSIZE;

  //   GP0 -- General Purpose port 0, FPGA is the master
  wire [5:0]  S_AXI_GP0_AWID;
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
  wire [5:0]  S_AXI_GP0_ARID;
  wire [31:0] S_AXI_GP0_ARADDR;
  wire [2:0]  S_AXI_GP0_ARPROT;
  wire        S_AXI_GP0_ARVALID;
  wire        S_AXI_GP0_ARREADY;
  wire [31:0] S_AXI_GP0_RDATA;
  wire [1:0]  S_AXI_GP0_RRESP;
  wire        S_AXI_GP0_RVALID;
  wire        S_AXI_GP0_RREADY;
  wire [3:0]  S_AXI_GP0_ARCACHE;
  wire [7:0]  S_AXI_GP0_AWLEN;
  wire [2:0]  S_AXI_GP0_AWSIZE;
  wire [1:0]  S_AXI_GP0_AWBURST;
  wire [3:0]  S_AXI_GP0_AWCACHE;
  wire        S_AXI_GP0_WLAST;
  wire [7:0]  S_AXI_GP0_ARLEN;
  wire [1:0]  S_AXI_GP0_ARBURST;
  wire [2:0]  S_AXI_GP0_ARSIZE;

  //   HP1 -- High Performance port 1, FPGA is the master
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
  wire [3:0]  S_AXI_HP1_ARCACHE;
  wire [7:0]  S_AXI_HP1_AWLEN;
  wire [2:0]  S_AXI_HP1_AWSIZE;
  wire [1:0]  S_AXI_HP1_AWBURST;
  wire [3:0]  S_AXI_HP1_AWCACHE;
  wire        S_AXI_HP1_WLAST;
  wire [7:0]  S_AXI_HP1_ARLEN;
  wire [1:0]  S_AXI_HP1_ARBURST;
  wire [2:0]  S_AXI_HP1_ARSIZE;

  //   GP1 -- General Purpose port 1, FPGA is the master
  wire [5:0]  S_AXI_GP1_AWID;
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
  wire [5:0]  S_AXI_GP1_ARID;
  wire [31:0] S_AXI_GP1_ARADDR;
  wire [2:0]  S_AXI_GP1_ARPROT;
  wire        S_AXI_GP1_ARVALID;
  wire        S_AXI_GP1_ARREADY;
  wire [31:0] S_AXI_GP1_RDATA;
  wire [1:0]  S_AXI_GP1_RRESP;
  wire        S_AXI_GP1_RVALID;
  wire        S_AXI_GP1_RREADY;
  wire [3:0]  S_AXI_GP1_ARCACHE;
  wire [7:0]  S_AXI_GP1_AWLEN;
  wire [2:0]  S_AXI_GP1_AWSIZE;
  wire [1:0]  S_AXI_GP1_AWBURST;
  wire [3:0]  S_AXI_GP1_AWCACHE;
  wire        S_AXI_GP1_WLAST;
  wire [7:0]  S_AXI_GP1_ARLEN;
  wire [1:0]  S_AXI_GP1_ARBURST;
  wire [2:0]  S_AXI_GP1_ARSIZE;

  //   GP0 -- General Purpose port 0, FPGA is the slave
  wire M_AXI_GP0_ARVALID;
  wire M_AXI_GP0_AWVALID;
  wire M_AXI_GP0_BREADY;
  wire M_AXI_GP0_RREADY;
  wire M_AXI_GP0_WVALID;
  wire [11:0] M_AXI_GP0_ARID;
  wire [11:0] M_AXI_GP0_AWID;
  wire [11:0] M_AXI_GP0_WID;
  wire [31:0] M_AXI_GP0_ARADDR;
  wire [31:0] M_AXI_GP0_AWADDR;
  wire [31:0] M_AXI_GP0_WDATA;
  wire [3:0] M_AXI_GP0_WSTRB;
  wire M_AXI_GP0_ARREADY;
  wire M_AXI_GP0_AWREADY;
  wire M_AXI_GP0_BVALID;
  wire M_AXI_GP0_RLAST;
  wire M_AXI_GP0_RVALID;
  wire M_AXI_GP0_WREADY;
  wire [1:0] M_AXI_GP0_BRESP;
  wire [1:0] M_AXI_GP0_RRESP;
  wire [31:0] M_AXI_GP0_RDATA;

  wire M_AXI_GP0_ARVALID_S0;
  wire M_AXI_GP0_AWVALID_S0;
  wire M_AXI_GP0_BREADY_S0;
  wire M_AXI_GP0_RREADY_S0;
  wire M_AXI_GP0_WVALID_S0;
  wire [11:0] M_AXI_GP0_ARID_S0;
  wire [11:0] M_AXI_GP0_AWID_S0;
  wire [11:0] M_AXI_GP0_WID_S0;
  wire [31:0] M_AXI_GP0_ARADDR_S0;
  wire [31:0] M_AXI_GP0_AWADDR_S0;
  wire [31:0] M_AXI_GP0_WDATA_S0;
  wire [3:0] M_AXI_GP0_WSTRB_S0;
  wire M_AXI_GP0_ARREADY_S0;
  wire M_AXI_GP0_AWREADY_S0;
  wire M_AXI_GP0_BVALID_S0;
  wire M_AXI_GP0_RLAST_S0;
  wire M_AXI_GP0_RVALID_S0;
  wire M_AXI_GP0_WREADY_S0;
  wire [1:0] M_AXI_GP0_BRESP_S0;
  wire [1:0] M_AXI_GP0_RRESP_S0;
  wire [31:0] M_AXI_GP0_RDATA_S0;

  wire M_AXI_GP0_ARVALID_S1;
  wire M_AXI_GP0_AWVALID_S1;
  wire M_AXI_GP0_BREADY_S1;
  wire M_AXI_GP0_RREADY_S1;
  wire M_AXI_GP0_WVALID_S1;
  wire [11:0] M_AXI_GP0_ARID_S1;
  wire [11:0] M_AXI_GP0_AWID_S1;
  wire [11:0] M_AXI_GP0_WID_S1;
  wire [31:0] M_AXI_GP0_ARADDR_S1;
  wire [31:0] M_AXI_GP0_AWADDR_S1;
  wire [31:0] M_AXI_GP0_WDATA_S1;
  wire [3:0] M_AXI_GP0_WSTRB_S1;
  wire M_AXI_GP0_ARREADY_S1;
  wire M_AXI_GP0_AWREADY_S1;
  wire M_AXI_GP0_BVALID_S1;
  wire M_AXI_GP0_RLAST_S1;
  wire M_AXI_GP0_RVALID_S1;
  wire M_AXI_GP0_WREADY_S1;
  wire [1:0] M_AXI_GP0_BRESP_S1;
  wire [1:0] M_AXI_GP0_RRESP_S1;
  wire [31:0] M_AXI_GP0_RDATA_S1;

  wire M_AXI_GP0_ARVALID_S2;
  wire M_AXI_GP0_AWVALID_S2;
  wire M_AXI_GP0_BREADY_S2;
  wire M_AXI_GP0_RREADY_S2;
  wire M_AXI_GP0_WVALID_S2;
  wire [11:0] M_AXI_GP0_ARID_S2;
  wire [11:0] M_AXI_GP0_AWID_S2;
  wire [11:0] M_AXI_GP0_WID_S2;
  wire [31:0] M_AXI_GP0_ARADDR_S2;
  wire [31:0] M_AXI_GP0_AWADDR_S2;
  wire [31:0] M_AXI_GP0_WDATA_S2;
  wire [3:0] M_AXI_GP0_WSTRB_S2;
  wire M_AXI_GP0_ARREADY_S2;
  wire M_AXI_GP0_AWREADY_S2;
  wire M_AXI_GP0_BVALID_S2;
  wire M_AXI_GP0_RLAST_S2;
  wire M_AXI_GP0_RVALID_S2;
  wire M_AXI_GP0_WREADY_S2;
  wire [1:0] M_AXI_GP0_BRESP_S2;
  wire [1:0] M_AXI_GP0_RRESP_S2;
  wire [31:0] M_AXI_GP0_RDATA_S2;

  wire M_AXI_GP0_ARVALID_S3;
  wire M_AXI_GP0_AWVALID_S3;
  wire M_AXI_GP0_BREADY_S3;
  wire M_AXI_GP0_RREADY_S3;
  wire M_AXI_GP0_WVALID_S3;
  wire [11:0] M_AXI_GP0_ARID_S3;
  wire [11:0] M_AXI_GP0_AWID_S3;
  wire [11:0] M_AXI_GP0_WID_S3;
  wire [31:0] M_AXI_GP0_ARADDR_S3;
  wire [31:0] M_AXI_GP0_AWADDR_S3;
  wire [31:0] M_AXI_GP0_WDATA_S3;
  wire [3:0] M_AXI_GP0_WSTRB_S3;
  wire M_AXI_GP0_ARREADY_S3;
  wire M_AXI_GP0_AWREADY_S3;
  wire M_AXI_GP0_BVALID_S3;
  wire M_AXI_GP0_RLAST_S3;
  wire M_AXI_GP0_RVALID_S3;
  wire M_AXI_GP0_WREADY_S3;
  wire [1:0] M_AXI_GP0_BRESP_S3;
  wire [1:0] M_AXI_GP0_RRESP_S3;
  wire [31:0] M_AXI_GP0_RDATA_S3;

  wire M_AXI_GP0_ARVALID_S4;
  wire M_AXI_GP0_AWVALID_S4;
  wire M_AXI_GP0_BREADY_S4;
  wire M_AXI_GP0_RREADY_S4;
  wire M_AXI_GP0_WVALID_S4;
  wire [11:0] M_AXI_GP0_ARID_S4;
  wire [11:0] M_AXI_GP0_AWID_S4;
  wire [11:0] M_AXI_GP0_WID_S4;
  wire [31:0] M_AXI_GP0_ARADDR_S4;
  wire [31:0] M_AXI_GP0_AWADDR_S4;
  wire [31:0] M_AXI_GP0_WDATA_S4;
  wire [3:0] M_AXI_GP0_WSTRB_S4;
  wire M_AXI_GP0_ARREADY_S4;
  wire M_AXI_GP0_AWREADY_S4;
  wire M_AXI_GP0_BVALID_S4;
  wire M_AXI_GP0_RLAST_S4;
  wire M_AXI_GP0_RVALID_S4;
  wire M_AXI_GP0_WREADY_S4;
  wire [1:0] M_AXI_GP0_BRESP_S4;
  wire [1:0] M_AXI_GP0_RRESP_S4;
  wire [31:0] M_AXI_GP0_RDATA_S4;

  wire M_AXI_GP0_ARVALID_S5;
  wire M_AXI_GP0_AWVALID_S5;
  wire M_AXI_GP0_BREADY_S5;
  wire M_AXI_GP0_RREADY_S5;
  wire M_AXI_GP0_WVALID_S5;
  wire [11:0] M_AXI_GP0_ARID_S5;
  wire [11:0] M_AXI_GP0_AWID_S5;
  wire [11:0] M_AXI_GP0_WID_S5;
  wire [31:0] M_AXI_GP0_ARADDR_S5;
  wire [31:0] M_AXI_GP0_AWADDR_S5;
  wire [31:0] M_AXI_GP0_WDATA_S5;
  wire [3:0] M_AXI_GP0_WSTRB_S5;
  wire M_AXI_GP0_ARREADY_S5;
  wire M_AXI_GP0_AWREADY_S5;
  wire M_AXI_GP0_BVALID_S5;
  wire M_AXI_GP0_RLAST_S5;
  wire M_AXI_GP0_RVALID_S5;
  wire M_AXI_GP0_WREADY_S5;
  wire [1:0] M_AXI_GP0_BRESP_S5;
  wire [1:0] M_AXI_GP0_RRESP_S5;
  wire [31:0] M_AXI_GP0_RDATA_S5;

  wire M_AXI_GP0_ARVALID_S6;
  wire M_AXI_GP0_AWVALID_S6;
  wire M_AXI_GP0_BREADY_S6;
  wire M_AXI_GP0_RREADY_S6;
  wire M_AXI_GP0_WVALID_S6;
  wire [11:0] M_AXI_GP0_ARID_S6;
  wire [11:0] M_AXI_GP0_AWID_S6;
  wire [11:0] M_AXI_GP0_WID_S6;
  wire [31:0] M_AXI_GP0_ARADDR_S6;
  wire [31:0] M_AXI_GP0_AWADDR_S6;
  wire [31:0] M_AXI_GP0_WDATA_S6;
  wire [3:0] M_AXI_GP0_WSTRB_S6;
  wire M_AXI_GP0_ARREADY_S6;
  wire M_AXI_GP0_AWREADY_S6;
  wire M_AXI_GP0_BVALID_S6;
  wire M_AXI_GP0_RLAST_S6;
  wire M_AXI_GP0_RVALID_S6;
  wire M_AXI_GP0_WREADY_S6;
  wire [1:0] M_AXI_GP0_BRESP_S6;
  wire [1:0] M_AXI_GP0_RRESP_S6;
  wire [31:0] M_AXI_GP0_RDATA_S6;

  wire        M_AXI_GP0_ARVALID_S[N_AXILITE_SLAVES-1:0];
  wire        M_AXI_GP0_AWVALID_S[N_AXILITE_SLAVES-1:0];
  wire        M_AXI_GP0_BREADY_S[N_AXILITE_SLAVES-1:0];
  wire        M_AXI_GP0_RREADY_S[N_AXILITE_SLAVES-1:0];
  wire        M_AXI_GP0_WVALID_S[N_AXILITE_SLAVES-1:0];
  wire [11:0] M_AXI_GP0_ARID_S[N_AXILITE_SLAVES-1:0];
  wire [11:0] M_AXI_GP0_AWID_S[N_AXILITE_SLAVES-1:0];
  wire [11:0] M_AXI_GP0_WID_S[N_AXILITE_SLAVES-1:0];
  wire [31:0] M_AXI_GP0_ARADDR_S[N_AXILITE_SLAVES-1:0];
  wire [31:0] M_AXI_GP0_AWADDR_S[N_AXILITE_SLAVES-1:0];
  wire [31:0] M_AXI_GP0_WDATA_S[N_AXILITE_SLAVES-1:0];
  wire [3:0]  M_AXI_GP0_WSTRB_S[N_AXILITE_SLAVES-1:0];
  wire        M_AXI_GP0_ARREADY_S[N_AXILITE_SLAVES-1:0];
  wire        M_AXI_GP0_AWREADY_S[N_AXILITE_SLAVES-1:0];
  wire        M_AXI_GP0_BVALID_S[N_AXILITE_SLAVES-1:0];
  wire        M_AXI_GP0_RLAST_S[N_AXILITE_SLAVES-1:0];
  wire        M_AXI_GP0_RVALID_S[N_AXILITE_SLAVES-1:0];
  wire        M_AXI_GP0_WREADY_S[N_AXILITE_SLAVES-1:0];
  wire [1:0]  M_AXI_GP0_BRESP_S[N_AXILITE_SLAVES-1:0];
  wire [1:0]  M_AXI_GP0_RRESP_S[N_AXILITE_SLAVES-1:0];
  wire [31:0] M_AXI_GP0_RDATA_S[N_AXILITE_SLAVES-1:0];

  wire [15:0] IRQ_F2P;
  wire FCLK_CLK0;
  wire FCLK_CLK1;
  wire FCLK_RESET0;
  wire FCLK_RESET0N = ~FCLK_RESET0;

  wire [1:0] USB0_PORT_INDCTL;
  wire USB0_VBUS_PWRSELECT;
  wire USB0_VBUS_PWRFAULT;

   /////////////////////////////////////////////////////////////////////
   //
   // power-on-reset logic.
   //
   //////////////////////////////////////////////////////////////////////
   por_gen por_gen(.clk(bus_clk), .reset_out(global_rst));

   //////////////////////////////////////////////////////////////////////
   //
   // Configure SFP+ clocking
   //
   //////////////////////////////////////////////////////////////////////
   //   Clocks : ---------------------------------------------------------------------------
   //   BusClk (40) : MGT156MHZ_CLK1_P > GTX IBUF > TenGbeClkIBuf   > MMCM > BUFG > BusClk
   //   Clk100 (100): MGT156MHZ_CLK1_P > GTX IBUF > TenGbeClkIBuf   > MMCM > BUFG > Clk100
   //   xgige_refclk: MGT156MHZ_CLK1_P > GTX IBUF > TenGbeClkIBuf   > BUFG > TenGbeClk
   //   gige_refclk : WB_CDCM_CLK2_P   > GTX IBUF > Eth1GRefClkIBuf > BUFG > Eth1GRefClkBufG
   //   RefClk (10) : FPGA_REFCLK      >     IBUF > RefClkIBuf      > BUFG > RefClk
   //
   //   MGT156MHZ_CLK1 requires PWREN_CLK_MGT156MHZ to be asserted.
   //   WB_CDCM_CLK2   requires

   //Turn on power to the clocks : Moved to PS : TODO: Remove
   //assign PWREN_CLK_MGT156MHZ = 1'b1;
   //assign PWREN_CLK_MAINREF   = 1'b1;
   //assign PWREN_CLK_DDR100MHZ = 1'b1;

   //// Configure the clocks to output 125 MHz.
   //assign PWREN_CLK_WB_25MHZ = 1'b1;
   //assign PWREN_CLK_WB_CDCM = 1'b1;
   //assign WB_CDCM_RESETN = 1'b1;
   //// Prescalar and Feedback Dividers
   //assign WB_CDCM_PR1 = 1'b1;
   //assign WB_CDCM_PR0 = 1'b1;
   ////Output Dividers
   //assign WB_CDCM_OD2 = 1'b0;
   //assign WB_CDCM_OD1 = 1'b1;
   //assign WB_CDCM_OD0 = 1'b1;

   /////////////////////////////////////////////////////////////////////
   //
   // 10MHz Reference clock
   //
   //////////////////////////////////////////////////////////////////////

   wire ref_clk_10mhz; //TODO: Check if this is 10 MHz
   IBUFDS IBUFDS_10_MHz (
        .O(ref_clk_10mhz),
        .I(FPGA_REFCLK_P),
        .IB(FPGA_REFCLK_N)
    );

  ////////////////////////////////////////////////////////////////////
  //
  // Generate Radio Clocks from ...
  // FIXME this needs to be defined in final terms. Most of this is just copied from X310.
  // CLK_IN was arbitrarily chosen. Input clk should be 200 MHz based on current clk_gen specs.
  // Radio clock is normally 200MHz, radio_clk_2x 400MHz.
  // In CPRI or LTE mode, radio clock is 184.32 MHz.
  // radio_clk_2x is only to be used for clocking out TX samples to DAC
  //
  //----------------------------------------------------------------------------
  //  Output     Output      Phase    Duty Cycle   Pk-to-Pk     Phase
  //   Clock     Freq (MHz)  (degrees)    (%)     Jitter (ps)  Error (ps)
  //----------------------------------------------------------------------------
  // CLK_OUT1___200.000______0.000______50.0_______92.799_____82.655
  // CLK_OUT2___400.000____-45.000______50.0_______81.254_____82.655
  // CLK_OUT3___400.000_____60.000______50.0_______81.254_____82.655
  //
  //----------------------------------------------------------------------------
  // Input Clock   Freq (MHz)    Input Jitter (UI)
  //----------------------------------------------------------------------------
  // __primary_________200.000____________0.010
  //
  ////////////////////////////////////////////////////////////////////

  // Radio Clock Generation

  wire radio_clk;
  // FIXME: Shifted to RadioClocking.vhd

  ////////////////////////////////////////////////////////////////////
  //
  // IJB. Radio PLL doesn't seem to lock at power up.
  // Probably needs AD9610 to be programmed to 120 or 200MHz to get
  // an input clock thats in the ball park for PLL configuration.
  // Currently use busclk PLL lock signal to control this reset,
  // but we should find a better solution, perhaps a S/W controllable
  // reset like the ETH PHY uses so that we can reset this clock domain
  // after programming the AD9610.
  //
  ////////////////////////////////////////////////////////////////////

  //FIXME RESET SYNC may need more or'd inputs.
  reset_sync radio_reset_sync (
     .clk(radio_clk),
     .reset_in(global_rst),
     //FIXME EXAMPLE of various reset_in sources
     //.reset_in(global_rst || !bus_clk_locked || sw_rst[1]),
     .reset_out(radio_rst)
  );

  reset_sync int_reset_sync (
     .clk(bus_clk),
     .reset_in(global_rst),
     .reset_out(bus_rst)
  );

`ifdef BUILD_1G
   wire  gige_refclk, gige_refclk_bufg;

   one_gige_phy_clk_gen gige_clk_gen_i (
      .areset(global_rst),
      .refclk_p(WB_CDCM_CLK2_P),
      .refclk_n(WB_CDCM_CLK2_N),
      .refclk(gige_refclk),
      .refclk_bufg(gige_refclk_bufg)
   );

   // FIXME
   assign SFP_0_RS0  = 1'b0;
   assign SFP_0_RS1  = 1'b0;
   assign SFP_1_RS0  = 1'b0;
   assign SFP_1_RS1  = 1'b0;

`endif

`ifdef BUILD_10G
   wire  xgige_refclk;
   wire  xgige_clk156;
   wire  xgige_dclk;

   ten_gige_phy_clk_gen xgige_clk_gen_i (
      .areset(global_rst),
      .refclk_p(MGT156MHZ_CLK1_P),
      .refclk_n(MGT156MHZ_CLK1_N),
      .refclk(xgige_refclk),
      .clk156(xgige_clk156),
      .dclk(xgige_dclk)
   );
   // FIXME
   assign SFP_0_RS0  = 1'b1;
   assign SFP_0_RS1  = 1'b1;
   assign SFP_1_RS0  = 1'b1;
   assign SFP_1_RS1  = 1'b1;

`endif

  BUFG bus_clk_buf (
     .I(FCLK_CLK0),
     .O(bus_clk));

   wire  sfp0_gt_refclk, sfp1_gt_refclk;
   wire  sfp0_gb_refclk, sfp1_gb_refclk;
   wire  sfp0_misc_clk, sfp1_misc_clk;

`ifdef SFP0_10GBE
   assign sfp0_gt_refclk = xgige_refclk;
   assign sfp0_gb_refclk = xgige_clk156;
   assign sfp0_misc_clk  = xgige_dclk;
`endif
`ifdef SFP0_1GBE
   assign sfp0_gt_refclk = gige_refclk;
   assign sfp0_gb_refclk = gige_refclk_bufg;
   assign sfp0_misc_clk  = gige_refclk_bufg;
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

   wire          gt0_qplloutclk,gt0_qplloutrefclk;
   wire          pma_reset;
   wire          qpllreset;
   wire          qplllock;
   wire          qplloutclk;
   wire          qplloutrefclk;
   wire  [15:0]  sfp0_phy_status;
   wire  [15:0]  sfp1_phy_status;
   wire  [63:0]  e01_tdata, e10_tdata;
   wire  [3:0]   e01_tuser, e10_tuser;
   wire          e01_tlast, e01_tvalid, e01_tready;
   wire          e10_tlast, e10_tvalid, e10_tready;

`ifdef SFP0_1GBE
   //GT COMMON
   one_gig_eth_pcs_pma_gt_common core_gt_common_i
   (
    .GTREFCLK0_IN                (gige_refclk) ,
    .QPLLLOCK_OUT                (),
    .QPLLLOCKDETCLK_IN           (bus_clk),
    .QPLLOUTCLK_OUT              (gt0_qplloutclk),
    .QPLLOUTREFCLK_OUT           (gt0_qplloutrefclk),
    .QPLLREFCLKLOST_OUT          (),
    .QPLLRESET_IN                (pma_reset)
   );
`endif

`ifdef SFP0_10GBE

  // Instantiate the 10GBASER/KR GT Common block
  ten_gig_eth_pcs_pma_gt_common # (
      .WRAPPER_SIM_GTRESET_SPEEDUP("TRUE") ) //Does not affect hardware
  ten_gig_eth_pcs_pma_gt_common_block
    (
     .refclk(xgige_refclk),
     .qpllreset(qpllreset),
     .qplllock(qplllock),
     .qplloutclk(qplloutclk),
     .qplloutrefclk(qplloutrefclk),
     .qpllrefclksel(3'b101 /*GTSOUTHREFCLK0*/)
    );
`endif

  ////////////////////////////////////////////////////////////////////
  // PPS
  // Support for internal, external, and GPSDO PPS inputs
  // Every attempt to minimize propagation between the external PPS
  // input and outputs to support daisy-chaining the signal.
  ///////////////////////////////////////////////////////////////////

  // Generate an internal PPS signal with a 25% duty cycle
  wire int_pps;
  pps_generator #(
     .CLK_FREQ(32'd10_000_000), .DUTY_CYCLE(25)
  ) pps_gen (
     .clk(ref_clk_10mhz), .reset(1'b0), .pps(int_pps)
  );

  // PPS MUX - selects internal, external, or gpsdo PPS
  reg pps;
  wire [1:0] pps_select;
  wire pps_out_enb;
  always @(*) begin
     case(pps_select)
        2'b00  :   pps = REF_1PPS_IN;
        2'b01  :   pps = 1'b0;
        2'b10  :   pps = int_pps;
        2'b11  :   pps = GPS_1PPS;
        default:   pps = 1'b0;
     endcase
  end

  // PPS out and LED
  assign REF_1PPS_OUT = pps & pps_out_enb;
  assign PANEL_LED_PPS = ~pps;                                  // active low LED driver


// ARM ethernet 0 bridge signals
  (* mark_debug = "true", keep = "true" *)
  wire [63:0] arm_eth0_tx_tdata;
  (* mark_debug = "true", keep = "true" *)
  wire        arm_eth0_tx_tvalid;
  (* mark_debug = "true", keep = "true" *)
  wire        arm_eth0_tx_tlast;
  (* mark_debug = "true", keep = "true" *)
  wire        arm_eth0_tx_tready;
  (* mark_debug = "true", keep = "true" *)
  wire [3:0]  arm_eth0_tx_tuser;
  wire [7:0]  arm_eth0_tx_tkeep;

  (* mark_debug = "true", keep = "true" *)
  wire [63:0] arm_eth0_rx_tdata;
  (* mark_debug = "true", keep = "true" *)
  wire        arm_eth0_rx_tvalid;
  (* mark_debug = "true", keep = "true" *)
  wire        arm_eth0_rx_tlast;
  (* mark_debug = "true", keep = "true" *)
  wire        arm_eth0_rx_tready;
  (* mark_debug = "true", keep = "true" *)
  wire [3:0]  arm_eth0_rx_tuser;
  wire [7:0]  arm_eth0_rx_tkeep;


  (* mark_debug = "true", keep = "true" *)
  wire        arm_eth0_rx_irq;
  wire        arm_eth0_tx_irq;

  // ARM ethernet 1 bridge signals
  (* mark_debug = "true", keep = "true" *)
  wire [63:0] arm_eth1_tx_tdata;
  (* mark_debug = "true", keep = "true" *)
  wire        arm_eth1_tx_tvalid;
  (* mark_debug = "true", keep = "true" *)
  wire        arm_eth1_tx_tlast;
  (* mark_debug = "true", keep = "true" *)
  wire        arm_eth1_tx_tready;
  (* mark_debug = "true", keep = "true" *)
  wire [3:0]  arm_eth1_tx_tuser;
  wire [7:0]  arm_eth1_tx_tkeep;


  (* mark_debug = "true", keep = "true" *)
  wire [63:0] arm_eth1_rx_tdata;
  (* mark_debug = "true", keep = "true" *)
  wire        arm_eth1_rx_tvalid;
  (* mark_debug = "true", keep = "true" *)
  wire        arm_eth1_rx_tlast;
  (* mark_debug = "true", keep = "true" *)
  wire        arm_eth1_rx_tready;
  (* mark_debug = "true", keep = "true" *)
  wire [3:0]  arm_eth1_rx_tuser;
  wire [7:0]  arm_eth1_rx_tkeep;

  (* mark_debug = "true", keep = "true" *)
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

   network_interface #(
`ifdef SFP0_10GBE
      .PROTOCOL("10GbE"),
`endif
`ifdef SFP0_1GBE
      .PROTOCOL("1GbE"),
`endif
      .DWIDTH(REG_DWIDTH),     // Width of the AXI4-Lite data bus (must be 32 or 64)
      .AWIDTH(REG_AWIDTH),     // Width of the address bus
      .MDIO_EN(1'b1),
      .PORTNUM(8'd0)
   ) network_interface_0 (
      .areset(global_rst),  // TODO: Add Reset through PS
      .gt_refclk(sfp0_gt_refclk),
      .gb_refclk(sfp0_gb_refclk),
      .misc_clk(sfp0_misc_clk),

      .bus_rst(bus_rst),
      .bus_clk(bus_clk),
   `ifdef SFP0_1GBE
      .gt0_qplloutclk(gt0_qplloutclk),
      .gt0_qplloutrefclk(gt0_qplloutrefclk),
      .pma_reset_out(pma_reset),
   `endif
   `ifdef SFP0_10GBE
      .qplllock(qplllock),
      .qplloutclk(qplloutclk),
      .qplloutrefclk(qplloutrefclk),
   `endif
      .txp(SFP_0_TX_P),
      .txn(SFP_0_TX_N),
      .rxp(SFP_0_RX_P),
      .rxn(SFP_0_RX_N),

      .sfpp_rxlos(SFP_0_LOS),
      .sfpp_tx_fault(SFP_0_TXFAULT),
      .sfpp_tx_disable(SFP_0_TXDISABLE),

      .sfp_phy_status(sfp0_phy_status),

      // Clock and reset
      .s_axi_aclk(FCLK_CLK0),
      .s_axi_aresetn(FCLK_RESET0N),
      // AXI4-Lite: Write address port (domain: s_axi_aclk)
      .s_axi_awaddr(M_AXI_GP0_AWADDR_S1),
      .s_axi_awvalid(M_AXI_GP0_AWVALID_S1),
      .s_axi_awready(M_AXI_GP0_AWREADY_S1),
      // AXI4-Lite: Write data port (domain: s_axi_aclk)
      .s_axi_wdata(M_AXI_GP0_WDATA_S1),
      .s_axi_wstrb(M_AXI_GP0_WSTRB_S1),
      .s_axi_wvalid(M_AXI_GP0_WVALID_S1),
      .s_axi_wready(M_AXI_GP0_WREADY_S1),
      // AXI4-Lite: Write response port (domain: s_axi_aclk)
      .s_axi_bresp(M_AXI_GP0_BRESP_S1),
      .s_axi_bvalid(M_AXI_GP0_BVALID_S1),
      .s_axi_bready(M_AXI_GP0_BREADY_S1),
      // AXI4-Lite: Read address port (domain: s_axi_aclk)
      .s_axi_araddr(M_AXI_GP0_ARADDR_S1),
      .s_axi_arvalid(M_AXI_GP0_ARVALID_S1),
      .s_axi_arready(M_AXI_GP0_ARREADY_S1),
      // AXI4-Lite: Read data port (domain: s_axi_aclk)
      .s_axi_rdata(M_AXI_GP0_RDATA_S1),
      .s_axi_rresp(M_AXI_GP0_RRESP_S1),
      .s_axi_rvalid(M_AXI_GP0_RVALID_S1),
      .s_axi_rready(M_AXI_GP0_RREADY_S1),

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
      .e2c_tdata(arm_eth0_rx_tdata),
      .e2c_tkeep(arm_eth0_rx_tkeep),
      .e2c_tlast(arm_eth0_rx_tlast),
      .e2c_tvalid(arm_eth0_rx_tvalid),
      .e2c_tready(arm_eth0_rx_tready),

      // CPU to Ethernet
      .c2e_tdata(arm_eth0_tx_tdata),
      .c2e_tkeep(arm_eth0_tx_tkeep),
      .c2e_tlast(arm_eth0_tx_tlast),
      .c2e_tvalid(arm_eth0_tx_tvalid),
      .c2e_tready(arm_eth0_tx_tready),

      // LED
      .activity_led(SFP_0_LED_A)
   );

   network_interface #(
`ifdef SFP1_10GBE
      .PROTOCOL("10GbE"),
`endif
`ifdef SFP1_1GBE
      .PROTOCOL("1GbE"),
`endif
      .DWIDTH(REG_DWIDTH),     // Width of the AXI4-Lite data bus (must be 32 or 64)
      .AWIDTH(REG_AWIDTH),     // Width of the address bus
      .MDIO_EN(1'b1),
      .PORTNUM(8'd1)
   ) network_interface_1 (
      .areset(global_rst),  // TODO: Add reset through PS
      .gt_refclk(sfp1_gt_refclk),
      .gb_refclk(sfp1_gb_refclk),
      .misc_clk(sfp1_misc_clk),

      .bus_rst(bus_rst),
      .bus_clk(bus_clk),
   `ifdef SFP1_1GBE
      .gt0_qplloutclk(gt0_qplloutclk),
      .gt0_qplloutrefclk(gt0_qplloutrefclk),
      .pma_reset_out(),
   `endif
   `ifdef SFP1_10GBE
      .qpllreset(qpllreset),
      .qplllock(qplllock),
      .qplloutclk(qplloutclk),
      .qplloutrefclk(qplloutrefclk),
   `endif
      .txp(SFP_1_TX_P),
      .txn(SFP_1_TX_N),
      .rxp(SFP_1_RX_P),
      .rxn(SFP_1_RX_N),

      .sfpp_rxlos(SFP_1_LOS),
      .sfpp_tx_fault(SFP_1_TXFAULT),
      .sfpp_tx_disable(SFP_1_TXDISABLE),

      .sfp_phy_status(sfp1_phy_status),

      // Clock and reset
      .s_axi_aclk(FCLK_CLK0),
      .s_axi_aresetn(FCLK_RESET0N),
      // AXI4-Lite: Write address port (domain: s_axi_aclk)
      .s_axi_awaddr(M_AXI_GP0_AWADDR_S3),
      .s_axi_awvalid(M_AXI_GP0_AWVALID_S3),
      .s_axi_awready(M_AXI_GP0_AWREADY_S3),
      // AXI4-Lite: Write data port (domain: s_axi_aclk)
      .s_axi_wdata(M_AXI_GP0_WDATA_S3),
      .s_axi_wstrb(M_AXI_GP0_WSTRB_S3),
      .s_axi_wvalid(M_AXI_GP0_WVALID_S3),
      .s_axi_wready(M_AXI_GP0_WREADY_S3),
      // AXI4-Lite: Write response port (domain: s_axi_aclk)
      .s_axi_bresp(M_AXI_GP0_BRESP_S3),
      .s_axi_bvalid(M_AXI_GP0_BVALID_S3),
      .s_axi_bready(M_AXI_GP0_BREADY_S3),
      // AXI4-Lite: Read address port (domain: s_axi_aclk)
      .s_axi_araddr(M_AXI_GP0_ARADDR_S3),
      .s_axi_arvalid(M_AXI_GP0_ARVALID_S3),
      .s_axi_arready(M_AXI_GP0_ARREADY_S3),
      // AXI4-Lite: Read data port (domain: s_axi_aclk)
      .s_axi_rdata(M_AXI_GP0_RDATA_S3),
      .s_axi_rresp(M_AXI_GP0_RRESP_S3),
      .s_axi_rvalid(M_AXI_GP0_RVALID_S3),
      .s_axi_rready(M_AXI_GP0_RREADY_S3),

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
      .e2c_tdata(arm_eth1_rx_tdata),
      .e2c_tkeep(arm_eth1_rx_tkeep),
      .e2c_tlast(arm_eth1_rx_tlast),
      .e2c_tvalid(arm_eth1_rx_tvalid),
      .e2c_tready(arm_eth1_rx_tready),

      // CPU to Ethernet
      .c2e_tdata(arm_eth1_tx_tdata),
      .c2e_tkeep(arm_eth1_tx_tkeep),
      .c2e_tlast(arm_eth1_tx_tlast),
      .c2e_tvalid(arm_eth1_tx_tvalid),
      .c2e_tready(arm_eth1_tx_tready),

      // LED
      .activity_led(SFP_1_LED_A)
  );


  assign      IRQ_F2P[0] = arm_eth0_rx_irq;
  assign      IRQ_F2P[1] = arm_eth0_tx_irq;
  assign      IRQ_F2P[2] = arm_eth1_rx_irq;
  assign      IRQ_F2P[3] = arm_eth1_tx_irq;

  axi_eth_dma inst_axi_eth_dma0
  (
    .s_axi_lite_aclk(bus_clk),
    .m_axi_sg_aclk(bus_clk),
    .m_axi_mm2s_aclk(bus_clk),
    .m_axi_s2mm_aclk(bus_clk),
    .axi_resetn(~bus_rst),

    .s_axi_lite_awaddr(M_AXI_GP0_AWADDR_S0),
    .s_axi_lite_awvalid(M_AXI_GP0_AWVALID_S0),
    .s_axi_lite_awready(M_AXI_GP0_AWREADY_S0),

    .s_axi_lite_wdata(M_AXI_GP0_WDATA_S0),
    .s_axi_lite_wvalid(M_AXI_GP0_WVALID_S0),
    .s_axi_lite_wready(M_AXI_GP0_WREADY_S0),

    .s_axi_lite_bresp(M_AXI_GP0_BRESP_S0),
    .s_axi_lite_bvalid(M_AXI_GP0_BVALID_S0),
    .s_axi_lite_bready(M_AXI_GP0_BREADY_S0),

    .s_axi_lite_araddr(M_AXI_GP0_ARADDR_S0),
    .s_axi_lite_arvalid(M_AXI_GP0_ARVALID_S0),
    .s_axi_lite_arready(M_AXI_GP0_ARREADY_S0),

    .s_axi_lite_rdata(M_AXI_GP0_RDATA_S0),
    .s_axi_lite_rresp(M_AXI_GP0_RRESP_S0),
    .s_axi_lite_rvalid(M_AXI_GP0_RVALID_S0),
    .s_axi_lite_rready(M_AXI_GP0_RREADY_S0),

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

  assign {S_AXI_HP0_AWID, S_AXI_HP0_ARID} = 12'd0;
  assign {S_AXI_GP0_AWID, S_AXI_GP0_ARID} = 12'd0;

  axi_eth_dma inst_axi_eth_dma1
  (
    .s_axi_lite_aclk(bus_clk),
    .m_axi_sg_aclk(bus_clk),
    .m_axi_mm2s_aclk(bus_clk),
    .m_axi_s2mm_aclk(bus_clk),
    .axi_resetn(~bus_rst),

    .s_axi_lite_awaddr(M_AXI_GP0_AWADDR_S2),
    .s_axi_lite_awvalid(M_AXI_GP0_AWVALID_S2),
    .s_axi_lite_awready(M_AXI_GP0_AWREADY_S2),

    .s_axi_lite_wdata(M_AXI_GP0_WDATA_S2),
    .s_axi_lite_wvalid(M_AXI_GP0_WVALID_S2),
    .s_axi_lite_wready(M_AXI_GP0_WREADY_S2),

    .s_axi_lite_bresp(M_AXI_GP0_BRESP_S2),
    .s_axi_lite_bvalid(M_AXI_GP0_BVALID_S2),
    .s_axi_lite_bready(M_AXI_GP0_BREADY_S2),

    .s_axi_lite_araddr(M_AXI_GP0_ARADDR_S2),
    .s_axi_lite_arvalid(M_AXI_GP0_ARVALID_S2),
    .s_axi_lite_arready(M_AXI_GP0_ARREADY_S2),

    .s_axi_lite_rdata(M_AXI_GP0_RDATA_S2),
    .s_axi_lite_rresp(M_AXI_GP0_RRESP_S2),
    .s_axi_lite_rvalid(M_AXI_GP0_RVALID_S2),
    .s_axi_lite_rready(M_AXI_GP0_RREADY_S2),

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

  assign {S_AXI_HP1_AWID, S_AXI_HP1_ARID} = 12'd0;
  assign {S_AXI_GP1_AWID, S_AXI_GP1_ARID} = 12'd0;

  axi_interconnect inst_axi_interconnect
  (
    .aclk(bus_clk),
    .aresetn(~bus_rst),
    .s_axi_awaddr(M_AXI_GP0_AWADDR),
    .s_axi_awready(M_AXI_GP0_AWREADY),
    .s_axi_awvalid(M_AXI_GP0_AWVALID),
    .s_axi_wdata(M_AXI_GP0_WDATA),
    .s_axi_wstrb(M_AXI_GP0_WSTRB),
    .s_axi_wvalid(M_AXI_GP0_WVALID),
    .s_axi_wready(M_AXI_GP0_WREADY),
    .s_axi_bresp(M_AXI_GP0_BRESP),
    .s_axi_bvalid(M_AXI_GP0_BVALID),
    .s_axi_bready(M_AXI_GP0_BREADY),
    .s_axi_araddr(M_AXI_GP0_ARADDR),
    .s_axi_arvalid(M_AXI_GP0_ARVALID),
    .s_axi_arready(M_AXI_GP0_ARREADY),
    .s_axi_rdata(M_AXI_GP0_RDATA),
    .s_axi_rresp(M_AXI_GP0_RRESP),
    .s_axi_rvalid(M_AXI_GP0_RVALID),
    .s_axi_rready(M_AXI_GP0_RREADY),
    .m_axi_awaddr({M_AXI_GP0_AWADDR_S6, M_AXI_GP0_AWADDR_S5, M_AXI_GP0_AWADDR_S4, M_AXI_GP0_AWADDR_S3, M_AXI_GP0_AWADDR_S2, M_AXI_GP0_AWADDR_S1, M_AXI_GP0_AWADDR_S0}),
    .m_axi_awvalid({M_AXI_GP0_AWVALID_S6, M_AXI_GP0_AWVALID_S5, M_AXI_GP0_AWVALID_S4, M_AXI_GP0_AWVALID_S3, M_AXI_GP0_AWVALID_S2, M_AXI_GP0_AWVALID_S1, M_AXI_GP0_AWVALID_S0}),
    .m_axi_awready({M_AXI_GP0_AWREADY_S6, M_AXI_GP0_AWREADY_S5, M_AXI_GP0_AWREADY_S4, M_AXI_GP0_AWREADY_S3, M_AXI_GP0_AWREADY_S2, M_AXI_GP0_AWREADY_S1, M_AXI_GP0_AWREADY_S0}),
    .m_axi_wdata({M_AXI_GP0_WDATA_S6, M_AXI_GP0_WDATA_S5, M_AXI_GP0_WDATA_S4, M_AXI_GP0_WDATA_S3, M_AXI_GP0_WDATA_S2, M_AXI_GP0_WDATA_S1, M_AXI_GP0_WDATA_S0}),
    .m_axi_wstrb({M_AXI_GP0_WSTRB_S6, M_AXI_GP0_WSTRB_S5, M_AXI_GP0_WSTRB_S4, M_AXI_GP0_WSTRB_S3, M_AXI_GP0_WSTRB_S2, M_AXI_GP0_WSTRB_S1, M_AXI_GP0_WSTRB_S0}),
    .m_axi_wvalid({M_AXI_GP0_WVALID_S6, M_AXI_GP0_WVALID_S5, M_AXI_GP0_WVALID_S4, M_AXI_GP0_WVALID_S3, M_AXI_GP0_WVALID_S2, M_AXI_GP0_WVALID_S1, M_AXI_GP0_WVALID_S0}),
    .m_axi_wready({M_AXI_GP0_WREADY_S6, M_AXI_GP0_WREADY_S5, M_AXI_GP0_WREADY_S4, M_AXI_GP0_WREADY_S3, M_AXI_GP0_WREADY_S2, M_AXI_GP0_WREADY_S1, M_AXI_GP0_WREADY_S0}),
    .m_axi_bresp({M_AXI_GP0_BRESP_S6, M_AXI_GP0_BRESP_S5, M_AXI_GP0_BRESP_S4, M_AXI_GP0_BRESP_S3, M_AXI_GP0_BRESP_S2, M_AXI_GP0_BRESP_S1, M_AXI_GP0_BRESP_S0}),
    .m_axi_bvalid({M_AXI_GP0_BVALID_S6, M_AXI_GP0_BVALID_S5, M_AXI_GP0_BVALID_S4, M_AXI_GP0_BVALID_S3, M_AXI_GP0_BVALID_S2, M_AXI_GP0_BVALID_S1, M_AXI_GP0_BVALID_S0}),
    .m_axi_bready({M_AXI_GP0_BREADY_S6, M_AXI_GP0_BREADY_S5, M_AXI_GP0_BREADY_S4, M_AXI_GP0_BREADY_S3, M_AXI_GP0_BREADY_S2, M_AXI_GP0_BREADY_S1, M_AXI_GP0_BREADY_S0}),
    .m_axi_araddr({M_AXI_GP0_ARADDR_S6, M_AXI_GP0_ARADDR_S5, M_AXI_GP0_ARADDR_S4, M_AXI_GP0_ARADDR_S3, M_AXI_GP0_ARADDR_S2, M_AXI_GP0_ARADDR_S1, M_AXI_GP0_ARADDR_S0}),
    .m_axi_arvalid({M_AXI_GP0_ARVALID_S6, M_AXI_GP0_ARVALID_S5, M_AXI_GP0_ARVALID_S4, M_AXI_GP0_ARVALID_S3, M_AXI_GP0_ARVALID_S2, M_AXI_GP0_ARVALID_S1, M_AXI_GP0_ARVALID_S0}),
    .m_axi_arready({M_AXI_GP0_ARREADY_S6, M_AXI_GP0_ARREADY_S5, M_AXI_GP0_ARREADY_S4, M_AXI_GP0_ARREADY_S3, M_AXI_GP0_ARREADY_S2, M_AXI_GP0_ARREADY_S1, M_AXI_GP0_ARREADY_S0}),
    .m_axi_rdata({M_AXI_GP0_RDATA_S6, M_AXI_GP0_RDATA_S5, M_AXI_GP0_RDATA_S4, M_AXI_GP0_RDATA_S3, M_AXI_GP0_RDATA_S2, M_AXI_GP0_RDATA_S1, M_AXI_GP0_RDATA_S0}),
    .m_axi_rresp({M_AXI_GP0_RRESP_S6, M_AXI_GP0_RRESP_S5, M_AXI_GP0_RRESP_S4, M_AXI_GP0_RRESP_S3, M_AXI_GP0_RRESP_S2, M_AXI_GP0_RRESP_S1, M_AXI_GP0_RRESP_S0}),
    .m_axi_rvalid({M_AXI_GP0_RVALID_S6, M_AXI_GP0_RVALID_S5, M_AXI_GP0_RVALID_S4, M_AXI_GP0_RVALID_S3, M_AXI_GP0_RVALID_S2, M_AXI_GP0_RVALID_S1, M_AXI_GP0_RVALID_S0}),
    .m_axi_rready({M_AXI_GP0_RREADY_S6, M_AXI_GP0_RREADY_S5, M_AXI_GP0_RREADY_S4, M_AXI_GP0_RREADY_S3, M_AXI_GP0_RREADY_S2, M_AXI_GP0_RREADY_S1, M_AXI_GP0_RREADY_S0})
  );

  (* mark_debug = "true", keep = "true" *)
  wire spi0_sclk;
  (* mark_debug = "true", keep = "true" *)
  wire spi0_mosi;
  (* mark_debug = "true", keep = "true" *)
  wire spi0_miso;
  (* mark_debug = "true", keep = "true" *)
  wire spi0_ss0;
  (* mark_debug = "true", keep = "true" *)
  wire spi0_ss1;
  (* mark_debug = "true", keep = "true" *)
  wire spi0_ss2;

  (* mark_debug = "true", keep = "true" *)
  wire [63:0] ps_gpio_out;
  (* mark_debug = "true", keep = "true" *)
  wire [63:0] ps_gpio_in;

  assign DBA_CPLD_JTAG_TCK = ps_gpio_out[0];
  assign DBA_CPLD_JTAG_TDI = ps_gpio_out[1];
  assign DBA_CPLD_JTAG_TMS = ps_gpio_out[2];
  assign ps_gpio_in[3]     = DBA_CPLD_JTAG_TDO;

  // Processing System
  n310_ps inst_n310_ps
  (
    .SPI0_SCLK(spi0_sclk),
    .SPI0_MOSI(spi0_mosi),
    .SPI0_MISO(spi0_miso),
    .SPI0_SS0(spi0_ss0),
    .SPI0_SS1(spi0_ss1),
    .SPI0_SS2(spi0_ss2),

    .M_AXI_GP0_ARVALID(M_AXI_GP0_ARVALID),
    .M_AXI_GP0_ARREADY(M_AXI_GP0_ARREADY),
    .M_AXI_GP0_ARADDR(M_AXI_GP0_ARADDR),
     // Write Address Channel
    .M_AXI_GP0_AWVALID(M_AXI_GP0_AWVALID),
    .M_AXI_GP0_AWREADY(M_AXI_GP0_AWREADY),
    .M_AXI_GP0_AWADDR(M_AXI_GP0_AWADDR),
    // Write Data Channel
    .M_AXI_GP0_WVALID(M_AXI_GP0_WVALID),
    .M_AXI_GP0_WDATA(M_AXI_GP0_WDATA),
    .M_AXI_GP0_WSTRB(M_AXI_GP0_WSTRB),
    .M_AXI_GP0_WREADY(M_AXI_GP0_WREADY),
    // Read Data Channel
    .M_AXI_GP0_RVALID(M_AXI_GP0_RVALID),
    .M_AXI_GP0_RDATA(M_AXI_GP0_RDATA),
    .M_AXI_GP0_RRESP(M_AXI_GP0_RRESP),
    .M_AXI_GP0_RREADY(M_AXI_GP0_RREADY),
    // Write Response Channel
    .M_AXI_GP0_BREADY(M_AXI_GP0_BREADY),
    .M_AXI_GP0_BRESP(M_AXI_GP0_BRESP),
    .M_AXI_GP0_BVALID(M_AXI_GP0_BVALID),

    .S_AXI_HP0_AWID(S_AXI_HP0_AWID),
    .S_AXI_HP0_AWADDR(S_AXI_HP0_AWADDR),
    .S_AXI_HP0_AWPROT(S_AXI_HP0_AWPROT),
    .S_AXI_HP0_AWVALID(S_AXI_HP0_AWVALID),
    .S_AXI_HP0_AWREADY(S_AXI_HP0_AWREADY),
    .S_AXI_HP0_WDATA(S_AXI_HP0_WDATA),
    .S_AXI_HP0_WSTRB(S_AXI_HP0_WSTRB),
    .S_AXI_HP0_WVALID(S_AXI_HP0_WVALID),
    .S_AXI_HP0_WREADY(S_AXI_HP0_WREADY),
    .S_AXI_HP0_BRESP(S_AXI_HP0_BRESP),
    .S_AXI_HP0_BVALID(S_AXI_HP0_BVALID),
    .S_AXI_HP0_BREADY(S_AXI_HP0_BREADY),
    .S_AXI_HP0_ARID(S_AXI_HP0_ARID),
    .S_AXI_HP0_ARADDR(S_AXI_HP0_ARADDR),
    .S_AXI_HP0_ARPROT(S_AXI_HP0_ARPROT),
    .S_AXI_HP0_ARVALID(S_AXI_HP0_ARVALID),
    .S_AXI_HP0_ARREADY(S_AXI_HP0_ARREADY),
    .S_AXI_HP0_RDATA(S_AXI_HP0_RDATA),
    .S_AXI_HP0_RRESP(S_AXI_HP0_RRESP),
    .S_AXI_HP0_RVALID(S_AXI_HP0_RVALID),
    .S_AXI_HP0_RREADY(S_AXI_HP0_RREADY),
    .S_AXI_HP0_AWLEN(S_AXI_HP0_AWLEN),
    .S_AXI_HP0_RLAST(S_AXI_HP0_RLAST),
    .S_AXI_HP0_ARCACHE(S_AXI_HP0_ARCACHE),
    .S_AXI_HP0_AWSIZE(S_AXI_HP0_AWSIZE),
    .S_AXI_HP0_AWBURST(S_AXI_HP0_AWBURST),
    .S_AXI_HP0_AWCACHE(S_AXI_HP0_AWCACHE),
    .S_AXI_HP0_WLAST(S_AXI_HP0_WLAST),
    .S_AXI_HP0_ARLEN(S_AXI_HP0_ARLEN),
    .S_AXI_HP0_ARBURST(S_AXI_HP0_ARBURST),
    .S_AXI_HP0_ARSIZE(S_AXI_HP0_ARSIZE),

    .S_AXI_GP0_AWID(S_AXI_GP0_AWID),
    .S_AXI_GP0_AWADDR(S_AXI_GP0_AWADDR),
    .S_AXI_GP0_AWPROT(S_AXI_GP0_AWPROT),
    .S_AXI_GP0_AWVALID(S_AXI_GP0_AWVALID),
    .S_AXI_GP0_AWREADY(S_AXI_GP0_AWREADY),
    .S_AXI_GP0_WDATA(S_AXI_GP0_WDATA),
    .S_AXI_GP0_WSTRB(S_AXI_GP0_WSTRB),
    .S_AXI_GP0_WVALID(S_AXI_GP0_WVALID),
    .S_AXI_GP0_WREADY(S_AXI_GP0_WREADY),
    .S_AXI_GP0_BRESP(S_AXI_GP0_BRESP),
    .S_AXI_GP0_BVALID(S_AXI_GP0_BVALID),
    .S_AXI_GP0_BREADY(S_AXI_GP0_BREADY),
    .S_AXI_GP0_ARID(S_AXI_GP0_ARID),
    .S_AXI_GP0_ARADDR(S_AXI_GP0_ARADDR),
    .S_AXI_GP0_ARPROT(S_AXI_GP0_ARPROT),
    .S_AXI_GP0_ARVALID(S_AXI_GP0_ARVALID),
    .S_AXI_GP0_ARREADY(S_AXI_GP0_ARREADY),
    .S_AXI_GP0_RDATA(S_AXI_GP0_RDATA),
    .S_AXI_GP0_RRESP(S_AXI_GP0_RRESP),
    .S_AXI_GP0_RVALID(S_AXI_GP0_RVALID),
    .S_AXI_GP0_RREADY(S_AXI_GP0_RREADY),
    .S_AXI_GP0_AWLEN(S_AXI_GP0_AWLEN),
    .S_AXI_GP0_RLAST(S_AXI_GP0_RLAST),
    .S_AXI_GP0_ARCACHE(S_AXI_GP0_ARCACHE),
    .S_AXI_GP0_AWSIZE(S_AXI_GP0_AWSIZE),
    .S_AXI_GP0_AWBURST(S_AXI_GP0_AWBURST),
    .S_AXI_GP0_AWCACHE(S_AXI_GP0_AWCACHE),
    .S_AXI_GP0_WLAST(S_AXI_GP0_WLAST),
    .S_AXI_GP0_ARLEN(S_AXI_GP0_ARLEN),
    .S_AXI_GP0_ARBURST(S_AXI_GP0_ARBURST),
    .S_AXI_GP0_ARSIZE(S_AXI_GP0_ARSIZE),

    .S_AXI_HP1_AWID(S_AXI_HP1_AWID),
    .S_AXI_HP1_AWADDR(S_AXI_HP1_AWADDR),
    .S_AXI_HP1_AWPROT(S_AXI_HP1_AWPROT),
    .S_AXI_HP1_AWVALID(S_AXI_HP1_AWVALID),
    .S_AXI_HP1_AWREADY(S_AXI_HP1_AWREADY),
    .S_AXI_HP1_WDATA(S_AXI_HP1_WDATA),
    .S_AXI_HP1_WSTRB(S_AXI_HP1_WSTRB),
    .S_AXI_HP1_WVALID(S_AXI_HP1_WVALID),
    .S_AXI_HP1_WREADY(S_AXI_HP1_WREADY),
    .S_AXI_HP1_BRESP(S_AXI_HP1_BRESP),
    .S_AXI_HP1_BVALID(S_AXI_HP1_BVALID),
    .S_AXI_HP1_BREADY(S_AXI_HP1_BREADY),
    .S_AXI_HP1_ARID(S_AXI_HP1_ARID),
    .S_AXI_HP1_ARADDR(S_AXI_HP1_ARADDR),
    .S_AXI_HP1_ARPROT(S_AXI_HP1_ARPROT),
    .S_AXI_HP1_ARVALID(S_AXI_HP1_ARVALID),
    .S_AXI_HP1_ARREADY(S_AXI_HP1_ARREADY),
    .S_AXI_HP1_RDATA(S_AXI_HP1_RDATA),
    .S_AXI_HP1_RRESP(S_AXI_HP1_RRESP),
    .S_AXI_HP1_RVALID(S_AXI_HP1_RVALID),
    .S_AXI_HP1_RREADY(S_AXI_HP1_RREADY),
    .S_AXI_HP1_AWLEN(S_AXI_HP1_AWLEN),
    .S_AXI_HP1_RLAST(S_AXI_HP1_RLAST),
    .S_AXI_HP1_ARCACHE(S_AXI_HP1_ARCACHE),
    .S_AXI_HP1_AWSIZE(S_AXI_HP1_AWSIZE),
    .S_AXI_HP1_AWBURST(S_AXI_HP1_AWBURST),
    .S_AXI_HP1_AWCACHE(S_AXI_HP1_AWCACHE),
    .S_AXI_HP1_WLAST(S_AXI_HP1_WLAST),
    .S_AXI_HP1_ARLEN(S_AXI_HP1_ARLEN),
    .S_AXI_HP1_ARBURST(S_AXI_HP1_ARBURST),
    .S_AXI_HP1_ARSIZE(S_AXI_HP1_ARSIZE),

    .S_AXI_GP1_AWID(S_AXI_GP1_AWID),
    .S_AXI_GP1_AWADDR(S_AXI_GP1_AWADDR),
    .S_AXI_GP1_AWPROT(S_AXI_GP1_AWPROT),
    .S_AXI_GP1_AWVALID(S_AXI_GP1_AWVALID),
    .S_AXI_GP1_AWREADY(S_AXI_GP1_AWREADY),
    .S_AXI_GP1_WDATA(S_AXI_GP1_WDATA),
    .S_AXI_GP1_WSTRB(S_AXI_GP1_WSTRB),
    .S_AXI_GP1_WVALID(S_AXI_GP1_WVALID),
    .S_AXI_GP1_WREADY(S_AXI_GP1_WREADY),
    .S_AXI_GP1_BRESP(S_AXI_GP1_BRESP),
    .S_AXI_GP1_BVALID(S_AXI_GP1_BVALID),
    .S_AXI_GP1_BREADY(S_AXI_GP1_BREADY),
    .S_AXI_GP1_ARID(S_AXI_GP1_ARID),
    .S_AXI_GP1_ARADDR(S_AXI_GP1_ARADDR),
    .S_AXI_GP1_ARPROT(S_AXI_GP1_ARPROT),
    .S_AXI_GP1_ARVALID(S_AXI_GP1_ARVALID),
    .S_AXI_GP1_ARREADY(S_AXI_GP1_ARREADY),
    .S_AXI_GP1_RDATA(S_AXI_GP1_RDATA),
    .S_AXI_GP1_RRESP(S_AXI_GP1_RRESP),
    .S_AXI_GP1_RVALID(S_AXI_GP1_RVALID),
    .S_AXI_GP1_RREADY(S_AXI_GP1_RREADY),
    .S_AXI_GP1_AWLEN(S_AXI_GP1_AWLEN),
    .S_AXI_GP1_RLAST(S_AXI_GP1_RLAST),
    .S_AXI_GP1_ARCACHE(S_AXI_GP1_ARCACHE),
    .S_AXI_GP1_AWSIZE(S_AXI_GP1_AWSIZE),
    .S_AXI_GP1_AWBURST(S_AXI_GP1_AWBURST),
    .S_AXI_GP1_AWCACHE(S_AXI_GP1_AWCACHE),
    .S_AXI_GP1_WLAST(S_AXI_GP1_WLAST),
    .S_AXI_GP1_ARLEN(S_AXI_GP1_ARLEN),
    .S_AXI_GP1_ARBURST(S_AXI_GP1_ARBURST),
    .S_AXI_GP1_ARSIZE(S_AXI_GP1_ARSIZE),

    // Misc Interrupts, GPIO, clk
    .IRQ_F2P(IRQ_F2P),

    .GPIO_I(ps_gpio_in),
    .GPIO_O(ps_gpio_out),

    .FCLK_CLK0(FCLK_CLK0),
    .FCLK_RESET0(FCLK_RESET0),
    .FCLK_CLK1(FCLK_CLK1),
    .FCLK_RESET1(FCLK_RESET1),
    .FCLK_CLK2(FCLK_CLK2),
    .FCLK_RESET2(FCLK_RESET2),
    .FCLK_CLK3(FCLK_CLK3),
    .FCLK_RESET3(FCLK_RESET3),

    // Outward connections to the pins
    .MIO(MIO),
    .DDR_CAS_n(DDR_CAS_n),
    .DDR_CKE(DDR_CKE),
    .DDR_Clk_n(DDR_Clk_n),
    .DDR_Clk(DDR_Clk),
    .DDR_CS_n(DDR_CS_n),
    .DDR_DRSTB(DDR_DRSTB),
    .DDR_ODT(DDR_ODT),
    .DDR_RAS_n(DDR_RAS_n),
    .DDR_WEB(DDR_WEB),
    .DDR_BankAddr(DDR_BankAddr),
    .DDR_Addr(DDR_Addr),
    .DDR_VRN(DDR_VRN),
    .DDR_VRP(DDR_VRP),
    .DDR_DM(DDR_DM),
    .DDR_DQ(DDR_DQ),
    .DDR_DQS_n(DDR_DQS_n),
    .DDR_DQS(DDR_DQS),
    .PS_SRSTB(PS_SRSTB),
    .PS_CLK(PS_CLK),
    .PS_PORB(PS_PORB)
);

   ///////////////////////////////////////////////////////
   //
   // DB Connections
   //
   ///////////////////////////////////////////////////////

   // Drive CPLD Address line with PS GPIO
   wire [2:0]                         spi_mux;
   wire                               cpld_reset;
   assign DBA_CPLD_ADDR             = spi_mux;

   // SPI to CPLD
   assign DBA_CPLD_SPI_SCLK_ATR_RX2 = spi0_sclk;
   assign DBA_CPLD_SPI_SDI_ATR_TX2  = spi0_mosi;  // Slave In
   assign DBA_CPLD_SEL_ATR_SPI_N    = 1'b0;       // Select SPI
   assign DBA_CPLD_SPI_CSB_ATR_TX1  = spi0_ss0;

   assign DBA_CPLD_RESET_N          = cpld_reset;

   assign DBA_MYK_SPI_CS_N          = spi0_ss1;
   assign DBA_MYK_SPI_SCLK          = spi0_sclk;
   assign DBA_MYK_SPI_SDIO          = spi0_mosi;

   assign spi0_miso = DBA_MYK_SPI_SDO | DBA_CPLD_SPI_SDO;

   assign DBA_CH1_TX_DSA_LE   = 1'b1;
   assign DBA_CH1_TX_DSA_DATA = 6'b0;
   assign DBA_CH1_RX_DSA_LE   = 1'b1;
   assign DBA_CH1_RX_DSA_DATA = 6'b0;

   assign DBA_CH2_TX_DSA_LE   = 1'b1;
   assign DBA_CH2_TX_DSA_DATA = 6'b0;
   assign DBA_CH2_RX_DSA_LE   = 1'b1;
   assign DBA_CH2_RX_DSA_DATA = 6'b0;

   ///////////////////////////////////////////////////////
   //
   // N310 CORE
   //
   ///////////////////////////////////////////////////////

   // Radio Clock Generation

   wire  [31:0]     rx0;
   wire  [31:0]     rx1;
   wire  [31:0]     rx2;
   wire  [31:0]     rx3;
   wire  [31:0]     tx0;
   wire  [31:0]     tx1;
   wire  [31:0]     tx2;
   wire  [31:0]     tx3;
   wire             rx_stb; // FIXME: 2 bit
   wire             tx_stb; // FIXME: 2 bit


  //TODO: Remove testing RX counter
  //always @(posedge sample_clk_1x) begin
  //  if (bus_rst) begin
  //    rx0 <= 32'b0;
  //    rx1 <= 32'b0;
  //  end else begin
  //    rx0 <= rx0 + 1'b1;
  //    if (rx0 == 32'hffff)
  //      rx1 <= rx1 + 1'b1;
  //  end
  //end

  n310_core #(.REG_AWIDTH(14)) n310_core
  (
    //Clocks and resets
    .radio_clk(/*radio_clk*/bus_clk), //FIXME: Move to radio_clk
    .radio_rst(/*radio_rst*/bus_rst), //FIXME: Move to radio_rst
    .bus_clk(bus_clk),
    .bus_rst(bus_rst),

    // AXI4-Lite: Write address port (domain: s_axi_aclk)
    .s_axi_awaddr(M_AXI_GP0_AWADDR_S4),
    .s_axi_awvalid(M_AXI_GP0_AWVALID_S4),
    .s_axi_awready(M_AXI_GP0_AWREADY_S4),
    // AXI4-Lite: Write data port (domain: s_axi_aclk)
    .s_axi_wdata(M_AXI_GP0_WDATA_S4),
    .s_axi_wstrb(M_AXI_GP0_WSTRB_S4),
    .s_axi_wvalid(M_AXI_GP0_WVALID_S4),
    .s_axi_wready(M_AXI_GP0_WREADY_S4),
    // AXI4-Lite: Write response port (domain: s_axi_aclk)
    .s_axi_bresp(M_AXI_GP0_BRESP_S4),
    .s_axi_bvalid(M_AXI_GP0_BVALID_S4),
    .s_axi_bready(M_AXI_GP0_BREADY_S4),
    // AXI4-Lite: Read address port (domain: s_axi_aclk)
    .s_axi_araddr(M_AXI_GP0_ARADDR_S4),
    .s_axi_arvalid(M_AXI_GP0_ARVALID_S4),
    .s_axi_arready(M_AXI_GP0_ARREADY_S4),
    // AXI4-Lite: Read data port (domain: s_axi_aclk)
    .s_axi_rdata(M_AXI_GP0_RDATA_S4),
    .s_axi_rresp(M_AXI_GP0_RRESP_S4),
    .s_axi_rvalid(M_AXI_GP0_RVALID_S4),
    .s_axi_rready(M_AXI_GP0_RREADY_S4),

    // JESD204
    .rx0(rx0),
    .tx0(tx0),

    .rx1(rx1),
    .tx1(tx1),

    .rx2(rx2),
    .tx2(tx2),

    .rx3(rx3),
    .tx3(tx3),

    //DMA
    .dmao_tdata(),
    .dmao_tlast(),
    .dmao_tvalid(),
    .dmao_tready(),

    .dmai_tdata(),
    .dmai_tlast(),
    .dmai_tvalid(),
    .dmai_tready(),

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
    .spi_mux(spi_mux),
    .cpld_reset(cpld_reset)
  );

  // //////////////////////////////////////////////////////////////////////
  //
  // JESD204b CORE
  //
  // //////////////////////////////////////////////////////////////////////

  wire  [3:0]  jesd_adc_rx_p;
  wire  [3:0]  jesd_adc_rx_n;
  wire  [3:0]  jesd_dac_tx_p;
  wire  [3:0]  jesd_dac_tx_n;
  wire         jesd_adc_sync;
  wire         jesd_dac_sync;

  // JESD204 core
   assign jesd_adc_rx_p = {USRPIO_A_RX_3_P, USRPIO_A_RX_2_P, USRPIO_A_RX_1_P, USRPIO_A_RX_0_P};
   assign jesd_adc_rx_n = {USRPIO_A_RX_3_N, USRPIO_A_RX_2_N, USRPIO_A_RX_1_N, USRPIO_A_RX_0_N};
   assign {USRPIO_A_TX_3_P, USRPIO_A_TX_2_P, USRPIO_A_TX_1_P, USRPIO_A_TX_0_P} = jesd_dac_tx_p;
   assign {USRPIO_A_TX_3_N, USRPIO_A_TX_2_N, USRPIO_A_TX_1_N, USRPIO_A_TX_0_N} = jesd_dac_tx_n;
  // FIXME: Add 2 JESD cores.

  jesd204_core_wrapper #(
    .REG_BASE(0),
    .REG_DWIDTH(32),
    .REG_AWIDTH(14)
  ) jesd204_core_wrapper (

   //Clocks and resets
   .areset(global_rst),
   .bus_clk(bus_clk),
   .bus_rst(bus_rst),
   .db_fpga_clk_p(DBA_FPGA_CLK_P),
   .db_fpga_clk_n(DBA_FPGA_CLK_N),
   .sample_clk(radio_clk),

   // AXI4-Lite: Write address port (domain: s_axi_aclk)
   .s_axi_awaddr(M_AXI_GP0_AWADDR_S5),
   .s_axi_awvalid(M_AXI_GP0_AWVALID_S5),
   .s_axi_awready(M_AXI_GP0_AWREADY_S5),
   // AXI4-Lite: Write data port (domain: s_axi_aclk)
   .s_axi_wdata(M_AXI_GP0_WDATA_S5),
   .s_axi_wstrb(M_AXI_GP0_WSTRB_S5),
   .s_axi_wvalid(M_AXI_GP0_WVALID_S5),
   .s_axi_wready(M_AXI_GP0_WREADY_S5),
   // AXI4-Lite: Write response port (domain: s_axi_aclk)
   .s_axi_bresp(M_AXI_GP0_BRESP_S5),
   .s_axi_bvalid(M_AXI_GP0_BVALID_S5),
   .s_axi_bready(M_AXI_GP0_BREADY_S5),
   // AXI4-Lite: Read address port (domain: s_axi_aclk)
   .s_axi_araddr(M_AXI_GP0_ARADDR_S5),
   .s_axi_arvalid(M_AXI_GP0_ARVALID_S5),
   .s_axi_arready(M_AXI_GP0_ARREADY_S5),
   // AXI4-Lite: Read data port (domain: s_axi_aclk)
   .s_axi_rdata(M_AXI_GP0_RDATA_S5),
   .s_axi_rresp(M_AXI_GP0_RRESP_S5),
   .s_axi_rvalid(M_AXI_GP0_RVALID_S5),
   .s_axi_rready(M_AXI_GP0_RREADY_S5),
   .rx0(rx0),
   .rx1(rx1),
   .rx_stb(rx_stb),
   .tx0(tx0),
   .tx1(tx1),
   .tx_stb(tx_stb),
   .lmk_sync(DBA_CPLD_SYNC_ATR_RX1),
   .myk_reset(/*DBA_CPLD_RESET_N*/), //TODO
   .jesd_dac_sync(jesd_dac_sync),
   .jesd_adc_sync(jesd_adc_sync),

   .jesd_refclk_p(USRPIO_A_MGTCLK_P),
   .jesd_refclk_n(USRPIO_A_MGTCLK_N),
   .jesd_adc_rx_p(jesd_adc_rx_p),
   .jesd_adc_rx_n(jesd_adc_rx_n),
   .jesd_dac_tx_p(jesd_dac_tx_p),
   .jesd_dac_tx_n(jesd_dac_tx_n),
   .myk_adc_sync_p(DBA_MYK_SYNC_IN_P),
   .myk_adc_sync_n(DBA_MYK_SYNC_IN_N),
   .myk_dac_sync_p(DBA_MYK_SYNC_OUT_P),
   .myk_dac_sync_n(DBA_MYK_SYNC_OUT_N),
   .fpga_sysref_p(DBA_FPGA_SYSREF_P),
   .fpga_sysref_n(DBA_FPGA_SYSREF_N)
  );

  // FIXME: Placeholder for XBAR AXI DMA
  axi_dummy #(.DEC_ERR(1'b0)) inst_axi_dummy
  (
    .s_axi_aclk(bus_clk),
    .s_axi_areset(bus_rst),

    .s_axi_awaddr(M_AXI_GP0_AWADDR_S6),
    .s_axi_awvalid(M_AXI_GP0_AWVALID_S6),
    .s_axi_awready(M_AXI_GP0_AWREADY_S6),

    .s_axi_wdata(M_AXI_GP0_WDATA_S6),
    .s_axi_wstrb(M_AXI_GP0_WSTRB_S6),
    .s_axi_wvalid(M_AXI_GP0_WVALID_S6),
    .s_axi_wready(M_AXI_GP0_WREADY_S6),

    .s_axi_bresp(M_AXI_GP0_BRESP_S6),
    .s_axi_bvalid(M_AXI_GP0_BVALID_S6),
    .s_axi_bready(M_AXI_GP0_BREADY_S6),

    .s_axi_araddr(M_AXI_GP0_ARADDR_S6),
    .s_axi_arvalid(M_AXI_GP0_ARVALID_S6),
    .s_axi_arready(M_AXI_GP0_ARREADY_S6),

    .s_axi_rdata(M_AXI_GP0_RDATA_S6),
    .s_axi_rresp(M_AXI_GP0_RRESP_S6),
    .s_axi_rvalid(M_AXI_GP0_RVALID_S6),
    .s_axi_rready(M_AXI_GP0_RREADY_S6)
  );


  // //////////////////////////////////////////////////////////////////////
  //
  // LEDS
  //
  // //////////////////////////////////////////////////////////////////////

   reg [31:0] counter1;
   always @(posedge bus_clk) begin
     if (FCLK_RESET0)
       counter1 <= 32'd0;
     else
       counter1 <= counter1 + 32'd1;
   end
   reg [31:0] counter2;
   always @(posedge radio_clk) begin
     if (FCLK_RESET0)
       counter2 <= 32'd0;
     else
       counter2 <= counter2 + 32'd1;
   end
   reg [31:0] counter3;
   always @(posedge gige_refclk) begin
     if (FCLK_RESET0)
       counter3 <= 32'd0;
     else
       counter3 <= counter3 + 32'd1;
   end

   assign {SFP_0_LED_B, SFP_1_LED_B} = {sfp0_phy_status[0],sfp1_phy_status[0]};

   assign PANEL_LED_LINK = counter1[26];
   assign PANEL_LED_REF = counter2[26];
   assign PANEL_LED_GPS = counter3[26];

   // Check Clock frequency through PPS_OUT

   // TODO:  Only for DEBUG
   ODDR #(
      .DDR_CLK_EDGE("SAME_EDGE"), // "OPPOSITE_EDGE" or "SAME_EDGE"
      .INIT(1'b0),    // Initial value of Q: 1'b0 or 1'b1
      .SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC"
   ) fclk_inst (
      .Q(REF_1PPS_OUT),   // 1-bit DDR output
      .C(gige_refclk),   // 1-bit clock input
      .CE(1'b1), // 1-bit clock enable input
      .D1(1'b0), // 1-bit data input (positive edge)
      .D2(1'b1), // 1-bit data input (negative edge)
      .R(1'b0),   // 1-bit reset
      .S(1'b0)    // 1-bit set
   );

endmodule
