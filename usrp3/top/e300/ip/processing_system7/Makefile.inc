#
# Copyright 2015 Ettus Research
#

include $(TOOLS_DIR)/make/viv_ip_builder.mak

IP_PROCESSING_SYSTEM7_SRCS = $(IP_BUILD_DIR)/processing_system7/processing_system7.xci

IP_PROCESSING_SYSTEM7_OUTS = $(addprefix $(IP_BUILD_DIR)/processing_system7/, \
synth/processing_system7.v \
)

$(IP_PROCESSING_SYSTEM7_SRCS) $(IP_PROCESSING_SYSTEM7_OUTS) : $(IP_DIR)/processing_system7/processing_system7.xci
	$(call BUILD_VIVADO_IP,processing_system7,$(PART_ID),$(IP_DIR),$(IP_BUILD_DIR),0)
