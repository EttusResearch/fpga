//
// Copyright 2014 Ettus Research
//

module e300_processing_system (
  inout [53:0]      MIO,
  input             PS_SRSTB,
  input             PS_CLK,
  input             PS_PORB,
  inout             DDR_Clk,
  inout             DDR_Clk_n,
  inout             DDR_CKE,
  inout             DDR_CS_n,
  inout             DDR_RAS_n,
  inout             DDR_CAS_n,
  inout             DDR_WEB,
  inout [2:0]       DDR_BankAddr,
  inout [14:0]      DDR_Addr,
  inout             DDR_ODT,
  inout             DDR_DRSTB,
  inout [31:0]      DDR_DQ,
  inout [3:0]       DDR_DM,
  inout [3:0]       DDR_DQS,
  inout [3:0]       DDR_DQS_n,
  inout             DDR_VRP,
  inout             DDR_VRN,
  input [5:0]       S_AXI_HP0_AWID,
  input [31:0]      S_AXI_HP0_AWADDR,
  input [2:0]       S_AXI_HP0_AWPROT,
  input             S_AXI_HP0_AWVALID,
  output            S_AXI_HP0_AWREADY,
  input [63:0]      S_AXI_HP0_WDATA,
  input [7:0]       S_AXI_HP0_WSTRB,
  input             S_AXI_HP0_WVALID,
  output            S_AXI_HP0_WREADY,
  output [1:0]      S_AXI_HP0_BRESP,
  output            S_AXI_HP0_BVALID,
  input             S_AXI_HP0_BREADY,
  input [5:0]       S_AXI_HP0_ARID,
  input [31:0]      S_AXI_HP0_ARADDR,
  input [2:0]       S_AXI_HP0_ARPROT,
  input             S_AXI_HP0_ARVALID,
  output            S_AXI_HP0_ARREADY,
  output [63:0]     S_AXI_HP0_RDATA,
  output [1:0]      S_AXI_HP0_RRESP,
  output            S_AXI_HP0_RVALID,
  input             S_AXI_HP0_RREADY,
  input [7:0]       S_AXI_HP0_AWLEN,
  output            S_AXI_HP0_RLAST,
  input [3:0]       S_AXI_HP0_ARCACHE,
  input [2:0]       S_AXI_HP0_AWSIZE,
  input [1:0]       S_AXI_HP0_AWBURST,
  input [3:0]       S_AXI_HP0_AWCACHE,
  input             S_AXI_HP0_WLAST,
  input [7:0]       S_AXI_HP0_ARLEN,
  input [1:0]       S_AXI_HP0_ARBURST,
  input [2:0]       S_AXI_HP0_ARSIZE,
  output [31:0]     M_AXI_GP0_AWADDR,
  output            M_AXI_GP0_AWVALID,
  input             M_AXI_GP0_AWREADY,
  output [31:0]     M_AXI_GP0_WDATA,
  output [3:0]      M_AXI_GP0_WSTRB,
  output            M_AXI_GP0_WVALID,
  input             M_AXI_GP0_WREADY,
  input [1:0]       M_AXI_GP0_BRESP,
  input             M_AXI_GP0_BVALID,
  output            M_AXI_GP0_BREADY,
  output [31:0]     M_AXI_GP0_ARADDR,
  output            M_AXI_GP0_ARVALID,
  input             M_AXI_GP0_ARREADY,
  input [31:0]      M_AXI_GP0_RDATA,
  input [1:0]       M_AXI_GP0_RRESP,
  input             M_AXI_GP0_RVALID,
  output            M_AXI_GP0_RREADY,
  input [15:0]      IRQ_F2P,
  input [31:0]      GPIO_I,
  output [31:0]     GPIO_O,
  output            FCLK_CLK0,
  output            FCLK_RESET0,
  output            FCLK_CLK1,
  output            FCLK_RESET1,
  output            FCLK_CLK2,
  output            FCLK_RESET2,
  output            FCLK_CLK3,
  output            FCLK_RESET3,
  output            PL_DRAM_CLK,
  output            PL_DRAM_RST,
  output            SPI0_SS,
  output            SPI0_SS1,
  output            SPI0_SS2,
  output            SPI0_SCLK,
  output            SPI0_MOSI,
  input             SPI0_MISO,
  output            SPI1_SS,
  output            SPI1_SS1,
  output            SPI1_SS2,
  output            SPI1_SCLK,
  output            SPI1_MOSI,
  input             SPI1_MISO);

  wire              processing_system7_M_AXI_GP0_ARVALID;
  wire              processing_system7_M_AXI_GP0_AWVALID;
  wire              processing_system7_M_AXI_GP0_BREADY;
  wire              processing_system7_M_AXI_GP0_RREADY;
  wire              processing_system7_M_AXI_GP0_WLAST;
  wire              processing_system7_M_AXI_GP0_WVALID;
  wire [11:0]       processing_system7_M_AXI_GP0_ARID;
  wire [11:0]       processing_system7_M_AXI_GP0_AWID;
  wire [11:0]       processing_system7_M_AXI_GP0_WID;
  wire [1:0]        processing_system7_M_AXI_GP0_ARBURST;
  wire [1:0]        processing_system7_M_AXI_GP0_ARLOCK;
  wire [2:0]        processing_system7_M_AXI_GP0_ARSIZE;
  wire [1:0]        processing_system7_M_AXI_GP0_AWBURST;
  wire [1:0]        processing_system7_M_AXI_GP0_AWLOCK;
  wire [2:0]        processing_system7_M_AXI_GP0_AWSIZE;
  wire [2:0]        processing_system7_M_AXI_GP0_ARPROT;
  wire [2:0]        processing_system7_M_AXI_GP0_AWPROT;
  wire [31:0]       processing_system7_M_AXI_GP0_ARADDR;
  wire [31:0]       processing_system7_M_AXI_GP0_AWADDR;
  wire [31:0]       processing_system7_M_AXI_GP0_WDATA;
  wire [3:0]        processing_system7_M_AXI_GP0_ARCACHE;
  wire [3:0]        processing_system7_M_AXI_GP0_ARLEN;
  wire [3:0]        processing_system7_M_AXI_GP0_ARQOS;
  wire [3:0]        processing_system7_M_AXI_GP0_AWCACHE;
  wire [3:0]        processing_system7_M_AXI_GP0_AWLEN;
  wire [3:0]        processing_system7_M_AXI_GP0_AWQOS;
  wire [3:0]        processing_system7_M_AXI_GP0_WSTRB;
  wire              processing_system7_M_AXI_GP0_ARREADY;
  wire              processing_system7_M_AXI_GP0_AWREADY;
  wire              processing_system7_M_AXI_GP0_BVALID;
  wire              processing_system7_M_AXI_GP0_RLAST;
  wire              processing_system7_M_AXI_GP0_RVALID;
  wire              processing_system7_M_AXI_GP0_WREADY;
  wire [11:0]       processing_system7_M_AXI_GP0_BID;
  wire [11:0]       processing_system7_M_AXI_GP0_RID;
  wire [1:0]        processing_system7_M_AXI_GP0_BRESP;
  wire [1:0]        processing_system7_M_AXI_GP0_RRESP;
  wire [31:0]       processing_system7_M_AXI_GP0_RDATA;
  wire              processing_system7_S_AXI_HP0_ARREADY;
  wire              processing_system7_S_AXI_HP0_AWREADY;
  wire              processing_system7_S_AXI_HP0_BVALID;
  wire              processing_system7_S_AXI_HP0_RLAST;
  wire              processing_system7_S_AXI_HP0_RVALID;
  wire              processing_system7_S_AXI_HP0_WREADY;
  wire [1:0]        processing_system7_S_AXI_HP0_BRESP;
  wire [1:0]        processing_system7_S_AXI_HP0_RRESP;
  wire [5:0]        processing_system7_S_AXI_HP0_BID;
  wire [5:0]        processing_system7_S_AXI_HP0_RID;
  wire [63:0]       processing_system7_S_AXI_HP0_RDATA;
  wire [7:0]        processing_system7_S_AXI_HP0_RCOUNT;
  wire [7:0]        processing_system7_S_AXI_HP0_WCOUNT;
  wire [2:0]        processing_system7_S_AXI_HP0_RACOUNT;
  wire [5:0]        processing_system7_S_AXI_HP0_WACOUNT;
  wire              processing_system7_S_AXI_HP0_ARVALID;
  wire              processing_system7_S_AXI_HP0_AWVALID;
  wire              processing_system7_S_AXI_HP0_BREADY;
  wire              processing_system7_S_AXI_HP0_RDISSUECAP1_EN;
  wire              processing_system7_S_AXI_HP0_RREADY;
  wire              processing_system7_S_AXI_HP0_WLAST;
  wire              processing_system7_S_AXI_HP0_WRISSUECAP1_EN;
  wire              processing_system7_S_AXI_HP0_WVALID;
  wire [1:0]        processing_system7_S_AXI_HP0_ARBURST;
  wire [1:0]        processing_system7_S_AXI_HP0_ARLOCK;
  wire [2:0]        processing_system7_S_AXI_HP0_ARSIZE;
  wire [1:0]        processing_system7_S_AXI_HP0_AWBURST;
  wire [1:0]        processing_system7_S_AXI_HP0_AWLOCK;
  wire [2:0]        processing_system7_S_AXI_HP0_AWSIZE;
  wire [2:0]        processing_system7_S_AXI_HP0_ARPROT;
  wire [2:0]        processing_system7_S_AXI_HP0_AWPROT;
  wire [31:0]       processing_system7_S_AXI_HP0_ARADDR;
  wire [31:0]       processing_system7_S_AXI_HP0_AWADDR;
  wire [3:0]        processing_system7_S_AXI_HP0_ARCACHE;
  wire [3:0]        processing_system7_S_AXI_HP0_ARLEN;
  wire [3:0]        processing_system7_S_AXI_HP0_ARQOS;
  wire [3:0]        processing_system7_S_AXI_HP0_AWCACHE;
  wire [3:0]        processing_system7_S_AXI_HP0_AWLEN;
  wire [3:0]        processing_system7_S_AXI_HP0_AWQOS;
  wire [5:0]        processing_system7_S_AXI_HP0_ARID;
  wire [5:0]        processing_system7_S_AXI_HP0_AWID;
  wire [5:0]        processing_system7_S_AXI_HP0_WID;
  wire [63:0]       processing_system7_S_AXI_HP0_WDATA;
  wire [7:0]        processing_system7_S_AXI_HP0_WSTRB;
  wire              processing_system7_FCLK_CLK0;
  wire              processing_system7_FCLK_RESET0_N;
  wire              processing_system7_FCLK_CLK1;
  wire              processing_system7_FCLK_RESET1_N;
  wire              processing_system7_FCLK_CLK2;
  wire              processing_system7_FCLK_RESET2_N;
  wire              processing_system7_FCLK_CLK3;
  wire              processing_system7_FCLK_RESET3_N;
  wire [5:0]        axi4_fifo_S_AXI_HP0_AWID;
  wire [31:0]       axi4_fifo_S_AXI_HP0_AWADDR;
  wire [7:0]        axi4_fifo_S_AXI_HP0_AWLEN;
  wire [2:0]        axi4_fifo_S_AXI_HP0_AWSIZE;
  wire [1:0]        axi4_fifo_S_AXI_HP0_AWBURST;
  wire [0:0]        axi4_fifo_S_AXI_HP0_AWLOCK;
  wire [3:0]        axi4_fifo_S_AXI_HP0_AWCACHE;
  wire [2:0]        axi4_fifo_S_AXI_HP0_AWPROT;
  wire [3:0]        axi4_fifo_S_AXI_HP0_AWREGION;
  wire [3:0]        axi4_fifo_S_AXI_HP0_AWQOS;
  wire              axi4_fifo_S_AXI_HP0_AWVALID;
  wire              axi4_fifo_S_AXI_HP0_AWREADY;
  wire [63:0]       axi4_fifo_S_AXI_HP0_WDATA;
  wire [7:0]        axi4_fifo_S_AXI_HP0_WSTRB;
  wire              axi4_fifo_S_AXI_HP0_WLAST;
  wire              axi4_fifo_S_AXI_HP0_WVALID;
  wire              axi4_fifo_S_AXI_HP0_WREADY;
  wire [5:0]        axi4_fifo_S_AXI_HP0_BID;
  wire [1:0]        axi4_fifo_S_AXI_HP0_BRESP;
  wire              axi4_fifo_S_AXI_HP0_BVALID;
  wire              axi4_fifo_S_AXI_HP0_BREADY;
  wire [5:0]        axi4_fifo_S_AXI_HP0_ARID;
  wire [31:0]       axi4_fifo_S_AXI_HP0_ARADDR;
  wire [7:0]        axi4_fifo_S_AXI_HP0_ARLEN;
  wire [2:0]        axi4_fifo_S_AXI_HP0_ARSIZE;
  wire [1:0]        axi4_fifo_S_AXI_HP0_ARBURST;
  wire [0:0]        axi4_fifo_S_AXI_HP0_ARLOCK;
  wire [3:0]        axi4_fifo_S_AXI_HP0_ARCACHE;
  wire [2:0]        axi4_fifo_S_AXI_HP0_ARPROT;
  wire [3:0]        axi4_fifo_S_AXI_HP0_ARREGION;
  wire [3:0]        axi4_fifo_S_AXI_HP0_ARQOS;
  wire              axi4_fifo_S_AXI_HP0_ARVALID;
  wire              axi4_fifo_S_AXI_HP0_ARREADY;
  wire [5:0]        axi4_fifo_S_AXI_HP0_RID;
  wire [63:0]       axi4_fifo_S_AXI_HP0_RDATA;
  wire [1:0]        axi4_fifo_S_AXI_HP0_RRESP;
  wire              axi4_fifo_S_AXI_HP0_RLAST;
  wire              axi4_fifo_S_AXI_HP0_RVALID;
  wire              axi4_fifo_S_AXI_HP0_RREADY;

  wire FCLK_LOCKED, FCLK_RESET0_N;
  assign FCLK_RESET0_N = ~FCLK_RESET0;
  e300_ps_fclk0_mmcm inst_e300_ps_fclk0_mmcm (
    .clk_50MHz_in(processing_system7_FCLK_CLK0),
    .clk_50MHz_out(FCLK_CLK0),
    .clk_200MHz_out(PL_DRAM_CLK),
    .reset(~processing_system7_FCLK_RESET0_N),
    .locked(FCLK_LOCKED));

  reset_sync inst_reset_sync0 (
    .clk(FCLK_CLK0),
    .reset_in(~FCLK_LOCKED),
    .reset_out(FCLK_RESET0));

  reset_sync inst_reset_sync1 (
    .clk(PL_DRAM_CLK),
    .reset_in(~FCLK_LOCKED),
    .reset_out(PL_DRAM_RST));

  assign FCLK_CLK1 = processing_system7_FCLK_CLK1;
  assign FCLK_RESET1 = ~processing_system7_FCLK_RESET1_N;
  assign FCLK_CLK2 = processing_system7_FCLK_CLK2;
  assign FCLK_RESET2 = ~processing_system7_FCLK_RESET2_N;
  assign FCLK_CLK3 = processing_system7_FCLK_CLK3;
  assign FCLK_RESET3 = ~processing_system7_FCLK_RESET3_N;

`ifdef E3XX_SG3
  processing_system7_3 inst_processing_system7 (
`else
  processing_system7_1 inst_processing_system7 (
`endif
    // Outward connections to the pins
    .GPIO_I(GPIO_I),
    .GPIO_O(GPIO_O),
    .GPIO_T(),
    // SPI0/1 used as master -- signals hard wired according to figure 17-8 in Zynq TRM
    .SPI0_SCLK_I(1'b0),
    .SPI0_SCLK_O(SPI0_SCLK),
    .SPI0_SCLK_T(),
    .SPI0_MOSI_I(1'b0),
    .SPI0_MOSI_O(SPI0_MOSI),
    .SPI0_MOSI_T(),
    .SPI0_MISO_I(SPI0_MISO),
    .SPI0_MISO_O(),
    .SPI0_MISO_T(),
    .SPI0_SS_I(1'b1),
    .SPI0_SS_O(SPI0_SS),
    .SPI0_SS1_O(SPI0_SS1),
    .SPI0_SS2_O(SPI0_SS2),
    .SPI0_SS_T(),
    .SPI1_SCLK_I(1'b0),
    .SPI1_SCLK_O(SPI1_SCLK),
    .SPI1_SCLK_T(),
    .SPI1_MOSI_I(1'b0),
    .SPI1_MOSI_O(SPI1_MOSI),
    .SPI1_MOSI_T(),
    .SPI1_MISO_I(SPI1_MISO),
    .SPI1_MISO_O(),
    .SPI1_MISO_T(),
    .SPI1_SS_I(1'b1),
    .SPI1_SS_O(SPI1_SS),
    .SPI1_SS1_O(SPI1_SS1),
    .SPI1_SS2_O(SPI1_SS2),
    .SPI1_SS_T(),
    .USB0_PORT_INDCTL(),
    .USB0_VBUS_PWRSELECT(),
    .USB0_VBUS_PWRFAULT(1'b0),
    .M_AXI_GP0_ARVALID(processing_system7_M_AXI_GP0_ARVALID),
    .M_AXI_GP0_AWVALID(processing_system7_M_AXI_GP0_AWVALID),
    .M_AXI_GP0_BREADY(processing_system7_M_AXI_GP0_BREADY),
    .M_AXI_GP0_RREADY(processing_system7_M_AXI_GP0_RREADY),
    .M_AXI_GP0_WLAST(processing_system7_M_AXI_GP0_WLAST),
    .M_AXI_GP0_WVALID(processing_system7_M_AXI_GP0_WVALID),
    .M_AXI_GP0_ARID(processing_system7_M_AXI_GP0_ARID),
    .M_AXI_GP0_AWID(processing_system7_M_AXI_GP0_AWID),
    .M_AXI_GP0_WID(processing_system7_M_AXI_GP0_WID),
    .M_AXI_GP0_ARBURST(processing_system7_M_AXI_GP0_ARBURST),
    .M_AXI_GP0_ARLOCK(processing_system7_M_AXI_GP0_ARLOCK),
    .M_AXI_GP0_ARSIZE(processing_system7_M_AXI_GP0_ARSIZE),
    .M_AXI_GP0_AWBURST(processing_system7_M_AXI_GP0_AWBURST),
    .M_AXI_GP0_AWLOCK(processing_system7_M_AXI_GP0_AWLOCK),
    .M_AXI_GP0_AWSIZE(processing_system7_M_AXI_GP0_AWSIZE),
    .M_AXI_GP0_ARPROT(processing_system7_M_AXI_GP0_ARPROT),
    .M_AXI_GP0_AWPROT(processing_system7_M_AXI_GP0_AWPROT),
    .M_AXI_GP0_ARADDR(processing_system7_M_AXI_GP0_ARADDR),
    .M_AXI_GP0_AWADDR(processing_system7_M_AXI_GP0_AWADDR),
    .M_AXI_GP0_WDATA(processing_system7_M_AXI_GP0_WDATA),
    .M_AXI_GP0_ARCACHE(processing_system7_M_AXI_GP0_ARCACHE),
    .M_AXI_GP0_ARLEN(processing_system7_M_AXI_GP0_ARLEN),
    .M_AXI_GP0_ARQOS(processing_system7_M_AXI_GP0_ARQOS),
    .M_AXI_GP0_AWCACHE(processing_system7_M_AXI_GP0_AWCACHE),
    .M_AXI_GP0_AWLEN(processing_system7_M_AXI_GP0_AWLEN),
    .M_AXI_GP0_AWQOS(processing_system7_M_AXI_GP0_AWQOS),
    .M_AXI_GP0_WSTRB(processing_system7_M_AXI_GP0_WSTRB),
    .M_AXI_GP0_ACLK(FCLK_CLK0),
    .M_AXI_GP0_ARREADY(processing_system7_M_AXI_GP0_ARREADY),
    .M_AXI_GP0_AWREADY(processing_system7_M_AXI_GP0_AWREADY),
    .M_AXI_GP0_BVALID(processing_system7_M_AXI_GP0_BVALID),
    .M_AXI_GP0_RLAST(processing_system7_M_AXI_GP0_RLAST),
    .M_AXI_GP0_RVALID(processing_system7_M_AXI_GP0_RVALID),
    .M_AXI_GP0_WREADY(processing_system7_M_AXI_GP0_WREADY),
    .M_AXI_GP0_BID(processing_system7_M_AXI_GP0_BID),
    .M_AXI_GP0_RID(processing_system7_M_AXI_GP0_RID),
    .M_AXI_GP0_BRESP(processing_system7_M_AXI_GP0_BRESP),
    .M_AXI_GP0_RRESP(processing_system7_M_AXI_GP0_RRESP),
    .M_AXI_GP0_RDATA(processing_system7_M_AXI_GP0_RDATA),
    .S_AXI_HP0_ARREADY(processing_system7_S_AXI_HP0_ARREADY),
    .S_AXI_HP0_AWREADY(processing_system7_S_AXI_HP0_AWREADY),
    .S_AXI_HP0_BVALID(processing_system7_S_AXI_HP0_BVALID),
    .S_AXI_HP0_RLAST(processing_system7_S_AXI_HP0_RLAST),
    .S_AXI_HP0_RVALID(processing_system7_S_AXI_HP0_RVALID),
    .S_AXI_HP0_WREADY(processing_system7_S_AXI_HP0_WREADY),
    .S_AXI_HP0_BRESP(processing_system7_S_AXI_HP0_BRESP),
    .S_AXI_HP0_RRESP(processing_system7_S_AXI_HP0_RRESP),
    .S_AXI_HP0_BID(processing_system7_S_AXI_HP0_BID),
    .S_AXI_HP0_RID(processing_system7_S_AXI_HP0_RID),
    .S_AXI_HP0_RDATA(processing_system7_S_AXI_HP0_RDATA),
    .S_AXI_HP0_RCOUNT(),
    .S_AXI_HP0_WCOUNT(),
    .S_AXI_HP0_RACOUNT(),
    .S_AXI_HP0_WACOUNT(),
    .S_AXI_HP0_ACLK(FCLK_CLK0),
    .S_AXI_HP0_ARVALID(processing_system7_S_AXI_HP0_ARVALID),
    .S_AXI_HP0_AWVALID(processing_system7_S_AXI_HP0_AWVALID),
    .S_AXI_HP0_BREADY(processing_system7_S_AXI_HP0_BREADY),
    .S_AXI_HP0_RDISSUECAP1_EN(1'b0),
    .S_AXI_HP0_RREADY(processing_system7_S_AXI_HP0_RREADY),
    .S_AXI_HP0_WLAST(processing_system7_S_AXI_HP0_WLAST),
    .S_AXI_HP0_WRISSUECAP1_EN(1'b0),
    .S_AXI_HP0_WVALID(processing_system7_S_AXI_HP0_WVALID),
    .S_AXI_HP0_ARBURST(processing_system7_S_AXI_HP0_ARBURST),
    .S_AXI_HP0_ARLOCK(processing_system7_S_AXI_HP0_ARLOCK),
    .S_AXI_HP0_ARSIZE(processing_system7_S_AXI_HP0_ARSIZE),
    .S_AXI_HP0_AWBURST(processing_system7_S_AXI_HP0_AWBURST),
    .S_AXI_HP0_AWLOCK(processing_system7_S_AXI_HP0_AWLOCK),
    .S_AXI_HP0_AWSIZE(processing_system7_S_AXI_HP0_AWSIZE),
    .S_AXI_HP0_ARPROT(processing_system7_S_AXI_HP0_ARPROT),
    .S_AXI_HP0_AWPROT(processing_system7_S_AXI_HP0_AWPROT),
    .S_AXI_HP0_ARADDR(processing_system7_S_AXI_HP0_ARADDR),
    .S_AXI_HP0_AWADDR(processing_system7_S_AXI_HP0_AWADDR),
    .S_AXI_HP0_ARCACHE(processing_system7_S_AXI_HP0_ARCACHE),
    .S_AXI_HP0_ARLEN(processing_system7_S_AXI_HP0_ARLEN),
    .S_AXI_HP0_ARQOS(processing_system7_S_AXI_HP0_ARQOS),
    .S_AXI_HP0_AWCACHE(processing_system7_S_AXI_HP0_AWCACHE),
    .S_AXI_HP0_AWLEN(processing_system7_S_AXI_HP0_AWLEN),
    .S_AXI_HP0_AWQOS(processing_system7_S_AXI_HP0_AWQOS),
    .S_AXI_HP0_ARID(processing_system7_S_AXI_HP0_ARID),
    .S_AXI_HP0_AWID(processing_system7_S_AXI_HP0_AWID),
    .S_AXI_HP0_WID(processing_system7_S_AXI_HP0_WID),
    .S_AXI_HP0_WDATA(processing_system7_S_AXI_HP0_WDATA),
    .S_AXI_HP0_WSTRB(processing_system7_S_AXI_HP0_WSTRB),
    .IRQ_F2P(IRQ_F2P),
    .FCLK_CLK0(processing_system7_FCLK_CLK0),
    .FCLK_RESET0_N(processing_system7_FCLK_RESET0_N),
    .FCLK_CLK1(processing_system7_FCLK_CLK1),
    .FCLK_RESET1_N(processing_system7_FCLK_RESET1_N),
    .FCLK_CLK2(processing_system7_FCLK_CLK2),
    .FCLK_RESET2_N(processing_system7_FCLK_RESET2_N),
    .FCLK_CLK3(processing_system7_FCLK_CLK3),
    .FCLK_RESET3_N(processing_system7_FCLK_RESET3_N),
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
    .PS_PORB(PS_PORB));

  axi4_fifo_512x64 inst_axi4_fifo_512x64 (
    .aclk(FCLK_CLK0),
    .aresetn(FCLK_RESET0_N),
    .s_axi_awid(S_AXI_HP0_AWID),
    .s_axi_awaddr(S_AXI_HP0_AWADDR),
    .s_axi_awlen(S_AXI_HP0_AWLEN),
    .s_axi_awsize(S_AXI_HP0_AWSIZE),
    .s_axi_awburst(S_AXI_HP0_AWBURST),
    .s_axi_awlock(1'b0),
    .s_axi_awcache(S_AXI_HP0_AWCACHE),
    .s_axi_awprot(S_AXI_HP0_AWPROT),
    .s_axi_awregion(4'h0),
    .s_axi_awqos(4'h0),
    .s_axi_awvalid(S_AXI_HP0_AWVALID),
    .s_axi_awready(S_AXI_HP0_AWREADY),
    .s_axi_wdata(S_AXI_HP0_WDATA),
    .s_axi_wstrb(S_AXI_HP0_WSTRB),
    .s_axi_wlast(S_AXI_HP0_WLAST),
    .s_axi_wvalid(S_AXI_HP0_WVALID),
    .s_axi_wready(S_AXI_HP0_WREADY),
    .s_axi_bid(),
    .s_axi_bresp(S_AXI_HP0_BRESP),
    .s_axi_bvalid(S_AXI_HP0_BVALID),
    .s_axi_bready(S_AXI_HP0_BREADY),
    .s_axi_arid(S_AXI_HP0_ARID),
    .s_axi_araddr(S_AXI_HP0_ARADDR),
    .s_axi_arlen(S_AXI_HP0_ARLEN),
    .s_axi_arsize(S_AXI_HP0_ARSIZE),
    .s_axi_arburst(S_AXI_HP0_ARBURST),
    .s_axi_arlock(1'b0),
    .s_axi_arcache(S_AXI_HP0_ARCACHE),
    .s_axi_arprot(S_AXI_HP0_ARPROT),
    .s_axi_arregion(4'h0),
    .s_axi_arqos(4'h0),
    .s_axi_arvalid(S_AXI_HP0_ARVALID),
    .s_axi_arready(S_AXI_HP0_ARREADY),
    .s_axi_rid(),
    .s_axi_rdata(S_AXI_HP0_RDATA),
    .s_axi_rresp(S_AXI_HP0_RRESP),
    .s_axi_rlast(S_AXI_HP0_RLAST),
    .s_axi_rvalid(S_AXI_HP0_RVALID),
    .s_axi_rready(S_AXI_HP0_RREADY),
    .m_axi_awid(axi4_fifo_S_AXI_HP0_AWID),
    .m_axi_awaddr(axi4_fifo_S_AXI_HP0_AWADDR),
    .m_axi_awlen(axi4_fifo_S_AXI_HP0_AWLEN),
    .m_axi_awsize(axi4_fifo_S_AXI_HP0_AWSIZE),
    .m_axi_awburst(axi4_fifo_S_AXI_HP0_AWBURST),
    .m_axi_awlock(axi4_fifo_S_AXI_HP0_AWLOCK),
    .m_axi_awcache(axi4_fifo_S_AXI_HP0_AWCACHE),
    .m_axi_awprot(axi4_fifo_S_AXI_HP0_AWPROT),
    .m_axi_awregion(axi4_fifo_S_AXI_HP0_AWREGION),
    .m_axi_awqos(axi4_fifo_S_AXI_HP0_AWQOS),
    .m_axi_awvalid(axi4_fifo_S_AXI_HP0_AWVALID),
    .m_axi_awready(axi4_fifo_S_AXI_HP0_AWREADY),
    .m_axi_wdata(axi4_fifo_S_AXI_HP0_WDATA),
    .m_axi_wstrb(axi4_fifo_S_AXI_HP0_WSTRB),
    .m_axi_wlast(axi4_fifo_S_AXI_HP0_WLAST),
    .m_axi_wvalid(axi4_fifo_S_AXI_HP0_WVALID),
    .m_axi_wready(axi4_fifo_S_AXI_HP0_WREADY),
    .m_axi_bid(6'd0),
    .m_axi_bresp(axi4_fifo_S_AXI_HP0_BRESP),
    .m_axi_bvalid(axi4_fifo_S_AXI_HP0_BVALID),
    .m_axi_bready(axi4_fifo_S_AXI_HP0_BREADY),
    .m_axi_arid(axi4_fifo_S_AXI_HP0_ARID),
    .m_axi_araddr(axi4_fifo_S_AXI_HP0_ARADDR),
    .m_axi_arlen(axi4_fifo_S_AXI_HP0_ARLEN),
    .m_axi_arsize(axi4_fifo_S_AXI_HP0_ARSIZE),
    .m_axi_arburst(axi4_fifo_S_AXI_HP0_ARBURST),
    .m_axi_arlock(axi4_fifo_S_AXI_HP0_ARLOCK),
    .m_axi_arcache(axi4_fifo_S_AXI_HP0_ARCACHE),
    .m_axi_arprot(axi4_fifo_S_AXI_HP0_ARPROT),
    .m_axi_arregion(axi4_fifo_S_AXI_HP0_ARREGION),
    .m_axi_arqos(axi4_fifo_S_AXI_HP0_ARQOS),
    .m_axi_arvalid(axi4_fifo_S_AXI_HP0_ARVALID),
    .m_axi_arready(axi4_fifo_S_AXI_HP0_ARREADY),
    .m_axi_rid(6'd0),
    .m_axi_rdata(axi4_fifo_S_AXI_HP0_RDATA),
    .m_axi_rresp(axi4_fifo_S_AXI_HP0_RRESP),
    .m_axi_rlast(axi4_fifo_S_AXI_HP0_RLAST),
    .m_axi_rvalid(axi4_fifo_S_AXI_HP0_RVALID),
    .m_axi_rready(axi4_fifo_S_AXI_HP0_RREADY));

  // Convert Zynq AXI4 bus to AXI3
  axi4_to_axi3_protocol_converter inst_axi4_to_axi3_protocol_converter (
    .aclk(FCLK_CLK0),
    .aresetn(FCLK_RESET0_N),
    .s_axi_awid(axi4_fifo_S_AXI_HP0_AWID),
    .s_axi_awaddr(axi4_fifo_S_AXI_HP0_AWADDR),
    .s_axi_awlen(axi4_fifo_S_AXI_HP0_AWLEN),
    .s_axi_awsize(axi4_fifo_S_AXI_HP0_AWSIZE),
    .s_axi_awburst(axi4_fifo_S_AXI_HP0_AWBURST),
    .s_axi_awlock(axi4_fifo_S_AXI_HP0_AWLOCK),
    .s_axi_awcache(axi4_fifo_S_AXI_HP0_AWCACHE),
    .s_axi_awprot(axi4_fifo_S_AXI_HP0_AWPROT),
    .s_axi_awregion(axi4_fifo_S_AXI_HP0_AWREGION),
    .s_axi_awqos(axi4_fifo_S_AXI_HP0_AWQOS),
    .s_axi_awvalid(axi4_fifo_S_AXI_HP0_AWVALID),
    .s_axi_awready(axi4_fifo_S_AXI_HP0_AWREADY),
    .s_axi_wdata(axi4_fifo_S_AXI_HP0_WDATA),
    .s_axi_wstrb(axi4_fifo_S_AXI_HP0_WSTRB),
    .s_axi_wlast(axi4_fifo_S_AXI_HP0_WLAST),
    .s_axi_wvalid(axi4_fifo_S_AXI_HP0_WVALID),
    .s_axi_wready(axi4_fifo_S_AXI_HP0_WREADY),
    .s_axi_bresp(axi4_fifo_S_AXI_HP0_BRESP),
    .s_axi_bvalid(axi4_fifo_S_AXI_HP0_BVALID),
    .s_axi_bready(axi4_fifo_S_AXI_HP0_BREADY),
    .s_axi_arid(axi4_fifo_S_AXI_HP0_ARID),
    .s_axi_araddr(axi4_fifo_S_AXI_HP0_ARADDR),
    .s_axi_arlen(axi4_fifo_S_AXI_HP0_ARLEN),
    .s_axi_arsize(axi4_fifo_S_AXI_HP0_ARSIZE),
    .s_axi_arburst(axi4_fifo_S_AXI_HP0_ARBURST),
    .s_axi_arlock(axi4_fifo_S_AXI_HP0_ARLOCK),
    .s_axi_arcache(axi4_fifo_S_AXI_HP0_ARCACHE),
    .s_axi_arprot(axi4_fifo_S_AXI_HP0_ARPROT),
    .s_axi_arregion(axi4_fifo_S_AXI_HP0_ARREGION),
    .s_axi_arqos(axi4_fifo_S_AXI_HP0_ARQOS),
    .s_axi_arvalid(axi4_fifo_S_AXI_HP0_ARVALID),
    .s_axi_arready(axi4_fifo_S_AXI_HP0_ARREADY),
    .s_axi_rdata(axi4_fifo_S_AXI_HP0_RDATA),
    .s_axi_rresp(axi4_fifo_S_AXI_HP0_RRESP),
    .s_axi_rlast(axi4_fifo_S_AXI_HP0_RLAST),
    .s_axi_rvalid(axi4_fifo_S_AXI_HP0_RVALID),
    .s_axi_rready(axi4_fifo_S_AXI_HP0_RREADY),
    .m_axi_awid(processing_system7_S_AXI_HP0_AWID),
    .m_axi_awaddr(processing_system7_S_AXI_HP0_AWADDR),
    .m_axi_awlen(processing_system7_S_AXI_HP0_AWLEN),
    .m_axi_awsize(processing_system7_S_AXI_HP0_AWSIZE),
    .m_axi_awburst(processing_system7_S_AXI_HP0_AWBURST),
    .m_axi_awlock(processing_system7_S_AXI_HP0_AWLOCK),
    .m_axi_awcache(processing_system7_S_AXI_HP0_AWCACHE),
    .m_axi_awprot(processing_system7_S_AXI_HP0_AWPROT),
    .m_axi_awqos(processing_system7_S_AXI_HP0_AWQOS),
    .m_axi_awvalid(processing_system7_S_AXI_HP0_AWVALID),
    .m_axi_awready(processing_system7_S_AXI_HP0_AWREADY),
    .m_axi_wid(processing_system7_S_AXI_HP0_WID),
    .m_axi_wdata(processing_system7_S_AXI_HP0_WDATA),
    .m_axi_wstrb(processing_system7_S_AXI_HP0_WSTRB),
    .m_axi_wlast(processing_system7_S_AXI_HP0_WLAST),
    .m_axi_wvalid(processing_system7_S_AXI_HP0_WVALID),
    .m_axi_wready(processing_system7_S_AXI_HP0_WREADY),
    .m_axi_bid(processing_system7_S_AXI_HP0_BID),
    .m_axi_bresp(processing_system7_S_AXI_HP0_BRESP),
    .m_axi_bvalid(processing_system7_S_AXI_HP0_BVALID),
    .m_axi_bready(processing_system7_S_AXI_HP0_BREADY),
    .m_axi_arid(processing_system7_S_AXI_HP0_ARID),
    .m_axi_araddr(processing_system7_S_AXI_HP0_ARADDR),
    .m_axi_arlen(processing_system7_S_AXI_HP0_ARLEN),
    .m_axi_arsize(processing_system7_S_AXI_HP0_ARSIZE),
    .m_axi_arburst(processing_system7_S_AXI_HP0_ARBURST),
    .m_axi_arlock(processing_system7_S_AXI_HP0_ARLOCK),
    .m_axi_arcache(processing_system7_S_AXI_HP0_ARCACHE),
    .m_axi_arprot(processing_system7_S_AXI_HP0_ARPROT),
    .m_axi_arqos(processing_system7_S_AXI_HP0_ARQOS),
    .m_axi_arvalid(processing_system7_S_AXI_HP0_ARVALID),
    .m_axi_arready(processing_system7_S_AXI_HP0_ARREADY),
    .m_axi_rid(processing_system7_S_AXI_HP0_RID),
    .m_axi_rdata(processing_system7_S_AXI_HP0_RDATA),
    .m_axi_rresp(processing_system7_S_AXI_HP0_RRESP),
    .m_axi_rlast(processing_system7_S_AXI_HP0_RLAST),
    .m_axi_rvalid(processing_system7_S_AXI_HP0_RVALID),
    .m_axi_rready(processing_system7_S_AXI_HP0_RREADY));

  // Convert Zynq AXI3 bus to AXI4-lite
  axi3_to_axi4lite_protocol_converter inst_axi3_to_axi4lite_protocol_converter (
    .aclk(FCLK_CLK0),
    .aresetn(FCLK_RESET0_N),
    .s_axi_awid(processing_system7_M_AXI_GP0_AWID),
    .s_axi_awaddr(processing_system7_M_AXI_GP0_AWADDR),
    .s_axi_awlen(processing_system7_M_AXI_GP0_AWLEN),
    .s_axi_awsize(processing_system7_M_AXI_GP0_AWSIZE),
    .s_axi_awburst(processing_system7_M_AXI_GP0_AWBURST),
    .s_axi_awlock(processing_system7_M_AXI_GP0_AWLOCK),
    .s_axi_awcache(processing_system7_M_AXI_GP0_AWCACHE),
    .s_axi_awprot(processing_system7_M_AXI_GP0_AWPROT),
    .s_axi_awqos(processing_system7_M_AXI_GP0_AWQOS),
    .s_axi_awvalid(processing_system7_M_AXI_GP0_AWVALID),
    .s_axi_awready(processing_system7_M_AXI_GP0_AWREADY),
    .s_axi_wid(processing_system7_M_AXI_GP0_WID),
    .s_axi_wdata(processing_system7_M_AXI_GP0_WDATA),
    .s_axi_wstrb(processing_system7_M_AXI_GP0_WSTRB),
    .s_axi_wlast(processing_system7_M_AXI_GP0_WLAST),
    .s_axi_wvalid(processing_system7_M_AXI_GP0_WVALID),
    .s_axi_wready(processing_system7_M_AXI_GP0_WREADY),
    .s_axi_bid(processing_system7_M_AXI_GP0_BID),
    .s_axi_bresp(processing_system7_M_AXI_GP0_BRESP),
    .s_axi_bvalid(processing_system7_M_AXI_GP0_BVALID),
    .s_axi_bready(processing_system7_M_AXI_GP0_BREADY),
    .s_axi_arid(processing_system7_M_AXI_GP0_ARID),
    .s_axi_araddr(processing_system7_M_AXI_GP0_ARADDR),
    .s_axi_arlen(processing_system7_M_AXI_GP0_ARLEN),
    .s_axi_arsize(processing_system7_M_AXI_GP0_ARSIZE),
    .s_axi_arburst(processing_system7_M_AXI_GP0_ARBURST),
    .s_axi_arlock(processing_system7_M_AXI_GP0_ARLOCK),
    .s_axi_arcache(processing_system7_M_AXI_GP0_ARCACHE),
    .s_axi_arprot(processing_system7_M_AXI_GP0_ARPROT),
    .s_axi_arqos(processing_system7_M_AXI_GP0_ARQOS),
    .s_axi_arvalid(processing_system7_M_AXI_GP0_ARVALID),
    .s_axi_arready(processing_system7_M_AXI_GP0_ARREADY),
    .s_axi_rid(processing_system7_M_AXI_GP0_RID),
    .s_axi_rdata(processing_system7_M_AXI_GP0_RDATA),
    .s_axi_rresp(processing_system7_M_AXI_GP0_RRESP),
    .s_axi_rlast(processing_system7_M_AXI_GP0_RLAST),
    .s_axi_rvalid(processing_system7_M_AXI_GP0_RVALID),
    .s_axi_rready(processing_system7_M_AXI_GP0_RREADY),
    .m_axi_awaddr(M_AXI_GP0_AWADDR),
    .m_axi_awprot(),
    .m_axi_awvalid(M_AXI_GP0_AWVALID),
    .m_axi_awready(M_AXI_GP0_AWREADY),
    .m_axi_wdata(M_AXI_GP0_WDATA),
    .m_axi_wstrb(M_AXI_GP0_WSTRB),
    .m_axi_wvalid(M_AXI_GP0_WVALID),
    .m_axi_wready(M_AXI_GP0_WREADY),
    .m_axi_bresp(M_AXI_GP0_BRESP),
    .m_axi_bvalid(M_AXI_GP0_BVALID),
    .m_axi_bready(M_AXI_GP0_BREADY),
    .m_axi_araddr(M_AXI_GP0_ARADDR),
    .m_axi_arprot(),
    .m_axi_arvalid(M_AXI_GP0_ARVALID),
    .m_axi_arready(M_AXI_GP0_ARREADY),
    .m_axi_rdata(M_AXI_GP0_RDATA),
    .m_axi_rresp(M_AXI_GP0_RRESP),
    .m_axi_rvalid(M_AXI_GP0_RVALID),
    .m_axi_rready(M_AXI_GP0_RREADY));

endmodule
