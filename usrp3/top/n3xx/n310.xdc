

## GPIO : ###############################################################################
## Bank 12, 2.5V LVCMOS
#########################################################################################

#set_property PACKAGE_PIN   AF25             [get_ports {FpgaGpio[0]}]
#set_property PACKAGE_PIN   AE25             [get_ports {FpgaGpio[1]}]
#set_property PACKAGE_PIN   AG26             [get_ports {FpgaGpio[2]}]
#set_property PACKAGE_PIN   AG27             [get_ports {FpgaGpio[3]}]
#set_property PACKAGE_PIN   AE26             [get_ports {FpgaGpio[4]}]
#set_property PACKAGE_PIN   AD28             [get_ports {FpgaGpio[5]}]
#set_property PACKAGE_PIN   AF27             [get_ports {FpgaGpio[6]}]
#set_property PACKAGE_PIN   AA27             [get_ports {FpgaGpio[7]}]
#set_property PACKAGE_PIN   AE27             [get_ports {FpgaGpio[8]}]
#set_property PACKAGE_PIN   AC26             [get_ports {FpgaGpio[9]}]
#set_property PACKAGE_PIN   AD25             [get_ports {FpgaGpio[10]}]
#set_property PACKAGE_PIN   AD26             [get_ports {FpgaGpio[11]}]
#
#set_property PACKAGE_PIN   Y27              [get_ports {FpgaGpioEn}]
#
#set_property IOSTANDARD    LVCMOS25         [get_ports {FpgaGpio[*]}]
#set_property IOSTANDARD    LVCMOS25         [get_ports {FpgaGpioEn}]


## Clocking : ###########################################################################
## Bank 13, 3.3V
#########################################################################################

# External 100 Ohm termination already in place!
set_property PACKAGE_PIN   U26              [get_ports FPGA_REFCLK]
set_property IOSTANDARD    LVCMOS33         [get_ports FPGA_REFCLK]
#
set_property PACKAGE_PIN   AA18             [get_ports {REF_1PPS_IN}]
set_property IOSTANDARD    LVCMOS33         [get_ports {REF_1PPS_IN}]
#
set_property PACKAGE_PIN   AB19             [get_ports {REF_1PPS_IN_MGMT}]
set_property IOSTANDARD    LVCMOS33         [get_ports {REF_1PPS_IN_MGMT}]
#
set_property PACKAGE_PIN   AA19             [get_ports {REF_1PPS_OUT}]
set_property IOSTANDARD    LVCMOS33         [get_ports {REF_1PPS_OUT}]

#set_property PACKAGE_PIN   N26              [get_ports {CLK_MAINREF_SEL[0]}]
#set_property PACKAGE_PIN   N27              [get_ports {CLK_MAINREF_SEL[1]}]
#set_property IOSTANDARD    LVCMOS33         [get_ports {CLK_MAINREF_SEL[*]}]
#
set_property PACKAGE_PIN   R21              [get_ports {PWREN_CLK_DDR100MHZ}]
set_property IOSTANDARD    LVCMOS33         [get_ports {PWREN_CLK_DDR100MHZ}]


## GPS : ################################################################################
## Bank 13, 3.3V
#########################################################################################

set_property PACKAGE_PIN   W28              [get_ports {GPS_1PPS}]
set_property IOSTANDARD    LVCMOS33         [get_ports {GPS_1PPS}]
#
#set_property PACKAGE_PIN   U25              [get_ports {GPS_1PPS_RAW}]
#set_property IOSTANDARD    LVCMOS33         [get_ports {GPS_1PPS_RAW}]
#
#set_property PACKAGE_PIN   R28              [get_ports {GPS_ALARM}]
#set_property IOSTANDARD    LVCMOS33         [get_ports {GPS_ALARM}]
#
#set_property PACKAGE_PIN   P29              [get_ports {GPS_LOCKOK}]
#set_property IOSTANDARD    LVCMOS33         [get_ports {GPS_LOCKOK}]
#
#set_property PACKAGE_PIN   V27              [get_ports {GPS_NINITSURV}]
#set_property IOSTANDARD    LVCMOS33         [get_ports {GPS_NINITSURV}]
#
#set_property PACKAGE_PIN   T22              [get_ports {GPS_NMOBILE}]
#set_property IOSTANDARD    LVCMOS33         [get_ports {GPS_NMOBILE}]
#
#set_property PACKAGE_PIN   T28              [get_ports {GPS_NRESET}]
#set_property IOSTANDARD    LVCMOS33         [get_ports {GPS_NRESET}]
#
#set_property PACKAGE_PIN   V28              [get_ports {GPS_PHASELOCK}]
#set_property IOSTANDARD    LVCMOS33         [get_ports {GPS_PHASELOCK}]
#
#set_property PACKAGE_PIN   P30              [get_ports {GPS_SURVEY}]
#set_property IOSTANDARD    LVCMOS33         [get_ports {GPS_SURVEY}]
#
#set_property PACKAGE_PIN   N29              [get_ports {GPS_WARMUP}]
#set_property IOSTANDARD    LVCMOS33         [get_ports {GPS_WARMUP}]


## NanoPitch Interface : ################################################################
##
#########################################################################################

## MGTs, Bank 110

#set_property PACKAGE_PIN   AD6              [get_ports {NPIO_0_RX0_P}]
#set_property PACKAGE_PIN   AD5              [get_ports {NPIO_0_RX0_N}]
#set_property PACKAGE_PIN   AF6              [get_ports {NPIO_0_RX1_P}]
#set_property PACKAGE_PIN   AF5              [get_ports {NPIO_0_RX1_N}]
#set_property PACKAGE_PIN   AD2              [get_ports {NPIO_0_TX0_P}]
#set_property PACKAGE_PIN   AD1              [get_ports {NPIO_0_TX0_N}]
#set_property PACKAGE_PIN   AE4              [get_ports {NPIO_0_TX1_P}]
#set_property PACKAGE_PIN   AE3              [get_ports {NPIO_0_TX1_N}]
#
#set_property PACKAGE_PIN   AG4              [get_ports {NPIO_1_RX0_P}]
#set_property PACKAGE_PIN   AG3              [get_ports {NPIO_1_RX0_N}]
#set_property PACKAGE_PIN   AH6              [get_ports {NPIO_1_RX1_P}]
#set_property PACKAGE_PIN   AH5              [get_ports {NPIO_1_RX1_N}]
#set_property PACKAGE_PIN   AF2              [get_ports {NPIO_1_TX0_P}]
#set_property PACKAGE_PIN   AF1              [get_ports {NPIO_1_TX0_N}]
#set_property PACKAGE_PIN   AH2              [get_ports {NPIO_1_TX1_P}]
#set_property PACKAGE_PIN   AH1              [get_ports {NPIO_1_TX1_N}]
#
### MGTs, Bank 109
#
#set_property PACKAGE_PIN   AE8              [get_ports {NPIO_2_RX0_P}]
#set_property PACKAGE_PIN   AE7              [get_ports {NPIO_2_RX0_N}]
#set_property PACKAGE_PIN   AG8              [get_ports {NPIO_2_RX1_P}]
#set_property PACKAGE_PIN   AG7              [get_ports {NPIO_2_RX1_N}]
#set_property PACKAGE_PIN   AK2              [get_ports {NPIO_2_TX0_P}]
#set_property PACKAGE_PIN   AK1              [get_ports {NPIO_2_TX0_N}]
#set_property PACKAGE_PIN   AJ4              [get_ports {NPIO_2_TX1_P}]
#set_property PACKAGE_PIN   AJ3              [get_ports {NPIO_2_TX1_N}]

#TODO: Uncomment when connected in top
## Sync Lines, Bank 12, 2.5V

#set_property PACKAGE_PIN   AK30             [get_ports {NPIO_0_RXSYNC_0_P}]
#set_property PACKAGE_PIN   AJ30             [get_ports {NPIO_0_RXSYNC_0_N}]
#set_property PACKAGE_PIN   AJ28             [get_ports {NPIO_0_RXSYNC_1_P}]
#set_property PACKAGE_PIN   AJ29             [get_ports {NPIO_0_RXSYNC_1_N}]
#
#set_property PACKAGE_PIN   AK26             [get_ports {NPIO_0_TXSYNC_0_P}]
#set_property PACKAGE_PIN   AJ26             [get_ports {NPIO_0_TXSYNC_0_N}]
#set_property PACKAGE_PIN   AK28             [get_ports {NPIO_0_TXSYNC_1_P}]
#set_property PACKAGE_PIN   AK27             [get_ports {NPIO_0_TXSYNC_1_N}]
#
#set_property PACKAGE_PIN   AC27             [get_ports {NPIO_1_RXSYNC_0_P}]
#set_property PACKAGE_PIN   AB27             [get_ports {NPIO_1_RXSYNC_0_N}]
#set_property PACKAGE_PIN   AF28             [get_ports {NPIO_1_RXSYNC_1_P}]
#set_property PACKAGE_PIN   AE28             [get_ports {NPIO_1_RXSYNC_1_N}]
#
#set_property PACKAGE_PIN   AH27             [get_ports {NPIO_1_TXSYNC_0_P}]
#set_property PACKAGE_PIN   AH26             [get_ports {NPIO_1_TXSYNC_0_N}]
#set_property PACKAGE_PIN   AF29             [get_ports {NPIO_1_TXSYNC_1_P}]
#set_property PACKAGE_PIN   AG29             [get_ports {NPIO_1_TXSYNC_1_N}]
#
#set_property PACKAGE_PIN   AD29             [get_ports {NPIO_2_RXSYNC_0_P}]
#set_property PACKAGE_PIN   AC29             [get_ports {NPIO_2_RXSYNC_0_N}]
#set_property PACKAGE_PIN   AE30             [get_ports {NPIO_2_RXSYNC_1_P}]
#set_property PACKAGE_PIN   AD30             [get_ports {NPIO_2_RXSYNC_1_N}]
#
#set_property PACKAGE_PIN   AH29             [get_ports {NPIO_2_TXSYNC_0_P}]
#set_property PACKAGE_PIN   AH28             [get_ports {NPIO_2_TXSYNC_0_N}]
#set_property PACKAGE_PIN   AF30             [get_ports {NPIO_2_TXSYNC_1_P}]
#set_property PACKAGE_PIN   AG30             [get_ports {NPIO_2_TXSYNC_1_N}]
#
#set_property IOSTANDARD    LVDS_25          [get_ports {NPIO_*_*XSYNC_*_*}]
#set_property DIFF_TERM     TRUE             [get_ports {NPIO_*_*XSYNC_*_*}]


## Misc : ###############################################################################
##
#########################################################################################

#set_property PACKAGE_PIN   AC28             [get_ports {ENET0_CLK125}]
#set_property IOSTANDARD    LVCMOS25         [get_ports {ENET0_CLK125}]
#
#set_property PACKAGE_PIN   T30              [get_ports {ENET0_LED1A}]
#set_property IOSTANDARD    LVCMOS33         [get_ports {ENET0_LED1A}]
#
#set_property PACKAGE_PIN   T29              [get_ports {ENET0_LED1B}]
#set_property IOSTANDARD    LVCMOS33         [get_ports {ENET0_LED1B}]
#
#set_property PACKAGE_PIN   AB25             [get_ports {ENET0_PTP}]
#set_property IOSTANDARD    LVCMOS25         [get_ports {ENET0_PTP}]
#
#set_property PACKAGE_PIN   AA25             [get_ports {ENET0_PTP_DIR}]
#set_property IOSTANDARD    LVCMOS25         [get_ports {ENET0_PTP_DIR}]
#
#set_property PACKAGE_PIN   R25              [get_ports {ATSHA204_SDA}]
#set_property IOSTANDARD    LVCMOS33         [get_ports {ATSHA204_SDA}]
#
set_property PACKAGE_PIN   R30              [get_ports {FPGA_PL_RESETN}]
set_property IOSTANDARD    LVCMOS33         [get_ports {FPGA_PL_RESETN}]
#
set_property PACKAGE_PIN   AA30             [get_ports {PWREN_CLK_MAINREF}]
set_property IOSTANDARD    LVCMOS25         [get_ports {PWREN_CLK_MAINREF}]
#
#set_property PACKAGE_PIN   AD19             [get_ports {FPGA_TEST[0]}]
#set_property IOSTANDARD    LVCMOS33         [get_ports {FPGA_TEST[0]}]
#set_property PACKAGE_PIN   AB26             [get_ports {FPGA_TEST[1]}]
#set_property IOSTANDARD    LVCMOS25         [get_ports {FPGA_TEST[1]}]


## White Rabbit : #######################################################################
##
#########################################################################################

#set_property PACKAGE_PIN   AD18             [get_ports {WB_20MHZ_CLK}]
#set_property IOSTANDARD    LVCMOS33         [get_ports {WB_20MHZ_CLK}]
#
set_property PACKAGE_PIN   W24              [get_ports {PWREN_CLK_WB_CDCM}]
set_property IOSTANDARD    LVCMOS33         [get_ports {PWREN_CLK_WB_CDCM}]

set_property PACKAGE_PIN   V23              [get_ports {WB_CDCM_OD0}]
set_property IOSTANDARD    LVCMOS33         [get_ports {WB_CDCM_OD0}]

set_property PACKAGE_PIN   T25              [get_ports {WB_CDCM_OD1}]
set_property IOSTANDARD    LVCMOS33         [get_ports {WB_CDCM_OD1}]

set_property PACKAGE_PIN   R26              [get_ports {WB_CDCM_OD2}]
set_property IOSTANDARD    LVCMOS33         [get_ports {WB_CDCM_OD2}]

set_property PACKAGE_PIN   P25              [get_ports {WB_CDCM_PR0}]
set_property IOSTANDARD    LVCMOS33         [get_ports {WB_CDCM_PR0}]

set_property PACKAGE_PIN   P26              [get_ports {WB_CDCM_PR1}]
set_property IOSTANDARD    LVCMOS33         [get_ports {WB_CDCM_PR1}]

set_property PACKAGE_PIN   V24              [get_ports {WB_CDCM_RESETN}]
set_property IOSTANDARD    LVCMOS33         [get_ports {WB_CDCM_RESETN}]

#set_property PACKAGE_PIN   Y28              [get_ports {WB_DAC_DIN}]
#set_property PACKAGE_PIN   AA28             [get_ports {WB_DAC_NCLR}]
#set_property PACKAGE_PIN   Y30              [get_ports {WB_DAC_NLDAC}]
#set_property PACKAGE_PIN   Y26              [get_ports {WB_DAC_NSYNC}]
#set_property PACKAGE_PIN   AB29             [get_ports {WB_DAC_SCLK}]
#set_property IOSTANDARD    LVCMOS25         [get_ports {WB_DAC_*}]
#
#set_property PACKAGE_PIN   AB30             [get_ports {PWREN_CLK_WB_20MHZ}]
#set_property IOSTANDARD    LVCMOS25         [get_ports {PWREN_CLK_WB_20MHZ}]
#
set_property PACKAGE_PIN   AA29             [get_ports {PWREN_CLK_WB_25MHZ}]
set_property IOSTANDARD    LVCMOS25         [get_ports {PWREN_CLK_WB_25MHZ}]


## Blink Lights : #######################################################################
##
#########################################################################################

set_property PACKAGE_PIN   U30              [get_ports {PANEL_LED_GPS}]
set_property IOSTANDARD    LVCMOS33         [get_ports {PANEL_LED_GPS}]

set_property PACKAGE_PIN   U29              [get_ports {PANEL_LED_LINK}]
set_property IOSTANDARD    LVCMOS33         [get_ports {PANEL_LED_LINK}]

set_property PACKAGE_PIN   W29              [get_ports {PANEL_LED_PPS}]
set_property IOSTANDARD    LVCMOS33         [get_ports {PANEL_LED_PPS}]

set_property PACKAGE_PIN   V29              [get_ports {PANEL_LED_REF}]
set_property IOSTANDARD    LVCMOS33         [get_ports {PANEL_LED_REF}]


## SFP+ : ###############################################################################
##
#########################################################################################

## Clocks, Enable = Bank 13 3.3V

#set_property PACKAGE_PIN   AC8              [get_ports {WB_CDCM_CLK1_P}]
#set_property PACKAGE_PIN   AC7              [get_ports {WB_CDCM_CLK1_N}]

set_property PACKAGE_PIN   V22              [get_ports {PWREN_CLK_MGT156MHZ}]
set_property IOSTANDARD    LVCMOS33         [get_ports {PWREN_CLK_MGT156MHZ}]

## MGTs, Bank 109

set_property PACKAGE_PIN   AH10             [get_ports {SFP_0_RX_P}]
set_property PACKAGE_PIN   AH9              [get_ports {SFP_0_RX_N}]
set_property PACKAGE_PIN   AK10             [get_ports {SFP_0_TX_P}]
set_property PACKAGE_PIN   AK9              [get_ports {SFP_0_TX_N}]

set_property PACKAGE_PIN   AJ8              [get_ports {SFP_1_RX_P}]
set_property PACKAGE_PIN   AJ7              [get_ports {SFP_1_RX_N}]
set_property PACKAGE_PIN   AK6              [get_ports {SFP_1_TX_P}]
set_property PACKAGE_PIN   AK5              [get_ports {SFP_1_TX_N}]

## SFP+ 0, Slow Speed, Bank 13 3.3V

#set_property PACKAGE_PIN   R27              [get_ports {SFP_0_I2C_NPRESENT}]
#set_property IOSTANDARD    LVCMOS33         [get_ports {SFP_0_I2C_NPRESENT}]
#
set_property PACKAGE_PIN   V26              [get_ports {SFP_0_LED_A}]
set_property IOSTANDARD    LVCMOS33         [get_ports {SFP_0_LED_A}]

set_property PACKAGE_PIN   W25              [get_ports {SFP_0_LED_B}]
set_property IOSTANDARD    LVCMOS33         [get_ports {SFP_0_LED_B}]
#
set_property PACKAGE_PIN   P28              [get_ports {SFP_0_LOS}]
set_property IOSTANDARD    LVCMOS33         [get_ports {SFP_0_LOS}]
#
set_property PACKAGE_PIN   N28              [get_ports {SFP_0_RS0}]
set_property IOSTANDARD    LVCMOS33         [get_ports {SFP_0_RS0}]

set_property PACKAGE_PIN   W30              [get_ports {SFP_0_RS1}]
set_property IOSTANDARD    LVCMOS33         [get_ports {SFP_0_RS1}]

set_property PACKAGE_PIN T27 [get_ports SFP_0_TXDISABLE]
set_property IOSTANDARD LVCMOS33 [get_ports SFP_0_TXDISABLE]

set_property PACKAGE_PIN   U24              [get_ports {SFP_0_TXFAULT}]
set_property IOSTANDARD    LVCMOS33         [get_ports {SFP_0_TXFAULT}]
#
### SFP+ 1, Slow Speed, Bank 13 3.3V
#
#set_property PACKAGE_PIN   T23              [get_ports {SFP_1_I2C_NPRESENT}]
#set_property IOSTANDARD    LVCMOS33         [get_ports {SFP_1_I2C_NPRESENT}]
#
set_property PACKAGE_PIN   P23              [get_ports {SFP_1_LED_A}]
set_property IOSTANDARD    LVCMOS33         [get_ports {SFP_1_LED_A}]

set_property PACKAGE_PIN   P21              [get_ports {SFP_1_LED_B}]
set_property IOSTANDARD    LVCMOS33         [get_ports {SFP_1_LED_B}]

#
set_property PACKAGE_PIN   T24              [get_ports {SFP_1_RS0}]
set_property IOSTANDARD    LVCMOS33         [get_ports {SFP_1_RS0}]
set_property PACKAGE_PIN   R23              [get_ports {SFP_1_LOS}]
set_property IOSTANDARD    LVCMOS33         [get_ports {SFP_1_LOS}]

set_property PACKAGE_PIN   P24              [get_ports {SFP_1_RS1}]
set_property IOSTANDARD    LVCMOS33         [get_ports {SFP_1_RS1}]

set_property PACKAGE_PIN   U22              [get_ports {SFP_1_TXDISABLE}]
set_property IOSTANDARD    LVCMOS33         [get_ports {SFP_1_TXDISABLE}]

#set_property PACKAGE_PIN   V21              [get_ports {SFP_1_TXFAULT}]
#set_property IOSTANDARD    LVCMOS33         [get_ports {SFP_1_TXFAULT}]
set_property PACKAGE_PIN   V21              [get_ports {SFP_1_TXFAULT}]
set_property IOSTANDARD    LVCMOS33         [get_ports {SFP_1_TXFAULT}]
#

## USRP IO A : ##########################################################################
##
#########################################################################################

### HP GPIO, Bank 33, 1.8V
#
set_property PACKAGE_PIN   G1               [get_ports {DBA_CPLD_RESET_N}]
set_property IOSTANDARD    LVCMOS18         [get_ports {DBA_CPLD_RESET_N}]

set_property PACKAGE_PIN   H2               [get_ports {DBA_CPLD_ADDR[0]}]
#set_property PACKAGE_PIN   D1               [get_ports {DbaCh1TxDsaData[5]}]
#set_property PACKAGE_PIN   E1               [get_ports {DbaCh1TxDsaLe}]
set_property PACKAGE_PIN   H1               [get_ports {DBA_CPLD_ADDR[2]}]
set_property PACKAGE_PIN   J1               [get_ports {DBA_CPLD_ADDR[1]}]
#set_property PACKAGE_PIN   A5               [get_ports {DbaCh1TxDsaData[3]}]
#set_property PACKAGE_PIN   A4               [get_ports {DbaCh1TxDsaData[4]}]
set_property PACKAGE_PIN   F5               [get_ports {DBA_CPLD_SPI_SDO}]
set_property PACKAGE_PIN   E5               [get_ports {DBA_CPLD_SEL_ATR_SPI_N}]
set_property IOSTANDARD    LVCMOS18         [get_ports {DBA_CPLD_SEL_ATR_SPI_N}]

#set_property PACKAGE_PIN   E3               [get_ports {DbaCh1RxDsaData[0]}]
#set_property PACKAGE_PIN   E2               [get_ports {DbaCh1RxDsaData[1]}]
#set_property PACKAGE_PIN   A3               [get_ports {DbaCh1TxDsaData[2]}]
#set_property PACKAGE_PIN   A2               [get_ports {DbaCh1TxDsaData[1]}]

set_property PACKAGE_PIN   K1               [get_ports {DBA_CPLD_SYNC_ATR_RX1}]
set_property IOSTANDARD    LVCMOS18         [get_ports {DBA_CPLD_SYNC_ATR_RX1}]

set_property PACKAGE_PIN   L1               [get_ports {DBA_CPLD_SPI_SDI_ATR_TX2}]
#set_property PACKAGE_PIN   C4               [get_ports {DbaCh1TxDsaData[0]}]
#set_property PACKAGE_PIN   C3               [get_ports {DbaCh1RxDsaData[5]}]
set_property PACKAGE_PIN   F4               [get_ports {DBA_CPLD_SPI_CSB_ATR_TX1}]
set_property PACKAGE_PIN   F3               [get_ports {DBA_CPLD_SPI_SCLK_ATR_RX2}]
#set_property PACKAGE_PIN   B1               [get_ports {DbaCh1RxDsaLe}]
#set_property PACKAGE_PIN   B2               [get_ports {DbaCh1RxDsaData[3]}]
#set_property PACKAGE_PIN   C1               [get_ports {DbaCh1RxDsaData[4]}]
#set_property PACKAGE_PIN   C2               [get_ports {DbaCh1RxDsaData[2]}]

set_property IOSTANDARD    LVCMOS18         [get_ports {DBA_CPLD_ADDR[*]}]
set_property IOSTANDARD    LVCMOS18         [get_ports {DBA_CH1*xDsa*[*]}]
set_property IOSTANDARD    LVCMOS18         [get_ports {DBA_CPLD_SPI_*}]

## HR GPIO, Bank 10, 2.5V

#set_property PACKAGE_PIN   AG12             [get_ports {DbaMykSyncIn_p}]
#set_property PACKAGE_PIN   AH12             [get_ports {DbaMykSyncIn_n}]
set_property PACKAGE_PIN   AJ13             [get_ports {DBA_MYK_SPI_SDO}]
set_property PACKAGE_PIN   AJ14             [get_ports {DBA_MYK_SPI_SDIO}]
#set_property PACKAGE_PIN   AG15             [get_ports {DbaCh2TxDsaLe}]
#set_property PACKAGE_PIN   AF15             [get_ports {DbaCh2TxDsaData[5]}]
set_property PACKAGE_PIN   AH13             [get_ports {DBA_CPLD_JTAG_TDI}]
set_property PACKAGE_PIN   AH14             [get_ports {DBA_CPLD_JTAG_TDO}]
#set_property PACKAGE_PIN   AK15             [get_ports {DbaMykGpio1}]
#set_property PACKAGE_PIN   AJ15             [get_ports {DbaMykGpio4}]
#set_property PACKAGE_PIN   AH16             [get_ports {DbaCh2TxDsaData[4]}]
#set_property PACKAGE_PIN   AH17             [get_ports {DbaCh2TxDsaData[3]}]
#set_property PACKAGE_PIN   AE12             [get_ports {DbaMykSyncOut_p}]
#set_property PACKAGE_PIN   AF12             [get_ports {DbaMykSyncOut_n}]
#set_property PACKAGE_PIN   AK12             [get_ports {DbaMykGpio13}]
#set_property PACKAGE_PIN   AK13             [get_ports {DbaMykGpio0}]
#set_property PACKAGE_PIN   AK16             [get_ports {DbaMykIntrq}]
#set_property PACKAGE_PIN   AJ16             [get_ports {DbaCh2TxDsaData[2]}]
#set_property PACKAGE_PIN   AH18             [get_ports {DbaCh2TxDsaData[0]}]
#set_property PACKAGE_PIN   AJ18             [get_ports {DbaCh2TxDsaData[1]}]
set_property PACKAGE_PIN   AF14             [get_ports {DbaFpgaClk_p}]
set_property PACKAGE_PIN   AG14             [get_ports {DbaFpgaClk_n}]
#set_property PACKAGE_PIN   AG17             [get_ports {DbaFpgaSysref_p}]
#set_property PACKAGE_PIN   AG16             [get_ports {DbaFpgaSysref_n}]
#set_property PACKAGE_PIN   AD15             [get_ports {DbaCh2RxDsaData[3]}]
#set_property PACKAGE_PIN   AD16             [get_ports {DbaCh2RxDsaData[5]}]
set_property PACKAGE_PIN   AE13             [get_ports {DBA_CPLD_JTAG_TMS}]
set_property PACKAGE_PIN   AF13             [get_ports {DBA_CPLD_JTAG_TCK}]
#set_property PACKAGE_PIN   AE15             [get_ports {DbaMykGpio15}]
set_property PACKAGE_PIN   AE16             [get_ports {DBA_MYK_SPI_CS_N}]
#set_property PACKAGE_PIN   AF17             [get_ports {DbaCh2RxDsaData[1]}]
#set_property PACKAGE_PIN   AF18             [get_ports {DbaCh2RxDsaData[2]}]
#set_property PACKAGE_PIN   AC16             [get_ports {DbaPDacSync_n}]
#set_property PACKAGE_PIN   AC17             [get_ports {DbaPDacDin}]
#set_property PACKAGE_PIN   AD13             [get_ports {DbaMykGpio12}]
#set_property PACKAGE_PIN   AD14             [get_ports {DbaMykGpio14}]
set_property PACKAGE_PIN   AE17             [get_ports {DBA_MYK_SPI_SCLK}]
#set_property PACKAGE_PIN   AE18             [get_ports {DbaMykGpio3}]
#set_property PACKAGE_PIN   AB12             [get_ports {DbaCh2RxDsaData[0]}]
#set_property PACKAGE_PIN   AC12             [get_ports {DbaCh2RxDsaData[4]}]
#set_property PACKAGE_PIN   AC13             [get_ports {DbaCh2RxDsaLe}]
#set_property PACKAGE_PIN   AC14             [get_ports {DbaPDacSclk}]

set_property IOSTANDARD    LVCMOS25         [get_ports {DBA_CPLD_JTAG*}]
set_property IOSTANDARD    LVCMOS25         [get_ports {DBA_MYK_SPI_*}]

#set UsrpIoAHrPinsDiff [get_ports {DbaMykSyncIn_* DbaMykSyncOut_* DbaFpgaClk_* DbaFpgaSysref_*}]
#set_property IOSTANDARD    LVDS_25          $UsrpIoAHrPinsDiff


#set_property PACKAGE_PIN   AD20             [get_ports {DbaSwitcherClock}]
#set_property IOSTANDARD    LVCMOS33         [get_ports {DbaSwitcherClock}]

### MGTs, Bank 112
#
set_property PACKAGE_PIN   N8               [get_ports USRPIO_A_MGTCLK_P]
set_property PACKAGE_PIN   N7               [get_ports USRPIO_A_MGTCLK_N]
#
#set_property PACKAGE_PIN   P6               [get_ports USRPIO_A_RX_0_P]
#set_property PACKAGE_PIN   P5               [get_ports USRPIO_A_RX_0_N]
#set_property PACKAGE_PIN   T6               [get_ports USRPIO_A_RX_1_P]
#set_property PACKAGE_PIN   T5               [get_ports USRPIO_A_RX_1_N]
#set_property PACKAGE_PIN   V6               [get_ports USRPIO_A_RX_2_P]
#set_property PACKAGE_PIN   V5               [get_ports USRPIO_A_RX_2_N]
#set_property PACKAGE_PIN   U4               [get_ports USRPIO_A_RX_3_P]
#set_property PACKAGE_PIN   U3               [get_ports USRPIO_A_RX_3_N]
#set_property PACKAGE_PIN   T2               [get_ports {USRPIO_A_TX_0_P}]
#set_property PACKAGE_PIN   T1               [get_ports {USRPIO_A_TX_0_N}]
#set_property PACKAGE_PIN   R4               [get_ports {USRPIO_A_TX_1_P}]
#set_property PACKAGE_PIN   R3               [get_ports {USRPIO_A_TX_1_N}]
#set_property PACKAGE_PIN   P2               [get_ports {USRPIO_A_TX_2_P}]
#set_property PACKAGE_PIN   P1               [get_ports {USRPIO_A_TX_2_N}]
#set_property PACKAGE_PIN   N4               [get_ports {USRPIO_A_TX_3_P}]
#set_property PACKAGE_PIN   N3               [get_ports {USRPIO_A_TX_3_N}]
#
#
### USRP IO B : ##########################################################################
###
##########################################################################################
#
### HP GPIO, Bank 33, 1.8V
#
#set_property PACKAGE_PIN   J4               [get_ports USRPIO_B_GP_0_P]
#set_property PACKAGE_PIN   J3               [get_ports USRPIO_B_GP_0_N]
#set_property PACKAGE_PIN   D4               [get_ports USRPIO_B_GP_1_P]
#set_property PACKAGE_PIN   D3               [get_ports USRPIO_B_GP_1_N]
#set_property PACKAGE_PIN   K2               [get_ports USRPIO_B_GP_2_P]
#set_property PACKAGE_PIN   K3               [get_ports USRPIO_B_GP_2_N]
#set_property PACKAGE_PIN   B5               [get_ports USRPIO_B_GP_3_P]
#set_property PACKAGE_PIN   B4               [get_ports USRPIO_B_GP_3_N]
## Clk
#set_property PACKAGE_PIN   G5               [get_ports USRPIO_B_GP_4_P]
#set_property PACKAGE_PIN   G4               [get_ports USRPIO_B_GP_4_N]
#set_property PACKAGE_PIN   J5               [get_ports USRPIO_B_GP_5_P]
#set_property PACKAGE_PIN   K5               [get_ports USRPIO_B_GP_5_N]
#set_property PACKAGE_PIN   D5               [get_ports USRPIO_B_GP_6_P]
#set_property PACKAGE_PIN   E6               [get_ports USRPIO_B_GP_6_N]
#set_property PACKAGE_PIN   L3               [get_ports USRPIO_B_GP_7_P]
#set_property PACKAGE_PIN   L2               [get_ports USRPIO_B_GP_7_N]
#set_property PACKAGE_PIN   G6               [get_ports USRPIO_B_GP_8_P]
#set_property PACKAGE_PIN   H6               [get_ports USRPIO_B_GP_8_N]
## SYSREF
#set_property PACKAGE_PIN   H4               [get_ports {USRPIO_B_GP_9_P}]
#set_property PACKAGE_PIN   H3               [get_ports {USRPIO_B_GP_9_N}]
#set_property PACKAGE_PIN   F2               [get_ports {USRPIO_B_GP_10_P}]
#set_property PACKAGE_PIN   G2               [get_ports {USRPIO_B_GP_10_N}]
#set_property PACKAGE_PIN   J6               [get_ports {USRPIO_B_GP_11_P}]
#set_property PACKAGE_PIN   K6               [get_ports {USRPIO_B_GP_11_N}]
#
#set UsrpIoBHpPins [get_ports -regexp -filter {NAME =~ {USRPIO_B_GP_([0-9]|10)_(P|N)}}]
#set_property IOSTANDARD    LVDS             $UsrpIoBHpPins
#set_property DIFF_TERM     TRUE             $UsrpIoBHpPins
#
### HR GPIO, Bank 11, 2.5V
#
#set_property PACKAGE_PIN   AK17             [get_ports USRPIO_B_GP_12_P]
#set_property PACKAGE_PIN   AK18             [get_ports USRPIO_B_GP_12_N]
#set_property PACKAGE_PIN   AK21             [get_ports USRPIO_B_GP_13_P]
#set_property PACKAGE_PIN   AJ21             [get_ports USRPIO_B_GP_13_N]
#set_property PACKAGE_PIN   AF19             [get_ports USRPIO_B_GP_14_P]
#set_property PACKAGE_PIN   AG19             [get_ports USRPIO_B_GP_14_N]
#set_property PACKAGE_PIN   AH19             [get_ports USRPIO_B_GP_15_P]
#set_property PACKAGE_PIN   AJ19             [get_ports USRPIO_B_GP_15_N]
#set_property PACKAGE_PIN   AK22             [get_ports USRPIO_B_GP_16_P]
#set_property PACKAGE_PIN   AK23             [get_ports USRPIO_B_GP_16_N]
#set_property PACKAGE_PIN   AF20             [get_ports USRPIO_B_GP_17_P]
#set_property PACKAGE_PIN   AG20             [get_ports USRPIO_B_GP_17_N]
#set_property PACKAGE_PIN   AF23             [get_ports USRPIO_B_GP_18_P]
#set_property PACKAGE_PIN   AF24             [get_ports USRPIO_B_GP_18_N]
#set_property PACKAGE_PIN   AK20             [get_ports USRPIO_B_GP_19_P]
#set_property PACKAGE_PIN   AJ20             [get_ports USRPIO_B_GP_19_N]
#set_property PACKAGE_PIN   AJ23             [get_ports USRPIO_B_GP_20_P]
#set_property PACKAGE_PIN   AJ24             [get_ports USRPIO_B_GP_20_N]
#set_property PACKAGE_PIN   AG24             [get_ports USRPIO_B_GP_21_P]
#set_property PACKAGE_PIN   AG25             [get_ports USRPIO_B_GP_21_N]
## Clk
#set_property PACKAGE_PIN   AG21             [get_ports USRPIO_B_GP_22_P]
#set_property PACKAGE_PIN   AH21             [get_ports USRPIO_B_GP_22_N]
## Clk
#set_property PACKAGE_PIN   AE22             [get_ports {USRPIO_B_GP_23_P}]
#set_property PACKAGE_PIN   AF22             [get_ports {USRPIO_B_GP_23_N}]
#set_property PACKAGE_PIN   AJ25             [get_ports {USRPIO_B_GP_24_P}]
#set_property PACKAGE_PIN   AK25             [get_ports {USRPIO_B_GP_24_N}]
#set_property PACKAGE_PIN   AB21             [get_ports {USRPIO_B_GP_25_P}]
#set_property PACKAGE_PIN   AB22             [get_ports {USRPIO_B_GP_25_N}]
#set_property PACKAGE_PIN   AD23             [get_ports {USRPIO_B_GP_26_P}]
#set_property PACKAGE_PIN   AE23             [get_ports {USRPIO_B_GP_26_N}]
#set_property PACKAGE_PIN   AB24             [get_ports {USRPIO_B_GP_27_P}]
#set_property PACKAGE_PIN   AA24             [get_ports {USRPIO_B_GP_27_N}]
#set_property PACKAGE_PIN   AG22             [get_ports {USRPIO_B_GP_28_P}]
#set_property PACKAGE_PIN   AH22             [get_ports {USRPIO_B_GP_28_N}]
#set_property PACKAGE_PIN   AD21             [get_ports {USRPIO_B_GP_29_P}]
#set_property PACKAGE_PIN   AE21             [get_ports {USRPIO_B_GP_29_N}]
#set_property PACKAGE_PIN   AC22             [get_ports {USRPIO_B_GP_30_P}]
#set_property PACKAGE_PIN   AC23             [get_ports {USRPIO_B_GP_30_N}]
#set_property PACKAGE_PIN   AC24             [get_ports {USRPIO_B_GP_31_P}]
#set_property PACKAGE_PIN   AD24             [get_ports {USRPIO_B_GP_31_N}]
#set_property PACKAGE_PIN   AH23             [get_ports {USRPIO_B_GP_32_P}]
#set_property PACKAGE_PIN   AH24             [get_ports {USRPIO_B_GP_32_N}]
#
#
#set UsrpIoBHrPinsSe [get_ports -regexp -filter {NAME =~ {USRPIO_B_GP_(1[2-9]|2[0-2]|29|3[0-2])_(P|N)}}]
#set_property IOSTANDARD    LVCMOS25         $UsrpIoBHrPinsSe
#
#set UsrpIoBHrPins   [get_ports -regexp -filter {NAME =~ {USRPIO_B_GP_(2[3-8])_(P|N)}}]
#set_property IOSTANDARD    LVDS_25          $UsrpIoBHrPins
#
#
#set_property PACKAGE_PIN   AE20             [get_ports {USRPIO_B_I2C_NINTRQ}]
#set_property IOSTANDARD    LVCMOS33         [get_ports {USRPIO_B_I2C_NINTRQ}]
#
### MGTs, Bank 111
#
set_property PACKAGE_PIN   W8               [get_ports USRPIO_B_MGTCLK_P]
set_property PACKAGE_PIN   W7               [get_ports USRPIO_B_MGTCLK_N]
#
#set_property PACKAGE_PIN   AA4              [get_ports USRPIO_B_RX_0_P]
#set_property PACKAGE_PIN   AA3              [get_ports USRPIO_B_RX_0_N]
#set_property PACKAGE_PIN   Y6               [get_ports USRPIO_B_RX_1_P]
#set_property PACKAGE_PIN   Y5               [get_ports USRPIO_B_RX_1_N]
#set_property PACKAGE_PIN   AC4              [get_ports USRPIO_B_RX_2_P]
#set_property PACKAGE_PIN   AC3              [get_ports USRPIO_B_RX_2_N]
#set_property PACKAGE_PIN   AB6              [get_ports USRPIO_B_RX_3_P]
#set_property PACKAGE_PIN   AB5              [get_ports USRPIO_B_RX_3_N]
#set_property PACKAGE_PIN   AB2              [get_ports {USRPIO_B_TX_0_P}]
#set_property PACKAGE_PIN   AB1              [get_ports {USRPIO_B_TX_0_N}]
#set_property PACKAGE_PIN   Y2               [get_ports {USRPIO_B_TX_1_P}]
#set_property PACKAGE_PIN   Y1               [get_ports {USRPIO_B_TX_1_N}]
#set_property PACKAGE_PIN   V2               [get_ports {USRPIO_B_TX_2_P}]
#set_property PACKAGE_PIN   V1               [get_ports {USRPIO_B_TX_2_N}]
#set_property PACKAGE_PIN   W4               [get_ports {USRPIO_B_TX_3_P}]
#set_property PACKAGE_PIN   W3               [get_ports {USRPIO_B_TX_3_N}]


## PL DDR : #############################################################################
##
#########################################################################################

# set_property PACKAGE_PIN   D8               [get_ports {PL_DDR_ADDR[0]}]
# set_property PACKAGE_PIN   A7               [get_ports {PL_DDR_ADDR[1]}]
# set_property PACKAGE_PIN   C7               [get_ports {PL_DDR_ADDR[2]}]
# set_property PACKAGE_PIN   D9               [get_ports {PL_DDR_ADDR[3]}]
# set_property PACKAGE_PIN   J9               [get_ports {PL_DDR_ADDR[4]}]
# set_property PACKAGE_PIN   E8               [get_ports {PL_DDR_ADDR[5]}]
# set_property PACKAGE_PIN   G7               [get_ports {PL_DDR_ADDR[6]}]
# set_property PACKAGE_PIN   E7               [get_ports {PL_DDR_ADDR[7]}]
# set_property PACKAGE_PIN   G11              [get_ports {PL_DDR_ADDR[8]}]
# set_property PACKAGE_PIN   C6               [get_ports {PL_DDR_ADDR[9]}]
# set_property PACKAGE_PIN   B6               [get_ports {PL_DDR_ADDR[10]}]
# set_property PACKAGE_PIN   H7               [get_ports {PL_DDR_ADDR[11]}]
# set_property PACKAGE_PIN   B7               [get_ports {PL_DDR_ADDR[12]}]
# set_property PACKAGE_PIN   F7               [get_ports {PL_DDR_ADDR[13]}]
# set_property PACKAGE_PIN   F8               [get_ports {PL_DDR_ADDR[14]}]
# set_property PACKAGE_PIN   F9               [get_ports {PL_DDR_ADDR[15]}]

# set_property PACKAGE_PIN   C9               [get_ports {PL_DDR_BA[0]}]
# set_property PACKAGE_PIN   E10              [get_ports {PL_DDR_BA[1]}]
# set_property PACKAGE_PIN   B9               [get_ports {PL_DDR_BA[2]}]

# set_property PACKAGE_PIN   A10              [get_ports {PL_DDR_CASN}]
# set_property PACKAGE_PIN   E11              [get_ports {PL_DDR_CKE}]
# set_property PACKAGE_PIN   H8               [get_ports {PL_DDR_CK_N}]
# set_property PACKAGE_PIN   J8               [get_ports {PL_DDR_CK_P}]
# set_property PACKAGE_PIN   D11              [get_ports {PL_DDR_CSN}]

# set_property PACKAGE_PIN   B16              [get_ports {PL_DDR_DM0}]
# set_property PACKAGE_PIN   B11              [get_ports {PL_DDR_DM1}]
# set_property PACKAGE_PIN   H13              [get_ports {PL_DDR_DM2}]
# set_property PACKAGE_PIN   G15              [get_ports {PL_DDR_DM3}]

# set_property PACKAGE_PIN   B17              [get_ports {PL_DDR_DQ[0 ]}]
# set_property PACKAGE_PIN   A17              [get_ports {PL_DDR_DQ[1 ]}]
# set_property PACKAGE_PIN   D15              [get_ports {PL_DDR_DQ[2 ]}]
# set_property PACKAGE_PIN   D14              [get_ports {PL_DDR_DQ[3 ]}]
# set_property PACKAGE_PIN   C17              [get_ports {PL_DDR_DQ[4 ]}]
# set_property PACKAGE_PIN   E15              [get_ports {PL_DDR_DQ[5 ]}]
# set_property PACKAGE_PIN   C16              [get_ports {PL_DDR_DQ[6 ]}]
# set_property PACKAGE_PIN   D16              [get_ports {PL_DDR_DQ[7 ]}]
# set_property PACKAGE_PIN   A13              [get_ports {PL_DDR_DQ[8 ]}]
# set_property PACKAGE_PIN   A12              [get_ports {PL_DDR_DQ[9 ]}]
# set_property PACKAGE_PIN   C14              [get_ports {PL_DDR_DQ[10]}]
# set_property PACKAGE_PIN   B12              [get_ports {PL_DDR_DQ[11]}]
# set_property PACKAGE_PIN   B14              [get_ports {PL_DDR_DQ[12]}]
# set_property PACKAGE_PIN   C12              [get_ports {PL_DDR_DQ[13]}]
# set_property PACKAGE_PIN   A14              [get_ports {PL_DDR_DQ[14]}]
# set_property PACKAGE_PIN   C11              [get_ports {PL_DDR_DQ[15]}]
# set_property PACKAGE_PIN   J15              [get_ports {PL_DDR_DQ[16]}]
# set_property PACKAGE_PIN   L14              [get_ports {PL_DDR_DQ[17]}]
# set_property PACKAGE_PIN   L15              [get_ports {PL_DDR_DQ[18]}]
# set_property PACKAGE_PIN   J13              [get_ports {PL_DDR_DQ[19]}]
# set_property PACKAGE_PIN   J14              [get_ports {PL_DDR_DQ[20]}]
# set_property PACKAGE_PIN   K15              [get_ports {PL_DDR_DQ[21]}]
# set_property PACKAGE_PIN   J16              [get_ports {PL_DDR_DQ[22]}]
# set_property PACKAGE_PIN   H14              [get_ports {PL_DDR_DQ[23]}]
# set_property PACKAGE_PIN   F15              [get_ports {PL_DDR_DQ[24]}]
# set_property PACKAGE_PIN   G16              [get_ports {PL_DDR_DQ[25]}]
# set_property PACKAGE_PIN   F14              [get_ports {PL_DDR_DQ[26]}]
# set_property PACKAGE_PIN   E13              [get_ports {PL_DDR_DQ[27]}]
# set_property PACKAGE_PIN   G14              [get_ports {PL_DDR_DQ[28]}]
# set_property PACKAGE_PIN   D13              [get_ports {PL_DDR_DQ[29]}]
# set_property PACKAGE_PIN   F13              [get_ports {PL_DDR_DQ[30]}]
# set_property PACKAGE_PIN   E12              [get_ports {PL_DDR_DQ[31]}]

# set_property PACKAGE_PIN   F17              [get_ports {PL_DDR_DQS0_P}]
# set_property PACKAGE_PIN   E17              [get_ports {PL_DDR_DQS0_N}]
# set_property PACKAGE_PIN   B15              [get_ports {PL_DDR_DQS1_P}]
# set_property PACKAGE_PIN   A15              [get_ports {PL_DDR_DQS1_N}]
# set_property PACKAGE_PIN   L13              [get_ports {PL_DDR_DQS2_P}]
# set_property PACKAGE_PIN   K13              [get_ports {PL_DDR_DQS2_N}]
# set_property PACKAGE_PIN   G12              [get_ports {PL_DDR_DQS3_P}]
# set_property PACKAGE_PIN   F12              [get_ports {PL_DDR_DQS3_N}]

# set_property PACKAGE_PIN   D10              [get_ports {PL_DDR_ODT}]
# set_property PACKAGE_PIN   B10              [get_ports {PL_DDR_RASN}]
# set_property PACKAGE_PIN   D6               [get_ports {PL_DDR_RSTN}]
# set_property PACKAGE_PIN   H9               [get_ports {PL_DDR_SYSCLK_P}]
# set_property PACKAGE_PIN   G9               [get_ports {PL_DDR_SYSCLK_N}]
# set_property PACKAGE_PIN   A9               [get_ports {PL_DDR_WEN}]
