#!/usr/bin/python3
#
# Copyright 2018 Ettus Research, a National Instruments Company
#
# SPDX-License-Identifier: LGPL-3.0-or-later
#

# Blocks
# 0: Core
# 1: SEP0
# 2: SEP1
# 3: Block0
# 4: Block1

edges = ([
	((1,0), (3,0)),	# SEP0 -> Block0_Port0
	((3,0), (1,0)),	# Block0_Port0 -> SEP0
	((2,0), (4,0)),	# SEP1 -> Block1_Port0
	((4,0), (2,0)),	# Block1_Port0 -> SEP1
	((3,1), (4,1)),	# Block0_Port1 -> Block1_Port1
	((4,1), (3,1)),	# Block1_Port1 -> Block0_Port1
])

def flatten(tup):
	src = tup[0]
	dst = tup[1]
	return (((src[0]<<6)|src[1])<<16)|((dst[0]<<6)|dst[1])

print('%08x' % len(edges))
for e in edges:
	print('%08x' % flatten(e))
