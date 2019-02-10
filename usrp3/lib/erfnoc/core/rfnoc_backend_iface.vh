//
// Copyright 2019 Ettus Research, A National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//

// Each block has a backed interface that is 512 bits wide. This bus
// is split into 16 32-bit registers to it is preferable to have fields
// aligned at 32-bit boundaries

// Backend Config
localparam BEC_FLUSH_TIMEOUT_OFFSET = 0;
localparam BEC_FLUSH_TIMEOUT_WIDTH  = 32;
localparam BEC_FLUSH_EN_OFFSET      = BEC_FLUSH_TIMEOUT_OFFSET + BEC_FLUSH_TIMEOUT_WIDTH;
localparam BEC_FLUSH_EN_WIDTH       = 1;
localparam BEC_TOTAL_WIDTH          = BEC_FLUSH_EN_OFFSET + BEC_FLUSH_EN_WIDTH;

// Backend Status
localparam BES_NOC_ID_OFFSET        = 0;
localparam BES_NOC_ID_WIDTH         = 32;
localparam BES_NUM_DATA_I_OFFSET    = BES_NOC_ID_OFFSET + BES_NOC_ID_WIDTH;
localparam BES_NUM_DATA_I_WIDTH     = 6;
localparam BES_NUM_DATA_O_OFFSET    = BES_NUM_DATA_I_OFFSET + BES_NUM_DATA_I_WIDTH;
localparam BES_NUM_DATA_O_WIDTH     = 6;
localparam BES_CTRL_FIFOSIZE_OFFSET = BES_NUM_DATA_O_OFFSET + BES_NUM_DATA_O_WIDTH;
localparam BES_CTRL_FIFOSIZE_WIDTH  = 6;
localparam BES_MTU_OFFSET           = BES_CTRL_FIFOSIZE_OFFSET + BES_CTRL_FIFOSIZE_WIDTH;
localparam BES_MTU_WIDTH            = 6;
localparam BES_FLUSH_ACTIVE_OFFSET  = BES_MTU_OFFSET + BES_MTU_WIDTH;
localparam BES_FLUSH_ACTIVE_WIDTH   = 1;
localparam BES_FLUSH_DONE_OFFSET    = BES_FLUSH_ACTIVE_OFFSET + BES_FLUSH_ACTIVE_WIDTH;
localparam BES_FLUSH_DONE_WIDTH     = 1;
localparam BES_TOTAL_WIDTH          = BES_FLUSH_DONE_OFFSET + BES_FLUSH_DONE_WIDTH;

