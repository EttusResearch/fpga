#
# Copyright 2015 Ettus Research
#

include $(TOOLS_DIR)/make/viv_hls_ip_builder.mak

# Add C/C++/tcl files
HLS_IP_ADDSUB_HLS_SRCS = $(addprefix $(IP_BUILD_DIR)/addsub_hls/, \
addsub_hls.cpp \
addsub_hls.tcl \
)

# Add output files
HLS_IP_ADDSUB_HLS_OUTS := $(shell find $(IP_BUILD_DIR)/addsub_hls/solution/impl/verilog/ -name '*.v' -o -name '*.vhd' -o -name '*.xci')

$(HLS_IP_ADDSUB_HLS_SRCS) $(HLS_IP_ADDSUB_HLS_OUTS) : $(HLS_IP_DIR)/addsub_hls/addsub_hls.cpp $(HLS_IP_DIR)/addsub_hls/addsub_hls.tcl
	$(call BUILD_VIVADO_HLS_IP,addsub_hls,$(PART_ID),$(HLS_IP_ADDSUB_HLS_SRCS),$(HLS_IP_DIR),$(IP_BUILD_DIR))
