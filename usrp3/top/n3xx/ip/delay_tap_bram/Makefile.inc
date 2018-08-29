#
# Copyright 2016 Ettus Research
#

include $(TOOLS_DIR)/make/viv_ip_builder.mak

IP_DELAY_TAP_BRAM_SRCS = $(IP_BUILD_DIR)/delay_tap_bram/delay_tap_bram.xci \
$(IP_BUILD_DIR)/delay_tap_bram/tap.coe


IP_DELAY_TAP_BRAM_OUTS = $(addprefix $(IP_BUILD_DIR)/delay_tap_bram/, \
delay_tap_bram.xci.out \
synth/delay_tap_bram.vhd \
) 

$(IP_DELAY_TAP_BRAM_SRCS) $(IP_DELAY_TAP_BRAM_OUTS) : $(IP_DIR)/delay_tap_bram/delay_tap_bram.xci
	$(call BUILD_VIVADO_IP,delay_tap_bram,$(ARCH),$(PART_ID),$(IP_DIR),$(IP_BUILD_DIR),0)
