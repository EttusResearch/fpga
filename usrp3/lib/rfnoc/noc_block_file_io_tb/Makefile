#
# Copyright 2015 National Instruments
#

#-------------------------------------------------
# Top-of-Makefile
#-------------------------------------------------
# Define BASE_DIR to point to the "top" dir
BASE_DIR = $(abspath ../../../top)
# Include viv_sim_preample after defining BASE_DIR
include $(BASE_DIR)/../tools/make/viv_sim_preamble.mak

#-------------------------------------------------
# Design Specific
#-------------------------------------------------
# Define part using PART_ID (<device>/<package>/<speedgrade>)
# and architecture (zynq, kintex7, or artix7)
ARCH = kintex7
PART_ID = xc7k410t/ffg900/-2

#-------------------------------------------------
# Testbench Specific
#-------------------------------------------------
include $(BASE_DIR)/../sim/general/Makefile.srcs
include $(BASE_DIR)/../sim/axi/Makefile.srcs
include $(BASE_DIR)/../sim/control/Makefile.srcs
include $(BASE_DIR)/../sim/rfnoc/Makefile.srcs

# Define only one toplevel module
SIM_TOP = noc_block_file_io_tb
# Simulation runtime in microseconds
SIM_RUNTIME_US = 1000

SIM_SRCS = \
$(abspath noc_block_file_io_tb.sv) \
$(SIM_GENERAL_SRCS) \
$(SIM_AXI_SRCS) \
$(SIM_CONTROL_SRCS) \
$(SIM_RFNOC_SRCS)

#-------------------------------------------------
# Bottom-of-Makefile
#-------------------------------------------------
# Include all simulator specific makefiles here
# Each should define a unique target to simulate
# e.g. xsim, vsim, etc and a common "clean" target
include $(BASE_DIR)/../tools/make/viv_simulator.mak
