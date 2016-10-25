//
// Copyright 2013-2014 Ettus Research
//

module e300
#(parameter STREAMS_WIDTH = 4,
  parameter CMDFIFO_DEPTH = 5,
  parameter CONFIG_BASE = 32'h4000_0000,
  parameter PAGE_WIDTH = 10)
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

  `ifdef DRAM_TEST
  // PL DDR
  input         PL_DDR3_SYSCLK,
  output        PL_DDR3_RESET_n,
  inout [15:0]  PL_DDR3_DQ,
  inout [1:0]   PL_DDR3_DQS_N,
  inout [1:0]   PL_DDR3_DQS_P,
  output [14:0] PL_DDR3_ADDR,
  output [2:0]  PL_DDR3_BA,
  output        PL_DDR3_RAS_n,
  output        PL_DDR3_CAS_n,
  output        PL_DDR3_WE_n,
  output [0:0]  PL_DDR3_CK_P,
  output [0:0]  PL_DDR3_CK_N,
  output [0:0]  PL_DDR3_CKE,
  output [1:0]  PL_DDR3_DM,
  output [0:0]  PL_DDR3_ODT,

  `endif

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
  wire [31:0] GP0_M_AXI_AWADDR;
  wire        GP0_M_AXI_AWVALID;
  wire        GP0_M_AXI_AWREADY;
  wire [31:0] GP0_M_AXI_WDATA;
  wire [3:0]  GP0_M_AXI_WSTRB;
  wire        GP0_M_AXI_WVALID;
  wire        GP0_M_AXI_WREADY;
  wire [1:0]  GP0_M_AXI_BRESP;
  wire        GP0_M_AXI_BVALID;
  wire        GP0_M_AXI_BREADY;
  wire [31:0] GP0_M_AXI_ARADDR;
  wire        GP0_M_AXI_ARVALID;
  wire        GP0_M_AXI_ARREADY;
  wire [31:0] GP0_M_AXI_RDATA;
  wire [1:0]  GP0_M_AXI_RRESP;
  wire        GP0_M_AXI_RVALID;
  wire        GP0_M_AXI_RREADY;

  wire [31:0] GP0_M_AXI_AWADDR_S0;
  wire        GP0_M_AXI_AWVALID_S0;
  wire        GP0_M_AXI_AWREADY_S0;
  wire [31:0] GP0_M_AXI_WDATA_S0;
  wire [3:0]  GP0_M_AXI_WSTRB_S0;
  wire        GP0_M_AXI_WVALID_S0;
  wire        GP0_M_AXI_WREADY_S0;
  wire [1:0]  GP0_M_AXI_BRESP_S0;
  wire        GP0_M_AXI_BVALID_S0;
  wire        GP0_M_AXI_BREADY_S0;
  wire [31:0] GP0_M_AXI_ARADDR_S0;
  wire        GP0_M_AXI_ARVALID_S0;
  wire        GP0_M_AXI_ARREADY_S0;
  wire [31:0] GP0_M_AXI_RDATA_S0;
  wire [1:0]  GP0_M_AXI_RRESP_S0;
  wire        GP0_M_AXI_RVALID_S0;
  wire        GP0_M_AXI_RREADY_S0;

  wire [31:0] GP0_M_AXI_AWADDR_S1;
  wire        GP0_M_AXI_AWVALID_S1;
  wire        GP0_M_AXI_AWREADY_S1;
  wire [31:0] GP0_M_AXI_WDATA_S1;
  wire [3:0]  GP0_M_AXI_WSTRB_S1;
  wire        GP0_M_AXI_WVALID_S1;
  wire        GP0_M_AXI_WREADY_S1;
  wire [1:0]  GP0_M_AXI_BRESP_S1;
  wire        GP0_M_AXI_BVALID_S1;
  wire        GP0_M_AXI_BREADY_S1;
  wire [31:0] GP0_M_AXI_ARADDR_S1;
  wire        GP0_M_AXI_ARVALID_S1;
  wire        GP0_M_AXI_ARREADY_S1;
  wire [31:0] GP0_M_AXI_RDATA_S1;
  wire [1:0]  GP0_M_AXI_RRESP_S1;
  wire        GP0_M_AXI_RVALID_S1;
  wire        GP0_M_AXI_RREADY_S1;

  //   HP0 -- High Performance port 0, FPGA is the master
  wire [5:0]  HP0_S_AXI_AWID;
  wire [31:0] HP0_S_AXI_AWADDR;
  wire [2:0]  HP0_S_AXI_AWPROT;
  wire        HP0_S_AXI_AWVALID;
  wire        HP0_S_AXI_AWREADY;
  wire [63:0] HP0_S_AXI_WDATA;
  wire [7:0]  HP0_S_AXI_WSTRB;
  wire        HP0_S_AXI_WVALID;
  wire        HP0_S_AXI_WREADY;
  wire [1:0]  HP0_S_AXI_BRESP;
  wire        HP0_S_AXI_BVALID;
  wire        HP0_S_AXI_BREADY;
  wire [5:0]  HP0_S_AXI_ARID;
  wire [31:0] HP0_S_AXI_ARADDR;
  wire [2:0]  HP0_S_AXI_ARPROT;
  wire        HP0_S_AXI_ARVALID;
  wire        HP0_S_AXI_ARREADY;
  wire [63:0] HP0_S_AXI_RDATA;
  wire [1:0]  HP0_S_AXI_RRESP;
  wire        HP0_S_AXI_RVALID;
  wire        HP0_S_AXI_RREADY;
  wire [3:0]  HP0_S_AXI_ARCACHE;
  wire [7:0]  HP0_S_AXI_AWLEN;
  wire [2:0]  HP0_S_AXI_AWSIZE;
  wire [1:0]  HP0_S_AXI_AWBURST;
  wire [3:0]  HP0_S_AXI_AWCACHE;
  wire        HP0_S_AXI_WLAST;
  wire [7:0]  HP0_S_AXI_ARLEN;
  wire [1:0]  HP0_S_AXI_ARBURST;
  wire [2:0]  HP0_S_AXI_ARSIZE;

  wire        fclk_clk0;
  wire        fclk_reset0;
  wire        fclk_clk1;
  wire        fclk_reset1;
  wire        fclk_clk2;
  wire        fclk_reset2;
  wire        fclk_clk3;
  wire        fclk_reset3;

  wire pl_dram_clk;
  wire pl_dram_rst;

  wire        bus_clk, radio_clk;
  wire        bus_rst, radio_rst;

  wire [31:0] ps_gpio_out;
  wire [31:0] ps_gpio_in;

  wire        stream_irq;

  wire [63:0] h2s_tdata;
  wire        h2s_tvalid;
  wire        h2s_tready;
  wire        h2s_tlast;

  wire [63:0] s2h_tdata;
  wire        s2h_tvalid;
  wire        s2h_tready;
  wire        s2h_tlast;

  wire        pmu_irq;

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
  axi_interconnect inst_axi_interconnect
  (
    .aclk(bus_clk),
    .aresetn(~bus_rst),
    .s_axi_awaddr(GP0_M_AXI_AWADDR),
    .s_axi_awready(GP0_M_AXI_AWREADY),
    .s_axi_awvalid(GP0_M_AXI_AWVALID),
    .s_axi_wdata(GP0_M_AXI_WDATA),
    .s_axi_wstrb(GP0_M_AXI_WSTRB),
    .s_axi_wvalid(GP0_M_AXI_WVALID),
    .s_axi_wready(GP0_M_AXI_WREADY),
    .s_axi_bresp(GP0_M_AXI_BRESP),
    .s_axi_bvalid(GP0_M_AXI_BVALID),
    .s_axi_bready(GP0_M_AXI_BREADY),
    .s_axi_araddr(GP0_M_AXI_ARADDR),
    .s_axi_arvalid(GP0_M_AXI_ARVALID),
    .s_axi_arready(GP0_M_AXI_ARREADY),
    .s_axi_rdata(GP0_M_AXI_RDATA),
    .s_axi_rresp(GP0_M_AXI_RRESP),
    .s_axi_rvalid(GP0_M_AXI_RVALID),
    .s_axi_rready(GP0_M_AXI_RREADY),
    .m_axi_awaddr({GP0_M_AXI_AWADDR_S1, GP0_M_AXI_AWADDR_S0}),
    .m_axi_awvalid({GP0_M_AXI_AWVALID_S1, GP0_M_AXI_AWVALID_S0}),
    .m_axi_awready({GP0_M_AXI_AWREADY_S1, GP0_M_AXI_AWREADY_S0}),
    .m_axi_wdata({GP0_M_AXI_WDATA_S1, GP0_M_AXI_WDATA_S0}),
    .m_axi_wstrb({GP0_M_AXI_WSTRB_S1, GP0_M_AXI_WSTRB_S0}),
    .m_axi_wvalid({GP0_M_AXI_WVALID_S1, GP0_M_AXI_WVALID_S0}),
    .m_axi_wready({GP0_M_AXI_WREADY_S1, GP0_M_AXI_WREADY_S0}),
    .m_axi_bresp({GP0_M_AXI_BRESP_S1, GP0_M_AXI_BRESP_S0}),
    .m_axi_bvalid({GP0_M_AXI_BVALID_S1, GP0_M_AXI_BVALID_S0}),
    .m_axi_bready({GP0_M_AXI_BREADY_S1, GP0_M_AXI_BREADY_S0}),
    .m_axi_araddr({GP0_M_AXI_ARADDR_S1, GP0_M_AXI_ARADDR_S0}),
    .m_axi_arvalid({GP0_M_AXI_ARVALID_S1, GP0_M_AXI_ARVALID_S0}),
    .m_axi_arready({GP0_M_AXI_ARREADY_S1, GP0_M_AXI_ARREADY_S0}),
    .m_axi_rdata({GP0_M_AXI_RDATA_S1, GP0_M_AXI_RDATA_S0}),
    .m_axi_rresp({GP0_M_AXI_RRESP_S1, GP0_M_AXI_RRESP_S0}),
    .m_axi_rvalid({GP0_M_AXI_RVALID_S1, GP0_M_AXI_RVALID_S0}),
    .m_axi_rready({GP0_M_AXI_RREADY_S1, GP0_M_AXI_RREADY_S0})
  );

  axi_pmu inst_axi_pmu
  (
    .s_axi_aclk(bus_clk),
    .s_axi_areset(bus_rst),

    .ss(AVR_CS_R),
    .mosi(AVR_MOSI_R),
    .sck(AVR_SCK_R),
    .miso(AVR_MISO_R),

    .s_axi_awaddr(GP0_M_AXI_AWADDR_S1),
    .s_axi_awvalid(GP0_M_AXI_AWVALID_S1),
    .s_axi_awready(GP0_M_AXI_AWREADY_S1),

    .s_axi_wdata(GP0_M_AXI_WDATA_S1),
    .s_axi_wstrb(GP0_M_AXI_WSTRB_S1),
    .s_axi_wvalid(GP0_M_AXI_WVALID_S1),
    .s_axi_wready(GP0_M_AXI_WREADY_S1),

    .s_axi_bresp(GP0_M_AXI_BRESP_S1),
    .s_axi_bvalid(GP0_M_AXI_BVALID_S1),
    .s_axi_bready(GP0_M_AXI_BREADY_S1),

    .s_axi_araddr(GP0_M_AXI_ARADDR_S1),
    .s_axi_arvalid(GP0_M_AXI_ARVALID_S1),
    .s_axi_arready(GP0_M_AXI_ARREADY_S1),

    .s_axi_rdata(GP0_M_AXI_RDATA_S1),
    .s_axi_rresp(GP0_M_AXI_RRESP_S1),
    .s_axi_rvalid(GP0_M_AXI_RVALID_S1),
    .s_axi_rready(GP0_M_AXI_RREADY_S1),
    .s_axi_irq(pmu_irq)
  );

  e300_processing_system inst_e300_processing_system
  (  // Outward connections to the pins
    .MIO(MIO),
    .PS_SRSTB(PS_SRSTB),
    .PS_CLK(PS_CLK),
    .PS_PORB(PS_PORB),
    .DDR_Clk(DDR_Clk),
    .DDR_Clk_n(DDR_Clk_n),
    .DDR_CKE(DDR_CKE),
    .DDR_CS_n(DDR_CS_n),
    .DDR_RAS_n(DDR_RAS_n),
    .DDR_CAS_n(DDR_CAS_n),
    .DDR_WEB(DDR_WEB),
    .DDR_BankAddr(DDR_BankAddr),
    .DDR_Addr(DDR_Addr),
    .DDR_ODT(DDR_ODT),
    .DDR_DRSTB(DDR_DRSTB),
    .DDR_DQ(DDR_DQ),
    .DDR_DM(DDR_DM),
    .DDR_DQS(DDR_DQS),
    .DDR_DQS_n(DDR_DQS_n),
    .DDR_VRN(DDR_VRN),
    .DDR_VRP(DDR_VRP),

    // Inward connections to our logic
    //    GP0  --  General Purpose Slave 0
    .M_AXI_GP0_AWADDR(GP0_M_AXI_AWADDR),
    .M_AXI_GP0_AWVALID(GP0_M_AXI_AWVALID),
    .M_AXI_GP0_AWREADY(GP0_M_AXI_AWREADY),
    .M_AXI_GP0_WDATA(GP0_M_AXI_WDATA),
    .M_AXI_GP0_WSTRB(GP0_M_AXI_WSTRB),
    .M_AXI_GP0_WVALID(GP0_M_AXI_WVALID),
    .M_AXI_GP0_WREADY(GP0_M_AXI_WREADY),
    .M_AXI_GP0_BRESP(GP0_M_AXI_BRESP),
    .M_AXI_GP0_BVALID(GP0_M_AXI_BVALID),
    .M_AXI_GP0_BREADY(GP0_M_AXI_BREADY),
    .M_AXI_GP0_ARADDR(GP0_M_AXI_ARADDR),
    .M_AXI_GP0_ARVALID(GP0_M_AXI_ARVALID),
    .M_AXI_GP0_ARREADY(GP0_M_AXI_ARREADY),
    .M_AXI_GP0_RDATA(GP0_M_AXI_RDATA),
    .M_AXI_GP0_RRESP(GP0_M_AXI_RRESP),
    .M_AXI_GP0_RVALID(GP0_M_AXI_RVALID),
    .M_AXI_GP0_RREADY(GP0_M_AXI_RREADY),

    //    Misc interrupts, GPIO, clk
    .IRQ_F2P({12'h0, pmu_irq, button_release_irq, button_press_irq, stream_irq}),
    .GPIO_I(ps_gpio_in),
    .GPIO_O(ps_gpio_out),
    .FCLK_CLK0(fclk_clk0),
    .FCLK_RESET0(fclk_reset0),
    .FCLK_CLK1(fclk_clk1),
    .FCLK_RESET1(fclk_reset1),
    .FCLK_CLK2(fclk_clk2),
    .FCLK_RESET2(fclk_reset2),
    .FCLK_CLK3(fclk_clk3),
    .FCLK_RESET3(fclk_reset3),

    .PL_DRAM_CLK(pl_dram_clk),
    .PL_DRAM_RST(pl_dram_rst),

    //    HP0  --  High Performance Master 0
    .S_AXI_HP0_AWID(HP0_S_AXI_AWID),
    .S_AXI_HP0_AWADDR(HP0_S_AXI_AWADDR),
    .S_AXI_HP0_AWPROT(HP0_S_AXI_AWPROT),
    .S_AXI_HP0_AWVALID(HP0_S_AXI_AWVALID),
    .S_AXI_HP0_AWREADY(HP0_S_AXI_AWREADY),
    .S_AXI_HP0_WDATA(HP0_S_AXI_WDATA),
    .S_AXI_HP0_WSTRB(HP0_S_AXI_WSTRB),
    .S_AXI_HP0_WVALID(HP0_S_AXI_WVALID),
    .S_AXI_HP0_WREADY(HP0_S_AXI_WREADY),
    .S_AXI_HP0_BRESP(HP0_S_AXI_BRESP),
    .S_AXI_HP0_BVALID(HP0_S_AXI_BVALID),
    .S_AXI_HP0_BREADY(HP0_S_AXI_BREADY),
    .S_AXI_HP0_ARID(HP0_S_AXI_ARID),
    .S_AXI_HP0_ARADDR(HP0_S_AXI_ARADDR),
    .S_AXI_HP0_ARPROT(HP0_S_AXI_ARPROT),
    .S_AXI_HP0_ARVALID(HP0_S_AXI_ARVALID),
    .S_AXI_HP0_ARREADY(HP0_S_AXI_ARREADY),
    .S_AXI_HP0_RDATA(HP0_S_AXI_RDATA),
    .S_AXI_HP0_RRESP(HP0_S_AXI_RRESP),
    .S_AXI_HP0_RVALID(HP0_S_AXI_RVALID),
    .S_AXI_HP0_RREADY(HP0_S_AXI_RREADY),
    .S_AXI_HP0_AWLEN(HP0_S_AXI_AWLEN),
    .S_AXI_HP0_RLAST(HP0_S_AXI_RLAST),
    .S_AXI_HP0_ARCACHE(HP0_S_AXI_ARCACHE),
    .S_AXI_HP0_AWSIZE(HP0_S_AXI_AWSIZE),
    .S_AXI_HP0_AWBURST(HP0_S_AXI_AWBURST),
    .S_AXI_HP0_AWCACHE(HP0_S_AXI_AWCACHE),
    .S_AXI_HP0_WLAST(HP0_S_AXI_WLAST),
    .S_AXI_HP0_ARLEN(HP0_S_AXI_ARLEN),
    .S_AXI_HP0_ARBURST(HP0_S_AXI_ARBURST),
    .S_AXI_HP0_ARSIZE(HP0_S_AXI_ARSIZE),

    //    SPI Core 0 - To AD9361
    .SPI0_SS(),
    .SPI0_SS1(CAT_CS),
    .SPI0_SS2(),
    .SPI0_SCLK(CAT_SCLK),
    .SPI0_MOSI(CAT_MOSI),
    .SPI0_MISO(CAT_MISO),

    //    SPI Core 1 - To AVR
    .SPI1_SS(),
    .SPI1_SS1(),
    .SPI1_SS2(),
    .SPI1_SCLK(),
    .SPI1_MOSI(),
    .SPI1_MISO()
  );

  //------------------------------------------------------------------
  //-- generate clock and reset signals
  //------------------------------------------------------------------

  reset_sync radio_rst_sync
  (
    .clk(radio_clk),
    .reset_in(bus_rst),
    .reset_out(radio_rst)
  );

  assign bus_clk = fclk_clk0;
  assign bus_rst = fclk_reset0;

  //------------------------------------------------------------------
  // CODEC capture/gen
  //------------------------------------------------------------------
  wire mimo;
  wire codec_arst;
  wire [31:0] rx_data0, rx_data1, tx_data0, tx_data1;

  catcodec_ddr_cmos #(
    .DEVICE("7SERIES"))
  inst_catcodec_ddr_cmos (
    .radio_clk(radio_clk),
    .arst(codec_arst),
    .mimo(mimo),
    .rx1(rx_data0),
    .rx2(rx_data1),
    .tx1(tx_data0),
    .tx2(tx_data1),
    .rx_clk(CAT_DATA_CLK),
    .rx_frame(CAT_RX_FRAME),
    .rx_d(CAT_P0_D),
    .tx_clk(CAT_FB_CLK),
    .tx_frame(CAT_TX_FRAME),
    .tx_d(CAT_P1_D));

  assign CAT_CTRL_IN = 4'b1;
  assign CAT_ENAGC = 1'b1;
  assign CAT_TXNRX = 1'b1;
  assign CAT_ENABLE = 1'b1;

  assign CAT_RESET = ~(bus_rst || (CAT_CS & CAT_MOSI));   // Operates active-low, really CAT_RESET_B
  assign CAT_SYNC = 1'b0;

  //------------------------------------------------------------------
  //-- radio core from x300 for super fast bring up
  //------------------------------------------------------------------

  wire [31:0] gpio0, gpio1;
  wire [5:0]  fp_gpio_in, fp_gpio_out, fp_gpio_ddr;

  assign { LED_TXRX1_TX, LED_TXRX1_RX, LED_RX1_RX, //3
           VCRX1_V2, VCRX1_V1, VCTXRX1_V2, VCTXRX1_V1, //4
           TX_ENABLE1B, TX_ENABLE1A //2
         } = gpio0[18:10];

  assign { LED_TXRX2_TX, LED_TXRX2_RX, LED_RX2_RX, //3
           VCRX2_V2, VCRX2_V1, VCTXRX2_V2, VCTXRX2_V1, //4
           TX_ENABLE2B, TX_ENABLE2A //2
         } = gpio1[18:10];

  gpio_atr_io #(.WIDTH(6)) fp_gpio_atr_inst (
    .clk(radio_clk), .gpio_pins(PL_GPIO),
    .gpio_ddr(fp_gpio_ddr), .gpio_out(fp_gpio_out), .gpio_in(fp_gpio_in)
  );

  //------------------------------------------------------------------
  //-- Zynq system interface, DMA, control channels, etc.
  //------------------------------------------------------------------

  wire [31:0] core_set_data, core_rb_data, xbar_set_data, xbar_rb_data;
  wire [7:0] core_set_addr;
  wire [10:0] xbar_set_addr, xbar_rb_addr;
  wire        core_set_stb, xbar_set_stb, xbar_rb_stb;


  zynq_fifo_top_legacy
  #(
    .CONFIG_BASE(CONFIG_BASE),
    .PAGE_WIDTH(PAGE_WIDTH),
    .H2S_STREAMS_WIDTH(STREAMS_WIDTH),
    .H2S_CMDFIFO_DEPTH(CMDFIFO_DEPTH),
    .S2H_STREAMS_WIDTH(STREAMS_WIDTH),
    .S2H_CMDFIFO_DEPTH(CMDFIFO_DEPTH)
  )
  zynq_fifo_top0
  (
    .clk(bus_clk), .rst(bus_rst),
    .CTL_AXI_AWADDR(GP0_M_AXI_AWADDR_S0),
    .CTL_AXI_AWVALID(GP0_M_AXI_AWVALID_S0),
    .CTL_AXI_AWREADY(GP0_M_AXI_AWREADY_S0),
    .CTL_AXI_WDATA(GP0_M_AXI_WDATA_S0),
    .CTL_AXI_WSTRB(GP0_M_AXI_WSTRB_S0),
    .CTL_AXI_WVALID(GP0_M_AXI_WVALID_S0),
    .CTL_AXI_WREADY(GP0_M_AXI_WREADY_S0),
    .CTL_AXI_BRESP(GP0_M_AXI_BRESP_S0),
    .CTL_AXI_BVALID(GP0_M_AXI_BVALID_S0),
    .CTL_AXI_BREADY(GP0_M_AXI_BREADY_S0),
    .CTL_AXI_ARADDR(GP0_M_AXI_ARADDR_S0),
    .CTL_AXI_ARVALID(GP0_M_AXI_ARVALID_S0),
    .CTL_AXI_ARREADY(GP0_M_AXI_ARREADY_S0),
    .CTL_AXI_RDATA(GP0_M_AXI_RDATA_S0),
    .CTL_AXI_RRESP(GP0_M_AXI_RRESP_S0),
    .CTL_AXI_RVALID(GP0_M_AXI_RVALID_S0),
    .CTL_AXI_RREADY(GP0_M_AXI_RREADY_S0),

    .DDR_AXI_AWID(HP0_S_AXI_AWID),
    .DDR_AXI_AWADDR(HP0_S_AXI_AWADDR),
    .DDR_AXI_AWPROT(HP0_S_AXI_AWPROT),
    .DDR_AXI_AWVALID(HP0_S_AXI_AWVALID),
    .DDR_AXI_AWREADY(HP0_S_AXI_AWREADY),
    .DDR_AXI_WDATA(HP0_S_AXI_WDATA),
    .DDR_AXI_WSTRB(HP0_S_AXI_WSTRB),
    .DDR_AXI_WVALID(HP0_S_AXI_WVALID),
    .DDR_AXI_WREADY(HP0_S_AXI_WREADY),
    .DDR_AXI_BRESP(HP0_S_AXI_BRESP),
    .DDR_AXI_BVALID(HP0_S_AXI_BVALID),
    .DDR_AXI_BREADY(HP0_S_AXI_BREADY),
    .DDR_AXI_ARID(HP0_S_AXI_ARID),
    .DDR_AXI_ARADDR(HP0_S_AXI_ARADDR),
    .DDR_AXI_ARPROT(HP0_S_AXI_ARPROT),
    .DDR_AXI_ARVALID(HP0_S_AXI_ARVALID),
    .DDR_AXI_ARREADY(HP0_S_AXI_ARREADY),
    .DDR_AXI_RDATA(HP0_S_AXI_RDATA),
    .DDR_AXI_RRESP(HP0_S_AXI_RRESP),
    .DDR_AXI_RVALID(HP0_S_AXI_RVALID),
    .DDR_AXI_RREADY(HP0_S_AXI_RREADY),
    .DDR_AXI_AWLEN(HP0_S_AXI_AWLEN),
    .DDR_AXI_RLAST(HP0_S_AXI_RLAST),
    .DDR_AXI_ARCACHE(HP0_S_AXI_ARCACHE),
    .DDR_AXI_AWSIZE(HP0_S_AXI_AWSIZE),
    .DDR_AXI_AWBURST(HP0_S_AXI_AWBURST),
    .DDR_AXI_AWCACHE(HP0_S_AXI_AWCACHE),
    .DDR_AXI_WLAST(HP0_S_AXI_WLAST),
    .DDR_AXI_ARLEN(HP0_S_AXI_ARLEN),
    .DDR_AXI_ARBURST(HP0_S_AXI_ARBURST),
    .DDR_AXI_ARSIZE(HP0_S_AXI_ARSIZE),

    .h2s_tdata(h2s_tdata),
    .h2s_tlast(h2s_tlast),
    .h2s_tvalid(h2s_tvalid),
    .h2s_tready(h2s_tready),

    .s2h_tdata(s2h_tdata),
    .s2h_tlast(s2h_tlast),
    .s2h_tvalid(s2h_tvalid),
    .s2h_tready(s2h_tready),

    .core_set_data(core_set_data),
    .core_set_addr(core_set_addr),
    .core_set_stb(core_set_stb),
    .core_rb_data(core_rb_data),

    .xbar_set_data(xbar_set_data),
    .xbar_set_addr(xbar_set_addr),
    .xbar_set_stb(xbar_set_stb),
    .xbar_rb_data(xbar_rb_data),
    .xbar_rb_addr(xbar_rb_addr),
    .xbar_rb_stb(xbar_rb_stb),

    .event_irq(stream_irq)
  );
  wire pps;

  wire clk_tcxo = TCXO_CLK; // 40 MHz

  wire [1:0] pps_select;

  /* A local pps signal is derived from the tcxo clock. If a referenc
   * at an appropriate rate (1 pps or 10 MHz) is present and selected
   * a digital control loop will be invoked to tune the vcxo and lock t
   * the reference.
   */

  wire is_10meg, is_pps, reflck, plllck; // reference status bits
  ppsloop ppslp
  (
    .reset(1'b0),
    .xoclk(clk_tcxo), .ppsgps(GPS_PPS), .ppsext(PPS_EXT_IN),
    .refsel(pps_select),
    .lpps(pps),
    .is10meg(is_10meg), .ispps(is_pps), .reflck(reflck), .plllck(plllck),
    .sclk(TCXO_DAC_SCLK), .mosi(TCXO_DAC_SDIN), .sync_n(TCXO_DAC_SYNCn),
    .dac_dflt(16'h7fff)
  );
  reg [3:0] tcxo_status, st_rsync;
  always @(posedge bus_clk) begin
    /* status signals originate from other than the bus_clk domain so re-sync
       before passing to e300_core
     */
    st_rsync <= {plllck, is_10meg, is_pps, reflck};
    tcxo_status <= st_rsync;
  end

  // E300 Core logic
  wire [31:0] debug;

  e310_core e310_core0
  (
    .bus_clk(bus_clk),
    .bus_rst(bus_rst),

    .h2s_tdata(h2s_tdata),
    .h2s_tlast(h2s_tlast),
    .h2s_tvalid(h2s_tvalid),
    .h2s_tready(h2s_tready),

    .s2h_tdata(s2h_tdata),
    .s2h_tlast(s2h_tlast),
    .s2h_tvalid(s2h_tvalid),
    .s2h_tready(s2h_tready),

    .radio_clk(radio_clk),
    .radio_rst(radio_rst),
    // flip them to match case
    // this is a hack
    .rx_data0(rx_data1),
    .tx_data0(tx_data1),
    .rx_data1(rx_data0),
    .tx_data1(tx_data0),

    // flip them, to match
    // case ... this is a hack
    .ctrl_out0(gpio1),
    .ctrl_out1(gpio0),

    .fp_gpio_in(fp_gpio_in),
    .fp_gpio_out(fp_gpio_out),
    .fp_gpio_ddr(fp_gpio_ddr),

    .set_data(core_set_data),
    .set_addr(core_set_addr),
    .set_stb(core_set_stb),
    .rb_data(core_rb_data),

    .xbar_set_data(xbar_set_data),
    .xbar_set_addr(xbar_set_addr),
    .xbar_set_stb(xbar_set_stb),
    .xbar_rb_data(xbar_rb_data),
    .xbar_rb_addr(xbar_rb_addr),
    .xbar_rb_stb(xbar_rb_stb),

    .pps_select(pps_select),
    .pps(pps),
    .tcxo_status(tcxo_status),

    .lock_signals(CAT_CTRL_OUT[7:6]),
    .mimo(mimo),
    .codec_arst(codec_arst),
    .tx_bandsel(TX_BANDSEL),
    .rx_bandsel_a({RX2_BANDSEL, RX1_BANDSEL}),
    .rx_bandsel_b({RX2B_BANDSEL, RX1B_BANDSEL}),
    .rx_bandsel_c({RX2C_BANDSEL, RX1C_BANDSEL}),
`ifdef DRAM_TEST
    .debug(),
    .debug_in(debug)
`else /* DRAM_TEST */
    .debug()
`endif /* DRAM_TEST */
  );

  // PL DRAM Test
  `ifdef DRAM_TEST

  wire tg_compare_error;
  wire tg_compare_error_sync;
  reg tg_compare_error_latch;
  wire init_calib_complete;
  wire init_calib_complete_sync;

  always @(posedge bus_clk)
    if (bus_rst)
      tg_compare_error_latch <= 1'b0;
    else
      // If an error ever occurs, latch it but only after initialization has completed
      if (tg_compare_error_sync && init_calib_complete_sync)
        tg_compare_error_latch <= 1'b1;

  synchronizer #(.INITIAL_VAL(1'b0)) sync_init_calib_complete
  (
    .clk(bus_clk),
    .rst(bus_rst),
    .in(init_calib_complete),
    .out(init_calib_complete_sync)
  );

  synchronizer #(.INITIAL_VAL(1'b0)) sync_tg_compare_error
  (
    .clk(bus_clk),
    .rst(bus_rst),
    .in(tg_compare_error),
    .out(tg_compare_error_sync)
  );

  // Asserted (and latched) if an error occured
  assign debug[0] = tg_compare_error_latch;
  assign debug[1] = init_calib_complete_sync;

  example_top inst_example_top
  (
    .ddr3_dq                       (PL_DDR3_DQ),
    .ddr3_dqs_n                    (PL_DDR3_DQS_N),
    .ddr3_dqs_p                    (PL_DDR3_DQS_P),
    .ddr3_addr                     (PL_DDR3_ADDR),
    .ddr3_ba                       (PL_DDR3_BA),
    .ddr3_ras_n                    (PL_DDR3_RAS_n),
    .ddr3_cas_n                    (PL_DDR3_CAS_n),
    .ddr3_we_n                     (PL_DDR3_WE_n),
    .ddr3_reset_n                  (PL_DDR3_RESET_n),
    .ddr3_ck_p                     (PL_DDR3_CK_P),
    .ddr3_ck_n                     (PL_DDR3_CK_N),
    .ddr3_cke                      (PL_DDR3_CKE),
    .ddr3_dm                       (PL_DDR3_DM),
    .ddr3_odt                      (PL_DDR3_ODT),
    .sys_clk_i                     (PL_DDR3_SYSCLK),
    .clk_ref_i                     (pl_dram_clk),
    .tg_compare_error              (tg_compare_error),
    .init_calib_complete           (init_calib_complete),
    .sys_rst                       (pl_dram_rst)
  );

  `endif /* DRAM_TEST */

endmodule // e300
