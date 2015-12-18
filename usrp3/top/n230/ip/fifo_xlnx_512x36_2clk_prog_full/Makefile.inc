#
# Copyright 2014 Ettus Research
#

include $(TOOLS_DIR)/make/viv_ip_builder.mak

IP_FIFO_XLNX_512X36_2CLK_PROG_FULL_SRCS = $(IP_BUILD_DIR)/fifo_xlnx_512x36_2clk_prog_full/fifo_xlnx_512x36_2clk_prog_full.xci

IP_FIFO_XLNX_512X36_2CLK_PROG_FULL_OUTS = $(addprefix $(IP_BUILD_DIR)/fifo_xlnx_512x36_2clk_prog_full/, \
fifo_xlnx_512x36_2clk_prog_full.xci.out \
synth/fifo_xlnx_512x36_2clk_prog_full.vhd \
)

$(IP_FIFO_XLNX_512X36_2CLK_PROG_FULL_SRCS) $(IP_FIFO_XLNX_512X36_2CLK_PROG_FULL_OUTS) : $(IP_DIR)/fifo_xlnx_512x36_2clk_prog_full/fifo_xlnx_512x36_2clk_prog_full.xci
	$(call BUILD_VIVADO_IP,fifo_xlnx_512x36_2clk_prog_full,$(ARCH),$(PART_ID),$(IP_DIR),$(IP_BUILD_DIR),0)
