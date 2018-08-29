#
# Copyright 2016 Ettus Research
#

#-------------------------------------------------
# Top-of-Makefile
#-------------------------------------------------
# Define BASE_DIR to point to the "top" dir
BASE_DIR = $(abspath ../../../../../../top)
# Include viv_sim_preample after defining BASE_DIR
include $(BASE_DIR)/../tools/make/viv_sim_preamble.mak

#-------------------------------------------------
# Design Specific
#-------------------------------------------------
# Define part using PART_ID (<device>/<package>/<speedgrade>)
ARCH = zynq
PART_ID = xc7z100/ffg900/-2


#-------------------------------------------------
# IP Specific
#-------------------------------------------------
# If simulation contains IP, define the IP_DIR and point
# it to the base level IP directory
LIB_IP_DIR = $(BASE_DIR)/../lib/ip

#-------------------------------------------------
# IP Specific
#-------------------------------------------------
# If simulation contains IP, define the IP_DIR and point
# it to the base level IP directory
IP_DIR = $(BASE_DIR)/n3xx/ip

# Include makefiles and sources for all IP components
# *after* defining the LIB_IP_DIR
include $(IP_DIR)/delay_tap_bram/Makefile.inc
include $(IP_DIR)/aurora_64b66b_pcs_pma/Makefile.inc
include $(IP_DIR)/fifo_short_2clk/Makefile.inc
include $(IP_DIR)/axi64_8k_2clk_fifo/Makefile.inc
include $(LIB_IP_DIR)/complex_multiplier_dds/Makefile.inc
include $(LIB_IP_DIR)/dds_sin_cos_lut_only/Makefile.inc
include $(BASE_DIR)/x300/coregen_dsp/Makefile.srcs


DESIGN_SRCS += $(abspath \
$(IP_DELAY_TAP_BRAM_SRCS) \
$(IP_AURORA_64B66B_PCS_PMA_SRCS) \
$(IP_AXI64_8K_2CLK_FIFO_SRCS) \
$(IP_FIFO_SHORT_2CLK_SRCS) \
$(LIB_IP_COMPLEX_MULTIPLIER_DDS_SRCS) \
$(LIB_IP_DDS_SIN_COS_LUT_ONLY_SRCS) \
$(COREGEN_DSP_SRCS) \
../beamform_delay_and_sum.v \
../multi_stream_add.v \
../multi_stream_aurora_handler.v \
../noc_block_ddc_eiscat.v \
../noc_block_radio_core_eiscat.v \
../rx_control_eiscat.v \
../settings_reg_fir_tap_bram_config.v \
../time_align_control_eiscat.v \
)

#-------------------------------------------------
# Testbench Specific
#-------------------------------------------------
# Define only one toplevel module
SIM_TOP = noc_block_radio_core_eiscat_tb

# Add test bench, user design under test, and
# additional user created files
SIM_SRCS = \
$(abspath noc_block_radio_core_eiscat_tb.sv) 

MODELSIM_USER_DO = $(abspath wave.do)

#-------------------------------------------------
# Bottom-of-Makefile
#-------------------------------------------------
# Include all simulator specific makefiles here
# Each should define a unique target to simulate
# e.g. xsim, vsim, etc and a common "clean" target
include $(BASE_DIR)/../tools/make/viv_simulator.mak
