//
// Copyright 2015 Ettus Research LLC
//

module pps_generator #(
   parameter CLK_FREQ   = 32'd10_000_000, //Min:10kHz, Max:4GHz
   parameter DUTY_CYCLE = 25
) (
   input  clk,
   input  reset,
   output pps
);
    reg [31:0] count;

    always @(posedge clk) begin
        if (reset) begin
            count <= 32'd0;
        end else if (count >= CLK_FREQ - 1) begin
            count <= 32'd0;
        end else begin
            count <= count + 32'd1;
        end
    end

    assign pps = (count < ((CLK_FREQ / 100) * DUTY_CYCLE));
endmodule //pps_generator
