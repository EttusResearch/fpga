  // Registers 0 - 127 for NoC Shell
  localparam SR_FLOW_CTRL_CYCS_PER_ACK      = 0;
  localparam SR_FLOW_CTRL_PKTS_PER_ACK      = 1;
  localparam SR_FLOW_CTRL_WINDOW_SIZE       = 2;
  localparam SR_FLOW_CTRL_WINDOW_EN         = 3;
  localparam SR_ERROR_POLICY                = 4;
  localparam SR_SRC_SID                     = 5;
  localparam SR_NEXT_DST_SID                = 6;
  localparam SR_RESP_IN_DST_SID             = 7;
  localparam SR_RESP_OUT_DST_SID            = 8;
  localparam SR_RB_ADDR_USER                = 124;
  localparam SR_CLEAR_RX_FC                 = 125;
  localparam SR_CLEAR_TX_FC                 = 126;
  localparam SR_RB_ADDR                     = 127;
  // Registers 128-255 for users
  localparam SR_USER_REG_BASE               = 128;

  // NoC Shell readback registers
  localparam RB_NOC_ID                      = 0;
  localparam RB_GLOBAL_PARAMS               = 1;
  localparam RB_FIFOSIZE                    = 2;
  localparam RB_MTU                         = 3;
  localparam RB_BLOCK_PORT_SIDS             = 4;
  localparam RB_USER_RB_DATA                = 5;