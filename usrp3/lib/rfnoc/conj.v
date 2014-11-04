//
// Copyright 2014 Ettus Research LLC
//
// NOTE -- does not flop the output.  could cause timing issues, so follow with axi_fifo_flop if you need it

module conj
  #(parameter WIDTH=16)
   (input clk, input reset, input clear,
    input [2*WIDTH-1:0] i_tdata, input i_tlast, input i_tvalid, output i_tready,
    output [2*WIDTH-1:0] o_tdata, output o_tlast, output o_tvalid, input o_tready);

   assign o_tdata = { i_tdata[2*WIDTH-1:WIDTH] , -i_tdata[WIDTH-1:0] };
   assign o_tlast = i_tlast;
   assign o_tvalid = i_tvalid;
   assign i_tready = o_tready;
   
endmodule // conj
