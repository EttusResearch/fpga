//
// Copyright 2014 Ettus Research LLC
//

module one_gige_phy_clk_gen 
(
   input  areset,
   input  refclk_p,
   input  refclk_n,
   output refclk
);

   IBUFDS_GTE2 ibufds_inst (
      .O     (refclk),
      .ODIV2 (),
      .CEB   (1'b0),
      .I     (refclk_p),
      .IB    (refclk_n)
   );

endmodule



