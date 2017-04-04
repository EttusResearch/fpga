#
# Copyright 2014 Ettus Research
#

include $(TOOLS_DIR)/make/viv_ip_builder.mak

IP_CLK_GEN_SRCS = $(IP_BUILD_DIR)/clk_gen/clk_gen.xci

IP_CLK_GEN_OUTS = $(addprefix $(IP_BUILD_DIR)/clk_gen/, \
clk_gen.xci.out \
clk_gen.v \
)

# We have to patch the XDC file to remove constraints on the source clock for the module
# All timing constraints are handled in one place (timing.xdc)
$(IP_CLK_GEN_SRCS) $(IP_CLK_GEN_OUTS) : $(IP_DIR)/clk_gen/clk_gen.xci
	$(call BUILD_VIVADO_IP,clk_gen,$(ARCH),$(PART_ID),$(IP_DIR),$(IP_BUILD_DIR),0)

