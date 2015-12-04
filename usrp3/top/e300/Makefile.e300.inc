#
# Copyright 2015 Ettus Research LLC
#

##################################################
# Project Setup
##################################################
TOP_MODULE = e300
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
include $(LIB_DIR)/control/Makefile.srcs
include $(LIB_DIR)/fifo/Makefile.srcs
include $(LIB_DIR)/zynq_fifo/Makefile.srcs
include $(LIB_DIR)/control/Makefile.srcs
include $(LIB_DIR)/timing/Makefile.srcs
include $(LIB_DIR)/packet_proc/Makefile.srcs
include $(LIB_DIR)/vita/Makefile.srcs
include $(LIB_DIR)/dsp/Makefile.srcs
include $(LIB_DIR)/radio/Makefile.srcs
include $(LIB_DIR)/io_cap_gen/Makefile.srcs

##################################################
# Sources
##################################################
TOP_SRCS = e300_ps.v \
           e300_core.v \
           ppsloop.v \
           spi_slave.v \
           axi_pmu.v \
           e300.xdc \
           timing.xdc

ifeq (,$(findstring E3X0_IDLE_IMAGE, $(EXTRA_DEFS)))
TOP_SRCS += e300.v
else
TOP_SRCS += e300_idle.v
endif

DESIGN_SRCS = $(abspath $(TOP_SRCS)) \
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
              $(IP_XCI_SRCS)

##################################################
# Git Hash
##################################################
SHORT_HASH=$(addprefix GIT_HASH=,$(shell ../../tools/scripts/git-hash.sh))

##################################################
# Dependency Targets
##################################################
.SECONDEXPANSION:

VERILOG_DEFS=$(EXTRA_DEFS) $(CUSTOM_DEFS) $(SHORT_HASH)

# DESIGN_SRCS and VERILOG_DEFS must be defined
bin: .prereqs $$(DESIGN_SRCS) ip
	$(call BUILD_VIVADO_DESIGN,$(abspath ./build_e300.tcl),$(TOP_MODULE),$(PART_ID))

.PHONY: bin
