//
// Copyright 2016-2017 Ettus Research
//

module n310_ps
(
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
  output            FCLK_RESET3
);

  wire        processing_system7_M_AXI_GP0_ARVALID;
  wire        processing_system7_M_AXI_GP0_AWVALID;
  wire        processing_system7_M_AXI_GP0_BREADY;
  wire        processing_system7_M_AXI_GP0_RREADY;
  wire        processing_system7_M_AXI_GP0_WLAST;
  wire        processing_system7_M_AXI_GP0_WVALID;
  wire [11:0] processing_system7_M_AXI_GP0_ARID;
  wire [11:0] processing_system7_M_AXI_GP0_AWID;
  wire [11:0] processing_system7_M_AXI_GP0_WID;
  wire [1:0]  processing_system7_M_AXI_GP0_ARBURST;
  wire [1:0]  processing_system7_M_AXI_GP0_ARLOCK;
  wire [2:0]  processing_system7_M_AXI_GP0_ARSIZE;
  wire [1:0]  processing_system7_M_AXI_GP0_AWBURST;
  wire [1:0]  processing_system7_M_AXI_GP0_AWLOCK;
  wire [2:0]  processing_system7_M_AXI_GP0_AWSIZE;
  wire [2:0]  processing_system7_M_AXI_GP0_ARPROT;
  wire [2:0]  processing_system7_M_AXI_GP0_AWPROT;
  wire [31:0] processing_system7_M_AXI_GP0_ARADDR;
  wire [31:0] processing_system7_M_AXI_GP0_AWADDR;
  wire [31:0] processing_system7_M_AXI_GP0_WDATA;
  wire [3:0]  processing_system7_M_AXI_GP0_ARCACHE;
  wire [3:0]  processing_system7_M_AXI_GP0_ARLEN;
  wire [3:0]  processing_system7_M_AXI_GP0_ARQOS;
  wire [3:0]  processing_system7_M_AXI_GP0_AWCACHE;
  wire [3:0]  processing_system7_M_AXI_GP0_AWLEN;
  wire [3:0]  processing_system7_M_AXI_GP0_AWQOS;
  wire [3:0]  processing_system7_M_AXI_GP0_WSTRB;
  wire        processing_system7_M_AXI_GP0_ARREADY;
  wire        processing_system7_M_AXI_GP0_AWREADY;
  wire        processing_system7_M_AXI_GP0_BVALID;
  wire        processing_system7_M_AXI_GP0_RLAST;
  wire        processing_system7_M_AXI_GP0_RVALID;
  wire        processing_system7_M_AXI_GP0_WREADY;
  wire [11:0] processing_system7_M_AXI_GP0_BID;
  wire [11:0] processing_system7_M_AXI_GP0_RID;
  wire [1:0]  processing_system7_M_AXI_GP0_BRESP;
  wire [1:0]  processing_system7_M_AXI_GP0_RRESP;
  wire [31:0] processing_system7_M_AXI_GP0_RDATA;

  wire        processing_system7_FCLK_RESET0_N;
  wire        processing_system7_FCLK_CLK0;
  wire        processing_system7_FCLK_RESET1_N;
  wire        processing_system7_FCLK_CLK1;
  wire        processing_system7_FCLK_RESET2_N;
  wire        processing_system7_FCLK_CLK2;
  wire        processing_system7_FCLK_RESET3_N;
  wire        processing_system7_FCLK_CLK3;

  assign FCLK_RESET0 = ~processing_system7_FCLK_RESET0_N;
  assign FCLK_CLK0 = processing_system7_FCLK_CLK0;

  assign FCLK_RESET1 = ~processing_system7_FCLK_RESET1_N;
  assign FCLK_CLK1 = processing_system7_FCLK_CLK1;

  assign FCLK_RESET2 = ~processing_system7_FCLK_RESET2_N;
  assign FCLK_CLK2 = processing_system7_FCLK_CLK2;

  assign FCLK_RESET3 = ~processing_system7_FCLK_RESET3_N;
  assign FCLK_CLK3 = processing_system7_FCLK_CLK3;

  processing_system7_0 inst_processing_system7_0
  (
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
     .IRQ_F2P(IRQ_F2P),
     .FCLK_CLK0(processing_system7_FCLK_CLK0),
     .FCLK_RESET0_N(processing_system7_FCLK_RESET0_N),
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

  axi3_to_axi4lite_protocol_converter inst_axi3_to_axi4lite_protocol_converter
  (
    .aclk(FCLK_CLK0),
    .aresetn(processing_system7_FCLK_RESET0_N),
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
    .m_axi_rready(M_AXI_GP0_RREADY)
);

endmodule
