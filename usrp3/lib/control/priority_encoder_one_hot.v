//
// Copyright 2013 Ettus Research LLC
//

module priority_encoder_one_hot
#(
  parameter WIDTH = 16
)
(
  input  [WIDTH-1:0]        in,
  output [WIDTH-1:0]        out
);

  wire [WIDTH-1:0] in_rev;
  wire [WIDTH-1:0] in_rev_inv_po = ~in_rev + 1;

  wire [WIDTH-1:0] mask;

  generate
  genvar i,j;

  for (i=0; i<WIDTH; i=i+1)
      assign in_rev[i] = in[WIDTH-1-i];

  for (j=0; j<WIDTH; j=j+1)
      assign mask[j]  = in_rev_inv_po[WIDTH-1-j];
  endgenerate

  assign out = in & mask;

endmodule
