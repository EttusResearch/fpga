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
ARCH = zynq
PART_ID= xc7z020/clg484/-1

DESIGN_SRCS = $(abspath ../../e310_io.v) \
  $(abspath $(addprefix $(BASE_DIR)/../lib/control/, \
  synchronizer.v \
  synchronizer_impl.v))

#-------------------------------------------------
# Testbench Specific
#-------------------------------------------------
include $(BASE_DIR)/../sim/general/Makefile.srcs

# Define only one toplevel module
SIM_TOP = e310_io_tb
# Simulation runtime in microseconds
SIM_RUNTIME_US = 20

SIM_SRCS = \
$(abspath e310_io_tb.sv) \
$(SIM_GENERAL_SRCS)

#-------------------------------------------------
# Bottom-of-Makefile
#-------------------------------------------------
# Include all simulator specific makefiles here
# Each should define a unique target to simulate
# e.g. xsim, vsim, etc and a common "clean" target
include $(BASE_DIR)/../tools/make/viv_simulator.mak
