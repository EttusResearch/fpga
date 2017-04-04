#
# Copyright 2014 Ettus Research
#

#include $(IP_DIR)/axi4_dualport_sram/Makefile.inc
include $(IP_DIR)/axi64_4k_2clk_fifo/Makefile.inc
include $(IP_DIR)/axi64_8k_2clk_fifo/Makefile.inc
include $(IP_DIR)/processing_system7_0/Makefile.inc
#include $(IP_DIR)/axi_intercon_2x64_128/Makefile.inc
#include $(IP_DIR)/axi_intercon_4x64_128/Makefile.inc
#include $(IP_DIR)/bus_clk_gen/Makefile.inc
#include $(IP_DIR)/ddr3_32bit/Makefile.inc
include $(IP_DIR)/fifo_4k_2clk/Makefile.inc
include $(IP_DIR)/fifo_short_2clk/Makefile.inc
#include $(IP_DIR)/input_sample_fifo/Makefile.inc
include $(IP_DIR)/one_gig_eth_pcs_pma/Makefile.inc
include $(IP_DIR)/radio_clk_gen/Makefile.inc
include $(IP_DIR)/clk_gen/Makefile.inc
include $(IP_DIR)/ten_gig_eth_pcs_pma/Makefile.inc
#include $(IP_DIR)/aurora_64b66b_pcs_pma/Makefile.inc
include $(IP_DIR)/axi3_to_axi4lite_protocol_converter/Makefile.inc
include $(IP_DIR)/axi_interconnect/Makefile.inc
include $(IP_DIR)/axis_fifo_to_axi4lite/Makefile.inc
include $(IP_DIR)/axi_interrupt_controller/Makefile.inc
include $(IP_DIR)/axi_eth_dma/Makefile.inc
include $(IP_DIR)/axi4_to_axi3_protocol_converter_32/Makefile.inc
include $(IP_DIR)/axi4_to_axi3_protocol_converter_64/Makefile.inc

BD_SRCS = \

IP_XCI_SRCS = \
$(IP_AXI4_BRAM_SRCS) \
$(IP_AXI64_4K_2CLK_FIFO_SRCS) \
$(IP_AXI64_8K_2CLK_FIFO_SRCS) \
$(IP_AXI3_TO_AXI4LITE_PROTOCOL_CONVERTER_SRCS) \
$(IP_AXI4_TO_AXI3_PROTOCOL_CONVERTER_32_SRCS) \
$(IP_AXI4_TO_AXI3_PROTOCOL_CONVERTER_64_SRCS) \
$(IP_AXI_INTERCONNECT_SRCS) \
$(IP_AXI_INTERRUPT_CONTROLLER_SRCS) \
$(IP_AXIS_FIFO_TO_AXI4LITE_SRCS) \
$(IP_BUS_CLK_GEN_SRCS) \
$(IP_FIFO_4K_2CLK_SRCS) \
$(IP_FIFO_SHORT_2CLK_SRCS) \
$(IP_RADIO_CLK_GEN_SRCS) \
$(IP_CLK_GEN_SRCS) \
$(IP_AXI_ETH_DMA_SRCS) \
$(IP_PROCESSING_SYSTEM7_0_SRCS)


IP_ONE_GIGE_PHY_XCI_SRCS = \
$(IP_ONE_GIG_ETH_PCS_PMA_SRCS) \

IP_TEN_GIGE_PHY_XCI_SRCS = \
$(IP_TEN_GIG_ETH_PCS_PMA_SRCS)

IP_AURORA_XCI_SRCS = \
$(IP_AURORA_64B66B_PCS_PMA_SRCS)

IP_DRAM_XCI_SRCS = \
$(IP_AXI_INTERCON_2X64_128_SRCS) \
$(IP_DDR3_32BIT_SRCS)

# Currently unused
# $(IP_INPUT_SAMPLE_FIFO_SRCS) \
# $(IP_AXI_INTERCON_4X64_128_SRCS) \

IP_CODEGEN_SRCS = \
$(ONE_GIGE_PHY_SRCS) \
$(TEN_GIGE_PHY_SRCS)

IP_SYNTH_OUTPUTS = \
$(IP_AXI4_BRAM_OUTS) \
$(IP_AXI64_4K_2CLK_FIFO_OUTS) \
$(IP_AXI64_8K_2CLK_FIFO_OUTS) \
$(IP_AXI3_TO_AXI4LITE_PROTOCOL_CONVERTER_OUTS) \
$(IP_AXI_INTERCONNECT_OUTS) \
$(IP_AXI_INTERRUPT_CONTROLLER_OUTS) \
$(IP_AXI4_TO_AXI3_PROTOCOL_CONVERTER_32_OUTS) \
$(IP_AXI4_TO_AXI3_PROTOCOL_CONVERTER_64_OUTS) \
$(IP_AXIS_FIFO_TO_AXI4LITE_OUTS) \
$(IP_AXI_INTERCON_2X64_128_OUTS) \
$(IP_BUS_CLK_GEN_OUTS) \
$(IP_FIFO_4K_2CLK_OUTS) \
$(IP_FIFO_SHORT_2CLK_OUTS) \
$(IP_ONE_GIG_ETH_PCS_PMA_OUTS) \
$(IP_PROCESSING_SYSTEM7_OUTS) \
$(IP_RADIO_CLK_GEN_OUTS) \
$(IP_CLK_GEN_OUTS) \
$(IP_AXI_ETH_DMA_OUTS) \
$(IP_TEN_GIG_ETH_PCS_PMA_OUTS) \
$(IP_AURORA_64B66B_PCS_PMA_OUTS)

BD_OUTPUTS= \

# Currently unused
# $(IP_INPUT_SAMPLE_FIFO_OUTS) \
# $(IP_AXI_INTERCON_4X64_128_OUTS) \

ip: $(IP_SYNTH_OUTPUTS) $(IP_CODEGEN_SRCS) $(BD_OUTPUTS)

.PHONY: ip

