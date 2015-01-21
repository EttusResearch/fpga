//
// Copyright 2015 Ettus Research LLC
//
// Flip flop with registered AXI control signals, ensuring no end to end combinatorial paths
// at the expense of additional registers.
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
  output reg i_tready,
  output [WIDTH-1:0] o_tdata,
  output o_tvalid,
  input o_tready,
  output space,
  output occupied);
  
  reg [WIDTH-1:0] i_tdata_pipe, i_tdata_reg;
  reg             i_tvalid_pipe, i_tvalid_reg;

  always @(posedge clk) begin
    if (reset | clear) begin
      i_tready <= 1'b1;
      i_tvalid_reg <= 1'b0;
      i_tvalid_pipe <= 1'b0;
    end else begin
      if (i_tready) begin
        i_tdata_reg <= i_tdata;
        i_tvalid_reg <= i_tvalid;
      end
      if (o_tready) begin
        i_tready <= 1'b1;
      end else begin
        // Throttle input. Need to store input data in our scratch register
        // as i_tvalid might be asserted. This is the case that requires an additional register
        // to break the i_tready / o_tready combinatorial path.
        if (i_tready) begin
          i_tdata_pipe <= i_tdata_reg;
          i_tvalid_pipe <= i_tvalid_reg;
          i_tready <= 1'b0;
        end
      end
    end
  end
  
  assign o_tvalid = i_tready ? i_tvalid_reg : i_tvalid_pipe;
  assign o_tdata = i_tready ? i_tdata_reg : i_tdata_pipe;

  assign space = i_tready;
  assign occupied = i_tvalid_pipe;

endmodule