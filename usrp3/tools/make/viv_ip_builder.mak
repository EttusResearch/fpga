#
# Copyright 2014 Ettus Research
#

# -------------------------------------------------------------------
# Usage: BUILD_VIVADO_IP
# Args: $1 = IP_NAME (IP name)
#       $2 = PART_ID (<device>/<package>/<speedgrade>)
#       $3 = IP_SRC_DIR (Absolute path to the top level ip src dir)
#       $4 = IP_BUILD_DIR (Absolute path to the top level ip build dir)
#       $5 = GENERATE_EXAMPLE (0 or 1)
# Prereqs: 
# - TOOLS_DIR must be defined globally
# -------------------------------------------------------------------
BUILD_VIVADO_IP = \
	@ \
	echo "========================================================"; \
	echo " Building IP $(1)"; \
	echo "========================================================"; \
	export XCI_FILE=$(4)/$(1)/$(1).xci; \
	export PART_NAME=$(subst /,,$(2)); \
	export GEN_EXAMPLE=$(5); \
	echo "Staging IP in build directory..."; \
	mkdir -p $(4)/$(1); \
	cp -rf $(3)/$(1)/* $(4)/$(1); \
	echo "Retargeting IP to part $$PART_NAME..."; \
	python $(TOOLS_DIR)/scripts/viv_retarget_ip.py --output_dir=$(4)/$(1) --part=$(2) $(3)/$(1)/$(1).xci; \
	cd $(4); \
	echo "Building IP..."; \
	vivado -mode batch -source $(TOOLS_DIR)/scripts/viv_generate_ip.tcl -log $(1).log -nojournal
