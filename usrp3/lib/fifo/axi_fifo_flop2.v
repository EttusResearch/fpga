//
// Copyright 2015 Ettus Research LLC
//
// Single cycle latency, depth of 2 "Flip flop" with no end to end combinatorial paths on
// AXI control signals (such as i_tready depends on o_tready). Breaking the combinatorial
// paths requires an additional register stage.
//
// Note: Once i_tvalid is asserted, it cannot be deasserted without i_tready having asserted
//       indicating i_tdata has been read. This is an AXI stream requirement.

module axi_fifo_flop2 #(
  parameter WIDTH = 32)
(
  input clk,
  input reset,
  input clear,
  input [WIDTH-1:0] i_tdata,
  input i_tvalid,
  output i_tready,
  output [WIDTH-1:0] o_tdata,
  output o_tvalid,
  input o_tready,
  output [1:0] space,
  output [1:0] occupied);

  reg [WIDTH-1:0] i_tdata_pipe  = 'd0;
  reg [WIDTH-1:0] i_tdata_reg   = 'd0;
  reg             i_tvalid_pipe = 1'b0;
  reg             i_tvalid_reg  = 1'b0;

  // Steady state data flow is typically: i_tdata -> i_tdata_reg -> o_tdata
  // but can change to: i_tdata -> i_tdata_reg -> i_tdata_pipe -> o_tdata
  // depending on i_tvalid / o_tready combinations
  always @(posedge clk) begin
    // Always accept new data if there is space in the pipeline
    if (i_tready) begin
      i_tdata_reg  <= i_tdata;
      i_tvalid_reg <= i_tvalid;
    end
    if (o_tready) begin
      if (i_tready) begin
        // Only useful when data flow is i_tdata -> i_tdata_reg -> i_tdata_pipe -> o_tdata
        i_tdata_pipe <= i_tdata_reg;
        if (i_tvalid_pipe) begin
          // Switch from: i_tdata -> i_tdata_reg -> i_tdata_pipe -> o_tdata
          // to:          i_tdata -> i_tdata_reg -> o_tdata
          // will occur if i_tvalid_reg = 0
          i_tvalid_pipe <= i_tvalid_reg;
        end
      // Input is throttled
      end else begin
        i_tdata_pipe  <= i_tdata_reg;
        i_tvalid_pipe <= i_tvalid_reg;
        i_tvalid_reg  <= 1'b0; // Since i_tready = 0, we know we will not get new data this cycle
      end
    // Output is throttled
    end else begin
      // Space available in i_tdata_pipe to store i_tdata_reg.
      // This is the case where data flow will change
      // from: i_tdata -> i_tdata_reg -> o_tdata
      // to:   i_tdata -> i_tdata_reg -> i_tdata_pipe -> o_tdata
      // if i_tvalid_reg = 1
      if (~i_tvalid_pipe) begin
        i_tvalid_pipe <= i_tvalid_reg;
        i_tdata_pipe  <= i_tdata_reg;
      end
    end
    // This module will be used very often, so only reset
    // tvalid paths to save on fanout.
    if (reset | clear) begin
      i_tvalid_reg  <= 1'b0;
      i_tvalid_pipe <= 1'b0;
    end
  end

  assign i_tready = ~(i_tvalid_reg & i_tvalid_pipe);

  assign o_tvalid = i_tvalid_pipe ? 1'b1         : i_tvalid_reg;
  assign o_tdata  = i_tvalid_pipe ? i_tdata_pipe : i_tdata_reg;

  assign occupied = i_tvalid_reg + i_tvalid_pipe;
  assign space = 2'd2 - occupied;

endmodule
