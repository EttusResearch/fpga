//
// Copyright 2014 Ettus Research LLC
//

module synchronizer #(
   parameter STAGES     = 2,
   parameter RESET_VAL  = 1'b0
)(
   input    clk,
   input    rst,
   input    in,
   output   out
);

   (* ASYNC_REG = "TRUE" *) reg [STAGES-1:0] value_int = {STAGES{RESET_VAL}};

   genvar i;
   generate
      for (i=0; i<STAGES; i=i+1) begin: synchronizer_gen
         always @(posedge clk) begin
            if (rst)
               value_int[i] <= RESET_VAL;
            else
               value_int[i] <= (i==0) ? in : value_int[i-1];
         end
      end
   endgenerate

   assign out = value_int[STAGES-1];

endmodule   //synchronizer
