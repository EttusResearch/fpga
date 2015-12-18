//
// Production test JESD204 interface connector on N230 by looping back signals using
// standard Molex cable #:79576-2102 for Mini-SAS/iPass connectors.
// Try to make this as safe as possible for inadverantly connected H/W.
//

module n230_test_jesd204_if
  (
   input clk,
   input reset,
   input run,
   output reg done,
   output reg [15:0] status,
   
 inout RD1_ET_SPI_SCLK,     // A5 1.8V
 inout RD1_ET_SPI_SDIN,     // A6 1.8V
 input RD1_ET_FRAME_CLKp,    // B5 2.5V
 input RD1_ET_FRAME_CLKn,    // B6 2.5V
 inout RD1_RX_TX_LOOPBACK,  // A8 3.3V
 inout RD1_TEMP_SDA,        // A9 3.3V
 input RD1_RFPWR_SDO,        // B8 3.3V
 input RD1_RFPWR_SCLK,       // B9 3.3V
 inout RD1_ET_SPI_SDOUT,    // A13 1.8V
 inout RD1_ET_SPI_SDEN,     // A14 1.8V
 input RD1_ET_ALARM,         // B13 1.8V
 input RD1_ET_WARNING,       // B14 1.8V
 inout RD1_ICSP_CLK,        // A16 1.8V
 inout RD1_ICSP_DAT,        // A17 1.8V
 input RD1_SLEEP,            // B16 1.8V
 input RD1_P_READY,          // B17 1.8V
   
 inout RD2_ET_SPI_SCLK,     // A5 1.8V
 inout RD2_ET_SPI_SDIN,     // A6 1.8V
 input RD2_ET_FRAME_CLKp,    // B5 2.5V
 input RD2_ET_FRAME_CLKn,    // B6 2.5V
 inout RD2_RX_TX_LOOPBACK,  // A8 3.3V
 inout RD2_TEMP_SDA,        // A9 3.3V
 input RD2_RFPWR_SDO,        // B8 3.3V
 input RD2_RFPWR_SCLK,       // B9 3.3V
 inout RD2_ET_SPI_SDOUT,    // A13 1.8V
 inout RD2_ET_SPI_SDEN,     // A14 1.8V
 input RD2_ET_ALARM,         // B13 1.8V
 input RD2_ET_WARNING,       // B14 1.8V
 inout RD2_ICSP_CLK,        // A16 1.8V
 inout RD2_ICSP_DAT,        // A17 1.8V
 input RD2_SLEEP,            // B16 1.8V
 input RD2_P_READY          // B17 1.8V
   
   );

   localparam IDLE = 0;
   localparam RUN1 = 1;
   localparam RUN2 = 2;
   localparam RUN3 = 3;
   localparam RUN4 = 4;
   localparam RUN5 = 5;
   localparam RUN6 = 6;  
   localparam RUN7 = 7;
   localparam RUN8 = 8;
   localparam RUN9 = 9;
   localparam RUN10 = 10;  
   localparam RUN11 = 11;
   localparam RUN12 = 12;
   localparam RUN13 = 13;
   localparam RUN14 = 14;   
   localparam DONE = 15;
   
   reg [3:0]  state;
   reg [3:0]  count;
   
   
   reg 	      tristate = 1;
   
   reg 	      RD1_ET_SPI_SCLK_out;     // A5 1.8V
   reg 	      RD1_ET_SPI_SDIN_out;     // A6 1.8V 
   reg 	      RD1_RX_TX_LOOPBACK_out;  // A8 3.3V
   reg 	      RD1_TEMP_SDA_out;        // A9 3.3V 
   reg 	      RD1_ET_SPI_SDOUT_out;    // A13 1.8V
   reg 	      RD1_ET_SPI_SDEN_out;     // A14 1.8V
   reg 	      RD1_ICSP_CLK_out;        // A16 1.8V
   reg 	      RD1_ICSP_DAT_out;        // A17 1.8V   
   reg 	      RD2_ET_SPI_SCLK_out;     // A5 1.8V
   reg 	      RD2_ET_SPI_SDIN_out;     // A6 1.8V
   reg 	      RD2_RX_TX_LOOPBACK_out;  // A8 3.3V
   reg 	      RD2_TEMP_SDA_out;        // A9 3.3V  
   reg 	      RD2_ET_SPI_SDOUT_out;    // A13 1.8V
   reg 	      RD2_ET_SPI_SDEN_out;     // A14 1.8V 
   reg 	      RD2_ICSP_CLK_out;        // A16 1.8V
   reg 	      RD2_ICSP_DAT_out;        // A17 1.8V

   reg 	      // J605
	      RD2_ET_FRAME_CLKp_in,    // B5 2.5V
	      RD2_ET_FRAME_CLKn_in,    // B6 2.5V  
	      RD2_RFPWR_SDO_in,        // B8 3.3V
	      RD2_RFPWR_SCLK_in,       // B9 3.3V  
	      RD2_ET_ALARM_in,         // B13 1.8V
	      RD2_ET_WARNING_in,       // B14 1.8V 
	      RD2_SLEEP_in,            // B16 1.8V
	      RD2_P_READY_in,          // B17 1.8V
	      // J603
	      RD1_ET_FRAME_CLKp_in,    // B5 2.5V
	      RD1_ET_FRAME_CLKn_in,    // B6 2.5V 
	      RD1_RFPWR_SDO_in,        // B8 3.3V
	      RD1_RFPWR_SCLK_in,       // B9 3.3V  
	      RD1_ET_ALARM_in,         // B13 1.8V
	      RD1_ET_WARNING_in,       // B14 1.8V  
	      RD1_SLEEP_in,            // B16 1.8V
	      RD1_P_READY_in;          // B17 1.8V  	

   always @(posedge clk)
     {
      // J605
      RD2_ET_FRAME_CLKp_in,    // B5 2.5V
      RD2_ET_FRAME_CLKn_in,    // B6 2.5V  
      RD2_RFPWR_SDO_in,        // B8 3.3V
      RD2_RFPWR_SCLK_in,       // B9 3.3V  
      RD2_ET_ALARM_in,         // B13 1.8V
      RD2_ET_WARNING_in,       // B14 1.8V 
      RD2_SLEEP_in,            // B16 1.8V
      RD2_P_READY_in,          // B17 1.8V
      // J603
      RD1_ET_FRAME_CLKp_in,    // B5 2.5V
      RD1_ET_FRAME_CLKn_in,    // B6 2.5V 
      RD1_RFPWR_SDO_in,        // B8 3.3V
      RD1_RFPWR_SCLK_in,       // B9 3.3V  
      RD1_ET_ALARM_in,         // B13 1.8V
      RD1_ET_WARNING_in,       // B14 1.8V  
      RD1_SLEEP_in,            // B16 1.8V
      RD1_P_READY_in}           // B17 1.8V  	
       <= {
	   // J605
	   RD2_ET_FRAME_CLKp,    // B5 2.5V
	   RD2_ET_FRAME_CLKn,    // B6 2.5V  
	   RD2_RFPWR_SDO,        // B8 3.3V
	   RD2_RFPWR_SCLK,       // B9 3.3V  
	   RD2_ET_ALARM,         // B13 1.8V
	   RD2_ET_WARNING,       // B14 1.8V 
	   RD2_SLEEP,            // B16 1.8V
	   RD2_P_READY,          // B17 1.8V
	   // J603
	   RD1_ET_FRAME_CLKp,    // B5 2.5V
	   RD1_ET_FRAME_CLKn,    // B6 2.5V 
	   RD1_RFPWR_SDO,        // B8 3.3V
	   RD1_RFPWR_SCLK,       // B9 3.3V  
	   RD1_ET_ALARM,         // B13 1.8V
	   RD1_ET_WARNING,       // B14 1.8V  
	   RD1_SLEEP,            // B16 1.8V
	   RD1_P_READY};          // B17 1.8V

   
   assign     RD1_ET_SPI_SCLK = tristate ? 1'bz : RD1_ET_SPI_SCLK_out ;     // A5 1.8V
   assign     RD1_ET_SPI_SDIN = tristate ? 1'bz : RD1_ET_SPI_SDIN_out ;     // A6 1.8V
   
   assign     RD1_RX_TX_LOOPBACK = tristate ? 1'bz : RD1_RX_TX_LOOPBACK_out ;  // A8 3.3V
   assign     RD1_TEMP_SDA = tristate ? 1'bz : RD1_TEMP_SDA_out  ;              // A9 3.3V
   
   assign     RD1_ET_SPI_SDOUT = tristate ? 1'bz : RD1_ET_SPI_SDOUT_out;    // A13 1.8V
   assign     RD1_ET_SPI_SDEN = tristate ? 1'bz : RD1_ET_SPI_SDEN_out;      // A14 1.8V

   assign     RD1_ICSP_CLK = tristate ? 1'bz : RD1_ICSP_CLK_out;        // A16 1.8V
   assign     RD1_ICSP_DAT = tristate ? 1'bz : RD1_ICSP_DAT_out;        // A17 1.8V
   
   assign     RD2_ET_SPI_SCLK = tristate ? 1'bz : RD2_ET_SPI_SCLK_out;     // A5 1.8V
   assign     RD2_ET_SPI_SDIN = tristate ? 1'bz : RD2_ET_SPI_SDIN_out;     // A6 1.8V
   
   assign     RD2_RX_TX_LOOPBACK = tristate ? 1'bz : RD2_RX_TX_LOOPBACK_out;  // A8 3.3V
   assign     RD2_TEMP_SDA = tristate ? 1'bz : RD2_TEMP_SDA_out;              // A9 3.3V
   
   assign     RD2_ET_SPI_SDOUT = tristate ? 1'bz : RD2_ET_SPI_SDOUT_out;    // A13 1.8V
   assign     RD2_ET_SPI_SDEN = tristate ? 1'bz : RD2_ET_SPI_SDEN_out;      // A14 1.8V
   
   assign     RD2_ICSP_CLK = tristate ? 1'bz : RD2_ICSP_CLK_out;        // A16 1.8V
   assign     RD2_ICSP_DAT = tristate ? 1'bz : RD2_ICSP_DAT_out;        // A17 1.8V

   always @(posedge clk)
     if (reset || !run) begin
	state <= IDLE;
	done <= 1'b0;
	status <= 16'h0;
	tristate <= 1'b1;
	count <= 4'h0;
     end else 
       case (state)
	 // Hang out in this state unless test has been activated.
	 // In this state all pins on the JESD204 connector are forced to be inputs
	 // with resistive pullup's so that no connected equipemnt can be damaged (hopeully!)
	 // and there are no mid-threshold signals burning obsene power.
	 IDLE: begin
	    done <= 1'b0;
	    status <= 16'h0;
	    tristate <= 1'b1;
	    if (run) begin
	       tristate <= 1'b0;
	       {
		// J603
		RD1_ET_SPI_SCLK_out,     // A5 1.8V
    		RD1_ET_SPI_SDIN_out,     // A6 1.8V 
    		RD1_RX_TX_LOOPBACK_out,  // A8 3.3V
    		RD1_TEMP_SDA_out,        // A9 3.3V 
    		RD1_ET_SPI_SDOUT_out,    // A13 1.8V
    		RD1_ET_SPI_SDEN_out,     // A14 1.8V
    		RD1_ICSP_CLK_out,        // A16 1.8V
    		RD1_ICSP_DAT_out,        // A17 1.8V
		// J605
    		RD2_ET_SPI_SCLK_out,     // A5 1.8V
    		RD2_ET_SPI_SDIN_out,     // A6 1.8V
    		RD2_RX_TX_LOOPBACK_out,  // A8 3.3V
    		RD2_TEMP_SDA_out,        // A9 3.3V  
    		RD2_ET_SPI_SDOUT_out,    // A13 1.8V
    		RD2_ET_SPI_SDEN_out,     // A14 1.8V 
    		RD2_ICSP_CLK_out,        // A16 1.8V
    		RD2_ICSP_DAT_out         // A17 1.8V
		} <= 16'b1010_1010_1010_1010;
	       state <= RUN1;
	       count <= 4'd15;
	    end
	    else
	      state <= IDLE;
	 end
	 // Turn on drivers for "A-side" pins on both min-SAS connectors, "B-side" pins are always inputs for test.
	 // Drive alternate 1/0 across loopback cable.
	 // Cycle 2 driving 0xAAAA
	 RUN1: begin
	    done <= 1'b0;
	    tristate <= 1'b0;
	    {
	     // J603
	     RD1_ET_SPI_SCLK_out,     // A5 1.8V
    	     RD1_ET_SPI_SDIN_out,     // A6 1.8V 
    	     RD1_RX_TX_LOOPBACK_out,  // A8 3.3V
    	     RD1_TEMP_SDA_out,        // A9 3.3V 
    	     RD1_ET_SPI_SDOUT_out,    // A13 1.8V
    	     RD1_ET_SPI_SDEN_out,     // A14 1.8V
    	     RD1_ICSP_CLK_out,        // A16 1.8V
    	     RD1_ICSP_DAT_out,        // A17 1.8V
	     // J605
    	     RD2_ET_SPI_SCLK_out,     // A5 1.8V
    	     RD2_ET_SPI_SDIN_out,     // A6 1.8V
    	     RD2_RX_TX_LOOPBACK_out,  // A8 3.3V
    	     RD2_TEMP_SDA_out,        // A9 3.3V  
    	     RD2_ET_SPI_SDOUT_out,    // A13 1.8V
    	     RD2_ET_SPI_SDEN_out,     // A14 1.8V 
    	     RD2_ICSP_CLK_out,        // A16 1.8V
    	     RD2_ICSP_DAT_out         // A17 1.8V
	     } <= 16'b1010_1010_1010_1010;
	    
	    if (count == 4'd0)
	      state <= RUN2;
	    else
	      count <= count - 4'd1;
	    
	 end
	 

	 // Check loopback signals
	 // Drive new 0/1 pattern next cycle.

	 RUN2: begin
	    done <= 1'b0;
	    tristate <= 1'b0;
	    {
	     // J603
	     RD1_ET_SPI_SCLK_out,     // A5 1.8V
    	     RD1_ET_SPI_SDIN_out,     // A6 1.8V 
    	     RD1_RX_TX_LOOPBACK_out,  // A8 3.3V
    	     RD1_TEMP_SDA_out,        // A9 3.3V 
    	     RD1_ET_SPI_SDOUT_out,    // A13 1.8V
    	     RD1_ET_SPI_SDEN_out,     // A14 1.8V
    	     RD1_ICSP_CLK_out,        // A16 1.8V
    	     RD1_ICSP_DAT_out,        // A17 1.8V
	     // J605
    	     RD2_ET_SPI_SCLK_out,     // A5 1.8V
    	     RD2_ET_SPI_SDIN_out,     // A6 1.8V
    	     RD2_RX_TX_LOOPBACK_out,  // A8 3.3V
    	     RD2_TEMP_SDA_out,        // A9 3.3V  
    	     RD2_ET_SPI_SDOUT_out,    // A13 1.8V
    	     RD2_ET_SPI_SDEN_out,     // A14 1.8V 
    	     RD2_ICSP_CLK_out,        // A16 1.8V
    	     RD2_ICSP_DAT_out         // A17 1.8V
	     } <= 16'b0101_0101_0101_0101;
	    
	     status <=  16'b1010_1010_1010_1010 ^
		       {
			// J605
			RD2_ET_FRAME_CLKp_in,    // B5 2.5V
			RD2_ET_FRAME_CLKn_in,    // B6 2.5V  
			RD2_RFPWR_SDO_in,        // B8 3.3V
			RD2_RFPWR_SCLK_in,       // B9 3.3V  
			RD2_ET_ALARM_in,         // B13 1.8V
			RD2_ET_WARNING_in,       // B14 1.8V 
			RD2_SLEEP_in,            // B16 1.8V
			RD2_P_READY_in,          // B17 1.8V
			// J603
			RD1_ET_FRAME_CLKp_in,    // B5 2.5V
			RD1_ET_FRAME_CLKn_in,    // B6 2.5V 
			RD1_RFPWR_SDO_in,        // B8 3.3V
			RD1_RFPWR_SCLK_in,       // B9 3.3V  
			RD1_ET_ALARM_in,         // B13 1.8V
			RD1_ET_WARNING_in,       // B14 1.8V  
			RD1_SLEEP_in,            // B16 1.8V
			RD1_P_READY_in           // B17 1.8V  		
			};
	    
	    state <= RUN3;
	    count <= 4'd15;
	    
	 end // case: RUN2

	 // Continue to drive 0/1 pattern across connector so signals propagate and settle.
  	 RUN3: begin
	    done <= 1'b0;
	    tristate <= 1'b0;
	    {
	     // J603
	     RD1_ET_SPI_SCLK_out,     // A5 1.8V
    	     RD1_ET_SPI_SDIN_out,     // A6 1.8V 
    	     RD1_RX_TX_LOOPBACK_out,  // A8 3.3V
    	     RD1_TEMP_SDA_out,        // A9 3.3V 
    	     RD1_ET_SPI_SDOUT_out,    // A13 1.8V
    	     RD1_ET_SPI_SDEN_out,     // A14 1.8V
    	     RD1_ICSP_CLK_out,        // A16 1.8V
    	     RD1_ICSP_DAT_out,        // A17 1.8V
	     // J605
    	     RD2_ET_SPI_SCLK_out,     // A5 1.8V
    	     RD2_ET_SPI_SDIN_out,     // A6 1.8V
    	     RD2_RX_TX_LOOPBACK_out,  // A8 3.3V
    	     RD2_TEMP_SDA_out,        // A9 3.3V  
    	     RD2_ET_SPI_SDOUT_out,    // A13 1.8V
    	     RD2_ET_SPI_SDEN_out,     // A14 1.8V 
    	     RD2_ICSP_CLK_out,        // A16 1.8V
    	     RD2_ICSP_DAT_out         // A17 1.8V
	     } <= 16'b0101_0101_0101_0101;
	    
	    if (count == 4'd0)
	      state <= RUN4;
	    else
	      count <= count - 4'd1;
	    
	 end // case: RUN3

	 // Check loopback signals
	 // Tristate bus next cycle.
	 RUN4: begin
	    done <= 1'b0;
	    tristate <= 1'b1;
	    status <=  (16'b0101_0101_0101_0101 ^
			 {
			  // J605
			  RD2_ET_FRAME_CLKp_in,    // B5 2.5V
			  RD2_ET_FRAME_CLKn_in,    // B6 2.5V  
			  RD2_RFPWR_SDO_in,        // B8 3.3V
			  RD2_RFPWR_SCLK_in,       // B9 3.3V  
			  RD2_ET_ALARM_in,         // B13 1.8V
			  RD2_ET_WARNING_in,       // B14 1.8V 
			  RD2_SLEEP_in,            // B16 1.8V
			  RD2_P_READY_in,          // B17 1.8V
			  // J603
			  RD1_ET_FRAME_CLKp_in,    // B5 2.5V
			  RD1_ET_FRAME_CLKn_in,    // B6 2.5V 
			  RD1_RFPWR_SDO_in,        // B8 3.3V
			  RD1_RFPWR_SCLK_in,       // B9 3.3V  
			  RD1_ET_ALARM_in,         // B13 1.8V
			  RD1_ET_WARNING_in,       // B14 1.8V  
			  RD1_SLEEP_in,            // B16 1.8V
			  RD1_P_READY_in           // B17 1.8V  		
			  }) | status;

	    state <= DONE;
	 end // case: RUN4

	 // Wait in DONE state until run signal taken low again.
	 DONE: begin
	    done <= 1'b1;
	    tristate <= 1'b1;

	    if (run)
	      state <= DONE;
	    else
	      state <= IDLE;

	 end

	 default:
	   state <= IDLE;
	 
       endcase // case(state)
   
   /*******************************************************************
    * Debug only logic below here.
    ******************************************************************/

   (* keep = "true", max_fanout = 10 *) reg [15:0] status_reg;
   (* keep = "true", max_fanout = 10 *) reg done_reg;   
   (* keep = "true", max_fanout = 10 *) reg run_reg;
   (* keep = "true", max_fanout = 10 *) reg [31:0] pins;
   

   always @(posedge clk) begin
      status_reg <= status;
      done_reg <= done;
      run_reg <= run;
      pins <= {	       
               RD1_ET_SPI_SCLK_out,     // A5 1.8V
	       RD1_ET_SPI_SDIN_out,     // A6 1.8V
	       RD1_ET_FRAME_CLKp_in,    // B5 2.5V
	       RD1_ET_FRAME_CLKn_in,    // B6 2.5V
	       RD1_RX_TX_LOOPBACK_out,  // A8 3.3V
	       RD1_TEMP_SDA_out,        // A9 3.3V
	       RD1_RFPWR_SDO_in,        // B8 3.3V
	       RD1_RFPWR_SCLK_in,       // B9 3.3V
	       RD1_ET_SPI_SDOUT_out,    // A13 1.8V
	       RD1_ET_SPI_SDEN_out,     // A14 1.8V
	       RD1_ET_ALARM_in,         // B13 1.8V
	       RD1_ET_WARNING_in,       // B14 1.8V
	       RD1_ICSP_CLK_out,        // A16 1.8V
	       RD1_ICSP_DAT_out,        // A17 1.8V
	       RD1_SLEEP_in,            // B16 1.8V
	       RD1_P_READY_in,          // B17 1.8V
      
	       RD2_ET_SPI_SCLK_out,     // A5 1.8V
	       RD2_ET_SPI_SDIN_out,     // A6 1.8V
	       RD2_ET_FRAME_CLKp_in,    // B5 2.5V
	       RD2_ET_FRAME_CLKn_in,    // B6 2.5V
	       RD2_RX_TX_LOOPBACK_out,  // A8 3.3V
	       RD2_TEMP_SDA_out,        // A9 3.3V
	       RD2_RFPWR_SDO_in,        // B8 3.3V
	       RD2_RFPWR_SCLK_in,       // B9 3.3V
	       RD2_ET_SPI_SDOUT_out,    // A13 1.8V
	       RD2_ET_SPI_SDEN_out,     // A14 1.8V
	       RD2_ET_ALARM_in,         // B13 1.8V
	       RD2_ET_WARNING_in,       // B14 1.8V
	       RD2_ICSP_CLK_out,        // A16 1.8V
	       RD2_ICSP_DAT_out,        // A17 1.8V
	       RD2_SLEEP_in,            // B16 1.8V
	       RD2_P_READY_in           // B17 1.8V
		       };
      
   end

endmodule // n230_test_jesd204_if
