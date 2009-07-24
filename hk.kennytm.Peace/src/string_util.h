/*

string_util.h ... String utilities

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

#ifndef NUMERIC_STRING_H
#define NUMERIC_STRING_H

#include <string>

// Format an unsigned number. The format must have exactly one %u or 0x%x
std::string numeric_format(const char* format, unsigned number) throw();

// Find last string in c string
const char* strrstr(const char* str, const char* search) throw();

// Find word in Pascal-case string.
const char* find_first_word(const char* str, const char* word_to_find) throw();

// Find the position of last word before the specified string.
const char* last_word_before(const char* str, const char* word) throw();

bool has_word_prefix(const char* str, const char* word_prefix) throw();

// Find the index _after_ the last common preposition. 
// The common prepositions are:  for, at, with, in, from, to, of
const char* find_word_after_last_common_preposition(const char* str) throw();

// Find the first common modal verb in the string. Ignore modal verbs at beginning.
// The common modal verbs are: Will, Did, Should.
const char* find_first_common_modal_word(const char* str, unsigned* modal_verb_length) throw();

// Add an article if it's a keyword or number (class, int, struct, typeof, 10, 24, 1970, etc.).
void articlize_keyword(std::string& str) throw();

// URLs -> urls, HTTPStream -> httpStream, ByteEncoder -> byteEncoder, IPV6Address -> ipv6Address, RSSOf -> rssOf
void lowercase_first_word(std::string& str) throw();

#endif
