#
# Copyright 2014 Ettus Research
#

# -------------------------------------------------------------------
# GUI Mode switch. Calling with GUI:=1 will launch Vivado GUI for build
# -------------------------------------------------------------------
ifeq ($(GUI),1)
VIVADO_MODE=gui
else
VIVADO_MODE=batch
endif

# -------------------------------------------------------------------
# Usage: BUILD_VIVADO_DESIGN
# Args: $1 = TCL_SCRIPT_NAME
#       $2 = TOP_MODULE
#       $3 = PART_ID (<device>/<package>/<speedgrade>)
# Prereqs: 
# - TOOLS_DIR must be defined globally
# - BUILD_DIR must be defined globally
# -------------------------------------------------------------------
BUILD_VIVADO_DESIGN = \
	@ \
	export VIV_TOOLS_DIR=$(TOOLS_DIR); \
	export VIV_OUTPUT_DIR=$(BUILD_DIR); \
	export VIV_TOP_MODULE=$(2); \
	export VIV_PART_NAME=$(subst /,,$(3)); \
	export VIV_MODE=$(VIVADO_MODE); \
	cd $(BUILD_DIR); \
	vivado -mode $(VIVADO_MODE) -source $(1) -log build.log -journal $(2).jou

