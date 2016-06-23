//
// Copyright 2016 Ettus Research
//

module cic_interpolate #(
  parameter WIDTH = 16,
  parameter N = 4,
  parameter MAX_RATE = 256
)(
  input clk,
  input reset,
  input rate_stb,
  input [$clog2(MAX_RATE+1)-1:0] rate, // +1 due to $clog2() rounding
  input  strobe_in,
  output strobe_out,
  input [WIDTH-1:0] signal_in,
  output reg [WIDTH-1:0] signal_out
);

  wire [WIDTH+(N*$clog2(MAX_RATE+1))-1:0] signal_in_ext;
  reg  [WIDTH+(N*$clog2(MAX_RATE+1))-1:0] integrator [0:N-1];
  reg  [WIDTH+(N*$clog2(MAX_RATE+1))-1:0] differentiator [0:N-1];
  reg  [WIDTH+(N*$clog2(MAX_RATE+1))-1:0] pipeline [0:N-1];

  integer i;

  sign_extend #(WIDTH,WIDTH+(N*$clog2(MAX_RATE+1))) ext_input (.in(signal_in),.out(signal_in_ext));

  // Differentiate
  always @(posedge clk) begin
    if (reset) begin
      for (i = 0; i < N; i = i + 1) begin
        pipeline[i]       <= 0;
        differentiator[i] <= 0;
      end
    end else begin
      if (strobe_in) begin
        differentiator[0] <= signal_in_ext;
        pipeline[0]       <= signal_in_ext - differentiator[0];
        for (i = 1; i < N; i = i + 1) begin
          differentiator[i] <= pipeline[i-1];
          pipeline[i]       <= pipeline[i-1] - differentiator[i];
        end
      end
    end
  end

  // Strober
  reg [$clog2(MAX_RATE+1):0] counter;
  reg counter_done;

  always @(posedge clk) begin
    if (reset | rate_stb) begin
      counter      <= rate;
      counter_done <= 1;
    end else if (strobe_in) begin
      counter      <= 1;
      counter_done <= 0;
    end else if (counter >= rate) begin
      counter_done <= 1;
    end else if (~counter_done) begin
      counter <= counter + 1;
    end
  end

  assign strobe_out = (~(counter >= rate) | strobe_in) & ~rate_stb;

  // Integrate
  always @(posedge clk) begin
    if (reset) begin
      for (i = 0; i < N; i = i + 1) begin
        integrator[i] <= 0;
      end
    end else begin
      if (strobe_out) begin
        if (strobe_in) begin
          integrator[0] <= integrator[0] + pipeline[N-1];
        end
        for (i = 1; i < N; i = i + 1) begin
          integrator[i] <= integrator[i] + integrator[i-1];
        end
      end
    end
  end

  genvar l;
  wire [WIDTH-1:0] signal_out_shifted[0:MAX_RATE];
  generate
    for (l = 1; l <= MAX_RATE; l = l + 1) begin
      // N*log2(rate), $clog2(rate) = ceil(log2(rate)) which rounds to nearest shift without overflow
      assign signal_out_shifted[l] = integrator[N-1][$clog2(l**N)+WIDTH-1:$clog2(l**N)];
    end
  endgenerate
  assign signal_out_shifted[0] = integrator[N-1][WIDTH-1:0];

  // Output register
  always @(posedge clk) begin
    if (reset) begin
      signal_out <= 'd0;
    end else begin
      signal_out <= signal_out_shifted[rate];
    end
  end

endmodule
