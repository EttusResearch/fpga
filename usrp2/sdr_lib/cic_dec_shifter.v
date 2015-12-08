// -*- verilog -*-
//
//  USRP - Universal Software Radio Peripheral
//
//  Copyright (C) 2003 Matt Ettus
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation; either version 2 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 51 Franklin Street, Boston, MA  02110-1301  USA
//


// NOTE   This only works for N=4, max decim rate of 128
// NOTE   signal "rate" is EQUAL TO the actual rate, no more -1 BS

module cic_dec_shifter
   #(parameter bw = 16, maxbitgain = 28)
     (input clk,
      input [7:0] rate,
      input strobe_in,
      output reg strobe_out,
      input [bw+maxbitgain-1:0] signal_in,
      output reg [bw-1:0] signal_out);

   function [4:0] bitgain;
      input [7:0] rate;
      case(rate)
	// Exact Cases -- N*log2(rate)
	8'd1 : bitgain = 0;
	8'd2 : bitgain = 4;
	8'd4 : bitgain = 8;
	8'd8 : bitgain = 12;
	8'd16 : bitgain = 16;
	8'd32 : bitgain = 20;
	8'd64 : bitgain = 24;
	8'd128 : bitgain = 28;

	// Nearest without overflow -- ceil(N*log2(rate))
	8'd3 : bitgain = 7;
	8'd5 : bitgain = 10;
	8'd6 : bitgain = 11;
	8'd7 : bitgain = 12;
	8'd9 : bitgain = 13;
	8'd10,8'd11 : bitgain = 14;
	8'd12,8'd13 : bitgain = 15;
	8'd14,8'd15 : bitgain = 16;
	8'd17,8'd18,8'd19 : bitgain = 17;
	8'd20,8'd21,8'd22 : bitgain = 18;
	8'd23,8'd24,8'd25,8'd26 : bitgain = 19;
	8'd27,8'd28,8'd29,8'd30,8'd31 : bitgain = 20;
	8'd33,8'd34,8'd35,8'd36,8'd37,8'd38 : bitgain = 21;
	8'd39,8'd40,8'd41,8'd42,8'd43,8'd44,8'd45 : bitgain = 22;
	8'd46,8'd47,8'd48,8'd49,8'd50,8'd51,8'd52,8'd53 : bitgain = 23;
	8'd54,8'd55,8'd56,8'd57,8'd58,8'd59,8'd60,8'd61,8'd62,8'd63 : bitgain = 24;
	8'd65,8'd66,8'd67,8'd68,8'd69,8'd70,8'd71,8'd72,8'd73,8'd74,8'd75,8'd76 : bitgain = 25;
	8'd77,8'd78,8'd79,8'd80,8'd81,8'd82,8'd83,8'd84,8'd85,8'd86,8'd87,8'd88,8'd89,8'd90 : bitgain = 26;
	8'd91,8'd92,8'd93,8'd94,8'd95,8'd96,8'd97,8'd98,8'd99,8'd100,8'd101,8'd102,8'd103,8'd104,8'd105,8'd106,8'd107 : bitgain = 27;
	default : bitgain = 28;
      endcase // case(rate)
   endfunction // bitgain

   // use register for shift to limit delay
   // force user encoding so signal_out can be inferred as a multiplexer
   (* signal_encoding = "user" *)
   reg [4:0] shift;
   always @(posedge clk)
     shift <= bitgain(rate);

   always @(posedge clk) begin
     signal_out <= signal_in[shift +: bw];
     strobe_out <= strobe_in;
   end

endmodule // cic_dec_shifter

