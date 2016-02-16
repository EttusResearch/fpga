#
# Copyright 2014-2016 Ettus Research LLC
#

include $(TOOLS_DIR)/make/viv_ip_builder.mak

IP_GIGE_PHY_SRCS = $(IP_BUILD_DIR)/gige_phy/gige_phy.xci

IP_GIGE_PHY_EXAMPLE_SRCS = $(addprefix $(IP_BUILD_DIR)/gige_phy_example/gige_phy_example.srcs/sources_1/imports/example_design/, \
support/gige_phy_clocking.v \
support/gige_phy_gt_common.v \
support/gige_phy_resets.v \
support/gige_phy_support.v \
support/gige_phy_common_reset.v \
) 

$(IP_GIGE_PHY_SRCS) $(IP_GIGE_PHY_OUTS) $(IP_GIGE_PHY_EXAMPLE_SRCS) : $(IP_DIR)/gige_phy/gige_phy.xci
	$(call BUILD_VIVADO_IP,gige_phy,$(ARCH),$(PART_ID),$(IP_DIR),$(IP_BUILD_DIR),1)
