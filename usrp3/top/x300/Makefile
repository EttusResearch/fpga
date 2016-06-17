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
# Uncomment the following line to add a debug UART on GPIO 10 & 11
#OPTIONS += DEBUG_UART=1

CREATE_LVBITX=python ../../lib/io_port2/create-lvbitx.py

GIGE_DEFS=BUILD_1G=1 SFP0_1GBE=1 SFP1_1GBE=1 $(OPTIONS)
HG_DEFS=BUILD_1G=1 BUILD_10G=1 SFP0_1GBE=1 SFP1_10GBE=1 $(OPTIONS)
XG_DEFS=BUILD_10G=1 SFP0_10GBE=1 SFP1_10GBE=1 $(OPTIONS)
HA_DEFS=BUILD_1G=1 BUILD_AURORA=1 SFP0_1GBE=1 SFP1_AURORA=1 $(OPTIONS)
XA_DEFS=BUILD_10G=1 BUILD_AURORA=1 SFP0_10GBE=1 SFP1_AURORA=1 $(OPTIONS)

# vivado_build($1=Device, $2=Definitions)
vivado_build = make -f Makefile.x300.inc bin NAME=$@ ARCH=$(XIL_ARCH_$1) PART_ID=$(XIL_PART_ID_$1) $2 VERILOG_DEFS="$2"

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
	$(call vivado_build,X310,$(GIGE_DEFS))
	$(call post_build,X310,1G)

X300_1G:  ##USRP X300. 1GigE on both SFP+ ports. DRAM TX FIFO (experimental!).
	$(call vivado_build,X300,$(GIGE_DEFS))
	$(call post_build,X300,1G)

X310_HG:  ##USRP X310. 1GigE on SFP+ Port0, 10Gig on SFP+ Port1. DRAM TX FIFO (experimental!).
	$(call vivado_build,X310,$(HG_DEFS))
	$(call post_build,X310,HG)

X300_HG:  ##USRP X300. 1GigE on SFP+ Port0, 10Gig on SFP+ Port1. DRAM TX FIFO (experimental!).
	$(call vivado_build,X300,$(HG_DEFS))
	$(call post_build,X300,HG)

X310_XG:  ##USRP X310. 10GigE on both SFP+ ports. DRAM TX FIFO (experimental!).
	$(call vivado_build,X310,$(XG_DEFS))
	$(call post_build,X310,XG)

X300_XG:  ##USRP X300. 10GigE on both SFP+ ports. DRAM TX FIFO (experimental!).
	$(call vivado_build,X300,$(XG_DEFS))
	$(call post_build,X300,XG)

X310_HA:  ##USRP X310. 1Gig on SFP+ Port0, Aurora on SFP+ Port1. DRAM TX FIFO (experimental!).
	$(call vivado_build,X310,$(HA_DEFS))
	$(call post_build,X310,HA)

X300_HA:  ##USRP X300. 1Gig on SFP+ Port0, Aurora on SFP+ Port1. DRAM TX FIFO (experimental!).
	$(call vivado_build,X300,$(HA_DEFS))
	$(call post_build,X300,HA)

X310_XA:  ##USRP X310. 10Gig on SFP+ Port0, Aurora on SFP+ Port1. DRAM TX FIFO (experimental!).
	$(call vivado_build,X310,$(XA_DEFS))
	$(call post_build,X310,XA)

X300_XA:  ##USRP X300. 10Gig on SFP+ Port0, Aurora on SFP+ Port1. DRAM TX FIFO (experimental!).
	$(call vivado_build,X300,$(XA_DEFS))
	$(call post_build,X300,XA)

X310_HGS: ##USRP X310. 1GigE on SFP+ Port0, 10Gig on SFP+ Port1. SRAM TX FIFO.
	$(call vivado_build,X310,$(HG_DEFS) NO_DRAM_FIFOS=1 SRAM_FIFO_SIZE=16)
	$(call post_build,X310,HGS)

X300_HGS: ##USRP X300. 1GigE on SFP+ Port0, 10Gig on SFP+ Port1. SRAM TX FIFO.
	$(call vivado_build,X300,$(HG_DEFS) NO_DRAM_FIFOS=1 SRAM_FIFO_SIZE=16)
	$(call post_build,X300,HGS)

X310_XGS: ##USRP X310. 10GigE on both SFP+ ports. SRAM TX FIFO.
	$(call vivado_build,X310,$(XG_DEFS) NO_DRAM_FIFOS=1 SRAM_FIFO_SIZE=16)
	$(call post_build,X310,XGS)

X300_XGS: ##USRP X300. 10GigE on both SFP+ ports. SRAM TX FIFO.
	$(call vivado_build,X300,$(XG_DEFS) NO_DRAM_FIFOS=1 SRAM_FIFO_SIZE=16)
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
