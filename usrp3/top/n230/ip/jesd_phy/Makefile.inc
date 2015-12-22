#
# Copyright 2015 Ettus Research
#

include $(TOOLS_DIR)/make/viv_ip_builder.mak

IP_JESD_PHY_SRCS = $(IP_BUILD_DIR)/jesd_phy/jesd_phy.xci

IP_JESD_PHY_OUTS = $(addprefix $(IP_BUILD_DIR)/jesd_phy/, \
jesd_phy.xci.out \
) 

$(IP_JESD_PHY_SRCS) $(IP_JESD_PHY_OUTS) : $(IP_DIR)/jesd_phy/jesd_phy.xci
	$(call BUILD_VIVADO_IP,jesd_phy,$(ARCH),$(PART_ID),$(IP_DIR),$(IP_BUILD_DIR),1)
