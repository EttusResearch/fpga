#
# Copyright 2018 Ettus Research, a National Instruments Company
#

.PHONY: all clean

SRCS=TopCpld.qpf TopCpld.qsf Timing.sdc PkgMgCpld.vhd PkgSetup.vhd TopCpld.vhd

output_files/TopCpld.svf: $(SRCS)
	quartus_map TopCpld
	quartus_fit TopCpld
	quartus_asm TopCpld
	quartus_sta TopCpld

all: output_files/TopCpld.svf

clean:
	rm -rf db incremental_db output_files simulation

