#
# Copyright 2014 Ettus Research LLC
#

#*******************************************************************************
## Primary clock definitions

# Define clocks
create_clock -name FPGA_CLK            -period   5.000 -waveform {0.000 2.500}   [get_ports FPGA_CLK_p]
create_clock -name FPGA_REFCLK_10MHz   -period 100.000 -waveform {0.000 50.000}  [get_ports FPGA_REFCLK_10MHz_p]
create_clock -name FPGA_125MHz_CLK     -period   8.000 -waveform {0.000 4.000}   [get_ports FPGA_125MHz_CLK]
create_clock -name DB0_ADC_DCLK        -period   5.000 -waveform {0.000 2.500}   [get_ports DB0_ADC_DCLK_P]
create_clock -name DB1_ADC_DCLK        -period   5.000 -waveform {0.000 2.500}   [get_ports DB1_ADC_DCLK_P]
create_clock -name IoRxClock           -period   4.000 -waveform {0.000 2.000}   [get_ports IoRxClock]

# Set clock properties
set_input_jitter [get_clocks FPGA_CLK] 0.05

set var_fpga_clk_delay  1.545    ;# LMK_Delay=0.900ns, LMK->FPGA=0.645ns
set var_fpga_clk_skew   0.100
#set_clock_latency -source -early [expr $var_fpga_clk_delay - $var_fpga_clk_skew/2] [get_clocks FPGA_CLK]
#set_clock_latency -source -late  [expr $var_fpga_clk_delay + $var_fpga_clk_skew/2] [get_clocks FPGA_CLK]

set var_adc_clk_delay  -1.560    ;# LMK->ADC=1.04ns, ADC->FPGA=0.750ns, ADC=6.65ns (0.69*5ns)+5.7-2.5 
set var_adc_clk_skew    0.100    ;# The real skew is ~3.5ns with which we will not meet static timing. Just use LMK jitter values.
#set_clock_latency -source -early [expr $var_adc_clk_delay - $var_adc_clk_skew/2] [get_clocks DB0_ADC_DCLK]
#set_clock_latency -source -late  [expr $var_adc_clk_delay + $var_adc_clk_skew/2] [get_clocks DB0_ADC_DCLK]
#set_clock_latency -source -early [expr $var_adc_clk_delay - $var_adc_clk_skew/2] [get_clocks DB1_ADC_DCLK]
#set_clock_latency -source -late  [expr $var_adc_clk_delay + $var_adc_clk_skew/2] [get_clocks DB1_ADC_DCLK]

# FPGA_CLK_p/n is externally phase shifted to allow for crossing from the ADC clock domain
# to the radio_clk (aka FPGA_CLK_p/n) clock domain. To ensure this timing is consistent,
# lock the locations of the MMCM and BUFG to generate radio_clk.
set_property LOC MMCME2_ADV_X0Y0 [get_cells -hierarchical -filter {NAME =~ "*radio_clk_gen/*mmcm_adv_inst"}]
set_property LOC BUFGCTRL_X0Y8   [get_cells -hierarchical -filter {NAME =~ "*radio_clk_gen/*clkout1_buf"}]


#*******************************************************************************
## Generated clock definitions

create_generated_clock -name DB0_DAC_DCI  -source [get_pins gen_db0/oddr_clk/C] -divide_by 1 [get_ports DB0_DAC_DCI_P]
create_generated_clock -name DB1_DAC_DCI  -source [get_pins gen_db1/oddr_clk/C] -divide_by 1 [get_ports DB1_DAC_DCI_P]
create_generated_clock -name IoTxClock -multiply_by 1                                                               \
                       -source [get_pins -hier -filter {NAME =~ lvfpga_chinch_inst/*/TxClockGenx/TxUseMmcm.TxMmcm/CLKOUT0}] \
                       [get_ports {IoTxClock}]


#*******************************************************************************
## Aliases for auto-generated clocks

create_generated_clock -name radio_clk                [get_pins -hierarchical -filter {NAME =~ "*radio_clk_gen/*/CLKOUT0"}]
#create_generated_clock -name radio_clk_2x             [get_pins -hierarchical -filter {NAME =~ "*radio_clk_gen/*/CLKOUT1"}]
create_generated_clock -name bus_clk                  [get_pins -hierarchical -filter {NAME =~ "*bus_clk_gen/*/CLKOUT0"}]
create_generated_clock -name ioport2_clk              [get_pins -hierarchical -filter {NAME =~ "*bus_clk_gen/*/CLKOUT1"}]
create_generated_clock -name rio40_clk                [get_pins -hierarchical -filter {NAME =~ "*pcie_clk_gen/*/CLKOUT0"}]
create_generated_clock -name ioport2_idelay_ref_clk   [get_pins -hierarchical -filter {NAME =~ "*pcie_clk_gen/*/CLKOUT1"}]


#*******************************************************************************
## Asynchronous clock groups

set_clock_groups -asynchronous -group [get_clocks bus_clk]     -group [get_clocks ioport2_clk]
set_clock_groups -asynchronous -group [get_clocks ioport2_clk] -group [get_clocks rio40_clk]
set_clock_groups -asynchronous -group [get_clocks bus_clk]     -group [get_clocks radio_clk]
set_clock_groups -asynchronous -group [get_clocks ioport2_clk] -group [get_clocks IoPort2Wrapperx/RxLowSpeedClk]

# TODO: Ashish: Review these. We should put synchronizers in some of these paths
set_clock_groups -asynchronous -group [get_clocks bus_clk]     -group [get_clocks FPGA_REFCLK_10MHz]
set_clock_groups -asynchronous -group [get_clocks radio_clk]   -group [get_clocks FPGA_REFCLK_10MHz]


#*******************************************************************************
## ADC Interface

#set adc_in_delay_max [expr 1.25 - 1.34 + 0.55]  ;# 1.25: Data-edge relative to clk, -1.34: Clk delay in ADC; 0.55: Min setup time 
#set adc_in_delay_min [expr 1.25 - 1.34 - 0.55]  ;# 1.25: Data-edge relative to clk, -1.34: Clk delay in ADC; 0.55: Min hold time

set_max_delay -datapath_only -from [get_cells -hier -filter {NAME =~ *gen_lvds_pins[*].iddr}] 0.840

#set_input_delay -clock DB0_ADC_DCLK -max $adc_in_delay_max                         [get_ports {DB0_ADC_DA*}]
#set_input_delay -clock DB0_ADC_DCLK -min $adc_in_delay_min                         [get_ports {DB0_ADC_DA*}]
#set_input_delay -clock DB0_ADC_DCLK -max $adc_in_delay_max -clock_fall -add_delay  [get_ports {DB0_ADC_DA*}]
#set_input_delay -clock DB0_ADC_DCLK -min $adc_in_delay_min -clock_fall -add_delay  [get_ports {DB0_ADC_DA*}]

#set_input_delay -clock DB0_ADC_DCLK -max $adc_in_delay_max                         [get_ports {DB0_ADC_DB*}]
#set_input_delay -clock DB0_ADC_DCLK -min $adc_in_delay_min                         [get_ports {DB0_ADC_DB*}]
#set_input_delay -clock DB0_ADC_DCLK -max $adc_in_delay_max -clock_fall -add_delay  [get_ports {DB0_ADC_DB*}]
#set_input_delay -clock DB0_ADC_DCLK -min $adc_in_delay_min -clock_fall -add_delay  [get_ports {DB0_ADC_DB*}]

#set_input_delay -clock DB1_ADC_DCLK -max $adc_in_delay_max                         [get_ports {DB1_ADC_DA*}]
#set_input_delay -clock DB1_ADC_DCLK -min $adc_in_delay_min                         [get_ports {DB1_ADC_DA*}]
#set_input_delay -clock DB1_ADC_DCLK -max $adc_in_delay_max -clock_fall -add_delay  [get_ports {DB1_ADC_DA*}]
#set_input_delay -clock DB1_ADC_DCLK -min $adc_in_delay_min -clock_fall -add_delay  [get_ports {DB1_ADC_DA*}]

#set_input_delay -clock DB1_ADC_DCLK -max $adc_in_delay_max                         [get_ports {DB1_ADC_DB*}]
#set_input_delay -clock DB1_ADC_DCLK -min $adc_in_delay_min                         [get_ports {DB1_ADC_DB*}]
#set_input_delay -clock DB1_ADC_DCLK -max $adc_in_delay_max -clock_fall -add_delay  [get_ports {DB1_ADC_DB*}]
#set_input_delay -clock DB1_ADC_DCLK -min $adc_in_delay_min -clock_fall -add_delay  [get_ports {DB1_ADC_DB*}]


#*******************************************************************************
## IoPort2

# Constrain the location of the IDELAYCTERL associated with the interface trainer IDELAYs
set_property LOC IDELAYCTRL_X1Y0 [get_cells lvfpga_chinch_inst/IDELAYCTRLx]

# RX Pad Input constraints
set_input_delay -clock [get_clocks IoRxClock] -max 2.580                        [get_ports {irIoRx*}]
set_input_delay -clock [get_clocks IoRxClock] -min 2.280                        [get_ports {irIoRx*}]
set_input_delay -clock [get_clocks IoRxClock] -max 2.580 -clock_fall -add_delay [get_ports {irIoRx*}]
set_input_delay -clock [get_clocks IoRxClock] -min 2.280 -clock_fall -add_delay [get_ports {irIoRx*}]

# Note: The input clock N-Side ISERDES is not constrained for IO timing since
# adding an input delay does not work as the clock and data are the same.
# Since the architecture requires dedicated routes, the build-to-build
# variablilty will be zero and therefore, no separate timing constraint
# is necessary for the N-Side pin. The RxClock delay is constrained because
# of the input delay constraints on the rest of the bus. This path does, however,
# require a max delay constraint in order to override the default analysis:
set_max_delay -from [get_ports {IoRxClock*}]                                                       \
              -to   [get_cells -hier -filter {NAME =~ *IoPort2Wrapperx/RxClockGenx/RxClockSerdes*}] \
              2.0 -datapath_only

# TX Pad Output constraints
set_output_delay -clock [get_clocks IoTxClock] -max 1.600                        [get_ports {itIoTx*}]
set_output_delay -clock [get_clocks IoTxClock] -min 0.400                        [get_ports {itIoTx*}]
set_output_delay -clock [get_clocks IoTxClock] -max 1.600 -clock_fall -add_delay [get_ports {itIoTx*}]
set_output_delay -clock [get_clocks IoTxClock] -min 0.400 -clock_fall -add_delay [get_ports {itIoTx*}]

# These signals are all treated as async signals so no stringent timing requirements are needed.
set_max_delay 10.0 -to     [get_ports {aIrq*}]
set_max_delay  8.0 -from   [get_ports {aIoResetIn_n}]
set_max_delay  8.0 -from   [get_ports {aIoReadyIn}]
set_max_delay  8.0 -to     [get_ports {aIoReadyOut}]

# FPGA feedback to STC3 through GPIO
set_output_delay 1.500 -clock [get_clocks FPGA_125MHz_CLK] [get_ports {aIoPort2Restart}]
#set_input_delay  1.500 -clock [get_clocks FPGA_125MHz_CLK] [get_ports {aStc3Gpio7}]

# Double Sync
set_max_delay -from [get_cells -hier -filter {NAME =~ *IoPort2Wrapperx/tIoResetSync/DoubleSyncBasex/iDlySig*}]                            \
              -to   [get_cells -hier -filter {NAME =~ *IoPort2Wrapperx/tIoResetSync/DoubleSyncBasex/DoubleSyncAsyncInBasex/oSig_ms*}]     \
              6.0 -datapath_only
set_max_delay -from [get_cells -hier -filter {NAME =~ *IoPort2Wrapperx/bIoResetAckSync/DoubleSyncBasex/iDlySig*}]                         \
              -to   [get_cells -hier -filter {NAME =~ *IoPort2Wrapperx/bIoResetAckSync/DoubleSyncBasex/DoubleSyncAsyncInBasex/oSig_ms*}]  \
              6.0 -datapath_only

# Constrains HandshakeSLVx and IClkToPushClkHs in ControlIoDelayClockCross
set_max_delay -from [get_cells -hier -filter {NAME =~ *IoPortClkDelayTrainerx/*ControlIoDelayClockCrossx/*/HBx/*iLclStoredData*}] \
              -to   [get_cells -hier -filter {NAME =~ *IoPortClkDelayTrainerx/*ControlIoDelayClockCrossx/*/HBx/*ODataFlop*}]      \
              8.0 -datapath_only
set_max_delay -from [get_cells -hier -filter {NAME =~ *IoPortClkDelayTrainerx/*ControlIoDelayClockCrossx/*/HBx/iPushToggle}]           \
              -to   [get_cells -hier -filter {NAME =~ *IoPortClkDelayTrainerx/*ControlIoDelayClockCrossx/*/HBx/BlkOut.oPushToggle0_ms*}] \
              4.0 -datapath_only
set_max_delay -from [get_cells -hier -filter {NAME =~ *IoPortClkDelayTrainerx/*ControlIoDelayClockCrossx/*/HBx/BlkOut.oPushToggle0_ms*}] \
              -to   [get_cells -hier -filter {NAME =~ *IoPortClkDelayTrainerx/*ControlIoDelayClockCrossx/*/HBx/BlkOut.oPushToggle1*}]    \
              4.0

set_max_delay -from [get_cells -hier -filter {NAME =~ *IoPortClkDelayTrainerx/*ControlIoDelayClockCrossx/*/HBx/*oPushToggleToReady*}] \
              -to   [get_cells -hier -filter {NAME =~ *IoPortClkDelayTrainerx/*ControlIoDelayClockCrossx/*/HBx/*iRdyPushToggle_ms*}]  \
              4.0 -datapath_only
set_max_delay -from [get_cells -hier -filter {NAME =~ *IoPortClkDelayTrainerx/*ControlIoDelayClockCrossx/*/HBx/*iRdyPushToggle_ms*}] \
              -to   [get_cells -hier -filter {NAME =~ *IoPortClkDelayTrainerx/*ControlIoDelayClockCrossx/*/HBx/*iRdyPushToggle*}]    \
              4.0

# SamplerResultsHandshake and SamplerControlHandshake
set_max_delay -from [get_cells -hier -filter {NAME =~ *IoPortClkDelayTrainerx/ClockSamplerBlock.Sampler*Handshake/HBx/*iLclStoredData*}] \
              -to   [get_cells -hier -filter {NAME =~ *IoPortClkDelayTrainerx/ClockSamplerBlock.Sampler*Handshake/HBx/*ODataFlop*}]      \
              6.0 -datapath_only
set_max_delay -from [get_cells -hier -filter {NAME =~ *IoPortClkDelayTrainerx/ClockSamplerBlock.Sampler*Handshake/HBx/iPushToggle}]           \
              -to   [get_cells -hier -filter {NAME =~ *IoPortClkDelayTrainerx/ClockSamplerBlock.Sampler*Handshake/HBx/BlkOut.oPushToggle0_ms*}] \
              4.0 -datapath_only
set_max_delay -from [get_cells -hier -filter {NAME =~ *IoPortClkDelayTrainerx/ClockSamplerBlock.Sampler*Handshake/HBx/BlkOut.oPushToggle0_ms*}] \
              -to   [get_cells -hier -filter {NAME =~ *IoPortClkDelayTrainerx/ClockSamplerBlock.Sampler*Handshake/HBx/BlkOut.oPushToggle1*}]    \
              4.0
set_max_delay -from [get_cells -hier -filter {NAME =~ *IoPortClkDelayTrainerx/ClockSamplerBlock.Sampler*Handshake/HBx/*oPushToggleToReady*}]  \
              -to   [get_cells -hier -filter {NAME =~ *IoPortClkDelayTrainerx/ClockSamplerBlock.Sampler*Handshake/HBx/*iRdyPushToggle_ms*}]   \
              4.0 -datapath_only
set_max_delay -from [get_cells -hier -filter {NAME =~ *IoPortClkDelayTrainerx/ClockSamplerBlock.Sampler*Handshake/HBx/*iRdyPushToggle_ms*}]   \
              -to   [get_cells -hier -filter {NAME =~ *IoPortClkDelayTrainerx/ClockSamplerBlock.Sampler*Handshake/HBx/*iRdyPushToggle*}]      \
              4.0

# Constrain PhyResetSync PulseSync
set_max_delay -from [get_cells -hier -filter {NAME =~ *IoPortClkDelayTrainerx/TrainerBlock.PhyResetSync/PulseSyncBasex/iHoldSigInx*}]     \
              -to   [get_cells -hier -filter {NAME =~ *IoPortClkDelayTrainerx/TrainerBlock.PhyResetSync/PulseSyncBasex/oHoldSigIn_msx*}]  \
              4.0 -datapath_only
set_max_delay -from [get_cells -hier -filter {NAME =~ *IoPortClkDelayTrainerx/TrainerBlock.PhyResetSync/PulseSyncBasex/oHoldSigIn_msx*}]  \
              -to   [get_cells -hier -filter {NAME =~ *IoPortClkDelayTrainerx/TrainerBlock.PhyResetSync/PulseSyncBasex/oLocalSigOutCEx*}] \
              4.0
set_max_delay -from [get_cells -hier -filter {NAME =~ *IoPortClkDelayTrainerx/TrainerBlock.PhyResetSync/PulseSyncBasex/oLocalSigOutCEx*}] \
              -to   [get_cells -hier -filter {NAME =~ *IoPortClkDelayTrainerx/TrainerBlock.PhyResetSync/PulseSyncBasex/iSigOut_msx*}]     \
              4.0 -datapath_only
set_max_delay -from [get_cells -hier -filter {NAME =~ *IoPortClkDelayTrainerx/TrainerBlock.PhyResetSync/PulseSyncBasex/iSigOut_msx*}]     \
              -to   [get_cells -hier -filter {NAME =~ *IoPortClkDelayTrainerx/TrainerBlock.PhyResetSync/PulseSyncBasex/iSigOutx*}]        \
              4.0

# IoPort2 Core Clock Crossings
set_max_delay -from [get_cells -hier -filter {NAME =~ *IoPort2x/IoPort2Basex/ReceiveSide.IoPort2Receiverx/PacketReceivedDoublesync*iDlySigx*}]               \
              -to   [get_cells -hier -filter {NAME =~ *IoPort2x/IoPort2Basex/ReceiveSide.IoPort2Receiverx/PacketReceivedDoublesync*DoubleSyncAsyncInBasex*}] \
              6.0 -datapath_only
set_max_delay -from [get_cells -hier -filter {NAME =~ *IoPort2x/IoPort2Basex/ReceiveSide.IoPort2Receiverx/PacketReceivedDoublesync*DoubleSyncAsyncInBasex/oSig_msx*}] \
              -to   [get_cells -hier -filter {NAME =~ *IoPort2x/IoPort2Basex/ReceiveSide.IoPort2Receiverx/PacketReceivedDoublesync*DoubleSyncAsyncInBasex/oSigx*}]    \
              6.0

# Handshake
set_max_delay -from [get_cells -hier -filter {NAME =~ *IoPort2x/IoPort2Basex/ReceiveSide.IoReceiveFifoBasex/CreditManager*/HBx/*iLclStoredData*}] \
              -to   [get_cells -hier -filter {NAME =~ *IoPort2x/IoPort2Basex/ReceiveSide.IoReceiveFifoBasex/CreditManager*/HBx/*ODataFlop*}]      \
              10.0 -datapath_only
set_max_delay -from [get_cells -hier -filter {NAME =~ *IoPort2x/IoPort2Basex/ReceiveSide.IoReceiveFifoBasex/CreditManager*/HBx/iPushToggle}]           \
              -to   [get_cells -hier -filter {NAME =~ *IoPort2x/IoPort2Basex/ReceiveSide.IoReceiveFifoBasex/CreditManager*/HBx/BlkOut.oPushToggle0_ms*}] \
              6.0 -datapath_only
set_max_delay -from [get_cells -hier -filter {NAME =~ *IoPort2x/IoPort2Basex/ReceiveSide.IoReceiveFifoBasex/CreditManager*/HBx/BlkOut.oPushToggle0_ms*}] \
              -to   [get_cells -hier -filter {NAME =~ *IoPort2x/IoPort2Basex/ReceiveSide.IoReceiveFifoBasex/CreditManager*/HBx/BlkOut.oPushToggle1*}]    \
              4.0
set_max_delay -from [get_cells -hier -filter {NAME =~ *IoPort2x/IoPort2Basex/ReceiveSide.IoReceiveFifoBasex/CreditManager*/HBx/*oPushToggleToReady*}] \
              -to   [get_cells -hier -filter {NAME =~ *IoPort2x/IoPort2Basex/ReceiveSide.IoReceiveFifoBasex/CreditManager*/HBx/*iRdyPushToggle_ms*}]  \
              6.0 -datapath_only
set_max_delay -from [get_cells -hier -filter {NAME =~ *IoPort2x/IoPort2Basex/ReceiveSide.IoReceiveFifoBasex/CreditManager*/HBx/*iRdyPushToggle_ms*}]  \
              -to   [get_cells -hier -filter {NAME =~ *IoPort2x/IoPort2Basex/ReceiveSide.IoReceiveFifoBasex/CreditManager*/HBx/*iRdyPushToggle*}]     \
              4.0

# FIFO Clock Crossings
set_max_delay -from [get_cells -hier -filter {NAME =~ *IoPort2x/IoPort2Basex/ReceiveSide.IoReceiveFifoBasex/FifoFlags/ieInputCountGrayx*}]    \
              -to   [get_cells -hier -filter {NAME =~ *IoPort2x/IoPort2Basex/ReceiveSide.IoReceiveFifoBasex/FifoFlags/oInputCountGray_msx*}]  \
              5.0 -datapath_only
set_max_delay -from [get_cells -hier -filter {NAME =~ *IoPort2x/IoPort2Basex/ReceiveSide.IoReceiveFifoBasex/FifoFlags/oInputCountGray_msx*}]  \
              -to   [get_cells -hier -filter {NAME =~ *IoPort2x/IoPort2Basex/ReceiveSide.IoReceiveFifoBasex/FifoFlags/oInputCountGrayx*}]     \
              4.0
set_max_delay -from [get_cells -hier -filter {NAME =~ *IoPort2x/IoPort2Basex/ReceiveSide.IoReceiveFifoBasex/PacketFullyReceived/ieInputCountGrayx*}]   \
              -to   [get_cells -hier -filter {NAME =~ *IoPort2x/IoPort2Basex/ReceiveSide.IoReceiveFifoBasex/PacketFullyReceived/oInputCountGray_msx*}] \
              5.0 -datapath_only
set_max_delay -from [get_cells -hier -filter {NAME =~ *IoPort2x/IoPort2Basex/ReceiveSide.IoReceiveFifoBasex/PacketFullyReceived/oInputCountGray_msx*}] \
              -to   [get_cells -hier -filter {NAME =~ *IoPort2x/IoPort2Basex/ReceiveSide.IoReceiveFifoBasex/PacketFullyReceived/oInputCountGrayx*}]    \
              4.0
set_max_delay -from [get_cells -hier -filter {NAME =~ *IoPort2Basex/TransmitSide.IoTransmitFifox/TransmitFifo.PacketFullyReceived/ieInputCountGrayx*}]    \
              -to   [get_cells -hier -filter {NAME =~ *IoPort2Basex/TransmitSide.IoTransmitFifox/TransmitFifo.PacketFullyReceived/oInputCountGray_msx*}]  \
              5.0 -datapath_only
set_max_delay -from [get_cells -hier -filter {NAME =~ *IoPort2Basex/TransmitSide.IoTransmitFifox/TransmitFifo.PacketFullyReceived/oInputCountGray_msx*}]  \
              -to   [get_cells -hier -filter {NAME =~ *IoPort2Basex/TransmitSide.IoTransmitFifox/TransmitFifo.PacketFullyReceived/oInputCountGrayx*}]     \
              4.0
set_max_delay -from [get_cells -hier -filter {NAME =~ *IoPort2Basex/TransmitSide.IoTransmitFifox/TransmitFifo.PacketFullyReceived/oeOutputCountGrayx*}]   \
              -to   [get_cells -hier -filter {NAME =~ *IoPort2Basex/TransmitSide.IoTransmitFifox/TransmitFifo.PacketFullyReceived/iOutputCountGray_msx*}] \
              5.0 -datapath_only
set_max_delay -from [get_cells -hier -filter {NAME =~ *IoPort2Basex/TransmitSide.IoTransmitFifox/TransmitFifo.PacketFullyReceived/iOutputCountGray_msx*}] \
              -to   [get_cells -hier -filter {NAME =~ *IoPort2Basex/TransmitSide.IoTransmitFifox/TransmitFifo.PacketFullyReceived/iOutputCountGrayx*}]    \
              4.0
set_max_delay -from [get_cells -hier -filter {NAME =~ *IoPort2Basex/TransmitSide.IoTransmitFifox/TransmitFifo.InputFifo.FifoFlags/ieInputCountGrayx*}]    \
              -to   [get_cells -hier -filter {NAME =~ *IoPort2Basex/TransmitSide.IoTransmitFifox/TransmitFifo.InputFifo.FifoFlags/oInputCountGray_msx*}]  \
              5.0 -datapath_only
set_max_delay -from [get_cells -hier -filter {NAME =~ *IoPort2Basex/TransmitSide.IoTransmitFifox/TransmitFifo.InputFifo.FifoFlags/oInputCountGray_msx*}]  \
              -to   [get_cells -hier -filter {NAME =~ *IoPort2Basex/TransmitSide.IoTransmitFifox/TransmitFifo.InputFifo.FifoFlags/oInputCountGrayx*}]     \
              4.0
set_max_delay -from [get_cells -hier -filter {NAME =~ *IoPort2Basex/TransmitSide.IoTransmitFifox/TransmitFifo.InputFifo.FifoFlags/oeOutputCountGrayx*}]   \
              -to   [get_cells -hier -filter {NAME =~ *IoPort2Basex/TransmitSide.IoTransmitFifox/TransmitFifo.InputFifo.FifoFlags/iOutputCountGray_msx*}] \
              5.0 -datapath_only
set_max_delay -from [get_cells -hier -filter {NAME =~ *IoPort2Basex/TransmitSide.IoTransmitFifox/TransmitFifo.InputFifo.FifoFlags/iOutputCountGray_msx*}] \
              -to   [get_cells -hier -filter {NAME =~ *IoPort2Basex/TransmitSide.IoTransmitFifox/TransmitFifo.InputFifo.FifoFlags/iOutputCountGrayx*}]    \
              4.0
set_max_delay -from [get_cells -hier -filter {NAME =~ *IoPort2Basex/TransmitSide.IoTransmitFifox/TransmitFifo.InputFifo.FifoFlags/oeOutputCountGrayx*}]   \
              -to   [get_cells -hier -filter {NAME =~ *IoPort2Basex/TransmitSide.IoTransmitFifox/TransmitFifo*DualPortRAMx*oDlyAddr*}]                    \
              5.0
set_max_delay -from [get_cells -hier -filter {NAME =~ *IoPort2Basex/TransmitSide.IoTransmitFifox/CreditManager.HandshakeCredits/HBx/*iLclStoredData*}] \
              -to   [get_cells -hier -filter {NAME =~ *IoPort2Basex/TransmitSide.IoTransmitFifox/CreditManager.HandshakeCredits/HBx/*ODataFlop*}]      \
              10.0 -datapath_only
set_max_delay -from [get_cells -hier -filter {NAME =~ *IoPort2Basex/TransmitSide.IoTransmitFifox/CreditManager.HandshakeCredits/HBx/iPushToggle}]           \
              -to   [get_cells -hier -filter {NAME =~ *IoPort2Basex/TransmitSide.IoTransmitFifox/CreditManager.HandshakeCredits/HBx/BlkOut.oPushToggle0_ms*}] \
              6.0 -datapath_only
set_max_delay -from [get_cells -hier -filter {NAME =~ *IoPort2Basex/TransmitSide.IoTransmitFifox/CreditManager.HandshakeCredits/HBx/BlkOut.oPushToggle0_ms*}] \
              -to   [get_cells -hier -filter {NAME =~ *IoPort2Basex/TransmitSide.IoTransmitFifox/CreditManager.HandshakeCredits/HBx/BlkOut.oPushToggle1*}]    \
              4.0
set_max_delay -from [get_cells -hier -filter {NAME =~ *IoPort2Basex/TransmitSide.IoTransmitFifox/CreditManager.HandshakeCredits/HBx/*oPushToggleToReady*}] \
              -to   [get_cells -hier -filter {NAME =~ *IoPort2Basex/TransmitSide.IoTransmitFifox/CreditManager.HandshakeCredits/HBx/*iRdyPushToggle_ms*}]  \
              6.0 -datapath_only
set_max_delay -from [get_cells -hier -filter {NAME =~ *IoPort2Basex/TransmitSide.IoTransmitFifox/CreditManager.HandshakeCredits/HBx/*iRdyPushToggle_ms*}]  \
              -to   [get_cells -hier -filter {NAME =~ *IoPort2Basex/TransmitSide.IoTransmitFifox/CreditManager.HandshakeCredits/HBx/*iRdyPushToggle*}]     \
              4.0

# Double Sync
set_max_delay -from [get_cells -hier -filter {NAME =~ *IoPort2x/IoPort2Basex/Startup.DoubleSyncEnableTransmit/iDlySigx*}]                         \
              -to   [get_cells -hier -filter {NAME =~ *IoPort2x/IoPort2Basex/Startup.DoubleSyncEnableTransmit/*DoubleSyncAsyncInBasex/oSig_msx*}] \
              6.0 -datapath_only
set_max_delay -from [get_cells -hier -filter {NAME =~ *IoPort2x/IoPort2Basex/Startup.DoubleSyncEnableTransmit/*DoubleSyncAsyncInBasex/oSig_msx*}] \
              -to   [get_cells -hier -filter {NAME =~ *IoPort2x/IoPort2Basex/Startup.DoubleSyncEnableTransmit/*DoubleSyncAsyncInBasex/oSigx*}]    \
              4.0
set_max_delay -from [get_cells -hier -filter {NAME =~ *IoPort2Basex/DoubleSyncWidePortMode.DoubleSync*WidePortMode/iDlySigx*}]               \
              -to   [get_cells -hier -filter {NAME =~ *IoPort2Basex/DoubleSyncWidePortMode.DoubleSync*WidePortMode/DoubleSyncAsyncInBasex*}] \
              6.0 -datapath_only -quiet
set_max_delay -from [get_cells -hier -filter {NAME =~ *IoPort2Basex/DoubleSyncWidePortMode.DoubleSync*WidePortMode/DoubleSyncAsyncInBasex/oSig_msx*}] \
              -to   [get_cells -hier -filter {NAME =~ *IoPort2Basex/DoubleSyncWidePortMode.DoubleSync*WidePortMode/DoubleSyncAsyncInBasex/oSigx*}]    \
              5.0 -quiet


#*******************************************************************************
## Miscellaneous Interfaces

# Low speed dboard interfaces 
# Board routing delay is less than 1.5ns so should be safe to
# sample these with a client generated 50MHz clock with 3.5ns of slack
set_max_delay 15.0 -to     [get_ports {DB*_*X_IO*}]
set_max_delay 15.0 -from   [get_ports {DB*_*X_IO*}]
set_max_delay 15.0 -to     [get_ports {DB*_*X*SEN*}]
set_max_delay 15.0 -from   [get_ports {DB*_*X*MISO*}]

set_max_delay 15.0 -to     [get_ports {DB_DAC_SCLK DB_ADC_RESET DB_DAC_RESET}]
set_max_delay 15.0 -from   [get_ports {DB_DAC_MOSI DB_SCL DB_SDA}]

# Front-panel GPIO
# Board routing delay is less than 1.5ns so should be safe to
# sample these with a client generated 50MHz clock with 3.5ns of slack
set_max_delay 15.0 -to     [get_ports {FrontPanelGpio[*]}]
set_max_delay 15.0 -from   [get_ports {FrontPanelGpio[*]}]

# Clock distribution chip control
# Board routing delay is less than 1ns
set_max_delay 10.0 -from   [get_ports {LMK_Status[1] LMK_Status[0] LMK_Holdover LMK_Lock LMK_Sync}]
set_max_delay 10.0 -to     [get_ports {LMK_SEN LMK_MOSI LMK_SCLK}]
set_max_delay 10.0 -to     [get_ports {ClockRefSelect*}]
set_max_delay 10.0 -to     [get_ports {TCXO_ENA}]

# GPS UART
set_max_delay  6.0 -from   [get_ports {GPS_SER_OUT}]
set_max_delay  6.0 -to     [get_ports {GPS_SER_IN}]

# PPS and GPS Signals are assumed to be sampled by a 10MHz clock
set_max_delay 25.0 -from   [get_ports {EXT_PPS_IN}]
set_max_delay 25.0 -from   [get_ports {GPS_LOCK_OK}]
set_max_delay 25.0 -from   [get_ports {GPS_PPS_OUT}]
set_max_delay 25.0 -to     [get_ports {EXT_PPS_OUT}]


#*******************************************************************************
## Asynchronous paths

set_false_path -from [get_pins -hierarchical -filter {NAME =~ "x300_core/bus_int/set_sw_rst/out_reg[*]*/C"}]
set_false_path -from [get_cells -hier -filter {NAME =~ lvfpga_chinch_inst/*StartupFsmx/aResetLcl*}]
set_false_path -to   [get_ports {LED_*}]

