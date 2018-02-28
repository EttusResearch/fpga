#! /usr/bin/python3
#!/usr/bin/python3
#
# Copyright 2018 Ettus Research, a National Instruments Company
#
# SPDX-License-Identifier: LGPL-3.0-or-later
#

import sys, os
import argparse
import subprocess

# Parse command line options
def get_options():
    parser = argparse.ArgumentParser(description='Generate ')
    parser.add_argument('--top', type=str, default='TORUS', help='Topologies (CSV)')
    parser.add_argument('--dimw', type=str, default='4', help='Router dimension width (CSV)')
    parser.add_argument('--dataw', type=str, default='32', help='Router datapath width (CSV)')
    parser.add_argument('--mtu', type=str, default='5', help='MTU (CSV)')
    parser.add_argument('--ralloc', type=str, default='WORMHOLE', help='Router allocation method (CSV)')
    parser.add_argument('--salloc', type=str, default='PRIO', help='Switch allocation algorithm (CSV)')
    return parser.parse_args()

def launch_run(top, dimw, dataw, mtu, ralloc, salloc):
    # Collect parameters
    transform = {'dimw':dimw, 'dataw':dataw, 'mtu':mtu, 
        'top':'"%s"'%(top), 'ralloc':'"%s"'%(ralloc), 'salloc':'"%s"'%(salloc)}
    prefix = '_'.join(['%s%s'%(k,str(v).strip('"')) for k, v in sorted(transform.items(), reverse=True)])
    print('='*80)
    print(' STARTING RUN %s'%(prefix))
    print('='*80)
    # Write Verilog top-level file
    with open('ctrl_crossbar_top.v.in', 'r') as in_file:
        with open('ctrl_crossbar_top.v', 'w') as out_file:
            out_file.write(in_file.read().format(**transform))
    # Run Vivado
    subprocess.Popen('vivado -mode tcl -source synth_module.tcl -nolog -nojou', shell=True).wait()
    # Save report
    os.rename('router_util.rpt', prefix + '.util_rpt')
    os.rename('router_timing.rpt', prefix + '.timing_rpt')
    os.rename('router_synth.dcp', prefix + '.dcp')
    os.remove('ctrl_crossbar_top.v')

def main():
    args = get_options();
    for top in args.top.strip().split(','):
        for dimw in args.dimw.strip().split(','):
            for dataw in args.dataw.strip().split(','):
                for mtu in args.mtu.strip().split(','):
                    for ralloc in args.ralloc.strip().split(','):
                        for salloc in args.salloc.strip().split(','):
                            launch_run(top, int(dimw), int(dataw), int(mtu), ralloc, salloc)

if __name__ == '__main__':
    main()
