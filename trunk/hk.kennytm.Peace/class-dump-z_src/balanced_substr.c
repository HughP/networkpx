/*

balanced_substr.c ... Skip balanced substring.

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

#include <stdbool.h>

#if __cplusplus
extern "C"
#endif

const char* skip_balanced_substring(const char* input) {
	int balance = 0;
	bool in_double_quote_mode = false, in_single_quote_mode = false, in_escape_mode = false;
	do {
		switch (*input) {
			case '{':
			case '[':
			case '(':
			case '<':
				if (!in_double_quote_mode && !in_single_quote_mode) {
					++ balance;
				} else
					in_escape_mode = false;
				break;
				
			case '}':
			case ']':
			case ')':
			case '>':
				if (!in_double_quote_mode && !in_single_quote_mode)
					-- balance;
				else
					in_escape_mode = false;
				break;
				
			case '\'':
				if (in_double_quote_mode || in_escape_mode)
					in_escape_mode = false;
				else {
					in_single_quote_mode = !in_single_quote_mode;
					if (in_single_quote_mode)
						++ balance;
					else
						-- balance;
				}
				break;
				
			case '"':
				if (in_single_quote_mode || in_escape_mode)
					in_escape_mode = false;
				else {
					in_double_quote_mode = !in_double_quote_mode;
					if (in_double_quote_mode)
						++ balance;
					else
						-- balance;
				}
				break;
				
			case '\\':
				if (in_single_quote_mode || in_double_quote_mode)
					in_escape_mode = !in_escape_mode;
				break;
				
			default:
				if (in_single_quote_mode || in_double_quote_mode)
					in_escape_mode = false;
				break;
		}
		++ input;
	} while (balance > 0);
	
	return input;
}
