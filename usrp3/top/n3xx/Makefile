#
# Copyright 2016-2017 Ettus Research LLC
#

# NOTE: All comments prefixed with a "##" will be displayed as a part of the "make help" target
##-------------------
##USRP N3XX FPGA Help
##-------------------
##Usage:
## make <Targets> <Options>
##
##Output:
## build/usrp_<product>_fpga_<image_type>.bit:    Configuration bitstream with header
## build/usrp_<product>_fpga_<image_type>.dts:    Device tree source file
## build/usrp_<product>_fpga_<image_type>.rpt:    Build report (includes utilization and timing summary)

# Debug Options
# Uncomment this line or add to make arg to omit radio_clk (sourced from db) and use bus_clk as radio_clk
# OPTIONS += NO_DB=1
# Uncomment this line to add two example Aurora loopback lanes on the general NPIO bus.
# OPTIONS += NPIO_LANES=2
# Uncomment this line to add four example Aurora loopback lanes on the QSFP NPIO bus.
# OPTIONS += QSFP_LANES=4

WX_DEFS=SFP0_WR=1     SFP1_10GBE=1  BUILD_WR=1     BUILD_10G=1    $(OPTIONS)
HG_DEFS=SFP0_1GBE=1   SFP1_10GBE=1  BUILD_1G=1     BUILD_10G=1    $(OPTIONS)
XG_DEFS=SFP0_10GBE=1  SFP1_10GBE=1  BUILD_10G=1                   $(OPTIONS)
HA_DEFS=SFP0_1GBE=1   SFP1_AURORA=1 BUILD_1G=1     BUILD_AURORA=1 $(OPTIONS)
XA_DEFS=SFP0_10GBE=1  SFP1_AURORA=1 BUILD_10G=1    BUILD_AURORA=1 $(OPTIONS)
AA_DEFS=SFP0_AURORA=1 SFP1_AURORA=1 BUILD_AURORA=1                $(OPTIONS)

# Option to stop after RTL elaboration. Use this flag as a synthesis check.
ifdef CHECK
TARGET = rtl
else
TARGET = bin
endif
TOP ?= n3xx

# Additional HLS options
ifdef HLS
HLS_DEFS = HLS=1
else
HLS_DEFS =
endif

# vivado_build($1=Device, $2=Definitions)
vivado_build = make -f Makefile.n3xx.inc $(TARGET) NAME=$@ ARCH=$(XIL_ARCH_$1) PART_ID=$(XIL_PART_ID_$1) $2 $(HLS_DEFS) TOP_MODULE=$(TOP) EXTRA_DEFS="$2 $(HLS_DEFS)"

# vivado_build($1=Device, $2=Option)
post_build = @\
	mkdir -p build; \
	echo "Exporting bitstream file..."; \
	cp build-$(1)_$(2)/n3xx.bit build/usrp_`echo $(1) | tr A-Z a-z`_fpga_$(2).bit; \
	echo "Exporting build report..."; \
	cp build-$(1)_$(2)/build.rpt build/usrp_`echo $(1) | tr A-Z a-z`_fpga_$(2).rpt; \
	echo "Build DONE ... $(1)_$(2)";

##
##Supported Targets
##-----------------

all:      N300_HG N300_XG N310_HG N310_XG ##(Default target)

##N310_WX:  1GigE White Rabbit on SFP+ Port0, 10Gig on SFP+ Port1.
N310_WX:  build/usrp_n310_fpga_WX.dts
	$(call vivado_build,N310,$(WX_DEFS) N310=1)
	$(call post_build,N310,WX)

##N310_HG:  1GigE on SFP+ Port0, 10Gig on SFP+ Port1.
N310_HG:  build/usrp_n310_fpga_HG.dts
	$(call vivado_build,N310,$(HG_DEFS) N310=1)
	$(call post_build,N310,HG)

##N310_XG:  10GigE on SFP+ Port0, 10Gig on SFP+ Port1.
N310_XG: build/usrp_n310_fpga_XG.dts
	$(call vivado_build,N310,$(XG_DEFS) N310=1)
	$(call post_build,N310,XG)

##N310_HA:  1Gig on SFP+ Port0, Aurora on SFP+ Port1.
N310_HA: build/usrp_n310_fpga_HA.dts
	$(call vivado_build,N310,$(HA_DEFS) N310=1)
	$(call post_build,N310,HA)

##N310_XA:  10Gig on SFP+ Port0, Aurora on SFP+ Port1.
N310_XA: build/usrp_n310_fpga_XA.dts
	$(call vivado_build,N310,$(XA_DEFS) N310=1)
	$(call post_build,N310,XA)

##N310_AA:  Aurora on SFP+ Port0, Aurora on SFP+ Port1.
N310_AA: build/usrp_n310_fpga_AA.dts
	$(call vivado_build,N310,$(AA_DEFS) N310=1)
	$(call post_build,N310,AA)

##N300_WX:  1GigE White Rabbit on SFP+ Port0, 10Gig on SFP+ Port1.
N300_WX:  build/usrp_n300_fpga_WX.dts
	$(call vivado_build,N300,$(WX_DEFS) N300=1)
	$(call post_build,N300,WX)

##N300_HG:  1GigE on SFP+ Port0, 10Gig on SFP+ Port1.
N300_HG:  build/usrp_n300_fpga_HG.dts
	$(call vivado_build,N300,$(HG_DEFS) N300=1)
	$(call post_build,N300,HG)

##N300_XG:  10GigE on SFP+ Port0, 10Gig on SFP+ Port1.
N300_XG: build/usrp_n300_fpga_XG.dts
	$(call vivado_build,N300,$(XG_DEFS) N300=1)
	$(call post_build,N300,XG)

##N300_HA:  1Gig on SFP+ Port0, Aurora on SFP+ Port1.
N300_HA: build/usrp_n300_fpga_HA.dts
	$(call vivado_build,N300,$(HA_DEFS) N300=1)
	$(call post_build,N300,HA)

##N300_XA:  10Gig on SFP+ Port0, Aurora on SFP+ Port1.
N300_XA: build/usrp_n300_fpga_XA.dts
	$(call vivado_build,N300,$(XA_DEFS) N300=1)
	$(call post_build,N300,XA)

##N300_AA:  Aurora on SFP+ Port0, Aurora on SFP+ Port1.
N300_AA: build/usrp_n300_fpga_AA.dts
	$(call vivado_build,N300,$(AA_DEFS) N300=1)
	$(call post_build,N300,AA)

build/%.dts: dts/%.dts dts/*.dtsi
	-mkdir -p build
	${CC} -o $@ -E -I dts -nostdinc -undef -x assembler-with-cpp -D__DTS__ $<

clean:    ##Clean up all target build outputs.
	@echo "Cleaning targets..."
	@rm -rf build-N3*_*
	@rm -rf build

cleanall: ##Clean up all target and ip build outputs.
	@echo "Cleaning targets and IP..."
	@rm -rf build-ip
	@rm -rf build-N3*_*
	@rm -rf build

help:     ##Show this help message.
	@grep -h "##" Makefile | grep -v "\"##\"" | sed -e 's/\\$$//' | sed -e 's/##//'

##
##Supported Options
##-----------------
##GUI=1        Launch the build in the Vivado GUI.
##CHECK=1      Launch the syntax checker instead of building a bitfile.
##TOP=<module> Specify a top module for syntax checking. (Optional. Default is the bitfile top)

.PHONY: all clean cleanall help
