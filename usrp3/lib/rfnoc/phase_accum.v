//
// Copyright 2015 Ettus Research
//
// Expects scaled radians fixed point input format of the form Q2.#,
// Example: WIDTH_IN=8 then input format: Q2.5 (sign bit, 2 integer bits, 5 fraction bits)
module phase_accum #(
  parameter WIDTH_ACCUM = 16,
  parameter WIDTH_IN = 16,
  parameter WIDTH_OUT = 16)
(
  input clk, input reset, input clear,
  input [WIDTH_IN-1:0] i_tdata, input i_tlast, input i_tvalid, output i_tready,
  output [WIDTH_OUT-1:0] o_tdata, output o_tlast, output o_tvalid, input o_tready
);

  reg signed [WIDTH_ACCUM-1:0] accum, accum_next, phase_inc;
  // Scaled radians. Restrict range from +1 to -1.
  wire signed [WIDTH_ACCUM-1:0] POS_ROLLOVER = 2**(WIDTH_ACCUM-3);
  wire signed [WIDTH_ACCUM-1:0] NEG_ROLLOVER = -(2**(WIDTH_ACCUM-3));

  wire [WIDTH_OUT-1:0] output_round_tdata;
  wire output_round_tvalid, output_round_tready, output_round_tlast;

  // Reset accumulator output on i_tlast
  wire [WIDTH_ACCUM-1:0] output_tdata = i_tlast ? {WIDTH_ACCUM{1'b0}} : accum;

  // Phase accumulator, can rotate in either direction
  always @(posedge clk) begin
    if (reset | clear) begin
      accum      <= 'd0;
      accum_next <= 'd0;
      phase_inc  <= 'd0;
    end else if (i_tvalid & i_tready) begin
      if (i_tlast) begin
        accum       <= {WIDTH_ACCUM{1'b0}};
        accum_next  <= $signed(i_tdata);
        phase_inc   <= $signed(i_tdata);
      end else begin
        if (accum >= POS_ROLLOVER) begin
            accum_next <= accum_next + phase_inc - 2*POS_ROLLOVER;
            accum      <= accum + phase_inc - 2*POS_ROLLOVER;
        end else if (accum <= NEG_ROLLOVER) begin
            accum_next <= accum_next + phase_inc - 2*NEG_ROLLOVER;
            accum      <= accum + phase_inc - 2*NEG_ROLLOVER;
        end else begin
            accum_next <= accum_next + phase_inc;
            accum      <= accum + phase_inc;
        end
      end
    end
  end

  generate
    // Bypass rounding if accumulator width is same as output width
    if (WIDTH_ACCUM == WIDTH_OUT) begin
      assign output_round_tdata = output_tdata;
      assign output_round_tvalid = i_tvalid;
      assign output_round_tlast = i_tlast;
      assign i_tready = output_round_tready;
    end else begin
      axi_round #(
        .WIDTH_IN(WIDTH_ACCUM),
        .WIDTH_OUT(WIDTH_OUT))
      axi_round (
        .clk(clk), .reset(reset),
        .i_tdata(output_tdata), .i_tlast(i_tlast), .i_tvalid(i_tvalid), .i_tready(i_tready),
        .o_tdata(output_round_tdata), .o_tlast(output_round_tlast), .o_tvalid(output_round_tvalid), .o_tready(output_round_tready));
    end
  endgenerate

  axi_fifo_flop #(.WIDTH(WIDTH_OUT+1)) axi_fifo_flop_output (
    .clk(clk), .reset(reset), .clear(clear),
    .i_tdata({output_round_tlast,output_round_tdata}), .i_tvalid(output_round_tvalid), .i_tready(output_round_tready),
    .o_tdata({o_tlast,o_tdata}), .o_tvalid(o_tvalid), .o_tready(o_tready),
    .occupied(), .space());

endmodule
