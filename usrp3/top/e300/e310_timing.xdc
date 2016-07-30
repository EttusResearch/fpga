###############################################################################
# Timing Constraints for E310 daughter board signals
###############################################################################

# CAT_DATA_CLK is the data clock from AD9361, sample rate dependent with a max rate of 61.44 MHz
set cat_data_clk_period             16.276;
set cat_data_clk_duty_cycle_var     [expr $cat_data_clk_period * (0.55 - 0.45)];
set tcxo_jitter                     0.0005;     # Calculated from datasheet phase noise
create_clock -period $cat_data_clk_period -name CAT_DATA_CLK [get_ports CAT_DATA_CLK]
# Model variable duty cycle as jitter.
set_input_jitter CAT_DATA_CLK [expr $cat_data_clk_duty_cycle_var + $tcxo_jitter]

# Generate DAC output clock
create_generated_clock -name CAT_FB_CLK -multiply_by 1 -source [get_pins inst_catcodec_ddr_cmos/catgen/oddr_clk/C] [get_ports CAT_FB_CLK]

# TCXO clock 40 MHz
create_clock -period 25.000 -name TCXO_CLK [get_nets TCXO_CLK]
set_input_jitter TCXO_CLK 0.100

# Asynchronous clock domains
set_clock_groups -asynchronous \
  -group [get_clocks -include_generated_clocks CAT_DATA_CLK] \
  -group [get_clocks -include_generated_clocks clk_fpga_0] \
  -group [get_clocks -include_generated_clocks *clk_50MHz_in] \
  -group [get_clocks -include_generated_clocks TCXO_CLK]

# Logically exclusive clocks in catcodec capture interface. These two clocks are the input to a BUFG mux that
# drives radio_clk, meaning only one of the two can drive radio_clk at a time.
set_clock_groups -logically_exclusive \
  -group [get_clocks -include_generated_clocks {clk0}] \
  -group [get_clocks -include_generated_clocks {clkdv}]

# Setup ADC (AD9361) interface constraints.
set cat_data_prog_dly               2.4;  # Programmable skew set to delay RX data by 2.4 ns
set cat_data_clk_to_data_out_min    0;
set cat_data_clk_to_data_out_max    1.2;

set_input_delay -clock [get_clocks CAT_DATA_CLK] -max [expr $cat_data_prog_dly + $cat_data_clk_to_data_out_max] [get_ports {CAT_P0_D* CAT_RX_FRAME}]
set_input_delay -clock [get_clocks CAT_DATA_CLK] -min [expr $cat_data_prog_dly + $cat_data_clk_to_data_out_min] [get_ports {CAT_P0_D* CAT_RX_FRAME}]
set_input_delay -clock [get_clocks CAT_DATA_CLK] -max [expr $cat_data_prog_dly + $cat_data_clk_to_data_out_max] [get_ports {CAT_P0_D* CAT_RX_FRAME}] -clock_fall -add_delay
set_input_delay -clock [get_clocks CAT_DATA_CLK] -min [expr $cat_data_prog_dly + $cat_data_clk_to_data_out_min] [get_ports {CAT_P0_D* CAT_RX_FRAME}] -clock_fall -add_delay

set cat_fb_data_prog_dly            4.5;  # Programmable skew set to delay TX data by 4.5 ns
set cat_fb_data_setup               1.0;
set cat_fb_data_hold                0;

set_output_delay -clock CAT_FB_CLK -max [expr $cat_fb_data_prog_dly + $cat_fb_data_setup] [get_ports {CAT_P1_D* CAT_TX_FRAME}]
set_output_delay -clock CAT_FB_CLK -min [expr $cat_fb_data_prog_dly - $cat_fb_data_hold]  [get_ports {CAT_P1_D* CAT_TX_FRAME}]
set_output_delay -clock CAT_FB_CLK -max [expr $cat_fb_data_prog_dly + $cat_fb_data_setup] [get_ports {CAT_P1_D* CAT_TX_FRAME}] -clock_fall -add_delay;
set_output_delay -clock CAT_FB_CLK -min [expr $cat_fb_data_prog_dly - $cat_fb_data_hold]  [get_ports {CAT_P1_D* CAT_TX_FRAME}] -clock_fall -add_delay;

# TCXO DAC SPI
# 12 MHz SPI clock rate
set_max_delay -datapath_only -to [get_ports TCXO_DAC*] -from [all_registers -edge_triggered] 40
set_min_delay                -to [get_ports TCXO_DAC*] -from [all_registers -edge_triggered] 1

###############################################################################
## Asynchronous paths
###############################################################################
set_false_path -from [get_ports CAT_CTRL_OUT]
set_false_path -to   [get_ports CAT_RESET]
set_false_path -to   [get_ports RX*_BANDSEL*]
set_false_path -to   [get_ports TX_BANDSEL*]
set_false_path -to   [get_ports TX_ENABLE*]
set_false_path -to   [get_ports LED_*]
set_false_path -to   [get_ports VCRX*]
set_false_path -to   [get_ports VCTX*]
