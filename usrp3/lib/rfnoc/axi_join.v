

// Copyright 2014 Ettus Research

module axi_join
  #(parameter INPUTS=2)
  (input [INPUTS-1:0] i_tlast, input [INPUTS-1:0] i_tvalid, output [INPUTS-1:0] i_tready,
   output o_tlast, output o_tvalid, input o_tready);

   wire   all_here = &i_tvalid;
   assign o_tvalid = all_here;
   assign o_tlast = |i_tlast;
   assign i_tready = {INPUTS{o_tready & all_here}};
   
endmodule // axi_join
