
// Copyright 2012 Ettus Research LLC
// axi_demux -- takes 1 AXI stream, demuxes to up to 16 output streams
//  One bubble cycle between each packet

module axi_demux
  #(parameter WIDTH=64,
    parameter SIZE=4)
   (input clk, input reset, input clear,
    output [WIDTH-1:0] header, input [3:0] dest,
    input [WIDTH-1:0] i_tdata, input i_tlast, input i_tvalid, output i_tready,
    output [(WIDTH*SIZE)-1:0] o_tdata, output [SIZE-1:0] o_tlast, output [SIZE-1:0] o_tvalid, input [SIZE-1:0] o_tready);

   reg [SIZE-1:0] 	      st;
   
   assign o_tdata = {SIZE{i_tdata}};
   assign o_tlast = {SIZE{i_tlast}};
   assign o_tvalid = {SIZE{i_tvalid}} & st;
   assign i_tready = |(o_tready & st);

   assign header = i_tdata;
   
   always @(posedge clk)
     if(reset | clear)
       st <= {SIZE{1'b0}};
     else
       if(st == 0)
	 if(i_tvalid)
	   st[dest] <= 1'b1;
	 else
	   ;
       else
	 if(i_tready & i_tvalid & i_tlast)
	   st <= {SIZE{1'b0}};
   
endmodule // axi_demux
