#
# Copyright 2014 Ettus Research LLC
#

set_property LOC GTXE2_CHANNEL_X0Y0 [get_cells -hierarchical -filter {NAME =~ "*ten_gige_phy_port0/*gtxe2_i*" && PRIMITIVE_TYPE == IO.gt.GTXE2_CHANNEL}]
set_property LOC GTXE2_COMMON_X0Y0  [get_cells -hierarchical -filter {NAME =~ "*ten_gige_phy_port0/*gtxe2_common_0_i*" && PRIMITIVE_TYPE == IO.gt.GTXE2_COMMON}]
