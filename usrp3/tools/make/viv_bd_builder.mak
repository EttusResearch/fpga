#
# Copyright 2014 Ettus Research
#

# -------------------------------------------------------------------
# Usage: BUILD_VIVADO_BD
# Args: $1 = IP_NAME (IP name)
#       $2 = ARCH (zynq, kintex7, etc)
#       $3 = PART_ID (<device>/<package>/<speedgrade>)
#       $4 = BD_SRC_DIR (Absolute path to the top level ip src dir)
#       $5 = BD_BUILD_DIR (Absolute path to the top level ip build dir)
# Prereqs: 
# - TOOLS_DIR must be defined globally
# -------------------------------------------------------------------
BUILD_VIVADO_BD = \
	@ \
	echo "========================================================"; \
	echo "BUILDER: Building BD $(1)"; \
	echo "========================================================"; \
	export BD_FILE=$(call RESOLVE_PATH,$(5)/$(1)/$(1).bd); \
	export PART_NAME=$(subst /,,$(3)); \
	export SYNTH_BD=$(SYNTH_BD); \
	echo "BUILDER: Staging BD in build directory..."; \
	$(TOOLS_DIR)/scripts/shared-ip-loc-manage.sh --path=$(5)/$(1) reserve; \
        cp -rf $(4)/$(1)/* $(5)/$(1); \
	echo "BUILDER: Retargeting BD to part $(2)/$(3)..."; \
	cd $(5)/$(1); \
	echo "BUILDER: Building BD..."; \
	export VIV_ERR=0; \
	$(TOOLS_DIR)/scripts/launch_vivado.sh -mode batch -source $(call RESOLVE_PATH,$(TOOLS_DIR)/scripts/viv_generate_bd.tcl) -log $(1).log -nojournal || export VIV_ERR=$$?; \
        $(TOOLS_DIR)/scripts/shared-ip-loc-manage.sh --path=$(5)/$(1) release; \
	exit $$VIV_ERR
