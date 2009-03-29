/*

thumb-ddis.cpp ... Thumb Dumb Disassembler front-end

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

*/

#include "DataFile.h"
#include "MachO_File.h"
#include "ThumbDumbDisassembler.h"

void print_section(const section* s) {
	printf(" ; %8x\t%08x\t%8x\t%s,%s\n", s->offset, s->addr, s->size, s->segname, s->sectname);
}

int main (int argc, char* argv[]) {
	if (argc < 2) {
		printf("thumb-ddis <filename> [<start-vmaddr> [<end-vmaddr>]]");
	} else {
		MachO_File f = MachO_File(argv[1]);
		
		printf(" ;  FileLoc\t  VMAddr\t    Size\tSectName\n");
		f.for_each_section(&print_section);

		ThumbDumbDisassembler d = ThumbDumbDisassembler(f);
		
		const section* text_section = f.section_having_name("__TEXT", "__text");
		
		unsigned start_vm, end_vm;
		if (text_section != NULL) {
			start_vm = text_section->addr;
			end_vm = text_section->addr + text_section->size - 2;
		} else {
			start_vm = 0;
			end_vm = 0;
		}
		
		if (argc >= 3)
			sscanf(argv[2], "%x", &start_vm);
		if (argc >= 4)
			sscanf(argv[3], "%x", &end_vm);
		
		d.disassemble_in_range(start_vm, end_vm-start_vm+2);
	}
	
	return 0;
}
