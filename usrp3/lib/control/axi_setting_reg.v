//
// Copyright 2016 Ettus Research LLC
//
// Settings register with AXI stream output.

module axi_setting_reg #(
  parameter ADDR = 0, 
  parameter AWIDTH = 8,
  parameter WIDTH = 32,
  parameter USE_LAST = 0,
  parameter USE_FIFO = 0,
  parameter FIFO_SIZE = 5,
  parameter DATA_AT_RESET = 0,
  parameter VALID_AT_RESET = 0,
  parameter LAST_AT_RESET = 0,
  parameter REPEATS = 0,
  parameter MSB_ALIGN = 0
)
(
  input clk, input reset, output reg error_stb,
  input set_stb, input [AWIDTH-1:0] set_addr, input [31:0] set_data,
  output [WIDTH-1:0] o_tdata, output o_tlast, output o_tvalid, input o_tready
);

  reg init;

  reg [WIDTH-1:0] o_tdata_int;
  reg o_tlast_int, o_tvalid_int;
  wire o_tready_int;

  always @(posedge clk) begin
    if (reset) begin
      o_tdata_int <= DATA_AT_RESET;
      o_tvalid_int <= VALID_AT_RESET;
      o_tlast_int <= LAST_AT_RESET;
      init <= 1'b0;
      error_stb <= 1'b0;
    end else begin
      error_stb <= 1'b0;
      if ((set_stb & (ADDR[AWIDTH-1:0] == set_addr)) || (set_stb & ((ADDR[AWIDTH-1:0]+1'b1) == set_addr) & USE_LAST)) begin
        init <= 1'b1;
        o_tdata_int <= (MSB_ALIGN == 0) ? set_data[WIDTH-1:0] : set_data[31:32-WIDTH];
        o_tvalid_int <= 1'b1;
        if (set_stb & ((ADDR[AWIDTH-1:0]+1'b1) == set_addr) & USE_LAST) begin
          o_tlast_int <= 1'b1;
        end else begin
          o_tlast_int <= 1'b0;
        end
        if (~o_tready_int) begin
          error_stb <= 1'b1;
        end
      end
      if (o_tvalid_int & o_tready_int & (REPEATS == 0)) begin
        o_tlast_int <= 1'b0;
        o_tvalid_int <= 1'b0;
      end
    end
  end

  generate
    if (USE_FIFO) begin
      axi_fifo #(
        .WIDTH(WIDTH+1), .SIZE(FIFO_SIZE))
      axi_fifo (
        .clk(clk), .reset(reset), .clear(1'b0),
        .i_tdata({o_tlast_int,o_tdata_int}), .i_tvalid(o_tvalid_int), .i_tready(o_tready_int),
        .o_tdata({o_tlast,o_tdata}), .o_tvalid(o_tvalid), .o_tready(o_tready),
        .space(), .occupied());
    end else begin
      assign o_tdata = o_tdata_int;
      assign o_tlast = o_tlast_int;
      assign o_tvalid = o_tvalid_int;
      assign o_tready_int = o_tready;
    end
  endgenerate

endmodule