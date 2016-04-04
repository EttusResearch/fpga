module pass_thru_and_invert (
  input clk, input reset,
  input [31:0] i_tdata, input i_tlast, input i_tvalid, output i_tready,
  output [31:0] pass_thru_tdata, output pass_thru_tlast, output pass_thru_tvalid, input pass_thru_tready,
  output [31:0] invert_tdata, output invert_tlast, output invert_tvalid, input invert_tready);

  wire [31:0] out_tdata[0:1];
  wire [1:0] out_tlast;
  wire [1:0] out_tvalid;
  wire [1:0] out_tready;
  split_stream_fifo #(
    .WIDTH(32), .ACTIVE_MASK(4'b0011))
  split_stream_fifo (
    .clk(clk), .reset(reset), .clear(1'b0),
    .i_tdata(i_tdata), .i_tlast(i_tlast), .i_tvalid(i_tvalid), .i_tready(i_tready),
    .o0_tdata(out_tdata[0]), .o0_tlast(out_tlast[0]), .o0_tvalid(out_tvalid[0]), .o0_tready(out_tready[0]),
    .o1_tdata(out_tdata[1]), .o1_tlast(out_tlast[1]), .o1_tvalid(out_tvalid[1]), .o1_tready(out_tready[1]),
    .o2_tready(1'b1), .o3_tready(1'b1));

  // Caculate inverted data + a register stage to show a path with a different length
  axi_fifo_flop #(.WIDTH(33))
  axi_fifo_flop (
    .clk(clk), .reset(reset), .clear(),
    .i_tdata({out_tlast[1],~out_tdata[1]}), .i_tvalid(out_tvalid[1]), .i_tready(out_tready[1]),
    .o_tdata({invert_tlast,invert_tdata}), .o_tvalid(invert_tvalid), .o_tready(invert_tready));

  // Pass through data
  assign pass_thru_tdata = out_tdata[0];
  assign pass_thru_tlast = out_tlast[0];
  assign pass_thru_tvalid = out_tvalid[0];
  assign out_tready[0] = pass_thru_tready;

endmodule
