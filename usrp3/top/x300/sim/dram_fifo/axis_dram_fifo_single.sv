//
// Copyright 2015 Ettus Research LLC
//

`timescale 1ns/1ps

module axis_dram_fifo_single
(
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
  axi4_rd_t #(.DWIDTH(128), .AWIDTH(30), .IDWIDTH(4)) mig_axi_rd(.clk(sys_clk));
  axi4_wr_t #(.DWIDTH(128), .AWIDTH(30), .IDWIDTH(4)) mig_axi_wr(.clk(sys_clk));

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

  always @(posedge ddr3_axi_clk)
    ddr3_axi_rst_reg_n <= ~ddr3_axi_rst;

  axi_dram_fifo #(.BASE('h0), .SIZE(24), .TIMEOUT(280)) axi_dram_fifo_i0
  (
    //
    // Clocks and reset
    .bus_clk                    (bus_clk),
    .bus_reset                  (bus_rst),
    .clear                      (1'b0),
    .dram_clk                   (ddr3_axi_clk),
    .dram_reset                 (ddr3_axi_rst),
    //
    // AXI Write address channel
    .m_axi_awid                 (mig_axi_wr.addr.id),
    .m_axi_awaddr               (mig_axi_wr.addr.addr),
    .m_axi_awlen                (mig_axi_wr.addr.len),
    .m_axi_awsize               (mig_axi_wr.addr.size),
    .m_axi_awburst              (mig_axi_wr.addr.burst),
    .m_axi_awlock               (mig_axi_wr.addr.lock),
    .m_axi_awcache              (mig_axi_wr.addr.cache),
    .m_axi_awprot               (mig_axi_wr.addr.prot),
    .m_axi_awqos                (mig_axi_wr.addr.qos),
    .m_axi_awregion             (mig_axi_wr.addr.region),
    .m_axi_awuser               (mig_axi_wr.addr.user),
    .m_axi_awvalid              (mig_axi_wr.addr.valid),
    .m_axi_awready              (mig_axi_wr.addr.ready),
    //
    // AXI Write data channel.
    .m_axi_wdata                (mig_axi_wr.data.data),
    .m_axi_wstrb                (mig_axi_wr.data.strb),
    .m_axi_wlast                (mig_axi_wr.data.last),
    .m_axi_wuser                (mig_axi_wr.data.user),
    .m_axi_wvalid               (mig_axi_wr.data.valid),
    .m_axi_wready               (mig_axi_wr.data.ready),
    //
    // AXI Write response channel signals
    .m_axi_bid                  (mig_axi_wr.resp.id),
    .m_axi_bresp                (mig_axi_wr.resp.resp),
    .m_axi_buser                (mig_axi_wr.resp.user),
    .m_axi_bvalid               (mig_axi_wr.resp.valid),
    .m_axi_bready               (mig_axi_wr.resp.ready),
    //
    // AXI Read address channel
    .m_axi_arid                 (mig_axi_rd.addr.id),
    .m_axi_araddr               (mig_axi_rd.addr.addr),
    .m_axi_arlen                (mig_axi_rd.addr.len),
    .m_axi_arsize               (mig_axi_rd.addr.size),
    .m_axi_arburst              (mig_axi_rd.addr.burst),
    .m_axi_arlock               (mig_axi_rd.addr.lock),
    .m_axi_arcache              (mig_axi_rd.addr.cache),
    .m_axi_arprot               (mig_axi_rd.addr.prot),
    .m_axi_arqos                (mig_axi_rd.addr.qos),
    .m_axi_arregion             (mig_axi_rd.addr.region),
    .m_axi_aruser               (mig_axi_rd.addr.user),
    .m_axi_arvalid              (mig_axi_rd.addr.valid),
    .m_axi_arready              (mig_axi_rd.addr.ready),
    //
    // AXI Read data channel
    .m_axi_rid                  (mig_axi_rd.data.id),
    .m_axi_rdata                (mig_axi_rd.data.data),
    .m_axi_rresp                (mig_axi_rd.data.resp),
    .m_axi_rlast                (mig_axi_rd.data.last),
    .m_axi_ruser                (mig_axi_rd.data.user),
    .m_axi_rvalid               (mig_axi_rd.data.valid),
    .m_axi_rready               (mig_axi_rd.data.ready),
    //
    // CHDR friendly AXI stream input
    .i_tdata                    (i_tdata),
    .i_tlast                    (i_tlast),
    .i_tvalid                   (i_tvalid),
    .i_tready                   (i_tready),
    //
    // CHDR friendly AXI Stream output
    .o_tdata                    (o_tdata),
    .o_tlast                    (o_tlast),
    .o_tvalid                   (o_tvalid),
    .o_tready                   (o_tready),
    //
    // Misc
    .supress_threshold          (16'h0),
    .supress_enable             (1'b0),
    .debug()
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
    .ui_clk                         (ddr3_axi_clk),  // 250MHz clock out
    .ui_clk_sync_rst                (ddr3_axi_rst),  // Active high Reset signal synchronised to 250MHz
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
  ddr3_model sdram_i0 (
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

  ddr3_model sdram_i1 (
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

endmodule
