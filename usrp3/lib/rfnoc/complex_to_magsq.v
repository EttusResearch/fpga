//
// Copyright 2014 Ettus Research LLC
//

module complex_to_magsq #(
  parameter WIDTH = 16)
(
  input clk, input reset, input clear,
  input [2*WIDTH-1:0] i_tdata, input i_tlast, input i_tvalid, output i_tready,
  output [2*WIDTH-1:0] o_tdata, output o_tlast, output o_tvalid, input o_tready);

  wire [WIDTH-1:0] i = i_tdata[2*WIDTH-1:WIDTH];
  wire [WIDTH-1:0] q = i_tdata[WIDTH-1:0];
  wire [2*WIDTH-1:0] i_sq_tdata, q_sq_tdata;
  wire i_sq_tlast, q_sq_tlast;
  wire i_sq_tvalid, q_sq_tvalid;
  wire i_sq_tready;

  // i^2
  mult #(
   .WIDTH_A(WIDTH),
   .WIDTH_B(WIDTH),
   .WIDTH_P(2*WIDTH),
   .DROP_TOP_P(6),
   .CASCADE_OUT(0))
  i_sq_mult (
    .clk(clk), .reset(reset),
    .a_tdata(i), .a_tlast(i_tlast), .a_tvalid(i_tvalid), .a_tready(i_tready),
    .b_tdata(i), .b_tlast(i_tlast), .b_tvalid(i_tvalid), .b_tready(),
    .p_tdata(i_sq_tdata), .p_tlast(i_sq_tlast), .p_tvalid(i_sq_tvalid), .p_tready(i_sq_tready));

  // q^2
  mult #(
   .WIDTH_A(WIDTH),
   .WIDTH_B(WIDTH),
   .WIDTH_P(2*WIDTH),
   .DROP_TOP_P(6),
   .CASCADE_OUT(0))
  q_sq_mult (
    .clk(clk), .reset(reset),
    .a_tdata(q), .a_tlast(i_tlast), .a_tvalid(i_tvalid), .a_tready(),
    .b_tdata(q), .b_tlast(i_tlast), .b_tvalid(i_tvalid), .b_tready(),
    .p_tdata(q_sq_tdata), .p_tlast(q_sq_tlast), .p_tvalid(q_sq_tvalid), .p_tready(i_sq_tready));

  wire [2*WIDTH-1:0] mag_sq = i_sq_tdata + q_sq_tdata;

  // i^2 + q^2
  axi_fifo_flop #(.WIDTH(2*WIDTH+1))
  inst_axi_fifo_flop (
    .clk(clk), .reset(reset), .clear(1'b0),
    .i_tdata({i_sq_tlast,mag_sq}), .i_tvalid(i_sq_tvalid), .i_tready(i_sq_tready),
    .o_tdata({o_tlast,o_tdata}), .o_tvalid(o_tvalid), .o_tready(o_tready));

endmodule