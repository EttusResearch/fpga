###############################################################################
# Timing Constraints
###############################################################################

# CAT_DATA_CLK is the data clock from AD9361, sample rate dependent with a max rate of 61.44 MHz
create_clock -period 16.276 -name CAT_DATA_CLK [get_ports CAT_DATA_CLK]

# TCXO clock 40 MHz
create_clock -period 25.000 -name TCXO_CLK [get_nets TCXO_CLK]
set_input_jitter TCXO_CLK 0.100

# 10MHz / PPS References
create_clock -period 100.000 -name PPS_EXT_IN [get_nets PPS_EXT_IN]
create_clock -period 100.000 -name GPS_PPS [get_nets GPS_PPS]

# Asynchronous clock domains
set_clock_groups -asynchronous \
  -group [get_clocks -include_generated_clocks CAT_DATA_CLK] \
  -group [get_clocks -include_generated_clocks clk_fpga_0] \
  -group [get_clocks -include_generated_clocks *clk_50MHz_in] \
  -group [get_clocks -include_generated_clocks TCXO_CLK] \
  -group [get_clocks -include_generated_clocks PPS_EXT_IN] \
  -group [get_clocks -include_generated_clocks GPS_PPS]

# Setup ADC interface constraints.
# AD9361 configured to delay RX data by 4.5 ns.
set_input_delay -clock [get_clocks CAT_DATA_CLK] -max 4.500 [get_ports {CAT_P0_D* CAT_RX_FRAME}]
set_input_delay -clock [get_clocks CAT_DATA_CLK] -min 4.500 [get_ports {CAT_P0_D* CAT_RX_FRAME}]
set_input_delay -clock [get_clocks CAT_DATA_CLK] -clock_fall -max -add_delay 4.500 [get_ports {CAT_P0_D* CAT_RX_FRAME}]
set_input_delay -clock [get_clocks CAT_DATA_CLK] -clock_fall -min -add_delay 4.500 [get_ports {CAT_P0_D* CAT_RX_FRAME}]