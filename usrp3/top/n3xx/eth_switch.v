//////////////////////////////////////
//
//  2017 Ettus Research
//
//////////////////////////////////////
//
// Module: eth_switch
// Description: The module takes care of all
// routing for:
//
// 1. SFP to ARM
// 2. SFP to XBAR
// 3. CROSSOVER SFP
//
//
//////////////////////////////////////


module eth_switch #(
    parameter NUM_CE = 3,          // Number of computation engines
    parameter REG_DWIDTH  = 32,    // Width of the AXI4-Lite data bus (must be 32 or 64)
    parameter REG_AWIDTH  = 32     // Width of the address bus
   )(
    input           clk,
    input           reset,

    input           reg_clk,
    // Register port: Write port (domain: reg_clk)
    output                         reg_wr_req,
    output   [REG_AWIDTH-1:0]      reg_wr_addr,
    output   [REG_DWIDTH-1:0]      reg_wr_data,
    output   [REG_DWIDTH/8-1:0]    reg_wr_keep,

    // Register port: Read port (domain: reg_clk)
    output                         reg_rd_req,
    output   [REG_AWIDTH-1:0]      reg_rd_addr,
    input                          reg_rd_resp,
    input    [REG_DWIDTH-1:0]      reg_rd_data,

    // SFP+ 0 data stream
    output  [63:0]  sfp0_tx_tdata,
    output  [3:0]   sfp0_tx_tuser,
    output          sfp0_tx_tlast,
    output          sfp0_tx_tvalid,
    input           sfp0_tx_tready,

    input   [63:0]  sfp0_rx_tdata,
    input   [3:0]   sfp0_rx_tuser,
    input           sfp0_rx_tlast,
    input           sfp0_rx_tvalid,
    output          sfp0_rx_tready,

    // SFP+ 1 data stream
    output  [63:0]  sfp1_tx_tdata,
    output  [3:0]   sfp1_tx_tuser,
    output          sfp1_tx_tlast,
    output          sfp1_tx_tvalid,
    input           sfp1_tx_tready,

    input   [63:0]  sfp1_rx_tdata,
    input   [3:0]   sfp1_rx_tuser,
    input           sfp1_rx_tlast,
    input           sfp1_rx_tvalid,
    output          sfp1_rx_tready,

    // DMA
    output  [63:0]  dmao_tdata,
    output          dmao_tlast,
    output          dmao_tvalid,
    input           dmao_tready,

    input   [63:0]  dmai_tdata,
    input           dmai_tlast,
    input           dmai_tvalid,
    output          dmai_tready,

    // CPU
    output  [63:0]  cpui_tdata,
    output  [3:0]   cpui_tuser,
    output          cpui_tlast,
    output          cpui_tvalid,
    input           cpui_tready,

    input   [63:0]  cpuo_tdata,
    input   [3:0]   cpuo_tuser,
    input           cpuo_tlast,
    input           cpuo_tvalid,
    output          cpuo_tready,

    // Computation Engines
    output  [NUM_CE*64-1:0] ce_o_tdata,
    output  [NUM_CE-1:0]    ce_o_tlast,
    output  [NUM_CE-1:0]    ce_o_tvalid,
    input   [NUM_CE-1:0]    ce_o_tready,

    input   [NUM_CE*64-1:0] ce_i_tdata,
    input   [NUM_CE-1:0]    ce_i_tlast,
    input   [NUM_CE-1:0]    ce_i_tvalid,
    output  [NUM_CE-1:0]    ce_i_tready,

    input   [15:0]  sfp0_phy_status,
    input   [15:0]  sfp1_phy_status
);

    localparam SR_ETHINT0      = 8'd40;
    localparam SR_ETHINT1      = 8'd56;

    wire    [31:0]  set_data;
    wire    [7:0]   set_addr;
    wire            set_stb;

    // CPU in and CPU out axi streams
    wire    [63:0]  cpui0_tdata, cpuo0_tdata;
    wire    [3:0]   cpui0_tuser, cpuo0_tuser;
    wire            cpui0_tlast, cpuo0_tlast, cpui0_tvalid, cpuo0_tvalid, cpui0_tready, cpuo0_tready;
    wire    [63:0]  cpui1_tdata, cpuo1_tdata;
    wire    [3:0]   cpui1_tuser, cpuo1_tuser;
    wire            cpui1_tlast, cpuo1_tlast, cpui1_tvalid, cpuo1_tvalid, cpui1_tready, cpuo1_tready;

    // v2e (vita to ethernet) and e2v (eth to vita)
    wire    [63:0]  v2e0_tdata, v2e1_tdata, e2v0_tdata, e2v1_tdata;
    wire            v2e0_tlast, v2e1_tlast, v2e0_tvalid, v2e1_tvalid, v2e0_tready, v2e1_tready;
    wire            e2v0_tlast, e2v1_tlast, e2v0_tvalid, e2v1_tvalid, e2v0_tready, e2v1_tready;

    // ////////////////////////////////////////////////////////////////
    // ETH interfaces
    // ////////////////////////////////////////////////////////////////

    wire    [63:0]  e01_tdata, e10_tdata;
    wire    [3:0]   e01_tuser, e10_tuser;
    wire            e01_tlast, e01_tvalid, e01_tready;
    wire            e10_tlast, e10_tvalid, e10_tready;

    n310_eth_interface #(
        .BASE       (SR_ETHINT0),
        .REG_DWIDTH (REG_DWIDTH),         // Width of the AXI4-Lite data bus (must be 32 or 64)
        .REG_AWIDTH (REG_AWIDTH)         // Width of the address bus
    ) eth_interface0 (
        .clk			(clk),
        .reset			(reset),
        .clear			(1'b0),
        //RegPort
        .reg_clk	    (bus_clk),
        .reg_wr_req	    (reg_wr_req),
        .reg_wr_addr	(reg_wr_addr),
        .reg_wr_data	(reg_wr_data),
        .reg_wr_keep	(/*unused*/),
        .reg_rd_req	    (reg_rd_req),
        .reg_rd_addr	(reg_rd_addr),
        .reg_rd_resp	(reg_rd_resp),
        .reg_rd_data	(reg_rd_data),
        // SFP
        .eth_tx_tdata	(sfp0_tx_tdata),
        .eth_tx_tuser	(sfp0_tx_tuser),
        .eth_tx_tlast	(sfp0_tx_tlast),
        .eth_tx_tvalid	(sfp0_tx_tvalid),
        .eth_tx_tready	(sfp0_tx_tready),
        .eth_rx_tdata	(sfp0_rx_tdata),
        .eth_rx_tuser	(sfp0_rx_tuser),
        .eth_rx_tlast	(sfp0_rx_tlast),
        .eth_rx_tvalid	(sfp0_rx_tvalid),
        .eth_rx_tready	(sfp0_rx_tready),
        // Ethernet to Vita
        .e2v_tdata		(e2v0_tdata),
        .e2v_tlast		(e2v0_tlast),
        .e2v_tvalid		(e2v0_tvalid),
        .e2v_tready		(e2v0_tready),
        // Vita to Ethernet
        .v2e_tdata		(v2e0_tdata),
        .v2e_tlast		(v2e0_tlast),
        .v2e_tvalid		(v2e0_tvalid),
        .v2e_tready		(v2e0_tready),
        // Crossover
        .xo_tdata		(e01_tdata),
        .xo_tuser		(e01_tuser),
        .xo_tlast		(e01_tlast),
        .xo_tvalid		(e01_tvalid),
        .xo_tready		(e01_tready),
        .xi_tdata		(e10_tdata),
        .xi_tuser		(e10_tuser),
        .xi_tlast		(e10_tlast),
        .xi_tvalid		(e10_tvalid),
        .xi_tready		(e10_tready),
        // Ethernet to CPU
        .e2c_tdata		(cpui0_tdata),
        .e2c_tuser		(cpui0_tuser),
        .e2c_tlast		(cpui0_tlast),
        .e2c_tvalid		(cpui0_tvalid),
        .e2c_tready		(cpui0_tready),
        // CPU to Ethernet
        .c2e_tdata		(cpuo0_tdata),
        .c2e_tuser		(cpuo0_tuser),
        .c2e_tlast		(cpuo0_tlast),
        .c2e_tvalid		(cpuo0_tvalid),
        .c2e_tready		(cpuo0_tready),
        .debug			()
    );

   n310_eth_interface #(
        .BASE       (SR_ETHINT1),
        .REG_DWIDTH (REG_DWIDTH),         // Width of the AXI4-Lite data bus (must be 32 or 64)
        .REG_AWIDTH (REG_AWIDTH)          // Width of the address bus
   ) eth_interface1 (
        .clk			(clk),
        .reset			(reset),
        .clear			(1'b0),
        //RegPort
        .reg_clk	    (bus_clk),
        .reg_wr_req	    (reg_wr_req),
        .reg_wr_addr	(reg_wr_addr),
        .reg_wr_data	(reg_wr_data),
        .reg_wr_keep	(/*unused*/),
        .reg_rd_req	    (reg_rd_req),
        .reg_rd_addr	(reg_rd_addr),
        .reg_rd_resp	(reg_rd_resp),
        .reg_rd_data	(reg_rd_data),
        // SFP
        .eth_tx_tdata	(sfp1_tx_tdata),
        .eth_tx_tuser	(sfp1_tx_tuser),
        .eth_tx_tlast	(sfp1_tx_tlast),
        .eth_tx_tvalid	(sfp1_tx_tvalid),
        .eth_tx_tready	(sfp1_tx_tready),
        .eth_rx_tdata	(sfp1_rx_tdata),
        .eth_rx_tuser	(sfp1_rx_tuser),
        .eth_rx_tlast	(sfp1_rx_tlast),
        .eth_rx_tvalid	(sfp1_rx_tvalid),
        .eth_rx_tready	(sfp1_rx_tready),
        // Ethernet to Vita
        .e2v_tdata		(e2v1_tdata),
        .e2v_tlast		(e2v1_tlast),
        .e2v_tvalid		(e2v1_tvalid),
        .e2v_tready		(e2v1_tready),
        // Vita to Ethernet
        .v2e_tdata		(v2e1_tdata),
        .v2e_tlast		(v2e1_tlast),
        .v2e_tvalid		(v2e1_tvalid),
        .v2e_tready		(v2e1_tready),
        // Crossover
        .xo_tdata		(e10_tdata),
        .xo_tuser		(e10_tuser),
        .xo_tlast		(e10_tlast),
        .xo_tvalid		(e10_tvalid),
        .xo_tready		(e10_tready),
        .xi_tdata		(e01_tdata),
        .xi_tuser		(e01_tuser),
        .xi_tlast		(e01_tlast),
        .xi_tvalid		(e01_tvalid),
        .xi_tready		(e01_tready),
        // Ethernet to CPU
        .e2c_tdata		(cpui1_tdata),
        .e2c_tuser		(cpui1_tuser),
        .e2c_tlast		(cpui1_tlast),
        .e2c_tvalid		(cpui1_tvalid),
        .e2c_tready		(cpui1_tready),
        // CPU to Ethernet
        .c2e_tdata		(cpuo1_tdata),
        .c2e_tuser		(cpuo1_tuser),
        .c2e_tlast		(cpuo1_tlast),
        .c2e_tvalid		(cpuo1_tvalid),
        .c2e_tready		(cpuo1_tready),
        .debug			()
    );

   axi_mux4 #(.PRIO(0), .WIDTH(68)) cpui_mux
     (.clk(clk), .reset(reset), .clear(1'b0),
      .i0_tdata({cpui0_tuser,cpui0_tdata}), .i0_tlast(cpui0_tlast), .i0_tvalid(cpui0_tvalid), .i0_tready(cpui0_tready),
      .i1_tdata({cpui1_tuser,cpui1_tdata}), .i1_tlast(cpui1_tlast), .i1_tvalid(cpui1_tvalid), .i1_tready(cpui1_tready),
      .i2_tdata(68'h0), .i2_tlast(1'b0), .i2_tvalid(1'b0), .i2_tready(),
      .i3_tdata(68'h0), .i3_tlast(1'b0), .i3_tvalid(1'b0), .i3_tready(),
      .o_tdata({cpui_tuser,cpui_tdata}), .o_tlast(cpui_tlast), .o_tvalid(cpui_tvalid), .o_tready(cpui_tready));

   //TODO : What is this for?
   // Demux ZPU to Eth output by the port number in top 8 bits of data on first line
   wire [67:0] 	  cpuo_eth_header;
   wire [1:0] 	  cpuo_eth_dest = (cpuo_eth_header[63:56] == 8'd0) ? 2'b00 : 2'b01;

   axi_demux4 #(.ACTIVE_CHAN(4'b0011), .WIDTH(68)) cpuo_demux
     (.clk(clk), .reset(reset), .clear(1'b0),
      .header(cpuo_eth_header), .dest(cpuo_eth_dest),
      .i_tdata({cpuo_tuser,cpuo_tdata}), .i_tlast(cpuo_tlast), .i_tvalid(cpuo_tvalid), .i_tready(cpuo_tready),
      .o0_tdata({cpuo0_tuser,cpuo0_tdata}), .o0_tlast(cpuo0_tlast), .o0_tvalid(cpuo0_tvalid), .o0_tready(cpuo0_tready),
      .o1_tdata({cpuo1_tuser,cpuo1_tdata}), .o1_tlast(cpuo1_tlast), .o1_tvalid(cpuo1_tvalid), .o1_tready(cpuo1_tready),
      .o2_tdata(), .o2_tlast(), .o2_tvalid(), .o2_tready(1'b1),
      .o3_tdata(), .o3_tlast(), .o3_tvalid(), .o3_tready(1'b1));

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
   localparam XBAR_NUM_PORTS = XBAR_FIXED_PORTS + NUM_CE;

   // Note: The custom accelerator inputs / outputs bitwidth grow based on NUM_CE
   axi_crossbar #(
      .FIFO_WIDTH(64), .DST_WIDTH(16), .NUM_INPUTS(XBAR_NUM_PORTS), .NUM_OUTPUTS(XBAR_NUM_PORTS))
   inst_axi_crossbar (
      .clk(clk), .reset(reset), .clear(0),
      .local_addr(local_addr),
      .set_stb(set_stb_xb), .set_addr(set_addr_xb), .set_data(set_data_xb),
      .i_tdata({ce_i_tdata,dmai_tdata,e2v1_tdata,e2v0_tdata}),
      .i_tlast({ce_i_tlast,dmai_tlast,e2v1_tlast,e2v0_tlast}),
      .i_tvalid({ce_i_tvalid,dmai_tvalid,e2v1_tvalid,e2v0_tvalid}),
      .i_tready({ce_i_tready,dmai_tready,e2v1_tready,e2v0_tready}),
      .o_tdata({ce_o_tdata,dmao_tdata,v2e1_tdata,v2e0_tdata}),
      .o_tlast({ce_o_tlast,dmao_tlast,v2e1_tlast,v2e0_tlast}),
      .o_tvalid({ce_o_tvalid,dmao_tvalid,v2e1_tvalid,v2e0_tvalid}),
      .o_tready({ce_o_tready,dmao_tready,v2e1_tready,v2e0_tready}),
      .pkt_present({ce_i_tvalid,dmai_tvalid,e2v1_tvalid,e2v0_tvalid})
      //.rb_rd_stb(rb_rd_stb && (rb_addr == RB_CROSSBAR)),
      //.rb_addr(rb_addr_xbar), .rb_data(rb_data_crossbar)
      );

endmodule // bus_int
