#
# Copyright 2008-2012 Ettus Research LLC
#

##################################################
# Project Setup
##################################################
# TOP_MODULE = <Input arg>
# NAME = <Input arg>
# PART_ID = <Input arg>

##################################################
# Include other makefiles
##################################################

BASE_DIR = $(abspath ..)
IP_DIR = $(abspath ./ip)
include $(BASE_DIR)/../tools/make/viv_design_builder.mak

include $(IP_DIR)/Makefile.inc
include coregen_dsp/Makefile.srcs
include $(LIB_DIR)/ip/Makefile.inc
include $(LIB_DIR)/hls/Makefile.inc
include $(LIB_DIR)/control/Makefile.srcs
include $(LIB_DIR)/fifo/Makefile.srcs
include $(LIB_DIR)/simple_gemac/Makefile.srcs
include $(LIB_DIR)/axi/Makefile.srcs
include $(LIB_DIR)/timing/Makefile.srcs
#include $(LIB_DIR)/zpu/Makefile.srcs
#include $(LIB_DIR)/wishbone/Makefile.srcs
include $(LIB_DIR)/packet_proc/Makefile.srcs
include $(LIB_DIR)/vita/Makefile.srcs
include $(LIB_DIR)/xge/Makefile.srcs
include $(LIB_DIR)/xge_interface/Makefile.srcs
include $(LIB_DIR)/dsp/Makefile.srcs
include $(LIB_DIR)/axi/Makefile.srcs
include $(LIB_DIR)/radio/Makefile.srcs
include $(LIB_DIR)/white_rabbit/wr_cores_v4_2/Makefile.srcs
#include $(LIB_DIR)/io_cap_gen/Makefile.srcs
include $(LIB_DIR)/rfnoc/Makefile.srcs
include $(BASE_DIR)/n3xx/Makefile.srcs
include $(BASE_DIR)/n3xx/dboards/mg/Makefile.srcs
include $(BASE_DIR)/n3xx/dboards/common/Makefile.srcs

##################################################
# Sources
##################################################
TOP_SRCS = \
n3xx_core.v \
n3xx_sfp_wrapper.v \
n3xx_mgt_io_core.v \
n3xx_clocking.v \
n3xx_db_fe_core.v \
n3xx_npio_qsfp_wrapper.v \
n3xx_chdr_eth_framer.v \
n3xx_eth_dispatch.v \
n3xx_eth_switch.v \


MB_XDC = \
mb_timing.xdc \
mb_pins.xdc

ifdef BUILD_WR
MB_XDC += $(abspath n3xx_wr.xdc)
TOP_SRCS += \
n3xx_wr_top.vhd \
n3xx_serial_dac.vhd \
n3xx_serial_dac_arb.vhd
endif

ifdef BUILD_10G
MB_XDC += $(abspath n310_10ge.xdc)
endif

ifdef BUILD_1G
MB_XDC += $(abspath n310_1ge.xdc)
endif

ifdef BUILD_AURORA
MB_XDC += $(abspath n310_aurora.xdc)
endif

ifndef NO_DRAM_FIFOS
DRAM_SRCS = $(IP_DRAM_XCI_SRCS) $(abspath n310_dram.xdc)
else
DRAM_SRCS =
endif

ifdef HLS
HLS_IP_GEN_SRCS = $(HLS_IP_OUTPUT_SRCS)
else
HLS_IP_GEN_SRCS =
endif

ifdef N300
MAGNESIUM_DB_XDC = $(MAGNESIUM_DB_TIMING_XDC) $(MAGNESIUM_DB0_XDC)
else
MAGNESIUM_DB_XDC = $(MAGNESIUM_DB_TIMING_XDC) $(MAGNESIUM_DB0_XDC) $(MAGNESIUM_DB1_XDC)
endif

ifdef HLS
HLS_IP_TARGETS = $(HLS_IP_OUTPUT_SRCS) hls_ip
else
HLS_IP_TARGETS =
endif

# The XDC files must be read in a specific order, motherboard first and then daughterboard.
# Outside of that, all the other sources can be read in any order desired.
DESIGN_SRCS = $(abspath $(MB_XDC)) $(MAGNESIUM_DB_XDC) $(MAGNESIUM_TOP_SRCS) \
$(abspath $(TOP_SRCS)) $(AXI_SRCS) $(FIFO_SRCS) \
$(CONTROL_LIB_SRCS) $(SDR_LIB_SRCS) $(SERDES_SRCS) \
$(SIMPLE_GEMAC_SRCS) $(TIMING_SRCS) $(COREGEN_DSP_SRCS) \
$(VRT_SRCS) $(UDP_SRCS) $(COREGEN_SRCS) $(EXTRAM_SRCS) $(WISHBONE_SRCS) \
$(XGE_SRCS) $(XGE_INTERFACE_SRCS) $(AURORA_PHY_SRCS) \
$(TEN_GIGE_PHY_SRCS) $(ONE_GIGE_PHY_SRCS) \
$(PACKET_PROC_SRCS) $(VITA_SRCS) $(DSP_SRCS) $(DRAM_SRCS) \
$(RADIO_SRCS) $(CAP_GEN_GENERIC_SRCS) $(IP_XCI_SRCS) $(BD_SRCS) \
$(RFNOC_SRCS) $(RFNOC_OOT_SRCS) $(HLS_IP_GEN_SRCS) $(LIB_IP_XCI_SRCS) $(LIBCOREGEN_SRCS) \
$(MAGNESIUM_DB_SRCS) $(DB_COMMON_SRCS) $(WHITE_RABBIT_SRCS)

##################################################
# Dependency Targets
##################################################
.SECONDEXPANSION:

VERILOG_DEFS=$(EXTRA_DEFS) $(CUSTOM_DEFS) $(GIT_HASH_VERILOG_DEF)

# DESIGN_SRCS and VERILOG_DEFS must be defined
bin: .prereqs $$(DESIGN_SRCS) ip
	$(call BUILD_VIVADO_DESIGN,$(abspath ./build_n3xx.tcl),$(TOP_MODULE),$(PART_ID))

rtl: .prereqs $$(DESIGN_SRCS) ip
	$(call CHECK_VIVADO_DESIGN,$(TOOLS_DIR)/scripts/viv_check_syntax.tcl,$(TOP_MODULE),$(PART_ID))

.PHONY: bin hls
