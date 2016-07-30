//
// Copyright 2014 Ettus Research LLC
//

module synchronizer_impl #(
   parameter STAGES      = 2,
   parameter INITIAL_VAL = 1'b0
)(
   input    clk,
   input    rst,
   input    in,
   output   out
);

   (* ASYNC_REG = "TRUE" *) reg [STAGES-1:0] value = {STAGES{INITIAL_VAL}};

   genvar i;
   generate
      for (i=0; i<STAGES; i=i+1) begin: stages
         always @(posedge clk) begin
            if (rst)
               value[i] <= INITIAL_VAL;
            else
               value[i] <= (i==0) ? in : value[i-1];
         end
      end
   endgenerate

   assign out = value[STAGES-1];

endmodule   //synchronizer_impl
