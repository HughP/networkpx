/*

objc_type_test.cpp ... Test if objc_type.cpp works correctly.

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

#include "objc_type.h"
#include <iostream>

using namespace std;

int main () {
	ObjCTypeRecord record;
	unsigned last_index = 3;
	while (!cin.fail()) {
		printf("%d> ", last_index);
		string str;
		getline(cin, str);
		if (!cin.fail()) {
			last_index = record.parse(str, true);
		}
	}
	
	printf("\nParsed into %lu types.\n\n", record.types_count());
	
	for (unsigned i = 0; i < record.types_count(); ++ i) {
		printf("%s;\n", record.format(i, "", 0, true).c_str());
	}
	printf("\n");
	
	for (unsigned i = 0; i < record.types_count(); ++ i) {
		char argname[32];
		snprintf(argname, 32, "_arg%u", i);
		printf("%s;\n", record.format(i, argname, 0, false).c_str());
	}
	
	return 0;
}
