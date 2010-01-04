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
#include <cctype>
#include "crc32.h"
#include "balanced_substr.h"
#include "string_util.h"
#include "combine_dependencies.h"
#include "hash_combine.h"

#ifdef _MSC_VER
#define __alignof__ __alignof
#endif

using namespace std;

static const char* map314[] = {
	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,	// 0 - F
	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,

	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,	// 10 - 1F
	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,

	NULL, "/*gc-invisible*/", NULL, "Class", NULL, "NXAtom", NULL, NULL,	// [space] ! " # $ % & '        ( ) * + , - . /
	NULL, NULL, "char*", NULL, NULL, NULL, NULL, NULL,

// let's hope gcc won't use the numbers :(
	NULL, NULL, NULL, NULL, "/*function*/", "?", "/*xxintrnl-category*/", "/*xxintrnl-protocol*/",	// 0 1 2 3 4 5 6 7         8 9 : ; < = > ?
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

#if _TR1_FUNCTIONAL || _MSC_VER
namespace std 
#if !_MSC_VER
{ 
	namespace tr1
#endif
#else
namespace boost
#endif
	{
		template<>
		struct hash< ::ObjCTypeRecord::TypePointerPair> : public unary_function< ::ObjCTypeRecord::TypePointerPair, size_t> {
			size_t operator() (const ::ObjCTypeRecord::TypePointerPair& x) const throw() {
				size_t retval = 0;
				hash_combine(retval, x.a);
				hash_combine(retval, x.b);
				return retval;
			}
		};
#if _TR1_FUNCTIONAL
	}
#endif
}

static inline bool name_Refable(const string& pretty_name) throw() {
	return pretty_name.substr(0, 2) != "NS" && isupper(pretty_name[0]) && isupper(pretty_name[1]) && isupper(pretty_name[2]);
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
	t.type_index = ret_index;
	
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
				if (t.is_more_complete_than(*cit)) {
					t.type_index = cit->type_index;
					*cit = t;
				} else
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
				if (type.name.empty() || type.subtypes.empty()) {
					std::vector<TypeIndex> dummy;
					struct_refs += type.format(*this, "", 0, true, true, pointers_right_aligned, false, &dummy, false);
				} else {
					// doesn't matter template<> or not. You can't forward reference a template class. It must be converted to a strong link.
					struct_refs += "typedef ";
					struct_refs += (type.type == '(') ? "union " : "struct ";
					struct_refs += type.name;
					struct_refs.push_back(' ');
					struct_refs += type.get_pretty_name(prettify_struct_names);
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
recurse:
	if (from == to)
		return;
	
	Type& target_type = ma_type_store[to];
	switch (target_type.type) {
		case '^':	// for pointers, building any link to it is equivalent to building a weak link to its underlying type.
			to = target_type.subtypes[0];
			target_strength = ES_Weak;
			convert_class_strength_to_weak = true;
			goto recurse;
			
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
			to = target_type.subtypes[0];
			convert_class_strength_to_weak = true;
			goto recurse;
			
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
	
	if (banned_pairs.find(TypePointerPair(this,&another)) != banned_pairs.end())
		return false;
	
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
				if (*member_typestrings == '"' || *member_typestrings == '\0' || *member_typestrings == ')' || *member_typestrings == '}') {	// Avoid WebKit segfault.
					typestrings_list.push_back(string(subtype_begin, member_typestrings) + "?");
					subtype_begin = member_typestrings;
				}
				break;
		}
	}
	
	// Merge @ and "xxx" into @"xxx" if possible.
	vector<string> retval;
	for (vector<string>::const_iterator cit = typestrings_list.begin(); cit != typestrings_list.end(); ++ cit) {
		if ((*cit)[cit->size()-1] == '@') {
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

ObjCTypeRecord::Type::Type(ObjCTypeRecord& record, const string& type_to_parse, bool is_struct_used_locally) : type(type_to_parse[0]), external(true), refcount(is_struct_used_locally ? 1 : Type::used_globally), encoding(type_to_parse) {
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
			// type_to_parse.size() > 1 added to fix WebKit segfault.
			subtypes.push_back( record.parse(type_to_parse.size() > 1 ? type_to_parse.substr(1) : "?", false) );
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
#if OBJC_TYPE_DEBUG
				for (vector<string>::const_iterator cit = raw_subtypes.begin(); cit != raw_subtypes.end(); ++ cit)
					printf("%s\n", cit->c_str());
#endif
				for (vector<string>::const_iterator cit = raw_subtypes.begin(); cit != raw_subtypes.end(); ++ cit) {
					if (has_field_names) {
						field_names.push_back( cit->substr(1, cit->size()-2) );
						++ cit;
					}
					subtypes.push_back( record.parse(*cit, true) );
				}
			}
			
			if (!name.empty()) {
				if (name == "__siginfo")
					pretty_name = "siginfo_t";
				else if (name == "__sFILE") {
					pretty_name = "FILE";
				} else {
					size_t first_non_underscore_position = name.find('<') == string::npos ? name.find_first_not_of('_') : 0;
					pretty_name = name.substr( first_non_underscore_position == string::npos ? 0 : first_non_underscore_position );
				}
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
string ObjCTypeRecord::Type::format (const ObjCTypeRecord& record, const string& argname, unsigned tabs, bool treat_char_as_bool, bool as_declaration, bool pointers_right_aligned, bool dont_typedef, std::vector<TypeIndex>* append_struct_if_matching, bool treat_objcls_as_struct) const throw() {
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
					retval += record.ma_type_store[subtypes[0]].format(record, argname, 0, false, false, pointers_right_aligned, false, append_struct_if_matching, treat_objcls_as_struct);
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
				retval += subtype.format(record, pseudo_argname, 0, true, false, pointers_right_aligned, false, append_struct_if_matching, treat_objcls_as_struct);
				return retval;
			} else if (record.prettify_struct_names && subtype.type == '{' && subtype.subtypes.empty() && !subtype.name.empty() && subtype.name.find('<') == string::npos && name_Refable(subtype.pretty_name)) {
				retval += subtype.pretty_name;
				retval += "Ref";
			} else {
				string pseudo_argname = "*";
				pseudo_argname += argname;
				// if it's char* it will be encoded as ^* instead of ^^c, so it's OK to treat_char_as_bool.
				retval += subtype.format(record, pseudo_argname, 0, true, false, pointers_right_aligned, false, append_struct_if_matching, treat_objcls_as_struct);
				// change all int ***c to int*** c.
				if (!pointers_right_aligned) {
					size_t string_length_1 = retval.size()-1;
					for (unsigned i = 0; i < string_length_1; ++ i) {
						if (retval[i] == ' ' && retval[i+1] == '*') {
							retval[i] = '*';
							retval[i+1] = ' ';
						}
					}
					if (retval[string_length_1] == ' ')
						retval.erase(string_length_1);
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
			retval = subtype.format(record, pseudo_argname, tabs, true, as_declaration, pointers_right_aligned, false, append_struct_if_matching, treat_objcls_as_struct);
			return retval;
		}
			
		case '@':
			if (name.empty())
				retval += "id";
			else {
				if (treat_objcls_as_struct)
					retval += "struct ";
				retval += name;
			}
			if (!treat_objcls_as_struct)
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
				bool do_append_struct = (append_struct_if_matching == NULL);
				if (!do_append_struct) {
					for (std::vector<TypeIndex>::const_iterator cit = append_struct_if_matching->begin(); cit != append_struct_if_matching->end(); ++ cit)
						if (type_index == *cit) {
							do_append_struct = true;
							break;
						}
				}
				
				if (do_append_struct)
					retval += (type == '(') ? "union " : "struct ";
				retval += get_pretty_name(record.prettify_struct_names);
				
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
					if (!dont_typedef && subtypes.empty() && name.find('<') == string::npos) {
						if (record.prettify_struct_names && type == '{' && name_Refable(pretty_name)) {
							retval += pointers_right_aligned ? " *" : "* ";
							retval += get_pretty_name(record.prettify_struct_names);
							retval += "Ref";
						} else {
							retval.push_back(' ');
							retval += get_pretty_name(record.prettify_struct_names);
						}
					}
				} else if (dont_typedef && !subtypes.empty()) {
					retval.push_back(' ');
					retval += get_pretty_name(record.prettify_struct_names);
				}
				
				if (!subtypes.empty()) {
					retval += " {\n";
					string field_name;
					if (append_struct_if_matching)
						append_struct_if_matching->push_back(type_index);
					for (unsigned i = 0; i < subtypes.size(); ++ i) {
						if (field_names.size() > 0)
							field_name = field_names[i];
						else
							field_name = numeric_format("_field%u", i+1);
						retval += record.ma_type_store[subtypes[i]].format(record, field_name, tabs+1, true, false, pointers_right_aligned, false, append_struct_if_matching, treat_objcls_as_struct);
						retval += ";\n";
					}
					if (append_struct_if_matching)
						append_struct_if_matching->pop_back();
					
					retval += tab_string;
					retval.push_back('}');
					if (!dont_typedef && (name.find('<') == string::npos && (!name.empty() || refcount > 1))) {
						retval.push_back(' ');
						retval += get_pretty_name(record.prettify_struct_names);
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

bool ObjCTypeRecord::can_reduce_to_type(TypeIndex from, TypeIndex to) const throw() {
	if (from == to)
		return true;
	
	const Type* type = &(ma_type_store[from]);
	TypeIndex last_index = from;
	
	while (true) {
		switch (type->type) {
			default:
				return last_index == to;
				
			case 'r':
			case 'R':
			case 'n':
			case 'N':
			case 'o':
			case 'O':
			case 'V':
			case '!':
				last_index = type->subtypes[0];
				type = &(ma_type_store[last_index]);
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

void ObjCTypeRecord::sort_alphabetically(vector<TypeIndex>::iterator type_indices_begin, vector<TypeIndex>::iterator type_indices_end) const throw() {
	sort(type_indices_begin, type_indices_end, octr_AlphabeticSorter(*this));
}

// Basically an uglified topological sort.
static void octr_visit(const tr1::unordered_map<ObjCTypeRecord::TypeIndex, tr1::unordered_map<ObjCTypeRecord::TypeIndex, ObjCTypeRecord::EdgeStrength> >& adjlist, tr1::unordered_map<ObjCTypeRecord::TypeIndex, bool>& visited, vector<ObjCTypeRecord::TypeIndex>& result, ObjCTypeRecord::TypeIndex ti) {
	tr1::unordered_map<ObjCTypeRecord::TypeIndex, bool>::iterator vit = visited.find(ti);
	if (vit != visited.end() && !vit->second) {
		vit->second = true;
		tr1::unordered_map<ObjCTypeRecord::TypeIndex, tr1::unordered_map<ObjCTypeRecord::TypeIndex, ObjCTypeRecord::EdgeStrength> >::const_iterator cit = adjlist.find(ti);
		if (cit != adjlist.end()) {
			for (tr1::unordered_map<ObjCTypeRecord::TypeIndex, ObjCTypeRecord::EdgeStrength>::const_iterator nit = cit->second.begin(); nit != cit->second.end(); ++ nit) {
				if (nit->second >= ObjCTypeRecord::ES_StrongIndirect)
					octr_visit(adjlist, visited, result, nit->first);
			}
			result.push_back(ti);
		}
	}
}

void ObjCTypeRecord::sort_by_strong_links(vector<TypeIndex>::iterator type_indices_begin, vector<TypeIndex>::iterator type_indices_end) const throw() {
	// sort(type_indices_begin, type_indices_end, octr_StrongLinkSorter(*this));
	tr1::unordered_map<TypeIndex, bool> visited;
	for (vector<TypeIndex>::iterator it = type_indices_begin; it != type_indices_end; ++ it)
		visited.insert(std::pair<TypeIndex, bool>(*it, false));
	
	size_t length = type_indices_end - type_indices_begin;
	vector<TypeIndex> result;
	result.reserve(length);
	
	for (vector<TypeIndex>::iterator it = type_indices_begin; it != type_indices_end; ++ it)
		octr_visit(ma_adjlist, visited, result, *it);
	
	copy(result.begin(), result.end(), type_indices_begin);
}

string ObjCTypeRecord::format_structs_with_forward_declarations(const vector<TypeIndex>& type_indices) const throw() {
	vector<TypeIndex> indices = type_indices;
	sort_by_strong_links(indices.begin(), indices.end());
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

/*
 Algorithm to create short circuit weak link.
 
 (1) For all structs/classes T with refcount > 1,
   (2) For all strongly linked, anonymous structs S with refcount == 1,
     (3) Remove this link.
     (4) Transfer all links S having to T.
 */

void ObjCTypeRecord::create_short_circuit_weak_links() throw() {
	for (TypeIndex i = 0; i < ma_type_store.size(); ++ i) {
		const Type& t = ma_type_store[i];
		if (t.refcount > 1 && (t.type == '@' || t.type == '{' || t.type == '[')) {
			tr1::unordered_map<TypeIndex, EdgeStrength>& adjs = ma_adjlist[i];
			bool modified;
			do {
				vector<pair<TypeIndex, EdgeStrength> > unmodified_adjs (adjs.begin(), adjs.end());
				modified = false;
				
				for (vector<pair<TypeIndex, EdgeStrength> >::const_iterator cit = unmodified_adjs.begin(); cit != unmodified_adjs.end(); ++ cit) {
					if (cit->second >= ES_StrongIndirect) {
						const Type& s = ma_type_store[cit->first];
						if (s.refcount == 1 && s.name.empty()) {
							combine_dependencies(adjs, ma_adjlist[cit->first], &ma_k_in, &ma_strong_k_in);
							adjs.erase(cit->first);
							-- ma_k_in[cit->first];
							-- ma_strong_k_in[cit->first];
							modified = true;
						}
					}
				}
			} while (modified);
		}
	}
}

size_t ObjCTypeRecord::size_of(TypeIndex ti) const throw() {
	const Type& t = ma_type_store[ti];
	
	switch (t.type) {
			// assume all pointer types have same size.
		case '*':
		case '^':
		case ':':
		case '#':
		case '%':
		case '@': return sizeof(void*);
			
		case 'N':
		case 'O':
		case 'R':
		case 'V':
		case 'r':
		case 'n':
		case 'o':
		case '!': return size_of(t.subtypes[0]);
		case '[': return atol(t.value.c_str()) * size_of(t.subtypes[0]);
		case 'j': return 2 * size_of(t.subtypes[0]);
			
		case 'B': return sizeof(bool);
		case 'C': return sizeof(unsigned char);
		case 'I': return sizeof(unsigned int);
		case 'L': return sizeof(unsigned long);
		case 'Q': return sizeof(unsigned long long);
		case 'S': return sizeof(unsigned short);
			
		case 'c': return sizeof(signed char);
		case 'd': return sizeof(double);
		case 'f': return sizeof(float);
		case 'i': return sizeof(int);
		case 'l': return sizeof(long);
		case 'q': return sizeof(long long);
		case 's': return sizeof(short);
			
		case 'b': return (atol(t.value.c_str())-1)/8+1;
			
		case '(': {
			size_t max_size = 0;
			for (vector<unsigned>::const_iterator cit = t.subtypes.begin(); cit != t.subtypes.end(); ++ cit) {
				size_t cur_size = size_of(*cit);
				if (cur_size > max_size)
					max_size = cur_size;
			}
			return max_size;
		}
		case '{': {
			size_t cur_bits = 0;
			size_t max_align = 8;
			for (vector<unsigned>::const_iterator cit = t.subtypes.begin(); cit != t.subtypes.end(); ++ cit) {
				const Type& t2 = ma_type_store[*cit];
				if (t2.type == 'b')
					cur_bits += atol(t2.value.c_str());
				else {
					size_t align = align_of(*cit) * 8;
					if (align > max_align)
						max_align = align;
					cur_bits = ((cur_bits-1) | (align-1)) + 1 + size_of(*cit)*8;
				}
			}
			return ((cur_bits-1)/max_align+1)*max_align/8;
		}
		default: return 0;
	}
}

size_t ObjCTypeRecord::align_of(TypeIndex ti) const throw() {
	const Type& t = ma_type_store[ti];
	
	switch (t.type) {
			// assume all pointer types have same size.
		case '*':
		case '^':
		case ':':
		case '#':
		case '%':
		case '@': return __alignof__(void*);
			
		case 'N':
		case 'O':
		case 'R':
		case 'V':
		case 'r':
		case 'n':
		case 'o':
		case '!': 
		case '[': 
		case 'j': return align_of(t.subtypes[0]);
			
		case 'B': return __alignof__(bool);
		case 'C': return __alignof__(unsigned char);
		case 'I': return __alignof__(unsigned int);
		case 'L': return __alignof__(unsigned long);
		case 'Q': return __alignof__(unsigned long long);
		case 'S': return __alignof__(unsigned short);
			
		case 'c': return __alignof__(signed char);
		case 'd': return __alignof__(double);
		case 'f': return __alignof__(float);
		case 'i': return __alignof__(int);
		case 'l': return __alignof__(long);
		case 'q': return __alignof__(long long);
		case 's': return __alignof__(short);
		
			// Fine unless we target mac68k.
		case '(': 
		case '{': {
			size_t max_align = 1;
			for (vector<unsigned>::const_iterator cit = t.subtypes.begin(); cit != t.subtypes.end(); ++ cit) {
				size_t cur_align = align_of(*cit);
				if (cur_align > max_align)
					max_align = cur_align;
			}
			return max_align;
		}

		default: return 1;
	}
}

void ObjCTypeRecord::print_arguments(TypeIndex ti, va_list& va, void(*inline_id_printer)(FILE* f, void* obj), FILE* f) const throw() {
	unsigned stsize = (size_of(ti)-1)/sizeof(int)+1;
	char* vacopy = reinterpret_cast<char*>(alloca(stsize*sizeof(int)));
	for (unsigned i = 0; i < stsize; ++ i) {
		int e = va_arg(va, int);
		memcpy(vacopy+i*sizeof(int), &e, sizeof(int));
	}
	print_args(ti, const_cast<const char*&>(vacopy), inline_id_printer, f);
}
	
template<typename T>
inline static T READ(const char*& vacopy) {
	T res;
	memcpy(&res, vacopy, sizeof(T));
	vacopy += sizeof(T);
	return res;
}
	
void ObjCTypeRecord::print_args(TypeIndex ti, const char*& vacopy, void(*inline_id_printer)(FILE* f, void* obj), FILE* f) const throw() {
	const Type& t = ma_type_store[ti];
	bool first = true;
	
	switch (t.type) {
		case '*':
			fprintf(f, "\"%s\"", READ<char*>(vacopy));
			break;
		case '^':
			fprintf(f, "%p", READ<void*>(vacopy));
			break;
		case ':':
			fprintf(f, "@selector(%s)", READ<char*>(vacopy));
			break;
		case '%':
			fprintf(f, "(NXAtom*)\"%s\"", READ<char*>(vacopy));
			break;
			
		case '@':
		case '#': {
			void* v = READ<void*>(vacopy);
			intptr_t vi = reinterpret_cast<intptr_t>(v);
			if (inline_id_printer == NULL || vi % __alignof__(void*) != 0)	// or should we use __alignof__ ?
				fprintf(f, "(%s)%p", t.type == '@' ? "id" : "Class", v);
			else
				inline_id_printer(f, v);
			break;
		}
			
		case 'N':
		case 'O':
		case 'R':
		case 'V':
		case 'r':
		case 'n':
		case 'o':
		case '!':
			print_args(t.subtypes[0], vacopy, inline_id_printer, f);
			break;
			
		case '[': {
			fprintf(f, "{");
			unsigned count = atoi(t.value.c_str());
			for (unsigned i = 0; i < count; ++ i) {
				if (first) first = false;
				else fprintf(f, ", ");
				print_args(t.subtypes[0], vacopy, inline_id_printer, f);
			}
			fprintf(f, "}");
			break;
		}
			
		case 'j':
			fprintf(f, "{");
			print_args(t.subtypes[0], vacopy, inline_id_printer, f);
			fprintf(f, ", ");
			print_args(t.subtypes[0], vacopy, inline_id_printer, f);
			fprintf(f, "}");
			break;
			
		case 'B':
			fprintf(f, READ<bool>(vacopy) ? "true" : "false");
			break;
			
		case 'C':
			fprintf(f, "0x%02xu", READ<char>(vacopy));
			break;
		case 'I':
			fprintf(f, "%uu", READ<unsigned int>(vacopy));
			break;
		case 'L':
			fprintf(f, "%luLu", READ<unsigned long>(vacopy));
			break;
		case 'Q':
			fprintf(f, "%lluLLu", READ<unsigned long long>(vacopy));
			break;
		case 'S':
			fprintf(f, "%uu", READ<unsigned short>(vacopy));
			break;
			
		case 'c': {
			char c = READ<char>(vacopy);
			if (c == 0)
				fprintf(f, "NO");
			else if (c == 1)
				fprintf(f, "YES");
			else if (c >= 0x20 && c < 0x7F)
				fprintf(f, "'%s%c'", (c == '\'' || c == '\\') ? "\\" : "", c);
			else
				fprintf(f, "0x%02x", c);
			break;
		}
		case 'd':
			fprintf(f, "%#.15lg", READ<double>(vacopy));
			break;
		case 'f':
			fprintf(f, "%#gf", READ<float>(vacopy));
			break;
		case 'i':
			fprintf(f, "%d", READ<int>(vacopy));
			break;
		case 'l':
			fprintf(f, "%ldL", READ<long>(vacopy));
			break;
		case 'q':
			fprintf(f, "%lldLL", READ<long long>(vacopy));
			break;
		case 's':
			fprintf(f, "%d", READ<short>(vacopy));
			break;
			
		case '(': {
			// For unions, find the longest member and print using it.
			size_t max_size = 0;
			TypeIndex max_index = 0;
			for (vector<unsigned>::const_iterator cit = t.subtypes.begin(); cit != t.subtypes.end(); ++ cit) {
				size_t cur_size = size_of(*cit);
				if (cur_size > max_size) {
					max_size = cur_size;
					max_index = *cit;
				}
			}
			print_args(max_index, vacopy, inline_id_printer, f);
			break;
		}
			
		case '{': {
			fprintf(f, "{");
			unsigned bits_to_skip = 0;
			for (vector<unsigned>::const_iterator cit = t.subtypes.begin(); cit != t.subtypes.end(); ++ cit) {
				if (first) first = false;
				else fprintf(f, ", ");
				
				const Type& t2 = ma_type_store[*cit];
				if (t2.type == 'b')
					bits_to_skip += atol(t2.value.c_str());
				else {
					size_t align = align_of(*cit);
					size_t size = size_of(*cit);
					if (bits_to_skip != 0) {
						unsigned bytes_to_skip = (((bits_to_skip-1) | (align*8-1)) + 1)/8;
						fprintf(f, "/*bitfield*/0x");
						for (unsigned units = 0; units < bytes_to_skip; ++ units)
							fprintf(f, "%02x", READ<char>(vacopy));
						bits_to_skip = 0;
					}
					print_args(*cit, vacopy, inline_id_printer, f);
					// an intentional minus sign.
#pragma warning ( suppress : 4146 )
					vacopy += (-size) % align;
				}
			}
			if (bits_to_skip != 0) {
				unsigned bytes_to_skip = (((bits_to_skip-1) | (8-1)) + 1)/8;
				if (!first) fprintf(f, ", ");
				fprintf(f, "/*bitfield*/0x");
				for (unsigned units = 0; units < bytes_to_skip; ++ units)
					fprintf(f, "%02x", READ<char>(vacopy));
			}
			fprintf(f, "}");
			break;
		}
			
		default: break;
	}		
}
