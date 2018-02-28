#!/usr/bin/env python3
#
# Copyright 2018 Ettus Research LLC
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#inj_rate
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

import os, sys
import argparse
import time
import glob
import csv
import re
import numpy as np

import matplotlib
#matplotlib.use('Agg')
import matplotlib.pyplot as plt

def get_options():
    parser = argparse.ArgumentParser(description='Generate Load Latency Graphs')
    parser.add_argument('--datadir', type=str, default='', help='IP Address of BEE7 device')
    # parser.add_argument('--sid',  type=int, default=-1, help='SID used for establishing connection (0 to 255)')
    # parser.add_argument('--bits', type=int, default=32, help='Transaction width')
    # parser.add_argument('--info', action='store_true', help='Report design info', default=False)
    return parser.parse_args()

TRAFFIC_PATTERNS = {'U':'UNIFORM', 'O':'UNIFORM_OTHERS', 'N':'NEIGHBOR', 'L':'LOOPBACK', 'S':'SEQUENTIAL', 'C':'BIT_COMPLEMENT', 'R':'RANDOM_PERM'}

class InfoFile():
    def __init__(self, filename):
        # Extract test info from filename
        m = re.search(r".*/info_inj([0-9]+)_lpp([0-9]+)_traffic(.)_sess([0-9]+)\.csv", filename)
        if m is None:
            raise ValueError('Incorrect filename format: %s'%(filename))
        self.inj_rate = int(m.group(1))
        self.lpp = int(m.group(2))
        self.traffic_patt = TRAFFIC_PATTERNS[m.group(3)]
        self.session = int(m.group(4))

        self.tx_pkts = 0
        self.rx_pkts = 0
        self.duration = 0
        self.errs = 0
        self.nodes = 0
        with open(filename, 'r') as csvfile:
            reader = csv.reader(csvfile, delimiter=',')
            isheader = True
            for row in reader:
                if isheader:
                    isheader = False
                    if row != ['Impl', 'Node', 'TxPkts', 'RxPkts', 'Duration', 'ErrRoute', 'ErrData']:
                        raise ValueError('Incorrect header: %s'%(filename))
                else:
                    self.impl = row[0]
                    self.tx_pkts = self.tx_pkts + int(row[2])
                    self.rx_pkts = self.tx_pkts + int(row[3])
                    self.duration = self.duration + int(row[4])
                    self.errs = self.errs + int(row[5]) + int(row[6])
                    self.nodes = self.nodes + 1
        self.real_inj_rate = (100.0 * self.tx_pkts * self.lpp) / self.duration

class PktFile():
    def __init__(self, filename):
        # Extract test info from filename
        m = re.search(r".*/pkts_node([0-9]+)_inj([0-9]+)_lpp([0-9]+)_traffic(.)_sess([0-9]+)\.csv", filename)
        if m is None:
            raise ValueError('Incorrect filename format: %s'%(filename))
        self.node = int(m.group(1))
        self.inj_rate = int(m.group(2))
        self.lpp = int(m.group(3))
        self.traffic_patt = TRAFFIC_PATTERNS[m.group(4)]
        self.session = int(m.group(5))

        self.latencies = []
        with open(filename, 'r') as csvfile:
            reader = csv.reader(csvfile, delimiter=',')
            isheader = True
            for row in reader:
                if isheader:
                    isheader = False
                    if row != ['Src', 'Dst', 'Seqno', 'Error', 'Latency']:
                        raise ValueError('Incorrect header: %s'%(filename))
                else:
                    self.latencies.append(int(row[4]))


########################################################################
# main
########################################################################
if __name__=='__main__':
    options = get_options()

    info_db = dict()
    info_files = glob.glob(options.datadir + '/info*.csv')
    router_impl = ''
    for ifile in info_files:
        print('Reading %s...'%(ifile))
        tmp = InfoFile(ifile)
        router_impl = tmp.impl  # Assume that all files have the same impl
        info_db[(tmp.lpp, tmp.traffic_patt, tmp.inj_rate)] = tmp

    pkt_db = dict()
    pkts_files = glob.glob(options.datadir + '/pkts*.csv')
    for pfile in pkts_files:
        print('Reading %s...'%(pfile))
        tmp = PktFile(pfile)
        config_key = (tmp.lpp, tmp.traffic_patt)
        if config_key not in pkt_db:
            pkt_db[config_key] = dict()
        if tmp.inj_rate not in pkt_db[config_key]:
            pkt_db[config_key][tmp.inj_rate] = []


        pkt_db[config_key][tmp.inj_rate].extend(tmp.latencies)


    actual_inj_rate_db = dict()
    for config in sorted(pkt_db):
        # Generate load-latency graph
        percentile = [0, 25, 50, 75, 90, 95, 99, 99.9, 100]
        (lpp, traffic_patt) = config
        plt.title('%s: Load Latency Graph (Traffic: %s, LPP: %d)'%(router_impl, traffic_patt, lpp))
        for p in percentile:
            plot_data = dict()
            for inj_rate in pkt_db[config]:
                real_inj_rate = info_db[(lpp, traffic_patt, inj_rate)].real_inj_rate
                plot_data[real_inj_rate] = np.percentile(pkt_db[config][inj_rate], p)
            latencies = []
            rates = []
            for inj_rate in sorted(plot_data):
                rates.append(inj_rate)
                latencies.append(plot_data[inj_rate])
            plt.plot(rates, latencies, label='$P_{%.1f}$'%(p))
            plt.xlabel('Load (%)')
            plt.xticks(range(0, 110, 10))
            plt.ylabel('Latency (cycles)')
            plt.grid(True)
        plt.legend()
        plt.show()
        # Generate actual inj_rate graph
        real_inj_rates = []
        for inj_rate in sorted(pkt_db[config]):
            real_inj_rates.append(info_db[(lpp, traffic_patt, inj_rate)].real_inj_rate)
        actual_inj_rate_db[config] = (sorted(pkt_db[config]), real_inj_rates)
    plt.title('%s: Max Injection Rate Graph'%(router_impl))
    for config in actual_inj_rate_db:
        (x, y) = actual_inj_rate_db[config]
        plt.plot(x, y, label=str(config))
        plt.xlabel('Offered Injection Rate (%)')
        plt.xticks(range(0, 110, 10))
        plt.ylabel('Accepted Injection Rate (%)')
        plt.yticks(range(0, 110, 10))
        plt.grid(True)
    plt.legend()
    plt.show()