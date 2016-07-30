//
// Copyright 2015 Ettus Research LLC
//

`include "sim_axi4_lib.svh"

`timescale 1ns/1ps

module axis_dram_fifo_dual #(
  parameter USE_SRAM_MEMORY = 0
) (
  input         bus_clk,
  input         bus_rst,
  input         sys_clk,
  input         sys_rst_n,
  
  input [63:0]  i_tdata,
  input         i_tlast,
  input         i_tvalid,
  output        i_tready,

  output [63:0] o_tdata,
  output        o_tlast,
  output        o_tvalid,
  input         o_tready,

  output        init_calib_complete
);

  // Misc declarations
  axi4_rd_t #(.DWIDTH(64), .AWIDTH(32), .IDWIDTH(1)) dma0_axi_rd(.clk(sys_clk));
  axi4_wr_t #(.DWIDTH(64), .AWIDTH(32), .IDWIDTH(1)) dma0_axi_wr(.clk(sys_clk));
  axi4_rd_t #(.DWIDTH(64), .AWIDTH(32), .IDWIDTH(1)) dma1_axi_rd(.clk(sys_clk));
  axi4_wr_t #(.DWIDTH(64), .AWIDTH(32), .IDWIDTH(1)) dma1_axi_wr(.clk(sys_clk));
  axi4_rd_t #(.DWIDTH(256), .AWIDTH(30), .IDWIDTH(4)) mig_axi_rd(.clk(sys_clk));
  axi4_wr_t #(.DWIDTH(256), .AWIDTH(30), .IDWIDTH(4)) mig_axi_wr(.clk(sys_clk));

  wire [31:0]   ddr3_dq;      // Data pins. Input for Reads; Output for Writes.
  wire [3:0]    ddr3_dqs_n;   // Data Strobes. Input for Reads; Output for Writes.
  wire [3:0]    ddr3_dqs_p;
  wire [14:0]   ddr3_addr;    // Address
  wire [2:0]    ddr3_ba;      // Bank Address
  wire          ddr3_ras_n;   // Row Address Strobe.
  wire          ddr3_cas_n;   // Column address select
  wire          ddr3_we_n;    // Write Enable
  wire          ddr3_reset_n; // SDRAM reset pin.
  wire [0:0]    ddr3_ck_p;    // Differential clock
  wire [0:0]    ddr3_ck_n;
  wire [0:0]    ddr3_cke;     // Clock Enable
  wire [0:0]    ddr3_cs_n;    // Chip Select
  wire [3:0]    ddr3_dm;      // Data Mask [3] = UDM.U26; [2] = LDM.U26; ...
  wire [0:0]    ddr3_odt;     // On-Die termination enable.

  wire          ddr3_axi_clk;       // 1/4 DDR external clock rate (250MHz)
  wire          ddr3_axi_rst;       // Synchronized to ddr_sys_clk
  reg           ddr3_axi_rst_reg_n; // Synchronized to ddr_sys_clk
  wire          ddr3_axi_clk_x2;

  always @(posedge ddr3_axi_clk)
    ddr3_axi_rst_reg_n <= ~ddr3_axi_rst;

  noc_block_axi_dma_fifo #(
    .NUM_FIFOS(2),
    .DEFAULT_FIFO_BASE({30'h00020000, 30'h00000000}),
    .DEFAULT_FIFO_SIZE({30'h0001FFFF, 30'h0001FFFF})
  ) inst_noc_block_dram_fifo (
    .bus_clk(bus_clk), .bus_rst(bus_rst),
    .ce_clk(ddr3_axi_clk_x2), .ce_rst(ddr3_axi_rst),
    //AXIS
    .i_tdata(i_tdata), .i_tlast(i_tlast), .i_tvalid(i_tvalid), .i_tready(i_tready),
    .o_tdata(o_tdata), .o_tlast(o_tlast), .o_tvalid(o_tvalid), .o_tready(o_tready),
    //AXI
    .m_axi_awid({dma1_axi_wr.addr.id, dma0_axi_wr.addr.id}),
    .m_axi_awaddr({dma1_axi_wr.addr.addr, dma0_axi_wr.addr.addr}),
    .m_axi_awlen({dma1_axi_wr.addr.len, dma0_axi_wr.addr.len}),
    .m_axi_awsize({dma1_axi_wr.addr.size, dma0_axi_wr.addr.size}),
    .m_axi_awburst({dma1_axi_wr.addr.burst, dma0_axi_wr.addr.burst}),
    .m_axi_awlock({dma1_axi_wr.addr.lock, dma0_axi_wr.addr.lock}),
    .m_axi_awcache({dma1_axi_wr.addr.cache, dma0_axi_wr.addr.cache}),
    .m_axi_awprot({dma1_axi_wr.addr.prot, dma0_axi_wr.addr.prot}),
    .m_axi_awqos({dma1_axi_wr.addr.qos, dma0_axi_wr.addr.qos}),
    .m_axi_awregion({dma1_axi_wr.addr.region, dma0_axi_wr.addr.region}),
    .m_axi_awuser({dma1_axi_wr.addr.user, dma0_axi_wr.addr.user}),
    .m_axi_awvalid({dma1_axi_wr.addr.valid, dma0_axi_wr.addr.valid}),
    .m_axi_awready({dma1_axi_wr.addr.ready, dma0_axi_wr.addr.ready}),
    .m_axi_wdata({dma1_axi_wr.data.data, dma0_axi_wr.data.data}),
    .m_axi_wstrb({dma1_axi_wr.data.strb, dma0_axi_wr.data.strb}),
    .m_axi_wlast({dma1_axi_wr.data.last, dma0_axi_wr.data.last}),
    .m_axi_wuser({dma1_axi_wr.data.user, dma0_axi_wr.data.user}),
    .m_axi_wvalid({dma1_axi_wr.data.valid, dma0_axi_wr.data.valid}),
    .m_axi_wready({dma1_axi_wr.data.ready, dma0_axi_wr.data.ready}),
    .m_axi_bid({dma1_axi_wr.resp.id, dma0_axi_wr.resp.id}),
    .m_axi_bresp({dma1_axi_wr.resp.resp, dma0_axi_wr.resp.resp}),
    .m_axi_buser({dma1_axi_wr.resp.user, dma0_axi_wr.resp.user}),
    .m_axi_bvalid({dma1_axi_wr.resp.valid, dma0_axi_wr.resp.valid}),
    .m_axi_bready({dma1_axi_wr.resp.ready, dma0_axi_wr.resp.ready}),
    .m_axi_arid({dma1_axi_rd.addr.id, dma0_axi_rd.addr.id}),
    .m_axi_araddr({dma1_axi_rd.addr.addr, dma0_axi_rd.addr.addr}),
    .m_axi_arlen({dma1_axi_rd.addr.len, dma0_axi_rd.addr.len}),
    .m_axi_arsize({dma1_axi_rd.addr.size, dma0_axi_rd.addr.size}),
    .m_axi_arburst({dma1_axi_rd.addr.burst, dma0_axi_rd.addr.burst}),
    .m_axi_arlock({dma1_axi_rd.addr.lock, dma0_axi_rd.addr.lock}),
    .m_axi_arcache({dma1_axi_rd.addr.cache, dma0_axi_rd.addr.cache}),
    .m_axi_arprot({dma1_axi_rd.addr.prot, dma0_axi_rd.addr.prot}),
    .m_axi_arqos({dma1_axi_rd.addr.qos, dma0_axi_rd.addr.qos}),
    .m_axi_arregion({dma1_axi_rd.addr.region, dma0_axi_rd.addr.region}),
    .m_axi_aruser({dma1_axi_rd.addr.user, dma0_axi_rd.addr.user}),
    .m_axi_arvalid({dma1_axi_rd.addr.valid, dma0_axi_rd.addr.valid}),
    .m_axi_arready({dma1_axi_rd.addr.ready, dma0_axi_rd.addr.ready}),
    .m_axi_rid({dma1_axi_rd.data.id, dma0_axi_rd.data.id}),
    .m_axi_rdata({dma1_axi_rd.data.data, dma0_axi_rd.data.data}),
    .m_axi_rresp({dma1_axi_rd.data.resp, dma0_axi_rd.data.resp}),
    .m_axi_rlast({dma1_axi_rd.data.last, dma0_axi_rd.data.last}),
    .m_axi_ruser({dma1_axi_rd.data.user, dma0_axi_rd.data.user}),
    .m_axi_rvalid({dma1_axi_rd.data.valid, dma0_axi_rd.data.valid}),
    .m_axi_rready({dma1_axi_rd.data.ready, dma0_axi_rd.data.ready}),
    .debug()
  );

  generate if (USE_SRAM_MEMORY) begin
    assign init_calib_complete  = 1;
    assign ddr3_axi_clk         = bus_clk;
    assign ddr3_axi_clk_x2      = bus_clk;
    assign ddr3_axi_rst         = bus_rst;

    axi4_dualport_sram axi4_dualport_sram_i0 (
      .s_aclk         (ddr3_axi_clk_x2), // input s_aclk
      .s_aresetn      (~ddr3_axi_rst), // input s_aresetn
      .s_axi_awid     (dma0_axi_wr.addr.id), // input [0 : 0] s_axi_awid
      .s_axi_awaddr   (dma0_axi_wr.addr.addr), // input [31 : 0] s_axi_awaddr
      .s_axi_awlen    (dma0_axi_wr.addr.len), // input [7 : 0] s_axi_awlen
      .s_axi_awsize   (dma0_axi_wr.addr.size), // input [2 : 0] s_axi_awsize
      .s_axi_awburst  (dma0_axi_wr.addr.burst), // input [1 : 0] s_axi_awburst
      .s_axi_awvalid  (dma0_axi_wr.addr.valid), // input s_axi_awvalid
      .s_axi_awready  (dma0_axi_wr.addr.ready), // output s_axi_awready
      .s_axi_wdata    (dma0_axi_wr.data.data), // input [63 : 0] s_axi_wdata
      .s_axi_wstrb    (dma0_axi_wr.data.strb), // input [7 : 0] s_axi_wstrb
      .s_axi_wlast    (dma0_axi_wr.data.last), // input s_axi_wlast
      .s_axi_wvalid   (dma0_axi_wr.data.valid), // input s_axi_wvalid
      .s_axi_wready   (dma0_axi_wr.data.ready), // output s_axi_wready
      .s_axi_bid      (dma0_axi_wr.resp.id), // output [0 : 0] s_axi_bid
      .s_axi_bresp    (dma0_axi_wr.resp.resp), // output [1 : 0] s_axi_bresp
      .s_axi_bvalid   (dma0_axi_wr.resp.valid), // output s_axi_bvalid
      .s_axi_bready   (dma0_axi_wr.resp.ready), // input s_axi_bready
      .s_axi_arid     (dma0_axi_rd.addr.id), // input [0 : 0] s_axi_arid
      .s_axi_araddr   (dma0_axi_rd.addr.addr), // input [31 : 0] s_axi_araddr
      .s_axi_arlen    (dma0_axi_rd.addr.len), // input [7 : 0] s_axi_arlen
      .s_axi_arsize   (dma0_axi_rd.addr.size), // input [2 : 0] s_axi_arsize
      .s_axi_arburst  (dma0_axi_rd.addr.burst), // input [1 : 0] s_axi_arburst
      .s_axi_arvalid  (dma0_axi_rd.addr.valid), // input s_axi_arvalid
      .s_axi_arready  (dma0_axi_rd.addr.ready), // output s_axi_arready
      .s_axi_rid      (dma0_axi_rd.data.id), // output [0 : 0] s_axi_rid
      .s_axi_rdata    (dma0_axi_rd.data.data), // output [63 : 0] s_axi_rdata
      .s_axi_rresp    (dma0_axi_rd.data.resp), // output [1 : 0] s_axi_rresp
      .s_axi_rlast    (dma0_axi_rd.data.last), // output s_axi_rlast
      .s_axi_rvalid   (dma0_axi_rd.data.valid), // output s_axi_rvalid
      .s_axi_rready   (dma0_axi_rd.data.ready) // input s_axi_rready
    );

    axi4_dualport_sram axi4_dualport_sram_i1 (
      .s_aclk         (ddr3_axi_clk_x2), // input s_aclk
      .s_aresetn      (~ddr3_axi_rst), // input s_aresetn
      .s_axi_awid     (dma1_axi_wr.addr.id), // input [0 : 0] s_axi_awid
      .s_axi_awaddr   (dma1_axi_wr.addr.addr), // input [31 : 0] s_axi_awaddr
      .s_axi_awlen    (dma1_axi_wr.addr.len), // input [7 : 0] s_axi_awlen
      .s_axi_awsize   (dma1_axi_wr.addr.size), // input [2 : 0] s_axi_awsize
      .s_axi_awburst  (dma1_axi_wr.addr.burst), // input [1 : 0] s_axi_awburst
      .s_axi_awvalid  (dma1_axi_wr.addr.valid), // input s_axi_awvalid
      .s_axi_awready  (dma1_axi_wr.addr.ready), // output s_axi_awready
      .s_axi_wdata    (dma1_axi_wr.data.data), // input [63 : 0] s_axi_wdata
      .s_axi_wstrb    (dma1_axi_wr.data.strb), // input [7 : 0] s_axi_wstrb
      .s_axi_wlast    (dma1_axi_wr.data.last), // input s_axi_wlast
      .s_axi_wvalid   (dma1_axi_wr.data.valid), // input s_axi_wvalid
      .s_axi_wready   (dma1_axi_wr.data.ready), // output s_axi_wready
      .s_axi_bid      (dma1_axi_wr.resp.id), // output [0 : 0] s_axi_bid
      .s_axi_bresp    (dma1_axi_wr.resp.resp), // output [1 : 0] s_axi_bresp
      .s_axi_bvalid   (dma1_axi_wr.resp.valid), // output s_axi_bvalid
      .s_axi_bready   (dma1_axi_wr.resp.ready), // input s_axi_bready
      .s_axi_arid     (dma1_axi_rd.addr.id), // input [0 : 0] s_axi_arid
      .s_axi_araddr   (dma1_axi_rd.addr.addr), // input [31 : 0] s_axi_araddr
      .s_axi_arlen    (dma1_axi_rd.addr.len), // input [7 : 0] s_axi_arlen
      .s_axi_arsize   (dma1_axi_rd.addr.size), // input [2 : 0] s_axi_arsize
      .s_axi_arburst  (dma1_axi_rd.addr.burst), // input [1 : 0] s_axi_arburst
      .s_axi_arvalid  (dma1_axi_rd.addr.valid), // input s_axi_arvalid
      .s_axi_arready  (dma1_axi_rd.addr.ready), // output s_axi_arready
      .s_axi_rid      (dma1_axi_rd.data.id), // output [0 : 0] s_axi_rid
      .s_axi_rdata    (dma1_axi_rd.data.data), // output [63 : 0] s_axi_rdata
      .s_axi_rresp    (dma1_axi_rd.data.resp), // output [1 : 0] s_axi_rresp
      .s_axi_rlast    (dma1_axi_rd.data.last), // output s_axi_rlast
      .s_axi_rvalid   (dma1_axi_rd.data.valid), // output s_axi_rvalid
      .s_axi_rready   (dma1_axi_rd.data.ready) // input s_axi_rready
    );

  end else begin  //generate if (USE_SRAM_MEMORY) begin
    //---------------------------------------------------
    // We use an interconnect to connect to FIFOs.
    //---------------------------------------------------
    axi_intercon_2x64_128 axi_intercon_2x64_128_i (
      .INTERCONNECT_ACLK(ddr3_axi_clk_x2), // input INTERCONNECT_ACLK
      .INTERCONNECT_ARESETN(~ddr3_axi_rst), // input INTERCONNECT_ARESETN
      //
      .S00_AXI_ARESET_OUT_N                 (), // output S00_AXI_ARESET_OUT_N
      .S00_AXI_ACLK                         (ddr3_axi_clk_x2), // input S00_AXI_ACLK
      .S00_AXI_AWID                         (dma0_axi_wr.addr.id), // input [0 : 0] S00_AXI_AWID
      .S00_AXI_AWADDR                       (dma0_axi_wr.addr.addr), // input [31 : 0] S00_AXI_AWADDR
      .S00_AXI_AWLEN                        (dma0_axi_wr.addr.len), // input [7 : 0] S00_AXI_AWLEN
      .S00_AXI_AWSIZE                       (dma0_axi_wr.addr.size), // input [2 : 0] S00_AXI_AWSIZE
      .S00_AXI_AWBURST                      (dma0_axi_wr.addr.burst), // input [1 : 0] S00_AXI_AWBURST
      .S00_AXI_AWLOCK                       (dma0_axi_wr.addr.lock), // input S00_AXI_AWLOCK
      .S00_AXI_AWCACHE                      (dma0_axi_wr.addr.cache), // input [3 : 0] S00_AXI_AWCACHE
      .S00_AXI_AWPROT                       (dma0_axi_wr.addr.prot), // input [2 : 0] S00_AXI_AWPROT
      .S00_AXI_AWQOS                        (dma0_axi_wr.addr.qos), // input [3 : 0] S00_AXI_AWQOS
      .S00_AXI_AWVALID                      (dma0_axi_wr.addr.valid), // input S00_AXI_AWVALID
      .S00_AXI_AWREADY                      (dma0_axi_wr.addr.ready), // output S00_AXI_AWREADY
      .S00_AXI_WDATA                        (dma0_axi_wr.data.data), // input [63 : 0] S00_AXI_WDATA
      .S00_AXI_WSTRB                        (dma0_axi_wr.data.strb), // input [7 : 0] S00_AXI_WSTRB
      .S00_AXI_WLAST                        (dma0_axi_wr.data.last), // input S00_AXI_WLAST
      .S00_AXI_WVALID                       (dma0_axi_wr.data.valid), // input S00_AXI_WVALID
      .S00_AXI_WREADY                       (dma0_axi_wr.data.ready), // output S00_AXI_WREADY
      .S00_AXI_BID                          (dma0_axi_wr.resp.id), // output [0 : 0] S00_AXI_BID
      .S00_AXI_BRESP                        (dma0_axi_wr.resp.resp), // output [1 : 0] S00_AXI_BRESP
      .S00_AXI_BVALID                       (dma0_axi_wr.resp.valid), // output S00_AXI_BVALID
      .S00_AXI_BREADY                       (dma0_axi_wr.resp.ready), // input S00_AXI_BREADY
      .S00_AXI_ARID                         (dma0_axi_rd.addr.id), // input [0 : 0] S00_AXI_ARID
      .S00_AXI_ARADDR                       (dma0_axi_rd.addr.addr), // input [31 : 0] S00_AXI_ARADDR
      .S00_AXI_ARLEN                        (dma0_axi_rd.addr.len), // input [7 : 0] S00_AXI_ARLEN
      .S00_AXI_ARSIZE                       (dma0_axi_rd.addr.size), // input [2 : 0] S00_AXI_ARSIZE
      .S00_AXI_ARBURST                      (dma0_axi_rd.addr.burst), // input [1 : 0] S00_AXI_ARBURST
      .S00_AXI_ARLOCK                       (dma0_axi_rd.addr.lock), // input S00_AXI_ARLOCK
      .S00_AXI_ARCACHE                      (dma0_axi_rd.addr.cache), // input [3 : 0] S00_AXI_ARCACHE
      .S00_AXI_ARPROT                       (dma0_axi_rd.addr.prot), // input [2 : 0] S00_AXI_ARPROT
      .S00_AXI_ARQOS                        (dma0_axi_rd.addr.qos), // input [3 : 0] S00_AXI_ARQOS
      .S00_AXI_ARVALID                      (dma0_axi_rd.addr.valid), // input S00_AXI_ARVALID
      .S00_AXI_ARREADY                      (dma0_axi_rd.addr.ready), // output S00_AXI_ARREADY
      .S00_AXI_RID                          (dma0_axi_rd.data.id), // output [0 : 0] S00_AXI_RID
      .S00_AXI_RDATA                        (dma0_axi_rd.data.data), // output [63 : 0] S00_AXI_RDATA
      .S00_AXI_RRESP                        (dma0_axi_rd.data.resp), // output [1 : 0] S00_AXI_RRESP
      .S00_AXI_RLAST                        (dma0_axi_rd.data.last), // output S00_AXI_RLAST
      .S00_AXI_RVALID                       (dma0_axi_rd.data.valid), // output S00_AXI_RVALID
      .S00_AXI_RREADY                       (dma0_axi_rd.data.ready), // input S00_AXI_RREADY
      //
      .S01_AXI_ARESET_OUT_N                 (), // output S01_AXI_ARESET_OUT_N
      .S01_AXI_ACLK                         (ddr3_axi_clk_x2), // input S00_AXI_ACLK
      .S01_AXI_AWID                         (dma1_axi_wr.addr.id), // input [0 : 0] S00_AXI_AWID
      .S01_AXI_AWADDR                       (dma1_axi_wr.addr.addr), // input [31 : 0] S00_AXI_AWADDR
      .S01_AXI_AWLEN                        (dma1_axi_wr.addr.len), // input [7 : 0] S00_AXI_AWLEN
      .S01_AXI_AWSIZE                       (dma1_axi_wr.addr.size), // input [2 : 0] S00_AXI_AWSIZE
      .S01_AXI_AWBURST                      (dma1_axi_wr.addr.burst), // input [1 : 0] S00_AXI_AWBURST
      .S01_AXI_AWLOCK                       (dma1_axi_wr.addr.lock), // input S00_AXI_AWLOCK
      .S01_AXI_AWCACHE                      (dma1_axi_wr.addr.cache), // input [3 : 0] S00_AXI_AWCACHE
      .S01_AXI_AWPROT                       (dma1_axi_wr.addr.prot), // input [2 : 0] S00_AXI_AWPROT
      .S01_AXI_AWQOS                        (dma1_axi_wr.addr.qos), // input [3 : 0] S00_AXI_AWQOS
      .S01_AXI_AWVALID                      (dma1_axi_wr.addr.valid), // input S00_AXI_AWVALID
      .S01_AXI_AWREADY                      (dma1_axi_wr.addr.ready), // output S00_AXI_AWREADY
      .S01_AXI_WDATA                        (dma1_axi_wr.data.data), // input [63 : 0] S00_AXI_WDATA
      .S01_AXI_WSTRB                        (dma1_axi_wr.data.strb), // input [7 : 0] S00_AXI_WSTRB
      .S01_AXI_WLAST                        (dma1_axi_wr.data.last), // input S00_AXI_WLAST
      .S01_AXI_WVALID                       (dma1_axi_wr.data.valid), // input S00_AXI_WVALID
      .S01_AXI_WREADY                       (dma1_axi_wr.data.ready), // output S00_AXI_WREADY
      .S01_AXI_BID                          (dma1_axi_wr.resp.id), // output [0 : 0] S00_AXI_BID
      .S01_AXI_BRESP                        (dma1_axi_wr.resp.resp), // output [1 : 0] S00_AXI_BRESP
      .S01_AXI_BVALID                       (dma1_axi_wr.resp.valid), // output S00_AXI_BVALID
      .S01_AXI_BREADY                       (dma1_axi_wr.resp.ready), // input S00_AXI_BREADY
      .S01_AXI_ARID                         (dma1_axi_rd.addr.id), // input [0 : 0] S00_AXI_ARID
      .S01_AXI_ARADDR                       (dma1_axi_rd.addr.addr), // input [31 : 0] S00_AXI_ARADDR
      .S01_AXI_ARLEN                        (dma1_axi_rd.addr.len), // input [7 : 0] S00_AXI_ARLEN
      .S01_AXI_ARSIZE                       (dma1_axi_rd.addr.size), // input [2 : 0] S00_AXI_ARSIZE
      .S01_AXI_ARBURST                      (dma1_axi_rd.addr.burst), // input [1 : 0] S00_AXI_ARBURST
      .S01_AXI_ARLOCK                       (dma1_axi_rd.addr.lock), // input S00_AXI_ARLOCK
      .S01_AXI_ARCACHE                      (dma1_axi_rd.addr.cache), // input [3 : 0] S00_AXI_ARCACHE
      .S01_AXI_ARPROT                       (dma1_axi_rd.addr.prot), // input [2 : 0] S00_AXI_ARPROT
      .S01_AXI_ARQOS                        (dma1_axi_rd.addr.qos), // input [3 : 0] S00_AXI_ARQOS
      .S01_AXI_ARVALID                      (dma1_axi_rd.addr.valid), // input S00_AXI_ARVALID
      .S01_AXI_ARREADY                      (dma1_axi_rd.addr.ready), // output S00_AXI_ARREADY
      .S01_AXI_RID                          (dma1_axi_rd.data.id), // output [0 : 0] S00_AXI_RID
      .S01_AXI_RDATA                        (dma1_axi_rd.data.data), // output [63 : 0] S00_AXI_RDATA
      .S01_AXI_RRESP                        (dma1_axi_rd.data.resp), // output [1 : 0] S00_AXI_RRESP
      .S01_AXI_RLAST                        (dma1_axi_rd.data.last), // output S00_AXI_RLAST
      .S01_AXI_RVALID                       (dma1_axi_rd.data.valid), // output S00_AXI_RVALID
      .S01_AXI_RREADY                       (dma1_axi_rd.data.ready), // input S00_AXI_RREADY
      //
      .M00_AXI_ARESET_OUT_N                 (), // output M00_AXI_ARESET_OUT_N
      .M00_AXI_ACLK                         (ddr3_axi_clk), // input M00_AXI_ACLK
      .M00_AXI_AWID                         (mig_axi_wr.addr.id), // output [3 : 0] M00_AXI_AWID
      .M00_AXI_AWADDR                       (mig_axi_wr.addr.addr), // output [31 : 0] M00_AXI_AWADDR
      .M00_AXI_AWLEN                        (mig_axi_wr.addr.len), // output [7 : 0] M00_AXI_AWLEN
      .M00_AXI_AWSIZE                       (mig_axi_wr.addr.size), // output [2 : 0] M00_AXI_AWSIZE
      .M00_AXI_AWBURST                      (mig_axi_wr.addr.burst), // output [1 : 0] M00_AXI_AWBURST
      .M00_AXI_AWLOCK                       (mig_axi_wr.addr.lock), // output M00_AXI_AWLOCK
      .M00_AXI_AWCACHE                      (mig_axi_wr.addr.cache), // output [3 : 0] M00_AXI_AWCACHE
      .M00_AXI_AWPROT                       (mig_axi_wr.addr.prot), // output [2 : 0] M00_AXI_AWPROT
      .M00_AXI_AWQOS                        (mig_axi_wr.addr.qos), // output [3 : 0] M00_AXI_AWQOS
      .M00_AXI_AWVALID                      (mig_axi_wr.addr.valid), // output M00_AXI_AWVALID
      .M00_AXI_AWREADY                      (mig_axi_wr.addr.ready), // input M00_AXI_AWREADY
      .M00_AXI_WDATA                        (mig_axi_wr.data.data), // output [127 : 0] M00_AXI_WDATA
      .M00_AXI_WSTRB                        (mig_axi_wr.data.strb), // output [15 : 0] M00_AXI_WSTRB
      .M00_AXI_WLAST                        (mig_axi_wr.data.last), // output M00_AXI_WLAST
      .M00_AXI_WVALID                       (mig_axi_wr.data.valid), // output M00_AXI_WVALID
      .M00_AXI_WREADY                       (mig_axi_wr.data.ready), // input M00_AXI_WREADY
      .M00_AXI_BID                          (mig_axi_wr.resp.id), // input [3 : 0] M00_AXI_BID
      .M00_AXI_BRESP                        (mig_axi_wr.resp.resp), // input [1 : 0] M00_AXI_BRESP
      .M00_AXI_BVALID                       (mig_axi_wr.resp.valid), // input M00_AXI_BVALID
      .M00_AXI_BREADY                       (mig_axi_wr.resp.ready), // output M00_AXI_BREADY
      .M00_AXI_ARID                         (mig_axi_rd.addr.id), // output [3 : 0] M00_AXI_ARID
      .M00_AXI_ARADDR                       (mig_axi_rd.addr.addr), // output [31 : 0] M00_AXI_ARADDR
      .M00_AXI_ARLEN                        (mig_axi_rd.addr.len), // output [7 : 0] M00_AXI_ARLEN
      .M00_AXI_ARSIZE                       (mig_axi_rd.addr.size), // output [2 : 0] M00_AXI_ARSIZE
      .M00_AXI_ARBURST                      (mig_axi_rd.addr.burst), // output [1 : 0] M00_AXI_ARBURST
      .M00_AXI_ARLOCK                       (mig_axi_rd.addr.lock), // output M00_AXI_ARLOCK
      .M00_AXI_ARCACHE                      (mig_axi_rd.addr.cache), // output [3 : 0] M00_AXI_ARCACHE
      .M00_AXI_ARPROT                       (mig_axi_rd.addr.prot), // output [2 : 0] M00_AXI_ARPROT
      .M00_AXI_ARQOS                        (mig_axi_rd.addr.qos), // output [3 : 0] M00_AXI_ARQOS
      .M00_AXI_ARVALID                      (mig_axi_rd.addr.valid), // output M00_AXI_ARVALID
      .M00_AXI_ARREADY                      (mig_axi_rd.addr.ready), // input M00_AXI_ARREADY
      .M00_AXI_RID                          (mig_axi_rd.data.id), // input [3 : 0] M00_AXI_RID
      .M00_AXI_RDATA                        (mig_axi_rd.data.data), // input [127 : 0] M00_AXI_RDATA
      .M00_AXI_RRESP                        (mig_axi_rd.data.resp), // input [1 : 0] M00_AXI_RRESP
      .M00_AXI_RLAST                        (mig_axi_rd.data.last), // input M00_AXI_RLAST
      .M00_AXI_RVALID                       (mig_axi_rd.data.valid), // input M00_AXI_RVALID
      .M00_AXI_RREADY                       (mig_axi_rd.data.ready) // output M00_AXI_RREADY
    );
  
    //---------------------------------------------------
    // MIG
    //---------------------------------------------------
    ddr3_32bit ddr_mig_i (
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
      .init_calib_complete            (init_calib_complete),
  
      .ddr3_cs_n                      (ddr3_cs_n),
      .ddr3_dm                        (ddr3_dm),
      .ddr3_odt                       (ddr3_odt),
      // Application interface ports
      .ui_clk                         (ddr3_axi_clk),  // 150MHz clock out
      .ui_clk_x2                      (ddr3_axi_clk_x2),  // 300MHz clock out
      .ui_clk_div2                      (),  // 75MHz clock out
      .ui_clk_sync_rst                (ddr3_axi_rst),  // Active high Reset signal synchronised to 150MHz
      .aresetn                        (ddr3_axi_rst_reg_n),
      .app_sr_req                     (1'b0),
      .app_sr_active                  (),
      .app_ref_req                    (1'b0),
      .app_ref_ack                    (),
      .app_zq_req                     (1'b0),
      .app_zq_ack                     (),
  
      // Slave Interface Write Address Ports
      .s_axi_awid                     (mig_axi_wr.addr.id),
      .s_axi_awaddr                   (mig_axi_wr.addr.addr),
      .s_axi_awlen                    (mig_axi_wr.addr.len),
      .s_axi_awsize                   (mig_axi_wr.addr.size),
      .s_axi_awburst                  (mig_axi_wr.addr.burst),
      .s_axi_awlock                   (mig_axi_wr.addr.lock),
      .s_axi_awcache                  (mig_axi_wr.addr.cache),
      .s_axi_awprot                   (mig_axi_wr.addr.prot),
      .s_axi_awqos                    (mig_axi_wr.addr.qos),
      .s_axi_awvalid                  (mig_axi_wr.addr.valid),
      .s_axi_awready                  (mig_axi_wr.addr.ready),
      // Slave Interface Write Data Ports
      .s_axi_wdata                    (mig_axi_wr.data.data),
      .s_axi_wstrb                    (mig_axi_wr.data.strb),
      .s_axi_wlast                    (mig_axi_wr.data.last),
      .s_axi_wvalid                   (mig_axi_wr.data.valid),
      .s_axi_wready                   (mig_axi_wr.data.ready),
      // Slave Interface Write Response Ports
      .s_axi_bid                      (mig_axi_wr.resp.id),
      .s_axi_bresp                    (mig_axi_wr.resp.resp),
      .s_axi_bvalid                   (mig_axi_wr.resp.valid),
      .s_axi_bready                   (mig_axi_wr.resp.ready),
      // Slave Interface Read Address Ports
      .s_axi_arid                     (mig_axi_rd.addr.id),
      .s_axi_araddr                   (mig_axi_rd.addr.addr),
      .s_axi_arlen                    (mig_axi_rd.addr.len),
      .s_axi_arsize                   (mig_axi_rd.addr.size),
      .s_axi_arburst                  (mig_axi_rd.addr.burst),
      .s_axi_arlock                   (mig_axi_rd.addr.lock),
      .s_axi_arcache                  (mig_axi_rd.addr.cache),
      .s_axi_arprot                   (mig_axi_rd.addr.prot),
      .s_axi_arqos                    (mig_axi_rd.addr.qos),
      .s_axi_arvalid                  (mig_axi_rd.addr.valid),
      .s_axi_arready                  (mig_axi_rd.addr.ready),
      // Slave Interface Read Data Ports
      .s_axi_rid                      (mig_axi_rd.data.id),
      .s_axi_rdata                    (mig_axi_rd.data.data),
      .s_axi_rresp                    (mig_axi_rd.data.resp),
      .s_axi_rlast                    (mig_axi_rd.data.last),
      .s_axi_rvalid                   (mig_axi_rd.data.valid),
      .s_axi_rready                   (mig_axi_rd.data.ready),
      // System Clock Ports
      .sys_clk_i                      (sys_clk),  // From external 100MHz source.
      .sys_rst                        (sys_rst_n) // IJB. Poorly named active low. Should change RST_ACT_LOW.
    );
  
    //---------------------------------------------------
    // DDR3 SDRAM Models
    //---------------------------------------------------
    ddr3_model #(
      .DEBUG(0)   //Disable verbose prints
    ) sdram_i0 (
      .rst_n    (ddr3_reset_n),
      .ck       (ddr3_ck_p), 
      .ck_n     (ddr3_ck_n),
      .cke      (ddr3_cke), 
      .cs_n     (ddr3_cs_n),
      .ras_n    (ddr3_ras_n), 
      .cas_n    (ddr3_cas_n), 
      .we_n     (ddr3_we_n), 
      .dm_tdqs  (ddr3_dm[1:0]), 
      .ba       (ddr3_ba), 
      .addr     (ddr3_addr), 
      .dq       (ddr3_dq[15:0]), 
      .dqs      (ddr3_dqs_p[1:0]),
      .dqs_n    (ddr3_dqs_n[1:0]),
      .tdqs_n   (), // Unused on x16
      .odt      (ddr3_odt)  
    );
  
    ddr3_model #(
      .DEBUG(0)   //Disable verbose prints
    ) sdram_i1 (
      .rst_n    (ddr3_reset_n),
      .ck       (ddr3_ck_p), 
      .ck_n     (ddr3_ck_n),
      .cke      (ddr3_cke), 
      .cs_n     (ddr3_cs_n),
      .ras_n    (ddr3_ras_n), 
      .cas_n    (ddr3_cas_n), 
      .we_n     (ddr3_we_n), 
      .dm_tdqs  (ddr3_dm[3:2]), 
      .ba       (ddr3_ba), 
      .addr     (ddr3_addr), 
      .dq       (ddr3_dq[31:16]), 
      .dqs      (ddr3_dqs_p[3:2]),
      .dqs_n    (ddr3_dqs_n[3:2]),
      .tdqs_n   (), // Unused on x16
      .odt      (ddr3_odt)
    );

  end endgenerate

endmodule
