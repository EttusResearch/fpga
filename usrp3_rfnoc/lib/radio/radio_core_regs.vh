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
/* Daughter board control settings bus register */
localparam [7:0] SR_MISC_OUTS            = 160;
localparam [7:0] SR_SPI                  = 168; // 168-173
localparam [7:0] SR_LEDS                 = 176; // 176-181
localparam [7:0] SR_FP_GPIO              = 184; // 184-189
localparam [7:0] SR_DB_GPIO              = 192; // 192-197
/* NOTE: Upper 32 registers are reserved for the output settings bus (see noc_block_radio_core.v) */
localparam [7:0] SR_EXTERNAL_BASE        = 224; // 224-255

/* Radio core readback registers */
localparam [7:0] RB_VITA_TIME            = 0;
localparam [7:0] RB_VITA_LASTPPS         = 1;
localparam [7:0] RB_TEST                 = 2;
localparam [7:0] RB_TXRX                 = 3;
localparam [7:0] RB_RADIO_NUM            = 4;
/* Daughter board control readback registers */
localparam [7:0] RB_MISC_IO              = 16;
localparam [7:0] RB_SPI                  = 17;
localparam [7:0] RB_LEDS                 = 18;
localparam [7:0] RB_DB_GPIO              = 19;
localparam [7:0] RB_FP_GPIO              = 20;
