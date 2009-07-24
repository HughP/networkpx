/*

FILE_NAME ... DESCRIPTION

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

#include "MachO_File.h"
#include <cstdio>
#include <fstream>
#include <sys/mman.h>
#include <string>
#include <vector>
#include <tr1/unordered_map>
#include <cstring>
#include <map>
#include "string_util.h"
using namespace std;

struct BinaryImage {
	char arch[16];
	string path;
};

int main (int argc, const char* argv[]) {
	if (argc == 1) {
		fprintf(stderr, "Usage: symbolicate <crash-log-plist>\n\n");
		return 0;
	}
	
	// 1. Read paths as strings.
	vector<string> lines;
	tr1::unordered_map<unsigned, BinaryImage> binaries;
	
	unsigned binary_image_index = ~0u, first_thread_index = ~0u;
	
	{
		ifstream fin (argv[1]);
		unsigned i = 0;
		int reading_binaries = 0;
		
		while (!!fin) {
			string str;
			getline(fin, str);
			
			if (first_thread_index == ~0u && str.substr(0, 7) == "Thread ")
				first_thread_index = i;
			else if (reading_binaries == 0 && str == "Binary Images:") {
				reading_binaries = 1;
				binary_image_index = i;
			} else if (reading_binaries == 1) {
				if (str == "</string>")
					reading_binaries = 2;
				else {
					int start;
					char arch[16];
					int curpos;
					int scanres;
					if (str.find("&gt;") != string::npos)
						scanres = sscanf(str.c_str(), " 0x%x - 0x%*x %*s %15s &lt;%*32s&gt; %n", &start, arch, &curpos);
					else
						scanres = sscanf(str.c_str(), " 0x%x - 0x%*x %*s %15s %n", &start, arch, &curpos);
						
					if (scanres != 0) {
						BinaryImage img;
						strncpy(img.arch, arch, 16);
						img.path = str.substr(curpos);
						binaries.insert(pair<unsigned,BinaryImage>(start, img));
					}
				}
			}
			
			++ i;
			
			lines.push_back(str);
		}
	}
	
	// From the stack trace, read all involved binary images.
	tr1::unordered_map<unsigned, pair<MachO_File*, int> > images;
	
	for (unsigned i = 0; i < lines.size(); ++ i) {
		printf("%s", lines[i].c_str());
		
		if (i >= first_thread_index && i < binary_image_index) {
			int start, addr;
			if (sscanf(lines[i].c_str(), "%*d %*s 0x%x 0x%x", &addr, &start) == 2) {
				tr1::unordered_map<unsigned, pair<MachO_File*, int> >::iterator cit = images.find(start);
				if (cit == images.end()) {
					// look up the path of this image.
					BinaryImage binary = binaries[start];
					MachO_File* file;
					try {
						file = new MachO_File(binary.path.c_str(), binary.arch);
					} catch (TRException) {
						file = new MachO_File(binary.path.c_str());
					}
					if (file == NULL)
						continue;
					
					int slide = start - file->text_segment_vm_adress();
					
					cit = images.insert(pair<unsigned, pair<MachO_File*, int> >(start, pair<MachO_File*, int>(file, slide))).first;
				}
				
				pair<MachO_File*, int> file_slide = cit->second;
				unsigned offset;
				const char* strrep = file_slide.first->nearest_string_representation(addr - file_slide.second, &offset);
				if (strrep != NULL)
					printf("\t// %s + 0x%04x", strrep, offset);
			}
		}
		
		printf("\n");
	}
	
	for (tr1::unordered_map<unsigned, pair<MachO_File*, int> >::iterator cit = images.begin(); cit != images.end(); ++ cit)
		delete cit->second.first;
			
	return 0;
}