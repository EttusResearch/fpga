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
# IP Specific
#-------------------------------------------------
# If simulation contains IP, define the IP_DIR and point
# it to the base level IP directory
IP_DIR = $(BASE_DIR)/x300/ip

# Include makefiles and sources for all IP components
# *after* defining the IP_DIR
include $(LIB_IP_DIR)/divide_int24/Makefile.inc

DESIGN_SRCS += $(abspath \
$(LIB_IP_DIVIDE_INT24_SRCS) \
)

#-------------------------------------------------
# Testbench Specific
#-------------------------------------------------
# Define only one toplevel module
SIM_TOP = noc_block_moving_avg_tb

SIM_SRCS = $(abspath \
noc_block_moving_avg_tb.sv \
../noc_block_moving_avg.v \
)

MODELSIM_USER_DO = $(abspath wave.do)

#-------------------------------------------------
# Bottom-of-Makefile
#-------------------------------------------------
# Include all simulator specific makefiles here
# Each should define a unique target to simulate
# e.g. xsim, vsim, etc and a common "clean" target
include $(BASE_DIR)/../tools/make/viv_simulator.mak
