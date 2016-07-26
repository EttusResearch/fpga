//
// Copyright 2016 Ettus Research
//
// Synchronizes AXI stream buses so data is released on every port simultaneously.
//

module axi_sync #(
  parameter WIDTH     = 32,
  parameter SIZE      = 2,
  parameter FIFO_SIZE = 0
)(
  input clk, input reset, input clear,
  input [(WIDTH*SIZE)-1:0] i_tdata, input  [SIZE-1:0] i_tlast, input  [SIZE-1:0] i_tvalid, output [SIZE-1:0] i_tready,
  input [(WIDTH*SIZE)-1:0] o_tdata, output [SIZE-1:0] o_tlast, output [SIZE-1:0] o_tvalid, input  [SIZE-1:0] o_tready
);

  wire [(WIDTH*SIZE)-1:0] int_tdata;
  wire [SIZE-1:0] int_tlast, int_tvalid, int_tready;

  genvar i;
  generate
    for (i = 0; i < SIZE; i = i + 1) begin
      axi_fifo #(.WIDTH(WIDTH+1), .SIZE(FIFO_SIZE)) axi_fifo (
        .clk(clk), .reset(reset), .clear(clear),
        .i_tdata({i_tlast[i],i_tdata[WIDTH*(i+1)-1:WIDTH*i]}), .i_tvalid(i_tvalid[i]), .i_tready(i_tready[i]),
        .o_tdata({int_tlast[i],int_tdata[WIDTH*(i+1)-1:WIDTH*i]}), .o_tvalid(int_tvalid[i]), .o_tready(int_tready[i]),
        .space(), .occupied());
    end
  endgenerate

  assign o_tdata    = int_tdata;
  assign o_tlast    = int_tlast;

  wire consume = (&int_tvalid) & (&o_tready);
  assign int_tready = {SIZE{consume}};
  assign o_tvalid   = {SIZE{consume}};

endmodule