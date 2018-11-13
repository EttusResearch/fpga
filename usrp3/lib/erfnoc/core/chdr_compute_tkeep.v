//
// Copyright 2018 Ettus Research, A National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// Module: chdr_compute_tkeep
// Description:
//  This module monitors an AXI-Stream CHDR bus and uses the
//  packet size field in the CHDR header to compute a tkeep
//  trailer signal to indicate the the valid bytes when
//  tlast is asserted.
//
// Parameters:
//   - CHDR_W: Width of the CHDR bus in bits
//
// Signals:
//   - axis_* : AXI-Stream CHDR bus

module chdr_compute_tkeep #(
  parameter CHDR_W = 256
)(
  input  wire                   clk,
  input  wire                   rst,
  input  wire [CHDR_W-1:0]      axis_tdata,
  input  wire                   axis_tlast,
  input  wire                   axis_tvalid,
  input  wire                   axis_tready,
  output wire [(CHDR_W/8)-1:0]  axis_tkeep
);

  `include "rfnoc_chdr_utils.vh"

  parameter LOG2_BYTE_W = $clog2(CHDR_W/8);

  // Binary to thermometer decoder
  // 2'd0 => 4'b1111 (special case)
  // 2'd1 => 4'b0001
  // 2'd2 => 4'b0011
  // 2'd3 => 4'b0111
  function [(CHDR_W/8)-1:0] bin2thermo;
    input [$clog2(CHDR_W/8)-1:0] bin;
    bin2thermo = ~((~1)<<((bin-1)%(CHDR_W/8)));
  endfunction

  // Read the packet length and figure out the number
  // of trailing words
  wire [15:0] pkt_len = chdr_get_length(axis_tdata[63:0]);
  wire [(CHDR_W/8)-1:0] len_thermo = bin2thermo(pkt_len[$clog2(CHDR_W/8)-1:0]);
  reg  [(CHDR_W/8)-1:0] reg_len_thermo = 'h0;
  reg                   is_header = 1'b1;

  always @(posedge clk) begin
    if (rst) begin
      is_header <= 1'b1;
    end else if (axis_tvalid & axis_tready) begin
      is_header <= axis_tlast;
      if (is_header) begin
        reg_len_thermo <= len_thermo;
      end
    end
  end

  // tkeep indicates trailing bytes, so for lines with tlast == 0, tkeep is
  // all 1's.
  assign axis_tkeep = (~axis_tlast) ? {LOG2_BYTE_W{1'b1}} :
    (is_header ? len_thermo : reg_len_thermo);

endmodule // chdr_compute_tkeep
