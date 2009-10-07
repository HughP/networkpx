/*

main.c ... extract
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

#include <stdio.h>
#include <stdlib.h>

// gcc main.c -O2 -o extract

int main(int argc, const char* argv[]) {
	if (argc < 3) {
		printf("extract [decrypted-kernelcache] [compressed-kernel-exec]\n\n");
	} else {
		struct IMG3 {
			unsigned magic;
			unsigned fullSize;
			unsigned sizeNoPack;
			unsigned sigCheckArea;
			unsigned iden;
		} header;
				
		FILE* fin = fopen(argv[1], "rb");
		fread(&header, sizeof(header), 1, fin);
		if (header.magic != 0x496D6733)	// Img3
			printf("Input file is not an IMG3 container!\n");
		else if (header.iden != 0x6B726E6C)	// krnl
			printf("Input file is not a kernelcache!\n");
		else {
			while (!feof(fin)) {
				struct Tag {
					unsigned magic;
					unsigned totalLength;
					unsigned dataLength;
				} tag;
								
				fread(&tag, sizeof(tag), 1, fin);
				if (tag.magic != 0x44415441) // DATA
					fseek(fin, tag.totalLength-sizeof(tag), SEEK_CUR);
				else {
					FILE* fout = fopen(argv[2], "wb");
					
					void* data = malloc(tag.dataLength);
					fread(data, 1, tag.dataLength, fin);
					fwrite(data, 1, tag.dataLength, fout);
					
					free(data);
					fclose(fout);
					
					break;
				}
			}
		}
		fclose(fin);
	}
}