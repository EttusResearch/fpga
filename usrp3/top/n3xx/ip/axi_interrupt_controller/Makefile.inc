#
# Copyright 2017 Ettus Research
#

include $(TOOLS_DIR)/make/viv_ip_builder.mak

IP_AXI_INTERRUPT_CONTROLLER_SRCS = $(IP_BUILD_DIR)/axi_interrupt_controller/axi_interrupt_controller.xci

IP_AXI_INTERRUPT_CONTROLLER_OUTS = $(addprefix $(IP_BUILD_DIR)/axi_interrupt_controller/, \
axi_interrupt_controller.xci.out \
) 

$(IP_AXI_INTERRUPT_CONTROLLER_SRCS) $(IP_AXI_INTERRUPT_CONTROLLER_OUTS) : $(IP_DIR)/axi_interrupt_controller/axi_interrupt_controller.xci
	$(call BUILD_VIVADO_IP,axi_interrupt_controller,$(ARCH),$(PART_ID),$(IP_DIR),$(IP_BUILD_DIR),0)
