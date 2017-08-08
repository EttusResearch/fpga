#
# Copyright 2008-2012 Ettus Research LLC
#

##################################################
# Project Setup
##################################################
TOP_MODULE = n310
# NAME = <Input arg>
# PART_ID = <Input arg>

##################################################
# Include other makefiles
##################################################

BASE_DIR = $(abspath ..)
IP_DIR = $(abspath ./ip)
include $(BASE_DIR)/../tools/make/viv_design_builder.mak

include $(IP_DIR)/Makefile.inc
#include coregen_dsp/Makefile.srcs
#include $(LIB_DIR)/ip/Makefile.inc
#include $(LIB_DIR)/hls/Makefile.inc
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
#include $(LIB_DIR)/dsp/Makefile.srcs
include $(LIB_DIR)/axi/Makefile.srcs
include $(LIB_DIR)/radio/Makefile.srcs
#include $(LIB_DIR)/io_cap_gen/Makefile.srcs
include $(LIB_DIR)/rfnoc/Makefile.srcs
include $(BASE_DIR)/n3xx/Makefile.srcs
include $(BASE_DIR)/n3xx/dboards/mg/Makefile.srcs
include $(BASE_DIR)/n3xx/dboards/common/Makefile.srcs

##################################################
# Sources
##################################################
TOP_SRCS = \
n310.v \
n310_core.v \
n310_sfpp_io_core.v \
n310.xdc \
n310_ps.v \
eth_switch.v \
network_interface.v \
timing.xdc

ifdef BUILD_10G
SFP_SERDES_SRCS += $(XGE_SRCS) $(XGE_INTERFACE_SRCS) $(abspath n310_10ge.xdc) $(TEN_GIGE_PHY_SRCS) $(IP_TEN_GIGE_PHY_XCI_SRCS)
endif

ifdef BUILD_1G
SFP_SERDES_SRCS += $(abspath n310_1ge.xdc) $(ONE_GIGE_PHY_SRCS) $(IP_ONE_GIGE_PHY_XCI_SRCS) $(abspath ../../lib/xge_interface/axi64_to_xge64.v)
endif

ifdef BUILD_AURORA
SFP_SERDES_SRCS += $(AURORA_PHY_SRCS) $(AURORA_PHY_1_SRCS) $(IP_AURORA_XCI_SRCS) $(abspath n310_aurora.xdc) $(abspath ../../lib/xge_interface/axi64_to_xge64.v) $(TEN_GIGE_PHY_SRCS)
endif

ifdef SFP0_10GBE
SFP_SERDES_SRCS += $(abspath n310_10ge_port0.xdc)
endif

ifdef SFP1_10GBE
SFP_SERDES_SRCS += $(abspath n310_10ge_port1.xdc)
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

DESIGN_SRCS = $(abspath $(TOP_SRCS)) $(AXI_SRCS) $(FIFO_SRCS) \
$(CONTROL_LIB_SRCS) $(SDR_LIB_SRCS) $(SERDES_SRCS) \
$(SIMPLE_GEMAC_SRCS) $(TIMING_SRCS) $(COREGEN_DSP_SRCS) \
$(VRT_SRCS) $(UDP_SRCS) $(COREGEN_SRCS) $(EXTRAM_SRCS) \
$(WISHBONE_SRCS) \
$(SFP_SERDES_SRCS) $(COREGEN_CHIPSCOPE_SRCS) \
$(PACKET_PROC_SRCS) $(VITA_SRCS) $(DSP_SRCS) $(DRAM_SRCS) \
$(AXI_SRCS) $(RADIO_SRCS) $(CAP_GEN_GENERIC_SRCS) $(IP_XCI_SRCS) $(BD_SRCS) \
$(RFNOC_SRCS) $(RFNOC_OOT_SRCS) $(HLS_IP_GEN_SRCS) $(LIB_IP_XCI_SRCS) $(LIBCOREGEN_SRCS) \
$(MAGNESIUM_SRCS) $(DB_COMMON_SRCS)

SHORT_HASH=$(addprefix GIT_HASH=,$(shell ../../tools/scripts/git-hash.sh))

##################################################
# Dependency Targets
##################################################
.SECONDEXPANSION:

VERILOG_DEFS=$(EXTRA_DEFS) $(CUSTOM_DEFS) $(SHORT_HASH)

# DESIGN_SRCS and VERILOG_DEFS must be defined
bin: .prereqs $$(DESIGN_SRCS) ip
	$(call BUILD_VIVADO_DESIGN,$(abspath ./build_n3xx.tcl),$(TOP_MODULE),$(PART_ID))

hls: .prereqs hls_ip bin

.PHONY: bin hls
