/*

MachO_File_ObjC_private.cpp ... Mach-O file analyzer specialized in Objective-C support (private methods).

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
#include <cstring>

using namespace std;

void MachO_File_ObjC::increase_use_count(unsigned& use_count, unsigned by) throw() {
	if (use_count != ~0u) {
		if (by == ~0u)
			use_count = ~0u;
		else
			use_count += by;
	}
}
void MachO_File_ObjC::decrease_use_count(unsigned& use_count) throw() {
	if (use_count != ~0u)
		-- use_count;
}

#define LONG_ENOUGH_TO_FIT(fmtStr) (static_cast<size_t>(sizeof(unsigned) * 2.40823996531185 + strlen(fmtStr)))	// 2.40823996531185 = log_10 (256).

static bool entab (string& another_string, unsigned number_of_tabs) throw() {
	if (number_of_tabs == 0)
		return false;
	
	unsigned newline_position = 0;
	unsigned last_newline_position = 0;
	
	string tabstring = string (number_of_tabs, '\t');
	string retstr;
	while (true) {
		last_newline_position = newline_position;
		newline_position = another_string.find('\n', newline_position);
		if (newline_position == string::npos) {
			if (last_newline_position != 0) {
				retstr.append(another_string.substr(last_newline_position));
				another_string = retstr;
			}
			return last_newline_position != 0;
		}
		++ newline_position;
		retstr.append(another_string.substr(last_newline_position, newline_position-last_newline_position));
		retstr.append(tabstring);
	}
}

static string specialize_converted_id_property (const vector<string>& ivar_decl, const char* expected_name, size_t expected_name_length) {
	string potential_type = "id";
	for (vector<string>::const_iterator cit = ivar_decl.begin(); cit != ivar_decl.end(); ++ cit) {
		if (cit->size() > expected_name_length && cit->substr(cit->size()-expected_name_length) == expected_name) {
			if ((*cit)[cit->size()-expected_name_length-1] == ' ') {
				potential_type = cit->substr(0, cit->size()-expected_name_length-1);
				break;
			} else if ((*cit)[cit->size()-expected_name_length-2] == ' ' && (*cit)[cit->size()-expected_name_length-1] == '_') {
				potential_type = cit->substr(0, cit->size()-expected_name_length-2);
				break;
			}
		}
	}
	if (potential_type.size() > 2 && potential_type.substr(0, 3) == "id<" && *potential_type.end() == '>')
		return potential_type;
	else {
		// to be a non-id objc type, 
		//  (1) it must have one and only * at the end.
		//  (2) it cannot end with _t* (just a convention).
		//  (3) it can only contain these characters: "0-9A-Za-z_$<, >"
		//  (4) it cannot be bool*, Class*, id*, int*, long*, short*, unsigned*, char*, float*, double*, SEL*, void*
		//  (5) it cannot contain any spaces, except preceded by a comma (e.g. MyObject<NSCopying, NSObject>* is OK, but unsigned int* is not)
		size_t type_length = potential_type.size();
		if (potential_type.find('*') == type_length-1 &&
			(type_length < 3 || potential_type.substr(type_length-3) != "_t*") &&
			potential_type.find_first_not_of("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_$<>, ") == string::npos &&
			potential_type != "bool*" && potential_type != "Class*" && potential_type != "id*" && potential_type != "int*" &&
			potential_type != "long*" && potential_type != "short*" && potential_type != "unsigned*" && potential_type != "char*" &&
			potential_type != "float*" && potential_type != "double*" && potential_type != "SEL*" && potential_type != "void*") {
			size_t space_loc = -1;
			while(true) {
				space_loc = potential_type.find(' ', space_loc+1);
				if (space_loc == string::npos)
					break;
				if (potential_type[space_loc-1] != ',')
					return "id";
			}
			return potential_type;
		}
		return "id";
	}
}

string MachO_File_ObjC::typestring_id_name_to_objc_name (const string& str) throw() {
	string retstr = str;
	for (unsigned i = 1; i < str.size(); ++ i)
		if (str[i-1] == '>' && str[i] == '<') {
			retstr[i-1] = ',';
			retstr[i] = ' ';
		}
	
	if (str[0] == '<')
		return "id" + retstr;
	else {
		size_t first_angle_bracket = retstr.find('<');
		string cls_name = (first_angle_bracket != string::npos) ? retstr.substr(0, first_angle_bracket) : retstr;
		if (ma_recognized_classes.find(cls_name) == ma_recognized_classes.end()) {
			ma_external_classes.push_back(cls_name);
		}
		return retstr + "*";
	}
}

#define PEEK_VM_ADDR(data, type, seg) (this->peek_data_at_vm_address<type>(reinterpret_cast<unsigned>(data), &(guess_##seg##_segment)))

unsigned MachO_File_ObjC::identify_structs (const char* typestr, const char** typestr_store, unsigned intended_use_count, bool dont_change_anything) throw() {
	/*
	 How to dispatch structs & unions:
	 
	 (1) undefined struct:
	 '{' identifier '}'
	 (2) defined struct:
	 '{' identifier '=' struct-definitions '}'
	 
	 identifiers can be
	 (a) simple identifiers:   [$a-zA-Z][0-9$a-zA-Z_]*
	 (b) template identifiers: [$a-zA-Z][0-9$a-zA-Z_]* '<' template_args '>'
	 (c) anonymous:            '?'
	 
	 template_args can be anything, but it will never contain the = sign *except*
	 inside a character literal '='.
	 
	 struct-definitions must be:
	 ( ( '"' simple-identifier '"' )? type )*
	 
	 and type can be yet another struct or union. 
	 
	 This method only dispatch a struct/union type string into
	 (1) the name
	 (2) the name of each member, and
	 (3) the type string of each member.
	 
	 */
	
	// special case: arrays also call this method. (but dont_change_anything must be false in those cases)
	if (*typestr == '[') {
		++ typestr;
		while (*typestr < '0' || *typestr > '9')
			++typestr;
		while (*typestr != ']') {
			if (*typestr == '{' || *typestr == '[' || *typestr == '(') {
				unsigned uid = identify_structs(typestr, &typestr);
				if (uid != ~0u)
					ma_struct_definitions[uid].direct_reference = true;
			} else
				++typestr;
		}
		if (typestr_store != NULL)
			*typestr_store = typestr+1;
		return ~0u;
	}
	
	// quickly scan through the type string to see if the same struct/union has been analyzed before.
	const char* typestr_start = typestr;
	int balance = 0; 
	bool in_character_mode = false, in_escape_mode = false;
	do {
		switch(*typestr) {
			case '\'':
				if (!in_escape_mode)
					in_character_mode = !in_character_mode;
				else
					in_escape_mode = false;
				break;
			case '\\':
				in_escape_mode = !in_escape_mode;
				break;
			case '{':
			case '(':
				if (!in_character_mode)
					++balance;
				else
					in_escape_mode = false;
				break;
			case ')':
			case '}':
				if (!in_character_mode)
					--balance;
				else
					in_escape_mode = false;
				break;
				
		}
		++ typestr;
	} while (balance > 0);
	
	string typestr_string = string(typestr_start, typestr);
	tr1::unordered_map<string, unsigned>::iterator cit = ma_struct_indices.find(typestr_string);
	if (cit != ma_struct_indices.end()) {
		if (!dont_change_anything)
			increase_use_count(ma_struct_definitions[cit->second].use_count);
		if (typestr_store != NULL)
			*typestr_store = typestr;
		return cit->second;
	} else if (dont_change_anything)
		return -1;
	
	typestr = typestr_start;
	
	StructDefinition curDef;
	curDef.is_union = *typestr == '(';	
	
	balance = 1;
	in_character_mode = false;
	in_escape_mode = false;
	
	// (1) find identifiers.
	++typestr;
	if (*typestr == '?') {
		++typestr;
	} else {
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
		curDef.name = string(identifier_start, typestr);
		// $_123 are C++'s way to denote an anonymous struct.
		if (curDef.name.size() > 2 && curDef.name.substr(0, 2) == "$_" && curDef.name.find_first_not_of("0123456789", 2) == string::npos)
			curDef.name = "";
	}
	
	if (*typestr == '=') {
		++ typestr;
		
		// (2) find struct definitions.
		balance = 1;
		bool in_objc_class_mode = false;
		bool is_direct_reference = true;
		bool found = false;
		const char* subtypestr_start = typestr;
		while (!found) {
			switch (*typestr) {
					
					// a '"' can be a member name or an obj-c type name @"NSWhatever".
					// In case for the obj-c type name, it must immediately follow by
					// another '"', i.e. "member"@"NSWhatever""next_member"...
					// (it's ok since for structs with no member names, the id type
					// will never be specified.)
				case '"': {
					const char* first_matching_quote = strchr(typestr+1, '"');
					if (in_objc_class_mode) {
						switch (first_matching_quote[1]) {
							default:
								curDef.member_typestrings.push_back(typestring_id_name_to_objc_name(string(subtypestr_start, typestr)));
								in_objc_class_mode = false;
								subtypestr_start = typestr;
							case '"':
							case '}':
							case ')':	
								break;
						}
					}
					if (!in_objc_class_mode) {
						curDef.members.push_back(string(typestr+1, first_matching_quote));
					} else {
						curDef.member_typestrings.push_back(string(subtypestr_start, first_matching_quote+1));
						in_objc_class_mode = false;
					}
					typestr = first_matching_quote;
					subtypestr_start = typestr+1;
					is_direct_reference = true;
					break;
				}
					
				case '{':
				case '[':
				case '(': {
					unsigned uid = identify_structs(typestr, &typestr, 1);
					if (uid != ~0u && is_direct_reference)
						ma_struct_definitions[uid].direct_reference = true;
					curDef.member_typestrings.push_back(string(subtypestr_start, typestr));
					subtypestr_start = typestr;
					-- typestr;
					is_direct_reference = true;
					break;
				}
					
				case ')':
				case '}':
				case '\0':
					found = true;
					break;
					
				case '^':
				case 'j':
				case 'r':
				case 'n':
				case 'N':
				case 'o':
				case 'O':
				case 'V':
					is_direct_reference = false;
					break;
					
				case 'b':
					do {
						++ typestr;
					} while (*typestr >= '0' && *typestr <= '9');
					curDef.member_typestrings.push_back(string(subtypestr_start, typestr));
					subtypestr_start = typestr;
					-- typestr;
					is_direct_reference = true;
					break;
					
				case '@':
					if (*(typestr+1) == '"') {
						in_objc_class_mode = true;
						break;
					} // else fall through.
					
				default:
					is_direct_reference = true;
					curDef.member_typestrings.push_back(string(subtypestr_start, typestr+1));
					subtypestr_start = typestr+1;
					break;
					
			}
			
			++ typestr;
		}
	} else {
		++ typestr;
	}
	
	curDef.see_also = ~0u;
	curDef.direct_reference = false;
	
	unsigned uid = ma_struct_definitions.size();
	curDef.use_count = intended_use_count;
	curDef.typestring = typestr_string;
	ma_struct_definitions.push_back(curDef);
	ma_struct_indices.insert(pair<string,unsigned>(typestr_string, uid));
	if (typestr_store != NULL) {
		*typestr_store = typestr;
	}
	return uid;
}

string MachO_File_ObjC::decode_type (const char* typestr, unsigned& chars_to_read, const char* argname, bool is_compound_type, unsigned intended_use_count, bool dont_change_anything) throw() {
	string suffix;
	if (argname != NULL) {
		suffix = string(" ");
		suffix.append(argname);
	}
	switch (*typestr) {
		default: {
			++chars_to_read; 
			string retstr = "/*unknown-type(";
			retstr.push_back(*typestr);
			retstr.append(")*/ void*");
			retstr.append(suffix);
			return retstr;
		}
		case '\0': return string();
		case 'c': ++chars_to_read; return (is_compound_type ? "char" : "BOOL") + suffix;
		case 'i': ++chars_to_read; return "int" + suffix;
		case 's': ++chars_to_read; return "short" + suffix;
		case 'l': ++chars_to_read; return "long" + suffix;
		case 'q': ++chars_to_read; return "long long" + suffix;
		case 'C': ++chars_to_read; return "unsigned char" + suffix;
		case 'I': ++chars_to_read; return "unsigned" + suffix;
		case 'S': ++chars_to_read; return "unsigned short" + suffix;
		case 'L': ++chars_to_read; return "unsigned long" + suffix;
		case 'Q': ++chars_to_read; return "unsigned long long" + suffix;
		case 'f': ++chars_to_read; return "float" + suffix;
		case 'd': ++chars_to_read; return "double" + suffix;
		case 'B': ++chars_to_read; return "bool" + suffix;
		case 'v': ++chars_to_read; return "void" + suffix;
		case '*': ++chars_to_read; return "char*" + suffix;
		case '#': ++chars_to_read; return "Class" + suffix;
		case ':': ++chars_to_read; return "SEL" + suffix;
		case '?': ++chars_to_read; return "/*function-pointer*/ void" + suffix;
		case '^': {
			++chars_to_read;
			if (typestr[1] != '[')
				return decode_type(typestr+1, chars_to_read, NULL, true, ~0u, dont_change_anything) + "*" + suffix;
			else {
				// ^[123type] -> type (*suffix)[123]. who uses this crazy type?
				const char* numstr = typestr+2 + strspn(typestr+2, "0123456789");
				chars_to_read += (numstr - typestr) + 1;
				suffix[0] = '*';
				suffix.insert(suffix.begin(), '(');
				suffix.push_back(')');
				suffix.append(typestr+1, numstr);
				suffix.push_back(']');
				return decode_type(numstr, chars_to_read, suffix.c_str(), true, intended_use_count, dont_change_anything);
			}
		}
		case 'j': ++chars_to_read; return decode_type(typestr+1, chars_to_read, NULL, true, intended_use_count, dont_change_anything) + " _Complex" + suffix;
		case 'r': ++chars_to_read; return "const " + decode_type(typestr+1, chars_to_read, NULL, true, ~0u, dont_change_anything) + suffix;
		case 'n': ++chars_to_read; return "in " + decode_type(typestr+1, chars_to_read, NULL, true, ~0u, dont_change_anything) + suffix;
		case 'N': ++chars_to_read; return "inout " + decode_type(typestr+1, chars_to_read, NULL, true, ~0u, dont_change_anything) + suffix;
		case 'o': ++chars_to_read; return "out " + decode_type(typestr+1, chars_to_read, NULL, true, ~0u, dont_change_anything) + suffix;
		case 'O': ++chars_to_read; return "bycopy " + decode_type(typestr+1, chars_to_read, NULL, true, ~0u, dont_change_anything) + suffix;
		case 'V': ++chars_to_read; return "oneway " + decode_type(typestr+1, chars_to_read, NULL, true, ~0u, dont_change_anything) + suffix;
		case 'b': {
			const char* numstr = typestr+1+strspn(typestr+1, "0123456789");
			chars_to_read += (numstr - typestr);
			
			suffix.append(" : ");
			suffix.append(typestr+1, numstr);
			return "int" + suffix;
		}
		case '[': {
			const char* numstr = typestr+1;
			while (*numstr >= '0' && *numstr <= '9')
				++numstr;
			chars_to_read += (numstr - typestr) + 1;
			
			suffix.append(typestr, numstr);
			suffix.push_back(']');
			return decode_type(numstr, chars_to_read, suffix.c_str()+1, true, intended_use_count, dont_change_anything);
		}
		case '@':
			if (typestr[1] != '"') {
				++ chars_to_read;
				return "id" + suffix;
			} else {
				const char* first_close_quote = strchr(typestr+2, '"');
				chars_to_read += (first_close_quote - typestr) + 1;
				
				return typestring_id_name_to_objc_name(string(typestr+2, first_close_quote)) + suffix;
			}
		case '{':
		case '(': {
			const char* next_item;
			unsigned uid = identify_structs(typestr, &next_item, intended_use_count, dont_change_anything);
			if (!is_compound_type)
				ma_struct_definitions[uid].direct_reference = true;
			chars_to_read += (next_item - typestr);
			
			char pseudo_name[ LONG_ENOUGH_TO_FIT("`%u") ];
			sprintf(pseudo_name, "`%u", uid);
			return pseudo_name + suffix;
		}
			
	}
}

string MachO_File_ObjC::analyze_method (const char* method_name, const char* method_type, const char* plus_or_minus) throw() {
	
	// analyze the type of each method.
	vector<string> types_per_argument;
	while (*method_type != '\0') {
		unsigned chars_to_read = 0;
		string decoded_type = decode_type(method_type, chars_to_read);
		types_per_argument.push_back(decoded_type);
		method_type += chars_to_read;
		while (*method_type >= '0' && *method_type <= '9')
			++ method_type;
	}
	
	// split the method_name by colons.
	vector<string> splitted_method_name (3);
	while (*method_name != '\0') {
		const char* next_colon = strchr(method_name, ':');
		if (next_colon == NULL) {
			splitted_method_name[2] = string(method_name);
			break;
		}
		splitted_method_name.push_back(string(method_name, next_colon));
		method_name = next_colon + 1;
	}
	
	if (splitted_method_name.size() == 3) {
		return plus_or_minus + types_per_argument[0] + ")" + splitted_method_name[2];
	} else {
		string method_decl = plus_or_minus + types_per_argument[0] + ")";
		tr1::unordered_set<string> used_names;
		for (unsigned k = 3; k < splitted_method_name.size(); ++ k) {
			if (k != 3)
				method_decl.push_back(' ');
			
			string part = splitted_method_name[k];
			method_decl.append(part);
			method_decl.append(":(");
			method_decl.append(types_per_argument[k]);
			method_decl.push_back(')');
			
			
			if (part.empty()) {
				
				char argname[ LONG_ENOUGH_TO_FIT("arg%u") ];
				sprintf(argname, "arg%u", k);
				method_decl.append(argname);
				
				used_names.insert(string(argname));
				
			} else {
				size_t argname_start_index = 0;
				size_t argname_end_index = string::npos;
				
				// heuristic to guess the name.
				// 1. find last capitalized letter.
				//    initWithArray, initWithURL, encoding    , URL
				//            ^                ^  (not found)     ^
				size_t last_capitalized_letter = part.find_last_of("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ", argname_end_index);
				
				if (last_capitalized_letter != string::npos && last_capitalized_letter != 0) {
					// 2. find last non-capitalized letter before that.
					//    initWithArray, initWithURL, URL
					//           ^              ^     (not found)
					size_t last_non_capitalized_letter = part.find_last_of("abcdefghijklmnopqrstuvwxyz_$", last_capitalized_letter-1);
					argname_start_index = last_non_capitalized_letter+1;
				}
				
				string potential_argname = part.substr(argname_start_index);
				// convert all uppercase character to lower case.
				for (string::iterator it = potential_argname.begin(); it != potential_argname.end(); ++ it)
					if (*it >= 'A' && *it <= 'Z')
						*it = static_cast<char>(tolower(*it));
				
				// change value of the potential name collide with keywords
#define REPLACE_KEYWORDS(kw, rep) else if (potential_argname == #kw) potential_argname = #rep
				{
					
					if (false) {}
					
					// C++ keywords
					REPLACE_KEYWORDS(abstract, abstraction);
					REPLACE_KEYWORDS(bool, boolean);
					REPLACE_KEYWORDS(break, breakage);
					REPLACE_KEYWORDS(case, aCase);
					REPLACE_KEYWORDS(catch, catcher);
					REPLACE_KEYWORDS(char, character);
					REPLACE_KEYWORDS(class, aClass);
					REPLACE_KEYWORDS(const, constant);
					REPLACE_KEYWORDS(continue, continuation);
					REPLACE_KEYWORDS(default, defaultValue);
					REPLACE_KEYWORDS(delete, deletion);
					REPLACE_KEYWORDS(do, operation);
					REPLACE_KEYWORDS(double, doubleValue);
					REPLACE_KEYWORDS(else, otherwise);
					REPLACE_KEYWORDS(enum, enumeration);
					REPLACE_KEYWORDS(explicit, explicitness);
					REPLACE_KEYWORDS(extern, externality);
					REPLACE_KEYWORDS(false, falseness);
					REPLACE_KEYWORDS(float, floatValue);
					REPLACE_KEYWORDS(for, cause);
					REPLACE_KEYWORDS(friend, aFriend);
					REPLACE_KEYWORDS(goto, location);
					REPLACE_KEYWORDS(if, condition);
					REPLACE_KEYWORDS(inline, inlineValue);
					REPLACE_KEYWORDS(int, integer);
					REPLACE_KEYWORDS(long, longValue);
					REPLACE_KEYWORDS(mutable, mutableValue);
					REPLACE_KEYWORDS(namespace, aNamespace);
					REPLACE_KEYWORDS(new, newValue);
					REPLACE_KEYWORDS(operator, anOperator);
					REPLACE_KEYWORDS(protected, protection);
					REPLACE_KEYWORDS(public, publicity);
					REPLACE_KEYWORDS(register, registration);
					REPLACE_KEYWORDS(return, returnValue);
					REPLACE_KEYWORDS(short, shortValue);
					REPLACE_KEYWORDS(signed, signedValue);
					REPLACE_KEYWORDS(sizeof, size);
					REPLACE_KEYWORDS(static, electricity);
					REPLACE_KEYWORDS(struct, aStruct);
					REPLACE_KEYWORDS(switch, aSwitch);
					REPLACE_KEYWORDS(template, aTemplate);
					REPLACE_KEYWORDS(this, thisValue);
					REPLACE_KEYWORDS(throw, valueToThrow);
					REPLACE_KEYWORDS(true, truth);
					REPLACE_KEYWORDS(try, trial);
					REPLACE_KEYWORDS(typedef, typeDefinition);
					REPLACE_KEYWORDS(typeid, typeID);
					REPLACE_KEYWORDS(typename, typeName);
					REPLACE_KEYWORDS(union, aUnion);
					REPLACE_KEYWORDS(unsigned, unsignedValue);
					REPLACE_KEYWORDS(using, what);
					REPLACE_KEYWORDS(virtual, virtuality);
					REPLACE_KEYWORDS(void, nothing);
					REPLACE_KEYWORDS(volatile, volatility);
					REPLACE_KEYWORDS(while, duration);
					
					REPLACE_KEYWORDS(asm, assembly);
					
					REPLACE_KEYWORDS(and, aCondition);
					REPLACE_KEYWORDS(or, aCondition);
					REPLACE_KEYWORDS(xor, aCondition);
					REPLACE_KEYWORDS(not, aCondition);
					REPLACE_KEYWORDS(bitand, integer);
					REPLACE_KEYWORDS(bitor, integer);
					REPLACE_KEYWORDS(compl, complementer);
					
					// obj-c keywords or commonly used identifiers
					REPLACE_KEYWORDS(oneway, onewayValue);
					REPLACE_KEYWORDS(in, inValue);
					REPLACE_KEYWORDS(out, outValue);
					REPLACE_KEYWORDS(inout, inoutValue);
					REPLACE_KEYWORDS(byref, byrefValue);
					REPLACE_KEYWORDS(bycopy, bycopyValue);
					REPLACE_KEYWORDS(nil, nilValue);
					REPLACE_KEYWORDS(self, myself);
					REPLACE_KEYWORDS(super, superclass);
					REPLACE_KEYWORDS(id, ID);
					
					// C99 keywords
					REPLACE_KEYWORDS(restrict, restriction);
					
					// GNU C extension keywords
					REPLACE_KEYWORDS(typeof, type);
					
					// Common identifiers
					REPLACE_KEYWORDS(offsetof, index);
					REPLACE_KEYWORDS(assert, assertion);
					
				}
#undef REPLACE_KEYWORDS
				
				// search if the potential arg name is already defined. 
				// if yes, append the index to it.
				if (used_names.find(potential_argname) != used_names.end()) {
					char index_string[ LONG_ENOUGH_TO_FIT("%u") ];
					sprintf(index_string, "%u", k);
					potential_argname.append(index_string);
				}
				
				// done :)
				
				method_decl.append(potential_argname);
				used_names.insert(potential_argname);
			}
		}
		
		return method_decl;
	}
}

void MachO_File_ObjC::obtain_properties(const objc_property* cur_property, int& guess_text_segment, vector<const char*>& property_names, vector<string>& property_prefixes, vector<string>& property_getters, vector<string>& property_setters) throw() {
	const char* property_name = PEEK_VM_ADDR(cur_property->name, char, text);
	const char* property_type = PEEK_VM_ADDR(cur_property->attributes, char, text);
	
	property_names.push_back(property_name);
	
	string property_prefix = "";
	string property_rettype;
	string getter = property_name, setter = "set";
	setter.append(property_name);
	setter.push_back(':');
	setter[3] = static_cast<char>(toupper(property_name[0]));
	
	while (*property_type != '\0' && *property_type != 'V') {
		const char* next_comma;
		switch (*property_type) {
			case 'T': {
				unsigned chars_to_read = 0;
				property_rettype = decode_type(property_type+1, chars_to_read);
				property_type += chars_to_read;
				break;
			}
			case 'R':
				property_prefix.append(", readonly");
				++ property_type;
				setter.clear();
				break;
			case 'C':
				property_prefix.append(", copy");
				++ property_type;
				break;
			case '&':
				property_prefix.append(", retain");
				++ property_type;
				break;
			case 'G':
				property_prefix.append(", getter=");
				++ property_type;
				next_comma = strchr(property_type, ',');
				if (next_comma == NULL)
					next_comma = strchr(property_type, '\0');
				getter = string(property_type, next_comma);
				property_getters.push_back(getter);
				property_prefix.append(getter);
				property_type = next_comma;
				break;
			case 'S':
				property_prefix.append(", setter=");
				++ property_type;
				next_comma = strchr(property_type, ',');
				if (next_comma == NULL)
					next_comma = strchr(property_type, '\0');
				setter = string(property_type, next_comma);
				property_setters.push_back(setter);
				property_prefix.append(setter);
				property_type = next_comma;
				break;
			case 'V':	// synthesized property
			case 'D':	// dynamic property
				goto done_property_string_analyzing;
			default:
				++ property_type;
				break;
		}
	}
	
done_property_string_analyzing:
	if (property_prefix.empty())
		property_prefix = "assign";
	else
		property_prefix.erase(0, 2);
	
	property_prefix.append(") ");
	property_prefix.append(property_rettype);
	
	property_getters.push_back(getter);
	property_setters.push_back(setter);
	
	property_prefixes.push_back(property_prefix);
}

void MachO_File_ObjC::propertize(ClassDefinition& clsDef, const std::vector<const char*>& method_names, std::vector<const char*>& method_types) throw() {
	// Rules of properization:
	//   (1) If both xxx and setXxx: are defined and the types are the same, change to @property, with:
	//      - if the type is id, use (retain).
	//      - but if the name ends with "delegate" or "Delegate", use (assign).
	//         * if the corresponding ivar (xxx or _xxx) exists, then copy the type of that ivar.
	//      - for all other types, use (assign).
	//   (2) If both isXxx and setXxx: are defined, same as (1).
	//   (3) If xxx is defined and one of the ivars xxx or _xxx are defined, use (readonly).
	//   (4) If only isXxx is defined, use (readonly).
	
	// Round (1) + (2).
	unsigned j = 0;
	vector<const char*>::const_iterator nit = method_names.begin(), tit = method_types.begin();
	for (; nit != method_names.end(); ++ nit, ++ tit, ++ j) {
		if (*tit != NULL && strlen(*nit) >= 5 && strncmp(*nit, "set", 3) == 0 && !((*nit)[3] >= '0' && (*nit)[3] <= '9') && ((*tit)[0] == 'v' || (*tit)[0] == 'V')) {
			size_t type_len = strlen(*tit);
			if (type_len >= 8 && (*tit)[type_len-1] == '8' && !((*tit)[type_len-2] >= '0' && (*tit)[type_len-2] <= '9')) {
				size_t expected_name_length = strlen(*nit) - 4;
				if (expected_name_length == 0)
					continue;
				
				// we've found the setXxx: method. now found the corresponding xxx or isXxx method.
				const char* expected_type = strstr(*tit, "@0:4") + 4;
				size_t expected_type_string_length = *tit + type_len - expected_type - 1;
				char expected_type_string[expected_type_string_length + strlen("8@0:4") + 1];
				strncpy(expected_type_string, expected_type, expected_type_string_length);
				strcpy(expected_type_string+expected_type_string_length, "8@0:4");
				
				char expected_name[expected_name_length+1], expected_is_name[expected_name_length+3];
				strncpy(expected_name, *nit + 3, expected_name_length);
				expected_is_name[0] = 'i';
				expected_is_name[1] = 's';
				strncpy(expected_is_name + 2, *nit + 3, expected_name_length);
				if (expected_name_length == 1 || !(expected_name[1] >= 'A' && expected_name[1] <= 'Z'))
					expected_name[0] = static_cast<char>(tolower(expected_name[0]));
				expected_name[expected_name_length] = '\0';
				expected_is_name[expected_name_length+2] = '\0';
				
				unsigned j2 = 0;
				vector<const char*>::const_iterator nit2 = method_names.begin(), tit2 = method_types.begin();
				bool is_delegate = (expected_name_length >= strlen("delegate")) && (strcmp(expected_name+expected_name_length-8, "Delegate") == 0 || strcmp(expected_name+expected_name_length-8, "delegate") == 0);
				
				/*
				 // make sure the same property has not been defined before.
				 for (vector<const char*>::const_iterator cit = clsDef.property_names.begin(); cit != clsDef.property_names.end(); ++ cit) {
				 if (strcmp(*cit, expected_name) == 0)
				 goto has_same_property_already_12;
				 }
				 */
				
				for (; nit2 != method_names.end(); ++ nit2, ++ tit2, ++ j2) {
					// we've found a compatible type string. let's check the name
					if (j != j2 && *tit2 != NULL && strcmp(*tit2, expected_type_string) == 0) {
						bool need_getter_redefine;
						if (strcmp(*nit2, expected_name) == 0)
							need_getter_redefine = false;
						else if (strcmp(*nit2, expected_is_name) == 0)
							need_getter_redefine = true;
						else
							continue;
						
						string& getter_method_decl = clsDef.method_declarations[j2 + clsDef.instance_method_start];
						string& setter_method_decl = clsDef.method_declarations[j + clsDef.instance_method_start];
						// (a) record the vm address for the property.
						if (!clsDef.isProtocol) {
							clsDef.property_getter_address.push_back(clsDef.method_vm_addresses[j2 + clsDef.instance_method_start]);
							clsDef.property_setter_address.push_back(clsDef.method_vm_addresses[j + clsDef.instance_method_start]);
						}
						
						// (b) insert the property name.
						if (!need_getter_redefine)
							clsDef.property_names.push_back(*nit2);
						else {
							string prop_name = expected_name;
							ma_string_store.push_back(prop_name);	// the string store is to avoid a string being leaked or prematurely deallocated.
							clsDef.property_names.push_back(prop_name.c_str());
						}
						
						// (c) insert the property declaration
						string property_prefix;
						if (need_getter_redefine) {
							property_prefix = "getter=";
							property_prefix.append(*nit2);
						}
						if (expected_type_string_length == 1 && expected_type[0] == '@') {
							if (is_delegate)
								property_prefix.append(need_getter_redefine ? ")" : "assign) ");
							else
								property_prefix.append(need_getter_redefine ? ", retain)" : "retain) ");
							property_prefix.append(specialize_converted_id_property(clsDef.ivar_declarations, expected_name, expected_name_length));
						} else {
							property_prefix.append(need_getter_redefine ? ")" : "assign) ");
							size_t last_close_parenthesis = getter_method_decl.rfind(')');
							property_prefix.append(getter_method_decl.substr(2, last_close_parenthesis-2));
						}
						clsDef.property_prefixes.push_back(property_prefix);
						
						// (d) change the 2 methods into a comment
						setter_method_decl.insert(0, "// converted property setter: "); // :p
						getter_method_decl.insert(0, "// converted property getter: ");
						
						// (c) empty the original type to prevent it to be found again.
						method_types[j] = method_types[j2] = NULL;
						break;
					}
				}
				/*
				 has_same_property_already_12:
				 ;
				 */
			}
		}
	}
	
	// Round (3)
	/*
	 nit = method_names.begin();
	 tit = method_types.begin();
	 j = 0;
	 for (; nit != method_names.end(); ++ nit, ++ tit, ++ j) {
	 if (*tit != NULL) {
	 size_t type_length = strlen(*tit);
	 if (type_length >= 6 && strcmp(*tit + type_length - 5, "8@0:4") == 0 && (*tit)[0] != 'v' && (*tit)[0] != 'V') {
	 // it is an xxx method.
	 for (vector<string>::const_iterator cit = ivar_decl.begin(); cit != ivar_decl.end(); ++ cit) {
	 size_t has_name_loc = cit->rfind(*nit);
	 if (has_name_loc != string::npos && has_name_loc > 0) {
	 if ((*cit)[has_name_loc-1] == ' ' || has_name_loc > 1 && (*cit)[has_name_loc-1] == '_' && (*cit)[has_name_loc-2] == ' ') {
	 size_t name_length = strlen(*nit);
	 if (cit->size() == has_name_loc + name_length || cit->size() > has_name_loc + name_length && (*cit)[has_name_loc + name_length] == '[') {
	 string type_of_ivar = 
	 
	 }
	 }
	 }
	 }
	 }	
	 }
	 }
	 */
	
	// Round (4)
	nit = method_names.begin();
	tit = method_types.begin();
	j = 0;
	for (; nit != method_names.end(); ++ nit, ++ tit, ++ j) {
		if (*tit != NULL && strlen(*nit) >= 3 && strncmp(*nit, "is", 2) == 0 && !((*nit)[2] >= '0' && (*nit)[2] <= '9')) {
			size_t type_length = strlen(*tit);
			if (type_length >= 6 && strcmp(*tit + type_length - 5, "8@0:4") == 0 && (*tit)[0] != 'v' && (*tit)[0] != 'V') {
				// it is an isXxx method. 
				size_t expected_name_length = strlen(*nit) - 2;
				char expected_name[expected_name_length + 1];
				strcpy(expected_name, *nit + 2);
				if (expected_name_length == 1 || !(expected_name[1] >= 'A' && expected_name[1] <= 'Z'))
					expected_name[0] = static_cast<char>(tolower(expected_name[0]));
				
				// make sure the same property has not been defined before.
				for (vector<const char*>::const_iterator cit = clsDef.property_names.begin(); cit != clsDef.property_names.end(); ++ cit)
					if (strcmp(*cit, expected_name) == 0)
						goto has_same_property_already_4;
				
				// since these methods are usually BOOL, we don't waste time to specialize it.
				string expected_name_string = expected_name;
				ma_string_store.push_back(expected_name_string);
				clsDef.property_names.push_back(expected_name_string.c_str());
				
				string& getter_method_decl = clsDef.method_declarations[j + clsDef.instance_method_start];
				
				string property_prefix = "readonly, getter=";
				property_prefix.append(*nit);
				property_prefix.append(") ");
				size_t last_close_parenthesis = getter_method_decl.rfind(')');
				property_prefix.append(getter_method_decl.substr(2, last_close_parenthesis-2));
				clsDef.property_prefixes.push_back(property_prefix);
				
				if (!clsDef.isProtocol) {
					clsDef.property_getter_address.push_back(clsDef.method_vm_addresses[j + clsDef.instance_method_start]);
					clsDef.property_setter_address.push_back(0);
				}
				
				getter_method_decl.insert(0, "// converted property getter: ");
				
				method_types[j] = NULL;
			}
		}
	has_same_property_already_4:
		;
	}
}

const char* MachO_File_ObjC::get_superclass_name(unsigned superclass_addr, unsigned pointer_to_superclass_addr, const std::tr1::unordered_map<unsigned,unsigned>& all_class_def_indices, ClassDefinition** superclass_clsDef) throw() {
	if (superclass_clsDef != NULL)
		*superclass_clsDef = NULL;
	
	if (superclass_addr == 0) {
		// superclass should be an external class. read from relocation entry.
		const char* ext_name = this->string_representation(pointer_to_superclass_addr);
		// strip the _OBJC_CLASS_$_ beginning if there is one.
		if (ext_name != NULL && strncmp(ext_name, "_OBJC_CLASS_$_", strlen("_OBJC_CLASS_$_")) == 0)
			ext_name += strlen("_OBJC_CLASS_$_");
		ma_external_classes.push_back(string(ext_name));
		return ext_name;
	} else {
		// superclass should be an internal class. search from vm addresses.
		tr1::unordered_map<unsigned,unsigned>::const_iterator cit = all_class_def_indices.find(superclass_addr);
		if (cit == all_class_def_indices.end()) {
			superclass_clsDef = NULL;
			// actually an extenal class :(. Search again from reloc entry.
			const char* ext_name = this->string_representation(superclass_addr);
			if (ext_name != NULL && strncmp(ext_name, "_OBJC_CLASS_$_", strlen("_OBJC_CLASS_$_")) == 0)
				ext_name += strlen("_OBJC_CLASS_$_");
			ma_external_classes.push_back(string(ext_name));
			return ext_name;
		} else {
			ClassDefinition& superClsDef = ma_classes[cit->second];
			if (superclass_clsDef != NULL)
				*superclass_clsDef = &superClsDef;
			return superClsDef.name;
		}
	}
}

string MachO_File_ObjC::get_struct_definition(const StructDefinition& curDef, bool need_typedef, bool prettify) throw() {
	string retstr;
	
	unsigned name_length = curDef.name.size();
	bool is_template = name_length > 0 && curDef.name[name_length-1] == '>';
	if (is_template) {
		retstr.append("template<>\n");
	} else if (need_typedef)
		retstr.append("typedef ");
	
	if (curDef.is_union)
		retstr.append("union");
	else
		retstr.append("struct");
	if (!curDef.name.empty()) {
		retstr.push_back(' ');
		retstr.append(curDef.name);
	}
	
	if (curDef.direct_reference || curDef.member_typestrings.size() > 0) {
		retstr.append(" {\n");
		
		vector<string>::const_iterator cit1 = curDef.member_typestrings.begin();
		vector<string>::const_iterator cit2 = curDef.members.begin();
		unsigned field = 1;
		bool has_member_names = !curDef.members.empty();
		
		unsigned dummy;
		
		for (; cit1 != curDef.member_typestrings.end(); ++ cit1) {
			dummy = 0;
			char argname[ LONG_ENOUGH_TO_FIT("_field%u") ];
			const char* actual_argname;
			
			if (has_member_names) {
				actual_argname = cit2->c_str();
				++ cit2;
			} else {
				sprintf(argname, "_field%u", field++);
				actual_argname = argname;
			}
			
			retstr.push_back('\t');
			string decoded_string = this->decode_type(cit1->c_str(), dummy, actual_argname, false, 1, true);
			if (prettify)
				this->replace_prettified_struct_names(decoded_string, 1, curDef.name);
			retstr.append(decoded_string);
			retstr.append(";\n");
		}
		
		retstr.push_back('}');
	}
	
	if (!is_template && need_typedef) {
		retstr.push_back(' ');
		retstr.append(curDef.prettified_name);
	}
	
	return retstr;
}

bool MachO_File_ObjC::replace_prettified_struct_names(string& str, unsigned tab_length, const string& caller_name) throw() {
	string retstr;
	bool replaced_already = false;
	unsigned grave_position = 0, last_grave_position;
	while (true) {
		last_grave_position = grave_position;
		grave_position = str.find('`', grave_position);
		if (grave_position == string::npos) {
			if (replaced_already) {
				retstr.append(str.substr(last_grave_position));
				str = retstr;
			}
			return replaced_already;
		}
		// found a `. Try to read an integer starting at that position.
		++ grave_position;
		unsigned index;
		int chars_read;
		if (sscanf(str.c_str()+grave_position, "%u%n", &index, &chars_read) != 0) {
			//if (!replaced_already) {
			retstr.append(str.substr(last_grave_position, grave_position-1-last_grave_position));
			replaced_already = true;
			//}
			StructDefinition* sd = &(ma_struct_definitions[index]);
			while (sd->see_also != ~0u) {
				if (sd->see_also == ~1u) {
					retstr.append(sd->is_union ? "XXAnonymousUnion" : "XXAnonymousStruct");
					goto continue_to_search_for_graves;
				} else
					sd = &(ma_struct_definitions[sd->see_also]);
			}
			grave_position += chars_read;
			// self-referal happens only when the struct has contents.
			if (!caller_name.empty() && sd->name == caller_name && sd->member_typestrings.size() > 0) {
				if (sd->is_union)
					retstr.append("union ");
				else
					retstr.append("struct ");
				retstr.append(caller_name);
			} else if (!sd->is_union && !sd->direct_reference && !sd->prettified_name.empty() && sd->member_typestrings.size() == 0 && (sd->prettified_name.size() < 2 || sd->prettified_name.substr(0,2) != "NS") && sd->name[sd->name.size()-1] != '>') {
				retstr.append(sd->prettified_name);
				retstr.append("Ref");
				++ grave_position;
			} else {
				entab(sd->prettified_name, tab_length);
				retstr.append(sd->prettified_name);
			}
		}
	continue_to_search_for_graves:
		;
	}
}

bool MachO_File_ObjC::member_typestrings_equal(const std::vector<std::string>& a, const std::vector<std::string>& b) const throw() {
	if (a.size() != b.size())
		return false;
	for (vector<string>::const_iterator ait = a.begin(), bit = b.begin(); ait != a.end(); ++ait, ++bit) {
		if ((ait->at(0) == '{' || ait->at(0) == '(') && ait->at(0) == bit->at(0)) {
			if (*ma_struct_indices.find(*ait) != *ma_struct_indices.find(*bit))
				return false;
		} else if (ait->at(0) == '@' && bit->at(0) == '@') {
			if (ait->size() != 1 && bit->size() != 1 && *ait != *bit)
				return false;
		} else if (*ait != *bit)
			return false;
	}
	return true;
}

unsigned MachO_File_ObjC::get_struct_link_type(const string& decl, unsigned minimum_link_type, unsigned struct_id_to_match) const throw() {
	unsigned grave_position = 0;
	unsigned lt = LT_None;
	unsigned prev_lt = minimum_link_type;
	while (true) {
		grave_position = decl.find('`', grave_position);
		if (grave_position == string::npos)
			return prev_lt;
		++ grave_position;
		
		unsigned struct_id;
		int chars_read;
		if (sscanf(decl.c_str() + grave_position, "%u%n", &struct_id, &chars_read) != 0) {
			grave_position += chars_read;
			lt = decl[grave_position] == '*' ? LT_Weak : LT_Strong;
			if (lt <= prev_lt)
				continue;
			unsigned last_remap, remap = struct_id;
			while (remap != ~0u || remap != ~1u) {
				last_remap = remap;
				remap = ma_struct_definitions[remap].see_also;
			}
			if (last_remap == struct_id_to_match) {
				prev_lt = lt;
				if (lt == LT_Strong)
					return LT_Strong;
			}
		}
	}
}
