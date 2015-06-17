#
# Copyright 2015 Ettus Research
#

include $(HLS_IP_DIR)/addsub_hls/Makefile.inc

HLS_IP_OUTPUT_SRCS = \
$(HLS_IP_ADDSUB_HLS_OUTS)

HLS_IP_SRCS = \
$(HLS_IP_ADDSUB_HLS_SRCS)

HLS_IP_SYNTH_OUTPUTS = \
$(HLS_IP_ADDSUB_HLS_OUTS)

hls_ip: $(HLS_IP_SYNTH_OUTPUTS)

.PHONY: hls_ip
