//
// Copyright 2014 Ettus Research LLC
//

module zpu_subsystem #(
   parameter SB_ADDRW   = 8,
   parameter RB_ADDRW   = 8,
   parameter DW         = 32,  // Data bus width
   parameter AW         = 16,  // Address bus width, for byte addressibility, 16 = 64K byte memory space
   parameter SW         = 4    // Select width -- 32-bit data bus with 8-bit granularity.
) (
   //------------------------------------------------------------------
   // Clocks and Resets
   //------------------------------------------------------------------
   input clk,
   input rst,

   //------------------------------------------------------------------
   // packet interface in
   //------------------------------------------------------------------
   input [63:0] zpui_tdata,
   input [3:0] zpui_tuser,
   input zpui_tlast,
   input zpui_tvalid,
   output zpui_tready,

   //------------------------------------------------------------------
   // packet interface out
   //------------------------------------------------------------------
   output [63:0] zpuo_tdata,
   output [3:0] zpuo_tuser,
   output zpuo_tlast,
   output zpuo_tvalid,
   input zpuo_tready,

   //------------------------------------------------------------------
   // settings bus interface
   //------------------------------------------------------------------
   output [31:0] set_data,
   output [SB_ADDRW-1:0] set_addr,
   output set_stb,

   //------------------------------------------------------------------
   // settings bus interface for crossbar router
   //------------------------------------------------------------------
   output [31:0] set_data_xb,
   output [8:0] set_addr_xb,
   output set_stb_xb,

   //------------------------------------------------------------------
   // SFP FLags
   //------------------------------------------------------------------
   input SFP0_ModAbs,
   input SFP0_TxFault,
   input SFP0_RxLOS,
   inout SFP0_RS0,
   inout SFP0_RS1,
   // Leave these pins in for single ethernet varient so that SFP1
   // still has a sane electrical enviroment.
   input SFP1_ModAbs,
   input SFP1_TxFault,
   input SFP1_RxLOS,
   inout SFP1_RS0,
   inout SFP1_RS1,
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
   // GMII interface 0 to PHY
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
   // ETH0 streaming interfaces
   //------------------------------------------------------------------
   input [63:0] eth0_tx_tdata,
   input [3:0] eth0_tx_tuser,
   input eth0_tx_tlast,
   input eth0_tx_tvalid,
   output eth0_tx_tready,
   output [63:0] eth0_rx_tdata,
   output [3:0] eth0_rx_tuser,
   output eth0_rx_tlast,
   output eth0_rx_tvalid,
   input eth0_rx_tready,

   //------------------------------------------------------------------
   // ETH1 streaming interfaces
   //------------------------------------------------------------------
   input [63:0] eth1_tx_tdata,
   input [3:0] eth1_tx_tuser,
   input eth1_tx_tlast,
   input eth1_tx_tvalid,
   output eth1_tx_tready,
   output [63:0] eth1_rx_tdata,
   output [3:0] eth1_rx_tuser,
   output eth1_rx_tlast,
   output eth1_rx_tvalid,
   input eth1_rx_tready,
   //------------------------------------------------------------------
   // UARTs
   //------------------------------------------------------------------
   input debug_rxd,
   output debug_txd,

   //------------------------------------------------------------------
   // UARTs
   //------------------------------------------------------------------
   output spiflash_cs,
   output spiflash_clk,
   input spiflash_miso,
   output spiflash_mosi,

   //------------------------------------------------------------------
   // I2C Buses
   //------------------------------------------------------------------
   inout scl0,
   inout sda0,
   inout scl1,
   inout sda1,

   //------------------------------------------------------------------
   // Misc
   //------------------------------------------------------------------
   output [3:0] sw_rst,
   output [15:0] leds,

   //------------------------------------------------------------------
   // Debug
   //------------------------------------------------------------------
   output [31:0] debug
);


   `include "n230_fpga_common.v"

   //------------------------------------------------------------------
   // readback bus interface
   //------------------------------------------------------------------
   reg [31:0]           rb_data;
   wire [RB_ADDRW-1:0]  rb_addr;
   wire                 rb_rd_stb;

   /*******************************************************************
   * SFP Logic
   ******************************************************************/
   reg           SFP0_ModAbs_reg, SFP0_TxFault_reg,SFP0_RxLOS_reg;
   reg           SFP0_ModAbs_reg2, SFP0_TxFault_reg2,SFP0_RxLOS_reg2;
   reg           SFP0_ModAbs_chgd, SFP0_TxFault_chgd, SFP0_RxLOS_chgd;

   reg           SFP1_ModAbs_reg, SFP1_TxFault_reg,SFP1_RxLOS_reg;
   reg           SFP1_ModAbs_reg2, SFP1_TxFault_reg2,SFP1_RxLOS_reg2;
   reg           SFP1_ModAbs_chgd, SFP1_TxFault_chgd, SFP1_RxLOS_chgd;

   //------------------------------------------------------------------
   // WB interconnect - ZPU, RAM, settings...
   //------------------------------------------------------------------

   wire [DW-1:0]  m0_dat_o, m0_dat_i;
   wire [DW-1:0]  s0_dat_o, s1_dat_o, s0_dat_i, s1_dat_i, s2_dat_o, s3_dat_o, s2_dat_i, s3_dat_i,
                  s4_dat_o,s5_dat_o,s4_dat_i,s5_dat_i, s6_dat_o, s7_dat_o, s6_dat_i, s7_dat_i,
                  s8_dat_o, s9_dat_o, s8_dat_i, s9_dat_i, sa_dat_o, sa_dat_i, sb_dat_i, sb_dat_o,
                  sc_dat_i, sc_dat_o, sd_dat_i, sd_dat_o, se_dat_i, se_dat_o, sf_dat_i, sf_dat_o;
   wire [AW-1:0]  m0_adr,s0_adr,s1_adr,s2_adr,s3_adr,s4_adr,s5_adr,s6_adr,s7_adr;
   wire [AW-1:0]  s8_adr,s9_adr,sa_adr,sb_adr,sc_adr,sd_adr,se_adr,sf_adr;
   wire [SW-1:0]  m0_sel,s0_sel,s1_sel,s2_sel,s3_sel,s4_sel,s5_sel,s6_sel,s7_sel;
   wire [SW-1:0]  s8_sel,s9_sel,sa_sel,sb_sel,sc_sel,sd_sel,se_sel,sf_sel;
   wire           m0_ack,s0_ack,s1_ack,s2_ack,s3_ack,s4_ack,s5_ack,s6_ack,s7_ack;
   wire           s8_ack,s9_ack,sa_ack,sb_ack,sc_ack,sd_ack,se_ack,sf_ack;
   wire           m0_stb,s0_stb,s1_stb,s2_stb,s3_stb,s4_stb,s5_stb,s6_stb,s7_stb;
   wire           s8_stb,s9_stb,sa_stb,sb_stb,sc_stb,sd_stb,se_stb,sf_stb;
   wire           m0_cyc,s0_cyc,s1_cyc,s2_cyc,s3_cyc,s4_cyc,s5_cyc,s6_cyc,s7_cyc;
   wire           s8_cyc,s9_cyc,sa_cyc,sb_cyc,sc_cyc,sd_cyc,se_cyc,sf_cyc;
   wire           m0_we,s0_we,s1_we,s2_we,s3_we,s4_we,s5_we,s6_we,s7_we;
   wire           s8_we,s9_we,sa_we,sb_we,sc_we,sd_we,se_we,sf_we;

   wb_1master #(
      .decode_w(8),
      .s0_addr(8'b0000_0000),.s0_mask(8'b1000_0000),  // 0x0000 - Main RAM 32k
      .s1_addr(8'b1000_0000),.s1_mask(8'b1110_0000),  // 0x8000 - PKT RAM 8k
      .s2_addr(8'b1010_0000),.s2_mask(8'b1111_0000),  // 0xa000 - Settings/Readback
      .s3_addr(8'b1011_0000),.s3_mask(8'b1111_0000),  // 0xb000 - SPI Flash
      .s4_addr(8'b1100_0000),.s4_mask(8'b1111_0000),  // 0xc000 - Ethernet MAC0
      .s5_addr(8'b1101_0000),.s5_mask(8'b1111_0000),  // 0xd000 - Ethernet MAC1
      .s6_addr(8'b1111_0110),.s6_mask(8'b1111_1111),  // 0xf600 - I2C0
      .s7_addr(8'b1111_0111),.s7_mask(8'b1111_1111),  // 0xf700 - I2C1
      .s8_addr(8'b1111_1000),.s8_mask(8'b1111_1111),  // 0xf800 - ICAP
      .s9_addr(8'b1111_1001),.s9_mask(8'b1111_1111),  // 0xf900 - UART0 (Debug on GPIO)
      .sa_addr(8'b1111_1010),.sa_mask(8'b1111_1111),  // 0xfa00 - Bootloader
      .sb_addr(8'b1110_0000),.sb_mask(8'b1111_0000),  // 0xe000 - Settings crossbar
      .sc_addr(8'b1111_1100),.sc_mask(8'b1111_1111),  // 0xfc00 - Unused
      .sd_addr(8'b1111_1101),.sd_mask(8'b1111_1111),  // 0xfd00 - Unused
      .se_addr(8'b1111_1110),.se_mask(8'b1111_1111),  // 0xfe00 - Unused
      .sf_addr(8'b1111_1111),.sf_mask(8'b1111_1111),  // 0xff00 - Unused
      .dw(DW),.aw(AW),.sw(SW)
   ) wb_1master (
      .clk_i(clk),.rst_i(rst),
      .m0_dat_o(m0_dat_o),.m0_ack_o(m0_ack),.m0_err_o(),.m0_rty_o(),.m0_dat_i(m0_dat_i),
      .m0_adr_i(m0_adr),.m0_sel_i(m0_sel),.m0_we_i(m0_we),.m0_cyc_i(m0_cyc),.m0_stb_i(m0_stb),
      .s0_dat_o(s0_dat_o),.s0_adr_o(s0_adr),.s0_sel_o(s0_sel),.s0_we_o(s0_we),.s0_cyc_o(s0_cyc),.s0_stb_o(s0_stb),
      .s0_dat_i(s0_dat_i),.s0_ack_i(s0_ack),.s0_err_i(1'b0),.s0_rty_i(1'b0),
      .s1_dat_o(s1_dat_o),.s1_adr_o(s1_adr),.s1_sel_o(s1_sel),.s1_we_o(s1_we),.s1_cyc_o(s1_cyc),.s1_stb_o(s1_stb),
      .s1_dat_i(s1_dat_i),.s1_ack_i(s1_ack),.s1_err_i(1'b0),.s1_rty_i(1'b0),
      .s2_dat_o(s2_dat_o),.s2_adr_o(s2_adr),.s2_sel_o(s2_sel),.s2_we_o(s2_we),.s2_cyc_o(s2_cyc),.s2_stb_o(s2_stb),
      .s2_dat_i(s2_dat_i),.s2_ack_i(s2_ack),.s2_err_i(1'b0),.s2_rty_i(1'b0),
      .s3_dat_o(s3_dat_o),.s3_adr_o(s3_adr),.s3_sel_o(s3_sel),.s3_we_o(s3_we),.s3_cyc_o(s3_cyc),.s3_stb_o(s3_stb),
      .s3_dat_i(s3_dat_i),.s3_ack_i(s3_ack),.s3_err_i(1'b0),.s3_rty_i(1'b0),
      .s4_dat_o(s4_dat_o),.s4_adr_o(s4_adr),.s4_sel_o(s4_sel),.s4_we_o(s4_we),.s4_cyc_o(s4_cyc),.s4_stb_o(s4_stb),
      .s4_dat_i(s4_dat_i),.s4_ack_i(s4_ack),.s4_err_i(1'b0),.s4_rty_i(1'b0),
      .s5_dat_o(s5_dat_o),.s5_adr_o(s5_adr),.s5_sel_o(s5_sel),.s5_we_o(s5_we),.s5_cyc_o(s5_cyc),.s5_stb_o(s5_stb),
      .s5_dat_i(s5_dat_i),.s5_ack_i(s5_ack),.s5_err_i(1'b0),.s5_rty_i(1'b0),
      .s6_dat_o(s6_dat_o),.s6_adr_o(s6_adr),.s6_sel_o(s6_sel),.s6_we_o(s6_we),.s6_cyc_o(s6_cyc),.s6_stb_o(s6_stb),
      .s6_dat_i(s6_dat_i),.s6_ack_i(s6_ack),.s6_err_i(1'b0),.s6_rty_i(1'b0),
      .s7_dat_o(s7_dat_o),.s7_adr_o(s7_adr),.s7_sel_o(s7_sel),.s7_we_o(s7_we),.s7_cyc_o(s7_cyc),.s7_stb_o(s7_stb),
      .s7_dat_i(s7_dat_i),.s7_ack_i(s7_ack),.s7_err_i(1'b0),.s7_rty_i(1'b0),
      .s8_dat_o(s8_dat_o),.s8_adr_o(s8_adr),.s8_sel_o(s8_sel),.s8_we_o(s8_we),.s8_cyc_o(s8_cyc),.s8_stb_o(s8_stb),
      .s8_dat_i(s8_dat_i),.s8_ack_i(s8_ack),.s8_err_i(1'b0),.s8_rty_i(1'b0),
      .s9_dat_o(s9_dat_o),.s9_adr_o(s9_adr),.s9_sel_o(s9_sel),.s9_we_o(s9_we),.s9_cyc_o(s9_cyc),.s9_stb_o(s9_stb),
      .s9_dat_i(s9_dat_i),.s9_ack_i(s9_ack),.s9_err_i(1'b0),.s9_rty_i(1'b0),
      .sa_dat_o(sa_dat_o),.sa_adr_o(sa_adr),.sa_sel_o(sa_sel),.sa_we_o(sa_we),.sa_cyc_o(sa_cyc),.sa_stb_o(sa_stb),
      .sa_dat_i(sa_dat_i),.sa_ack_i(sa_ack),.sa_err_i(1'b0),.sa_rty_i(1'b0),
      .sb_dat_o(sb_dat_o),.sb_adr_o(sb_adr),.sb_sel_o(sb_sel),.sb_we_o(sb_we),.sb_cyc_o(sb_cyc),.sb_stb_o(sb_stb),
      .sb_dat_i(sb_dat_i),.sb_ack_i(sb_ack),.sb_err_i(1'b0),.sb_rty_i(1'b0),
      .sc_dat_o(sc_dat_o),.sc_adr_o(sc_adr),.sc_sel_o(sc_sel),.sc_we_o(sc_we),.sc_cyc_o(sc_cyc),.sc_stb_o(sc_stb),
      .sc_dat_i(sc_dat_i),.sc_ack_i(sc_ack),.sc_err_i(1'b0),.sc_rty_i(1'b0),
      .sd_dat_o(sd_dat_o),.sd_adr_o(sd_adr),.sd_sel_o(sd_sel),.sd_we_o(sd_we),.sd_cyc_o(sd_cyc),.sd_stb_o(sd_stb),
      .sd_dat_i(sd_dat_i),.sd_ack_i(sd_ack),.sd_err_i(1'b0),.sd_rty_i(1'b0),
      .se_dat_o(se_dat_o),.se_adr_o(se_adr),.se_sel_o(se_sel),.se_we_o(se_we),.se_cyc_o(se_cyc),.se_stb_o(se_stb),
      .se_dat_i(se_dat_i),.se_ack_i(se_ack),.se_err_i(1'b0),.se_rty_i(1'b0),
      .sf_dat_o(sf_dat_o),.sf_adr_o(sf_adr),.sf_sel_o(sf_sel),.sf_we_o(sf_we),.sf_cyc_o(sf_cyc),.sf_stb_o(sf_stb),
      .sf_dat_i(sf_dat_i),.sf_ack_i(sf_ack),.sf_err_i(1'b0),.sf_rty_i(1'b0)
   );

   ////////////////////////////////////////////////////////////////////
   // Processor
   ////////////////////////////////////////////////////////////////////
   wire zpu_rst;

   zpu_wb_top #(.dat_w(DW), .adr_w(AW), .sel_w(SW)) zpu_top0 (
      .clk(clk), .rst(zpu_rst), .enb(~zpu_rst),
      // Data Wishbone bus to system bus fabric
      .we_o(m0_we),.stb_o(m0_stb),.dat_o(m0_dat_i),.adr_o(m0_adr),
      .dat_i(m0_dat_o),.ack_i(m0_ack),.sel_o(m0_sel),.cyc_o(m0_cyc),
      // Interrupts and exceptions
      .zpu_status(), .interrupt(1'b0)
   );

   ////////////////////////////////////////////////////////////////////
   // Double buffered system RAM (Slave #0) and Bootloader (Slave #A)
   ////////////////////////////////////////////////////////////////////
   zpu_bootram #(.ADDR_WIDTH(AW), .DATA_WIDTH(DW), .MAX_ADDR(16'h7FFC)) sys_ram (
      .clk(clk), .rst(rst),

      //ram interface
      .mem_stb(s0_stb), .mem_wea(&({SW{s0_we}} & s0_sel)), .mem_acka(s0_ack),
      .mem_addra(s0_adr), .mem_dina(s0_dat_o), .mem_douta(s0_dat_i),

      //bootloader interface
      .ldr_stb(sa_stb), .ldr_wea(&({SW{sa_we}} & sa_sel)), .ldr_acka(sa_ack),
      .ldr_addra(sa_adr), .ldr_dina(sa_dat_o), 

      //boot reset
      .zpu_rst(zpu_rst)
   );

   ////////////////////////////////////////////////////////////////////
   // Packet RAM -- Slave #1
   ////////////////////////////////////////////////////////////////////
   axi_stream_to_wb #(.AWIDTH(13), .CTRL_ADDR(13'h1ffc)) axi_stream_to_wb (
      .clk_i(clk), .rst_i(rst),

      //wb interface
      .we_i(s1_we), .stb_i(s1_stb), .cyc_i(s1_cyc), .ack_o(s1_ack),
      .adr_i(s1_adr[12:0]), .dat_i(s1_dat_o), .dat_o(s1_dat_i),

      //axi stream in
      .rx_tdata(zpui_tdata), .rx_tuser(zpui_tuser), .rx_tlast(zpui_tlast),
      .rx_tvalid(zpui_tvalid), .rx_tready(zpui_tready),

      //axi stream out
      .tx_tdata(zpuo_tdata), .tx_tuser(zpuo_tuser), .tx_tlast(zpuo_tlast),
      .tx_tvalid(zpuo_tvalid), .tx_tready(zpuo_tready),

      .debug_rx(), .debug_tx()
   );

   ////////////////////////////////////////////////////////////////////
   // Settings and readback bus -- Slave #2
   ////////////////////////////////////////////////////////////////////
   settings_bus #(.AWIDTH(AW), .DWIDTH(DW), .SWIDTH(SB_ADDRW)) settings_bus (
      .wb_clk(clk), .wb_rst(rst),
      .wb_adr_i(s2_adr), .wb_dat_i(s2_dat_o),
      .wb_stb_i(s2_stb), .wb_we_i(s2_we), .wb_ack_o(s2_ack),
      .strobe(set_stb), .addr(set_addr), .data(set_data)
   );

   settings_readback #(.AWIDTH(AW),.DWIDTH(DW), .RB_ADDRW(RB_ADDRW)) settings_readback (
      .wb_clk(clk),
      .wb_rst(rst),
      .wb_adr_i(s2_adr),
      .wb_stb_i(s2_stb),
      .wb_we_i(s2_we),
      .rb_data(rb_data),
      .rb_addr(rb_addr),
      .wb_dat_o(s2_dat_i),
      .rb_rd_stb(rb_rd_stb)
   );

   ////////////////////////////////////////////////////////////////////
   // SPI Flash -- Slave #3
   ////////////////////////////////////////////////////////////////////
   wire [15:0] spiflash_cs_raw; // Supress parser warnings.
   assign     spiflash_cs = spiflash_cs_raw[0];

   spi_top flash_spi (
      .wb_clk_i(clk),.wb_rst_i(rst),.wb_adr_i(s3_adr[4:0]),.wb_dat_i(s3_dat_o),
      .wb_dat_o(s3_dat_i),.wb_sel_i(s3_sel),.wb_we_i(s3_we),.wb_stb_i(s3_stb),
      .wb_cyc_i(s3_cyc),.wb_ack_o(s3_ack),.wb_err_o(s3_err),.wb_int_o(spiflash_int),
      .ss_pad_o(spiflash_cs_raw),
      .sclk_pad_o(spiflash_clk),.mosi_pad_o(spiflash_mosi),.miso_pad_i(spiflash_miso)
   );

   ////////////////////////////////////////////////////////////////////
   // Ethernet MAC0 -- Slave #4
   ////////////////////////////////////////////////////////////////////
   wire      mdio_tri0;

   simple_gemac_wrapper #(
      .RX_FLOW_CTRL(0), .PORTNUM(8'd0)
   ) simple_gemac_wrapper_port0 (
      .clk125(gmii_clk0), .reset(sw_rst[0]),
      .GMII_GTX_CLK(), .GMII_TX_EN(gmii_tx_en0), .GMII_TX_ER(gmii_tx_er0), .GMII_TXD(gmii_txd0),
      .GMII_RX_CLK(gmii_clk0), .GMII_RX_DV(gmii_rx_dv0), .GMII_RX_ER(gmii_rx_er0), .GMII_RXD(gmii_rxd0),
      
      .sys_clk(clk),
      .rx_tdata(eth0_rx_tdata), .rx_tuser(eth0_rx_tuser), .rx_tlast(eth0_rx_tlast), .rx_tvalid(eth0_rx_tvalid), .rx_tready(eth0_rx_tready),
      .tx_tdata(eth0_tx_tdata), .tx_tuser(eth0_tx_tuser), .tx_tlast(eth0_tx_tlast), .tx_tvalid(eth0_tx_tvalid), .tx_tready(eth0_tx_tready),
      // MDIO
      .mdc(mdc0),
      .mdio_in(mdio_in0),
      .mdio_out(mdio_out0),
      .mdio_tri(mdio_tri0),
      // Wishbone I/F
      .wb_adr_i(s4_adr[7:0]),            // To wishbone_if0 of wishbone_if.v
      .wb_clk_i(clk),           // To sync_clk_wb0 of sync_clk_wb.v, ...
      .wb_cyc_i(s4_cyc),            // To wishbone_if0 of wishbone_if.v
      .wb_dat_i(s4_dat_o),          // To wishbone_if0 of wishbone_if.v
      .wb_rst_i(rst),           // To sync_clk_wb0 of sync_clk_wb.v, ...
      .wb_stb_i(s4_stb),            // To wishbone_if0 of wishbone_if.v
      .wb_we_i(s4_we),             // To wishbone_if0 of wishbone_if.v
      .wb_ack_o(s4_ack),            // From wishbone_if0 of wishbone_if.v
      .wb_dat_o(s4_dat_i),          // From wishbone_if0 of wishbone_if.v
      .wb_int_o(s4_int),            // From wishbone_if0 of wishbone_if.v
      // Debug
      .debug_tx(), .debug_rx()
   );

   ////////////////////////////////////////////////////////////////////
   // Etherenet MAC1 -- Slave #5
   ////////////////////////////////////////////////////////////////////
   wire      mdio_tri1;

   simple_gemac_wrapper #(
      .RX_FLOW_CTRL(0), .PORTNUM(8'd1)
   ) simple_gemac_wrapper_port1 (
      .clk125(gmii_clk1), .reset(sw_rst[0]),
      .GMII_GTX_CLK(), .GMII_TX_EN(gmii_tx_en1), .GMII_TX_ER(gmii_tx_er1), .GMII_TXD(gmii_txd1),
      .GMII_RX_CLK(gmii_clk1), .GMII_RX_DV(gmii_rx_dv1), .GMII_RX_ER(gmii_rx_er1), .GMII_RXD(gmii_rxd1),
      
      .sys_clk(clk),
      .rx_tdata(eth1_rx_tdata), .rx_tuser(eth1_rx_tuser), .rx_tlast(eth1_rx_tlast), .rx_tvalid(eth1_rx_tvalid), .rx_tready(eth1_rx_tready),
      .tx_tdata(eth1_tx_tdata), .tx_tuser(eth1_tx_tuser), .tx_tlast(eth1_tx_tlast), .tx_tvalid(eth1_tx_tvalid), .tx_tready(eth1_tx_tready),
      // MDIO
      .mdc(mdc1),
      .mdio_in(mdio_in1),
      .mdio_out(mdio_out1),
      .mdio_tri(mdio_tri1),
      // Wishbone I/F
      .wb_adr_i(s5_adr[7:0]),            // To wishbone_if0 of wishbone_if.v
      .wb_clk_i(clk),           // To sync_clk_wb0 of sync_clk_wb.v, ...
      .wb_cyc_i(s5_cyc),            // To wishbone_if0 of wishbone_if.v
      .wb_dat_i(s5_dat_o),          // To wishbone_if0 of wishbone_if.v
      .wb_rst_i(rst),           // To sync_clk_wb0 of sync_clk_wb.v, ...
      .wb_stb_i(s5_stb),            // To wishbone_if0 of wishbone_if.v
      .wb_we_i(s5_we),             // To wishbone_if0 of wishbone_if.v
      .wb_ack_o(s5_ack),            // From wishbone_if0 of wishbone_if.v
      .wb_dat_o(s5_dat_i),          // From wishbone_if0 of wishbone_if.v
      .wb_int_o(s5_int),            // From wishbone_if0 of wishbone_if.v
      // Debug
      .debug_tx(), .debug_rx()
   );

   ////////////////////////////////////////////////////////////////////
   // I2C0 -- Slave #6
   ////////////////////////////////////////////////////////////////////
   wire scl0_pad_i, scl0_pad_o, scl0_pad_oen_o;
   wire sda0_pad_i, sda0_pad_o, sda0_pad_oen_o;

   i2c_master_top #(.ARST_LVL(1)) i2c0 (
      .wb_clk_i(clk),.wb_rst_i(rst),.arst_i(1'b0),
      .wb_adr_i(s6_adr[4:2]),.wb_dat_i(s6_dat_o[7:0]),.wb_dat_o(s6_dat_i[7:0]),
      .wb_we_i(s6_we),.wb_stb_i(s6_stb),.wb_cyc_i(s6_cyc),
      .wb_ack_o(s6_ack),.wb_inta_o(),
      .scl_pad_i(scl0_pad_i),.scl_pad_o(scl0_pad_o),.scl_padoen_o(scl0_pad_oen_o),
      .sda_pad_i(sda0_pad_i),.sda_pad_o(sda0_pad_o),.sda_padoen_o(sda0_pad_oen_o)
   );

   // I2C -- Don't use external transistors for open drain, the FPGA implements this
   IOBUF scl0_pin(.O(scl0_pad_i), .IO(scl0), .I(scl0_pad_o), .T(scl0_pad_oen_o));
   IOBUF sda0_pin(.O(sda0_pad_i), .IO(sda0), .I(sda0_pad_o), .T(sda0_pad_oen_o));

   assign s6_dat_i[31:8] = 24'd0;

   ////////////////////////////////////////////////////////////////////
   // I2C1 -- Slave #7
   ////////////////////////////////////////////////////////////////////
   wire scl1_pad_i, scl1_pad_o, scl1_pad_oen_o;
   wire sda1_pad_i, sda1_pad_o, sda1_pad_oen_o;

   i2c_master_top #(.ARST_LVL(1)) i2c1 (
      .wb_clk_i(clk),.wb_rst_i(rst),.arst_i(1'b0),
      .wb_adr_i(s7_adr[4:2]),.wb_dat_i(s7_dat_o[7:0]),.wb_dat_o(s7_dat_i[7:0]),
      .wb_we_i(s7_we),.wb_stb_i(s7_stb),.wb_cyc_i(s7_cyc),
      .wb_ack_o(s7_ack),.wb_inta_o(),
      .scl_pad_i(scl1_pad_i),.scl_pad_o(scl1_pad_o),.scl_padoen_o(scl1_pad_oen_o),
      .sda_pad_i(sda1_pad_i),.sda_pad_o(sda1_pad_o),.sda_padoen_o(sda1_pad_oen_o)
   );

   // I2C -- Don't use external transistors for open drain, the FPGA implements this
   IOBUF scl1_pin(.O(scl1_pad_i), .IO(scl1), .I(scl1_pad_o), .T(scl1_pad_oen_o));
   IOBUF sda1_pin(.O(sda1_pad_i), .IO(sda1), .I(sda1_pad_o), .T(sda1_pad_oen_o));

   assign s7_dat_i[31:8] = 24'd0;

   ////////////////////////////////////////////////////////////////////
   // ICAP Reconfiguration of FPGA -- Slave #8
   ////////////////////////////////////////////////////////////////////
   // IJB. Fix NASTY Derived clock inside ICAP block!!
   s7_icap_wb s7_icap_wb (
      .clk(clk), .reset(rst), .cyc_i(s8_cyc), .stb_i(s8_stb),
      .we_i(s8_we), .ack_o(s8_ack), .dat_i(s8_dat_o), .dat_o(s8_dat_i)
   );

   ////////////////////////////////////////////////////////////////////
   // UART0 -- Slave #9
   ////////////////////////////////////////////////////////////////////
   simple_uart zpu_debug_uart (
      .clk_i(clk), .rst_i(rst),
      .we_i(s9_we), .stb_i(s9_stb), .cyc_i(s9_cyc), .ack_o(s9_ack),
      .adr_i(s9_adr[4:2]), .dat_i(s9_dat_o), .dat_o(s9_dat_i),
      .rx_int_o(), .tx_int_o(), .tx_o(debug_txd), .rx_i(debug_rxd), .baud_o()
   );

   ////////////////////////////////////////////////////////////////////
   // Settings bus for cross bar -- Slave #B
   ////////////////////////////////////////////////////////////////////
   settings_bus #(.AWIDTH(AW), .DWIDTH(DW), .SWIDTH(9)) settings_bus_xb
   (
      .wb_clk(clk), .wb_rst(rst),
      .wb_adr_i(sb_adr), .wb_dat_i(sb_dat_o),
      .wb_stb_i(sb_stb), .wb_we_i(sb_we), .wb_ack_o(sb_ack),
      .strobe(set_stb_xb), .addr(set_addr_xb), .data(set_data_xb)
   );

   assign sb_dat_i = 32'b0;

   ////////////////////////////////////////////////////////////////////
   // Unused -- Slave C-F
   ////////////////////////////////////////////////////////////////////
   assign {sc_dat_i, sc_ack} = 33'b0;
   assign {sd_dat_i, sd_ack} = 33'b0;
   assign {se_dat_i, se_ack} = 33'b0;
   assign {sf_dat_i, sf_ack} = 33'b0;

   // S/W Timer
   reg [31:0] counter;
   always @(posedge clk)
      if (rst)
         counter <= 32'd0;
      else
         counter <= counter + 1'b1;

   // Ethernet packet counters
   reg [31:0] eth0_pkt_count, eth1_pkt_count;
   always @(posedge clk)
      if (rst)
         eth0_pkt_count <= 32'd0;
      else if (eth0_rx_tlast && eth0_rx_tvalid && eth0_rx_tready &&
               eth0_tx_tlast && eth0_tx_tvalid && eth0_tx_tready)
         eth0_pkt_count <= eth0_pkt_count + 32'd2;
      else if (eth0_rx_tlast && eth0_rx_tvalid && eth0_rx_tready)
         eth0_pkt_count <= eth0_pkt_count + 32'd1;
      else if (eth0_tx_tlast && eth0_tx_tvalid && eth0_tx_tready)
         eth0_pkt_count <= eth0_pkt_count + 32'd1;

   always @(posedge clk)
      if (rst)
         eth1_pkt_count <= 32'd0;
      else if (eth1_rx_tlast && eth1_rx_tvalid && eth1_rx_tready &&
               eth1_tx_tlast && eth1_tx_tvalid && eth1_tx_tready)
         eth1_pkt_count <= eth1_pkt_count + 32'd2;
      else if (eth1_rx_tlast && eth1_rx_tvalid && eth1_rx_tready)
         eth1_pkt_count <= eth1_pkt_count + 32'd1;
      else if (eth1_tx_tlast && eth1_tx_tvalid && eth1_tx_tready)
         eth1_pkt_count <= eth1_pkt_count + 32'd1;
   //
   // SW_RST - Bit allocation:
   // [0] - PHY reset
   // [1] - Radio clk domain reset
   // [2] - Unused
   // [3] - Unused
   //
   setting_reg #(.my_addr(SR_ZPU_SW_RST), .awidth(SB_ADDRW), .width(4)) set_sw_rst (
      .clk(clk), .rst(rst),
      .strobe(set_stb), .addr(set_addr), .in(set_data),
      .out(sw_rst),.changed()
   );

   // FW sets this register to signal boot is completed.
   setting_reg #(.my_addr(SR_ZPU_BOOT_DONE), .awidth(SB_ADDRW), .width(1)) sr_bld (
      .clk(clk),.rst(rst),.strobe(set_stb),.addr(set_addr),.in(set_data),
      .out(bldr_done),.changed()
   );

   // Ethernet LED's
   setting_reg #(.my_addr(SR_ZPU_LEDS), .awidth(SB_ADDRW), .width(16)) set_leds (
      .clk(clk), .rst(rst),
      .strobe(set_stb), .addr(set_addr), .in(set_data),
      .out(leds),.changed()
   );

   // Debug Register...can be driven to logic analyzer.
   wire [31:0] debug_reg;
   reg [31:0]  debug_reg2;
   assign    debug = debug_reg2;
   always @(posedge clk) debug_reg2 <= debug_reg;

   setting_reg #(.my_addr(SR_ZPU_DEBUG), .awidth(SB_ADDRW), .width(32)) set_debug (
      .clk(clk), .rst(rst),
      .strobe(set_stb), .addr(set_addr), .in(set_data),
      .out(debug_reg),.changed()
   );

   // Readback Mux
   always @*
      case(rb_addr)
         RB_ZPU_COMPAT : rb_data = { PRODUCT_ID, COMPAT_MAJOR, COMPAT_MINOR };
         RB_ZPU_COUNTER : rb_data = { counter };
         // SFP Interface pins.
         RB_ZPU_SFP_STATUS0: rb_data = {
            gmii_status0,
            10'h0,
            SFP0_ModAbs_chgd,SFP0_TxFault_chgd,SFP0_RxLOS_chgd,
            SFP0_ModAbs_reg2,SFP0_TxFault_reg2,SFP0_RxLOS_reg2
         };
         RB_ZPU_SFP_STATUS1: rb_data = {
            gmii_status1,
            10'h0,
            SFP1_ModAbs_chgd,SFP1_TxFault_chgd,SFP1_RxLOS_chgd,
            SFP1_ModAbs_reg2,SFP1_TxFault_reg2,SFP1_RxLOS_reg2
         };
         // GIT HASH of RTL Source
         // [31:28] = 0xf - Unclean build
         // [27:0] - Abrieviated git hash for RTL.
         RB_ZPU_GIT_HASH: rb_data = 32'h`GIT_HASH;
         RB_ZPU_ETH0_PKT_CNT: rb_data = eth0_pkt_count;
         RB_ZPU_ETH1_PKT_CNT: rb_data = eth1_pkt_count;

         default : rb_data = 32'd0;
      endcase // case (rb_addr)


   /*******************************************************************
   * Latch state changes to SFP pins.
   ******************************************************************/
   always @(posedge clk) begin
      SFP0_ModAbs_reg <= SFP0_ModAbs;
      SFP0_TxFault_reg <= SFP0_TxFault;
      SFP0_RxLOS_reg <= SFP0_RxLOS;
      SFP0_ModAbs_reg2 <= SFP0_ModAbs_reg;
      SFP0_TxFault_reg2 <= SFP0_TxFault_reg;
      SFP0_RxLOS_reg2 <= SFP0_RxLOS_reg;
      if (rb_rd_stb && (rb_addr == RB_ZPU_SFP_STATUS0)) begin
         SFP0_ModAbs_chgd <= 1'b0;
         SFP0_TxFault_chgd <= 1'b0;
         SFP0_RxLOS_chgd <= 1'b0;
      end else begin
         if (SFP0_ModAbs_reg2 != SFP0_ModAbs_reg)
            SFP0_ModAbs_chgd <= 1'b1;
         if (SFP0_TxFault_reg2 != SFP0_TxFault_reg)
            SFP0_TxFault_chgd <= 1'b1;
         if (SFP0_RxLOS_reg2 != SFP0_RxLOS_reg)
            SFP0_RxLOS_chgd <= 1'b1;
      end // else: !if(rb_rd_stb && (rb_addr == RB_SFP_STATUS0) )
   end

   always @(posedge clk) begin
      SFP1_ModAbs_reg <= SFP1_ModAbs;
      SFP1_TxFault_reg <= SFP1_TxFault;
      SFP1_RxLOS_reg <= SFP1_RxLOS;
      SFP1_ModAbs_reg2 <= SFP1_ModAbs_reg;
      SFP1_TxFault_reg2 <= SFP1_TxFault_reg;
      SFP1_RxLOS_reg2 <= SFP1_RxLOS_reg;
      if (rb_rd_stb && (rb_addr == RB_ZPU_SFP_STATUS1)) begin
         SFP1_ModAbs_chgd <= 1'b0;
         SFP1_TxFault_chgd <= 1'b0;
         SFP1_RxLOS_chgd <= 1'b0;
      end else begin
         if (SFP1_ModAbs_reg2 != SFP1_ModAbs_reg)
            SFP1_ModAbs_chgd <= 1'b1;
         if (SFP1_TxFault_reg2 != SFP1_TxFault_reg)
            SFP1_TxFault_chgd <= 1'b1;
         if (SFP1_RxLOS_reg2 != SFP1_RxLOS_reg)
            SFP1_RxLOS_chgd <= 1'b1;
      end // else: !if(rb_rd_stb && (rb_addr == RB_SFP_STATUS1) )
   end

   // SFP_RS0/1 pins are open drain.
   wire [1:0]     sfp0_ctrl, sfp1_ctrl;

   setting_reg #(.my_addr(SR_ZPU_SFP_CTRL0), .awidth(SB_ADDRW), .width(2), .at_reset(2'b00)) set_sfp0_ctrl (
      .clk(clk), .rst(rst),
      .strobe(set_stb), .addr(set_addr), .in(set_data),
      .out(sfp0_ctrl), .changed()
   );

   setting_reg #(.my_addr(SR_ZPU_SFP_CTRL1), .awidth(SB_ADDRW), .width(2), .at_reset(2'b00)) set_sfp1_ctrl (
      .clk(clk), .rst(rst),
      .strobe(set_stb), .addr(set_addr), .in(set_data),
      .out(sfp1_ctrl), .changed()
   );

   assign     SFP0_RS0 = sfp0_ctrl[0] ? 1'b0 : 1'bz;
   assign     SFP0_RS1 = sfp0_ctrl[1] ? 1'b0 : 1'bz;
   assign     SFP1_RS0 = sfp1_ctrl[0] ? 1'b0 : 1'bz;
   assign     SFP1_RS1 = sfp1_ctrl[1] ? 1'b0 : 1'bz;

endmodule
