//
// Copyright 2017 Ettus Research, A National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0
//
// Module: replay_sim_ram
//
// Description:
//
//   Simulation model for the RAM to use for the replay block. This module
//   instantiates the memory (DRAM, SRAM, or a generic AXI RAM depending on the
//   RAM_MODEL parameter).
//
// Parameters:
//
//   RAM_MODEL : Can be "DRAM", "SRAM", or "AXI_RAM". DRAM uses a full DRAM
//               controller and memory model, but takes a long time to
//               simulate. SRAM is faster but might not catch flow control
//               issues due to its high speed. AXI_RAM is a generic simulation
//               models that simulates occasional random memory stalls.
//

`include "sim_axi4_lib.svh"

`default_nettype none

`timescale 1ns/1ps



module replay_sim_ram #(
  parameter RAM_MODEL  = "AXI_RAM",
  parameter MEM_ADDR_W = 32,  // Memory size to use with AXI_RAM
  parameter STALL_PROB = 25   // Stall probability to use with AXI_RAM
) (
  input  wire        ce_clk,
  input  wire        ce_rst,
  input  wire        sys_clk,
  input  wire        sys_rst_n,

  output wire        init_done,

  axi4_rd_t          dma0_axi_rd,
  axi4_wr_t          dma0_axi_wr,
  axi4_rd_t          dma1_axi_rd,
  axi4_wr_t          dma1_axi_wr
);

  //---------------------------------------------------------------------------
  // AXI_RAM Option
  //---------------------------------------------------------------------------
  //
  // In this case, we instantiate a generic AXI_RAM for each replay block. This
  // gives us the fastest simulation. we instantiate a separate RAM for each
  // replay block, rather than use an AXI interconnect block to share a single
  // RAM. This means that when simulating with SRAM, collisions between replay
  // blocks is not possible.
  //
  //---------------------------------------------------------------------------

  generate if (RAM_MODEL == "AXI_RAM") begin

    localparam AWIDTH     = MEM_ADDR_W;
    localparam DWIDTH     = 64;

    // In this case, there's no MIG, so we must generate the status signal
    // indicating the MIG is initialized.
    assign init_done = 1;

    axi_ram_model #(
      .AWIDTH     (AWIDTH),
      .DWIDTH     (DWIDTH),
      .IDWIDTH    (1),
      .BIG_ENDIAN (0),
      .STALL_PROB (STALL_PROB)
    ) axi_ram_model_0 (
      .s_aclk        (ce_clk),
      .s_aresetn     (~ce_rst),
      .s_axi_awid    (dma0_axi_wr.addr.id),
      .s_axi_awaddr  (dma0_axi_wr.addr.addr),
      .s_axi_awlen   (dma0_axi_wr.addr.len),
      .s_axi_awsize  (dma0_axi_wr.addr.size),
      .s_axi_awburst (dma0_axi_wr.addr.burst),
      .s_axi_awvalid (dma0_axi_wr.addr.valid),
      .s_axi_awready (dma0_axi_wr.addr.ready),
      .s_axi_wdata   (dma0_axi_wr.data.data),
      .s_axi_wstrb   (dma0_axi_wr.data.strb),
      .s_axi_wlast   (dma0_axi_wr.data.last),
      .s_axi_wvalid  (dma0_axi_wr.data.valid),
      .s_axi_wready  (dma0_axi_wr.data.ready),
      .s_axi_bid     (dma0_axi_wr.resp.id),
      .s_axi_bresp   (dma0_axi_wr.resp.resp),
      .s_axi_bvalid  (dma0_axi_wr.resp.valid),
      .s_axi_bready  (dma0_axi_wr.resp.ready),
      .s_axi_arid    (dma0_axi_rd.addr.id),
      .s_axi_araddr  (dma0_axi_rd.addr.addr),
      .s_axi_arlen   (dma0_axi_rd.addr.len),
      .s_axi_arsize  (dma0_axi_rd.addr.size),
      .s_axi_arburst (dma0_axi_rd.addr.burst),
      .s_axi_arvalid (dma0_axi_rd.addr.valid),
      .s_axi_arready (dma0_axi_rd.addr.ready),
      .s_axi_rid     (dma0_axi_rd.data.id),
      .s_axi_rdata   (dma0_axi_rd.data.data),
      .s_axi_rresp   (dma0_axi_rd.data.resp),
      .s_axi_rlast   (dma0_axi_rd.data.last),
      .s_axi_rvalid  (dma0_axi_rd.data.valid),
      .s_axi_rready  (dma0_axi_rd.data.ready)
    );

    axi_ram_model #(
      .AWIDTH     (AWIDTH),
      .DWIDTH     (DWIDTH),
      .IDWIDTH    (1),
      .BIG_ENDIAN (0),
      .STALL_PROB (STALL_PROB)
    ) axi_ram_model_1 (
      .s_aclk        (ce_clk),
      .s_aresetn     (~ce_rst),
      .s_axi_awid    (dma1_axi_wr.addr.id),
      .s_axi_awaddr  (dma1_axi_wr.addr.addr),
      .s_axi_awlen   (dma1_axi_wr.addr.len),
      .s_axi_awsize  (dma1_axi_wr.addr.size),
      .s_axi_awburst (dma1_axi_wr.addr.burst),
      .s_axi_awvalid (dma1_axi_wr.addr.valid),
      .s_axi_awready (dma1_axi_wr.addr.ready),
      .s_axi_wdata   (dma1_axi_wr.data.data),
      .s_axi_wstrb   (dma1_axi_wr.data.strb),
      .s_axi_wlast   (dma1_axi_wr.data.last),
      .s_axi_wvalid  (dma1_axi_wr.data.valid),
      .s_axi_wready  (dma1_axi_wr.data.ready),
      .s_axi_bid     (dma1_axi_wr.resp.id),
      .s_axi_bresp   (dma1_axi_wr.resp.resp),
      .s_axi_bvalid  (dma1_axi_wr.resp.valid),
      .s_axi_bready  (dma1_axi_wr.resp.ready),
      .s_axi_arid    (dma1_axi_rd.addr.id),
      .s_axi_araddr  (dma1_axi_rd.addr.addr),
      .s_axi_arlen   (dma1_axi_rd.addr.len),
      .s_axi_arsize  (dma1_axi_rd.addr.size),
      .s_axi_arburst (dma1_axi_rd.addr.burst),
      .s_axi_arvalid (dma1_axi_rd.addr.valid),
      .s_axi_arready (dma1_axi_rd.addr.ready),
      .s_axi_rid     (dma1_axi_rd.data.id),
      .s_axi_rdata   (dma1_axi_rd.data.data),
      .s_axi_rresp   (dma1_axi_rd.data.resp),
      .s_axi_rlast   (dma1_axi_rd.data.last),
      .s_axi_rvalid  (dma1_axi_rd.data.valid),
      .s_axi_rready  (dma1_axi_rd.data.ready)
    );


  //---------------------------------------------------------------------------
  // SRAM Option
  //---------------------------------------------------------------------------
  //
  // In this case, we instantiate a separate SRAM for each replay block, rather
  // than use an AXI interconnect block to share a single SRAM. This is due
  // port widths of the IP that already exists, although new IP could be
  // created. This means that when simulating with SRAM, collisions between
  // replay blocks is not possible.
  //
  //---------------------------------------------------------------------------

  end else if (RAM_MODEL == "SRAM") begin

    // In this case, there's no MIG, so we must generate the status signal
    // indicating the MIG is initialized.
    assign init_done = 1;

    axi4_dualport_sram axi4_dualport_sram_i0 (
      .s_aclk        (ce_clk),                 // input s_aclk
      .s_aresetn     (~ce_rst),                // input s_aresetn
      .s_axi_awid    (dma0_axi_wr.addr.id),    // input [0 : 0] s_axi_awid
      .s_axi_awaddr  (dma0_axi_wr.addr.addr),  // input [31 : 0] s_axi_awaddr
      .s_axi_awlen   (dma0_axi_wr.addr.len),   // input [7 : 0] s_axi_awlen
      .s_axi_awsize  (dma0_axi_wr.addr.size),  // input [2 : 0] s_axi_awsize
      .s_axi_awburst (dma0_axi_wr.addr.burst), // input [1 : 0] s_axi_awburst
      .s_axi_awvalid (dma0_axi_wr.addr.valid), // input s_axi_awvalid
      .s_axi_awready (dma0_axi_wr.addr.ready), // output s_axi_awready
      .s_axi_wdata   (dma0_axi_wr.data.data),  // input [63 : 0] s_axi_wdata
      .s_axi_wstrb   (dma0_axi_wr.data.strb),  // input [7 : 0] s_axi_wstrb
      .s_axi_wlast   (dma0_axi_wr.data.last),  // input s_axi_wlast
      .s_axi_wvalid  (dma0_axi_wr.data.valid), // input s_axi_wvalid
      .s_axi_wready  (dma0_axi_wr.data.ready), // output s_axi_wready
      .s_axi_bid     (dma0_axi_wr.resp.id),    // output [0 : 0] s_axi_bid
      .s_axi_bresp   (dma0_axi_wr.resp.resp),  // output [1 : 0] s_axi_bresp
      .s_axi_bvalid  (dma0_axi_wr.resp.valid), // output s_axi_bvalid
      .s_axi_bready  (dma0_axi_wr.resp.ready), // input s_axi_bready
      .s_axi_arid    (dma0_axi_rd.addr.id),    // input [0 : 0] s_axi_arid
      .s_axi_araddr  (dma0_axi_rd.addr.addr),  // input [31 : 0] s_axi_araddr
      .s_axi_arlen   (dma0_axi_rd.addr.len),   // input [7 : 0] s_axi_arlen
      .s_axi_arsize  (dma0_axi_rd.addr.size),  // input [2 : 0] s_axi_arsize
      .s_axi_arburst (dma0_axi_rd.addr.burst), // input [1 : 0] s_axi_arburst
      .s_axi_arvalid (dma0_axi_rd.addr.valid), // input s_axi_arvalid
      .s_axi_arready (dma0_axi_rd.addr.ready), // output s_axi_arready
      .s_axi_rid     (dma0_axi_rd.data.id),    // output [0 : 0] s_axi_rid
      .s_axi_rdata   (dma0_axi_rd.data.data),  // output [63 : 0] s_axi_rdata
      .s_axi_rresp   (dma0_axi_rd.data.resp),  // output [1 : 0] s_axi_rresp
      .s_axi_rlast   (dma0_axi_rd.data.last),  // output s_axi_rlast
      .s_axi_rvalid  (dma0_axi_rd.data.valid), // output s_axi_rvalid
      .s_axi_rready  (dma0_axi_rd.data.ready)  // input s_axi_rready
    );

    axi4_dualport_sram axi4_dualport_sram_i1 (
      .s_aclk        (ce_clk),                 // input s_aclk
      .s_aresetn     (~ce_rst),                // input s_aresetn
      .s_axi_awid    (dma1_axi_wr.addr.id),    // input [0 : 0] s_axi_awid
      .s_axi_awaddr  (dma1_axi_wr.addr.addr),  // input [31 : 0] s_axi_awaddr
      .s_axi_awlen   (dma1_axi_wr.addr.len),   // input [7 : 0] s_axi_awlen
      .s_axi_awsize  (dma1_axi_wr.addr.size),  // input [2 : 0] s_axi_awsize
      .s_axi_awburst (dma1_axi_wr.addr.burst), // input [1 : 0] s_axi_awburst
      .s_axi_awvalid (dma1_axi_wr.addr.valid), // input s_axi_awvalid
      .s_axi_awready (dma1_axi_wr.addr.ready), // output s_axi_awready
      .s_axi_wdata   (dma1_axi_wr.data.data),  // input [63 : 0] s_axi_wdata
      .s_axi_wstrb   (dma1_axi_wr.data.strb),  // input [7 : 0] s_axi_wstrb
      .s_axi_wlast   (dma1_axi_wr.data.last),  // input s_axi_wlast
      .s_axi_wvalid  (dma1_axi_wr.data.valid), // input s_axi_wvalid
      .s_axi_wready  (dma1_axi_wr.data.ready), // output s_axi_wready
      .s_axi_bid     (dma1_axi_wr.resp.id),    // output [0 : 0] s_axi_bid
      .s_axi_bresp   (dma1_axi_wr.resp.resp),  // output [1 : 0] s_axi_bresp
      .s_axi_bvalid  (dma1_axi_wr.resp.valid), // output s_axi_bvalid
      .s_axi_bready  (dma1_axi_wr.resp.ready), // input s_axi_bready
      .s_axi_arid    (dma1_axi_rd.addr.id),    // input [0 : 0] s_axi_arid
      .s_axi_araddr  (dma1_axi_rd.addr.addr),  // input [31 : 0] s_axi_araddr
      .s_axi_arlen   (dma1_axi_rd.addr.len),   // input [7 : 0] s_axi_arlen
      .s_axi_arsize  (dma1_axi_rd.addr.size),  // input [2 : 0] s_axi_arsize
      .s_axi_arburst (dma1_axi_rd.addr.burst), // input [1 : 0] s_axi_arburst
      .s_axi_arvalid (dma1_axi_rd.addr.valid), // input s_axi_arvalid
      .s_axi_arready (dma1_axi_rd.addr.ready), // output s_axi_arready
      .s_axi_rid     (dma1_axi_rd.data.id),    // output [0 : 0] s_axi_rid
      .s_axi_rdata   (dma1_axi_rd.data.data),  // output [63 : 0] s_axi_rdata
      .s_axi_rresp   (dma1_axi_rd.data.resp),  // output [1 : 0] s_axi_rresp
      .s_axi_rlast   (dma1_axi_rd.data.last),  // output s_axi_rlast
      .s_axi_rvalid  (dma1_axi_rd.data.valid), // output s_axi_rvalid
      .s_axi_rready  (dma1_axi_rd.data.ready)  // input s_axi_rready
    );



  //---------------------------------------------------------------------------
  // DDR3/MIG Simulation Option
  //---------------------------------------------------------------------------
  //
  // In this case, we instantiate the AXI interconnect, MIG (Xilinx DRAM memory
  // interface IP), and DDR3 memory models.
  //
  //---------------------------------------------------------------------------

  end else if (RAM_MODEL == "DRAM") begin

    axi4_rd_t #(.DWIDTH(256), .AWIDTH(30), .IDWIDTH(4)) mig_axi_rd (.clk(sys_clk));
    axi4_wr_t #(.DWIDTH(256), .AWIDTH(30), .IDWIDTH(4)) mig_axi_wr (.clk(sys_clk));

    wire [31:0] ddr3_dq;      // Data pins. Input for Reads; Output for Writes.
    wire [ 3:0] ddr3_dqs_n;   // Data Strobes. Input for Reads; Output for Writes.
    wire [ 3:0] ddr3_dqs_p;
    wire [14:0] ddr3_addr;    // Address
    wire [ 2:0] ddr3_ba;      // Bank Address
    wire        ddr3_ras_n;   // Row Address Strobe
    wire        ddr3_cas_n;   // Column address select
    wire        ddr3_we_n;    // Write Enable
    wire        ddr3_reset_n; // SDRAM reset pin
    wire [ 0:0] ddr3_ck_p;    // Differential clock
    wire [ 0:0] ddr3_ck_n;
    wire [ 0:0] ddr3_cke;     // Clock Enable
    wire [ 0:0] ddr3_cs_n;    // Chip Select
    wire [ 3:0] ddr3_dm;      // Data Mask
    wire [ 0:0] ddr3_odt;     // On-Die termination enable

    wire ddr3_idelay_refclk;

    wire ddr3_axi_clk;    // 1/4 DDR external clock rate
    wire ddr3_axi_clk_x2; // 1/2 DDR external clock rate
    wire ddr3_axi_rst;    // UI reset from MIG

    //-------------------------------------------------------------------------
    // AXI Interconnect Crossbar
    //-------------------------------------------------------------------------
    //
    // This AXI interconnect block is a crossbar with two slave ports and one
    // master, which allows two replay blocks to share the same MIG interface.
    //
    //-------------------------------------------------------------------------

    axi_intercon_2x64_128_bd_wrapper axi_intercon_2x64_128_i (
      // Slave Port 0
      //
      .S00_AXI_ARESETN (~ce_rst),                // input S00_AXI_ARESETN
      .S00_AXI_ACLK    (ce_clk),                 // input S00_AXI_ACLK
      .S00_AXI_AWID    (dma0_axi_wr.addr.id),    // input [0 : 0] S00_AXI_AWID
      .S00_AXI_AWADDR  (dma0_axi_wr.addr.addr),  // input [31 : 0] S00_AXI_AWADDR
      .S00_AXI_AWLEN   (dma0_axi_wr.addr.len),   // input [7 : 0] S00_AXI_AWLEN
      .S00_AXI_AWSIZE  (dma0_axi_wr.addr.size),  // input [2 : 0] S00_AXI_AWSIZE
      .S00_AXI_AWBURST (dma0_axi_wr.addr.burst), // input [1 : 0] S00_AXI_AWBURST
      .S00_AXI_AWLOCK  (dma0_axi_wr.addr.lock),  // input S00_AXI_AWLOCK
      .S00_AXI_AWCACHE (dma0_axi_wr.addr.cache), // input [3 : 0] S00_AXI_AWCACHE
      .S00_AXI_AWPROT  (dma0_axi_wr.addr.prot),  // input [2 : 0] S00_AXI_AWPROT
      .S00_AXI_AWQOS   (dma0_axi_wr.addr.qos),   // input [3 : 0] S00_AXI_AWQOS
      .S00_AXI_AWVALID (dma0_axi_wr.addr.valid), // input S00_AXI_AWVALID
      .S00_AXI_AWREADY (dma0_axi_wr.addr.ready), // output S00_AXI_AWREADY
      .S00_AXI_WDATA   (dma0_axi_wr.data.data),  // input [63 : 0] S00_AXI_WDATA
      .S00_AXI_WSTRB   (dma0_axi_wr.data.strb),  // input [7 : 0] S00_AXI_WSTRB
      .S00_AXI_WLAST   (dma0_axi_wr.data.last),  // input S00_AXI_WLAST
      .S00_AXI_WVALID  (dma0_axi_wr.data.valid), // input S00_AXI_WVALID
      .S00_AXI_WREADY  (dma0_axi_wr.data.ready), // output S00_AXI_WREADY
      .S00_AXI_BID     (dma0_axi_wr.resp.id),    // output [0 : 0] S00_AXI_BID
      .S00_AXI_BRESP   (dma0_axi_wr.resp.resp),  // output [1 : 0] S00_AXI_BRESP
      .S00_AXI_BVALID  (dma0_axi_wr.resp.valid), // output S00_AXI_BVALID
      .S00_AXI_BREADY  (dma0_axi_wr.resp.ready), // input S00_AXI_BREADY
      .S00_AXI_ARID    (dma0_axi_rd.addr.id),    // input [0 : 0] S00_AXI_ARID
      .S00_AXI_ARADDR  (dma0_axi_rd.addr.addr),  // input [31 : 0] S00_AXI_ARADDR
      .S00_AXI_ARLEN   (dma0_axi_rd.addr.len),   // input [7 : 0] S00_AXI_ARLEN
      .S00_AXI_ARSIZE  (dma0_axi_rd.addr.size),  // input [2 : 0] S00_AXI_ARSIZE
      .S00_AXI_ARBURST (dma0_axi_rd.addr.burst), // input [1 : 0] S00_AXI_ARBURST
      .S00_AXI_ARLOCK  (dma0_axi_rd.addr.lock),  // input S00_AXI_ARLOCK
      .S00_AXI_ARCACHE (dma0_axi_rd.addr.cache), // input [3 : 0] S00_AXI_ARCACHE
      .S00_AXI_ARPROT  (dma0_axi_rd.addr.prot),  // input [2 : 0] S00_AXI_ARPROT
      .S00_AXI_ARQOS   (dma0_axi_rd.addr.qos),   // input [3 : 0] S00_AXI_ARQOS
      .S00_AXI_ARVALID (dma0_axi_rd.addr.valid), // input S00_AXI_ARVALID
      .S00_AXI_ARREADY (dma0_axi_rd.addr.ready), // output S00_AXI_ARREADY
      .S00_AXI_RID     (dma0_axi_rd.data.id),    // output [0 : 0] S00_AXI_RID
      .S00_AXI_RDATA   (dma0_axi_rd.data.data),  // output [63 : 0] S00_AXI_RDATA
      .S00_AXI_RRESP   (dma0_axi_rd.data.resp),  // output [1 : 0] S00_AXI_RRESP
      .S00_AXI_RLAST   (dma0_axi_rd.data.last),  // output S00_AXI_RLAST
      .S00_AXI_RVALID  (dma0_axi_rd.data.valid), // output S00_AXI_RVALID
      .S00_AXI_RREADY  (dma0_axi_rd.data.ready), // input S00_AXI_RREADY

      // Slave Port 1
      //
      .S01_AXI_ACLK    (ce_clk),                 // input S00_AXI_ACLK
      .S01_AXI_ARESETN (~ce_rst),                // input S00_AXI_ARESETN
      .S01_AXI_AWID    (dma1_axi_wr.addr.id),    // input [0 : 0] S00_AXI_AWID
      .S01_AXI_AWADDR  (dma1_axi_wr.addr.addr),  // input [31 : 0] S00_AXI_AWADDR
      .S01_AXI_AWLEN   (dma1_axi_wr.addr.len),   // input [7 : 0] S00_AXI_AWLEN
      .S01_AXI_AWSIZE  (dma1_axi_wr.addr.size),  // input [2 : 0] S00_AXI_AWSIZE
      .S01_AXI_AWBURST (dma1_axi_wr.addr.burst), // input [1 : 0] S00_AXI_AWBURST
      .S01_AXI_AWLOCK  (dma1_axi_wr.addr.lock),  // input S00_AXI_AWLOCK
      .S01_AXI_AWCACHE (dma1_axi_wr.addr.cache), // input [3 : 0] S00_AXI_AWCACHE
      .S01_AXI_AWPROT  (dma1_axi_wr.addr.prot),  // input [2 : 0] S00_AXI_AWPROT
      .S01_AXI_AWQOS   (dma1_axi_wr.addr.qos),   // input [3 : 0] S00_AXI_AWQOS
      .S01_AXI_AWVALID (dma1_axi_wr.addr.valid), // input S00_AXI_AWVALID
      .S01_AXI_AWREADY (dma1_axi_wr.addr.ready), // output S00_AXI_AWREADY
      .S01_AXI_WDATA   (dma1_axi_wr.data.data),  // input [63 : 0] S00_AXI_WDATA
      .S01_AXI_WSTRB   (dma1_axi_wr.data.strb),  // input [7 : 0] S00_AXI_WSTRB
      .S01_AXI_WLAST   (dma1_axi_wr.data.last),  // input S00_AXI_WLAST
      .S01_AXI_WVALID  (dma1_axi_wr.data.valid), // input S00_AXI_WVALID
      .S01_AXI_WREADY  (dma1_axi_wr.data.ready), // output S00_AXI_WREADY
      .S01_AXI_BID     (dma1_axi_wr.resp.id),    // output [0 : 0] S00_AXI_BID
      .S01_AXI_BRESP   (dma1_axi_wr.resp.resp),  // output [1 : 0] S00_AXI_BRESP
      .S01_AXI_BVALID  (dma1_axi_wr.resp.valid), // output S00_AXI_BVALID
      .S01_AXI_BREADY  (dma1_axi_wr.resp.ready), // input S00_AXI_BREADY
      .S01_AXI_ARID    (dma1_axi_rd.addr.id),    // input [0 : 0] S00_AXI_ARID
      .S01_AXI_ARADDR  (dma1_axi_rd.addr.addr),  // input [31 : 0] S00_AXI_ARADDR
      .S01_AXI_ARLEN   (dma1_axi_rd.addr.len),   // input [7 : 0] S00_AXI_ARLEN
      .S01_AXI_ARSIZE  (dma1_axi_rd.addr.size),  // input [2 : 0] S00_AXI_ARSIZE
      .S01_AXI_ARBURST (dma1_axi_rd.addr.burst), // input [1 : 0] S00_AXI_ARBURST
      .S01_AXI_ARLOCK  (dma1_axi_rd.addr.lock),  // input S00_AXI_ARLOCK
      .S01_AXI_ARCACHE (dma1_axi_rd.addr.cache), // input [3 : 0] S00_AXI_ARCACHE
      .S01_AXI_ARPROT  (dma1_axi_rd.addr.prot),  // input [2 : 0] S00_AXI_ARPROT
      .S01_AXI_ARQOS   (dma1_axi_rd.addr.qos),   // input [3 : 0] S00_AXI_ARQOS
      .S01_AXI_ARVALID (dma1_axi_rd.addr.valid), // input S00_AXI_ARVALID
      .S01_AXI_ARREADY (dma1_axi_rd.addr.ready), // output S00_AXI_ARREADY
      .S01_AXI_RID     (dma1_axi_rd.data.id),    // output [0 : 0] S00_AXI_RID
      .S01_AXI_RDATA   (dma1_axi_rd.data.data),  // output [63 : 0] S00_AXI_RDATA
      .S01_AXI_RRESP   (dma1_axi_rd.data.resp),  // output [1 : 0] S00_AXI_RRESP
      .S01_AXI_RLAST   (dma1_axi_rd.data.last),  // output S00_AXI_RLAST
      .S01_AXI_RVALID  (dma1_axi_rd.data.valid), // output S00_AXI_RVALID
      .S01_AXI_RREADY  (dma1_axi_rd.data.ready), // input S00_AXI_RREADY

      // Master Port 0
      //
      .M00_AXI_ACLK    (ddr3_axi_clk),          // input M00_AXI_ACLK
      .M00_AXI_ARESETN (~ddr3_axi_rst),         // input S00_AXI_ARESETN
      .M00_AXI_AWID    (mig_axi_wr.addr.id),    // output [3 : 0] M00_AXI_AWID
      .M00_AXI_AWADDR  (mig_axi_wr.addr.addr),  // output [31 : 0] M00_AXI_AWADDR
      .M00_AXI_AWLEN   (mig_axi_wr.addr.len),   // output [7 : 0] M00_AXI_AWLEN
      .M00_AXI_AWSIZE  (mig_axi_wr.addr.size),  // output [2 : 0] M00_AXI_AWSIZE
      .M00_AXI_AWBURST (mig_axi_wr.addr.burst), // output [1 : 0] M00_AXI_AWBURST
      .M00_AXI_AWLOCK  (mig_axi_wr.addr.lock),  // output M00_AXI_AWLOCK
      .M00_AXI_AWCACHE (mig_axi_wr.addr.cache), // output [3 : 0] M00_AXI_AWCACHE
      .M00_AXI_AWPROT  (mig_axi_wr.addr.prot),  // output [2 : 0] M00_AXI_AWPROT
      .M00_AXI_AWQOS   (mig_axi_wr.addr.qos),   // output [3 : 0] M00_AXI_AWQOS
      .M00_AXI_AWVALID (mig_axi_wr.addr.valid), // output M00_AXI_AWVALID
      .M00_AXI_AWREADY (mig_axi_wr.addr.ready), // input M00_AXI_AWREADY
      .M00_AXI_WDATA   (mig_axi_wr.data.data),  // output [127 : 0] M00_AXI_WDATA
      .M00_AXI_WSTRB   (mig_axi_wr.data.strb),  // output [15 : 0] M00_AXI_WSTRB
      .M00_AXI_WLAST   (mig_axi_wr.data.last),  // output M00_AXI_WLAST
      .M00_AXI_WVALID  (mig_axi_wr.data.valid), // output M00_AXI_WVALID
      .M00_AXI_WREADY  (mig_axi_wr.data.ready), // input M00_AXI_WREADY
      .M00_AXI_BID     (mig_axi_wr.resp.id),    // input [3 : 0] M00_AXI_BID
      .M00_AXI_BRESP   (mig_axi_wr.resp.resp),  // input [1 : 0] M00_AXI_BRESP
      .M00_AXI_BVALID  (mig_axi_wr.resp.valid), // input M00_AXI_BVALID
      .M00_AXI_BREADY  (mig_axi_wr.resp.ready), // output M00_AXI_BREADY
      .M00_AXI_ARID    (mig_axi_rd.addr.id),    // output [3 : 0] M00_AXI_ARID
      .M00_AXI_ARADDR  (mig_axi_rd.addr.addr),  // output [31 : 0] M00_AXI_ARADDR
      .M00_AXI_ARLEN   (mig_axi_rd.addr.len),   // output [7 : 0] M00_AXI_ARLEN
      .M00_AXI_ARSIZE  (mig_axi_rd.addr.size),  // output [2 : 0] M00_AXI_ARSIZE
      .M00_AXI_ARBURST (mig_axi_rd.addr.burst), // output [1 : 0] M00_AXI_ARBURST
      .M00_AXI_ARLOCK  (mig_axi_rd.addr.lock),  // output M00_AXI_ARLOCK
      .M00_AXI_ARCACHE (mig_axi_rd.addr.cache), // output [3 : 0] M00_AXI_ARCACHE
      .M00_AXI_ARPROT  (mig_axi_rd.addr.prot),  // output [2 : 0] M00_AXI_ARPROT
      .M00_AXI_ARQOS   (mig_axi_rd.addr.qos),   // output [3 : 0] M00_AXI_ARQOS
      .M00_AXI_ARVALID (mig_axi_rd.addr.valid), // output M00_AXI_ARVALID
      .M00_AXI_ARREADY (mig_axi_rd.addr.ready), // input M00_AXI_ARREADY
      .M00_AXI_RID     (mig_axi_rd.data.id),    // input [3 : 0] M00_AXI_RID
      .M00_AXI_RDATA   (mig_axi_rd.data.data),  // input [127 : 0] M00_AXI_RDATA
      .M00_AXI_RRESP   (mig_axi_rd.data.resp),  // input [1 : 0] M00_AXI_RRESP
      .M00_AXI_RLAST   (mig_axi_rd.data.last),  // input M00_AXI_RLAST
      .M00_AXI_RVALID  (mig_axi_rd.data.valid), // input M00_AXI_RVALID
      .M00_AXI_RREADY  (mig_axi_rd.data.ready)  // output M00_AXI_RREADY
    );


    //-------------------------------------------------------------------------
    // MIG Instance
    //-------------------------------------------------------------------------

    ddr3_32bit ddr_mig_i (
      // Memory interface ports
      .ddr3_addr           (ddr3_addr),
      .ddr3_ba             (ddr3_ba),
      .ddr3_cas_n          (ddr3_cas_n),
      .ddr3_ck_n           (ddr3_ck_n),
      .ddr3_ck_p           (ddr3_ck_p),
      .ddr3_cke            (ddr3_cke),
      .ddr3_ras_n          (ddr3_ras_n),
      .ddr3_reset_n        (ddr3_reset_n),
      .ddr3_we_n           (ddr3_we_n),
      .ddr3_dq             (ddr3_dq),
      .ddr3_dqs_n          (ddr3_dqs_n),
      .ddr3_dqs_p          (ddr3_dqs_p),
      .init_calib_complete (init_done),
      .ddr3_cs_n           (ddr3_cs_n),
      .ddr3_dm             (ddr3_dm),
      .ddr3_odt            (ddr3_odt),

      // Application interface ports
      .ui_clk          (ddr3_axi_clk),
      .ui_addn_clk_0   (ddr3_axi_clk_x2),
      .ui_addn_clk_1   (ddr3_idelay_refclk),
      .ui_addn_clk_2   (),
      .ui_addn_clk_3   (),
      .ui_addn_clk_4   (),
      .clk_ref_i       (ddr3_idelay_refclk),
      .ui_clk_sync_rst (ddr3_axi_rst),    // Active high reset output signal
                                          // synchronized to ui_clk.
      .aresetn         (~ddr3_axi_rst),   // AXI shim reset input, should be synchronous to ui_clk
      .app_sr_req      (1'b0),
      .app_sr_active   (),
      .app_ref_req     (1'b0),
      .app_ref_ack     (),
      .app_zq_req      (1'b0),
      .app_zq_ack      (),

      // Slave Interface Write Address Ports
      .s_axi_awid    (mig_axi_wr.addr.id),
      .s_axi_awaddr  (mig_axi_wr.addr.addr),
      .s_axi_awlen   (mig_axi_wr.addr.len),
      .s_axi_awsize  (mig_axi_wr.addr.size),
      .s_axi_awburst (mig_axi_wr.addr.burst),
      .s_axi_awlock  (mig_axi_wr.addr.lock),
      .s_axi_awcache (mig_axi_wr.addr.cache),
      .s_axi_awprot  (mig_axi_wr.addr.prot),
      .s_axi_awqos   (mig_axi_wr.addr.qos),
      .s_axi_awvalid (mig_axi_wr.addr.valid),
      .s_axi_awready (mig_axi_wr.addr.ready),

      // Slave Interface Write Data Ports
      .s_axi_wdata  (mig_axi_wr.data.data),
      .s_axi_wstrb  (mig_axi_wr.data.strb),
      .s_axi_wlast  (mig_axi_wr.data.last),
      .s_axi_wvalid (mig_axi_wr.data.valid),
      .s_axi_wready (mig_axi_wr.data.ready),

      // Slave Interface Write Response Ports
      .s_axi_bid    (mig_axi_wr.resp.id),
      .s_axi_bresp  (mig_axi_wr.resp.resp),
      .s_axi_bvalid (mig_axi_wr.resp.valid),
      .s_axi_bready (mig_axi_wr.resp.ready),

      // Slave Interface Read Address Ports
      .s_axi_arid    (mig_axi_rd.addr.id),
      .s_axi_araddr  (mig_axi_rd.addr.addr),
      .s_axi_arlen   (mig_axi_rd.addr.len),
      .s_axi_arsize  (mig_axi_rd.addr.size),
      .s_axi_arburst (mig_axi_rd.addr.burst),
      .s_axi_arlock  (mig_axi_rd.addr.lock),
      .s_axi_arcache (mig_axi_rd.addr.cache),
      .s_axi_arprot  (mig_axi_rd.addr.prot),
      .s_axi_arqos   (mig_axi_rd.addr.qos),
      .s_axi_arvalid (mig_axi_rd.addr.valid),
      .s_axi_arready (mig_axi_rd.addr.ready),

      // Slave Interface Read Data Ports
      .s_axi_rid    (mig_axi_rd.data.id),
      .s_axi_rdata  (mig_axi_rd.data.data),
      .s_axi_rresp  (mig_axi_rd.data.resp),
      .s_axi_rlast  (mig_axi_rd.data.last),
      .s_axi_rvalid (mig_axi_rd.data.valid),
      .s_axi_rready (mig_axi_rd.data.ready),

      // System Clock Ports
      .sys_clk_i (sys_clk),
      .sys_rst   (~sys_rst_n)
    );


    //-------------------------------------------------------------------------
    // DDR3 SDRAM Models
    //-------------------------------------------------------------------------

    ddr3_model #(
      .DEBUG (0)  // Disable verbose prints
    ) ddr3_model_i0 (
      .rst_n   (ddr3_reset_n),
      .ck      (ddr3_ck_p),
      .ck_n    (ddr3_ck_n),
      .cke     (ddr3_cke),
      .cs_n    (ddr3_cs_n),
      .ras_n   (ddr3_ras_n),
      .cas_n   (ddr3_cas_n),
      .we_n    (ddr3_we_n),
      .dm_tdqs (ddr3_dm[1:0]),
      .ba      (ddr3_ba),
      .addr    (ddr3_addr),
      .dq      (ddr3_dq[15:0]),
      .dqs     (ddr3_dqs_p[1:0]),
      .dqs_n   (ddr3_dqs_n[1:0]),
      .tdqs_n  (),                // Unused on x16
      .odt     (ddr3_odt)
    );

    ddr3_model #(
      .DEBUG (0)  //Disable verbose prints
    ) ddr3_model_i1 (
      .rst_n   (ddr3_reset_n),
      .ck      (ddr3_ck_p),
      .ck_n    (ddr3_ck_n),
      .cke     (ddr3_cke),
      .cs_n    (ddr3_cs_n),
      .ras_n   (ddr3_ras_n),
      .cas_n   (ddr3_cas_n),
      .we_n    (ddr3_we_n),
      .dm_tdqs (ddr3_dm[3:2]),
      .ba      (ddr3_ba),
      .addr    (ddr3_addr),
      .dq      (ddr3_dq[31:16]),
      .dqs     (ddr3_dqs_p[3:2]),
      .dqs_n   (ddr3_dqs_n[3:2]),
      .tdqs_n  (),                // Unused on x16
      .odt     (ddr3_odt)
    );

  end endgenerate

endmodule


`default_nettype wire
