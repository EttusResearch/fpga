#
# Copyright 2015 Ettus Research
#

include $(IP_DIR)/axi3_to_axi4lite_protocol_converter/Makefile.inc
include $(IP_DIR)/axi4_to_axi3_protocol_converter/Makefile.inc
include $(IP_DIR)/axi4_fifo_512x64/Makefile.inc
include $(IP_DIR)/axi_dma_stream/Makefile.inc
include $(IP_DIR)/axi_interconnect/Makefile.inc
include $(IP_DIR)/catcodec_mmcm/Makefile.inc
include $(IP_DIR)/e300_ps_fclk0_mmcm/Makefile.inc
include $(IP_DIR)/fifo_4k_2clk/Makefile.inc
include $(IP_DIR)/fifo_short_2clk/Makefile.inc
include $(IP_DIR)/processing_system7_1/Makefile.inc
include $(IP_DIR)/processing_system7_3/Makefile.inc
include $(IP_DIR)/mig_7series_0/Makefile.inc

IP_XCI_SRCS = \
$(IP_AXI3_TO_AXI4LITE_PROTOCOL_CONVERTER_SRCS) \
$(IP_AXI4_FIFO_512X64_SRCS) \
$(IP_AXI4_TO_AXI3_PROTOCOL_CONVERTER_SRCS) \
$(IP_AXI_DMA_STREAM_SRCS) \
$(IP_AXI_INTERCONNECT_SRCS) \
$(IP_CATCODEC_MMCM_SRCS) \
$(IP_E300_PS_FCLK0_MMCM_SRCS) \
$(IP_FIFO_4K_2CLK_SRCS) \
$(IP_MIG_7SERIES_0_SRCS) \
$(IP_MIG_7SERIES_TG_SRCS) \
$(IP_FIFO_SHORT_2CLK_SRCS)

IP_PS7_1_SRCS = \
$(IP_PROCESSING_SYSTEM7_1_SRCS)

IP_PS7_3_SRCS = \
$(IP_PROCESSING_SYSTEM7_3_SRCS)

IP_SYNTH_OUTPUTS = \
$(IP_AXI3_TO_AXI4LITE_PROTOCOL_CONVERTER_OUTS) \
$(IP_AXI4_FIFO_512X64_OUTS) \
$(IP_AXI4_TO_AXI3_PROTOCOL_CONVERTER_OUTS) \
$(IP_AXI_DMA_STREAM_OUTS) \
$(IP_CATCODEC_MMCM_OUTS) \
$(IP_E300_PS_FCLK0_MMCM_OUTS) \
$(IP_PROCESSING_SYSTEM7_OUTS) \
$(IP_FIFO_4K_2CLK_OUTS) \
$(IP_MIG_7SERIES_0_OUTS) \
$(IP_FIFO_SHORT_2CLK_OUTS)

ip: $(IP_XCI_SRCS)

.PHONY: ip
