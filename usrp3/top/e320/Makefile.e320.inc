#
# Copyright 2008-2012 Ettus Research LLC
#

##################################################
# Project Setup
##################################################
TOP_MODULE = <Input arg>
# NAME = <Input arg>
# PART_ID = <Input arg>
# ARCH = <Input arg>

##################################################
# Include other makefiles
##################################################

BASE_DIR = $(abspath ..)
IP_DIR = $(abspath ./ip)
include $(BASE_DIR)/../tools/make/viv_design_builder.mak

include $(IP_DIR)/Makefile.inc
include ../n3xx/coregen_dsp/Makefile.srcs
include $(LIB_DIR)/ip/Makefile.inc
include $(LIB_DIR)/hls/Makefile.inc
include $(LIB_DIR)/control/Makefile.srcs
include $(LIB_DIR)/fifo/Makefile.srcs
include $(LIB_DIR)/simple_gemac/Makefile.srcs
include $(LIB_DIR)/axi/Makefile.srcs
include $(LIB_DIR)/timing/Makefile.srcs
include $(LIB_DIR)/packet_proc/Makefile.srcs
include $(LIB_DIR)/vita/Makefile.srcs
include $(LIB_DIR)/xge/Makefile.srcs
include $(LIB_DIR)/xge_interface/Makefile.srcs
include $(LIB_DIR)/dsp/Makefile.srcs
include $(LIB_DIR)/radio/Makefile.srcs
include $(LIB_DIR)/io_cap_gen/Makefile.srcs
include $(LIB_DIR)/rfnoc/Makefile.srcs

##################################################
# Sources
##################################################
TOP_SRCS = \
e320.v \
e320_core.v \
e320_clocking.v \
../n3xx/n3xx_db_fe_core.v \
n3xx_sfp_wrapper.v \
n3xx_mgt_io_core.v \
../n3xx/n3xx_eth_switch.v \
../n3xx/n3xx_eth_dispatch.v \
../n3xx/n3xx_chdr_eth_framer.v

MB_XDC = \
mb_pins.xdc \
mb_timing.xdc

ifdef BUILD_10G
MB_XDC += $(abspath e320_10ge.xdc)
endif

ifdef BUILD_1G
MB_XDC += $(abspath e320_1ge.xdc)
endif

ifdef BUILD_AURORA
MB_XDC += $(abspath e320_aurora.xdc)
endif

ifdef SFP_10GBE
MB_XDC += $(abspath e320_10ge_port0.xdc)
endif

ifndef NO_DRAM_FIFOS
DRAM_SRCS = $(IP_DRAM_XCI_SRCS) $(abspath e320_dram.xdc)
else
DRAM_SRCS =
endif

# The XDC files must be read in a specific order, motherboard first and then daughterboard.
# Outside of that, all the other sources can be read in any order desired.
DESIGN_SRCS = \
$(abspath $(TOP_SRCS)) \
$(CONTROL_LIB_SRCS) \
$(IP_XCI_SRCS) \
$(TEN_GIGE_PHY_SRCS) \
$(XGE_SRCS) \
$(XGE_INTERFACE_SRCS) \
$(PACKET_PROC_SRCS) \
$(AXI_SRCS) \
$(FIFO_SRCS) \
$(ONE_GIGE_PHY_SRCS) \
$(SIMPLE_GEMAC_SRCS) \
$(AURORA_PHY_SRCS) \
$(BD_SRCS) \
$(RADIO_SRCS) \
$(RFNOC_SRCS) \
$(TIMING_SRCS) \
$(VITA_SRCS) \
$(CAT_CAP_GEN_SRCS) \
$(DRAM_SRCS) \
$(COREGEN_DSP_SRCS) \
$(DSP_SRCS) \
$(LIB_IP_XCI_SRCS) \
$(LIB_HLS_IP_SRCS) \
$(EXTRAM_SRCS) \
$(CAP_GEN_GENERIC_SRCS) \
$(RFNOC_OOT_SRCS)\
$(LIBCOREGEN_SRCS) \
$(abspath $(MB_XDC))

##################################################
# Dependency Targets
##################################################
.SECONDEXPANSION:

VERILOG_DEFS=$(EXTRA_DEFS) $(CUSTOM_DEFS) $(GIT_HASH_VERILOG_DEF)

# DESIGN_SRCS and VERILOG_DEFS must be defined
bin: .prereqs $$(DESIGN_SRCS) ip
	$(call BUILD_VIVADO_DESIGN,$(abspath ./build_e320.tcl),$(TOP_MODULE),$(ARCH),$(PART_ID))

synth: .prereqs $$(DESIGN_SRCS) ip
	$(call BUILD_VIVADO_DESIGN,$(TOOLS_DIR)/scripts/viv_synth.tcl,$(TOP_MODULE),$(ARCH),$(PART_ID))

rtl: .prereqs $$(DESIGN_SRCS) ip
	$(call CHECK_VIVADO_DESIGN,$(TOOLS_DIR)/scripts/viv_check_syntax.tcl,$(TOP_MODULE),$(ARCH),$(PART_ID))

.PHONY: bin
