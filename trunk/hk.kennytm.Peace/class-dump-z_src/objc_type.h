/*

objc_type.h ... Objective-C type decoder & usage network manager.

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

#ifndef OBJC_TYPE_H
#define OBJC_TYPE_H

#include <vector>
#include <string>
#include <tr1/unordered_set>
#include <tr1/unordered_map>

class ObjCTypeRecord {
public:
	typedef unsigned TypeIndex;
	typedef unsigned EdgeStrength;
	
	enum {
		ES_None,
		ES_Weak,			// (direct) weak link: The target type must be forward-declared (struct X; @class ABC, etc.) before the source type. But this forward-declaration must appear in the same header file as the source type.
		ES_StrongIndirect,	// indirect strong link (made by transitive closure): The target type must be completely declared before the source type, but it doesn't need to be #include-ed.
		ES_Strong			// direct strong link: The target type must be completely declared before the source type, and a class must #include this type in a header file.
	};
	
private:
	class Type;
	
public:
	struct TypePointerPair {
		const Type* a;
		const Type* b;
		TypePointerPair(const Type* a_, const Type* b_) throw() : a(a_ < b_ ? a_ : b_), b(a_ < b_ ? b_ : a_) {};
		bool operator==(const TypePointerPair& other) const throw() { return a == other.a && b == other.b; }
	};
	
private:
	class Type {
		static const unsigned used_globally = ~0u;
		
		char type;
		bool external;
		unsigned refcount;
		
		std::string name;	// struct name or objc class name. This is an optional field for equality.
		std::string value;	// array size, bitfield size, objc protocols. This is a required field for equality.
		
		std::string pretty_name;	// the prettified name for a struct.
		
		std::vector<unsigned> subtypes;
		std::vector<std::string> field_names;
		
		//----
		
		Type(ObjCTypeRecord& record, const std::string& type_to_parse, bool is_struct_used_locally);
		std::string format(const ObjCTypeRecord& record, const std::string& argname, unsigned tabs, bool treat_char_as_bool, bool as_declaration, bool pointers_right_aligned, bool dont_typedef = false) const throw();
		
		bool is_compatible_with(const Type& another, const ObjCTypeRecord& record, std::tr1::unordered_set<TypePointerPair>& banned_pairs) const throw();
		bool is_more_complete_than(const Type& another) const throw();
		
		friend class ObjCTypeRecord;
	};
	
	std::tr1::unordered_map<std::string, TypeIndex> ma_indexed_types;
	std::vector<Type> ma_type_store;
	
	std::tr1::unordered_map<TypeIndex, std::tr1::unordered_map<TypeIndex, EdgeStrength> > ma_adjlist;
	std::tr1::unordered_map<TypeIndex, unsigned> ma_k_in;
	
	TypeIndex m_void_type_index;
	TypeIndex m_id_type_index;
	TypeIndex m_sel_type_index;
	
	friend class Type;
	
private:
	void add_objc_class_private(const std::string& objc_class);
	void add_link_with_strength(TypeIndex from, TypeIndex to, EdgeStrength strength, bool convert_class_strength_to_weak = true);
	
public:
	bool pointers_right_aligned;
	
	TypeIndex add_external_objc_class(const std::string& objc_class);
	TypeIndex add_internal_objc_class(const std::string& objc_class);
	TypeIndex add_objc_protocol(const std::string& protocol);
	TypeIndex add_objc_category(const std::string& category_name, const std::string& categorized_class);

	void add_strong_link(TypeIndex from, TypeIndex to) { add_link_with_strength(from, to, ES_Strong); }
	void add_strong_class_link(TypeIndex from, TypeIndex to) { add_link_with_strength(from, to, ES_Strong, false); }
	void add_weak_link(TypeIndex from, TypeIndex to) { add_link_with_strength(from, to, ES_Weak); }
	
	TypeIndex parse(const std::string& type_to_parse, bool is_struct_used_locally);
	std::string format(TypeIndex type_index, const std::string& argname, unsigned tabs = 0, bool as_declaration = false, bool dont_typedef = false) const throw() {
		return ma_type_store[type_index].format(*this, argname, tabs, true, as_declaration, pointers_right_aligned, dont_typedef);
	}
	
	std::string format_forward_declaration(const std::vector<TypeIndex>& type_indices) const throw();
	
	size_t types_count() const throw() { return ma_type_store.size(); }
	
	ObjCTypeRecord() : pointers_right_aligned(false) {
		m_void_type_index = parse("v", false);
		m_id_type_index = parse("@", false);
		m_sel_type_index = parse(":", false);
	}
	
	TypeIndex void_type() const throw() { return m_void_type_index; }
	TypeIndex id_type() const throw() { return m_id_type_index; }
	TypeIndex sel_type() const throw() { return m_sel_type_index; }
	
	bool is_id_type(TypeIndex idx) const throw() { return idx == m_id_type_index || ma_type_store[idx].type == '@'; }
	bool is_void_type(TypeIndex idx) const throw() { return idx == m_void_type_index; }
	bool can_dereference_to_id_type(TypeIndex idx) const throw();
	bool is_struct_type(TypeIndex idx) const throw() { const Type& type = ma_type_store[idx]; return type.type == '{' || type.type == '('; }
	bool is_external_type(TypeIndex idx) const throw() { return ma_type_store[idx].external; }
	
	bool are_types_compatible(TypeIndex a, TypeIndex b) const throw();
	
	const std::string& name_of_type(TypeIndex idx) const throw() { 
		const Type& t = ma_type_store[idx];
		return t.type == '7' ?  ma_type_store[idx].value : ma_type_store[idx].name;
	}
	
	void print_network() const throw();
	
	// ignores those structs with refcount = 1.
	std::vector<TypeIndex> all_public_struct_types() const throw();
	void sort_alphabetically(std::vector<TypeIndex>& type_indices) const throw();
	void sort_by_strong_links(std::vector<TypeIndex>& type_indices) const throw();
	std::string format_structs_with_forward_declarations(const std::vector<TypeIndex>& type_indices) const throw();
	
	const std::tr1::unordered_map<TypeIndex, EdgeStrength>* dependencies(TypeIndex type_index) const throw() { 
		std::tr1::unordered_map<TypeIndex, std::tr1::unordered_map<TypeIndex, EdgeStrength> >::const_iterator cit = ma_adjlist.find(type_index);
		if (cit == ma_adjlist.end())
			return NULL;
		else
			return &(cit->second);
	}
	EdgeStrength link_strength(TypeIndex a, TypeIndex b) const throw() {
		std::tr1::unordered_map<TypeIndex, std::tr1::unordered_map<TypeIndex, EdgeStrength> >::const_iterator ait = ma_adjlist.find(a);
		if (ait == ma_adjlist.end())
			return ES_None;
		else {
			std::tr1::unordered_map<TypeIndex, EdgeStrength>::const_iterator bit = ait->second.find(b);
			if (bit == ait->second.end())
				return ES_None;
			else
				return bit->second;
		}
	}
	
	unsigned link_count(TypeIndex type_index) const throw() { return ma_k_in.find(type_index)->second; }
};

#endif