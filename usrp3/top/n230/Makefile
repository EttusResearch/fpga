#
# Copyright 2014-2016 Ettus Research LLC
#

# NOTE: All comments prefixed with a "##" will be displayed as a part of the "make help" target 
##-------------------
##USRP N230 FPGA Help
##-------------------
##Usage:
## make <Targets> <Options>
##
##Output:
## build/usrp_n230_fpga_<image_type>.bit:    Configuration bitstream with header
## build/usrp_n230_fpga_<image_type>.bin:    Configuration bitstream without header
## build/usrp_n230_fpga_<image_type>.rpt:    Build report (includes utilization and timing summary)

# vivado_build($1=Device, $2=Definitions)
vivado_build = make -f Makefile.n230.inc bin NAME=$@ ARCH=$(XIL_ARCH_N230) PART_ID=$(XIL_PART_ID_N230) $1

post_build = @\
	mkdir -p build; \
	echo "Exporting bitstream files..."; \
	cp -f build-N230$(1)/n230.bin build/usrp_n230_fpga`echo $(1) | tr A-Z a-z`.bin; \
	cp -f build-N230$(1)/n230.bit build/usrp_n230_fpga`echo $(1) | tr A-Z a-z`.bit; \
	echo "Exporting build report..."; \
	cp -f build-N230$(1)/build.rpt build/usrp_n230_fpga`echo $(1) | tr A-Z a-z`.rpt; \
	echo "Build DONE ... N230$(1)";

##
##Supported Targets
##-----------------

all:      N230 ##(Default target)

N230:  ##USRP N230 default production image
	$(call vivado_build,SAFE_MODE=0)
	$(call post_build,)

N230_SAFE:  ##USRP N230 failsafe image
	$(call vivado_build,SAFE_MODE=1)
	$(call post_build,_SAFE)

clean:    ##Clean up all target build outputs.
	@echo "Cleaning targets..."
	@rm -rf build-N230*
	@rm -rf build

cleanall: ##Clean up all target and ip build outputs.
	@echo "Cleaning targets and IP..."
	@rm -rf build-ip
	@rm -rf build-N230*
	@rm -rf build

help:     ##Show this help message.
	@grep -h "##" Makefile | grep -v "\"##\"" | sed -e 's/\\$$//' | sed -e 's/##//'

##
##Supported Options
##-----------------
##GUI=1     Launch the build in the Vivado GUI. 

.PHONY: all clean cleanall help N230 N230_SAFE
