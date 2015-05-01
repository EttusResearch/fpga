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

include ../../tools/make/viv_preamble.mak

include ip/Makefile.inc
include coregen_dsp/Makefile.srcs
include ../../lib/ip/Makefile.inc
include ../../lib/control/Makefile.srcs
include ../../lib/fifo/Makefile.srcs
include ../../lib/zynq_fifo/Makefile.srcs
include ../../lib/control/Makefile.srcs
include ../../lib/timing/Makefile.srcs
include ../../lib/packet_proc/Makefile.srcs
include ../../lib/vita/Makefile.srcs
include ../../lib/dsp/Makefile.srcs
include ../../lib/radio/Makefile.srcs
include ../../lib/rfnoc/Makefile.srcs
include ../../lib/io_cap_gen/Makefile.srcs

##################################################
# Sources
##################################################
TOP_SRCS = e300_ps.v \
           e300_core.v \
           ppsloop.v \
           ad5662_auto_spi.v \
           e300.xdc \
           timing.xdc

ifeq (,$(findstring E3X0_IDLE_IMAGE, $(EXTRA_DEFS)))
TOP_SRCS += e300.v
else
TOP_SRCS += e300_idle.v
endif

SOURCES = $(abspath $(TOP_SRCS)) \
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
          $(RFNOC_SRCS) \
          $(LIB_IP_XCI_SRCS)

##################################################
# Git Hash
##################################################
SHORT_HASH=$(addprefix GIT_HASH=,$(shell ../../tools/scripts/git-hash.sh))

##################################################
# Dependency Targets
##################################################
.SECONDEXPANSION:

export VIV_SOURCE_FILES=$(SOURCES)
export VIV_VERILOG_DEFS=$(EXTRA_DEFS) $(SHORT_HASH)

bin: prereqs $$(SOURCES) ip lib_ip
	$(call BUILD_VIVADO_DESIGN,$(abspath ./build_e300.tcl),$(TOP_MODULE),$(PART_ID))

.PHONY: bin
