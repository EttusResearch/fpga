#
# Copyright 2014 Ettus Research LLC
#

##################################################
# Dependencies
##################################################
include Makefile.sim.srcs
LIB_WORK = $(PWD)/work
MODELSIM_DEP = $(PWD)/vmap.log
VERILOG_DEP = $(PWD)/vlog.log
VHDL_DEP = $(PWD)/vcom.log

# Check if modelsim.ini path provided
ifdef MODELSIM_INI
MODELSIM_LOCAL_INI = $(MODELSIM_INI)
else
MODELSIM_LOCAL_INI = $(PWD)/modelsim.ini
endif

##################################################
# Targets
##################################################
.PHONY: all compile clean clean_ini

all: compile sim

compile: $(MODELSIM_DEP) $(VERILOG_DEP) $(VHDL_DEP)

sim:
	vsim $(VSIM_LIBS) $(VSIM_FLAGS) work.$(TOPLEVEL_MOD)

clean:
	rm -rf work
	rm -f transcript
	rm -f dpiheader.h
	rm -f vsim*
	rm -f $(MODELSIM_DEP)
	rm -f $(VERILOG_DEP)
	rm -f $(VHDL_DEP)

clean_ini:
	rm -f modelsim.ini

# Check if modelsim.ini exists and work directory.
$(MODELSIM_DEP): $(MODELSIM_LOCAL_INI) | $(LIB_WORK)

# Missing modelsim.ini, throw an error
$(MODELSIM_LOCAL_INI):
	$(error "Missing $(MODELSIM_LOCAL_INI)! Set MODELSIM_INI to path or copy file to local directory.")

# Create work library
$(LIB_WORK):
	vlib $@
	vmap -modelsimini $(MODELSIM_LOCAL_INI) work $@ | tee $(MODELSIM_DEP)

# Compile Verilog sources if they exist
$(VERILOG_DEP): $(VERILOG_SRCS)
ifdef VERILOG_SRCS
	vlog -l $(VERILOG_DEP) $(VLOG_FLAGS) +incdir+$(VERILOG_INC) $(VERILOG_SRCS)
endif

# Compile VHDL sources if they exist
$(VHDL_DEP): $(VHDL_SRCS)
ifdef VHDL_SRCS
	vcom -l $(VHDL_DEP) $(VCOM_FLAGS) $(VHDL_SRCS)
endif