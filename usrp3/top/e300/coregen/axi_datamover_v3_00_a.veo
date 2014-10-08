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

// The following must be inserted into your Verilog file for this
// core to be instantiated. Change the instance name and port connections
// (in parentheses) to your own signal names.

//----------- Begin Cut here for INSTANTIATION Template ---// INST_TAG
axi_datamover_v3_00_a your_instance_name (
  .m_axi_mm2s_aclk(m_axi_mm2s_aclk), // input m_axi_mm2s_aclk
  .m_axi_mm2s_aresetn(m_axi_mm2s_aresetn), // input m_axi_mm2s_aresetn
  .mm2s_halt(mm2s_halt), // input mm2s_halt
  .mm2s_halt_cmplt(mm2s_halt_cmplt), // output mm2s_halt_cmplt
  .mm2s_err(mm2s_err), // output mm2s_err
  .m_axis_mm2s_cmdsts_aclk(m_axis_mm2s_cmdsts_aclk), // input m_axis_mm2s_cmdsts_aclk
  .m_axis_mm2s_cmdsts_aresetn(m_axis_mm2s_cmdsts_aresetn), // input m_axis_mm2s_cmdsts_aresetn
  .s_axis_mm2s_cmd_tvalid(s_axis_mm2s_cmd_tvalid), // input s_axis_mm2s_cmd_tvalid
  .s_axis_mm2s_cmd_tready(s_axis_mm2s_cmd_tready), // output s_axis_mm2s_cmd_tready
  .s_axis_mm2s_cmd_tdata(s_axis_mm2s_cmd_tdata), // input [71 : 0] s_axis_mm2s_cmd_tdata
  .m_axis_mm2s_sts_tvalid(m_axis_mm2s_sts_tvalid), // output m_axis_mm2s_sts_tvalid
  .m_axis_mm2s_sts_tready(m_axis_mm2s_sts_tready), // input m_axis_mm2s_sts_tready
  .m_axis_mm2s_sts_tdata(m_axis_mm2s_sts_tdata), // output [7 : 0] m_axis_mm2s_sts_tdata
  .m_axis_mm2s_sts_tkeep(m_axis_mm2s_sts_tkeep), // output [0 : 0] m_axis_mm2s_sts_tkeep
  .m_axis_mm2s_sts_tlast(m_axis_mm2s_sts_tlast), // output m_axis_mm2s_sts_tlast
  .mm2s_allow_addr_req(mm2s_allow_addr_req), // input mm2s_allow_addr_req
  .mm2s_addr_req_posted(mm2s_addr_req_posted), // output mm2s_addr_req_posted
  .mm2s_rd_xfer_cmplt(mm2s_rd_xfer_cmplt), // output mm2s_rd_xfer_cmplt
  .m_axi_mm2s_arid(m_axi_mm2s_arid), // output [3 : 0] m_axi_mm2s_arid
  .m_axi_mm2s_araddr(m_axi_mm2s_araddr), // output [31 : 0] m_axi_mm2s_araddr
  .m_axi_mm2s_arlen(m_axi_mm2s_arlen), // output [7 : 0] m_axi_mm2s_arlen
  .m_axi_mm2s_arsize(m_axi_mm2s_arsize), // output [2 : 0] m_axi_mm2s_arsize
  .m_axi_mm2s_arburst(m_axi_mm2s_arburst), // output [1 : 0] m_axi_mm2s_arburst
  .m_axi_mm2s_arprot(m_axi_mm2s_arprot), // output [2 : 0] m_axi_mm2s_arprot
  .m_axi_mm2s_arcache(m_axi_mm2s_arcache), // output [3 : 0] m_axi_mm2s_arcache
  .m_axi_mm2s_arvalid(m_axi_mm2s_arvalid), // output m_axi_mm2s_arvalid
  .m_axi_mm2s_arready(m_axi_mm2s_arready), // input m_axi_mm2s_arready
  .m_axi_mm2s_rdata(m_axi_mm2s_rdata), // input [63 : 0] m_axi_mm2s_rdata
  .m_axi_mm2s_rresp(m_axi_mm2s_rresp), // input [1 : 0] m_axi_mm2s_rresp
  .m_axi_mm2s_rlast(m_axi_mm2s_rlast), // input m_axi_mm2s_rlast
  .m_axi_mm2s_rvalid(m_axi_mm2s_rvalid), // input m_axi_mm2s_rvalid
  .m_axi_mm2s_rready(m_axi_mm2s_rready), // output m_axi_mm2s_rready
  .m_axis_mm2s_tdata(m_axis_mm2s_tdata), // output [63 : 0] m_axis_mm2s_tdata
  .m_axis_mm2s_tkeep(m_axis_mm2s_tkeep), // output [7 : 0] m_axis_mm2s_tkeep
  .m_axis_mm2s_tlast(m_axis_mm2s_tlast), // output m_axis_mm2s_tlast
  .m_axis_mm2s_tvalid(m_axis_mm2s_tvalid), // output m_axis_mm2s_tvalid
  .m_axis_mm2s_tready(m_axis_mm2s_tready), // input m_axis_mm2s_tready
  .mm2s_dbg_sel(mm2s_dbg_sel), // input [3 : 0] mm2s_dbg_sel
  .mm2s_dbg_data(mm2s_dbg_data), // output [31 : 0] mm2s_dbg_data
  .m_axi_s2mm_aclk(m_axi_s2mm_aclk), // input m_axi_s2mm_aclk
  .m_axi_s2mm_aresetn(m_axi_s2mm_aresetn), // input m_axi_s2mm_aresetn
  .s2mm_halt(s2mm_halt), // input s2mm_halt
  .s2mm_halt_cmplt(s2mm_halt_cmplt), // output s2mm_halt_cmplt
  .s2mm_err(s2mm_err), // output s2mm_err
  .m_axis_s2mm_cmdsts_awclk(m_axis_s2mm_cmdsts_awclk), // input m_axis_s2mm_cmdsts_awclk
  .m_axis_s2mm_cmdsts_aresetn(m_axis_s2mm_cmdsts_aresetn), // input m_axis_s2mm_cmdsts_aresetn
  .s_axis_s2mm_cmd_tvalid(s_axis_s2mm_cmd_tvalid), // input s_axis_s2mm_cmd_tvalid
  .s_axis_s2mm_cmd_tready(s_axis_s2mm_cmd_tready), // output s_axis_s2mm_cmd_tready
  .s_axis_s2mm_cmd_tdata(s_axis_s2mm_cmd_tdata), // input [71 : 0] s_axis_s2mm_cmd_tdata
  .m_axis_s2mm_sts_tvalid(m_axis_s2mm_sts_tvalid), // output m_axis_s2mm_sts_tvalid
  .m_axis_s2mm_sts_tready(m_axis_s2mm_sts_tready), // input m_axis_s2mm_sts_tready
  .m_axis_s2mm_sts_tdata(m_axis_s2mm_sts_tdata), // output [31 : 0] m_axis_s2mm_sts_tdata
  .m_axis_s2mm_sts_tkeep(m_axis_s2mm_sts_tkeep), // output [3 : 0] m_axis_s2mm_sts_tkeep
  .m_axis_s2mm_sts_tlast(m_axis_s2mm_sts_tlast), // output m_axis_s2mm_sts_tlast
  .s2mm_allow_addr_req(s2mm_allow_addr_req), // input s2mm_allow_addr_req
  .s2mm_addr_req_posted(s2mm_addr_req_posted), // output s2mm_addr_req_posted
  .s2mm_wr_xfer_cmplt(s2mm_wr_xfer_cmplt), // output s2mm_wr_xfer_cmplt
  .s2mm_ld_nxt_len(s2mm_ld_nxt_len), // output s2mm_ld_nxt_len
  .s2mm_wr_len(s2mm_wr_len), // output [7 : 0] s2mm_wr_len
  .m_axi_s2mm_awid(m_axi_s2mm_awid), // output [3 : 0] m_axi_s2mm_awid
  .m_axi_s2mm_awaddr(m_axi_s2mm_awaddr), // output [31 : 0] m_axi_s2mm_awaddr
  .m_axi_s2mm_awlen(m_axi_s2mm_awlen), // output [7 : 0] m_axi_s2mm_awlen
  .m_axi_s2mm_awsize(m_axi_s2mm_awsize), // output [2 : 0] m_axi_s2mm_awsize
  .m_axi_s2mm_awburst(m_axi_s2mm_awburst), // output [1 : 0] m_axi_s2mm_awburst
  .m_axi_s2mm_awprot(m_axi_s2mm_awprot), // output [2 : 0] m_axi_s2mm_awprot
  .m_axi_s2mm_awcache(m_axi_s2mm_awcache), // output [3 : 0] m_axi_s2mm_awcache
  .m_axi_s2mm_awvalid(m_axi_s2mm_awvalid), // output m_axi_s2mm_awvalid
  .m_axi_s2mm_awready(m_axi_s2mm_awready), // input m_axi_s2mm_awready
  .m_axi_s2mm_wdata(m_axi_s2mm_wdata), // output [63 : 0] m_axi_s2mm_wdata
  .m_axi_s2mm_wstrb(m_axi_s2mm_wstrb), // output [7 : 0] m_axi_s2mm_wstrb
  .m_axi_s2mm_wlast(m_axi_s2mm_wlast), // output m_axi_s2mm_wlast
  .m_axi_s2mm_wvalid(m_axi_s2mm_wvalid), // output m_axi_s2mm_wvalid
  .m_axi_s2mm_wready(m_axi_s2mm_wready), // input m_axi_s2mm_wready
  .m_axi_s2mm_bresp(m_axi_s2mm_bresp), // input [1 : 0] m_axi_s2mm_bresp
  .m_axi_s2mm_bvalid(m_axi_s2mm_bvalid), // input m_axi_s2mm_bvalid
  .m_axi_s2mm_bready(m_axi_s2mm_bready), // output m_axi_s2mm_bready
  .s_axis_s2mm_tdata(s_axis_s2mm_tdata), // input [63 : 0] s_axis_s2mm_tdata
  .s_axis_s2mm_tkeep(s_axis_s2mm_tkeep), // input [7 : 0] s_axis_s2mm_tkeep
  .s_axis_s2mm_tlast(s_axis_s2mm_tlast), // input s_axis_s2mm_tlast
  .s_axis_s2mm_tvalid(s_axis_s2mm_tvalid), // input s_axis_s2mm_tvalid
  .s_axis_s2mm_tready(s_axis_s2mm_tready), // output s_axis_s2mm_tready
  .s2mm_dbg_sel(s2mm_dbg_sel), // input [3 : 0] s2mm_dbg_sel
  .s2mm_dbg_data(s2mm_dbg_data) // output [31 : 0] s2mm_dbg_data
);
// INST_TAG_END ------ End INSTANTIATION Template ---------

// You must compile the wrapper file axi_datamover_v3_00_a.v when simulating
// the core, axi_datamover_v3_00_a. When compiling the wrapper file, be sure to
// reference the XilinxCoreLib Verilog simulation library. For detailed
// instructions, please refer to the "CORE Generator Help".

