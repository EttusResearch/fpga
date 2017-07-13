#
# Copyright 2017 Ettus Research
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
LIB_IP_DIR = $(BASE_DIR)/../lib/ip

# Include makefiles and sources for all IP components
# *after* defining the LIB_IP_DIR
include $(LIB_IP_DIR)/axi_fft/Makefile.inc
include $(LIB_IP_DIR)/complex_to_magphase/Makefile.inc
include $(LIB_IP_DIR)/complex_to_magphase_int32/Makefile.inc
include $(LIB_IP_DIR)/complex_to_magphase_int16_int24/Makefile.inc
include $(LIB_IP_DIR)/complex_multiplier/Makefile.inc
include $(LIB_IP_DIR)/cordic_rotate_int24_int16/Makefile.inc
include $(LIB_IP_DIR)/divide_int16/Makefile.inc
include $(LIB_IP_DIR)/divide_int24/Makefile.inc
include $(LIB_IP_DIR)/divide_int32/Makefile.inc

DESIGN_SRCS += $(abspath \
$(LIB_IP_AXI_FFT_SRCS) \
$(LIB_IP_COMPLEX_TO_MAGPHASE_SRCS) \
$(LIB_IP_COMPLEX_TO_MAGPHASE_INT32_SRCS) \
$(LIB_IP_COMPLEX_TO_MAGPHASE_INT16_INT24_SRCS) \
$(LIB_IP_COMPLEX_MULTIPLIER_SRCS) \
$(LIB_IP_CORDIC_ROTATE_INT24_INT16_SRCS) \
$(LIB_IP_DIVIDE_INT16_SRCS) \
$(LIB_IP_DIVIDE_INT24_SRCS) \
$(LIB_IP_DIVIDE_INT32_SRCS) \
)

#-------------------------------------------------
# Testbench Specific
#-------------------------------------------------
# Define only one toplevel module
SIM_TOP = noc_block_schmidl_cox_tb

# Add test bench, user design under test, and
# additional user created files
SIM_SRCS = \
$(abspath noc_block_schmidl_cox_tb.sv)

MODELSIM_USER_DO = $(abspath wave.do)

#-------------------------------------------------
# Bottom-of-Makefile
#-------------------------------------------------
# Include all simulator specific makefiles here
# Each should define a unique target to simulate
# e.g. xsim, vsim, etc and a common "clean" target
include $(BASE_DIR)/../tools/make/viv_simulator.mak
