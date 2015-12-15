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
## build/usrp_<product>_fpga_<image_type>.bit:    Configuration bitstream with header
## build/usrp_<product>_fpga_<image_type>.bin:    Configuration bitstream without header
## build/usrp_<product>_fpga_<image_type>.rpt:    Build report (includes utilization and timing summary)

# vivado_build($1=Device, $2=SG, $3=Definitions)
vivado_build = make -f Makefile.e300.inc bin NAME=$@ ARCH=zynq PART_ID=$1/clg484/-$2 EXTRA_DEFS="$3"

# post_build($1=Device, $2=TYPE, $3=SG)
post_build = @\
	mkdir -p build; \
	echo "Exporting bitstream files..."; \
	cp build-$(1)$(2)$(3)/e300.bin build/usrp_`echo $(1) | tr A-Z a-z`_fpga$(2)$(3).bin; \
	cp build-$(1)$(2)$(3)/e300.bit build/usrp_`echo $(1) | tr A-Z a-z`_fpga$(2)$(3).bit; \
	echo "Exporting build report..."; \
	cp build-$(1)$(2)$(3)/build.rpt build/usrp_`echo $(1) | tr A-Z a-z`_fpga$(2)$(3).rpt; \
	echo "Build DONE ... $(1)";

##
##Supported Targets
##-----------------
all: E3XX_idle E3XX_idle_sg3 E310 E310_sg3 ##(Default target)

E3XX_idle: ##Build USRP E3XX idle design.
	$(call vivado_build,xc7z020,1,E3XX_IDLE_IMAGE=1)
	$(call post_build,E3XX,_idle,)

E3XX_idle_sg3: ##Build USRP E3XX idle design.
	$(call vivado_build,xc7z020,3,E3XX_IDLE_IMAGE=1 E3XX_SG3)
	$(call post_build,E3XX,_idle_,sg3)

E310: ##Build USRP E310 design for SG1 device.
	$(call vivado_build,xc7z020,1,E310)
	$(call post_build,E310,,)

E310_sg3: ##Build USRP E310 design for SG3 device.
	$(call vivado_build,xc7z020,3,E310 E3XX_SG3)
	$(call post_build,E310,_,sg3)

E310_dram_test: ##Build USRP E310 design with DRAM test.
	$(call vivado_build,xc7z020,1,E310 DRAM_TEST)
	$(call post_build,E310,_dram_test,)

E310_dram_test_sg3: ##Build USRP E310 design with DRAM test.
	$(call vivado_build,xc7z020,3,E310 DRAM_TEST E3XX_SG3)
	$(call post_build,E310,_dram_test_,sg3)

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

.PHONY: all clean cleanall E310 E310_sg3 E3XX_idle E3XX_idle_SG3 help
