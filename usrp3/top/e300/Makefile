#
# Copyright 2014 Ettus Research LLC
#

all: e300

clean:
	@rm -rf build-e3*
	@rm -rf build

cleanall: clean
	@rm -rf vivado*.jou
	@rm -rf vivado*.log

# Todo: Make seperate images
e300: check_vivado_in_path
	@mkdir -p build-$@
	@mkdir -p build
	make -f Makefile.$@.inc bin NAME=$@ DEVICE=xc7z020clg484-1 2>&1|tee build-$@/build.log
	cp build-$@/$@.bit build/usrp_$@_fpga.bit
	cp build-$@/build.log build/usrp_$@_fpga.log

check_vivado_in_path: ; @vivado -version 2>&1 | grep Vivado

.PHONY: all clean cleanall check_vivado_in_path
