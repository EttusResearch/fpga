#
# Copyright 2015 Ettus Research
#

include $(TOOLS_DIR)/make/viv_ip_builder.mak

IP_AXI4_FIFO_512X64_SRCS = $(IP_BUILD_DIR)/axi4_fifo_512x64/axi4_fifo_512x64.xci

IP_AXI4_FIFO_512X64_OUTS = $(addprefix $(IP_BUILD_DIR)/axi4_fifo_512x64/, \
axi4_fifo_512x64.xci.out \
synth/axi4_fifo_512x64.v \
)

$(IP_AXI4_FIFO_512X64_SRCS) $(IP_AXI4_FIFO_512X64_OUTS) : $(IP_DIR)/axi4_fifo_512x64/axi4_fifo_512x64.xci
	$(call BUILD_VIVADO_IP,axi4_fifo_512x64,$(ARCH),$(PART_ID),$(IP_DIR),$(IP_BUILD_DIR),0)

