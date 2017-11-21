//
// Copyright 2017 Ettus Research, A National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0
//
// Module: regport_to_settingbus
// Description:
// Converts regport write bus to the a setting bus
// Care must be taken when DEALIGN = 1. set_addr has the width SR_AWIDTH
// Address MSB might get chopped off in case (SR_AWIDTH + 2) != AWIDTH

module regport_to_settingsbus #(
  parameter BASE   = 14'h0,
  parameter END_ADDR = 14'h3FFF,
  parameter DWIDTH = 32,
  parameter AWIDTH = 14,
  parameter SR_AWIDTH = 12,
  // Dealign for settings bus by shifting by 2
  parameter DEALIGN = 0
)
(
  input                   clk,
  input                   reset,

  input                   reg_wr_req,
  input [AWIDTH-1:0]      reg_wr_addr,
  input [DWIDTH-1:0]      reg_wr_data,

  output                  set_stb,
  output [SR_AWIDTH-1:0]  set_addr,
  output [DWIDTH-1:0]     set_data
);

  wire [AWIDTH-1:0] set_addr_int;

  // Strobe asserted only when address is between BASE and END ADDR
  assign set_stb = reg_wr_req & (reg_wr_addr >= BASE) & (reg_wr_addr <= END_ADDR);
  assign set_addr_int = reg_wr_addr - BASE;
  // Shift by 2 in case of setting bus
  assign set_addr = DEALIGN ? {2'b0, set_addr_int[SR_AWIDTH-1:2]}
                            : set_addr_int[SR_AWIDTH-1:0];
  assign set_data = reg_wr_data;

endmodule
