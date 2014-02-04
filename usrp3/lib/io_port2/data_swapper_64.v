//
// Copyright 2013 Ettus Research LLC
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

module data_swapper_64 (
   input  [2:0]   swap_lanes,

   input  [63:0]  i_tdata,
   output [63:0]  o_tdata
);
   localparam SWAP_32B = 3'b100;
   localparam SWAP_16B = 3'b010;
   localparam SWAP_8B  = 3'b001;

   wire [63:0] data_p1, data_p2;

   assign data_p1 = (|(swap_lanes & SWAP_32B)) ? { i_tdata[31:0], i_tdata[63:32] } : i_tdata;
   assign data_p2 = (|(swap_lanes & SWAP_16B)) ? { data_p1[47:32], data_p1[63:48], data_p1[15:0],  data_p1[31:16] } : data_p1;
   assign o_tdata = (|(swap_lanes & SWAP_8B))  ? { data_p2[55:48], data_p2[63:56], data_p2[39:32], data_p2[47:40], 
                                                   data_p2[23:16], data_p2[31:24], data_p2[7:0],   data_p2[15:8]  } : data_p2;

endmodule // data_swapper_64
