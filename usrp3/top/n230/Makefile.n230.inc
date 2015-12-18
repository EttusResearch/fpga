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
include $(LIB_DIR)/io_cap_gen/Makefile.srcs

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
ext_sram.xdc \
)

B200_RADIO = $(BASE_DIR)/b200/radio_b200.v

USRP2_SPI_SRCS = \
$(BASE_DIR)/../../usrp2/opencores/spi/rtl/verilog/spi_clgen.v \
$(BASE_DIR)/../../usrp2/opencores/spi/rtl/verilog/spi_defines.v \
$(BASE_DIR)/../../usrp2/opencores/spi/rtl/verilog/spi_shift.v \
$(BASE_DIR)/../../usrp2/opencores/spi/rtl/verilog/spi_top16.v \
$(BASE_DIR)/../../usrp2/opencores/spi/rtl/verilog/spi_top.v

USRP2_MISC_SRCS = \
$(BASE_DIR)/../../usrp2/extramfifo/ext_fifo.v \
$(BASE_DIR)/../../usrp2/extramfifo/nobl_fifo.v \
$(BASE_DIR)/../../usrp2/extramfifo/nobl_if.v \
$(BASE_DIR)/../../usrp2/extramfifo/refill_randomizer.v \
$(BASE_DIR)/../../usrp2/control_lib/bin2gray.v \
$(BASE_DIR)/../../usrp2/control_lib/user_settings.v

DESIGN_SRCS = \
$(TOP_SRCS) \
$(FIFO_SRCS) \
$(CONTROL_LIB_SRCS) \
$(SDR_LIB_SRCS) \
$(SERDES_SRCS) \
$(SIMPLE_GEMAC_SRCS) \
$(TIMING_SRCS) \
$(VRT_SRCS) \
$(UDP_SRCS) \
$(COREGEN_SRCS) \
$(EXTRAM_SRCS) \
$(WISHBONE_SRCS) \
$(ETH_SRCS)  \
$(PACKET_PROC_SRCS) \
$(VITA_SRCS) \
$(DSP_SRCS) \
$(DRAM_SRCS) \
$(AXI_SRCS) \
$(B200_RADIO) \
$(CAT_CAP_GEN_SRCS) \
$(ZPU_CORE_SRCS) \
$(ZPU_CONFIG_SRCS) \
$(USRP2_SPI_SRCS) \
$(USRP2_MISC_SRCS) \
$(IP_XCI_SRCS)

# Additional Verilog defs
EXTRA_DEFS = EXT_SRAM_FIFO DELETE_FORMAT_CONVERSION
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
