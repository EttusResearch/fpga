/*
 * f15_maxhold.v
 *
 * Computes the max hold (with epsilon decay)
 *
 * Copyright (C) 2015  Ettus Corporation LLC
 *
 * vim: ts=4 sw=4
 */

`ifdef SIM
`default_nettype none
`endif

module f15_maxhold #(
	parameter integer WIDTH = 9
)(
	input  wire [WIDTH-1:0] yin_0,
	input  wire [WIDTH-1:0] x_0,
	input  wire [15:0] epsilon_0,
	input  wire clear_0,
	output wire [WIDTH-1:0] yout_4,
	input  wire clk,
	input  wire rst
);

	// Signals
	reg [WIDTH-1:0] x_1;
	reg [WIDTH  :0] y_1;
	reg [WIDTH  :0] d_1;
	reg clear_1;

	reg [WIDTH-1:0] y_2;

	// Stage 1
	always @(posedge clk)
	begin
		x_1 <= x_0;
		y_1 <= yin_0 - epsilon_0;
		d_1 <= yin_0 - x_0;
		clear_1 <= clear_0;
	end

	// Stage 2
	always @(posedge clk)
	begin
		if (clear_1)
			y_2 <= 0;
		else if (d_1[WIDTH])
			// x is larger, use this
			y_2 <= x_1;
		else
			// y is larger, take old y with small decay
			if (y_1[WIDTH])
				y_2 <= 0;
			else
				y_2 <= y_1[WIDTH-1:0];
	end

	// Apply two more delay to match the avg block
	delay_bus #(2, WIDTH) dl_y (y_2, yout_4, clk);

endmodule // f15_maxhold
