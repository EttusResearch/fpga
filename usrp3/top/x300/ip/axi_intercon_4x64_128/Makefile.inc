#
# Copyright 2014 Ettus Research
#

include $(TOOLS_DIR)/make/viv_ip_builder.mak

IP_AXI_INTERCON_4X64_128_SRCS = $(IP_BUILD_DIR)/axi_intercon_4x64_128/axi_intercon_4x64_128.xci

IP_AXI_INTERCON_4X64_128_OUTS = $(addprefix $(IP_BUILD_DIR)/axi_intercon_4x64_128/, \
axi_intercon_4x64_128.xci.out \
synth/axi_intercon_4x64_128.v \
) 

$(IP_AXI_INTERCON_4X64_128_SRCS) $(IP_AXI_INTERCON_4X64_128_OUTS) : $(IP_DIR)/axi_intercon_4x64_128/axi_intercon_4x64_128.xci
	$(call BUILD_VIVADO_IP,axi_intercon_4x64_128,$(PART_ID),$(IP_DIR),$(IP_BUILD_DIR),0)
