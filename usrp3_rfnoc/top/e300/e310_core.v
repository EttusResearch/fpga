//
// Copyright 2013-2014 Ettus Research LLC
//

module e310_core
(
  // bus interfaces
  input             bus_clk,
  input             bus_rst,

  //axi fifo out from data mover
  input [63:0]      h2s_tdata,
  input             h2s_tlast,
  input             h2s_tvalid,
  output            h2s_tready,

  //axi fifo in to data mover
  output [63:0]     s2h_tdata,
  output            s2h_tlast,
  output            s2h_tvalid,
  input             s2h_tready,

  // radio interfaces
  input             radio_clk,
  input             radio_rst,
  input             rx_stb0,
  input [31:0]      rx_data0,
  input             tx_stb0,
  output [31:0]     tx_data0,
  input             rx_stb1,
  input [31:0]      rx_data1,
  input             tx_stb1,
  output [31:0]     tx_data1,

  // gpio controls
  output [31:0]     db_gpio0,
  output [31:0]     db_gpio1,
  output [2:0]      leds0,
  output [2:0]      leds1,

  // SPI from radio core 0
  output            spi_sen,
  output            spi_sclk,
  output            spi_mosi,
  input             spi_miso,

  // settings bus to control global registers
  input [31:0]      set_data,
  input [7:0]       set_addr,
  input             set_stb,
  output reg [31:0] rb_data,

  // settings bus to crossbar registers
  input [31:0]      xbar_set_data,
  input [10:0]      xbar_set_addr,
  input             xbar_set_stb,
  output [31:0]     xbar_rb_data,
  input [10:0]      xbar_rb_addr,
  input             xbar_rb_stb,

  // pps signals -- muxing happens toplevel
  output [1:0]      pps_select,
  input             pps,
  input  [3:0]      tcxo_status,

  // mimo
  output            mimo,

  // codec async reset
  output            codec_arst,

  // front panel (internal) gpio, uses fp gpio from radio channel 0
  input [5:0]       fp_gpio_in0,
  output [5:0]      fp_gpio_out0,
  output [5:0]      fp_gpio_ddr0,

  // signals for ad9361 pll locks
  input [1:0]       lock_signals,

`ifdef DRAM_TEST
  output [31:0]     debug,
  input [31:0]      debug_in
`else /* DRAM_TEST */
  output [31:0]     debug
`endif /* DRAM_TEST */
);

  reg [1:0] lock_state;
  reg [1:0] lock_state_r;

  always @(posedge bus_clk)
    if (bus_rst)
      {lock_state_r, lock_state} <= 4'h0;
    else
      {lock_state_r, lock_state} <= {lock_state, lock_signals};

  // Global register offsets
  localparam SR_CORE_READBACK   = 11'd0;
  localparam SR_CORE_MISC       = 11'd4;
  localparam SR_CORE_TEST       = 11'd28;
  localparam SR_CORE_XB_LOCAL   = 11'd32;

  localparam RB32_CORE_MISC     = 5'd1;
  localparam RB32_CORE_COMPAT   = 5'd2;
  localparam RB32_CORE_GITHASH  = 5'd3;
  localparam RB32_CORE_PLL      = 5'd4;
  localparam RB32_CORE_DEBUG    = 5'd5;
  localparam RB32_CORE_NUMCE    = 5'd8;
  localparam RB32_CORE_TEST     = 5'd24;


   /////////////////////////////////////////////////////////////////////////////////
   // Internal time synchronization
   /////////////////////////////////////////////////////////////////////////////////
  wire [4:0]  rb_addr;
  wire [31:0] rb_test;
  wire [31:0] rb_data_xb;
  wire [7:0] xb_local_addr;

  wire [31:0] core_misc_out;


  setting_reg
  #( .my_addr(SR_CORE_READBACK),
     .awidth(8), .width(5),
     .at_reset(5'd0)
  ) sr_readback_addr
  (
    .clk(bus_clk), .rst(bus_rst),
    .strobe(set_stb), .addr(set_addr),
    .in(set_data), .out(rb_addr),
    .changed()
  );

  setting_reg
  #( .my_addr(SR_CORE_TEST),
     .awidth(8), .width(32),
     .at_reset(32'h0)
  ) sr_test
  (
    .clk(bus_clk), .rst(bus_rst),
    .strobe(set_stb), .addr(set_addr),
    .in(set_data), .out(rb_test),
    .changed()
  );

  // the at_reset value 2'b10 selects
  // the internal pps signal as default
  setting_reg
  #(
    .my_addr(SR_CORE_MISC),
    .awidth(8), .width(32),
    .at_reset({30'h0, 2'b10})
  ) sr_misc
  (
    .clk(bus_clk), .rst(bus_rst),
    .strobe(set_stb), .addr(set_addr),
    .in(set_data), .out(core_misc_out),
    .changed()
  );

  assign pps_select   = core_misc_out[1:0];
  assign mimo         = core_misc_out[2];
  assign codec_arst   = core_misc_out[3];

  setting_reg
  #(
    .my_addr(SR_CORE_XB_LOCAL),
    .awidth(8), .width(8),
    .at_reset(11'd40)
  ) sr_xb_local
  (
    .clk(bus_clk), .rst(bus_rst),
    .strobe(set_stb), .addr(set_addr),
    .in(set_data), .out(xb_local_addr),
    .changed()
  );

  always @(*)
    case(rb_addr)
      RB32_CORE_TEST    : rb_data <= rb_test;
      RB32_CORE_MISC    : rb_data <= {26'd0, tcxo_status, pps_select};
      RB32_CORE_COMPAT  : rb_data <= {8'hAC, 8'h0, 8'd255, 8'd0};
      RB32_CORE_GITHASH : rb_data <= 32'h`GIT_HASH;
      RB32_CORE_PLL     : rb_data <= {30'h0, lock_state_r};
      RB32_CORE_NUMCE   : rb_data <= {28'h0, NUM_CE+4'd1}; // +1 for radio core
`ifdef DRAM_TEST
      RB32_CORE_DEBUG   : rb_data <= debug_in;
`endif /* DRAM_TEST */
      default           : rb_data <= 64'hdeadbeef;
    endcase

  //////////////////////////////////////////////////////////////////////////////////////////////
  // RFNoC
  //////////////////////////////////////////////////////////////////////////////////////////////
  // Specify RFNoC blocks
  `ifdef RFNOC
    `ifdef E310
      `include "rfnoc_ce_auto_inst_e310.v"
    `endif
  `else
    `ifdef E310
      `include "rfnoc_ce_default_inst_e310.v"
    `endif
  `endif

  ////////////////////////////////////////////////////////////////////
  // routing logic, aka crossbar
  ////////////////////////////////////////////////////////////////////

  wire [63:0]          ro_tdata;
  wire                 ro_tlast;
  wire                 ro_tvalid;
  wire                 ro_tready;

  wire [63:0]          ri_tdata;
  wire                 ri_tlast;
  wire                 ri_tvalid;
  wire                 ri_tready;

  localparam XBAR_FIXED_PORTS = 2;
  localparam XBAR_NUM_PORTS = XBAR_FIXED_PORTS + NUM_CE;

  `ifndef LOG2
  `define LOG2(N) (\
                 N < 2    ? 0 : \
                 N < 4    ? 1 : \
                 N < 8    ? 2 : \
                 N < 16   ? 3 : \
                 N < 32   ? 4 : \
                 N < 64   ? 5 : \
                 N < 128  ? 6 : \
                 N < 256  ? 7 : \
                 N < 512  ? 8 : \
                 N < 1024 ? 9 : 10)
  `endif

  // axi crossbar ports
  // 0    - Host (DMA FIFO)
  // 1    - Radios
  // 2-15 - CEs. If available, 2 == DDC and 3 == DUC.

  generate
  if (NUM_CE > 0) begin
    axi_crossbar
    #(
      .BASE(0),
      .FIFO_WIDTH(64),
      .DST_WIDTH(16),
      .NUM_INPUTS(XBAR_NUM_PORTS),
      .NUM_OUTPUTS(XBAR_NUM_PORTS)
    ) axi_crossbar
    (
      .clk(bus_clk),
      .reset(bus_rst),
      .clear(1'b0),
      .local_addr(xb_local_addr),

      // settings bus for config
      .set_stb(xbar_set_stb),
      .set_addr({7'd0, xbar_set_addr[10:2]}), // Settings bus is word aligned, so drop lower two LSBs.
                                              // Also, upper bits are masked to 0 as BASE address is set to 0.
      .set_data(xbar_set_data),
      .rb_rd_stb(xbar_rb_stb),
      .rb_addr(xbar_rb_addr[2*(`LOG2(XBAR_NUM_PORTS))-1+2:2]), // Also word aligned
      .rb_data(xbar_rb_data),

      // inputs, flattened busses
      .i_tdata({ce_flat_i_tdata, ri_tdata, h2s_tdata}),
      .i_tlast({ce_i_tlast, ri_tlast, h2s_tlast}),
      .i_tvalid({ce_i_tvalid, ri_tvalid, h2s_tvalid}),
      .i_tready({ce_i_tready, ri_tready, h2s_tready}),

      // outputs, flattened busses
      .o_tdata({ce_flat_o_tdata, ro_tdata, s2h_tdata}),
      .o_tlast({ce_o_tlast, ro_tlast, s2h_tlast}),
      .o_tvalid({ce_o_tvalid, ro_tvalid, s2h_tvalid}),
      .o_tready({ce_o_tready, ro_tready, s2h_tready}),
      .pkt_present({ce_i_tvalid, ri_tvalid, h2s_tvalid})
    );
  end else begin
    axi_crossbar
    #(
      .BASE(0),
      .FIFO_WIDTH(64),
      .DST_WIDTH(16),
      .NUM_INPUTS(XBAR_NUM_PORTS),
      .NUM_OUTPUTS(XBAR_NUM_PORTS)
    ) axi_crossbar
    (
      .clk(bus_clk),
      .reset(bus_rst),
      .clear(1'b0),
      .local_addr(xb_local_addr),
      .set_stb(xbar_set_stb),
      .set_addr({7'd0, xbar_set_addr[10:2]}),
      .set_data(xbar_set_data),
      .rb_rd_stb(xbar_rb_stb),
      .rb_addr(xbar_rb_addr[2*(`LOG2(XBAR_NUM_PORTS))-1+2:2]), // Also word aligned
      .rb_data(xbar_rb_data),
      .i_tdata({ri_tdata, h2s_tdata}),
      .i_tlast({ri_tlast, h2s_tlast}),
      .i_tvalid({ri_tvalid, h2s_tvalid}),
      .i_tready({ri_tready, h2s_tready}),
      .o_tdata({ro_tdata, s2h_tdata}),
      .o_tlast({ro_tlast, s2h_tlast}),
      .o_tvalid({ro_tvalid, s2h_tvalid}),
      .o_tready({ro_tready, s2h_tready}),
      .pkt_present({ri_tvalid, h2s_tvalid})
    );
  end
  endgenerate

  ////////////////////////////////////////////////////////////////////
  // radio instantiation
  ////////////////////////////////////////////////////////////////////
  // Daughter board I/O is replicated per radio, some of it is unused
  localparam NUM_CHANNELS = 2;
  wire [31:0] leds[0:NUM_CHANNELS-1];
  wire [31:0] fp_gpio_in[0:NUM_CHANNELS-1], fp_gpio_out[0:NUM_CHANNELS-1], fp_gpio_ddr[0:NUM_CHANNELS-1];
  wire [31:0] db_gpio_out[0:NUM_CHANNELS-1];
  wire [7:0] sen[0:NUM_CHANNELS-1];
  wire sclk[0:NUM_CHANNELS-1], mosi[0:NUM_CHANNELS-1], miso[0:NUM_CHANNELS-1];
  noc_block_radio_core #(
    .NUM_CHANNELS(NUM_CHANNELS),
    .STR_SINK_FIFOSIZE({8'd13,8'd13}),
    .MTU(10),                // Tuned value
    .USE_SPI_CLK(1))
  noc_block_radio_core (
    .bus_clk(bus_clk), .bus_rst(bus_rst),
    .ce_clk(radio_clk), .ce_rst(radio_rst),
    .i_tdata(ro_tdata), .i_tlast(ro_tlast), .i_tvalid(ro_tvalid), .i_tready(ro_tready),
    .o_tdata(ri_tdata), .o_tlast(ri_tlast), .o_tvalid(ri_tvalid), .o_tready(ri_tready),
    // Output timed settings bus, one per radio
    .ext_set_stb(), .ext_set_addr(), .ext_set_data(),
    // Ports connected to radio front end
    .rx({rx_data1,rx_data0}), .rx_stb({rx_stb1,rx_stb0}),
    .tx({tx_data1,tx_data0}), .tx_stb({tx_stb1,tx_stb0}),
    // Interfaces to front panel and daughter board
    .pps(pps), .sync_out(),
    .misc_ins('d0), .misc_outs(),
    .fp_gpio_in({fp_gpio_in[1],fp_gpio_in[0]}), .fp_gpio_out({fp_gpio_out[1],fp_gpio_out[0]}), .fp_gpio_ddr({fp_gpio_ddr[1],fp_gpio_ddr[0]}),
    .db_gpio_in('d0), .db_gpio_out({db_gpio_out[1],db_gpio_out[0]}), .db_gpio_ddr(),
    .leds({leds[1],leds[0]}),
    .spi_clk(bus_clk), .spi_rst(bus_rst),
    .sen({sen[1],sen[0]}), .sclk({sclk[1],sclk[0]}), .mosi({mosi[1],mosi[0]}), .miso({miso[1],miso[0]}),
    .debug());

  // Connect daughter board I/O
  assign fp_gpio_in[0]      = {26'd0,fp_gpio_in0};
  assign fp_gpio_out0       = fp_gpio_out[0][5:0];
  assign fp_gpio_ddr0       = fp_gpio_ddr[0][5:0];
  assign fp_gpio_in[1]      = 32'd0; // Note: Unused, but could split fp gpio between both channels
  assign spi_sen            = sen[0][0] & sen[1][0];
  assign spi_sclk           = ~sen[0][0] /* Active low */ ? sclk[0] : sclk[1];
  assign spi_mosi           = ~sen[0][0]                  ? mosi[0] : mosi[1];
  assign miso[0]            = spi_miso;
  assign miso[1]            = spi_miso;
  assign db_gpio0           = db_gpio_out[0];
  assign db_gpio1           = db_gpio_out[1];
  assign leds0              = leds[0][2:0];
  assign leds1              = leds[1][2:0];

endmodule // e310_core
