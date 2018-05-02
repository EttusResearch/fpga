//
// Copyright 2015 Ettus Research LLC
// Copyright 2018 Ettus Research, a National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//

module pulse_generator #() (
   input  clk,
   input  reset,
   input [31:0] period,
   input [31:0] pulse_width,
   output pulse
);
    reg [31:0] count;

    always @(posedge clk) begin
        if (reset) begin
            count <= 32'd0;
        end else if (count >= period - 1) begin
            count <= 32'd0;
        end else begin
            count <= count + 32'd1;
        end
    end

    assign pulse = count < pulse_width;
endmodule //pulse_generator
