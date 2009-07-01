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

#include "objc_type.h"
#include <cstdio>
#include <cstring>
#include "crc32.h"

#define LONG_ENOUGH_TO_FIT(fmtStr) (static_cast<size_t>(sizeof(unsigned) * 2.40823996531185 + strlen(fmtStr)))	// 2.40823996531185 = log_10 (256).

using namespace std;

static const char* map[] = {
// 0 - F
	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,

// 10 - 1F
	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,

// [space] ! " # $ % & '        ( ) * + , - . /
	NULL, "/*gcinvisible*/", NULL, "Class", NULL, "/*atom*/ char*", NULL, NULL,
	NULL, NULL, "char*", NULL, NULL, NULL, NULL, NULL,

// 0 1 2 3 4 5 6 7         8 9 : ; < = > ?
	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
	NULL, NULL, "SEL", NULL, NULL, NULL, NULL, "/*function-pointer*/ void",

// @ A B C D E F G        H I J K L M N O
	"id", NULL, "bool", "unsigned char", NULL, NULL, NULL, NULL,
	NULL, "unsigned", NULL, NULL, "unsigned long", NULL, "inout", "bycopy",

// P Q R S T U V W        X Y Z [ \ ] ^ _
	NULL, "unsigned long long", NULL, "unsigned short", NULL, NULL, "oneway",
	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,

// ` a b c d e f g         h i j k l m n o
	NULL, NULL, NULL, "char", "double", NULL, "float", NULL, 
	NULL, "int", "_Complex", NULL, "long", NULL, "in", "out",

// p q r s t u v w         x y z { | } ~ [del]
	NULL, "long long", "const", "short", NULL, NULL, "void",
	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
};

unsigned ObjCTypeRecord::parse(const string& type_to_parse, bool is_struct_used_locally) {
	tr1::unordered_map<string, unsigned>::const_iterator p_index = ma_indexed_types.find(type_to_parse);
	
	if (p_index != ma_indexed_types.end()) {
		Type& retval = ma_type_store[p_index->second];
		if (is_struct_used_locally) {
			if (retval.refcount != Type::used_globally)
				++ retval.refcount;
		} else
			retval.refcount = Type::used_globally;
		return p_index->second;
	}
	
	Type t = Type(*this, type_to_parse, "", is_struct_used_locally);
	
	unsigned ret_index = ma_type_store.size();
	
	// merge struct with the same name, typesignature etc. 
	if (t.type == '(' || t.type == '{') {
		ret_index = 0;
		for (vector<Type>::iterator cit = ma_type_store.begin(); cit != ma_type_store.end(); ++ cit, ++ ret_index) {
			if (cit->is_compatible_with(t, *this)) {
				ma_indexed_types.insert(pair<string,unsigned>(type_to_parse, ret_index));
				if (t.is_more_complete_than(*cit))
					*cit = t;
				return ret_index;
			}
		}
	}
	
	ma_type_store.push_back(t);
	ma_indexed_types.insert(pair<string,unsigned>(type_to_parse, ret_index));
	
	return ret_index;
}

string ObjCTypeRecord::format(unsigned type_index, const string& argname, unsigned tabs, bool as_declaration) const throw() {
	return ma_type_store[type_index].format(*this, argname, tabs, true, as_declaration);
}

// for 2 types to be equal...
bool ObjCTypeRecord::Type::is_compatible_with(const Type& another, const ObjCTypeRecord& record) const throw() {
	// (1) they must have the same leading character.
	if (type != another.type)
		return false;
	
	// (2) the subtypes, if any, must be equal.
	if (!subtypes.empty()) {
		if (!another.subtypes.empty()) {
			if (subtypes.size() != another.subtypes.size())
				return false;
			for (vector<unsigned>::const_iterator cit1 = subtypes.begin(), cit2 = another.subtypes.begin(); cit1 != subtypes.end(); ++cit1, ++cit2)
				if (*cit1 != *cit2 && !record.ma_type_store[*cit1].is_compatible_with(record.ma_type_store[*cit2], record))
					return false;
		} else if ((type == '{' || type == '(') && name.empty())
			return false;
	}
	
	// (3) the values must be equal. (this forces int x[12] != int y[24].)
	if (value != another.value)
		return false;
	
	// (4) the field names, if both present, must be equal. (this allows struct { int _field1; } == struct SingletonValue { int value; }, but struct Point { float x, y; } != struct Complex { float x, y; }.)
	if (!name.empty()) {
		if (!another.name.empty()) {
			if (name != another.name)
				return false;
		}
	
		// (5) it's not compatible to match a named empty struct anything anonymous.
		else if ((type == '{' || type == '(') && subtypes.empty())
			return false;
	}
	
	return true;
}

bool ObjCTypeRecord::Type::is_more_complete_than (const Type& another) const throw() {
	bool i_has_name = !name.empty(), you_have_name = !another.name.empty();
	
	// Named struct is always more complete than anonymous structs
	if (i_has_name && !you_have_name)
		return true;
	else if (you_have_name && !i_has_name)
		return false;
	
	bool i_has_content = !struct_is_undeclared, you_have_content = !another.struct_is_undeclared;
	
	// Declared struct is more complete than undeclared ones.
	if (i_has_content && !you_have_content)
		return true;
	else if (you_have_content && !i_has_content)
		return false;
	
	// Having field names is better than none.
	bool i_has_field_names = !field_names.empty(), you_have_field_names = !field_names.empty();
	if (i_has_field_names && !you_have_field_names)
		return true;
	// In case of tie, prefer to be humble.
	else
		return false;
}

/** Find the name of the struct given the type string.
 Returns an empty string if the struct is anonymous (i.e. having a name of ? or $_123).
 The parameter typestr will be advanced until to end of the struct name.
 @param[inout] typestr C string that contains the type string of the struct/union, with the leading ( or { removed. 
 */
static string parse_struct_name (const char*& typestr) {
	int balance = 1; 
	bool in_character_mode = false, in_escape_mode = false;
	// (1) Find the name.
	if (*typestr == '?') {
		++typestr;
		return "";
	}
	
	const char* identifier_start = typestr;
	while (true) {
		switch (*typestr) {
			case '\0':
				goto finish;
				
			case '\'':
				if (!in_escape_mode)
					in_character_mode = !in_character_mode;
				else
					in_escape_mode = false;
				break;
			case '\\':
				in_escape_mode = !in_escape_mode;
				break;
				
			case '(':
			case '{':
				if (!in_character_mode)
					++ balance;
				else
					in_escape_mode = false;
				break;
				
			case '=':
			case '}':
			case ')':
				if (!in_character_mode) {
					--balance;
					if (balance == 0)
						goto finish;
				} // fall through
			default:
				in_escape_mode = false;
				break;
		}
		++ typestr;
	}
finish:
	string name = string(identifier_start, typestr);
	// $_123 are g++'s way to denote an anonymous struct.
	if (name.size() > 2 && name.substr(0, 2) == "$_" && name.find_first_not_of("0123456789", 2) == string::npos)
		return "";
	return name;
}

static vector<string> parse_struct_members (const char* member_typestrings, bool& has_field_names) {
	vector<string> typestrings_list;
	unsigned balance = 1;
	const char* subtype_begin = member_typestrings;
	bool in_double_quote_mode = false, in_single_quote_mode = false, in_escape_mode = false;
	has_field_names = false;
	
	// Parse the whole string into tokens.
	while (balance > 0) {
		switch (*member_typestrings) {
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
				if (!in_double_quote_mode && !in_single_quote_mode) {
					-- balance;
					// we're back to the same level we begin with. Let's insert a type.
					if (balance == 1) {
						typestrings_list.push_back(string(subtype_begin, member_typestrings+1));
						subtype_begin = member_typestrings+1;
					}
				} else
					in_escape_mode = false;
				break;
				
			case '\'':
				if (in_double_quote_mode || in_escape_mode)
					in_escape_mode = false;
				else
					in_single_quote_mode = !in_single_quote_mode;
				break;
				
			case '"':
				if (in_single_quote_mode || in_escape_mode)
					in_escape_mode = false;
				else {
					in_double_quote_mode = !in_double_quote_mode;
					if (!in_double_quote_mode && balance == 1) {
						typestrings_list.push_back(string(subtype_begin, member_typestrings+1));
						subtype_begin = member_typestrings+1;
					}
				}
				break;
				
			case '\\':
				if (in_single_quote_mode || in_double_quote_mode)
					in_escape_mode = !in_escape_mode;
				break;
				
			case 'b':
				if (in_double_quote_mode || in_escape_mode)
					in_escape_mode = false;
				else
					member_typestrings += strspn(member_typestrings+1, "0123456789")-1;
				break;
				
			case '^':
			case 'j':
			case 'r':
			case 'n':
			case 'N':
			case 'o':
			case 'O':
			case 'V':
			case '!':
				break;

			default:
				if (in_single_quote_mode || in_double_quote_mode)
					in_escape_mode = false;
				else if (balance == 1) {
					typestrings_list.push_back(string(subtype_begin, member_typestrings+1));
					subtype_begin = member_typestrings+1;
				}
				break;
		}
		++ member_typestrings;
	}
	
	// Merge @ and "xxx" into @"xxx" if possible.
	vector<string> retval;
	for (vector<string>::const_iterator cit = typestrings_list.begin(); cit != typestrings_list.end(); ++ cit) {
		if (*cit == "@") {
			if (cit+1 != typestrings_list.end() && (*(cit+1))[0] == '"') {
				if (cit+2 == typestrings_list.end() || (*(cit+2))[0] == '"') {
					retval.push_back(*cit + *(cit+1));
					++ cit;
					continue;
				}
			}
		} else if ((*cit)[0] == '"')
			has_field_names = true;
		retval.push_back(*cit);
	}
	
	return retval;
}

ObjCTypeRecord::Type::Type(ObjCTypeRecord& record, const string& type_to_parse, const string& current_name, bool is_struct_used_locally) : type(type_to_parse[0]), refcount(is_struct_used_locally ? 1 : Type::used_globally), name(current_name) {
	switch (type) {
		case '^':
		case 'j':
		case 'r':
		case 'n':
		case 'N':
		case 'o':
		case 'O':
		case 'V':
		case '!':	// GC Invisible. (! can also be "Vector type". But these are rare enough to be used in anywhere.)
			subtypes.push_back( record.parse(type_to_parse.substr(1), false) );
			break;
		case 'b':
			value = type_to_parse.substr(1);
			break;
		case '@':
			if (type_to_parse.size() != 1) {
				name = type_to_parse.substr(2, type_to_parse.size()-3);
				size_t first_angle_bracket = name.find('<');
				if (first_angle_bracket != 0) {
					if (first_angle_bracket == string::npos)
						record.add_external_objc_class(value);
					else
						record.add_external_objc_class(value.substr(0, first_angle_bracket));
				}
			}
			break;
		case '[': {
			size_t first_nonnumber_position = type_to_parse.find_first_not_of("0123456789", 1);
			value = type_to_parse.substr(1, first_nonnumber_position-1);
			subtypes.push_back( record.parse( type_to_parse.substr(first_nonnumber_position, type_to_parse.size()-first_nonnumber_position-1), is_struct_used_locally) );
			break;
		}
		
		case '{':
		case '(': {
			const char* typestr = type_to_parse.c_str()+1;
			
			name = parse_struct_name(typestr);
			
			// (2) Check if it has contents.
			struct_is_undeclared = *typestr != '=';
			if (!struct_is_undeclared) {
				// (3) parse the subtypes!
				bool has_field_names;
				vector<string> raw_subtypes = parse_struct_members(typestr+1, has_field_names);
				for (vector<string>::const_iterator cit = raw_subtypes.begin(); cit != raw_subtypes.end(); ++ cit) {
					if (has_field_names) {
						field_names.push_back( cit->substr(1, cit->size()-2) );
						++ cit;
					}
					subtypes.push_back( record.parse(*cit, true) );					
				}
			}
			
			if (!name.empty()) {
				size_t first_non_underscore_position = name.find('<') == string::npos ? name.find_first_not_of('_') : 0;
				pretty_name = name.substr( first_non_underscore_position == string::npos ? 0 : first_non_underscore_position );
			} else {
				// synthesize a stable name for an anonymous struct.
				char synthesized_name[12];
				crc32_b64(type_to_parse.c_str(), type_to_parse.size(), synthesized_name);
				pretty_name = (type == '(' ? "XXUnion_" : "XXStruct_");
				pretty_name += synthesized_name;
			}
			
			break;
		}
		default:
			break;
	}
}

// as_declaration = true: present struct as typedef struct ABC { ... } ABC; = false: present as ABC.
string ObjCTypeRecord::Type::format (const ObjCTypeRecord& record, const string& argname, unsigned tabs, bool treat_char_as_bool, bool as_declaration) const throw() {
	string retval = string(tabs, '\t');
	switch (type) {
		default: {
			const char* map_type = map[static_cast<unsigned char>(type)];
			if (map_type != NULL) {
				retval += map_type;
				if (subtypes.size() == 1) {
					retval.push_back(' ');
					retval += record.ma_type_store[subtypes[0]].format(record, argname, 0, false, false);
					return retval;
				}
			} else {
				fprintf(stderr, "Warning: Unrecognized type encoding '%c'.\n", type);
				retval += "/*unknown-type-(";
				retval.push_back(type);
				retval += ")*/ void*";
			}
			break;
		}
			
		case 'c':
			retval += treat_char_as_bool ? "BOOL" : "char";
			break;
			
		case '^': {
			const Type& subtype = record.ma_type_store[subtypes[0]];
			if (subtype.type == '[') {
				string pseudo_argname = "(*";
				pseudo_argname += argname;
				pseudo_argname.push_back(')');
				retval += subtype.format(record, pseudo_argname, 0, true, false);
				return retval;
			} else if (subtype.type == '{' && subtype.struct_is_undeclared && subtype.name.find('<') == string::npos && subtype.pretty_name.substr(0, 2) != "NS") {
				retval += subtype.pretty_name;
				retval += "Ref";
			} else {
				string pseudo_argname = "*";
				pseudo_argname += argname;
				retval += subtype.format(record, pseudo_argname, 0, true, false);	// if it's char* it will be encoded as ^* instead of ^^c, so it's OK to treat_char_as_bool.
				// change all int ***c to int*** c. Make this optional maybe?
				for (unsigned i = 0; i < retval.size()-1; ++ i) {
					if (retval[i] == ' ' && retval[i+1] == '*') {
						retval[i] = '*';
						retval[i+1] = ' ';
					}
				}
				if (retval[retval.size()-1] == ' ')
					retval.erase(retval.size()-1);
				return retval;
			}
			break;
		}
			
		case 'b':
			retval += "unsigned ";
			retval += argname;
			retval += " : ";
			retval += value;
			return retval;
			
		case '[': {
			const Type& subtype = record.ma_type_store[subtypes[0]];
			string pseudo_argname = argname;
			pseudo_argname.push_back('[');
			pseudo_argname += value;
			pseudo_argname.push_back(']');
			retval += subtype.format(record, pseudo_argname, 0, true, as_declaration);
			return retval;
		}
			
		case '@':
			if (name.empty())
				retval += "id";
			else
				retval += name;
			retval += value;
			if (!name.empty())
				retval.push_back('*');
			break;
			
		case '(':
		case '{':
			if (!as_declaration && name.empty() && struct_is_undeclared ) {
				retval += (type == '(') ? "XXUnionEmpty" : "XXStructEmpty";
				
			} else if (!as_declaration && (!name.empty() || refcount > 1)) {
				retval += pretty_name;
				
			} else {
				string tab_string = retval;
				
				if (name.find('<') != string::npos) {
					retval += "template<>\n";
					retval += tab_string;
				} else if (!name.empty() || refcount > 1)
					retval += "typedef ";
				
				retval += (type == '(') ? "union" : "struct";
				
				if (!name.empty()) {
					retval.push_back(' ');
					retval += name;
					if (struct_is_undeclared) {
						if (type == '{' && name.find('<') == string::npos && pretty_name.substr(0, 2) != "NS") {
							retval.push_back(' ');
							retval += pretty_name;
						} else {
							retval += "* ";
							retval += pretty_name;
							retval += "Ref";
						}
					}
				} else if (struct_is_undeclared)
					retval += (type == '(') ? " XXUnionEmpty XXUnionEmpty" : " XXStructEmpty XXStructEmpty";
				
				if (!struct_is_undeclared) {
					retval += " {\n";
					string field_name;
					for (unsigned i = 0; i < subtypes.size(); ++ i) {
						if (field_names.size() > 0)
							field_name = field_names[i];
						else {
							char raw_field_name[ LONG_ENOUGH_TO_FIT("_field%u") ];
							sprintf(raw_field_name, "_field%u", i+1);
							field_name = raw_field_name;
						}
						
						retval += record.ma_type_store[subtypes[i]].format(record, field_name, tabs+1, true, false);
						retval += ";\n";
					}
					
					retval += tab_string;
					retval.push_back('}');
					if (!name.empty() || refcount > 1) {
						retval.push_back(' ');
						retval += pretty_name;
					}
				}
			}
			
			break;
	}
	
	if (!argname.empty()) {
		retval.push_back(' ');
		retval += argname;
	}
	
	return retval;
}