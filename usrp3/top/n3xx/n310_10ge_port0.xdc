#
# Copyright 2017 Ettus Research, A National Instruments Company
# SPDX-License-Identifier: GPL-3.0
#

set_property LOC GTXE2_CHANNEL_X0Y0 [get_cells -hierarchical -filter {NAME =~ "*network_interface_0/sfpp_io_i/ten_gige_phy_i/*gtxe2_i*" && PRIMITIVE_TYPE == IO.gt.GTXE2_CHANNEL}]
set_property LOC GTXE2_COMMON_X0Y0  [get_cells -hierarchical -filter {NAME =~ "*gtxe2_common_0_i*" && PRIMITIVE_TYPE == IO.gt.GTXE2_COMMON}]
