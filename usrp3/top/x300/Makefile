#
# Copyright 2012-2014 Ettus Research LLC
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
# Uncomment the following lines to build radio's with no DSP's (experimental!)
#OPTIONS += DELETE_DSP0=1
#OPTIONS += DELETE_DSP1=1
# Uncomment the following line to add a debug UART on GPIO 10 & 11
#OPTIONS += DEBUG_UART=1

CREATE_LVBITX=python ../../lib/io_port2/create-lvbitx.py

GIGE_DEFS=BUILD_1G=1 $(OPTIONS)
HYBRID_DEFS=ETH10G_PORT1=1 BUILD_1G=1 BUILD_10G=1 $(OPTIONS)
XGIGE_DEFS=ETH10G_PORT0=1 ETH10G_PORT1=1 BUILD_10G=1 $(OPTIONS)
HYBRID_SRAM_DEFS=ETH10G_PORT1=1 BUILD_1G=1 BUILD_10G=1 NO_DRAM_FIFOS=1 SRAM_FIFO_SIZE=16 $(OPTIONS)
XGIGE_SRAM_DEFS=ETH10G_PORT0=1 ETH10G_PORT1=1 BUILD_10G=1 NO_DRAM_FIFOS=1 SRAM_FIFO_SIZE=16 $(OPTIONS)

# vivado_build($1=Device, $2=Definitions)
vivado_build = make -f Makefile.x300.inc bin NAME=$@ PART_ID=$1/ffg900/-2 $2 EXTRA_DEFS="$2"

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

all:      X300_HGS X310_HGS ##(Default target)

X310_1G:  ##USRP X310. 1GigE on both SFP+ ports. DRAM TX FIFO (experimental!).
	$(call vivado_build,xc7k410t,$(GIGE_DEFS))
	$(call post_build,X310,1G)

X300_1G:  ##USRP X300. 1GigE on both SFP+ ports. DRAM TX FIFO (experimental!).
	$(call vivado_build,xc7k325t,$(GIGE_DEFS))
	$(call post_build,X300,1G)

X310_HG:  ##USRP X310. 1GigE on SFP+ Port0, 10Gig on SFP+ Port1. DRAM TX FIFO (experimental!).
	$(call vivado_build,xc7k410t,$(HYBRID_DEFS))
	$(call post_build,X310,HG)

X300_HG:  ##USRP X300. 1GigE on SFP+ Port0, 10Gig on SFP+ Port1. DRAM TX FIFO (experimental!).
	$(call vivado_build,xc7k325t,$(HYBRID_DEFS))
	$(call post_build,X300,HG)

X310_XG:  ##USRP X310. 10GigE on both SFP+ ports. DRAM TX FIFO (experimental!).
	$(call vivado_build,xc7k410t,$(XGIGE_DEFS))
	$(call post_build,X310,XG)

X300_XG:  ##USRP X300. 10GigE on both SFP+ ports. DRAM TX FIFO (experimental!).
	$(call vivado_build,xc7k325t,$(XGIGE_DEFS))
	$(call post_build,X300,XG)

X310_HGS: ##USRP X310. 1GigE on SFP+ Port0, 10Gig on SFP+ Port1. SRAM TX FIFO.
	$(call vivado_build,xc7k410t,$(HYBRID_SRAM_DEFS))
	$(call post_build,X310,HGS)

X300_HGS: ##USRP X300. 1GigE on SFP+ Port0, 10Gig on SFP+ Port1. SRAM TX FIFO.
	$(call vivado_build,xc7k325t,$(HYBRID_SRAM_DEFS))
	$(call post_build,X300,HGS)

X310_XGS: ##USRP X310. 10GigE on both SFP+ ports. SRAM TX FIFO.
	$(call vivado_build,xc7k410t,$(XGIGE_SRAM_DEFS))
	$(call post_build,X310,XGS)

X300_XGS: ##USRP X300. 10GigE on both SFP+ ports. SRAM TX FIFO.
	$(call vivado_build,xc7k325t,$(XGIGE_SRAM_DEFS))
	$(call post_build,X300,XGS)

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
