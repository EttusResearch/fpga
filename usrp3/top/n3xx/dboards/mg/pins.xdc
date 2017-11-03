

## GPIO and FPGA_TEST: ###############################################################################
## Bank 12, 3.3V LVCMOS
#########################################################################################

set_property PACKAGE_PIN AF25 [get_ports {FPGA_GPIO[0]}]
set_property PACKAGE_PIN AE25 [get_ports {FPGA_GPIO[1]}]
set_property PACKAGE_PIN AG26 [get_ports {FPGA_GPIO[2]}]
set_property PACKAGE_PIN AG27 [get_ports {FPGA_GPIO[3]}]
set_property PACKAGE_PIN AE26 [get_ports {FPGA_GPIO[4]}]
set_property PACKAGE_PIN AB26 [get_ports {FPGA_GPIO[5]}]
set_property PACKAGE_PIN AF27 [get_ports {FPGA_GPIO[6]}]
set_property PACKAGE_PIN AA27 [get_ports {FPGA_GPIO[7]}]
set_property PACKAGE_PIN AE27 [get_ports {FPGA_GPIO[8]}]
set_property PACKAGE_PIN AC26 [get_ports {FPGA_GPIO[9]}]
set_property PACKAGE_PIN AD25 [get_ports {FPGA_GPIO[10]}]
set_property PACKAGE_PIN AD26 [get_ports {FPGA_GPIO[11]}]

set_property PACKAGE_PIN Y30 [get_ports {FPGA_TEST[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {FPGA_TEST[0]}]
set_property PACKAGE_PIN AA30 [get_ports {FPGA_TEST[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {FPGA_TEST[1]}]


#
set_property IOSTANDARD LVCMOS33 [get_ports {FPGA_GPIO[*]}]


## Clocking : ###########################################################################
## Bank 9, 2.5V
#########################################################################################

set_property PACKAGE_PIN AC18 [get_ports FPGA_REFCLK_N]
set_property PACKAGE_PIN AC19 [get_ports FPGA_REFCLK_P]
set_property IOSTANDARD LVDS_25 [get_ports FPGA_REFCLK_*]
set_property DIFF_TERM TRUE [get_ports FPGA_REFCLK_*]


## Clocking : ###########################################################################
## Bank 13, 3.3V
#########################################################################################

set_property PACKAGE_PIN U24 [get_ports REF_1PPS_IN]
set_property IOSTANDARD LVCMOS33 [get_ports REF_1PPS_IN]

#set_property PACKAGE_PIN   U29              [get_ports {REF_1PPS_IN_MGMT}]
#set_property IOSTANDARD    LVCMOS33         [get_ports {REF_1PPS_IN_MGMT}]

set_property PACKAGE_PIN V29 [get_ports REF_1PPS_OUT]
set_property IOSTANDARD LVCMOS33 [get_ports REF_1PPS_OUT]


## TDC : ################################################################################
## Bank 10, 2.5V
#########################################################################################

set_property PACKAGE_PIN   AB15             [get_ports {UNUSED_PIN_TDCA_0}]
set_property IOSTANDARD    LVCMOS25         [get_ports {UNUSED_PIN_TDCA_0}]
set_property PACKAGE_PIN   AB14             [get_ports {UNUSED_PIN_TDCA_1}]
set_property IOSTANDARD    LVCMOS25         [get_ports {UNUSED_PIN_TDCA_1}]
set_property IOB           TRUE             [get_ports {UNUSED_PIN_TDCA_*}]


## TDC : ################################################################################
## Bank 11, 2.5V
#########################################################################################

set_property PACKAGE_PIN   W21              [get_ports {UNUSED_PIN_TDCB_0}]
set_property IOSTANDARD    LVCMOS25         [get_ports {UNUSED_PIN_TDCB_0}]
set_property PACKAGE_PIN   Y21              [get_ports {UNUSED_PIN_TDCB_1}]
set_property IOSTANDARD    LVCMOS25         [get_ports {UNUSED_PIN_TDCB_1}]
set_property IOB           TRUE             [get_ports {UNUSED_PIN_TDCB_*}]


## GPS : ################################################################################
## Bank 13, 3.3V
#########################################################################################

set_property PACKAGE_PIN W30 [get_ports GPS_1PPS]
set_property IOSTANDARD LVCMOS33 [get_ports GPS_1PPS]
#
#set_property PACKAGE_PIN   V28              [get_ports {GPS_1PPS_RAW}]
#set_property IOSTANDARD    LVCMOS33         [get_ports {GPS_1PPS_RAW}]
#

## NanoPitch Interface : ################################################################
##
#########################################################################################
#set_property PACKAGE_PIN   AD29             [get_ports {NPIO-GPIO0}]
#set_property PACKAGE_PIN   AC29             [get_ports {NPIO-GPIO1}]
#set_property PACKAGE_PIN   AE30             [get_ports {NPIO-GPIO2}]
#set_property PACKAGE_PIN   AD30             [get_ports {NPIO-GPIO3}]
#set_property PACKAGE_PIN   AH29             [get_ports {NPIO-GPIO4}]
#set_property PACKAGE_PIN   AH28             [get_ports {NPIO-GPIO5}]
#set_property PACKAGE_PIN   AF30             [get_ports {NPIO-GPIO6}]
#set_property PACKAGE_PIN   AG30             [get_ports {NPIO-GPIO7}]
#set_property PACKAGE_PIN   AE7              [get_ports {NPIO-RX0_N}]
#set_property PACKAGE_PIN   AE8              [get_ports {NPIO-RX0_P}]
#set_property PACKAGE_PIN   AG7              [get_ports {NPIO-RX1_N}]
#set_property PACKAGE_PIN   AG8              [get_ports {NPIO-RX1_P}]
#set_property PACKAGE_PIN   AK1              [get_ports {NPIO-TX0_N}]
#set_property PACKAGE_PIN   AK2              [get_ports {NPIO-TX0_P}]
#set_property PACKAGE_PIN   AJ3              [get_ports {NPIO-TX1_N}]
#set_property PACKAGE_PIN   AJ4              [get_ports {NPIO-TX1_P}]




## Misc : ###############################################################################
##
#########################################################################################

set_property PACKAGE_PIN U26 [get_ports ENET0_CLK125]
set_property IOSTANDARD LVCMOS33 [get_ports ENET0_CLK125]

#set_property PACKAGE_PIN   R25              [get_ports {ENET0_PTP}]
#set_property IOSTANDARD    LVCMOS33         [get_ports {ENET0_PTP}]
#
#set_property PACKAGE_PIN   R30              [get_ports {ENET0_PTP_DIR}]
#set_property IOSTANDARD    LVCMOS33         [get_ports {ENET0_PTP_DIR}]
#
#set_property PACKAGE_PIN   U30              [get_ports {ATSHA204_SDA}]
#set_property IOSTANDARD    LVCMOS33         [get_ports {ATSHA204_SDA}]
#
set_property PACKAGE_PIN P26 [get_ports FPGA_PL_RESETN]
set_property IOSTANDARD LVCMOS33 [get_ports FPGA_PL_RESETN]

# set_property PACKAGE_PIN   A8               [get_ports {PUDC_N}]
# set_property IOSTANDARD    LVDCI_15         [get_ports {PUDC_N}]

set_property PACKAGE_PIN   AA18             [get_ports {WB_20MHz_P}]
set_property PACKAGE_PIN   AA19             [get_ports {WB_20MHz_N}]
set_property DIFF_TERM TRUE [get_ports WB_20MHz_P]
set_property DIFF_TERM TRUE [get_ports WB_20MHz_N]
set_property IOSTANDARD    LVDS_25         [get_ports {WB_20MHz_*}]

set_property PACKAGE_PIN   AD18             [get_ports NETCLK_REF_P]
set_property PACKAGE_PIN   AD19             [get_ports NETCLK_REF_N]
set_property DIFF_TERM TRUE [get_ports NETCLK_REF_P]
set_property DIFF_TERM TRUE [get_ports NETCLK_REF_N]
set_property IOSTANDARD    LVDS_25         [get_ports NETCLK_REF_*]


## MGMT ports: ########################
#
######################################
#set_property PACKAGE_PIN   AH27             [get_ports {MGMT-GPIO0}]
#set_property PACKAGE_PIN   AH26             [get_ports {MGMT-GPIO1}]
#set_property PACKAGE_PIN   AC27             [get_ports {MGMT-JTAG-TCK}]
#set_property PACKAGE_PIN   AF29             [get_ports {MGMT-JTAG-TDI}]
#set_property PACKAGE_PIN   AG29             [get_ports {MGMT-JTAG-TDO}]
#set_property PACKAGE_PIN   AB27             [get_ports {MGMT-JTAG-TMS}]
#set_property PACKAGE_PIN   Y28              [get_ports {MGMT-SPI-LE}]
#set_property PACKAGE_PIN   AD28             [get_ports {MGMT-SPI-MISO}]
#set_property PACKAGE_PIN   AA28             [get_ports {MGMT-SPI-MOSI}]
#set_property PACKAGE_PIN   AE28             [get_ports {MGMT-SPI-RESET}]
#set_property PACKAGE_PIN   AC28             [get_ports {MGMT-SPI-SCLK}]
#############################################################################
##QSFP: #################################################################
#
##########################################################################
#set_property PACKAGE_PIN   AJ26             [get_ports {QSFP-I2C-SCL}]
#set_property PACKAGE_PIN   AK26             [get_ports {QSFP-I2C-SDA}]
#set_property PACKAGE_PIN   AK28             [get_ports {QSFP-INTL}]
#set_property PACKAGE_PIN   AK30             [get_ports {QSFP-LED}]
#set_property PACKAGE_PIN   AJ29             [get_ports {QSFP-LPMODE}]
#set_property PACKAGE_PIN   AK27             [get_ports {QSFP-MODPRSL}]
#set_property PACKAGE_PIN   AJ28             [get_ports {QSFP-MODSELL}]
#set_property PACKAGE_PIN   AJ30             [get_ports {QSFP-RESETL}]
#set_property PACKAGE_PIN   AD5              [get_ports {QSFP-RX0_N}]
#set_property PACKAGE_PIN   AD6              [get_ports {QSFP-RX0_P}]
#set_property PACKAGE_PIN   AF5              [get_ports {QSFP-RX1_N}]
#set_property PACKAGE_PIN   AF6              [get_ports {QSFP-RX1_P}]
#set_property PACKAGE_PIN   AG3              [get_ports {QSFP-RX2_N}]
#set_property PACKAGE_PIN   AG4              [get_ports {QSFP-RX2_P}]
#set_property PACKAGE_PIN   AH5              [get_ports {QSFP-RX3_N}]
#set_property PACKAGE_PIN   AH6              [get_ports {QSFP-RX3_P}]
#set_property PACKAGE_PIN   AD1              [get_ports {QSFP-TX0_N}]
#set_property PACKAGE_PIN   AD2              [get_ports {QSFP-TX0_P}]
#set_property PACKAGE_PIN   AE3              [get_ports {QSFP-TX1_N}]
#set_property PACKAGE_PIN   AE4              [get_ports {QSFP-TX1_P}]
#set_property PACKAGE_PIN   AF1              [get_ports {QSFP-TX2_N}]
#set_property PACKAGE_PIN   AF2              [get_ports {QSFP-TX2_P}]
#set_property PACKAGE_PIN   AH1              [get_ports {QSFP-TX3_N}]
#set_property PACKAGE_PIN   AH2              [get_ports {QSFP-TX3_P}]

## White Rabbit : #######################################################################
##
#########################################################################################

#set_property PACKAGE_PIN   AA19             [get_ports {WB_20MHZ_N}]
#set_property IOSTANDARD    LVCMOS25         [get_ports {WB_20MHZ_N}]
#
#set_property PACKAGE_PIN   AA18             [get_ports {WB_20MHZ_P}]
#set_property IOSTANDARD    LVCMOS25         [get_ports {WB_20MHZ_P}]
#
#set_property PACKAGE_PIN   T29              [get_ports {WB_DAC_DIN}]
#set_property PACKAGE_PIN   T28              [get_ports {WB_DAC_NCLR}]
#set_property PACKAGE_PIN   T30              [get_ports {WB_DAC_NLDAC}]
#set_property PACKAGE_PIN   N29              [get_ports {WB_DAC_NSYNC}]
#set_property PACKAGE_PIN   P29              [get_ports {WB_DAC_SCLK}]
#set_property IOSTANDARD    LVCMOS33         [get_ports {WB_DAC_*}]


## Blink Lights : #######################################################################
##
#########################################################################################

set_property PACKAGE_PIN U25 [get_ports PANEL_LED_GPS]
set_property IOSTANDARD LVCMOS33 [get_ports PANEL_LED_GPS]

set_property PACKAGE_PIN T25 [get_ports PANEL_LED_LINK]
set_property IOSTANDARD LVCMOS33 [get_ports PANEL_LED_LINK]

set_property PACKAGE_PIN W29 [get_ports PANEL_LED_PPS]
set_property IOSTANDARD LVCMOS33 [get_ports PANEL_LED_PPS]

set_property PACKAGE_PIN V24 [get_ports PANEL_LED_REF]
set_property IOSTANDARD LVCMOS33 [get_ports PANEL_LED_REF]


## SFP+ : ###############################################################################
##
#########################################################################################

## Clocks, Enable = Bank 13 3.3V

#set_property PACKAGE_PIN   AC8              [get_ports {WB_CDCM_CLK1_P}]
#set_property PACKAGE_PIN   AC7              [get_ports {WB_CDCM_CLK1_N}]

## MGTs, Bank 109

set_property PACKAGE_PIN   AH9              [get_ports SFP_0_RX_N]
set_property PACKAGE_PIN   AH10             [get_ports SFP_0_RX_P]
set_property PACKAGE_PIN   AK9              [get_ports SFP_0_TX_N]
set_property PACKAGE_PIN   AK10             [get_ports SFP_0_TX_P]

set_property PACKAGE_PIN   AJ7              [get_ports SFP_1_RX_N]
set_property PACKAGE_PIN   AJ8              [get_ports SFP_1_RX_P]
set_property PACKAGE_PIN   AK5              [get_ports SFP_1_TX_N]
set_property PACKAGE_PIN   AK6              [get_ports SFP_1_TX_P]

## SFP+ 0, Slow Speed, Bank 13 3.3V

#set_property PACKAGE_PIN   V23              [get_ports {SFP_0_I2C_NPRESENT}]
#set_property IOSTANDARD    LVCMOS33         [get_ports {SFP_0_I2C_NPRESENT}]
#
set_property PACKAGE_PIN N26 [get_ports SFP_0_LED_A]
set_property IOSTANDARD LVCMOS33 [get_ports SFP_0_LED_A]

set_property PACKAGE_PIN P30 [get_ports SFP_0_LED_B]
set_property IOSTANDARD LVCMOS33 [get_ports SFP_0_LED_B]

set_property PACKAGE_PIN R28 [get_ports SFP_0_LOS]
set_property IOSTANDARD LVCMOS33 [get_ports SFP_0_LOS]

set_property PACKAGE_PIN T24 [get_ports SFP_0_RS0]
set_property IOSTANDARD LVCMOS33 [get_ports SFP_0_RS0]

set_property PACKAGE_PIN P25 [get_ports SFP_0_RS1]
set_property IOSTANDARD LVCMOS33 [get_ports SFP_0_RS1]

set_property PACKAGE_PIN V27 [get_ports SFP_0_TXDISABLE]
set_property IOSTANDARD LVCMOS33 [get_ports SFP_0_TXDISABLE]

set_property PACKAGE_PIN W24 [get_ports SFP_0_TXFAULT]
set_property IOSTANDARD LVCMOS33 [get_ports SFP_0_TXFAULT]
#
### SFP+ 1, Slow Speed, Bank 13 3.3V
#
#set_property PACKAGE_PIN   T27              [get_ports {SFP_1_I2C_NPRESENT}]
#set_property IOSTANDARD    LVCMOS33         [get_ports {SFP_1_I2C_NPRESENT}]
#
set_property PACKAGE_PIN N27 [get_ports SFP_1_LED_A]
set_property IOSTANDARD LVCMOS33 [get_ports SFP_1_LED_A]

set_property PACKAGE_PIN N28 [get_ports SFP_1_LED_B]
set_property IOSTANDARD LVCMOS33 [get_ports SFP_1_LED_B]

set_property PACKAGE_PIN R26 [get_ports SFP_1_RS0]
set_property IOSTANDARD LVCMOS33 [get_ports SFP_1_RS0]

set_property PACKAGE_PIN R27 [get_ports SFP_1_LOS]
set_property IOSTANDARD LVCMOS33 [get_ports SFP_1_LOS]

set_property PACKAGE_PIN P28 [get_ports SFP_1_RS1]
set_property IOSTANDARD LVCMOS33 [get_ports SFP_1_RS1]

set_property PACKAGE_PIN U27 [get_ports SFP_1_TXDISABLE]
set_property IOSTANDARD LVCMOS33 [get_ports SFP_1_TXDISABLE]

set_property PACKAGE_PIN V26 [get_ports SFP_1_TXFAULT]
set_property IOSTANDARD LVCMOS33 [get_ports SFP_1_TXFAULT]

## USRP IO A : ##########################################################################
##
#########################################################################################

## HP GPIO, Bank 33, 1.8V

set_property PACKAGE_PIN G1 [get_ports DBA_CPLD_PS_SPI_LE]
set_property PACKAGE_PIN H2 [get_ports DBA_CPLD_PS_SPI_SCLK]
set_property PACKAGE_PIN D1 [get_ports {DBA_CH1_TX_DSA_DATA[5]}]
# set_property PACKAGE_PIN   E1               [get_ports {nc}]
set_property PACKAGE_PIN H1 [get_ports {DBA_CPLD_PS_SPI_ADDR[0]}]
set_property PACKAGE_PIN J1 [get_ports {DBA_CPLD_PS_SPI_ADDR[1]}]
set_property PACKAGE_PIN A5 [get_ports {DBA_CH1_TX_DSA_DATA[3]}]
set_property PACKAGE_PIN A4 [get_ports {DBA_CH1_TX_DSA_DATA[4]}]
set_property PACKAGE_PIN F5 [get_ports DBA_CPLD_PS_SPI_SDO]
set_property PACKAGE_PIN E5 [get_ports DBA_CPLD_PS_SPI_SDI]
set_property PACKAGE_PIN E3 [get_ports {DBA_CH1_RX_DSA_DATA[0]}]
set_property PACKAGE_PIN E2 [get_ports {DBA_CH1_RX_DSA_DATA[1]}]
set_property PACKAGE_PIN A3 [get_ports {DBA_CH1_TX_DSA_DATA[2]}]
set_property PACKAGE_PIN A2 [get_ports {DBA_CH1_TX_DSA_DATA[1]}]
set_property PACKAGE_PIN K1 [get_ports DBA_ATR_RX_1]
set_property PACKAGE_PIN L1 [get_ports DBA_ATR_TX_2]
set_property PACKAGE_PIN C4 [get_ports {DBA_CH1_TX_DSA_DATA[0]}]
set_property PACKAGE_PIN C3 [get_ports {DBA_CH1_RX_DSA_DATA[5]}]
set_property PACKAGE_PIN F4 [get_ports DBA_ATR_TX_1]
set_property PACKAGE_PIN F3 [get_ports DBA_ATR_RX_2]
# set_property PACKAGE_PIN   B1               [get_ports {nc}]
set_property PACKAGE_PIN B2 [get_ports {DBA_CH1_RX_DSA_DATA[3]}]
set_property PACKAGE_PIN C1 [get_ports {DBA_CH1_RX_DSA_DATA[4]}]
set_property PACKAGE_PIN C2 [get_ports {DBA_CH1_RX_DSA_DATA[2]}]

## HR GPIO, Bank 10, 2.5V

set_property PACKAGE_PIN AG12 [get_ports DBA_MYK_SYNC_IN_n]
set_property PACKAGE_PIN AH12 [get_ports {DBA_CPLD_PL_SPI_ADDR[0]}]
set_property PACKAGE_PIN AJ13 [get_ports DBA_MYK_SPI_SDO]
set_property PACKAGE_PIN AJ14 [get_ports DBA_MYK_SPI_SDIO]
set_property PACKAGE_PIN AG15 [get_ports {DBA_CPLD_PL_SPI_ADDR[1]}]
set_property PACKAGE_PIN AF15 [get_ports {DBA_CH2_TX_DSA_DATA[5]}]
set_property PACKAGE_PIN AH13 [get_ports DBA_CPLD_JTAG_TDI]
set_property PACKAGE_PIN AH14 [get_ports DBA_CPLD_JTAG_TDO]
set_property PACKAGE_PIN AK15 [get_ports DBA_MYK_GPIO_1]
set_property PACKAGE_PIN AJ15 [get_ports DBA_MYK_GPIO_4]
set_property PACKAGE_PIN AH16 [get_ports {DBA_CH2_TX_DSA_DATA[4]}]
set_property PACKAGE_PIN AH17 [get_ports {DBA_CH2_TX_DSA_DATA[3]}]
set_property PACKAGE_PIN AE12 [get_ports DBA_MYK_SYNC_OUT_n]
set_property PACKAGE_PIN AF12 [get_ports DBA_CPLD_PL_SPI_SDO]
set_property PACKAGE_PIN AK12 [get_ports DBA_MYK_GPIO_13]
set_property PACKAGE_PIN AK13 [get_ports DBA_MYK_GPIO_0]
set_property PACKAGE_PIN AK16 [get_ports DBA_MYK_INTRQ]
set_property PACKAGE_PIN AJ16 [get_ports {DBA_CH2_TX_DSA_DATA[2]}]
set_property PACKAGE_PIN AH18 [get_ports {DBA_CH2_TX_DSA_DATA[0]}]
set_property PACKAGE_PIN AJ18 [get_ports {DBA_CH2_TX_DSA_DATA[1]}]
set_property PACKAGE_PIN AF14 [get_ports DBA_FPGA_CLK_p]
set_property PACKAGE_PIN AG14 [get_ports DBA_FPGA_CLK_n]
set_property PACKAGE_PIN AG17 [get_ports DBA_FPGA_SYSREF_p]
set_property PACKAGE_PIN AG16 [get_ports DBA_FPGA_SYSREF_n]
set_property PACKAGE_PIN AD15 [get_ports {DBA_CH2_RX_DSA_DATA[3]}]
set_property PACKAGE_PIN AD16 [get_ports {DBA_CH2_RX_DSA_DATA[5]}]
set_property PACKAGE_PIN AE13 [get_ports DBA_CPLD_JTAG_TMS]
set_property PACKAGE_PIN AF13 [get_ports DBA_CPLD_JTAG_TCK]
set_property PACKAGE_PIN AE15 [get_ports DBA_MYK_GPIO_15]
set_property PACKAGE_PIN AE16 [get_ports DBA_MYK_SPI_CS_n]
set_property PACKAGE_PIN AF17 [get_ports {DBA_CH2_RX_DSA_DATA[1]}]
set_property PACKAGE_PIN AF18 [get_ports {DBA_CH2_RX_DSA_DATA[2]}]
set_property PACKAGE_PIN AC16 [get_ports DBA_CPLD_PL_SPI_LE]
set_property PACKAGE_PIN AC17 [get_ports DBA_CPLD_PL_SPI_SDI]
set_property PACKAGE_PIN AD13 [get_ports DBA_MYK_GPIO_12]
set_property PACKAGE_PIN AD14 [get_ports DBA_MYK_GPIO_14]
set_property PACKAGE_PIN AE17 [get_ports DBA_MYK_SPI_SCLK]
set_property PACKAGE_PIN AE18 [get_ports DBA_MYK_GPIO_3]
set_property PACKAGE_PIN AB12 [get_ports {DBA_CH2_RX_DSA_DATA[0]}]
set_property PACKAGE_PIN AC12 [get_ports {DBA_CH2_RX_DSA_DATA[4]}]
set_property PACKAGE_PIN AC13 [get_ports {DBA_CPLD_PL_SPI_ADDR[2]}]
set_property PACKAGE_PIN AC14 [get_ports DBA_CPLD_PL_SPI_SCLK]

# set_property PACKAGE_PIN AB25     [get_ports DBA_SWITCHER_CLOCK]
# set_property IOSTANDARD  LVCMOS33 [get_ports DBA_SWITCHER_CLOCK]
# set_property DRIVE       4        [get_ports DBA_SWITCHER_CLOCK]
# set_property SLEW        SLOW     [get_ports DBA_SWITCHER_CLOCK]

# During SI measurements with default drive strength, many of the FPGA-driven lines to
# the DB were showing high over/undershoot. Therefore for single-ended lines to the DBs
# we are decreasing the drive strength to the minimum value (4mA) and explicitly
# declaring the (default) slew rate as SLOW.

set UsrpIoAHpPinsSe [get_ports {DBA_CPLD_PS_* DBA_CH1_* DBA_ATR*}]
set_property IOSTANDARD    LVCMOS18         $UsrpIoAHpPinsSe
set_property DRIVE         4                $UsrpIoAHpPinsSe
set_property SLEW          SLOW             $UsrpIoAHpPinsSe

set UsrpIoAHrPinsSe [get_ports {DBA_MYK_SPI_* DBA_MYK_INTRQ DBA_CPLD_PL_* DBA_CPLD_JTAG_* DBA_MYK_SYNC* DBA_CH2* DBA_MYK_GPIO*}]
set_property IOSTANDARD    LVCMOS25         $UsrpIoAHrPinsSe
set_property DRIVE         4                $UsrpIoAHrPinsSe
set_property SLEW          SLOW             $UsrpIoAHrPinsSe

set UsrpIoAHrPinsDiff [get_ports {DBA_FPGA_CLK_* DBA_FPGA_SYSREF_*}]
set_property IOSTANDARD    LVDS_25          $UsrpIoAHrPinsDiff
set_property DIFF_TERM     TRUE             $UsrpIoAHrPinsDiff


### MGTs, Bank 112

set_property PACKAGE_PIN   N8               [get_ports {USRPIO_A_MGTCLK_P}]
set_property PACKAGE_PIN   N7               [get_ports {USRPIO_A_MGTCLK_N}]

# This mapping uses the TX pins as the "master" and mimics RX off of them.
set_property PACKAGE_PIN   V6               [get_ports {USRPIO_A_RX_P[0]}]
set_property PACKAGE_PIN   V5               [get_ports {USRPIO_A_RX_N[0]}]
set_property PACKAGE_PIN   U4               [get_ports {USRPIO_A_RX_P[1]}]
set_property PACKAGE_PIN   U3               [get_ports {USRPIO_A_RX_N[1]}]
set_property PACKAGE_PIN   T6               [get_ports {USRPIO_A_RX_P[2]}]
set_property PACKAGE_PIN   T5               [get_ports {USRPIO_A_RX_N[2]}]
set_property PACKAGE_PIN   P6               [get_ports {USRPIO_A_RX_P[3]}]
set_property PACKAGE_PIN   P5               [get_ports {USRPIO_A_RX_N[3]}]

set_property PACKAGE_PIN   T2               [get_ports {USRPIO_A_TX_P[0]}]
set_property PACKAGE_PIN   T1               [get_ports {USRPIO_A_TX_N[0]}]
set_property PACKAGE_PIN   R4               [get_ports {USRPIO_A_TX_P[1]}]
set_property PACKAGE_PIN   R3               [get_ports {USRPIO_A_TX_N[1]}]
set_property PACKAGE_PIN   P2               [get_ports {USRPIO_A_TX_P[2]}]
set_property PACKAGE_PIN   P1               [get_ports {USRPIO_A_TX_N[2]}]
set_property PACKAGE_PIN   N4               [get_ports {USRPIO_A_TX_P[3]}]
set_property PACKAGE_PIN   N3               [get_ports {USRPIO_A_TX_N[3]}]

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


### USRP IO B : ##########################################################################
###
##########################################################################################

## HP GPIO, Bank 33, 1.8V

set_property PACKAGE_PIN   J4               [get_ports {DBB_CPLD_PS_SPI_LE}]
set_property PACKAGE_PIN   J3               [get_ports {DBB_CPLD_PS_SPI_SCLK}]
set_property PACKAGE_PIN   D4               [get_ports {DBB_CH1_TX_DSA_DATA[5]}]
# set_property PACKAGE_PIN   D3               [get_ports {nc}]
set_property PACKAGE_PIN   K2               [get_ports {DBB_CPLD_PS_SPI_ADDR[0]}]
set_property PACKAGE_PIN   K3               [get_ports {DBB_CPLD_PS_SPI_ADDR[1]}]
set_property PACKAGE_PIN   B5               [get_ports {DBB_CH1_TX_DSA_DATA[3]}]
set_property PACKAGE_PIN   B4               [get_ports {DBB_CH1_TX_DSA_DATA[4]}]
set_property PACKAGE_PIN   G5               [get_ports {DBB_CPLD_PS_SPI_SDO}]
set_property PACKAGE_PIN   G4               [get_ports {DBB_CPLD_PS_SPI_SDI}]
set_property PACKAGE_PIN   J5               [get_ports {DBB_CH1_RX_DSA_DATA[0]}]
set_property PACKAGE_PIN   K5               [get_ports {DBB_CH1_RX_DSA_DATA[1]}]
set_property PACKAGE_PIN   D5               [get_ports {DBB_CH1_TX_DSA_DATA[2]}]
set_property PACKAGE_PIN   E6               [get_ports {DBB_CH1_TX_DSA_DATA[1]}]
set_property PACKAGE_PIN   L3               [get_ports {DBB_ATR_RX_1}]
set_property PACKAGE_PIN   L2               [get_ports {DBB_ATR_TX_2}]
set_property PACKAGE_PIN   G6               [get_ports {DBB_CH1_TX_DSA_DATA[0]}]
set_property PACKAGE_PIN   H6               [get_ports {DBB_CH1_RX_DSA_DATA[5]}]
set_property PACKAGE_PIN   H4               [get_ports {DBB_ATR_TX_1}]
set_property PACKAGE_PIN   H3               [get_ports {DBB_ATR_RX_2}]
# set_property PACKAGE_PIN   F2               [get_ports {nc}]
set_property PACKAGE_PIN   G2               [get_ports {DBB_CH1_RX_DSA_DATA[3]}]
set_property PACKAGE_PIN   J6               [get_ports {DBB_CH1_RX_DSA_DATA[4]}]
set_property PACKAGE_PIN   K6               [get_ports {DBB_CH1_RX_DSA_DATA[2]}]

## HR GPIO, Bank 10, 2.5V

set_property PACKAGE_PIN   AK17             [get_ports {DBB_MYK_SYNC_IN_n}]
set_property PACKAGE_PIN   AK18             [get_ports {DBB_CPLD_PL_SPI_ADDR[0]}]
set_property PACKAGE_PIN   AK21             [get_ports {DBB_MYK_SPI_SDO}]
set_property PACKAGE_PIN   AJ21             [get_ports {DBB_MYK_SPI_SDIO}]
set_property PACKAGE_PIN   AF19             [get_ports {DBB_CPLD_PL_SPI_ADDR[1]}]
set_property PACKAGE_PIN   AG19             [get_ports {DBB_CH2_TX_DSA_DATA[5]}]
set_property PACKAGE_PIN   AH19             [get_ports {DBB_CPLD_JTAG_TDI}]
set_property PACKAGE_PIN   AJ19             [get_ports {DBB_CPLD_JTAG_TDO}]
set_property PACKAGE_PIN   AK22             [get_ports {DBB_MYK_GPIO_1}]
set_property PACKAGE_PIN   AK23             [get_ports {DBB_MYK_GPIO_4}]
set_property PACKAGE_PIN   AF20             [get_ports {DBB_CH2_TX_DSA_DATA[4]}]
set_property PACKAGE_PIN   AG20             [get_ports {DBB_CH2_TX_DSA_DATA[3]}]
set_property PACKAGE_PIN   AF23             [get_ports {DBB_MYK_SYNC_OUT_n}]
set_property PACKAGE_PIN   AF24             [get_ports {DBB_CPLD_PL_SPI_SDO}]
set_property PACKAGE_PIN   AK20             [get_ports {DBB_MYK_GPIO_13}]
set_property PACKAGE_PIN   AJ20             [get_ports {DBB_MYK_GPIO_0}]
set_property PACKAGE_PIN   AJ23             [get_ports {DBB_MYK_INTRQ}]
set_property PACKAGE_PIN   AJ24             [get_ports {DBB_CH2_TX_DSA_DATA[2]}]
set_property PACKAGE_PIN   AG24             [get_ports {DBB_CH2_TX_DSA_DATA[0]}]
set_property PACKAGE_PIN   AG25             [get_ports {DBB_CH2_TX_DSA_DATA[1]}]
set_property PACKAGE_PIN   AG21             [get_ports {DBB_FPGA_CLK_p}]
set_property PACKAGE_PIN   AH21             [get_ports {DBB_FPGA_CLK_n}]
set_property PACKAGE_PIN   AE22             [get_ports {DBB_FPGA_SYSREF_p}]
set_property PACKAGE_PIN   AF22             [get_ports {DBB_FPGA_SYSREF_n}]
set_property PACKAGE_PIN   AJ25             [get_ports {DBB_CH2_RX_DSA_DATA[3]}]
set_property PACKAGE_PIN   AK25             [get_ports {DBB_CH2_RX_DSA_DATA[5]}]
set_property PACKAGE_PIN   AB21             [get_ports {DBB_CPLD_JTAG_TMS}]
set_property PACKAGE_PIN   AB22             [get_ports {DBB_CPLD_JTAG_TCK}]
set_property PACKAGE_PIN   AD23             [get_ports {DBB_MYK_GPIO_15}]
set_property PACKAGE_PIN   AE23             [get_ports {DBB_MYK_SPI_CS_n}]
set_property PACKAGE_PIN   AB24             [get_ports {DBB_CH2_RX_DSA_DATA[1]}]
set_property PACKAGE_PIN   AA24             [get_ports {DBB_CH2_RX_DSA_DATA[2]}]
set_property PACKAGE_PIN   AG22             [get_ports {DBB_CPLD_PL_SPI_LE}]
set_property PACKAGE_PIN   AH22             [get_ports {DBB_CPLD_PL_SPI_SDI}]
set_property PACKAGE_PIN   AD21             [get_ports {DBB_MYK_GPIO_12}]
set_property PACKAGE_PIN   AE21             [get_ports {DBB_MYK_GPIO_14}]
set_property PACKAGE_PIN   AC22             [get_ports {DBB_MYK_SPI_SCLK}]
set_property PACKAGE_PIN   AC23             [get_ports {DBB_MYK_GPIO_3}]
set_property PACKAGE_PIN   AC24             [get_ports {DBB_CH2_RX_DSA_DATA[0]}]
set_property PACKAGE_PIN   AD24             [get_ports {DBB_CH2_RX_DSA_DATA[4]}]
set_property PACKAGE_PIN   AH23             [get_ports {DBB_CPLD_PL_SPI_ADDR[2]}]
set_property PACKAGE_PIN   AH24             [get_ports {DBB_CPLD_PL_SPI_SCLK}]

# set_property PACKAGE_PIN AA25     [get_ports DBB_SWITCHER_CLOCK]
# set_property IOSTANDARD  LVCMOS33 [get_ports DBB_SWITCHER_CLOCK]
# set_property DRIVE       4        [get_ports DBB_SWITCHER_CLOCK]
# set_property SLEW        SLOW     [get_ports DBB_SWITCHER_CLOCK]

# During SI measurements with default drive strength, many of the FPGA-driven lines to
# the DB were showing high over/undershoot. Therefore for single-ended lines to the DBs
# we are decreasing the drive strength to the minimum value (4mA) and explicitly
# declaring the (default) slew rate as SLOW.

set UsrpIoBHpPinsSe [get_ports {DBB_CPLD_PS_* DBB_CH1_* DBB_ATR*}]
set_property IOSTANDARD    LVCMOS18         $UsrpIoBHpPinsSe
set_property DRIVE         4                $UsrpIoBHpPinsSe
set_property SLEW          SLOW             $UsrpIoBHpPinsSe

set UsrpIoBHrPinsSe [get_ports {DBB_MYK_SPI_* DBB_MYK_INTRQ DBB_CPLD_PL_* DBB_CPLD_JTAG_* DBB_MYK_SYNC* DBB_CH2* DBB_MYK_GPIO*}]
set_property IOSTANDARD    LVCMOS25         $UsrpIoBHrPinsSe
set_property DRIVE         4                $UsrpIoBHrPinsSe
set_property SLEW          SLOW             $UsrpIoBHrPinsSe

set UsrpIoBHrPinsDiff [get_ports {DBB_FPGA_CLK_* DBB_FPGA_SYSREF_*}]
set_property IOSTANDARD    LVDS_25          $UsrpIoBHrPinsDiff
set_property DIFF_TERM     TRUE             $UsrpIoBHrPinsDiff

set_property PULLUP TRUE [get_ports {DB*_CH*_*X_DSA_DATA[*]}]


### MGTs, Bank 112

set_property PACKAGE_PIN   W8               [get_ports {USRPIO_B_MGTCLK_P}]
set_property PACKAGE_PIN   W7               [get_ports {USRPIO_B_MGTCLK_N}]

# This mapping uses the TX pins as the "master" and mimics RX off of them.
set_property PACKAGE_PIN   AC4              [get_ports {USRPIO_B_RX_P[0]}]
set_property PACKAGE_PIN   AC3              [get_ports {USRPIO_B_RX_N[0]}]
set_property PACKAGE_PIN   AB6              [get_ports {USRPIO_B_RX_P[1]}]
set_property PACKAGE_PIN   AB5              [get_ports {USRPIO_B_RX_N[1]}]
set_property PACKAGE_PIN   Y6               [get_ports {USRPIO_B_RX_P[2]}]
set_property PACKAGE_PIN   Y5               [get_ports {USRPIO_B_RX_N[2]}]
set_property PACKAGE_PIN   AA4              [get_ports {USRPIO_B_RX_P[3]}]
set_property PACKAGE_PIN   AA3              [get_ports {USRPIO_B_RX_N[3]}]

set_property PACKAGE_PIN   AB2              [get_ports {USRPIO_B_TX_P[0]}]
set_property PACKAGE_PIN   AB1              [get_ports {USRPIO_B_TX_N[0]}]
set_property PACKAGE_PIN   Y2               [get_ports {USRPIO_B_TX_P[1]}]
set_property PACKAGE_PIN   Y1               [get_ports {USRPIO_B_TX_N[1]}]
set_property PACKAGE_PIN   W4               [get_ports {USRPIO_B_TX_P[2]}]
set_property PACKAGE_PIN   W3               [get_ports {USRPIO_B_TX_N[2]}]
set_property PACKAGE_PIN   V2               [get_ports {USRPIO_B_TX_P[3]}]
set_property PACKAGE_PIN   V1               [get_ports {USRPIO_B_TX_N[3]}]



## PL DDR : #############################################################################
##
#########################################################################################

set_property PACKAGE_PIN   D8               [get_ports {ddr3_addr[0]}]
set_property PACKAGE_PIN   A7               [get_ports {ddr3_addr[1]}]
set_property PACKAGE_PIN   C7               [get_ports {ddr3_addr[2]}]
set_property PACKAGE_PIN   D9               [get_ports {ddr3_addr[3]}]
set_property PACKAGE_PIN   J9               [get_ports {ddr3_addr[4]}]
set_property PACKAGE_PIN   E8               [get_ports {ddr3_addr[5]}]
set_property PACKAGE_PIN   G7               [get_ports {ddr3_addr[6]}]
set_property PACKAGE_PIN   E7               [get_ports {ddr3_addr[7]}]
set_property PACKAGE_PIN   G11              [get_ports {ddr3_addr[8]}]
set_property PACKAGE_PIN   C6               [get_ports {ddr3_addr[9]}]
set_property PACKAGE_PIN   B6               [get_ports {ddr3_addr[10]}]
set_property PACKAGE_PIN   H7               [get_ports {ddr3_addr[11]}]
set_property PACKAGE_PIN   B7               [get_ports {ddr3_addr[12]}]
set_property PACKAGE_PIN   F7               [get_ports {ddr3_addr[13]}]
set_property PACKAGE_PIN   F8               [get_ports {ddr3_addr[14]}]
set_property PACKAGE_PIN   F9               [get_ports {ddr3_addr[15]}]

set_property PACKAGE_PIN   C9               [get_ports {ddr3_ba[0]}]
set_property PACKAGE_PIN   E10              [get_ports {ddr3_ba[1]}]
set_property PACKAGE_PIN   B9               [get_ports {ddr3_ba[2]}]

set_property PACKAGE_PIN A10 [get_ports ddr3_cas_n]
set_property PACKAGE_PIN E11 [get_ports {ddr3_cke[0]}]
set_property PACKAGE_PIN H8 [get_ports {ddr3_ck_n[0]}]
set_property PACKAGE_PIN J8 [get_ports {ddr3_ck_p[0]}]
set_property PACKAGE_PIN D11 [get_ports {ddr3_cs_n[0]}]

set_property PACKAGE_PIN B16 [get_ports {ddr3_dm[0]}]
set_property PACKAGE_PIN B11 [get_ports {ddr3_dm[1]}]
set_property PACKAGE_PIN H13 [get_ports {ddr3_dm[2]}]
set_property PACKAGE_PIN G15 [get_ports {ddr3_dm[3]}]

set_property PACKAGE_PIN B17 [get_ports {ddr3_dq[0]}]
set_property PACKAGE_PIN A17 [get_ports {ddr3_dq[1]}]
set_property PACKAGE_PIN D15 [get_ports {ddr3_dq[2]}]
set_property PACKAGE_PIN D14 [get_ports {ddr3_dq[3]}]
set_property PACKAGE_PIN C17 [get_ports {ddr3_dq[4]}]
set_property PACKAGE_PIN E15 [get_ports {ddr3_dq[5]}]
set_property PACKAGE_PIN C16 [get_ports {ddr3_dq[6]}]
set_property PACKAGE_PIN D16 [get_ports {ddr3_dq[7]}]
set_property PACKAGE_PIN A13 [get_ports {ddr3_dq[8]}]
set_property PACKAGE_PIN A12 [get_ports {ddr3_dq[9]}]
set_property PACKAGE_PIN C14 [get_ports {ddr3_dq[10]}]
set_property PACKAGE_PIN B12 [get_ports {ddr3_dq[11]}]
set_property PACKAGE_PIN B14 [get_ports {ddr3_dq[12]}]
set_property PACKAGE_PIN C12 [get_ports {ddr3_dq[13]}]
set_property PACKAGE_PIN A14 [get_ports {ddr3_dq[14]}]
set_property PACKAGE_PIN C11 [get_ports {ddr3_dq[15]}]
set_property PACKAGE_PIN J15 [get_ports {ddr3_dq[16]}]
set_property PACKAGE_PIN L14 [get_ports {ddr3_dq[17]}]
set_property PACKAGE_PIN L15 [get_ports {ddr3_dq[18]}]
set_property PACKAGE_PIN J13 [get_ports {ddr3_dq[19]}]
set_property PACKAGE_PIN J14 [get_ports {ddr3_dq[20]}]
set_property PACKAGE_PIN K15 [get_ports {ddr3_dq[21]}]
set_property PACKAGE_PIN J16 [get_ports {ddr3_dq[22]}]
set_property PACKAGE_PIN H14 [get_ports {ddr3_dq[23]}]
set_property PACKAGE_PIN F15 [get_ports {ddr3_dq[24]}]
set_property PACKAGE_PIN G16 [get_ports {ddr3_dq[25]}]
set_property PACKAGE_PIN F14 [get_ports {ddr3_dq[26]}]
set_property PACKAGE_PIN E13 [get_ports {ddr3_dq[27]}]
set_property PACKAGE_PIN G14 [get_ports {ddr3_dq[28]}]
set_property PACKAGE_PIN D13 [get_ports {ddr3_dq[29]}]
set_property PACKAGE_PIN F13 [get_ports {ddr3_dq[30]}]
set_property PACKAGE_PIN E12 [get_ports {ddr3_dq[31]}]

set_property PACKAGE_PIN F17 [get_ports {ddr3_dqs_p[0]}]
set_property PACKAGE_PIN E17 [get_ports {ddr3_dqs_n[0]}]
set_property PACKAGE_PIN B15 [get_ports {ddr3_dqs_p[1]}]
set_property PACKAGE_PIN A15 [get_ports {ddr3_dqs_n[1]}]
set_property PACKAGE_PIN L13 [get_ports {ddr3_dqs_p[2]}]
set_property PACKAGE_PIN K13 [get_ports {ddr3_dqs_n[2]}]
set_property PACKAGE_PIN F12 [get_ports {ddr3_dqs_n[3]}]
set_property PACKAGE_PIN G12 [get_ports {ddr3_dqs_p[3]}]

set_property PACKAGE_PIN D10 [get_ports {ddr3_odt[0]}]
set_property PACKAGE_PIN B10 [get_ports ddr3_ras_n]
set_property PACKAGE_PIN D6 [get_ports ddr3_reset_n]
set_property PACKAGE_PIN G9 [get_ports sys_clk_n]
set_property PACKAGE_PIN H9 [get_ports sys_clk_p]
set_property DIFF_TERM true  [get_ports sys_clk_n]
set_property DIFF_TERM true [get_ports sys_clk_p]
set_property PACKAGE_PIN A9 [get_ports ddr3_we_n]

