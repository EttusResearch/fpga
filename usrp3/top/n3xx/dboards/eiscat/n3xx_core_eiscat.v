////////////////////////////////////////////////////////////////////
//
// Copyright 2017-2018 Ettus Research, A National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// Module: n3xx_core
// Description:
// - Motherboard Registers
// - Crossbar
// - Noc Block Radios
// - Noc Block Dram fifo
// - Radio Front End control
//
/////////////////////////////////////////////////////////////////////

module n3xx_core_eiscat #(
  parameter REG_DWIDTH  = 32, // Width of the AXI4-Lite data bus (must be 32 or 64)
  parameter REG_AWIDTH  = 32,  // Width of the address bus
  parameter ENABLE_DDR3 = 1,
  parameter BUS_CLK_RATE = 200000000, // BUS_CLK rate
  parameter NUM_RADIO_CORES = 4,
  parameter NUM_CHANNELS_PER_RADIO = 1,
  parameter NUM_CHANNELS = 4,
  parameter NUM_DBOARDS = 2,
  parameter FP_GPIO_WIDTH = 12 // Front panel GPIO width
)(
  // Clocks and resets
  input         radio_clk,
  input         radio_rst,
  input         bus_clk,
  input         bus_rst,
  input         ddr3_dma_clk,

  // Clocking and PPS Controls/Indicators
  input            pps,
  output reg[3:0]  pps_select = 4'h1,
  output reg       pps_out_enb,
  output reg[1:0]  pps_select_sfp = 2'b0,
  output reg       ref_clk_reset,
  output reg       meas_clk_reset,
  input            ref_clk_locked,
  input            meas_clk_locked,
  input            sync_in,
  output           sync_out,

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

  input        rxAA_stb,
  input [63:0] rxAA,
  input        rxAB_stb,
  input [63:0] rxAB,
  input        rxBA_stb,
  input [63:0] rxBA,
  input        rxBB_stb,
  input [63:0] rxBB,
  output       sysref_pulse,

  // DMA
  output [63:0] dmao_tdata,
  output        dmao_tlast,
  output        dmao_tvalid,
  input         dmao_tready,

  input [63:0]  dmai_tdata,
  input         dmai_tlast,
  input         dmai_tvalid,
  output        dmai_tready,

  // AXI4 (256b@200MHz) interface to DDR3 controller
  input          ddr3_axi_clk,
  input          ddr3_axi_rst,
  input          ddr3_running,
  // Write Address Ports
  output [3:0]   ddr3_axi_awid,
  output [31:0]  ddr3_axi_awaddr,
  output [7:0]   ddr3_axi_awlen,
  output [2:0]   ddr3_axi_awsize,
  output [1:0]   ddr3_axi_awburst,
  output [0:0]   ddr3_axi_awlock,
  output [3:0]   ddr3_axi_awcache,
  output [2:0]   ddr3_axi_awprot,
  output [3:0]   ddr3_axi_awqos,
  output         ddr3_axi_awvalid,
  input          ddr3_axi_awready,
  // Write Data Ports
  output [255:0] ddr3_axi_wdata,
  output [31:0]  ddr3_axi_wstrb,
  output         ddr3_axi_wlast,
  output         ddr3_axi_wvalid,
  input          ddr3_axi_wready,
  // Write Response Ports
  output         ddr3_axi_bready,
  input [3:0]    ddr3_axi_bid,
  input [1:0]    ddr3_axi_bresp,
  input          ddr3_axi_bvalid,
  // Read Address Ports
  output [3:0]   ddr3_axi_arid,
  output [31:0]  ddr3_axi_araddr,
  output [7:0]   ddr3_axi_arlen,
  output [2:0]   ddr3_axi_arsize,
  output [1:0]   ddr3_axi_arburst,
  output [0:0]   ddr3_axi_arlock,
  output [3:0]   ddr3_axi_arcache,
  output [2:0]   ddr3_axi_arprot,
  output [3:0]   ddr3_axi_arqos,
  output         ddr3_axi_arvalid,
  input          ddr3_axi_arready,
  // Read Data Ports
  output         ddr3_axi_rready,
  input [3:0]    ddr3_axi_rid,
  input [255:0]  ddr3_axi_rdata,
  input [1:0]    ddr3_axi_rresp,
  input          ddr3_axi_rlast,
  input          ddr3_axi_rvalid,

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
  output        e2v1_tready,
  
  //npio to/from eiscat 
  output [63:0] eiscat2npio_tdata,
  output        eiscat2npio_tlast,
  output        eiscat2npio_tvalid,
  input         eiscat2npio_tready,

  input  [63:0] npio2eiscat_tdata,
  input         npio2eiscat_tlast,
  input         npio2eiscat_tvalid,
  output        npio2eiscat_tready,

  // RegPort interface to NPIO
  output                  reg_wr_req_npio,
  output [REG_AWIDTH-1:0] reg_wr_addr_npio,
  output [REG_DWIDTH-1:0] reg_wr_data_npio,
  output                  reg_rd_req_npio,
  output [REG_AWIDTH-1:0] reg_rd_addr_npio,
  input                   reg_rd_resp_npio,
  input  [REG_DWIDTH-1:0] reg_rd_data_npio,

  // Misc
  input  [31:0]   build_datestamp,
  input  [31:0]   xadc_readback,
  input  [63:0]   sfp_ports_info
);

  /////////////////////////////////////////////////////////////////////////////////
  // Compatibility Number
  //
  localparam [15:0] COMPAT_MAJOR = 16'd5;
  localparam [15:0] COMPAT_MINOR = 16'd2;
  /////////////////////////////////////////////////////////////////////////////////

  // Computation engines that need access to IO
  localparam NUM_IO_CE = NUM_RADIO_CORES + ENABLE_DDR3; // NUM_RADIO_CORES + 1 DMA_FIFO

  // Indicate if we want to use replay block
  localparam USE_REPLAY = 0;

  /////////////////////////////////////////////////////////////////////////////////
  // Motherboard Registers
  /////////////////////////////////////////////////////////////////////////////////

  // Register base
  localparam REG_BASE_MISC  = 14'h0;
  localparam REG_BASE_XBAR  = 14'h1000;

  // Misc Motherboard Registers
  localparam REG_COMPAT_NUM        = REG_BASE_MISC + 14'h00;
  localparam REG_DATESTAMP         = REG_BASE_MISC + 14'h04;
  localparam REG_GIT_HASH          = REG_BASE_MISC + 14'h08;
  localparam REG_SCRATCH           = REG_BASE_MISC + 14'h0C;
  localparam REG_NUM_CE            = REG_BASE_MISC + 14'h10;
  localparam REG_NUM_IO_CE         = REG_BASE_MISC + 14'h14;
  localparam REG_CLOCK_CTRL        = REG_BASE_MISC + 14'h18;
  localparam REG_XADC_READBACK     = REG_BASE_MISC + 14'h1C;
  localparam REG_BUS_CLK_RATE      = REG_BASE_MISC + 14'h20;
  localparam REG_BUS_CLK_COUNT     = REG_BASE_MISC + 14'h24;
  localparam REG_SFP_PORT0_INFO    = REG_BASE_MISC + 14'h28;
  localparam REG_SFP_PORT1_INFO    = REG_BASE_MISC + 14'h2C;
  localparam REG_FP_GPIO_MASTER    = REG_BASE_MISC + 14'h30;
  localparam REG_FP_GPIO_RADIO_SRC = REG_BASE_MISC + 14'h34;

  reg [31:0] scratch_reg = 32'b0;
  reg [31:0] bus_counter = 32'h0;
  reg [31:0] fp_gpio_master_reg = 32'h0;
  reg [31:0] fp_gpio_src_reg = 32'h0;

  always @(posedge bus_clk) begin
     if (bus_rst)
        bus_counter <= 32'd0;
     else
        bus_counter <= bus_counter + 32'd1;
  end

  // Regport
  wire                  reg_wr_req;
  wire [REG_AWIDTH-1:0] reg_wr_addr;
  wire [REG_DWIDTH-1:0] reg_wr_data;
  wire                  reg_rd_req;
  wire [REG_AWIDTH-1:0] reg_rd_addr;
  wire                  reg_rd_resp;
  wire [REG_DWIDTH-1:0] reg_rd_data;

  reg                   reg_rd_resp_glob;
  reg  [REG_DWIDTH-1:0] reg_rd_data_glob;

  wire [REG_DWIDTH-1:0] reg_rd_data_xbar;
  wire                  reg_rd_resp_xbar;

  regport_resp_mux #(
    .WIDTH(REG_DWIDTH),
    .NUM_SLAVES(3)
  ) inst_mboard_regport_resp_mux (
    .clk(bus_clk),
    .reset(bus_rst),
    .sla_rd_resp({reg_rd_resp_npio, reg_rd_resp_glob, reg_rd_resp_xbar}),
    .sla_rd_data({reg_rd_data_npio, reg_rd_data_glob, reg_rd_data_xbar}),
    .mst_rd_resp(reg_rd_resp),
    .mst_rd_data(reg_rd_data)
  );

  axil_regport_master #(
    .DWIDTH   (REG_DWIDTH), // Width of the AXI4-Lite data bus (must be 32 or 64)
    .AWIDTH   (REG_AWIDTH), // Width of the address bus
    .WRBASE   (0),          // Write address base
    .RDBASE   (0),          // Read address base
    .TIMEOUT  (10)          // log2(timeout). Read will timeout after (2^TIMEOUT - 1) cycles
  ) mboard_regport_master_i (
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

  assign reg_wr_req_npio = reg_wr_req;
  assign reg_wr_addr_npio = reg_wr_addr;
  assign reg_wr_data_npio = reg_wr_data;
  assign reg_rd_req_npio = reg_rd_req;
  assign reg_rd_addr_npio = reg_rd_addr;

  reg b_ref_clk_locked_ms;
  reg b_ref_clk_locked;
  reg b_meas_clk_locked_ms;
  reg b_meas_clk_locked;

  // Write Registers
  always @ (posedge bus_clk) begin
    if (bus_rst) begin
      scratch_reg    <= 32'h0;
      fp_gpio_master_reg <= 32'h0;
      fp_gpio_src_reg <= 32'h0;
      pps_select     <= 4'h1;
      pps_select_sfp <= 2'h1;
      pps_out_enb    <= 1'b0;
      ref_clk_reset  <= 1'b0;
      meas_clk_reset <= 1'b0;
    end else if (reg_wr_req) begin
      case (reg_wr_addr)
        REG_FP_GPIO_MASTER: begin
          fp_gpio_master_reg <= reg_wr_data;
        end
        REG_FP_GPIO_RADIO_SRC: begin
          fp_gpio_src_reg <= reg_wr_data;
        end
        REG_SCRATCH: begin
          scratch_reg <= reg_wr_data;
        end
        REG_CLOCK_CTRL: begin
          pps_select     <= reg_wr_data[3:0];
          pps_out_enb    <= reg_wr_data[4];
          pps_select_sfp <= reg_wr_data[6:5];
          ref_clk_reset  <= reg_wr_data[8];
          meas_clk_reset <= reg_wr_data[12];
        end
      endcase
    end
  end

  // Read Registers
  always @ (posedge bus_clk) begin
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
        REG_COMPAT_NUM:
          reg_rd_data_glob <= {COMPAT_MAJOR, COMPAT_MINOR};

        REG_DATESTAMP:
          reg_rd_data_glob <= build_datestamp;

        REG_GIT_HASH:
          reg_rd_data_glob <= `GIT_HASH;

        REG_FP_GPIO_MASTER:
          reg_rd_data_glob <= fp_gpio_master_reg;

        REG_FP_GPIO_RADIO_SRC:
          reg_rd_data_glob <= fp_gpio_src_reg;

        REG_SCRATCH:
          reg_rd_data_glob <= scratch_reg;

        REG_NUM_CE:
          reg_rd_data_glob <= NUM_CE;

        REG_NUM_IO_CE:
          reg_rd_data_glob <= NUM_IO_CE;

        REG_CLOCK_CTRL: begin
          reg_rd_data_glob <= 32'b0;
          reg_rd_data_glob[3:0] <= pps_select;
          reg_rd_data_glob[4]   <= pps_out_enb;
          reg_rd_data_glob[6:5] <= pps_select_sfp;
          reg_rd_data_glob[8]   <= ref_clk_reset;
          reg_rd_data_glob[9]   <= b_ref_clk_locked;
          reg_rd_data_glob[12]  <= meas_clk_reset;
          reg_rd_data_glob[13]  <= b_meas_clk_locked;
        end

        REG_XADC_READBACK:
          reg_rd_data_glob <= xadc_readback;

        REG_BUS_CLK_RATE:
          reg_rd_data_glob <= BUS_CLK_RATE;

        REG_BUS_CLK_COUNT:
          reg_rd_data_glob <= bus_counter;

        REG_SFP_PORT0_INFO:
          reg_rd_data_glob <= sfp_ports_info[31:0];

        REG_SFP_PORT1_INFO:
          reg_rd_data_glob <= sfp_ports_info[63:32];

        default:
          reg_rd_resp_glob <= 1'b0;
        endcase
      end
      else if (reg_rd_resp_glob) begin
          reg_rd_resp_glob <= 1'b0;
      end
    end
  end

  // IOCE
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

  /////////////////////////////////////////////////////////////////////
  //
  // DRAM FIFO
  //
  /////////////////////////////////////////////////////////////////////

  generate
  if(ENABLE_DDR3) begin
  localparam NUM_DRAM_FIFOS = 4;
  localparam DRAM_FIFO_INPUT_BUFF_SIZE = 8'd13;

  wire ddr3_dma_rst;
  synchronizer #(
    .INITIAL_VAL(1'b1)
  ) ddr3_dma_rst_sync_i (
    .clk(ddr3_dma_clk), .rst(1'b0), .in(ddr3_axi_rst), .out(ddr3_dma_rst)
  );

  // AXI4 MM buses
  wire [0:0]  fifo_axi_awid     [0:NUM_DRAM_FIFOS-1];
  wire [31:0] fifo_axi_awaddr   [0:NUM_DRAM_FIFOS-1];
  wire [7:0]  fifo_axi_awlen    [0:NUM_DRAM_FIFOS-1];
  wire [2:0]  fifo_axi_awsize   [0:NUM_DRAM_FIFOS-1];
  wire [1:0]  fifo_axi_awburst  [0:NUM_DRAM_FIFOS-1];
  wire [0:0]  fifo_axi_awlock   [0:NUM_DRAM_FIFOS-1];
  wire [3:0]  fifo_axi_awcache  [0:NUM_DRAM_FIFOS-1];
  wire [2:0]  fifo_axi_awprot   [0:NUM_DRAM_FIFOS-1];
  wire [3:0]  fifo_axi_awqos    [0:NUM_DRAM_FIFOS-1];
  wire [3:0]  fifo_axi_awregion [0:NUM_DRAM_FIFOS-1];
  wire [0:0]  fifo_axi_awuser   [0:NUM_DRAM_FIFOS-1];
  wire        fifo_axi_awvalid  [0:NUM_DRAM_FIFOS-1];
  wire        fifo_axi_awready  [0:NUM_DRAM_FIFOS-1];
  wire [63:0] fifo_axi_wdata    [0:NUM_DRAM_FIFOS-1];
  wire [7:0]  fifo_axi_wstrb    [0:NUM_DRAM_FIFOS-1];
  wire        fifo_axi_wlast    [0:NUM_DRAM_FIFOS-1];
  wire [0:0]  fifo_axi_wuser    [0:NUM_DRAM_FIFOS-1];
  wire        fifo_axi_wvalid   [0:NUM_DRAM_FIFOS-1];
  wire        fifo_axi_wready   [0:NUM_DRAM_FIFOS-1];
  wire [0:0]  fifo_axi_bid      [0:NUM_DRAM_FIFOS-1];
  wire [1:0]  fifo_axi_bresp    [0:NUM_DRAM_FIFOS-1];
  wire [0:0]  fifo_axi_buser    [0:NUM_DRAM_FIFOS-1];
  wire        fifo_axi_bvalid   [0:NUM_DRAM_FIFOS-1];
  wire        fifo_axi_bready   [0:NUM_DRAM_FIFOS-1];
  wire [0:0]  fifo_axi_arid     [0:NUM_DRAM_FIFOS-1];
  wire [31:0] fifo_axi_araddr   [0:NUM_DRAM_FIFOS-1];
  wire [7:0]  fifo_axi_arlen    [0:NUM_DRAM_FIFOS-1];
  wire [2:0]  fifo_axi_arsize   [0:NUM_DRAM_FIFOS-1];
  wire [1:0]  fifo_axi_arburst  [0:NUM_DRAM_FIFOS-1];
  wire [0:0]  fifo_axi_arlock   [0:NUM_DRAM_FIFOS-1];
  wire [3:0]  fifo_axi_arcache  [0:NUM_DRAM_FIFOS-1];
  wire [2:0]  fifo_axi_arprot   [0:NUM_DRAM_FIFOS-1];
  wire [3:0]  fifo_axi_arqos    [0:NUM_DRAM_FIFOS-1];
  wire [3:0]  fifo_axi_arregion [0:NUM_DRAM_FIFOS-1];
  wire [0:0]  fifo_axi_aruser   [0:NUM_DRAM_FIFOS-1];
  wire        fifo_axi_arvalid  [0:NUM_DRAM_FIFOS-1];
  wire        fifo_axi_arready  [0:NUM_DRAM_FIFOS-1];
  wire [0:0]  fifo_axi_rid      [0:NUM_DRAM_FIFOS-1];
  wire [63:0] fifo_axi_rdata    [0:NUM_DRAM_FIFOS-1];
  wire [1:0]  fifo_axi_rresp    [0:NUM_DRAM_FIFOS-1];
  wire        fifo_axi_rlast    [0:NUM_DRAM_FIFOS-1];
  wire [0:0]  fifo_axi_ruser    [0:NUM_DRAM_FIFOS-1];
  wire        fifo_axi_rvalid   [0:NUM_DRAM_FIFOS-1];
  wire        fifo_axi_rready   [0:NUM_DRAM_FIFOS-1];

  axi_intercon_4x64_256_bd_wrapper axi_intercon_2x64_256_bd_i (
    .S00_AXI_ACLK     (ddr3_dma_clk        ),
    .S00_AXI_ARESETN  (~ddr3_dma_rst       ),
    .S00_AXI_AWID     (fifo_axi_awid    [0]),
    .S00_AXI_AWADDR   (fifo_axi_awaddr  [0]),
    .S00_AXI_AWLEN    (fifo_axi_awlen   [0]),
    .S00_AXI_AWSIZE   (fifo_axi_awsize  [0]),
    .S00_AXI_AWBURST  (fifo_axi_awburst [0]),
    .S00_AXI_AWLOCK   (fifo_axi_awlock  [0]),
    .S00_AXI_AWCACHE  (fifo_axi_awcache [0]),
    .S00_AXI_AWPROT   (fifo_axi_awprot  [0]),
    .S00_AXI_AWQOS    (fifo_axi_awqos   [0]),
    .S00_AXI_AWREGION (fifo_axi_awregion[0]),
    .S00_AXI_AWVALID  (fifo_axi_awvalid [0]),
    .S00_AXI_AWREADY  (fifo_axi_awready [0]),
    .S00_AXI_WDATA    (fifo_axi_wdata   [0]),
    .S00_AXI_WSTRB    (fifo_axi_wstrb   [0]),
    .S00_AXI_WLAST    (fifo_axi_wlast   [0]),
    .S00_AXI_WVALID   (fifo_axi_wvalid  [0]),
    .S00_AXI_WREADY   (fifo_axi_wready  [0]),
    .S00_AXI_BID      (fifo_axi_bid     [0]),
    .S00_AXI_BRESP    (fifo_axi_bresp   [0]),
    .S00_AXI_BVALID   (fifo_axi_bvalid  [0]),
    .S00_AXI_BREADY   (fifo_axi_bready  [0]),
    .S00_AXI_ARID     (fifo_axi_arid    [0]),
    .S00_AXI_ARADDR   (fifo_axi_araddr  [0]),
    .S00_AXI_ARLEN    (fifo_axi_arlen   [0]),
    .S00_AXI_ARSIZE   (fifo_axi_arsize  [0]),
    .S00_AXI_ARBURST  (fifo_axi_arburst [0]),
    .S00_AXI_ARLOCK   (fifo_axi_arlock  [0]),
    .S00_AXI_ARCACHE  (fifo_axi_arcache [0]),
    .S00_AXI_ARPROT   (fifo_axi_arprot  [0]),
    .S00_AXI_ARQOS    (fifo_axi_arqos   [0]),
    .S00_AXI_ARREGION (fifo_axi_arregion[0]),
    .S00_AXI_ARVALID  (fifo_axi_arvalid [0]),
    .S00_AXI_ARREADY  (fifo_axi_arready [0]),
    .S00_AXI_RID      (fifo_axi_rid     [0]),
    .S00_AXI_RDATA    (fifo_axi_rdata   [0]),
    .S00_AXI_RRESP    (fifo_axi_rresp   [0]),
    .S00_AXI_RLAST    (fifo_axi_rlast   [0]),
    .S00_AXI_RVALID   (fifo_axi_rvalid  [0]),
    .S00_AXI_RREADY   (fifo_axi_rready  [0]),
    //
    .S01_AXI_ACLK     (ddr3_dma_clk        ),
    .S01_AXI_ARESETN  (~ddr3_dma_rst       ),
    .S01_AXI_AWID     (fifo_axi_awid    [1]),
    .S01_AXI_AWADDR   (fifo_axi_awaddr  [1]),
    .S01_AXI_AWLEN    (fifo_axi_awlen   [1]),
    .S01_AXI_AWSIZE   (fifo_axi_awsize  [1]),
    .S01_AXI_AWBURST  (fifo_axi_awburst [1]),
    .S01_AXI_AWLOCK   (fifo_axi_awlock  [1]),
    .S01_AXI_AWCACHE  (fifo_axi_awcache [1]),
    .S01_AXI_AWPROT   (fifo_axi_awprot  [1]),
    .S01_AXI_AWQOS    (fifo_axi_awqos   [1]),
    .S01_AXI_AWREGION (fifo_axi_awregion[1]),
    .S01_AXI_AWVALID  (fifo_axi_awvalid [1]),
    .S01_AXI_AWREADY  (fifo_axi_awready [1]),
    .S01_AXI_WDATA    (fifo_axi_wdata   [1]),
    .S01_AXI_WSTRB    (fifo_axi_wstrb   [1]),
    .S01_AXI_WLAST    (fifo_axi_wlast   [1]),
    .S01_AXI_WVALID   (fifo_axi_wvalid  [1]),
    .S01_AXI_WREADY   (fifo_axi_wready  [1]),
    .S01_AXI_BID      (fifo_axi_bid     [1]),
    .S01_AXI_BRESP    (fifo_axi_bresp   [1]),
    .S01_AXI_BVALID   (fifo_axi_bvalid  [1]),
    .S01_AXI_BREADY   (fifo_axi_bready  [1]),
    .S01_AXI_ARID     (fifo_axi_arid    [1]),
    .S01_AXI_ARADDR   (fifo_axi_araddr  [1]),
    .S01_AXI_ARLEN    (fifo_axi_arlen   [1]),
    .S01_AXI_ARSIZE   (fifo_axi_arsize  [1]),
    .S01_AXI_ARBURST  (fifo_axi_arburst [1]),
    .S01_AXI_ARLOCK   (fifo_axi_arlock  [1]),
    .S01_AXI_ARCACHE  (fifo_axi_arcache [1]),
    .S01_AXI_ARPROT   (fifo_axi_arprot  [1]),
    .S01_AXI_ARQOS    (fifo_axi_arqos   [1]),
    .S01_AXI_ARREGION (fifo_axi_arregion[1]),
    .S01_AXI_ARVALID  (fifo_axi_arvalid [1]),
    .S01_AXI_ARREADY  (fifo_axi_arready [1]),
    .S01_AXI_RID      (fifo_axi_rid     [1]),
    .S01_AXI_RDATA    (fifo_axi_rdata   [1]),
    .S01_AXI_RRESP    (fifo_axi_rresp   [1]),
    .S01_AXI_RLAST    (fifo_axi_rlast   [1]),
    .S01_AXI_RVALID   (fifo_axi_rvalid  [1]),
    .S01_AXI_RREADY   (fifo_axi_rready  [1]),
    //
    .S02_AXI_ACLK     (ddr3_dma_clk        ),
    .S02_AXI_ARESETN  (~ddr3_dma_rst       ),
    .S02_AXI_AWID     (fifo_axi_awid    [2]),
    .S02_AXI_AWADDR   (fifo_axi_awaddr  [2]),
    .S02_AXI_AWLEN    (fifo_axi_awlen   [2]),
    .S02_AXI_AWSIZE   (fifo_axi_awsize  [2]),
    .S02_AXI_AWBURST  (fifo_axi_awburst [2]),
    .S02_AXI_AWLOCK   (fifo_axi_awlock  [2]),
    .S02_AXI_AWCACHE  (fifo_axi_awcache [2]),
    .S02_AXI_AWPROT   (fifo_axi_awprot  [2]),
    .S02_AXI_AWQOS    (fifo_axi_awqos   [2]),
    .S02_AXI_AWREGION (fifo_axi_awregion[2]),
    .S02_AXI_AWVALID  (fifo_axi_awvalid [2]),
    .S02_AXI_AWREADY  (fifo_axi_awready [2]),
    .S02_AXI_WDATA    (fifo_axi_wdata   [2]),
    .S02_AXI_WSTRB    (fifo_axi_wstrb   [2]),
    .S02_AXI_WLAST    (fifo_axi_wlast   [2]),
    .S02_AXI_WVALID   (fifo_axi_wvalid  [2]),
    .S02_AXI_WREADY   (fifo_axi_wready  [2]),
    .S02_AXI_BID      (fifo_axi_bid     [2]),
    .S02_AXI_BRESP    (fifo_axi_bresp   [2]),
    .S02_AXI_BVALID   (fifo_axi_bvalid  [2]),
    .S02_AXI_BREADY   (fifo_axi_bready  [2]),
    .S02_AXI_ARID     (fifo_axi_arid    [2]),
    .S02_AXI_ARADDR   (fifo_axi_araddr  [2]),
    .S02_AXI_ARLEN    (fifo_axi_arlen   [2]),
    .S02_AXI_ARSIZE   (fifo_axi_arsize  [2]),
    .S02_AXI_ARBURST  (fifo_axi_arburst [2]),
    .S02_AXI_ARLOCK   (fifo_axi_arlock  [2]),
    .S02_AXI_ARCACHE  (fifo_axi_arcache [2]),
    .S02_AXI_ARPROT   (fifo_axi_arprot  [2]),
    .S02_AXI_ARQOS    (fifo_axi_arqos   [2]),
    .S02_AXI_ARREGION (fifo_axi_arregion[2]),
    .S02_AXI_ARVALID  (fifo_axi_arvalid [2]),
    .S02_AXI_ARREADY  (fifo_axi_arready [2]),
    .S02_AXI_RID      (fifo_axi_rid     [2]),
    .S02_AXI_RDATA    (fifo_axi_rdata   [2]),
    .S02_AXI_RRESP    (fifo_axi_rresp   [2]),
    .S02_AXI_RLAST    (fifo_axi_rlast   [2]),
    .S02_AXI_RVALID   (fifo_axi_rvalid  [2]),
    .S02_AXI_RREADY   (fifo_axi_rready  [2]),
    //
    .S03_AXI_ACLK     (ddr3_dma_clk        ),
    .S03_AXI_ARESETN  (~ddr3_dma_rst       ),
    .S03_AXI_AWID     (fifo_axi_awid    [3]),
    .S03_AXI_AWADDR   (fifo_axi_awaddr  [3]),
    .S03_AXI_AWLEN    (fifo_axi_awlen   [3]),
    .S03_AXI_AWSIZE   (fifo_axi_awsize  [3]),
    .S03_AXI_AWBURST  (fifo_axi_awburst [3]),
    .S03_AXI_AWLOCK   (fifo_axi_awlock  [3]),
    .S03_AXI_AWCACHE  (fifo_axi_awcache [3]),
    .S03_AXI_AWPROT   (fifo_axi_awprot  [3]),
    .S03_AXI_AWQOS    (fifo_axi_awqos   [3]),
    .S03_AXI_AWREGION (fifo_axi_awregion[3]),
    .S03_AXI_AWVALID  (fifo_axi_awvalid [3]),
    .S03_AXI_AWREADY  (fifo_axi_awready [3]),
    .S03_AXI_WDATA    (fifo_axi_wdata   [3]),
    .S03_AXI_WSTRB    (fifo_axi_wstrb   [3]),
    .S03_AXI_WLAST    (fifo_axi_wlast   [3]),
    .S03_AXI_WVALID   (fifo_axi_wvalid  [3]),
    .S03_AXI_WREADY   (fifo_axi_wready  [3]),
    .S03_AXI_BID      (fifo_axi_bid     [3]),
    .S03_AXI_BRESP    (fifo_axi_bresp   [3]),
    .S03_AXI_BVALID   (fifo_axi_bvalid  [3]),
    .S03_AXI_BREADY   (fifo_axi_bready  [3]),
    .S03_AXI_ARID     (fifo_axi_arid    [3]),
    .S03_AXI_ARADDR   (fifo_axi_araddr  [3]),
    .S03_AXI_ARLEN    (fifo_axi_arlen   [3]),
    .S03_AXI_ARSIZE   (fifo_axi_arsize  [3]),
    .S03_AXI_ARBURST  (fifo_axi_arburst [3]),
    .S03_AXI_ARLOCK   (fifo_axi_arlock  [3]),
    .S03_AXI_ARCACHE  (fifo_axi_arcache [3]),
    .S03_AXI_ARPROT   (fifo_axi_arprot  [3]),
    .S03_AXI_ARQOS    (fifo_axi_arqos   [3]),
    .S03_AXI_ARREGION (fifo_axi_arregion[3]),
    .S03_AXI_ARVALID  (fifo_axi_arvalid [3]),
    .S03_AXI_ARREADY  (fifo_axi_arready [3]),
    .S03_AXI_RID      (fifo_axi_rid     [3]),
    .S03_AXI_RDATA    (fifo_axi_rdata   [3]),
    .S03_AXI_RRESP    (fifo_axi_rresp   [3]),
    .S03_AXI_RLAST    (fifo_axi_rlast   [3]),
    .S03_AXI_RVALID   (fifo_axi_rvalid  [3]),
    .S03_AXI_RREADY   (fifo_axi_rready  [3]),
    //
    .M00_AXI_ACLK     (ddr3_axi_clk        ),
    .M00_AXI_ARESETN  (~ddr3_axi_rst       ),
    .M00_AXI_AWID     (ddr3_axi_awid       ),
    .M00_AXI_AWADDR   (ddr3_axi_awaddr     ),
    .M00_AXI_AWLEN    (ddr3_axi_awlen      ),
    .M00_AXI_AWSIZE   (ddr3_axi_awsize     ),
    .M00_AXI_AWBURST  (ddr3_axi_awburst    ),
    .M00_AXI_AWLOCK   (ddr3_axi_awlock     ),
    .M00_AXI_AWCACHE  (ddr3_axi_awcache    ),
    .M00_AXI_AWPROT   (ddr3_axi_awprot     ),
    .M00_AXI_AWQOS    (ddr3_axi_awqos      ),
    .M00_AXI_AWREGION (                    ),
    .M00_AXI_AWVALID  (ddr3_axi_awvalid    ),
    .M00_AXI_AWREADY  (ddr3_axi_awready    ),
    .M00_AXI_WDATA    (ddr3_axi_wdata      ),
    .M00_AXI_WSTRB    (ddr3_axi_wstrb      ),
    .M00_AXI_WLAST    (ddr3_axi_wlast      ),
    .M00_AXI_WVALID   (ddr3_axi_wvalid     ),
    .M00_AXI_WREADY   (ddr3_axi_wready     ),
    .M00_AXI_BID      (ddr3_axi_bid        ),
    .M00_AXI_BRESP    (ddr3_axi_bresp      ),
    .M00_AXI_BVALID   (ddr3_axi_bvalid     ),
    .M00_AXI_BREADY   (ddr3_axi_bready     ),
    .M00_AXI_ARID     (ddr3_axi_arid       ),
    .M00_AXI_ARADDR   (ddr3_axi_araddr     ),
    .M00_AXI_ARLEN    (ddr3_axi_arlen      ),
    .M00_AXI_ARSIZE   (ddr3_axi_arsize     ),
    .M00_AXI_ARBURST  (ddr3_axi_arburst    ),
    .M00_AXI_ARLOCK   (ddr3_axi_arlock     ),
    .M00_AXI_ARCACHE  (ddr3_axi_arcache    ),
    .M00_AXI_ARPROT   (ddr3_axi_arprot     ),
    .M00_AXI_ARQOS    (ddr3_axi_arqos      ),
    .M00_AXI_ARREGION (                    ),
    .M00_AXI_ARVALID  (ddr3_axi_arvalid    ),
    .M00_AXI_ARREADY  (ddr3_axi_arready    ),
    .M00_AXI_RID      (ddr3_axi_rid        ),
    .M00_AXI_RDATA    (ddr3_axi_rdata      ),
    .M00_AXI_RRESP    (ddr3_axi_rresp      ),
    .M00_AXI_RLAST    (ddr3_axi_rlast      ),
    .M00_AXI_RVALID   (ddr3_axi_rvalid     ),
    .M00_AXI_RREADY   (ddr3_axi_rready     )
  );

    if (USE_REPLAY) begin

      noc_block_replay #(
        .NUM_REPLAY_BLOCKS (NUM_DRAM_FIFOS),
        .STR_SINK_FIFOSIZE (14)
      ) inst_noc_block_dram_fifo (
        .bus_clk (bus_clk),
        .bus_rst (bus_rst),
        .ce_clk  (ddr3_axi_clk_x2),
        .ce_rst  (ddr3_axi_rst),

        .i_tdata  (ioce_o_tdata[0]),
        .i_tlast  (ioce_o_tlast[0]),
        .i_tvalid (ioce_o_tvalid[0]),
        .i_tready (ioce_o_tready[0]),
        .o_tdata  (ioce_i_tdata[0]),
        .o_tlast  (ioce_i_tlast[0]),
        .o_tvalid (ioce_i_tvalid[0]),
        .o_tready (ioce_i_tready[0]),

        .m_axi_awid     ({fifo_axi_awid    [3], fifo_axi_awid    [2], fifo_axi_awid    [1], fifo_axi_awid    [0]}),
        .m_axi_awaddr   ({fifo_axi_awaddr  [3], fifo_axi_awaddr  [2], fifo_axi_awaddr  [1], fifo_axi_awaddr  [0]}),
        .m_axi_awlen    ({fifo_axi_awlen   [3], fifo_axi_awlen   [2], fifo_axi_awlen   [1], fifo_axi_awlen   [0]}),
        .m_axi_awsize   ({fifo_axi_awsize  [3], fifo_axi_awsize  [2], fifo_axi_awsize  [1], fifo_axi_awsize  [0]}),
        .m_axi_awburst  ({fifo_axi_awburst [3], fifo_axi_awburst [2], fifo_axi_awburst [1], fifo_axi_awburst [0]}),
        .m_axi_awlock   ({fifo_axi_awlock  [3], fifo_axi_awlock  [2], fifo_axi_awlock  [1], fifo_axi_awlock  [0]}),
        .m_axi_awcache  ({fifo_axi_awcache [3], fifo_axi_awcache [2], fifo_axi_awcache [1], fifo_axi_awcache [0]}),
        .m_axi_awprot   ({fifo_axi_awprot  [3], fifo_axi_awprot  [2], fifo_axi_awprot  [1], fifo_axi_awprot  [0]}),
        .m_axi_awqos    ({fifo_axi_awqos   [3], fifo_axi_awqos   [2], fifo_axi_awqos   [1], fifo_axi_awqos   [0]}),
        .m_axi_awregion ({fifo_axi_awregion[3], fifo_axi_awregion[2], fifo_axi_awregion[1], fifo_axi_awregion[0]}),
        .m_axi_awuser   ({fifo_axi_awuser  [3], fifo_axi_awuser  [2], fifo_axi_awuser  [1], fifo_axi_awuser  [0]}),
        .m_axi_awvalid  ({fifo_axi_awvalid [3], fifo_axi_awvalid [2], fifo_axi_awvalid [1], fifo_axi_awvalid [0]}),
        .m_axi_awready  ({fifo_axi_awready [3], fifo_axi_awready [2], fifo_axi_awready [1], fifo_axi_awready [0]}),
        .m_axi_wdata    ({fifo_axi_wdata   [3], fifo_axi_wdata   [2], fifo_axi_wdata   [1], fifo_axi_wdata   [0]}),
        .m_axi_wstrb    ({fifo_axi_wstrb   [3], fifo_axi_wstrb   [2], fifo_axi_wstrb   [1], fifo_axi_wstrb   [0]}),
        .m_axi_wlast    ({fifo_axi_wlast   [3], fifo_axi_wlast   [2], fifo_axi_wlast   [1], fifo_axi_wlast   [0]}),
        .m_axi_wuser    ({fifo_axi_wuser   [3], fifo_axi_wuser   [2], fifo_axi_wuser   [1], fifo_axi_wuser   [0]}),
        .m_axi_wvalid   ({fifo_axi_wvalid  [3], fifo_axi_wvalid  [2], fifo_axi_wvalid  [1], fifo_axi_wvalid  [0]}),
        .m_axi_wready   ({fifo_axi_wready  [3], fifo_axi_wready  [2], fifo_axi_wready  [1], fifo_axi_wready  [0]}),
        .m_axi_bid      ({fifo_axi_bid     [3], fifo_axi_bid     [2], fifo_axi_bid     [1], fifo_axi_bid     [0]}),
        .m_axi_bresp    ({fifo_axi_bresp   [3], fifo_axi_bresp   [2], fifo_axi_bresp   [1], fifo_axi_bresp   [0]}),
        .m_axi_buser    ({fifo_axi_buser   [3], fifo_axi_buser   [2], fifo_axi_buser   [1], fifo_axi_buser   [0]}),
        .m_axi_bvalid   ({fifo_axi_bvalid  [3], fifo_axi_bvalid  [2], fifo_axi_bvalid  [1], fifo_axi_bvalid  [0]}),
        .m_axi_bready   ({fifo_axi_bready  [3], fifo_axi_bready  [2], fifo_axi_bready  [1], fifo_axi_bready  [0]}),
        .m_axi_arid     ({fifo_axi_arid    [3], fifo_axi_arid    [2], fifo_axi_arid    [1], fifo_axi_arid    [0]}),
        .m_axi_araddr   ({fifo_axi_araddr  [3], fifo_axi_araddr  [2], fifo_axi_araddr  [1], fifo_axi_araddr  [0]}),
        .m_axi_arlen    ({fifo_axi_arlen   [3], fifo_axi_arlen   [2], fifo_axi_arlen   [1], fifo_axi_arlen   [0]}),
        .m_axi_arsize   ({fifo_axi_arsize  [3], fifo_axi_arsize  [2], fifo_axi_arsize  [1], fifo_axi_arsize  [0]}),
        .m_axi_arburst  ({fifo_axi_arburst [3], fifo_axi_arburst [2], fifo_axi_arburst [1], fifo_axi_arburst [0]}),
        .m_axi_arlock   ({fifo_axi_arlock  [3], fifo_axi_arlock  [2], fifo_axi_arlock  [1], fifo_axi_arlock  [0]}),
        .m_axi_arcache  ({fifo_axi_arcache [3], fifo_axi_arcache [2], fifo_axi_arcache [1], fifo_axi_arcache [0]}),
        .m_axi_arprot   ({fifo_axi_arprot  [3], fifo_axi_arprot  [2], fifo_axi_arprot  [1], fifo_axi_arprot  [0]}),
        .m_axi_arqos    ({fifo_axi_arqos   [3], fifo_axi_arqos   [2], fifo_axi_arqos   [1], fifo_axi_arqos   [0]}),
        .m_axi_arregion ({fifo_axi_arregion[3], fifo_axi_arregion[2], fifo_axi_arregion[1], fifo_axi_arregion[0]}),
        .m_axi_aruser   ({fifo_axi_aruser  [3], fifo_axi_aruser  [2], fifo_axi_aruser  [1], fifo_axi_aruser  [0]}),
        .m_axi_arvalid  ({fifo_axi_arvalid [3], fifo_axi_arvalid [2], fifo_axi_arvalid [1], fifo_axi_arvalid [0]}),
        .m_axi_arready  ({fifo_axi_arready [3], fifo_axi_arready [2], fifo_axi_arready [1], fifo_axi_arready [0]}),
        .m_axi_rid      ({fifo_axi_rid     [3], fifo_axi_rid     [2], fifo_axi_rid     [1], fifo_axi_rid     [0]}),
        .m_axi_rdata    ({fifo_axi_rdata   [3], fifo_axi_rdata   [2], fifo_axi_rdata   [1], fifo_axi_rdata   [0]}),
        .m_axi_rresp    ({fifo_axi_rresp   [3], fifo_axi_rresp   [2], fifo_axi_rresp   [1], fifo_axi_rresp   [0]}),
        .m_axi_rlast    ({fifo_axi_rlast   [3], fifo_axi_rlast   [2], fifo_axi_rlast   [1], fifo_axi_rlast   [0]}),
        .m_axi_ruser    ({fifo_axi_ruser   [3], fifo_axi_ruser   [2], fifo_axi_ruser   [1], fifo_axi_ruser   [0]}),
        .m_axi_rvalid   ({fifo_axi_rvalid  [3], fifo_axi_rvalid  [2], fifo_axi_rvalid  [1], fifo_axi_rvalid  [0]}),
        .m_axi_rready   ({fifo_axi_rready  [3], fifo_axi_rready  [2], fifo_axi_rready  [1], fifo_axi_rready  [0]}),

        .debug ()
      );

    end else begin

      noc_block_axi_dma_fifo #(
        .NOC_ID               (64'hF1F0_D000_0000_0004),
        .NUM_FIFOS            (NUM_DRAM_FIFOS),
        .BUS_CLK_RATE         (BUS_CLK_RATE),
        .DEFAULT_FIFO_BASE    ({30'h06000000, 30'h04000000, 30'h02000000, 30'h00000000}),
        .DEFAULT_FIFO_SIZE    ({30'h01FFFFFF, 30'h01FFFFFF, 30'h01FFFFFF, 30'h01FFFFFF}),
        .STR_SINK_FIFOSIZE    (DRAM_FIFO_INPUT_BUFF_SIZE),
        .DEFAULT_BURST_TIMEOUT({NUM_DRAM_FIFOS{12'd280}}),
        .EXTENDED_DRAM_BIST   (1)
      ) noc_block_dram_fifo_i (
        // Clocks and resets
        .bus_clk(bus_clk), .bus_rst(bus_rst),
        .ce_clk(ddr3_dma_clk), .ce_rst(ddr3_dma_rst),
        // AXI-Stream interface to the RFNoC crossbar
        .i_tdata(ioce_o_tdata[0]), .i_tlast(ioce_o_tlast[0]), .i_tvalid(ioce_o_tvalid[0]), .i_tready(ioce_o_tready[0]),
        .o_tdata(ioce_i_tdata[0]), .o_tlast(ioce_i_tlast[0]), .o_tvalid(ioce_i_tvalid[0]), .o_tready(ioce_i_tready[0]),
        // AXI-MM interface to the MIG crossbar
        .m_axi_awid     ({fifo_axi_awid    [3], fifo_axi_awid    [2], fifo_axi_awid    [1], fifo_axi_awid    [0]}),
        .m_axi_awaddr   ({fifo_axi_awaddr  [3], fifo_axi_awaddr  [2], fifo_axi_awaddr  [1], fifo_axi_awaddr  [0]}),
        .m_axi_awlen    ({fifo_axi_awlen   [3], fifo_axi_awlen   [2], fifo_axi_awlen   [1], fifo_axi_awlen   [0]}),
        .m_axi_awsize   ({fifo_axi_awsize  [3], fifo_axi_awsize  [2], fifo_axi_awsize  [1], fifo_axi_awsize  [0]}),
        .m_axi_awburst  ({fifo_axi_awburst [3], fifo_axi_awburst [2], fifo_axi_awburst [1], fifo_axi_awburst [0]}),
        .m_axi_awlock   ({fifo_axi_awlock  [3], fifo_axi_awlock  [2], fifo_axi_awlock  [1], fifo_axi_awlock  [0]}),
        .m_axi_awcache  ({fifo_axi_awcache [3], fifo_axi_awcache [2], fifo_axi_awcache [1], fifo_axi_awcache [0]}),
        .m_axi_awprot   ({fifo_axi_awprot  [3], fifo_axi_awprot  [2], fifo_axi_awprot  [1], fifo_axi_awprot  [0]}),
        .m_axi_awqos    ({fifo_axi_awqos   [3], fifo_axi_awqos   [2], fifo_axi_awqos   [1], fifo_axi_awqos   [0]}),
        .m_axi_awregion ({fifo_axi_awregion[3], fifo_axi_awregion[2], fifo_axi_awregion[1], fifo_axi_awregion[0]}),
        .m_axi_awuser   ({fifo_axi_awuser  [3], fifo_axi_awuser  [2], fifo_axi_awuser  [1], fifo_axi_awuser  [0]}),
        .m_axi_awvalid  ({fifo_axi_awvalid [3], fifo_axi_awvalid [2], fifo_axi_awvalid [1], fifo_axi_awvalid [0]}),
        .m_axi_awready  ({fifo_axi_awready [3], fifo_axi_awready [2], fifo_axi_awready [1], fifo_axi_awready [0]}),
        .m_axi_wdata    ({fifo_axi_wdata   [3], fifo_axi_wdata   [2], fifo_axi_wdata   [1], fifo_axi_wdata   [0]}),
        .m_axi_wstrb    ({fifo_axi_wstrb   [3], fifo_axi_wstrb   [2], fifo_axi_wstrb   [1], fifo_axi_wstrb   [0]}),
        .m_axi_wlast    ({fifo_axi_wlast   [3], fifo_axi_wlast   [2], fifo_axi_wlast   [1], fifo_axi_wlast   [0]}),
        .m_axi_wuser    ({fifo_axi_wuser   [3], fifo_axi_wuser   [2], fifo_axi_wuser   [1], fifo_axi_wuser   [0]}),
        .m_axi_wvalid   ({fifo_axi_wvalid  [3], fifo_axi_wvalid  [2], fifo_axi_wvalid  [1], fifo_axi_wvalid  [0]}),
        .m_axi_wready   ({fifo_axi_wready  [3], fifo_axi_wready  [2], fifo_axi_wready  [1], fifo_axi_wready  [0]}),
        .m_axi_bid      ({fifo_axi_bid     [3], fifo_axi_bid     [2], fifo_axi_bid     [1], fifo_axi_bid     [0]}),
        .m_axi_bresp    ({fifo_axi_bresp   [3], fifo_axi_bresp   [2], fifo_axi_bresp   [1], fifo_axi_bresp   [0]}),
        .m_axi_buser    ({fifo_axi_buser   [3], fifo_axi_buser   [2], fifo_axi_buser   [1], fifo_axi_buser   [0]}),
        .m_axi_bvalid   ({fifo_axi_bvalid  [3], fifo_axi_bvalid  [2], fifo_axi_bvalid  [1], fifo_axi_bvalid  [0]}),
        .m_axi_bready   ({fifo_axi_bready  [3], fifo_axi_bready  [2], fifo_axi_bready  [1], fifo_axi_bready  [0]}),
        .m_axi_arid     ({fifo_axi_arid    [3], fifo_axi_arid    [2], fifo_axi_arid    [1], fifo_axi_arid    [0]}),
        .m_axi_araddr   ({fifo_axi_araddr  [3], fifo_axi_araddr  [2], fifo_axi_araddr  [1], fifo_axi_araddr  [0]}),
        .m_axi_arlen    ({fifo_axi_arlen   [3], fifo_axi_arlen   [2], fifo_axi_arlen   [1], fifo_axi_arlen   [0]}),
        .m_axi_arsize   ({fifo_axi_arsize  [3], fifo_axi_arsize  [2], fifo_axi_arsize  [1], fifo_axi_arsize  [0]}),
        .m_axi_arburst  ({fifo_axi_arburst [3], fifo_axi_arburst [2], fifo_axi_arburst [1], fifo_axi_arburst [0]}),
        .m_axi_arlock   ({fifo_axi_arlock  [3], fifo_axi_arlock  [2], fifo_axi_arlock  [1], fifo_axi_arlock  [0]}),
        .m_axi_arcache  ({fifo_axi_arcache [3], fifo_axi_arcache [2], fifo_axi_arcache [1], fifo_axi_arcache [0]}),
        .m_axi_arprot   ({fifo_axi_arprot  [3], fifo_axi_arprot  [2], fifo_axi_arprot  [1], fifo_axi_arprot  [0]}),
        .m_axi_arqos    ({fifo_axi_arqos   [3], fifo_axi_arqos   [2], fifo_axi_arqos   [1], fifo_axi_arqos   [0]}),
        .m_axi_arregion ({fifo_axi_arregion[3], fifo_axi_arregion[2], fifo_axi_arregion[1], fifo_axi_arregion[0]}),
        .m_axi_aruser   ({fifo_axi_aruser  [3], fifo_axi_aruser  [2], fifo_axi_aruser  [1], fifo_axi_aruser  [0]}),
        .m_axi_arvalid  ({fifo_axi_arvalid [3], fifo_axi_arvalid [2], fifo_axi_arvalid [1], fifo_axi_arvalid [0]}),
        .m_axi_arready  ({fifo_axi_arready [3], fifo_axi_arready [2], fifo_axi_arready [1], fifo_axi_arready [0]}),
        .m_axi_rid      ({fifo_axi_rid     [3], fifo_axi_rid     [2], fifo_axi_rid     [1], fifo_axi_rid     [0]}),
        .m_axi_rdata    ({fifo_axi_rdata   [3], fifo_axi_rdata   [2], fifo_axi_rdata   [1], fifo_axi_rdata   [0]}),
        .m_axi_rresp    ({fifo_axi_rresp   [3], fifo_axi_rresp   [2], fifo_axi_rresp   [1], fifo_axi_rresp   [0]}),
        .m_axi_rlast    ({fifo_axi_rlast   [3], fifo_axi_rlast   [2], fifo_axi_rlast   [1], fifo_axi_rlast   [0]}),
        .m_axi_ruser    ({fifo_axi_ruser   [3], fifo_axi_ruser   [2], fifo_axi_ruser   [1], fifo_axi_ruser   [0]}),
        .m_axi_rvalid   ({fifo_axi_rvalid  [3], fifo_axi_rvalid  [2], fifo_axi_rvalid  [1], fifo_axi_rvalid  [0]}),
        .m_axi_rready   ({fifo_axi_rready  [3], fifo_axi_rready  [2], fifo_axi_rready  [1], fifo_axi_rready  [0]}),
        // Misc
        .debug()
      );

    end
  end
  endgenerate

  /////////////////////////////////////////////////////////////////////////////
  //
  // Radios
  //
  /////////////////////////////////////////////////////////////////////////////

  localparam RADIO_COMPAT_NUM_MAJOR = 32'b1;
  localparam RADIO_COMPAT_NUM_MINOR = 32'b0;
  localparam RADIO_NOC_ID = 64'h12AD_1000_0001_1310 + NUM_CHANNELS_PER_RADIO;
  localparam FIRST_RADIO_CORE_INST = 1;
  localparam LAST_RADIO_CORE_INST = NUM_RADIO_CORES+FIRST_RADIO_CORE_INST;

  // We need enough input buffering for 4 MTU sized packets.
  // Regardless of the sample rate the radio consumes data at a max
  // rate of 153.6MS/s so we need a decent amount of buffering at the input.
  // With 4k samples we have 25us.
  localparam RADIO_INPUT_BUFF_SIZE   = 8'd12;
  // The radio needs a larger output buffer compared to other blocks because it is a finite
  // rate producer i.e. the input is not backpressured.
  // Here, we allocate enough room from 2 MTU sized packets. This buffer serves as a
  // packet gate so we need room for an additional packet if the first one is held due to
  // contention on the crossbar. Any additional buffering will be largely a waste.
  localparam RADIO_OUTPUT_BUFF_SIZE  = 8'd11;

  //------------------------------------
  // Radios
  //------------------------------------
  wire [NUM_CHANNELS-1:0] rx_stb;
  wire [NUM_CHANNELS*16-1:0] rx;
  //correct the ADC channel inversions here:
  wire [63:0] rxAA_corrected;
  wire [63:0] rxAB_corrected;
  wire [63:0] rxBA_corrected;
  wire [63:0] rxBB_corrected;
  wire [15:0] rxAA_D;
  wire [15:0] rxAA_C;
  wire [15:0] rxAA_B;
  wire [15:0] rxAA_A;
  //rxAB_D is db A, adc B, channel D(0)
  wire [15:0] rxAB_D;
  wire [15:0] rxAB_C;
  wire [15:0] rxAB_B;
  wire [15:0] rxAB_A;
  wire [15:0] rxBA_D;
  wire [15:0] rxBA_C;
  wire [15:0] rxBA_B;
  wire [15:0] rxBA_A;
  wire [15:0] rxBB_D;
  wire [15:0] rxBB_C;
  wire [15:0] rxBB_B;
  wire [15:0] rxBB_A;

  //Channel D is channel 0 out of the JESD core, but A is left most channel on DB (J1)
  assign rxAA_D = rxAA[63:48];
  assign rxAA_C = rxAA[47:32];
  assign rxAA_B = rxAA[31:16];
  assign rxAA_A = rxAA[15:0];
  assign rxAB_D = rxAB[63:48];
  assign rxAB_C = rxAB[47:32];
  assign rxAB_B = rxAB[31:16];
  assign rxAB_A = rxAB[15:0];
  assign rxBA_D = rxBA[63:48];
  assign rxBA_C = rxBA[47:32];
  assign rxBA_B = rxBA[31:16];
  assign rxBA_A = rxBA[15:0];
  assign rxBB_D = rxBB[63:48];
  assign rxBB_C = rxBB[47:32];
  assign rxBB_B = rxBB[31:16];
  assign rxBB_A = rxBB[15:0];
  assign rxAA_corrected = {rxAA_D, ~rxAA_C, rxAA_B, ~rxAA_A};
  assign rxAB_corrected = {rxAB_D, ~rxAB_C, rxAB_B, ~rxAB_A};
  assign rxBA_corrected = {rxBA_D, ~rxBA_C, rxBA_B, ~rxBA_A};
  assign rxBB_corrected = {rxBB_D, ~rxBB_C, rxBB_B, ~rxBB_A};


  assign rx_stb = {{4{rxBB_stb}}, {4{rxBA_stb}}, {4{rxAB_stb}}, {4{rxAA_stb}}};
  assign rx = {rxBB_corrected, rxBA_corrected, rxAB_corrected, rxAA_corrected}; //channels 15-0 in that order.


  //eiscat Radio core
  (* keep_hierarchy = "yes" *)
  noc_block_radio_core_eiscat
  #( .ENABLE_BEAMFORM(1))
  inst_noc_block_radio_core_eiscat (
    .bus_clk(bus_clk),
    .bus_rst(bus_rst),
    .ce_clk(radio_clk),
    .ce_rst(radio_rst),
    .i_tdata(ioce_o_tdata[0]), .i_tlast(ioce_o_tlast[0]), .i_tvalid(ioce_o_tvalid[0]), .i_tready(ioce_o_tready[0]),
    .o_tdata(ioce_i_tdata[0]), .o_tlast(ioce_i_tlast[0]), .o_tvalid(ioce_i_tvalid[0]), .o_tready(ioce_i_tready[0]),
    //connects to npio through n310_core
    .i_npio_tdata(npio2eiscat_tdata), .i_npio_tlast(npio2eiscat_tlast), .i_npio_tvalid(npio2eiscat_tvalid), .i_npio_tready(npio2eiscat_tready),
    .o_npio_tdata(eiscat2npio_tdata), .o_npio_tlast(eiscat2npio_tlast), .o_npio_tvalid(eiscat2npio_tvalid), .o_npio_tready(eiscat2npio_tready),
    .debug(ce_debug[0]),
    .rx(rx),
    .rx_stb(rx_stb),
    // GTX Serial I/O
    .sysref_pulse(sysref_pulse),
    .pps(pps),
    .sync_in(sync_in),
    .sync_out(sync_out));

  /////////////////////////////////////////////////////////////////////////////////
  //
  // RFNoC
  //
  /////////////////////////////////////////////////////////////////////////////////

  // Included automatically instantiated CEs sources file created by RFNoC mod tool
  `include "rfnoc_ce_eiscat_inst_n310.v"

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

  ////////////////////////////////////////////////////////////////////////
  //
  // axi_crossbar ports
  // 0  - ETH0
  // 1  - ETH1
  // 2  - DMA
  // 3  - CE0
  // ...
  // 15 - CE13
  //
  ////////////////////////////////////////////////////////////////////////

  // Base width of crossbar based on fixed components (ethernet, DMA)
  localparam XBAR_FIXED_PORTS = 3;
  localparam XBAR_NUM_PORTS = XBAR_FIXED_PORTS + NUM_CE + NUM_IO_CE;

  // Note: The custom accelerator inputs / outputs bitwidth grow based on NUM_CE
  axi_crossbar_regport #(
    .REG_BASE(REG_BASE_XBAR),
    .REG_DWIDTH(REG_DWIDTH),  // Width of the AXI4-Lite data bus (must be 32 or 64)
    .REG_AWIDTH(REG_AWIDTH),  // Width of the address bus
    .FIFO_WIDTH(64),
    .DST_WIDTH(16),
    .NUM_INPUTS(XBAR_NUM_PORTS),
    .NUM_OUTPUTS(XBAR_NUM_PORTS)
  ) inst_axi_crossbar_regport (
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
