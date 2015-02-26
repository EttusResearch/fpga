#
# Copyright 2014 Ettus Research
#

# -------------------------------------------------------------------
# GUI Mode switch. Calling with GUI:=1 will launch Vivado GUI for build

ifeq ($(GUI),1)
VIVADO_MODE=gui
else
VIVADO_MODE=batch
endif
# -------------------------------------------------------------------

# -------------------------------------------------------------------
# Path variables

SIMLIB_DIR = $(BASE_DIR)/../sim
# -------------------------------------------------------------------

# Parse part name from ID
PART_NAME=$(subst /,,$(PART_ID))

.SECONDEXPANSION:

xsim:
	@ \
	export VIV_SIM_TOP=$(SIM_TOP); \
	export VIV_SIM_RUNTIME=$(SIM_RUNTIME_NS); \
	export VIV_PART_NAME=$(PART_NAME); \
	export VIV_MODE=$(VIVADO_MODE); \
	export VIV_DESIGN_SRCS="$(DESIGN_SRCS)"; \
	export VIV_SIM_SRCS="$(SIM_SRCS)"; \
	vivado -mode $(VIVADO_MODE) -source $(BASE_DIR)/../tools/scripts/viv_sim_project.tcl -log xsim.log -nojournal

xclean:
	@rm -f xsim*.log
	@rm -rf xsim_proj
	@rm -f xvhdl.log
	@rm -f xvhdl.pb
	@rm -f xvlog.log
	@rm -f xvlog.pb
	@rm -f vivado_pid*.str

# Use clean with :: to support allow "make clean" to work with multiple makefiles
clean:: xclean

.PHONY: sim clean