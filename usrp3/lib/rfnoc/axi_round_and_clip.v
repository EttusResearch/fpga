

// Copyright 2014, Ettus Research

module axi_round_and_clip
  #(parameter WIDTH_IN=24,
    parameter WIDTH_OUT=16,
    parameter CLIP_BITS=3,
    parameter FIFOSIZE=0)  // leave at 0 for a normal single flop
   (input clk, input reset,
    input [WIDTH_IN-1:0] i_tdata, input i_tlast, input i_tvalid, output i_tready,
    output [WIDTH_OUT-1:0] o_tdata, output o_tlast, output o_tvalid, input o_tready);

   wire [WIDTH_OUT+CLIP_BITS-1:0] int_tdata;
   wire int_tlast, int_tvalid, int_tready;

   axi_round #(.WIDTH_IN(WIDTH_IN), .WIDTH_OUT(WIDTH_OUT+CLIP_BITS), .round_to_nearest(1)) round
     (.clk(clk), .reset(reset),
      .i_tdata(i_tdata), .i_tlast(i_tlast), .i_tvalid(i_tvalid), .i_tready(i_tready),
      .o_tdata(int_tdata), .o_tlast(int_tlast), .o_tvalid(int_tvalid), .o_tready(int_tready));

   axi_clip #(.WIDTH_IN(WIDTH_OUT+CLIP_BITS), .WIDTH_OUT(WIDTH_OUT), .FIFOSIZE(FIFOSIZE)) clip
     (.clk(clk), .reset(reset),
      .i_tdata(int_tdata), .i_tlast(int_tlast), .i_tvalid(int_tvalid), .i_tready(int_tready),
      .o_tdata(o_tdata), .o_tlast(o_tlast), .o_tvalid(o_tvalid), .o_tready(o_tready));

endmodule // round_and_clip
