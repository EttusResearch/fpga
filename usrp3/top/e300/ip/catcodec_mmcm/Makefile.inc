#
# Copyright 2015 Ettus Research
#

include $(TOOLS_DIR)/make/viv_ip_builder.mak

IP_CATCODEC_MMCM_SRCS = $(IP_BUILD_DIR)/catcodec_mmcm/catcodec_mmcm.xci

IP_CATCODEC_MMCM_OUTS = $(addprefix $(IP_BUILD_DIR)/catcodec_mmcm/, \
catcodec_mmcm.xci.out \
synth/catcodec_mmcm.v \
)

$(IP_CATCODEC_MMCM_SRCS) $(IP_CATCODEC_MMCM_OUTS) : $(IP_DIR)/catcodec_mmcm/catcodec_mmcm.xci
	$(call BUILD_VIVADO_IP,catcodec_mmcm,$(ARCH),$(PART_ID),$(IP_DIR),$(IP_BUILD_DIR),0)

