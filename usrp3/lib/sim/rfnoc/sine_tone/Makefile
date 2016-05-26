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
# IP Specific
#-------------------------------------------------
# If simulation contains IP, define the IP_DIR and point
# it to the base level IP directory
LIB_IP_DIR = $(BASE_DIR)/../lib/ip

# Include makefiles and sources for all IP components
# *after* defining the IP_DIR
include $(LIB_IP_DIR)/cordic_rotator/Makefile.inc

DESIGN_SRCS += $(abspath \
$(LIB_IP_CORDIC_ROTATOR_SRCS) \
)

#-------------------------------------------------
# Testbench Specific
#-------------------------------------------------
# Define only one toplevel module
SIM_TOP = sine_tone_tb

SIM_SRCS = $(abspath \
sine_tone_tb.sv \
)

MODELSIM_USER_DO = $(abspath wave.do)

#-------------------------------------------------
# Bottom-of-Makefile
#-------------------------------------------------
# Include all simulator specific makefiles here
# Each should define a unique target to simulate
# e.g. xsim, vsim, etc and a common "clean" target
include $(BASE_DIR)/../tools/make/viv_simulator.mak
