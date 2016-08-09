//
// Copyright 2015 Ettus Research LLC
//
// Muxes settings register bus onto the same clock domain

module settings_bus_mux_crossclock #(
  parameter PRIO=0, // 0 = Round robin, 1 = Lower ports get priority
  parameter AWIDTH=8,
  parameter DWIDTH=32,
  parameter NUM_BUSES=2)
(
  input [NUM_BUSES-1:0] in_clk, input [NUM_BUSES-1:0] in_rst,
  input [NUM_BUSES-1:0] in_set_stb, input [NUM_BUSES*AWIDTH-1:0] in_set_addr, input [NUM_BUSES*DWIDTH-1:0] in_set_data,
  input out_clk, input out_rst,
  output out_set_stb, output [AWIDTH-1:0] out_set_addr, output [DWIDTH-1:0] out_set_data
);

  wire [NUM_BUSES-1:0]        set_stb_sync;
  wire [NUM_BUSES*AWIDTH-1:0] set_addr_sync;
  wire [NUM_BUSES*DWIDTH-1:0] set_data_sync;

  genvar i;
  generate
    for (i = 0; i < NUM_BUSES; i = i + 1) begin
      settings_bus_crossclock #(.FLOW_CTRL(0), .SR_AWIDTH(AWIDTH), .SR_DWIDTH(DWIDTH))
      settings_bus_crossclock (
        .clk_a(in_clk[i]), .rst_a(in_rst[i]), .set_stb_a(in_set_stb[i]), .set_addr_a(in_set_addr[i]), .set_data_a(in_set_data[i]),
        .clk_b(out_clk), .rst_b(out_clk), .set_stb_b(set_stb_sync[i]), .set_addr_b(set_addr_sync[i]), .set_data_b(set_data_sync[i]), .set_ready(1'b1));
    end
  endgenerate

  settings_bus_mux #(.PRIO(PRIO), .AWIDTH(AWIDTH), .DWIDTH(DWIDTH), .NUM_BUSES(NUM_BUSES))
  settings_bus_mux (
    .clk(out_clk), .rst(out_clk),
    .in_set_stb(set_stb_sync), .in_set_addr(set_addr_sync), .in_set_data(set_data_sync),
    .out_set_stb(out_set_stb), .out_set_addr(out_set_addr), .out_set_data(out_set_data));

endmodule