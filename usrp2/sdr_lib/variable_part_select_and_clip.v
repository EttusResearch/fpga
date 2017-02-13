// -*- verilog -*-
//
//  USRP - Universal Software Radio Peripheral
//
//  Copyright (C) 2016 Ryan Volz
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


module variable_part_select_and_clip
  #(parameter WIDTH_IN=31, WIDTH_OUT=24, INDEX_WIDTH=3)
    (input clk,
     input strobe_in,
     output reg strobe_out,
     input [WIDTH_IN-1:0] signal_in,
     input [INDEX_WIDTH-1:0] lowidx,
     output reg [WIDTH_OUT-1:0] signal_out);

   localparam MASKBW = WIDTH_IN - WIDTH_OUT;

   // isolate bits to be clipped and determine if an overflow would occur
   wire [MASKBW:0] head = signal_in[WIDTH_IN-1 -: MASKBW+1];

   // bit order reversed so we can read in reverse
   reg [0:MASKBW+MASKBW-1] maskrom = {{MASKBW{1'b1}}, {MASKBW{1'b0}}};

   function [MASKBW-1:0] clipmask;
      input [INDEX_WIDTH-1:0] idx;
      clipmask = maskrom[MASKBW-1+idx -: MASKBW];
// with MASKBW == 7 and INDEX_WIDTH ==3, this is equivalent to the following:
//    case(idx)
//      3'd0 : clipmask = 7'b1111111;
//      3'd1 : clipmask = 7'b1111110;
//      3'd2 : clipmask = 7'b1111100;
//      3'd3 : clipmask = 7'b1111000;
//      3'd4 : clipmask = 7'b1110000;
//      3'd5 : clipmask = 7'b1100000;
//      3'd6 : clipmask = 7'b1000000;
//      default : clipmask = 7'b0000000;
//    endcase
   endfunction

   // use register for mask to limit delay
   reg [MASKBW-1:0] mask;
   always @(posedge clk)
     mask <= clipmask(lowidx);

   wire overflow = |((head[MASKBW-1:0] ^ {MASKBW{head[MASKBW]}}) & mask);

   // apply part selection and clip if necessary
   wire [WIDTH_OUT-1:0] clipped = signal_in[WIDTH_IN-1] ?
                                    {1'b1, {(WIDTH_OUT-1){1'b0}}} :
                                    {1'b0, {(WIDTH_OUT-1){1'b1}}};

   wire [WIDTH_OUT-1:0] signal_selected = signal_in[lowidx +: WIDTH_OUT];

   always @(posedge clk) begin
     signal_out <= overflow ? clipped : signal_selected;
     strobe_out <= strobe_in;
   end

endmodule // variable_part_select_and_clip
