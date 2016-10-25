//
// Copyright 2016 Ettus Research LLC
//

module cordic #(
  parameter bitwidth = 16,
  parameter stages = 19,
  parameter zwidth = 24
)(
  input clk,
  input reset,
  input enable,
  input strobe_in,
  output strobe_out,
  input last_in,
  output last_out,
  input [bitwidth-1:0] xi,
  input [bitwidth-1:0] yi,
  output [bitwidth-1:0] xo,
  output [bitwidth-1:0] yo,
  input [zwidth-1:0] zi,
  output [zwidth-1:0] zo
);

  reg  [bitwidth+1:0] xi_reg, yi_reg;
  reg  [zwidth-2:0]   zi_reg;
  wire [bitwidth+1:0] x[0:stages+1];
  wire [bitwidth+1:0] y[0:stages+1];
  wire [zwidth-2:0]   z[0:stages+1];
  reg                 strobe_in_reg;
  wire [stages+1:0]   strobe;
  reg                 last_in_reg;
  wire [stages+1:0]   last;

  wire [bitwidth+1:0] xi_ext = {{2{xi[bitwidth-1]}},xi};
  wire [bitwidth+1:0] yi_ext = {{2{yi[bitwidth-1]}},yi};

  // constants for 24 bit wide phase
  wire [22:0] c[0:23];
  assign c[0]  = 23'd2097152;
  assign c[1]  = 23'd1238021;
  assign c[2]  = 23'd654136;
  assign c[3]  = 23'd332050;
  assign c[4]  = 23'd166669;
  assign c[5]  = 23'd83416;
  assign c[6]  = 23'd41718;
  assign c[7]  = 23'd20860;
  assign c[8]  = 23'd10430;
  assign c[9]  = 23'd5215;
  assign c[10] = 23'd2608;
  assign c[11] = 23'd1304;
  assign c[12] = 23'd652;
  assign c[13] = 23'd326;
  assign c[14] = 23'd163;
  assign c[15] = 23'd81;
  assign c[16] = 23'd41;
  assign c[17] = 23'd20;
  assign c[18] = 23'd10;
  assign c[19] = 23'd5;
  assign c[20] = 23'd3;
  assign c[21] = 23'd1;
  assign c[22] = 23'd1;
  assign c[23] = 23'd0;

  always @(posedge clk) begin
    if (reset) begin
      strobe_in_reg <= 1'b0;
      last_in_reg   <= 1'b0;
      xi_reg        <= 'd0;
      yi_reg        <= 'd0;
      zi_reg        <= 'd0;
    end else if (enable) begin
      strobe_in_reg <= strobe_in;
      if (strobe_in) begin 
        last_in_reg <= last_in;
        zi_reg      <= zi[zwidth-2:0];
        case (zi[zwidth-1:zwidth-2])
          2'b00, 2'b11 : begin
            xi_reg  <= xi_ext;
            yi_reg  <= yi_ext;
          end
          2'b01, 2'b10 : begin
            xi_reg  <= -xi_ext;
            yi_reg  <= -yi_ext;
          end
        endcase // case(zi[zwidth-1:zwidth-2])
      end
    end // else: !if(reset)
  end

  assign x[0]      = xi_reg;
  assign y[0]      = yi_reg;
  assign z[0]      = zi_reg;
  assign strobe[0] = strobe_in_reg;
  assign last[0]   = last_in_reg;

  genvar i;
  generate
    for (i = 0; i < stages+1; i = i + 1) begin
      _cordic_stage #(bitwidth+2,zwidth-1,i) cordic_stage (
        .clk(clk), .reset(reset), .enable(enable),
        .strobe_in(strobe[i]), .strobe_out(strobe[i+1]),
        .last_in(last[i]), .last_out(last[i+1]),
        .xi(x[i]), .yi(y[i]), .zi(z[i]), .constant(c[i]),
        .xo(x[i+1]), .yo(y[i+1]), .zo(z[i+1]));
    end
  endgenerate

  assign xo         = x[stages+1][bitwidth:1];
  assign yo         = y[stages+1][bitwidth:1];
  assign zo         = z[stages+1];
  assign strobe_out = strobe[stages+1];
  assign last_out   = last[stages+1];

endmodule // cordic

module _cordic_stage #(
  parameter bitwidth = 16,
  parameter zwidth = 16,
  parameter shift = 1
)(
  input clk,
  input reset,
  input enable,
  input strobe_in,
  output reg strobe_out,
  input last_in,
  output reg last_out,
  input [bitwidth-1:0] xi,
  input [bitwidth-1:0] yi,
  input [zwidth-1:0] zi,
  input [zwidth-1:0] constant,
  output reg [bitwidth-1:0] xo,
  output reg [bitwidth-1:0] yo,
  output reg [zwidth-1:0] zo
);

  wire z_is_pos = ~zi[zwidth-1];

  always @(posedge clk) begin
    if (reset) begin
      strobe_out <= 1'b0;
      last_out <= 1'b0;
      xo <= 0;
      yo <= 0;
      zo <= 0;
    end else if (enable) begin
      strobe_out <= strobe_in;
      if (strobe_in) begin
        last_out <= last_in;
        xo <= z_is_pos ? xi - {{shift+1{yi[bitwidth-1]}},yi[bitwidth-2:shift]} :
                         xi + {{shift+1{yi[bitwidth-1]}},yi[bitwidth-2:shift]};
        yo <= z_is_pos ? yi + {{shift+1{xi[bitwidth-1]}},xi[bitwidth-2:shift]} :
                         yi - {{shift+1{xi[bitwidth-1]}},xi[bitwidth-2:shift]};
        zo <= z_is_pos ? zi - constant :
                         zi + constant;
      end
    end
  end
endmodule
