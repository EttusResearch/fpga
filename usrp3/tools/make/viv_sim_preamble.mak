#
# Copyright 2015 Ettus Research
#

include $(BASE_DIR)/../tools/make/viv_preamble.mak
SIMULATION = 1

all:
	$(error "all" or "<empty>" is not a valid target. Run make help for a list of supported targets.)

ipclean:
	@rm -rf $(abspath ./build-ip)

cleanall: ipclean clean

help::
	@echo "-----------------"
	@echo "Supported Targets"
	@echo "-----------------"
	@echo "ipclean:    Cleanup all IP intermediate files"
	@echo "clean:      Cleanup all simulator intermediate files"
	@echo "cleanall:   Cleanup everything!"

.PHONY: ipclean cleanall help
