#
# Copyright 2015 Ettus Research LLC
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
include $(LIB_DIR)/axi/Makefile.srcs
include $(LIB_DIR)/ip/Makefile.inc
include $(LIB_DIR)/axi/Makefile.srcs
include $(LIB_DIR)/hls/Makefile.inc
include $(LIB_DIR)/control/Makefile.srcs
include $(LIB_DIR)/fifo/Makefile.srcs
include $(LIB_DIR)/zynq_fifo/Makefile.srcs
include $(LIB_DIR)/control/Makefile.srcs
include $(LIB_DIR)/timing/Makefile.srcs
include $(LIB_DIR)/packet_proc/Makefile.srcs
include $(LIB_DIR)/vita/Makefile.srcs
include $(LIB_DIR)/dsp/Makefile.srcs
include $(LIB_DIR)/radio/Makefile.srcs
include $(LIB_DIR)/rfnoc/Makefile.srcs
include $(LIB_DIR)/io_cap_gen/Makefile.srcs
include $(BASE_DIR)/e300/Makefile.OOT.inc

##################################################
# Sources
##################################################
TOP_SRCS = e3xx_ps.v \
           ppsloop.v \
           spi_slave.v \
           axi_pmu.v

ifeq (E310,$(findstring E310, $(EXTRA_DEFS)))
TOP_SRCS += e310.v
TOP_SRCS += e310_core.v
TOP_SRCS += e310_io.v
TOP_SRCS += e310.xdc
TOP_SRCS += e310_timing.xdc
else
TOP_SRCS += e3xx_idle.v
TOP_SRCS += e3xx_idle.xdc
endif

ifdef HLS
HLS_IP_TARGETS = $(HLS_IP_OUTPUT_SRCS) hls_ip
else
HLS_IP_TARGETS =
endif

# Vivado seems somewhat unhappy when adding above
TOP_SRCS += e3xx.xdc \
            e3xx_timing.xdc

ifeq (,$(findstring E3XX_SG3, $(EXTRA_DEFS)))
PS7_SRCS = $(IP_PS7_1_SRCS)
else
PS7_SRCS = $(IP_PS7_3_SRCS)
endif

DESIGN_SRCS = $(abspath $(TOP_SRCS)) \
          $(AXI_SRCS) \
          $(ZYNQ_FIFO_SRCS) \
          $(FIFO_SRCS) \
          $(VITA_SRCS) \
          $(TIMING_SRCS) \
          $(DSP_SRCS) \
          $(PACKET_PROC_SRCS) \
          $(CONTROL_LIB_SRCS) \
          $(RADIO_SRCS) \
          $(CAT_CAP_GEN_SRCS) \
          $(COREGEN_DSP_SRCS) \
          $(IP_XCI_SRCS) \
          $(PS7_SRCS) \
          $(AXI_SRCS) \
          $(RFNOC_SRCS) \
          $(RFNOC_OOT_SRCS) \
          $(LIB_IP_XCI_SRCS) \
          $(HLS_IP_TARGETS)

##################################################
# Dependency Targets
##################################################
.SECONDEXPANSION:

VERILOG_DEFS=$(EXTRA_DEFS) $(CUSTOM_DEFS) $(GIT_HASH_VERILOG_DEF)

# DESIGN_SRCS and VERILOG_DEFS must be defined
bin: .prereqs $$(DESIGN_SRCS) ip
	$(call BUILD_VIVADO_DESIGN,$(abspath ./build_e300.tcl),$(TOP_MODULE),$(PART_ID))

rtl: .prereqs $$(DESIGN_SRCS) ip
	$(call CHECK_VIVADO_DESIGN,$(TOOLS_DIR)/scripts/viv_check_syntax.tcl,$(TOP_MODULE),$(PART_ID))

.PHONY: bin rtl
