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

# Include makefiles and sources for the DUT and its dependencies
include $(BASE_DIR)/../lib/fifo/Makefile.srcs
include $(BASE_DIR)/../lib/axi/Makefile.srcs
include $(BASE_DIR)/../lib/control/Makefile.srcs
include $(BASE_DIR)/../lib/vita/Makefile.srcs
include $(BASE_DIR)/../lib/timing/Makefile.srcs
include $(BASE_DIR)/../lib/packet_proc/Makefile.srcs
include $(BASE_DIR)/../lib/rfnoc/Makefile.srcs

DESIGN_SRCS = $(abspath \
$(FIFO_SRCS) \
$(AXI_SRCS) \
$(CONTROL_LIB_SRCS) \
$(VITA_SRCS) \
$(TIMING_SRCS) \
$(PACKET_PROC_SRCS) \
$(RFNOC_SRCS) \
)

#-------------------------------------------------
# IP Specific
#-------------------------------------------------
# If simulation contains IP, define the IP_DIR and point
# it to the base level IP directory
IP_DIR = $(BASE_DIR)/x300/ip
LIB_IP_DIR = $(BASE_DIR)/../lib/ip

# Include makefiles and sources for all IP components
# *after* defining the IP_DIR
include $(IP_DIR)/fifo_short_2clk/Makefile.inc
include $(IP_DIR)/fifo_4k_2clk/Makefile.inc
include $(LIB_IP_DIR)/axi_fft/Makefile.inc
include $(LIB_IP_DIR)/complex_to_magphase/Makefile.inc
include $(LIB_IP_DIR)/complex_multiplier/Makefile.inc
include $(LIB_IP_DIR)/divide_int16_int32/Makefile.inc

DESIGN_SRCS += $(abspath \
$(IP_FIFO_SHORT_2CLK_SRCS) \
$(IP_FIFO_4K_2CLK_SRCS) \
$(LIB_IP_AXI_FFT_SRCS) \
$(LIB_IP_COMPLEX_TO_MAGPHASE_SRCS) \
$(LIB_IP_COMPLEX_MULTIPLIER_SRCS) \
$(LIB_IP_DIVIDE_INT16_INT32_SRCS) \
)

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
$(abspath ../../control/axi_crossbar_intf.sv) \
$(SIM_GENERAL_SRCS) \
$(SIM_AXI_SRCS) \
$(SIM_CONTROL_SRCS) \
$(SIM_RFNOC_SRCS)

MODELSIM_USER_DO = $(abspath wave.do)

#-------------------------------------------------
# Bottom-of-Makefile
#-------------------------------------------------
# Include all simulator specific makefiles here
# Each should define a unique target to simulate
# e.g. xsim, vsim, etc and a common "clean" target
include $(BASE_DIR)/../tools/make/viv_simulator.mak
