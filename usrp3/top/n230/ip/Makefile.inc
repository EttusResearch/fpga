#
# Copyright 2014 Ettus Research
#

include $(IP_DIR)/axi64_8k_2clk_fifo/Makefile.inc
include $(IP_DIR)/bootram_8kx32/Makefile.inc
include $(IP_DIR)/bus_clk_gen/Makefile.inc
include $(IP_DIR)/fifo_4k_2clk/Makefile.inc
include $(IP_DIR)/fifo_short_2clk/Makefile.inc
include $(IP_DIR)/fifo_xlnx_32x36_2clk/Makefile.inc
include $(IP_DIR)/fifo_xlnx_512x36_2clk_prog_full/Makefile.inc
include $(IP_DIR)/gige_sfp0/Makefile.inc

IP_XCI_SRCS = \
$(IP_AXI64_8K_2CLK_FIFO_SRCS) \
$(IP_BOOTRAM_8KX32_SRCS) \
$(IP_BUS_CLK_GEN_SRCS) \
$(IP_FIFO_4K_2CLK_SRCS) \
$(IP_FIFO_SHORT_2CLK_SRCS) \
$(IP_FIFO_XLNX_32X36_2CLK_SRCS) \
$(IP_FIFO_XLNX_512X36_2CLK_PROG_FULL_SRCS) \
$(IP_GIGE_SFP0_SRCS) \
$(IP_GIGE_SFP0_EXAMPLE_SRCS)

IP_SYNTH_OUTPUTS = \
$(IP_AXI64_8K_2CLK_FIFO_OUTS) \
$(IP_BUS_CLK_GEN_OUTS) \
$(IP_BOOTRAM_8KX32_OUTS) \
$(IP_FIFO_4K_2CLK_OUTS) \
$(IP_FIFO_SHORT_2CLK_OUTS) \
$(IP_FIFO_XLNX_32X36_2CLK_OUTS) \
$(IP_FIFO_XLNX_512X36_2CLK_PROG_FULL_OUTS) \
$(IP_GIGE_SFP0_OUTS)

ip: $(IP_SYNTH_OUTPUTS)

.PHONY: ip



