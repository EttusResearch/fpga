#
# Copyright 2015 Ettus Research
#

include $(TOOLS_DIR)/make/viv_ip_builder.mak

IP_PROCESSING_SYSTEM7_1_SRCS = $(IP_BUILD_DIR)/processing_system7_1/processing_system7_1.xci

IP_PROCESSING_SYSTEM7_1_OUTS = $(addprefix $(IP_BUILD_DIR)/processing_system7_1/, \
processing_system7_1.xci.out \
synth/processing_system7_1.v \
)

$(IP_PROCESSING_SYSTEM7_1_SRCS) $(IP_PROCESSING_SYSTEM7_1_OUTS) : $(IP_DIR)/processing_system7_1/processing_system7_1.xci
	$(call BUILD_VIVADO_IP,processing_system7_1,$(ARCH),$(PART_ID),$(IP_DIR),$(IP_BUILD_DIR),0)
