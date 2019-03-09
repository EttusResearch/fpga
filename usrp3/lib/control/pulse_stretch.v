//
// Copyright 2017 Ettus Research, a National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//

module pulse_stretch #(
  parameter SCALE = 64'd12_500_000
)(
  input clk,
  input rst,
  input pulse,
  output pulse_stretched
);

  reg [$clog2(SCALE)-1:0] count = 'd0;
  reg             state = 1'b0;

  always @ (posedge clk)
    if (rst) begin
      state <= 1'b0;
      count <= 'd0;
    end
    else begin
      case (state)

      1'b0: begin
        if (pulse) begin
          state <= 1'b1;
          count <= 'd0;
        end
      end

      1'b1: begin
        if (count == SCALE)
          state <= 1'b0;
        else
          count <= count + 1'b1;
      end
      endcase
    end

  assign pulse_stretched = (state == 1'b1);

endmodule
