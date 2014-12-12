#
# Copyright 2014 Ettus Research LLC
#

set_property PACKAGE_PIN AE10               [get_ports {sys_clk_i}]
set_property IOSTANDARD  LVCMOS15           [get_ports {sys_clk_i}]

set_property PACKAGE_PIN AD3                [get_ports {ddr3_dq[0]}]
set_property PACKAGE_PIN AC2                [get_ports {ddr3_dq[1]}]
set_property PACKAGE_PIN AC1                [get_ports {ddr3_dq[2]}]
set_property PACKAGE_PIN AC5                [get_ports {ddr3_dq[3]}]
set_property PACKAGE_PIN AC4                [get_ports {ddr3_dq[4]}]
set_property PACKAGE_PIN AD6                [get_ports {ddr3_dq[5]}]
set_property PACKAGE_PIN AE6                [get_ports {ddr3_dq[6]}]
set_property PACKAGE_PIN AC7                [get_ports {ddr3_dq[7]}]
set_property PACKAGE_PIN AF2                [get_ports {ddr3_dq[8]}]
set_property PACKAGE_PIN AE1                [get_ports {ddr3_dq[9]}]
set_property PACKAGE_PIN AF1                [get_ports {ddr3_dq[10]}]
set_property PACKAGE_PIN AE4                [get_ports {ddr3_dq[11]}]
set_property PACKAGE_PIN AE3                [get_ports {ddr3_dq[12]}]
set_property PACKAGE_PIN AE5                [get_ports {ddr3_dq[13]}]
set_property PACKAGE_PIN AF5                [get_ports {ddr3_dq[14]}]
set_property PACKAGE_PIN AF6                [get_ports {ddr3_dq[15]}]
set_property PACKAGE_PIN AJ4                [get_ports {ddr3_dq[16]}]
set_property PACKAGE_PIN AH6                [get_ports {ddr3_dq[17]}]
set_property PACKAGE_PIN AH5                [get_ports {ddr3_dq[18]}]
set_property PACKAGE_PIN AH2                [get_ports {ddr3_dq[19]}]
set_property PACKAGE_PIN AJ2                [get_ports {ddr3_dq[20]}]
set_property PACKAGE_PIN AJ1                [get_ports {ddr3_dq[21]}]
set_property PACKAGE_PIN AK1                [get_ports {ddr3_dq[22]}]
set_property PACKAGE_PIN AJ3                [get_ports {ddr3_dq[23]}]
set_property PACKAGE_PIN AF7                [get_ports {ddr3_dq[24]}]
set_property PACKAGE_PIN AG7                [get_ports {ddr3_dq[25]}]
set_property PACKAGE_PIN AJ6                [get_ports {ddr3_dq[26]}]
set_property PACKAGE_PIN AK6                [get_ports {ddr3_dq[27]}]
set_property PACKAGE_PIN AJ8                [get_ports {ddr3_dq[28]}]
set_property PACKAGE_PIN AK8                [get_ports {ddr3_dq[29]}]
set_property PACKAGE_PIN AK5                [get_ports {ddr3_dq[30]}]
set_property PACKAGE_PIN AK4                [get_ports {ddr3_dq[31]}]
set_property IOSTANDARD  SSTL15_T_DCI       [get_ports {ddr3_dq[*]}]

set_property PACKAGE_PIN AC12               [get_ports {ddr3_addr[0]}]
set_property PACKAGE_PIN AE8                [get_ports {ddr3_addr[1]}]
set_property PACKAGE_PIN AD8                [get_ports {ddr3_addr[2]}]
set_property PACKAGE_PIN AC10               [get_ports {ddr3_addr[3]}]
set_property PACKAGE_PIN AB10               [get_ports {ddr3_addr[4]}]
set_property PACKAGE_PIN AB13               [get_ports {ddr3_addr[5]}]
set_property PACKAGE_PIN AA13               [get_ports {ddr3_addr[6]}]
set_property PACKAGE_PIN AA10               [get_ports {ddr3_addr[7]}]
set_property PACKAGE_PIN AA11               [get_ports {ddr3_addr[8]}]
set_property PACKAGE_PIN Y10                [get_ports {ddr3_addr[9]}]
set_property PACKAGE_PIN Y11                [get_ports {ddr3_addr[10]}]
set_property PACKAGE_PIN AB8                [get_ports {ddr3_addr[11]}]
set_property PACKAGE_PIN AA8                [get_ports {ddr3_addr[12]}]
set_property PACKAGE_PIN AB12               [get_ports {ddr3_addr[13]}]
set_property PACKAGE_PIN AA12               [get_ports {ddr3_addr[14]}]
set_property IOSTANDARD  SSTL15             [get_ports {ddr3_addr[*]}]

set_property PACKAGE_PIN AE9                [get_ports {ddr3_ba[0]}]
set_property PACKAGE_PIN AD9                [get_ports {ddr3_ba[1]}]
set_property PACKAGE_PIN AC11               [get_ports {ddr3_ba[2]}]
set_property IOSTANDARD  SSTL15             [get_ports {ddr3_ba[*]}]

set_property PACKAGE_PIN AE11               [get_ports {ddr3_ras_n}]
set_property IOSTANDARD  SSTL15             [get_ports {ddr3_ras_n}]

set_property PACKAGE_PIN AF11               [get_ports {ddr3_cas_n}]
set_property IOSTANDARD  SSTL15             [get_ports {ddr3_cas_n}]

set_property PACKAGE_PIN AD12               [get_ports {ddr3_we_n}]
set_property IOSTANDARD  SSTL15             [get_ports {ddr3_we_n}]

set_property PACKAGE_PIN AG5                [get_ports {ddr3_reset_n}]
set_property IOSTANDARD  LVCMOS15           [get_ports {ddr3_reset_n}]

set_property PACKAGE_PIN AJ9                [get_ports {ddr3_cke[0]}]
set_property IOSTANDARD  SSTL15             [get_ports {ddr3_cke*}]

set_property PACKAGE_PIN AK9                [get_ports {ddr3_odt[0]}]
set_property IOSTANDARD  SSTL15             [get_ports {ddr3_odt*}]

set_property PACKAGE_PIN AD11               [get_ports {ddr3_cs_n[0]}]
set_property IOSTANDARD  SSTL15             [get_ports {ddr3_cs_n*}]

set_property PACKAGE_PIN AD4                [get_ports {ddr3_dm[0]}]
set_property PACKAGE_PIN AF3                [get_ports {ddr3_dm[1]}]
set_property PACKAGE_PIN AH4                [get_ports {ddr3_dm[2]}]
set_property PACKAGE_PIN AF8                [get_ports {ddr3_dm[3]}]
set_property IOSTANDARD  SSTL15             [get_ports {ddr3_dm[*]}]

set_property PACKAGE_PIN AD2                [get_ports {ddr3_dqs_p[0]}]
set_property PACKAGE_PIN AD1                [get_ports {ddr3_dqs_n[0]}]
set_property PACKAGE_PIN AG4                [get_ports {ddr3_dqs_p[1]}]
set_property PACKAGE_PIN AG3                [get_ports {ddr3_dqs_n[1]}]
set_property PACKAGE_PIN AG2                [get_ports {ddr3_dqs_p[2]}]
set_property PACKAGE_PIN AH1                [get_ports {ddr3_dqs_n[2]}]
set_property PACKAGE_PIN AH7                [get_ports {ddr3_dqs_p[3]}]
set_property PACKAGE_PIN AJ7                [get_ports {ddr3_dqs_n[3]}]
set_property IOSTANDARD  DIFF_SSTL15_T_DCI  [get_ports {ddr3_dqs_*}]

set_property PACKAGE_PIN AB9                [get_ports {ddr3_ck_p[0]}]
set_property PACKAGE_PIN AC9                [get_ports {ddr3_ck_n[0]}]
set_property IOSTANDARD  DIFF_SSTL15        [get_ports {ddr3_ck_*}]

# VCCAUX_IO property is all or nothing based on bank Vccauxio voltage
set_property VCCAUX_IO   NORMAL             [get_ports {ddr3_*}]
set_property SLEW        FAST               [get_ports {ddr3_*}]

# Clocks
create_clock -name DRAM_SYS_CLK     -period 10.000 -waveform {0.000 5.000} [get_ports {sys_clk_i}]
create_clock -name DRAM_ISERDES_CLK -period  2.000 -waveform {0.000 1.000} [get_nets -hier -filter {NAME =~ *ddr3_32bit*_mig/iserdes_clk}]

# Note: the following CLOCK_DEDICATED_ROUTE constraint will cause a warning in place similar
# to the following:
#   WARNING:Place:1402 - A clock IOB / PLL clock component pair have been found that are not
#   placed at an optimal clock IOB / PLL site pair.
set_property CLOCK_DEDICATED_ROUTE BACKBONE [get_nets -hier -filter {NAME =~ "*sys_clk_ibufg*"}]
set_property CLOCK_DEDICATED_ROUTE BACKBONE [get_pins -hier -filter {NAME =~ "*ddr3_32bit*pll*clk*/I"}]

set_property LOC PLLE2_ADV_X1Y1         [get_cells -hier -filter {NAME =~ */u_ddr3_infrastructure/plle2_i}]
set_property LOC MMCME2_ADV_X1Y1        [get_cells -hier -filter {NAME =~ */u_ddr3_infrastructure*mmcm_i}]

set_property LOC PHASER_OUT_PHY_X1Y7    [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_1.u_ddr_phy_4lanes/ddr_byte_lane_D.ddr_byte_lane_D/phaser_out}]
set_property LOC PHASER_OUT_PHY_X1Y6    [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_1.u_ddr_phy_4lanes/ddr_byte_lane_C.ddr_byte_lane_C/phaser_out}]
set_property LOC PHASER_OUT_PHY_X1Y5    [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_1.u_ddr_phy_4lanes/ddr_byte_lane_B.ddr_byte_lane_B/phaser_out}]
set_property LOC PHASER_OUT_PHY_X1Y11   [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_D.ddr_byte_lane_D/phaser_out}]
set_property LOC PHASER_OUT_PHY_X1Y10   [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_C.ddr_byte_lane_C/phaser_out}]
set_property LOC PHASER_OUT_PHY_X1Y9    [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_B.ddr_byte_lane_B/phaser_out}]
set_property LOC PHASER_OUT_PHY_X1Y8    [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_A.ddr_byte_lane_A/phaser_out}]

set_property LOC PHASER_IN_PHY_X1Y11    [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_D.ddr_byte_lane_D/phaser_in_gen.phaser_in}]
set_property LOC PHASER_IN_PHY_X1Y10    [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_C.ddr_byte_lane_C/phaser_in_gen.phaser_in}]
set_property LOC PHASER_IN_PHY_X1Y9     [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_B.ddr_byte_lane_B/phaser_in_gen.phaser_in}]
set_property LOC PHASER_IN_PHY_X1Y8     [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_A.ddr_byte_lane_A/phaser_in_gen.phaser_in}]

set_property LOC OUT_FIFO_X1Y7          [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_1.u_ddr_phy_4lanes/ddr_byte_lane_D.ddr_byte_lane_D/out_fifo}]
set_property LOC OUT_FIFO_X1Y6          [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_1.u_ddr_phy_4lanes/ddr_byte_lane_C.ddr_byte_lane_C/out_fifo}]
set_property LOC OUT_FIFO_X1Y5          [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_1.u_ddr_phy_4lanes/ddr_byte_lane_B.ddr_byte_lane_B/out_fifo}]
set_property LOC OUT_FIFO_X1Y11         [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_D.ddr_byte_lane_D/out_fifo}]
set_property LOC OUT_FIFO_X1Y10         [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_C.ddr_byte_lane_C/out_fifo}]
set_property LOC OUT_FIFO_X1Y9          [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_B.ddr_byte_lane_B/out_fifo}]
set_property LOC OUT_FIFO_X1Y8          [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_A.ddr_byte_lane_A/out_fifo}]

set_property LOC IN_FIFO_X1Y11          [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_D.ddr_byte_lane_D/in_fifo_gen.in_fifo}]
set_property LOC IN_FIFO_X1Y10          [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_C.ddr_byte_lane_C/in_fifo_gen.in_fifo}]
set_property LOC IN_FIFO_X1Y9           [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_B.ddr_byte_lane_B/in_fifo_gen.in_fifo}]
set_property LOC IN_FIFO_X1Y8           [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_A.ddr_byte_lane_A/in_fifo_gen.in_fifo}]

set_property LOC PHY_CONTROL_X1Y1       [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_1.u_ddr_phy_4lanes/phy_control_i}]
set_property LOC PHY_CONTROL_X1Y2       [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/phy_control_i}]
set_property LOC PHASER_REF_X1Y1        [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_1.u_ddr_phy_4lanes/phaser_ref_i}]
set_property LOC PHASER_REF_X1Y2        [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/phaser_ref_i}]

set_property LOC OLOGIC_X1Y143          [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_D.ddr_byte_lane_D/ddr_byte_group_io/*slave_ts}]
set_property LOC OLOGIC_X1Y131          [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_C.ddr_byte_lane_C/ddr_byte_group_io/*slave_ts}]
set_property LOC OLOGIC_X1Y119          [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_B.ddr_byte_lane_B/ddr_byte_group_io/*slave_ts}]
set_property LOC OLOGIC_X1Y107          [get_cells -hier -filter {NAME =~ */ddr_phy_4lanes_0.u_ddr_phy_4lanes/ddr_byte_lane_A.ddr_byte_lane_A/ddr_byte_group_io/*slave_ts}]

set_multicycle_path -from [get_cells -hier -filter {NAME =~ */mc0/mc_read_idle_r_reg}]          \
                    -to   [get_cells -hier -filter {NAME =~ */input_[?].iserdes_dq_.iserdesdq}] \
                    -setup 6

set_multicycle_path -from [get_cells -hier -filter {NAME =~ */mc0/mc_read_idle_r_reg}]          \
                    -to   [get_cells -hier -filter {NAME =~ */input_[?].iserdes_dq_.iserdesdq}] \
                    -hold  5

set_false_path -through [get_pins -filter {NAME =~ */DQSFOUND}                  \
               -of      [get_cells -hier -filter {REF_NAME == PHASER_IN_PHY}]]

set_multicycle_path -through [get_pins -filter {NAME =~ */OSERDESRST}           \
                    -of [get_cells -hier -filter {REF_NAME == PHASER_OUT_PHY}]] \
                    -setup 2 -start

set_multicycle_path -through [get_pins -filter {NAME =~ */OSERDESRST}                 \
                    -of      [get_cells -hier -filter {REF_NAME == PHASER_OUT_PHY}]]  \
                    -hold  1 -start
