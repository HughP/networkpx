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
#include <cstring>
#include <unistd.h>
#include <sys/stat.h>

using namespace std;

void print_usage () {
	fprintf(stderr,
			"Usage: class-dump-z [<options>] <filename>\n"
			"\n"
			"where options are:\n"
			"\n  Analysis:\n"
			"    -p         Convert undeclared getters and setters into properties (propertize).\n"
			"    -h proto   Hide methods which already appears in an adopted protocol.\n"
			"    -h super   Hide inherited methods.\n"
			"    -y <root>  Choose the sysroot. Default to /.\n"
			"\n  Formatting:\n"
			"    -a         Print ivar offsets\n"
			"    -A         Print implementation VM addresses.\n"
			"    -k         Show additional comments.\n"
			"    -R         Show pointer declarations as int *a instead of int* a.\n"
			"    -N         Keep the raw struct names (e.g. do no replace __CFArray* with CFArrayRef).\n"
			"\n  Filtering:\n"
			"    -C <regex> Only display types with (original) name matching the RegExp (in PCRE syntax).\n"
			"    -f <regex> Only display methods with (original) name matching the RegExp.\n"
			"    -g         Display exported classes only.\n"
			"    -X <list>  Ignore all types (except categories) with a prefix in the comma-separated list.\n"
			"\n  Sorting:\n"
			"    -S         Sort types in alphabetical order.\n" 
			"    -s         Sort methods in alphabetical order.\n"
			"\n  Output:\n"
			"    -H         Separate into header files\n"
			"    -o <dir>   Put header files into this directory instead of current directory."
			"\n"
			);
}

int main (int argc, char* argv[]) {
	if (argc == 1) {
		print_usage();
	} else {
		int c;
		bool print_ivar_offsets = false, print_method_addresses = false, print_comments = false, sort_methods_alphabetically = false;
		bool pointers_right_align = false, show_only_exported_classes = false, propertize = false, generate_headers = false, prettify_struct_names = true;
		bool hide_protocols = false, hide_super = false;
		MachO_File_ObjC::SortBy sort_by = MachO_File_ObjC::SB_None;
		char diagnosis_option = '\0';
		const char* sysroot = "/";
		const char* type_regexp = NULL;
		const char* method_regexp = NULL;
		const char* output_directory = NULL;
		vector<string> kill_prefix;
		
		// const char* regexp_string = NULL;
		while ((c = getopt(argc, argv, "aAkC:ISsD:Rf:gpHo:X:Nh:y:")) != -1) {
			switch (c) {
				case 'a': print_ivar_offsets = true; break;
				case 'A': print_method_addresses = true; break;
				case 'k': print_comments = true; break;
				case 's': sort_methods_alphabetically = true; break;
				case 'D': diagnosis_option = *optarg; break;	// diagnosis options, not to be used publicly.
				case 'C': type_regexp = optarg; break;
				case 'f': method_regexp = optarg; break;
				case 'R': pointers_right_align = true; break;
				case 'g': show_only_exported_classes = true; break;
				case 'p': propertize = true; break;
				case 'S': sort_by = MachO_File_ObjC::SB_Alphabetic; break;
				case 'I':
					fprintf(stderr, "Warning: Sort by inheritance is not implemented yet.\n");
					break;
				case 'o': output_directory = optarg;  break;
				case 'H': generate_headers = true; break;
				case 'X': {
					const char* comma = optarg;
					const char* last_comma;
					while (true) {
						last_comma = comma;
						comma = strchr(comma, ',');
						if (comma == NULL) {
							kill_prefix.push_back(last_comma);
							break;
						} else {
							kill_prefix.push_back(string(last_comma, comma));
						}
						++ comma;
					}
					break;
				}
				case 'N': prettify_struct_names = false; break;
				case 'h':
					if (strncmp(optarg, "proto", 5) == 0)
						hide_protocols = true;
					else if (strncmp(optarg, "super", 5) == 0)
						hide_super = true;
					break;
				case 'y': sysroot = optarg; break;
				default:
					break;
			}
		}
		
		if (optind == argc) {
			print_usage();
			return 0;
		}
		
		const char* filename = argv[optind];
		
		try {
			MachO_File_ObjC mf = MachO_File_ObjC(filename);
		
			if (diagnosis_option != '\0') {
				switch (diagnosis_option) {
					case 't': mf.print_all_types(); break;
					case 'n': mf.print_network(); break;
					case 'e': mf.print_extern_symbols(); break;
//					case 'i': mf.print_protocol_adoption_network(); break;
						
					default:
						printf("// Unrecognized diagnosis option: -D %c\n", diagnosis_option);
						break;
				}
			} else {
				mf.set_prettify_struct_names(prettify_struct_names);
				mf.set_pointers_right_aligned(pointers_right_align);
				if (type_regexp != NULL)
					mf.set_class_filter(type_regexp);
				if (method_regexp != NULL)
					mf.set_method_filter(method_regexp);
				if (!kill_prefix.empty())
					mf.set_kill_prefix(kill_prefix);
			
				mf.hide_overlapping_methods(hide_super, hide_protocols, sysroot);
				if (propertize)
					mf.propertize();
								
				if (generate_headers) {
					if (output_directory != NULL) {
						if (chdir(output_directory) == -1) {
							if (mkdir(output_directory, 0755) == -1) {
								perror("Cannot create directory for header generation. ");
								return 1;
							} else
								chdir(output_directory);
						}
					}
					
					mf.write_header_files(filename, print_method_addresses, print_comments, print_ivar_offsets, sort_methods_alphabetically, show_only_exported_classes);
				} else {
					mf.print_struct_declaration(sort_by);
					mf.print_class_type(sort_by, print_method_addresses, print_comments, print_ivar_offsets, sort_methods_alphabetically, show_only_exported_classes);
				}
				
			}
			
		} catch (const TRException& e) {
			printf("/*\n\nAn exception was thrown while analyzing '%s' (with sysroot '%s'):\n\n%s\n\n*/\n", filename, sysroot, e.what());
		}
	}
}
