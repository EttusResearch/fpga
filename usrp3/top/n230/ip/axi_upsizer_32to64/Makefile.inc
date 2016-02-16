#
# Copyright 2015 Ettus Research
#

include $(TOOLS_DIR)/make/viv_ip_builder.mak

IP_AXI_UPSIZER_32TO64_SRCS = $(IP_BUILD_DIR)/axi_upsizer_32to64/axi_upsizer_32to64.xci

IP_AXI_UPSIZER_32TO64_OUTS = $(addprefix $(IP_BUILD_DIR)/axi_upsizer_32to64/, \
axi_upsizer_32to64.xci.out \
) 

$(IP_AXI_UPSIZER_32TO64_SRCS) $(IP_AXI_UPSIZER_32TO64_OUTS) : $(IP_DIR)/axi_upsizer_32to64/axi_upsizer_32to64.xci
	$(call BUILD_VIVADO_IP,axi_upsizer_32to64,$(ARCH),$(PART_ID),$(IP_DIR),$(IP_BUILD_DIR),0)
