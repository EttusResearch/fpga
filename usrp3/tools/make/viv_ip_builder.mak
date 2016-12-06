#
# Copyright 2014 Ettus Research
#

ifeq ($(SIMULATION),1)
SYNTH_IP=0
else
SYNTH_IP=1
endif

# -------------------------------------------------------------------
# Usage: BUILD_VIVADO_IP
# Args: $1 = IP_NAME (IP name)
#       $2 = ARCH (zynq, kintex7, etc)
#       $3 = PART_ID (<device>/<package>/<speedgrade>)
#       $4 = IP_SRC_DIR (Absolute path to the top level ip src dir)
#       $5 = IP_BUILD_DIR (Absolute path to the top level ip build dir)
#       $6 = GENERATE_EXAMPLE (0 or 1)
# Prereqs: 
# - TOOLS_DIR must be defined globally
# -------------------------------------------------------------------
BUILD_VIVADO_IP = \
	@ \
	echo "========================================================"; \
	echo "BUILDER: Building IP $(1)"; \
	echo "========================================================"; \
	export XCI_FILE=$(call RESOLVE_PATH,$(5)/$(1)/$(1).xci); \
	export PART_NAME=$(subst /,,$(3)); \
	export GEN_EXAMPLE=$(6); \
	export SYNTH_IP=$(SYNTH_IP); \
	echo "BUILDER: Staging IP in build directory..."; \
	$(TOOLS_DIR)/scripts/shared-ip-loc-manage.sh --path=$(5)/$(1) reserve; \
	cp -rf $(4)/$(1)/* $(5)/$(1); \
	echo "BUILDER: Retargeting IP to part $(2)/$(3)..."; \
	python $(TOOLS_DIR)/scripts/viv_ip_xci_editor.py --output_dir=$(5)/$(1) --target=$(2)/$(3) retarget $(4)/$(1)/$(1).xci; \
	cd $(5); \
	echo "BUILDER: Building IP..."; \
	export VIV_ERR=0; \
	$(TOOLS_DIR)/scripts/launch_vivado.sh -mode batch -source $(call RESOLVE_PATH,$(TOOLS_DIR)/scripts/viv_generate_ip.tcl) -log $(1).log -nojournal || export VIV_ERR=$$?; \
	$(TOOLS_DIR)/scripts/shared-ip-loc-manage.sh --path=$(5)/$(1) release; \
	exit $$VIV_ERR

# -------------------------------------------------------------------
# Usage: BUILD_VIVADO_BD
# Args: $1 = BD_NAME (IP name)
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
	echo "BUILDER: Staging BD in build directory..."; \
	rm $(5)/$(1)/* -rf; \
	$(TOOLS_DIR)/scripts/shared-ip-loc-manage.sh --path=$(5)/$(1) reserve; \
        cp -rf $(4)/$(1)/* $(5)/$(1); \
	echo "BUILDER: Retargeting BD to part $(2)/$(3)..."; \
	cd $(5)/$(1); \
	echo "BUILDER: Building BD..."; \
	export VIV_ERR=0; \
	$(TOOLS_DIR)/scripts/launch_vivado.sh -mode batch -source $(call RESOLVE_PATH,$(TOOLS_DIR)/scripts/viv_generate_bd.tcl) -log $(1).log -nojournal || export VIV_ERR=$$?; \
        $(TOOLS_DIR)/scripts/shared-ip-loc-manage.sh --path=$(5)/$(1) release; \
	exit $$VIV_ERR
