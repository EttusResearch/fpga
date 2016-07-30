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
  input [31:0]      rx_data0,
  output [31:0]     tx_data0,
  input [31:0]      rx_data1,
  output [31:0]     tx_data1,

  // gpio controls
  output [31:0]     ctrl_out0,
  output [31:0]     ctrl_out1,

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

  // bandselects
  output [2:0]      tx_bandsel,
  output [5:0]      rx_bandsel_a,
  output [3:0]      rx_bandsel_b,
  output [3:0]      rx_bandsel_c,

  // front panel (internal) gpio
  input [5:0]       fp_gpio_in,
  output [5:0]      fp_gpio_out,
  output [5:0]      fp_gpio_ddr,

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
  localparam SR_CORE_READBACK = 8'h00;
  localparam SR_CORE_MISC     = 8'h04;
  localparam SR_CORE_TEST     = 8'h1c;
  localparam SR_CORE_XB_LOCAL = 8'h20;

  localparam RB32_CORE_MISC     = 5'd1;
  localparam RB32_CORE_COMPAT   = 5'd2;
  localparam RB32_CORE_GITHASH  = 5'd3;
  localparam RB32_CORE_PLL      = 5'd4;
  localparam RB32_CORE_DEBUG    = 5'd5;
  localparam RB32_CORE_TEST     = 5'd24;


   /////////////////////////////////////////////////////////////////////////////////
   // Internal time synchronization
   /////////////////////////////////////////////////////////////////////////////////
   wire time_sync, time_sync_r;
    synchronizer time_sync_synchronizer
     (.clk(radio_clk), .rst(radio_rst), .in(time_sync), .out(time_sync_r));

  wire [4:0]  rb_addr;
  wire [31:0] rb_test;
  wire [31:0] rb_data_xb;
  wire [7:0] xb_local_addr;

  wire [31:0] misc_out;

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
    .in(set_data), .out(misc_out),
    .changed()
  );

  assign pps_select   = misc_out[1:0];
  assign mimo         = misc_out[2];
  assign codec_arst   = misc_out[3];
  assign tx_bandsel   = misc_out[6:4];
  assign rx_bandsel_a = misc_out[12:7];
  assign rx_bandsel_b = misc_out[16:13];
  assign rx_bandsel_c = misc_out[20:17];
  assign time_sync    = misc_out[21];

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
      RB32_CORE_COMPAT  : rb_data <= {8'hAC, 8'h0, 8'd16, 8'd0};
      RB32_CORE_GITHASH : rb_data <= 32'h`GIT_HASH;
      RB32_CORE_PLL     : rb_data <= {30'h0, lock_state_r};
`ifdef DRAM_TEST
      RB32_CORE_DEBUG   : rb_data <= debug_in;
`endif /* DRAM_TEST */
      default           : rb_data <= 64'hdeadbeef;
    endcase


  ////////////////////////////////////////////////////////////////////
  // routing logic, aka crossbar
  ////////////////////////////////////////////////////////////////////

  wire [63:0] ro_tdata [1:0]; wire ro_tlast [1:0]; wire ro_tvalid [1:0]; wire ro_tready [1:0];
  wire [63:0] ri_tdata [1:0]; wire ri_tlast [1:0]; wire ri_tvalid [1:0]; wire ri_tready [1:0];

  wire [63:0] cei_tdata [1:0]; wire cei_tlast [1:0]; wire cei_tvalid [1:0]; wire cei_tready [1:0];
  wire [63:0] ceo_tdata [1:0]; wire ceo_tlast [1:0]; wire ceo_tvalid [1:0]; wire ceo_tready [1:0];


  localparam CROSSBAR_IN = 5;
  localparam CROSSBAR_OUT = 5;

  `define LOG2(N) (\
                 N < 2 ? 0 : \
                 N < 4 ? 1 : \
                 N < 8 ? 2 : \
                 N < 16 ? 3 : \
                 N < 32 ? 4 : \
                 N < 64 ? 5 : \
                 N < 128 ? 6 : \
                 N < 256 ? 7 : \
                 N < 512 ? 8 : \
                 N < 1024 ? 9 : \
                 10)


  // axi crossbar ports
  // 0 - Host
  // 1 - Radio0
  // 2 - Radio1
  // 3 - CE0
  // 4 - CE1

  axi_crossbar
  #(
    .BASE(0), // TODO: Set to 0 as logic for other values has not been tested
    .FIFO_WIDTH(64),
    .DST_WIDTH(16),
    .NUM_INPUTS(CROSSBAR_IN),
    .NUM_OUTPUTS(CROSSBAR_OUT)
  ) axi_crossbar
  (
    .clk(bus_clk),
    .reset(bus_rst),
    .clear(0),
    .local_addr(xb_local_addr),

    // settings bus for config
    .set_stb(xbar_set_stb),
    .set_addr({7'd0, xbar_set_addr[10:2]}), // Settings bus is word aligned, so drop lower two LSBs.
                                            // Also, upper bits are masked to 0 as BASE address is set to 0.
    .set_data(xbar_set_data),
    .rb_rd_stb(xbar_rb_stb),
    .rb_addr(xbar_rb_addr[`LOG2(CROSSBAR_IN)+`LOG2(CROSSBAR_OUT)-1+2:2]), // Also word aligned
    .rb_data(xbar_rb_data),

    // inputs, real men flatten busses
    .i_tdata({cei_tdata[1], cei_tdata[0], ri_tdata[1], ri_tdata[0], h2s_tdata}),
    .i_tlast({cei_tlast[1], cei_tlast[0], ri_tlast[1], ri_tlast[0], h2s_tlast}),
    .i_tvalid({cei_tvalid[1], cei_tvalid[0], ri_tvalid[1], ri_tvalid[0], h2s_tvalid}),
    .i_tready({cei_tready[1], cei_tready[0], ri_tready[1], ri_tready[0], h2s_tready}),

    // outputs, real men flatten busses
    .o_tdata({ceo_tdata[1], ceo_tdata[0], ro_tdata[1], ro_tdata[0], s2h_tdata}),
    .o_tlast({ceo_tlast[1], ceo_tlast[0], ro_tlast[1], ro_tlast[0], s2h_tlast}),
    .o_tvalid({ceo_tvalid[1], ceo_tvalid[0], ro_tvalid[1], ro_tvalid[0], s2h_tvalid}),
    .o_tready({ceo_tready[1], ceo_tready[0], ro_tready[1], ro_tready[0], s2h_tready}),
    .pkt_present({cei_tvalid[1], cei_tvalid[0], ri_tvalid[1], ri_tvalid[0], h2s_tvalid})
  );

  // placeholder computational engines
  axi_loopback axi_loopback_ce0
  (
    .clk(bus_clk),
    .reset(bus_rst),
    // Input AXIS
    .i_tdata(ceo_tdata[0]),
    .i_tlast(ceo_tlast[0]),
    .i_tvalid(ceo_tvalid[0]),
    .i_tready(ceo_tready[0]),
    // Output AXIS
    .o_tdata(cei_tdata[0]),
    .o_tlast(cei_tlast[0]),
    .o_tvalid(cei_tvalid[0]),
    .o_tready(cei_tready[0])
  );

  axi_loopback axi_loopback_ce1
  (
    .clk(bus_clk),
    .reset(bus_rst),
    // Input AXIS
    .i_tdata(ceo_tdata[1]),
    .i_tlast(ceo_tlast[1]),
    .i_tvalid(ceo_tvalid[1]),
    .i_tready(ceo_tready[1]),
    // Output AXIS
    .o_tdata(cei_tdata[1]),
    .o_tlast(cei_tlast[1]),
    .o_tvalid(cei_tvalid[1]),
    .o_tready(cei_tready[1])
  );

  ////////////////////////////////////////////////////////////////////
  // radio instantiation
  ////////////////////////////////////////////////////////////////////
  wire [63:0] tx_tdata_bo [1:0], tx_tdata_bi [1:0];
  wire tx_tlast_bo[1:0], tx_tvalid_bo [1:0], tx_tready_bo [1:0];
  wire tx_tlast_bi[1:0], tx_tvalid_bi [1:0], tx_tready_bi [1:0];

  wire [31:0] fp_gpio_out32, fp_gpio_ddr32;
  assign fp_gpio_out = fp_gpio_out32[5:0];
  assign fp_gpio_ddr = fp_gpio_ddr32[5:0];

  axi_fifo #(.WIDTH(65), .SIZE(11)) axi_fifo_tx_packet_buff0
  (
      .clk(bus_clk), .reset(bus_rst), .clear(1'b0),
      .i_tdata({tx_tlast_bo[0], tx_tdata_bo[0]}), .i_tvalid(tx_tvalid_bo[0]), .i_tready(tx_tready_bo[0]),
      .o_tdata({tx_tlast_bi[0], tx_tdata_bi[0]}), .o_tvalid(tx_tvalid_bi[0]), .o_tready(tx_tready_bi[0]),
      .occupied()
  );

  radio #(.RADIO_NUM(0), .DATA_FIFO_SIZE(13), .MSG_FIFO_SIZE(9)) radio0
  (
    //radio domain stuff
    .radio_clk(radio_clk), .radio_rst(radio_rst),

    //not connected
    .rx(rx_data0), .tx(tx_data0),
    .db_gpio_in(32'h0), .db_gpio_out(ctrl_out0), .db_gpio_ddr(/*assumed to be all outputs*/),
    .fp_gpio_in({26'h0, fp_gpio_in}), .fp_gpio_out(fp_gpio_out32), .fp_gpio_ddr(fp_gpio_ddr32),
    .sen(), .sclk(), .mosi(), .miso(),
    .misc_outs(), .misc_ins(32'h0), .leds(),

    //bus clock domain and fifos
    .bus_clk(bus_clk), .bus_rst(bus_rst),
    .in_tdata(ro_tdata[0]), .in_tlast(ro_tlast[0]), .in_tvalid(ro_tvalid[0]), .in_tready(ro_tready[0]),
    .out_tdata(ri_tdata[0]), .out_tlast(ri_tlast[0]), .out_tvalid(ri_tvalid[0]), .out_tready(ri_tready[0]),

    //tx buffering -- used for insertion of axi_fifo_tx_packet_buff
    .tx_tdata_bo(tx_tdata_bo[0]), .tx_tlast_bo(tx_tlast_bo[0]), .tx_tvalid_bo(tx_tvalid_bo[0]), .tx_tready_bo(tx_tready_bo[0]),
    .tx_tdata_bi(tx_tdata_bi[0]), .tx_tlast_bi(tx_tlast_bi[0]), .tx_tvalid_bi(tx_tvalid_bi[0]), .tx_tready_bi(tx_tready_bi[0]),

    .pps(pps), .time_sync(time_sync_r), .sync_dacs(),
    .debug()
  );

  axi_fifo #(.WIDTH(65), .SIZE(11)) axi_fifo_tx_packet_buff1
  (
      .clk(bus_clk), .reset(bus_rst), .clear(1'b0),
      .i_tdata({tx_tlast_bo[1], tx_tdata_bo[1]}), .i_tvalid(tx_tvalid_bo[1]), .i_tready(tx_tready_bo[1]),
      .o_tdata({tx_tlast_bi[1], tx_tdata_bi[1]}), .o_tvalid(tx_tvalid_bi[1]), .o_tready(tx_tready_bi[1]),
      .occupied()
  );

  radio #(.RADIO_NUM(1), .DATA_FIFO_SIZE(13), .MSG_FIFO_SIZE(9)) radio1
  (
    //radio domain stuff
    .radio_clk(radio_clk), .radio_rst(radio_rst),

    //not connected
    .rx(rx_data1), .tx(tx_data1),
    .db_gpio_in(32'h0), .db_gpio_out(ctrl_out1), .db_gpio_ddr(/*assumed to be all outputs*/),
    .fp_gpio_in(32'h0), .fp_gpio_out(), .fp_gpio_ddr(),
    .sen(), .sclk(), .mosi(), .miso(),
    .misc_outs(), .misc_ins(32'h0), .leds(),

    //bus clock domain and fifos
    .bus_clk(bus_clk), .bus_rst(bus_rst),
    .in_tdata(ro_tdata[1]), .in_tlast(ro_tlast[1]), .in_tvalid(ro_tvalid[1]), .in_tready(ro_tready[1]),
    .out_tdata(ri_tdata[1]), .out_tlast(ri_tlast[1]), .out_tvalid(ri_tvalid[1]), .out_tready(ri_tready[1]),

    //tx buffering -- used for insertion of axi_fifo_tx_packet_buff
    .tx_tdata_bo(tx_tdata_bo[1]), .tx_tlast_bo(tx_tlast_bo[1]), .tx_tvalid_bo(tx_tvalid_bo[1]), .tx_tready_bo(tx_tready_bo[1]),
    .tx_tdata_bi(tx_tdata_bi[1]), .tx_tlast_bi(tx_tlast_bi[1]), .tx_tvalid_bi(tx_tvalid_bi[1]), .tx_tready_bi(tx_tready_bi[1]),

    .pps(pps), .time_sync(time_sync_r), .sync_dacs(),
    .debug()
  );

endmodule // e300_core
