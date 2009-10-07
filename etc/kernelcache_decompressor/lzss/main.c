/*
 
 main.c ... lzss
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

// gcc -O2 -I. *.c -o lzss

#include "lzssfile.h"
#include <stdio.h>

int main (int argc, const char* argv[]) {
	if (argc < 3)
		printf("Usage: lzss [decrypted-kernel-cache] [output]");
	else {
		AbstractFile* g = createAbstractFileFromFile(fopen(argv[1], "rb"));
		AbstractFile* f = createAbstractFileFromComp(g);
		AbstractFile* o = createAbstractFileFromFile(fopen(argv[2], "wb"));
		
		size_t inDataSize = (size_t) f->getLength(f);
		char* inData = (char*) malloc(inDataSize);
		f->read(f, inData, inDataSize);
		f->close(f);
		
		o->write(o, inData, inDataSize);
		o->close(o);
		
		free(inData);
	}
	
	return 0;
}
