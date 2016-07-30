`timescale 1ns/1ps

module cat_io_lvds_tb();

   wire GSR, GTS;
   glbl glbl( );

   reg 	clk    = 0;
   reg 	rx_clk = 0;
   reg 	reset;
   reg 	clk200 = 0;
   reg 	       mimo;
   reg [5:0]   rx_d;
   reg 	       rx_frame;
   reg [7:0]   count;
  

//   initial $dumpfile("catcap_ddr_lvds_tb.vcd");
//   initial $dumpvars(0,catcap_ddr_lvds_tb);

   wire [11:0] i0 = {4'hA,count};
   wire [11:0] q0 = {4'hB,count};
   wire [11:0] i1 = {4'hC,count};
   wire [11:0] q1 = {4'hD,count};

//   reg 	       tx_strobe;
   
   reg [11:0] tx_i0;
   reg [11:0] tx_q0;
   reg [11:0] tx_i1;
   reg [11:0] tx_q1;

   wire [11:0] rx_i0;
   wire [11:0] rx_q0;
   wire [11:0] rx_i1;
   wire [11:0] rx_q1;

   wire        tx_clk_p, tx_clk_n;
   wire        tx_frame_p, tx_frame_n;
   wire [5:0]  tx_d_p, tx_d_n;

   reg [4:0]  ctrl_data_delay;   
   reg [4:0]  ctrl_clk_delay;
   reg        ctrl_ld_data_delay;
   reg        ctrl_ld_clk_delay;
   
/*
   wire [11:0] i0 = {count,count};
   wire [11:0] q0 = {count,count};
   wire [11:0] i1 = {count,count};
   wire [11:0] q1 = {count,count};
*/
 
   always #100 clk = ~clk;
   always #2.5 clk200 = ~clk200;
   always @(negedge clk) rx_clk <= ~rx_clk;
   
   initial
     begin
	reset = 1;
//	mimo = 0;
	mimo = 1;
	ctrl_data_delay = 5'd0;
	ctrl_clk_delay = 5'd8;
	ctrl_ld_data_delay = 1'b0;
	ctrl_ld_clk_delay = 1'b0;
	repeat(10) @(negedge rx_clk);
	ctrl_ld_data_delay = 1'b1;
	ctrl_ld_clk_delay = 1'b1;
	@(negedge rx_clk);
	ctrl_ld_data_delay = 1'b0;
	ctrl_ld_clk_delay = 1'b0;
	#1000 reset = 0;
//	BURST(16);
//	#2000 reset = 1;
//	mimo = 1;	
//	#3000 reset = 0;	
	MIMO_BURST(30);
	#1000 reset = 1;
//	mimo = 0;
//	#3000 reset = 0;;
//	BURST(9);
	#1000 reset = 1;
	mimo = 0;
	#3000 reset = 0;
	MIMO_BURST(20);
	#2000;
	$finish;
     end
   /*
   task BURST;
      input [7:0] len;
      begin
	 @(posedge clk);
	 rx_frame <= 0;
	 @(posedge clk);
	 @(posedge clk);
	 @(posedge clk);
	 @(posedge clk);
	 @(posedge clk);
	 @(posedge rx_clk);
	 count <= 0;
	 repeat(len)
	   begin
	      @(posedge clk);
	      rx_d <= i0[11:6];
	      rx_frame <= 1;
	      @(posedge clk);
	      rx_d <= q0[11:6];
	      rx_frame <= 1;
	      @(posedge clk);
	      rx_d <= i0[5:0];
	      rx_frame <= 0;
	      @(posedge clk);
	      rx_d <= q0[5:0];
	      rx_frame <= 0;
	      count <= count + 1;
	   end
      end
   endtask // BURST
   */
   task MIMO_BURST;
      input [7:0] len;
      begin
	 @(posedge clk);
	 rx_frame <= 0;
	 @(posedge clk);
	 @(posedge clk);
	 @(posedge clk);
	 @(posedge clk);
	 @(posedge clk);
	 @(posedge rx_clk);
	 count <= 0;
	 repeat(len)
	   begin
	      @(posedge clk);
	      rx_d <= i0[11:6];
	      rx_frame <= 1;
	      @(posedge clk);
	      rx_d <= q0[11:6];
	      rx_frame <= 1;
	      @(posedge clk);
	      rx_d <= i0[5:0];
	      rx_frame <= 1;
	      @(posedge clk);
	      rx_d <= q0[5:0];
	      rx_frame <= 1;

	      @(posedge clk);
	      rx_d <= i1[11:6];
	      rx_frame <= 0;
	      @(posedge clk);
	      rx_d <= q1[11:6];
	      rx_frame <= 0;
	      @(posedge clk);
	      rx_d <= i1[5:0];
	      rx_frame <= 0;
	      @(posedge clk);
	      rx_d <= q1[5:0];
	      rx_frame <= 0;

	      count <= count + 1;
	   end
	 @(posedge clk);
	 @(posedge clk);
      end
   endtask // MIMO_BURST
      
   wire        radio_clk /*, rx_strobe*/;
   wire [11:0] i0o,i1o,q0o,q1o;
/* -----\/----- EXCLUDED -----\/-----
   
   catcap_ddr_lvds #(.INVERT_CLOCK(0), .INVERT_FRAME(0), .INVERT_DATA(0)) catcap
     (.reset(reset),
      .mimo(mimo),
      // DDR LVDS
      .rx_clk_p(ddrclk), .rx_clk_n(~ddrclk),
      .rx_frame_p(frame), .rx_frame_n(~frame),
      .rx_d_p(pins), .rx_d_n(~pins),
      // Output
      .radio_clk(radio_clk),
      .rx_strobe(rx_strobe),
      .i0(i0o),.q0(q0o),
      .i1(i1o),.q1(q1o));
 -----/\----- EXCLUDED -----/\----- */

   // Loopback
   always @(posedge radio_clk)
     begin
//	tx_strobe = rx_strobe;
	tx_i0 = rx_i0;
	tx_q0 = rx_q0;
	tx_i1 = rx_i1;
	tx_q1 = rx_q1;
     end
   

   cat_io_lvds
     #(
       .CLOCK_DELAY(0),
       .DATA_DELAY(0),
       .WIDTH(6),
       .GROUP("DEFAULT")
       )
       cat_io_lvds_i0
	 (
	  .rst(reset),
	  .mimo(mimo),
	  .clk200(clk200),
	  // Delay Control Interface
	  .ctrl_clk(rx_clk),
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
	  .rx_clk_p(rx_clk), 
	  .rx_clk_n(~rx_clk),       
	  .rx_frame_p(rx_frame), 
	  .rx_frame_n(~rx_frame),       
	  .rx_d_p(rx_d), 
	  .rx_d_n(~rx_d),
		       
	  .tx_clk_p(tx_clk_p), 
	  .tx_clk_n(tx_clk_n),
	  .tx_frame_p(tx_frame_p), 
	  .tx_frame_n(tx_frame_n),
	  .tx_d_p(tx_d_p), 
	  .tx_d_n(tx_d_n));
   
	
   
endmodule // catcap_ddr_lvds_tb
