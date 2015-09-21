
//
// Copyright 2015 Ettus Research LLC
//

module gpio_atr_io #(
  parameter WIDTH = 32
) (
  input                   clk,
  input      [WIDTH-1:0]  gpio_ddr,
  input      [WIDTH-1:0]  gpio_out,
  output reg [WIDTH-1:0]  gpio_in,
  inout      [WIDTH-1:0]  gpio_pins
);

  reg [WIDTH-1:0] pins_reg, gpio_out_reg;

  //Instantiate registers in the IOB
  always @(posedge clk)
    gpio_in <= gpio_pins;

  always @(posedge clk)
    gpio_out_reg <= gpio_out;

  genvar i;
  generate for (i=0; i<WIDTH; i=i+1) begin: io_gen
    assign gpio_pins[i] = gpio_ddr[i] ? gpio_out_reg[i] : 1'bz;
  end endgenerate

endmodule // gpio_atr_io
