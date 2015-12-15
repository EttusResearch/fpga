#
# Copyright 2015 Ettus Research
#

include $(TOOLS_DIR)/make/viv_ip_builder.mak

IP_PROCESSING_SYSTEM7_3_SRCS = $(IP_BUILD_DIR)/processing_system7_3/processing_system7_3.xci

IP_PROCESSING_SYSTEM7_3_OUTS = $(addprefix $(IP_BUILD_DIR)/processing_system7_3/, \
processing_system7_3.xci.out \
synth/processing_system7_3.v \
)

$(IP_PROCESSING_SYSTEM7_3_SRCS) $(IP_PROCESSING_SYSTEM7_3_OUTS) : $(IP_DIR)/processing_system7_3/processing_system7_3.xci
	$(call BUILD_VIVADO_IP,processing_system7_3,$(ARCH),$(PART_ID),$(IP_DIR),$(IP_BUILD_DIR),0)
