
// Copyright 2014 Ettus Research
// Complex times real.  Complex number is on port B (18I, 18Q), real is on A (25 bits)

module mult_rc
  #(parameter WIDTH_A=25,
    parameter WIDTH_B=18,
    parameter WIDTH_P=48,
    parameter LATENCY=3,
    parameter CASCADE_OUT=0)
   (input clk, input reset,
    input [WIDTH_A-1:0] a_tdata, input a_tlast, input a_tvalid, output a_tready,
    input [2*WIDTH_B-1:0] b_tdata, input b_tlast, input b_tvalid, output b_tready,
    output [2*WIDTH_P-1:0] p_tdata, output p_tlast, output p_tvalid, input p_tready);

   // NOTE -- we cheat here and share ready/valid.  This works because we can guarantee both
   //           paths will match
   
   mult #(.WIDTH_A(WIDTH_A), .WIDTH_B(WIDTH_B), .WIDTH_P(WIDTH_P),
	  .LATENCY(LATENCY), .CASCADE_OUT(CASCADE_OUT)) mult_i
     (.clk(clk), .reset(reset),
      .a_tdata(a_tdata), .a_tlast(a_tlast), .a_tvalid(a_tvalid), .a_tready(a_tready),
      .b_tdata(b_tdata[2*WIDTH_B-1:WIDTH_B]), .b_tlast(b_tlast), .b_tvalid(b_tvalid), .b_tready(b_tready),
      .p_tdata(p_tdata[2*WIDTH_P-1:WIDTH_P]), .p_tlast(p_tlast), .p_tvalid(p_tvalid), .p_tready(p_tready));
         
   mult #(.WIDTH_A(WIDTH_A), .WIDTH_B(WIDTH_B), .WIDTH_P(WIDTH_P),
	  .LATENCY(LATENCY), .CASCADE_OUT(CASCADE_OUT)) mult_q
     (.clk(clk), .reset(reset),
      .a_tdata(a_tdata), .a_tlast(a_tlast), .a_tvalid(a_tvalid), .a_tready(),
      .b_tdata(b_tdata[WIDTH_B-1:0]), .b_tlast(b_tlast), .b_tvalid(b_tvalid), .b_tready(),
      .p_tdata(p_tdata[WIDTH_P-1:0]), .p_tlast(), .p_tvalid(), .p_tready(p_tready));
         
endmodule // mult_rc
