//
// Copyright 2014 Ettus Research LLC
//
// Settings register with AXI stream output.

module axi_setting_reg #(
  parameter ADDR = 0, 
  parameter AWIDTH = 8,
  parameter WIDTH = 32,
  parameter DATA_AT_RESET = 0,
  parameter VALID_AT_RESET = 0,
  parameter ALWAYS_VALID = 0)
(
  input clk, input reset, 
  input set_stb, input [AWIDTH-1:0] set_addr, input [31:0] set_data,
  output reg [WIDTH-1:0] o_tdata, output o_tlast, output reg o_tvalid, input o_tready
);

  always @(posedge clk) begin
    if (reset) begin
      o_tdata  <= DATA_AT_RESET;
      o_tvalid <= VALID_AT_RESET;
    end else begin
      if (set_stb & (ADDR==set_addr)) begin
        o_tdata  <= set_data[WIDTH-1:0];
        o_tvalid <= 1'b1;
      end
      if (o_tvalid & o_tready) begin
        o_tvalid <= 1'b0;
      end
      if (ALWAYS_VALID) begin
        o_tvalid <= 1'b1;
      end
    end
  end

  assign o_tlast = 1'b0;

endmodule