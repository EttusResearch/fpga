//
// Copyright 2012-2014 Ettus Research LLC
//


// General FIFO block
//  If Size == 0, uses a flop (axi_fifo_flop)
//  If Size <= 5, uses SRL32 (axi_fifo_short)
//  If Size >5, uses BRAM fifo (axi_fifo_bram)

module axi_fifo
  #(parameter WIDTH=32, SIZE=9)
   (input clk, input reset, input clear,
    input [WIDTH-1:0] i_tdata,
    input i_tvalid,
    output i_tready,
    output [WIDTH-1:0] o_tdata,
    output o_tvalid,
    input o_tready,
    
    output [15:0] space,
    output [15:0] occupied);
   
   generate
      if(SIZE==0)
	begin
	   axi_fifo_flop #(.WIDTH(WIDTH)) fifo_flop
	      (.clk(clk), .reset(reset), .clear(clear),
	       .i_tdata(i_tdata), .i_tvalid(i_tvalid), .i_tready(i_tready),
	       .o_tdata(o_tdata), .o_tvalid(o_tvalid), .o_tready(o_tready),
	       .space(space[0]), .occupied(occupied[0]));
	   assign space[15:1] = 15'd0;
	   assign occupied[15:1] = 15'd0;
	end
      else if(SIZE<=5) 
	begin
           axi_fifo_short #(.WIDTH(WIDTH)) fifo_short
		    (.clk(clk), .reset(reset), .clear(clear),
		     .i_tdata(i_tdata), .i_tvalid(i_tvalid), .i_tready(i_tready),
		     .o_tdata(o_tdata), .o_tvalid(o_tvalid), .o_tready(o_tready),
		     .space(space[5:0]), .occupied(occupied[5:0]));
           assign space[15:6] = 10'd0;
           assign occupied[15:6] = 10'd0;
	end
      else
        axi_fifo_bram #(.WIDTH(WIDTH), .SIZE(SIZE)) fifo_bram
	  (.clk(clk), .reset(reset), .clear(clear),
	   .i_tdata(i_tdata), .i_tvalid(i_tvalid), .i_tready(i_tready),
	   .o_tdata(o_tdata), .o_tvalid(o_tvalid), .o_tready(o_tready),
	   .space(space), .occupied(occupied));
   endgenerate
      
endmodule // axi_fifo
