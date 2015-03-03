#
# Copyright 2015 Ettus Research LLC
#

#-------------------------------------------------
# Top-of-Makefile
#-------------------------------------------------
# Define BASE_DIR to point to the "top" dir
BASE_DIR = $(abspath ../../..)
# Include viv_sim_preample after defining BASE_DIR
include $(BASE_DIR)/../tools/make/viv_sim_preamble.mak

#-------------------------------------------------
# Design Specific
#-------------------------------------------------
# Define part using PART_ID (<device>/<package>/<speedgrade>)
PART_ID = xc7k410t/ffg900/-2

# Include makefiles and sources for the DUT and its dependencies
include $(BASE_DIR)/../lib/control/Makefile.srcs
include $(BASE_DIR)/../lib/packet_proc/Makefile.srcs
include $(BASE_DIR)/../lib/fifo/Makefile.srcs
include $(BASE_DIR)/../lib/io_port2/Makefile.srcs

DESIGN_SRCS = $(abspath \
$(FIFO_SRCS) \
$(CONTROL_LIB_SRCS) \
$(PACKET_PROC_SRCS) \
$(IOPORT2_SRCS) \
../../x300_pcie_int.v \
)

#-------------------------------------------------
# IP Specific
#-------------------------------------------------
# If simulation contains IP, define the IP_DIR and point
# it to the base level IP directory
IP_DIR = ../../ip

# Include makefiles and sources for all IP components
# *after* defining the IP_DIR
include $(IP_DIR)/fifo_short_2clk/Makefile.inc
include $(IP_DIR)/fifo_4k_2clk/Makefile.inc

DESIGN_SRCS += $(abspath \
$(IP_FIFO_4K_2CLK_SRCS) \
$(IP_FIFO_SHORT_2CLK_SRCS) \
)

#-------------------------------------------------
# Testbench Specific
#-------------------------------------------------
include $(BASE_DIR)/../sim/general/Makefile.srcs
include $(BASE_DIR)/../sim/axi/Makefile.srcs

# Define only one toplevel module
SIM_TOP = x300_pcie_int_tb
# Simulation runtime in microseconds
SIM_RUNTIME_US = 20

SIM_SRCS = \
$(abspath x300_pcie_int_tb.sv) \
$(SIM_GENERAL_SRCS) \
$(SIM_AXI_SRCS)

#-------------------------------------------------
# Bottom-of-Makefile
#-------------------------------------------------
# Include all simulator specific makefiles here
# Each should define a unique target to simulate
# e.g. xsim, vsim, etc and a common "clean" target
include $(BASE_DIR)/../tools/make/viv_simulator.mak
