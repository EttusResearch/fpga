#
# Copyright 2015 Ettus Research
#

include $(TOOLS_DIR)/make/viv_ip_builder.mak

IP_AXI_DATAMOVER_SRCS = $(IP_BUILD_DIR)/axi_datamover/axi_datamover.xci

IP_AXI_DATAMOVER_OUTS = $(addprefix $(IP_BUILD_DIR)/axi_datamover/, \
axi_datamover.xci.out \
synth/axi_datamover.v \
)

$(IP_AXI_DATAMOVER_SRCS) $(IP_AXI_DATAMOVER_OUTS) : $(IP_DIR)/axi_datamover/axi_datamover.xci
	$(call BUILD_VIVADO_IP,axi_datamover,$(ARCH),$(PART_ID),$(IP_DIR),$(IP_BUILD_DIR),0)

