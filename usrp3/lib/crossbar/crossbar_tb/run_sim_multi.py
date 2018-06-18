#!/usr/bin/python3
#
# Copyright 2018 Ettus Research, a National Instruments Company
#
# SPDX-License-Identifier: LGPL-3.0-or-later
#
# Description
#   Run the crossbar testbench (crossbar_tb) for varios parameter
#   configurations and generates load-latency graphs for each run.

import argparse
import math
import os, sys
import shutil
import glob
import subprocess

g_localparam_template = """  // Router parameters
  localparam ROUTER_IMPL        = "{rtr_impl}";
  localparam ROUTER_PORTS_SQRT  = {rtr_ports_sqrt};
  localparam ROUTER_PORTS       = {rtr_ports};
  localparam ROUTER_DWIDTH      = 64;
  localparam MTU_LOG2           = {rtr_mtu};
  localparam NUM_MASTERS        = {rtr_sources};
  // Test parameters
  localparam TEST_MAX_PACKETS   = {tst_maxpkts};
  localparam TEST_LPP           = {tst_lpp};
  localparam TEST_MIN_INJ_RATE  = {tst_injrate_min};
  localparam TEST_MAX_INJ_RATE  = {tst_injrate_max};
  localparam TEST_INJ_RATE_INCR = 10;
  localparam TEST_GEN_LL_FILES  = 1;
"""

g_test_params = {
    'data': {'rtr_mtu':7, 'tst_maxpkts':100, 'tst_lpp':100, 'tst_injrate_min':30, 'tst_injrate_max':100},
    'ctrl': {'rtr_mtu':5, 'tst_maxpkts':100, 'tst_lpp':10,  'tst_injrate_min':10, 'tst_injrate_max':50},
}

g_xb_types = {
    'chdr_crossbar_nxn':'data', 'axi_crossbar':'data',
    'axis_ctrl_2d_torus':'ctrl', 'axis_ctrl_2d_mesh':'ctrl'
}

def get_options():
    parser = argparse.ArgumentParser(description='Run correctness sim and generate load-latency plots')
    parser.add_argument('--impl', type=str, default='chdr_crossbar_nxn', help='Implementation (CSV) [%s]'%(','.join(g_xb_types.keys())))
    parser.add_argument('--ports', type=str, default='16', help='Number of ports (CSV)')
    parser.add_argument('--sources', type=str, default='16', help='Router datapath width (CSV)')
    return parser.parse_args()

def launch_run(impl, ports, sources):
    run_name = '%s_ports%d_srcs%d'%(impl, ports, sources)
    # Prepare a transform map to autogenerate a TB file
    transform = {'rtr_impl':impl, 'rtr_ports':ports, 'rtr_ports_sqrt':str(math.ceil(math.sqrt(ports))), 'rtr_sources':sources}
    for k,v in g_test_params[g_xb_types[impl]].items():
        transform[k] = v 
    # Read crossbar_tb.sv and create crossbar_tb_auto.sv with new parameters
    with open('crossbar_tb.sv', 'r') as in_file:
        in_lines = in_file.readlines()
    echo = 1
    with open('crossbar_tb_auto.sv', 'w') as out_file:
        for l in in_lines:
            if '</PARAMS_BLOCK_AUTOGEN>' in l:
                echo = 1
            if echo:
                out_file.write(l)
            if '<PARAMS_BLOCK_AUTOGEN>' in l:
                out_file.write(g_localparam_template.format(**transform))
                echo = 0
    # Create data directory for the simulation
    data_dir = os.path.join('data', impl)
    export_dir = os.path.join('data', run_name)
    try:
        os.makedirs('data')
    except FileExistsError:
        pass
    os.makedirs(data_dir)
    os.makedirs(export_dir)
    # Run "make xsim"
    exitcode = subprocess.Popen('make xsim TB_TOP_FILE=crossbar_tb_auto.sv', shell=True).wait()
    if exitcode != 0:
        raise RuntimeError('Error running "make xsim". Was setupenv.sh run?')
    # Generate load-latency graphs
    exitcode = subprocess.Popen('gen_load_latency_graph.py ' + data_dir, shell=True).wait()
    if exitcode != 0:
        raise RuntimeError('Error running "gen_load_latency_graph.py"')
    # Copy files
    os.rename('xsim.log', os.path.join(export_dir, 'xsim.log'))
    for file in glob.glob(os.path.join(data_dir, '*.png')):
        shutil.copy(file, export_dir)
    # Cleanup outputs
    subprocess.Popen('make cleanall', shell=True).wait()
    try:
        os.remove('crossbar_tb_auto.sv')
    except FileNotFoundError:
        pass
    try:
        shutil.rmtree(data_dir)
    except OSError:
        print('WARNING: Could not delete ' + data_dir)

def main():
    args = get_options();
    for impl in args.impl.strip().split(','):
        for ports in args.ports.strip().split(','):
            for sources in args.sources.strip().split(','):
                launch_run(impl, int(ports), min(int(ports), int(sources)))

if __name__ == '__main__':
    main()
