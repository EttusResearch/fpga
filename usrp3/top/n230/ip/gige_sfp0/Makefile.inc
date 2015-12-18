#
# Copyright 2014-2016 Ettus Research LLC
#

include $(TOOLS_DIR)/make/viv_ip_builder.mak

IP_GIGE_SFP0_SRCS = $(IP_BUILD_DIR)/gige_sfp0/gige_sfp0.xci

IP_GIGE_SFP0_EXAMPLE_SRCS = $(addprefix $(IP_DIR)/gige_sfp0/, \
gige_sfp0_clocking.v \
gige_sfp0_gt_common.v \
gige_sfp0_resets.v \
gige_sfp0_support.v \
gige_sfp0_common_reset.v \
) 

$(IP_GIGE_SFP0_SRCS) $(IP_GIGE_SFP0_OUTS) : $(IP_DIR)/gige_sfp0/gige_sfp0.xci
	$(call BUILD_VIVADO_IP,gige_sfp0,$(ARCH),$(PART_ID),$(IP_DIR),$(IP_BUILD_DIR),1)
