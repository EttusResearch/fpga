//
// Copyright 2015 Ettus Research
//

module e300
(
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
  output        DDR_WEB_pin,
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

  //AVR SPI IO
  input         AVR_CS_R,
  output        AVR_IRQ,
  output        AVR_MISO_R,
  input         AVR_MOSI_R,
  input         AVR_SCK_R,

  input         ONSWITCH_DB,

  // RF Board connections
  // Change to inout/output as
  // they are implemented/tested
  input [34:0]  DB_EXP_1_8V,

  //band selects
  output [2:0]  TX_BANDSEL,
  output [2:0]  RX1_BANDSEL,
  output [2:0]  RX2_BANDSEL,
  output [1:0]  RX2C_BANDSEL,
  output [1:0]  RX1B_BANDSEL,
  output [1:0]  RX1C_BANDSEL,
  output [1:0]  RX2B_BANDSEL,

  //enables
  output        TX_ENABLE1A,
  output        TX_ENABLE2A,
  output        TX_ENABLE1B,
  output        TX_ENABLE2B,

  //antenna selects
  output        VCTXRX1_V1,
  output        VCTXRX1_V2,
  output        VCTXRX2_V1,
  output        VCTXRX2_V2,
  output        VCRX1_V1,
  output        VCRX1_V2,
  output        VCRX2_V1,
  output        VCRX2_V2,

  // leds
  output        LED_TXRX1_TX,
  output        LED_TXRX1_RX,
  output        LED_RX1_RX,
  output        LED_TXRX2_TX,
  output        LED_TXRX2_RX,
  output        LED_RX2_RX,

  // ad9361 connections
  input [7:0]   CAT_CTRL_OUT,
  output [3:0]  CAT_CTRL_IN,
  output        CAT_RESET,  // Really CAT_RESET_B, active low
  output        CAT_CS,
  output        CAT_SCLK,
  output        CAT_MOSI,
  input         CAT_MISO,
  input         CAT_BBCLK_OUT, //unused
  output        CAT_SYNC,
  output        CAT_TXNRX,
  output        CAT_ENABLE,
  output        CAT_ENAGC,
  input         CAT_RX_FRAME,
  input         CAT_DATA_CLK,
  output        CAT_TX_FRAME,
  output        CAT_FB_CLK,
  input [11:0]  CAT_P0_D,
  output [11:0] CAT_P1_D,

  // pps connections
  input         GPS_PPS,
  input         PPS_EXT_IN,

  // VTCXO and the DAC that feeds it
  output        TCXO_DAC_SYNCn,
  output        TCXO_DAC_SCLK,
  output        TCXO_DAC_SDIN,
  input         TCXO_CLK,

  // gpios, change to inout somehow
  inout [5:0]   PL_GPIO
);

  // Internal connections to PS
  //   GP0 -- General Purpose port 0, FPGA is the slave
  wire [31:0] GP0_M_AXI_AWADDR_pin;
  wire        GP0_M_AXI_AWVALID_pin;
  wire        GP0_M_AXI_AWREADY_pin;
  wire [31:0] GP0_M_AXI_WDATA_pin;
  wire [3:0]  GP0_M_AXI_WSTRB_pin;
  wire        GP0_M_AXI_WVALID_pin;
  wire        GP0_M_AXI_WREADY_pin;
  wire [1:0]  GP0_M_AXI_BRESP_pin;
  wire        GP0_M_AXI_BVALID_pin;
  wire        GP0_M_AXI_BREADY_pin;
  wire [31:0] GP0_M_AXI_ARADDR_pin;
  wire        GP0_M_AXI_ARVALID_pin;
  wire        GP0_M_AXI_ARREADY_pin;
  wire [31:0] GP0_M_AXI_RDATA_pin;
  wire [1:0]  GP0_M_AXI_RRESP_pin;
  wire        GP0_M_AXI_RVALID_pin;
  wire        GP0_M_AXI_RREADY_pin;
  //   HP0 -- High Performance port 0, FPGA is the master
  wire [31:0] HP0_S_AXI_AWADDR_pin;
  wire [2:0]  HP0_S_AXI_AWPROT_pin;
  wire        HP0_S_AXI_AWVALID_pin;
  wire        HP0_S_AXI_AWREADY_pin;
  wire [63:0] HP0_S_AXI_WDATA_pin;
  wire [7:0]  HP0_S_AXI_WSTRB_pin;
  wire        HP0_S_AXI_WVALID_pin;
  wire        HP0_S_AXI_WREADY_pin;
  wire [1:0]  HP0_S_AXI_BRESP_pin;
  wire        HP0_S_AXI_BVALID_pin;
  wire        HP0_S_AXI_BREADY_pin;
  wire [31:0] HP0_S_AXI_ARADDR_pin;
  wire [2:0]  HP0_S_AXI_ARPROT_pin;
  wire        HP0_S_AXI_ARVALID_pin;
  wire        HP0_S_AXI_ARREADY_pin;
  wire [63:0] HP0_S_AXI_RDATA_pin;
  wire [1:0]  HP0_S_AXI_RRESP_pin;
  wire        HP0_S_AXI_RVALID_pin;
  wire        HP0_S_AXI_RREADY_pin;
  wire [3:0]  HP0_S_AXI_ARCACHE_pin;
  wire [7:0]  HP0_S_AXI_AWLEN_pin;
  wire [2:0]  HP0_S_AXI_AWSIZE_pin;
  wire [1:0]  HP0_S_AXI_AWBURST_pin;
  wire [3:0]  HP0_S_AXI_AWCACHE_pin;
  wire        HP0_S_AXI_WLAST_pin;
  wire [7:0]  HP0_S_AXI_ARLEN_pin;
  wire [1:0]  HP0_S_AXI_ARBURST_pin;
  wire [2:0]  HP0_S_AXI_ARSIZE_pin;

  wire        bus_clk_pin;

  wire        bus_clk;
  wire        bus_rst;
  wire        sys_arst, sys_arst_n;

  wire [31:0] ps_gpio_out;
  wire [31:0] ps_gpio_in;

  // register the debounced onswitch signal to detect edges,
  // Note: ONSWITCH_DB is low active
  reg [1:0] onswitch_edge;
  always @ (posedge bus_clk)
    onswitch_edge <= bus_rst ? 2'b00 : {onswitch_edge[0], ONSWITCH_DB};

  wire button_press = ~ONSWITCH_DB & onswitch_edge[0] & onswitch_edge[1];
  wire button_release = ONSWITCH_DB & ~onswitch_edge[0] & ~onswitch_edge[1];

  // stretch the pulse so IRQs don't get lost
  reg [7:0] button_press_reg, button_release_reg;
  always @ (posedge bus_clk)
    if (bus_rst) begin
      button_press_reg <= 8'h00;
      button_release_reg <= 8'h00;
    end else begin
      button_press_reg <= {button_press_reg[6:0], button_press};
      button_release_reg <= {button_release_reg[6:0], button_release};
    end

  wire button_press_irq = |button_press_reg;
  wire button_release_irq = |button_release_reg;

  // connect PPS input to GPIO so ntpd can use it
  reg [2:0] pps_reg;
  always @ (posedge bus_clk)
    pps_reg <= bus_rst ? 3'b000 : {pps_reg[1:0], GPS_PPS};
  assign ps_gpio_in[8] = pps_reg[2]; // 62

  // First, make all connections to the PS (ARM+buses)
  e300_ps e300_ps_instance
  (  // Outward connections to the pins
    .processing_system7_0_MIO(MIO),
    .processing_system7_0_PS_SRSTB_pin(PS_SRSTB),
    .processing_system7_0_PS_CLK_pin(PS_CLK),
    .processing_system7_0_PS_PORB_pin(PS_PORB),
    .processing_system7_0_DDR_Clk(DDR_Clk),
    .processing_system7_0_DDR_Clk_n(DDR_Clk_n),
    .processing_system7_0_DDR_CKE(DDR_CKE),
    .processing_system7_0_DDR_CS_n(DDR_CS_n),
    .processing_system7_0_DDR_RAS_n(DDR_RAS_n),
    .processing_system7_0_DDR_CAS_n(DDR_CAS_n),
    .processing_system7_0_DDR_WEB_pin(DDR_WEB_pin),
    .processing_system7_0_DDR_BankAddr(DDR_BankAddr),
    .processing_system7_0_DDR_Addr(DDR_Addr),
    .processing_system7_0_DDR_ODT(DDR_ODT),
    .processing_system7_0_DDR_DRSTB(DDR_DRSTB),
    .processing_system7_0_DDR_DQ(DDR_DQ),
    .processing_system7_0_DDR_DM(DDR_DM),
    .processing_system7_0_DDR_DQS(DDR_DQS),
    .processing_system7_0_DDR_DQS_n(DDR_DQS_n),
    .processing_system7_0_DDR_VRN(DDR_VRN),
    .processing_system7_0_DDR_VRP(DDR_VRP),

    // Inward connections to our logic
    //    GP0  --  General Purpose Slave 0
    .axi_ext_slave_conn_0_M_AXI_AWADDR_pin(GP0_M_AXI_AWADDR_pin),
    .axi_ext_slave_conn_0_M_AXI_AWVALID_pin(GP0_M_AXI_AWVALID_pin),
    .axi_ext_slave_conn_0_M_AXI_AWREADY_pin(GP0_M_AXI_AWREADY_pin),
    .axi_ext_slave_conn_0_M_AXI_WDATA_pin(GP0_M_AXI_WDATA_pin),
    .axi_ext_slave_conn_0_M_AXI_WSTRB_pin(GP0_M_AXI_WSTRB_pin),
    .axi_ext_slave_conn_0_M_AXI_WVALID_pin(GP0_M_AXI_WVALID_pin),
    .axi_ext_slave_conn_0_M_AXI_WREADY_pin(GP0_M_AXI_WREADY_pin),
    .axi_ext_slave_conn_0_M_AXI_BRESP_pin(GP0_M_AXI_BRESP_pin),
    .axi_ext_slave_conn_0_M_AXI_BVALID_pin(GP0_M_AXI_BVALID_pin),
    .axi_ext_slave_conn_0_M_AXI_BREADY_pin(GP0_M_AXI_BREADY_pin),
    .axi_ext_slave_conn_0_M_AXI_ARADDR_pin(GP0_M_AXI_ARADDR_pin),
    .axi_ext_slave_conn_0_M_AXI_ARVALID_pin(GP0_M_AXI_ARVALID_pin),
    .axi_ext_slave_conn_0_M_AXI_ARREADY_pin(GP0_M_AXI_ARREADY_pin),
    .axi_ext_slave_conn_0_M_AXI_RDATA_pin(GP0_M_AXI_RDATA_pin),
    .axi_ext_slave_conn_0_M_AXI_RRESP_pin(GP0_M_AXI_RRESP_pin),
    .axi_ext_slave_conn_0_M_AXI_RVALID_pin(GP0_M_AXI_RVALID_pin),
    .axi_ext_slave_conn_0_M_AXI_RREADY_pin(GP0_M_AXI_RREADY_pin),

    //    Misc interrupts, GPIO, clk
    .processing_system7_0_IRQ_F2P_pin({13'h0, button_release_irq, button_press_irq, 1'b0}),
    .processing_system7_0_GPIO_I_pin(ps_gpio_in),
    .processing_system7_0_GPIO_O_pin(ps_gpio_out),
    .processing_system7_0_FCLK_CLK0_pin(bus_clk_pin),
    .processing_system7_0_FCLK_RESET0_N_pin(sys_arst_n),

    //    HP0  --  High Performance Master 0
    .axi_ext_master_conn_0_S_AXI_AWADDR_pin(HP0_S_AXI_AWADDR_pin),
    .axi_ext_master_conn_0_S_AXI_AWPROT_pin(HP0_S_AXI_AWPROT_pin),
    .axi_ext_master_conn_0_S_AXI_AWVALID_pin(HP0_S_AXI_AWVALID_pin),
    .axi_ext_master_conn_0_S_AXI_AWREADY_pin(HP0_S_AXI_AWREADY_pin),
    .axi_ext_master_conn_0_S_AXI_WDATA_pin(HP0_S_AXI_WDATA_pin),
    .axi_ext_master_conn_0_S_AXI_WSTRB_pin(HP0_S_AXI_WSTRB_pin),
    .axi_ext_master_conn_0_S_AXI_WVALID_pin(HP0_S_AXI_WVALID_pin),
    .axi_ext_master_conn_0_S_AXI_WREADY_pin(HP0_S_AXI_WREADY_pin),
    .axi_ext_master_conn_0_S_AXI_BRESP_pin(HP0_S_AXI_BRESP_pin),
    .axi_ext_master_conn_0_S_AXI_BVALID_pin(HP0_S_AXI_BVALID_pin),
    .axi_ext_master_conn_0_S_AXI_BREADY_pin(HP0_S_AXI_BREADY_pin),
    .axi_ext_master_conn_0_S_AXI_ARADDR_pin(HP0_S_AXI_ARADDR_pin),
    .axi_ext_master_conn_0_S_AXI_ARPROT_pin(HP0_S_AXI_ARPROT_pin),
    .axi_ext_master_conn_0_S_AXI_ARVALID_pin(HP0_S_AXI_ARVALID_pin),
    .axi_ext_master_conn_0_S_AXI_ARREADY_pin(HP0_S_AXI_ARREADY_pin),
    .axi_ext_master_conn_0_S_AXI_RDATA_pin(HP0_S_AXI_RDATA_pin),
    .axi_ext_master_conn_0_S_AXI_RRESP_pin(HP0_S_AXI_RRESP_pin),
    .axi_ext_master_conn_0_S_AXI_RVALID_pin(HP0_S_AXI_RVALID_pin),
    .axi_ext_master_conn_0_S_AXI_RREADY_pin(HP0_S_AXI_RREADY_pin),
    .axi_ext_master_conn_0_S_AXI_AWLEN_pin(HP0_S_AXI_AWLEN_pin),
    .axi_ext_master_conn_0_S_AXI_RLAST_pin(HP0_S_AXI_RLAST_pin),
    .axi_ext_master_conn_0_S_AXI_ARCACHE_pin(HP0_S_AXI_ARCACHE_pin),
    .axi_ext_master_conn_0_S_AXI_AWSIZE_pin(HP0_S_AXI_AWSIZE_pin),
    .axi_ext_master_conn_0_S_AXI_AWBURST_pin(HP0_S_AXI_AWBURST_pin),
    .axi_ext_master_conn_0_S_AXI_AWCACHE_pin(HP0_S_AXI_AWCACHE_pin),
    .axi_ext_master_conn_0_S_AXI_WLAST_pin(HP0_S_AXI_WLAST_pin),
    .axi_ext_master_conn_0_S_AXI_ARLEN_pin(HP0_S_AXI_ARLEN_pin),
    .axi_ext_master_conn_0_S_AXI_ARBURST_pin(HP0_S_AXI_ARBURST_pin),
    .axi_ext_master_conn_0_S_AXI_ARSIZE_pin(HP0_S_AXI_ARSIZE_pin),

    //    SPI Core 0 - To AD9361
    .processing_system7_0_SPI0_SS_O_pin(),
    .processing_system7_0_SPI0_SS1_O_pin(),
    .processing_system7_0_SPI0_SS2_O_pin(),
    .processing_system7_0_SPI0_SCLK_O_pin(),
    .processing_system7_0_SPI0_MOSI_O_pin(),
    .processing_system7_0_SPI0_MISO_I_pin(),

    //    SPI Core 1 - To AVR
    .processing_system7_0_SPI1_SS_O_pin(),
    .processing_system7_0_SPI1_SS1_O_pin(AVR_CS_R),
    .processing_system7_0_SPI1_SS2_O_pin(),
    .processing_system7_0_SPI1_SCLK_O_pin(AVR_SCK_R),
    .processing_system7_0_SPI1_MOSI_O_pin(AVR_MOSI_R),
    .processing_system7_0_SPI1_MISO_I_pin(AVR_MISO_R)
  );

  //------------------------------------------------------------------
  //-- generate clock and reset signals
  //------------------------------------------------------------------

  assign sys_arst = ~sys_arst_n;

  BUFG core_clk_gen
  (
    .I(bus_clk_pin),
    .O(bus_clk)
  );

  reset_sync core_rst_gen
  (
    .clk(bus_clk),
    .reset_in(sys_arst),
    .reset_out(bus_rst)
  );

  //band selects
  assign TX_BANDSEL   = 3'b000;
  assign RX1_BANDSEL  = 3'b000;
  assign RX2_BANDSEL  = 3'b000;
  assign RX2C_BANDSEL = 2'b00;
  assign RX1B_BANDSEL = 2'b00;
  assign RX1C_BANDSEL = 2'b00;
  assign RX2B_BANDSEL = 2'b00;

  //leds
  assign LED_TXRX1_TX = 1'b0;
  assign LED_TXRX1_RX = 1'b0;
  assign LED_RX1_RX = 1'b0;
  assign LED_TXRX2_TX = 1'b0;
  assign LED_TXRX2_RX = 1'b0;
  assign LED_RX2_RX = 1'b0;

  //enables
  assign TX_ENABLE1A = 1'b0;
  assign TX_ENABLE2A = 1'b0;
  assign TX_ENABLE1B = 1'b0;
  assign TX_ENABLE2B = 1'b0;

  //antenna selects
  assign VCTXRX1_V1 = 0;
  assign VCTXRX1_V2 = 0;
  assign VCTXRX2_V1 = 0;
  assign VCTXRX2_V2 = 0;
  assign VCRX1_V1   = 0;
  assign VCRX1_V2   = 0;
  assign VCRX2_V1   = 0;
  assign VCRX2_V2   = 0;

  assign CAT_CTRL_IN  = 4'b0000;
  assign CAT_RESET    = 1'b0;
  assign CAT_CS       = 1'b0;
  assign CAT_SCLK     = 1'b0;
  assign CAT_MOSI     = 1'b0;
  assign CAT_SYNC     = 1'b0;
  assign CAT_TXNRX    = 1'b0;
  assign CAT_ENABLE   = 1'b0;
  assign CAT_P1_D     = 12'b0000_0000_0000;

  assign CAT_TX_FRAME = 1'b0;
  assign CAT_FB_CLK   = 1'b0;
  assign CAT_ENAGC    = 1'b0;

  assign PL_GPIO = 6'b00_0000;

  assign AVR_IRQ = 1'b0;

  assign TCXO_DAC_SYNCn = 1'b1;
  assign TCXO_DAC_SCLK = 1'b0;
  assign TCXO_DAC_SDIN = 1'b0;

endmodule // e300
