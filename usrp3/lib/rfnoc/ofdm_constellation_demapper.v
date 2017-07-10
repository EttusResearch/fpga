//
// Copyright 2015 Ettus Research
//

module ofdm_constellation_demapper #(
  parameter NUM_SUBCARRIERS        = 64,
  // Bit mask of subcarriers to exclude, such as guard bands, pilot subcarriers, DC bin, etc., Neg freq -> Pos freq
  parameter EXCLUDE_SUBCARRIERS    = 64'b1111_1100_0001_0000_0000_0000_0100_0000_1000_0001_0000_0000_0000_0100_0001_1111,
  parameter MAX_MODULATION_ORDER   = 6,  // Must be a power of 4, default QAM-64
  parameter BYTE_REVERSE           = 0,  // Reverse output bytes
  parameter SR_MODULATION_ORDER    = 0,  // 1 = BPSK, 2 = QPSK, 4 = QAM16, 6 = QAM64
  parameter SR_SCALING             = 1,  // Normalization factor (i.e. QAM64 = sqrt(42)) in Q2.14 format
  parameter SR_OUTPUT_SYMBOLS      = 2)  // Bypass symbol to gray code module and output symbols. Useful for viewing constellation.
(
  input clk, input reset, input clear,
  input set_stb, input [7:0] set_addr, input [31:0] set_data,
  input [31:0] i_tdata, input i_tlast, input i_tvalid, output i_tready,
  output [31:0] o_tdata, output o_tlast, output o_tvalid, input o_tready
);

  localparam BPSK_MOD  = 1;
  localparam QPSK_MOD  = 2;
  localparam QAM16_MOD = 4;
  localparam QAM64_MOD = 6;

  // Settings Registers
  wire [$clog2(MAX_MODULATION_ORDER):0] modulation_order;
  setting_reg #(
    .my_addr(SR_MODULATION_ORDER), .width($clog2(MAX_MODULATION_ORDER)+1), .at_reset(QPSK_MOD))
  setting_reg_modulation_order (
    .clk(clk), .rst(reset),
    .strobe(set_stb), .addr(set_addr), .in(set_data), .out(modulation_order), .changed());

  wire [15:0] scaling_tdata;
  wire scaling_tvalid, scaling_tready, scaling_tlast;
  axi_setting_reg #(
    .ADDR(SR_SCALING), .WIDTH(16), .REPEATS(1), .DATA_AT_RESET(23170)) // DATA_AT_RESET is QPSK scaling = $floor((2**14)*$sqrt(2))
  axi_setting_reg_scaling (
    .clk(clk), .reset(reset),
    .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
    .o_tdata(scaling_tdata), .o_tlast(scaling_tlast), .o_tvalid(scaling_tvalid), .o_tready(scaling_tready));

  wire output_symbols;
  setting_reg #(
    .my_addr(SR_OUTPUT_SYMBOLS), .width(1), .at_reset(0))
  setting_reg_output_symbols (
    .clk(clk), .rst(reset),
    .strobe(set_stb), .addr(set_addr), .in(set_data), .out(output_symbols), .changed());

  // Remove unused subcarriers (such as guard bands / pilot tones)
  wire [31:0] punctured_tdata;
  wire punctured_tlast, punctured_tvalid, punctured_tready;
  puncture #(
    .WIDTH(32),
    .MAX_LEN(NUM_SUBCARRIERS),
    .DEFAULT_VECTOR_LEN(NUM_SUBCARRIERS),
    .DEFAULT_PUNCTURE_VECTOR(~EXCLUDE_SUBCARRIERS))
  puncture (
    .clk(clk), .reset(reset), .clear(clear),
    .vector_len_tdata(), .vector_len_tvalid(1'b0), .vector_len_tready(),
    .puncture_vector_tdata(), .puncture_vector_tvalid(1'b0), .puncture_vector_tready(),
    .i_tdata(i_tdata), .i_tlast(i_tlast), .i_tvalid(i_tvalid), .i_tready(i_tready),
    .o_tdata(punctured_tdata), .o_tlast(punctured_tlast), .o_tvalid(punctured_tvalid), .o_tready(punctured_tready));

  // Scaling
  // Based on 802.11, format Q3.12 (1 sign bit, 3 integer, 12 fractional), +0.5 for rounding
  wire [63:0] scaled_tdata;
  wire scaled_tlast, scaled_tvalid, scaled_tready;
  mult #(.WIDTH_A(16), .WIDTH_B(16), .WIDTH_P(32), .DROP_TOP_P(1), .LATENCY(3))
  mult_i (
    .clk(clk), .reset(reset),
    .a_tdata(scaling_tdata), .a_tlast(scaling_tlast), .a_tvalid(scaling_tvalid), .a_tready(scaling_tready),
    .b_tdata(punctured_tdata[31:16]), .b_tlast(punctured_tlast), .b_tvalid(punctured_tvalid), .b_tready(punctured_tready),
    .p_tdata(scaled_tdata[63:32]), .p_tlast(scaled_tlast), .p_tvalid(scaled_tvalid), .p_tready(scaled_tready));

  mult #(.WIDTH_A(16), .WIDTH_B(16), .WIDTH_P(32), .DROP_TOP_P(1), .LATENCY(3))
  mult_q (
    .clk(clk), .reset(reset),
    .a_tdata(scaling_tdata), .a_tlast(scaling_tlast), .a_tvalid(scaling_tvalid), .a_tready(),
    .b_tdata(punctured_tdata[15:0]), .b_tlast(punctured_tlast), .b_tvalid(punctured_tvalid), .b_tready(),
    .p_tdata(scaled_tdata[31:0]), .p_tlast(), .p_tvalid(), .p_tready(scaled_tready));

  // Round back to sc16
  wire [31:0] rounded_tdata;
  wire rounded_tlast, rounded_tvalid, rounded_tready;
  axi_round_and_clip_complex #(
    .WIDTH_IN(32),
    .WIDTH_OUT(16),
    .CLIP_BITS(6))
  axi_round_complex (
    .clk(clk), .reset(reset),
    .i_tdata(scaled_tdata), .i_tlast(scaled_tlast), .i_tvalid(scaled_tvalid), .i_tready(scaled_tready),
    .o_tdata(rounded_tdata), .o_tlast(rounded_tlast), .o_tvalid(rounded_tvalid), .o_tready(rounded_tready));

  // Demap QAM symbols to gray coded bits
  wire [MAX_MODULATION_ORDER-1:0] bits_tdata;
  wire bits_tlast, bits_tvalid, bits_tready, rounded_int_tready;
  symbol_to_gray_bits #(
    .WIDTH_IN(16),
    .MODULATION_ORDER(MAX_MODULATION_ORDER))
  symbol_to_gray_bits (
    .clk(clk), .reset(reset), .clear(clear),
    .i_tdata(rounded_tdata), .i_tlast(rounded_tlast), .i_tvalid(rounded_tvalid), .i_tready(rounded_int_tready),
    .o_tdata(bits_tdata), .o_tlast(bits_tlast), .o_tvalid(bits_tvalid), .o_tready(bits_tready));

  // Pack bits into words based on modulation order
  reg [35:0] packed_bits;
  reg [31:0] packed_bits_tdata;
  reg packed_bits_tvalid;
  reg [7:0] bit_cnt;
  reg [3:0] qam64_bit_sel;
  always @(posedge clk) begin
    if (reset | clear) begin
      bit_cnt             <= 'd0;
      packed_bits_tdata   <= 'd0;
      packed_bits_tvalid  <= 1'b0;
      qam64_bit_sel       <= 0;
    end else begin
      if (bits_tvalid & bits_tready) begin
        packed_bits_tvalid    <= 1'b0;
        case (modulation_order)
          // BPSK
          BPSK_MOD : begin
            packed_bits[0]    <= bits_tdata[MAX_MODULATION_ORDER/2-1];
            packed_bits[31:1] <= packed_bits[30:0];
            if (bit_cnt > 31) begin
              bit_cnt            <= 'd1;
              packed_bits_tvalid <= 1'b1;
              packed_bits_tdata  <= packed_bits[31:0];
            end else begin
              bit_cnt            <= bit_cnt + 1;
            end
          end
          // QPSK
          QPSK_MOD : begin
            packed_bits[1:0]  <= {bits_tdata[MAX_MODULATION_ORDER-1],bits_tdata[MAX_MODULATION_ORDER/2-1]};
            packed_bits[31:2] <= packed_bits[29:0];
            if (bit_cnt > 31) begin
              bit_cnt            <= 'd2;
              packed_bits_tvalid <= 1'b1;
              packed_bits_tdata  <= packed_bits[31:0];
            end else begin
              bit_cnt            <= bit_cnt + 2;
            end
          end
          // QAM 16
          QAM16_MOD : begin
            packed_bits[3:0]  <= {bits_tdata[MAX_MODULATION_ORDER-1:MAX_MODULATION_ORDER-2],bits_tdata[MAX_MODULATION_ORDER/2-1:MAX_MODULATION_ORDER/2-2]};
            packed_bits[31:4] <= packed_bits[27:0];
            if (bit_cnt > 31) begin
              bit_cnt            <= 'd4;
              packed_bits_tvalid <= 1'b1;
              packed_bits_tdata  <= packed_bits[31:0];
            end else begin
              bit_cnt            <= bit_cnt + 4;
            end
          end
          // QAM 64
          QAM64_MOD : begin
            packed_bits[5:0]  <= bits_tdata[MAX_MODULATION_ORDER-1:MAX_MODULATION_ORDER-6];
            packed_bits[35:6] <= packed_bits[29:0];
            if (bit_cnt > 31) begin
              bit_cnt            <= bit_cnt - 32 + 6;
              packed_bits_tvalid <= 1'b1;
              case (qam64_bit_sel)
                0 : begin
                  packed_bits_tdata  <= packed_bits[35:4];
                  qam64_bit_sel      <= 1;
                end
                1 : begin
                  packed_bits_tdata  <= packed_bits[33:2];
                  qam64_bit_sel      <= 2;
                end
                2 : begin
                  packed_bits_tdata  <= packed_bits[31:0];
                  qam64_bit_sel      <= 0;
                end
              endcase
            end else begin
                bit_cnt          <= bit_cnt + 6;
            end
          end
          // Anything else always output the raw data
          default : begin
            packed_bits_tdata    <= bits_tdata;
            packed_bits_tvalid   <= 1'b1;
          end
        endcase
      end
    end
  end

  // Reverse bytes (optional)
  wire [31:0] packed_bits_reverse_tdata;
  genvar i,j;
  generate
    if (BYTE_REVERSE) begin
      for (j = 0; j < 4; j = j + 1) begin
        for (i = 0; i < 8; i = i + 1) begin
          assign packed_bits_reverse_tdata[(j+1)*8-i-1] = packed_bits_tdata[j*8+i];
        end
      end
    end else begin
      assign packed_bits_reverse_tdata = packed_bits_tdata;
    end
  endgenerate

  // Mux to output packed bits or symbols. Bypassing symbol to gray code module is useful for viewing constellation.
  wire [31:0] output_reg_tdata;
  wire output_reg_tvalid, output_reg_tready;
  assign output_reg_tdata  = output_symbols ? rounded_tdata     : packed_bits_reverse_tdata;
  assign output_reg_tvalid = output_symbols ? rounded_tvalid    : packed_bits_tvalid;
  assign rounded_tready    = output_symbols ? output_reg_tready : rounded_int_tready;
  assign bits_tready       = output_reg_tready;

  axi_fifo_flop #(.WIDTH(33)) axi_fifo_flop_output (
    .clk(clk), .reset(reset), .clear(clear),
    .i_tdata({1'b0,output_reg_tdata}), .i_tvalid(output_reg_tvalid), .i_tready(output_reg_tready),
    .o_tdata({o_tlast,o_tdata}), .o_tvalid(o_tvalid), .o_tready(o_tready),
    .space(), .occupied());

endmodule