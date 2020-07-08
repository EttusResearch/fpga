/////////////////////////////////////////////////////////////////////
//
// Copyright 2018 Ettus Research, A National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0
//
// Module: e31x_core
// Description:
//  - Motherboard Registers
//  - Crossbar
//  - Noc Block Radio
//  - Noc Block Dram Fifo
//  - Radio Front End control
//
/////////////////////////////////////////////////////////////////////

module e31x_core #(
  parameter REG_DWIDTH   = 32,        // Width of the AXI4-Lite data bus (must be 32 or 64)
  parameter REG_AWIDTH   = 32,        // Width of the address bus
  parameter BUS_CLK_RATE = 200000000, // bus_clk rate
  parameter NUM_SFP_PORTS = 0,        // Number of SFP Ports
  parameter NUM_RADIO_CORES = 1,
  parameter NUM_CHANNELS_PER_RADIO = 2,
  parameter NUM_CHANNELS = 2,
  parameter NUM_DBOARDS = 1,
  parameter FP_GPIO_WIDTH = 8,  // Front panel GPIO width
  parameter DB_GPIO_WIDTH = 16  // Daughterboard GPIO width
)(
  // Clocks and resets
  input radio_clk,
  input radio_rst,
  input bus_clk,
  input bus_rst,

  // Motherboard Registers: AXI lite interface
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

  // PPS and Clock Control
  input            pps_refclk,
  input            refclk_locked,
  output reg [1:0] pps_select,

  // PS GPIO source
  input  [FP_GPIO_WIDTH-1:0]  ps_gpio_out,
  input  [FP_GPIO_WIDTH-1:0]  ps_gpio_tri,
  output [FP_GPIO_WIDTH-1:0]  ps_gpio_in,

  // Front Panel GPIO
  input  [FP_GPIO_WIDTH-1:0] fp_gpio_in,
  output [FP_GPIO_WIDTH-1:0] fp_gpio_tri,
  output [FP_GPIO_WIDTH-1:0] fp_gpio_out,

  // Radio GPIO control
  output [DB_GPIO_WIDTH*NUM_CHANNELS-1:0] db_gpio_out_flat,
  output [DB_GPIO_WIDTH*NUM_CHANNELS-1:0] db_gpio_ddr_flat,
  input  [DB_GPIO_WIDTH*NUM_CHANNELS-1:0] db_gpio_in_flat,
  input  [DB_GPIO_WIDTH*NUM_CHANNELS-1:0] db_gpio_fab_flat,

  // TX/RX LEDs
  output [32*NUM_CHANNELS-1:0] leds_flat,

  // Radio ATR
  output [NUM_CHANNELS-1:0] rx_atr,
  output [NUM_CHANNELS-1:0] tx_atr,

  // Radio Data
  input  [NUM_CHANNELS-1:0]    rx_stb,
  input  [NUM_CHANNELS-1:0]    tx_stb,
  input  [32*NUM_CHANNELS-1:0] rx,
  output [32*NUM_CHANNELS-1:0] tx,

  // DMA
  output [63:0] dmao_tdata,
  output        dmao_tlast,
  output        dmao_tvalid,
  input         dmao_tready,

  input [63:0]  dmai_tdata,
  input         dmai_tlast,
  input         dmai_tvalid,
  output        dmai_tready,

  // Misc
  input      [31:0] build_datestamp,
  input      [31:0] sfp_ports_info,
  input      [31:0] gps_status,
  output reg [31:0] gps_ctrl,
  input      [31:0] dboard_status,
  input      [31:0] xadc_readback,
  output reg [31:0] fp_gpio_ctrl,
  output reg [31:0] dboard_ctrl
);

  /////////////////////////////////////////////////////////////////////////////////
  //
  // FPGA Compatibility Number
  //   Rules for modifying compat number:
  //   - Major is updated when the FPGA is changed and requires a software
  //     change as a result.
  //   - Minor is updated when a new feature is added to the FPGA that does not
  //     break software compatibility.
  //
  /////////////////////////////////////////////////////////////////////////////////

  localparam [15:0] COMPAT_MAJOR = 16'd1;
  localparam [15:0] COMPAT_MINOR = 16'd0;

  /////////////////////////////////////////////////////////////////////////////////

  // Computation engines that need access to IO
  localparam NUM_IO_CE = NUM_RADIO_CORES; //NUM_RADIO_CORES
  // Radio NOC ID
  localparam NOC_ID_RADIO = 64'h12AD_1000_0000_3310;

  // Base width of crossbar based on fixed components (ethernet, DMA)
  localparam XBAR_FIXED_PORTS = 1 + NUM_SFP_PORTS;

  /////////////////////////////////////////////////////////////////////////////////
  //
  // Motherboard Registers
  //
  /////////////////////////////////////////////////////////////////////////////////

  // Register base
  localparam REG_BASE_MISC           = 14'h0;
  localparam REG_BASE_XBAR           = 14'h1000;
  localparam NUM_CORE_REGPORT_SLAVES = 2; // Global registers + Crossbar

  // Misc Registers
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
  localparam REG_FP_GPIO_MASTER    = REG_BASE_MISC + 14'h30;
  localparam REG_FP_GPIO_RADIO_SRC = REG_BASE_MISC + 14'h34;
  localparam REG_GPS_CTRL          = REG_BASE_MISC + 14'h38;
  localparam REG_GPS_STATUS        = REG_BASE_MISC + 14'h3C;
  localparam REG_DBOARD_CTRL       = REG_BASE_MISC + 14'h40;
  localparam REG_DBOARD_STATUS     = REG_BASE_MISC + 14'h44;
  localparam REG_XBAR_BASEPORT     = REG_BASE_MISC + 14'h48;

  reg  [31:0]              fp_gpio_master_reg = 32'h0;
  reg  [31:0]              fp_gpio_src_reg    = 32'h0;

  wire                     reg_wr_req;
  wire [REG_AWIDTH-1:0]    reg_wr_addr;
  wire [REG_DWIDTH-1:0]    reg_wr_data;
  wire                     reg_rd_req;
  wire [REG_AWIDTH-1:0]    reg_rd_addr;
  wire                     reg_rd_resp;
  wire [REG_DWIDTH-1:0]    reg_rd_data;

  reg                      reg_rd_resp_glob;
  reg  [REG_DWIDTH-1:0]    reg_rd_data_glob;

  wire [REG_DWIDTH-1:0]    reg_rd_data_xbar;
  wire                     reg_rd_resp_xbar;

  reg [31:0] scratch_reg = 32'h0;
  reg [31:0] bus_counter = 32'h0;

  always @(posedge bus_clk) begin
     if (bus_rst)
        bus_counter <= 32'd0;
     else
        bus_counter <= bus_counter + 32'd1;
  end

  // Regport Master to convert AXI4-Lite to regport
  axil_regport_master #(
    .DWIDTH   (REG_DWIDTH), // Width of the AXI4-Lite data bus (must be 32 or 64)
    .AWIDTH   (REG_AWIDTH), // Width of the address bus
    .WRBASE   (0),          // Write address base
    .RDBASE   (0),          // Read address base
    .TIMEOUT  (10)          // log2(timeout). Read will timeout after (2^TIMEOUT - 1) cycles
  ) core_regport_master_i (
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

  // Muxed Read Response on the regport
  //    - Crossbar registers
  //    - Global registers
  regport_resp_mux #(
    .WIDTH(REG_DWIDTH),
    .NUM_SLAVES(NUM_CORE_REGPORT_SLAVES)
  ) core_regport_resp_mux_i (
    .clk(bus_clk),
    .reset(bus_rst),
    .sla_rd_resp({reg_rd_resp_glob, reg_rd_resp_xbar}),
    .sla_rd_data({reg_rd_data_glob, reg_rd_data_xbar}),
    .mst_rd_resp(reg_rd_resp),
    .mst_rd_data(reg_rd_data)
  );

  //--------------------------------------------------------------------
  // Global Registers
  // -------------------------------------------------------------------

  // Write Registers
  always @ (posedge bus_clk) begin
    if (bus_rst) begin
      scratch_reg    <= 32'h0;
      pps_select     <= 2'b00; // Default to internal
      fp_gpio_ctrl   <= 32'h9; // Default to OFF - 4'b1001
      gps_ctrl       <= 32'h3; // Default to gps_en, out of reset
      dboard_ctrl    <= 32'h3; // Default to mimo, in reset
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
          pps_select  <= reg_wr_data[1:0];
        end
        REG_GPS_CTRL: begin
          gps_ctrl    <= reg_wr_data;
        end
        REG_DBOARD_CTRL: begin
          dboard_ctrl <= reg_wr_data;
        end
      endcase
    end
  end

  // Read Registers
  always @ (posedge bus_clk) begin
    if (bus_rst) begin
      reg_rd_resp_glob <= 1'b0;
    end
    else begin

      if (reg_rd_req) begin
        reg_rd_resp_glob <= 1'b1;

        case (reg_rd_addr)
        REG_COMPAT_NUM:
          reg_rd_data_glob <= {COMPAT_MAJOR, COMPAT_MINOR};

        REG_FP_GPIO_MASTER:
          reg_rd_data_glob <= fp_gpio_master_reg;

        REG_FP_GPIO_RADIO_SRC:
          reg_rd_data_glob <= fp_gpio_src_reg;

        REG_DATESTAMP:
          reg_rd_data_glob <= build_datestamp;

        REG_GIT_HASH:
          reg_rd_data_glob <= `GIT_HASH;

        REG_SCRATCH:
          reg_rd_data_glob <= scratch_reg;

        REG_NUM_CE:
          reg_rd_data_glob <= NUM_CE;

        REG_NUM_IO_CE:
          reg_rd_data_glob <= NUM_IO_CE;

        REG_CLOCK_CTRL: begin
          reg_rd_data_glob      <= 32'b0;
          reg_rd_data_glob[1:0] <= pps_select;
          reg_rd_data_glob[2]   <= refclk_locked;
        end

        REG_XADC_READBACK:
          reg_rd_data_glob <= xadc_readback;

        REG_BUS_CLK_RATE:
          reg_rd_data_glob <= BUS_CLK_RATE;

        REG_BUS_CLK_COUNT:
          reg_rd_data_glob <= bus_counter;

        REG_GPS_CTRL:
          reg_rd_data_glob <= gps_ctrl;

        REG_GPS_STATUS:
          reg_rd_data_glob <= gps_status;

        REG_DBOARD_CTRL:
          reg_rd_data_glob <= dboard_ctrl;

        REG_DBOARD_STATUS:
          reg_rd_data_glob <= dboard_status;

        REG_XBAR_BASEPORT:
          reg_rd_data_glob <= XBAR_FIXED_PORTS;

        default:
          reg_rd_resp_glob <= 1'b0;
        endcase
      end
      else if (reg_rd_resp_glob) begin
          reg_rd_resp_glob <= 1'b0;
      end
    end
  end

  /////////////////////////////////////////////////////////////////////////////////////////////
  //
  // IOCE: CEs that need access to IO
  //   - Radio 0
  //
  /////////////////////////////////////////////////////////////////////////////////////////////

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
  // Radio
  //
  /////////////////////////////////////////////////////////////////////////////

  wire pps_radioclk;

  // Synchronize the PPS signal to the radio clock domain
  synchronizer pps_radio_sync (
    .clk(radio_clk), .rst(1'b0), .in(pps_refclk), .out(pps_radioclk)
  );

  localparam RADIO_INPUT_BUFF_SIZE   = 8'd11;
  // The radio needs a larger output buffer compared to other blocks because it is a finite
  // rate producer i.e. the input is not backpressured.
  // Here, we allocate enough room from 2 MTU sized packets. This buffer serves as a
  // packet gate so we need room for an additional packet if the first one is held due to
  // contention on the crossbar. Any additional buffering will be largely a waste.
  localparam RADIO_OUTPUT_BUFF_SIZE  = 8'd10;

  wire [31:0] rx_int[0:NUM_CHANNELS-1], rx_data[0:NUM_CHANNELS-1], tx_int[0:NUM_CHANNELS-1], tx_data[0:NUM_CHANNELS-1];
  wire        db_fe_set_stb[0:1];
  wire [7:0]  db_fe_set_addr[0:1];
  wire [31:0] db_fe_set_data[0:1];
  wire        db_fe_rb_stb[0:1];
  wire [7:0]  db_fe_rb_addr[0:1];
  wire [63:0] db_fe_rb_data[0:1];
  wire        rx_running[0:1], tx_running[0:1];
  wire [NUM_RADIO_CORES-1:0] sync_out;

  genvar i;
  generate
    for (i = 0; i < NUM_CHANNELS; i = i + 1) begin
      assign rx_atr[i] = rx_running[i];
      assign tx_atr[i] = tx_running[i];
    end
  endgenerate

  noc_block_radio_core #(
    .NOC_ID(NOC_ID_RADIO),
    .NUM_CHANNELS(NUM_CHANNELS_PER_RADIO),
    .STR_SINK_FIFOSIZE({NUM_CHANNELS_PER_RADIO{RADIO_INPUT_BUFF_SIZE}}),
    .MTU(RADIO_OUTPUT_BUFF_SIZE)
  ) noc_block_radio_core_i (
    // Clocks and reset
    .bus_clk(bus_clk),
    .bus_rst(bus_rst),
    .ce_clk(radio_clk),
    .ce_rst(radio_rst),
    //AXIS data to/from crossbar
    .i_tdata(ioce_o_tdata[0]),
    .i_tlast(ioce_o_tlast[0]),
    .i_tvalid(ioce_o_tvalid[0]),
    .i_tready(ioce_o_tready[0]),
    .o_tdata(ioce_i_tdata[0]),
    .o_tlast(ioce_i_tlast[0]),
    .o_tvalid(ioce_i_tvalid[0]),
    .o_tready(ioce_i_tready[0]),
    // Radio front-end
    .rx({rx_data[1],rx_data[0]}),
    .rx_stb({rx_stb[1], rx_stb[0]}),
    .tx({tx_data[1], tx_data[0]}),
    .tx_stb({tx_stb[1], tx_stb[0]}),
    // Timing and sync
    .pps(pps_radioclk),
    .sync_in(1'b0),
    .sync_out(sync_out),
    .rx_running({rx_running[1], rx_running[0]}),
    .tx_running({tx_running[1], tx_running[0]}),
    // Ctrl ports connected to radio dboard and front end core
    .db_fe_set_stb ({db_fe_set_stb [1], db_fe_set_stb [0]}),
    .db_fe_set_addr({db_fe_set_addr[1], db_fe_set_addr[0]}),
    .db_fe_set_data({db_fe_set_data[1], db_fe_set_data[0]}),
    .db_fe_rb_stb  ({db_fe_rb_stb  [1], db_fe_rb_stb  [0]}),
    .db_fe_rb_addr ({db_fe_rb_addr [1], db_fe_rb_addr [0]}),
    .db_fe_rb_data ({db_fe_rb_data [1], db_fe_rb_data [0]}),
    //Debug
    .debug()
  );

  /////////////////////////////////////////////////////////////////////////////
  //
  // Radio Front End Control
  //
  /////////////////////////////////////////////////////////////////////////////

  // Radio Daughter board GPIO
  wire [DB_GPIO_WIDTH-1:0] db_gpio_in[0:NUM_CHANNELS-1];
  wire [DB_GPIO_WIDTH-1:0] db_gpio_out[0:NUM_CHANNELS-1];
  wire [DB_GPIO_WIDTH-1:0] db_gpio_ddr[0:NUM_CHANNELS-1];
  wire [DB_GPIO_WIDTH-1:0] db_gpio_fab[0:NUM_CHANNELS-1];
  wire [31:0] radio_gpio_out[0:NUM_CHANNELS-1];
  wire [31:0] radio_gpio_ddr[0:NUM_CHANNELS-1];
  wire [31:0] radio_gpio_in[0:NUM_CHANNELS-1];
  wire [31:0] leds[0:NUM_CHANNELS-1];

  generate
    for (i = 0; i < NUM_CHANNELS; i = i + 1) begin
      // Radio Data
      assign rx_int[i] = rx[32*i+31:32*i];
      assign tx[32*i+31:32*i] = tx_int[i];
      // GPIO
      assign db_gpio_out_flat[DB_GPIO_WIDTH*i +: DB_GPIO_WIDTH] = db_gpio_out[i];
      assign db_gpio_ddr_flat[DB_GPIO_WIDTH*i +: DB_GPIO_WIDTH] = db_gpio_ddr[i];
      assign db_gpio_in[i] = db_gpio_in_flat[DB_GPIO_WIDTH*i +: DB_GPIO_WIDTH];
      assign db_gpio_fab[i] = db_gpio_fab_flat[DB_GPIO_WIDTH*i +: DB_GPIO_WIDTH];
      // LEDs
      assign leds_flat[32*i+31:32*i] = leds[i];
    end
  endgenerate

  generate
    for (i = 0; i < NUM_CHANNELS; i = i + 1) begin
      n3xx_db_fe_core db_fe_core_i (
        .clk(radio_clk),
        .reset(radio_rst),
        .set_stb(db_fe_set_stb[i]),
        .set_addr(db_fe_set_addr[i]),
        .set_data(db_fe_set_data[i]),
        .rb_stb(db_fe_rb_stb[i]),
        .rb_addr(db_fe_rb_addr[i]),
        .rb_data(db_fe_rb_data[i]),
        .time_sync(sync_out[i < 2 ? 0 : 1]),
        .tx_stb(tx_stb[i]),
        .tx_data_in(tx_data[i]),
        .tx_data_out(tx_int[i]),
        .tx_running(tx_running[i]),
        .rx_stb(rx_stb[i]),
        .rx_data_in(rx_int[i]),
        .rx_data_out(rx_data[i]),
        .rx_running(rx_running[i]),
        .misc_ins(32'h0),
        .misc_outs(),
        .fp_gpio_in(radio_gpio_in[i]),
        .fp_gpio_out(radio_gpio_out[i]),
        .fp_gpio_ddr(radio_gpio_ddr[i]),
        .fp_gpio_fab(32'h0),
        .db_gpio_in(db_gpio_in[i]),
        .db_gpio_out(db_gpio_out[i]),
        .db_gpio_ddr(db_gpio_ddr[i]),
        .db_gpio_fab(db_gpio_fab[i]),
        .leds(leds[i]),
        .spi_clk(1'b0),
        .spi_rst(1'b0),
        .sen(),
        .sclk(),
        .mosi(),
        .miso(1'b0)
      );
    end
  endgenerate

  ////////////////////////////////////////////////////////////////////////
  //
  // axi_crossbar ports:
  //   The crossbar has 16 ports out of which Port 4 to Port 15 can be used
  //   for RFNOC blocks. Note that Radio and DRAM are always included by default
  //   but DDC/DUC and other blocks are not and need to be included via
  //   rfnoc_ce_default_inst_e31x.v which can be edited manually or
  //   automatically generated by rfnoc mod tool.
  //
  // 0  - DMA to PS
  // 1  - Radio
  // 2  - CE0
  // ...
  // ...
  // 15 - CE13
  //
  ////////////////////////////////////////////////////////////////////////

  // Default CE clock for this device
  wire ce_clk = bus_clk;
  wire ce_rst = bus_rst;

  // Included automatically instantiated CEs sources file created by RFNoC mod tool

`ifdef RFNOC
  `include "rfnoc_ce_auto_inst_e31x.v"
`else
  `include "rfnoc_ce_default_inst_e31x.v"
`endif

  localparam XBAR_NUM_PORTS = XBAR_FIXED_PORTS + NUM_CE + NUM_IO_CE;

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

  // Note: The custom accelerator inputs / outputs bitwidth grow based on NUM_CE
  axi_crossbar_regport #(
    .REG_BASE(REG_BASE_XBAR),
    .REG_DWIDTH(REG_DWIDTH),  // Width of the AXI4-Lite data bus (must be 32 or 64)
    .REG_AWIDTH(REG_AWIDTH),  // Width of the address bus
    .FIFO_WIDTH(64),
    .DST_WIDTH(16),
    .NUM_INPUTS(XBAR_NUM_PORTS),
    .NUM_OUTPUTS(XBAR_NUM_PORTS)
  ) axi_crossbar_regport_i (
    .clk(bus_clk), .reset(bus_rst), .clear(1'b0),
    .i_tdata({xbar_ce_i_tdata,dmai_tdata}),
    .i_tlast({xbar_ce_i_tlast,dmai_tlast}),
    .i_tvalid({xbar_ce_i_tvalid,dmai_tvalid}),
    .i_tready({xbar_ce_i_tready,dmai_tready}),
    .o_tdata({xbar_ce_o_tdata,dmao_tdata}),
    .o_tlast({xbar_ce_o_tlast,dmao_tlast}),
    .o_tvalid({xbar_ce_o_tvalid,dmao_tvalid}),
    .o_tready({xbar_ce_o_tready,dmao_tready}),
    .pkt_present({xbar_ce_i_tvalid,dmai_tvalid}),
    .reg_wr_req(reg_wr_req),
    .reg_wr_addr(reg_wr_addr),
    .reg_wr_data(reg_wr_data),
    .reg_rd_req(reg_rd_req),
    .reg_rd_addr(reg_rd_addr),
    .reg_rd_data(reg_rd_data_xbar),
    .reg_rd_resp(reg_rd_resp_xbar)
  );

  /////////////////////////////////////////////////////////////////////////////
  //
  // Front-panel GPIO
  //
  /////////////////////////////////////////////////////////////////////////////

  wire [FP_GPIO_WIDTH-1:0] radio_gpio_in_sync;
  wire [FP_GPIO_WIDTH-1:0] radio_gpio_src_out;
  reg  [FP_GPIO_WIDTH-1:0] radio_gpio_src_out_reg;
  wire [FP_GPIO_WIDTH-1:0] radio_gpio_src_ddr;
  reg  [FP_GPIO_WIDTH-1:0] radio_gpio_src_ddr_reg = ~0;

  // Double-synchronize the inputs to the PS
  synchronizer #(
    .INITIAL_VAL(1'b0), .WIDTH(FP_GPIO_WIDTH)
    ) ps_gpio_in_sync_i (
    .clk(bus_clk), .rst(1'b0), .in(fp_gpio_in), .out(ps_gpio_in)
  );

  // Double-synchronize the inputs to the radio
  synchronizer #(
    .INITIAL_VAL(1'b0), .WIDTH(FP_GPIO_WIDTH)
    ) radio_gpio_in_sync_i (
    .clk(radio_clk), .rst(1'b0), .in(fp_gpio_in), .out(radio_gpio_in_sync)
  );

  // Map the double-synchronized inputs to all radio channels
  generate
    for (i=0; i<NUM_CHANNELS; i=i+1) begin: gen_fp_gpio_in_sync
      assign radio_gpio_in[i][FP_GPIO_WIDTH-1:0] = radio_gpio_in_sync;
    end
  endgenerate

  // For each of the FP GPIO bits, implement four control muxes
  generate
    for (i=0; i<FP_GPIO_WIDTH; i=i+1) begin: gpio_muxing_gen

      // 1) Select which radio drives the output
      assign radio_gpio_src_out[i] = radio_gpio_out[fp_gpio_src_reg[2*i+1:2*i]][i];
      always @ (posedge radio_clk) begin
        if (radio_rst) begin
          radio_gpio_src_out_reg <= 0;
        end else begin
          radio_gpio_src_out_reg <= radio_gpio_src_out;
        end
      end

      // 2) Select which radio drives the direction
      assign radio_gpio_src_ddr[i] = radio_gpio_ddr[fp_gpio_src_reg[2*i+1:2*i]][i];
      always @ (posedge radio_clk) begin
        if (radio_rst) begin
          radio_gpio_src_ddr_reg <= ~0;
        end else begin
          radio_gpio_src_ddr_reg <= radio_gpio_src_ddr;
        end
      end

      // 3) Select if the radio or the ps drives the output
      //
      // The following implements a 2:1 mux in a LUT explicitly to avoid
      // glitches that can be introduced by unexpected Vivado synthesis.
      //
      (* dont_touch = "TRUE" *) LUT3 #(
        .INIT(8'hCA) // Specify LUT Contents. O = ~I2&I0 | I2&I1
      ) mux_out_i (
        .O(fp_gpio_out[i]),             // LUT general output. Mux output
        .I0(radio_gpio_src_out_reg[i]), // LUT input. Input 1
        .I1(ps_gpio_out[i]),            // LUT input. Input 2
        .I2(fp_gpio_master_reg[i])      // LUT input. Select bit
      );

      // 4) Select if the radio or the PS drives the direction
      //
      (* dont_touch = "TRUE" *) LUT3 #(
        .INIT(8'hC5) // Specify LUT Contents. O = ~I2&I0 | I2&~I1
      ) mux_ddr_i (
        .O(fp_gpio_tri[i]),             // LUT general output. Mux output
        .I0(radio_gpio_src_ddr_reg[i]), // LUT input. Input 1
        .I1(ps_gpio_tri[i]),            // LUT input. Input 2
        .I2(fp_gpio_master_reg[i])      // LUT input. Select bit
      );

    end
  endgenerate

endmodule //e31x_core

