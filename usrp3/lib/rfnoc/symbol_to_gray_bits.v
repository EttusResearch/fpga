//
// Copyright 2015 Ettus Research
//
// Map symbols to gray encoded bits
// Note: Only use with power of 4 constellations (QPSK, QAM16, QAM64)
// TODO: Extend to other constellations

module symbol_to_gray_bits #(
  parameter WIDTH_IN         = 16,
  parameter MODULATION_ORDER = 6,  // QPSK = 2, QAM16 = 4, QAM64 = 6
  parameter REVERSE          = 0)  // 0: Q/I mapping (i.e. QPSK symbol 10 Q = 1, I = 0), 1: I/Q mapping
(
  input clk, input reset, input clear,
  input [2*WIDTH_IN-1:0] i_tdata, input i_tlast, input i_tvalid, output i_tready,
  output [MODULATION_ORDER-1:0] o_tdata, output o_tlast, output o_tvalid, input o_tready
);

  // Truncate & invert sign bit
  wire [MODULATION_ORDER/2-1:0] symbol_i = {~i_tdata[2*WIDTH_IN-1],i_tdata[2*WIDTH_IN-2:2*WIDTH_IN-MODULATION_ORDER/2]};
  wire [MODULATION_ORDER/2-1:0] symbol_q = {~i_tdata[WIDTH_IN-1],i_tdata[WIDTH_IN-2:WIDTH_IN-MODULATION_ORDER/2]};

  // Symbol to gray coded bits
  reg [MODULATION_ORDER/2-1:0] gray_bits_i, gray_bits_q;
  integer k;
  always @(*) begin
    for (k = MODULATION_ORDER/2-1; k >= 0; k = k - 1) begin
      if (k == MODULATION_ORDER/2-1) begin
        gray_bits_i[k]   = symbol_i[k];
        gray_bits_q[k]   = symbol_q[k];
      end else begin
        gray_bits_i[k]   = symbol_i[k] ^ symbol_i[k+1];
        gray_bits_q[k]   = symbol_q[k] ^ symbol_q[k+1];
      end
    end
  end

  wire [MODULATION_ORDER-1:0] gray_bits = REVERSE ? {gray_bits_q,gray_bits_i} : {gray_bits_i,gray_bits_q};

  axi_fifo_flop #(.WIDTH(MODULATION_ORDER+1)) reg_gray_bits (
    .clk(clk), .reset(reset), .clear(clear),
    .i_tdata({i_tlast,gray_bits}), .i_tvalid(i_tvalid), .i_tready(i_tready),
    .o_tdata({o_tlast,o_tdata}), .o_tvalid(o_tvalid), .o_tready(o_tready),
    .space(), .occupied());

endmodule