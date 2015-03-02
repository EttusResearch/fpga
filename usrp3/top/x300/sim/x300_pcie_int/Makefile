#
# Copyright 2014 Ettus Research LLC
#

BASE_DIR = $(abspath ../../..)
include $(BASE_DIR)/../tools/make/viv_simulator.mak

PART_ID = xc7k410t/ffg900/-2

#-------------------------------------------------
# Design Sources
#-------------------------------------------------
include $(BASE_DIR)/../lib/control/Makefile.srcs
include $(BASE_DIR)/../lib/packet_proc/Makefile.srcs
include $(BASE_DIR)/../lib/fifo/Makefile.srcs
include $(BASE_DIR)/../lib/io_port2/Makefile.srcs

DESIGN_SRCS += $(abspath \
$(FIFO_SRCS) \
$(CONTROL_LIB_SRCS) \
$(PACKET_PROC_SRCS) \
$(IOPORT2_SRCS) \
../../x300_pcie_int.v \
)

DESIGN_SRCS += $(abspath \
../../ip/fifo_short_2clk/fifo_short_2clk.xci \
../../ip/fifo_4k_2clk/fifo_4k_2clk.xci \
)

#-------------------------------------------------
# Testbench Sources
#-------------------------------------------------
# Define only one toplevel module
SIM_TOP = x300_pcie_int_tb
SIM_RUNTIME_US = 20

SIM_SRCS = \
$(abspath x300_pcie_int_tb.sv) \
$(SIMLIB_DIR)/general/sim_clks_rsts.vh \
$(SIMLIB_DIR)/general/sim_exec_report.vh
