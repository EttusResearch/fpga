#
# Copyright 2014 Ettus Research
#

include $(TOOLS_DIR)/make/viv_ip_builder.mak

IP_AXI4_BRAM_1KX64_SRCS = $(IP_BUILD_DIR)/axi4_bram_1kx64/axi4_bram_1kx64.xci

IP_AXI4_BRAM_1KX64_OUTS = $(addprefix $(IP_BUILD_DIR)/axi4_bram_1kx64/, \
axi4_bram_1kx64.xci.out \
synth/axi4_bram_1kx64.vhd \
) 

$(IP_AXI4_BRAM_1KX64_SRCS) $(IP_AXI4_BRAM_1KX64_OUTS) : $(IP_DIR)/axi4_bram_1kx64/axi4_bram_1kx64.xci
	$(call BUILD_VIVADO_IP,axi4_bram_1kx64,$(PART_ID),$(IP_DIR),$(IP_BUILD_DIR),0)
