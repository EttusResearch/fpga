/////////////////////////////////////////////////////////////////////
//
// Copyright 2017 Ettus Research, A National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0
//
// Module: eth_switch
// Description:
//   - Registers - Device MAC, IP address, UDP ports for normal and Bridge Mode
//   - eth dispatch - Classify ethernet packets and route them to CPU, CROSSOVER
//                    and VITA(crossbar)
//   - chdr_eth_framer - Frames internal VITA packets from crossbar into
//                       ethernet packets.
//
//////////////////////////////////////////////////////////////////////

`default_nettype none
module n3xx_eth_switch #(
  parameter BASE                     = 0,
  parameter XO_FIFOSIZE              = 1,
  parameter CPU_FIFOSIZE             = 10,
  parameter VITA_FIFOSIZE            = 11,
  parameter ETHOUT_FIFOSIZE          = 1,
  parameter REG_DWIDTH               = 32,    // Width of the AXI4-Lite data bus (must be 32 or 64)
  parameter REG_AWIDTH               = 14,    // Width of the address bus
  parameter [47:0] DEFAULT_MAC_ADDR  = {8'h00, 8'h80, 8'h2f, 8'h16, 8'hc5, 8'h2f},
  parameter [31:0] DEFAULT_IP_ADDR   = {8'd192, 8'd168, 8'd10, 8'd2},
  parameter [31:0] DEFAULT_UDP_PORTS = {16'd49154, 16'd49153}
)(

  input  wire         clk,
  input  wire         reset,
  input  wire         clear,

  // Register port: Write port (domain: clk)
  input  wire                     reg_wr_req,
  input  wire [REG_AWIDTH-1:0]    reg_wr_addr,
  input  wire [REG_DWIDTH-1:0]    reg_wr_data,
  input  wire [REG_DWIDTH/8-1:0]  reg_wr_keep,

  // Register port: Read port (domain: clk)
  input  wire                  reg_rd_req,
  input  wire [REG_AWIDTH-1:0] reg_rd_addr,
  output reg                   reg_rd_resp,
  output reg  [REG_DWIDTH-1:0] reg_rd_data,

  // Eth ports
  output wire [63:0]  eth_tx_tdata,
  output wire [3:0]   eth_tx_tuser,
  output wire         eth_tx_tlast,
  output wire         eth_tx_tvalid,
  input  wire         eth_tx_tready,

  input  wire [63:0]  eth_rx_tdata,
  input  wire [3:0]   eth_rx_tuser,
  input  wire         eth_rx_tlast,
  input  wire         eth_rx_tvalid,
  output wire         eth_rx_tready,

  // Vita router interface
  output wire [63:0]  e2v_tdata,
  output wire         e2v_tlast,
  output wire         e2v_tvalid,
  input  wire         e2v_tready,

  input  wire [63:0]  v2e_tdata,
  input  wire         v2e_tlast,
  input  wire         v2e_tvalid,
  output wire         v2e_tready,

  // Ethernet crossover
  output wire [63:0]  xo_tdata,
  output wire [3:0]   xo_tuser,
  output wire         xo_tlast,
  output wire         xo_tvalid,
  input  wire         xo_tready,

  input  wire [63:0]  xi_tdata,
  input  wire [3:0]   xi_tuser,
  input  wire         xi_tlast,
  input  wire         xi_tvalid,
  output wire         xi_tready,

  // CPU
  output wire [63:0]  e2c_tdata,
  output wire [3:0]   e2c_tuser,
  output wire         e2c_tlast,
  output wire         e2c_tvalid,
  input  wire         e2c_tready,

  input  wire [63:0]  c2e_tdata,
  input  wire [3:0]   c2e_tuser,
  input  wire         c2e_tlast,
  input  wire         c2e_tvalid,
  output wire         c2e_tready,

  // Debug
  output wire [31:0]  debug
  );

  //---------------------------------------------------------
  // Registers
  //---------------------------------------------------------

  // Allocate one full page for MAC
  localparam REG_MAC_LSB        = BASE + 'h0000;
  localparam REG_MAC_MSB        = BASE + 'h0004;

  // Source IP address
  localparam REG_IP             = BASE + 'h1000;
  // Source UDP Port
  localparam REG_UDP            = BASE + 'h1004;

  // Base Address for eth_dispatch
  localparam REG_BASE_DISPATCH  = BASE + 'h1008;

  // Registers for Bridge Network Mode in CPU
  localparam REG_BRIDGE_MAC_LSB = BASE + 'h1010;
  localparam REG_BRIDGE_MAC_MSB = BASE + 'h1014;
  localparam REG_BRIDGE_IP      = BASE + 'h1018;
  localparam REG_BRIDGE_UDP     = BASE + 'h101c;
  localparam REG_BRIDGE_ENABLE  = BASE + 'h1020;

  // Base address for chdr_eth_framer
  localparam REG_BASE_FRAMER    = BASE + 'h2000;
  localparam REG_END_ADDR_FRAMER    = BASE + 'h2FFF;

  // Setting register width
  localparam SR_AWIDTH = 12;

  // MAC address for the dispatcher module.
  // This value is used to determine if the packet is meant
  // for this device should be consumed
  // IP address for the dispatcher module.
  // This value is used to determine if the packet is addressed
  // to this device
  // This module supports two destination ports
  reg [47:0]      mac_reg;
  reg [31:0]      ip_reg;
  reg [15:0]      udp_port0, udp_port1;
  reg [47:0]      bridge_mac_reg;
  reg [31:0]      bridge_ip_reg;
  reg [15:0]      bridge_udp_port0, bridge_udp_port1;
  reg             bridge_en;
  wire [47:0]     my_mac;
  wire [31:0]     my_ip;
  wire [15:0]     my_udp_port0;
  wire [15:0]     my_udp_port1;

  assign my_mac       = bridge_en ? bridge_mac_reg : mac_reg;
  assign my_ip        = bridge_en ? bridge_ip_reg : ip_reg;
  assign my_udp_port0 = bridge_en ? bridge_udp_port0 : udp_port0;

  always @(posedge clk) begin
    if (reset) begin
      mac_reg                             <= DEFAULT_MAC_ADDR;
      ip_reg                              <= DEFAULT_IP_ADDR;
      {udp_port1,udp_port0}               <= DEFAULT_UDP_PORTS;
      bridge_en                           <= 1'b0;
      bridge_mac_reg                      <= DEFAULT_MAC_ADDR;
      bridge_ip_reg                       <= DEFAULT_IP_ADDR;
      {bridge_udp_port1,bridge_udp_port0} <= DEFAULT_UDP_PORTS;
    end
    else begin
      if (reg_wr_req)
        case (reg_wr_addr)

        REG_MAC_LSB:
          mac_reg[31:0]                       <= reg_wr_data;

        REG_MAC_MSB:
          mac_reg[47:32]                      <= reg_wr_data[15:0];

        REG_IP:
          ip_reg                              <= reg_wr_data;

        REG_UDP:
          {udp_port1,udp_port0}               <= reg_wr_data;

        REG_BRIDGE_MAC_LSB:
          bridge_mac_reg[31:0]                <= reg_wr_data;

        REG_BRIDGE_MAC_MSB:
          bridge_mac_reg[47:32]               <= reg_wr_data[15:0];

        REG_BRIDGE_IP:
          bridge_ip_reg                       <= reg_wr_data;

        REG_BRIDGE_UDP:
          {bridge_udp_port1,bridge_udp_port0} <= reg_wr_data;

        REG_BRIDGE_ENABLE:
          bridge_en                           <= reg_wr_data[0];
        endcase
    end
  end

  always @ (posedge clk) begin
    // No reset handling required for readback
    if (reg_rd_req) begin
      // Assert read response one cycle after read request
      reg_rd_resp <= 1'b1;
      case (reg_rd_addr)
        REG_MAC_LSB:
          reg_rd_data <= mac_reg[31:0];

        REG_MAC_MSB:
          reg_rd_data <= {16'b0,mac_reg[47:32]};

        REG_IP:
          reg_rd_data <= ip_reg;

        REG_UDP:
          reg_rd_data <= {udp_port1, udp_port0};

        REG_BRIDGE_MAC_LSB:
          reg_rd_data <= bridge_mac_reg[31:0];

        REG_BRIDGE_MAC_MSB:
          reg_rd_data <= {16'b0,bridge_mac_reg[47:32]};

        REG_BRIDGE_IP:
          reg_rd_data <= bridge_ip_reg;

        REG_BRIDGE_UDP:
          reg_rd_data <= {bridge_udp_port1, bridge_udp_port0};

        REG_BRIDGE_ENABLE:
          reg_rd_data <= {31'b0,bridge_en};

        default:
          reg_rd_resp <= 1'b0;
      endcase
    end
    // Deassert read response after one clock cycle
    if (reg_rd_resp) begin
      reg_rd_resp <= 1'b0;
    end
  end

  wire [63:0] v2ef_tdata;
  wire [3:0]  v2ef_tuser;
  wire        v2ef_tlast, v2ef_tvalid, v2ef_tready;

  ////////////////////////////////////////////////////////////////
  //
  // Incoming Ethernet path
  // Includes FIFO on the output going to CPU
  //
  ////////////////////////////////////////////////////////////////

  wire [63:0] epg_tdata_int;
  wire [3:0]  epg_tuser_int;
  wire        epg_tlast_int, epg_tvalid_int, epg_tready_int;

  //
  // Packet gate ensures on entire ingressing packet is buffered before feeding it downstream so that it bursts
  // efficiently internally without holding resources allocted for longer than optimal. This also means that an upstream
  // error discovered in the packet can allow the packet to be destroyed here, before it gets deeper into the USRP.
  //
  // This gate must be able to hold at least 9900 bytes which is the maximum length between the SOF and EOF
  // as asserted by the 1G and 10G MACs. This is required in case one of the max size packets has an error
  // and needs to be dropped. With SIZE=11, this gate will hold 2 8k packets.

  axi_packet_gate #(
    .WIDTH(68),
    .SIZE(11)
  ) packet_gater (
    .clk(clk),
    .reset(reset),
    .clear(clear),
    .i_tdata({eth_rx_tuser, eth_rx_tdata}),
    .i_tlast(eth_rx_tlast),
    .i_terror(eth_rx_tuser[3]), //top bit of user bus is error
    .i_tvalid(eth_rx_tvalid),
    .i_tready(eth_rx_tready),

    .o_tdata({epg_tuser_int, epg_tdata_int}),
    .o_tlast(epg_tlast_int),
    .o_tvalid(epg_tvalid_int),
    .o_tready(epg_tready_int)
  );

  //
  // Based on programmed rules, parse network headers and decide which internal destination(s) this packet will be forwarded to.
  //
  wire  [63:0]    e2v_tdata_int;
  wire            e2v_tlast_int, e2v_tvalid_int, e2v_tready_int;

  wire  [63:0]    e2c_tdata_int;
  wire  [3:0]     e2c_tuser_int;
  wire            e2c_tlast_int, e2c_tvalid_int, e2c_tready_int;

  wire  [63:0]    e2c_tdata_int2;
  wire  [3:0]     e2c_tuser_int2;
  wire            e2c_tlast_int2, e2c_tvalid_int2, e2c_tready_int2;

  wire                  dispatch_set_stb;
  wire [SR_AWIDTH-1:0]  dispatch_set_addr;
  wire [REG_DWIDTH-1:0] dispatch_set_data;

  // Convert regport to setting bus
  regport_to_settingsbus #(
    .BASE(REG_BASE_DISPATCH),
    .END_ADDR(REG_BASE_DISPATCH + 14'h8), // has 2 register for now
    .DWIDTH(REG_DWIDTH),
    .AWIDTH(REG_AWIDTH),
    .SR_AWIDTH(SR_AWIDTH),
    .ADDRESSING("WORD")
  )
  inst_eth_dispatch_settingsbus (
    .clk(clk),
    .reset(reset),
    .reg_wr_req(reg_wr_req),
    .reg_wr_addr(reg_wr_addr),
    .reg_wr_data(reg_wr_data),
    .set_stb(dispatch_set_stb),
    .set_addr(dispatch_set_addr),
    .set_data(dispatch_set_data)
  );

  n3xx_eth_dispatch #(
    .BASE(0),
    .AWIDTH(SR_AWIDTH),
    .DROP_UNKNOWN_MAC(0)
  ) eth_dispatch (
    .clk(clk),
    .reset(reset),
    .clear(clear),

    .set_stb(dispatch_set_stb),
    .set_addr(dispatch_set_addr),
    .set_data(dispatch_set_data),

    .in_tdata(epg_tdata_int),
    .in_tuser(epg_tuser_int),
    .in_tlast(epg_tlast_int),
    .in_tvalid(epg_tvalid_int),
    .in_tready(epg_tready_int),

    .vita_tdata(e2v_tdata_int),
    .vita_tlast(e2v_tlast_int),
    .vita_tvalid(e2v_tvalid_int),
    .vita_tready(e2v_tready_int),

    .cpu_tdata(e2c_tdata_int),
    .cpu_tuser(e2c_tuser_int),
    .cpu_tlast(e2c_tlast_int),
    .cpu_tvalid(e2c_tvalid_int),
    .cpu_tready(e2c_tready_int),

    .xo_tdata(xo_tdata),
    .xo_tuser(xo_tuser),
    .xo_tlast(xo_tlast),
    .xo_tvalid(xo_tvalid),
    .xo_tready(xo_tready),

    .eth_mac(mac_reg),
    .bridge_mac(bridge_mac_reg),
    .my_ip (my_ip),
    .my_port0(my_udp_port0),
    .my_port1(my_udp_port1),

    .debug_flags(),
    .debug()
  );

  axi_fifo #(
    .WIDTH(65), .SIZE(1)
  ) e2v_reg_slice (
    .clk(clk),
    .reset(reset),
    .clear(clear),
    .i_tdata({e2v_tlast_int,e2v_tdata_int}),
    .i_tvalid(e2v_tvalid_int),
    .i_tready(e2v_tready_int),
    .o_tdata({e2v_tlast,e2v_tdata}),
    .o_tvalid(e2v_tvalid),
    .o_tready(e2v_tready),
    .space(),
    .occupied()
  );

  // ARM FRAMER
  // Strip the 6 octet ethernet padding we used internally
  // before sending to ARM.
  // Put SOF into bit[3] of tuser.
  //
  axi64_to_xge64 arm_framer (
    .clk(clk),
    .reset(reset),
    .clear(clear),
    .s_axis_tdata(e2c_tdata_int),
    .s_axis_tuser(e2c_tuser_int),
    .s_axis_tlast(e2c_tlast_int),
    .s_axis_tvalid(e2c_tvalid_int),
    .s_axis_tready(e2c_tready_int),
    .m_axis_tdata(e2c_tdata_int2),
    .m_axis_tuser(e2c_tuser_int2),
    .m_axis_tlast(e2c_tlast_int2),
    .m_axis_tvalid(e2c_tvalid_int2),
    .m_axis_tready(e2c_tready_int2)
  );

  // CPU can be slow to respond (relative to packet wirespeed) so extra buffer for packets destined there so it doesn't back up.
  //
  axi_fifo #(
    .WIDTH(69),
    .SIZE(CPU_FIFOSIZE)
  ) cpu_fifo (
    .clk(clk),
    .reset(reset),
    .clear(clear),
    .i_tdata({e2c_tlast_int2,e2c_tuser_int2,e2c_tdata_int2}),
    .i_tvalid(e2c_tvalid_int2), .i_tready(e2c_tready_int2),
    .o_tdata({e2c_tlast,e2c_tuser,e2c_tdata}),
    .o_tvalid(e2c_tvalid),
    .o_tready(e2c_tready),
    .space(),
    .occupied()
  );

  // //////////////////////////////////////////////////////////////
  // Outgoing Ethernet path
  //  Includes FIFOs on path from VITA router, from ethernet crossover, and on the overall output

  wire [63:0] c2e_tdata_int;
  wire [3:0]  c2e_tuser_int;
  wire        c2e_tlast_int;
  wire        c2e_tvalid_int;
  wire        c2e_tready_int;

  wire [63:0] c2e_tdata_int2;
  wire [3:0]  c2e_tuser_int2;
  wire        c2e_tlast_int2;
  wire        c2e_tvalid_int2;
  wire        c2e_tready_int2;

  wire [63:0] eth_tx_tdata_int;
  wire [3:0]  eth_tx_tuser_int;
  wire        eth_tx_tlast_int, eth_tx_tvalid_int, eth_tx_tready_int;

  wire [63:0] xi_tdata_int;
  wire [3:0]  xi_tuser_int;
  wire        xi_tlast_int, xi_tvalid_int, xi_tready_int;

  wire [63:0] v2e_tdata_int;
  wire        v2e_tlast_int, v2e_tvalid_int, v2e_tready_int;

  axi_fifo #(
    .WIDTH(65),
    .SIZE(VITA_FIFOSIZE)
  ) vitaout_fifo (
    .clk(clk),
    .reset(reset),
    .clear(clear),
    .i_tdata({v2e_tlast,v2e_tdata}),
    .i_tvalid(v2e_tvalid),
    .i_tready(v2e_tready),
    .o_tdata({v2e_tlast_int,v2e_tdata_int}),
    .o_tvalid(v2e_tvalid_int),
    .o_tready(v2e_tready_int),
    .space(),
    .occupied()
  );

  wire                  framer_set_stb;
  wire [SR_AWIDTH-1:0]  framer_set_addr;
  wire [REG_DWIDTH-1:0] framer_set_data;

  // Convert regport to setting bus
  regport_to_settingsbus #(
    .BASE(REG_BASE_FRAMER),
    .END_ADDR(REG_END_ADDR_FRAMER),
    .DWIDTH(REG_DWIDTH),
    .AWIDTH(REG_AWIDTH),
    .SR_AWIDTH(SR_AWIDTH),
    .ADDRESSING("WORD")
  )
  inst_eth_framer_settingsbus (
    .clk(clk),
    .reset(reset),
    .reg_wr_req(reg_wr_req),
    .reg_wr_addr(reg_wr_addr),
    .reg_wr_data(reg_wr_data),
    .set_stb(framer_set_stb),
    .set_addr(framer_set_addr),
    .set_data(framer_set_data)
  );

  n3xx_chdr_eth_framer #(
    .BASE   (0),
    .AWIDTH (SR_AWIDTH)
  ) my_eth_framer (
    .clk(clk),
    .reset(reset),
    .clear(clear),
    .set_stb(framer_set_stb),
    .set_addr(framer_set_addr),
    .set_data(framer_set_data),
    .in_tdata(v2e_tdata_int),
    .in_tlast(v2e_tlast_int),
    .in_tvalid(v2e_tvalid_int),
    .in_tready(v2e_tready_int),
    .out_tdata(v2ef_tdata),
    .out_tuser(v2ef_tuser),
    .out_tlast(v2ef_tlast),
    .out_tvalid(v2ef_tvalid),
    .out_tready(v2ef_tready),
    .mac_src(my_mac),
    .ip_src(my_ip),
    .udp_src(my_udp_port0),
    .debug()
   );

  axi_fifo #(
    .WIDTH(69),
    .SIZE(XO_FIFOSIZE)
  ) xo_fifo (
    .clk(clk),
    .reset(reset),
    .clear(clear),
    .i_tdata({xi_tlast,xi_tuser,xi_tdata}),
    .i_tvalid(xi_tvalid),
    .i_tready(xi_tready),
    .o_tdata({xi_tlast_int,xi_tuser_int,xi_tdata_int}),
    .o_tvalid(xi_tvalid_int),
    .o_tready(xi_tready_int),
    .space(),
    .occupied()
  );

  // Add pad of 6 empty bytes to the ethernet packet going from the CPU to the
  // SFP. This padding added before MAC addresses aligns the source and
  // destination IP addresses, UDP headers etc.
  // Note that the xge_mac_wrapper strips this padding to recreate the ethernet
  // packet
  arm_deframer inst_arm_deframer
  (
    .clk(clk),
    .reset(reset),
    .clear(clear),

    .s_axis_tdata(c2e_tdata),
    .s_axis_tuser(c2e_tuser),
    .s_axis_tlast(c2e_tlast),
    .s_axis_tvalid(c2e_tvalid),
    .s_axis_tready(c2e_tready),

    .m_axis_tdata(c2e_tdata_int),
    .m_axis_tuser(c2e_tuser_int),
    .m_axis_tlast(c2e_tlast_int),
    .m_axis_tvalid(c2e_tvalid_int),
    .m_axis_tready(c2e_tready_int)
  );

  // Mux data from 3 sources - CPU, CHDR(XBAR), CROSSOVER into eth_tx
  axi_mux4 #(
    .PRIO(0),
    .WIDTH(68)
  ) eth_mux (
    .clk(clk),
    .reset(reset),
    .clear(clear),
    .i0_tdata({c2e_tuser_int, c2e_tdata_int}),
    .i0_tlast(c2e_tlast_int),
    .i0_tvalid(c2e_tvalid_int),
    .i0_tready(c2e_tready_int),
    .i1_tdata({v2ef_tuser, v2ef_tdata}),
    .i1_tlast(v2ef_tlast),
    .i1_tvalid(v2ef_tvalid),
    .i1_tready(v2ef_tready),
    .i2_tdata({xi_tuser_int, xi_tdata_int}),
    .i2_tlast(xi_tlast_int),
    .i2_tvalid(xi_tvalid_int),
    .i2_tready(xi_tready_int),
    .i3_tdata(),
    .i3_tlast(),
    .i3_tvalid(1'b0),
    .i3_tready(),
    .o_tdata({eth_tx_tuser_int, eth_tx_tdata_int}),
    .o_tlast(eth_tx_tlast_int),
    .o_tvalid(eth_tx_tvalid_int),
    .o_tready(eth_tx_tready_int)
  );

  axi_fifo #(
    .WIDTH(69),
    .SIZE(ETHOUT_FIFOSIZE)
  ) ethout_fifo (
    .clk(clk),
    .reset(reset),
    .clear(clear),
    .i_tdata({eth_tx_tlast_int, eth_tx_tuser_int, eth_tx_tdata_int}),
    .i_tvalid(eth_tx_tvalid_int),
    .i_tready(eth_tx_tready_int),
    .o_tdata({eth_tx_tlast, eth_tx_tuser, eth_tx_tdata}),
    .o_tvalid(eth_tx_tvalid),
    .o_tready(eth_tx_tready),
    .space(),
    .occupied()
  );

endmodule // eth_switch
`default_nettype wire
