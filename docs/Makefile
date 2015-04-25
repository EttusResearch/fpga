#
# Copyright 2015 Ettus Research LLC
#

manual:
	sed 's/(docs\//(/' ../README.md > doxREADME.md
	doxygen Doxyfile.in

clean:
	@rm -rf html
	@rm -rf latex
	@rm -f doxREADME.md

.PHONY: manual clean
