#
# Copyright 2008-2014 Ettus Research LLC
#

##################################################
# Project Setup
##################################################
export TOP_MODULE = e300
BASE_DIR = $(abspath ..)
SOURCE_DIR = $(BASE_DIR)/e300
BUILD_DIR = $(SOURCE_DIR)/build-$(NAME)

##################################################
# Include other makefiles
##################################################
include ip/Makefile.srcs
include ../../lib/control/Makefile.srcs
include ../../lib/fifo/Makefile.srcs
include ../../lib/zynq_fifo/Makefile.srcs
include ../../lib/control/Makefile.srcs
include ../../lib/timing/Makefile.srcs
include ../../lib/packet_proc/Makefile.srcs
include ../../lib/vita/Makefile.srcs
include ../../lib/dsp/Makefile.srcs
include ../../lib/radio/Makefile.srcs
include ../../lib/io_cap_gen/Makefile.srcs

##################################################
# Sources
##################################################
TOP_SRCS = \
$(SOURCE_DIR)/e300.v \
$(SOURCE_DIR)/e300_core.v \
$(SOURCE_DIR)/e300_ps.v \
$(SOURCE_DIR)/ppsloop.v \
$(SOURCE_DIR)/ad5662_auto_spi.v

TOP_XDC = \
$(SOURCE_DIR)/e300.xdc

# Source files shared with X300
X300_SHARED_SRCS = \
$(SOURCE_DIR)/coregen_dsp/hbdec1.v \
$(SOURCE_DIR)/coregen_dsp/hbdec2.v \
$(SOURCE_DIR)/coregen_dsp/hbdec3.v \
$(SOURCE_DIR)/coregen_dsp/hbint1.v \
$(SOURCE_DIR)/coregen_dsp/hbint2.v \
$(SOURCE_DIR)/coregen_dsp/hbint3.v

EDIF_NGC_SRCS = \
$(SOURCE_DIR)/coregen_dsp/hbdec1.ngc \
$(SOURCE_DIR)/coregen_dsp/hbdec2.ngc \
$(SOURCE_DIR)/coregen_dsp/hbdec3.ngc \
$(SOURCE_DIR)/coregen_dsp/hbint1.ngc \
$(SOURCE_DIR)/coregen_dsp/hbint2.ngc \
$(SOURCE_DIR)/coregen_dsp/hbint3.ngc

export VERILOG_SOURCES = \
	$(TOP_SRCS) \
	$(ZYNQ_FIFO_SRCS) \
	$(FIFO_SRCS) \
	$(VITA_SRCS) \
	$(TIMING_SRCS) \
	$(DSP_SRCS) \
	$(PACKET_PROC_SRCS) \
	$(CONTROL_LIB_SRCS) \
	$(RADIO_SRCS) \
	$(CAT_CAP_GEN_SRCS) \
	$(X300_SHARED_SRCS)

export VHDL_SOURCES =
export XDC_SOURCES = $(TOP_XDC)
export EDIF_NGC_SOURCES = $(EDIF_NGC_SRCS)
export SHORT_HASH = $(shell ../git-hash.sh)
export IP_DIRS = $(foreach dir, $(IP_DIR), $(abspath $(addprefix $(IP_BUILD_DIR)/, $(dir))))
export OUTPUT_DIR = $(BUILD_DIR)

##################################################
# Dependency Targets
##################################################
.SECONDEXPANSION:

export VHDL_SOURCES =
export XDC_SOURCES = $(TOP_XDC)
export EDIF_NGC_SOURCES = $(EDIF_NGC_SRCS)
export SHORT_HASH = $(shell ../git-hash.sh)
export IP_DIRS = $(foreach dir, $(IP_DIR), $(abspath $(addprefix $(IP_BUILD_DIR)/, $(dir))))
export OUTPUT_DIR = $(BUILD_DIR)

# Build binary build products (.bit file etc)
ifeq ($(GUI),1)
  VIV_MODE=gui
else
  VIV_MODE=batch
endif

bin: $$(VERILOG_SOURCES) $$(VHDL_SOURCES) $$(XDC_SOURCES) ipdirs
	cd $(BUILD_DIR); vivado -mode $(VIV_MODE) -source $(SOURCE_DIR)/build_e300.tcl
	$(BASE_DIR)/python/check_timing_vivado.py $(BUILD_DIR)/post_route_timing_summary.rpt
