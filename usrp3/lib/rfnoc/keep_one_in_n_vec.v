//
// Copyright 2014 Ettus Research LLC
//

module keep_one_in_n_vec
  #(parameter WIDTH=16)
   (input clk, input reset,
    input [15:0] n,
    input [WIDTH-1:0] i_tdata, input i_tlast, input i_tvalid, output i_tready,
    output [WIDTH-1:0] o_tdata, output o_tlast, output o_tvalid, input o_tready);

   reg [15:0] 	       counter;
   wire 	       on_last_one = ( (counter >= (n-1)) | (n == 0) );  // n==0 lets everything through
   // Caution if changing n during operation!
   
   always @(posedge clk)
     if(reset)
       counter <= 0;
     else
       if(i_tvalid & i_tready & i_tlast)
	 if(on_last_one)
	   counter <= 16'd0;
	 else
	   counter <= counter + 16'd1;

   assign i_tready = o_tready | ~on_last_one;
   assign o_tvalid = i_tvalid & on_last_one;
   
   assign o_tdata = i_tdata;
   assign o_tlast = i_tlast;
   
endmodule // keep_one_in_n_vec
