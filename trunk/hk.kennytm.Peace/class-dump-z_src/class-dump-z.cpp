/*

class-dump-z ... Advanced Class-dump for  Objective-C 2.0

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

#include "MachO_File_ObjC.h"
#include <getopt.h>
#include <cstdio>
//#include <tr1/regex>	// tr1/regex is not supported by GCC even in 4.4 :( Use PCRE instead.
#include <pcre.h>
#include <cstring>

using namespace std;

void print_usage () {
	fprintf(stderr,
			"Usage: class-dump-z [<options>] <filename>\n"
			"\n"
			"where options are:\n"
			"	-a         Print ivar offsets\n"
			"	-A         Print implementation VM addresses.\n"
			"	-p         Show methods which are actually properties.\n"
			"	-C <regex> Only display types with (original) name matching the RegExp (in PCRE syntax).\n"
			"	-I         Sort types by inheritance / adoption order.\n" 
			"	-S         Sort types in alphabetical order.\n" 
			"	-D <char>  Print internal diagnosis data, with\n"
			"	              u = reachability matrix & usage graph\n"
			"	              s = struct indices\n"
			);
}

int main (int argc, char* argv[]) {
	if (argc == 1) {
		print_usage();
	} else {
		int c;
		bool print_ivar_offsets = false, print_method_addresses = false, print_comments = false;
		bool print_reachability_matrix = false, print_struct_indices = false;
		const char* sysroot = "";
		const char* regexp_string = NULL;
		MachO_File_ObjC::SortBy sortBy = MachO_File_ObjC::SB_None;
		while ((c = getopt(argc, argv, "aApC:ISD:")) != -1) {
			switch (c) {
				case 'a':
					print_ivar_offsets = true;
					break;
				case 'A':
					print_method_addresses = true;
					break;
				case 'p':
					print_comments = true;
					break;
				case 'C':
					regexp_string = optarg;
					break;
				case 'I':
					sortBy = MachO_File_ObjC::SB_Inherit;
					break;
				case 'S':
					sortBy = MachO_File_ObjC::SB_Alphabetic;
					break;
				case 'D':
					switch (*optarg) {
						case 'r':
							print_reachability_matrix = true;
							break;
						case 's':
							print_struct_indices = true;
							break;
					}
					break;
				default:
					break;
			}
		}
		
		if (optind == argc) {
			print_usage();
			return 0;
		}
		
		const char* filename = argv[optind];
		
		pcre* regExp = NULL;
		pcre_extra* regExpExtra = NULL;
		
		try {
			MachO_File_ObjC mf = MachO_File_ObjC(filename);
			
			if (print_reachability_matrix) {
				printf("/* Reachability matrix:\n\n");
				mf.print_reachability_matrix();
				printf("\n*/\n\n");
			}
			
			if (print_struct_indices) {
				printf("/* Struct indices:\n\n");
				mf.print_struct_indices();
				printf("\n*/\n\n");
			}
			
			if (regexp_string != NULL) {
				const char* errStr = NULL;
				int erroffset;
				regExp = pcre_compile(regexp_string, 0, &errStr, &erroffset, NULL);
				if (regExp != NULL)
					regExpExtra = pcre_study(regExp, 0, &errStr);
				if (errStr != NULL)
					fprintf(stderr, "Warning: Encountered error while parsing RegExp pattern '%s' at offset %d: %s.\n", regexp_string, erroffset, errStr);
			}
			
			
			unsigned structs_count = mf.structs_count();
			for (unsigned i = 0; i < structs_count; ++ i) {
				if (regexp_string != NULL) {
					const std::string& name = mf.name_of_struct(i);
					if (0 != pcre_exec(regExp, regExpExtra, name.c_str(), name.size(), 0, 0, NULL, 0))
						continue;
				}
				mf.print_struct(i);
			}
			
			vector<unsigned> sortmap = mf.get_class_sort_order_by(sortBy);
			
			for (vector<unsigned>::const_iterator cit = sortmap.begin(); cit != sortmap.end(); ++ cit) {
				if (regexp_string != NULL) {
					const char* name = mf.name_of_class(*cit);
					if (0 != pcre_exec(regExp, regExpExtra, name, strlen(name), 0, 0, NULL, 0))
						continue;
				}
				mf.print_class(*cit, print_ivar_offsets, print_method_addresses, print_comments);
			}
			
		} catch (const TRException& e) {
			printf("/*\n\nAn exception was thrown while analyzing '%s' (with sysroot '%s'):\n\n%s\n\n*/\n", filename, sysroot, e.what());
		}
		
		free(regExp);
		free(regExpExtra);
	}
}