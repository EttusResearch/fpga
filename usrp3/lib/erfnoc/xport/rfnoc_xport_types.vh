//
// Copyright 2019 Ettus Research, A National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//

// Add all new transport types here
// NOTE: NODE_TYPE_XPORT_BASE is defined in rfnoc_chdr_internal_utils.vh

localparam [7:0] NODE_TYPE_XPORT_GENERIC     = NODE_TYPE_XPORT_BASE + 8'd0;
localparam [7:0] NODE_TYPE_XPORT_IPV4_CHDR64 = NODE_TYPE_XPORT_BASE + 8'd1;
