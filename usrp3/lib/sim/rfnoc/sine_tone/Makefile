#
# Copyright 2015 Ettus Research LLC
#

#-------------------------------------------------
# Top-of-Makefile
#-------------------------------------------------
# Define BASE_DIR to point to the "top" dir
BASE_DIR = $(abspath ../../../../top)
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
include $(BASE_DIR)/../lib/axi/Makefile.srcs
include $(BASE_DIR)/../lib/control/Makefile.srcs
include $(BASE_DIR)/../lib/fifo/Makefile.srcs
include $(BASE_DIR)/../lib/rfnoc/Makefile.srcs

DESIGN_SRCS = $(abspath \
$(AXI_SRCS) \
$(CONTROL_LIB_SRCS) \
$(FIFO_SRCS) \
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
include $(LIB_IP_DIR)/cordic_rotator/Makefile.inc

DESIGN_SRCS += $(abspath \
$(IP_FIFO_SHORT_2CLK_SRCS) \
$(IP_FIFO_4K_2CLK_SRCS) \
$(LIB_IP_AXI_FFT_SRCS) \
$(LIB_IP_COMPLEX_TO_MAGPHASE_SRCS) \
$(LIB_IP_CORDIC_ROTATOR_SRCS)\
)

#-------------------------------------------------
# Testbench Specific
#-------------------------------------------------
include $(BASE_DIR)/../lib/sim/Makefile.srcs
include $(BASE_DIR)/../lib/axi/Makefile.srcs
include $(BASE_DIR)/../lib/control/Makefile.srcs
include $(BASE_DIR)/../lib/rfnoc/Makefile.srcs

# Define only one toplevel module
SIM_TOP = sine_tone_tb
# Simulation runtime in microseconds
SIM_RUNTIME_US = 4000

SIM_SRCS = \
$(abspath sine_tone_tb.sv) \
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
