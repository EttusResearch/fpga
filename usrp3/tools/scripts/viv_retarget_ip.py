#!/usr/bin/python

import optparse
import os
import re

# Parse options
parser = optparse.OptionParser()
parser.add_option("--arch", type="string", dest="arch", help="Architecture to retarget IP to. Examples: zynq, kintex7, artix7", default="")
parser.add_option("--part", type="string", dest="part", help="Part ID to retarget IP to. Must be of the form <device>/<package>/<speedgrade>", default="")
parser.add_option("--output_dir", type="string", dest="output_dir", help="Build directory for IP", default="")
(options, args) = parser.parse_args()

# Args
if (len(args) < 1):
	print 'ERROR: Please specify an input IP XCI file'
	parser.print_help()
	sys.exit(1)
arch = options.arch
if (len(arch) == 0):
	print 'ERROR: Please specify an architecture'
	parser.print_help()
	sys.exit(1)
part_info = str.split(options.part, '/')
if (len(part_info) != 3):
	print 'ERROR: Part name ' + options.part + ' is invalid.'
	parser.print_help()
	sys.exit(1)
if (options.output_dir is None or not os.path.isdir(options.output_dir)):
	print 'ERROR: IP Build directory ' + options.build_dir + ' could not be accessed or is not a directory.'
	parser.print_help()
	sys.exit(1)

in_xci_filename = os.path.abspath(args[0])
out_xci_filename = os.path.join(os.path.abspath(options.output_dir), os.path.basename(in_xci_filename))
if (not os.path.isfile(in_xci_filename)):
	print 'ERROR: XCI File ' + in_xci_filename + ' could not be accessed or is not a file.'
	parser.print_help()
	sys.exit(1)

# Read XCI File
with open(in_xci_filename) as in_file:
	xci_lines = in_file.readlines()
in_file.close()

def get_match_str(item):
	return 	'(.*\<spirit:configurableElementValue spirit:referenceId=\".*\.' \
			+ item + '\"\>).*(\</spirit:configurableElementValue\>)'

replace_dict = {'ARCHITECTURE': arch, 'DEVICE': part_info[0], 'PACKAGE': part_info[1], 'SPEEDGRADE': part_info[2], \
                'C_XDEVICEFAMILY': arch, 'C_FAMILY': arch, 'C_XDEVICE': part_info[0]}

# Write XCI File
with open(out_xci_filename, 'w') as out_file:
	for r_line in xci_lines:
		w_line = r_line
		for key in replace_dict:
			m = re.search(get_match_str(key), r_line)
			if m is not None:
				w_line = m.group(1) + replace_dict[key] + m.group(2) + '\n'
				break
		out_file.write(w_line)
out_file.close()
