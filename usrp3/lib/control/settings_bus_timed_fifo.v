//
// Copyright 2015 Ettus Research LLC
//
// Stores settings bus transaction in a FIFO and releases them based on VITA time input

module settings_bus_timed_fifo #(
  parameter AWIDTH=8,
  parameter DWIDTH=32,
  parameter SIZE=6)
(
  input clk, input rst,
  input [63:0] vita_time,
  input set_stb, input [7:0] set_addr, input [31:0] set_data, input [63:0] set_vita,
  output set_stb_timed, output [7:0] set_addr_timed, output [31:0] set_data_timed, input ready
);

  wire o_tvalid;
  reg o_tready;
  wire [63:0] set_vita_fifo;
  reg [63:0] vita_time_reg;

  axi_fifo #(.WIDTH(AWIDTH+DWIDTH+64),.SIZE(SIZE)) axi_fifo (
    .clk(ce_clk), .reset(rst), .clear(1'b0),
    .i_tdata({set_addr,set_data,set_vita}), .i_tvalid(set_stb), .i_tready(),
    .o_tdata({set_addr_timed,set_data_timed,set_vita_fifo}), .o_tvalid(o_tvalid), .o_tready(o_tready),
    .space(), .occupied());

  always @(posedge clk) begin
    if (rst) begin
      o_tready      <= 1'b0;
      vita_time_reg <= 64'd0;
    end else begin
      // Register. Offset by 2 to account for registering latency for both vita_time_reg and ready.
      vita_time_reg <= vita_time - 2;
      if (vita_time_reg >= set_vita_fifo) begin
        o_tready       <= ready;
      end else begin
        o_tready       <= 1'b0;
      end
    end
  end

  assign set_stb_timed = o_tvalid & o_tready;

endmodule