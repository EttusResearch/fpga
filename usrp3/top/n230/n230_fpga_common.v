/*******************************************************************
 * Seting Register Base addresses
 *******************************************************************/
localparam SR_CORE_RADIO_CONTROL = 8'd3;
localparam SR_CORE_LOOPBACK  = 8'd4;
localparam SR_CORE_BIST1     = 8'd5;
localparam SR_CORE_BIST2     = 8'd6;
localparam SR_CORE_SPI       = 8'd8;
localparam SR_CORE_MISC      = 8'd16;
localparam SR_CORE_DATA_DELAY = 8'd17;
localparam SR_CORE_CLK_DELAY = 8'd18;
localparam SR_CORE_COMPAT    = 8'd24;
localparam SR_CORE_READBACK  = 8'd32;
localparam SR_CORE_GPSDO_ST  = 8'd40;
localparam SR_CORE_PPS_SEL   = 8'd48;
localparam SR_CORE_MS0_GPIO  = 8'd50;
localparam SR_CORE_MS1_GPIO  = 8'd58;

localparam SR_ZPU_SW_RST     = 8'd00;
localparam SR_ZPU_BOOT_DONE  = 8'd01;
localparam SR_ZPU_LEDS       = 8'd02;
localparam SR_ZPU_DEBUG      = 8'd03;
localparam SR_ZPU_XB_LOCAL   = 8'd04;
localparam SR_ZPU_JESD204_TEST = 8'd05;
localparam SR_ZPU_SFP_CTRL0  = 8'd16;
localparam SR_ZPU_SFP_CTRL1  = 8'd17;
localparam SR_ZPU_ETHINT0    = 8'd64;
localparam SR_ZPU_ETHINT1    = 8'd80;

/*******************************************************************
 * Readback addresses
 *******************************************************************/
localparam RB_CORE_SIGNATURE = 3'd0;
localparam RB_CORE_SPI       = 3'd1;
localparam RB_CORE_STATUS    = 3'd2;
localparam RB_CORE_BIST      = 3'd3;
localparam RB_CORE_GIT_HASH  = 3'd4;
localparam RB_CORE_MS0_GPIO  = 3'd5;
localparam RB_CORE_MS1_GPIO  = 3'd6;

localparam RB_ZPU_COMPAT      = 8'd0;
localparam RB_ZPU_COUNTER     = 8'd1;
localparam RB_ZPU_SFP_STATUS0 = 8'd2;
localparam RB_ZPU_SFP_STATUS1 = 8'd3;
localparam RB_ZPU_GIT_HASH    = 8'd4;
//localparam RB_ZPU_UNCLAIMED = 8'd5;
localparam RB_ZPU_ETH0_PKT_CNT = 8'd6;
localparam RB_ZPU_ETH1_PKT_CNT = 8'd7;


/*******************************************************************
 * Build Compatability Numbers
 *******************************************************************/
localparam PRODUCT_ID = 8'h01;
`ifdef SAFE_IMAGE
   // Decrement safe image compat number
   localparam COMPAT_MAJOR = 8'hF0;
   localparam COMPAT_MINOR = 16'hFFFF;
`else
   // Increment non-safe image compat number
   localparam COMPAT_MAJOR = 8'h20;
   localparam COMPAT_MINOR = 16'h0000;
`endif

