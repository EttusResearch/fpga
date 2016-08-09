//
// Copyright 2015 Ettus Research LLC
//
// Stores settings bus transaction in a FIFO and releases them based on VITA time input

module settings_bus_timed_fifo #(
  parameter BASE   = 0,
  parameter RANGE  = 256,
  parameter AWIDTH = 8,
  parameter DWIDTH = 32,
  parameter SIZE   = 6)
(
  input clk, input reset,
  input [63:0] vita_time,
  input set_stb, input [AWIDTH-1:0] set_addr, input [DWIDTH-1:0] set_data, input [63:0] set_time,
  output set_stb_timed, output [AWIDTH-1:0] set_addr_timed, output [DWIDTH-1:0] set_data_timed, input ready
);

  wire o_tvalid;
  reg o_tready;
  wire [63:0] set_time_fifo;
  reg [63:0] vita_time_reg;

  // Prevent writes to FIFO if they are outside the valid address range. This prevents timed commands
  // not intended for this address range from blocking the FIFO.
  wire set_stb_masked = (set_addr >= BASE && set_addr <= BASE+RANGE-1) ? set_stb : 1'b0;

  axi_fifo #(.WIDTH(AWIDTH+DWIDTH+64),.SIZE(SIZE)) axi_fifo (
    .clk(clk), .reset(reset), .clear(1'b0),
    .i_tdata({set_addr,set_data,set_time}), .i_tvalid(set_stb_masked), .i_tready(),
    .o_tdata({set_addr_timed,set_data_timed,set_time_fifo}), .o_tvalid(o_tvalid), .o_tready(o_tready),
    .space(), .occupied());

  always @(posedge clk) begin
    if (reset) begin
      o_tready      <= 1'b0;
      vita_time_reg <= 64'd0;
    end else begin
      // Register. Offset by 2 to account for registering latency for both vita_time_reg and ready.
      vita_time_reg <= vita_time + 2;
      if (vita_time_reg >= set_time_fifo) begin
        o_tready       <= ready;
      end else begin
        o_tready       <= 1'b0;
      end
    end
  end

  assign set_stb_timed = o_tvalid & o_tready;

endmodule