
module x300_core (
   //Clocks and resets
   input radio_clk,
   input radio_rst,
   input bus_clk,
   input bus_rst,
   output [3:0] sw_rst,
   // Radio 0
   input [31:0] rx0, output [31:0] tx0,
   input [31:0] db0_gpio_in, output [31:0] db0_gpio_out, output [31:0] db0_gpio_ddr,
   input [31:0] fp_gpio_in, output [31:0] fp_gpio_out, output [31:0] fp_gpio_ddr,
   output [7:0] sen0, output sclk0, output mosi0, input miso0,
   output [2:0] radio_led0,
   output reg [31:0] radio0_misc_out, input [31:0] radio0_misc_in,
   // Radio 1
   input [31:0] rx1, output [31:0] tx1,
   input [31:0] db1_gpio_in, output [31:0] db1_gpio_out, output [31:0] db1_gpio_ddr,
   output [7:0] sen1, output sclk1, output mosi1, input miso1,
   output [2:0] radio_led1,
   output reg [31:0] radio1_misc_out, input [31:0] radio1_misc_in,
   // Radio shared misc
   inout db_scl,
   inout db_sda,
   // Clock control
   input ext_ref_clk,
   output [1:0] clock_ref_sel,
   output [1:0] clock_misc_opt,
   input [1:0] LMK_Status,
   input LMK_Holdover, input LMK_Lock, output LMK_Sync,
   output LMK_SEN, output LMK_SCLK, output LMK_MOSI,
   input [2:0] misc_clock_status,
   // SFP+ pins
   inout SFPP0_SCL,
   inout SFPP0_SDA,
   inout SFPP0_RS0,
   inout SFPP0_RS1,
   input SFPP0_ModAbs,
   input SFPP0_TxFault,
   input SFPP0_RxLOS,
   output SFPP0_TxDisable,   // Assert low to enable transmitter.

   inout SFPP1_SCL,
   inout SFPP1_SDA,
   inout SFPP1_RS0,
   inout SFPP1_RS1,
   input SFPP1_ModAbs,
   input SFPP1_TxFault,
   input SFPP1_RxLOS,
   output SFPP1_TxDisable,   // Assert low to enable transmitter.
   // MDIO
   output mdc0,
   output mdio_in0,
   input mdio_out0,
   input [15:0] eth0_phy_status,
   output mdc1,
   output mdio_in1,
   input mdio_out1,
   input [15:0] eth1_phy_status,

`ifdef ETH10G_PORT0
   // XGMII
   input xgmii_clk0,
   output [63:0] xgmii_txd0,
   output [7:0]  xgmii_txc0,
   input [63:0] xgmii_rxd0,
   input [7:0]  xgmii_rxc0,
   input xge_phy_resetdone0,
`else
   // GMII
   input gmii_clk0,
   output [7:0] gmii_txd0,
   output gmii_tx_en0,
   output gmii_tx_er0,
   input [7:0] gmii_rxd0,
   input gmii_rx_dv0,
   input gmii_rx_er0,
`endif // !`ifdef

`ifdef ETH10G_PORT1
   // XGMII
   input xgmii_clk1,
   output [63:0] xgmii_txd1,
   output [7:0]  xgmii_txc1,
   input [63:0] xgmii_rxd1,
   input [7:0]  xgmii_rxc1,
   input xge_phy_resetdone1,
`else
   // GMII
   input gmii_clk1,
   output [7:0] gmii_txd1,
   output gmii_tx_en1,
   output gmii_tx_er1,
   input [7:0] gmii_rxd1,
   input gmii_rx_dv1,
   input gmii_rx_er1,
`endif // !`ifdef

   // Time
   input pps,
   output [1:0] pps_select,
   output pps_out_enb,
   output gps_txd,
   input gps_rxd,
   // Debug UART
   input debug_rxd,
   output debug_txd,

   //
   // AXI4 (128b@250MHz) interface to DDR3 controller
   //
`ifndef NO_DRAM_FIFOS
   input           ddr3_axi_clk,
   input           ddr3_axi_clk_x2,
   input           ddr3_axi_rst,
   input           ddr3_running,
   // Write Address Ports
   output  [3:0]   ddr3_axi_awid,
   output  [31:0]  ddr3_axi_awaddr,
   output  [7:0]   ddr3_axi_awlen,
   output  [2:0]   ddr3_axi_awsize,
   output  [1:0]   ddr3_axi_awburst,
   output  [0:0]   ddr3_axi_awlock,
   output  [3:0]   ddr3_axi_awcache,
   output  [2:0]   ddr3_axi_awprot,
   output  [3:0]   ddr3_axi_awqos,
   output          ddr3_axi_awvalid,
   input           ddr3_axi_awready,
   // Write Data Ports
   output  [255:0] ddr3_axi_wdata,
   output  [31:0]  ddr3_axi_wstrb,
   output          ddr3_axi_wlast,
   output          ddr3_axi_wvalid,
   input           ddr3_axi_wready,
   // Write Response Ports
   output          ddr3_axi_bready,
   input [3:0]     ddr3_axi_bid,
   input [1:0]     ddr3_axi_bresp,
   input           ddr3_axi_bvalid,
   // Read Address Ports
   output  [3:0]   ddr3_axi_arid,
   output  [31:0]  ddr3_axi_araddr,
   output  [7:0]   ddr3_axi_arlen,
   output  [2:0]   ddr3_axi_arsize,
   output  [1:0]   ddr3_axi_arburst,
   output  [0:0]   ddr3_axi_arlock,
   output  [3:0]   ddr3_axi_arcache,
   output  [2:0]   ddr3_axi_arprot,
   output  [3:0]   ddr3_axi_arqos,
   output          ddr3_axi_arvalid,
   input           ddr3_axi_arready,
   // Read Data Ports
   output          ddr3_axi_rready,
   input [3:0]     ddr3_axi_rid,
   input [255:0]   ddr3_axi_rdata,
   input [1:0]     ddr3_axi_rresp,
   input           ddr3_axi_rlast,
   input           ddr3_axi_rvalid,
`endif //  `ifndef NO_DRAM_FIFOS

   //iop2 message fifos
   output [63:0] o_iop2_msg_tdata,
   output o_iop2_msg_tvalid,
   output o_iop2_msg_tlast,
   input o_iop2_msg_tready,
   input [63:0] i_iop2_msg_tdata,
   input i_iop2_msg_tvalid,
   input i_iop2_msg_tlast,
   output i_iop2_msg_tready,

   //PCIe
   output [63:0] pcio_tdata,
   output pcio_tlast,
   output pcio_tvalid,
   input pcio_tready,
   input [63:0] pcii_tdata,
   input pcii_tlast,
   input pcii_tvalid,
   output pcii_tready,

   // Debug
   output [7:0] led_misc,
   output [31:0] debug0,
   output [31:0] debug1,
   output [127:0] debug2
   );

   wire [63:0] eth0_rx_tdata, eth0_tx_tdata;
   wire [3:0]  eth0_rx_tuser, eth0_tx_tuser;
   wire        eth0_rx_tlast, eth0_tx_tlast, eth0_rx_tvalid, eth0_tx_tvalid, eth0_rx_tready, eth0_tx_tready;

   wire [63:0] eth1_rx_tdata, eth1_tx_tdata;
   wire [3:0]  eth1_rx_tuser, eth1_tx_tuser;
   wire        eth1_rx_tlast, eth1_tx_tlast, eth1_rx_tvalid, eth1_tx_tvalid, eth1_rx_tready, eth1_tx_tready;

   wire [63:0] r0i_tdata, r0o_tdata, r1i_tdata, r1o_tdata;
   wire        r0i_tlast, r0o_tlast, r1i_tlast, r1o_tlast;
   wire        r0i_tvalid, r0o_tvalid, r1i_tvalid, r1o_tvalid;
   wire        r0i_tready, r0o_tready, r1i_tready, r1o_tready;

   wire [63:0] r0_tx_tdata_bi, r0_tx_tdata_bo, r1_tx_tdata_bi, r1_tx_tdata_bo;
   wire        r0_tx_tlast_bi, r0_tx_tlast_bo, r1_tx_tlast_bi, r1_tx_tlast_bo;
   wire        r0_tx_tvalid_bi, r0_tx_tvalid_bo, r1_tx_tvalid_bi, r1_tx_tvalid_bo;
   wire        r0_tx_tready_bi, r0_tx_tready_bo, r1_tx_tready_bi, r1_tx_tready_bo;

   // Number of Radio Cores Instantiated
   localparam NUM_RADIO_CORES = 2;

   //------------------------------------------------------------------
   // Wishbone Slave Interface(s)
   //------------------------------------------------------------------
   localparam  dw  = 32;  // Data bus width
   localparam  aw  = 16;  // Address bus width, for byte addressibility, 16 = 64K byte memory space
   localparam  sw  = 4;   // Select width -- 32-bit data bus with 8-bit granularity.

   wire [dw-1:0] s4_dat_i;
   wire [dw-1:0] s4_dat_o;
   wire [aw-1:0] s4_adr;
   wire [sw-1:0] s4_sel;
   wire 	 s4_ack;
   wire 	 s4_stb;
   wire 	 s4_cyc;
   wire 	 s4_we;
   wire 	 s4_int;

   wire [dw-1:0] s5_dat_i;
   wire [dw-1:0] s5_dat_o;
   wire [aw-1:0] s5_adr;
   wire [sw-1:0] s5_sel;
   wire 	 s5_ack;
   wire 	 s5_stb;
   wire 	 s5_cyc;
   wire 	 s5_we;
   wire 	 s5_int;

   //////////////////////////////////////////////////////////////////////////////////////////////
   // RFNoC
   //////////////////////////////////////////////////////////////////////////////////////////////

   // Included automatically instantiated CEs sources file created by RFNoC mod tool
   `ifdef RFNOC
     `ifdef X300
       `include "rfnoc_ce_auto_inst_x300.v"
     `endif
     `ifdef X310
       `include "rfnoc_ce_auto_inst_x310.v"
     `endif
   `else
     localparam NUM_CE = 0;
   `endif

   /////////////////////////////////////////////////////////////////////////////////
   // Internal time synchronization
   /////////////////////////////////////////////////////////////////////////////////
   wire time_sync, time_sync_r;
    synchronizer time_sync_synchronizer
     (.clk(radio_clk), .rst(radio_rst), .in(time_sync), .out(time_sync_r));

   /////////////////////////////////////////////////////////////////////////////////
   // PPS synchronization logic
   /////////////////////////////////////////////////////////////////////////////////
   wire pps_rclk, pps_detect;
   pps_synchronizer pps_sync_inst (
      .ref_clk(ext_ref_clk), .timebase_clk(radio_clk),
      .pps_in(pps), .pps_out(pps_rclk), .pps_count(pps_detect)
   );

   /////////////////////////////////////////////////////////////////////////////////
   // Bus Int containing soft CPU control, routing fabric
   /////////////////////////////////////////////////////////////////////////////////
   bus_int #(.NUM_CE(NUM_CE+NUM_RADIO_CORES)) bus_int (
      .clk(bus_clk), .reset(bus_rst),
      .sen(LMK_SEN), .sclk(LMK_SCLK), .mosi(LMK_MOSI), .miso(1'b0),
      .scl0(SFPP0_SCL), .sda0(SFPP0_SDA),
      .scl1(db_scl), .sda1(db_sda),
      .scl2(SFPP1_SCL), .sda2(SFPP1_SDA),
      .gps_txd(gps_txd), .gps_rxd(gps_rxd),
      .debug_txd(debug_txd), .debug_rxd(debug_rxd),
      .leds(led_misc), .sw_rst(sw_rst),
      // SFP 0
      .SFPP0_ModAbs(SFPP0_ModAbs),.SFPP0_TxFault(SFPP0_TxFault),.SFPP0_RxLOS(SFPP0_RxLOS),
      .SFPP0_RS0(SFPP0_RS0), .SFPP0_RS1(SFPP0_RS1),
      // SFP 1
      .SFPP1_ModAbs(SFPP1_ModAbs),.SFPP1_TxFault(SFPP1_TxFault),.SFPP1_RxLOS(SFPP1_RxLOS),
      .SFPP1_RS0(SFPP1_RS0), .SFPP1_RS1(SFPP1_RS1),
      //clocky locky misc
      .clock_status({misc_clock_status, pps_detect, LMK_Holdover, LMK_Lock, LMK_Status}),
      .clock_control({time_sync, clock_misc_opt[1:0], pps_out_enb, pps_select[1:0], clock_ref_sel[1:0]}),
      // Eth0
      .eth0_tx_tdata(eth0_tx_tdata), .eth0_tx_tuser(eth0_tx_tuser), .eth0_tx_tlast(eth0_tx_tlast),
      .eth0_tx_tvalid(eth0_tx_tvalid), .eth0_tx_tready(eth0_tx_tready),
      .eth0_rx_tdata(eth0_rx_tdata), .eth0_rx_tuser(eth0_rx_tuser), .eth0_rx_tlast(eth0_rx_tlast),
      .eth0_rx_tvalid(eth0_rx_tvalid), .eth0_rx_tready(eth0_rx_tready),
      // Eth1
      .eth1_tx_tdata(eth1_tx_tdata), .eth1_tx_tuser(eth1_tx_tuser), .eth1_tx_tlast(eth1_tx_tlast),
      .eth1_tx_tvalid(eth1_tx_tvalid), .eth1_tx_tready(eth1_tx_tready),
      .eth1_rx_tdata(eth1_rx_tdata), .eth1_rx_tuser(eth1_rx_tuser), .eth1_rx_tlast(eth1_rx_tlast),
      .eth1_rx_tvalid(eth1_rx_tvalid), .eth1_rx_tready(eth1_rx_tready),
      // Radio 0
      .r0o_tdata(r0i_tdata), .r0o_tlast(r0i_tlast), .r0o_tready(r0i_tready), .r0o_tvalid(r0i_tvalid),
      .r0i_tdata(r0o_tdata), .r0i_tlast(r0o_tlast), .r0i_tready(r0o_tready), .r0i_tvalid(r0o_tvalid),
      // Radio 1
      .r1o_tdata(r1i_tdata), .r1o_tlast(r1i_tlast), .r1o_tready(r1i_tready), .r1o_tvalid(r1i_tvalid),
      .r1i_tdata(r1o_tdata), .r1i_tlast(r1o_tlast), .r1i_tready(r1o_tready), .r1i_tvalid(r1o_tvalid),
      // Computation Engines
      .ce_o_tdata(ce_flat_o_tdata), .ce_o_tlast(ce_o_tlast), .ce_o_tvalid(ce_o_tvalid), .ce_o_tready(ce_o_tready),
      .ce_i_tdata(ce_flat_i_tdata), .ce_i_tlast(ce_i_tlast), .ce_i_tvalid(ce_i_tvalid), .ce_i_tready(ce_i_tready),
      // IoP2 Msgs
      .o_iop2_msg_tdata(o_iop2_msg_tdata), .o_iop2_msg_tvalid(o_iop2_msg_tvalid), .o_iop2_msg_tlast(o_iop2_msg_tlast), .o_iop2_msg_tready(o_iop2_msg_tready),
      .i_iop2_msg_tdata(i_iop2_msg_tdata), .i_iop2_msg_tvalid(i_iop2_msg_tvalid), .i_iop2_msg_tlast(i_iop2_msg_tlast), .i_iop2_msg_tready(i_iop2_msg_tready),
      // PCIe
      .pcio_tdata(pcio_tdata), .pcio_tlast(pcio_tlast), .pcio_tvalid(pcio_tvalid), .pcio_tready(pcio_tready),
      .pcii_tdata(pcii_tdata), .pcii_tlast(pcii_tlast), .pcii_tvalid(pcii_tvalid), .pcii_tready(pcii_tready),
      // Wishbone Slave Interface(s)
      .s4_dat_i(s4_dat_i),
      .s4_dat_o(s4_dat_o),
      .s4_adr(s4_adr),
      .s4_sel(s4_sel),
      .s4_ack(s4_ack),
      .s4_stb(s4_stb),
      .s4_cyc(s4_cyc),
      .s4_we(s4_we),
      .s4_int(s4_int),
      .s5_dat_i(s5_dat_i),
      .s5_dat_o(s5_dat_o),
      .s5_adr(s5_adr),
      .s5_sel(s5_sel),
      .s5_ack(s5_ack),
      .s5_stb(s5_stb),
      .s5_cyc(s5_cyc),
      .s5_we(s5_we),
      .s5_int(s5_int),

      //Status signals
      .eth0_phy_status(eth0_phy_status),
      .eth1_phy_status(eth1_phy_status),

      // Debug
      .debug0(debug0), .debug1(debug1), .debug2(debug2));


   /////////////////////////////////////////////////////////////////////////////////////////////
   //
   // Radios
   //
   /////////////////////////////////////////////////////////////////////////////////////////////

   // Daughter board I/O
   wire [31:0] leds[0:3];
   wire [31:0] fp_gpio_r_in[0:3], fp_gpio_r_out[0:3], fp_gpio_r_ddr[0:3];
   wire [31:0] db_gpio_in[0:3], db_gpio_out[0:3], db_gpio_ddr[0:3];
   wire [31:0] misc_outs[0:3];
   reg  [31:0] misc_ins[0:3];
   wire [7:0]  sen[0:3];
   wire        sclk[0:3], mosi[0:3], miso[0:3];

   // Data
   wire [31:0] rx_data_in[0:3], rx_data[0:3], tx_data[0:3], tx_data_out[0:3];
   wire        rx_stb[0:3], tx_stb[0:3];
   wire        ext_set_stb[0:3];
   wire [7:0]  ext_set_addr[0:3];
   wire [31:0] ext_set_data[0:3];

   //------------------------------------
   // Radio 0,1 (XB Radio Port 0)
   //------------------------------------
   noc_block_radio_core #(
      .NOC_ID(64'h12AD_1000_0000_0001),
      .NUM_CHANNELS(2),
      .STR_SINK_FIFOSIZE(15),
      .MTU(13),
      .USE_SPI_CLK(1))
   noc_block_radio_core_i0 (
      //Clocks
      .bus_clk(bus_clk), .bus_rst(bus_rst),
      .ce_clk(radio_clk), .ce_rst(radio_rst),
      //AXIS data to/from crossbar
      .i_tdata(r0i_tdata), .i_tlast(r0i_tlast), .i_tvalid(r0i_tvalid), .i_tready(r0i_tready),
      .o_tdata(r0o_tdata), .o_tlast(r0o_tlast), .o_tvalid(r0o_tvalid), .o_tready(r0o_tready),
      // Data ports connected to radio front end
      .rx({rx_data[1],rx_data[0]}), .rx_stb({rx_stb[1],rx_stb[0]}),
      .tx({tx_data[1],tx_data[0]}), .tx_stb({tx_stb[1],tx_stb[0]}),
      // Ctrl ports connected to radio front end
      .ext_set_stb({ext_set_stb[1],ext_set_stb[0]}), .ext_set_addr({ext_set_addr[1],ext_set_addr[0]}), .ext_set_data({ext_set_data[1],ext_set_data[0]}),
      // Interfaces to front panel and daughter board
      .pps(pps_rclk), .sync(time_sync_r),
      .misc_ins({misc_ins[1], misc_ins[0]}), .misc_outs({misc_outs[1], misc_outs[0]}),
      .fp_gpio_in({fp_gpio_r_in[1],fp_gpio_r_in[0]}), .fp_gpio_out({fp_gpio_r_out[1],fp_gpio_r_out[0]}), .fp_gpio_ddr({fp_gpio_r_ddr[1],fp_gpio_r_ddr[0]}),
      .db_gpio_in({db_gpio_in[1],db_gpio_in[0]}), .db_gpio_out({db_gpio_out[1],db_gpio_out[0]}), .db_gpio_ddr({db_gpio_ddr[1],db_gpio_ddr[0]}),
      .leds({leds[1],leds[0]}),
      .spi_clk(radio_clk), .spi_rst(radio_rst),
      .sen({sen[1],sen[0]}), .sclk({sclk[1],sclk[0]}), .mosi({mosi[1],mosi[0]}), .miso({miso[1],miso[0]}),
      //Debug
      .debug()
   );
   
   //------------------------------------
   // Radio 2,3 (XB Radio Port 1)
   //------------------------------------
   noc_block_radio_core #(
      .NOC_ID(64'h12AD_1000_0000_0001),
      .NUM_CHANNELS(2),
      .STR_SINK_FIFOSIZE(15),
      .MTU(13),
      .USE_SPI_CLK(1))
   noc_block_radio_core_i1 (
      //Clocks
      .bus_clk(bus_clk), .bus_rst(bus_rst),
      .ce_clk(radio_clk), .ce_rst(radio_rst),
      //AXIS data to/from crossbar
      .i_tdata(r1i_tdata), .i_tlast(r1i_tlast), .i_tvalid(r1i_tvalid), .i_tready(r1i_tready),
      .o_tdata(r1o_tdata), .o_tlast(r1o_tlast), .o_tvalid(r1o_tvalid), .o_tready(r1o_tready),
      // Ports connected to radio front end
      .rx({rx_data[3],rx_data[2]}), .rx_stb({rx_stb[3],rx_stb[2]}),
      .tx({tx_data[3],tx_data[2]}), .tx_stb({tx_stb[3],tx_stb[2]}),
      // Ctrl ports connected to radio front end
      .ext_set_stb({ext_set_stb[3],ext_set_stb[2]}), .ext_set_addr({ext_set_addr[3],ext_set_addr[2]}), .ext_set_data({ext_set_data[3],ext_set_data[2]}),
      // Interfaces to front panel and daughter board
      .pps(pps_rclk), .sync(time_sync_r),
      .misc_ins({misc_ins[3], misc_ins[2]}), .misc_outs({misc_outs[3], misc_outs[2]}),
      .fp_gpio_in({fp_gpio_r_in[3],fp_gpio_r_in[2]}), .fp_gpio_out({fp_gpio_r_out[3],fp_gpio_r_out[2]}), .fp_gpio_ddr({fp_gpio_r_ddr[3],fp_gpio_r_ddr[2]}),
      .db_gpio_in({db_gpio_in[3],db_gpio_in[2]}), .db_gpio_out({db_gpio_out[3],db_gpio_out[2]}), .db_gpio_ddr({db_gpio_ddr[3],db_gpio_ddr[2]}),
      .leds({leds[3],leds[2]}),
      .spi_clk(radio_clk), .spi_rst(radio_rst),
      .sen({sen[3],sen[2]}), .sclk({sclk[3],sclk[2]}), .mosi({mosi[3],mosi[2]}), .miso({miso[3],miso[2]}),
      //Debug
      .debug()
   );

   //------------------------------------
   // Frontend Correction
   //------------------------------------

   localparam SET_TX_FE_BASE = 224;
   localparam SET_RX_FE_BASE = 232;
   genvar i;
   generate for (i=0; i<4; i=i+1) begin
      tx_frontend_gen3 #(
         .SR_OFFSET_I(SET_TX_FE_BASE + 0), .SR_OFFSET_Q(SET_TX_FE_BASE + 1),.SR_MAG_CORRECTION(SET_TX_FE_BASE + 2),
         .SR_PHASE_CORRECTION(SET_TX_FE_BASE + 3), .SR_MUX(SET_TX_FE_BASE + 4),
         .BYPASS_DC_OFFSET_CORR(0), .BYPASS_IQ_COMP(0),
         .DEVICE("7SERIES")
      ) tx_fe_corr_i (
         .clk(radio_clk), .reset(radio_rst),
         .set_stb(ext_set_stb[i]), .set_addr(ext_set_addr[i]), .set_data(ext_set_data[i]),
         .tx_stb(tx_stb[i]), .tx_i(tx_data[i][31:16]), .tx_q(tx_data[i][15:0]),
         .dac_stb(), .dac_i(tx_data_out[i][31:16]), .dac_q(tx_data_out[i][15:0])
      );

      rx_frontend_gen3 #(
         .SR_MAG_CORRECTION(SET_RX_FE_BASE + 0), .SR_PHASE_CORRECTION(SET_RX_FE_BASE + 1), .SR_OFFSET_I(SET_RX_FE_BASE + 2),
         .SR_OFFSET_Q(SET_RX_FE_BASE + 3), .SR_IQ_MAPPING(SET_RX_FE_BASE + 4), .SR_HET_PHASE_INCR(SET_RX_FE_BASE + 5),
         .BYPASS_DC_OFFSET_CORR(0), .BYPASS_IQ_COMP(0), .BYPASS_REALMODE_DSP(0),
         .DEVICE("7SERIES")
      ) rx_fe_corr_i (
         .clk(radio_clk), .reset(radio_rst),
         .set_stb(ext_set_stb[i]), .set_addr(ext_set_addr[i]), .set_data(ext_set_data[i]),
         .adc_stb(1'b1), .adc_i(rx_data_in[i][31:16]), .adc_q(rx_data_in[i][15:0]),
         .rx_stb(rx_stb[i]), .rx_i(rx_data[i][31:16]), .rx_q(rx_data[i][15:0])
      );
   end endgenerate

   //------------------------------------
   // Radio to ADC,DAC and IO Mapping
   //------------------------------------

   // Data
   assign {rx_data_in[1], rx_data_in[0]} = {rx0, rx0};
   assign {rx_data_in[3], rx_data_in[2]} = {rx1, rx1};

   assign tx0 = tx_data_out[0];   //tx_data_out[1] unused
   assign tx1 = tx_data_out[2];   //tx_data_out[3] unused
   assign tx_stb[0] = 1'b1;
   assign tx_stb[1] = 1'b0;
   assign tx_stb[2] = 1'b1;
   assign tx_stb[3] = 1'b0;
   
   //Daughter board GPIO
   assign {db_gpio_in[1], db_gpio_in[0]} = {32'b0, db0_gpio_in};
   assign {db_gpio_in[3], db_gpio_in[2]} = {32'b0, db1_gpio_in};
   assign db0_gpio_out = db_gpio_out[0];  //db_gpio_out[1] unused
   assign db1_gpio_out = db_gpio_out[2];  //db_gpio_out[3] unused
   assign db0_gpio_ddr = db_gpio_ddr[0];  //db_gpio_ddr[1] unused
   assign db1_gpio_ddr = db_gpio_ddr[2];  //db_gpio_out[3] unused

   //Front-panel board GPIO
   assign {fp_gpio_r_in[1], fp_gpio_r_in[0]} = {32'b0, fp_gpio_in};
   assign {fp_gpio_r_in[3], fp_gpio_r_in[2]} = {32'b0, 32'b0};
   assign fp_gpio_out = fp_gpio_r_out[0];  //fp_gpio_r_out[1,2,3] unused
   assign fp_gpio_ddr = fp_gpio_r_ddr[0];  //fp_gpio_ddr[1,2,3] unused

   //SPI
   assign {sen0, sclk0, mosi0} = {sen[0], sclk[0], mosi[0]};   //*[1] unused
   assign {miso[1], miso[0]}   = {1'b0, miso0};
   assign {sen1, sclk1, mosi1} = {sen[2], sclk[2], mosi[2]};   //*[3] unused
   assign {miso[3], miso[2]}   = {1'b0, miso1};
   
   //LEDs
   assign radio_led0 = leds[0][2:0];    //Other other led bits unused in leds[0,1]
   assign radio_led1 = leds[2][2:0];    //Other other led bits unused in leds[2,3]
   
   //Misc ins and outs
   always @(posedge radio_clk) begin
      radio0_misc_out   <= misc_outs[0];
      radio1_misc_out   <= misc_outs[2];
      misc_ins[0]       <= radio0_misc_in;
      misc_ins[2]       <= radio1_misc_in;
   end

   /////////////////////////////////////////////////////////////////////////////////////////////
   //
   // Ethernet
   //
   /////////////////////////////////////////////////////////////////////////////////////////////
`ifdef ETH10G_PORT0
   xge_mac_wrapper
     #(.PORTNUM(8'h0))
   xge_mac_wrapper_port0
     (
      // XGMII
      .xgmii_clk(xgmii_clk0),
      .xgmii_txd(xgmii_txd0),
      .xgmii_txc(xgmii_txc0),
      .xgmii_rxd(xgmii_rxd0),
      .xgmii_rxc(xgmii_rxc0),
      // MDIO
      .mdc(mdc0),
      .mdio_in(mdio_in0),
      .mdio_out(mdio_out0),
      // Wishbone I/F
      .wb_adr_i(s4_adr),               // To wishbone_if0 of wishbone_if.v
      .wb_clk_i(bus_clk),              // To sync_clk_wb0 of sync_clk_wb.v, ...
      .wb_cyc_i(s4_cyc),               // To wishbone_if0 of wishbone_if.v
      .wb_dat_i(s4_dat_o),             // To wishbone_if0 of wishbone_if.v
      .wb_rst_i(bus_rst),              // To sync_clk_wb0 of sync_clk_wb.v, ...
      .wb_stb_i(s4_stb),               // To wishbone_if0 of wishbone_if.v
      .wb_we_i(s4_we),                 // To wishbone_if0 of wishbone_if.v
      .wb_ack_o(s4_ack),               // From wishbone_if0 of wishbone_if.v
      .wb_dat_o(s4_dat_i),             // From wishbone_if0 of wishbone_if.v
      .wb_int_o(s4_int),               // From wishbone_if0 of wishbone_if.v
      // Client FIFO Interfaces
      .sys_clk(bus_clk),
      .reset(bus_rst),          // From sys_clk domain.
      .rx_tdata(eth0_rx_tdata),
      .rx_tuser(eth0_rx_tuser),
      .rx_tlast(eth0_rx_tlast),
      .rx_tvalid(eth0_rx_tvalid),
      .rx_tready(eth0_rx_tready),
      .tx_tdata(eth0_tx_tdata),
      .tx_tuser(eth0_tx_tuser),                // Bit[3] (error) is ignored for now.
      .tx_tlast(eth0_tx_tlast),
      .tx_tvalid(eth0_tx_tvalid),
      .tx_tready(eth0_tx_tready),
      // Other
      .phy_ready(xge_phy_resetdone0),
      // Debug
      .debug_rx(),
      .debug_tx());

`else
   simple_gemac_wrapper #(.RX_FLOW_CTRL(0), .PORTNUM(8'd0)) simple_gemac_wrapper_port0
     (.clk125(gmii_clk0), .reset(sw_rst[0]),
      .GMII_GTX_CLK(), .GMII_TX_EN(gmii_tx_en0), .GMII_TX_ER(gmii_tx_er0), .GMII_TXD(gmii_txd0),
      .GMII_RX_CLK(gmii_clk0), .GMII_RX_DV(gmii_rx_dv0), .GMII_RX_ER(gmii_rx_er0), .GMII_RXD(gmii_rxd0),

      .sys_clk(bus_clk),
      .rx_tdata(eth0_rx_tdata), .rx_tuser(eth0_rx_tuser), .rx_tlast(eth0_rx_tlast), .rx_tvalid(eth0_rx_tvalid), .rx_tready(eth0_rx_tready),
      .tx_tdata(eth0_tx_tdata), .tx_tuser(eth0_tx_tuser), .tx_tlast(eth0_tx_tlast), .tx_tvalid(eth0_tx_tvalid), .tx_tready(eth0_tx_tready),
      // MDIO
      .mdc(mdc0),
      .mdio_in(mdio_in0),
      .mdio_out(mdio_out0),
      // Wishbone I/F
      .wb_adr_i(s4_adr),               // To wishbone_if0 of wishbone_if.v
      .wb_clk_i(bus_clk),              // To sync_clk_wb0 of sync_clk_wb.v, ...
      .wb_cyc_i(s4_cyc),               // To wishbone_if0 of wishbone_if.v
      .wb_dat_i(s4_dat_o),             // To wishbone_if0 of wishbone_if.v
      .wb_rst_i(bus_rst),              // To sync_clk_wb0 of sync_clk_wb.v, ...
      .wb_stb_i(s4_stb),               // To wishbone_if0 of wishbone_if.v
      .wb_we_i(s4_we),                 // To wishbone_if0 of wishbone_if.v
      .wb_ack_o(s4_ack),               // From wishbone_if0 of wishbone_if.v
      .wb_dat_o(s4_dat_i),             // From wishbone_if0 of wishbone_if.v
      .wb_int_o(s4_int),               // From wishbone_if0 of wishbone_if.v
      // Debug
      .debug_tx(), .debug_rx()
      );
`endif // !`ifdef ETH10G_PORT0


 `ifdef ETH10G_PORT1
   xge_mac_wrapper
     #(.PORTNUM(8'h1))
   xge_mac_wrapper_port1
     (
      // XGMII
      .xgmii_clk(xgmii_clk1),
      .xgmii_txd(xgmii_txd1),
      .xgmii_txc(xgmii_txc1),
      .xgmii_rxd(xgmii_rxd1),
      .xgmii_rxc(xgmii_rxc1),
      // MDIO
      .mdc(mdc1),
      .mdio_in(mdio_in1),
      .mdio_out(mdio_out1),
      // Wishbone I/F
      .wb_adr_i(s5_adr),               // To wishbone_if0 of wishbone_if.v
      .wb_clk_i(bus_clk),              // To sync_clk_wb0 of sync_clk_wb.v, ...
      .wb_cyc_i(s5_cyc),               // To wishbone_if0 of wishbone_if.v
      .wb_dat_i(s5_dat_o),             // To wishbone_if0 of wishbone_if.v
      .wb_rst_i(bus_rst),              // To sync_clk_wb0 of sync_clk_wb.v, ...
      .wb_stb_i(s5_stb),               // To wishbone_if0 of wishbone_if.v
      .wb_we_i(s5_we),                 // To wishbone_if0 of wishbone_if.v
      .wb_ack_o(s5_ack),               // From wishbone_if0 of wishbone_if.v
      .wb_dat_o(s5_dat_i),             // From wishbone_if0 of wishbone_if.v
      .wb_int_o(s5_int),               // From wishbone_if0 of wishbone_if.v
      // Client FIFO Interfaces
      .sys_clk(bus_clk),
      .reset(bus_rst),          // From sys_clk domain.
      .rx_tdata(eth1_rx_tdata),
      .rx_tuser(eth1_rx_tuser),
      .rx_tlast(eth1_rx_tlast),
      .rx_tvalid(eth1_rx_tvalid),
      .rx_tready(eth1_rx_tready),
      .tx_tdata(eth1_tx_tdata),
      .tx_tuser(eth1_tx_tuser),                // Bit[3] (error) is ignored for now.
      .tx_tlast(eth1_tx_tlast),
      .tx_tvalid(eth1_tx_tvalid),
      .tx_tready(eth1_tx_tready),
      // Other
      .phy_ready(xge_phy_resetdone1),
      // Debug
      .debug_rx(),
      .debug_tx());

`else
   simple_gemac_wrapper #(.RX_FLOW_CTRL(0), .PORTNUM(8'd1)) simple_gemac_wrapper_port1
     (.clk125(gmii_clk1), .reset(sw_rst[0]),
      .GMII_GTX_CLK(), .GMII_TX_EN(gmii_tx_en1), .GMII_TX_ER(gmii_tx_er1), .GMII_TXD(gmii_txd1),
      .GMII_RX_CLK(gmii_clk1), .GMII_RX_DV(gmii_rx_dv1), .GMII_RX_ER(gmii_rx_er1), .GMII_RXD(gmii_rxd1),

      .sys_clk(bus_clk),
      .rx_tdata(eth1_rx_tdata), .rx_tuser(eth1_rx_tuser), .rx_tlast(eth1_rx_tlast), .rx_tvalid(eth1_rx_tvalid), .rx_tready(eth1_rx_tready),
      .tx_tdata(eth1_tx_tdata), .tx_tuser(eth1_tx_tuser), .tx_tlast(eth1_tx_tlast), .tx_tvalid(eth1_tx_tvalid), .tx_tready(eth1_tx_tready),
      // MDIO
      .mdc(mdc1),
      .mdio_in(mdio_in1),
      .mdio_out(mdio_out1),
      // Wishbone I/F
      .wb_adr_i(s5_adr),               // To wishbone_if0 of wishbone_if.v
      .wb_clk_i(bus_clk),              // To sync_clk_wb0 of sync_clk_wb.v, ...
      .wb_cyc_i(s5_cyc),               // To wishbone_if0 of wishbone_if.v
      .wb_dat_i(s5_dat_o),             // To wishbone_if0 of wishbone_if.v
      .wb_rst_i(bus_rst),              // To sync_clk_wb0 of sync_clk_wb.v, ...
      .wb_stb_i(s5_stb),               // To wishbone_if0 of wishbone_if.v
      .wb_we_i(s5_we),                 // To wishbone_if0 of wishbone_if.v
      .wb_ack_o(s5_ack),               // From wishbone_if0 of wishbone_if.v
      .wb_dat_o(s5_dat_i),             // From wishbone_if0 of wishbone_if.v
      .wb_int_o(s5_int),               // From wishbone_if0 of wishbone_if.v
      // Debug
      .debug_tx(), .debug_rx());
`endif

endmodule // x300_core
