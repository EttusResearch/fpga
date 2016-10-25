//
// Copyright 2013 Ettus Research LLC
//

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

module bus_int
  #(
    parameter NUM_CE = 3          // Number of computation engines
   )
   (input clk, input clk_div2, input reset, input reset_div2,
    output sen, output sclk, output mosi, input miso,
    inout scl0, inout sda0,
    inout scl1, inout sda1,
    inout scl2, inout sda2,
    output gps_txd, input gps_rxd,
    output debug_txd, input debug_rxd,
    output [7:0] leds,
    output [3:0] sw_rst,
    // SFP+ 0
    input SFPP0_ModAbs, input SFPP0_TxFault, input SFPP0_RxLOS, inout SFPP0_RS0, inout SFPP0_RS1,
    // SFP+ 1
    input SFPP1_ModAbs, input SFPP1_TxFault, input SFPP1_RxLOS, inout SFPP1_RS0, inout SFPP1_RS1,
    // Clock control and status
    input [7:0] clock_status, output [7:0] clock_control,
    // SFP+ 0 data stream
    output [63:0] sfp0_tx_tdata, output [3:0] sfp0_tx_tuser, output sfp0_tx_tlast, output sfp0_tx_tvalid, input sfp0_tx_tready,
    input [63:0] sfp0_rx_tdata, input [3:0] sfp0_rx_tuser, input sfp0_rx_tlast, input sfp0_rx_tvalid, output sfp0_rx_tready,
    // SFP+ 1 data stream
    output [63:0] sfp1_tx_tdata, output [3:0] sfp1_tx_tuser, output sfp1_tx_tlast, output sfp1_tx_tvalid, input sfp1_tx_tready,
    input [63:0] sfp1_rx_tdata, input [3:0] sfp1_rx_tuser, input sfp1_rx_tlast, input sfp1_rx_tvalid, output sfp1_rx_tready,
    // Radio0
    output [63:0] r0o_tdata, output r0o_tlast, output r0o_tvalid, input r0o_tready,
    input [63:0] r0i_tdata, input r0i_tlast, input r0i_tvalid, output r0i_tready,
    // Radio1
    output [63:0] r1o_tdata, output r1o_tlast, output r1o_tvalid, input r1o_tready,
    input [63:0] r1i_tdata, input r1i_tlast, input r1i_tvalid, output r1i_tready,
    // CE0
    output [63:0] ce0o_tdata, output ce0o_tlast, output ce0o_tvalid, input ce0o_tready,
    input [63:0] ce0i_tdata, input ce0i_tlast, input ce0i_tvalid, output ce0i_tready,
    // CE1
    output [63:0] ce1o_tdata, output ce1o_tlast, output ce1o_tvalid, input ce1o_tready,
    input [63:0] ce1i_tdata, input ce1i_tlast, input ce1i_tvalid, output ce1i_tready,
    // CE2
    output [63:0] ce2o_tdata, output ce2o_tlast, output ce2o_tvalid, input ce2o_tready,
    input [63:0] ce2i_tdata, input ce2i_tlast, input ce2i_tvalid, output ce2i_tready,
    // PCIe
    output [63:0] pcio_tdata, output pcio_tlast, output pcio_tvalid, input pcio_tready,
    input [63:0] pcii_tdata, input pcii_tlast, input pcii_tvalid, output pcii_tready,
    // Computation Engines
    output [NUM_CE*64-1:0] ce_o_tdata, output [NUM_CE-1:0] ce_o_tlast, output [NUM_CE-1:0] ce_o_tvalid, input  [NUM_CE-1:0] ce_o_tready,
    input  [NUM_CE*64-1:0] ce_i_tdata, input  [NUM_CE-1:0] ce_i_tlast, input  [NUM_CE-1:0] ce_i_tvalid, output [NUM_CE-1:0] ce_i_tready,
    //iop2 message fifos
    output [63:0] o_iop2_msg_tdata, output o_iop2_msg_tvalid, output o_iop2_msg_tlast, input o_iop2_msg_tready,
    input [63:0] i_iop2_msg_tdata, input i_iop2_msg_tvalid, input i_iop2_msg_tlast, output i_iop2_msg_tready,
    //------------------------------------------------------------------
    // Wishbone Slave Interface(s)
    //------------------------------------------------------------------
    input [31:0] sfp0_wb_dat_i,
    output [31:0] sfp0_wb_dat_o,
    output [15:0] sfp0_wb_adr,
    output [3:0] sfp0_wb_sel,
    input sfp0_wb_ack,
    output sfp0_wb_stb,
    output sfp0_wb_cyc,
    output sfp0_wb_we,
    input sfp0_wb_int,  // IJB. Nothing to connect this too!! No IRQ controller on x300.

    input [31:0] sfp1_wb_dat_i,
    output [31:0] sfp1_wb_dat_o,
    output [15:0] sfp1_wb_adr,
    output [3:0] sfp1_wb_sel,
    input sfp1_wb_ack,
    output sfp1_wb_stb,
    output sfp1_wb_cyc,
    output sfp1_wb_we,
    input sfp1_wb_int,  // IJB. Nothing to connect this too!! No IRQ controller on x300.

    input [15:0] sfp0_phy_status,
    input [15:0] sfp1_phy_status,

   // Debug
    output [31:0] debug0,
    output [31:0] debug1,
    output [127:0] debug2);

   localparam SR_AWIDTH = 8;
   localparam RB_AWIDTH = 8;

   localparam SR_LEDS         = 8'd00;
   localparam SR_SW_RST       = 8'd01;
   localparam SR_CLOCK_CTRL   = 8'd02;
   localparam SR_XB_LOCAL     = 8'd03;
   localparam SR_SFPP_CTRL0   = 8'd08;
   localparam SR_SFPP_CTRL1   = 8'd09;
   localparam SR_SPI          = 8'd32;
   localparam SR_ETHINT0      = 8'd40;
   localparam SR_ETHINT1      = 8'd56;
   //localparam SR_NEXT_ADDR    = 8'd72;
   // Sets the readback bus address dedicated to the xbar
   localparam SR_RB_ADDR_XBAR = 8'd128;


   localparam RB_COUNTER      = 8'd00;
   localparam RB_SPI_RDY      = 8'd01;
   localparam RB_SPI_DATA     = 8'd02;
   localparam RB_CLK_STATUS   = 8'd03;
   localparam RB_ETH_TYPE0    = 8'd04;
   localparam RB_ETH_TYPE1    = 8'd05;
   localparam RB_COMPAT_NUM   = 8'd06;
   localparam RB_NUM_CE       = 8'd07;
   localparam RB_SFPP_STATUS0 = 8'd08;
   localparam RB_SFPP_STATUS1 = 8'd09;
   localparam RB_GIT_HASH     = 8'd10;
   localparam RB_CROSSBAR     = 8'd128;

   localparam COMPAT_MAJOR    = 16'h0021;
   localparam COMPAT_MINOR    = 16'h0000;

   wire [31:0] 	  set_data;
   wire [7:0] 	  set_addr;
   reg [31:0] 	  rb_data;
   wire [RB_AWIDTH-1:0] rb_addr;
   wire 		rb_rd_stb;
   wire 	  set_stb;
   wire 	  spi_ready;
   wire [31:0] 	  rb_spi_data;


   // ZPU in and ZPU out axi streams
   wire [63:0] 	  zpui_tdata, zpuo_tdata;
   wire [3:0] 	  zpui_tuser, zpuo_tuser;
   wire 	  zpui_tlast, zpuo_tlast, zpui_tvalid, zpuo_tvalid, zpui_tready, zpuo_tready;
   wire [63:0] 	  zpui0_tdata, zpuo0_tdata;
   wire [3:0] 	  zpui0_tuser, zpuo0_tuser;
   wire 	  zpui0_tlast, zpuo0_tlast, zpui0_tvalid, zpuo0_tvalid, zpui0_tready, zpuo0_tready;
   wire [63:0] 	  zpui1_tdata, zpuo1_tdata;
   wire [3:0] 	  zpui1_tuser, zpuo1_tuser;
   wire 	  zpui1_tlast, zpuo1_tlast, zpui1_tvalid, zpuo1_tvalid, zpui1_tready, zpuo1_tready;

   // v2e (vita to ethernet) and e2v (eth to vita)
   wire [63:0] 	  v2e0_tdata, v2e1_tdata, e2v0_tdata, e2v1_tdata;
   wire 	  v2e0_tlast, v2e1_tlast, v2e0_tvalid, v2e1_tvalid, v2e0_tready, v2e1_tready;
   wire 	  e2v0_tlast, e2v1_tlast, e2v0_tvalid, e2v1_tvalid, e2v0_tready, e2v1_tready;

   //settings bus for crossbar router
   wire [31:0] 	  set_data_xb;
   wire [8:0] 	  set_addr_xb;
   wire 	  set_stb_xb;

   // SFP+ logic
   wire  SFPP0_ModAbs_sync, SFPP0_TxFault_sync, SFPP0_RxLOS_sync;
   reg   SFPP0_ModAbs_reg,  SFPP0_TxFault_reg,  SFPP0_RxLOS_reg;
   reg   SFPP0_ModAbs_chgd, SFPP0_TxFault_chgd, SFPP0_RxLOS_chgd;

   wire  SFPP1_ModAbs_sync, SFPP1_TxFault_sync, SFPP1_RxLOS_sync;
   reg   SFPP1_ModAbs_reg,  SFPP1_TxFault_reg,  SFPP1_RxLOS_reg;
   reg   SFPP1_ModAbs_chgd, SFPP1_TxFault_chgd, SFPP1_RxLOS_chgd;

   wire [15:0]  sfp0_phy_status_sync, sfp1_phy_status_sync;

   ////////////////////////////////////////////////////////////////////
   // Soft CPU - drives network setup, soft reset, ICMP, ...
   ////////////////////////////////////////////////////////////////////
   soft_ctrl #(.SB_ADDRW(SR_AWIDTH), .RB_ADDRW(RB_AWIDTH)) sc
     (
      .clk(clk), .rst(reset),
      .clk_div2(clk_div2), .rst_div2(reset_div2),
      //------------------------------------------------------------------
      // I2C interfaces
      //------------------------------------------------------------------
      .scl0(scl0), .sda0(sda0),
      .scl1(scl1), .sda1(sda1),
      .scl2(scl2), .sda2(sda2),
      //------------------------------------------------------------------
      // UARTs for CPU comms
      //------------------------------------------------------------------
      .gps_rxd(gps_rxd), .gps_txd(gps_txd),
      .debug_rxd(debug_rxd), .debug_txd(debug_txd),
      //------------------------------------------------------------------
      // settings bus interface
      //------------------------------------------------------------------
      .set_stb(set_stb),
      .set_addr(set_addr),
      .set_data(set_data),
      //------------------------------------------------------------------
      // settings bus interface for crossbar router
      //------------------------------------------------------------------
      .set_stb_xb(set_stb_xb),
      .set_addr_xb(set_addr_xb),
      .set_data_xb(set_data_xb),
      //------------------------------------------------------------------
      // readback bus interface
      //------------------------------------------------------------------
      .rb_addr(rb_addr),
      .rb_data(rb_data),
      .rb_rd_stb(rb_rd_stb),
      //------------------------------------------------------------------
      // packet interface in
      //------------------------------------------------------------------
      .rx_tdata(zpui_tdata),
      .rx_tuser(zpui_tuser),
      .rx_tlast(zpui_tlast),
      .rx_tvalid(zpui_tvalid),
      .rx_tready(zpui_tready),
      //------------------------------------------------------------------
      // packet interface out
      //------------------------------------------------------------------
      .tx_tdata(zpuo_tdata),
      .tx_tuser(zpuo_tuser),
      .tx_tlast(zpuo_tlast),
      .tx_tvalid(zpuo_tvalid),
      .tx_tready(zpuo_tready),
      //------------------------------------------------------------------
      // Wishbone Slave Interface(s)
      //------------------------------------------------------------------
      .s4_dat_i(sfp0_wb_dat_i),
      .s4_dat_o(sfp0_wb_dat_o),
      .s4_adr(sfp0_wb_adr),
      .s4_sel(sfp0_wb_sel),
      .s4_ack(sfp0_wb_ack),
      .s4_stb(sfp0_wb_stb),
      .s4_cyc(sfp0_wb_cyc),
      .s4_we(sfp0_wb_we),
      .s4_int(sfp0_wb_int),
      //------------------------------------------------------------------
      // IoPort2 Msg Interface
      //------------------------------------------------------------------
      .o_iop2_msg_tdata(o_iop2_msg_tdata),
      .o_iop2_msg_tvalid(o_iop2_msg_tvalid),
      .o_iop2_msg_tlast(o_iop2_msg_tlast),
      .o_iop2_msg_tready(o_iop2_msg_tready),
      .i_iop2_msg_tdata(i_iop2_msg_tdata),
      .i_iop2_msg_tvalid(i_iop2_msg_tvalid),
      .i_iop2_msg_tlast(i_iop2_msg_tlast),
      .i_iop2_msg_tready(i_iop2_msg_tready),

      .s5_dat_i(sfp1_wb_dat_i),
      .s5_dat_o(sfp1_wb_dat_o),
      .s5_adr(sfp1_wb_adr),
      .s5_sel(sfp1_wb_sel),
      .s5_ack(sfp1_wb_ack),
      .s5_stb(sfp1_wb_stb),
      .s5_cyc(sfp1_wb_cyc),
      .s5_we(sfp1_wb_we),
      .s5_int(sfp1_wb_int),

      //------------------------------------------------------------------
      // Debug
      //------------------------------------------------------------------
      .debug0(debug2),
      .debug1()
   );

   setting_reg #(.my_addr(SR_LEDS), .awidth(SR_AWIDTH), .width(8)) set_leds
     (.clk(clk), .rst(reset),
      .strobe(set_stb), .addr(set_addr), .in(set_data),
      .out(leds));

   //
   // SW_RST - Bit allocation:
   // [0] - PHY reset
   // [1] - Radio clk domain reset
   // [2] - Radio Clk PLL reset.
   // [3] - ADC IdelayCtrl reset
   //
   setting_reg #(.my_addr(SR_SW_RST), .awidth(SR_AWIDTH), .width(4)) set_sw_rst
     (.clk(clk), .rst(reset),
      .strobe(set_stb), .addr(set_addr), .in(set_data),
      .out(sw_rst));

   setting_reg #(.my_addr(SR_CLOCK_CTRL), .awidth(SR_AWIDTH), .width(8),
        .at_reset(7'b1000000) //bit 6 high means GPSDO on by default
    ) set_clk_ctrl
     (.clk(clk), .rst(reset),
      .strobe(set_stb), .addr(set_addr), .in(set_data),
      .out(clock_control));

   simple_spi_core #(.BASE(SR_SPI), .WIDTH(1), .CLK_IDLE(0), .SEN_IDLE(1'b1)) misc_spi
     (.clock(clk), .reset(reset),
      .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
      .readback(rb_spi_data), .ready(spi_ready),
      .sen(sen), .sclk(sclk), .mosi(mosi), .miso(miso),
      .debug());

   reg [31:0]   counter;
   wire [31:0]  rb_data_crossbar;

   always @(posedge clk) counter <= counter + 1;

   always @*
     casex (rb_addr)
       RB_NUM_CE: rb_data = NUM_CE;
       RB_COMPAT_NUM: rb_data = {COMPAT_MAJOR, COMPAT_MINOR};
       RB_COUNTER: rb_data = counter;
       RB_SPI_RDY: rb_data = {31'b0, spi_ready};
       RB_SPI_DATA: rb_data = rb_spi_data;
       RB_CLK_STATUS: rb_data = {24'b0, clock_status};
       // SFPP Interface pins.
       RB_SFPP_STATUS0: rb_data = {
            sfp0_phy_status_sync, 10'b0,
            SFPP0_ModAbs_chgd, SFPP0_TxFault_chgd, SFPP0_RxLOS_chgd,
            SFPP0_ModAbs_sync, SFPP0_TxFault_sync, SFPP0_RxLOS_sync};
       RB_SFPP_STATUS1: rb_data = {
            sfp1_phy_status_sync, 10'b0,
            SFPP1_ModAbs_chgd, SFPP1_TxFault_chgd, SFPP1_RxLOS_chgd,
            SFPP1_ModAbs_sync, SFPP1_TxFault_sync, SFPP1_RxLOS_sync};
       // Allow readback of configured ethernet interfaces.
`ifdef SFP0_AURORA
       RB_ETH_TYPE0: rb_data = {32'h2};
`else
   `ifdef SFP0_10GBE
       RB_ETH_TYPE0: rb_data = {32'h1};
   `else
       RB_ETH_TYPE0: rb_data = {32'h0};
   `endif
`endif
`ifdef SFP1_AURORA
       RB_ETH_TYPE1: rb_data = {32'h2};
`else
   `ifdef SFP1_10GBE
       RB_ETH_TYPE1: rb_data = {32'h1};
   `else
       RB_ETH_TYPE1: rb_data = {32'h0};
   `endif
`endif
       RB_GIT_HASH: rb_data = 32'h`GIT_HASH;

       RB_CROSSBAR: rb_data = rb_data_crossbar;

       default: rb_data = 32'h0;
     endcase // case (rb_addr)

   // Latch state changes to SFP0+ pins.
   synchronizer #(.INITIAL_VAL(1'b0)) sfpp0_modabs_sync (
      .clk(clk), .rst(1'b0 /* no reset */), .in(SFPP0_ModAbs), .out(SFPP0_ModAbs_sync));
   synchronizer #(.INITIAL_VAL(1'b0)) sfpp0_txfault_sync (
      .clk(clk), .rst(1'b0 /* no reset */), .in(SFPP0_TxFault), .out(SFPP0_TxFault_sync));
   synchronizer #(.INITIAL_VAL(1'b0)) sfpp0_rxlos_sync (
      .clk(clk), .rst(1'b0 /* no reset */), .in(SFPP0_RxLOS), .out(SFPP0_RxLOS_sync));

   always @(posedge clk) begin
      SFPP0_ModAbs_reg  <= SFPP0_ModAbs_sync;
      SFPP0_TxFault_reg <= SFPP0_TxFault_sync;
      SFPP0_RxLOS_reg   <= SFPP0_RxLOS_sync;
   end

   always @(posedge clk) begin
      if (reset || (rb_rd_stb && (rb_addr == RB_SFPP_STATUS0))) begin
         SFPP0_ModAbs_chgd  <= 1'b0;
         SFPP0_TxFault_chgd <= 1'b0;
         SFPP0_RxLOS_chgd   <= 1'b0;
      end else begin
         if (SFPP0_ModAbs_sync != SFPP0_ModAbs_reg)
            SFPP0_ModAbs_chgd <= 1'b1;
         if (SFPP0_TxFault_sync != SFPP0_TxFault_reg)
            SFPP0_TxFault_chgd <= 1'b1;
         if (SFPP0_RxLOS_sync != SFPP0_RxLOS_reg)
            SFPP0_RxLOS_chgd <= 1'b1;
      end
   end

   // Latch state changes to SFP1+ pins.
   synchronizer #(.INITIAL_VAL(1'b0)) sfpp1_modabs_sync (
      .clk(clk), .rst(1'b0 /* no reset */), .in(SFPP1_ModAbs), .out(SFPP1_ModAbs_sync));
   synchronizer #(.INITIAL_VAL(1'b0)) sfpp1_txfault_sync (
      .clk(clk), .rst(1'b0 /* no reset */), .in(SFPP1_TxFault), .out(SFPP1_TxFault_sync));
   synchronizer #(.INITIAL_VAL(1'b0)) sfpp1_rxlos_sync (
      .clk(clk), .rst(1'b0 /* no reset */), .in(SFPP1_RxLOS), .out(SFPP1_RxLOS_sync));

   always @(posedge clk) begin
      SFPP1_ModAbs_reg  <= SFPP1_ModAbs_sync;
      SFPP1_TxFault_reg <= SFPP1_TxFault_sync;
      SFPP1_RxLOS_reg   <= SFPP1_RxLOS_sync;
   end

   always @(posedge clk) begin
      if (reset || (rb_rd_stb && (rb_addr == RB_SFPP_STATUS1))) begin
         SFPP1_ModAbs_chgd  <= 1'b0;
         SFPP1_TxFault_chgd <= 1'b0;
         SFPP1_RxLOS_chgd   <= 1'b0;
      end else begin
         if (SFPP1_ModAbs_sync != SFPP1_ModAbs_reg)
            SFPP1_ModAbs_chgd <= 1'b1;
         if (SFPP1_TxFault_sync != SFPP1_TxFault_reg)
            SFPP1_TxFault_chgd <= 1'b1;
         if (SFPP1_RxLOS_sync != SFPP1_RxLOS_reg)
            SFPP1_RxLOS_chgd <= 1'b1;
      end
   end

   //Synchronize ethernet PHY status bits to bus_clk
   //All bits in the bus can be treated as asynchronous
   genvar i;
   generate
   for (i=0; i<16; i=i+1) begin: eth_status_synchronizer_gen
      synchronizer #(.INITIAL_VAL(1'b0)) sfp0_status (
         .clk(clk), .rst(1'b0 /* no reset */), .in(sfp0_phy_status[i]), .out(sfp0_phy_status_sync[i]));
      synchronizer #(.INITIAL_VAL(1'b0)) sfp1_status (
         .clk(clk), .rst(1'b0 /* no reset */), .in(sfp1_phy_status[i]), .out(sfp1_phy_status_sync[i]));
   end
   endgenerate


   wire [1:0] 	  sfpp0_ctrl;

   // SFPP_RS0/1 pins are open drain.
   setting_reg #(.my_addr(SR_SFPP_CTRL0), .awidth(SR_AWIDTH), .width(2), .at_reset(2'b00)) set_sfpp0_ctrl
     (.clk(clk), .rst(reset),
      .strobe(set_stb), .addr(set_addr), .in(set_data),
      .out(sfpp0_ctrl));

   assign SFPP0_RS0 = sfpp0_ctrl[0] ? 1'b0 : 1'bz;
   assign SFPP0_RS1 = sfpp0_ctrl[1] ? 1'b0 : 1'bz;

  wire [1:0] 	  sfpp1_ctrl;

   // SFPP1_RS0/1 pins are open drain.
   setting_reg #(.my_addr(SR_SFPP_CTRL1), .awidth(SR_AWIDTH), .width(2), .at_reset(2'b00)) set_sfpp1_ctrl
     (.clk(clk), .rst(reset),
      .strobe(set_stb), .addr(set_addr), .in(set_data),
      .out(sfpp1_ctrl));

   assign SFPP1_RS0 = sfpp1_ctrl[0] ? 1'b0 : 1'bz;
   assign SFPP1_RS1 = sfpp1_ctrl[1] ? 1'b0 : 1'bz;

   // ////////////////////////////////////////////////////////////////
   // ETH interfaces

   wire [63:0] e01_tdata, e10_tdata;
   wire [3:0]  e01_tuser, e10_tuser;
   wire        e01_tlast, e01_tvalid, e01_tready;
   wire        e10_tlast, e10_tvalid, e10_tready;

`ifdef SFP0_AURORA
   // The packet format over Aurora is CHDR so we don't need any special framing/deframing
   assign {e2v0_tdata, e2v0_tlast, e2v0_tvalid, sfp0_rx_tready} = {sfp0_rx_tdata, sfp0_rx_tlast, sfp0_rx_tvalid, e2v0_tready};
   assign {sfp0_tx_tdata, sfp0_tx_tlast, sfp0_tx_tvalid, v2e0_tready} = {v2e0_tdata, v2e0_tlast, v2e0_tvalid, sfp0_tx_tready};
   assign {zpui0_tdata, zpui0_tlast, zpui0_tvalid, zpuo0_tready} = {64'h0, 1'b0, 1'b0, 1'b1};
   assign {e01_tdata, e01_tlast, e01_tvalid, e10_tready} = {64'h0, 1'b0, 1'b0, 1'b1};
`else
   eth_interface #(.BASE(SR_ETHINT0)) eth_interface0
     (.clk(clk), .reset(reset), .clear(1'b0),
      .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
      .eth_tx_tdata(sfp0_tx_tdata), .eth_tx_tuser(sfp0_tx_tuser), .eth_tx_tlast(sfp0_tx_tlast),
      .eth_tx_tvalid(sfp0_tx_tvalid), .eth_tx_tready(sfp0_tx_tready),
      .eth_rx_tdata(sfp0_rx_tdata), .eth_rx_tuser(sfp0_rx_tuser), .eth_rx_tlast(sfp0_rx_tlast),
      .eth_rx_tvalid(sfp0_rx_tvalid), .eth_rx_tready(sfp0_rx_tready),
      .e2v_tdata(e2v0_tdata), .e2v_tlast(e2v0_tlast), .e2v_tvalid(e2v0_tvalid), .e2v_tready(e2v0_tready),
      .v2e_tdata(v2e0_tdata), .v2e_tlast(v2e0_tlast), .v2e_tvalid(v2e0_tvalid), .v2e_tready(v2e0_tready),
      .xo_tdata(e01_tdata), .xo_tuser(e01_tuser), .xo_tlast(e01_tlast), .xo_tvalid(e01_tvalid), .xo_tready(e01_tready),
      .xi_tdata(e10_tdata), .xi_tuser(e10_tuser), .xi_tlast(e10_tlast), .xi_tvalid(e10_tvalid), .xi_tready(e10_tready),
      .e2z_tdata(zpui0_tdata), .e2z_tuser(zpui0_tuser), .e2z_tlast(zpui0_tlast), .e2z_tvalid(zpui0_tvalid), .e2z_tready(zpui0_tready),
      .z2e_tdata(zpuo0_tdata), .z2e_tuser(zpuo0_tuser), .z2e_tlast(zpuo0_tlast), .z2e_tvalid(zpuo0_tvalid), .z2e_tready(zpuo0_tready),
      .debug());
`endif

`ifdef SFP1_AURORA
   // The packet format over Aurora is CHDR so we don't need any special framing/deframing
   assign {e2v1_tdata, e2v1_tlast, e2v1_tvalid, sfp1_rx_tready} = {sfp1_rx_tdata, sfp1_rx_tlast, sfp1_rx_tvalid, e2v1_tready};
   assign {sfp1_tx_tdata, sfp1_tx_tlast, sfp1_tx_tvalid, v2e1_tready} = {v2e1_tdata, v2e1_tlast, v2e1_tvalid, sfp1_tx_tready};
   assign {zpui1_tdata, zpui1_tlast, zpui1_tvalid, zpuo1_tready} = {64'h0, 1'b0, 1'b0, 1'b1};
   assign {e10_tdata, e10_tlast, e10_tvalid, e01_tready} = {64'h0, 1'b0, 1'b0, 1'b1};
`else
   eth_interface #(.BASE(SR_ETHINT1)) eth_interface1
     (.clk(clk), .reset(reset), .clear(1'b0),
      .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
      .eth_tx_tdata(sfp1_tx_tdata), .eth_tx_tuser(sfp1_tx_tuser), .eth_tx_tlast(sfp1_tx_tlast),
      .eth_tx_tvalid(sfp1_tx_tvalid), .eth_tx_tready(sfp1_tx_tready),
      .eth_rx_tdata(sfp1_rx_tdata), .eth_rx_tuser(sfp1_rx_tuser), .eth_rx_tlast(sfp1_rx_tlast),
      .eth_rx_tvalid(sfp1_rx_tvalid), .eth_rx_tready(sfp1_rx_tready),
      .e2v_tdata(e2v1_tdata), .e2v_tlast(e2v1_tlast), .e2v_tvalid(e2v1_tvalid), .e2v_tready(e2v1_tready),
      .v2e_tdata(v2e1_tdata), .v2e_tlast(v2e1_tlast), .v2e_tvalid(v2e1_tvalid), .v2e_tready(v2e1_tready),
      .xo_tdata(e10_tdata), .xo_tuser(e10_tuser), .xo_tlast(e10_tlast), .xo_tvalid(e10_tvalid), .xo_tready(e10_tready),
      .xi_tdata(e01_tdata), .xi_tuser(e01_tuser), .xi_tlast(e01_tlast), .xi_tvalid(e01_tvalid), .xi_tready(e01_tready),
      .e2z_tdata(zpui1_tdata), .e2z_tuser(zpui1_tuser), .e2z_tlast(zpui1_tlast), .e2z_tvalid(zpui1_tvalid), .e2z_tready(zpui1_tready),
      .z2e_tdata(zpuo1_tdata), .z2e_tuser(zpuo1_tuser), .z2e_tlast(zpuo1_tlast), .z2e_tvalid(zpuo1_tvalid), .z2e_tready(zpuo1_tready),
      .debug());
`endif

   axi_mux4 #(.PRIO(0), .WIDTH(68)) zpui_mux
     (.clk(clk), .reset(reset), .clear(1'b0),
      .i0_tdata({zpui0_tuser,zpui0_tdata}), .i0_tlast(zpui0_tlast), .i0_tvalid(zpui0_tvalid), .i0_tready(zpui0_tready),
      .i1_tdata({zpui1_tuser,zpui1_tdata}), .i1_tlast(zpui1_tlast), .i1_tvalid(zpui1_tvalid), .i1_tready(zpui1_tready),
      .i2_tdata(68'h0), .i2_tlast(1'b0), .i2_tvalid(1'b0), .i2_tready(),
      .i3_tdata(68'h0), .i3_tlast(1'b0), .i3_tvalid(1'b0), .i3_tready(),
      .o_tdata({zpui_tuser,zpui_tdata}), .o_tlast(zpui_tlast), .o_tvalid(zpui_tvalid), .o_tready(zpui_tready));

   // Demux ZPU to Eth output by the port number in top 8 bits of data on first line
   wire [67:0] 	  zpuo_eth_header;
   wire [1:0] 	  zpuo_eth_dest = (zpuo_eth_header[63:56] == 8'd0) ? 2'b00 : 2'b01;

   axi_demux4 #(.ACTIVE_CHAN(4'b0011), .WIDTH(68)) zpuo_demux
     (.clk(clk), .reset(reset), .clear(1'b0),
      .header(zpuo_eth_header), .dest(zpuo_eth_dest),
      .i_tdata({zpuo_tuser,zpuo_tdata}), .i_tlast(zpuo_tlast), .i_tvalid(zpuo_tvalid), .i_tready(zpuo_tready),
      .o0_tdata({zpuo0_tuser,zpuo0_tdata}), .o0_tlast(zpuo0_tlast), .o0_tvalid(zpuo0_tvalid), .o0_tready(zpuo0_tready),
      .o1_tdata({zpuo1_tuser,zpuo1_tdata}), .o1_tlast(zpuo1_tlast), .o1_tvalid(zpuo1_tvalid), .o1_tready(zpuo1_tready),
      .o2_tdata(), .o2_tlast(), .o2_tvalid(), .o2_tready(1'b1),
      .o3_tdata(), .o3_tlast(), .o3_tvalid(), .o3_tready(1'b1));

   // //////////////////////////////////////////////////////////////////////
   // axi_crossbar ports
   // 0  - ETH0
   // 1  - ETH1
   // 2  - PCIe
   // 3  - CE0
   // ...
   // 15 - CE13
   
  // Base width of crossbar based on fixed components (ethernet, PCIE)
   localparam XBAR_FIXED_PORTS = 3;
   localparam XBAR_NUM_PORTS = XBAR_FIXED_PORTS + NUM_CE;
   
   wire [7:0] local_addr;
   // Dedicated address space readback of xbar stats (up to 16x16)
   wire [`LOG2(XBAR_NUM_PORTS)+`LOG2(XBAR_NUM_PORTS)-1:0] rb_addr_xbar;

   setting_reg #(.my_addr(SR_XB_LOCAL), .awidth(SR_AWIDTH), .width(8)) sr_local_addr
     (.clk(clk),.rst(reset),.strobe(set_stb),.addr(set_addr),
      .in(set_data),.out(local_addr),.changed());

   setting_reg #(.my_addr(SR_RB_ADDR_XBAR), .awidth(SR_AWIDTH), .width(`LOG2(XBAR_NUM_PORTS)+`LOG2(XBAR_NUM_PORTS))) sr_rb_addr_xbar
     (.clk(clk),.rst(reset),.strobe(set_stb),.addr(set_addr),
      .in(set_data),.out(rb_addr_xbar),.changed());
  
   // Note: The custom accelerator inputs / outputs bitwidth grow based on NUM_CE
   axi_crossbar #(
      .FIFO_WIDTH(64), .DST_WIDTH(16), .NUM_INPUTS(XBAR_NUM_PORTS), .NUM_OUTPUTS(XBAR_NUM_PORTS))
   inst_axi_crossbar (
      .clk(clk), .reset(reset), .clear(0),
      .local_addr(local_addr),
      .set_stb(set_stb_xb), .set_addr(set_addr_xb), .set_data(set_data_xb),
      .i_tdata({ce_i_tdata,pcii_tdata,e2v1_tdata,e2v0_tdata}),
      .i_tlast({ce_i_tlast,pcii_tlast,e2v1_tlast,e2v0_tlast}),
      .i_tvalid({ce_i_tvalid,pcii_tvalid,e2v1_tvalid,e2v0_tvalid}),
      .i_tready({ce_i_tready,pcii_tready,e2v1_tready,e2v0_tready}),
      .o_tdata({ce_o_tdata,pcio_tdata,v2e1_tdata,v2e0_tdata}),
      .o_tlast({ce_o_tlast,pcio_tlast,v2e1_tlast,v2e0_tlast}),
      .o_tvalid({ce_o_tvalid,pcio_tvalid,v2e1_tvalid,v2e0_tvalid}),
      .o_tready({ce_o_tready,pcio_tready,v2e1_tready,v2e0_tready}),
      .pkt_present({ce_i_tvalid,pcii_tvalid,e2v1_tvalid,e2v0_tvalid}),
      .rb_rd_stb(rb_rd_stb && (rb_addr == RB_CROSSBAR)),
      .rb_addr(rb_addr_xbar), .rb_data(rb_data_crossbar));

endmodule // bus_int
