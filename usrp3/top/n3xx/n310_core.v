//
// Copyright 2016-2017 Ettus Research, A National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0
//
// Module: n3xx_core
// Description:
// - Motherboard registers
// - Crossbar
// - Radios
// - DMA fifo
//
/////////////////////////////////////////////////////////////////////

module n310_core #(
  parameter REG_DWIDTH  = 32, // Width of the AXI4-Lite data bus (must be 32 or 64)
  parameter REG_AWIDTH  = 32,  // Width of the address bus
  parameter BUS_CLK_RATE = 200000000 // BUS_CLK rate for dram_fifo BIST calculation
)(

 //Clocks and resets
  input         radio_clk,
  input         radio_rst,
  input         bus_clk,
  input         bus_rst,

  // Clocking and PPS Controls/Inidcators
  input            pps,
  output reg[1:0]  pps_select,
  output reg       pps_out_enb,
  output reg       ref_clk_reset,
  output reg       meas_clk_reset,
  input            ref_clk_locked,
  input            meas_clk_locked,

  // AXI lite interface
  input                    s_axi_aclk,
  input                    s_axi_aresetn,
  input [REG_AWIDTH-1:0]   s_axi_awaddr,
  input                    s_axi_awvalid,
  output                   s_axi_awready,

  input [REG_DWIDTH-1:0]   s_axi_wdata,
  input [REG_DWIDTH/8-1:0] s_axi_wstrb,
  input                    s_axi_wvalid,
  output                   s_axi_wready,

  output [1:0]             s_axi_bresp,
  output                   s_axi_bvalid,
  input                    s_axi_bready,

  input [REG_AWIDTH-1:0]   s_axi_araddr,
  input                    s_axi_arvalid,
  output                   s_axi_arready,

  output [REG_DWIDTH-1:0]  s_axi_rdata,
  output [1:0]             s_axi_rresp,
  output                   s_axi_rvalid,
  input                    s_axi_rready,

  //radios gpio dsa
  output [15:0] db_gpio_out0,
  output [15:0] db_gpio_out1,
  output [15:0] db_gpio_out2,
  output [15:0] db_gpio_out3,
  output [15:0] db_gpio_ddr0,
  output [15:0] db_gpio_ddr1,
  output [15:0] db_gpio_ddr2,
  output [15:0] db_gpio_ddr3,
  input  [15:0] db_gpio_in0,
  input  [15:0] db_gpio_in1,
  input  [15:0] db_gpio_in2,
  input  [15:0] db_gpio_in3,
  input  [15:0] db_gpio_fab0,
  input  [15:0] db_gpio_fab1,
  input  [15:0] db_gpio_fab2,
  input  [15:0] db_gpio_fab3,
  //radios atr
  output [3:0] rx_atr,
  output [3:0] tx_atr,
  //radios data
  input  [3:0]  rx_stb,
  input  [3:0]  tx_stb,
  input  [31:0] rx0,
  output [31:0] tx0,
  input  [31:0] rx1,
  output [31:0] tx1,
  // cpld
  output [7:0] sen0,
  output sclk0,
  output mosi0,
  input miso0,
  //radios data
  input  [31:0] rx2,
  output [31:0] tx2,
  input  [31:0] rx3,
  output [31:0] tx3,
  //cpld
  output [7:0] sen1,
  output sclk1,
  output mosi1,
  input miso1,
   // DMA
  output [63:0] dmao_tdata,
  output        dmao_tlast,
  output        dmao_tvalid,
  input         dmao_tready,

  input [63:0]  dmai_tdata,
  input         dmai_tlast,
  input         dmai_tvalid,
  output        dmai_tready,

  //
  // AXI4 (256b@200MHz) interface to DDR3 controller
  //
  input           ddr3_axi_clk,
  input           ddr3_axi_clk_x2,
  input           ddr3_axi_rst,
  input           ddr3_running,
  // Write Address Ports
  output          ddr3_axi_awid,
  output  [31:0]  ddr3_axi_awaddr,
  output  [7:0]   ddr3_axi_awlen,
  output  [2:0]   ddr3_axi_awsize,
  output  [1:0]   ddr3_axi_awburst,
  output  [0:0]   ddr3_axi_awlock,
  output  [3:0]   ddr3_axi_awcache,
  output  [2:0]   ddr3_axi_awprot,
  output  [3:0]   ddr3_axi_awqos,
  output          ddr3_axi_awvalid,
  input           ddr3_axi_awready,
  // Write Data Ports
  output  [255:0] ddr3_axi_wdata,
  output  [31:0]  ddr3_axi_wstrb,
  output          ddr3_axi_wlast,
  output          ddr3_axi_wvalid,
  input           ddr3_axi_wready,
  // Write Response Ports
  output          ddr3_axi_bready,
  input           ddr3_axi_bid,
  input [1:0]     ddr3_axi_bresp,
  input           ddr3_axi_bvalid,
  // Read Address Ports
  output          ddr3_axi_arid,
  output  [31:0]  ddr3_axi_araddr,
  output  [7:0]   ddr3_axi_arlen,
  output  [2:0]   ddr3_axi_arsize,
  output  [1:0]   ddr3_axi_arburst,
  output  [0:0]   ddr3_axi_arlock,
  output  [3:0]   ddr3_axi_arcache,
  output  [2:0]   ddr3_axi_arprot,
  output  [3:0]   ddr3_axi_arqos,
  output          ddr3_axi_arvalid,
  input           ddr3_axi_arready,
  // Read Data Ports
  output          ddr3_axi_rready,
  input           ddr3_axi_rid,
  input [255:0]   ddr3_axi_rdata,
  input [1:0]     ddr3_axi_rresp,
  input           ddr3_axi_rlast,
  input           ddr3_axi_rvalid,

  // v2e (vita to ethernet) and e2v (eth to vita)
  output [63:0] v2e0_tdata,
  output        v2e0_tvalid,
  output        v2e0_tlast,
  input         v2e0_tready,

  output [63:0] v2e1_tdata,
  output        v2e1_tlast,
  output        v2e1_tvalid,
  input         v2e1_tready,

  input  [63:0] e2v0_tdata,
  input         e2v0_tlast,
  input         e2v0_tvalid,
  output        e2v0_tready,

  input  [63:0] e2v1_tdata,
  input         e2v1_tlast,
  input         e2v1_tvalid,
  output        e2v1_tready
);

  localparam NUM_CHANNELS = 1;
  // Number of Radio Cores Instantiated
  localparam NUM_RADIO_CORES = 4;
  // Computation engines that need access to IO
  localparam NUM_IO_CE = NUM_RADIO_CORES+1; //NUM_RADIO_CORES + 1 DMA_FIFO
  localparam COMPAT_MAJOR = 16'b1;
  localparam COMPAT_MINOR = 16'b0;

  /////////////////////////////////////////////////////////////////////////////////
  // Motherboard Registers
  /////////////////////////////////////////////////////////////////////////////////

  // Register base
  localparam REG_BASE_MISC  = 14'h0;
  localparam REG_BASE_XBAR  = 14'h1000;

  // Misc Registers
  localparam REG_DESIGN_REV  = REG_BASE_MISC + 14'h0;
  localparam REG_DATESTAMP   = REG_BASE_MISC + 14'h4;
  localparam REG_GIT_HASH    = REG_BASE_MISC + 14'h8;
  localparam REG_BUS_COUNTER = REG_BASE_MISC + 14'hC;
  localparam REG_NUM_CE      = REG_BASE_MISC + 14'h10;
  localparam REG_SCRATCH     = REG_BASE_MISC + 14'h14;
  localparam REG_CLOCK_CTRL  = REG_BASE_MISC + 14'h18;

  reg [31:0] scratch_reg = 32'b0;
  reg [31:0] datestamp = 32'b0;
  reg [31:0] bus_counter = 32'h0;

  always @(posedge bus_clk) begin
     if (bus_rst)
        bus_counter <= 32'd0;
     else
        bus_counter <= bus_counter + 32'd1;
  end

  wire                     reg_wr_req;
  wire [REG_AWIDTH-1:0]    reg_wr_addr;
  wire [REG_DWIDTH-1:0]    reg_wr_data;
  wire [REG_DWIDTH/8-1:0]  reg_wr_keep;
  wire                     reg_rd_req;
  wire  [REG_AWIDTH-1:0]   reg_rd_addr;
  wire                     reg_rd_resp;
  wire  [REG_DWIDTH-1:0]   reg_rd_data;

  reg                      reg_rd_resp_glob;
  reg   [REG_DWIDTH-1:0]   reg_rd_data_glob;

  wire  [REG_DWIDTH-1:0]   reg_rd_data_xbar;
  wire                     reg_rd_resp_xbar;

  regport_resp_mux #(.WIDTH(REG_DWIDTH)) inst_regport_resp_mux
  (
    .clk(bus_clk),
    .reset(bus_rst),
    .sla_rd_resp({reg_rd_resp_glob, reg_rd_resp_xbar}),
    .sla_rd_data({reg_rd_data_glob, reg_rd_data_xbar}),
    .mst_rd_resp(reg_rd_resp),
    .mst_rd_data(reg_rd_data)
  );

  axil_regport_master #(
    .DWIDTH   (REG_DWIDTH), // Width of the AXI4-Lite data bus (must be 32 or 64)
    .AWIDTH   (REG_AWIDTH), // Width of the address bus
    .WRBASE   (0),          // Write address base
    .RDBASE   (0),          // Read address base
    .TIMEOUT  (10)          // log2(timeout). Read will timeout after (2^TIMEOUT - 1) cycles
  ) regport_master_i (
    // Clock and reset
    .s_axi_aclk    (s_axi_aclk),
    .s_axi_aresetn (s_axi_aresetn),
    // AXI4-Lite: Write address port (domain: s_axi_aclk)
    .s_axi_awaddr  (s_axi_awaddr),
    .s_axi_awvalid (s_axi_awvalid),
    .s_axi_awready (s_axi_awready),
    // AXI4-Lite: Write data port (domain: s_axi_aclk)
    .s_axi_wdata   (s_axi_wdata),
    .s_axi_wstrb   (s_axi_wstrb),
    .s_axi_wvalid  (s_axi_wvalid),
    .s_axi_wready  (s_axi_wready),
    // AXI4-Lite: Write response port (domain: s_axi_aclk)
    .s_axi_bresp   (s_axi_bresp),
    .s_axi_bvalid  (s_axi_bvalid),
    .s_axi_bready  (s_axi_bready),
    // AXI4-Lite: Read address port (domain: s_axi_aclk)
    .s_axi_araddr  (s_axi_araddr),
    .s_axi_arvalid (s_axi_arvalid),
    .s_axi_arready (s_axi_arready),
    // AXI4-Lite: Read data port (domain: s_axi_aclk)
    .s_axi_rdata   (s_axi_rdata),
    .s_axi_rresp   (s_axi_rresp),
    .s_axi_rvalid  (s_axi_rvalid),
    .s_axi_rready  (s_axi_rready),
    // Register port: Write port (domain: reg_clk)
    .reg_clk       (bus_clk),
    .reg_wr_req    (reg_wr_req),
    .reg_wr_addr   (reg_wr_addr),
    .reg_wr_data   (reg_wr_data),
    .reg_wr_keep   (/*unused*/),
    // Register port: Read port (domain: reg_clk)
    .reg_rd_req    (reg_rd_req),
    .reg_rd_addr   (reg_rd_addr),
    .reg_rd_resp   (reg_rd_resp),
    .reg_rd_data   (reg_rd_data)
  );

  reg b_ref_clk_locked_ms;
  reg b_ref_clk_locked;
  reg b_meas_clk_locked_ms;
  reg b_meas_clk_locked;

  always @ (posedge bus_clk)
    if (bus_rst) begin
      scratch_reg    <= 32'h0;
      pps_select     <= 2'h1;
      pps_out_enb    <= 1'b0;
      ref_clk_reset  <= 1'b0;
      meas_clk_reset <= 1'b0;
    end
    else begin
      if (reg_wr_req)
        case (reg_wr_addr)
          REG_SCRATCH:
            scratch_reg <= reg_wr_data;
          REG_CLOCK_CTRL: begin
            pps_select     <= reg_wr_data[1:0];
            pps_out_enb    <= reg_wr_data[4];
            ref_clk_reset  <= reg_wr_data[8];
            meas_clk_reset <= reg_wr_data[12];
            end
        endcase
    end

  always @ (posedge bus_clk)
    if (bus_rst) begin
      reg_rd_resp_glob <= 1'b0;
      b_ref_clk_locked_ms  <= 1'b0;
      b_ref_clk_locked     <= 1'b0;
      b_meas_clk_locked_ms <= 1'b0;
      b_meas_clk_locked    <= 1'b0;
    end
    else begin

      // double-sync the locked bits into the bus_clk domain before using them
      b_ref_clk_locked_ms  <= ref_clk_locked;
      b_ref_clk_locked     <= b_ref_clk_locked_ms;
      b_meas_clk_locked_ms <= meas_clk_locked;
      b_meas_clk_locked    <= b_meas_clk_locked_ms;


      if (reg_rd_req) begin
        reg_rd_resp_glob <= 1'b1;

        case (reg_rd_addr)
        REG_DESIGN_REV:
          reg_rd_data_glob <= {COMPAT_MAJOR, COMPAT_MINOR};

        // Placeholder for datestamp
        REG_DATESTAMP:
          reg_rd_data_glob <= datestamp;

        REG_GIT_HASH:
          reg_rd_data_glob <= 32'h`GIT_HASH;

        REG_BUS_COUNTER:
          reg_rd_data_glob <= bus_counter;

        REG_NUM_CE:
          reg_rd_data_glob <= NUM_CE;

        REG_SCRATCH:
          reg_rd_data_glob <= scratch_reg;

        REG_CLOCK_CTRL: begin
          reg_rd_data_glob <= 32'b0;
          reg_rd_data_glob[1:0] <= pps_select;
          reg_rd_data_glob[4]   <= pps_out_enb;
          reg_rd_data_glob[8]   <= ref_clk_reset;
          reg_rd_data_glob[9]   <= b_ref_clk_locked;
          reg_rd_data_glob[12]  <= meas_clk_reset;
          reg_rd_data_glob[13]  <= b_meas_clk_locked;
          end

        default:
          reg_rd_resp_glob <= 1'b0;
        endcase
      end
      else if (reg_rd_resp_glob) begin
          reg_rd_resp_glob <= 1'b0;
      end
    end

   //
   // ioce
   //

   wire     [NUM_IO_CE*64-1:0]  ioce_flat_o_tdata;
   wire     [NUM_IO_CE*64-1:0]  ioce_flat_i_tdata;
   wire     [63:0]              ioce_o_tdata[0:NUM_IO_CE-1];
   wire     [63:0]              ioce_i_tdata[0:NUM_IO_CE-1];
   wire     [NUM_IO_CE-1:0]     ioce_o_tlast;
   wire     [NUM_IO_CE-1:0]     ioce_o_tvalid;
   wire     [NUM_IO_CE-1:0]     ioce_o_tready;
   wire     [NUM_IO_CE-1:0]     ioce_i_tlast;
   wire     [NUM_IO_CE-1:0]     ioce_i_tvalid;
   wire     [NUM_IO_CE-1:0]     ioce_i_tready;

   genvar ioce_i;
   generate for (ioce_i = 0; ioce_i < NUM_IO_CE; ioce_i = ioce_i + 1) begin
      assign ioce_o_tdata[ioce_i] = ioce_flat_o_tdata[ioce_i*64 + 63 : ioce_i*64];
      assign ioce_flat_i_tdata[ioce_i*64+63:ioce_i*64] = ioce_i_tdata[ioce_i];
   end endgenerate


   /////////////////////////////////////////////////////////////////////////////////////////////
   //
   // DRAM FIFO
   //
   /////////////////////////////////////////////////////////////////////////////////////////////

   // AXI4 MM buses
   wire        s00_axi_awready, s01_axi_awready;
   wire [0:0]  s00_axi_awid, s01_axi_awid;
   wire [31:0] s00_axi_awaddr, s01_axi_awaddr;
   wire [7:0]  s00_axi_awlen, s01_axi_awlen;
   wire [2:0]  s00_axi_awsize, s01_axi_awsize;
   wire [1:0]  s00_axi_awburst, s01_axi_awburst;
   wire [0:0]  s00_axi_awlock, s01_axi_awlock;
   wire [3:0]  s00_axi_awcache, s01_axi_awcache;
   wire [2:0]  s00_axi_awprot, s01_axi_awprot;
   wire [3:0]  s00_axi_awqos, s01_axi_awqos;
   wire [3:0]  s00_axi_awregion, s01_axi_awregion;
   wire [0:0]  s00_axi_awuser, s01_axi_awuser;
   wire        s00_axi_wready, s01_axi_wready;
   wire [63:0] s00_axi_wdata, s01_axi_wdata;
   wire [7:0]  s00_axi_wstrb, s01_axi_wstrb;
   wire [0:0]  s00_axi_wuser, s01_axi_wuser;
   wire        s00_axi_bvalid, s01_axi_bvalid;
   wire [0:0]  s00_axi_bid, s01_axi_bid;
   wire [1:0]  s00_axi_bresp, s01_axi_bresp;
   wire [0:0]  s00_axi_buser, s01_axi_buser;
   wire        s00_axi_arready, s01_axi_arready;
   wire [0:0]  s00_axi_arid, s01_axi_arid;
   wire [31:0] s00_axi_araddr, s01_axi_araddr;
   wire [7:0]  s00_axi_arlen, s01_axi_arlen;
   wire [2:0]  s00_axi_arsize, s01_axi_arsize;
   wire [1:0]  s00_axi_arburst, s01_axi_arburst;
   wire [0:0]  s00_axi_arlock, s01_axi_arlock;
   wire [3:0]  s00_axi_arcache, s01_axi_arcache;
   wire [2:0]  s00_axi_arprot, s01_axi_arprot;
   wire [3:0]  s00_axi_arqos, s01_axi_arqos;
   wire [3:0]  s00_axi_arregion, s01_axi_arregion;
   wire [0:0]  s00_axi_aruser, s01_axi_aruser;
   wire        s00_axi_rlast, s01_axi_rlast;
   wire        s00_axi_rvalid, s01_axi_rvalid;
   wire        s00_axi_awvalid, s01_axi_awvalid;
   wire        s00_axi_wlast, s01_axi_wlast;
   wire        s00_axi_wvalid, s01_axi_wvalid;
   wire        s00_axi_bready, s01_axi_bready;
   wire        s00_axi_arvalid, s01_axi_arvalid;
   wire        s00_axi_rready, s01_axi_rready;
   wire [0:0]  s00_axi_rid, s01_axi_rid;
   wire [63:0] s00_axi_rdata, s01_axi_rdata;
   wire [1:0]  s00_axi_rresp, s01_axi_rresp;
   wire [0:0]  s00_axi_ruser, s01_axi_ruser;

   axi_intercon_2x64_256_bd_wrapper axi_intercon_2x64_256_bd_i (
      .INTERCONNECT_ACLK(ddr3_axi_clk_x2), // input INTERCONNECT_ACLK
      .INTERCONNECT_ARESETN(~ddr3_axi_rst), // input INTERCONNECT_ARESETN
      //
      .S00_AXI_ACLK(ddr3_axi_clk_x2), // input S00_AXI_ACLK
      .S00_AXI_ARESETN(~ddr3_axi_rst), // input S00_AXI_ARESETN
      .S00_AXI_AWID(s00_axi_awid), // input [0 : 0] S00_AXI_AWID
      .S00_AXI_AWADDR(s00_axi_awaddr), // input [31 : 0] S00_AXI_AWADDR
      .S00_AXI_AWLEN(s00_axi_awlen), // input [7 : 0] S00_AXI_AWLEN
      .S00_AXI_AWSIZE(s00_axi_awsize), // input [2 : 0] S00_AXI_AWSIZE
      .S00_AXI_AWBURST(s00_axi_awburst), // input [1 : 0] S00_AXI_AWBURST
      .S00_AXI_AWLOCK(s00_axi_awlock), // input S00_AXI_AWLOCK
      .S00_AXI_AWCACHE(s00_axi_awcache), // input [3 : 0] S00_AXI_AWCACHE
      .S00_AXI_AWPROT(s00_axi_awprot), // input [2 : 0] S00_AXI_AWPROT
      .S00_AXI_AWQOS(s00_axi_awqos), // input [3 : 0] S00_AXI_AWQOS
      .S00_AXI_AWVALID(s00_axi_awvalid), // input S00_AXI_AWVALID
      .S00_AXI_AWREADY(s00_axi_awready), // output S00_AXI_AWREADY
      .S00_AXI_WDATA(s00_axi_wdata), // input [63 : 0] S00_AXI_WDATA
      .S00_AXI_WSTRB(s00_axi_wstrb), // input [7 : 0] S00_AXI_WSTRB
      .S00_AXI_WLAST(s00_axi_wlast), // input S00_AXI_WLAST
      .S00_AXI_WVALID(s00_axi_wvalid), // input S00_AXI_WVALID
      .S00_AXI_WREADY(s00_axi_wready), // output S00_AXI_WREADY
      .S00_AXI_BID(s00_axi_bid), // output [0 : 0] S00_AXI_BID
      .S00_AXI_BRESP(s00_axi_bresp), // output [1 : 0] S00_AXI_BRESP
      .S00_AXI_BVALID(s00_axi_bvalid), // output S00_AXI_BVALID
      .S00_AXI_BREADY(s00_axi_bready), // input S00_AXI_BREADY
      .S00_AXI_ARID(s00_axi_arid), // input [0 : 0] S00_AXI_ARID
      .S00_AXI_ARADDR(s00_axi_araddr), // input [31 : 0] S00_AXI_ARADDR
      .S00_AXI_ARLEN(s00_axi_arlen), // input [7 : 0] S00_AXI_ARLEN
      .S00_AXI_ARSIZE(s00_axi_arsize), // input [2 : 0] S00_AXI_ARSIZE
      .S00_AXI_ARBURST(s00_axi_arburst), // input [1 : 0] S00_AXI_ARBURST
      .S00_AXI_ARLOCK(s00_axi_arlock), // input S00_AXI_ARLOCK
      .S00_AXI_ARCACHE(s00_axi_arcache), // input [3 : 0] S00_AXI_ARCACHE
      .S00_AXI_ARPROT(s00_axi_arprot), // input [2 : 0] S00_AXI_ARPROT
      .S00_AXI_ARQOS(s00_axi_arqos), // input [3 : 0] S00_AXI_ARQOS
      .S00_AXI_ARVALID(s00_axi_arvalid), // input S00_AXI_ARVALID
      .S00_AXI_ARREADY(s00_axi_arready), // output S00_AXI_ARREADY
      .S00_AXI_RID(s00_axi_rid), // output [0 : 0] S00_AXI_RID
      .S00_AXI_RDATA(s00_axi_rdata), // output [63 : 0] S00_AXI_RDATA
      .S00_AXI_RRESP(s00_axi_rresp), // output [1 : 0] S00_AXI_RRESP
      .S00_AXI_RLAST(s00_axi_rlast), // output S00_AXI_RLAST
      .S00_AXI_RVALID(s00_axi_rvalid), // output S00_AXI_RVALID
      .S00_AXI_RREADY(s00_axi_rready), // input S00_AXI_RREADY
      //
      .S01_AXI_ACLK(ddr3_axi_clk_x2), // input S01_AXI_ACLK
      .S01_AXI_ARESETN(~ddr3_axi_rst), // input S00_AXI_ARESETN
      .S01_AXI_AWID(s01_axi_awid), // input [0 : 0] S01_AXI_AWID
      .S01_AXI_AWADDR(s01_axi_awaddr), // input [31 : 0] S01_AXI_AWADDR
      .S01_AXI_AWLEN(s01_axi_awlen), // input [7 : 0] S01_AXI_AWLEN
      .S01_AXI_AWSIZE(s01_axi_awsize), // input [2 : 0] S01_AXI_AWSIZE
      .S01_AXI_AWBURST(s01_axi_awburst), // input [1 : 0] S01_AXI_AWBURST
      .S01_AXI_AWLOCK(s01_axi_awlock), // input S01_AXI_AWLOCK
      .S01_AXI_AWCACHE(s01_axi_awcache), // input [3 : 0] S01_AXI_AWCACHE
      .S01_AXI_AWPROT(s01_axi_awprot), // input [2 : 0] S01_AXI_AWPROT
      .S01_AXI_AWQOS(s01_axi_awqos), // input [3 : 0] S01_AXI_AWQOS
      .S01_AXI_AWVALID(s01_axi_awvalid), // input S01_AXI_AWVALID
      .S01_AXI_AWREADY(s01_axi_awready), // output S01_AXI_AWREADY
      .S01_AXI_WDATA(s01_axi_wdata), // input [63 : 0] S01_AXI_WDATA
      .S01_AXI_WSTRB(s01_axi_wstrb), // input [7 : 0] S01_AXI_WSTRB
      .S01_AXI_WLAST(s01_axi_wlast), // input S01_AXI_WLAST
      .S01_AXI_WVALID(s01_axi_wvalid), // input S01_AXI_WVALID
      .S01_AXI_WREADY(s01_axi_wready), // output S01_AXI_WREADY
      .S01_AXI_BID(s01_axi_bid), // output [0 : 0] S01_AXI_BID
      .S01_AXI_BRESP(s01_axi_bresp), // output [1 : 0] S01_AXI_BRESP
      .S01_AXI_BVALID(s01_axi_bvalid), // output S01_AXI_BVALID
      .S01_AXI_BREADY(s01_axi_bready), // input S01_AXI_BREADY
      .S01_AXI_ARID(s01_axi_arid), // input [0 : 0] S01_AXI_ARID
      .S01_AXI_ARADDR(s01_axi_araddr), // input [31 : 0] S01_AXI_ARADDR
      .S01_AXI_ARLEN(s01_axi_arlen), // input [7 : 0] S01_AXI_ARLEN
      .S01_AXI_ARSIZE(s01_axi_arsize), // input [2 : 0] S01_AXI_ARSIZE
      .S01_AXI_ARBURST(s01_axi_arburst), // input [1 : 0] S01_AXI_ARBURST
      .S01_AXI_ARLOCK(s01_axi_arlock), // input S01_AXI_ARLOCK
      .S01_AXI_ARCACHE(s01_axi_arcache), // input [3 : 0] S01_AXI_ARCACHE
      .S01_AXI_ARPROT(s01_axi_arprot), // input [2 : 0] S01_AXI_ARPROT
      .S01_AXI_ARQOS(s01_axi_arqos), // input [3 : 0] S01_AXI_ARQOS
      .S01_AXI_ARVALID(s01_axi_arvalid), // input S01_AXI_ARVALID
      .S01_AXI_ARREADY(s01_axi_arready), // output S01_AXI_ARREADY
      .S01_AXI_RID(s01_axi_rid), // output [0 : 0] S01_AXI_RID
      .S01_AXI_RDATA(s01_axi_rdata), // output [63 : 0] S01_AXI_RDATA
      .S01_AXI_RRESP(s01_axi_rresp), // output [1 : 0] S01_AXI_RRESP
      .S01_AXI_RLAST(s01_axi_rlast), // output S01_AXI_RLAST
      .S01_AXI_RVALID(s01_axi_rvalid), // output S01_AXI_RVALID
      .S01_AXI_RREADY(s01_axi_rready), // input S01_AXI_RREADY
      //
      .M00_AXI_ACLK(ddr3_axi_clk), // input M00_AXI_ACLK
      .M00_AXI_ARESETN(~ddr3_axi_rst), // input S00_AXI_ARESETN
      .M00_AXI_AWID(ddr3_axi_awid), // output [3 : 0] M00_AXI_AWID
      .M00_AXI_AWADDR(ddr3_axi_awaddr), // output [31 : 0] M00_AXI_AWADDR
      .M00_AXI_AWLEN(ddr3_axi_awlen), // output [7 : 0] M00_AXI_AWLEN
      .M00_AXI_AWSIZE(ddr3_axi_awsize), // output [2 : 0] M00_AXI_AWSIZE
      .M00_AXI_AWBURST(ddr3_axi_awburst), // output [1 : 0] M00_AXI_AWBURST
      .M00_AXI_AWLOCK(ddr3_axi_awlock), // output M00_AXI_AWLOCK
      .M00_AXI_AWCACHE(ddr3_axi_awcache), // output [3 : 0] M00_AXI_AWCACHE
      .M00_AXI_AWPROT(ddr3_axi_awprot), // output [2 : 0] M00_AXI_AWPROT
      .M00_AXI_AWQOS(ddr3_axi_awqos), // output [3 : 0] M00_AXI_AWQOS
      .M00_AXI_AWVALID(ddr3_axi_awvalid), // output M00_AXI_AWVALID
      .M00_AXI_AWREADY(ddr3_axi_awready), // input M00_AXI_AWREADY
      .M00_AXI_WDATA(ddr3_axi_wdata), // output [127 : 0] M00_AXI_WDATA
      .M00_AXI_WSTRB(ddr3_axi_wstrb), // output [15 : 0] M00_AXI_WSTRB
      .M00_AXI_WLAST(ddr3_axi_wlast), // output M00_AXI_WLAST
      .M00_AXI_WVALID(ddr3_axi_wvalid), // output M00_AXI_WVALID
      .M00_AXI_WREADY(ddr3_axi_wready), // input M00_AXI_WREADY
      .M00_AXI_BID(ddr3_axi_bid), // input [3 : 0] M00_AXI_BID
      .M00_AXI_BRESP(ddr3_axi_bresp), // input [1 : 0] M00_AXI_BRESP
      .M00_AXI_BVALID(ddr3_axi_bvalid), // input M00_AXI_BVALID
      .M00_AXI_BREADY(ddr3_axi_bready), // output M00_AXI_BREADY
      .M00_AXI_ARID(ddr3_axi_arid), // output [3 : 0] M00_AXI_ARID
      .M00_AXI_ARADDR(ddr3_axi_araddr), // output [31 : 0] M00_AXI_ARADDR
      .M00_AXI_ARLEN(ddr3_axi_arlen), // output [7 : 0] M00_AXI_ARLEN
      .M00_AXI_ARSIZE(ddr3_axi_arsize), // output [2 : 0] M00_AXI_ARSIZE
      .M00_AXI_ARBURST(ddr3_axi_arburst), // output [1 : 0] M00_AXI_ARBURST
      .M00_AXI_ARLOCK(ddr3_axi_arlock), // output M00_AXI_ARLOCK
      .M00_AXI_ARCACHE(ddr3_axi_arcache), // output [3 : 0] M00_AXI_ARCACHE
      .M00_AXI_ARPROT(ddr3_axi_arprot), // output [2 : 0] M00_AXI_ARPROT
      .M00_AXI_ARQOS(ddr3_axi_arqos), // output [3 : 0] M00_AXI_ARQOS
      .M00_AXI_ARVALID(ddr3_axi_arvalid), // output M00_AXI_ARVALID
      .M00_AXI_ARREADY(ddr3_axi_arready), // input M00_AXI_ARREADY
      .M00_AXI_RID(ddr3_axi_rid), // input [3 : 0] M00_AXI_RID
      .M00_AXI_RDATA(ddr3_axi_rdata), // input [127 : 0] M00_AXI_RDATA
      .M00_AXI_RRESP(ddr3_axi_rresp), // input [1 : 0] M00_AXI_RRESP
      .M00_AXI_RLAST(ddr3_axi_rlast), // input M00_AXI_RLAST
      .M00_AXI_RVALID(ddr3_axi_rvalid), // input M00_AXI_RVALID
      .M00_AXI_RREADY(ddr3_axi_rready) // output M00_AXI_RREADY
   );

   noc_block_axi_dma_fifo #(
      .NUM_FIFOS(2),
      .BUS_CLK_RATE(BUS_CLK_RATE), //200MHz
      .DEFAULT_FIFO_BASE({30'h02000000, 30'h00000000}),
      .DEFAULT_FIFO_SIZE({30'h01FFFFFF, 30'h01FFFFFF}),
      .STR_SINK_FIFOSIZE(14),
      .DEFAULT_BURST_TIMEOUT({12'd280, 12'd280}),
      .EXTENDED_DRAM_BIST(1)
   ) inst_noc_block_dram_fifo (
      .bus_clk(bus_clk), .bus_rst(bus_rst),
      .ce_clk(ddr3_axi_clk_x2), .ce_rst(ddr3_axi_rst),
      //AXIS
      .i_tdata(ioce_o_tdata[0]), .i_tlast(ioce_o_tlast[0]), .i_tvalid(ioce_o_tvalid[0]), .i_tready(ioce_o_tready[0]),
      .o_tdata(ioce_i_tdata[0]), .o_tlast(ioce_i_tlast[0]), .o_tvalid(ioce_i_tvalid[0]), .o_tready(ioce_i_tready[0]),
      //AXI
      .m_axi_awid({s01_axi_awid, s00_axi_awid}),
      .m_axi_awaddr({s01_axi_awaddr, s00_axi_awaddr}),
      .m_axi_awlen({s01_axi_awlen, s00_axi_awlen}),
      .m_axi_awsize({s01_axi_awsize, s00_axi_awsize}),
      .m_axi_awburst({s01_axi_awburst, s00_axi_awburst}),
      .m_axi_awlock({s01_axi_awlock, s00_axi_awlock}),
      .m_axi_awcache({s01_axi_awcache, s00_axi_awcache}),
      .m_axi_awprot({s01_axi_awprot, s00_axi_awprot}),
      .m_axi_awqos({s01_axi_awqos, s00_axi_awqos}),
      .m_axi_awregion({s01_axi_awregion, s00_axi_awregion}),
      .m_axi_awuser({s01_axi_awuser, s00_axi_awuser}),
      .m_axi_awvalid({s01_axi_awvalid, s00_axi_awvalid}),
      .m_axi_awready({s01_axi_awready, s00_axi_awready}),
      .m_axi_wdata({s01_axi_wdata, s00_axi_wdata}),
      .m_axi_wstrb({s01_axi_wstrb, s00_axi_wstrb}),
      .m_axi_wlast({s01_axi_wlast, s00_axi_wlast}),
      .m_axi_wuser({s01_axi_wuser, s00_axi_wuser}),
      .m_axi_wvalid({s01_axi_wvalid, s00_axi_wvalid}),
      .m_axi_wready({s01_axi_wready, s00_axi_wready}),
      .m_axi_bid({s01_axi_bid, s00_axi_bid}),
      .m_axi_bresp({s01_axi_bresp, s00_axi_bresp}),
      .m_axi_buser({s01_axi_buser, s00_axi_buser}),
      .m_axi_bvalid({s01_axi_bvalid, s00_axi_bvalid}),
      .m_axi_bready({s01_axi_bready, s00_axi_bready}),
      .m_axi_arid({s01_axi_arid, s00_axi_arid}),
      .m_axi_araddr({s01_axi_araddr, s00_axi_araddr}),
      .m_axi_arlen({s01_axi_arlen, s00_axi_arlen}),
      .m_axi_arsize({s01_axi_arsize, s00_axi_arsize}),
      .m_axi_arburst({s01_axi_arburst, s00_axi_arburst}),
      .m_axi_arlock({s01_axi_arlock, s00_axi_arlock}),
      .m_axi_arcache({s01_axi_arcache, s00_axi_arcache}),
      .m_axi_arprot({s01_axi_arprot, s00_axi_arprot}),
      .m_axi_arqos({s01_axi_arqos, s00_axi_arqos}),
      .m_axi_arregion({s01_axi_arregion, s00_axi_arregion}),
      .m_axi_aruser({s01_axi_aruser, s00_axi_aruser}),
      .m_axi_arvalid({s01_axi_arvalid, s00_axi_arvalid}),
      .m_axi_arready({s01_axi_arready, s00_axi_arready}),
      .m_axi_rid({s01_axi_rid, s00_axi_rid}),
      .m_axi_rdata({s01_axi_rdata, s00_axi_rdata}),
      .m_axi_rresp({s01_axi_rresp, s00_axi_rresp}),
      .m_axi_rlast({s01_axi_rlast, s00_axi_rlast}),
      .m_axi_ruser({s01_axi_ruser, s00_axi_ruser}),
      .m_axi_rvalid({s01_axi_rvalid, s00_axi_rvalid}),
      .m_axi_rready({s01_axi_rready, s00_axi_rready}),

      .debug()
   );

   /////////////////////////////////////////////////////////////////////////////////////////////
   //
   // Radios
   //
   /////////////////////////////////////////////////////////////////////////////

   localparam FIRST_RADIO_CORE_INST = 1;
   localparam LAST_RADIO_CORE_INST = NUM_RADIO_CORES+FIRST_RADIO_CORE_INST;
   localparam RADIO_STR_FIFO_SIZE = 8'd11;

   //------------------------------------
   // Radios
   //------------------------------------
   wire [7:0]  sen[0:3];
   wire        sclk[0:3], mosi[0:3], miso[0:3];
   // Data
   wire [31:0] rx[0:3], rx_data[0:3], tx[0:3], tx_data[0:3];
   wire        db_fe_set_stb[0:3];
   wire [7:0]  db_fe_set_addr[0:3];
   wire [31:0] db_fe_set_data[0:3];
   wire        db_fe_rb_stb[0:3];
   wire [7:0]  db_fe_rb_addr[0:3];
   wire [64:0] db_fe_rb_data[0:3];
   wire        rx_running[0:3], tx_running[0:3];
   wire [NUM_RADIO_CORES-1:0] sync_out;

   assign rx_atr[0] = rx_running[0];
   assign rx_atr[1] = rx_running[1];
   assign rx_atr[2] = rx_running[2];
   assign rx_atr[3] = rx_running[3];
   assign tx_atr[0] = tx_running[0];
   assign tx_atr[1] = tx_running[1];
   assign tx_atr[2] = tx_running[2];
   assign tx_atr[3] = tx_running[3];
   genvar i;
   generate for (i = FIRST_RADIO_CORE_INST; i < LAST_RADIO_CORE_INST; i = i + 1) begin
      noc_block_radio_core #(
         .NOC_ID(64'h12AD_1000_0000_0310),
         .NUM_CHANNELS(NUM_CHANNELS),
         .STR_SINK_FIFOSIZE({NUM_CHANNELS{RADIO_STR_FIFO_SIZE}}),
         .MTU(13)
      ) noc_block_radio_core_i (
         //Clocks
         .bus_clk(bus_clk), .bus_rst(bus_rst),
         .ce_clk(radio_clk), .ce_rst(radio_rst),
         //AXIS data to/from crossbar
         .i_tdata(ioce_o_tdata[i]), .i_tlast(ioce_o_tlast[i]), .i_tvalid(ioce_o_tvalid[i]), .i_tready(ioce_o_tready[i]),
         .o_tdata(ioce_i_tdata[i]), .o_tlast(ioce_i_tlast[i]), .o_tvalid(ioce_i_tvalid[i]), .o_tready(ioce_i_tready[i]),
         // Data ports connected to radio front end
         .rx(    {rx_data[i-FIRST_RADIO_CORE_INST]}),
         .rx_stb({rx_stb[i-FIRST_RADIO_CORE_INST]}),
         .tx(    {tx_data[i-FIRST_RADIO_CORE_INST]}),
         .tx_stb({tx_stb[i-FIRST_RADIO_CORE_INST]}),
         // Timing and sync
         .pps(pps), .sync_in(1'b0), .sync_out(sync_out[i]),
         .rx_running({rx_running[i-FIRST_RADIO_CORE_INST]}),
         .tx_running({tx_running[i-FIRST_RADIO_CORE_INST]}),
         // Ctrl ports connected to radio dboard and front end core
         .db_fe_set_stb ({db_fe_set_stb [i-FIRST_RADIO_CORE_INST]}),
         .db_fe_set_addr({db_fe_set_addr[i-FIRST_RADIO_CORE_INST]}),
         .db_fe_set_data({db_fe_set_data[i-FIRST_RADIO_CORE_INST]}),
         .db_fe_rb_stb  ({db_fe_rb_stb  [i-FIRST_RADIO_CORE_INST]}),
         .db_fe_rb_addr ({db_fe_rb_addr [i-FIRST_RADIO_CORE_INST]}),
         .db_fe_rb_data ({db_fe_rb_data [i-FIRST_RADIO_CORE_INST]}),
         //Debug
         .debug()
      );
   end endgenerate

   /////////////////////////////////////////////////////////////////////////////////
   // TX/RX FrontEnd
   /////////////////////////////////////////////////////////////////////////////////
   wire [15:0] db_gpio_in[0:3];
   wire [15:0] db_gpio_out[0:3];
   wire [15:0] db_gpio_ddr[0:3];
   wire [15:0] db_gpio_fab[0:3];
   assign {rx[0], rx[1]} = {rx0, rx1};
   assign {rx[2], rx[3]} = {rx2, rx3};
   assign {tx0, tx1} = {tx[0], tx[1]};
   assign {tx2, tx3} = {tx[2], tx[3]};
   assign {miso[0], miso[2]} = {miso0, miso1};
   assign {sclk0, sclk1} = {sclk[0], sclk[2]};
   assign {sen0, sen1} = {sen[0], sen[2]} ;
   assign {mosi0, mosi1} = {mosi[0], mosi[2]};
   assign {db_gpio_out0, db_gpio_out1} = {db_gpio_out[0], db_gpio_out[1]};
   assign {db_gpio_out2, db_gpio_out3} = {db_gpio_out[2], db_gpio_out[3]};
   assign {db_gpio_ddr0, db_gpio_ddr1} = {db_gpio_ddr[0], db_gpio_ddr[1]};
   assign {db_gpio_ddr2, db_gpio_ddr3} = {db_gpio_ddr[2], db_gpio_ddr[3]};
   assign {db_gpio_in[0],db_gpio_in[1]} = {db_gpio_in0, db_gpio_in1};
   assign {db_gpio_in[2],db_gpio_in[3]} = {db_gpio_in2, db_gpio_in3};
   assign {db_gpio_fab[0],db_gpio_fab[1]} = {db_gpio_fab0, db_gpio_fab1};
   assign {db_gpio_fab[2],db_gpio_fab[3]} = {db_gpio_fab2, db_gpio_fab3};

   generate for (i = 0; i < NUM_RADIO_CORES*NUM_CHANNELS; i = i + 1) begin
      n3xx_db_fe_core db_fe_core_i (
         .clk(radio_clk), .reset(radio_rst),
         .set_stb(db_fe_set_stb[i]), .set_addr(db_fe_set_addr[i]), .set_data(db_fe_set_data[i]),
         .rb_stb(db_fe_rb_stb[i]),  .rb_addr(db_fe_rb_addr[i]), .rb_data(db_fe_rb_data[i]),
         .time_sync(sync_out[i < 2 ? 0 : 1]),
         .tx_stb(tx_stb[i]), .tx_data_in(tx_data[i]), .tx_data_out(tx[i]), .tx_running(tx_running[i]),
         .rx_stb(rx_stb[i]), .rx_data_in(rx[i]), .rx_data_out(rx_data[i]), .rx_running(rx_running[i]),
         .misc_ins(32'h0), .misc_outs(),
         .fp_gpio_in(32'h0), .fp_gpio_out(), .fp_gpio_ddr(), .fp_gpio_fab(32'h0),
         .db_gpio_in(db_gpio_in[i]), .db_gpio_out(db_gpio_out[i]),
         .db_gpio_ddr(db_gpio_ddr[i]), .db_gpio_fab(db_gpio_fab[i]),
         .leds(),
         .spi_clk(radio_clk), .spi_rst(radio_rst),
         .sen(sen[i]), .sclk(sclk[i]), .mosi(mosi[i]), .miso(miso[i])
      );
   end endgenerate

   /////////////////////////////////////////////////////////////////////////////////
   // RFNoC
   /////////////////////////////////////////////////////////////////////////////////

   // Included automatically instantiated CEs sources file created by RFNoC mod tool
`ifdef RFNOC
 `ifdef N300
   `include "rfnoc_ce_auto_inst_n300.v"
 `endif
 `ifdef N310
   `include "rfnoc_ce_auto_inst_n310.v"
 `endif
`else
 `ifdef N300
   `include "rfnoc_ce_default_inst_n300.v"
 `endif
 `ifdef N310
   `include "rfnoc_ce_default_inst_n310.v"
 `endif
`endif

   wire  [(NUM_CE + NUM_IO_CE)*64-1:0] xbar_ce_o_tdata;
   wire  [(NUM_CE + NUM_IO_CE)-1:0]    xbar_ce_o_tlast;
   wire  [(NUM_CE + NUM_IO_CE)-1:0]    xbar_ce_o_tvalid;
   wire  [(NUM_CE + NUM_IO_CE)-1:0]    xbar_ce_o_tready;

   wire  [(NUM_CE + NUM_IO_CE)*64-1:0] xbar_ce_i_tdata;
   wire  [(NUM_CE + NUM_IO_CE)-1:0]    xbar_ce_i_tlast;
   wire  [(NUM_CE + NUM_IO_CE)-1:0]    xbar_ce_i_tvalid;
   wire  [(NUM_CE + NUM_IO_CE)-1:0]    xbar_ce_i_tready;

   assign xbar_ce_i_tdata                      = {ce_flat_i_tdata, ioce_flat_i_tdata};
   assign xbar_ce_i_tvalid                     = {ce_i_tvalid, ioce_i_tvalid};
   assign {ce_i_tready, ioce_i_tready}         = xbar_ce_i_tready;
   assign xbar_ce_i_tlast                      = {ce_i_tlast, ioce_i_tlast};

   assign {ce_flat_o_tdata, ioce_flat_o_tdata} = xbar_ce_o_tdata;
   assign {ce_o_tvalid, ioce_o_tvalid}         = xbar_ce_o_tvalid;
   assign xbar_ce_o_tready                     = {ce_o_tready, ioce_o_tready};
   assign {ce_o_tlast, ioce_o_tlast}           = xbar_ce_o_tlast;

   // //////////////////////////////////////////////////////////////////////
   // axi_crossbar ports
   // 0  - ETH0
   // 1  - ETH1
   // 2  - DMA
   // 3  - CE0
   // ...
   // 15 - CE13
   // //////////////////////////////////////////////////////////////////////

  // Base width of crossbar based on fixed components (ethernet, DMA)
   localparam XBAR_FIXED_PORTS = 3;
   localparam XBAR_NUM_PORTS = XBAR_FIXED_PORTS + NUM_CE + NUM_IO_CE;

   // Note: The custom accelerator inputs / outputs bitwidth grow based on NUM_CE
   axi_crossbar_regport #(
      .REG_BASE(REG_BASE_XBAR),
      .REG_DWIDTH(REG_DWIDTH),  // Width of the AXI4-Lite data bus (must be 32 or 64)
      .REG_AWIDTH(REG_AWIDTH),  // Width of the address bus
      .FIFO_WIDTH(64), .DST_WIDTH(16), .NUM_INPUTS(XBAR_NUM_PORTS), .NUM_OUTPUTS(XBAR_NUM_PORTS))
   inst_axi_crossbar_regport (
      .clk(bus_clk), .reset(bus_rst), .clear(1'b0),
      .i_tdata({xbar_ce_i_tdata,dmai_tdata,e2v1_tdata,e2v0_tdata}),
      .i_tlast({xbar_ce_i_tlast,dmai_tlast,e2v1_tlast,e2v0_tlast}),
      .i_tvalid({xbar_ce_i_tvalid,dmai_tvalid,e2v1_tvalid,e2v0_tvalid}),
      .i_tready({xbar_ce_i_tready,dmai_tready,e2v1_tready,e2v0_tready}),
      .o_tdata({xbar_ce_o_tdata,dmao_tdata,v2e1_tdata,v2e0_tdata}),
      .o_tlast({xbar_ce_o_tlast,dmao_tlast,v2e1_tlast,v2e0_tlast}),
      .o_tvalid({xbar_ce_o_tvalid,dmao_tvalid,v2e1_tvalid,v2e0_tvalid}),
      .o_tready({xbar_ce_o_tready,dmao_tready,v2e1_tready,v2e0_tready}),
      .pkt_present({xbar_ce_i_tvalid,dmai_tvalid,e2v1_tvalid,e2v0_tvalid}),
      .reg_wr_req(reg_wr_req),
      .reg_wr_addr(reg_wr_addr),
      .reg_wr_data(reg_wr_data),
      .reg_rd_req(reg_rd_req),
      .reg_rd_addr(reg_rd_addr),
      .reg_rd_data(reg_rd_data_xbar),
      .reg_rd_resp(reg_rd_resp_xbar)
   );

endmodule //n310_core
