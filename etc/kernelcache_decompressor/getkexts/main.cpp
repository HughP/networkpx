/*

main.cpp ... getkexts
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

// g++ main.cpp -I../../hk.kennytm.Peace/include -I../../hk.kennytm.Peace/src -I/opt/local/include -m32 ../../hk.kennytm.Peace/src/DataFile.cpp ../../hk.kennytm.Peace/src/MachO_File.cpp ../../hk.kennytm.Peace/src/get_arch_from_flag.c -O2 -o getkexts

#include "MachO_File.h"
#include <cstdio>

using namespace std;

int main (int argc, const char* argv[]) {
	if (argc < 2)
		printf("getkexts [decompressed-kernelcache]\n");
	else {
		MachO_File_Simple f (argv[1]);
		
		if (!f.valid())
			printf("Not a Mach-O file.\n");
		else {
			const section* prelink_section = f.section_having_name("__PRELINK_TEXT", "__text");
			if (prelink_section == NULL)
				printf("Section __PRELINK_TEXT,__text not found.\n");
			else {
				f.seek(prelink_section->offset);
				
				off_t loc = f.tell();
				
				while (!f.is_eof() && f.search_forward("\xCE\xFA\xED\xFE\x0C\x00\x00\x00\x06\x00\x00\x00\x0B\x00\x00\x00", 16)) {
					off_t new_loc = f.tell();
					
					printf(".");
					
					char filename[32];
					snprintf(filename, 32, "%x", loc);
					FILE* g = fopen(filename, "wb");
					fwrite(f.peek_data_at<char>(loc), 1, new_loc - loc, g);
					fclose(g);
					
					loc = new_loc;
					
					f.advance(4);
				}
				
				if (!f.is_eof()) {
					printf(".");
					
					char filename[32];
					snprintf(filename, 32, "%x", loc);
					FILE* g = fopen(filename, "wb");
					fwrite(f.peek_data_at<char>(loc), 1, prelink_section->offset + prelink_section->size - loc, g);
					fclose(g);					
				}
				
				printf("\n");
			}
		}
	}
	
	return 0;
}