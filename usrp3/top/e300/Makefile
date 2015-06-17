#
# Copyright 2015 Ettus Research LLC
#

# NOTE: All comments prefixed with a "##" will be displayed as a part of the "make help" target 
##-------------------
##USRP E3X0 FPGA Help
##-------------------
##Usage:
## make <Targets> <Options>
##
##Output:
## build/usrp_<product>_fpga.bit:    Configuration bitstream with header
## build/usrp_<product>_fpga.bin:    Configuration bitstream without header
## build/usrp_<product>_fpga.rpt:    Build report (includes utilization and timing summary)

# vivado_build($1=Target, $2=Device, $2=Definitions)
vivado_build = make -f Makefile.e300.inc $1 NAME=$@ ARCH=zynq PART_ID=$2/clg484/-1 $3 EXTRA_DEFS="$3"

post_build = @\
	mkdir -p build; \
	echo "Exporting bitstream files..."; \
	cp build-$(1)/e300.bin build/usrp_`echo $(1) | tr A-Z a-z`_fpga.bin; \
	cp build-$(1)/e300.bit build/usrp_`echo $(1) | tr A-Z a-z`_fpga.bit; \
	echo "Exporting build report..."; \
	cp build-$(1)/build.rpt build/usrp_`echo $(1) | tr A-Z a-z`_fpga.rpt; \
	echo "Build DONE ... $(1)";

##
##Supported Targets
##-----------------

all: E310 E310_idle ##(Default target)

E310: ##Build USRP E310 design.
	$(call vivado_build,bin,xc7z020,)
	$(call post_build,E310)

E310_idle: ##Build USRP E310 idle design.
	$(call vivado_build,bin,xc7z020,E3X0_IDLE_IMAGE)
	$(call post_build,E310_idle)

E310_RFNOC: ##Build USRP E310 with RFNoC enabled.
	$(call vivado_build,bin,xc7z020,RFNOC=1 E310=1)
	$(call post_build,E310_RFNOC)

E310_RFNOC_HLS: ##Build USRP E310 with RFNoC + Vivado HLS enabled.
	$(call vivado_build,hls,xc7z020,RFNOC=1 E310=1 HLS=1)
	$(call post_build,E310_RFNOC_HLS)

clean: ##Clean up all itarget build outputs.
	@echo "Cleaning targets..."
	@rm -rf build-E3*
	@rm -rf build

cleanall: ##Clean up all target and ip build outputs.
	@echo "Cleaning targets and IP..."
	@rm -rf build-ip
	@rm -rf build-E3*
	@rm -rf build

help: ## Show this help message.
	@grep -h "##" Makefile | grep -v "\"##\"" | sed -e 's/\\$$//' | sed -e 's/##//'

##
##Supported Options
##-----------------
##GUI=1     Launch the build in the Vivado GUI. 

.PHONY: all clean cleanall E310 E310_idle help
