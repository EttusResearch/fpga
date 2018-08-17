## Generated SDC file "rhodium_top.sdc"
# Author: Humberto Jimenez
# Based on Mg CPLD constraints by Daniel Jepson.

## Copyright (C) 2017  Intel Corporation. All rights reserved.
## Your use of Intel Corporation's design tools, logic functions 
## and other software and tools, and its AMPP partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Intel Program License 
## Subscription Agreement, the Intel Quartus Prime License Agreement,
## the Intel MegaCore Function License Agreement, or other 
## applicable license agreement, including, without limitation, 
## that your use is for the sole purpose of programming logic 
## devices manufactured by Intel and sold by Intel or its 
## authorized distributors.  Please refer to the applicable 
## agreement for further details.


## VENDOR  "Altera"
## PROGRAM "Quartus Prime"
## VERSION "Version 17.0.2 Build 602 07/19/2017 SJ Lite Edition"

## DATE    "Wed Nov 15 08:22:11 2017"

##
## DEVICE  "10M04SAU169I7G"
##

set_time_format -unit ns -decimal_places 3

# All the magic numbers come from the "/n3xx/dboards/rh/doc/rh_timing.xlsx" timing
# analysis spreadsheet. Analysis should be re-performed every time a board rev occurs
# that affects the CPLD interfaces.

################################################################################
# PS SPI Slave constraints.
# These constraints are for the CPLD endpoint. Pass-through constraints are
# handled in another section.
#   - PS SPI Clk rate.
#   - PS SPI Clk to SDI.
#   - PS SPI Clk to LE.
#   - PS SPI Clk to SDO.
################################################################################

# Maximum 6 MHz clock rate! This is heavily limited by the read data turnaround time...
# and could be up to 25 MHz if only performing writes.
set PsSpiFreq  6000000.0; # In Hz (6 MHz)

create_clock -name {SpiPsClk} \
             -period [expr 1.0e9 / $PsSpiFreq] \
             [get_ports {CPLD_PS_SPI_CLK_25}]             

set_clock_uncertainty -to SpiPsClk 0.1ns

# SDI is both registered in the CPLD and used as a direct passthrough. First constrain
# the input delay on the local paths inside the CPLD. Passthrough constraints
# are handled elsewhere.

set PsSdiInputDelayMax  10.404
set PsSdiInputDelayMin  -9.564

# SDI is driven from the PS on the falling edge of the Clk. Worst-case data-clock skew
# is around +/-10ns due to FPGA routing delays and board buffering. Complete timing
# analysis is performed and recorded elsewhere.
set_input_delay -clock SpiPsClk -max $PsSdiInputDelayMax [get_ports CPLD_PS_SPI_SDI_25] -clock_fall
set_input_delay -clock SpiPsClk -min $PsSdiInputDelayMin [get_ports CPLD_PS_SPI_SDI_25] -clock_fall

# For the CPLD Cs_n, the latch enable is used both as an asynchronous reset and
# synchronously to latch data. First, constrain the overall input delay for sync use.
# Technically, Cs_n is asserted and de-asserted many nanoseconds before the clock arrives
# but we still constrain it identically to the SDI in case something goes amiss.
set_input_delay -clock SpiPsClk -max $PsSdiInputDelayMax [get_ports CPLD_PS_ADDR0_25] -clock_fall
set_input_delay -clock SpiPsClk -min $PsSdiInputDelayMin [get_ports CPLD_PS_ADDR0_25] -clock_fall
# Then set a false path only on the async reset flops.
set_false_path -from [get_ports {CPLD_PS_ADDR0_25}] -to [get_pins *|clrn]

# Constrain MISO as snugly as possible through the CPLD without making the tools work
# too hard. At a 166.667 ns period, this sets the clock-to-out for the CPLD at [10, 50]ns.
# Math for Max = T_clk/2 - 50 = 166.667/2 - 50 = 33.33 ns.
# The clock_fall argument is not used, because the tools are already aware of which edge
# to launch and latch at. This was verified in the TimeQuest Timing Analyzer diagrams.
set PsSdoOutputDelayMax   33.333
set PsSdoOutputDelayMin  -10.000

set_output_delay -clock SpiPsClk -max $PsSdoOutputDelayMax [get_ports CPLD_PS_SPI_SDO_25]
set_output_delay -clock SpiPsClk -min $PsSdoOutputDelayMin [get_ports CPLD_PS_SPI_SDO_25]



################################################################################
# PL SPI Slave constraints.
# These constraints are for the CPLD endpoint. Pass-through constraints are
# handled in another section.
#   - PL SPI Clk rate.
#   - PL SPI Clk to SDI.
#   - PL SPI Clk to LE.
#   - PL SPI Clk to SDO.
################################################################################

# Maximum 62.500 MHz clock rate for writes!
# Maximum 15.625 MHz clock rate for reads!

set PlSpiFreqW 62500000.0; # In Hz (250 MHz/4) = 62.5 MHz
set PlSpiFreqR 15625000.0; # In Hz (250 MHz/16) = 15.625 MHz

create_clock -name {PlSpiClkW} \
             -period [expr 1.0e9 / $PlSpiFreqW] \
             [get_ports {CPLD_PL_SPI_SCLK_18}]                    

create_clock -name {PlSpiClkR} \
             -period [expr 1.0e9 / $PlSpiFreqR] \
             [get_ports {CPLD_PL_SPI_SCLK_18}] \
             -add             

set_clock_uncertainty -to PlSpiClkW 0.1ns
set_clock_uncertainty -to PlSpiClkR 0.1ns

# Technically, only one clock can be driven from the FPGA for the PL SPI, so
# we treat both clocks as logically exclusive to tell the tools to not analyze
# the paths between them.
set_clock_groups -logically_exclusive -group [get_clocks {PlSpiClkR}] -group [get_clocks {PlSpiClkW}]

# SDI is both registered in the CPLD and used as a direct passthrough. First constrain
# the input delay on the local paths inside the CPLD. Passthrough constraints
# are handled elsewhere.

set PlSdiInputDelayMax   3.445
set PlSdiInputDelayMin  -3.427

# SDI is driven from the FPGA on the falling edge of the Clk. Worst-case data-clock skew
# is around +/-5ns. Complete timing analysis is performed and recorded elsewhere.
set_input_delay -clock PlSpiClkW -max $PlSdiInputDelayMax [get_ports CPLD_PL_SPI_SDI_18] -clock_fall
set_input_delay -clock PlSpiClkW -min $PlSdiInputDelayMin [get_ports CPLD_PL_SPI_SDI_18] -clock_fall

# For the CPLD Cs_n, the latch enable is used both as an asynchronous reset and
# synchronously to latch data. First, constrain the overall input delay for sync use.
# Technically, Cs_n is asserted and de-asserted many nanoseconds before the clock arrives
# but we still constrain it identically to the SDI in case something goes amiss.
set_input_delay -clock PlSpiClkW -max $PlSdiInputDelayMax [get_ports CPLD_PL_SPI_ADDR0_18] -clock_fall
set_input_delay -clock PlSpiClkW -min $PlSdiInputDelayMin [get_ports CPLD_PL_SPI_ADDR0_18] -clock_fall
# Then set a false path only on the async reset flops.
set_false_path -from [get_ports {CPLD_PL_SPI_ADDR0_18}] -to [get_pins *|clrn]

# Constrain MISO as snugly as possible through the CPLD without making the tools work too
# hard. At a 64 ns period (15.625 MHz), this sets the clock-to-out for the CPLD at [5, 10]ns.
# Math for Max = T_clk/2 - 22 = 64/2 - 22 = 10 ns.
set PlSdoOutputDelayMax  22.000
set PlSdoOutputDelayMin  -5.000

set_output_delay -clock PlSpiClkR -max $PlSdoOutputDelayMax [get_ports CPLD_PL_SPI_SDO_18]
set_output_delay -clock PlSpiClkR -min $PlSdoOutputDelayMin [get_ports CPLD_PL_SPI_SDO_18]


## Passthrough Constraints ##############################################################
# SPI Passthroughs: constrain min and max delays for outputs and inputs.
# Since the SDI ports have input delays pre-defined above, we have to remove those from
# the delay analysis here by adding the input delay to the constraint.
# Similarly, for the SDO pins add the output delay to the constraint.

# - PsClk passthrough
#   - SDI passthrough for LMK, Phase DAC, DAC, and ADC
#   - Cs_n passthrough for LMK, Phase DAC, DAC, and ADC
#   - SDO return mux passthrough for LMK, DAC, and ADC

# These values give us a constrained skew of +/- 25 ns considering worst delay combinations.
# For an overconstrained 166.67 ns period (6 MHz, above), 50 ns of total skew is accepted.
# In reality, this interface will be running at ~1 MHz (1000 ns), so we have plenty of time.
set PsSpiMaxDelay  30.000
set PsSpiMinDelay   5.000

## PS
# SDI
set_max_delay -to [get_ports {CLKDIST_SPI_SDIO PHDAC_SPI_SDI DAC_SPI_SDIO_18 ADC_SPI_SDIO_18}] \
              [expr $PsSdiInputDelayMax + $PsSpiMaxDelay]
set_min_delay -to [get_ports {CLKDIST_SPI_SDIO PHDAC_SPI_SDI DAC_SPI_SDIO_18 ADC_SPI_SDIO_18}] \
              [expr $PsSdiInputDelayMin + $PsSpiMinDelay]
# CS
set_max_delay -to [get_ports {CLKDIST_SPI_CS_L PHDAC_SPI_CS_L DAC_SPI_CS_L_18 ADC_SPI_CS_L_18}] \
              $PsSpiMaxDelay
set_min_delay -to [get_ports {CLKDIST_SPI_CS_L PHDAC_SPI_CS_L DAC_SPI_CS_L_18 ADC_SPI_CS_L_18}] \
              $PsSpiMinDelay
# CLK
set_max_delay -to [get_ports {CLKDIST_SPI_SCLK PHDAC_SPI_SCLK DAC_SPI_SCLK_18 ADC_SPI_SCLK_18}] \
              $PsSpiMaxDelay
set_min_delay -to [get_ports {CLKDIST_SPI_SCLK PHDAC_SPI_SCLK DAC_SPI_SCLK_18 ADC_SPI_SCLK_18}] \
              $PsSpiMinDelay
# SDO
set_max_delay -from [get_ports {CLKDIST_SPI_SDIO DAC_SPI_SDIO_18 ADC_SPI_SDIO_18}] \
              [expr $PsSpiMaxDelay + $PsSdoOutputDelayMax]
set_min_delay -from [get_ports {CLKDIST_SPI_SDIO DAC_SPI_SDIO_18 ADC_SPI_SDIO_18}] \
              [expr $PsSpiMinDelay + $PsSdoOutputDelayMin]

# - PlClk passthrough
#   - SDI passthrough for TX-LO, RX-LO, and LO Dist.
#   - Cs_n passthrough for TX-LO, RX-LO, and LO Dist.
#   - SDO return mux passthrough for TX-LO, and RX-LO.

# These values give us a constrained skew of +/- 7 ns considering worst delay combinations.
# For an overconstrained 64 ns period (15.625 MHz, above), 14 ns of total skew is accepted.
set PlSpiMaxDelay  10.000
set PlSpiMinDelay   3.000

## PL
# SDI
set_max_delay -to [get_ports {LO_SPI_SDI LODIST_Bd_SPI_SDI}] \
              [expr $PlSdiInputDelayMax + $PlSpiMaxDelay]
set_min_delay -to [get_ports {LO_SPI_SDI LODIST_Bd_SPI_SDI}] \
              [expr $PlSdiInputDelayMin + $PlSpiMinDelay]
# CS
set_max_delay -to [get_ports {LO_TX_CS_L LO_RX_CS_L LODIST_Bd_SPI_CS_L}] \
              $PlSpiMaxDelay
set_min_delay -to [get_ports {LO_TX_CS_L LO_RX_CS_L LODIST_Bd_SPI_CS_L}] \
              $PlSpiMinDelay
# CLK
set_max_delay -to [get_ports {LO_SPI_SCLK LODIST_Bd_SPI_SCLK}] \
              $PlSpiMaxDelay
set_min_delay -to [get_ports {LO_SPI_SCLK LODIST_Bd_SPI_SCLK}] \
              $PlSpiMinDelay
# SDO
set_max_delay -from [get_ports {LOSYNTH_RX_MUXOUT LOSYNTH_TX_MUXOUT}] \
              [expr $PlSpiMaxDelay + $PlSdoOutputDelayMax]
set_min_delay -from [get_ports {LOSYNTH_RX_MUXOUT LOSYNTH_TX_MUXOUT}] \
              [expr $PlSpiMinDelay + $PlSdoOutputDelayMin]


set_max_skew -to [get_ports Rx_DSA_*] 1.3
set_max_skew -to [get_ports Tx_DSA_*] 1.3
set_max_skew -to [get_ports {LO_DSA_* RxLO_DSA_LE TxLO_DSA_LE}] 1.3

set_false_path -to [get_ports {Tx_Sw1_Ctrl_1
Tx_Sw1_Ctrl_2
Tx_Sw2_Ctrl_1
Tx_Sw2_Ctrl_2
Tx_Sw3_Ctrl_1
Tx_Sw3_Ctrl_2
Tx_Sw3_Ctrl_3
Tx_Sw3_Ctrl_4
Rx_LO_Input_Select
Rx_LO_Filter_Sw_1
Rx_LO_Filter_Sw_2
Tx_LO_Input_Select
Tx_LO_Filter_Sw_1
Tx_LO_Filter_Sw_2
Tx_Sw5_Ctrl_1
Tx_Sw5_Ctrl_2
Rx_Sw6_Ctrl_1
Rx_Sw6_Ctrl_2
Tx_HB_LB_Select
Rx_HB_LB_Select
Cal_iso_Sw_Ctrl
Rx_Sw2_Ctrl
Rx_Sw1_Ctrl_1
Rx_Sw1_Ctrl_2
Rx_Sw3_Ctrl_1
Rx_Sw3_Ctrl_2
Rx_Sw4_Ctrl_1
Rx_Sw4_Ctrl_2
Rx_Sw4_Ctrl_3
Rx_Sw4_Ctrl_4
Rx_Demod_ADJ_1
Rx_Demod_ADJ_2}]
           
