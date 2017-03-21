//
// Copyright (c) 2017 National Instruments
//

module pulse_stretch
(
  input clk,
  input rst,
  input pulse,
  output pulse_stretched
);

  parameter WIDTH = 64;
  parameter SCALE = 64'd12_500_000;

  (* mark_debug = "true", keep = "true" *)
  reg [WIDTH-1:0] count;

  (* mark_debug = "true", keep = "true" *)
  reg        state;

  always @ (posedge clk)
    if (rst)
      state <= 0;
    else case (state)

    1'b0: begin
      if (pulse) begin
        state <= 1'b1;
        count <= 'd0;
      end
    end

    1'b1: begin
      if (count >= 'd12_500_000)
        state <= 1'b0;
      else
        count <= count + 1'b1;
    end

    endcase

  assign pulse_stretched = (state == 1'b1);

endmodule
