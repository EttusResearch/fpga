//
// Copyright 2014 Ettus Research LLC
//

module threshold_scaled
  #(parameter WIDTH=32, SCALAR=131072)
   (input clk, input reset, input clear,
    input [WIDTH-1:0] i0_tdata, input i0_tlast, input i0_tvalid, output i0_tready,
    input [WIDTH-1:0] i1_tdata, input i1_tlast, input i1_tvalid, output i1_tready,
    output o_tdata, output o_tlast, output o_tvalid, input o_tready);

   wire signed [WIDTH-1:0] scaled_input;
   wire signed [WIDTH-1:0] difference;
   wire signed 		   thresh_met;
   
   assign scaled_input = (i1_tdata-1) * SCALAR;
   assign difference = scaled_input - i0_tdata;
   assign thresh_met = difference > 0;
   
   assign o_tdata = thresh_met;
   assign o_tlast = i0_tlast;

   wire 		   do_op = o_tready & i0_tvalid & i1_tvalid;
   
   assign o_tvalid = do_op;
   
   assign i0_tready = do_op;
   assign i1_tready = do_op;

endmodule // threshold_scaled
