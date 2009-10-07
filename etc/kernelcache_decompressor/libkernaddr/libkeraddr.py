#!/opt/local/bin/python

#libkeraddr.py ... Partially symbolicate a kext.
#Copyright (C) 2009  KennyTM~ <kennytm@gmail.com>
#
#This program is free software: you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation, either version 3 of the License, or
#(at your option) any later version.
#
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with this program.  If not, see <http://www.gnu.org/licenses/>.

import sys
import re
from tempfile import mkstemp
import os

def thumb_last_digit(x):
	last_digit = chr(ord(x[-1])+1)
	return x[:-1] + last_digit
	
def main(argv=None):
	if argv is None:
		argv = sys.argv
	if len(argv) < 3:
		print ("Usage: libkeraddr.py [ravel-armed-file] [result-of-nm-kernelcache]")
	else:
		sym_matcher = re.compile("^([0-9a-f]+) \\w (.+)$")
		sym_searcher = {}
		
		with open(argv[2]) as syms:
			for line in syms:
				match = sym_matcher.match(line)
				if match is not None:
					sym_searcher[match.group(1)] = match.group(2)
					sym_searcher[thumb_last_digit(match.group(1))] = match.group(2)
				
		call_matcher = re.compile("(?:0x)(c0[01][0-9a-f]{5})")

		tempfn = None
		with open(argv[1]) as dec:
			(fout, tempfn) = mkstemp()
			for line in dec:
				match = call_matcher.search(line)
				if match is not None:
					line = line[:match.start()] + sym_searcher[match.group(1)] + line[match.end():]
				os.write(fout, line)
			os.close(fout)
			
		if tempfn is not None:
			os.rename(tempfn, argv[1])

if __name__ == "__main__":
	main()
