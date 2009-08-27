/*

string_uitl.cpp ... String utilities.

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

#include "string_util.h"
#include <cstdio>
#include <cstring>
#include <cctype>
#include "snprintf.h"

using namespace std;

string numeric_format(const char* format, unsigned number) throw() {
	// for simplicity, assume C99.
	size_t buffer_size = static_cast<size_t>(sizeof(unsigned) * 2.40823996531185) + strlen(format);	// 2.40823996531185 = log_10 (256).
	char* buffer = reinterpret_cast<char*>(alloca(buffer_size));
	snprintf(buffer, buffer_size, format, number);
	return string(buffer);
}

const char* strrstr(const char* string, const char* search) throw() {
	size_t search_length = strlen(search);
	size_t string_length = strlen(string);
	const char* cur_pos = string + string_length - search_length;
	while (cur_pos >= string) {
		if (strncmp(cur_pos, search, search_length) == 0)
			return cur_pos;
		-- cur_pos;
	}
	return NULL;
}

bool has_word_prefix(const char* str, const char* word_prefix) throw() {
	size_t word_prefix_length = strlen(word_prefix);
	if (strncmp(str, word_prefix, word_prefix_length) == 0) {
		if (!(str[word_prefix_length] >= 'a' && str[word_prefix_length] <= 'z'))
			return true;
	}
	return false;
}

const char* find_first_word(const char* str, const char* word_to_find) throw() {
	size_t word_prefix_length = strlen(word_to_find);
	while (true) {
		str = strstr(str, word_to_find);
		if (str == NULL)
			return NULL;
		if (!(str[word_prefix_length] >= 'a' && str[word_prefix_length] <= 'z'))
			return str;
		else
			str += word_prefix_length;
	}
}

const char* last_word_before(const char* string, const char* word) throw() {
	if (word <= string)
		return NULL;
	
	const char* potential_location = word-1;
	
rescan_for_plural:
	
	// Search for numbers.
	if (*potential_location >= '0' && *potential_location <= '9') {
		while (potential_location >= string) {
			-- potential_location;
			if (!(*potential_location >= '0' && *potential_location <= '9'))
				break;
		}
		
	}
	
	// Search for capital letters.
	else if (*potential_location >= 'A' && *potential_location <= 'Z') {
		while (potential_location >= string) {
			-- potential_location;
			if (!(*potential_location >= 'A' && *potential_location <= 'Z'))
				break;
		}
	}
	
	// Search for small letters, optionally prefixed by one captical letter.
	else {
		if (*potential_location == 's' && potential_location > string && !(*(potential_location-1) >= 'a' && *(potential_location-1) <= 'z')) {
			-- potential_location;
			goto rescan_for_plural;
		}
		
		while (potential_location >= string) {
			-- potential_location;
			if (!(*potential_location >= 'a' && *potential_location <= 'z')) {
				if (*potential_location >= 'A' && *potential_location <= 'Z') {
					-- potential_location;
				}
				break;
			}
		}
	}
	
	return potential_location+1;
}

static bool have_word_in_alphabetic_table(const char* word, unsigned word_length, const char* table[][26], unsigned table_rows) {
	unsigned index = *word - 'A';
	if (index >= 26) index = *word - 'a';
	if (index >= 26) return false;
	
	for (unsigned i = 0; i < table_rows; ++ i) {
		if (table[i][index] == NULL)
			return false;
		if (strlen(table[i][index]) == word_length) {
			int compres = strncmp(word, table[i][index], word_length);
			if (compres == 0)
				return true;
			else if (compres < 0)
				return false;
		}
	}
	
	return false;
}

const char* find_word_after_last_common_preposition(const char* str) throw() {
	static const char* common_prepositions[][26] = {
		{"At", NULL, NULL, NULL, NULL, "For", NULL, NULL, "In", NULL, NULL, NULL, NULL, NULL, "Of", NULL, NULL, NULL, NULL, "To", NULL, NULL, "With", NULL, NULL, NULL},
		{"at", NULL, NULL, NULL, NULL, "From", NULL, NULL, "in", NULL, NULL, NULL, NULL, NULL, "of", NULL, NULL, NULL, NULL, "to", NULL, NULL, "with", NULL, NULL, NULL},
		{NULL, NULL, NULL, NULL, NULL, "for", NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL},
		{NULL, NULL, NULL, NULL, NULL, "from", NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL},
	};
	int max_preposition_length = 4;	// max strlen of all possible prepositions.
		
	const char* word = str + strlen(str);
	
	while (true) {
		const char* last_word = word;
		word = last_word_before(str, word);
		
		if (word == NULL)
			return NULL;
		
		if (last_word - word > max_preposition_length)
			continue;
		
		if (word != NULL) {
			if (have_word_in_alphabetic_table(word, last_word - word, common_prepositions, sizeof(common_prepositions)/sizeof(const char*[26])))
				return last_word;
		}
	}
}

const char* find_first_common_modal_word(const char* str, unsigned* modal_verb_length) throw() {
	const char* did = find_first_word(str, "Did");
	const char* will = find_first_word(str, "Will");
	const char* should = find_first_word(str, "Should");
	
	const char* min = did;
	*modal_verb_length = 3;
	if (min == NULL || (will != NULL && min > will)) {
		min = will;
		*modal_verb_length = 4;
	}
	if (min == NULL || (should != NULL && min > should)) {
		min = should;
		*modal_verb_length = 6;
	}
	
	return min;
}

void lowercase_first_word(string& str) throw() {
	unsigned i = 0;
	for (; i < str.size(); ++ i) {
		if (!(str[i] >= 'A' && str[i] <= 'Z'))
			break;
	}
	if (i == 0)
		return;
	if (i == str.size() || !(str[i] == 's' && (i == str.size()-1 || !(str[i+1] >= 'a' && str[i+1] <= 'z'))))
		-- i;
	for (unsigned j = 0; j <= i; ++ j)
		str[j] = static_cast<char>(tolower(str[j]));
}

void articlize_keyword(string& str) throw() {
	static const char* keywords[][26] = {
		{"abstract", "bitand", "case", "default", "else", "false", "goto", NULL, "id", NULL, NULL, "long", "mutable", "namespace", "offsetof", "private", NULL, "register", "self", "template", "union", "virtual", "while", "xor", NULL, NULL},
		{"and", "bitor", "catch", "delete", "enum", "float", NULL, NULL, "if", NULL, NULL, NULL, NULL, "new", "oneway", "protected", NULL, "restrict", "short", "this", "unsigned", "void", NULL, NULL, NULL, NULL},
		{"asm", "bool", "char", "do", "explicit", "for", NULL, NULL, "in", NULL, NULL, NULL, NULL, "nil", "operator", "public", NULL, "return", "signed", "throw", "using", "volatile", NULL, NULL, NULL, NULL},
		{"assert", "break", "class", "double", "extern", "friend", NULL, NULL, "inline", NULL, NULL, NULL, NULL, "not", "or", NULL, NULL, NULL, "sizeof", "true", NULL, NULL, NULL, NULL, NULL, NULL},
		{NULL, "bycopy", "compl", NULL, NULL, NULL, NULL, NULL, "inout", NULL, NULL, NULL, NULL, NULL, "out", NULL, NULL, NULL, "static", "try", NULL, NULL, NULL, NULL, NULL, NULL},
		{NULL, "byref", "const", NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, "struct", "typedef", NULL, NULL, NULL, NULL, NULL, NULL},
		{NULL, NULL, "continue", NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, "super", "typeid", NULL, NULL, NULL, NULL, NULL, NULL},
		{NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, "switch", "typename", NULL, NULL, NULL, NULL, NULL, NULL},
		{NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, "typeof", NULL, NULL, NULL, NULL, NULL, NULL}
	};
	
	bool do_articlize = false;
	if (str[0] >= '0' && str[0] <= '9')
		do_articlize = true;
	if (str[0] >= 'a' && str[0] <= 'z' && have_word_in_alphabetic_table(str.c_str(), str.size(), keywords, sizeof(keywords)/sizeof(const char*[26])))
		do_articlize = true;
	
	if (do_articlize) {
		str[0] = static_cast<char>(toupper(str[0]));
		if (str[0] == 'A' || str[0] == 'E' || str[0] == 'I' || (str[0] == 'O' && str != "Oneway") || str == "Unsigned" || str[0] == 'X')
			str.insert(0, "an");
		else
			str.insert(0, "a");
	}
}
