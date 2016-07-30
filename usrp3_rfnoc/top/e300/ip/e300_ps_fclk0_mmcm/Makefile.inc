#
# Copyright 2015 Ettus Research
#

include $(TOOLS_DIR)/make/viv_ip_builder.mak

IP_E300_PS_FCLK0_MMCM_SRCS = $(IP_BUILD_DIR)/e300_ps_fclk0_mmcm/e300_ps_fclk0_mmcm.xci

IP_E300_PS_FCLK0_MMCM_OUTS = $(addprefix $(IP_BUILD_DIR)/e300_ps_fclk0_mmcm/, \
e300_ps_fclk0_mmcm.xci.out \
synth/e300_ps_fclk0_mmcm.v \
)

$(IP_E300_PS_FCLK0_MMCM_SRCS) $(IP_E300_PS_FCLK0_MMCM_OUTS) : $(IP_DIR)/e300_ps_fclk0_mmcm/e300_ps_fclk0_mmcm.xci
	$(call BUILD_VIVADO_IP,e300_ps_fclk0_mmcm,$(ARCH),$(PART_ID),$(IP_DIR),$(IP_BUILD_DIR),0)

