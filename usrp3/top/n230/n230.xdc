#
# Copyright 2014-2016 Ettus Research LLC
#


#
# Global config bank properties
#
set_property CFGBVS VCCO         [current_design]
set_property CONFIG_VOLTAGE 3.3  [current_design]

#
# Configuration Flash SPI interface
#
set_property PACKAGE_PIN      R22         [get_ports SPIFLASH_MISO]
set_property PACKAGE_PIN      P22         [get_ports SPIFLASH_MOSI]
# set_property PACKAGE_PIN     L12         [get_ports SPIFLASH_CFGCLK]   ;# Accessible through STARTUPE2 primitive
set_property PACKAGE_PIN      T19         [get_ports SPIFLASH_CS]
set_property IOSTANDARD       LVCMOS33    [get_ports SPIFLASH_*]

#
# ADF4002 Clock Chip
#
set_property PACKAGE_PIN      T20         [get_ports PLL_CE]
set_property PACKAGE_PIN      R19         [get_ports PLL_MOSI]
set_property PACKAGE_PIN      T21         [get_ports PLL_SCLK]
set_property PACKAGE_PIN      P19         [get_ports PLL_LOCK]
set_property IOSTANDARD       LVCMOS33    [get_ports PLL_*]

#
# Debug UART
#
set_property PACKAGE_PIN      R14         [get_ports FPGA_RXD0]
set_property IOSTANDARD       LVCMOS33    [get_ports FPGA_RXD0]
set_property PACKAGE_PIN      U17         [get_ports FPGA_TXD0]
set_property IOSTANDARD       LVCMOS33    [get_ports FPGA_TXD0]

#
# AD9361 Codec SPI
#
set_property PACKAGE_PIN      U6          [get_ports CODEC_CE]
set_property IOSTANDARD       LVCMOS18    [get_ports CODEC_CE]
set_property PACKAGE_PIN      R6          [get_ports CODEC_MISO]
set_property IOSTANDARD       LVCMOS18    [get_ports CODEC_MISO]
set_property PACKAGE_PIN      AA6         [get_ports CODEC_MOSI]
set_property IOSTANDARD       LVCMOS18    [get_ports CODEC_MOSI]
set_property PACKAGE_PIN      T6          [get_ports CODEC_SCLK]
set_property IOSTANDARD       LVCMOS18    [get_ports CODEC_SCLK]

#
# AD9361 Coded Control
#
set_property PACKAGE_PIN      W5          [get_ports CODEC_ENABLE]
set_property IOSTANDARD       LVCMOS18    [get_ports CODEC_ENABLE]
set_property PACKAGE_PIN      W6          [get_ports CODEC_EN_AGC]
set_property IOSTANDARD       LVCMOS18    [get_ports CODEC_EN_AGC]
set_property PACKAGE_PIN      T5          [get_ports CODEC_RESET]
set_property IOSTANDARD       LVCMOS18    [get_ports CODEC_RESET]
set_property PACKAGE_PIN      Y6          [get_ports CODEC_SYNC]
set_property IOSTANDARD       LVCMOS18    [get_ports CODEC_SYNC]
set_property PACKAGE_PIN      V5          [get_ports CODEC_TXRX]
set_property IOSTANDARD       LVCMOS18    [get_ports CODEC_TXRX]
set_property PACKAGE_PIN      W9          [get_ports {CODEC_CTRL_IN[3]}]
set_property PACKAGE_PIN      Y9          [get_ports {CODEC_CTRL_IN[2]}]
set_property PACKAGE_PIN      Y8          [get_ports {CODEC_CTRL_IN[1]}]
set_property PACKAGE_PIN      Y7          [get_ports {CODEC_CTRL_IN[0]}]
set_property IOSTANDARD       LVCMOS18    [get_ports CODEC_CTRL_IN*]
# set_property PACKAGE_PIN     AA8         [get_ports {CODEC_CTRL_OUT[7]}]
# set_property PACKAGE_PIN     AB8         [get_ports {CODEC_CTRL_OUT[6]}]
# set_property PACKAGE_PIN     V9          [get_ports {CODEC_CTRL_OUT[5]}]
# set_property PACKAGE_PIN     V8          [get_ports {CODEC_CTRL_OUT[4]}]
# set_property PACKAGE_PIN     AB7         [get_ports {CODEC_CTRL_OUT[3]}]
# set_property PACKAGE_PIN     AB6         [get_ports {CODEC_CTRL_OUT[2]}]
# set_property PACKAGE_PIN     V7          [get_ports {CODEC_CTRL_OUT[1]}]
# set_property PACKAGE_PIN     W7          [get_ports {CODEC_CTRL_OUT[0]}]
# set_property IOSTANDARD      LVCMOS18    [get_ports CODEC_CTRL_OUT*]

#
# Catalina Source Sync Clocks
#
set_property PACKAGE_PIN      W11         [get_ports CODEC_DATA_CLK_P]
set_property PACKAGE_PIN      W12         [get_ports CODEC_DATA_CLK_N]
set_property IOSTANDARD       LVDS_25     [get_ports CODEC_DATA_CLK_P]
set_property IOSTANDARD       LVDS_25     [get_ports CODEC_DATA_CLK_N]
set_property PACKAGE_PIN      Y11         [get_ports CODEC_FB_CLK_P]
set_property PACKAGE_PIN      Y12         [get_ports CODEC_FB_CLK_N]
set_property IOSTANDARD       LVDS_25     [get_ports CODEC_FB_CLK_P]
set_property IOSTANDARD       LVDS_25     [get_ports CODEC_FB_CLK_N]

#
# Catalina Data buses
#
set_property PACKAGE_PIN      AA13        [get_ports {RX_DATA_P[5]}]
set_property PACKAGE_PIN      AB13        [get_ports {RX_DATA_N[5]}]
set_property PACKAGE_PIN      V15         [get_ports {RX_DATA_N[4]}]    ;# inverted pair
set_property PACKAGE_PIN      U15         [get_ports {RX_DATA_P[4]}]
set_property PACKAGE_PIN      AA14        [get_ports {RX_DATA_N[3]}]    ;# inverted pair
set_property PACKAGE_PIN      Y13         [get_ports {RX_DATA_P[3]}]
set_property PACKAGE_PIN      Y14         [get_ports {RX_DATA_N[2]}]    ;# inverted pair
set_property PACKAGE_PIN      W14         [get_ports {RX_DATA_P[2]}]
set_property PACKAGE_PIN      AB15        [get_ports {RX_DATA_N[1]}]    ;# inverted pair
set_property PACKAGE_PIN      AA15        [get_ports {RX_DATA_P[1]}]
set_property PACKAGE_PIN      AA16        [get_ports {RX_DATA_N[0]}]    ;# inverted pair
set_property PACKAGE_PIN      Y16         [get_ports {RX_DATA_P[0]}]
set_property IOSTANDARD       LVDS_25     [get_ports RX_DATA_*]

set_property PACKAGE_PIN      AB10        [get_ports {TX_DATA_N[5]}]    ;# inverted pair
set_property PACKAGE_PIN      AA9         [get_ports {TX_DATA_P[5]}]
set_property PACKAGE_PIN      AA10        [get_ports {TX_DATA_P[4]}]
set_property PACKAGE_PIN      AA11        [get_ports {TX_DATA_N[4]}]
set_property PACKAGE_PIN      U16         [get_ports {TX_DATA_N[3]}]    ;# inverted pair
set_property PACKAGE_PIN      T16         [get_ports {TX_DATA_P[3]}]
set_property PACKAGE_PIN      AB11        [get_ports {TX_DATA_P[2]}]
set_property PACKAGE_PIN      AB12        [get_ports {TX_DATA_N[2]}]
set_property PACKAGE_PIN      W15         [get_ports {TX_DATA_P[1]}]
set_property PACKAGE_PIN      W16         [get_ports {TX_DATA_N[1]}]
set_property PACKAGE_PIN      W10         [get_ports {TX_DATA_N[0]}]    ;# inverted pair
set_property PACKAGE_PIN      V10         [get_ports {TX_DATA_P[0]}]
set_property IOSTANDARD       LVDS_25     [get_ports TX_DATA_*]

set_property PACKAGE_PIN      AB17        [get_ports RX_FRAME_N]        ;# inverted pair 
set_property PACKAGE_PIN      AB16        [get_ports RX_FRAME_P]
set_property IOSTANDARD       LVDS_25     [get_ports RX_FRAME*]
set_property PACKAGE_PIN      T15         [get_ports TX_FRAME_N]        ;# inverted pair
set_property PACKAGE_PIN      T14         [get_ports TX_FRAME_P]
set_property IOSTANDARD       LVDS_25     [get_ports TX_FRAME*]

#
# Catalina Clocking
#
set_property PACKAGE_PIN      K18         [get_ports CODEC_MAIN_CLK_P]
set_property PACKAGE_PIN      K19         [get_ports CODEC_MAIN_CLK_N]
set_property IOSTANDARD       LVDS_25     [get_ports CODEC_MAIN_CLK_*]
# from catalina clock_out pin 
#set_property PACKAGE_PIN     Y19         [get_ports CODEC_CLKOUT_FPGA]
#set_property IOSTANDARD      LVCMOS33    [get_ports CODEC_CLKOUT_FPGA]

#
# MICTOR Debug Port
#
set_property PACKAGE_PIN      W21         [get_ports DEBUG[31]]
set_property PACKAGE_PIN      AA21        [get_ports DEBUG[30]]
set_property PACKAGE_PIN      AA20        [get_ports DEBUG[29]]
set_property PACKAGE_PIN      Y22         [get_ports DEBUG[28]]
set_property PACKAGE_PIN      Y21         [get_ports DEBUG[27]]
set_property PACKAGE_PIN      AB22        [get_ports DEBUG[26]]
set_property PACKAGE_PIN      AB21        [get_ports DEBUG[25]]
set_property PACKAGE_PIN      V20         [get_ports DEBUG[24]]
set_property PACKAGE_PIN      U20         [get_ports DEBUG[23]]
set_property PACKAGE_PIN      W20         [get_ports DEBUG[22]]
set_property PACKAGE_PIN      V19         [get_ports DEBUG[21]]
set_property PACKAGE_PIN      V18         [get_ports DEBUG[20]]
set_property PACKAGE_PIN      AB20        [get_ports DEBUG[19]]
set_property PACKAGE_PIN      M1          [get_ports DEBUG[18]]
set_property PACKAGE_PIN      M2          [get_ports DEBUG[17]]
set_property PACKAGE_PIN      M3          [get_ports DEBUG[16]]
set_property PACKAGE_PIN      J6          [get_ports DEBUG[15]]
set_property PACKAGE_PIN      K6          [get_ports DEBUG[14]]
set_property PACKAGE_PIN      L4          [get_ports DEBUG[13]]
set_property PACKAGE_PIN      L5          [get_ports DEBUG[12]]
set_property PACKAGE_PIN      N3          [get_ports DEBUG[11]]
set_property PACKAGE_PIN      N4          [get_ports DEBUG[10]]
set_property PACKAGE_PIN      P1          [get_ports DEBUG[9]]
set_property PACKAGE_PIN      R1          [get_ports DEBUG[8]]
set_property PACKAGE_PIN      P4          [get_ports DEBUG[7]]
set_property PACKAGE_PIN      P5          [get_ports DEBUG[6]]
set_property PACKAGE_PIN      N2          [get_ports DEBUG[5]]
set_property PACKAGE_PIN      P2          [get_ports DEBUG[4]]
set_property PACKAGE_PIN      M5          [get_ports DEBUG[3]]
set_property PACKAGE_PIN      M6          [get_ports DEBUG[2]]
set_property PACKAGE_PIN      N5          [get_ports DEBUG[1]]
set_property PACKAGE_PIN      P6          [get_ports DEBUG[0]]
set_property PACKAGE_PIN      Y18         [get_ports DEBUG_CLK[1]]
set_property PACKAGE_PIN      W19         [get_ports DEBUG_CLK[0]]
set_property IOSTANDARD       LVCMOS33    [get_ports DEBUG*]

#
# GPSDO 
#
set_property IOSTANDARD       LVCMOS33    [get_ports GPS_*]
#set_property PACKAGE_PIN      W17         [get_ports GPS_LOCK]
set_property PACKAGE_PIN      V17         [get_ports GPS_RXD]
#IJB Temp reset switch input	
set_property PULLUP TRUE                  [get_ports GPS_RXD]
set_property PACKAGE_PIN      AA19        [get_ports GPS_TXD]
#set_property PACKAGE_PIN      AB18       [get_ports GPS_TXD_NMEA]
set_property PACKAGE_PIN      W22         [get_ports REF_SEL]
set_property IOSTANDARD       LVCMOS33    [get_ports REF_SEL]
set_property PACKAGE_PIN      AA18        [get_ports PPS_IN_INT]
set_property PACKAGE_PIN      U18         [get_ports PPS_IN_EXT]
set_property IOSTANDARD       LVCMOS33    [get_ports PPS_IN_*]

#
# LEDS
#
set_property PACKAGE_PIN      F13         [get_ports LED_RX1]
set_property PACKAGE_PIN      F16         [get_ports LED_RX2]
set_property PACKAGE_PIN      F15         [get_ports LED_TXRX1_RX]
set_property PACKAGE_PIN      E17         [get_ports LED_TXRX1_TX]
set_property PACKAGE_PIN      F14         [get_ports LED_TXRX2_RX]
set_property PACKAGE_PIN      F21         [get_ports LED_TXRX2_TX]
set_property PACKAGE_PIN      K16         [get_ports LED_LINK1]
set_property PACKAGE_PIN      L16         [get_ports LED_ACT1]
set_property PACKAGE_PIN      M16         [get_ports LED_LINK2]
set_property PACKAGE_PIN      M15         [get_ports LED_ACT2]
set_property IOSTANDARD       LVCMOS25    [get_ports LED_*]

#
# RF Switch control
#
set_property PACKAGE_PIN      R18         [get_ports SFDX1_RX]
set_property PACKAGE_PIN      P16         [get_ports SFDX1_TX]
set_property PACKAGE_PIN      N14         [get_ports SFDX2_RX]
set_property PACKAGE_PIN      P15         [get_ports SFDX2_TX]
set_property PACKAGE_PIN      T18         [get_ports SRX1_RX]
set_property PACKAGE_PIN      P14         [get_ports SRX1_TX]
set_property PACKAGE_PIN      R17         [get_ports SRX2_RX]
set_property PACKAGE_PIN      N13         [get_ports SRX2_TX]
set_property PACKAGE_PIN      V22         [get_ports TX_BANDSEL_A]
set_property PACKAGE_PIN      U21         [get_ports TX_BANDSEL_B]
set_property PACKAGE_PIN      N15         [get_ports TX_ENABLE1]
set_property PACKAGE_PIN      P20         [get_ports TX_ENABLE2]
set_property PACKAGE_PIN      P17         [get_ports RX_BANDSEL_A]
set_property PACKAGE_PIN      N17         [get_ports RX_BANDSEL_B]
set_property PACKAGE_PIN      R16         [get_ports RX_BANDSEL_C]
set_property IOSTANDARD       LVCMOS33    [get_ports SFDX1_RX]
set_property IOSTANDARD       LVCMOS33    [get_ports SFDX1_TX]
set_property IOSTANDARD       LVCMOS33    [get_ports SFDX2_RX]
set_property IOSTANDARD       LVCMOS33    [get_ports SFDX2_TX]
set_property IOSTANDARD       LVCMOS33    [get_ports SRX1_RX]
set_property IOSTANDARD       LVCMOS33    [get_ports SRX1_TX]
set_property IOSTANDARD       LVCMOS33    [get_ports SRX2_RX]
set_property IOSTANDARD       LVCMOS33    [get_ports SRX2_TX]
set_property IOSTANDARD       LVCMOS33    [get_ports TX_BANDSEL_A]
set_property IOSTANDARD       LVCMOS33    [get_ports TX_BANDSEL_B]
set_property IOSTANDARD       LVCMOS33    [get_ports TX_ENABLE1]
set_property IOSTANDARD       LVCMOS33    [get_ports TX_ENABLE2]
set_property IOSTANDARD       LVCMOS33    [get_ports RX_BANDSEL_A]
set_property IOSTANDARD       LVCMOS33    [get_ports RX_BANDSEL_B]
set_property IOSTANDARD       LVCMOS33    [get_ports RX_BANDSEL_C]

#
# GPIO Header
#
#set_property PACKAGE_PIN      L19        [get_ports GPIO[7]]
#set_property PACKAGE_PIN      L20        [get_ports GPIO[6]]
#set_property PACKAGE_PIN      E16        [get_ports GPIO[5]]
#set_property PACKAGE_PIN      D16        [get_ports GPIO[4]]
#set_property PACKAGE_PIN      E13        [get_ports GPIO[3]]
#set_property PACKAGE_PIN      E14        [get_ports GPIO[2]]
#set_property PACKAGE_PIN      C14        [get_ports GPIO[1]]
#set_property PACKAGE_PIN      C15        [get_ports GPIO[0]]
#set_property IOSTANDARD       LVCMOS25   [get_ports GPIO*]

#
# SFP ethernet reference clock
# (Direct to MGT logic - signal type implied)
#
set_property PACKAGE_PIN      F6          [get_ports SFPX_CLK_P]
set_property PACKAGE_PIN      E6          [get_ports SFPX_CLK_N]

#
# SFP0 - Serial Data - Highspeed transceiver signals
#
set_property PACKAGE_PIN      B8          [get_ports SFP0_RX_P]
set_property PACKAGE_PIN      A8          [get_ports SFP0_RX_N]
set_property PACKAGE_PIN      B4          [get_ports SFP0_TX_P]
set_property PACKAGE_PIN      A4          [get_ports SFP0_TX_N]

#
# SFP1 - Serial Data - Highspeed transceiver signals
#
set_property PACKAGE_PIN      D11         [get_ports SFP1_RX_P]
set_property PACKAGE_PIN      C11         [get_ports SFP1_RX_N]
set_property PACKAGE_PIN      D5          [get_ports SFP1_TX_P]
set_property PACKAGE_PIN      C5          [get_ports SFP1_TX_N]

#
# SFP0 - Low speed supporting signals
#
set_property PACKAGE_PIN      E3          [get_ports SFP0_TXFAULT]
set_property PACKAGE_PIN      F3          [get_ports SFP0_TXDISABLE]
set_property PACKAGE_PIN      J1          [get_ports SFP0_SDA]
set_property PACKAGE_PIN      K1          [get_ports SFP0_SCL]
set_property PACKAGE_PIN      G2          [get_ports SFP0_MODABS]
set_property PACKAGE_PIN      J2          [get_ports SFP0_RXLOS]
set_property PACKAGE_PIN      H2          [get_ports SFP0_RS0]
set_property PACKAGE_PIN      K2          [get_ports SFP0_RS1]
set_property IOSTANDARD       LVCMOS33    [get_ports SFP0_TXFAULT]
set_property IOSTANDARD       LVCMOS33    [get_ports SFP0_TXDISABLE]
set_property IOSTANDARD       LVCMOS33    [get_ports SFP0_SDA]
set_property IOSTANDARD       LVCMOS33    [get_ports SFP0_SCL]
set_property IOSTANDARD       LVCMOS33    [get_ports SFP0_MODABS]
set_property IOSTANDARD       LVCMOS33    [get_ports SFP0_RXLOS]
set_property IOSTANDARD       LVCMOS33    [get_ports SFP0_RS0]
set_property IOSTANDARD       LVCMOS33    [get_ports SFP0_RS1]

#
# SFP1 - Low speed supporting signals
#
set_property PACKAGE_PIN      H5          [get_ports SFP1_TXFAULT]
set_property PACKAGE_PIN      J5          [get_ports SFP1_TXDISABLE]
set_property PACKAGE_PIN      G3          [get_ports SFP1_SDA]
set_property PACKAGE_PIN      H3          [get_ports SFP1_SCL]
set_property PACKAGE_PIN      G4          [get_ports SFP1_MODABS]
set_property PACKAGE_PIN      J4          [get_ports SFP1_RXLOS]
set_property PACKAGE_PIN      H4          [get_ports SFP1_RS0]
set_property PACKAGE_PIN      K4          [get_ports SFP1_RS1]
set_property IOSTANDARD       LVCMOS33    [get_ports SFP1_TXFAULT]
set_property IOSTANDARD       LVCMOS33    [get_ports SFP1_TXDISABLE]
set_property IOSTANDARD       LVCMOS33    [get_ports SFP1_SDA]
set_property IOSTANDARD       LVCMOS33    [get_ports SFP1_SCL]
set_property IOSTANDARD       LVCMOS33    [get_ports SFP1_MODABS]
set_property IOSTANDARD       LVCMOS33    [get_ports SFP1_RXLOS]
set_property IOSTANDARD       LVCMOS33    [get_ports SFP1_RS0]
set_property IOSTANDARD       LVCMOS33    [get_ports SFP1_RS1]

#
# LTE/JESD204 Clocking sources
#
set_property PACKAGE_PIN      V13         [get_ports CODEC_LOOP_CLK_OUT_P]
set_property PACKAGE_PIN      V14         [get_ports CODEC_LOOP_CLK_OUT_N]
set_property IOSTANDARD       LVDS_25     [get_ports CODEC_LOOP_CLK_OUT_*]
# CPRI - Put these pins back in later.
set_property PACKAGE_PIN      F10         [get_ports CODEC_LOOP_CLK_IN_P]
set_property PACKAGE_PIN      E10         [get_ports CODEC_LOOP_CLK_IN_N]

#
# MiniSAS Interface
#
set_property PACKAGE_PIN      D7          [get_ports RD1_ET_ENV0_P]
set_property PACKAGE_PIN      C7          [get_ports RD1_ET_ENV0_N]
set_property PACKAGE_PIN      D9          [get_ports RD1_ET_RXNC_P]
set_property PACKAGE_PIN      C9          [get_ports RD1_ET_RXNC_N]

set_property PACKAGE_PIN      B17         [get_ports RD1_ET_SYNCp]
set_property PACKAGE_PIN      B18         [get_ports RD1_ET_SYNCn]
set_property PACKAGE_PIN      D17         [get_ports RD1_ET_FRAME_CLKp]
set_property PACKAGE_PIN      C17         [get_ports RD1_ET_FRAME_CLKn]
set_property IOSTANDARD       LVDS_25     [get_ports RD1_ET_SYNCp]
set_property IOSTANDARD       LVDS_25     [get_ports RD1_ET_SYNCn]
set_property IOSTANDARD       LVDS_25     [get_ports RD1_ET_FRAME_CLKp]
set_property IOSTANDARD       LVDS_25     [get_ports RD1_ET_FRAME_CLKn]

set_property PACKAGE_PIN      B6          [get_ports RD2_ET_ENV0_P]
set_property PACKAGE_PIN      A6          [get_ports RD2_ET_ENV0_N]
set_property PACKAGE_PIN      B10         [get_ports RD2_ET_RXNC_P]
set_property PACKAGE_PIN      A10         [get_ports RD2_ET_RXNC_N]

set_property PACKAGE_PIN      E19         [get_ports RD2_ET_SYNCp]
set_property PACKAGE_PIN      D19         [get_ports RD2_ET_SYNCn]
set_property PACKAGE_PIN      C18         [get_ports RD2_ET_FRAME_CLKp]
set_property PACKAGE_PIN      C19         [get_ports RD2_ET_FRAME_CLKn]
set_property IOSTANDARD       LVDS_25     [get_ports RD2_ET_SYNCp]
set_property IOSTANDARD       LVDS_25     [get_ports RD2_ET_SYNCn]
set_property IOSTANDARD       LVDS_25     [get_ports RD2_ET_FRAME_CLKp]
set_property IOSTANDARD       LVDS_25     [get_ports RD2_ET_FRAME_CLKn]

set_property PACKAGE_PIN      F4          [get_ports RD1_RX_TX_LOOPBACK]
set_property PACKAGE_PIN      L6          [get_ports RD1_TEMP_SDA]
set_property PACKAGE_PIN      A1          [get_ports RD1_TEMP_SCL]
set_property PACKAGE_PIN      B1          [get_ports RD1_RFPWR_CONV]
set_property PACKAGE_PIN      B2          [get_ports RD1_RFPWR_SDO]
set_property PACKAGE_PIN      C2          [get_ports RD1_RFPWR_SCLK]
set_property PACKAGE_PIN      T3          [get_ports RD1_ET_SPI_SCLK]
set_property PACKAGE_PIN      U7          [get_ports RD1_ET_SPI_SDIN]
set_property PACKAGE_PIN      U1          [get_ports RD1_ET_SPI_SDOUT]
set_property PACKAGE_PIN      T1          [get_ports RD1_ET_SPI_SDEN]
set_property PACKAGE_PIN      V2          [get_ports RD1_ET_RESET]
set_property PACKAGE_PIN      U2          [get_ports RD1_ET_ALARM]
set_property PACKAGE_PIN      R2          [get_ports RD1_ET_WARNING]
set_property PACKAGE_PIN      R3          [get_ports RD1_SLEEP]
set_property PACKAGE_PIN      Y2          [get_ports RD1_P_READY]
set_property PACKAGE_PIN      W2          [get_ports RD1_ICSP_CLK]
set_property PACKAGE_PIN      Y1          [get_ports RD1_ICSP_DAT]
set_property IOSTANDARD       LVCMOS33    [get_ports RD1_RX_TX_LOOPBACK]
set_property IOSTANDARD       LVCMOS33    [get_ports RD1_TEMP_SDA]
set_property IOSTANDARD       LVCMOS33    [get_ports RD1_TEMP_SCL]
set_property IOSTANDARD       LVCMOS33    [get_ports RD1_RFPWR_CONV]
set_property IOSTANDARD       LVCMOS33    [get_ports RD1_RFPWR_SDO]
set_property IOSTANDARD       LVCMOS33    [get_ports RD1_RFPWR_SCLK]
set_property IOSTANDARD       LVCMOS18    [get_ports RD1_ET_SPI_SCLK]
set_property IOSTANDARD       LVCMOS18    [get_ports RD1_ET_SPI_SDIN]
set_property IOSTANDARD       LVCMOS18    [get_ports RD1_ET_SPI_SDOUT]
set_property IOSTANDARD       LVCMOS18    [get_ports RD1_ET_SPI_SDEN]
set_property IOSTANDARD       LVCMOS18    [get_ports RD1_ET_RESET]
set_property IOSTANDARD       LVCMOS18    [get_ports RD1_ET_ALARM]
set_property IOSTANDARD       LVCMOS18    [get_ports RD1_ET_WARNING]
set_property IOSTANDARD       LVCMOS18    [get_ports RD1_SLEEP]
set_property IOSTANDARD       LVCMOS18    [get_ports RD1_P_READY]
set_property IOSTANDARD       LVCMOS18    [get_ports RD1_ICSP_CLK]
set_property IOSTANDARD       LVCMOS18    [get_ports RD1_ICSP_DAT]


set_property PACKAGE_PIN      D1          [get_ports RD2_RX_TX_LOOPBACK]
set_property PACKAGE_PIN      E1          [get_ports RD2_TEMP_SDA]
set_property PACKAGE_PIN      D2          [get_ports RD2_TEMP_SCL]
set_property PACKAGE_PIN      E2          [get_ports RD2_RFPWR_CONV]
set_property PACKAGE_PIN      F1          [get_ports RD2_RFPWR_SDO]
set_property PACKAGE_PIN      G1          [get_ports RD2_RFPWR_SCLK]
set_property PACKAGE_PIN      W1          [get_ports RD2_ET_SPI_SCLK]
set_property PACKAGE_PIN      V3          [get_ports RD2_ET_SPI_SDIN]
set_property PACKAGE_PIN      U3          [get_ports RD2_ET_SPI_SDOUT]
set_property PACKAGE_PIN      AB1         [get_ports RD2_ET_SPI_SDEN]
set_property PACKAGE_PIN      AA1         [get_ports RD2_ET_RESET]
set_property PACKAGE_PIN      AB2         [get_ports RD2_ET_ALARM]
set_property PACKAGE_PIN      AB3         [get_ports RD2_ET_WARNING]
set_property PACKAGE_PIN      AA3         [get_ports RD2_SLEEP]
set_property PACKAGE_PIN      Y3          [get_ports RD2_P_READY]
set_property PACKAGE_PIN      AB5         [get_ports RD2_ICSP_CLK]
set_property PACKAGE_PIN      AA5         [get_ports RD2_ICSP_DAT]
set_property IOSTANDARD       LVCMOS33    [get_ports RD2_RX_TX_LOOPBACK]
set_property IOSTANDARD       LVCMOS33    [get_ports RD2_TEMP_SDA]
set_property IOSTANDARD       LVCMOS33    [get_ports RD2_TEMP_SCL]
set_property IOSTANDARD       LVCMOS33    [get_ports RD2_RFPWR_CONV]
set_property IOSTANDARD       LVCMOS33    [get_ports RD2_RFPWR_SDO]
set_property IOSTANDARD       LVCMOS33    [get_ports RD2_RFPWR_SCLK]
set_property IOSTANDARD       LVCMOS18    [get_ports RD2_ET_SPI_SCLK]
set_property IOSTANDARD       LVCMOS18    [get_ports RD2_ET_SPI_SDIN]
set_property IOSTANDARD       LVCMOS18    [get_ports RD2_ET_SPI_SDOUT]
set_property IOSTANDARD       LVCMOS18    [get_ports RD2_ET_SPI_SDEN]
set_property IOSTANDARD       LVCMOS18    [get_ports RD2_ET_RESET]
set_property IOSTANDARD       LVCMOS18    [get_ports RD2_ET_ALARM]
set_property IOSTANDARD       LVCMOS18    [get_ports RD2_ET_WARNING]
set_property IOSTANDARD       LVCMOS18    [get_ports RD2_SLEEP]
set_property IOSTANDARD       LVCMOS18    [get_ports RD2_P_READY]
set_property IOSTANDARD       LVCMOS18    [get_ports RD2_ICSP_CLK]
set_property IOSTANDARD       LVCMOS18    [get_ports RD2_ICSP_DAT]

#
# Ext SRAM
#
set_property IOSTANDARD LVCMOS25 [get_ports RAM_*]

set_property PACKAGE_PIN      H20         [get_ports RAM_D[35]]
set_property PACKAGE_PIN      J17         [get_ports RAM_D[34]]
set_property PACKAGE_PIN      H22         [get_ports RAM_D[33]]
set_property PACKAGE_PIN      K17         [get_ports RAM_D[32]]
set_property PACKAGE_PIN      J22         [get_ports RAM_D[31]]
set_property PACKAGE_PIN      K21         [get_ports RAM_D[30]]
set_property PACKAGE_PIN      K22         [get_ports RAM_D[29]]
set_property PACKAGE_PIN      L18         [get_ports RAM_D[28]]
set_property PACKAGE_PIN      L21         [get_ports RAM_D[27]]
set_property PACKAGE_PIN      N18         [get_ports RAM_D[26]]
set_property PACKAGE_PIN      M20         [get_ports RAM_D[25]]
set_property PACKAGE_PIN      M21         [get_ports RAM_D[24]]
set_property PACKAGE_PIN      M22         [get_ports RAM_D[23]]
set_property PACKAGE_PIN      M18         [get_ports RAM_D[22]]
set_property PACKAGE_PIN      M17         [get_ports RAM_D[21]]
set_property PACKAGE_PIN      N22         [get_ports RAM_D[20]]
set_property PACKAGE_PIN      N20         [get_ports RAM_D[19]]
set_property PACKAGE_PIN      N19         [get_ports RAM_D[18]]
set_property PACKAGE_PIN      G20         [get_ports RAM_D[17]]
set_property PACKAGE_PIN      H18         [get_ports RAM_D[16]]
set_property PACKAGE_PIN      G18         [get_ports RAM_D[15]]
set_property PACKAGE_PIN      H17         [get_ports RAM_D[14]]
set_property PACKAGE_PIN      G17         [get_ports RAM_D[13]]
set_property PACKAGE_PIN      J16         [get_ports RAM_D[12]]
set_property PACKAGE_PIN      G16         [get_ports RAM_D[11]]
set_property PACKAGE_PIN      H15         [get_ports RAM_D[10]]
set_property PACKAGE_PIN      G15         [get_ports RAM_D[9]]
set_property PACKAGE_PIN      M13         [get_ports RAM_D[8]]
set_property PACKAGE_PIN      L13         [get_ports RAM_D[7]]
set_property PACKAGE_PIN      K13         [get_ports RAM_D[6]]
set_property PACKAGE_PIN      H13         [get_ports RAM_D[5]]
set_property PACKAGE_PIN      G13         [get_ports RAM_D[4]]
set_property PACKAGE_PIN      J14         [get_ports RAM_D[3]]
set_property PACKAGE_PIN      H14         [get_ports RAM_D[2]]
set_property PACKAGE_PIN      K14         [get_ports RAM_D[1]]
set_property PACKAGE_PIN      J15         [get_ports RAM_D[0]]

set_property IOB TRUE                     [get_ports RAM_D*]
set_property DRIVE            8           [get_ports RAM_D*]

# Top 3 Address bits ied low in FPGA
set_property PACKAGE_PIN      D22         [get_ports RAM_A[20]]
set_property PACKAGE_PIN      D21         [get_ports RAM_A[19]]
set_property PACKAGE_PIN      B22         [get_ports RAM_A[18]]
set_property PACKAGE_PIN      G21         [get_ports RAM_A[17]]
set_property PACKAGE_PIN      F20         [get_ports RAM_A[16]]
set_property PACKAGE_PIN      F19         [get_ports RAM_A[15]]
set_property PACKAGE_PIN      E22         [get_ports RAM_A[14]]
set_property PACKAGE_PIN      D20         [get_ports RAM_A[13]]
set_property PACKAGE_PIN      C22         [get_ports RAM_A[12]]
set_property PACKAGE_PIN      C20         [get_ports RAM_A[11]]
set_property PACKAGE_PIN      B21         [get_ports RAM_A[10]]
set_property PACKAGE_PIN      B20         [get_ports RAM_A[9]]
set_property PACKAGE_PIN      A19         [get_ports RAM_A[8]]
set_property PACKAGE_PIN      A13         [get_ports RAM_A[7]]
set_property PACKAGE_PIN      A18         [get_ports RAM_A[6]]
set_property PACKAGE_PIN      A20         [get_ports RAM_A[5]]
set_property PACKAGE_PIN      A21         [get_ports RAM_A[4]]
set_property PACKAGE_PIN      F18         [get_ports RAM_A[3]]
set_property PACKAGE_PIN      G22         [get_ports RAM_A[2]]
set_property PACKAGE_PIN      E21         [get_ports RAM_A[1]]
set_property PACKAGE_PIN      E18         [get_ports RAM_A[0]]
set_property DRIVE            8           [get_ports RAM_A*]
set_property IOB              TRUE        [get_ports RAM_A[17]]
set_property IOB              TRUE        [get_ports RAM_A[16]]
set_property IOB              TRUE        [get_ports RAM_A[15]]
set_property IOB              TRUE        [get_ports RAM_A[14]]
set_property IOB              TRUE        [get_ports RAM_A[13]]
set_property IOB              TRUE        [get_ports RAM_A[12]]
set_property IOB              TRUE        [get_ports RAM_A[11]]
set_property IOB              TRUE        [get_ports RAM_A[10]]
set_property IOB              TRUE        [get_ports RAM_A[9]]
set_property IOB              TRUE        [get_ports RAM_A[8]]
set_property IOB              TRUE        [get_ports RAM_A[7]]
set_property IOB              TRUE        [get_ports RAM_A[6]]
set_property IOB              TRUE        [get_ports RAM_A[5]]
set_property IOB              TRUE        [get_ports RAM_A[4]]
set_property IOB              TRUE        [get_ports RAM_A[3]]
set_property IOB              TRUE        [get_ports RAM_A[2]]
set_property IOB              TRUE        [get_ports RAM_A[1]]
set_property IOB              TRUE        [get_ports RAM_A[0]]

# These pins tied low in FPGA
set_property DRIVE            4           [get_ports RAM_BWn*]
set_property IOSTANDARD       LVCMOS25    [get_ports RAM_BW*]
set_property PACKAGE_PIN      D14         [get_ports RAM_BWn[3]]
set_property PACKAGE_PIN      B16         [get_ports RAM_BWn[2]]
set_property PACKAGE_PIN      A16         [get_ports RAM_BWn[1]]
set_property PACKAGE_PIN      B15         [get_ports RAM_BWn[0]]

# These pins tied low in FPGA
set_property DRIVE            4           [get_ports RAM_ZZ]
set_property PACKAGE_PIN      J19         [get_ports RAM_ZZ]
set_property IOSTANDARD       LVCMOS25    [get_ports RAM_ZZ]

# These pins tied low in FPGA
set_property DRIVE            4           [get_ports RAM_LDn]
set_property PACKAGE_PIN      B13         [get_ports RAM_LDn]
set_property IOSTANDARD       LVCMOS25    [get_ports RAM_LDn]

# These pins tied low in FPGA
set_property DRIVE            4           [get_ports RAM_OEn]
set_property PACKAGE_PIN      A14         [get_ports RAM_OEn]
set_property IOSTANDARD       LVCMOS25    [get_ports RAM_OEn]

set_property DRIVE            8           [get_ports RAM_WEn]
set_property IOB              TRUE        [get_ports RAM_WEn]
set_property PACKAGE_PIN      A15         [get_ports RAM_WEn]
set_property IOSTANDARD       LVCMOS25    [get_ports RAM_WEn]

#  These pins tied low in FPGA
set_property PACKAGE_PIN      C13         [get_ports RAM_CENn]
set_property IOSTANDARD       LVCMOS25    [get_ports RAM_CENn]

set_property DRIVE            8           [get_ports RAM_CE1n]
set_property IOB              TRUE        [get_ports RAM_CE1n]
set_property PACKAGE_PIN      D15         [get_ports RAM_CE1n]
set_property IOSTANDARD       LVCMOS25    [get_ports RAM_CE1n]

# This pins uses ODDR cell...implicitly in IOB
set_property DRIVE            8           [get_ports RAM_CLK]
set_property PACKAGE_PIN      J20         [get_ports RAM_CLK]
set_property IOSTANDARD       LVCMOS25    [get_ports RAM_CLK]
