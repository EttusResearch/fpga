//
// Copyright 2018 Ettus Research, A National Instruments Brand
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// Module: all_tb
//
// Description: Run all testbenches
//

`default_nettype none


module test_all_erfnoc_tb;

  timeunit 1ns;
  timeprecision 1ps;

  test_axi_stream_tb test_axi_stream_tb ();
  test_chdr_tb       test_chdr_tb       ();
  test_axis_ctrl_tb  test_axis_ctrl_tb  ();

endmodule
