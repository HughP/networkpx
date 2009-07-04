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

#ifndef BALANCED_SUBSTRING_H
#define BALANCED_SUBSTRING_H

extern "C" {
	
	/* Skip a substring with balanced brackets and quotation marks.
	 
	 e.g. abc  --> returns bc
	 e.g. {xx}d --> returns d
	 e.g. [df)c --> undefined, may crash
	 e.g. "sdfc)df"abc -> returns abc
	 
	 */
	const char* skip_balanced_substring(const char* input);
	
}

#endif