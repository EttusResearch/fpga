/////////////////////////////////////////////////////////////////////
//
// Copyright 2016-2017 Ettus Research
//
// N3xx TOP
//
// Rev D Brimstone MB
//
// Rev C Magnesium DB
//
//////////////////////////////////////////////////////////////////////

module n310
(

   inout [11:0] FPGA_GPIO,

   input FPGA_REFCLK_P,
   input FPGA_REFCLK_N,
   input REF_1PPS_IN,
   input WB_20MHz_P,
   input WB_20MHz_N,
   input NETCLK_REF_P,
   input NETCLK_REF_N,
   //input REF_1PPS_IN_MGMT,
   output REF_1PPS_OUT,

   //TDC
   inout UNUSED_PIN_TDCA_0,
   inout UNUSED_PIN_TDCA_1,
   inout UNUSED_PIN_TDCB_0,
   inout UNUSED_PIN_TDCB_1,

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
   output reg [1:0] FPGA_TEST,
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

`ifdef BUILD_1G
   input NETCLK_P,
   input NETCLK_N,
`endif

`ifdef BUILD_10G
   `define BUILD_10G_OR_AURORA
`endif
`ifdef BUILD_AURORA
   `define BUILD_10G_OR_AURORA
`endif
`ifdef BUILD_10G_OR_AURORA
   input MGT156MHZ_CLK1_P,
   input MGT156MHZ_CLK1_N,
`endif

   input SFP_0_RX_P, input SFP_0_RX_N,
   output SFP_0_TX_P, output SFP_0_TX_N,
   input SFP_1_RX_P, input SFP_1_RX_N,
   output SFP_1_TX_P, output SFP_1_TX_N,


   ///////////////////////////////////
   //
   // DRAM Interface
   //
   ///////////////////////////////////
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

   //USRP IO A
   output        DBA_CPLD_PS_SPI_SCLK,
   output        DBA_CPLD_PS_SPI_LE,
   output        DBA_CPLD_PS_SPI_SDI,
   input         DBA_CPLD_PS_SPI_SDO,
   output [1:0]  DBA_CPLD_PS_SPI_ADDR,

   output        DBA_ATR_RX_1,
   output        DBA_ATR_RX_2,
   output        DBA_ATR_TX_1,
   output        DBA_ATR_TX_2,

   inout [5:0]  DBA_CH1_TX_DSA_DATA,
   inout [5:0]  DBA_CH1_RX_DSA_DATA,
   inout [5:0]  DBA_CH2_TX_DSA_DATA,
   inout [5:0]  DBA_CH2_RX_DSA_DATA,

   output        DBA_CPLD_PL_SPI_SCLK,
   output        DBA_CPLD_PL_SPI_LE,
   output        DBA_CPLD_PL_SPI_SDI,
   input         DBA_CPLD_PL_SPI_SDO,
   output [2:0]  DBA_CPLD_PL_SPI_ADDR,

   output        DBA_MYK_SPI_SCLK,
   output        DBA_MYK_SPI_CS_n,
   input         DBA_MYK_SPI_SDO,
   output        DBA_MYK_SPI_SDIO,
   input         DBA_MYK_INTRQ,

   output        DBA_MYK_SYNC_IN_n,
   input         DBA_MYK_SYNC_OUT_n,

   output        DBA_CPLD_JTAG_TCK,
   output        DBA_CPLD_JTAG_TMS,
   output        DBA_CPLD_JTAG_TDI,
   input         DBA_CPLD_JTAG_TDO,

   output        DBA_MYK_GPIO_0,
   output        DBA_MYK_GPIO_1,
   output        DBA_MYK_GPIO_3,
   output        DBA_MYK_GPIO_4,
   output        DBA_MYK_GPIO_12,
   output        DBA_MYK_GPIO_13,
   output        DBA_MYK_GPIO_14,
   output        DBA_MYK_GPIO_15,

   input         DBA_FPGA_CLK_p,
   input         DBA_FPGA_CLK_n,
   input         DBA_FPGA_SYSREF_p,
   input         DBA_FPGA_SYSREF_n,

   input         USRPIO_A_MGTCLK_P,
   input         USRPIO_A_MGTCLK_N,

   input  [3:0]  USRPIO_A_RX_P,
   input  [3:0]  USRPIO_A_RX_N,
   output [3:0]  USRPIO_A_TX_P,
   output [3:0]  USRPIO_A_TX_N,


   //USRP IO B
   output        DBB_CPLD_PS_SPI_SCLK,
   output        DBB_CPLD_PS_SPI_LE,
   output        DBB_CPLD_PS_SPI_SDI,
   input         DBB_CPLD_PS_SPI_SDO,
   output [1:0]  DBB_CPLD_PS_SPI_ADDR,

   output        DBB_ATR_RX_1,
   output        DBB_ATR_RX_2,
   output        DBB_ATR_TX_1,
   output        DBB_ATR_TX_2,

   inout [5:0]  DBB_CH1_TX_DSA_DATA,
   inout [5:0]  DBB_CH1_RX_DSA_DATA,
   inout [5:0]  DBB_CH2_TX_DSA_DATA,
   inout [5:0]  DBB_CH2_RX_DSA_DATA,

   output        DBB_CPLD_PL_SPI_SCLK,
   output        DBB_CPLD_PL_SPI_LE,
   output        DBB_CPLD_PL_SPI_SDI,
   input         DBB_CPLD_PL_SPI_SDO,
   output [2:0]  DBB_CPLD_PL_SPI_ADDR,

   output        DBB_MYK_SPI_SCLK,
   output        DBB_MYK_SPI_CS_n,
   input         DBB_MYK_SPI_SDO,
   output        DBB_MYK_SPI_SDIO,
   input         DBB_MYK_INTRQ,

   output        DBB_MYK_SYNC_IN_n,
   input         DBB_MYK_SYNC_OUT_n,

   output        DBB_CPLD_JTAG_TCK,
   output        DBB_CPLD_JTAG_TMS,
   output        DBB_CPLD_JTAG_TDI,
   input         DBB_CPLD_JTAG_TDO,

   output        DBB_MYK_GPIO_0,
   output        DBB_MYK_GPIO_1,
   output        DBB_MYK_GPIO_3,
   output        DBB_MYK_GPIO_4,
   output        DBB_MYK_GPIO_12,
   output        DBB_MYK_GPIO_13,
   output        DBB_MYK_GPIO_14,
   output        DBB_MYK_GPIO_15,

   input         DBB_FPGA_CLK_p,
   input         DBB_FPGA_CLK_n,
   input         DBB_FPGA_SYSREF_p,
   input         DBB_FPGA_SYSREF_n,

   input         USRPIO_B_MGTCLK_P,
   input         USRPIO_B_MGTCLK_N,

   input  [3:0]  USRPIO_B_RX_P,
   input  [3:0]  USRPIO_B_RX_N,
   output [3:0]  USRPIO_B_TX_P,
   output [3:0]  USRPIO_B_TX_N




);

  localparam N_AXILITE_SLAVES = 4;
  localparam REG_AWIDTH = 14; // log2(0x4000)
  localparam REG_DWIDTH = 32;


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

  wire [15:0] IRQ_F2P;
  wire        FCLK_CLK0;
  wire        FCLK_CLK1;
  wire        FCLK_CLK2;
  wire        FCLK_CLK3;
  wire        clk100 = FCLK_CLK0;
  wire        clk40 = FCLK_CLK1;
  wire        meas_clk_ref = FCLK_CLK2;
  wire        bus_clk = FCLK_CLK3;
  wire        gige_refclk;
  wire        gige_refclk_bufg;
  wire        xgige_refclk;
  wire        xgige_clk156;
  wire        xgige_dclk;
  wire        aurora_gt_refclk;
  wire        aurora_refclk;
  wire        aurora_clk156;
  wire        aurora_init_clk;

  // TODO: Add sw_rst
  wire        bus_rst;
  wire        bus_rstn = ~bus_rst;
  wire        global_rst;
  wire        radio_rst;
  wire        FCLK_RESET0_N;
  wire        FCLK_RESET1_N;
  wire        FCLK_RESET2_N;
  wire        FCLK_RESET3_N;
  wire        FCLK_RESET0 = ~FCLK_RESET0_N;
  wire        FCLK_RESET1 = ~FCLK_RESET1_N;
  wire        FCLK_RESET2 = ~FCLK_RESET2_N;
  wire        FCLK_RESET3 = ~FCLK_RESET3_N;
  wire        clk40_rstn = FCLK_RESET1_N;
  wire        clk40_rst = ~clk40_rstn;

  wire [1:0] USB0_PORT_INDCTL;
  wire       USB0_VBUS_PWRSELECT;
  wire       USB0_VBUS_PWRFAULT;

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
  //
  //   PL Clocks : ---------------------------------------------------------------------------
  //   xgige_refclk (156): MGT156MHZ_CLK1_P > GTX IBUF > IBUFDS_GTE2  > xgige_refclk
  //   clk156            : MGT156MHZ_CLK1_P > GTX IBUF > IBUFDS_GTE2  > BUFG  > clk156
  //   gige_refclk (125) : NETCLK_P         > GTX IBUF > IBUFDS_GTE2  > gige_refclk
  //   gige_refclk_bufg  : NETCLK_P         > GTX IBUF > IBUFDS_GTE2  > BUFG  > gige_refclk_bufg
  //   RefClk (10)       : FPGA_REFCLK_P    >   IBUFDS > ref_clk
  //
  //   PS Clocks to PL:
  //   FCLK_CLK0 :      100 MHz
  //   FCLK_CLK1 :       40 MHz
  //   FCLK_CLK2 : 166.6667 MHz
  //   FCLK_CLK3 :      200 MHz
  //
  /////////////////////////////////////////////////////////////////////

  /////////////////////////////////////////////////////////////////////
  //
  // 10MHz Reference clock
  //
  //////////////////////////////////////////////////////////////////////

  wire ref_clk_buf_inv;
  //FIXME this for signal integrity checkonly please name it correctly when use
  wire outWBclk;
  wire outNetclk;
  ////////////
  wire ref_clk_inv;
  wire ref_clk;
  wire ref_clk_reset;
  wire ref_clk_locked;

  wire radio_clk;
  wire radio_clkB;
  wire radio_clk_2x;
  wire radio_clk_2xB;

  wire meas_clk;
  wire meas_clk_reset;
  wire meas_clk_locked;

  // FPGA Reference Clock Buffering
  //
  // Only require an IBUF and BUFG here, since an MMCM is (thankfully) not needed
  // to meet timing with the PPS signal.
   IBUFGDS ref_clk_ibuf (
    .O(outWBclk),
    .I(WB_20MHz_P),
    .IB(WB_20MHz_N)
  );
  IBUFGDS ref_clk_ibuf1 (
    .O(outNetclk),
    .I(NETCLK_REF_P),
    .IB(NETCLK_REF_N)
  );
  IBUFGDS ref_clk_ibuf2 (
    .O(ref_clk_buf_inv),
    .I(FPGA_REFCLK_N),
    .IB(FPGA_REFCLK_P)
  );

  BUFG ref_clk_bufg (
       .O(ref_clk_inv),
       .I(ref_clk_buf_inv)
   );

  // For Rev D Motherboard, the REFCLK signal sent to the FPGA is inverted on the PCB.
  // To fix this, add in an inverter after the BUFG, such that the re-inversion (to
  // the correct polarity of the clock) is pulled into each flop that uses this clock.
  // Tested with Vivado 2015.4 for correct behavior.
  assign ref_clk = ~ref_clk_inv;


  // Measurement Clock MMCM Instantiation
  //
  // This must be an MMCM to hit the weird rates we need for meas_clk.
  MeasClkMmcm MeasClkMmcmx (
    .clk_in1 (meas_clk_ref),
    .clk_out1(meas_clk),
    .reset   (meas_clk_reset),
    .locked  (meas_clk_locked)
  );


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
   one_gige_phy_clk_gen gige_clk_gen_i (
      .areset(global_rst),
      .refclk_p(NETCLK_P),
      .refclk_n(NETCLK_N),
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
   `ifdef BUILD_AURORA
      assign  aurora_refclk = xgige_refclk;
      assign  aurora_clk156 = xgige_clk156;
      assign  aurora_init_clk = xgige_dclk;
   `endif
`else
   `ifdef BUILD_AURORA
      aurora_phy_clk_gen aurora_clk_gen_i (
         .areset(global_rst),
         .refclk_p(MGT156MHZ_CLK1_P),
         .refclk_n(MGT156MHZ_CLK1_N),
         .refclk(aurora_refclk),
         .clk156(aurora_clk156),
         .init_clk(aurora_init_clk)
      );

   assign SFP_0_RS0  = 1'b1;
   assign SFP_0_RS1  = 1'b1;
   assign SFP_1_RS0  = 1'b1;
   assign SFP_1_RS1  = 1'b1;
   `endif
`endif

  //If bus_clk freq ever changes, update this paramter accordingly.
  localparam BUS_CLK_RATE = 32'd200000000; //200 MHz bus_clk rate.

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

  wire          gt0_qplloutclk,gt0_qplloutrefclk;
  wire          pma_reset;
  wire          qpllreset;
  wire          qplllock;
  wire          qplloutclk;
  wire          qplloutrefclk;
  wire  [15:0]  sfp0_phy_status;
  wire  [15:0]  sfp1_phy_status;
  wire  [31:0]  sfp0_mac_status;
  wire  [31:0]  sfp1_mac_status;
  wire  [63:0]  e01_tdata, e10_tdata;
  wire  [3:0]   e01_tuser, e10_tuser;
  wire          e01_tlast, e01_tvalid, e01_tready;
  wire          e10_tlast, e10_tvalid, e10_tready;

`ifdef SFP1_10GBE
  wire qpllrefclklost = 1'b0;

  // Instantiate the 10GBASER/KR GT Common block
  ten_gig_eth_pcs_pma_gt_common # (
      .WRAPPER_SIM_GTRESET_SPEEDUP("TRUE") ) //Does not affect hardware
  ten_gig_eth_pcs_pma_gt_common_block
  (
   .refclk(xgige_refclk),
   .qpllreset(qpllreset), //from 2nd sfp
   .qplllock(qplllock),
   .qplloutclk(qplloutclk),
   .qplloutrefclk(qplloutrefclk),
   .qpllrefclksel(3'b101 /*GTSOUTHREFCLK0*/)
  );
`elsif SFP1_AURORA
  wire qpllrefclklost;

  wire    [7:0]      qpll_drpaddr_in_i = 8'h0;
  wire    [15:0]     qpll_drpdi_in_i = 16'h0;
  wire               qpll_drpen_in_i =  1'b0;
  wire               qpll_drpwe_in_i =  1'b0;
  wire    [15:0]     qpll_drpdo_out_i;
  wire               qpll_drprdy_out_i;

  aurora_64b66b_pcs_pma_gt_common_wrapper gt_common_support (
    .gt_qpllclk_quad1_out      (qplloutclk), //to sfp
    .gt_qpllrefclk_quad1_out   (qplloutrefclk), // to sfp
    .GT0_GTREFCLK0_COMMON_IN   (aurora_refclk),
    //----------------------- Common Block - QPLL Ports ------------------------
    .GT0_QPLLLOCK_OUT          (qplllock), //to sfp1
    .GT0_QPLLRESET_IN          (qpllreset), //from sfp1
    .GT0_QPLLLOCKDETCLK_IN     (aurora_init_clk),
    .GT0_QPLLREFCLKLOST_OUT    (qpllrefclklost), //to sfp1
    //---------------------- Common DRP Ports ---------------------- //not really used???
    .qpll_drpaddr_in           (qpll_drpaddr_in_i),
    .qpll_drpdi_in             (qpll_drpdi_in_i),
    .qpll_drpclk_in            (aurora_init_clk),
    .qpll_drpdo_out            (qpll_drpdo_out_i),
    .qpll_drprdy_out           (qpll_drprdy_out_i),
    .qpll_drpen_in             (qpll_drpen_in_i),
    .qpll_drpwe_in             (qpll_drpwe_in_i)
  );
`endif

`ifdef BUILD_AURORA
  wire aurora_tx_clk0, aurora_tx_clk1;
  wire aurora_mmcm_reset0, aurora_mmcm_reset1;
  wire au_user_clk;
  wire au_sync_clk;
  wire au_mmcm_locked;
  wire sfp0_tx_out_clk, sfp1_tx_out_clk;
  wire sfp0_gt_pll_lock, sfp1_gt_pll_lock;
  wire sfp0_phy_areset, sfp1_phy_areset;
  //just always use sfp1 for this because in all build combinations with
  //Aurora, sfp1 is Aurora.
  //Since sfp1 aurora core is the source of the mmcm clk, connect its reset to
  //all other gtx channels on this quad.
  aurora_phy_mmcm aurora_phy_mmcm_0 (
    .aurora_tx_clk(sfp1_tx_out_clk),
    .mmcm_reset(!sfp1_gt_pll_lock),
    .user_clk(au_user_clk),
    .sync_clk(au_sync_clk),
    .mmcm_locked(au_mmcm_locked)
  );
`endif
  ////////////////////////////////////////////////////////////////////
  // PPS
  // Support for internal or external inputs.
  ///////////////////////////////////////////////////////////////////

  // Generate an internal PPS signal with a 25% duty cycle
  wire r_int_pps;
  pps_generator #(
     .CLK_FREQ(32'd10_000_000), .DUTY_CYCLE(25)
  ) pps_gen (
     .clk(ref_clk), .reset(1'b0), .pps(r_int_pps)
  );

  // PPS MUX - selects internal or external PPS.
  wire [1:0] pps_select;
  wire pps_out_enb;
  reg r_pps_select_ms = 1'b0;
  reg r_pps_select    = 1'b0;
  reg r_pps_ext_ms    = 1'b0;
  reg r_pps_ext       = 1'b0;
  reg pps_refclk      = 1'b0;
  always @(posedge ref_clk) begin

    // Capture the external PPS with a FF before sending to the select. To be safe,
    // we double-synchronize the external signal. If we meet timing (which we should)
    // then this is a two-cycle delay. If we don't meet timing, then it's 1-2 cycles
    // and our system timing is thrown off--but at least our downstream logic doesn't
    // go haywire!
    r_pps_ext_ms <= REF_1PPS_IN;
    r_pps_ext    <= r_pps_ext_ms;

    r_pps_select_ms <= pps_select[0]; // pps_select[1:0] comes from a register in some unknown domain
    r_pps_select    <= r_pps_select_ms;

    if(r_pps_select)
      pps_refclk <= r_int_pps; // pps_select = 1 = internal
    else
      pps_refclk <= r_pps_ext;

    FPGA_TEST[1] <= pps_refclk;
  end

  // PPS out and LED
  assign PANEL_LED_PPS = pps_refclk;


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

  // ARM DMA
  wire [63:0] o_cvita_dma_tdata;
  wire        o_cvita_dma_tlast;
  wire        o_cvita_dma_tready;
  wire        o_cvita_dma_tvalid;

  wire [63:0] i_cvita_dma_tdata;
  wire        i_cvita_dma_tlast;
  wire        i_cvita_dma_tready;
  wire        i_cvita_dma_tvalid;


  /////////////////////////////////////////////////////////////////////
  //
  // SFP Wrapper 0: Network Interface (1/10G or Aurora)
  //
  //////////////////////////////////////////////////////////////////////

  n310_sfp_wrapper #(
`ifdef SFP0_10GBE
      .PROTOCOL("10GbE"),
`elsif SFP0_AURORA
      .PROTOCOL("Aurora"),
`elsif SFP0_1GBE
      .PROTOCOL("1GbE"),
`endif
      .DWIDTH(REG_DWIDTH),     // Width of the AXI4-Lite data bus (must be 32 or 64)
      .AWIDTH(REG_AWIDTH),     // Width of the address bus
      .MDIO_EN(1'b1),
      .PORTNUM(8'd0)
  ) sfp_wrapper_0 (
`ifdef SFP0_AURORA
     //must reset all channels on quad when aurora mmcm is reset.
     //sfp1 is the master of the mmcm, so reset sfp0 as well.
     .areset(global_rst | sfp1_phy_areset),
`else
     .areset(global_rst),     // TODO: Add Reset through PS
`endif
     .gt_refclk(sfp0_gt_refclk),
     .gb_refclk(sfp0_gb_refclk),
     .misc_clk(sfp0_misc_clk),
     .user_clk(au_user_clk),
     .sync_clk(au_sync_clk),
     .au_tx_out_clk(sfp0_tx_out_clk),

     .bus_rst(bus_rst),
     .bus_clk(bus_clk),

     .qpllreset(),
     .qplllock(qplllock),
     .qplloutclk(qplloutclk),
     .qplloutrefclk(qplloutrefclk),
     .qpllrefclklost(qpllrefclklost),

     .au_mmcm_locked(au_mmcm_locked),
     .gt_pll_lock(sfp0_gt_pll_lock),
     .phy_areset_out(sfp0_phy_areset),

     .txp(SFP_0_TX_P),
     .txn(SFP_0_TX_N),
     .rxp(SFP_0_RX_P),
     .rxn(SFP_0_RX_N),

     .sfpp_rxlos(SFP_0_LOS),
     .sfpp_tx_fault(SFP_0_TXFAULT),
     .sfpp_tx_disable(SFP_0_TXDISABLE),

     .sfp_phy_status(sfp0_phy_status),
     .sfp_mac_status(sfp0_mac_status),

     // Clock and reset
     .s_axi_aclk(clk40),
     .s_axi_aresetn(clk40_rstn),
     // AXI4-Lite: Write address port (domain: s_axi_aclk)
     .s_axi_awaddr(M_AXI_NET0_AWADDR),
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
     .s_axi_araddr(M_AXI_NET0_ARADDR),
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

     // LED
     .activity_led(SFP_0_LED_A)
  );


  /////////////////////////////////////////////////////////////////////
  //
  // SFP Wrapper 1: Network Interface (1/10G or Aurora)
  //
  //////////////////////////////////////////////////////////////////////

  n310_sfp_wrapper #(
`ifdef SFP1_10GBE
      .PROTOCOL("10GbE"),
`elsif SFP1_AURORA
      .PROTOCOL("Aurora"),
`endif
      .DWIDTH(REG_DWIDTH),     // Width of the AXI4-Lite data bus (must be 32 or 64)
      .AWIDTH(REG_AWIDTH),     // Width of the address bus
      .MDIO_EN(1'b1),
      .PORTNUM(8'd1)
  ) sfp_wrapper_1 (
     .areset(global_rst),     // TODO: Add Reset through PS

     .gt_refclk(sfp1_gt_refclk),
     .gb_refclk(sfp1_gb_refclk),
     .misc_clk(sfp1_misc_clk),
     .user_clk(au_user_clk),
     .sync_clk(au_sync_clk),
     .au_tx_out_clk(sfp1_tx_out_clk),

     .bus_rst(bus_rst),
     .bus_clk(bus_clk),

     .qpllreset(qpllreset),
     .qplllock(qplllock),
     .qplloutclk(qplloutclk),
     .qplloutrefclk(qplloutrefclk),
     .qpllrefclklost(qpllrefclklost),

     .au_mmcm_locked(au_mmcm_locked),
     .gt_pll_lock(sfp1_gt_pll_lock),
     .phy_areset_out(sfp1_phy_areset),

     .txp(SFP_1_TX_P),
     .txn(SFP_1_TX_N),
     .rxp(SFP_1_RX_P),
     .rxn(SFP_1_RX_N),

     .sfpp_rxlos(SFP_1_LOS),
     .sfpp_tx_fault(SFP_1_TXFAULT),
     .sfpp_tx_disable(SFP_1_TXDISABLE),

     .sfp_phy_status(sfp1_phy_status),
     .sfp_mac_status(sfp1_mac_status),

      // Clock and reset
      .s_axi_aclk(clk40),
      .s_axi_aresetn(clk40_rstn),
      // AXI4-Lite: Write address port (domain: s_axi_aclk)
      .s_axi_awaddr(M_AXI_NET1_AWADDR),
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
      .s_axi_araddr(M_AXI_NET1_ARADDR),
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

      // LED
      .activity_led(SFP_1_LED_A)
  );

  /////////////////////////////////////////////////////////////////////
  //
  // Ethernet DMA 0
  //
  //////////////////////////////////////////////////////////////////////

  assign  IRQ_F2P[0] = arm_eth0_rx_irq;
  assign  IRQ_F2P[1] = arm_eth0_tx_irq;

  assign {S_AXI_HP0_AWID, S_AXI_HP0_ARID} = 12'd0;
  assign {S_AXI_GP0_AWID, S_AXI_GP0_ARID} = 12'd0;

`ifdef SFP0_AURORA
  //If inst Aurora, tie off each axi/axi-lite interface
  axi_dummy #(.DEC_ERR(1'b0)) inst_axi_dummy_sfp0_eth_dma
  (
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

  axi_eth_dma inst_axi_eth_dma0
  (
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

  axis_fifo_2clk #( .WIDTH(1+8+64)) eth_tx_0_fifo_2clk_i (
    .s_axis_areset(clk40_rst), .s_axis_aclk(clk40),
    .s_axis_tdata({arm_eth0_tx_tlast, arm_eth0_tx_tkeep, arm_eth0_tx_tdata}),
    .s_axis_tvalid(arm_eth0_tx_tvalid),
    .s_axis_tready(arm_eth0_tx_tready),
    .m_axis_aclk(bus_clk),
    .m_axis_tdata({arm_eth0_tx_tlast_b, arm_eth0_tx_tkeep_b, arm_eth0_tx_tdata_b}),
    .m_axis_tvalid(arm_eth0_tx_tvalid_b),
    .m_axis_tready(arm_eth0_tx_tready_b)
  );

  axis_fifo_2clk #( .WIDTH(1+8+64)) eth_rx_0_fifo_2clk_i (
    .s_axis_areset(bus_rst), .s_axis_aclk(bus_clk),
    .s_axis_tdata({arm_eth0_rx_tlast_b, arm_eth0_rx_tkeep_b, arm_eth0_rx_tdata_b}),
    .s_axis_tvalid(arm_eth0_rx_tvalid_b),
    .s_axis_tready(arm_eth0_rx_tready_b),
    .m_axis_aclk(clk40),
    .m_axis_tdata({arm_eth0_rx_tlast, arm_eth0_rx_tkeep, arm_eth0_rx_tdata}),
    .m_axis_tvalid(arm_eth0_rx_tvalid),
    .m_axis_tready(arm_eth0_rx_tready)
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
  assign {S_AXI_GP1_AWID, S_AXI_GP1_ARID} = 12'd0;
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

  axi_eth_dma inst_axi_eth_dma1
  (
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

  axis_fifo_2clk #( .WIDTH(1+8+64)) eth_tx_1_fifo_2clk_i (
    .s_axis_areset(clk40_rst), .s_axis_aclk(clk40),
    .s_axis_tdata({arm_eth1_tx_tlast, arm_eth1_tx_tkeep, arm_eth1_tx_tdata}),
    .s_axis_tvalid(arm_eth1_tx_tvalid),
    .s_axis_tready(arm_eth1_tx_tready),
    .m_axis_aclk(bus_clk),
    .m_axis_tdata({arm_eth1_tx_tlast_b, arm_eth1_tx_tkeep_b, arm_eth1_tx_tdata_b}),
    .m_axis_tvalid(arm_eth1_tx_tvalid_b),
    .m_axis_tready(arm_eth1_tx_tready_b)
  );

  axis_fifo_2clk #( .WIDTH(1+8+64)) eth_rx_1_fifo_2clk_i (
    .s_axis_areset(bus_rst), .s_axis_aclk(bus_clk),
    .s_axis_tdata({arm_eth1_rx_tlast_b, arm_eth1_rx_tkeep_b, arm_eth1_rx_tdata_b}),
    .s_axis_tvalid(arm_eth1_rx_tvalid_b),
    .s_axis_tready(arm_eth1_rx_tready_b),
    .m_axis_aclk(clk40),
    .m_axis_tdata({arm_eth1_rx_tlast, arm_eth1_rx_tkeep, arm_eth1_rx_tdata}),
    .m_axis_tvalid(arm_eth1_rx_tvalid),
    .m_axis_tready(arm_eth1_rx_tready)
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
  wire spi1_sclk;
  wire spi1_mosi;
  wire spi1_miso;
  wire spi1_ss0;
  wire spi1_ss1;
  wire spi1_ss2;

  wire [63:0] ps_gpio_out;
  wire [63:0] ps_gpio_in;
  wire [63:0] ps_gpio_tri;

  assign DBA_CPLD_JTAG_TCK = ps_gpio_out[0];
  assign DBA_CPLD_JTAG_TDI = ps_gpio_out[1];
  assign DBA_CPLD_JTAG_TMS = ps_gpio_out[2];
  assign ps_gpio_in[3]     = DBA_CPLD_JTAG_TDO;

  assign DBB_CPLD_JTAG_TCK = ps_gpio_out[4];
  assign DBB_CPLD_JTAG_TDI = ps_gpio_out[5];
  assign DBB_CPLD_JTAG_TMS = ps_gpio_out[6];
  assign ps_gpio_in[7]     = DBB_CPLD_JTAG_TDO;

  genvar i;
  generate for (i=0; i<12; i=i+1) begin: io_tristate_gen
    assign FPGA_GPIO[i] = ps_gpio_tri[32+i] ? 1'bz : ps_gpio_out[32+i];
    assign ps_gpio_in[32+i] = FPGA_GPIO[i];
  end endgenerate

  // Processing System
  n310_ps_bd inst_n310_ps
  (
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

    .bus_clk(bus_clk),
    .bus_rstn(bus_rstn),
    .interconnect_clk(FCLK_CLK0),
    .interconnect_rstn(FCLK_RESET0_N),
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
    .S_AXI_GP1_awid(),
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

    .FCLK_CLK0(FCLK_CLK0),
    .FCLK_RESET0_N(FCLK_RESET0_N),
    .FCLK_CLK1(FCLK_CLK1),
    .FCLK_RESET1_N(FCLK_RESET1_N),
    .FCLK_CLK2(FCLK_CLK2),
    .FCLK_RESET2_N(FCLK_RESET2_N),
    .FCLK_CLK3(FCLK_CLK3),
    .FCLK_RESET3_N(FCLK_RESET3_N),

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


   wire        ddr3_axi_clk;           // 1/4 DDR external clock rate (250MHz)
   wire        ddr3_axi_clk_x2;        // 1/4 DDR external clock rate (250MHz)
   wire        ddr3_axi_rst;           // Synchronized to ddr_sys_clk
   wire        ddr3_running;           // DRAM calibration complete.

   // Slave Interface Write Address Ports
   wire        s_axi_awid;
   wire [31:0] s_axi_awaddr;
   wire [7:0]  s_axi_awlen;
   wire [2:0]  s_axi_awsize;
   wire [1:0]  s_axi_awburst;
   wire [0:0]  s_axi_awlock;
   wire [3:0]  s_axi_awcache;
   wire [2:0]  s_axi_awprot;
   wire [3:0]  s_axi_awqos;
   wire        s_axi_awvalid;
   wire        s_axi_awready;
   // Slave Interface Write Data Ports
   wire [255:0] s_axi_wdata;
   wire [31:0]  s_axi_wstrb;
   wire     s_axi_wlast;
   wire     s_axi_wvalid;
   wire     s_axi_wready;
   // Slave Interface Write Response Ports
   wire     s_axi_bready;
   wire     s_axi_bid;
   wire [1:0]   s_axi_bresp;
   wire     s_axi_bvalid;
   // Slave Interface Read Address Ports
   wire     s_axi_arid;
   wire [31:0]  s_axi_araddr;
   wire [7:0]   s_axi_arlen;
   wire [2:0]   s_axi_arsize;
   wire [1:0]   s_axi_arburst;
   wire [0:0]   s_axi_arlock;
   wire [3:0]   s_axi_arcache;
   wire [2:0]   s_axi_arprot;
   wire [3:0]   s_axi_arqos;
   wire     s_axi_arvalid;
   wire     s_axi_arready;
   // Slave Interface Read Data Ports
   wire     s_axi_rready;
   wire     s_axi_rid;
   wire [255:0] s_axi_rdata;
   wire [1:0]   s_axi_rresp;
   wire     s_axi_rlast;
   wire     s_axi_rvalid;

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

      .ddr3_cs_n                      (ddr3_cs_n),
      .ddr3_dm                        (ddr3_dm),
      .ddr3_odt                       (ddr3_odt),
      // Application interface ports
      .ui_clk                         (ddr3_axi_clk),  // 200Hz clock out
      .ui_clk_x2                      (ddr3_axi_clk_x2), //300 MHz, not actually x2 for n310 design because of timing.
      .ui_clk_sync_rst                (ddr3_axi_rst),  // Active high Reset signal synchronised to 200 MHz.
      .aresetn                        (ddr3_axi_rst_reg_n),
      .app_sr_req                     (1'b0),
      .app_sr_active                  (app_sr_active),
      .app_ref_req                    (1'b0),
      .app_ref_ack                    (app_ref_ack),
      .app_zq_req                     (1'b0),
      .app_zq_ack                     (app_zq_ack),
      // Slave Interface Write Address Ports
      .s_axi_awid                     (s_axi_awid),
      .s_axi_awaddr                   (s_axi_awaddr),
      .s_axi_awlen                    (s_axi_awlen),
      .s_axi_awsize                   (s_axi_awsize),
      .s_axi_awburst                  (s_axi_awburst),
      .s_axi_awlock                   (s_axi_awlock),
      .s_axi_awcache                  (s_axi_awcache),
      .s_axi_awprot                   (s_axi_awprot),
      .s_axi_awqos                    (s_axi_awqos),
      .s_axi_awvalid                  (s_axi_awvalid),
      .s_axi_awready                  (s_axi_awready),
      // Slave Interface Write Data Ports
      .s_axi_wdata                    (s_axi_wdata),
      .s_axi_wstrb                    (s_axi_wstrb),
      .s_axi_wlast                    (s_axi_wlast),
      .s_axi_wvalid                   (s_axi_wvalid),
      .s_axi_wready                   (s_axi_wready),
      // Slave Interface Write Response Ports
      .s_axi_bid                      (s_axi_bid),
      .s_axi_bresp                    (s_axi_bresp),
      .s_axi_bvalid                   (s_axi_bvalid),
      .s_axi_bready                   (s_axi_bready),
      // Slave Interface Read Address Ports
      .s_axi_arid                     (s_axi_arid),
      .s_axi_araddr                   (s_axi_araddr),
      .s_axi_arlen                    (s_axi_arlen),
      .s_axi_arsize                   (s_axi_arsize),
      .s_axi_arburst                  (s_axi_arburst),
      .s_axi_arlock                   (s_axi_arlock),
      .s_axi_arcache                  (s_axi_arcache),
      .s_axi_arprot                   (s_axi_arprot),
      .s_axi_arqos                    (s_axi_arqos),
      .s_axi_arvalid                  (s_axi_arvalid),
      .s_axi_arready                  (s_axi_arready),
      // Slave Interface Read Data Ports
      .s_axi_rid                      (s_axi_rid),
      .s_axi_rdata                    (s_axi_rdata),
      .s_axi_rresp                    (s_axi_rresp),
      .s_axi_rlast                    (s_axi_rlast),
      .s_axi_rvalid                   (s_axi_rvalid),
      .s_axi_rready                   (s_axi_rready),
      // System Clock Ports
      .sys_clk_p                       (sys_clk_p),
      .sys_clk_n                       (sys_clk_n),
      .clk_ref_i                       (bus_clk),

      .sys_rst                        (~global_rst) // IJB. Poorly named active low. Should change RST_ACT_LOW.
   );


  ///////////////////////////////////////////////////////
  //
  // DB PS SPI Connections
  //
  ///////////////////////////////////////////////////////
  wire [3:0] rx_atr;
  wire [3:0] tx_atr;

  wire [15:0] db_gpio_out[0:3];
  wire [15:0] db_gpio_in[0:3];
  wire [15:0] db_gpio_ddr[0:3];
  wire [15:0] db_gpio_fab[0:3];

  // DB A SPI Connections
  wire cpld_a_cs_n;
  wire cpld_pl_a_cs_n;
  wire lmk_a_cs_n;
  wire dac_a_cs_n;
  wire myk_a_cs_n;

  // Split out the SCLK and MOSI data to Mykonos and the CPLD.
  assign DBA_CPLD_PS_SPI_SCLK = spi0_sclk;
  assign DBA_CPLD_PS_SPI_SDI  = spi0_mosi;

  assign DBA_MYK_SPI_SCLK     = spi0_sclk;
  assign DBA_MYK_SPI_SDIO     = spi0_mosi;
  // Assign individual chip selects from PS SPI MASTER 0.
  assign cpld_a_cs_n = spi0_ss0;
  assign lmk_a_cs_n  = spi0_ss1;
  assign dac_a_cs_n  = ps_gpio_out[8]; // DAC select driven through GPIO.
  assign myk_a_cs_n  = spi0_ss2;

  // Returned data mux from the SPI interfaces.
  assign spi0_miso = ~myk_a_cs_n      ? DBA_MYK_SPI_SDO  : // From Mykonos
                     DBA_CPLD_PS_SPI_SDO;

  // For the PS SPI connection to the CPLD, we use the LE and ADDR lines as individual
  // chip selects for the CPLD endpoint as well as the LMK and DAC endpoints.
  // LE      = CPLD
  // ADDR[0] = LMK
  // ADDR[1] = DAC
  assign DBA_CPLD_PS_SPI_LE       = cpld_a_cs_n;
  assign DBA_CPLD_PS_SPI_ADDR[0]  = lmk_a_cs_n;
  assign DBA_CPLD_PS_SPI_ADDR[1]  = dac_a_cs_n;
  assign DBA_MYK_SPI_CS_n         = myk_a_cs_n;


   gpio_atr_io #(.WIDTH(16)) gpio_DSA_dbA0_inst (
      .clk(radio_clk), .gpio_pins({DBA_CH1_TX_DSA_DATA,DBA_CH1_RX_DSA_DATA}),
      .gpio_ddr(db_gpio_ddr[0]), .gpio_out(db_gpio_out[0]), .gpio_in(db_gpio_in[0])
   );
  gpio_atr_io #(.WIDTH(16)) gpio_DSA_dbA1_inst (
      .clk(radio_clk), .gpio_pins({DBA_CH2_TX_DSA_DATA,DBA_CH2_RX_DSA_DATA}),
      .gpio_ddr(db_gpio_ddr[1]), .gpio_out(db_gpio_out[1]), .gpio_in(db_gpio_in[1])
   );

  assign DBA_ATR_RX_1 = rx_atr[0];
  assign DBA_ATR_RX_2 = rx_atr[1];
  assign DBA_ATR_TX_1 = tx_atr[0];
  assign DBA_ATR_TX_2 = tx_atr[1];

  assign DBA_MYK_GPIO_0  = 1'b0;
  assign DBA_MYK_GPIO_1  = 1'b0;
  assign DBA_MYK_GPIO_3  = 1'b0;
  assign DBA_MYK_GPIO_4  = 1'b0;
  assign DBA_MYK_GPIO_12 = 1'b0;
  assign DBA_MYK_GPIO_13 = 1'b0;
  assign DBA_MYK_GPIO_14 = 1'b0;
  assign DBA_MYK_GPIO_15 = 1'b0;



  // DB B SPI Connections
  wire cpld_b_cs_n;
  wire cpld_pl_b_cs_n;
  wire lmk_b_cs_n;
  wire dac_b_cs_n;
  wire myk_b_cs_n;

  // Split out the SCLK and MOSI data to Mykonos and the CPLD.
  assign DBB_CPLD_PS_SPI_SCLK = spi1_sclk;
  assign DBB_CPLD_PS_SPI_SDI  = spi1_mosi;

  assign DBB_MYK_SPI_SCLK     = spi1_sclk;
  assign DBB_MYK_SPI_SDIO     = spi1_mosi;

  // Assign individual chip selects from PS SPI MASTER 1.
  assign cpld_b_cs_n = spi1_ss0;
  assign lmk_b_cs_n  = spi1_ss1;
  assign dac_b_cs_n  = ps_gpio_out[9]; // DAC select driven through GPIO.
  assign myk_b_cs_n  = spi1_ss2;

  // Returned data mux from the SPI interfaces.
  assign spi1_miso = ~myk_b_cs_n      ? DBB_MYK_SPI_SDO  : // From Mykonos
                     DBB_CPLD_PS_SPI_SDO;

  // For the PS SPI connection to the CPLD, we use the LE and ADDR lines as individual
  // chip selects for the CPLD endpoint as well as the LMK and DAC endpoints.
  // LE      = CPLD
  // ADDR[0] = LMK
  // ADDR[1] = DAC
  assign DBB_CPLD_PS_SPI_LE       = cpld_b_cs_n;
  assign DBB_CPLD_PS_SPI_ADDR[0]  = lmk_b_cs_n;
  assign DBB_CPLD_PS_SPI_ADDR[1]  = dac_b_cs_n;
  assign DBB_MYK_SPI_CS_n         = myk_b_cs_n;



  gpio_atr_io #(.WIDTH(16)) gpio_DSA_dbB0_inst (
      .clk(radio_clk), .gpio_pins({DBB_CH1_TX_DSA_DATA,DBB_CH1_RX_DSA_DATA}),
      .gpio_ddr(db_gpio_ddr[2]), .gpio_out(db_gpio_out[2]), .gpio_in(db_gpio_in[2])
   );
  gpio_atr_io #(.WIDTH(16)) gpio_DSA_dbB1_inst (
      .clk(radio_clk), .gpio_pins({DBB_CH2_TX_DSA_DATA,DBB_CH2_RX_DSA_DATA}),
      .gpio_ddr(db_gpio_ddr[3]), .gpio_out(db_gpio_out[3]), .gpio_in(db_gpio_in[3])
   );

  assign DBB_ATR_RX_1 = rx_atr[2];
  assign DBB_ATR_RX_2 = rx_atr[3];
  assign DBB_ATR_TX_1 = tx_atr[2];
  assign DBB_ATR_TX_2 = tx_atr[3];

  assign DBB_MYK_GPIO_0  = 1'b0;
  assign DBB_MYK_GPIO_1  = 1'b0;
  assign DBB_MYK_GPIO_3  = 1'b0;
  assign DBB_MYK_GPIO_4  = 1'b0;
  assign DBB_MYK_GPIO_12 = 1'b0;
  assign DBB_MYK_GPIO_13 = 1'b0;
  assign DBB_MYK_GPIO_14 = 1'b0;
  assign DBB_MYK_GPIO_15 = 1'b0;




  ///////////////////////////////////////////////////////
  //
  // N310 CORE
  //
  ///////////////////////////////////////////////////////

  wire  [31:0]     rx0;
  wire  [31:0]     rx1;
  wire  [31:0]     rx2;
  wire  [31:0]     rx3;
  wire  [31:0]     tx0;
  wire  [31:0]     tx1;
  wire  [31:0]     tx2;
  wire  [31:0]     tx3;
  wire  [3:0]      rx_stb;
  wire  [3:0]      tx_stb;
  wire pps_radioclk1x;

  n310_core #(.REG_AWIDTH(14), .BUS_CLK_RATE(BUS_CLK_RATE)) n310_core
  (
    //Clocks and resets
`ifdef NO_DB
    .radio_clk(bus_clk),
    .radio_rst(bus_rst),
`else
    .radio_clk(radio_clk),
    .radio_rst(radio_rst),
`endif
    .bus_clk(bus_clk),
    .bus_rst(bus_rst),

    // Clocking and PPS Controls/Indicators
    .pps(pps_radioclk1x),
    .pps_select(pps_select),
    .pps_out_enb(pps_out_enb),
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
    //radios atr
    .rx_atr(rx_atr),
    .tx_atr(tx_atr),
    //radios gpio dsa
    .db_gpio_out0(db_gpio_out[0]),
    .db_gpio_out1(db_gpio_out[1]),
    .db_gpio_out2(db_gpio_out[2]),
    .db_gpio_out3(db_gpio_out[3]),
    .db_gpio_in0(db_gpio_in[0]),
    .db_gpio_in1(db_gpio_in[1]),
    .db_gpio_in2(db_gpio_in[2]),
    .db_gpio_in3(db_gpio_in[3]),
    .db_gpio_ddr0(db_gpio_ddr[0]),
    .db_gpio_ddr1(db_gpio_ddr[1]),
    .db_gpio_ddr2(db_gpio_ddr[2]),
    .db_gpio_ddr3(db_gpio_ddr[3]),
    .db_gpio_fab0(db_gpio_fab[0]),
    .db_gpio_fab1(db_gpio_fab[1]),
    .db_gpio_fab2(db_gpio_fab[2]),
    .db_gpio_fab3(db_gpio_fab[3]),
    //radios data
    .rx0(rx0),
    .tx0(tx0),
    .rx1(rx1),
    .tx1(tx1),
    .rx2(rx2),
    .tx2(tx2),
    .rx3(rx3),
    .tx3(tx3),
    .rx_stb(rx_stb),
    .tx_stb(tx_stb),
    //cpld rx_lo tx_lo  spi
    .sclk0(DBA_CPLD_PL_SPI_SCLK),
    .sen0({DBA_CPLD_PL_SPI_ADDR[1],DBA_CPLD_PL_SPI_ADDR[0],DBA_CPLD_PL_SPI_LE}),
    .mosi0(DBA_CPLD_PL_SPI_SDI),
    .miso0(DBA_CPLD_PL_SPI_SDO),
    .sclk1(DBB_CPLD_PL_SPI_SCLK),
    .sen1({DBB_CPLD_PL_SPI_ADDR[1],DBB_CPLD_PL_SPI_ADDR[0],DBB_CPLD_PL_SPI_LE}),
    .mosi1(DBB_CPLD_PL_SPI_SDI),
    .miso1(DBB_CPLD_PL_SPI_SDO),
    // DRAM signals.
    .ddr3_axi_clk              (ddr3_axi_clk),
    .ddr3_axi_clk_x2           (ddr3_axi_clk_x2),
    .ddr3_axi_rst              (ddr3_axi_rst),
    .ddr3_running              (ddr3_running),
    // Slave Interface Write Address Ports
    .ddr3_axi_awid             (s_axi_awid),
    .ddr3_axi_awaddr           (s_axi_awaddr),
    .ddr3_axi_awlen            (s_axi_awlen),
    .ddr3_axi_awsize           (s_axi_awsize),
    .ddr3_axi_awburst          (s_axi_awburst),
    .ddr3_axi_awlock           (s_axi_awlock),
    .ddr3_axi_awcache          (s_axi_awcache),
    .ddr3_axi_awprot           (s_axi_awprot),
    .ddr3_axi_awqos            (s_axi_awqos),
    .ddr3_axi_awvalid          (s_axi_awvalid),
    .ddr3_axi_awready          (s_axi_awready),
    // Slave Interface Write Data Ports
    .ddr3_axi_wdata            (s_axi_wdata),
    .ddr3_axi_wstrb            (s_axi_wstrb),
    .ddr3_axi_wlast            (s_axi_wlast),
    .ddr3_axi_wvalid           (s_axi_wvalid),
    .ddr3_axi_wready           (s_axi_wready),
    // Slave Interface Write Response Ports
    .ddr3_axi_bid              (s_axi_bid),
    .ddr3_axi_bresp            (s_axi_bresp),
    .ddr3_axi_bvalid           (s_axi_bvalid),
    .ddr3_axi_bready           (s_axi_bready),
    // Slave Interface Read Address Ports
    .ddr3_axi_arid             (s_axi_arid),
    .ddr3_axi_araddr           (s_axi_araddr),
    .ddr3_axi_arlen            (s_axi_arlen),
    .ddr3_axi_arsize           (s_axi_arsize),
    .ddr3_axi_arburst          (s_axi_arburst),
    .ddr3_axi_arlock           (s_axi_arlock),
    .ddr3_axi_arcache          (s_axi_arcache),
    .ddr3_axi_arprot           (s_axi_arprot),
    .ddr3_axi_arqos            (s_axi_arqos),
    .ddr3_axi_arvalid          (s_axi_arvalid),
    .ddr3_axi_arready          (s_axi_arready),
    // Slave Interface Read Data Ports
    .ddr3_axi_rid              (s_axi_rid),
    .ddr3_axi_rdata            (s_axi_rdata),
    .ddr3_axi_rresp            (s_axi_rresp),
    .ddr3_axi_rlast            (s_axi_rlast),
    .ddr3_axi_rvalid           (s_axi_rvalid),
    .ddr3_axi_rready           (s_axi_rready),

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
    .e2v1_tready(e2v1_tready)
  );

  // //////////////////////////////////////////////////////////////////////
  //
  // Daughterboard Cores
  //
  // //////////////////////////////////////////////////////////////////////

  wire aAdcSyncUnusedA;
  wire aAdcSyncUnusedB;
  wire aDacSyncUnusedA;
  wire aDacSyncUnusedB;
  wire aLmkSyncUnusedB;
  wire [49:0] bRegPortInFlatA;
  wire [49:0] bRegPortInFlatB;
  wire [33:0] bRegPortOutFlatA;
  wire [33:0] bRegPortOutFlatB;
  wire rRSP_a_unused;
  wire rRSP_b_unused;
  wire rx_a_valid;
  wire rx_b_valid;
  wire sPpsUnusedB;
  wire sRTC_a_unused;
  wire sRTC_b_unused;
  wire tx_a_rfi;
  wire tx_b_rfi;

  wire          reg_portA_rd;
  wire          reg_portA_wr;
  wire [14-1:0] reg_portA_addr;
  wire [32-1:0] reg_portA_wr_data;
  wire [32-1:0] reg_portA_rd_data;
  wire          reg_portA_ready;
  wire          validA_unused;

  assign bRegPortInFlatA = {2'b0, reg_portA_addr, reg_portA_wr_data, reg_portA_rd, reg_portA_wr};
  assign {reg_portA_rd_data, validA_unused, reg_portA_ready} = bRegPortOutFlatA;

  DbCore
    dba_core (
      .aReset(clk40_rst),                  //in  std_logic
      .bReset(1'b0),                           //in  std_logic
      .BusClk(clk40),                          //in  std_logic
      .Clk40(clk40),                           //in  std_logic
      .MeasClk(meas_clk),                      //in  std_logic
      .FpgaClk_p(DBA_FPGA_CLK_p),              //in  std_logic
      .FpgaClk_n(DBA_FPGA_CLK_n),              //in  std_logic
      .SampleClk1xOut(radio_clk),              //out std_logic
      .SampleClk1x(radio_clk),                 //in  std_logic
      .SampleClk2xOut(radio_clk_2x),           //out std_logic
      .SampleClk2x(radio_clk_2x),              //in  std_logic
      .bRegPortInFlat(bRegPortInFlatA),        //in  std_logic_vector(49:0)
      .bRegPortOutFlat(bRegPortOutFlatA),      //out std_logic_vector(33:0)
      .kSlotId(1'b0),                          //in  std_logic
      .sSysRefFpgaLvds_p(DBA_FPGA_SYSREF_p),   //in  std_logic
      .sSysRefFpgaLvds_n(DBA_FPGA_SYSREF_n),   //in  std_logic
      .aLmkSync(DBA_CPLD_PL_SPI_ADDR[2]),      //out std_logic
      .JesdRefClk_p(USRPIO_A_MGTCLK_P),        //in  std_logic
      .JesdRefClk_n(USRPIO_A_MGTCLK_N),        //in  std_logic
      .aAdcRx_p(USRPIO_A_RX_P),                //in  std_logic_vector(3:0)
      .aAdcRx_n(USRPIO_A_RX_N),                //in  std_logic_vector(3:0)
      .aSyncAdcOut_n(DBA_MYK_SYNC_IN_n),       //out std_logic
      .aDacTx_p(USRPIO_A_TX_P),                //out std_logic_vector(3:0)
      .aDacTx_n(USRPIO_A_TX_N),                //out std_logic_vector(3:0)
      .aSyncDacIn_n(DBA_MYK_SYNC_OUT_n),       //in  std_logic
      .aAdcSync(aAdcSyncUnusedA),              //out std_logic
      .aDacSync(aDacSyncUnusedA),              //out std_logic
      .sAdcDataValid(rx_a_valid),              //out std_logic
      .sAdcDataSamples0I(rx0[31:16]),          //out std_logic_vector(15:0)
      .sAdcDataSamples0Q(rx0[15:0]),           //out std_logic_vector(15:0)
      .sAdcDataSamples1I(rx1[31:16]),          //out std_logic_vector(15:0)
      .sAdcDataSamples1Q(rx1[15:0]),           //out std_logic_vector(15:0)
      .sDacReadyForInput(tx_a_rfi),            //out std_logic
      .sDacDataSamples0I(tx0[31:16]),          //in  std_logic_vector(15:0)
      .sDacDataSamples0Q(tx0[15:0]),           //in  std_logic_vector(15:0)
      .sDacDataSamples1I(tx1[31:16]),          //in  std_logic_vector(15:0)
      .sDacDataSamples1Q(tx1[15:0]),           //in  std_logic_vector(15:0)
      .RefClk(ref_clk),                        //in  std_logic
      .rPpsPulse(pps_refclk),                  //in  std_logic
      .rGatedPulseToPin(UNUSED_PIN_TDCA_0),    //inout std_logic
      .sGatedPulseToPin(UNUSED_PIN_TDCA_1),    //inout std_logic
      .rRSP(rRSP_a_unused),                    //out std_logic
      .sRTC(sRTC_a_unused),                    //out std_logic
      .sPps(pps_radioclk1x));                  //out std_logic

  assign rx_stb[0] = rx_a_valid;
  assign rx_stb[1] = rx_a_valid;
  assign tx_stb[0] = tx_a_rfi;
  assign tx_stb[1] = tx_a_rfi;

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

  wire          reg_portB_rd;
  wire          reg_portB_wr;
  wire [14-1:0] reg_portB_addr;
  wire [32-1:0] reg_portB_wr_data;
  wire [32-1:0] reg_portB_rd_data;
  wire          reg_portB_ready;
  wire          validB_unused;

  assign bRegPortInFlatB = {2'b0, reg_portB_addr, reg_portB_wr_data, reg_portB_rd, reg_portB_wr};
  assign {reg_portB_rd_data, validB_unused, reg_portB_ready} = bRegPortOutFlatB;

  DbCore
    dbb_core (
      .aReset(clk40_rst),                  //in  std_logic
      .bReset(1'b0),                           //in  std_logic
      .BusClk(clk40),                          //in  std_logic
      .Clk40(clk40),                           //in  std_logic
      .MeasClk(meas_clk),                      //in  std_logic
      .FpgaClk_p(DBB_FPGA_CLK_p),              //in  std_logic
      .FpgaClk_n(DBB_FPGA_CLK_n),              //in  std_logic
      .SampleClk1xOut(radio_clkB),             //out std_logic
      .SampleClk1x(radio_clk),                 //in  std_logic
      .SampleClk2xOut(radio_clk_2xB),          //out std_logic
      .SampleClk2x(radio_clk_2x),              //in  std_logic
      .bRegPortInFlat(bRegPortInFlatB),        //in  std_logic_vector(49:0)
      .bRegPortOutFlat(bRegPortOutFlatB),      //out std_logic_vector(33:0)
      .kSlotId(1'b1),                          //in  std_logic
      .sSysRefFpgaLvds_p(DBB_FPGA_SYSREF_p),   //in  std_logic
      .sSysRefFpgaLvds_n(DBB_FPGA_SYSREF_n),   //in  std_logic
      .aLmkSync(DBB_CPLD_PL_SPI_ADDR[2]),      //out std_logic
      .JesdRefClk_p(USRPIO_B_MGTCLK_P),        //in  std_logic
      .JesdRefClk_n(USRPIO_B_MGTCLK_N),        //in  std_logic
      .aAdcRx_p(USRPIO_B_RX_P),                //in  std_logic_vector(3:0)
      .aAdcRx_n(USRPIO_B_RX_N),                //in  std_logic_vector(3:0)
      .aSyncAdcOut_n(DBB_MYK_SYNC_IN_n),       //out std_logic
      .aDacTx_p(USRPIO_B_TX_P),                //out std_logic_vector(3:0)
      .aDacTx_n(USRPIO_B_TX_N),                //out std_logic_vector(3:0)
      .aSyncDacIn_n(DBB_MYK_SYNC_OUT_n),       //in  std_logic
      .aAdcSync(aAdcSyncUnusedB),              //out std_logic
      .aDacSync(aDacSyncUnusedB),              //out std_logic
      .sAdcDataValid(rx_b_valid),              //out std_logic
      .sAdcDataSamples0I(rx2[31:16]),          //out std_logic_vector(15:0)
      .sAdcDataSamples0Q(rx2[15:0]),           //out std_logic_vector(15:0)
      .sAdcDataSamples1I(rx3[31:16]),          //out std_logic_vector(15:0)
      .sAdcDataSamples1Q(rx3[15:0]),           //out std_logic_vector(15:0)
      .sDacReadyForInput(tx_b_rfi),            //out std_logic
      .sDacDataSamples0I(tx2[31:16]),          //in  std_logic_vector(15:0)
      .sDacDataSamples0Q(tx2[15:0]),           //in  std_logic_vector(15:0)
      .sDacDataSamples1I(tx3[31:16]),          //in  std_logic_vector(15:0)
      .sDacDataSamples1Q(tx3[15:0]),           //in  std_logic_vector(15:0)
      .RefClk(ref_clk),                        //in  std_logic
      .rPpsPulse(pps_refclk),                  //in  std_logic
      .rGatedPulseToPin(UNUSED_PIN_TDCB_0),    //inout std_logic
      .sGatedPulseToPin(UNUSED_PIN_TDCB_1),    //inout std_logic
      .rRSP(rRSP_b_unused),                    //out std_logic
      .sRTC(sRTC_b_unused),                    //out std_logic
      .sPps(sPpsUnusedB));                     //out std_logic

  assign rx_stb[2] = rx_b_valid;
  assign rx_stb[3] = rx_b_valid;
  assign tx_stb[2] = tx_b_rfi;
  assign tx_stb[3] = tx_b_rfi;

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

   reg [31:0] counter1;
   always @(posedge bus_clk) begin
     if (clk40_rst)
       counter1 <= 32'd0;
     else
       counter1 <= counter1 + 32'd1;
   end
   reg [31:0] counter2;
   always @(posedge radio_clk) begin
     if (clk40_rst)
       counter2 <= 32'd0;
     else
       counter2 <= counter2 + 32'd1;
   end
   reg [31:0] counter3;
   always @(posedge sfp0_gb_refclk) begin
     if (clk40_rst)
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
   // ODDR #(
      // .DDR_CLK_EDGE("SAME_EDGE"), // "OPPOSITE_EDGE" or "SAME_EDGE"
      // .INIT(1'b0),    // Initial value of Q: 1'b0 or 1'b1
      // .SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC"
   // ) fclk_inst (
      // .Q(REF_1PPS_OUT),   // 1-bit DDR output
      // .C(gige_refclk),   // 1-bit clock input
      // .CE(1'b1), // 1-bit clock enable input
      // .D1(1'b0), // 1-bit data input (positive edge)
      // .D2(1'b1), // 1-bit data input (negative edge)
      // .R(1'b0),   // 1-bit reset
      // .S(1'b0)    // 1-bit set
   // );

endmodule
