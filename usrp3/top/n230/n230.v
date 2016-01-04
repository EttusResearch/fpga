//
// Copyright 2014-2016 Ettus Research LLC
//

module n230 (
   //------------------------------------------------------------------
   // Configuration SPI Flash interface
   //------------------------------------------------------------------
   output         SPIFLASH_CS,
   //output       SPIFLASH_CFGCLK, //Need to use STARTUPE2 macro to drive it after config
   input          SPIFLASH_MISO,
   output         SPIFLASH_MOSI,
   //------------------------------------------------------------------
   // AD9361 SPI Interface
   //------------------------------------------------------------------
   output         CODEC_CE,
   input          CODEC_MISO,
   output         CODEC_MOSI,
   output         CODEC_SCLK,
   //------------------------------------------------------------------
   // ADF4001 SPI Interface
   //------------------------------------------------------------------
   output         PLL_CE,
   output         PLL_MOSI,
   output         PLL_SCLK,
   //------------------------------------------------------------------
   // Debug UART
   //------------------------------------------------------------------
   input          FPGA_RXD0,
   output         FPGA_TXD0,
   //------------------------------------------------------------------
   // AD9361 Controls
   //------------------------------------------------------------------
   output         CODEC_ENABLE,
   output         CODEC_EN_AGC,
   output         CODEC_RESET,
   output         CODEC_SYNC,
   output         CODEC_TXRX,
   output [3:0]   CODEC_CTRL_IN,       // These should be outputs
   //input [7:0]  CODEC_CTRL_OUT,      // MUST BE INPUT. Unused.
   //------------------------------------------------------------------
   // Catalina Source Synchronous Data
   //------------------------------------------------------------------
   input          CODEC_DATA_CLK_P,    // Source Sync Clock from AD9361 (RX)
   input          CODEC_DATA_CLK_N,
   output         CODEC_FB_CLK_P,      // Source Sync Clock to AD9361 (TX)
   output         CODEC_FB_CLK_N,
   input  [5:0]   RX_DATA_P,
   input  [5:0]   RX_DATA_N,
   output [5:0]   TX_DATA_P,
   output [5:0]   TX_DATA_N,
   input          RX_FRAME_P,
   input          RX_FRAME_N,
   output         TX_FRAME_P,
   output         TX_FRAME_N,
   //input        CODEC_CLKOUT_FPGA, UNUSED
   //------------------------------------------------------------------
   // Clock (root) to AD9361 (always on) - Driven by 40MHz VCTCXO
   //------------------------------------------------------------------
   input          CODEC_MAIN_CLK_P,
   input          CODEC_MAIN_CLK_N,
   //------------------------------------------------------------------
   // Debug Bus (MICTOR)
   //------------------------------------------------------------------
   output [31:0]  DEBUG,
   output [1:0]   DEBUG_CLK,
   //------------------------------------------------------------------
   // GPSDO
   //------------------------------------------------------------------
   //input        GPS_LOCK,      //Unused
   output         GPS_RXD,
   input          GPS_TXD,
   //input        GPS_TXD_NMEA,  //Unused
   //------------------------------------------------------------------
   // LEDS
   //------------------------------------------------------------------
   output         LED_RX1,
   output         LED_RX2,
   output         LED_TXRX1_RX,
   output         LED_TXRX1_TX,
   output         LED_TXRX2_RX,
   output         LED_TXRX2_TX,
   output         LED_LINK1,
   output         LED_ACT1,
   output         LED_LINK2,
   output         LED_ACT2,
   //------------------------------------------------------------------
   // Clock/PPS
   //------------------------------------------------------------------
   output         REF_SEL,
   input          PLL_LOCK,
   input          PPS_IN_EXT,
   input          PPS_IN_INT,
   //------------------------------------------------------------------
   // RF Hardware Control
   //------------------------------------------------------------------
   output         SFDX1_RX,
   output         SFDX1_TX,
   output         SFDX2_RX,
   output         SFDX2_TX,
   output         SRX1_RX,
   output         SRX1_TX,
   output         SRX2_RX,
   output         SRX2_TX,
   output         TX_BANDSEL_A,
   output         TX_BANDSEL_B,
   output         TX_ENABLE1,
   output         TX_ENABLE2,
   output         RX_BANDSEL_A,
   output         RX_BANDSEL_B,
   output         RX_BANDSEL_C,
   //------------------------------------------------------------------
   // external ZBT SRAM
   //------------------------------------------------------------------
   inout  [35:0]  RAM_D,
   output [20:0]  RAM_A,
   output [3:0]   RAM_BWn,
   output         RAM_ZZ,
   output         RAM_LDn,
   output         RAM_OEn,
   output         RAM_WEn,
   output         RAM_CENn,
   output         RAM_CE1n,
   output         RAM_CLK,
   //------------------------------------------------------------------
   // general purpose IO connector
   //------------------------------------------------------------------
   //inout [7:0] GPIO,  // IJB Need to decide how GPIO pins are driven. Likely like B200 Rev2.
   //------------------------------------------------------------------
   // Gige SFPs (High speed data)
   //------------------------------------------------------------------
   input          SFP0_RX_P, // MGT
   input          SFP0_RX_N,
   output         SFP0_TX_P, // MGT
   output         SFP0_TX_N,

   input          SFP1_RX_P, // MGT
   input          SFP1_RX_N,
   output         SFP1_TX_P, // MGT
   output         SFP1_TX_N,
   //------------------------------------------------------------------
   // SFP (low speed signals)
   //------------------------------------------------------------------
   input          SFP0_TXFAULT,
   output         SFP0_TXDISABLE,
   inout          SFP0_SDA,
   inout          SFP0_SCL,
   input          SFP0_MODABS,
   input          SFP0_RXLOS,
   output         SFP0_RS0,
   output         SFP0_RS1,

   input          SFP1_TXFAULT,
   output         SFP1_TXDISABLE,
   inout          SFP1_SDA,
   inout          SFP1_SCL,
   input          SFP1_MODABS,
   input          SFP1_RXLOS,
   inout          SFP1_RS0,
   input          SFP1_RS1,
   //------------------------------------------------------------------
   // Gig-E clock reference for MGT (125MHz from LVDS Osc)
   //------------------------------------------------------------------
   input          SFPX_CLK_P,
   input          SFPX_CLK_N,
   //------------------------------------------------------------------
   // JESD MGT reference clock including optional loop-back output
   //------------------------------------------------------------------
   output         CODEC_LOOP_CLK_OUT_P, // lvds clock out
   output         CODEC_LOOP_CLK_OUT_N,
   input          CODEC_LOOP_CLK_IN_P, // MGT refclk in
   input          CODEC_LOOP_CLK_IN_N,
   
   input          JESD0_RX_P,
   input          JESD0_RX_N,
   output         JESD0_TX_P,
   output         JESD0_TX_N,

   input          JESD1_RX_P,
   input          JESD1_RX_N,
   output         JESD1_TX_P,
   output         JESD1_TX_N
   //------------------------------------------------------------------
   // JESD interface 1 signals
   //------------------------------------------------------------------
   //output RD1_ET_FRAME_CLKp,
   //output RD1_ET_FRAME_CLKn,
   //input RD1_ET_SYNCp,
   //input RD1_ET_SYNCn,
   // High Speed Data
   //output RD1_ET_ENV0p, // MGT Tx
   //output RD1_ET_ENV0n, // MGT Tx
   // SPI
   //output RD1_ET_SPI_SCLK,
   //output RD1_ET_SPI_SDIN,
   //input RD1_ET_SPI_SDOUT,
   //output RD1_ET_SPI_SDEN,
   // Modulator (PIC) Reset
   //output RD1_ET_RESET,
   // Alarm interupt
   //input RD1_ET_ALARM,
   // Warning interupt
   //input RD1_ET_WARNING,
   // Sleep mode
   //output RD1_SLEEP,
   // Modulator Ready
   //input RD1_P_READY,
   // PIC Program/Debug
   //output RD1_ICSP_CLK,
   //inout RD1_ICSP_DAT,
   // Set the loopback from PA to RX
   //output RD1_RX_TX_LOOPBACK,
   // Temperature Sensor
   //inout RD1_TEMP_SDA,
   //output RD1_TEMP_SCL,
   //
   //output RD1_RFPWR_CONV,
   //input RD1_RFPWR_SDO,
   //output RD1_RFPWR_SCLK,
   `ifdef TEST_JESD204_IF
   //
   // WARNING! Pin directions in this section are purely for use on the production test stand
   // for loopback testing using a standard Molex cable. The could be *DESTRUCTIVE* to connected
   // hardware
   //
   , // Continue last signal declaration with comma
  (* IOB = "TRUE" *)    inout RD1_ET_SPI_SCLK,     // A5 1.8V
  (* IOB = "TRUE" *)    inout RD1_ET_SPI_SDIN,     // A6 1.8V
  (* IOB = "TRUE" *)    input RD1_ET_FRAME_CLKp,    // B5 2.5V
  (* IOB = "TRUE" *)    input RD1_ET_FRAME_CLKn,    // B6 2.5V
  (* IOB = "TRUE" *)    inout RD1_RX_TX_LOOPBACK,  // A8 3.3V
  (* IOB = "TRUE" *)    inout RD1_TEMP_SDA,        // A9 3.3V
  (* IOB = "TRUE" *)    input RD1_RFPWR_SDO,        // B8 3.3V
  (* IOB = "TRUE" *)    input RD1_RFPWR_SCLK,       // B9 3.3V
  (* IOB = "TRUE" *)    inout RD1_ET_SPI_SDOUT,    // A13 1.8V
  (* IOB = "TRUE" *)    inout RD1_ET_SPI_SDEN,     // A14 1.8V
  (* IOB = "TRUE" *)    input RD1_ET_ALARM,         // B13 1.8V
  (* IOB = "TRUE" *)    input RD1_ET_WARNING,       // B14 1.8V
  (* IOB = "TRUE" *)    inout RD1_ICSP_CLK,        // A16 1.8V
  (* IOB = "TRUE" *)    inout RD1_ICSP_DAT,        // A17 1.8V
  (* IOB = "TRUE" *)    input RD1_SLEEP,            // B16 1.8V
  (* IOB = "TRUE" *)    input RD1_P_READY,          // B17 1.8V

 `endif
   //------------------------------------------------------------------
   // JESD interface 2 signals
   //------------------------------------------------------------------
   //output RD2_ET_FRAME_CLKp,
   //output RD2_ET_FRAME_CLKn,
   //input RD2_ET_SYNCp,
   //input RD2_ET_SYNCn,
   // High Speed Data
   //output RD2_ET_ENV0p, // MGT Tx
   //output RD2_ET_ENV0n,  // MGT Tx
   // SPI
   //output RD2_ET_SPI_SCLK,
   //output RD2_ET_SPI_SDIN,
   //input RD2_ET_SPI_SDOUT,
   //output RD2_ET_SPI_SDEN,
   // Modulator (PIC) Reset
   //output RD2_ET_RESET,
   // Alarm interupt
   //input RD2_ET_ALARM,
   // Warning interupt
   //input RD2_ET_WARNING,
   // Sleep mode
   //output RD2_SLEEP,
   // Modulator Ready
   //input RD2_P_READY,
   // PIC Program/Debug
   //output RD2_ICSP_CLK,
   //inout RD2_ICSP_DAT,
   // Set the loopback from PA to RX
   //output RD2_RX_TX_LOOPBACK,
   // Temperature Sensor
   //inout RD2_TEMP_SDA,
   //output RD2_TEMP_SCL,
   //
   //output RD2_RFPWR_CONV,
   //input RD2_RFPWR_SDO,
   //output RD2_RFPWR_SCLK
    `ifdef TEST_JESD204_IF
   //
   // WARNING! Pin directions in this section are purely for use on the production test stand
   // for loopback testing using a standard Molex cable. The could be *DESTRUCTIVE* to connected
   // hardware
   //
  (* IOB = "TRUE" *)    inout RD2_ET_SPI_SCLK,     // A5 1.8V
  (* IOB = "TRUE" *)    inout RD2_ET_SPI_SDIN,     // A6 1.8V
  (* IOB = "TRUE" *)    input RD2_ET_FRAME_CLKp,    // B5 2.5V
  (* IOB = "TRUE" *)    input RD2_ET_FRAME_CLKn,    // B6 2.5V
  (* IOB = "TRUE" *)    inout RD2_RX_TX_LOOPBACK,  // A8 3.3V
  (* IOB = "TRUE" *)    inout RD2_TEMP_SDA,        // A9 3.3V
  (* IOB = "TRUE" *)    input RD2_RFPWR_SDO,        // B8 3.3V
  (* IOB = "TRUE" *)    input RD2_RFPWR_SCLK,       // B9 3.3V
  (* IOB = "TRUE" *)    inout RD2_ET_SPI_SDOUT,    // A13 1.8V
  (* IOB = "TRUE" *)    inout RD2_ET_SPI_SDEN,     // A14 1.8V
  (* IOB = "TRUE" *)    input RD2_ET_ALARM,         // B13 1.8V
  (* IOB = "TRUE" *)    input RD2_ET_WARNING,       // B14 1.8V
  (* IOB = "TRUE" *)    inout RD2_ICSP_CLK,        // A16 1.8V
  (* IOB = "TRUE" *)    inout RD2_ICSP_DAT,        // A17 1.8V
  (* IOB = "TRUE" *)    input RD2_SLEEP,            // B16 1.8V
  (* IOB = "TRUE" *)    input RD2_P_READY          // B17 1.8V

 `endif
);

   //------------------------------------------------------------------
   wire reset_global = 1'b0; // TODO: connect to something

   wire [3:0] sw_rst;
   wire [2:0] radio_control;

   wire ethrefclk;
   wire codec_main_clk;
   IBUFDS codec_main_clk_IBUFDS_i0 (.I(CODEC_MAIN_CLK_P), .IB(CODEC_MAIN_CLK_N), .O(codec_main_clk));

   //------------------------------------------------------------------
   // generate clocks from always on codec main clk
   //------------------------------------------------------------------
   wire   bus_clk;      // Nominally 80MHz
   wire   radio_clk;    // Frequency determined by Catalina Programming
   wire   radio_clk_2x; // Double radio_clk freq.
   wire   clk200;       // 200MHz fixed frequency clock (For DELAY I/O)
   wire   clk100;       // 100MHz fixed frequency clock looped back as JESD GT refclk
   wire   ram_ui_clk;
   wire   ram_io_clk;

   wire catclk_92_16; // TODO:
   assign catclk_92_16 = radio_clk;
   // this needs to always be 92.16 MHz
   // since the catalina data clock may be either 184.32 or 92.16,
   // use a BUFGCTRL to select between the direct clock, if it is 92.16,
   // or a divided-by-2 version if it is 184.32


   //----------------------------------------------------------------------------
   //  Output     Output      Phase    Duty Cycle   Pk-to-Pk     Phase
   //   Clock     Freq (MHz)  (degrees)    (%)     Jitter (ps)  Error (ps)
   //----------------------------------------------------------------------------
   // CLK_OUT1____80.000______0.000______50.0______158.221____166.174
   // CLK_OUT2___200.000______0.000______50.0______137.833____166.174
   // CLK_OUT3___100.000______0.000______50.0______152.933____166.174
   // CLK_OUT4___120.000______0.000______50.0______148.771____166.174
   // CLK_OUT5___120.000____261.000______50.0______148.771____166.174
   //
   //----------------------------------------------------------------------------
   // Input Clock   Freq (MHz)    Input Jitter (UI)
   //----------------------------------------------------------------------------
   // __primary______________40____________0.010

   wire locked;
   bus_clk_gen bus_clk_gen_i (
      // Clock in ports
      .clk_in_40mhz(codec_main_clk),
      // Clock out ports
      .clk_out_80mhz(bus_clk),
      .clk_out_200mhz(clk200),
      .clk_out_100mhz(clk100),
      .clk_out_120mhz(ram_ui_clk),
      .clk_out_120mhz_del(ram_io_clk),
      // Status and control signals
      .reset(reset_global),
      .locked(locked)
   );
   
   // send the clock off-chip, it comes back in as the reference clock for the jesd GT transceiver
   // We need to place an ODDR register here to get the clock signal out of the FPGA cleanly.
   wire   codec_loop_clk_out;
   ODDR #(.DDR_CLK_EDGE("SAME_EDGE")) codec_loop_clk_out_i
     (.Q(codec_loop_clk_out), .C(clk100), .CE(1'b1), .D1(1'b0), .D2(1'b1), .R(1'b0), .S(1'b0));
   OBUFDS clock_out_OBUFDS_i0 (.I(codec_loop_clk_out), .O(CODEC_LOOP_CLK_OUT_P), .OB(CODEC_LOOP_CLK_OUT_N));

   //hold-off logic for clocks ready
   reg [15:0] clocks_ready_count;
   reg clocks_ready;
   always @(posedge bus_clk or posedge reset_global or negedge locked) begin
      if (reset_global | !locked) begin
          clocks_ready_count <= 16'b0;
          clocks_ready <= 1'b0;
      end
      else if (!clocks_ready) begin
          clocks_ready_count <= clocks_ready_count + 1'b1;
          clocks_ready <= (clocks_ready_count == 16'hffff);
      end
   end

   //hold-off logic for clocks ready
   reg [15:0]  radio_clocks_ready_count = 16'h0;
   reg         radio_clocks_ready = 1'b0;
   always @(posedge radio_clk ) begin
      if (!radio_clocks_ready) begin
         radio_clocks_ready_count <= radio_clocks_ready_count + 1'b1;
         radio_clocks_ready <= (radio_clocks_ready_count == 16'hffff);
      end
   end

   //------------------------------------------------------------------
   // Create sync reset signals
   //------------------------------------------------------------------
   wire  bus_rst_pre;
   (* MAX_FANOUT = 200 *) wire  radio_rst_pre;
   (* MAX_FANOUT = 200 *) wire  bus_rst;

   reset_sync bus_sync_i0(.clk(bus_clk), .reset_in(!clocks_ready), .reset_out(bus_rst));
   reset_sync radio_sync_i0(.clk(radio_clk), .reset_in(!radio_clocks_ready), .reset_out(radio_rst_pre));
   BUFG radio_rst_bufg (.O(radio_rst), .I(radio_rst_pre));

   //------------------------------------------------------------------
   // Instantiate external RAM FIFO
   //------------------------------------------------------------------
   wire [63:0] ef0i_tdata, ef1i_tdata;
   wire        ef0i_tlast, ef0i_tvalid, ef0i_tready, ef1i_tlast, ef1i_tvalid, ef1i_tready;
   wire [63:0] ef0o_tdata, ef1o_tdata;
   wire        ef0o_tlast, ef0o_tvalid, ef0o_tready, ef1o_tlast, ef1o_tvalid, ef1o_tready;
   wire        ef_bist_done;
   wire [1:0]  ef_bist_error;

   n230_ext_sram_fifo #(
      .INGRESS_BUF_DEPTH(10),    //Buffer packets after XB
      .EGRESS_BUF_DEPTH(11),     //16k packet gate FIFO here plus an 8k FIFO in the radio
      .BIST_ENABLED(0), .BIST_REG_BASE(0)
   ) ext_fifo_i (
      //Clocks
      .bus_clk(bus_clk),
      .bus_rst(bus_rst),
      .ram_ui_clk(ram_ui_clk),
      .ram_io_clk(ram_io_clk),
      // IO Interface
      .RAM_D(RAM_D),
      .RAM_A(RAM_A),
      .RAM_BWn(RAM_BWn),
      .RAM_ZZ(RAM_ZZ),
      .RAM_LDn(RAM_LDn),
      .RAM_OEn(RAM_OEn),
      .RAM_WEn(RAM_WEn),
      .RAM_CENn(RAM_CENn),
      .RAM_CE1n(RAM_CE1n),
      .RAM_CLK(RAM_CLK),
      // Ch0: AXI Stream Interface
      .i0_tdata(ef0i_tdata),
      .i0_tlast(ef0i_tlast),
      .i0_tvalid(ef0i_tvalid),
      .i0_tready(ef0i_tready),
      .o0_tdata(ef0o_tdata),
      .o0_tlast(ef0o_tlast),
      .o0_tvalid(ef0o_tvalid),
      .o0_tready(ef0o_tready),
      // Ch1: AXI Stream Interface
      .i1_tdata(ef1i_tdata),
      .i1_tlast(ef1i_tlast),
      .i1_tvalid(ef1i_tvalid),
      .i1_tready(ef1i_tready),
      .o1_tdata(ef1o_tdata),
      .o1_tlast(ef1o_tlast),
      .o1_tvalid(ef1o_tvalid),
      .o1_tready(ef1o_tready),
      // BIST Control Status Interface
      .set_stb(1'b0),
      .set_addr(8'h0),
      .set_data(32'h0),
      .bist_done(ef_bist_done),
      .bist_error(ef_bist_error)
   );

   //------------------------------------------------------------------
   // Production Test of JESD204 connectors and signals
   //------------------------------------------------------------------
   `ifdef TEST_JESD204_IF

   wire  jesd204_test_run;
   wire  jesd204_test_done;
   wire [15:0] jesd204_test_status;


   n230_test_jesd204_if  n230_test_jesd204_if
     (
      .clk(bus_clk),
      .reset(bus_rst),
      .run(jesd204_test_run),
      .done(jesd204_test_done),
      .status(jesd204_test_status),
      .RD1_ET_SPI_SCLK(RD1_ET_SPI_SCLK ),     // A5 1.8V
      .RD1_ET_SPI_SDIN(RD1_ET_SPI_SDIN ),     // A6 1.8V
      .RD1_ET_FRAME_CLKp(RD1_ET_FRAME_CLKp ),    // B5 2.5V
      .RD1_ET_FRAME_CLKn(RD1_ET_FRAME_CLKn ),    // B6 2.5V
      .RD1_RX_TX_LOOPBACK(RD1_RX_TX_LOOPBACK ),  // A8 3.3V
      .RD1_TEMP_SDA(RD1_TEMP_SDA ),        // A9 3.3V
      .RD1_RFPWR_SDO(RD1_RFPWR_SDO ),        // B8 3.3V
      .RD1_RFPWR_SCLK(RD1_RFPWR_SCLK ),       // B9 3.3V
      .RD1_ET_SPI_SDOUT(RD1_ET_SPI_SDOUT ),    // A13 1.8V
      .RD1_ET_SPI_SDEN(RD1_ET_SPI_SDEN ),     // A14 1.8V
      .RD1_ET_ALARM(RD1_ET_ALARM ),         // B13 1.8V
      .RD1_ET_WARNING(RD1_ET_WARNING ),       // B14 1.8V
      .RD1_ICSP_CLK(RD1_ICSP_CLK ),        // A16 1.8V
      .RD1_ICSP_DAT(RD1_ICSP_DAT ),        // A17 1.8V
      .RD1_SLEEP(RD1_SLEEP ),            // B16 1.8V
      .RD1_P_READY(RD1_P_READY ),          // B17 1.8V

      .RD2_ET_SPI_SCLK(RD2_ET_SPI_SCLK ),     // A5 1.8V
      .RD2_ET_SPI_SDIN(RD2_ET_SPI_SDIN ),     // A6 1.8V
      .RD2_ET_FRAME_CLKp(RD2_ET_FRAME_CLKp ),    // B5 2.5V
      .RD2_ET_FRAME_CLKn(RD2_ET_FRAME_CLKn ),    // B6 2.5V
      .RD2_RX_TX_LOOPBACK(RD2_RX_TX_LOOPBACK ),  // A8 3.3V
      .RD2_TEMP_SDA(RD2_TEMP_SDA ),        // A9 3.3V
      .RD2_RFPWR_SDO(RD2_RFPWR_SDO ),        // B8 3.3V
      .RD2_RFPWR_SCLK(RD2_RFPWR_SCLK ),       // B9 3.3V
      .RD2_ET_SPI_SDOUT(RD2_ET_SPI_SDOUT ),    // A13 1.8V
      .RD2_ET_SPI_SDEN(RD2_ET_SPI_SDEN ),     // A14 1.8V
      .RD2_ET_ALARM(RD2_ET_ALARM ),         // B13 1.8V
      .RD2_ET_WARNING(RD2_ET_WARNING ),       // B14 1.8V
      .RD2_ICSP_CLK(RD2_ICSP_CLK ),        // A16 1.8V
      .RD2_ICSP_DAT(RD2_ICSP_DAT ),        // A17 1.8V
      .RD2_SLEEP(RD2_SLEEP ),            // B16 1.8V
      .RD2_P_READY(RD2_P_READY )          // B17 1.8V
      );
 `endif

   //------------------------------------------------------------------
   // CODEC capture/gen
   //------------------------------------------------------------------
   wire [4:0] ctrl_clk_delay, ctrl_data_delay;
   wire       ctrl_ld_clk_delay, ctrl_ld_data_delay;

   wire [31:0] rx_data0, rx_data1;
   wire [31:0] tx_data0, tx_data1;
   wire mimo, codec_arst;

   wire [11:0] rx_i0, rx_q0, tx_i0, tx_q0;
   wire [11:0] rx_i1, rx_q1, tx_i1, tx_q1;
   assign rx_data0 = { rx_i0, 4'b0, rx_q0, 4'b0 };
   assign rx_data1 = { rx_i1, 4'b0, rx_q1, 4'b0 };
   assign tx_i0 = tx_data0[31:20];
   assign tx_q0 = tx_data0[15:4];
   assign tx_i1 = tx_data1[31:20];
   assign tx_q1 = tx_data1[15:4];


   cat_io_lvds #(
      .INVERT_FRAME_RX(1'b1),
      .INVERT_DATA_RX(6'b01_1111),
      .INVERT_FRAME_TX(1'b1),
      .INVERT_DATA_TX(6'b10_1001),
      .INPUT_CLOCK_DELAY(8),
      .INPUT_DATA_DELAY(0),
      .OUTPUT_CLOCK_DELAY(16),
      .OUTPUT_DATA_DELAY(0)
   ) cat_io_lvds (
      .rst(codec_arst),
      .mimo(mimo),
      .clk200(clk200),   // Delay Control_interface
      .ctrl_clk(bus_clk),
      .ctrl_data_delay(ctrl_data_delay),
      .ctrl_clk_delay(ctrl_clk_delay),
      .ctrl_ld_data_delay(ctrl_ld_data_delay),
      .ctrl_ld_clk_delay(ctrl_ld_clk_delay),
      // Baseband sample interface
      .radio_clk(radio_clk),
      .radio_clk_2x(radio_clk_2x),
      .rx_i0(rx_i0),
      .rx_q0(rx_q0),
      .rx_i1(rx_i1),
      .rx_q1(rx_q1),
      .tx_i0(tx_i0),
      .tx_q0(tx_q0),
      .tx_i1(tx_i1),
      .tx_q1(tx_q1),
      // Catalina interface
      .rx_clk_p(CODEC_DATA_CLK_P),
      .rx_clk_n(CODEC_DATA_CLK_N),
      .rx_frame_p(RX_FRAME_P),
      .rx_frame_n(RX_FRAME_N),
      .rx_d_p(RX_DATA_P),
      .rx_d_n(RX_DATA_N),
      .tx_clk_p(CODEC_FB_CLK_P),
      .tx_clk_n(CODEC_FB_CLK_N),
      .tx_frame_p(TX_FRAME_P),
      .tx_frame_n(TX_FRAME_N),
      .tx_d_p(TX_DATA_P),
      .tx_d_n(TX_DATA_N)
   );

   ///////////////////////////////////////////////////////////////////////
   // LED's on SFPs
   ///////////////////////////////////////////////////////////////////////
   wire [15:0] leds;
   assign {LED_ACT1, LED_ACT2, LED_LINK1, LED_LINK2} = ~leds[3:0];

   ///////////////////////////////////////////////////////////////////////
   // SPI connections
   ///////////////////////////////////////////////////////////////////////
   wire mosi, miso, sclk;
   wire [7:0] sen; // More cs_n than we need
   assign CODEC_CE = sen[0] /*& fx3_ce*/;
   assign CODEC_MOSI = ~sen[0] & mosi;
   assign CODEC_SCLK = ~sen[0] & sclk;
   assign miso = CODEC_MISO; // Only Catalina generates SPI read data.
  // assign fx3_miso = ~fx3_ce & CODEC_MISO;
   assign PLL_CE = sen[1];
   assign PLL_MOSI = ~sen[1] & mosi;
   assign PLL_SCLK = ~sen[1] & sclk;


   ///////////////////////////////////////////////////////////////////////
   // frontend assignments
   ///////////////////////////////////////////////////////////////////////
   wire [31:0] fe_atr1, fe_atr2;

   assign {TX_ENABLE1, SFDX1_RX, SFDX1_TX, SRX1_RX, SRX1_TX} = fe_atr1[7:3];
   assign LED_RX1        = fe_atr1[2];
   assign LED_TXRX1_RX   = fe_atr1[1];
   assign LED_TXRX1_TX   = fe_atr1[0];
   assign {TX_ENABLE2, SFDX2_RX, SFDX2_TX, SRX2_RX, SRX2_TX} = fe_atr2[7:3];
   assign LED_RX2        = fe_atr2[2];
   assign LED_TXRX2_RX   = fe_atr2[1];
   assign LED_TXRX2_TX   = fe_atr2[0];

   wire [31:0] misc_outs;
   reg [31:0]  misc_outs_r;
   always @(posedge bus_clk)
      misc_outs_r <= misc_outs; //register misc ios to ease routing to flop

   assign {TX_BANDSEL_A, TX_BANDSEL_B, RX_BANDSEL_A, RX_BANDSEL_B, RX_BANDSEL_C,  REF_SEL} = misc_outs_r[5:0];

   reg [2:0]   radio_control_r;
   always @(posedge bus_clk)
      radio_control_r <= radio_control;

   assign {codec_arst, mimo} =  radio_control_r[1:0];

   //
   // Catalina Control Signals -TODO. Review for Helium
   //
   OBUF pin_codec_ctrl_in_0 (.I(1'b1), .O(CODEC_CTRL_IN[0]));
   OBUF pin_codec_ctrl_in_1 (.I(1'b1), .O(CODEC_CTRL_IN[1]));
   OBUF pin_codec_ctrl_in_2 (.I(1'b1), .O(CODEC_CTRL_IN[2]));
   OBUF pin_codec_ctrl_in_3 (.I(1'b1), .O(CODEC_CTRL_IN[3]));

   OBUF pin_codec_en_agc    (.I(1'b1), .O(CODEC_EN_AGC));
   OBUF pin_codec_txrx      (.I(1'b1), .O(CODEC_TXRX));
   OBUF pin_codec_enable    (.I(1'b1), .O(CODEC_ENABLE));
   OBUF pin_codec_reset     (.I(!reset_global), .O(CODEC_RESET));
   OBUF pin_codec_sync      (.I(1'b0), .O(CODEC_SYNC));

   wire spiflash_clk;

   //  since CCLK is dedicated, need to use STARTUPE2 macro to drive it after config
   STARTUPE2 #(
      .PROG_USR("FALSE"), .SIM_CCLK_FREQ(10.0)
   ) STARTUPE2_i0 (
      // Outputs
      .CFGCLK(),
      .CFGMCLK(),
      .EOS(),
      .PREQ(),
      // Inputs
      .CLK(1'b0),
      .GSR(1'b0),
      .GTS(1'b0),
      .KEYCLEARB(1'b0),
      .PACK(1'b0),
      .USRCCLKO(spiflash_clk),
      .USRCCLKTS(1'b0),
      .USRDONEO(1'b0),
      .USRDONETS(1'b1)
   );

   ///////////////////////////////////////////////////////////////////////
   // Helium core - TODO pinout
   ///////////////////////////////////////////////////////////////////////

   wire        gmii_rx_dv0, gmii_rx_er0;
   wire [7:0]  gmii_rxd0;
   wire        gmii_tx_en0, gmii_tx_er0;
   wire [7:0]  gmii_txd0;
   wire [15:0] gmii_status0;
   wire        mdc0, mdio_in0, mdio_out0;

   wire        gmii_rx_dv1, gmii_rx_er1;
   wire [7:0]  gmii_rxd1;
   wire        gmii_tx_en1, gmii_tx_er1;
   wire [7:0]  gmii_txd1;
   wire [15:0] gmii_status1;
   wire        mdc1, mdio_in1, mdio_out1;

   n230_core n230_core (
      //------------------------------------------------------------------
      // bus interfaces
      //------------------------------------------------------------------
      .bus_clk(bus_clk),
      .bus_rst(bus_rst),

      //------------------------------------------------------------------
      // Configuration SPI Flash interface
      //------------------------------------------------------------------
      .spiflash_cs(SPIFLASH_CS),
      .spiflash_clk(spiflash_clk),
      .spiflash_miso(SPIFLASH_MISO),
      .spiflash_mosi(SPIFLASH_MOSI),

      //------------------------------------------------------------------
      // radio interfaces
      //------------------------------------------------------------------
      .radio_clk(radio_clk),
      .radio_rst(radio_rst),

      .rx0(rx_data0),
      .rx1(rx_data1),
      .tx0(tx_data0),
      .tx1(tx_data1),
      .fe_atr0(fe_atr1),
      .fe_atr1(fe_atr2),
      .pps_int(PPS_IN_INT),
      .pps_ext(PPS_IN_EXT),

      //------------------------------------------------------------------
      // gpsdo uart
      //------------------------------------------------------------------
      .gpsdo_rxd(GPS_TXD), // STUPID NAMING SWAP
      .gpsdo_txd(GPS_RXD), // STUPID NAMING SWAP
      //------------------------------------------------------------------
      // core interfaces
      //------------------------------------------------------------------
      .sen(sen),
      .sclk(sclk),
      .mosi(mosi),
      .miso(miso),
      .rb_misc({31'b0, PLL_LOCK}),        // Add misc signals to observe here.
      .misc_outs(misc_outs),
      .sw_rst(sw_rst),
      .radio_control(radio_control),
      //------------------------------------------------------------------
      // SFP interface 0 (Supporting signals)
      //------------------------------------------------------------------
      .SFP0_ModAbs(SFP0_MODABS),
      .SFP0_TxFault(SFP0_TXFAULT),
      .SFP0_RxLOS(SFP0_RXLOS),
      .SFP0_RS0(SFP0_RS0),
      .SFP0_RS1(SFP0_RS1),
      .SFP0_SCL(SFP0_SCL),
      .SFP0_SDA(SFP0_SDA),
      //------------------------------------------------------------------
      // SFP interface 1 (Supporting signals)
      //------------------------------------------------------------------
      .SFP1_ModAbs(SFP1_MODABS),
      .SFP1_TxFault(SFP1_TXFAULT),
      .SFP1_RxLOS(SFP1_RXLOS),
      .SFP1_RS0(SFP1_RS0),
      .SFP1_RS1(SFP1_RS1),
      .SFP1_SCL(SFP1_SCL),
      .SFP1_SDA(SFP1_SDA),
      //------------------------------------------------------------------
      // GMII interface 0 to PHY
      //------------------------------------------------------------------
      .gmii_clk0(gmii_clk),
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
      .gmii_clk1(gmii_clk),
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
      // External ZBT SRAM FIFO
      //------------------------------------------------------------------
      .ef0i_tdata(ef0o_tdata),
      .ef0i_tlast(ef0o_tlast),
      .ef0i_tvalid(ef0o_tvalid),
      .ef0i_tready(ef0o_tready),
      .ef0o_tdata(ef0i_tdata),
      .ef0o_tlast(ef0i_tlast),
      .ef0o_tvalid(ef0i_tvalid),
      .ef0o_tready(ef0i_tready),

      .ef1i_tdata(ef1o_tdata),
      .ef1i_tlast(ef1o_tlast),
      .ef1i_tvalid(ef1o_tvalid),
      .ef1i_tready(ef1o_tready),
      .ef1o_tdata(ef1i_tdata),
      .ef1o_tlast(ef1i_tlast),
      .ef1o_tvalid(ef1i_tvalid),
      .ef1o_tready(ef1i_tready),

      .ef_bist_done(ef_bist_done),
      .ef_bist_error(ef_bist_error),
      //------------------------------------------------------------------
      // I/O Delay Control Interface
      //------------------------------------------------------------------
      .ctrl_data_delay(ctrl_data_delay),
      .ctrl_clk_delay(ctrl_clk_delay),
      .ctrl_ld_data_delay(ctrl_ld_data_delay),
      .ctrl_ld_clk_delay(ctrl_ld_clk_delay),
      //------------------------------------------------------------------
      // LED's
      //------------------------------------------------------------------
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
      // debug UART
      //------------------------------------------------------------------
      .debug_txd(FPGA_TXD0),
      .debug_rxd(FPGA_RXD0)
   );

   wire        ge_phy_resetdone0, ge_phy_resetdone1;

   OBUF pin_SFP0_TxDisable (.I(1'b0), .O(SFP0_TXDISABLE));
   OBUF pin_SFP1_TxDisable (.I(1'b0), .O(SFP1_TXDISABLE));

   eth_jesd_gtp_phy quad_phy_i (
      .areset(reset_global | sw_rst[0]),
      .independent_clock(bus_clk),

      .gtrefclk0_p(SFPX_CLK_P), .gtrefclk0_n(SFPX_CLK_N),
      .gtrefclk1_p(CODEC_LOOP_CLK_IN_P), .gtrefclk1_n(CODEC_LOOP_CLK_IN_N),

      .sfp0rx_p(SFP0_RX_P), .sfp0rx_n(SFP0_RX_N),
      .sfp0tx_p(SFP0_TX_P), .sfp0tx_n(SFP0_TX_N),
      .sfp1rx_p(SFP1_RX_P), .sfp1rx_n(SFP1_RX_N),
      .sfp1tx_p(SFP1_TX_P), .sfp1tx_n(SFP1_TX_N),

      .jesd0rx_p(JESD0_RX_P), .jesd0rx_n(JESD0_RX_N),
      .jesd0tx_p(JESD0_TX_P), .jesd0tx_n(JESD0_TX_N),
      .jesd1rx_p(JESD1_RX_P), .jesd1rx_n(JESD1_RX_N),
      .jesd1tx_p(JESD1_TX_P), .jesd1tx_n(JESD1_TX_N),

      .eth_gtrefclk_bufg(),
      .gmii_clk(gmii_clk),

      .eth0gmii_txd(gmii_txd0),              // Transmit data from client MAC. [7:0]
      .eth0gmii_tx_en(gmii_tx_en0),            // Transmit control signal from client MAC.
      .eth0gmii_tx_er(gmii_tx_er0),            // Transmit control signal from client MAC.
      .eth0gmii_rxd(gmii_rxd0),              // Received Data to client MAC. [7:0]
      .eth0gmii_rx_dv(gmii_rx_dv0),            // Received control signal to client MAC.
      .eth0gmii_rx_er(gmii_rx_er0),            // Received control signal to client MAC.
      .eth0gmii_isolate(),          // Tristate control to electrically isolate GMII.

      .eth0mdc(mdc0),                   // Management Data Clock
      .eth0mdio_i(mdio_in0),                // Management Data In
      .eth0mdio_o(mdio_out0),                // Management Data Out

      .eth0status_vector(gmii_status0),
      .eth0signal_detect(~SFP0_RXLOS),
      .eth0resetdone(ge_phy_resetdone0),

      .eth1gmii_txd(gmii_txd1),              // Transmit data from client MAC. [7:0]
      .eth1gmii_tx_en(gmii_tx_en1),            // Transmit control signal from client MAC.
      .eth1gmii_tx_er(gmii_tx_er1),            // Transmit control signal from client MAC.
      .eth1gmii_rxd(gmii_rxd1),              // Received Data to client MAC. [7:0]
      .eth1gmii_rx_dv(gmii_rx_dv1),            // Received control signal to client MAC.
      .eth1gmii_rx_er(gmii_rx_er1),            // Received control signal to client MAC.
      .eth1gmii_isolate(),          // Tristate control to electrically isolate GMII.

      .eth1mdc(mdc1),                   // Management Data Clock
      .eth1mdio_i(mdio_in1),                // Management Data In
      .eth1mdio_o(mdio_out1),                // Management Data Out

      .eth1status_vector(gmii_status1),
      .eth1signal_detect(~SFP1_RXLOS),
      .eth1resetdone(ge_phy_resetdone1),
      
      .jesd_coreclk(clk100),
      .jesd_clk(),

      .jesd0txdata(32'hCCCCCCCC),
      .jesd0txcharisk(4'b0000),
      .jesd0rxdata(),
      .jesd0rxcharisk(),
      .jesd0rxdisperr(),
      .jesd0rxnotintable(),
      .jesd0resetdone(),

      .jesd1txdata(32'h55555555),
      .jesd1txcharisk(4'b0000),
      .jesd1rxdata(),
      .jesd1rxcharisk(),
      .jesd1rxdisperr(),
      .jesd1rxnotintable(),
      .jesd1resetdone()
   );


   ///////////////////////////////////////////////////////////////////////
   // Debug port
   ///////////////////////////////////////////////////////////////////////
   assign DEBUG = {rx_i1[11:4], rx_q0[11:0], rx_i0[11:0]};
   //assign DEBUG_CLK[1:0] = 2'b0;
   ODDR #(.DDR_CLK_EDGE("SAME_EDGE")) dbg_clk_out_i0
     (.Q(DEBUG_CLK[0]), .C(bus_clk), .CE(1'b1), .D1(1'b0), .D2(1'b1), .R(1'b0), .S(1'b0));
   ODDR #(.DDR_CLK_EDGE("SAME_EDGE")) dbg_clk_out_i1
     (.Q(DEBUG_CLK[1]), .C(radio_clk), .CE(1'b1), .D1(1'b0), .D2(1'b1), .R(1'b0), .S(1'b0));

endmodule // N230
