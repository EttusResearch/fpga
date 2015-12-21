#
# Copyright 2014-2016 Ettus Research LLC
#

##################################################
# Project Setup
##################################################
TOP_MODULE = n230
# NAME = <Input arg> 
# PART_ID = <Input arg> 

##################################################
# Include other makefiles
##################################################

BASE_DIR = $(abspath ..)
IP_DIR = $(abspath ./ip)
include $(BASE_DIR)/../tools/make/viv_design_builder.mak

include $(IP_DIR)/Makefile.inc
include $(LIB_DIR)/control/Makefile.srcs
include $(LIB_DIR)/fifo/Makefile.srcs
include $(LIB_DIR)/simple_gemac/Makefile.srcs
include $(LIB_DIR)/timing/Makefile.srcs
include $(LIB_DIR)/zpu/Makefile.srcs
include $(LIB_DIR)/wishbone/Makefile.srcs
include $(LIB_DIR)/packet_proc/Makefile.srcs
include $(LIB_DIR)/vita/Makefile.srcs
include $(LIB_DIR)/dsp/Makefile.srcs
include $(LIB_DIR)/axi/Makefile.srcs
include $(LIB_DIR)/radio/Makefile.srcs
include $(LIB_DIR)/io_cap_gen/Makefile.srcs
include $(LIB_DIR)/extramfifo/Makefile.srcs
include $(LIB_DIR)/wb_spi/Makefile.srcs

##################################################
# Sources
##################################################
TOP_SRCS = $(abspath \
n230.v \
n230_core.v \
zpu_bootram.v \
zpu_subsystem.v \
phy_clump.v \
n230_test_jesd204_if.v \
n230.xdc \
timing.xdc \
)

DESIGN_SRCS = \
$(TOP_SRCS) \
$(FIFO_SRCS) \
$(CONTROL_LIB_SRCS) \
$(SIMPLE_GEMAC_SRCS) \
$(TIMING_SRCS) \
$(WISHBONE_SRCS) \
$(ETH_SRCS)  \
$(PACKET_PROC_SRCS) \
$(VITA_SRCS) \
$(DSP_SRCS) \
$(AXI_SRCS) \
$(RADIO_LEGACY_SRCS) \
$(CAT_CAP_GEN_SRCS) \
$(ZPU_CORE_SRCS) \
$(ZPU_CONFIG_SRCS) \
$(EXTRAM_SRCS) \
$(WB_SPI_SRCS) \
$(IP_XCI_SRCS)

# Additional Verilog defs
EXTRA_DEFS = DELETE_FORMAT_CONVERSION
ifeq (1,$(SAFE_MODE))
EXTRA_DEFS += SAFE_IMAGE
endif
ifeq (1,$(TEST_MODE))
EXTRA_DEFS += TEST_JESD204_IF
endif

# Git Hash
SHORT_HASH=$(addprefix GIT_HASH=,$(shell $(BASE_DIR)/../tools/scripts/git-hash.sh))

##################################################
# Dependency Targets
##################################################
.SECONDEXPANSION:

VERILOG_DEFS=$(EXTRA_DEFS) $(SHORT_HASH)
export SAFE_MODE=$(SAFE_MODE)
export TEST_MODE=$(TEST_MODE)

# DESIGN_SRCS and VERILOG_DEFS must be defined
bin: .prereqs $$(DESIGN_SRCS) ip
	$(call BUILD_VIVADO_DESIGN,$(abspath ./build_n230.tcl),$(TOP_MODULE),$(PART_ID))

.PHONY: bin
