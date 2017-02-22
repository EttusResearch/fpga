//
// Copyright 2016-2017 Ettus Research
//
module n310
(

   //inout [11:0] FpgaGpio,
   //output FpgaGpioEn,

   input FPGA_REFCLK,
   //input REF_1PPS_IN,
   //input REF_1PPS_IN_MGMT,
   output REF_1PPS_OUT,
   //output [1:0] CLK_MAINREF_SEL,
   output PWREN_CLK_DDR100MHZ,

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
   //input GPS_1PPS,
   //input GPS_1PPS_RAW,
   //input GPS_ALARM,
   //input GPS_LOCKOK,
   //output GPS_NINITSURV,
   //output GPS_NMOBILE,
   //output GPS_NRESET,
   //input GPS_PHASELOCK,
   //input GPS_SURVEY,
   //input GPS_WARMUP,

   //Misc
   //input ENET0_CLK125,
   //output ENET0_LED1A,
   //output ENET0_LED1B,
   //inout ENET0_PTP,
   //output ENET0_PTP_DIR,
   //inout ATSHA204_SDA,
   input FPGA_PL_RESETN, //??
   output PWREN_CLK_MAINREF,
   //input [1:0] FPGA_TEST,// TODO :Check this ??

   //White Rabbit
   //input WB_20MHZ_CLK,
   output PWREN_CLK_WB_CDCM,
   output WB_CDCM_OD0,
   output WB_CDCM_OD1,
   output WB_CDCM_OD2,
   output WB_CDCM_PR0,
   output WB_CDCM_PR1,
   output WB_CDCM_RESETN,
   //output WB_DAC_DIN,
   //output WB_DAC_NCLR,
   //output WB_DAC_NLDAC,
   //output WB_DAC_NSYNC,
   //output WB_DAC_SCLK,
   //output PWREN_CLK_WB_20MHZ,
   output PWREN_CLK_WB_25MHZ,

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
   output PWREN_CLK_MGT156MHZ,

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
   //input SFP_0_LOS,
   output SFP_0_RS0,
   output SFP_0_RS1,
   output SFP_0_TXDISABLE,
   //input SFP_0_TXFAULT,

   //SFP+ 1, Slow Speed, Bank 13 3.3V
   //input SFP_1_I2C_NPRESENT,
   output SFP_1_LED_A,
   output SFP_1_LED_B,
   //input SFP_1_LOS,
   output SFP_1_RS0,
   output SFP_1_RS1,
   output SFP_1_TXDISABLE
   //input SFP_1_TXFAULT

   //TODO: Uncomment when connected here
   //USRP IO
   //inout  USRPIO_A_GP_0_P, USRPIO_A_GP_1_P, USRPIO_A_GP_2_P, USRPIO_A_GP_3_P,
   //inout  USRPIO_A_GP_0_N, USRPIO_A_GP_1_N, USRPIO_A_GP_2_N, USRPIO_A_GP_3_N,
   //inout  USRPIO_A_GP_4_P, USRPIO_A_GP_5_P, USRPIO_A_GP_6_P, USRPIO_A_GP_7_P,
   //inout  USRPIO_A_GP_4_N, USRPIO_A_GP_5_N, USRPIO_A_GP_6_N, USRPIO_A_GP_7_N,
   //inout  USRPIO_A_GP_8_P, USRPIO_A_GP_9_P, USRPIO_A_GP_10_P, USRPIO_A_GP_11_P,
   //inout  USRPIO_A_GP_8_N, USRPIO_A_GP_9_N, USRPIO_A_GP_10_N, USRPIO_A_GP_11_N,
   //inout  USRPIO_A_GP_12_P, USRPIO_A_GP_13_P, USRPIO_A_GP_14_P, USRPIO_A_GP_15_P,
   //inout  USRPIO_A_GP_12_N, USRPIO_A_GP_13_N, USRPIO_A_GP_14_N, USRPIO_A_GP_15_N,
   //inout  USRPIO_A_GP_16_P, USRPIO_A_GP_17_P, USRPIO_A_GP_18_P, USRPIO_A_GP_19_P,
   //inout  USRPIO_A_GP_16_N, USRPIO_A_GP_17_N, USRPIO_A_GP_18_N, USRPIO_A_GP_19_N,
   //inout  USRPIO_A_GP_20_P, USRPIO_A_GP_21_P, USRPIO_A_GP_22_P, USRPIO_A_GP_23_P,
   //inout  USRPIO_A_GP_20_N, USRPIO_A_GP_21_N, USRPIO_A_GP_22_N, USRPIO_A_GP_23_N,
   //inout  USRPIO_A_GP_24_P, USRPIO_A_GP_25_P, USRPIO_A_GP_26_P, USRPIO_A_GP_27_P,
   //inout  USRPIO_A_GP_24_N, USRPIO_A_GP_25_N, USRPIO_A_GP_26_N, USRPIO_A_GP_27_N,
   //inout  USRPIO_A_GP_28_P, USRPIO_A_GP_29_P, USRPIO_A_GP_30_P, USRPIO_A_GP_31_P,
   //inout  USRPIO_A_GP_28_N, USRPIO_A_GP_29_N, USRPIO_A_GP_30_N, USRPIO_A_GP_31_N,
   //inout  USRPIO_A_GP_32_P,
   //inout  USRPIO_A_GP_32_N,
   //input USRPIO_A_I2C_NINTRQ,
   //input USRPIO_A_MGTCLK_P,
   //input USRPIO_A_MGTCLK_N,
   //input USRPIO_A_RX_0_P, USRPIO_A_RX_1_P, USRPIO_A_RX_2_P, USRPIO_A_RX_3_P,
   //input USRPIO_A_RX_0_N, USRPIO_A_RX_1_N, USRPIO_A_RX_2_N, USRPIO_A_RX_3_N,
   //output USRPIO_A_TX_0_P, USRPIO_A_TX_1_P, USRPIO_A_TX_2_P, USRPIO_A_TX_3_P,
   //output USRPIO_A_TX_0_N, USRPIO_A_TX_1_N, USRPIO_A_TX_2_N, USRPIO_A_TX_3_N,

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
   //input USRPIO_B_I2C_NINTRQ,
   //input USRPIO_B_MGTCLK_P,
   //input USRPIO_B_MGTCLK_N,
   //input USRPIO_B_RX_0_P, USRPIO_B_RX_1_P, USRPIO_B_RX_2_P, USRPIO_B_RX_3_P,
   //input USRPIO_B_RX_0_N, USRPIO_B_RX_1_N, USRPIO_B_RX_2_N, USRPIO_B_RX_3_N,
   //output USRPIO_B_TX_0_P, USRPIO_B_TX_1_P, USRPIO_B_TX_2_P, USRPIO_B_TX_3_P,
   //output USRPIO_B_TX_0_N, USRPIO_B_TX_1_N, USRPIO_B_TX_2_N, USRPIO_B_TX_3_N

);
  localparam N_AXILITE_SLAVES = 4;

  localparam REG_AWIDTH = 14; // log2(0x4000)
  localparam REG_DWIDTH = 32;

  localparam REG_BASE_MISC = 32'h4001_0000;
  localparam REG_BASE_ETH_0 = 32'h4000_0000;
  localparam REG_BASE_ETH_1 = 32'h4008_0000;

   //TODO: Add bus_clk_gen, bus_rst, sw_rst
   wire bus_clk;
   wire bus_rst;
   wire global_rst;

   assign bus_rst = global_rst; //FIXME

  // Internal connections to PS
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

   //Turn on power to the clocks
   assign PWREN_CLK_MGT156MHZ = 1'b1;
   assign PWREN_CLK_MAINREF   = 1'b1;
   assign PWREN_CLK_DDR100MHZ = 1'b1;

   // Configure the clocks to output 125 MHz.
   assign PWREN_CLK_WB_25MHZ = 1'b1;
   assign PWREN_CLK_WB_CDCM = 1'b1;
   assign WB_CDCM_RESETN = 1'b1;
   // Prescalar and Feedback Dividers
   assign WB_CDCM_PR1 = 1'b1;
   assign WB_CDCM_PR0 = 1'b1;
   //Output Dividers
   assign WB_CDCM_OD2 = 1'b0;
   assign WB_CDCM_OD1 = 1'b1;
   assign WB_CDCM_OD0 = 1'b1;

   // Check Clock frequency through PPS_OUT

   ODDR #(
      .DDR_CLK_EDGE("SAME_EDGE"), // "OPPOSITE_EDGE" or "SAME_EDGE"
      .INIT(1'b0),    // Initial value of Q: 1'b0 or 1'b1
      .SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC"
   ) fclk_inst (
      .Q(REF_1PPS_OUT),   // 1-bit DDR output
      .C(FCLK_CLK0),   // 1-bit clock input
      .CE(1'b1), // 1-bit clock enable input
      .D1(1'b0), // 1-bit data input (positive edge)
      .D2(1'b1), // 1-bit data input (negative edge)
      .R(1'b0),   // 1-bit reset
      .S(1'b0)    // 1-bit set
   );

  wire ref_clk_10mhz; //TODO: Check if this is 10 MHz
  IBUF FPGA_REFCLK_ibuf (
      .I(FPGA_REFCLK),
      .O(ref_clk_10mhz));


`ifdef BUILD_1G
   wire  gige_refclk, gige_refclk_bufg;

   one_gige_phy_clk_gen gige_clk_gen_i (
      .areset(global_rst),
      .refclk_p(WB_CDCM_CLK2_P),
      .refclk_n(WB_CDCM_CLK2_N),
      .refclk(gige_refclk),
      .refclk_bufg(gige_refclk_bufg)
   );
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

  (* mark_debug = "true", keep = "true" *)
  wire        arm_eth0_irq;

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

  (* mark_debug = "true", keep = "true" *)
  wire        arm_eth1_irq;

   network_interface #(
`ifdef SFP0_10GBE
      .PROTOCOL("10GbE"),
`endif
`ifdef SFP0_1GBE
      .PROTOCOL("1GbE"),
`endif
      .REG_BASE(REG_BASE_ETH_0),
      .DWIDTH(REG_DWIDTH),     // Width of the AXI4-Lite data bus (must be 32 or 64)
      .AWIDTH(REG_AWIDTH),     // Width of the address bus
      .MDIO_EN(1'b1),
      .PORTNUM(8'd0)
   ) network_interface_0 (
      .areset(global_rst),
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

      .sfpp_rxlos(1'b0/*SFP_0_LOS*/),
      .sfpp_tx_fault(1'b0/*SFP_0_TXFAULT*/),
      .sfpp_tx_disable(/*SFP_0_TXDISABLE*/),

      .sfp_phy_status(sfp0_phy_status),

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
      .e2c_tuser(arm_eth0_rx_tuser),
      .e2c_tlast(arm_eth0_rx_tlast),
      .e2c_tvalid(arm_eth0_rx_tvalid),
      .e2c_tready(arm_eth0_rx_tready),

      // CPU to Ethernet
      .c2e_tdata(arm_eth0_tx_tdata),
      .c2e_tuser(arm_eth0_tx_tuser),
      .c2e_tlast(arm_eth0_tx_tlast),
      .c2e_tvalid(arm_eth0_tx_tvalid),
      .c2e_tready(arm_eth0_tx_tready)
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
      .REG_BASE(REG_BASE_ETH_1),
      .MDIO_EN(1'b1),
      .PORTNUM(8'd0)
   ) network_interface_1 (
      .areset(global_rst),
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

      .sfpp_rxlos(1'b0/*SFP_1_LOS*/),
      .sfpp_tx_fault(1'b0/*SFP_1_TXFAULT*/),
      .sfpp_tx_disable(/*SFP_1_TXDISABLE*/),

      .sfp_phy_status(sfp1_phy_status),

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
      .e2c_tuser(arm_eth1_rx_tuser),
      .e2c_tlast(arm_eth1_rx_tlast),
      .e2c_tvalid(arm_eth1_rx_tvalid),
      .e2c_tready(arm_eth1_rx_tready),

      // CPU to Ethernet
      .c2e_tdata(arm_eth1_tx_tdata),
      .c2e_tuser(arm_eth1_tx_tuser),
      .c2e_tlast(arm_eth1_tx_tlast),
      .c2e_tvalid(arm_eth1_tx_tvalid),
      .c2e_tready(arm_eth1_tx_tready)
   );


  // loopback test
  /*
  assign      arm_eth0_rx_tdata = arm_eth1_tx_tdata;
  assign      arm_eth0_rx_tvalid = arm_eth1_tx_tvalid;
  assign      arm_eth0_rx_tlast = arm_eth1_tx_tlast;
  assign      arm_eth0_rx_tuser = arm_eth1_tx_tuser;
  assign      arm_eth1_tx_tready = arm_eth0_rx_tready;

  assign      arm_eth1_rx_tdata = arm_eth0_tx_tdata;
  assign      arm_eth1_rx_tvalid = arm_eth0_tx_tvalid;
  assign      arm_eth1_rx_tlast = arm_eth0_tx_tlast;
  assign      arm_eth1_rx_tuser = arm_eth0_tx_tuser;
  assign      arm_eth0_tx_tready = arm_eth1_rx_tready;
*/

  assign      IRQ_F2P[0] = arm_eth0_irq;
  assign      IRQ_F2P[1] = arm_eth1_irq;

  fifo64_to_axi4lite inst_fifo64_to_axi4lite0
  (
    .s_axi_aclk(bus_clk),
    .s_axi_areset(bus_rst),

    .s_axi_awaddr(M_AXI_GP0_AWADDR_S0),
    .s_axi_awvalid(M_AXI_GP0_AWVALID_S0),
    .s_axi_awready(M_AXI_GP0_AWREADY_S0),

    .s_axi_wdata(M_AXI_GP0_WDATA_S0),
    .s_axi_wstrb(M_AXI_GP0_WSTRB_S0),
    .s_axi_wvalid(M_AXI_GP0_WVALID_S0),
    .s_axi_wready(M_AXI_GP0_WREADY_S0),

    .s_axi_bresp(M_AXI_GP0_BRESP_S0),
    .s_axi_bvalid(M_AXI_GP0_BVALID_S0),
    .s_axi_bready(M_AXI_GP0_BREADY_S0),

    .s_axi_araddr(M_AXI_GP0_ARADDR_S0),
    .s_axi_arvalid(M_AXI_GP0_ARVALID_S0),
    .s_axi_arready(M_AXI_GP0_ARREADY_S0),

    .s_axi_rdata(M_AXI_GP0_RDATA_S0),
    .s_axi_rresp(M_AXI_GP0_RRESP_S0),
    .s_axi_rvalid(M_AXI_GP0_RVALID_S0),
    .s_axi_rready(M_AXI_GP0_RREADY_S0),

    .m_axis_tvalid(arm_eth0_tx_tvalid),
    .m_axis_tlast(arm_eth0_tx_tlast),
    .m_axis_tdata(arm_eth0_tx_tdata),
    .m_axis_tready(arm_eth0_tx_tready),
    .m_axis_tuser(arm_eth0_tx_tuser),

    .s_axis_tvalid(arm_eth0_rx_tvalid),
    .s_axis_tlast(arm_eth0_rx_tlast),
    .s_axis_tdata(arm_eth0_rx_tdata),
    .s_axis_tready(arm_eth0_rx_tready),
    .s_axis_tuser(arm_eth0_rx_tuser),

    .irq(arm_eth0_irq)
  );

  axi_dummy #(.DEC_ERR(1'b0)) inst_axi_dummy1
  (
    .s_axi_aclk(bus_clk),
    .s_axi_areset(bus_rst),

    .s_axi_awaddr(M_AXI_GP0_AWADDR_S1),
    .s_axi_awvalid(M_AXI_GP0_AWVALID_S1),
    .s_axi_awready(M_AXI_GP0_AWREADY_S1),

    .s_axi_wdata(M_AXI_GP0_WDATA_S1),
    .s_axi_wstrb(M_AXI_GP0_WSTRB_S1),
    .s_axi_wvalid(M_AXI_GP0_WVALID_S1),
    .s_axi_wready(M_AXI_GP0_WREADY_S1),

    .s_axi_bresp(M_AXI_GP0_BRESP_S1),
    .s_axi_bvalid(M_AXI_GP0_BVALID_S1),
    .s_axi_bready(M_AXI_GP0_BREADY_S1),

    .s_axi_araddr(M_AXI_GP0_ARADDR_S1),
    .s_axi_arvalid(M_AXI_GP0_ARVALID_S1),
    .s_axi_arready(M_AXI_GP0_ARREADY_S1),

    .s_axi_rdata(M_AXI_GP0_RDATA_S1),
    .s_axi_rresp(M_AXI_GP0_RRESP_S1),
    .s_axi_rvalid(M_AXI_GP0_RVALID_S1),
    .s_axi_rready(M_AXI_GP0_RREADY_S1)
  );

  fifo64_to_axi4lite inst_fifo64_to_axi4lite1
  (
    .s_axi_aclk(bus_clk),
    .s_axi_areset(bus_rst),

    .s_axi_awaddr(M_AXI_GP0_AWADDR_S2),
    .s_axi_awvalid(M_AXI_GP0_AWVALID_S2),
    .s_axi_awready(M_AXI_GP0_AWREADY_S2),

    .s_axi_wdata(M_AXI_GP0_WDATA_S2),
    .s_axi_wstrb(M_AXI_GP0_WSTRB_S2),
    .s_axi_wvalid(M_AXI_GP0_WVALID_S2),
    .s_axi_wready(M_AXI_GP0_WREADY_S2),

    .s_axi_bresp(M_AXI_GP0_BRESP_S2),
    .s_axi_bvalid(M_AXI_GP0_BVALID_S2),
    .s_axi_bready(M_AXI_GP0_BREADY_S2),

    .s_axi_araddr(M_AXI_GP0_ARADDR_S2),
    .s_axi_arvalid(M_AXI_GP0_ARVALID_S2),
    .s_axi_arready(M_AXI_GP0_ARREADY_S2),

    .s_axi_rdata(M_AXI_GP0_RDATA_S2),
    .s_axi_rresp(M_AXI_GP0_RRESP_S2),
    .s_axi_rvalid(M_AXI_GP0_RVALID_S2),
    .s_axi_rready(M_AXI_GP0_RREADY_S2),

    .m_axis_tvalid(arm_eth1_tx_tvalid),
    .m_axis_tlast(arm_eth1_tx_tlast),
    .m_axis_tdata(arm_eth1_tx_tdata),
    .m_axis_tready(arm_eth1_tx_tready),
    .m_axis_tuser(arm_eth1_tx_tuser),

    .s_axis_tvalid(arm_eth1_rx_tvalid),
    .s_axis_tlast(arm_eth1_rx_tlast),
    .s_axis_tdata(arm_eth1_rx_tdata),
    .s_axis_tready(arm_eth1_rx_tready),
    .s_axis_tuser(arm_eth1_rx_tuser),

    .irq(arm_eth1_irq)
  );

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
    .m_axi_awaddr({M_AXI_GP0_AWADDR_S4, M_AXI_GP0_AWADDR_S3, M_AXI_GP0_AWADDR_S2, M_AXI_GP0_AWADDR_S1, M_AXI_GP0_AWADDR_S0}),
    .m_axi_awvalid({M_AXI_GP0_AWVALID_S4, M_AXI_GP0_AWVALID_S3, M_AXI_GP0_AWVALID_S2, M_AXI_GP0_AWVALID_S1, M_AXI_GP0_AWVALID_S0}),
    .m_axi_awready({M_AXI_GP0_AWREADY_S4, M_AXI_GP0_AWREADY_S3, M_AXI_GP0_AWREADY_S2, M_AXI_GP0_AWREADY_S1, M_AXI_GP0_AWREADY_S0}),
    .m_axi_wdata({M_AXI_GP0_WDATA_S4, M_AXI_GP0_WDATA_S3, M_AXI_GP0_WDATA_S2, M_AXI_GP0_WDATA_S1, M_AXI_GP0_WDATA_S0}),
    .m_axi_wstrb({M_AXI_GP0_WSTRB_S4, M_AXI_GP0_WSTRB_S3, M_AXI_GP0_WSTRB_S2, M_AXI_GP0_WSTRB_S1, M_AXI_GP0_WSTRB_S0}),
    .m_axi_wvalid({M_AXI_GP0_WVALID_S4, M_AXI_GP0_WVALID_S3, M_AXI_GP0_WVALID_S2, M_AXI_GP0_WVALID_S1, M_AXI_GP0_WVALID_S0}),
    .m_axi_wready({M_AXI_GP0_WREADY_S4, M_AXI_GP0_WREADY_S3, M_AXI_GP0_WREADY_S2, M_AXI_GP0_WREADY_S1, M_AXI_GP0_WREADY_S0}),
    .m_axi_bresp({M_AXI_GP0_BRESP_S4, M_AXI_GP0_BRESP_S3, M_AXI_GP0_BRESP_S2, M_AXI_GP0_BRESP_S1, M_AXI_GP0_BRESP_S0}),
    .m_axi_bvalid({M_AXI_GP0_BVALID_S4, M_AXI_GP0_BVALID_S3, M_AXI_GP0_BVALID_S2, M_AXI_GP0_BVALID_S1, M_AXI_GP0_BVALID_S0}),
    .m_axi_bready({M_AXI_GP0_BREADY_S4, M_AXI_GP0_BREADY_S3, M_AXI_GP0_BREADY_S2, M_AXI_GP0_BREADY_S1, M_AXI_GP0_BREADY_S0}),
    .m_axi_araddr({M_AXI_GP0_ARADDR_S4, M_AXI_GP0_ARADDR_S3, M_AXI_GP0_ARADDR_S2, M_AXI_GP0_ARADDR_S1, M_AXI_GP0_ARADDR_S0}),
    .m_axi_arvalid({M_AXI_GP0_ARVALID_S4, M_AXI_GP0_ARVALID_S3, M_AXI_GP0_ARVALID_S2, M_AXI_GP0_ARVALID_S1, M_AXI_GP0_ARVALID_S0}),
    .m_axi_arready({M_AXI_GP0_ARREADY_S4, M_AXI_GP0_ARREADY_S3, M_AXI_GP0_ARREADY_S2, M_AXI_GP0_ARREADY_S1, M_AXI_GP0_ARREADY_S0}),
    .m_axi_rdata({M_AXI_GP0_RDATA_S4, M_AXI_GP0_RDATA_S3, M_AXI_GP0_RDATA_S2, M_AXI_GP0_RDATA_S1, M_AXI_GP0_RDATA_S0}),
    .m_axi_rresp({M_AXI_GP0_RRESP_S4, M_AXI_GP0_RRESP_S3, M_AXI_GP0_RRESP_S2, M_AXI_GP0_RRESP_S1, M_AXI_GP0_RRESP_S0}),
    .m_axi_rvalid({M_AXI_GP0_RVALID_S4, M_AXI_GP0_RVALID_S3, M_AXI_GP0_RVALID_S2, M_AXI_GP0_RVALID_S1, M_AXI_GP0_RVALID_S0}),
    .m_axi_rready({M_AXI_GP0_RREADY_S4, M_AXI_GP0_RREADY_S3, M_AXI_GP0_RREADY_S2, M_AXI_GP0_RREADY_S1, M_AXI_GP0_RREADY_S0})
  );


  // Processing System
  n310_ps inst_n310_ps
  (
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

   // Radio Clock Generation

   wire             radio_clk;
   wire             radio_clk_locked;

   wire [31:0]      rx0, rx1;
   wire [31:0]      tx0, tx1;

  n310_core n310_core
  (
    //Clocks and resets
    .radio_clk(radio_clk),
    .radio_rst(/*radio_rst*/GSR),
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

    // Radio 0 signals
    .rx0(rx0),
    .tx0(tx0),
    .rx1(rx1),
    .tx1(tx1),

    //DMA
    .dmao_tdata(dmao_tdata),
    .dmao_tlast(dmao_tlast),
    .dmao_tvalid(dmao_tvalid),
    .dmao_tready(dmao_tready),

    .dmai_tdata(dmai_tdata),
    .dmai_tlast(dmai_tlast),
    .dmai_tvalid(dmai_tvalid),
    .dmai_tready(dmai_tready),

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
    .e2v1_tready(e2v1_tready)
  );

   reg [31:0] counter1;
   always @(posedge bus_clk) begin
     if (FCLK_RESET0)
       counter1 <= 32'd0;
     else
       counter1 <= counter1 + 32'd1;
   end
   reg [31:0] counter2;
   always @(posedge sfp0_gt_refclk) begin
     if (FCLK_RESET0)
       counter2 <= 32'd0;
     else
       counter2 <= counter2 + 32'd1;
   end
   reg [31:0] counter3;
   always @(posedge FCLK_CLK0) begin
     if (FCLK_RESET0)
       counter3 <= 32'd0;
     else
       counter3 <= counter3 + 32'd1;
   end
   //reg [31:0] counter4;
   //always @(posedge gmii_clk1) begin
   //  if (FCLK_RESET0)
   //    counter4 <= 32'd0;
   //  else
   //    counter4 <= counter4 + 32'd1;
   //end

   assign {SFP_0_LED_B, SFP_1_LED_B} = {sfp0_phy_status[0],sfp1_phy_status[0]};
   assign {SFP_0_LED_A, SFP_1_LED_A} = 2'b00;

   assign PANEL_LED_LINK = counter1[26];
   assign PANEL_LED_PPS = counter2[26];
   assign PANEL_LED_REF = counter3[26];
   assign PANEL_LED_GPS = 1'b1;
endmodule
