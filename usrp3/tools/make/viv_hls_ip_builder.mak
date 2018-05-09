#
# Copyright 2015-2017 Ettus Research
#

# -------------------------------------------------------------------
# Usage: BUILD_VIVADO_HLS_IP
# Args: $1 = HLS_IP_NAME (High level synthsis IP name)
#       $2 = PART_ID (<device>/<package>/<speedgrade>)
#       $3 = HLS_IP_SRCS (Absolute paths to the HLS IP source files)
#       $4 = HLS_IP_SRC_DIR (Absolute path to the top level HLS IP src dir)
#       $5 = HLS_IP_BUILD_DIR (Absolute path to the top level HLS IP build dir)
# Prereqs:
# - TOOLS_DIR must be defined globally
# -------------------------------------------------------------------
BUILD_VIVADO_HLS_IP = \
	@ \
	echo "========================================================"; \
	echo "BUILDER: Building HLS IP $(1)"; \
	echo "========================================================"; \
	export HLS_IP_NAME=$(1); \
	export PART_NAME=$(subst /,,$(2)); \
	export HLS_IP_SRCS='$(3)'; \
	export HLS_IP_INCLUDES='$(6)'; \
	echo "BUILDER: Staging HLS IP in build directory..."; \
	$(TOOLS_DIR)/scripts/shared-ip-loc-manage.sh --path=$(5)/$(1) reserve; \
	cp -rf $(4)/$(1)/* $(5)/$(1); \
	cd $(5); \
	echo "BUILDER: Building HLS IP..."; \
	export VIV_ERR=0; \
	vivado_hls -f $(TOOLS_DIR)/scripts/viv_generate_hls_ip.tcl -l $(1).log || export VIV_ERR=$$?; \
	$(TOOLS_DIR)/scripts/shared-ip-loc-manage.sh --path=$(5)/$(1) release; \
	exit $$(($$VIV_ERR))

# -------------------------------------------------------------------
# Generates targets to build HLS IP and to add HLS output files to
# global variable HLS_IP_OUTPUT_SRCS
#
# Usage: $(eval $(HLS_IP_GEN_TARGETS))
# Args: $1 = HLS_IP_NAME (High level synthsis IP name)
#       $2 = PART_ID (<device>/<package>/<speedgrade>)
#       $3 = HLS_IP_SRCS (HLS IP source files relative to $4, HLS_IP_SRC_DIR)
#       $4 = HLS_IP_SRC_DIR (Absolute path to the top level HLS IP src dir)
#       $5 = HLS_IP_BUILD_DIR (Absolute path to the top level HLS IP build dir)
#       $6 = HLS_INCLUDE_DIR (Optional: Absolute path to HLS include directory)
# Prereqs:
# - HLS_IP_OUTPUT_SRCS and HLS_IP_BUILD_TARGETS must be defined globally
# -------------------------------------------------------------------
define HLS_IP_GEN_TARGETS
# Sources in lib directory
HLS_IP_$(1)_LIB_SRCS = $(addprefix $(4)/$(1)/, $(3))
# Output file for dependency tracking
HLS_IP_$(1)_OUTS = $(5)/$(1)/solution/impl/verilog/$(1).v
# Add this IP to global list of HLS IP to build
HLS_IP_BUILD_TARGETS += build_$(1)

# Since HLS output files can change between software versions, this target finds them and
# adds them to the list of output source files
build_$(1) : $$(HLS_IP_$(1)_OUTS)
	$$(eval HLS_IP_OUTPUT_SRCS += $$(shell find $(5)/$(1)/solution/impl/verilog/ -maxdepth 1 -name '*.v' -o -name '*dat'))
	$$(eval HLS_IP_OUTPUT_SRCS += $$(shell find $(5)/$(1)/solution/impl/verilog/project.srcs/sources_1/ip -name '*.xci' 2>/dev/null))

# Build with HLS
$$(HLS_IP_$(1)_OUTS) : $$(HLS_IP_$(1)_LIB_SRCS)
	$$(call BUILD_VIVADO_HLS_IP,$(1),$(2),$$(HLS_IP_$(1)_LIB_SRCS),$(4),$(5),$(6))

.PHONEY : build_$(1)
endef
