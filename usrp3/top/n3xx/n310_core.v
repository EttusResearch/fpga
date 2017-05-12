/////////////////////////////////////////////////////////////////////
//
// Copyright 2016-2017 Ettus Research
//
// n3xx_core
// - Crossbar
// - Radio 0 and Radio 1
//
/////////////////////////////////////////////////////////////////////

module n310_core #(
  parameter REG_DWIDTH  = 32, // Width of the AXI4-Lite data bus (must be 32 or 64)
  parameter REG_AWIDTH  = 32  // Width of the address bus
)(
 //Clocks and resets
  input         radio_clk,
  input         radio_rst,
  input         bus_clk,
  input         bus_rst,

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

  // JESD204
  input  [31:0] rx0,
  output [31:0] tx0,

  input  [31:0] rx1,
  output [31:0] tx1,

  input  [31:0] rx2,
  output [31:0] tx2,

  input  [31:0] rx3,
  output [31:0] tx3,

  //input         rx_stb,  //FIXME
  //input         rx_stb,  //FIXME

  // DMA
  output [63:0] dmao_tdata,
  output        dmao_tlast,
  output        dmao_tvalid,
  input         dmao_tready,

  input [63:0]  dmai_tdata,
  input         dmai_tlast,
  input         dmai_tvalid,
  output        dmai_tready,

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

  output [2:0]  spi_mux,
  output        cpld_reset
);

  localparam NUM_CHANNELS = 2;
  // Computation engines that need access to IO
  localparam NUM_IO_CE = 2;

  /////////////////////////////////////////////////////////////////////////////////
  // Global Registers
  /////////////////////////////////////////////////////////////////////////////////
  localparam REG_BASE_MISC = 0; // axi interconnect takes care of that

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

  localparam REG_GIT_HASH    = 14'h0;
  localparam REG_NUM_CE      = 14'h4;
  localparam REG_SCRATCH     = 14'h8;

  reg [31:0] scratch_reg;

  assign spi_mux = scratch_reg[2:0];
  assign cpld_reset = scratch_reg[3];

  always @ (posedge bus_clk)
    if (bus_rst) begin
      scratch_reg <= 32'h2;
    end
    else begin
    if (reg_wr_req)
      case (reg_wr_addr)
        REG_SCRATCH:
          scratch_reg <= reg_wr_data;
      endcase
    end

  always @ (posedge bus_clk)
    if (bus_rst)
      reg_rd_resp_glob <= 1'b0;

    else begin
      if (reg_rd_req) begin
        reg_rd_resp_glob <= 1'b1;

        case (reg_rd_addr)
        REG_GIT_HASH:
          reg_rd_data_glob <= 32'h`GIT_HASH;

        REG_NUM_CE:
          reg_rd_data_glob <= NUM_CE;

        REG_SCRATCH:
          reg_rd_data_glob <= scratch_reg;
        default:
          reg_rd_resp_glob <= 1'b0;
        endcase
      end
      else if (reg_rd_resp_glob) begin
          reg_rd_resp_glob <= 1'b0;
      end
    end

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

   /////////////////////////////////////////////////////////////////////////////
   //
   // Radios
   //
   /////////////////////////////////////////////////////////////////////////////

   // Number of Radio Cores Instantiated
   localparam NUM_RADIO_CORES = 2;
   localparam RADIO_STR_FIFO_SIZE = 8'd11;

   //------------------------------------
   // Radios
   //------------------------------------

   // Data
   wire [31:0] rx_data[0:3], tx_data[0:3];

   wire        rx_stb[0:3], tx_stb[0:3];
   assign rx_stb[0] = 1'b1;
   assign rx_stb[1] = 1'b1;
   assign rx_stb[2] = 1'b1;
   assign rx_stb[3] = 1'b1;
   assign tx_stb[0] = 1'b1;
   assign tx_stb[1] = 1'b1;
   assign tx_stb[2] = 1'b1;
   assign tx_stb[3] = 1'b1;

   genvar i;
   generate for (i = 0; i < NUM_RADIO_CORES; i = i + 1) begin

   noc_block_radio_core #(
      .NOC_ID(64'h12AD_1000_0000_0310),
      .NUM_CHANNELS(NUM_CHANNELS),
      .STR_SINK_FIFOSIZE({8'd5,RADIO_STR_FIFO_SIZE}),
      .MTU(13)
   ) noc_block_radio_core_i (
      //Clocks
      .bus_clk(bus_clk),
      .bus_rst(bus_rst),
      .ce_clk(radio_clk),
      .ce_rst(radio_rst),
      //AXIS data to/from crossbar
      .i_tdata(ioce_o_tdata[i]),
      .i_tlast(ioce_o_tlast[i]),
      .i_tvalid(ioce_o_tvalid[i]),
      .i_tready(ioce_o_tready[i]),
      .o_tdata(ioce_i_tdata[i]),
      .o_tlast(ioce_i_tlast[i]),
      .o_tvalid(ioce_i_tvalid[i]),
      .o_tready(ioce_i_tready[i]),
      // Data ports connected to radio front end
      .rx({rx_data[i*2+1],rx_data[i*2]}),
      .rx_stb({rx_stb[i*2+1],rx_stb[i*2]}),
      .tx({tx_data[i*2+1],tx_data[i*2]}),
      .tx_stb({tx_stb[i*2+1],tx_stb[i*2]}),
      // Ctrl ports connected to radio front end
      //.ext_set_stb({ext_set_stb[i+1],ext_set_stb[i]}),
      //.ext_set_addr({ext_set_addr[i+1],ext_set_addr[i]}),
      //.ext_set_data({ext_set_data[i+1],ext_set_data[i]}),
      //// Interfaces to front panel and daughter board
      //.pps(pps_rclk),
      //.sync_in(time_sync_r),
      //.sync_out(sync_out[i]),
      //.misc_ins({misc_ins[i+1],misc_ins[i]}),
      //.misc_outs({misc_outs[i+1], misc_outs[i]}),
      //.fp_gpio_in({fp_gpio_r_in[i+1],fp_gpio_r_in[i]}),
      //.fp_gpio_out({fp_gpio_r_out[i+1],fp_gpio_r_out[i]}),
      //.fp_gpio_ddr({fp_gpio_r_ddr[i+1],fp_gpio_r_ddr[i]}),
      //.db_gpio_in({db_gpio_in[i+1],db_gpio_in[i]}),
      //.db_gpio_out({db_gpio_out[i+1],db_gpio_out[i]}),
      //.db_gpio_ddr({db_gpio_ddr[i+1],db_gpio_ddr[i]}),
      //.leds({leds[i+1],leds[i]}),
      //.spi_clk(radio_clk),
      //.spi_rst(radio_rst),
      //.sen({sen[i+1],sen[i]}),
      //.sclk({sclk[i+1],sclk[i]}),
      //.mosi({mosi[i+1],mosi[i]}),
      //.miso({miso[i+1],miso[i]}),
      //Debug
      .debug()
   );
   end endgenerate

   /////////////////////////////////////////////////////////////////////////////////
   // TX/RX FrontEnd
   /////////////////////////////////////////////////////////////////////////////////

   wire  [31:0]     rx[0:3], tx[0:3];
   assign {rx[0], rx[1]} = {rx0, rx1};
   assign {rx[2], rx[3]} = {rx2, rx3};
   assign {tx0, tx1} = {tx[0], tx[1]};
   assign {tx2, tx3} = {tx[2], tx[3]};

   generate for (i = 0; i < NUM_RADIO_CORES*NUM_CHANNELS; i = i + 1) begin

   n310_tx_frontend n310_tx_frontend (
      .tx_in(tx_data[i]),
      .tx_out(tx[i])
   );
   end endgenerate

   generate for (i = 0; i < NUM_RADIO_CORES*NUM_CHANNELS; i = i + 1) begin

   n310_rx_frontend n310_rx_frontend (
      .rx_in(rx[i]),
      .rx_out(rx_data[i])
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
      .REG_BASE(32'h10),
      .REG_DWIDTH(REG_DWIDTH),  // Width of the AXI4-Lite data bus (must be 32 or 64)
      .REG_AWIDTH(REG_AWIDTH),  // Width of the address bus
      .FIFO_WIDTH(64), .DST_WIDTH(16), .NUM_INPUTS(XBAR_NUM_PORTS), .NUM_OUTPUTS(XBAR_NUM_PORTS))
   inst_axi_crossbar_regport (
      .clk(bus_clk), .reset(bus_rst), .clear(0),
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
