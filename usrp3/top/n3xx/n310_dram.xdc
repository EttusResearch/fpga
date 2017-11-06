#
# Copyright 2017 Ettus Research, A National Instruments Company
# SPDX-License-Identifier: GPL-3.0
#


set_clock_groups -asynchronous -group [$bus_clk] -group [get_clocks clk_ref_i*]
set_clock_groups -asynchronous -group [$bus_clk] -group [get_clocks clk_pll_i*]
set_clock_groups -asynchronous -group [$bus_clk] -group [get_clocks mmcm_ps_clk_bufg_in*]
set_clock_groups -asynchronous -group [$bus_clk] -group [get_clocks mmcm_clkout0*]
set_clock_groups -asynchronous -group [get_clocks mmcm_clkout0*] -group [get_clocks clk_pll_i*]
