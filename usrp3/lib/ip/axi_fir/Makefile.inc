#
# Copyright 2015 Ettus Research
#

include $(TOOLS_DIR)/make/viv_ip_builder.mak

LIB_IP_AXI_FIR_SRCS = $(IP_BUILD_DIR)/axi_fir/axi_fir.xci

LIB_IP_AXI_FIR_OUTS = $(addprefix $(IP_BUILD_DIR)/axi_fir/, \
axi_fir.xci.out \
synth/axi_fir.vhd \
) 

$(LIB_IP_AXI_FIR_SRCS) $(LIB_IP_AXI_FIR_OUTS) : $(LIB_IP_DIR)/axi_fir/axi_fir.xci
	$(call BUILD_VIVADO_IP,axi_fir,$(ARCH),$(PART_ID),$(LIB_IP_DIR),$(IP_BUILD_DIR),0)
