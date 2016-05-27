#
# Copyright 2012-2016 Ettus Research LLC
#

# NOTE: All comments prefixed with a "##" will be displayed as a part of the "make help" target 
##-------------------
##USRP X3X0 FPGA Help
##-------------------
##Usage:
## make <Targets> <Options>
##
##Output:
## build/usrp_<product>_fpga_<image_type>.bit:    Configuration bitstream with header
## build/usrp_<product>_fpga_<image_type>.bin:    Configuration bitstream without header
## build/usrp_<product>_fpga_<image_type>.lvbitx: Configuration bitstream for PCIe (NI-RIO)
## build/usrp_<product>_fpga_<image_type>.rpt:    Build report (includes utilization and timing summary)

# Debug Options
# Uncomment the following line to add a debug UART on GPIO 10 & 11
#OPTIONS += DEBUG_UART=1

CREATE_LVBITX=python ../../lib/io_port2/create-lvbitx.py

GIGE_DEFS=BUILD_1G=1 $(OPTIONS)
HYBRID_DEFS=ETH10G_PORT1=1 BUILD_1G=1 BUILD_10G=1 $(OPTIONS)
XGIGE_DEFS=ETH10G_PORT0=1 ETH10G_PORT1=1 BUILD_10G=1 $(OPTIONS)

# vivado_build($1=Target, $2=Device, $3=Definitions)
vivado_build = make -f Makefile.x300.inc $1 NAME=$@ ARCH=$(XIL_ARCH_$2) PART_ID=$(XIL_PART_ID_$2) $3 VERILOG_DEFS="$3"

# vivado_build($1=Device, $2=Option)
post_build = @\
	mkdir -p build; \
	echo "Exporting bitstream files..."; \
	cp build-$(1)_$(2)/x300.bin build/usrp_`echo $(1) | tr A-Z a-z`_fpga_$(2).bin; \
	cp build-$(1)_$(2)/x300.bit build/usrp_`echo $(1) | tr A-Z a-z`_fpga_$(2).bit; \
	echo "Generating LVBITX..."; \
	$(CREATE_LVBITX) --input-bin=build-$(1)_$(2)/x300.bin --output-lvbitx=build/usrp_`echo $(1) | tr A-Z a-z`_fpga_$(2).lvbitx --device="USRP $(1)" x3x0_base.lvbitx; \
	cp -f x3x0_base.lvbitx build/`echo $(1) | tr A-Z a-z`.lvbitx_base; \
	echo "Exporting build report..."; \
	cp build-$(1)_$(2)/build.rpt build/usrp_`echo $(1) | tr A-Z a-z`_fpga_$(2).rpt; \
	echo "Build DONE ... $(1)_$(2)";

##
##Supported Targets
##-----------------

all:      X300_HG X310_HG ##(Default target)

X310_1G:  ##USRP X310. 1GigE on both SFP+ ports. DRAM TX FIFO. (experimental!)
	$(call vivado_build,bin,X310,$(GIGE_DEFS))
	$(call post_build,X310,1G)

X300_1G:  ##USRP X300. 1GigE on both SFP+ ports. DRAM TX FIFO. (experimental!)
	$(call vivado_build,bin,X300,$(GIGE_DEFS))
	$(call post_build,X300,1G)

X310_HG:  ##USRP X310. 1GigE on SFP+ Port0, 10Gig on SFP+ Port1. DRAM TX FIFO.
	$(call vivado_build,bin,X310,$(HYBRID_DEFS))
	$(call post_build,X310,HG)

X300_HG:  ##USRP X300. 1GigE on SFP+ Port0, 10Gig on SFP+ Port1. DRAM TX FIFO.
	$(call vivado_build,bin,X300,$(HYBRID_DEFS))
	$(call post_build,X300,HG)

X310_XG:  ##USRP X310. 10GigE on both SFP+ ports. DRAM TX FIFO.
	$(call vivado_build,bin,X310,$(XGIGE_DEFS))
	$(call post_build,X310,XG)

X300_XG:  ##USRP X300. 10GigE on both SFP+ ports. DRAM TX FIFO.
	$(call vivado_build,bin,X300,$(XGIGE_DEFS))
	$(call post_build,X300,XG)

X310_RFNOC_HG: ##USRP X310. 1GigE on SFP+ Port0, 10Gig on SFP+ Port1. DRAM TX FIFO. RFNoC enabled.
	$(call vivado_build,bin,X310,$(HYBRID_DEFS) RFNOC=1 X310=1)
	$(call post_build,X310,RFNOC_HG)

X300_RFNOC_HG: ##USRP X300. 1GigE on SFP+ Port0, 10Gig on SFP+ Port1. DRAM TX FIFO. RFNoC enabled.
	$(call vivado_build,bin,X300,$(HYBRID_DEFS) RFNOC=1 X300=1)
	$(call post_build,X300,RFNOC_HG)

X310_RFNOC_XG: ##USRP X310. 10GigE on both SFP+ ports. DRAM TX FIFO. RFNoC enabled.
	$(call vivado_build,bin,X310,$(XGIGE_DEFS) RFNOC=1 X310=1)
	$(call post_build,X310,RFNOC_XG)

X300_RFNOC_XG: ##USRP X300. 10GigE on both SFP+ ports. DRAM TX FIFO. RFNoC enabled.
	$(call vivado_build,bin,X300,$(XGIGE_DEFS) RFNOC=1 X300=1)
	$(call post_build,X300,RFNOC_XG)

X310_RFNOC_HLS_HG: ##USRP X310. 1GigE on SFP+ Port0, 10Gig on SFP+ Port1. DRAM TX FIFO. RFNoC + Vivado HLS enabled.
	$(call vivado_build,hls,X310,$(HYBRID_DEFS) RFNOC=1 X310=1 HLS=1)
	$(call post_build,X310,RFNOC_HLS_HG)

X300_RFNOC_HLS_HG: ##USRP X300. 1GigE on SFP+ Port0, 10Gig on SFP+ Port1. DRAM TX FIFO. RFNoC + Vivado HLS enabled.
	$(call vivado_build,hls,X300,$(HYBRID_DEFS) RFNOC=1 X310=1 HLS=1)
	$(call post_build,X300,RFNOC_HLS_HG)

clean:    ##Clean up all target build outputs.
	@echo "Cleaning targets..."
	@rm -rf build-X3*_*
	@rm -rf build

cleanall: ##Clean up all target and ip build outputs.
	@echo "Cleaning targets and IP..."
	@rm -rf build-ip
	@rm -rf build-X3*_*
	@rm -rf build

help:     ##Show this help message.
	@grep -h "##" Makefile | grep -v "\"##\"" | sed -e 's/\\$$//' | sed -e 's/##//'

##
##Supported Options
##-----------------
##GUI=1     Launch the build in the Vivado GUI. 

.PHONY: all clean cleanall help
