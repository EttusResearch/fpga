//
// Copyright 2011-2013 Ettus Research LLC
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
//



module simple_uart_rx
#(
  parameter SIZE=0,
  parameter EXTRA_BUFFER=0
)
(
  input        clk,
  input        rst,
  output [7:0] fifo_out,
  input        fifo_read,
  output [7:0] fifo_level,
  output       fifo_empty,
  input [15:0] clkdiv,
  input rx
);

  reg rx_d1;
  reg rx_d2;

  always @(posedge clk)
    if(rst)
      {rx_d2,rx_d1} <= 0;
    else
      {rx_d2,rx_d1} <= {rx_d1,rx};
   
  reg [15:0]  baud_ctr;
  reg [3:0]   bit_ctr;
  reg [7:0]   sr;

  wire neg_trans = rx_d2 & ~rx_d1;
  wire shift_now = baud_ctr == (clkdiv>>1);
  wire stop_now = (bit_ctr == 10) && shift_now;
  wire go_now = (bit_ctr == 0) && neg_trans;
   
  always @(posedge clk)
    if(rst)
      sr <= 0;
    else if(shift_now)
      sr <= {rx_d2,sr[7:1]};
   
  always @(posedge clk)
    if(rst)
      baud_ctr <= 0;
    else
      if(go_now)
        baud_ctr <= 1;
       else if(stop_now)
         baud_ctr <= 0;
       else if(baud_ctr >= clkdiv)
         baud_ctr <= 1;
       else if(baud_ctr != 0)
         baud_ctr <= baud_ctr + 1;

  always @(posedge clk)
    if(rst)
      bit_ctr <= 0;
    else
      if(go_now)
         bit_ctr <= 1;
      else if(stop_now)
         bit_ctr <= 0;
       else if(baud_ctr == clkdiv)
         bit_ctr <= bit_ctr + 1;

  wire i_tready, o_tvalid;
  wire full = ~i_tready;
  wire write = ~full & rx_d2 & stop_now;
  assign fifo_empty = ~o_tvalid;

  generate

  if (EXTRA_BUFFER) begin
    wire [7:0] f0_to_f1_tdata;
    wire       f0_to_f1_tvalid;
    wire       f0_to_f1_tready;

    wire [7:0] f1_to_f2_tdata;
    wire       f1_to_f2_tvalid;
    wire       f1_to_f2_tready;

    wire [5:0] f0_occupied;
    wire [5:0] f1_occupied;
    wire [5:0] f2_occupied;

    axi_fifo #
    (
      .WIDTH(8),
      .SIZE(SIZE)
    )
    fifo0
    (
      .clk(clk),
      .reset(rst),
      .clear(1'b0),
      .i_tdata(sr),
      .i_tvalid(write),
      .i_tready(i_tready),
      .o_tdata(f0_to_f1_tdata),
      .o_tvalid(f0_to_f1_tvalid),
      .o_tready(f0_to_f1_tready),
      .space(),
      .occupied(f0_occupied)
    );

    axi_fifo #
    (
      .WIDTH(8),
      .SIZE(SIZE)
    )
    fifo1
    (
      .clk(clk),
      .reset(rst),
      .clear(1'b0),
      .i_tdata(f0_to_f1_tdata),
      .i_tvalid(f0_to_f1_tvalid),
      .i_tready(f0_to_f1_tready),
      .o_tdata(f1_to_f2_tdata),
      .o_tvalid(f1_to_f2_tvalid),
      .o_tready(f1_to_f2_tready),
      .space(),
      .occupied(f1_occupied)
    );

    axi_fifo #
    (
      .WIDTH(8),
      .SIZE(SIZE)
    )
    fifo2
    (
      .clk(clk),
      .reset(rst),
      .clear(1'b0),
      .i_tdata(f1_to_f2_tdata),
      .i_tvalid(f1_to_f2_tvalid),
      .i_tready(f1_to_f2_tready),
      .o_tdata(fifo_out),
      .o_tvalid(o_tvalid),
      .o_tready(fifo_read),
      .space(),
      .occupied(f2_occupied)
    );

    assign fifo_level = f0_occupied + f1_occupied + f2_occupied;
  end
  else begin
    wire [5:0] occ;

    axi_fifo #
    (
      .WIDTH(8),
      .SIZE(SIZE)
    )
    fifo2
    (
      .clk(clk),
      .reset(rst),
      .clear(1'b0),
      .i_tdata(sr),
      .i_tvalid(write),
      .i_tready(i_tready),
      .o_tdata(fifo_out),
      .o_tvalid(o_tvalid),
      .o_tready(fifo_read),
      .space(),
      .occupied(occ)
    );

    assign fifo_level = {2'h0, occ};
  end

  endgenerate

endmodule // simple_uart_rx
