#!/usr/bin/env python
#
# Copyright 2011-2012 Ettus Research LLC
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
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

import sys
import re

def print_timing_constraint_summary(timing_rpt_file):
    output = ""
    keep = False
    done = False
    failed_timing = False
    try: open(timing_rpt_file)
    except IOError:
        print "cannot open or find %s; no timing summary to print!"%timing_rpt_file
        exit(-1)
    for line in open(timing_rpt_file).readlines():
        if 'Timing Summary Report' in line: keep = True
        if '| Timing Details' in line: done = True
        if 'Timing constraints are not met.' in line: failed_timing = True
        if done: break
        if keep: output += line
    print("\n"+output)
    if failed_timing: print("\nWARNING!!!: Timing constraints were not met.\n")

if __name__=='__main__': map(print_timing_constraint_summary, sys.argv[1:])
