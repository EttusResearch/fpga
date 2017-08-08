#
# Copyright 2014 Ettus Research
#

include $(TOOLS_DIR)/make/viv_ip_builder.mak

IP_MEASCLK_MMCM_SRCS = $(IP_BUILD_DIR)/MeasClkMmcm/MeasClkMmcm.xci

IP_MEASCLK_MMCM_OUTS = $(addprefix $(IP_BUILD_DIR)/MeasClkMmcm/, \
MeasClkMmcm.xci.out \
MeasClkMmcm.v \
)

# We have to patch the XDC file to remove constraints on the source clock for the module
# All timing constraints are handled in one place (timing.xdc)
$(IP_MEASCLK_MMCM_SRCS) $(IP_MEASCLK_MMCM_OUTS) : $(IP_DIR)/MeasClkMmcm/MeasClkMmcm.xci
	$(call BUILD_VIVADO_IP,MeasClkMmcm,$(ARCH),$(PART_ID),$(IP_DIR),$(IP_BUILD_DIR),0)

