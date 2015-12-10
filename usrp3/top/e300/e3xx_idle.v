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

  //AVR SPI IO
  input         AVR_CS_R,
  output        AVR_IRQ,
  output        AVR_MISO_R,
  input         AVR_MOSI_R,
  input         AVR_SCK_R,

  input         ONSWITCH_DB,

  // pps connections
  input         GPS_PPS,
  input         PPS_EXT_IN,

  // gpios
  inout [5:0]   PL_GPIO,

  // RF Board connections
  inout [99:0] DB_IO
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
  wire [3:0]  GP0_M_AXI_RRESP_S0;
  wire        GP0_M_AXI_RVALID_S0;
  wire        GP0_M_AXI_RREADY_S0;
  wire [31:0] GP0_M_AXI_AWADDR_S1;
  wire        GP0_M_AXI_AWVALID_S1;
  wire        GP0_M_AXI_AWREADY_S1;
  wire [31:0] GP0_M_AXI_WDATA_S1;
  wire [1:0]  GP0_M_AXI_WSTRB_S1;
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
  wire [31:0] GP0_M_AXI_AWADDR_S2;
  wire        GP0_M_AXI_AWVALID_S2;
  wire        GP0_M_AXI_AWREADY_S2;
  wire [31:0] GP0_M_AXI_WDATA_S2;
  wire [1:0]  GP0_M_AXI_WSTRB_S2;
  wire        GP0_M_AXI_WVALID_S2;
  wire        GP0_M_AXI_WREADY_S2;
  wire [1:0]  GP0_M_AXI_BRESP_S2;
  wire        GP0_M_AXI_BVALID_S2;
  wire        GP0_M_AXI_BREADY_S2;
  wire [31:0] GP0_M_AXI_ARADDR_S2;
  wire        GP0_M_AXI_ARVALID_S2;
  wire        GP0_M_AXI_ARREADY_S2;
  wire [31:0] GP0_M_AXI_RDATA_S2;
  wire [1:0]  GP0_M_AXI_RRESP_S2;
  wire        GP0_M_AXI_RVALID_S2;
  wire        GP0_M_AXI_RREADY_S2;

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

  wire        bus_clk;
  wire        bus_rst;

  wire [31:0] ps_gpio_out;
  wire [31:0] ps_gpio_in;

  wire pmu_irq;

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

  axi_dummy #(.DEC_ERR(1'b0)) inst_axi_dummy
  (
    .s_axi_aclk(bus_clk),
    .s_axi_areset(bus_rst),

    .s_axi_awaddr(GP0_M_AXI_AWADDR_S0),
    .s_axi_awvalid(GP0_M_AXI_AWVALID_S0),
    .s_axi_awready(GP0_M_AXI_AWREADY_S0),

    .s_axi_wdata(GP0_M_AXI_WDATA_S0),
    .s_axi_wstrb(GP0_M_AXI_WSTRB_S0),
    .s_axi_wvalid(GP0_M_AXI_WVALID_S0),
    .s_axi_wready(GP0_M_AXI_WREADY_S0),

    .s_axi_bresp(GP0_M_AXI_BRESP_S0),
    .s_axi_bvalid(GP0_M_AXI_BVALID_S0),
    .s_axi_bready(GP0_M_AXI_BREADY_S0),

    .s_axi_araddr(GP0_M_AXI_ARADDR_S0),
    .s_axi_arvalid(GP0_M_AXI_ARVALID_S0),
    .s_axi_arready(GP0_M_AXI_ARREADY_S0),

    .s_axi_rdata(GP0_M_AXI_RDATA_S0),
    .s_axi_rresp(GP0_M_AXI_RRESP_S0),
    .s_axi_rvalid(GP0_M_AXI_RVALID_S0),
    .s_axi_rready(GP0_M_AXI_RREADY_S0)
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

  // First, make all connections to the PS (ARM+buses)
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
    .IRQ_F2P({12'h0, pmu_irq, button_release_irq, button_press_irq, 1'b0}),
    .GPIO_I(ps_gpio_in),
    .GPIO_O(ps_gpio_out),
    .FCLK_CLK0(fclk_clk0),
    .FCLK_RESET0(fclk_reset0),

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
    .SPI0_SS1(),
    .SPI0_SS2(),
    .SPI0_SCLK(),
    .SPI0_MOSI(),
    .SPI0_MISO(),

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
  assign bus_clk = fclk_clk0;
  assign bus_rst = fclk_reset0;

  assign PL_GPIO = 6'b00_0000;

  assign AVR_IRQ = 1'b0;

  //------------------------------------------------------------------
  //-- idle magic
  //   the idea here is that u-boot sets this up after inspecting
  //   the product value in the eeprom,
  //   if board comes up as unknown, we play it safe
  //   and tristate all the things
  //------------------------------------------------------------------

  wire is_e33x = ps_gpio_out[9]; /* GPIO 63 in sw */
  wire is_safe = ps_gpio_out[10]; /* GPIO 64 in sw */

  localparam DB_E31X_IDLE_OUT = {
    1'b0,              /* DB_EXP_18_24 (99) */
    13'b0000000000000, /* leds & rx bandsels */
    1'b0,              /* CAT_FB_CLK (85) */
    1'b0,              /* CAT_TX_FRAME (84) */
    1'b0,              /* CAT_RX_DATA_CLK (83) */
    25'b0000_0000_0000_0000_0000_0000_0, /* CAT_RX_FRAME(81), CAT_P0 & CAT_P1 (58)*/
    1'b0,              /* CAT_SYNC(57) */
    4'b0000,           /* CAT_ENAGC(56), CAT_BBCLK_OUT (55), CAT_ENABLE(54), CAT_TXNRX(53) */
    3'b000,            /* DB_EXP_1_8_V_{33,34,32} */
    2'b00,             /* CAT_CTRL_IN[1:0] (49,48) */
    1'b0,              /* CAT_MISO (47) */
    4'b0000,           /* CAT_{MOSI,SCLK,CS,RESETn) (46,45, 44, 43) */
    1'b0,              /* DB_1_8V_31 (42) */
    8'h00,             /* CAT_CTRL_OUT (41:34) */
    1'b0,              /* DB_1_8V_11 (33) */
    1'b0,              /* CAT_CTRL_IN3 (32) */
    1'b0,              /* DB_1_8V_10 (31) */
    1'b0,              /* CAT_CTRL_IN2 (30) */
    1'b0,              /* DB_1_8V_9 (29) */
    1'b0,              /* VCRX2_V2 (28) */
    1'b0,              /* DB_1_8V_8 (25) */
    1'b0,              /* VCRX2_V1 (26) */
    1'b0,              /* DB_1_8V_7 (25) */
    1'b0,              /* VCRX1_V2 (24) */
    1'b0,              /* DB_1_8V_6 (23) */
    1'b0,              /* VCRX1_V1 (22) */
    1'b0,              /* DB_1_8V_5 (21) */
    1'b0,              /* VCTXRX1_V2 (20) */
    1'b0,              /* DB_1_8V_4 (19) */
    1'b0,              /* VCTXRX1_V1 (18) */
    1'b0,              /* DB_1_8V_3 (17) */
    1'b0,              /* VCTXRX2_V1 (16) */
    1'b1,              /* DB_1_8V_2 (15) */
    15'd0};

  localparam DB_E31X_IDLE_DDR = {
    1'b0,              /* DB_EXP_18_24 (99) */
    13'b0101010101010, /* leds & rx bandsels */
    1'b0,              /* CAT_FB_CLK (85) */
    1'b0,              /* CAT_TX_FRAME (84) */
    1'b0,              /* CAT_RX_DATA_CLK (83) */
    25'b0000_0000_0000_0000_0000_0000_0, /* CAT_RX_FRAME(81), CAT_P0 & CAT_P1 (58) */
    1'b0,              /* CAT_SYNC(57) */
    4'b0001,           /* CAT_ENAGC(56), CAT_BBCLK_OUT (55), CAT_ENABLE(54), CAT_TXNRX(53) */
    3'b000,            /* DB_EXP_1_8_V_{32,33,34,} (52, 51, 50) */
    2'b00,             /* CAT_CTRL_IN[1:0] (49,48) */
    1'b0,              /* CAT_MISO (47) */
    4'b0111,           /* CAT_{MOSI,SCLK,CS,RESETn) (46, 45, 44, 43) */
    1'b0,              /* DB_1_8V_31 (42) */
    8'h00,             /* CAT_CTRL_OUT (41:34) */
    1'b0,              /* DB_1_8V_11 (33) */
    1'b0,              /* CAT_CTRL_IN3 (32) */
    1'b0,              /* DB_1_8V_10 (31) */
    1'b0,              /* CAT_CTRL_IN2 (30) */
    1'b0,              /* DB_1_8V_9 (29) */
    1'b0,              /* VCRX2_V2 (28) */
    1'b0,              /* DB_1_8V_8 (25) */
    1'b0,              /* VCRX2_V1 (26) */
    1'b0,              /* DB_1_8V_7 (24) */
    1'b0,              /* VCRX1_V2 (24) */
    1'b0,              /* DB_1_8V_6 (23) */
    1'b0,              /* VCRX1_V1 (22) */
    1'b0,              /* DB_1_8V_5 (21) */
    1'b0,              /* VCTXRX1_V1 (20) */
    1'b0,              /* DB_1_8V_4 (19) */
    1'b0,              /* VCTXRX1_V2 (18) */
    1'b1,              /* DB_1_8V_3 (17) */
    1'b0,              /* VCTXRX2_V1 (16) */
    1'b1,              /* DB_1_8V_2 (15) */
    15'd0};

  localparam DB_E33X_IDLE_OUT = 100'd0;
  localparam DB_E33X_IDLE_DDR = 100'd0;

  localparam DB_E3XX_SAFE_DDR = 100'd0;

  localparam NUM_DB_IO_PINS   = 100;

  wire [NUM_DB_IO_PINS-1:0] db_ddr = is_safe ? is_e33x ? DB_E33X_IDLE_DDR : DB_E31X_IDLE_DDR : DB_E3XX_SAFE_DDR;
  wire [NUM_DB_IO_PINS-1:0] db_out = is_e33x ? DB_E33X_IDLE_OUT : DB_E31X_IDLE_OUT;
  wire [NUM_DB_IO_PINS-1:0] db_in;


  genvar k;
  generate
    for (k = 0; k < NUM_DB_IO_PINS; k = k+1) begin
      IOBUF db_io_i(.O(db_in[k]), .IO(DB_IO[k]), .I(db_out[k]), .T(~db_ddr[k]));
    end
  endgenerate

endmodule // e300
