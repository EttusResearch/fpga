#
# Copyright 2015 Ettus Research
#

TOOLS_DIR = $(BASE_DIR)/../tools
IP_BUILD_DIR = $(abspath ./build-ip/$(subst /,,$(PART_ID)))

ipclean:
	@rm -rf $(IP_BUILD_DIR)

cleanall: ipclean clean

.PHONY: ipclean
