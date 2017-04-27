#
# Copyright 2017 Ettus Research LLC
#


#*******************************************************************************
## Primary clock definitions

# Define clock FIXME Verify all clocks are rights
# 10 MHz FPGA_REFCLK_P/N
create_clock -period 100.000 -name FPGA_REFCLK -waveform {0.000 50.000} [get_ports FPGA_REFCLK_P]

# 125 MHz clock : RJ45
create_clock -period 8.000 -name ENET0_CLK125 -waveform {0.000 4.000} [get_ports ENET0_CLK125]

# 20 MHz White Rabbit Ref clk
#create_clock -name WB_20MHZ_CLK        -period 50.000  -waveform {0.000 25.000}   [get_ports WB_20MHZ_P]

#create_clock -name sysref_A            -period 8.000   -waveform {0.000 4.000}    [get_ports DBA_FPGA_SYSREF_P]
#create_clock -name sysref_B            -period 8.000   -waveform {0.000 4.000}    [get_ports DBB_FPGA_SYSREF_P]

# Sample Clk
create_clock -period 8.000 -name sample_clk_A -waveform {0.000 4.000} [get_ports DBA_FPGA_CLK_P]
#FIXME: Uncomment for daughter board B
#create_clock -name sample_clk_B        -period 8.000   -waveform {0.000 4.000}    [get_ports {DBB_FPGA_CLK_P}]

#*******************************************************************************
## Jesd204b Core

# 125 MHz MGT Reference
create_clock -period 8.000 -name USRPIO_A_MGTCLK -waveform {0.000 4.000} [get_ports USRPIO_A_MGTCLK_P]
#create_clock -name USRPIO_B_MGTCLK     -period 8.000   -waveform {0.000 4.000}    [get_ports USRPIO_B_MGTCLK_P]

#*******************************************************************************
## Aliases for auto-generated clocks
#FIXME add all clks
#create_generated_clock -name bus_clk                  [get_pins bus_clk_buf/O]
#create_generated_clock -name refclk_10mhz             [get_pins IBUFDS_10_MHz/O]



set_clock_groups -asynchronous -group [get_clocks clk_fpga_0 -include_generated_clocks]
set_clock_groups -asynchronous -group [get_clocks USRPIO_A_MGTCLK -include_generated_clocks]
#set_clock_groups -asynchronous -group [get_clocks USRPIO_B_MGTCLK -include_generated_clocks]
set_clock_groups -asynchronous -group [get_clocks sample_clk_A -include_generated_clocks]
#set_clock_groups -asynchronous -group [get_clocks sample_clk_B -include_generated_clocks]


