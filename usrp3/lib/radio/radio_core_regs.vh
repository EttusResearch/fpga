// Timekeeper
localparam [7:0] SR_TIME_HI              = 128;
localparam [7:0] SR_TIME_LO              = 129;
localparam [7:0] SR_TIME_CTRL            = 130;
// Clear out command FIFO
localparam [7:0] SR_CLEAR_CMDS           = 131;
/* Radio core readback settings bus register */
// Debug / startup testing
localparam [7:0] SR_LOOPBACK             = 132;
localparam [7:0] SR_TEST                 = 133;
localparam [7:0] SR_CODEC_IDLE           = 134;
// TX / RX Control statemachines
localparam [7:0] SR_TX_CTRL_ERROR_POLICY = 144;
localparam [7:0] SR_RX_CTRL_COMMAND      = 152;
localparam [7:0] SR_RX_CTRL_TIME_HI      = 153;
localparam [7:0] SR_RX_CTRL_TIME_LO      = 154;
localparam [7:0] SR_RX_CTRL_HALT         = 155;
localparam [7:0] SR_RX_CTRL_MAXLEN       = 156;
localparam [7:0] SR_RX_CTRL_CLEAR_CMDS   = 157;
localparam [7:0] SR_RX_CTRL_OUTPUT_FORMAT = 158;

/* Radio core readback registers */
localparam [7:0] RB_VITA_TIME            = 0;
localparam [7:0] RB_VITA_LASTPPS         = 1;
localparam [7:0] RB_TEST                 = 2;
localparam [7:0] RB_TXRX                 = 3;
localparam [7:0] RB_RADIO_NUM            = 4;
localparam [7:0] RB_COMPAT_NUM           = 5;

/* NOTE: Settings and readback offsets for the dboard and frontend
 *       controller cores. These are device specific */
localparam [7:0] SR_DB_FE_BASE           = 160; // 160-255
localparam [7:0] RB_DB_FE_BASE           = 16;  // 16-255
