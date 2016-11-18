//
// Copyright 2013 Ettus Research LLC
//

// Cascade FIFO :  ShortFIFO -> Block RAM fifo -> ShortFIFO for timing and placement help

// Special case SIZE <= 5 uses a short fifo

module axi_fifo_2clk_cascade
  #(parameter WIDTH=69, SIZE=9)
   (input reset,
    input i_aclk,
    input [WIDTH-1:0] i_tdata,
    input i_tvalid,
    output i_tready,
    input o_aclk,
    output [WIDTH-1:0] o_tdata,
    output o_tvalid,
    input o_tready);

   // FIXME reset should be taken into each clock domain properly
   
   wire [WIDTH-1:0] int1_tdata, int2_tdata;
   wire 	    int1_tvalid, int1_tready, int2_tvalid, int2_tready;
   
   axi_fifo_short #(.WIDTH(WIDTH)) pre_fifo
     (.clk(i_aclk), .reset(reset), .clear(1'b0),
      .i_tdata(i_tdata), .i_tvalid(i_tvalid), .i_tready(i_tready),
      .o_tdata(int1_tdata), .o_tvalid(int1_tvalid), .o_tready(int1_tready),
      .space(), .occupied());

   axi_fifo_2clk #(.WIDTH(WIDTH), .SIZE(SIZE)) main_fifo_2clk
     (.reset(reset),
      .i_aclk(i_aclk), .i_tdata(int1_tdata), .i_tvalid(int1_tvalid), .i_tready(int1_tready),
      .o_aclk(o_aclk), .o_tdata(int2_tdata), .o_tvalid(int2_tvalid), .o_tready(int2_tready));
   
   axi_fifo_short #(.WIDTH(WIDTH)) post_fifo
     (.clk(o_aclk), .reset(reset), .clear(1'b0),
      .i_tdata(int2_tdata), .i_tvalid(int2_tvalid), .i_tready(int2_tready),
      .o_tdata(o_tdata), .o_tvalid(o_tvalid), .o_tready(o_tready),
      .space(), .occupied());

endmodule // axi_fifo_2clk_cascade
