//
// Copyright 2017 Ettus Research
//
// Throttle input stream.
//

module axi_throttle #(
  parameter INITIAL_STATE = 0,   // Throttle state after reset
  parameter WAIT_FOR_LAST = 0,   // 0: Throttle mid packet, 1: Wait for end of packet
  parameter WIDTH         = 64
)(
  input clk,
  input reset,
  input enable,
  output active,
  input [WIDTH-1:0] i_tdata,
  input i_tlast,
  input i_tvalid,
  output i_tready,
  output [WIDTH-1:0] o_tdata,
  output o_tlast,
  output o_tvalid,
  input o_tready
);

  reg throttle_reg = INITIAL_STATE[0];
  reg mid_pkt;

  assign active = WAIT_FOR_LAST ? throttle_reg : enable;

  assign o_tdata  = i_tdata;
  assign o_tlast  = i_tlast;
  assign o_tvalid = active ? 1'b0 : i_tvalid;
  assign i_tready = active ? 1'b1 : o_tready;

  always @(posedge clk) begin
    if (reset) begin
      mid_pkt      <= 1'b0;
      throttle_reg <= INITIAL_STATE[0];
    end else begin
      if (i_tvalid & i_tready) begin
        mid_pkt    <= ~i_tlast;
      end
      if (enable & ((i_tvalid & i_tready & i_tlast) | (~mid_pkt & (~i_tvalid | ~i_tready)))) begin
        throttle_reg <= 1'b1;
      end else if (~enable) begin
        throttle_reg <= 1'b0;
      end
    end
  end

endmodule