/*

MachO_File_ObjC_debug.cpp ... Just for debugging.

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
#include <cstdio>

using namespace std;

void MachO_File_ObjC::print_all_types() const throw() {
	printf("// Parsed %lu types.\n\n", static_cast<unsigned long>(m_record.types_count()));
	
	for (unsigned i = 0; i < m_record.types_count(); ++ i) {
		printf("%s;\n", m_record.format(i, "", 0, true).c_str());
	}
	printf("\n");
}

void MachO_File_ObjC::print_extern_symbols() const throw() {
	printf("// Found %lu external symbols.\n\n", ma_include_paths.size());
	
	for (tr1::unordered_map<ObjCTypeRecord::TypeIndex, string>::const_iterator cit = ma_include_paths.begin(); cit != ma_include_paths.end(); ++ cit) {
		std::tr1::unordered_map<ObjCTypeRecord::TypeIndex, const char*>::const_iterator lit = ma_lib_path.find(cit->first);
		printf("%s:\t%s\t(%s)\n", cit->second.c_str(), m_record.name_of_type(cit->first).c_str(), lit == ma_lib_path.end() ? "-" : lit->second);
	}
	printf("\n");
}
