/*

objc_type.cpp ... Objective-C type decoder & usage network manager.

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
#include <algorithm>
#include "crc32.h"
#include "balanced_substr.h"
#include "string_util.h"

using namespace std;

static const char* map314[] = {
	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,	// 0 - F
	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,

	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,	// 10 - 1F
	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,

	NULL, "/*gc-invisible*/", NULL, "Class", NULL, "NXAtom", NULL, NULL,	// [space] ! " # $ % & '        ( ) * + , - . /
	NULL, NULL, "char*", NULL, NULL, NULL, NULL, NULL,

// let's hope gcc won't use the numbers :(
	NULL, NULL, NULL, NULL, NULL, NULL, "/*xxintrnl-category*/", "/*xxintrnl-protocol*/",	// 0 1 2 3 4 5 6 7         8 9 : ; < = > ?
	NULL, NULL, "SEL", NULL, NULL, NULL, NULL, "/*function-pointer*/ void",

	"id", NULL, "bool", "unsigned char", NULL, NULL, NULL, NULL,	// @ A B C D E F G        H I J K L M N O
	NULL, "unsigned", NULL, NULL, "unsigned long", NULL, "inout", "bycopy",

	NULL, "unsigned long long", "byref", "unsigned short", NULL, NULL, "oneway",	// P Q R S T U V W        X Y Z [ \ ] ^ _
	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,

	NULL, NULL, NULL, "char", "double", NULL, "float", NULL, 	// ` a b c d e f g         h i j k l m n o
	NULL, "int", "_Complex", NULL, "long", NULL, "in", "out",

	NULL, "long long", "const", "short", NULL, NULL, "void",	// p q r s t u v w         x y z { | } ~ [del]
	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
};

/*
namespace std { 
	namespace tr1 { 
 */
namespace boost {
		template<>
		struct hash< ::ObjCTypeRecord::TypePointerPair> : public unary_function< ::ObjCTypeRecord::TypePointerPair, size_t> {
			size_t operator() (const ::ObjCTypeRecord::TypePointerPair& x) const throw() {
				size_t retval = reinterpret_cast<size_t>(x.a) + 0x9e3779b9;
				retval ^= reinterpret_cast<size_t>(x.b) + 0x9e3779b9 + (retval << 6) + (retval >> 2);
				return retval;
			}
		};
//	}
}



ObjCTypeRecord::TypeIndex ObjCTypeRecord::parse(const string& type_to_parse, bool is_struct_used_locally) {
	tr1::unordered_map<string, TypeIndex>::const_iterator p_index = ma_indexed_types.find(type_to_parse);
		
	if (p_index != ma_indexed_types.end()) {
		Type& retval = ma_type_store[p_index->second];
		if (is_struct_used_locally) {
			if (retval.refcount != Type::used_globally)
				++ retval.refcount;
		} else
			retval.refcount = Type::used_globally;
		return p_index->second;
	}
	
	Type t = Type(*this, type_to_parse, is_struct_used_locally);
	
	TypeIndex ret_index = ma_type_store.size();
	
	// merge struct with the same name, typesignature etc. 
	if (t.type != '@' && (!t.subtypes.empty() || !t.name.empty())) {
		ret_index = 0;
		tr1::unordered_set<TypePointerPair> banned_pairs;
		for (vector<Type>::iterator cit = ma_type_store.begin(); cit != ma_type_store.end(); ++ cit, ++ ret_index) {
			if (cit->is_compatible_with(t, *this, banned_pairs)) {
				if (is_struct_used_locally) {
					t.refcount = cit->refcount;
				} else
					cit->refcount = Type::used_globally;
				ma_indexed_types.insert(pair<string,unsigned>(type_to_parse, ret_index));
				if (t.is_more_complete_than(*cit))
					*cit = t;
				else
					t = *cit;
				goto combined;
			}
		}
	}
	
	ma_type_store.push_back(t);
	ma_indexed_types.insert(pair<string,unsigned>(type_to_parse, ret_index));
	
combined:
	// add strong link to its children. (only for unions & structs.)
	if (t.type == '{' || t.type == '(')
		for (vector<TypeIndex>::const_iterator cit = t.subtypes.begin(); cit != t.subtypes.end(); ++ cit)
			add_strong_link(ret_index, *cit);
		
	return ret_index;
}

string ObjCTypeRecord::format_forward_declaration(const vector<TypeIndex>& type_indices) const throw() {
	string class_refs, protocol_refs, struct_refs;
	
	for (vector<TypeIndex>::const_iterator cit = type_indices.begin(); cit != type_indices.end(); ++ cit) {
		if (*cit == m_id_type_index)
			continue;
		const Type& type = ma_type_store[*cit];
		switch (type.type) {
			case '@':
				if (class_refs.empty())
					class_refs += "@class ";
				else
					class_refs += ", ";
				class_refs += type.name;
				break;
			case '7':
				if (protocol_refs.empty())
					protocol_refs += "@protocol ";
				else
					protocol_refs += ", ";
				protocol_refs += type.value;
				break;
			case '(':
			case '{':
				if (type.name.empty() || type.subtypes.empty())
					struct_refs += type.format(*this, "", 0, true, true, pointers_right_aligned);
				else {
					// doesn't matter template<> or not. You can't forward reference a template class. It must be converted to a strong link.
					struct_refs += "typedef ";
					struct_refs += (type.type == '(') ? "union " : "struct ";
					struct_refs += type.name;
					struct_refs.push_back(' ');
					struct_refs += type.pretty_name;
				}
				struct_refs += ";\n";
				break;
			default:
				break;
		}
	}
		
	if (!class_refs.empty()) {
		struct_refs += class_refs;
		struct_refs += ";\n";
	}
	if (!protocol_refs.empty()) {
		struct_refs += protocol_refs;
		struct_refs += ";\n";
	}
	
	return struct_refs;
}

ObjCTypeRecord::TypeIndex ObjCTypeRecord::add_external_objc_class(const std::string& objc_class) {
	TypeIndex idx = parse("@\"" + objc_class + "\"", false);
	ma_type_store[idx].external = true;
	return idx;
}

ObjCTypeRecord::TypeIndex ObjCTypeRecord::add_internal_objc_class(const std::string& objc_class) {
	TypeIndex idx = parse("@\"" + objc_class + "\"", false);
	ma_type_store[idx].external = false;
	return idx;
}

ObjCTypeRecord::TypeIndex ObjCTypeRecord::add_objc_protocol(const std::string& protocol) {
	return parse("7" + protocol, false);
}

ObjCTypeRecord::TypeIndex ObjCTypeRecord::add_objc_category(const std::string& category_name, const std::string& categorized_class) {
	return parse("6" + category_name + "@\"" + categorized_class + "\"", false);	// the category name must be an identifier.
}

void ObjCTypeRecord::add_link_with_strength(TypeIndex from, TypeIndex to, EdgeStrength target_strength, bool convert_class_strength_to_weak) {
	if (from == to)
		return;
	
	Type& target_type = ma_type_store[to];
	switch (target_type.type) {
		case '^':	// for pointers, building any link to it is equivalent to building a weak link to its underlying type.
			add_link_with_strength(from, target_type.subtypes[0], ES_Weak, true);
			return;
			
		case '[':
		case 'j':
		case 'r':
		case 'R':
		case 'n':
		case 'N':
		case 'o':
		case 'O':
		case 'V':
		case '!':	// for arrays and other type qualifiers, building any link to it is equivalent to building the same link to its underlying type.
			add_link_with_strength(from, target_type.subtypes[0], target_strength, true);
			return;
			
		case '@':	// for objects, if it has adopted protocols specified, build weak links to them also. And redirect the link to its original type.
			if (!target_type.subtypes.empty()) {
				if (!target_type.name.empty())
					add_link_with_strength(from, parse("@\"" + target_type.name + "\"", false), target_strength, true);
				for (vector<TypeIndex>::const_iterator cit = target_type.subtypes.begin(); cit != target_type.subtypes.end(); ++ cit)
					add_link_with_strength(from, *cit, ES_Weak, true);
				return;
			} else if (convert_class_strength_to_weak) {
				if (target_strength <= ES_StrongIndirect || target_type.name.empty())
					return;
				target_strength = ES_Weak;
			}
			break;
			
		case '{':
		case '(':
		case '6':
		case '7':	// link building is possible only for Objective-C classes, structs, unions, protocols and categories.
			break;
			
		default:	// other types shouldn't involve.
			return;
	}
	
	tr1::unordered_map<TypeIndex, EdgeStrength>& from_adjs = ma_adjlist[from];
	
	EdgeStrength& strength = from_adjs[to];
	bool need_bfs = false;
	if (strength < target_strength) {
		if (strength == 0)
			++ ma_k_in[to];
		if (target_strength == ES_Strong)
			++ ma_strong_k_in[to];
		
		strength = target_strength;
		if (target_strength >= ES_StrongIndirect)
			need_bfs = true;
	}
	if (!need_bfs)
		return;
	
	// BFS through all strong (direct or indirect) neighbors of the target node and make an indirect strong link with them.
	vector<TypeIndex> bfs_stack;
	bfs_stack.push_back(to);
	tr1::unordered_set<TypeIndex> visited;
	visited.insert(to);
	
	while (bfs_stack.size() != 0) {
		TypeIndex cur = bfs_stack.back();
		bfs_stack.pop_back();
		tr1::unordered_map<TypeIndex, EdgeStrength>& cur_adjs = ma_adjlist[cur];
		
		for (tr1::unordered_map<TypeIndex, EdgeStrength>::iterator cit = cur_adjs.begin(); cit != cur_adjs.end(); ++ cit) {
			if (cit->second >= ES_StrongIndirect && visited.insert(cit->first).second) {
				EdgeStrength& orig_strength = from_adjs[cit->first];
				if (orig_strength < ES_StrongIndirect) {
					if (orig_strength == 0)
						++ ma_k_in[cit->first];
					orig_strength = ES_StrongIndirect;
				}
				bfs_stack.push_back(cit->first);
			}
		}
	}
}

// for 2 types to be equal...
bool ObjCTypeRecord::Type::is_compatible_with(const Type& another, const ObjCTypeRecord& record, tr1::unordered_set<TypePointerPair>& banned_pairs) const throw() {
	// this is pretty obvious yeah?
	if (this == &another)
		return true;
	
	if (banned_pairs.find(TypePointerPair(this,&another)) != banned_pairs.end())
		return false;
	
	// (1) they must have the same leading character.
	if (type != another.type)
		return false;
	
	// (2) the values must be equal. (this forces int x[12] != int y[24].)
	if (value != another.value)
		return false;
	
	// (3) Don't match anonymous structs/unions with content, with named undeclared structs/unions.
	if ((type == '{' || type == '(') && ((another.subtypes.empty() && name.empty()) || (subtypes.empty() && another.name.empty()))) {
		return false;
	}
	
	// (4) the field names, if both present, must be equal. (this allows struct { int _field1; } == struct SingletonValue { int value; }, but struct Point { float x, y; } != struct Complex { float x, y; }.)
	if (!name.empty()) {
		if (!another.name.empty()) {
			if (name != another.name)
				return false;
		}
	}
	
	// (5) the subtypes, if any, must be equal.
	if (!subtypes.empty()) {
		if (!another.subtypes.empty()) {
			if (subtypes.size() != another.subtypes.size())
				return false;
			
			// do not match a struct having an id with anything *except* when the field names match.
			bool i_have_id = false, you_have_id = false;
			for (vector<TypeIndex>::const_iterator cit1 = subtypes.begin(); cit1 != subtypes.end(); ++ cit1)
				if (record.is_id_type(*cit1)) {
					i_have_id = true;
					break;
				}
			for (vector<TypeIndex>::const_iterator cit2 = another.subtypes.begin(); cit2 != another.subtypes.end(); ++ cit2)
				if (record.is_id_type(*cit2)) {
					you_have_id = true;
					break;
				}
			if (i_have_id != you_have_id)
				return false;
			else if (i_have_id) {
				if (name.empty())
					if (field_names.empty() || field_names != another.field_names)
						return false;
			}
			
			// prevent infinite recursion when comparing struct $_1 { int value; struct $_1* next; }; vs struct $_2 { int value; struct $_2* next; };
			banned_pairs.insert(TypePointerPair(this,&another));
			
			for (vector<TypeIndex>::const_iterator cit1 = subtypes.begin(), cit2 = another.subtypes.begin(); cit1 != subtypes.end(); ++cit1, ++cit2)
				if (*cit1 != *cit2 && !record.ma_type_store[*cit1].is_compatible_with(record.ma_type_store[*cit2], record, banned_pairs))
					return false;
		}
	}
	
	return true;
}

bool ObjCTypeRecord::Type::is_more_complete_than (const Type& another) const throw() {
	bool i_have_name = !name.empty(), you_have_name = !another.name.empty();
	
	// Named struct is always more complete than anonymous structs
	if (i_have_name && !you_have_name)
		return true;
	else if (you_have_name && !i_have_name)
		return false;
	
	bool i_have_content = !subtypes.empty(), you_have_content = !another.subtypes.empty();
	
	// Declared struct is more complete than undeclared ones.
	if (i_have_content && !you_have_content)
		return true;
	else if (you_have_content && !i_have_content)
		return false;
	
	// Having field names is better than none.
	bool i_have_field_names = !field_names.empty(), you_have_field_names = !another.field_names.empty();
	if (i_have_field_names && !you_have_field_names)
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
static string parse_struct_name (const char* typestr, const char** res) {
	if (*typestr == '?') {
		*res = ++typestr;
		return "";
	}
	
	const char* identifier_start = typestr;
	while (*typestr != '=' && *typestr != ')' && *typestr != '}')
		typestr = skip_balanced_substring(typestr);
	*res = typestr;
	
	string name = string(identifier_start, typestr);
	// $_123 are g++'s way to denote an anonymous struct.
	if (name.size() > 2 && name.substr(0, 2) == "$_" && name.find_first_not_of("0123456789", 2) == string::npos)
		return "";
	
	return name;
}

static vector<string> parse_struct_members (const char* member_typestrings, bool& has_field_names) {
	vector<string> typestrings_list;
	const char* subtype_begin = member_typestrings;
	has_field_names = (*member_typestrings == '"');
	bool finish = false;
	
	// Parse the whole string into tokens.
	while (!finish) {
		switch (*member_typestrings) {
			default:
				member_typestrings = skip_balanced_substring(member_typestrings);
				typestrings_list.push_back(string(subtype_begin, member_typestrings));
				subtype_begin = member_typestrings;
				break;
				
			case '}':
			case ')':
			case '\0':
				finish = true;
				break;
				
			case 'b':
				member_typestrings += strspn(member_typestrings+1, "0123456789")+1;
				typestrings_list.push_back(string(subtype_begin, member_typestrings));
				subtype_begin = member_typestrings;
				break;
				
			case '^':
			case 'j':
			case 'r':
			case 'R':
			case 'n':
			case 'N':
			case 'o':
			case 'O':
			case 'V':
			case '!':
				++ member_typestrings;
				break;
		}
	}
	
	// Merge @ and "xxx" into @"xxx" if possible.
	vector<string> retval;
	for (vector<string>::const_iterator cit = typestrings_list.begin(); cit != typestrings_list.end(); ++ cit) {
		if (*cit == "@") {
			if (cit+1 != typestrings_list.end() && (*(cit+1))[0] == '"') {
				if (!has_field_names || cit+2 == typestrings_list.end() || (*(cit+2))[0] == '"') {
					retval.push_back(*cit + *(cit+1));
					++ cit;
					continue;
				}
			}
		}
		retval.push_back(*cit);
	}
	
	return retval;
}

ObjCTypeRecord::Type::Type(ObjCTypeRecord& record, const string& type_to_parse, bool is_struct_used_locally) : type(type_to_parse[0]), external(true), refcount(is_struct_used_locally ? 1 : Type::used_globally) {
	switch (type) {
		case '6': {	// category -- for internal use only.
			external = false;
			size_t first_at_position = type_to_parse.find('@');
			value = type_to_parse.substr(1, first_at_position-1);
			subtypes.push_back( record.parse(type_to_parse.substr(first_at_position), false) );
			break;
		}
		case 'b':
		case '7':	// protocol -- for internal use only.
			external = false;
			value = type_to_parse.substr(1);
			break;
			
		case '^':
		case 'j':
		case 'r':
		case 'R':
		case 'n':
		case 'N':
		case 'o':
		case 'O':
		case 'V':
		case '!':	// GC Invisible. (! can also be "Vector type". But these are rare enough to be used in anywhere.)
			subtypes.push_back( record.parse(type_to_parse.substr(1), false) );
			break;

		case '@':
			if (type_to_parse.size() != 1) {
				name = type_to_parse.substr(2, type_to_parse.size()-3);
				size_t first_angle_bracket = name.find('<');
				if (first_angle_bracket != string::npos) {
					value = name.substr(first_angle_bracket);
					if (first_angle_bracket != 0) {
						// just to create a type.
						name = name.substr(0, first_angle_bracket);
						record.parse("@\"" + name + "\"", false);
					} else
						name = "";
					
					first_angle_bracket = 0;

					while (first_angle_bracket != value.size()) {
						size_t first_close_angle_bracket = value.find('>', first_angle_bracket+1);
						string proto_name = value.substr(first_angle_bracket+1, first_close_angle_bracket-first_angle_bracket-1);
						subtypes.push_back( record.parse("7" + proto_name, false) );
						first_angle_bracket = first_close_angle_bracket+1;
					}
					if (!subtypes.empty()) {
						// Make sure id<NSCopying, NSCoding> is compatible with id<NSCoding, NSCopying>.
						sort(subtypes.begin(), subtypes.end());
						
						value = "<";
						bool is_first = true;
						for (vector<TypeIndex>::const_iterator cit = subtypes.begin(); cit != subtypes.end(); ++ cit) {
							if (is_first)
								is_first = false;
							else
								value += ", ";
							value += record.ma_type_store[*cit].value;
						}
						value.push_back('>');
					}
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
			// anonymous contentless struct
			if (type_to_parse == "{?}" || type_to_parse == "(?)") {
				refcount = Type::used_globally;
				break;
			}
			
			const char* typestr = type_to_parse.c_str()+1;
			
			name = parse_struct_name(typestr, &typestr);
			
			if (*typestr == '=') {
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
string ObjCTypeRecord::Type::format (const ObjCTypeRecord& record, const string& argname, unsigned tabs, bool treat_char_as_bool, bool as_declaration, bool pointers_right_aligned, bool dont_typedef) const throw() {
	string retval = string(tabs, '\t');
	switch (type) {
		case '*':
			if (pointers_right_aligned) {
				retval += "char *";
				retval += argname;
				return retval;
			}
			// fall-through
			
		default: {
			const char* map_type = map314[static_cast<unsigned char>(type)];
			if (map_type != NULL) {
				retval += map_type;
				if (subtypes.size() == 1) {
					retval.push_back(' ');
					retval += record.ma_type_store[subtypes[0]].format(record, argname, 0, false, false, pointers_right_aligned);
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
				retval += subtype.format(record, pseudo_argname, 0, true, false, pointers_right_aligned);
				return retval;
			} else if (subtype.type == '{' && subtype.subtypes.empty() && !subtype.name.empty() && subtype.name.find('<') == string::npos && subtype.pretty_name.substr(0, 2) != "NS") {
				retval += subtype.pretty_name;
				retval += "Ref";
			} else {
				string pseudo_argname = "*";
				pseudo_argname += argname;
				retval += subtype.format(record, pseudo_argname, 0, true, false, pointers_right_aligned);	// if it's char* it will be encoded as ^* instead of ^^c, so it's OK to treat_char_as_bool.
				// change all int ***c to int*** c.
				if (!pointers_right_aligned) {
					for (unsigned i = 0; i < retval.size()-1; ++ i) {
						if (retval[i] == ' ' && retval[i+1] == '*') {
							retval[i] = '*';
							retval[i+1] = ' ';
						}
					}
					if (retval[retval.size()-1] == ' ')
						retval.erase(retval.size()-1);
				}
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
			retval = subtype.format(record, pseudo_argname, tabs, true, as_declaration, pointers_right_aligned);
			return retval;
		}
			
		case '@':
			if (name.empty())
				retval += "id";
			else
				retval += name;
			/*
			if (!subtypes.empty()) {
				retval.push_back('<');
				bool is_first = true;
				for (vector<unsigned>::const_iterator cit = subtypes.begin(); cit != subtypes.end(); ++ cit) {
					if (is_first)
						is_first = false;
					else
						retval += ", ";
					retval += record.ma_type_store[*cit].name;
				}
				retval.push_back('>');
			}
			 */
			retval += value;
			if (!name.empty()) {
				if (pointers_right_aligned) {
					retval += " *";
					retval += argname;
					return retval;
				} else
					retval.push_back('*');
			}
			break;
			
		case '(':
		case '{':
			if (name.empty() && subtypes.empty() ) {
				retval += type == '(' ? "union {}" : "struct {}";
				
			} else if (!as_declaration && (!name.empty() || refcount > 1)) {
				retval += pretty_name;
				
			} else {
				string tab_string = retval;
				
				if (name.find('<') != string::npos) {
					retval += "template<>\n";
					retval += tab_string;
				} else if (!dont_typedef && (!name.empty() || refcount > 1))
					retval += "typedef ";
				
				retval += (type == '(') ? "union" : "struct";
				
				if (!name.empty()) {
					retval.push_back(' ');
					retval += name;
					if (subtypes.empty() && name.find('<') == string::npos) {
						if (type == '{' && pretty_name.substr(0, 2) != "NS") {
							retval += pointers_right_aligned ? " *" : "* ";
							retval += pretty_name;
							retval += "Ref";
						} else {
							retval.push_back(' ');
							retval += pretty_name;
						}
					}
				}
				
				if (!subtypes.empty()) {
					retval += " {\n";
					string field_name;
					for (unsigned i = 0; i < subtypes.size(); ++ i) {
						if (field_names.size() > 0)
							field_name = field_names[i];
						else
							field_name = numeric_format("_field%u", i+1);
						
						retval += record.ma_type_store[subtypes[i]].format(record, field_name, tabs+1, true, false, pointers_right_aligned);
						retval += ";\n";
					}
					
					retval += tab_string;
					retval.push_back('}');
					if (!dont_typedef && (name.find('<') == string::npos && (!name.empty() || refcount > 1))) {
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

bool ObjCTypeRecord::can_dereference_to_id_type(TypeIndex idx) const throw() {
	if (idx == m_id_type_index)
		return true;
	
	const Type* type = &(ma_type_store[idx]);
	while (true) {
		switch (type->type) {
			case '@':
				return true;
				
			default:
				return false;
				
			case '^':
			case '[':
			case 'j':
			case 'r':
			case 'R':
			case 'n':
			case 'N':
			case 'o':
			case 'O':
			case 'V':
			case '!':
				type = &(ma_type_store[type->subtypes[0]]);
				break;
		}
	}
}

bool ObjCTypeRecord::are_types_compatible(TypeIndex a, TypeIndex b) const throw() {
	if (a == b)
		return true;
	tr1::unordered_set<TypePointerPair> banned_pairs;
	return ma_type_store[a].is_compatible_with(ma_type_store[b], *this, banned_pairs);
}

vector<ObjCTypeRecord::TypeIndex> ObjCTypeRecord::all_public_struct_types() const throw() {
	vector<TypeIndex> ret;
	for (unsigned i = 0; i < ma_type_store.size(); ++ i) {
		const Type& type = ma_type_store[i];
		if ((type.type == '(' || type.type == '{') && (!type.name.empty() || type.refcount > 1))
			ret.push_back(i);
	}
	return ret;
}

struct octr_AlphabeticSorter {
private:
	const ObjCTypeRecord& record;
public:
	octr_AlphabeticSorter(const ObjCTypeRecord& record_) : record(record_) {}
	
	bool operator() (ObjCTypeRecord::TypeIndex a, ObjCTypeRecord::TypeIndex b) const throw() {
		return record.name_of_type(a) < record.name_of_type(b);
	}
};

struct octr_StrongLinkSorter {
private:
	const ObjCTypeRecord& record;
public:
	octr_StrongLinkSorter(const ObjCTypeRecord& record_) : record(record_) {}
	
	bool operator() (ObjCTypeRecord::TypeIndex a, ObjCTypeRecord::TypeIndex b) const throw() {
		bool strong_ab = record.link_strength(a, b) >= ObjCTypeRecord::ES_StrongIndirect;
		bool strong_ba = record.link_strength(b, a) >= ObjCTypeRecord::ES_StrongIndirect;
		if (strong_ab == strong_ba)
			return a < b;
		else 
			return strong_ba;
	}
};

void ObjCTypeRecord::sort_alphabetically(vector<TypeIndex>& type_indices) const throw() {
	sort(type_indices.begin(), type_indices.end(), octr_AlphabeticSorter(*this));
}

void ObjCTypeRecord::sort_by_strong_links(vector<TypeIndex>& type_indices) const throw() {
	sort(type_indices.begin(), type_indices.end(), octr_StrongLinkSorter(*this));
}

string ObjCTypeRecord::format_structs_with_forward_declarations(const vector<TypeIndex>& type_indices) const throw() {
	vector<TypeIndex> indices = type_indices;
	sort_by_strong_links(indices);
	string res;
	tr1::unordered_set<TypeIndex> forward_declared; //, index_set (indices.begin(), indices.end());
	
	vector<TypeIndex> weak_dependecies;
	for (vector<TypeIndex>::const_iterator cit = indices.begin(); cit != indices.end(); ++ cit) {
		// Forward declare any weak dependencies first.
		weak_dependecies.clear();
		
		const tr1::unordered_map<TypeIndex, EdgeStrength>* cur_dependencies = dependencies(*cit);
		if (cur_dependencies != NULL)
			for (tr1::unordered_map<TypeIndex, EdgeStrength>::const_iterator dit = cur_dependencies->begin(); dit != cur_dependencies->end(); ++ dit) {
				if (dit->second == ES_Weak && dit->first != *cit && forward_declared.find(dit->first) == forward_declared.end()) {
					forward_declared.insert(dit->first);
					weak_dependecies.push_back(dit->first);
				}
			}
		
		res += format_forward_declaration(weak_dependecies);
		res += format(*cit, "", 0, true, forward_declared.find(*cit) != forward_declared.end());
		res += ";\n\n";
		
		forward_declared.insert(*cit);
	}
	
	return res;
}

void ObjCTypeRecord::print_network() const throw() {
	printf("digraph G {\n");
	for (tr1::unordered_map<TypeIndex, tr1::unordered_map<TypeIndex, EdgeStrength> >::const_iterator cit = ma_adjlist.begin(); cit != ma_adjlist.end(); ++ cit) {
		const Type& t = ma_type_store[cit->first];
		char tp = t.type;
		const char* shape = (tp == '(' || tp == '{') ? "box" : t.external ? "doublecircle" : "circle";
		printf("\t\"%c%s%s\" [shape=%s]\n", tp, t.name.c_str(), t.value.c_str(), shape);
	}
	string s;
	for (tr1::unordered_map<TypeIndex, tr1::unordered_map<TypeIndex, EdgeStrength> >::const_iterator cit = ma_adjlist.begin(); cit != ma_adjlist.end(); ++ cit) {
		const Type& t = ma_type_store[cit->first];
		s = string(1, t.type);
		s += t.name;
		s += t.value;
		for (tr1::unordered_map<TypeIndex, EdgeStrength>::const_iterator dit = cit->second.begin(); dit != cit->second.end(); ++ dit) {
			const Type& t2 = ma_type_store[dit->first];
			printf("\t\"%s\" -> \"%c%s%s\" [color=%s]\n", s.c_str(), t2.type, t2.name.c_str(), t2.value.c_str(), dit->second == ES_Strong ? "black" : dit->second == ES_StrongIndirect ? "gray50" : "gray");
		}
	}
	printf("}\n");
}
