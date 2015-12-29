#
# Copyright 2015 Ettus Research
#

include $(TOOLS_DIR)/make/viv_ip_builder.mak

IP_AXI_DOWNSIZER_64TO32_SRCS = $(IP_BUILD_DIR)/axi_downsizer_64to32/axi_downsizer_64to32.xci

IP_AXI_DOWNSIZER_64TO32_OUTS = $(addprefix $(IP_BUILD_DIR)/axi_downsizer_64to32/, \
axi_downsizer_64to32.xci.out \
) 

$(IP_AXI_DOWNSIZER_64TO32_SRCS) $(IP_AXI_DOWNSIZER_64TO32_OUTS) : $(IP_DIR)/axi_downsizer_64to32/axi_downsizer_64to32.xci
	$(call BUILD_VIVADO_IP,axi_downsizer_64to32,$(ARCH),$(PART_ID),$(IP_DIR),$(IP_BUILD_DIR),0)
