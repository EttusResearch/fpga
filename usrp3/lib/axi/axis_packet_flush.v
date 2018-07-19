//
// Copyright 2018 Ettus Research, a National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// Description:
//   When this module is inserted in an AXI-Stream link, it allows
//   the client to flip a bit to make the stream lossy. When enable=1
//   all data coming through the input is dropped. This module can
//   start and stop flushing at packet boundaries to ensure no partial
//   packets are introduces into the stream. Set FLUSH_PARTIAL_PKTS = 1
//   to disable that behavior.

module axis_packet_flush #(
  parameter WIDTH               = 64,
  parameter FLUSH_PARTIAL_PKTS  = 0
)(
  input  wire             clk,
  input  wire             reset,
  input  wire             enable,
  output wire             flushing,
  input  wire [WIDTH-1:0] s_axis_tdata,
  input  wire             s_axis_tlast,
  input  wire             s_axis_tvalid,
  output wire             s_axis_tready,
  output wire [WIDTH-1:0] m_axis_tdata,
  output wire             m_axis_tlast,
  output wire             m_axis_tvalid,
  input  wire             m_axis_tready
);

  reg mid_pkt = 1'b0;
  reg active  = 1'b0;

  always @(posedge clk) begin
    if (reset) begin
      mid_pkt <= 1'b0;
      active <= 1'b0;
    end else begin
      if (s_axis_tvalid & s_axis_tready) begin
        mid_pkt <= ~s_axis_tlast;
      end
      if (enable & ((s_axis_tvalid & s_axis_tready & s_axis_tlast) | (~mid_pkt & (~s_axis_tvalid | ~s_axis_tready)))) begin
        active <= 1'b1;
      end else if (~enable) begin
        active <= 1'b0;
      end
    end
  end

  assign flushing      = (FLUSH_PARTIAL_PKTS == 0) ? active : enable;

  assign m_axis_tdata  = s_axis_tdata;
  assign m_axis_tlast  = s_axis_tlast;
  assign m_axis_tvalid = flushing ? 1'b0 : s_axis_tvalid;
  assign s_axis_tready = flushing ? 1'b1 : m_axis_tready;

endmodule