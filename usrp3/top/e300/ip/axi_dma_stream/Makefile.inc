#
# Copyright 2015 Ettus Research
#

include $(TOOLS_DIR)/make/viv_ip_builder.mak

IP_AXI_DMA_STREAM_SRCS = $(IP_BUILD_DIR)/axi_dma_stream/axi_dma_stream.xci

IP_AXI_DMA_STREAM_OUTS = $(addprefix $(IP_BUILD_DIR)/axi_dma_stream/, \
axi_dma_stream.xci.out \
synth/axi_dma_stream.v \
)

$(IP_AXI_DMA_STREAM_SRCS) $(IP_AXI_DMA_STREAM_OUTS) : $(IP_DIR)/axi_dma_stream/axi_dma_stream.xci
	$(call BUILD_VIVADO_IP,axi_dma_stream,$(ARCH),$(PART_ID),$(IP_DIR),$(IP_BUILD_DIR),0)

