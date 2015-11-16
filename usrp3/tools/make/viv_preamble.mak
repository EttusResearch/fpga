#
# Copyright 2014 Ettus Research
#

# -------------------------------------------------------------------
# Project Setup
# -------------------------------------------------------------------
BASE_DIR = $(abspath ..)
IP_DIR = $(abspath ./ip)
TOOLS_DIR = $(BASE_DIR)/../tools
SIMULATION = 0

BUILD_DIR = $(abspath ./build-$(NAME))
IP_BUILD_DIR = $(abspath ./build-ip/$(subst /,,$(PART_ID)))

include $(TOOLS_DIR)/make/viv_design_builder.mak

# -------------------------------------------------------------------
# Toolchain dependency target
# -------------------------------------------------------------------
check_tool: ; @vivado -version 2>&1 | grep Vivado

# -------------------------------------------------------------------
# Intermediate build dirs 
# -------------------------------------------------------------------
build_dirs:
	@mkdir -p $(BUILD_DIR)
	@mkdir -p $(IP_BUILD_DIR)

prereqs: check_tool build_dirs

.PHONY: check_tool build_dirs prereqs

# -------------------------------------------------------------------
# Validate prerequisites
# -------------------------------------------------------------------
ifndef NAME
	$(error NAME was empty or not set)
endif
ifndef PART_ID
	$(error PART_ID was empty or not set)
endif