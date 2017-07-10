//
// Copyright 2015 Ettus Research
//
// Drop input words according to either a fixed or configurable bit mask (a.k.a puncturing vector).

module puncture #(
  parameter WIDTH                   = 32,      // Input bit width
  parameter MAX_LEN                 = 8,       // Maximum length of puncturing vector
  parameter DEFAULT_VECTOR_LEN      = 8,       // Vector length reset value
  parameter DEFAULT_PUNCTURE_VECTOR = 8'hFF)   // Puncture vector reset value
(
  input clk, input reset, input clear,
  input [$clog2(MAX_LEN):0] vector_len_tdata, input vector_len_tvalid, output vector_len_tready,
  input [MAX_LEN-1:0] puncture_vector_tdata, input puncture_vector_tvalid, output puncture_vector_tready,
  input [WIDTH-1:0] i_tdata, input i_tlast, input i_tvalid, output i_tready,
  output [WIDTH-1:0] o_tdata, output o_tlast, output o_tvalid, input o_tready
);

  assign vector_len_tready      = 1'b1;
  assign puncture_vector_tready = 1'b1;

  reg [$clog2(MAX_LEN):0] puncture_index, vector_len;
  reg [MAX_LEN-1:0] puncture_vector;
  always @(posedge clk) begin
    if (reset | clear) begin
      vector_len         <= DEFAULT_VECTOR_LEN-1;
      puncture_index     <= DEFAULT_VECTOR_LEN-1;
      puncture_vector    <= DEFAULT_PUNCTURE_VECTOR;
    end else begin
      if (puncture_vector_tvalid | vector_len_tvalid) begin
        puncture_index   <= vector_len_tdata - 1;
      end else if (i_tready & i_tvalid) begin
        if (puncture_index == 0) begin
          puncture_index <= vector_len;
        end else begin
          puncture_index <= puncture_index - 1;
        end
      end
      if (puncture_vector_tvalid) begin
        puncture_vector = puncture_vector_tdata;
      end
      if (vector_len_tvalid) begin
        vector_len = vector_len_tdata - 1;
      end
    end
  end

  wire puncture = puncture_vector[puncture_index];
  // Puncture by ANDing i_tvalid
  axi_fifo_flop #(.WIDTH(WIDTH+1)) axi_fifo_flop_punctured (
    .clk(clk), .reset(reset), .clear(clear),
    .i_tdata({i_tlast,i_tdata}), .i_tvalid(i_tvalid & puncture), .i_tready(i_tready),
    .o_tdata({o_tlast,o_tdata}), .o_tvalid(o_tvalid), .o_tready(o_tready),
    .space(), .occupied());

endmodule