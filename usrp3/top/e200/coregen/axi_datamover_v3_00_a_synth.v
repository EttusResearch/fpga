/*******************************************************************************
*     This file is owned and controlled by Xilinx and must be used solely      *
*     for design, simulation, implementation and creation of design files      *
*     limited to Xilinx devices or technologies. Use with non-Xilinx           *
*     devices or technologies is expressly prohibited and immediately          *
*     terminates your license.                                                 *
*                                                                              *
*     XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS" SOLELY     *
*     FOR USE IN DEVELOPING PROGRAMS AND SOLUTIONS FOR XILINX DEVICES.  BY     *
*     PROVIDING THIS DESIGN, CODE, OR INFORMATION AS ONE POSSIBLE              *
*     IMPLEMENTATION OF THIS FEATURE, APPLICATION OR STANDARD, XILINX IS       *
*     MAKING NO REPRESENTATION THAT THIS IMPLEMENTATION IS FREE FROM ANY       *
*     CLAIMS OF INFRINGEMENT, AND YOU ARE RESPONSIBLE FOR OBTAINING ANY        *
*     RIGHTS YOU MAY REQUIRE FOR YOUR IMPLEMENTATION.  XILINX EXPRESSLY        *
*     DISCLAIMS ANY WARRANTY WHATSOEVER WITH RESPECT TO THE ADEQUACY OF THE    *
*     IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR           *
*     REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE FROM CLAIMS OF          *
*     INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A    *
*     PARTICULAR PURPOSE.                                                      *
*                                                                              *
*     Xilinx products are not intended for use in life support appliances,     *
*     devices, or systems.  Use in such applications are expressly             *
*     prohibited.                                                              *
*                                                                              *
*     (c) Copyright 1995-2013 Xilinx, Inc.                                     *
*     All rights reserved.                                                     *
*******************************************************************************/

/*******************************************************************************
*     Generated from core with identifier:                                     *
*     xilinx.com:ip:axi_datamover:3.00.a                                       *
*                                                                              *
*     AXI DataMover is a soft Xilinx IP core used as a building block for      *
*     scalable DMA functions. It provides the basic AXI4 Memory Map Read to    *
*     AXI4-Stream and AXI4-Stream to AXI4 Memory Map Write data transport      *
*     and protocol conversion. It supports Synchronous/Asynchronous            *
*     clocking for Command/Status interface. Supports Memory Map and Stream    *
*     side data widht up to 1024 bits and Memory Map address width up to       *
*     64-bit. AXI Datamover core also provide optional Data Realignment        *
*     Engine (DRE) upto 64-bit of stream data width, General purpose Store     *
*     and Forward unit, Interminate BTT mode.                                  *
*******************************************************************************/
// Source Code Wrapper
// This file is provided to wrap around the source code (if appropriate)

// Interfaces:
//    m_axi_mm2s
//    m_axi_s2mm
//    s_axis_s2mm
//    s_axis_s2mm_cmd
//    m_axis_s2mm_sts
//    s_axis_mm2s_cmd
//    m_axis_mm2s_sts
//    m_axi_mm2s_aclk
//    m_axi_mm2s_aresetn
//    m_axi_s2mm_aclk
//    m_axi_s2mm_aresetn
//    m_axis_mm2s_cmdsts_aclk
//    m_axis_mm2s_cmdsts_aresetn
//    m_axis_s2mm_cmdsts_awclk
//    m_axis_s2mm_cmdsts_aresetn
//    m_axis_mm2s

module axi_datamover_v3_00_a (
  m_axi_mm2s_aclk,
  m_axi_mm2s_aresetn,
  mm2s_halt,
  mm2s_halt_cmplt,
  mm2s_err,
  m_axis_mm2s_cmdsts_aclk,
  m_axis_mm2s_cmdsts_aresetn,
  s_axis_mm2s_cmd_tvalid,
  s_axis_mm2s_cmd_tready,
  s_axis_mm2s_cmd_tdata,
  m_axis_mm2s_sts_tvalid,
  m_axis_mm2s_sts_tready,
  m_axis_mm2s_sts_tdata,
  m_axis_mm2s_sts_tkeep,
  m_axis_mm2s_sts_tlast,
  mm2s_allow_addr_req,
  mm2s_addr_req_posted,
  mm2s_rd_xfer_cmplt,
  m_axi_mm2s_arid,
  m_axi_mm2s_araddr,
  m_axi_mm2s_arlen,
  m_axi_mm2s_arsize,
  m_axi_mm2s_arburst,
  m_axi_mm2s_arprot,
  m_axi_mm2s_arcache,
  m_axi_mm2s_arvalid,
  m_axi_mm2s_arready,
  m_axi_mm2s_rdata,
  m_axi_mm2s_rresp,
  m_axi_mm2s_rlast,
  m_axi_mm2s_rvalid,
  m_axi_mm2s_rready,
  m_axis_mm2s_tdata,
  m_axis_mm2s_tkeep,
  m_axis_mm2s_tlast,
  m_axis_mm2s_tvalid,
  m_axis_mm2s_tready,
  mm2s_dbg_sel,
  mm2s_dbg_data,
  m_axi_s2mm_aclk,
  m_axi_s2mm_aresetn,
  s2mm_halt,
  s2mm_halt_cmplt,
  s2mm_err,
  m_axis_s2mm_cmdsts_awclk,
  m_axis_s2mm_cmdsts_aresetn,
  s_axis_s2mm_cmd_tvalid,
  s_axis_s2mm_cmd_tready,
  s_axis_s2mm_cmd_tdata,
  m_axis_s2mm_sts_tvalid,
  m_axis_s2mm_sts_tready,
  m_axis_s2mm_sts_tdata,
  m_axis_s2mm_sts_tkeep,
  m_axis_s2mm_sts_tlast,
  s2mm_allow_addr_req,
  s2mm_addr_req_posted,
  s2mm_wr_xfer_cmplt,
  s2mm_ld_nxt_len,
  s2mm_wr_len,
  m_axi_s2mm_awid,
  m_axi_s2mm_awaddr,
  m_axi_s2mm_awlen,
  m_axi_s2mm_awsize,
  m_axi_s2mm_awburst,
  m_axi_s2mm_awprot,
  m_axi_s2mm_awcache,
  m_axi_s2mm_awvalid,
  m_axi_s2mm_awready,
  m_axi_s2mm_wdata,
  m_axi_s2mm_wstrb,
  m_axi_s2mm_wlast,
  m_axi_s2mm_wvalid,
  m_axi_s2mm_wready,
  m_axi_s2mm_bresp,
  m_axi_s2mm_bvalid,
  m_axi_s2mm_bready,
  s_axis_s2mm_tdata,
  s_axis_s2mm_tkeep,
  s_axis_s2mm_tlast,
  s_axis_s2mm_tvalid,
  s_axis_s2mm_tready,
  s2mm_dbg_sel,
  s2mm_dbg_data
);

  input m_axi_mm2s_aclk;
  input m_axi_mm2s_aresetn;
  input mm2s_halt;
  output mm2s_halt_cmplt;
  output mm2s_err;
  input m_axis_mm2s_cmdsts_aclk;
  input m_axis_mm2s_cmdsts_aresetn;
  input s_axis_mm2s_cmd_tvalid;
  output s_axis_mm2s_cmd_tready;
  input [71 : 0] s_axis_mm2s_cmd_tdata;
  output m_axis_mm2s_sts_tvalid;
  input m_axis_mm2s_sts_tready;
  output [7 : 0] m_axis_mm2s_sts_tdata;
  output [0 : 0] m_axis_mm2s_sts_tkeep;
  output m_axis_mm2s_sts_tlast;
  input mm2s_allow_addr_req;
  output mm2s_addr_req_posted;
  output mm2s_rd_xfer_cmplt;
  output [3 : 0] m_axi_mm2s_arid;
  output [31 : 0] m_axi_mm2s_araddr;
  output [7 : 0] m_axi_mm2s_arlen;
  output [2 : 0] m_axi_mm2s_arsize;
  output [1 : 0] m_axi_mm2s_arburst;
  output [2 : 0] m_axi_mm2s_arprot;
  output [3 : 0] m_axi_mm2s_arcache;
  output m_axi_mm2s_arvalid;
  input m_axi_mm2s_arready;
  input [63 : 0] m_axi_mm2s_rdata;
  input [1 : 0] m_axi_mm2s_rresp;
  input m_axi_mm2s_rlast;
  input m_axi_mm2s_rvalid;
  output m_axi_mm2s_rready;
  output [63 : 0] m_axis_mm2s_tdata;
  output [7 : 0] m_axis_mm2s_tkeep;
  output m_axis_mm2s_tlast;
  output m_axis_mm2s_tvalid;
  input m_axis_mm2s_tready;
  input [3 : 0] mm2s_dbg_sel;
  output [31 : 0] mm2s_dbg_data;
  input m_axi_s2mm_aclk;
  input m_axi_s2mm_aresetn;
  input s2mm_halt;
  output s2mm_halt_cmplt;
  output s2mm_err;
  input m_axis_s2mm_cmdsts_awclk;
  input m_axis_s2mm_cmdsts_aresetn;
  input s_axis_s2mm_cmd_tvalid;
  output s_axis_s2mm_cmd_tready;
  input [71 : 0] s_axis_s2mm_cmd_tdata;
  output m_axis_s2mm_sts_tvalid;
  input m_axis_s2mm_sts_tready;
  output [31 : 0] m_axis_s2mm_sts_tdata;
  output [3 : 0] m_axis_s2mm_sts_tkeep;
  output m_axis_s2mm_sts_tlast;
  input s2mm_allow_addr_req;
  output s2mm_addr_req_posted;
  output s2mm_wr_xfer_cmplt;
  output s2mm_ld_nxt_len;
  output [7 : 0] s2mm_wr_len;
  output [3 : 0] m_axi_s2mm_awid;
  output [31 : 0] m_axi_s2mm_awaddr;
  output [7 : 0] m_axi_s2mm_awlen;
  output [2 : 0] m_axi_s2mm_awsize;
  output [1 : 0] m_axi_s2mm_awburst;
  output [2 : 0] m_axi_s2mm_awprot;
  output [3 : 0] m_axi_s2mm_awcache;
  output m_axi_s2mm_awvalid;
  input m_axi_s2mm_awready;
  output [63 : 0] m_axi_s2mm_wdata;
  output [7 : 0] m_axi_s2mm_wstrb;
  output m_axi_s2mm_wlast;
  output m_axi_s2mm_wvalid;
  input m_axi_s2mm_wready;
  input [1 : 0] m_axi_s2mm_bresp;
  input m_axi_s2mm_bvalid;
  output m_axi_s2mm_bready;
  input [63 : 0] s_axis_s2mm_tdata;
  input [7 : 0] s_axis_s2mm_tkeep;
  input s_axis_s2mm_tlast;
  input s_axis_s2mm_tvalid;
  output s_axis_s2mm_tready;
  input [3 : 0] s2mm_dbg_sel;
  output [31 : 0] s2mm_dbg_data;

  axi_datamover #(
    .C_FAMILY("zynq"),
    .C_INCLUDE_MM2S(1),
    .C_INCLUDE_MM2S_DRE(0),
    .C_INCLUDE_MM2S_STSFIFO(1),
    .C_INCLUDE_S2MM(1),
    .C_INCLUDE_S2MM_DRE(0),
    .C_INCLUDE_S2MM_STSFIFO(1),
    .C_MM2S_ADDR_PIPE_DEPTH(1),
    .C_MM2S_BTT_USED(16),
    .C_MM2S_BURST_SIZE(32),
    .C_MM2S_INCLUDE_SF(0),
    .C_MM2S_STSCMD_FIFO_DEPTH(1),
    .C_MM2S_STSCMD_IS_ASYNC(0),
    .C_M_AXIS_MM2S_TDATA_WIDTH(64),
    .C_M_AXI_MM2S_ADDR_WIDTH(32),
    .C_M_AXI_MM2S_ARID(0),
    .C_M_AXI_MM2S_DATA_WIDTH(64),
    .C_M_AXI_MM2S_ID_WIDTH(4),
    .C_M_AXI_S2MM_ADDR_WIDTH(32),
    .C_M_AXI_S2MM_AWID(1),
    .C_M_AXI_S2MM_DATA_WIDTH(64),
    .C_M_AXI_S2MM_ID_WIDTH(4),
    .C_S2MM_ADDR_PIPE_DEPTH(1),
    .C_S2MM_BTT_USED(16),
    .C_S2MM_BURST_SIZE(32),
    .C_S2MM_INCLUDE_SF(0),
    .C_S2MM_STSCMD_FIFO_DEPTH(1),
    .C_S2MM_STSCMD_IS_ASYNC(0),
    .C_S2MM_SUPPORT_INDET_BTT(1),
    .C_S_AXIS_S2MM_TDATA_WIDTH(64)
  ) inst (
    .m_axi_mm2s_aclk(m_axi_mm2s_aclk),
    .m_axi_mm2s_aresetn(m_axi_mm2s_aresetn),
    .mm2s_halt(mm2s_halt),
    .mm2s_halt_cmplt(mm2s_halt_cmplt),
    .mm2s_err(mm2s_err),
    .m_axis_mm2s_cmdsts_aclk(m_axis_mm2s_cmdsts_aclk),
    .m_axis_mm2s_cmdsts_aresetn(m_axis_mm2s_cmdsts_aresetn),
    .s_axis_mm2s_cmd_tvalid(s_axis_mm2s_cmd_tvalid),
    .s_axis_mm2s_cmd_tready(s_axis_mm2s_cmd_tready),
    .s_axis_mm2s_cmd_tdata(s_axis_mm2s_cmd_tdata),
    .m_axis_mm2s_sts_tvalid(m_axis_mm2s_sts_tvalid),
    .m_axis_mm2s_sts_tready(m_axis_mm2s_sts_tready),
    .m_axis_mm2s_sts_tdata(m_axis_mm2s_sts_tdata),
    .m_axis_mm2s_sts_tkeep(m_axis_mm2s_sts_tkeep),
    .m_axis_mm2s_sts_tlast(m_axis_mm2s_sts_tlast),
    .mm2s_allow_addr_req(mm2s_allow_addr_req),
    .mm2s_addr_req_posted(mm2s_addr_req_posted),
    .mm2s_rd_xfer_cmplt(mm2s_rd_xfer_cmplt),
    .m_axi_mm2s_arid(m_axi_mm2s_arid),
    .m_axi_mm2s_araddr(m_axi_mm2s_araddr),
    .m_axi_mm2s_arlen(m_axi_mm2s_arlen),
    .m_axi_mm2s_arsize(m_axi_mm2s_arsize),
    .m_axi_mm2s_arburst(m_axi_mm2s_arburst),
    .m_axi_mm2s_arprot(m_axi_mm2s_arprot),
    .m_axi_mm2s_arcache(m_axi_mm2s_arcache),
    .m_axi_mm2s_arvalid(m_axi_mm2s_arvalid),
    .m_axi_mm2s_arready(m_axi_mm2s_arready),
    .m_axi_mm2s_rdata(m_axi_mm2s_rdata),
    .m_axi_mm2s_rresp(m_axi_mm2s_rresp),
    .m_axi_mm2s_rlast(m_axi_mm2s_rlast),
    .m_axi_mm2s_rvalid(m_axi_mm2s_rvalid),
    .m_axi_mm2s_rready(m_axi_mm2s_rready),
    .m_axis_mm2s_tdata(m_axis_mm2s_tdata),
    .m_axis_mm2s_tkeep(m_axis_mm2s_tkeep),
    .m_axis_mm2s_tlast(m_axis_mm2s_tlast),
    .m_axis_mm2s_tvalid(m_axis_mm2s_tvalid),
    .m_axis_mm2s_tready(m_axis_mm2s_tready),
    .mm2s_dbg_sel(mm2s_dbg_sel),
    .mm2s_dbg_data(mm2s_dbg_data),
    .m_axi_s2mm_aclk(m_axi_s2mm_aclk),
    .m_axi_s2mm_aresetn(m_axi_s2mm_aresetn),
    .s2mm_halt(s2mm_halt),
    .s2mm_halt_cmplt(s2mm_halt_cmplt),
    .s2mm_err(s2mm_err),
    .m_axis_s2mm_cmdsts_awclk(m_axis_s2mm_cmdsts_awclk),
    .m_axis_s2mm_cmdsts_aresetn(m_axis_s2mm_cmdsts_aresetn),
    .s_axis_s2mm_cmd_tvalid(s_axis_s2mm_cmd_tvalid),
    .s_axis_s2mm_cmd_tready(s_axis_s2mm_cmd_tready),
    .s_axis_s2mm_cmd_tdata(s_axis_s2mm_cmd_tdata),
    .m_axis_s2mm_sts_tvalid(m_axis_s2mm_sts_tvalid),
    .m_axis_s2mm_sts_tready(m_axis_s2mm_sts_tready),
    .m_axis_s2mm_sts_tdata(m_axis_s2mm_sts_tdata),
    .m_axis_s2mm_sts_tkeep(m_axis_s2mm_sts_tkeep),
    .m_axis_s2mm_sts_tlast(m_axis_s2mm_sts_tlast),
    .s2mm_allow_addr_req(s2mm_allow_addr_req),
    .s2mm_addr_req_posted(s2mm_addr_req_posted),
    .s2mm_wr_xfer_cmplt(s2mm_wr_xfer_cmplt),
    .s2mm_ld_nxt_len(s2mm_ld_nxt_len),
    .s2mm_wr_len(s2mm_wr_len),
    .m_axi_s2mm_awid(m_axi_s2mm_awid),
    .m_axi_s2mm_awaddr(m_axi_s2mm_awaddr),
    .m_axi_s2mm_awlen(m_axi_s2mm_awlen),
    .m_axi_s2mm_awsize(m_axi_s2mm_awsize),
    .m_axi_s2mm_awburst(m_axi_s2mm_awburst),
    .m_axi_s2mm_awprot(m_axi_s2mm_awprot),
    .m_axi_s2mm_awcache(m_axi_s2mm_awcache),
    .m_axi_s2mm_awvalid(m_axi_s2mm_awvalid),
    .m_axi_s2mm_awready(m_axi_s2mm_awready),
    .m_axi_s2mm_wdata(m_axi_s2mm_wdata),
    .m_axi_s2mm_wstrb(m_axi_s2mm_wstrb),
    .m_axi_s2mm_wlast(m_axi_s2mm_wlast),
    .m_axi_s2mm_wvalid(m_axi_s2mm_wvalid),
    .m_axi_s2mm_wready(m_axi_s2mm_wready),
    .m_axi_s2mm_bresp(m_axi_s2mm_bresp),
    .m_axi_s2mm_bvalid(m_axi_s2mm_bvalid),
    .m_axi_s2mm_bready(m_axi_s2mm_bready),
    .s_axis_s2mm_tdata(s_axis_s2mm_tdata),
    .s_axis_s2mm_tkeep(s_axis_s2mm_tkeep),
    .s_axis_s2mm_tlast(s_axis_s2mm_tlast),
    .s_axis_s2mm_tvalid(s_axis_s2mm_tvalid),
    .s_axis_s2mm_tready(s_axis_s2mm_tready),
    .s2mm_dbg_sel(s2mm_dbg_sel),
    .s2mm_dbg_data(s2mm_dbg_data)
  );

endmodule

