module n230_core_tb
  (
   );

   //------------------------------------------------------------------
   // bus interfaces
   //------------------------------------------------------------------
   reg bus_clk;
   reg bus_rst;

   //------------------------------------------------------------------
   // Configuration SPI Flash interface
   //------------------------------------------------------------------
   wire spiflash_cs; 
   wire spiflash_clk; 
   wire spiflash_miso; 
   wire spiflash_mosi;
   

   //------------------------------------------------------------------
   // radio interfaces
   //------------------------------------------------------------------
   reg radio_clk;
   reg radio_rst;

   wire [31:0] rx0; 
   wire [31:0] rx1;
   wire [31:0] tx0; 
   wire [31:0] tx1;
   wire [31:0] fe_atr0;
   wire [31:0] fe_atr1;
   wire        pps_int; 
   wire        pps_ext;

   //------------------------------------------------------------------
   // gpsdo uart
   //------------------------------------------------------------------
   wire        gpsdo_rxd;
   wire        gpsdo_txd;

   //------------------------------------------------------------------
   // core interfaces
   //------------------------------------------------------------------
   wire [7:0]  sen; 
   wire        sclk; 
   wire        mosi; 
   wire        miso;
   wire [31:0] rb_misc;
   wire [31:0] misc_outs;

   //------------------------------------------------------------------
   // SFP interface 0 (Supporting signals)
   //------------------------------------------------------------------
   wire        SFP0_ModAbs;
   wire        SFP0_TxFault; 
   wire        SFP0_RxLOS;
   wire        SFP0_RS0;
   wire        SFP0_RS1;
   
   //------------------------------------------------------------------
   // SFP interface 1 (Supporting signals)
   //------------------------------------------------------------------
   wire        SFP1_ModAbs;
   wire        SFP1_TxFault; 
   wire        SFP1_RxLOS;
   wire        SFP1_RS0;
   wire        SFP1_RS1;

   //------------------------------------------------------------------
   // GMII interface 0 to PHY
   //------------------------------------------------------------------
   wire        gmii_clk0;
   wire [7:0]  gmii_txd0;
   wire        gmii_tx_en0;
   wire        gmii_tx_er0;
   wire [7:0]  gmii_rxd0;
   wire        gmii_rx_dv0;
   wire        gmii_rx_er0;  
   wire        mdc0;
   wire        mdio_in0;
   wire        mdio_out0;

   //------------------------------------------------------------------
   // GMII interface 1 to PHY
   //------------------------------------------------------------------
   wire        gmii_clk1;
   wire [7:0]  gmii_txd1;
   wire        gmii_tx_en1;
   wire        gmii_tx_er1;
   wire [7:0]  gmii_rxd1;
   wire        gmii_rx_dv1;
   wire        gmii_rx_er1;
   wire        mdc1;
   wire        mdio_in1;
   wire        mdio_out1;
   //------------------------------------------------------------------
   // LED's
   //------------------------------------------------------------------     
   wire [15:0] leds;
   
   //------------------------------------------------------------------
   // debug UART
   //------------------------------------------------------------------
   wire        debug_txd; 
   wire        debug_rxd;
   wire [3:0]  sw_rst;
   
   //------------------------------------------------------------------
   // debug signals
   //------------------------------------------------------------------
   wire [63:0] debug;

   //------------------------------------------------------------------
   // Testbench Wishbone Bus - Drives TB peripherals from BFM
   //------------------------------------------------------------------
   wire [31:0] tb_uart_dat_o;
   reg [31:0]  tb_uart_dat_i, tb_uart_adr;
   reg 	       tb_uart_stb, tb_uart_cyc, tb_uart_we;
   wire        tb_uart_ack;
   
   
   //------------------------------------------------------------------
   //
   // IMPORTANT!!! Declare all Test Bench nets before here so they can be 
   // accessed from simulation scriots.
   //
   //------------------------------------------------------------------

   //------------------------------------------------------------------
   //
   // Simulation specific testbench is included here
   //
   //------------------------------------------------------------------
//`include "task_library.vh"
`include "math.v"
`include "n230_tasks.v"
`include "simulation_script.v"

   
   //------------------------------------------------------------------
   // Generate Clocks
   //------------------------------------------------------------------
   
   initial begin
      bus_clk <= 1'b1;
      radio_clk <= 1'b1;
   end
   
   // 125MHz clock
   always #4000 begin
      bus_clk <= ~bus_clk;
      radio_clk <= ~radio_clk;
   end
   
   //------------------------------------------------------------------
   // Good initial starting state
   //------------------------------------------------------------------
     initial begin
	bus_rst <= 0;
	radio_rst <= 0;
     end

   //------------------------------------------------------------------
   // Testbench UART - Driven from Wishbone BFM
   //------------------------------------------------------------------
   
   simple_uart tb_uart
     (
      .clk_i(bus_clk), .rst_i(bus_rst),
      .we_i(tb_uart_we), .stb_i(tb_uart_stb), .cyc_i(tb_uart_cyc), .ack_o(tb_uart_ack),
      .adr_i(tb_uart_adr[4:2]), .dat_i(tb_uart_dat_i), .dat_o(tb_uart_dat_o),
      .rx_int_o(), .tx_int_o(), 
      .tx_o(debug_rxd), .rx_i(debug_txd), // TX/RX crossed - We are talking to FPGA UART pins
      .baud_o()
      );

   localparam UART_CLKDIV = 0;
   localparam UART_TXLEVEL = 1;
   localparam UART_RXLEVEL = 2;
   localparam UART_TXCHAR = 3;
   localparam UART_RXCHAR = 4;
 
   integer    uart_file;
   integer    x;
   
   initial
     begin
	uart_file = $fopen("uart.log");
	
	// Wait for DUT reset to complete
	#1;
	$display("Start %d\n",$time);
	

	@(negedge bus_rst);
	$display("rst low %d\n",$time);
	@(posedge bus_clk);
	// Set UART Baud rate at 115Kbaud
	// CPU_CLOCK/BAUD_RATE
	// 125M/115200
	$display("About to prog uart %d\n",$time);
	
	write_tb_wb(UART_CLKDIV*4,32'h43d);
	$display("Wrote BAUD RATE\n");
	
	
	// Start testbench poll loop
	forever begin
	   // Is UART RX FIFO empty?
	   repeat(100) @(posedge bus_clk);
	   x = 0;
	   
	   read_tb_wb(UART_RXLEVEL*4,x);
	   $display("FIFO level:%d\n",x);
	   if (x > 0) begin
	      // Get next CHAR from UART RX FIFO.	      
	      read_tb_wb(UART_RXCHAR*4,x);
	      $display("Getting char from TB UART: %d\n",x);
	      // Print recevied chars both to simulation and log file.
	      $write("%c",x);
	      $fwrite(uart_file,"%c",x);
	   end 
	end
     end // initial begin


   //------------------------------------------------------------------
   // DUT
   //------------------------------------------------------------------
   wire WPNeg = 1'b1;
   wire HOLDNeg = 1'b1;


s25fl128s #(.UserPreload(1),
	       .mem_file_name("spi_flash.mem"),
	       .otp_file_name("none")
	       )

     s25fl128s 
       (
	// Data Inputs/Outputs
	.SI(spiflash_mosi),
	.SO(spiflash_miso),
	// Controls
	.SCK(spiflash_clk),
	.CSNeg(spiflash_cs),
	.RSTNeg(1'b1),    // Might rethink this
	.WPNeg(WPNeg),
	.HOLDNeg(HOLDNeg)
	);


   //------------------------------------------------------------------
   // DUT
   //------------------------------------------------------------------
   n230_core
     #(.EXTRA_BUFF_SIZE(0),.RADIO_FIFO_SIZE(12),.SAMPLE_FIFO_SIZE(11)) n230_core_i
       (
	//------------------------------------------------------------------
	// bus interfaces
	//------------------------------------------------------------------
	.bus_clk(bus_clk),
	.bus_rst(bus_rst),
	//------------------------------------------------------------------
	// Configuration SPI Flash interface
	//------------------------------------------------------------------
	.spiflash_cs(spiflash_cs), 
	.spiflash_clk(spiflash_clk), 
	.spiflash_miso(spiflash_miso), 
	.spiflash_mosi(spiflash_mosi),
	//------------------------------------------------------------------
	// radio interfaces
	//------------------------------------------------------------------   
	.radio_clk(radio_clk), 
	.radio_rst(radio_rst),
	.rx0(rx0),
	.tx0(tx0),
	.rx1(rx1),
	.tx1(tx1),
	.fe_atr0(fe_atr0),
	.fe_atr1(fe_atr1),
	.pps_int(pps_int),
	.pps_ext(pps_ext),
	//------------------------------------------------------------------
	// gpsdo uart
	//------------------------------------------------------------------
	.gpsdo_rxd(gpsd0_rxd),
	.gpsdo_txd(gpsdo_txd),	
	//------------------------------------------------------------------
	// core interfaces
	//------------------------------------------------------------------
	.sen(sen), 
	.sclk(sclk), 
	.mosi(mosi), 
	.miso(miso),
	.rb_misc(rb_misc),
	.misc_outs(misc_outs),	
	//------------------------------------------------------------------
	// SFP interface 0 (Supporting signals)
	//------------------------------------------------------------------ 
	.SFP0_SCL(SFP0_SCL),
	.SFP0_SDA(SFP0_SDA),
	.SFP0_ModAbs(SFP0_ModAbs),
	.SFP0_TxFault(SFP0_TxFault),
	.SFP0_RxLOS(SFP0_RxLOS),
	.SFP0_RS1(SFP0_RS1),
	.SFP0_RS0(SFP0_RS0),
	//------------------------------------------------------------------
	// SFP interface 1 (Supporting signals)
	//------------------------------------------------------------------
	.SFP1_SCL(SFP1_SCL),
	.SFP1_SDA(SFP1_SDA),
	.SFP1_ModAbs(SFP1_ModAbs),
	.SFP1_TxFault(SFP1_TxFault),
	.SFP1_RxLOS(SFP1_RxLOS),
	.SFP1_RS1(SFP1_RS1),
	.SFP1_RS0(SFP1_RS0),     
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
	.mdc0(mdc0),
	.mdio_in0(mdio_in0),
	.mdio_out0(mdio_out0),
	//------------------------------------------------------------------
	// GMII interface 1 to PHY
	//------------------------------------------------------------------  
	`ifdef ETH1G_PORT1
	.gmii_clk1(gmii_clk1),
	.gmii_txd1(gmii_txd1), 
	.gmii_tx_en1(gmii_tx_en1), 
	.gmii_tx_er1(gmii_tx_er1),
	.gmii_rxd1(gmii_rxd1), 
	.gmii_rx_dv1(gmii_rx_dv1), 
	.gmii_rx_er1(gmii_rx_er1),
	.mdc1(mdc1),
	.mdio_in1(mdio_in1),
	.mdio_out1(mdio_out1),
	`endif
	//------------------------------------------------------------------
	// External ZBT SRAM FIFO
	//------------------------------------------------------------------     
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
	//------------------------------------------------------------------
	// LED's
	//------------------------------------------------------------------     
	.leds(leds), 	
	//------------------------------------------------------------------
	// debug UART
	//------------------------------------------------------------------
	.debug_txd(debug_txd),
	.debug_rxd(debug_rxd),
	//------------------------------------------------------------------
	// Misc
	//------------------------------------------------------------------
	.sw_rst(sw_rst),
	//------------------------------------------------------------------
	// debug signals
	//------------------------------------------------------------------
	.debug()
	);

`ifdef ASCII_DEBUG
   integer sim_count;
   
   initial
     sim_count = 32'd0;
   
   always @(posedge bus_clk) begin
      $display("Count: %d,  %b %b %b %b %b %h %h %h %d %d",
	       sim_count,
	       n230_core_i.zpu_subsystem_i0.rst,
	       n230_core_i.zpu_subsystem_i0.zpu_rst,
	       {n230_core_i.zpu_subsystem_i0.s0_stb,
		n230_core_i.zpu_subsystem_i0.s1_stb,
		n230_core_i.zpu_subsystem_i0.s2_stb,
		n230_core_i.zpu_subsystem_i0.s3_stb,
		n230_core_i.zpu_subsystem_i0.s4_stb,
		n230_core_i.zpu_subsystem_i0.s5_stb,
		n230_core_i.zpu_subsystem_i0.s6_stb,
		n230_core_i.zpu_subsystem_i0.s7_stb,
		n230_core_i.zpu_subsystem_i0.s8_stb,
		n230_core_i.zpu_subsystem_i0.s9_stb},
	       n230_core_i.zpu_subsystem_i0.m0_we,
	       n230_core_i.zpu_subsystem_i0.m0_ack,
	       n230_core_i.zpu_subsystem_i0.m0_adr,
	       n230_core_i.zpu_subsystem_i0.m0_dat_o,
	       n230_core_i.zpu_subsystem_i0.m0_dat_i,
	       n230_core_i.zpu_subsystem_i0.cpu_bldr_ctrl_state,
	       n230_core_i.zpu_subsystem_i0.cpu_adr
	       );
      sim_count = sim_count + 1;
      
   end // always @ (posedge clk)
		       `endif //  `ifdef ASCII_DEBUG

   initial begin
      $dumpfile("waves.vcd");
      $dumpvars(1,
		bus_clk,
		n230_core_i.zpu_subsystem_i0.rst,
		n230_core_i.zpu_subsystem_i0.zpu_rst,
		n230_core_i.zpu_subsystem_i0.s0_stb,
		n230_core_i.zpu_subsystem_i0.s1_stb,
		n230_core_i.zpu_subsystem_i0.s2_stb,
		n230_core_i.zpu_subsystem_i0.s3_stb,
		n230_core_i.zpu_subsystem_i0.s4_stb,
		n230_core_i.zpu_subsystem_i0.s5_stb,
		n230_core_i.zpu_subsystem_i0.s6_stb,
		n230_core_i.zpu_subsystem_i0.s7_stb,
		n230_core_i.zpu_subsystem_i0.s8_stb,
		n230_core_i.zpu_subsystem_i0.s9_stb,
		n230_core_i.zpu_subsystem_i0.m0_we,
		n230_core_i.zpu_subsystem_i0.m0_ack,
		n230_core_i.zpu_subsystem_i0.m0_adr,
		n230_core_i.zpu_subsystem_i0.m0_dat_o,
		n230_core_i.zpu_subsystem_i0.m0_dat_i,
		n230_core_i.zpu_subsystem_i0.cpu_bldr_ctrl_state,
		n230_core_i.zpu_subsystem_i0.cpu_adr,
		tb_uart_dat_o,
		tb_uart_dat_i, tb_uart_adr,
   		tb_uart_stb, tb_uart_cyc, tb_uart_we,
		tb_uart_ack
		);
   end // initial begin
   
  
   always @(debug_txd) begin
      $display("TXD changed: %b @ %d",debug_txd,$time);
   end

endmodule // n230_core_tb
