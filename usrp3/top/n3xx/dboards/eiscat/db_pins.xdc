#
# Copyright 2017 Ettus Research, A National Instruments Company
# SPDX-License-Identifier: LGPL-3.0
#
# Daughterboard Pin Definitions for the N310.
#


## TDC : ################################################################################
## Bank 10, 2.5V
#########################################################################################
set_property PACKAGE_PIN   AB15             [get_ports {UNUSED_PIN_TDCA_0}]
set_property PACKAGE_PIN   AB14             [get_ports {UNUSED_PIN_TDCA_1}]
set_property PACKAGE_PIN   AB16             [get_ports {UNUSED_PIN_TDCA_2}]
set_property PACKAGE_PIN   AB17             [get_ports {UNUSED_PIN_TDCA_3}]
set_property IOSTANDARD    LVCMOS25         [get_ports {UNUSED_PIN_TDCA_*}]
set_property IOB           TRUE             [get_ports {UNUSED_PIN_TDCA_*}]
## TDC : ################################################################################
## Bank 11, 2.5V
#########################################################################################
set_property PACKAGE_PIN   W21              [get_ports {UNUSED_PIN_TDCB_0}]
set_property PACKAGE_PIN   Y21              [get_ports {UNUSED_PIN_TDCB_1}]
set_property PACKAGE_PIN   Y22              [get_ports {UNUSED_PIN_TDCB_2}]
set_property PACKAGE_PIN   Y23              [get_ports {UNUSED_PIN_TDCB_3}]
set_property IOSTANDARD    LVCMOS25         [get_ports {UNUSED_PIN_TDCB_*}]
set_property IOB           TRUE             [get_ports {UNUSED_PIN_TDCB_*}]

## USRP IO A : ##########################################################################
##
#########################################################################################

## HP GPIO, Bank 33, 1.8V

set_property PACKAGE_PIN   G1               [get_ports {DBA_ADC_B_SYNC_P}]
set_property PACKAGE_PIN   H2               [get_ports {DBA_ADC_B_SYNC_N}]
set_property PACKAGE_PIN   D1               [get_ports {DBA_ADC_A_SYNC_P}]
set_property PACKAGE_PIN   E1               [get_ports {DBA_ADC_A_SYNC_N}]
set_property PACKAGE_PIN   H1               [get_ports {DBA_ADC_B_SYSREF_P}]
set_property PACKAGE_PIN   J1               [get_ports {DBA_ADC_B_SYSREF_N}]
set_property PACKAGE_PIN   A5               [get_ports {DBA_ADC_A_SYSREF_P}]
set_property PACKAGE_PIN   A4               [get_ports {DBA_ADC_A_SYSREF_N}]
# set_property PACKAGE_PIN   F5               [get_ports {nc}]
# set_property PACKAGE_PIN   E5               [get_ports {nc}]
# set_property PACKAGE_PIN   E3               [get_ports {nc}]
# set_property PACKAGE_PIN   E2               [get_ports {nc}]
set_property PACKAGE_PIN   A3               [get_ports {DBA_TMON_ALERT_N}]
set_property PACKAGE_PIN   A2               [get_ports {DBA_VMON_ALERT}]
# set_property PACKAGE_PIN   K1               [get_ports {nc}]
# set_property PACKAGE_PIN   L1               [get_ports {nc}]
set_property PACKAGE_PIN   C4               [get_ports {DBA_ADC_A_SDOUT}]
# set_property PACKAGE_PIN   C3               [get_ports {nc}]
# set_property PACKAGE_PIN   F4               [get_ports {nc}]
# set_property PACKAGE_PIN   F3               [get_ports {nc}]
# set_property PACKAGE_PIN   B1               [get_ports {nc}]
# set_property PACKAGE_PIN   B2               [get_ports {nc}]
# set_property PACKAGE_PIN   C1               [get_ports {nc}]
set_property PACKAGE_PIN   C2               [get_ports {DBA_ADC_B_SDOUT}]

## HR GPIO, Bank 10, 2.5V

set_property PACKAGE_PIN   AG12             [get_ports {DBA_LMK_READBACK}]
set_property PACKAGE_PIN   AH12             [get_ports {DBA_ADC_A_RESET}]
set_property PACKAGE_PIN   AJ13             [get_ports {DBA_PDAC_CS_N}]
set_property PACKAGE_PIN   AJ14             [get_ports {DBA_ADC_A_SCLK}]
# set_property PACKAGE_PIN   AG15             [get_ports {nc}]
# set_property PACKAGE_PIN   AF15             [get_ports {nc}]
# set_property PACKAGE_PIN   AH13             [get_ports {nc}]
set_property PACKAGE_PIN   AH14             [get_ports {DBA_ADC_A_CS_N}]
set_property PACKAGE_PIN   AK15             [get_ports {DBA_LMK_CS_N}]
set_property PACKAGE_PIN   AJ15             [get_ports {DBA_PDAC_SCLK}]
set_property PACKAGE_PIN   AH16             [get_ports {DBA_ADC_B_CS_N}]
set_property PACKAGE_PIN   AH17             [get_ports {DBA_LMK_SPI_EN}]
set_property PACKAGE_PIN   AE12             [get_ports {DBA_LMK_SYNC}]
set_property PACKAGE_PIN   AF12             [get_ports {DBA_LMK_SDI}]
set_property PACKAGE_PIN   AK12             [get_ports {DBA_LMK_STATUS}]
set_property PACKAGE_PIN   AK13             [get_ports {DBA_PDAC_SDI}]
set_property PACKAGE_PIN   AK16             [get_ports {DBA_LMK_SCK}]
set_property PACKAGE_PIN   AJ16             [get_ports {DBA_ADC_B_RESET}]
# set_property PACKAGE_PIN   AH18             [get_ports {nc}]
set_property PACKAGE_PIN   AJ18             [get_ports {DBA_DC_PWR_EN}]
set_property PACKAGE_PIN   AF14             [get_ports {DBA_FPGA_CLK_P}]
set_property PACKAGE_PIN   AG14             [get_ports {DBA_FPGA_CLK_N}]
# set_property PACKAGE_PIN   AG17             [get_ports {DbaFpgaSysref_p}]
# set_property PACKAGE_PIN   AG16             [get_ports {DbaFpgaSysref_n}]
# set_property PACKAGE_PIN   AD15             [get_ports {nc}]
set_property PACKAGE_PIN   AD16             [get_ports {DBA_ADC_B_SCLK}]
set_property PACKAGE_PIN   AE13             [get_ports {DBA_CH2_EN_N}]
set_property PACKAGE_PIN   AF13             [get_ports {DBA_CH3_EN_N}]
set_property PACKAGE_PIN   AE15             [get_ports {DBA_CH1_EN_N}]
set_property PACKAGE_PIN   AE16             [get_ports {DBA_CH0_EN_N}]
set_property PACKAGE_PIN   AF17             [get_ports {DBA_ADC_A_SDI}]
# set_property PACKAGE_PIN   AF18             [get_ports {nc}]
set_property PACKAGE_PIN   AC16             [get_ports {DBA_ADC_SPI_EN}]
set_property PACKAGE_PIN   AC17             [get_ports {DBA_LNA_CTRL_EN}]
set_property PACKAGE_PIN   AD13             [get_ports {DBA_CH6_EN_N}]
set_property PACKAGE_PIN   AD14             [get_ports {DBA_CH7_EN_N}]
set_property PACKAGE_PIN   AE17             [get_ports {DBA_CH5_EN_N}]
set_property PACKAGE_PIN   AE18             [get_ports {DBA_CH4_EN_N}]
# set_property PACKAGE_PIN   AB12             [get_ports {nc}]
# set_property PACKAGE_PIN   AC12             [get_ports {nc}]
set_property PACKAGE_PIN   AC13             [get_ports {DBA_DB_CTRL_EN_N}]
set_property PACKAGE_PIN   AC14             [get_ports {DBA_ADC_B_SDI}]


set UsrpIoAHpPinsSe [get_ports {DBA_ADC*SDOUT DBA*MON_ALERT*}]
set_property IOSTANDARD    LVCMOS18         $UsrpIoAHpPinsSe

set UsrpIoAHpPinsDiff [get_ports {DBA_ADC*SYNC* DBA_ADC*SYSREF*}]
set_property IOSTANDARD    LVDS             $UsrpIoAHpPinsDiff


set UsrpIoAHrPinsSe [get_ports {DBA_ADC*SDI DBA_ADC*SCLK DBA_ADC*CS_N DBA_ADC*RESET \
    DBA_LMK* DBA_PDAC* DBA_CH*EN_N DBA_DC_PWR_EN DBA_DB_CTRL_EN_N DBA_LNA_CTRL_EN DBA_ADC_SPI_EN DBA_LMK_SPI_EN }]
set_property IOSTANDARD    LVCMOS25         $UsrpIoAHrPinsSe
set_property DRIVE         4                $UsrpIoAHrPinsSe

set UsrpIoAHrPinsDiff [get_ports {DBA_FPGA_CLK_*}]
set_property IOSTANDARD    LVDS_25          $UsrpIoAHrPinsDiff
set_property DIFF_TERM     TRUE             $UsrpIoAHrPinsDiff


# set_property PACKAGE_PIN   AD20             [get_ports {DbaSwitcherClock}]
# set_property IOSTANDARD    LVCMOS33         [get_ports {DbaSwitcherClock}]

## MGTs, Bank 112

set_property PACKAGE_PIN   N8               [get_ports {USRPIO_A_MGTCLK_P}]
set_property PACKAGE_PIN   N7               [get_ports {USRPIO_A_MGTCLK_N}]

# 0/1 are swapped on the daughterboard connector for both 0/1 and 2/3
set_property PACKAGE_PIN   T6               [get_ports {USRPIO_A_RX_P[0]}]
set_property PACKAGE_PIN   T5               [get_ports {USRPIO_A_RX_N[0]}]
set_property PACKAGE_PIN   P6               [get_ports {USRPIO_A_RX_P[1]}]
set_property PACKAGE_PIN   P5               [get_ports {USRPIO_A_RX_N[1]}]
set_property PACKAGE_PIN   U4               [get_ports {USRPIO_A_RX_P[2]}]
set_property PACKAGE_PIN   U3               [get_ports {USRPIO_A_RX_N[2]}]
set_property PACKAGE_PIN   V6               [get_ports {USRPIO_A_RX_P[3]}]
set_property PACKAGE_PIN   V5               [get_ports {USRPIO_A_RX_N[3]}]

## USRP IO B : ##########################################################################
##
#########################################################################################

## HP GPIO, Bank 33, 1.8V

set_property PACKAGE_PIN   J4               [get_ports {DBB_ADC_B_SYNC_P}]
set_property PACKAGE_PIN   J3               [get_ports {DBB_ADC_B_SYNC_N}]
set_property PACKAGE_PIN   D4               [get_ports {DBB_ADC_A_SYNC_P}]
set_property PACKAGE_PIN   D3               [get_ports {DBB_ADC_A_SYNC_N}]
set_property PACKAGE_PIN   K2               [get_ports {DBB_ADC_B_SYSREF_P}]
set_property PACKAGE_PIN   K3               [get_ports {DBB_ADC_B_SYSREF_N}]
set_property PACKAGE_PIN   B5               [get_ports {DBB_ADC_A_SYSREF_P}]
set_property PACKAGE_PIN   B4               [get_ports {DBB_ADC_A_SYSREF_N}]
# set_property PACKAGE_PIN   G5               [get_ports {nc}]
# set_property PACKAGE_PIN   G4               [get_ports {nc}]
# set_property PACKAGE_PIN   J5               [get_ports {nc}]
# set_property PACKAGE_PIN   K5               [get_ports {nc}]
set_property PACKAGE_PIN   D5               [get_ports {DBB_TMON_ALERT_N}]
set_property PACKAGE_PIN   E6               [get_ports {DBB_VMON_ALERT}]
# set_property PACKAGE_PIN   L3               [get_ports {nc}]
# set_property PACKAGE_PIN   L2               [get_ports {nc}]
set_property PACKAGE_PIN   G6               [get_ports {DBB_ADC_A_SDOUT}]
# set_property PACKAGE_PIN   H6               [get_ports {nc}]
# set_property PACKAGE_PIN   H4               [get_ports {nc}]
# set_property PACKAGE_PIN   H3               [get_ports {nc}]
# set_property PACKAGE_PIN   F2               [get_ports {nc}]
# set_property PACKAGE_PIN   G2               [get_ports {nc}]
# set_property PACKAGE_PIN   J6               [get_ports {nc}]
set_property PACKAGE_PIN   K6               [get_ports {DBB_ADC_B_SDOUT}]

## HR GPIO, Bank 11, 2.5V

set_property PACKAGE_PIN   AK17             [get_ports {DBB_LMK_READBACK}]
set_property PACKAGE_PIN   AK18             [get_ports {DBB_ADC_A_RESET}]
set_property PACKAGE_PIN   AK21             [get_ports {DBB_PDAC_CS_N}]
set_property PACKAGE_PIN   AJ21             [get_ports {DBB_ADC_A_SCLK}]
# set_property PACKAGE_PIN   AF19             [get_ports {nc}]
# set_property PACKAGE_PIN   AG19             [get_ports {nc}]
# set_property PACKAGE_PIN   AH19             [get_ports {nc}]
set_property PACKAGE_PIN   AJ19             [get_ports {DBB_ADC_A_CS_N}]
set_property PACKAGE_PIN   AK22             [get_ports {DBB_LMK_CS_N}]
set_property PACKAGE_PIN   AK23             [get_ports {DBB_PDAC_SCLK}]
set_property PACKAGE_PIN   AF20             [get_ports {DBB_ADC_B_CS_N}]
set_property PACKAGE_PIN   AG20             [get_ports {DBB_LMK_SPI_EN}]
set_property PACKAGE_PIN   AF23             [get_ports {DBB_LMK_SYNC}]
set_property PACKAGE_PIN   AF24             [get_ports {DBB_LMK_SDI}]
set_property PACKAGE_PIN   AK20             [get_ports {DBB_LMK_STATUS}]
set_property PACKAGE_PIN   AJ20             [get_ports {DBB_PDAC_SDI}]
set_property PACKAGE_PIN   AJ23             [get_ports {DBB_LMK_SCK}]
set_property PACKAGE_PIN   AJ24             [get_ports {DBB_ADC_B_RESET}]
# set_property PACKAGE_PIN   AG24             [get_ports {nc}]
set_property PACKAGE_PIN   AG25             [get_ports {DBB_DC_PWR_EN}]
set_property PACKAGE_PIN   AG21             [get_ports {DBB_FPGA_CLK_P}]
set_property PACKAGE_PIN   AH21             [get_ports {DBB_FPGA_CLK_N}]
# set_property PACKAGE_PIN   AE22             [get_ports {DbbFpgaSysref_p}]
# set_property PACKAGE_PIN   AF22             [get_ports {DbbFpgaSysref_n}]
# set_property PACKAGE_PIN   AJ25             [get_ports {nc}]
set_property PACKAGE_PIN   AK25             [get_ports {DBB_ADC_B_SCLK}]
set_property PACKAGE_PIN   AB21             [get_ports {DBB_CH2_EN_N}]
set_property PACKAGE_PIN   AB22             [get_ports {DBB_CH3_EN_N}]
set_property PACKAGE_PIN   AD23             [get_ports {DBB_CH1_EN_N}]
set_property PACKAGE_PIN   AE23             [get_ports {DBB_CH0_EN_N}]
set_property PACKAGE_PIN   AB24             [get_ports {DBB_ADC_A_SDI}]
# set_property PACKAGE_PIN   AA24             [get_ports {nc}]
set_property PACKAGE_PIN   AG22             [get_ports {DBB_ADC_SPI_EN}]
set_property PACKAGE_PIN   AH22             [get_ports {DBB_LNA_CTRL_EN}]
set_property PACKAGE_PIN   AD21             [get_ports {DBB_CH6_EN_N}]
set_property PACKAGE_PIN   AE21             [get_ports {DBB_CH7_EN_N}]
set_property PACKAGE_PIN   AC22             [get_ports {DBB_CH5_EN_N}]
set_property PACKAGE_PIN   AC23             [get_ports {DBB_CH4_EN_N}]
# set_property PACKAGE_PIN   AC24             [get_ports {nc}]
# set_property PACKAGE_PIN   AD24             [get_ports {nc}]
set_property PACKAGE_PIN   AH23             [get_ports {DBB_DB_CTRL_EN_N}]
set_property PACKAGE_PIN   AH24             [get_ports {DBB_ADC_B_SDI}]


set UsrpIoBHpPinsSe [get_ports {DBB_ADC*SDOUT DBB*MON_ALERT*}]
set_property IOSTANDARD    LVCMOS18         $UsrpIoBHpPinsSe

set UsrpIoBHpPinsDiff [get_ports {DBB_ADC*SYNC* DBB_ADC*SYSREF*}]
set_property IOSTANDARD    LVDS             $UsrpIoBHpPinsDiff


set UsrpIoBHrPinsSe [get_ports {DBB_ADC*SDI DBB_ADC*SCLK DBB_ADC*CS_N DBB_ADC*RESET \
    DBB_LMK* DBB_PDAC* DBB_CH*EN_N DBB_DC_PWR_EN DBB_DB_CTRL_EN_N DBB_LNA_CTRL_EN DBB_ADC_SPI_EN DBB_LMK_SPI_EN }]
set_property IOSTANDARD    LVCMOS25         $UsrpIoBHrPinsSe
set_property DRIVE         4                $UsrpIoBHrPinsSe

set UsrpIoBHrPinsDiff [get_ports {DBB_FPGA_CLK_*}]
set_property IOSTANDARD    LVDS_25          $UsrpIoBHrPinsDiff
set_property DIFF_TERM     TRUE             $UsrpIoBHrPinsDiff


# set_property PACKAGE_PIN   AE20             [get_ports {DbbSwitcherClock}]
# set_property IOSTANDARD    LVCMOS33         [get_ports {DbbSwitcherClock}]

## MGTs, Bank 111

set_property PACKAGE_PIN   W8               [get_ports {USRPIO_B_MGTCLK_P}]
set_property PACKAGE_PIN   W7               [get_ports {USRPIO_B_MGTCLK_N}]

set_property PACKAGE_PIN   Y6               [get_ports {USRPIO_B_RX_P[0]}]
set_property PACKAGE_PIN   Y5               [get_ports {USRPIO_B_RX_N[0]}]
set_property PACKAGE_PIN   AA4              [get_ports {USRPIO_B_RX_P[1]}]
set_property PACKAGE_PIN   AA3              [get_ports {USRPIO_B_RX_N[1]}]

set_property PACKAGE_PIN   AB6              [get_ports {USRPIO_B_RX_P[2]}]
set_property PACKAGE_PIN   AB5              [get_ports {USRPIO_B_RX_N[2]}]
set_property PACKAGE_PIN   AC4              [get_ports {USRPIO_B_RX_P[3]}]
set_property PACKAGE_PIN   AC3              [get_ports {USRPIO_B_RX_N[3]}]


