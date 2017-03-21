//
// Copyright 2017 Ettus Research LLC
//
// Adapts from internal VITA to ethernet packets.  Also handles CPU and ethernet crossover interfaces.

module eth_switch #(
    parameter BASE=0,
    parameter XO_FIFOSIZE=10,
    parameter CPU_FIFOSIZE=10,
    parameter VITA_FIFOSIZE=10,
    parameter ETHOUT_FIFOSIZE=10,
    parameter REG_DWIDTH = 32,    // Width of the AXI4-Lite data bus (must be 32 or 64)
    parameter REG_AWIDTH = 32     // Width of the address bus
    )(
    input           clk,
    input           reset,
    input           clear,

    input           reg_clk,
    // Register port: Write port (domain: reg_clk)
    input                       reg_wr_req,
    input   [REG_AWIDTH-1:0]    reg_wr_addr,
    input   [REG_DWIDTH-1:0]    reg_wr_data,
    input   [REG_DWIDTH/8-1:0]  reg_wr_keep,

    // Register port: Read port (domain: reg_clk)
    input                       reg_rd_req,
    input   [REG_AWIDTH-1:0]    reg_rd_addr,
    output                      reg_rd_resp,
    output  [REG_DWIDTH-1:0]    reg_rd_data,

    // Eth ports
    output  [63:0]  eth_tx_tdata,
    output  [3:0]   eth_tx_tuser,
    output          eth_tx_tlast,
    output          eth_tx_tvalid,
    input           eth_tx_tready,

    input   [63:0]  eth_rx_tdata,
    input   [3:0]   eth_rx_tuser,
    input           eth_rx_tlast,
    input           eth_rx_tvalid,
    output          eth_rx_tready,

    // Vita router interface
    output  [63:0]  e2v_tdata,
    output          e2v_tlast,
    output          e2v_tvalid,
    input           e2v_tready,

    input   [63:0]  v2e_tdata,
    input           v2e_tlast,
    input           v2e_tvalid,
    output          v2e_tready,

    // Ethernet crossover
    output  [63:0]  xo_tdata,
    output  [3:0]   xo_tuser,
    output          xo_tlast,
    output          xo_tvalid,
    input           xo_tready,

    input   [63:0]  xi_tdata,
    input   [3:0]   xi_tuser,
    input           xi_tlast,
    input           xi_tvalid,
    output          xi_tready,

    // CPU
    output  [63:0]  e2c_tdata,
    output  [3:0]   e2c_tuser,
    output          e2c_tlast,
    output          e2c_tvalid,
    input           e2c_tready,

    input   [63:0]  c2e_tdata,
    input   [3:0]   c2e_tuser,
    input           c2e_tlast,
    input           c2e_tvalid,
    output          c2e_tready,

    // Debug
    output  [31:0]  debug
   );

   // FIXME: Declaration for hard-coded values

   wire [47:0] mac_src_addr;
   wire [47:0] my_mac_addr;
   wire [31:0] ip_src_addr;
   wire [31:0] my_ip_addr;
   wire [15:0] udp_src_prt;
   wire [15:0] my_udp_port;

   wire  [63:0]    v2ef_tdata;
   wire  [3:0]     v2ef_tuser;
   wire            v2ef_tlast, v2ef_tvalid, v2ef_tready;

   // //////////////////////////////////////////////////////////////
   // Incoming Ethernet path
   //  Includes FIFO on the output going to CPU

   wire  [63:0]    epg_tdata_int;
   wire  [3:0]     epg_tuser_int;
   wire            epg_tlast_int, epg_tvalid_int, epg_tready_int;

   //
   // Packet gate ensures on entire ingressing packet is buffered before feeding it downstream so that it bursts
   // efficiently internally without holding resources allocted for longer than optimal. This also means that an upstream
   // error discovered in the packet can allow the packet to be destroyed here, before it gets deeper into the USRP.
   //
   // This gate must be able to hold at least 9900 bytes which is the maximum length between the SOF and EOF
   // as asserted by the 1G and 10G MACs. This is required in case one of the max size packets has an error
   // and needs to be dropped. With SIZE=11, this gate will hold 2 8k packets.

   axi_packet_gate #(.WIDTH(68), .SIZE(11)) packet_gater
     (.clk(clk), .reset(reset), .clear(clear),

      .i_tdata({eth_rx_tuser, eth_rx_tdata}), .i_tlast(eth_rx_tlast),
      .i_terror(eth_rx_tuser[3]), //top bit of user bus is error
      .i_tvalid(eth_rx_tvalid), .i_tready(eth_rx_tready),

      .o_tdata({epg_tuser_int, epg_tdata_int}), .o_tlast(epg_tlast_int),
      .o_tvalid(epg_tvalid_int), .o_tready(epg_tready_int));

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

   n310_eth_dispatch #(
    .BASE   (BASE),
    .REG_DWIDTH (REG_DWIDTH),         // Width of the AXI4-Lite data bus (must be 32 or 64)
    .REG_AWIDTH (REG_AWIDTH)          // Width of the address bus
    ) eth_dispatch (
    .clk        (clk),
    .reset      (reset),
    .clear      (clear),
    //RegPort
    .reg_clk    (reg_clk),
    .reg_wr_req (reg_wr_req),
    .reg_wr_addr(reg_wr_addr),
    .reg_wr_data(reg_wr_data),
    .reg_wr_keep(/*unused*/),
    .reg_rd_req (reg_rd_req),
    .reg_rd_addr(reg_rd_addr),
    .reg_rd_resp(reg_rd_resp),
    .reg_rd_data(reg_rd_data),

    .in_tdata   (epg_tdata_int),
    .in_tuser   (epg_tuser_int),
    .in_tlast   (epg_tlast_int),
    .in_tvalid  (epg_tvalid_int),
    .in_tready  (epg_tready_int),

    .vita_tdata (e2v_tdata_int),
    .vita_tlast (e2v_tlast_int),
    .vita_tvalid(e2v_tvalid_int),
    .vita_tready(e2v_tready_int),

    .cpu_tdata  (e2c_tdata_int),
    .cpu_tuser  (e2c_tuser_int),
    .cpu_tlast  (e2c_tlast_int),
    .cpu_tvalid (e2c_tvalid_int),
    .cpu_tready (e2c_tready_int),

    .xo_tdata   (xo_tdata),
    .xo_tuser   (xo_tuser),
    .xo_tlast   (xo_tlast),
    .xo_tvalid  (xo_tvalid),
    .xo_tready  (xo_tready),
    // to other eth port
    .mac_src_addr(mac_src_addr),
    .ip_src_addr(ip_src_addr),
    .udp_src_prt(udp_src_prt),

    .my_mac_addr(my_mac_addr),
    .my_ip_addr (my_ip_addr),
    .my_udp_port(my_udp_port),

    .debug_flags(),
    .debug      ()
    );

   axi_fifo_short #(.WIDTH(65)) e2v_pipeline_srl
     (.clk(clk), .reset(reset), .clear(clear),
      .i_tdata({e2v_tlast_int,e2v_tdata_int}), .i_tvalid(e2v_tvalid_int), .i_tready(e2v_tready_int),
      .o_tdata({e2v_tlast,e2v_tdata}), .o_tvalid(e2v_tvalid), .o_tready(e2v_tready),
      .space(), .occupied()
      );

   // ARM DEFRAMER
   // Strip the 6 octet ethernet padding we used internally
   // before sending to ARM.
   // Put SOF into bit[3] of tuser.
   //
   axi64_to_xge64 arm_deframer
     (
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
   axi_fifo #(.WIDTH(69),.SIZE(CPU_FIFOSIZE)) cpu_fifo
     (.clk(clk), .reset(reset), .clear(clear),
      .i_tdata({e2c_tlast_int2,e2c_tuser_int2,e2c_tdata_int2}), .i_tvalid(e2c_tvalid_int2), .i_tready(e2c_tready_int2),
      .o_tdata({e2c_tlast,e2c_tuser,e2c_tdata}), .o_tvalid(e2c_tvalid), .o_tready(e2c_tready), .space(), .occupied());

   // //////////////////////////////////////////////////////////////
   // Outgoing Ethernet path
   //  Includes FIFOs on path from VITA router, from ethernet crossover, and on the overall output

   wire  [63:0]  c2e_tdata_int;
   wire  [3:0]   c2e_tuser_int;
   wire          c2e_tlast_int;
   wire          c2e_tvalid_int;
   wire          c2e_tready_int;

   wire  [63:0]  c2e_tdata_int2;
   wire  [3:0]   c2e_tuser_int2;
   wire          c2e_tlast_int2;
   wire          c2e_tvalid_int2;
   wire          c2e_tready_int2;

   wire  [63:0]  eth_tx_tdata_int;
   wire  [3:0]   eth_tx_tuser_int;
   wire          eth_tx_tlast_int, eth_tx_tvalid_int, eth_tx_tready_int;

   wire  [63:0]  xi_tdata_int;
   wire  [3:0]   xi_tuser_int;
   wire          xi_tlast_int, xi_tvalid_int, xi_tready_int;

   wire  [63:0]  v2e_tdata_int;
   wire          v2e_tlast_int, v2e_tvalid_int, v2e_tready_int;

   axi_fifo #(.WIDTH(65),.SIZE(VITA_FIFOSIZE)) vitaout_fifo
     (.clk(clk), .reset(reset), .clear(clear),
      .i_tdata({v2e_tlast,v2e_tdata}), .i_tvalid(v2e_tvalid), .i_tready(v2e_tready),
      .o_tdata({v2e_tlast_int,v2e_tdata_int}), .o_tvalid(v2e_tvalid_int), .o_tready(v2e_tready_int), .space(), .occupied());

   n310_chdr_eth_framer #(.BASE(BASE)) my_eth_framer
     (.clk(clk), .reset(reset), .clear(clear),
      .set_stb(set_stb), .set_addr(set_addr) , .set_data(set_data),
      .in_tdata(v2e_tdata_int), .in_tlast(v2e_tlast_int), .in_tvalid(v2e_tvalid_int), .in_tready(v2e_tready_int),
      .out_tdata(v2ef_tdata), .out_tuser(v2ef_tuser), .out_tlast(v2ef_tlast), .out_tvalid(v2ef_tvalid), .out_tready(v2ef_tready),
      .mac_src(my_mac_addr), .mac_dst(mac_src_addr),
      .ip_src(my_ip_addr),   .ip_dst(ip_src_addr),
      .udp_src(my_udp_port), .udp_dst(udp_src_prt),
      .debug());

   axi_fifo #(.WIDTH(69),.SIZE(XO_FIFOSIZE)) xo_fifo
     (.clk(clk), .reset(reset), .clear(clear),
      .i_tdata({xi_tlast,xi_tuser,xi_tdata}), .i_tvalid(xi_tvalid), .i_tready(xi_tready),
      .o_tdata({xi_tlast_int,xi_tuser_int,xi_tdata_int}), .o_tvalid(xi_tvalid_int), .o_tready(xi_tready_int), .space(), .occupied());

   // ARM FRAMER
   // Add pad of 6 empty bytes before MAC addresses of new Rxed packet so that IP
   // headers are alligned.
   //
  arm_framer inst_arm_framer
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

   axi_mux4 #(.PRIO(0), .WIDTH(68)) eth_mux
     (.clk(clk), .reset(reset), .clear(clear),
      .i0_tdata({c2e_tuser_int,c2e_tdata_int}), .i0_tlast(c2e_tlast_int), .i0_tvalid(c2e_tvalid_int), .i0_tready(c2e_tready_int),
      .i1_tdata({v2ef_tuser,v2ef_tdata}), .i1_tlast(v2ef_tlast), .i1_tvalid(v2ef_tvalid), .i1_tready(v2ef_tready),
      .i2_tdata({xi_tuser_int,xi_tdata_int}), .i2_tlast(xi_tlast_int), .i2_tvalid(xi_tvalid_int), .i2_tready(xi_tready_int),
      .i3_tdata(), .i3_tlast(), .i3_tvalid(1'b0), .i3_tready(),
      .o_tdata({eth_tx_tuser_int,eth_tx_tdata_int}), .o_tlast(eth_tx_tlast_int), .o_tvalid(eth_tx_tvalid_int), .o_tready(eth_tx_tready_int));

   axi_fifo #(.WIDTH(69),.SIZE(ETHOUT_FIFOSIZE)) ethout_fifo
     (.clk(clk), .reset(reset), .clear(clear),
      .i_tdata({eth_tx_tlast_int,eth_tx_tuser_int,eth_tx_tdata_int}), .i_tvalid(eth_tx_tvalid_int), .i_tready(eth_tx_tready_int),
      .o_tdata({eth_tx_tlast,eth_tx_tuser,eth_tx_tdata}), .o_tvalid(eth_tx_tvalid), .o_tready(eth_tx_tready), .space(), .occupied());


endmodule // eth_switch
