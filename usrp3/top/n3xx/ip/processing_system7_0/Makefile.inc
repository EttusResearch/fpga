#
# Copyright 2015 Ettus Research
#

include $(TOOLS_DIR)/make/viv_ip_builder.mak

IP_PROCESSING_SYSTEM7_0_SRCS = $(IP_BUILD_DIR)/processing_system7_0/processing_system7_0.xci

IP_PROCESSING_SYSTEM7_0_OUTS = $(addprefix $(IP_BUILD_DIR)/processing_system7_0/, \
processing_system7_0.xci.out \
synth/processing_system7_0.v \
)

$(IP_PROCESSING_SYSTEM7_0_SRCS) $(IP_PROCESSING_SYSTEM7_0_OUTS) : $(IP_DIR)/processing_system7_0/processing_system7_0.xci
	$(call BUILD_VIVADO_IP,processing_system7_0,$(ARCH),$(PART_ID),$(IP_DIR),$(IP_BUILD_DIR),0)
