#
# Copyright 2015 Ettus Research
#

TOOLS_DIR = $(BASE_DIR)/../tools
IP_BUILD_DIR = $(abspath ./build-ip/$(subst /,,$(PART_ID)))
SIMULATION = 1

ipclean:
	@rm -rf $(abspath ./build-ip)

cleanall: ipclean clean

.PHONY: ipclean cleanall
