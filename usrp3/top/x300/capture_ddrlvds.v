//
// Copyright 2011-2014 Ettus Research LLC
//

// The two clocks are aligned externally in order to eliminate the need for a FIFO.
// A FIFO cannot be used to transition between clock domains because it can cause
// alignment issues between the output of multiple modules.

module capture_ddrlvds
  #(parameter WIDTH=7,
    parameter X300=0)
   (input clk,
    input ssclk_p,
    input ssclk_n,
    input [WIDTH-1:0] in_p,
    input [WIDTH-1:0] in_n,
    output reg [(2*WIDTH)-1:0] out);

   wire [WIDTH-1:0] 	   ddr_dat;
   wire 		   ssclk;
   wire [(2*WIDTH)-1:0]    out_pre1;
   reg  [(2*WIDTH)-1:0]    out_pre2;
   wire 		   ssclk_bufr1, ssclk_bufr2, ssclk_bufmr;

   IBUFGDS #(.DIFF_TERM("TRUE"))
   clkbuf (.O(ssclk), .I(ssclk_p), .IB(ssclk_n));

   BUFMR clkbufmr (
      .I(ssclk),
      .O(ssclk_bufmr)
   );

   BUFR #(
      .SIM_DEVICE("7SERIES"), .BUFR_DIVIDE("BYPASS")
   ) clkbufr1 (
      .I(ssclk_bufmr),
      .O(ssclk_bufr1)
   );

   BUFR #(
      .SIM_DEVICE("7SERIES"), .BUFR_DIVIDE("BYPASS")
   ) clkbufr2 (
      .I(ssclk_bufmr),
      .O(ssclk_bufr2)
   );

   genvar i;

   generate
      for(i = 0; i < WIDTH; i = i + 1)
	begin : gen_lvds_pins
	   if ((i == 10) && (X300 == 1)) begin
	      IBUFDS #(.DIFF_TERM("FALSE")) ibufds
		(.O(ddr_dat[i]), .I(in_p[i]), .IB(in_n[i]) );
	      IDDR #(.DDR_CLK_EDGE("SAME_EDGE_PIPELINED")) iddr
		(.Q1(out_pre1[2*i]), .Q2(out_pre1[(2*i)+1]), .C(ssclk_bufr2),
		 .CE(1'b1), .D(ddr_dat[i]), .R(1'b0), .S(1'b0));
	   end else begin
	      IBUFDS #(.DIFF_TERM("TRUE")) ibufds
		(.O(ddr_dat[i]), .I(in_p[i]), .IB(in_n[i]) );
	      IDDR #(.DDR_CLK_EDGE("SAME_EDGE_PIPELINED")) iddr
		(.Q1(out_pre1[2*i]), .Q2(out_pre1[(2*i)+1]), .C(ssclk_bufr1),
		 .CE(1'b1), .D(ddr_dat[i]), .R(1'b0), .S(1'b0));
	   end
	end
   endgenerate

   always @(posedge clk)
     {out, out_pre2} <= {out_pre2, out_pre1};

endmodule // capture_ddrlvds
