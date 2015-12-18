

module cat_io_lvds
  #(
    parameter INVERT_FRAME_RX = 0,
    parameter INVERT_DATA_RX = 6'b00_0000,
    parameter INVERT_FRAME_TX = 0,
    parameter INVERT_DATA_TX = 6'b00_0000,
    parameter INPUT_CLOCK_DELAY = 16,
    parameter INPUT_DATA_DELAY = 0,
    parameter OUTPUT_CLOCK_DELAY = 16,
    parameter OUTPUT_DATA_DELAY = 0
    )
   (input rst,
    input  mimo,
    input  clk200,
    // Delay Control Interface
    input ctrl_clk,
    input [4:0] ctrl_data_delay,
    input [4:0] ctrl_clk_delay,
    input ctrl_ld_data_delay,
    input ctrl_ld_clk_delay,
    // Baseband sample interface
    output radio_clk,
    output radio_clk_2x,
    output [11:0] rx_i0, 
    output [11:0] rx_q0, 
    output [11:0] rx_i1, 
    output [11:0] rx_q1,
    input [11:0] tx_i0, 
    input [11:0] tx_q0, 
    input [11:0] tx_i1, 
    input [11:0] tx_q1,
   
    // Catalina interface
    input rx_clk_p, 
    input rx_clk_n, 
    input rx_frame_p, 
    input rx_frame_n, 
    input [5:0] rx_d_p, 
    input [5:0] rx_d_n,
    output tx_clk_p, 
    output tx_clk_n, 
    output tx_frame_p, 
    output tx_frame_n, 
    output [5:0] tx_d_p, 
    output [5:0] tx_d_n
    );
   
   wire    sdr_clk, ddr_clk;
     
   //------------------------------------------------------------------
   // AD9361 Datasheet page 7:
   // DATA_CLK to DataBusOut (Tddrx): Min 0.25ns, Max 1.25nS
   //
   //------------------------------------------------------------------
   
   cat_input_lvds
     #(
       .INVERT_FRAME_RX(INVERT_FRAME_RX),
       .INVERT_DATA_RX(INVERT_DATA_RX),
       .CLOCK_DELAY(INPUT_CLOCK_DELAY), 
       .DATA_DELAY(INPUT_DATA_DELAY),
       .WIDTH(6),
       .GROUP("CATALINA")
       )
       cat_input_lvds_i0
	 (
	  .clk200(clk200),
	  .rst(rst),
	  .mimo(mimo),
	  // Region local Clocks for I/O cells.
	  .ddr_clk(ddr_clk),
	  .sdr_clk(sdr_clk),     
	  // Source Synchronous external input clock
	  .ddr_clk_p(rx_clk_p),
	  .ddr_clk_n(rx_clk_n),
	  // Source Synchronous data lines
	  .ddr_data_p(rx_d_p),
	  .ddr_data_n(rx_d_n),
	  .ddr_frame_p(rx_frame_p),
	  .ddr_frame_n(rx_frame_n),
	  // delay control interface
	  .ctrl_clk(ctrl_clk),
	  .ctrl_data_delay(ctrl_data_delay),
	  .ctrl_clk_delay(ctrl_clk_delay),
	  .ctrl_ld_data_delay(ctrl_ld_data_delay),
	  .ctrl_ld_clk_delay(ctrl_ld_clk_delay),
	  // SDR output clock(s)
	  .radio_clk(radio_clk),
	  .radio_clk_2x(radio_clk_2x),
	  // SDR Data buses
	  .i0(rx_i0),
	  .q0(rx_q0),
	  .i1(rx_i1),
	  .q1(rx_q1),
	  .rx_aligned()
	  );
   
   //------------------------------------------------------------------
   // AD9361 Interface Specification, page 22.
   // FBCLK is approximately data centered, must provide 1ns data setup and hold
   // when signals arrive at AD9361.
   // Therefore we delay FBCLK more than data to give 1nS setup:
   // 1 tap = 72pS. 1000/72 = ~14. Set delay at 16 taps.
   //------------------------------------------------------------------
   cat_output_lvds
     #(
       .INVERT_FRAME_TX(INVERT_FRAME_TX),
       .INVERT_DATA_TX(INVERT_DATA_TX),
       .CLOCK_DELAY(OUTPUT_CLOCK_DELAY),
       .DATA_DELAY(OUTPUT_DATA_DELAY),
       .WIDTH(6),
       .GROUP("CATALINA")
       )
       cat_output_lvds_i0
	 (
     	  .clk200(clk200),
   	  .rst(rst),
    	  .mimo(mimo),
	  // Region local Clocks for I/O cells.
          .ddr_clk(ddr_clk),
          .sdr_clk(sdr_clk),     
	  // Source Synchronous external input clock
 	  .ddr_clk_p(tx_clk_p),
   	  .ddr_clk_n(tx_clk_n),
	  // Source Synchronous data lines
    	  .ddr_data_p(tx_d_p),
  	  .ddr_data_n(tx_d_n),
   	  .ddr_frame_p(tx_frame_p),
  	  .ddr_frame_n(tx_frame_n),
	  // delay control interface
/* -----\/----- EXCLUDED -----\/-----
  	  .ctrl_clk(1'b0),
   	  .ctrl_rst(1'b0),
   	  .ctrl_en(1'b0),
   	  .ctrl_inc(1'b0),
 -----/\----- EXCLUDED -----/\----- */
	  // SDR global input clock
    	  .radio_clk(radio_clk),
	  // SDR Data buses
	  .i0(tx_i0),
	  .q0(tx_q0),
	  .i1(tx_i1),
	  .q1(tx_q1)
	  );

   
endmodule // cat_int_ddr_lvds
