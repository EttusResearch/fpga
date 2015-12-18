#
# Copyright 2014 Ettus Research
#

include $(TOOLS_DIR)/make/viv_ip_builder.mak

IP_BOOTRAM_8KX32_SRCS = $(IP_BUILD_DIR)/bootram_8kx32/bootram_8kx32.xci

IP_BOOTRAM_8KX32_OUTS = $(addprefix $(IP_BUILD_DIR)/bootram_8kx32/, \
bootram_8kx32.xci.out \
synth/bootram_8kx32.vhd \
) 

$(IP_BOOTRAM_8KX32_SRCS) $(IP_BOOTRAM_8KX32_OUTS) : $(IP_DIR)/bootram_8kx32/bootram_8kx32.xci $(IP_DIR)/bootram_8kx32/bootram_8kx32.coe
	$(call BUILD_VIVADO_IP,bootram_8kx32,$(ARCH),$(PART_ID),$(IP_DIR),$(IP_BUILD_DIR),0)
