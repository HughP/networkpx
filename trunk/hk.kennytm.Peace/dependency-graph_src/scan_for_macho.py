#!/usr/bin/python

"""
scan_for_macho.py ... Scan for all potential Mach-O files in a root path.

Copyright (C) 2009  KennyTM~

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
"""

import os, sys

if len(sys.argv) < 2:
	print("Usage: scan_for_macho.py <sysroot>")
	exit()

def is_macho(fn):
	try:
		f = open(fn, 'rb', 4)
		magic = f.read(4)
		retval = (magic == "\xCA\xFE\xBA\xBE" or magic == "\xCE\xFA\xED\xFE")
		f.close()
		return retval
	except Exception:
		return False

for (root, subdirs, filenames) in os.walk(sys.argv[1]):
	for fn in filenames:
		actual_fn = os.path.join(root, fn)
		if is_macho(actual_fn):
			print(actual_fn)
	