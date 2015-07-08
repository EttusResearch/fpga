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
  //   GP0 -- General Purpose port 0, FPGA is slave 0
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
  //   GP0 -- General Purpose port 0, FPGA is slave 1
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
  wire [31:0] HP0_S_AXI_AWADDR_M0;
  wire [2:0]  HP0_S_AXI_AWPROT_M0;
  wire        HP0_S_AXI_AWVALID_M0;
  wire        HP0_S_AXI_AWREADY_M0;
  wire [63:0] HP0_S_AXI_WDATA_M0;
  wire [7:0]  HP0_S_AXI_WSTRB_M0;
  wire        HP0_S_AXI_WVALID_M0;
  wire        HP0_S_AXI_WREADY_M0;
  wire [1:0]  HP0_S_AXI_BRESP_M0;
  wire        HP0_S_AXI_BVALID_M0;
  wire        HP0_S_AXI_BREADY_M0;
  wire [31:0] HP0_S_AXI_ARADDR_M0;
  wire [2:0]  HP0_S_AXI_ARPROT_M0;
  wire        HP0_S_AXI_ARVALID_M0;
  wire        HP0_S_AXI_ARREADY_M0;
  wire [63:0] HP0_S_AXI_RDATA_M0;
  wire [1:0]  HP0_S_AXI_RRESP_M0;
  wire        HP0_S_AXI_RVALID_M0;
  wire        HP0_S_AXI_RREADY_M0;
  wire [3:0]  HP0_S_AXI_ARCACHE_M0;
  wire [7:0]  HP0_S_AXI_AWLEN_M0;
  wire [2:0]  HP0_S_AXI_AWSIZE_M0;
  wire [1:0]  HP0_S_AXI_AWBURST_M0;
  wire [3:0]  HP0_S_AXI_AWCACHE_M0;
  wire        HP0_S_AXI_WLAST_M0;
  wire [7:0]  HP0_S_AXI_ARLEN_M0;
  wire [1:0]  HP0_S_AXI_ARBURST_M0;
  wire [2:0]  HP0_S_AXI_ARSIZE_M0;

  wire        bus_clk_pin;

  wire        bus_clk, radio_clk;
  wire        bus_rst, radio_rst;
  wire        sys_arst, sys_arst_n;

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

  wire pmu_irq;

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
    .axi_ext_slave_conn_0_M_AXI_AWADDR_pin(GP0_M_AXI_AWADDR_S0),
    .axi_ext_slave_conn_0_M_AXI_AWVALID_pin(GP0_M_AXI_AWVALID_S0),
    .axi_ext_slave_conn_0_M_AXI_AWREADY_pin(GP0_M_AXI_AWREADY_S0),
    .axi_ext_slave_conn_0_M_AXI_WDATA_pin(GP0_M_AXI_WDATA_S0),
    .axi_ext_slave_conn_0_M_AXI_WSTRB_pin(GP0_M_AXI_WSTRB_S0),
    .axi_ext_slave_conn_0_M_AXI_WVALID_pin(GP0_M_AXI_WVALID_S0),
    .axi_ext_slave_conn_0_M_AXI_WREADY_pin(GP0_M_AXI_WREADY_S0),
    .axi_ext_slave_conn_0_M_AXI_BRESP_pin(GP0_M_AXI_BRESP_S0),
    .axi_ext_slave_conn_0_M_AXI_BVALID_pin(GP0_M_AXI_BVALID_S0),
    .axi_ext_slave_conn_0_M_AXI_BREADY_pin(GP0_M_AXI_BREADY_S0),
    .axi_ext_slave_conn_0_M_AXI_ARADDR_pin(GP0_M_AXI_ARADDR_S0),
    .axi_ext_slave_conn_0_M_AXI_ARVALID_pin(GP0_M_AXI_ARVALID_S0),
    .axi_ext_slave_conn_0_M_AXI_ARREADY_pin(GP0_M_AXI_ARREADY_S0),
    .axi_ext_slave_conn_0_M_AXI_RDATA_pin(GP0_M_AXI_RDATA_S0),
    .axi_ext_slave_conn_0_M_AXI_RRESP_pin(GP0_M_AXI_RRESP_S0),
    .axi_ext_slave_conn_0_M_AXI_RVALID_pin(GP0_M_AXI_RVALID_S0),
    .axi_ext_slave_conn_0_M_AXI_RREADY_pin(GP0_M_AXI_RREADY_S0),

    .axi_ext_slave_conn_1_M_AXI_AWADDR_pin(GP0_M_AXI_AWADDR_S1),
    .axi_ext_slave_conn_1_M_AXI_AWVALID_pin(GP0_M_AXI_AWVALID_S1),
    .axi_ext_slave_conn_1_M_AXI_AWREADY_pin(GP0_M_AXI_AWREADY_S1),
    .axi_ext_slave_conn_1_M_AXI_WDATA_pin(GP0_M_AXI_WDATA_S1),
    .axi_ext_slave_conn_1_M_AXI_WSTRB_pin(GP0_M_AXI_WSTRB_S1),
    .axi_ext_slave_conn_1_M_AXI_WVALID_pin(GP0_M_AXI_WVALID_S1),
    .axi_ext_slave_conn_1_M_AXI_WREADY_pin(GP0_M_AXI_WREADY_S1),
    .axi_ext_slave_conn_1_M_AXI_BRESP_pin(GP0_M_AXI_BRESP_S1),
    .axi_ext_slave_conn_1_M_AXI_BVALID_pin(GP0_M_AXI_BVALID_S1),
    .axi_ext_slave_conn_1_M_AXI_BREADY_pin(GP0_M_AXI_BREADY_S1),
    .axi_ext_slave_conn_1_M_AXI_ARADDR_pin(GP0_M_AXI_ARADDR_S1),
    .axi_ext_slave_conn_1_M_AXI_ARVALID_pin(GP0_M_AXI_ARVALID_S1),
    .axi_ext_slave_conn_1_M_AXI_ARREADY_pin(GP0_M_AXI_ARREADY_S1),
    .axi_ext_slave_conn_1_M_AXI_RDATA_pin(GP0_M_AXI_RDATA_S1),
    .axi_ext_slave_conn_1_M_AXI_RRESP_pin(GP0_M_AXI_RRESP_S1),
    .axi_ext_slave_conn_1_M_AXI_RVALID_pin(GP0_M_AXI_RVALID_S1),
    .axi_ext_slave_conn_1_M_AXI_RREADY_pin(GP0_M_AXI_RREADY_S1),

    //    Misc interrupts, GPIO, clk
    .processing_system7_0_IRQ_F2P_pin({12'h0, pmu_irq, button_release_irq, button_press_irq, stream_irq}),
    .processing_system7_0_GPIO_I_pin(ps_gpio_in),
    .processing_system7_0_GPIO_O_pin(ps_gpio_out),
    .processing_system7_0_FCLK_CLK0_pin(bus_clk_pin),
    .processing_system7_0_FCLK_RESET0_N_pin(sys_arst_n),

    //    HP0  --  High Performance Master 0
    .axi_ext_master_conn_0_S_AXI_AWADDR_pin(HP0_S_AXI_AWADDR_M0),
    .axi_ext_master_conn_0_S_AXI_AWPROT_pin(HP0_S_AXI_AWPROT_M0),
    .axi_ext_master_conn_0_S_AXI_AWVALID_pin(HP0_S_AXI_AWVALID_M0),
    .axi_ext_master_conn_0_S_AXI_AWREADY_pin(HP0_S_AXI_AWREADY_M0),
    .axi_ext_master_conn_0_S_AXI_WDATA_pin(HP0_S_AXI_WDATA_M0),
    .axi_ext_master_conn_0_S_AXI_WSTRB_pin(HP0_S_AXI_WSTRB_M0),
    .axi_ext_master_conn_0_S_AXI_WVALID_pin(HP0_S_AXI_WVALID_M0),
    .axi_ext_master_conn_0_S_AXI_WREADY_pin(HP0_S_AXI_WREADY_M0),
    .axi_ext_master_conn_0_S_AXI_BRESP_pin(HP0_S_AXI_BRESP_M0),
    .axi_ext_master_conn_0_S_AXI_BVALID_pin(HP0_S_AXI_BVALID_M0),
    .axi_ext_master_conn_0_S_AXI_BREADY_pin(HP0_S_AXI_BREADY_M0),
    .axi_ext_master_conn_0_S_AXI_ARADDR_pin(HP0_S_AXI_ARADDR_M0),
    .axi_ext_master_conn_0_S_AXI_ARPROT_pin(HP0_S_AXI_ARPROT_M0),
    .axi_ext_master_conn_0_S_AXI_ARVALID_pin(HP0_S_AXI_ARVALID_M0),
    .axi_ext_master_conn_0_S_AXI_ARREADY_pin(HP0_S_AXI_ARREADY_M0),
    .axi_ext_master_conn_0_S_AXI_RDATA_pin(HP0_S_AXI_RDATA_M0),
    .axi_ext_master_conn_0_S_AXI_RRESP_pin(HP0_S_AXI_RRESP_M0),
    .axi_ext_master_conn_0_S_AXI_RVALID_pin(HP0_S_AXI_RVALID_M0),
    .axi_ext_master_conn_0_S_AXI_RREADY_pin(HP0_S_AXI_RREADY_M0),
    .axi_ext_master_conn_0_S_AXI_AWLEN_pin(HP0_S_AXI_AWLEN_M0),
    .axi_ext_master_conn_0_S_AXI_RLAST_pin(HP0_S_AXI_RLAST_M0),
    .axi_ext_master_conn_0_S_AXI_ARCACHE_pin(HP0_S_AXI_ARCACHE_M0),
    .axi_ext_master_conn_0_S_AXI_AWSIZE_pin(HP0_S_AXI_AWSIZE_M0),
    .axi_ext_master_conn_0_S_AXI_AWBURST_pin(HP0_S_AXI_AWBURST_M0),
    .axi_ext_master_conn_0_S_AXI_AWCACHE_pin(HP0_S_AXI_AWCACHE_M0),
    .axi_ext_master_conn_0_S_AXI_WLAST_pin(HP0_S_AXI_WLAST_M0),
    .axi_ext_master_conn_0_S_AXI_ARLEN_pin(HP0_S_AXI_ARLEN_M0),
    .axi_ext_master_conn_0_S_AXI_ARBURST_pin(HP0_S_AXI_ARBURST_M0),
    .axi_ext_master_conn_0_S_AXI_ARSIZE_pin(HP0_S_AXI_ARSIZE_M0),

    //    SPI Core 0 - To AD9361
    .processing_system7_0_SPI0_SS_O_pin(),
    .processing_system7_0_SPI0_SS1_O_pin(CAT_CS),
    .processing_system7_0_SPI0_SS2_O_pin(),
    .processing_system7_0_SPI0_SCLK_O_pin(CAT_SCLK),
    .processing_system7_0_SPI0_MOSI_O_pin(CAT_MOSI),
    .processing_system7_0_SPI0_MISO_I_pin(CAT_MISO),

    //    SPI Core 1 - To AVR
    .processing_system7_0_SPI1_SS_O_pin(),
    .processing_system7_0_SPI1_SS1_O_pin(),
    .processing_system7_0_SPI1_SS2_O_pin(),
    .processing_system7_0_SPI1_SCLK_O_pin(),
    .processing_system7_0_SPI1_MOSI_O_pin(),
    .processing_system7_0_SPI1_MISO_I_pin()
  );
  //------------------------------------------------------------------
  //-- power management
  //------------------------------------------------------------------

  axi_pmu inst_axi_pmu0
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

  assign AVR_IRQ = 1'b0;

  //------------------------------------------------------------------
  //-- generate clock and reset signals
  //------------------------------------------------------------------

  assign sys_arst = ~sys_arst_n;

  reset_sync radio_rst_sync
  (
    .clk(radio_clk),
    .reset_in(sys_arst),
    .reset_out(radio_rst)
  );

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

  assign CAT_RESET = ~(sys_arst || (CAT_CS & CAT_MOSI));   // Operates active-low, really CAT_RESET_B
  assign CAT_SYNC = 1'b0;

  //------------------------------------------------------------------
  //-- connect misc stuff to user GPIO
  //------------------------------------------------------------------
  assign ps_gpio_in[7] = ONSWITCH_DB;   //61

  //------------------------------------------------------------------
  //-- radio core from x300 for super fast bring up
  //------------------------------------------------------------------

  wire [31:0] gpio0, gpio1;

  assign { LED_TXRX1_TX, LED_TXRX1_RX, LED_RX1_RX, //3
           VCRX1_V2, VCRX1_V1, VCTXRX1_V2, VCTXRX1_V1, //4
           TX_ENABLE1B, TX_ENABLE1A //2
         } = gpio0[18:10];

  assign { LED_TXRX2_TX, LED_TXRX2_RX, LED_RX2_RX, //3
           VCRX2_V2, VCRX2_V1, VCTXRX2_V2, VCTXRX2_V1, //4
           TX_ENABLE2B, TX_ENABLE2A //2
         } = gpio1[18:10];

  //------------------------------------------------------------------
  //-- Zynq system interface, DMA, control channels, etc.
  //------------------------------------------------------------------

  wire [31:0] core_set_data, core_rb_data, xbar_set_data, xbar_rb_data;
  wire [31:0] core_set_addr, xbar_set_addr, xbar_rb_addr;
  wire        core_stb, xbar_set_stb, xbar_rb_stb;

  zynq_fifo_top
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
    .clk(bus_clk),
    .rst(bus_rst),
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

    .DDR_AXI_AWADDR(HP0_S_AXI_AWADDR_M0),
    .DDR_AXI_AWPROT(HP0_S_AXI_AWPROT_M0),
    .DDR_AXI_AWVALID(HP0_S_AXI_AWVALID_M0),
    .DDR_AXI_AWREADY(HP0_S_AXI_AWREADY_M0),
    .DDR_AXI_WDATA(HP0_S_AXI_WDATA_M0),
    .DDR_AXI_WSTRB(HP0_S_AXI_WSTRB_M0),
    .DDR_AXI_WVALID(HP0_S_AXI_WVALID_M0),
    .DDR_AXI_WREADY(HP0_S_AXI_WREADY_M0),
    .DDR_AXI_BRESP(HP0_S_AXI_BRESP_M0),
    .DDR_AXI_BVALID(HP0_S_AXI_BVALID_M0),
    .DDR_AXI_BREADY(HP0_S_AXI_BREADY_M0),
    .DDR_AXI_ARADDR(HP0_S_AXI_ARADDR_M0),
    .DDR_AXI_ARPROT(HP0_S_AXI_ARPROT_M0),
    .DDR_AXI_ARVALID(HP0_S_AXI_ARVALID_M0),
    .DDR_AXI_ARREADY(HP0_S_AXI_ARREADY_M0),
    .DDR_AXI_RDATA(HP0_S_AXI_RDATA_M0),
    .DDR_AXI_RRESP(HP0_S_AXI_RRESP_M0),
    .DDR_AXI_RVALID(HP0_S_AXI_RVALID_M0),
    .DDR_AXI_RREADY(HP0_S_AXI_RREADY_M0),
    .DDR_AXI_AWLEN(HP0_S_AXI_AWLEN_M0),
    .DDR_AXI_RLAST(HP0_S_AXI_RLAST_M0),
    .DDR_AXI_ARCACHE(HP0_S_AXI_ARCACHE_M0),
    .DDR_AXI_AWSIZE(HP0_S_AXI_AWSIZE_M0),
    .DDR_AXI_AWBURST(HP0_S_AXI_AWBURST_M0),
    .DDR_AXI_AWCACHE(HP0_S_AXI_AWCACHE_M0),
    .DDR_AXI_WLAST(HP0_S_AXI_WLAST_M0),
    .DDR_AXI_ARLEN(HP0_S_AXI_ARLEN_M0),
    .DDR_AXI_ARBURST(HP0_S_AXI_ARBURST_M0),
    .DDR_AXI_ARSIZE(HP0_S_AXI_ARSIZE_M0),

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

  e300_core e300_core0
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

    .fp_gpio(PL_GPIO),

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
    .debug()
  );

  //------------------------------------------------------------------
  //-- chipscope debugs
  //------------------------------------------------------------------
  /*
  wire [35:0] CONTROL;
  wire [255:0] DATA;
  wire [7:0] TRIG;

  chipscope_icon chipscope_icon(.CONTROL0(CONTROL));
  chipscope_ila chipscope_ila
  (
      .CONTROL(CONTROL), .CLK(bus_clk),
      .DATA(DATA), .TRIG0(TRIG)
  );

  assign DATA[63:0] = h2s_tdata;
  assign TRIG = {
      h2s_tlast, h2s_tvalid, h2s_tready, 1'b0,
      4'b0
  };
  assign DATA[64] = h2s_tlast;
  assign DATA[65] = h2s_tvalid;
  assign DATA[66] = h2s_tready;
  */

endmodule // e300
