//
// Copyright 2013 Ettus Research LLC
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

/***********************************************************
 * Helium Core Guts
 **********************************************************/
module n230_core #(
    parameter R0_CTRL_SID = 8'h10,
    parameter R1_CTRL_SID = 8'h20,
    parameter U0_CTRL_SID = 8'h30,
    parameter L0_CTRL_SID = 8'h40,
    parameter R0_DATA_SID = 8'h50,
    parameter R1_DATA_SID = 8'h60,
    parameter DEMUX_SID_MASK = 8'hf0,
    parameter EXTRA_TX_BUFF_SIZE = 10,
    parameter EXTRA_RX_BUFF_SIZE = 0,
    parameter RADIO_FIFO_SIZE = 12,
    parameter SAMPLE_FIFO_SIZE = 11
) (
   //------------------------------------------------------------------
   // bus interfaces
   //------------------------------------------------------------------
   input bus_clk,
   input bus_rst,

   //------------------------------------------------------------------
   // Configuration SPI Flash interface
   //------------------------------------------------------------------
   output spiflash_cs,
   output spiflash_clk,
   input spiflash_miso,
   output spiflash_mosi,

   //------------------------------------------------------------------
   // radio interfaces
   //------------------------------------------------------------------
   input radio_clk,
   input radio_rst,

   input [31:0] rx0,
   input [31:0] rx1,
   output [31:0] tx0,
   output [31:0] tx1,
   output [31:0] fe_atr0,
   output [31:0] fe_atr1,
   input pps_int,
   input pps_ext,

   //------------------------------------------------------------------
   // gpsdo uart
   //------------------------------------------------------------------
   input gpsdo_rxd,
   output gpsdo_txd,

   //------------------------------------------------------------------
   // core interfaces
   //------------------------------------------------------------------
   output [7:0] sen,
   output sclk,
   output mosi,
   input miso,
   input [31:0] rb_misc,
   output [31:0] misc_outs,
   output [3:0] sw_rst,
   output [2:0] radio_control,

   //------------------------------------------------------------------
   // SFP interface 0 (Supporting signals)
   //------------------------------------------------------------------
   input SFP0_ModAbs,
   input SFP0_TxFault,
   input SFP0_RxLOS,
   inout SFP0_RS0,
   inout SFP0_RS1,
   inout SFP0_SCL,
   inout SFP0_SDA,
   //------------------------------------------------------------------
   // SFP interface 1 (Supporting signals)
   //------------------------------------------------------------------

   input SFP1_ModAbs,
   input SFP1_TxFault,
   input SFP1_RxLOS,
   inout SFP1_RS0,
   inout SFP1_RS1,
   inout SFP1_SCL,
   inout SFP1_SDA,
   //------------------------------------------------------------------
   // GMII interface 0 to PHY
   //------------------------------------------------------------------
   input gmii_clk0,
   output [7:0] gmii_txd0,
   output gmii_tx_en0,
   output gmii_tx_er0,
   input [7:0] gmii_rxd0,
   input gmii_rx_dv0,
   input gmii_rx_er0,
   input [15:0] gmii_status0,
   output mdc0,
   output mdio_in0,
   input mdio_out0,

   //------------------------------------------------------------------
   // GMII interface 1 to PHY
   //------------------------------------------------------------------
   input gmii_clk1,
   output [7:0] gmii_txd1,
   output gmii_tx_en1,
   output gmii_tx_er1,
   input [7:0] gmii_rxd1,
   input gmii_rx_dv1,
   input gmii_rx_er1,
   input [15:0] gmii_status1,
   output mdc1,
   output mdio_in1,
   input mdio_out1,
   //------------------------------------------------------------------
   // External ZBT SRAM FIFO
   //------------------------------------------------------------------
   input [63:0] i_tdata_extfifo,
   input i_tlast_extfifo,
   input i_tvalid_extfifo,
   output i_tready_extfifo,
   output [63:0] o_tdata_extfifo,
   output o_tlast_extfifo,
   output o_tvalid_extfifo,
   input o_tready_extfifo,
   
   input extfifo_bist_done,
   input [1:0] extfifo_bist_error,

   //------------------------------------------------------------------
   // Delay Control_interface
   //------------------------------------------------------------------
   output [4:0] ctrl_clk_delay,
   output [4:0] ctrl_data_delay,
   output ctrl_ld_clk_delay,
   output ctrl_ld_data_delay,
   //------------------------------------------------------------------
   // LED's
   //------------------------------------------------------------------
   output [15:0] leds,
   //------------------------------------------------------------------
   // debug UART
   //------------------------------------------------------------------
   output debug_txd, input debug_rxd,
   //------------------------------------------------------------------
   // Production Test
   //------------------------------------------------------------------
   `ifdef TEST_JESD204_IF
   output jesd204_test_run,
   input jesd204_test_done,
   input [15:0] jesd204_test_status,
   `endif
   //------------------------------------------------------------------
   // debug signals
   //------------------------------------------------------------------
   output [31:0] debug
);

`include "n230_fpga_common.v"


   /*******************************************************************
    * CHDR busses
    *******************************************************************/
   wire [63:0]       tx_tdata; wire tx_tlast; wire tx_tvalid; wire tx_tready;
   wire [63:0]       rx_tdata; wire rx_tlast; wire rx_tvalid; wire rx_tready;
   wire [63:0]       ctrl_tdata; wire ctrl_tlast; wire ctrl_tvalid; wire ctrl_tready;
   wire [63:0]       resp_tdata; wire resp_tlast; wire resp_tvalid; wire resp_tready;
   // v2e (vita to ethernet) and e2v (eth to vita)
   wire [63:0]       v2e0_tdata, v2e1_tdata, e2v0_tdata, e2v1_tdata;
   wire       v2e0_tlast, v2e1_tlast, v2e0_tvalid, v2e1_tvalid, v2e0_tready, v2e1_tready;
   wire       e2v0_tlast, e2v1_tlast, e2v0_tvalid, e2v1_tvalid, e2v0_tready, e2v1_tready;

   /*******************************************************************
    * AXI Stream carrying IP/UDP packets to/from ZPU
    *******************************************************************/
   wire [63:0]      zpui_tdata, zpuo_tdata;
   wire [3:0]      zpui_tuser, zpuo_tuser;
   wire      zpui_tlast, zpuo_tlast, zpui_tvalid, zpuo_tvalid, zpui_tready, zpuo_tready;
   wire [63:0]      zpui0_tdata, zpuo0_tdata;
   wire [3:0]      zpui0_tuser, zpuo0_tuser;
   wire      zpui0_tlast, zpuo0_tlast, zpui0_tvalid, zpuo0_tvalid, zpui0_tready, zpuo0_tready;
   wire [63:0]      zpui1_tdata, zpuo1_tdata;
   wire [3:0]      zpui1_tuser, zpuo1_tuser;
   wire      zpui1_tlast, zpuo1_tlast, zpui1_tvalid, zpuo1_tvalid, zpui1_tready, zpuo1_tready;

   /*******************************************************************
    * AXI Stream carrying IP/UDP packets to/from Ethernet MAC's
    *******************************************************************/
   wire [63:0]      eth0_rx_tdata, eth0_tx_tdata;
   wire [3:0]      eth0_rx_tuser, eth0_tx_tuser;
   wire      eth0_rx_tlast, eth0_tx_tlast, eth0_rx_tvalid, eth0_tx_tvalid, eth0_rx_tready, eth0_tx_tready;
`ifdef ETH1G_PORT1
   wire [63:0]      eth1_rx_tdata, eth1_tx_tdata;
   wire [3:0]      eth1_rx_tuser, eth1_tx_tuser;
   wire      eth1_rx_tlast, eth1_tx_tlast, eth1_rx_tvalid, eth1_tx_tvalid, eth1_rx_tready, eth1_tx_tready;
`endif

   /*******************************************************************
    * PPS Timing stuff
    ******************************************************************/
   reg [1:0]       int_pps_del, ext_pps_del;
   always @(posedge radio_clk) ext_pps_del[1:0] <= {ext_pps_del[0], pps_ext};
   always @(posedge radio_clk) int_pps_del[1:0] <= {int_pps_del[0], pps_int};
   wire       pps_select;
   wire       pps = pps_select? ext_pps_del[1] : int_pps_del[1];

   /*******************************************************************
    * Instrumentation
    ******************************************************************/
   wire [63:0]       ingress_time_diff1, ingress_time_diff2;
   wire [63:0]       egress_time_diff1, egress_time_diff2;

   /*******************************************************************
    * Response mux Routing logic
    ******************************************************************/
   wire [63:0]       r0_resp_tdata; wire r0_resp_tlast, r0_resp_tvalid, r0_resp_tready;
   wire [63:0]       r1_resp_tdata; wire r1_resp_tlast, r1_resp_tvalid, r1_resp_tready;
   wire [63:0]       u0_resp_tdata; wire u0_resp_tlast, u0_resp_tvalid, u0_resp_tready;
   wire [63:0]       l0_resp_tdata; wire l0_resp_tlast, l0_resp_tvalid, l0_resp_tready;

   axi_mux4 #(.WIDTH(64), .BUFFER(1)) mux_for_resp
     (.clk(bus_clk), .reset(bus_rst), .clear(1'b0),
      .i0_tdata(r0_resp_tdata), .i0_tlast(r0_resp_tlast), .i0_tvalid(r0_resp_tvalid), .i0_tready(r0_resp_tready),
      .i1_tdata(r1_resp_tdata), .i1_tlast(r1_resp_tlast), .i1_tvalid(r1_resp_tvalid), .i1_tready(r1_resp_tready),
      .i2_tdata(u0_resp_tdata), .i2_tlast(u0_resp_tlast), .i2_tvalid(u0_resp_tvalid), .i2_tready(u0_resp_tready),
      .i3_tdata(l0_resp_tdata), .i3_tlast(l0_resp_tlast), .i3_tvalid(l0_resp_tvalid), .i3_tready(l0_resp_tready),
      .o_tdata(resp_tdata), .o_tlast(resp_tlast), .o_tvalid(resp_tvalid), .o_tready(resp_tready));

   /*******************************************************************
    * Control demux Routing logic
    ******************************************************************/
   wire [63:0]       r0_ctrl_tdata; wire r0_ctrl_tlast, r0_ctrl_tvalid, r0_ctrl_tready;
   wire [63:0]       r1_ctrl_tdata; wire r1_ctrl_tlast, r1_ctrl_tvalid, r1_ctrl_tready;
   wire [63:0]       u0_ctrl_tdata; wire u0_ctrl_tlast, u0_ctrl_tvalid, u0_ctrl_tready;
   wire [63:0]       l0_ctrl_tdata; wire l0_ctrl_tlast, l0_ctrl_tvalid, l0_ctrl_tready;

   wire [63:0]       ctrl_hdr;
   wire [1:0]       ctrl_dst =
         ((ctrl_hdr[7:0] & DEMUX_SID_MASK) == R0_CTRL_SID)? 0 :
         (
          ((ctrl_hdr[7:0] & DEMUX_SID_MASK) == R1_CTRL_SID)? 1 :
          (
           ((ctrl_hdr[7:0] & DEMUX_SID_MASK) == U0_CTRL_SID)? 2 :
           (
            ((ctrl_hdr[7:0] & DEMUX_SID_MASK) == L0_CTRL_SID)? 3 :
            (
             3))));

   axi_demux4 #(.ACTIVE_CHAN(4'b1111), .WIDTH(64), .BUFFER(1)) demux_for_ctrl
     (.clk(bus_clk), .reset(bus_rst), .clear(1'b0),
      .header(ctrl_hdr), .dest(ctrl_dst),
      .i_tdata(ctrl_tdata), .i_tlast(ctrl_tlast), .i_tvalid(ctrl_tvalid), .i_tready(ctrl_tready),
      .o0_tdata(r0_ctrl_tdata), .o0_tlast(r0_ctrl_tlast), .o0_tvalid(r0_ctrl_tvalid), .o0_tready(r0_ctrl_tready),
      .o1_tdata(r1_ctrl_tdata), .o1_tlast(r1_ctrl_tlast), .o1_tvalid(r1_ctrl_tvalid), .o1_tready(r1_ctrl_tready),
      .o2_tdata(u0_ctrl_tdata), .o2_tlast(u0_ctrl_tlast), .o2_tvalid(u0_ctrl_tvalid), .o2_tready(u0_ctrl_tready),
      .o3_tdata(l0_ctrl_tdata), .o3_tlast(l0_ctrl_tlast), .o3_tvalid(l0_ctrl_tvalid), .o3_tready(l0_ctrl_tready));

   /*******************************************************************
    * GPSDO UART
    ******************************************************************/
   wire [63:0]       u0i_ctrl_tdata; wire u0i_ctrl_tlast, u0i_ctrl_tvalid, u0i_ctrl_tready;

   axi_fifo #(.WIDTH(65), .SIZE(0)) uart_timing_fifo
     (
      .clk(bus_clk), .reset(bus_rst), .clear(1'b0),
      .i_tdata({u0_ctrl_tlast, u0_ctrl_tdata}), .i_tvalid(u0_ctrl_tvalid), .i_tready(u0_ctrl_tready), .space(),
      .o_tdata({u0i_ctrl_tlast, u0i_ctrl_tdata}), .o_tvalid(u0i_ctrl_tvalid), .o_tready(u0i_ctrl_tready), .occupied()
      );

   cvita_uart #(.SIZE(7)) gpsdo_uart
     (
      .clk(bus_clk), .rst(bus_rst), .rxd(gpsdo_rxd), .txd(gpsdo_txd),
      .i_tdata(u0i_ctrl_tdata), .i_tlast(u0i_ctrl_tlast), .i_tvalid(u0i_ctrl_tvalid), .i_tready(u0i_ctrl_tready),
      .o_tdata(u0_resp_tdata), .o_tlast(u0_resp_tlast), .o_tvalid(u0_resp_tvalid), .o_tready(u0_resp_tready)
      );

   /*******************************************************************
    * Misc controls
    ******************************************************************/
   wire       set_stb;
   wire [7:0]       set_addr;
   wire [31:0]       set_data;

   wire       set_zpu_stb;
   wire [7:0]       set_zpu_addr;
   wire [31:0]       set_zpu_data;

   wire       spi_ready;
   wire [31:0]       spi_readback;

   wire [7:0]       gpsdo_st;
   wire [7:0]       radio_st;

   wire [2:0]       rb_addr;
   reg [63:0]       rb_data;

   wire       loopback;

   wire [63:0]       l0i_ctrl_tdata; wire l0i_ctrl_tlast, l0i_ctrl_tvalid, l0i_ctrl_tready;

   axi_fifo #(.WIDTH(65), .SIZE(0)) radio_ctrl_proc_timing_fifo
     (
      .clk(bus_clk), .reset(bus_rst), .clear(1'b0),
      .i_tdata({l0_ctrl_tlast, l0_ctrl_tdata}), .i_tvalid(l0_ctrl_tvalid), .i_tready(l0_ctrl_tready), .space(),
      .o_tdata({l0i_ctrl_tlast, l0i_ctrl_tdata}), .o_tvalid(l0i_ctrl_tvalid), .o_tready(l0i_ctrl_tready), .occupied()
      );

   radio_ctrl_proc radio_ctrl_proc
     (.clk(bus_clk), .reset(bus_rst), .clear(1'b0),
      .ctrl_tdata(l0i_ctrl_tdata), .ctrl_tlast(l0i_ctrl_tlast), .ctrl_tvalid(l0i_ctrl_tvalid), .ctrl_tready(l0i_ctrl_tready),
      .resp_tdata(l0_resp_tdata), .resp_tlast(l0_resp_tlast), .resp_tvalid(l0_resp_tvalid), .resp_tready(l0_resp_tready),
      .vita_time(64'b0),
      .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
      .ready(spi_ready), .readback(rb_data),
      .debug());

   setting_reg #(.my_addr(SR_CORE_LOOPBACK), .awidth(8), .width(1)) sr_loopback
     (.clk(bus_clk), .rst(bus_rst), .strobe(set_stb), .addr(set_addr), .in(set_data),
      .out(loopback), .changed());

   setting_reg #(.my_addr(SR_CORE_MISC), .awidth(8), .width(32), .at_reset(8'h0)) sr_misc
     (.clk(bus_clk), .rst(bus_rst), .strobe(set_stb), .addr(set_addr), .in(set_data),
      .out(misc_outs), .changed());

   setting_reg #(.my_addr(SR_CORE_DATA_DELAY), .awidth(8), .width(5), .at_reset(5'd0)) sr_data_delay
     (.clk(bus_clk), .rst(bus_rst), .strobe(set_stb), .addr(set_addr), .in(set_data),
      .out(ctrl_data_delay), .changed(ctrl_ld_data_delay));

   setting_reg #(.my_addr(SR_CORE_CLK_DELAY), .awidth(8), .width(5), .at_reset(5'd16)) sr_clk_delay
     (.clk(bus_clk), .rst(bus_rst), .strobe(set_stb), .addr(set_addr), .in(set_data),
      .out(ctrl_clk_delay), .changed(ctrl_ld_clk_delay));

   setting_reg #(.my_addr(SR_CORE_RADIO_CONTROL), .awidth(8), .width(3), .at_reset(3'd0)) sr_radio_contol
     (.clk(bus_clk), .rst(bus_rst), .strobe(set_stb), .addr(set_addr), .in(set_data),
      .out(radio_control), .changed());

   setting_reg #(.my_addr(SR_CORE_READBACK), .awidth(8), .width(3)) sr_rdback
     (.clk(bus_clk), .rst(bus_rst), .strobe(set_stb), .addr(set_addr), .in(set_data),
      .out(rb_addr), .changed());

   setting_reg #(.my_addr(SR_CORE_GPSDO_ST), .awidth(8), .width(8)) sr_gpsdo_st
     (.clk(bus_clk), .rst(1'b0/*keep*/), .strobe(set_stb), .addr(set_addr), .in(set_data),
      .out(gpsdo_st), .changed());

   setting_reg #(.my_addr(SR_CORE_PPS_SEL), .awidth(8), .width(1)) sr_pps_sel
     (.clk(bus_clk), .rst(bus_rst), .strobe(set_stb), .addr(set_addr), .in(set_data),
      .out(pps_select), .changed());

   simple_spi_core #(.BASE(SR_CORE_SPI), .WIDTH(8), .CLK_IDLE(0), .SEN_IDLE(8'hFF)) misc_spi
     (.clock(bus_clk), .reset(bus_rst),
      .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
      .readback(spi_readback), .ready(spi_ready),
      .sen(sen), .sclk(sclk), .mosi(mosi), .miso(miso),
      .debug());

   //
   // Readback Mux
   //

   always @*
     case(rb_addr)
       // PRODUCT ID
       RB_CORE_SIGNATURE : rb_data <= { 32'hACE0BA5E, PRODUCT_ID, COMPAT_MAJOR, COMPAT_MINOR };
       // SPI READ
       RB_CORE_SPI : rb_data <= { 32'b0, spi_readback };
       //
       RB_CORE_STATUS : rb_data <= { 16'b0, radio_st, gpsdo_st, rb_misc };
       // BIST
       RB_CORE_BIST : rb_data <= {62'h0, extfifo_bist_error, extfifo_bist_done};
       // GIT HASH of RTL Source
       // [31:28] = 0xf - Unclean build
       // [27:0] - Abrieviated git hash for RTL.
       RB_CORE_GIT_HASH : rb_data <= {32'h0,32'h`GIT_HASH};


       default : rb_data <= 64'd0;
     endcase // case (rb_addr)

   /*******************************************************************
    * RX Data mux Routing logic
    ******************************************************************/
   wire [63:0]       r0_rx_tdata; wire r0_rx_tlast, r0_rx_tvalid, r0_rx_tready;
   wire [63:0]       r1_rx_tdata; wire r1_rx_tlast, r1_rx_tvalid, r1_rx_tready;
   wire [63:0]       rx_tdata_int; wire rx_tlast_int, rx_tvalid_int, rx_tready_int;

   axi_mux4 #(.WIDTH(64), .BUFFER(1)) mux_for_rx
     (.clk(bus_clk), .reset(bus_rst), .clear(1'b0),
      .i0_tdata(r0_rx_tdata), .i0_tlast(r0_rx_tlast), .i0_tvalid(r0_rx_tvalid), .i0_tready(r0_rx_tready),
      .i1_tdata(r1_rx_tdata), .i1_tlast(r1_rx_tlast), .i1_tvalid(r1_rx_tvalid), .i1_tready(r1_rx_tready),
      /*******************************************************************
       * Merge RX Response and RX Data streams.
       * Replace this later with slimmed down X-Bar
       ******************************************************************/
      .i2_tdata(resp_tdata), .i2_tlast(resp_tlast), .i2_tvalid(resp_tvalid), .i2_tready(resp_tready),
      .i3_tdata(64'b0), .i3_tlast(1'b0), .i3_tvalid(1'b0), .i3_tready(),
      .o_tdata(rx_tdata_int), .o_tlast(rx_tlast_int), .o_tvalid(rx_tvalid_int), .o_tready(rx_tready_int));

   axi_fifo #(.WIDTH(65), .SIZE(EXTRA_RX_BUFF_SIZE)) extra_rx_buff
     (.clk(bus_clk), .reset(bus_rst), .clear(1'b0),
      .i_tdata({rx_tlast_int, rx_tdata_int}), .i_tvalid(rx_tvalid_int), .i_tready(rx_tready_int),
      .o_tdata({rx_tlast, rx_tdata}), .o_tvalid(rx_tvalid), .o_tready(rx_tready),
      .space(),.occupied());

   assign v2e0_tdata = rx_tdata;
   assign v2e0_tlast = rx_tlast;
   assign v2e0_tvalid = rx_tvalid;
   assign rx_tready = v2e0_tready;

   /*******************************************************************
    * TX CTRL and Data de-mux Routing logic -
    *   Replace this logic when X300 radio replaces B200 radio.
    ******************************************************************/

   wire [63:0]       tx_ctrl_hdr;
   wire [1:0]       tx_ctrl_dst =
         (((tx_ctrl_hdr[7:0] & DEMUX_SID_MASK) == R0_DATA_SID) | ((tx_ctrl_hdr[7:0] & DEMUX_SID_MASK) == R1_DATA_SID)) ? 1
         : 0; // Default all non-CTRL Traffic to EXT FIFO ...sloppy but quick.
   axi_demux4 #(.ACTIVE_CHAN(4'b0011), .WIDTH(64), .BUFFER(1)) demux_for_tx_ctrl
     (.clk(bus_clk), .reset(bus_rst), .clear(1'b0),
      .header(tx_ctrl_hdr), .dest(tx_ctrl_dst),
      .i_tdata(e2v0_tdata), .i_tlast(e2v0_tlast), .i_tvalid(e2v0_tvalid), .i_tready(e2v0_tready),
      .o0_tdata(ctrl_tdata), .o0_tlast(ctrl_tlast), .o0_tvalid(ctrl_tvalid), .o0_tready(ctrl_tready),
      .o1_tdata(o_tdata_extfifo), .o1_tlast(o_tlast_extfifo), .o1_tvalid(o_tvalid_extfifo), .o1_tready(o_tready_extfifo),
      .o2_tdata(), .o2_tlast(), .o2_tvalid(), .o2_tready(1'b1),
      .o3_tdata(), .o3_tlast(), .o3_tvalid(), .o3_tready(1'b1));

   /*******************************************************************
    * TX Data mux Routing logic
    ******************************************************************/
   wire [63:0]       r0_tx_tdata; wire r0_tx_tlast, r0_tx_tvalid, r0_tx_tready;
   wire [63:0]       r1_tx_tdata; wire r1_tx_tlast, r1_tx_tvalid, r1_tx_tready;

   wire [63:0]       tx_hdr;
   wire [1:0]       tx_dst =
         ((tx_hdr[7:0] & DEMUX_SID_MASK) == R0_DATA_SID) ? 0
         : (((tx_hdr[7:0] & DEMUX_SID_MASK) == R1_DATA_SID) ? 1
            : (3));
   axi_demux4 #(.ACTIVE_CHAN(4'b0011), .WIDTH(64), .BUFFER(1)) demux_for_tx
     (.clk(bus_clk), .reset(bus_rst), .clear(1'b0),
      .header(tx_hdr), .dest(tx_dst),
      .i_tdata(i_tdata_extfifo), .i_tlast(i_tlast_extfifo), .i_tvalid(i_tvalid_extfifo), .i_tready(i_tready_extfifo),
      .o0_tdata(r0_tx_tdata), .o0_tlast(r0_tx_tlast), .o0_tvalid(r0_tx_tvalid), .o0_tready(r0_tx_tready),
      .o1_tdata(r1_tx_tdata), .o1_tlast(r1_tx_tlast), .o1_tvalid(r1_tx_tvalid), .o1_tready(r1_tx_tready),
      .o2_tdata(), .o2_tlast(), .o2_tvalid(), .o2_tready(1'b1),
      .o3_tdata(), .o3_tlast(), .o3_tvalid(), .o3_tready(1'b1));

   /*******************************************************************
    * Radio 0
    ******************************************************************/
   wire [63:0]       radio0_debug;
   reg [31:0]       rx0_post_loop;

   // IJB. Note that loopback signal comes from bus_clk. Better to do the loopback entirely inside radio_legacy in radio_clk
   always @(posedge radio_clk)
      rx0_post_loop <= loopback ? tx0 : rx0;

   radio_legacy #(
      .RADIO_FIFO_SIZE(RADIO_FIFO_SIZE), .SAMPLE_FIFO_SIZE(SAMPLE_FIFO_SIZE),
      .NEW_HB_INTERP(1),
      .SOURCE_FLOW_CONTROL(1),
      .USER_SETTINGS(1),
      .DEVICE("7SERIES")
   ) radio_0 (
      .radio_clk(radio_clk), .radio_rst(radio_rst),
      .rx(rx0_post_loop), .tx(tx0),
      .pps(pps), .time_sync(time_sync_r),
      .fe_gpio_in(32'h00000000), .fe_gpio_out(fe_atr0), .fe_gpio_ddr(/* Always assumed to be outputs */),
      .fp_gpio_in(32'h00000000), .fp_gpio_out(), .fp_gpio_ddr(),

      .bus_clk(bus_clk), .bus_rst(bus_rst),
      .tx_tdata(r0_tx_tdata), .tx_tlast(r0_tx_tlast), .tx_tvalid(r0_tx_tvalid), .tx_tready(r0_tx_tready),
      .rx_tdata(r0_rx_tdata), .rx_tlast(r0_rx_tlast),  .rx_tvalid(r0_rx_tvalid), .rx_tready(r0_rx_tready),
      .ctrl_tdata(r0_ctrl_tdata), .ctrl_tlast(r0_ctrl_tlast),  .ctrl_tvalid(r0_ctrl_tvalid), .ctrl_tready(r0_ctrl_tready),
      .resp_tdata(r0_resp_tdata), .resp_tlast(r0_resp_tlast),  .resp_tvalid(r0_resp_tvalid), .resp_tready(r0_resp_tready),

      .debug(radio0_debug)
   );

   /*******************************************************************
    * Radio 1
    ******************************************************************/
   assign       radio_st = 8'h2;
   reg [31:0]       rx1_post_loop;

   always @(posedge radio_clk)
     rx1_post_loop <= loopback ? tx1 : rx1;

   radio_legacy #(
      .RADIO_FIFO_SIZE(RADIO_FIFO_SIZE), .SAMPLE_FIFO_SIZE(SAMPLE_FIFO_SIZE),
      .NEW_HB_INTERP(1),
      .SOURCE_FLOW_CONTROL(1),
      .USER_SETTINGS(1),
      .DEVICE("7SERIES")
   ) radio_1 (
      .radio_clk(radio_clk), .radio_rst(radio_rst),
      .rx(rx1_post_loop), .tx(tx1),
      .pps(pps), .time_sync(time_sync_r),
      .fe_gpio_in(32'h00000000), .fe_gpio_out(fe_atr1), .fe_gpio_ddr(/* Always assumed to be outputs */),
      .fp_gpio_in(32'h00000000), .fp_gpio_out(), .fp_gpio_ddr(),

      .bus_clk(bus_clk), .bus_rst(bus_rst),
      .tx_tdata(r1_tx_tdata), .tx_tlast(r1_tx_tlast), .tx_tvalid(r1_tx_tvalid), .tx_tready(r1_tx_tready),
      .rx_tdata(r1_rx_tdata), .rx_tlast(r1_rx_tlast),  .rx_tvalid(r1_rx_tvalid), .rx_tready(r1_rx_tready),
      .ctrl_tdata(r1_ctrl_tdata), .ctrl_tlast(r1_ctrl_tlast),  .ctrl_tvalid(r1_ctrl_tvalid), .ctrl_tready(r1_ctrl_tready),
      .resp_tdata(r1_resp_tdata), .resp_tlast(r1_resp_tlast),  .resp_tvalid(r1_resp_tvalid), .resp_tready(r1_resp_tready),

      .debug()
   );

   /*******************************************************************
    * Complete ZPU subsystem with RAM and peripherals
    ******************************************************************/

   zpu_subsystem #(
      .SB_ADDRW(8),
      .RB_ADDRW(8),
      .DW(32),    // Data bus width
      .AW (16),   // Address bus width
      .SW (4)     // Select width -- 32-bit data bus with 8-bit granularity.
   ) zpu_subsystem_i0 (
      //------------------------------------------------------------------
      // Clocks and Resets
      //------------------------------------------------------------------
      .clk(bus_clk),
      .rst(bus_rst),
      //------------------------------------------------------------------
      // packet interface in
      //------------------------------------------------------------------
      .zpui_tdata(zpui_tdata),
      .zpui_tuser(zpui_tuser),
      .zpui_tlast(zpui_tlast),
      .zpui_tvalid(zpui_tvalid),
      .zpui_tready(zpui_tready),
      //------------------------------------------------------------------
      // packet interface out
      //------------------------------------------------------------------
      .zpuo_tdata(zpuo_tdata),
      .zpuo_tuser(zpuo_tuser),
      .zpuo_tlast(zpuo_tlast),
      .zpuo_tvalid(zpuo_tvalid),
      .zpuo_tready(zpuo_tready),
      //------------------------------------------------------------------
      // settings bus interface
      //------------------------------------------------------------------
      .set_data(set_zpu_data),
      .set_addr(set_zpu_addr),
      .set_stb(set_zpu_stb),
      //------------------------------------------------------------------
      // SFP flags
      //------------------------------------------------------------------
      .SFP0_ModAbs(SFP0_ModAbs),
      .SFP0_TxFault(SFP0_TxFault),
      .SFP0_RxLOS(SFP0_RxLOS),
      .SFP0_RS0(SFP0_RS0),
      .SFP0_RS1(SFP0_RS1),
      .SFP1_ModAbs(SFP1_ModAbs),
      .SFP1_TxFault(SFP1_TxFault),
      .SFP1_RxLOS(SFP1_RxLOS),
      .SFP1_RS0(SFP1_RS0),
      .SFP1_RS1(SFP1_RS1),
      //------------------------------------------------------------------
      // GMII interface 0 to PHY
      //------------------------------------------------------------------
      .gmii_clk0(gmii_clk0),
      .gmii_txd0(gmii_txd0),
      .gmii_tx_en0(gmii_tx_en0),
      .gmii_tx_er0(gmii_tx_er0),
      .gmii_rxd0(gmii_rxd0),
      .gmii_rx_dv0(gmii_rx_dv0),
      .gmii_rx_er0(gmii_rx_er0),
      .gmii_status0(gmii_status0),
      .mdc0(mdc0),
      .mdio_in0(mdio_in0),
      .mdio_out0(mdio_out0),
      //------------------------------------------------------------------
      // GMII interface 1 to PHY
      //------------------------------------------------------------------
      .gmii_clk1(gmii_clk1),
      .gmii_txd1(gmii_txd1),
      .gmii_tx_en1(gmii_tx_en1),
      .gmii_tx_er1(gmii_tx_er1),
      .gmii_rxd1(gmii_rxd1),
      .gmii_rx_dv1(gmii_rx_dv1),
      .gmii_rx_er1(gmii_rx_er1),
      .gmii_status1(gmii_status1),
      .mdc1(mdc1),
      .mdio_in1(mdio_in1),
      .mdio_out1(mdio_out1),
      //------------------------------------------------------------------
      // ETH0 streaming interfaces
      //------------------------------------------------------------------
      .eth0_tx_tdata(eth0_tx_tdata),
      .eth0_tx_tuser(eth0_tx_tuser),
      .eth0_tx_tlast(eth0_tx_tlast),
      .eth0_tx_tvalid(eth0_tx_tvalid),
      .eth0_tx_tready(eth0_tx_tready),
      .eth0_rx_tdata(eth0_rx_tdata),
      .eth0_rx_tuser(eth0_rx_tuser),
      .eth0_rx_tlast(eth0_rx_tlast),
      .eth0_rx_tvalid(eth0_rx_tvalid),
      .eth0_rx_tready(eth0_rx_tready),
      //------------------------------------------------------------------
      // ETH1 streaming interfaces
      //------------------------------------------------------------------
      `ifdef ETH1G_PORT1
      .eth1_tx_tdata(eth1_tx_tdata),
      .eth1_tx_tuser(eth1_tx_tuser),
      .eth1_tx_tlast(eth1_tx_tlast),
      .eth1_tx_tvalid(eth1_tx_tvalid),
      .eth1_tx_tready(eth1_tx_tready),
      .eth1_rx_tdata(eth1_rx_tdata),
      .eth1_rx_tuser(eth1_rx_tuser),
      .eth1_rx_tlast(eth1_rx_tlast),
      .eth1_rx_tvalid(eth1_rx_tvalid),
      .eth1_rx_tready(eth1_rx_tready),
      `endif //  `ifdef ETH1G_PORT1
      //------------------------------------------------------------------
      // UARTs
      //------------------------------------------------------------------
      .debug_rxd(debug_rxd),
      .debug_txd(debug_txd),
      //------------------------------------------------------------------
      // UARTs
      //------------------------------------------------------------------
      .spiflash_cs(spiflash_cs),
      .spiflash_clk(spiflash_clk),
      .spiflash_miso(spiflash_miso),
      .spiflash_mosi(spiflash_mosi),
      //------------------------------------------------------------------
      // I2C
      //------------------------------------------------------------------
      .scl0(SFP0_SCL), //TODO - FOR SFP's
      .sda0(SFP0_SDA),
      .scl1(SFP1_SCL),
      .sda1(SFP1_SDA),
      //------------------------------------------------------------------
      // Misc
      //------------------------------------------------------------------
      .sw_rst(sw_rst),
      .leds(leds),
      //------------------------------------------------------------------
      // Production test signals
      //------------------------------------------------------------------
 `ifdef TEST_JESD204_IF
      .jesd204_test_run(jesd204_test_run),
      .jesd204_test_done(jesd204_test_done),
      .jesd204_test_status(jesd204_test_status),
 `endif
      //------------------------------------------------------------------
      // Debug
      //------------------------------------------------------------------
      .debug(debug)
   );


   //------------------------------------------------------------------
   // Packet processing for Ethernet/IP/UDP/CHDR framed packets.
   //------------------------------------------------------------------
   wire [63:0]      e01_tdata, e10_tdata;
   wire [3:0]      e01_tuser, e10_tuser;
   wire      e01_tlast, e01_tvalid, e01_tready;
   wire      e10_tlast, e10_tvalid, e10_tready;

   eth_interface #(.BASE(SR_ZPU_ETHINT0)) eth_interface0
     (.clk(bus_clk), .reset(bus_rst), .clear(1'b0),
      .set_stb(set_zpu_stb), .set_addr(set_zpu_addr), .set_data(set_zpu_data),
      .eth_tx_tdata(eth0_tx_tdata), .eth_tx_tuser(eth0_tx_tuser), .eth_tx_tlast(eth0_tx_tlast),
      .eth_tx_tvalid(eth0_tx_tvalid), .eth_tx_tready(eth0_tx_tready),
      .eth_rx_tdata(eth0_rx_tdata), .eth_rx_tuser(eth0_rx_tuser), .eth_rx_tlast(eth0_rx_tlast),
      .eth_rx_tvalid(eth0_rx_tvalid), .eth_rx_tready(eth0_rx_tready),
      .e2v_tdata(e2v0_tdata), .e2v_tlast(e2v0_tlast), .e2v_tvalid(e2v0_tvalid), .e2v_tready(e2v0_tready),
      .v2e_tdata(v2e0_tdata), .v2e_tlast(v2e0_tlast), .v2e_tvalid(v2e0_tvalid), .v2e_tready(v2e0_tready),
      .xo_tdata(e01_tdata), .xo_tuser(e01_tuser), .xo_tlast(e01_tlast), .xo_tvalid(e01_tvalid), .xo_tready(e01_tready),
      .xi_tdata(e10_tdata), .xi_tuser(e10_tuser), .xi_tlast(e10_tlast), .xi_tvalid(e10_tvalid), .xi_tready(e10_tready),
      .e2z_tdata(zpui0_tdata), .e2z_tuser(zpui0_tuser), .e2z_tlast(zpui0_tlast), .e2z_tvalid(zpui0_tvalid), .e2z_tready(zpui0_tready),
      .z2e_tdata(zpuo0_tdata), .z2e_tuser(zpuo0_tuser), .z2e_tlast(zpuo0_tlast), .z2e_tvalid(zpuo0_tvalid), .z2e_tready(zpuo0_tready),
      .debug());

   eth_interface #(.BASE(SR_ZPU_ETHINT1)) eth_interface1
     (.clk(bus_clk), .reset(bus_rst), .clear(1'b0),
      .set_stb(set_zpu_stb), .set_addr(set_zpu_addr), .set_data(set_zpu_data),
      .eth_tx_tdata(eth1_tx_tdata), .eth_tx_tuser(eth1_tx_tuser), .eth_tx_tlast(eth1_tx_tlast),
      .eth_tx_tvalid(eth1_tx_tvalid), .eth_tx_tready(eth1_tx_tready),
      .eth_rx_tdata(eth1_rx_tdata), .eth_rx_tuser(eth1_rx_tuser), .eth_rx_tlast(eth1_rx_tlast),
      .eth_rx_tvalid(eth1_rx_tvalid), .eth_rx_tready(eth1_rx_tready),
      .e2v_tdata(e2v1_tdata), .e2v_tlast(e2v1_tlast), .e2v_tvalid(e2v1_tvalid), .e2v_tready(e2v1_tready),
      .v2e_tdata(v2e1_tdata), .v2e_tlast(v2e1_tlast), .v2e_tvalid(v2e1_tvalid), .v2e_tready(v2e1_tready),
      .xo_tdata(e10_tdata), .xo_tuser(e10_tuser), .xo_tlast(e10_tlast), .xo_tvalid(e10_tvalid), .xo_tready(e10_tready),
      .xi_tdata(e01_tdata), .xi_tuser(e01_tuser), .xi_tlast(e01_tlast), .xi_tvalid(e01_tvalid), .xi_tready(e01_tready),
      .e2z_tdata(zpui1_tdata), .e2z_tuser(zpui1_tuser), .e2z_tlast(zpui1_tlast), .e2z_tvalid(zpui1_tvalid), .e2z_tready(zpui1_tready),
      .z2e_tdata(zpuo1_tdata), .z2e_tuser(zpuo1_tuser), .z2e_tlast(zpuo1_tlast), .z2e_tvalid(zpuo1_tvalid), .z2e_tready(zpuo1_tready),
      .debug());

   //------------------------------------------------------------------
   // Mux packets from either Eth interface to the ZPU
   //------------------------------------------------------------------
    axi_mux4 #(.PRIO(0), .WIDTH(68)) zpui_mux
     (.clk(bus_clk), .reset(bus_rst), .clear(1'b0),
      .i0_tdata({zpui0_tuser,zpui0_tdata}), .i0_tlast(zpui0_tlast), .i0_tvalid(zpui0_tvalid), .i0_tready(zpui0_tready),
      .i1_tdata({zpui1_tuser,zpui1_tdata}), .i1_tlast(zpui1_tlast), .i1_tvalid(zpui1_tvalid), .i1_tready(zpui1_tready),
      .i2_tdata(68'h0), .i2_tlast(1'b0), .i2_tvalid(1'b0), .i2_tready(),
      .i3_tdata(68'h0), .i3_tlast(1'b0), .i3_tvalid(1'b0), .i3_tready(),
      .o_tdata({zpui_tuser,zpui_tdata}), .o_tlast(zpui_tlast), .o_tvalid(zpui_tvalid), .o_tready(zpui_tready));

   //------------------------------------------------------------------
   // Demux ZPU to Eth output by the port number in top 8 bits of data on first line
   //------------------------------------------------------------------
   wire [67:0]      zpuo_eth_header;
   wire [1:0]      zpuo_eth_dest = (zpuo_eth_header[63:56] == 8'd0) ? 2'b00 : 2'b01;

   axi_demux4 #(.ACTIVE_CHAN(4'b0011), .WIDTH(68)) zpuo_demux
     (.clk(bus_clk), .reset(bus_rst), .clear(1'b0),
      .header(zpuo_eth_header), .dest(zpuo_eth_dest),
      .i_tdata({zpuo_tuser,zpuo_tdata}), .i_tlast(zpuo_tlast), .i_tvalid(zpuo_tvalid), .i_tready(zpuo_tready),
      .o0_tdata({zpuo0_tuser,zpuo0_tdata}), .o0_tlast(zpuo0_tlast), .o0_tvalid(zpuo0_tvalid), .o0_tready(zpuo0_tready),
      .o1_tdata({zpuo1_tuser,zpuo1_tdata}), .o1_tlast(zpuo1_tlast), .o1_tvalid(zpuo1_tvalid), .o1_tready(zpuo1_tready),
      .o2_tdata(), .o2_tlast(), .o2_tvalid(), .o2_tready(1'b1),
      .o3_tdata(), .o3_tlast(), .o3_tvalid(), .o3_tready(1'b1));

endmodule
