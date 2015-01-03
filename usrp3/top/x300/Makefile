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
## build/usrp_<product>_fpga_<image_type>.syr:    Xilinx system report
## build/usrp_<product>_fpga_<image_type>.twr:    Xilinx timing report

# Debug Options
# Uncomment the following lines to build radio's with no DSP's
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

print_report = \
	echo "========================================================================"; \
	cat $(1)/x300.syr | grep "Device utilization summary:" -A 30; \
	echo "========================================================================"; \
	echo "Timing Summary:\n"; \
	cat $(1)/x300.twr | grep constraint | grep met | grep -v "*"; \
	echo "========================================================================";

# pre_build($1=Device, $2=Flavor)
ifeq ($(EXPORT_ONLY),1)
	pre_build = @test -s build-$(1)_$(2)/x300.bit || { echo "EXPORT_ONLY requires the project in build-$(1)_$(2) to be fully built."; false; }
else
	pre_build = @echo "ISE Version: $(shell xtclsh -h | head -n1)"
endif

# ise_build($1=Device, $2=Definitions)
ifeq ($(PROJECT_ONLY),1)
	ise_build = make -f Makefile.x300.inc proj NAME=$@ DEVICE=$1 $2 EXTRA_DEFS="$2"
else ifeq ($(EXPORT_ONLY),1)
	ise_build = @echo "Skipping ISE build and exporting pre-built files.";
else
	ise_build = make -f Makefile.x300.inc bin NAME=$@ DEVICE=$1 $2 EXTRA_DEFS="$2"
endif

# post_build($1=Device, $2=Flavor)
ifeq ($(PROJECT_ONLY),1)
	post_build = \
		@echo "Generated $(shell pwd)/build-$(1)_$(2)/x300.xise"; \
		echo "\nProject Generation DONE ... $(1)_$(2)\n";
else
	post_build = \
		@$(call print_report,build-$(1)_$(2)) \
		mkdir -p build; \
		echo "Exporting bitstream files..."; \
		cp build-$(1)_$(2)/x300.bin build/usrp_`echo $(1) | tr A-Z a-z`_fpga_$(2).bin; \
		cp build-$(1)_$(2)/x300.bit build/usrp_`echo $(1) | tr A-Z a-z`_fpga_$(2).bit; \
		echo "Generating LVBITX..."; \
		$(CREATE_LVBITX) --input-bin=build-$(1)_$(2)/x300.bin --output-lvbitx=build/usrp_`echo $(1) | tr A-Z a-z`_fpga_$(2).lvbitx --device="USRP $(1)" x3x0_base.lvbitx; \
		cp -f x3x0_base.lvbitx build/`echo $(1) | tr A-Z a-z`.lvbitx_base; \
		echo "Exporting logs..."; \
		cp build-$(1)_$(2)/x300.syr build/usrp_`echo $(1) | tr A-Z a-z`_fpga_$(2).syr; \
		cp build-$(1)_$(2)/x300.twr build/usrp_`echo $(1) | tr A-Z a-z`_fpga_$(2).twr; \
		echo "\nBuild DONE ... $(1)_$(2)\n";
endif

##
##Supported Targets
##-----------------

all:      X300_HGS X310_HGS ##(Default target)

X310_1G:  ##USRP X310. 1GigE on both SFP+ ports. DRAM TX FIFO (experimental!).
	$(call pre_build,X310,1G)
	$(call ise_build,XC7K410T,$(GIGE_DEFS))
	$(call post_build,X310,1G)

X300_1G:  ##USRP X300. 1GigE on both SFP+ ports. DRAM TX FIFO (experimental!).
	$(call pre_build,X300,1G)
	$(call ise_build,XC7K325T,$(GIGE_DEFS))
	$(call post_build,X300,1G)

X310_HG:  ##USRP X310. 1GigE on SFP+ Port0, 10Gig on SFP+ Port1. DRAM TX FIFO (experimental!).
	$(call pre_build,X310,HG)
	$(call ise_build,XC7K410T,$(HYBRID_DEFS))
	$(call post_build,X310,HG)

X300_HG:  ##USRP X300. 1GigE on SFP+ Port0, 10Gig on SFP+ Port1. DRAM TX FIFO (experimental!).
	$(call pre_build,X300,HG)
	$(call ise_build,XC7K325T,$(HYBRID_DEFS))
	$(call post_build,X300,HG)

X310_XG:  ##USRP X310. 10GigE on both SFP+ ports. DRAM TX FIFO (experimental!).
	$(call pre_build,X310,XG)
	$(call ise_build,XC7K410T,$(XGIGE_DEFS))
	$(call post_build,X310,XG)

X300_XG:  ##USRP X300. 10GigE on both SFP+ ports. DRAM TX FIFO (experimental!).
	$(call pre_build,X300,XG)
	$(call ise_build,XC7K325T,$(XGIGE_DEFS))
	$(call post_build,X300,XG)

X310_HGS: ##USRP X310. 1GigE on SFP+ Port0, 10Gig on SFP+ Port1. SRAM TX FIFO.
	$(call pre_build,X310,HGS)
	$(call ise_build,XC7K410T,$(HYBRID_SRAM_DEFS))
	$(call post_build,X310,HGS)

X300_HGS: ##USRP X300. 1GigE on SFP+ Port0, 10Gig on SFP+ Port1. SRAM TX FIFO.
	$(call pre_build,X300,HGS)
	$(call ise_build,XC7K325T,$(HYBRID_SRAM_DEFS))
	$(call post_build,X300,HGS)

X310_XGS: ##USRP X310. 10GigE on both SFP+ ports. SRAM TX FIFO.
	$(call pre_build,X310,XGS)
	$(call ise_build,XC7K410T,$(XGIGE_SRAM_DEFS))
	$(call post_build,X310,XGS)

X300_XGS: ##USRP X300. 10GigE on both SFP+ ports. SRAM TX FIFO.
	$(call pre_build,X300,XGS)
	$(call ise_build,XC7K325T,$(XGIGE_SRAM_DEFS))
	$(call post_build,X300,XGS)

clean:    ##Clean up all build output.
	rm -rf build-*_*
	rm -rf build

help:     ##Show this help message.
	@grep -h "##" Makefile | grep -v "\"##\"" | sed -e 's/\\$$//' | sed -e 's/##//'

##
##Supported Options
##-----------------
##PROJECT_ONLY=1   Only create a Xilinx project for the specified target(s). 
##                 Useful for use with the ISE GUI.
##EXPORT_ONLY=1    Export build targets from a GUI build to the build directory.
##                 Requires the project in build-*_* to be built.

.PHONY: all clean X300 X310 help
