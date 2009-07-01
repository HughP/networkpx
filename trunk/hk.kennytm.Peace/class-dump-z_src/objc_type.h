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

#ifndef OBJC_TYPE_H
#define OBJC_TYPE_H

#include <vector>
#include <string>
#include <tr1/unordered_set>
#include <tr1/unordered_map>

class ObjCTypeRecord {
private:
	class Type {
		static const unsigned used_globally = ~0u;
		
		char type;
		unsigned refcount;
		
		std::string name;	// struct name or objc class name. This is an optional field for equality.
		std::string value;	// array size, bitfield size, objc protocols. This is a required field for equality.
		
		std::string pretty_name;	// the prettified name for a struct.
		
		bool struct_is_undeclared;
		
		std::vector<unsigned> subtypes;
		std::vector<std::string> field_names;
		
		Type(ObjCTypeRecord& record, const std::string& type_to_parse, const std::string& current_name, bool is_struct_used_locally);
		std::string format(const ObjCTypeRecord& record, const std::string& argname, unsigned tabs, bool treat_char_as_bool, bool as_declaration) const throw();
		
		bool is_compatible_with(const Type& another, const ObjCTypeRecord& record) const throw();
		bool is_more_complete_than(const Type& another) const throw();
		
		friend class ObjCTypeRecord;
	};
	
	struct Edge {
		const Type* user;
		const Type* required_type;
		unsigned strength;
	};
	
	std::tr1::unordered_set<std::string> ga_external_objc_classes_set;
	std::tr1::unordered_set<std::string> ga_internal_objc_classes_set;
	std::vector<std::string> ga_external_objc_classes;
	
	std::tr1::unordered_map<std::string, unsigned> ma_indexed_types;
	std::vector<Type> ma_type_store;
	
	std::tr1::unordered_map<const Type*, std::vector<std::pair<const Type*, unsigned> > > ma_adjlist;
	
	friend class Type;
	
private:
	
public:
	unsigned add_external_objc_class(const std::string& objc_class __attribute__((unused))) { return 0; }
	unsigned add_internal_objc_class(const std::string& objc_class __attribute__((unused))) { return 0; }
	
#if 0
	void add_class_inheritance(const Type* derived, const Type* base) {}	// equivalent to adding a strong link.
	void add_protocol_adoption(const Type* protocol, const Type* base) {}	// equivalent to adding a weak link.
#endif
	
	unsigned parse(const std::string& type_to_parse, bool is_struct_used_locally);
	std::string format(unsigned type_index, const std::string& argname, unsigned tabs = 0, bool as_declaration = false) const throw();
	
	size_t types_count() const throw() { return ma_type_store.size(); }
};

#endif