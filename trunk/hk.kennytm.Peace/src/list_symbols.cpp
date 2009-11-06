/*

list_symbols.cpp ... List symbols
Copyright (C) 2009  KennyTM~ <kennytm@gmail.com>

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

*/

#include "MachO_File.h"
#include <cstdio>
#include <cstring>

static const char tns[] = {'Y', 'F', 'C', 'S', 'K', 'P', 'I', 'M'};
static const char* const lefts[] = {
	"",
	"CFSTR(\"",
	"\"",
	"@selector(",
	"(Class)",
	"(Protocol*)",
	"",
	""
};
static const char* const rights[] = {
	"",
	"\")",
	"\"",
	")",
	"",
	"",
	"",
	""
};

static void g(unsigned addr, const char* symbol, MachO_File::StringType type, void* context) {
	printf("%08x %c %s%s%s\n", addr, tns[type], lefts[type], symbol, rights[type]);
}

int main (int argc, const char* argv[]) {
	if (argc == 1) {
		std::printf("Usage: list_symbols [-arch <arch>] <file>\n");
	} else {
		const char* filename = NULL, *arch = "any";
		bool read_arch = false;
		
		for (int i = 1; i < argc; ++ i) {
			if (std::strcmp(argv[i], "-arch") == 0) {
				read_arch = true;
			} else {
				if (read_arch) {
					arch = argv[i];
					read_arch = false;
				} else {
					filename = argv[i];
				}
			}
		}
		
		if (filename) {
			MachO_File f (filename, arch);
			f.for_each_symbol(g, &f);
		}
	}
}