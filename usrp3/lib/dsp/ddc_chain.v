//
// Copyright 2011-2013 Ettus Research LLC
//


//! The USRP digital down-conversion chain

module ddc_chain
  #(
    parameter BASE = 0,
    parameter DSPNO = 0,
    parameter WIDTH = 24,
    parameter NEW_HB_DECIM = 0,
    parameter DEVICE = "SPARTAN6"
  )
  (input clk, input rst, input clr,
   input 	     set_stb, input [7:0] set_addr, input [31:0] set_data,

   // From RX frontend
   input [WIDTH-1:0] rx_fe_i,
   input [WIDTH-1:0] rx_fe_q,

   // To RX control
//IJB   output reg [31:0] sample,
   output [31:0] sample,
   input 	     run,
   output 	     strobe,
   output [31:0]     debug
   );

   localparam  cwidth = 25;
   localparam  zwidth = 24;

   wire [31:0] phase_inc;
   reg [31:0]  phase;

   wire [17:0] scale_factor;
   wire [cwidth-1:0] to_cordic_i, to_cordic_q;
   wire [cwidth-1:0] i_cordic, q_cordic;
   reg  [WIDTH-1:0] i_cordic_pipe, q_cordic_pipe;
   wire [WIDTH-1:0] i_cic, q_cic;


   wire        strobe_cic, strobe_hb1, strobe_hb2;
   wire        enable_hb1, enable_hb2;
   wire [7:0]  cic_decim_rate;

   reg [WIDTH-1:0]  rx_fe_i_mux, rx_fe_q_mux;
   wire        realmode;
   wire        swap_iq;
   wire        invert_i;
   wire        invert_q;

/* -----\/----- EXCLUDED -----\/-----
   always @(posedge clk) begin
      sample[31:16] <= {rx_fe_i[23:12],4'h0};
      sample[15:0] <= {rx_fe_q[23:12],4'h0};
   end
   assign strobe = 1;
 -----/\----- EXCLUDED -----/\----- */
   

   setting_reg #(.my_addr(BASE+0)) sr_0
     (.clk(clk),.rst(rst),.strobe(set_stb),.addr(set_addr),
      .in(set_data),.out(phase_inc),.changed());

   setting_reg #(.my_addr(BASE+1), .width(18)) sr_1
     (.clk(clk),.rst(rst),.strobe(set_stb),.addr(set_addr),
      .in(set_data),.out(scale_factor),.changed());

   setting_reg #(.my_addr(BASE+2), .width(10)) sr_2
     (.clk(clk),.rst(rst),.strobe(set_stb),.addr(set_addr),
      .in(set_data),.out({enable_hb1, enable_hb2, cic_decim_rate}),.changed());

   setting_reg #(.my_addr(BASE+3), .width(4)) sr_3
     (.clk(clk),.rst(rst),.strobe(set_stb),.addr(set_addr),
      .in(set_data),.out({invert_i,invert_q,realmode,swap_iq}),.changed());


   // MUX so we can do realmode signals on either input

   always @(posedge clk)
     if(swap_iq)
       begin
          rx_fe_i_mux <= invert_i ? ~rx_fe_q : rx_fe_q;
          rx_fe_q_mux <= realmode ? {WIDTH{1'b0}} : invert_q ? ~rx_fe_i : rx_fe_i;
       end
     else
       begin
	  rx_fe_i_mux <= invert_i ? ~rx_fe_i : rx_fe_i;
          rx_fe_q_mux <= realmode ? {WIDTH{1'b0}} : invert_q ? ~rx_fe_q : rx_fe_q;
       end

   // NCO
   always @(posedge clk)
     if(rst)
       phase <= 0;
     else if(~run)
       phase <= 0;
     else
       phase <= phase + phase_inc;

   // CORDIC  24-bit I/O
   // (Algorithmic gain through CORDIC => 1.647 * 0.5 = 0.8235)
   // (Worst case gain through rotation => SQRT(2) = 1.4142)
   // Total worst case gain => 0.8235 * 1.4142 = 1.1646
   // So add an extra MSB bit for word growth.
   
   sign_extend #(.bits_in(WIDTH), .bits_out(cwidth)) sign_extend_cordic_i (.in(rx_fe_i_mux), .out(to_cordic_i));
   sign_extend #(.bits_in(WIDTH), .bits_out(cwidth)) sign_extend_cordic_q (.in(rx_fe_q_mux), .out(to_cordic_q));
   
   cordic_z24 #(.bitwidth(cwidth))
   cordic(.clock(clk), .reset(rst), .enable(run),
	  .xi(to_cordic_i),. yi(to_cordic_q), .zi(phase[31:32-zwidth]),
	  .xo(i_cordic),.yo(q_cordic),.zo() );

   always @(posedge clk) begin
      i_cordic_pipe[23:0] <= i_cordic[24:1];
      q_cordic_pipe[23:0] <= q_cordic[24:1];
   end
   

   // CIC decimator  24 bit I/O
   // Applies crude 1/(2^N) right shift gain compensation internally to prevent excesive downstream word growth.
   // Output gain is = algo_gain/(POW(2,CEIL(LOG2(algo_gain))) where algo_gain is = cic_decim_rate^4
   // Thus output gain is <= 1.0 and no word growth occurs.
   cic_strober cic_strober(.clock(clk),.reset(rst),.enable(run),.rate(cic_decim_rate),
			   .strobe_fast(1'b1),.strobe_slow(strobe_cic) );

   cic_decim #(.bw(WIDTH))
     decim_i (.clock(clk),.reset(rst),.enable(run),
	      .rate(cic_decim_rate),.strobe_in(1'b1),.strobe_out(strobe_cic),
	      .signal_in(i_cordic_pipe),.signal_out(i_cic));

   cic_decim #(.bw(WIDTH))
     decim_q (.clock(clk),.reset(rst),.enable(run),
	      .rate(cic_decim_rate),.strobe_in(1'b1),.strobe_out(strobe_cic),
	      .signal_in(q_cordic_pipe),.signal_out(q_cic));

   //////////////////////////////////////////////////////////////////////////
   //
   // Conditional compilation of either:
   // 1) New X300 style decimation filters, or
   // 2) Traditional N210 style decimation filters.
   //
   //////////////////////////////////////////////////////////////////////////
   generate
      if (NEW_HB_DECIM == 1) begin: new_hb

	 wire        reload_go, reload_we1, reload_we2,  reload_ld1, reload_ld2;
	 wire [17:0] coef_din;

	 setting_reg #(.my_addr(BASE+4), .width(22)) sr_4
	   (.clk(clk),.rst(rst),.strobe(set_stb),.addr(set_addr),
	    .in(set_data),.out({reload_ld2,reload_we2,reload_ld1,reload_we1,coef_din[17:0]}),.changed(reload_go));

	 // Halfbands
	 wire 	     nd1, nd2, nd3;
	 wire 	     rfd1, rfd2, rfd3;
	 wire 	     rdy1, rdy2, rdy3;
	 wire 	     data_valid1, data_valid2, data_valid3;
	 wire [46:0] i_hb1, q_hb1;
	 wire [46:0] i_hb2, q_hb2;
	 localparam HB1_SCALE = 18;
	 localparam HB2_SCALE = 18;


	 assign strobe_hb1 = data_valid1;
	 assign strobe_hb2 = data_valid2;

	 assign nd1 = strobe_cic;
	 assign nd2 = strobe_hb1;
	 
	 // Default Coeffs have gain of ~1.0
	 hbdec1 hbdec1
	   (.clk(clk), // input clk
	    .sclr(rst), // input sclr
	    .ce(enable_hb1), // input ce
	    .coef_ld(reload_go & reload_ld1), // input coef_ld
	    .coef_we(reload_go & reload_we1), // input coef_we
	    .coef_din(coef_din), // input [17 : 0] coef_din
	    .rfd(rfd1), // output rfd
	    .nd(nd1), // input nd
	    .din_1(i_cic), // input [23 : 0] din_1
	    .din_2(q_cic), // input [23 : 0] din_2
	    .rdy(rdy1), // output rdy
	    .data_valid(data_valid1), // output data_valid
	    .dout_1(i_hb1), // output [46 : 0] dout_1
	    .dout_2(q_hb1)); // output [46 : 0] dout_2
	 
	 // Default Coeffs have gain of ~1.0
	 hbdec2 hbdec2
	   (.clk(clk), // input clk
	    .sclr(rst), // input sclr
	    .ce(enable_hb2), // input ce
	    .coef_ld(reload_go & reload_ld2), // input coef_ld
	    .coef_we(reload_go & reload_we2), // input coef_we
	    .coef_din(coef_din), // input [17 : 0] coef_din
	    .rfd(rfd2), // output rfd
	    .nd(nd2), // input nd
	    .din_1(i_hb1[23+HB1_SCALE:HB1_SCALE]), // input [23 : 0] din_1
	    .din_2(q_hb1[23+HB1_SCALE:HB1_SCALE]), // input [23 : 0] din_2
	    .rdy(rdy2), // output rdy
	    .data_valid(data_valid2), // output data_valid
	    .dout_1(i_hb2), // output [46 : 0] dout_1
	    .dout_2(q_hb2)); // output [46 : 0] dout_2

	 // TEST. IJB
	 wire [17:0] i_hb_round, q_hb_round;
	 wire 	     strobe_hb1_round;
	 
	 round_sd #(.WIDTH_IN(24+HB1_SCALE), .WIDTH_OUT(18)) round_i_hb1
	   (.clk(clk), .reset(rst), .in(i_hb1[23+HB1_SCALE:0]), .strobe_in(strobe_hb1), .out(i_hb_round[17:0]), .strobe_out(strobe_hb1_round));
	 round_sd #(.WIDTH_IN(24+HB1_SCALE), .WIDTH_OUT(18)) round_q_hb1
	   (.clk(clk), .reset(rst), .in(q_hb1[23+HB1_SCALE:0]), .strobe_in(strobe_hb1), .out(q_hb_round[17:0]), .strobe_out());
	 
	 // END TEST
	 
	 reg [17:0]  i_unscaled, q_unscaled;
	 reg 	     strobe_unscaled;

	 always @(posedge clk)
	   case({enable_hb1,enable_hb2})
	     // No Halfbands enabled, no decimation.
	     2'd0 :
	       begin
		  strobe_unscaled <= strobe_cic;
		  i_unscaled <= i_cic[23:6];
		  q_unscaled <= q_cic[23:6];
	       end
	     // ILLEGAL. Only half sample rate half band enabled.
	     2'd1 :
	       begin
		  strobe_unscaled <= strobe_cic;
		  i_unscaled <= i_cic[23:6];
		  q_unscaled <= q_cic[23:6];
	       end
	     // One Halfband enabled, decimate by 2.
	     2'd2 :
	       begin
		  strobe_unscaled <= strobe_hb1_round;
		//  i_unscaled <= i_hb1[23+HB1_SCALE:6+HB1_SCALE];
		//  q_unscaled <= q_hb1[23+HB1_SCALE:6+HB1_SCALE];
		  i_unscaled <= i_hb_round[17:0];
		  q_unscaled <= q_hb_round[17:0];
	       end
	     // Both Halfbands enabled, decimate by 4.
	     2'd3 :
	       begin
		  strobe_unscaled <= strobe_hb2;
		  i_unscaled <= i_hb2[23+HB2_SCALE:6+HB2_SCALE];
		  q_unscaled <= q_hb2[23+HB2_SCALE:6+HB2_SCALE];
	     end
	   endcase // case (hb_rate)

	 // //scalar operation (gain of 6 bits)
	 wire [35:0] 	  prod_i, prod_q;

	 MULT_MACRO #(.DEVICE(DEVICE),  // Target Device: "VIRTEX5", "VIRTEX6", "SPARTAN6","7SERIES"
		      .LATENCY(1),         // Desired clock cycle latency, 0-4
		      .WIDTH_A(18),        // Multiplier A-input bus width, 1-25
		      .WIDTH_B(18))        // Multiplier B-input bus width, 1-18
	 mult_i (.P(prod_i),             // Multiplier output bus, width determined by WIDTH_P parameter
		.A(i_unscaled),         // Multiplier input A bus, width determined by WIDTH_A parameter
		.B(scale_factor),       // Multiplier input B bus, width determined by WIDTH_B parameter
		.CE(strobe_unscaled),   // 1-bit active high input clock enable
		.CLK(clk),              // 1-bit positive edge clock input
		.RST(rst));             // 1-bit input active high reset

	 MULT_MACRO #(.DEVICE(DEVICE),  // Target Device: "VIRTEX5", "VIRTEX6", "SPARTAN6","7SERIES"
		      .LATENCY(1),         // Desired clock cycle latency, 0-4
		      .WIDTH_A(18),        // Multiplier A-input bus width, 1-25
		      .WIDTH_B(18))        // Multiplier B-input bus width, 1-18
	 mult_q (.P(prod_q),             // Multiplier output bus, width determined by WIDTH_P parameter
		.A(q_unscaled),         // Multiplier input A bus, width determined by WIDTH_A parameter
		.B(scale_factor),       // Multiplier input B bus, width determined by WIDTH_B parameter
		.CE(strobe_unscaled),   // 1-bit active high input clock enable
		.CLK(clk),              // 1-bit positive edge clock input
		.RST(rst));             // 1-bit input active high reset
	 
	 reg 		  strobe_scaled;
	 wire 		  strobe_clip;
	 wire [33:0] 	  i_clip, q_clip;

	 always @(posedge clk)  strobe_scaled <= strobe_unscaled;
   
	 clip_reg #(.bits_in(36), .bits_out(34), .STROBED(1)) clip_i
	   (.clk(clk), .in(prod_i[35:0]), .strobe_in(strobe_scaled), .out(i_clip), .strobe_out(strobe_clip));
	 clip_reg #(.bits_in(36), .bits_out(34), .STROBED(1)) clip_q
	   (.clk(clk), .in(prod_q[35:0]), .strobe_in(strobe_scaled), .out(q_clip), .strobe_out());

//	 round_sd #(.WIDTH_IN(34), .WIDTH_OUT(16)) round_i
//	   (.clk(clk), .reset(rst), .in(i_clip), .strobe_in(strobe_clip), .out(sample[31:16]), .strobe_out(strobe));
//	 round_sd #(.WIDTH_IN(34), .WIDTH_OUT(16)) round_q
//	   (.clk(clk), .reset(rst), .in(q_clip), .strobe_in(strobe_clip), .out(sample[15:0]), .strobe_out());
   

	 //pipeline for the multiplier (gain of 10 bits)
	 reg [WIDTH-1:0]  prod_reg_i, prod_reg_q;
	 reg 		  strobe_mult;

	 always @(posedge clk) begin
	    strobe_mult <= strobe_unscaled;
	    prod_reg_i <= prod_i[33:34-WIDTH];
	    prod_reg_q <= prod_q[33:34-WIDTH];
	 end

	 // Round final answer to 16 bits
	 round_sd #(.WIDTH_IN(WIDTH),.WIDTH_OUT(16)) round_i
	   (.clk(clk),.reset(rst), .in(prod_reg_i),.strobe_in(strobe_mult), .out(sample[31:16]), .strobe_out(strobe));

	 round_sd #(.WIDTH_IN(WIDTH),.WIDTH_OUT(16)) round_q
	   (.clk(clk),.reset(rst), .in(prod_reg_q),.strobe_in(strobe_mult), .out(sample[15:0]), .strobe_out());

      end else begin: old_hb // block: new_hb
	 ///////////////////////////////////////////////
	 //
	 // Legacy Decimation Filters from USRP2
	 //
	 ///////////////////////////////////////////////
	 wire [WIDTH-1:0] i_hb1, q_hb1;
	 wire [WIDTH-1:0] i_hb2, q_hb2;
	 // First (small) halfband  24 bit I/O
	 small_hb_dec #(.WIDTH(WIDTH),.DEVICE(DEVICE)) small_hb_i
	   (.clk(clk),.rst(rst),.bypass(~enable_hb1),.run(run),
	    .stb_in(strobe_cic),.data_in(i_cic),.stb_out(strobe_hb1),.data_out(i_hb1));

	 small_hb_dec #(.WIDTH(WIDTH),.DEVICE(DEVICE)) small_hb_q
	   (.clk(clk),.rst(rst),.bypass(~enable_hb1),.run(run),
	    .stb_in(strobe_cic),.data_in(q_cic),.stb_out(),.data_out(q_hb1));

	 // Second (large) halfband  24 bit I/O
	 wire [8:0] 	  cpi_hb = enable_hb1 ? {cic_decim_rate,1'b0} : {1'b0,cic_decim_rate};
	 hb_dec #(.WIDTH(WIDTH),.DEVICE(DEVICE)) hb_i
	   (.clk(clk),.rst(rst),.bypass(~enable_hb2),.run(run),.cpi(cpi_hb),
	    .stb_in(strobe_hb1),.data_in(i_hb1),.stb_out(strobe_hb2),.data_out(i_hb2));

	 hb_dec #(.WIDTH(WIDTH),.DEVICE(DEVICE)) hb_q
	   (.clk(clk),.rst(rst),.bypass(~enable_hb2),.run(run),.cpi(cpi_hb),
	    .stb_in(strobe_hb1),.data_in(q_hb1),.stb_out(),.data_out(q_hb2));

	 //scalar operation (gain of 6 bits)
	 wire [35:0] 	  prod_i, prod_q;

	 MULT_MACRO #(.DEVICE(DEVICE),  // Target Device: "VIRTEX5", "VIRTEX6", "SPARTAN6","7SERIES"
		      .LATENCY(1),         // Desired clock cycle latency, 0-4
		      .WIDTH_A(18),        // Multiplier A-input bus width, 1-25
		      .WIDTH_B(18))        // Multiplier B-input bus width, 1-18
	 mult_i (.P(prod_i),             // Multiplier output bus, width determined by WIDTH_P parameter
		.A(i_hb2[WIDTH-1:WIDTH-18]),// Multiplier input A bus, width determined by WIDTH_A parameter
		.B(scale_factor),       // Multiplier input B bus, width determined by WIDTH_B parameter
		.CE(strobe_hb2),        // 1-bit active high input clock enable
		.CLK(clk),              // 1-bit positive edge clock input
		.RST(rst));             // 1-bit input active high reset

	 MULT_MACRO #(.DEVICE(DEVICE),  // Target Device: "VIRTEX5", "VIRTEX6", "SPARTAN6","7SERIES"
		      .LATENCY(1),         // Desired clock cycle latency, 0-4
		      .WIDTH_A(18),        // Multiplier A-input bus width, 1-25
		      .WIDTH_B(18))        // Multiplier B-input bus width, 1-18
	 mult_q (.P(prod_q),             // Multiplier output bus, width determined by WIDTH_P parameter
		.A(q_hb2[WIDTH-1:WIDTH-18]),// Multiplier input A bus, width determined by WIDTH_A parameter
		.B(scale_factor),       // Multiplier input B bus, width determined by WIDTH_B parameter
		.CE(strobe_hb2),        // 1-bit active high input clock enable
		.CLK(clk),              // 1-bit positive edge clock input
		.RST(rst));             // 1-bit input active high reset

	 //pipeline for the multiplier (gain of 10 bits)
	 reg [WIDTH-1:0]  prod_reg_i, prod_reg_q;
	 reg 		  strobe_mult;

	 always @(posedge clk) begin
	    strobe_mult <= strobe_hb2;
	    prod_reg_i <= prod_i[33:34-WIDTH];
	    prod_reg_q <= prod_q[33:34-WIDTH];
	 end

	 // Round final answer to 16 bits
	 round_sd #(.WIDTH_IN(WIDTH),.WIDTH_OUT(16)) round_i
	   (.clk(clk),.reset(rst), .in(prod_reg_i),.strobe_in(strobe_mult), .out(sample[31:16]), .strobe_out(strobe));

	 round_sd #(.WIDTH_IN(WIDTH),.WIDTH_OUT(16)) round_q
	   (.clk(clk),.reset(rst), .in(prod_reg_q),.strobe_in(strobe_mult), .out(sample[15:0]), .strobe_out());
      end // block: old_hb
   endgenerate



   assign debug = {enable_hb1, enable_hb2, run, strobe, strobe_cic, strobe_hb1, strobe_hb2};

endmodule // ddc_chain
