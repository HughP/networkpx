/*

MachO_File_ObjC.h ... Mach-O file analyzer specialized in Objective-C support.

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

#ifndef MACH_O_FILE_OBJC_H
#define MACH_O_FILE_OBJC_H

#include "objc-runtime-new.h"
#include "MachO_File.h" 
#include <vector>
#include <string>
#include <tr1/unordered_map>
#include <tr1/unordered_set>
#include "lazy_reachability_matrix.h"

class MachO_File_ObjC : public MachO_File {
private:
	struct StructDefinition {
		bool is_union;
		unsigned see_also;
		std::string name;
		std::string typestring;
		std::vector<std::string> members;
		std::vector<std::string> member_typestrings;
		unsigned use_count;	// only count direct use count. If struct A is used by struct B only, even if B is part of function argument, the use count of A is still 1.
		std::string prettified_name;
		bool direct_reference;
	};
	
	struct ClassDefinition {
		bool isProtocol;
		bool isCategory;
		
		unsigned vm_address;
		
		const char* name;
		uint32_t attributes;
		const char* superclass_name;		// category name if isCategory.
		
		ClassDefinition* categorized_class;	// NULL if the categoized class is external.
		
		std::vector<std::string> ivar_declarations;
		std::vector<unsigned> ivar_offsets;

		std::vector<std::string> property_prefixes;
		std::vector<const char*> property_names;
		std::vector<unsigned> property_getter_address;
		std::vector<unsigned> property_setter_address;
		
		unsigned converted_property_start;

		std::vector<std::string> method_declarations;
		std::vector<unsigned> method_vm_addresses;
		
		unsigned optional_class_method_start, instance_method_start, optional_instance_method_start;
		
		std::vector<unsigned> related_categories;
		std::vector<unsigned> adopted_protocols;
	};
	
	enum {
		LT_None,
		LT_Weak,
		LT_Strong
	};
	
	void increase_use_count(unsigned& use_count, unsigned by = 1) throw();
	void decrease_use_count(unsigned& use_count) throw();
	
	std::vector<std::vector<std::pair<unsigned,unsigned> > > ma_adjlist;
	std::vector<std::pair<unsigned,unsigned> > ma_k_in;	// weak, strong.
	LazyReachabilityMatrix ma_reachability_matrix;
	
	std::vector<std::string> ma_external_classes;
	std::tr1::unordered_set<std::string> ma_recognized_classes;
	
	bool m_has_anonymous_contentless_struct, m_has_anonymous_contentless_union;
	
	std::vector<ClassDefinition> ma_classes;	// classes, categories & protocols.
	
	std::tr1::unordered_map<std::string, unsigned> ma_struct_indices;	// typestring -> index
	std::vector<StructDefinition> ma_struct_definitions;
	
	std::string decode_type(const char* typestr, unsigned& chars_to_read, const char* argname = NULL, bool is_compound_type = false, unsigned intended_use_count = ~0u, bool dont_change_anything = false) throw();
	unsigned identify_structs(const char* typestr, const char** typestr_store = NULL, unsigned intended_use_count = ~0u, bool dont_change_anything = false) throw();
	std::string analyze_method(const char* method_name, const char* method_type, const char* plus_or_minus) throw();
	void obtain_properties(const objc_property* cur_property, int& guess_text_segment, std::vector<const char*>& property_names, std::vector<std::string>& property_prefixes, std::vector<std::string>& property_getters, std::vector<std::string>& property_setters) throw();
	void propertize(ClassDefinition& clsDef, const std::vector<const char*>& method_names, std::vector<const char*>& method_types) throw();
	const char* get_superclass_name(unsigned superclass_vmaddr, unsigned pointer_to_superclass_vmaddr, const std::tr1::unordered_map<unsigned,unsigned>& all_class_def_indices, ClassDefinition** superclass_clsDef = NULL) throw();
	
	bool member_typestrings_equal(const std::vector<std::string>& a, const std::vector<std::string>& b) const throw();
	
	std::vector<std::string> ma_string_store;
	
	std::string get_struct_definition(const StructDefinition& curDef, bool need_typedef = true, bool prettify = false) throw();
	bool replace_prettified_struct_names(std::string& str, unsigned tab_length, const std::string& caller_name) throw();
	unsigned get_struct_link_type(const std::string& decl, unsigned minimum_link_type, unsigned struct_id_to_match) const throw();
	
	std::string typestring_id_name_to_objc_name (const std::string& str) throw();
	
	class InheritSorter {
		const MachO_File_ObjC& mf;
	public:
		InheritSorter(const MachO_File_ObjC& mf_) : mf(mf_) {}
		bool operator() (unsigned i, unsigned j) const throw();
	};
	class NormalSorter {
		const MachO_File_ObjC& mf;
	public:
		NormalSorter(const MachO_File_ObjC& mf_) : mf(mf_) {}
		bool operator() (unsigned i, unsigned j) const throw();
	};
	class AlphabeticSorter {
		const MachO_File_ObjC& mf;
	public:
		AlphabeticSorter(const MachO_File_ObjC& mf_) : mf(mf_) {}
		bool operator() (unsigned i, unsigned j) const throw();
	};
	
	friend class InheritSorter;
	friend class NormalSorter;
	
public:
	enum SortBy {
		SB_None,
		SB_Inherit,
		SB_Alphabetic
	};
	
	MachO_File_ObjC(const char* path) throw(std::bad_alloc, TRException);
	
	unsigned classes_count() const throw() { return ma_classes.size(); }
	unsigned structs_count() const throw() { return ma_struct_definitions.size(); }
	
	const char* name_of_class(unsigned index) const throw() { return ma_classes[index].name; }
	const std::string& name_of_struct(unsigned index) const throw() { return ma_struct_definitions[index].prettified_name; }
	
	void print_class(unsigned index, bool print_ivar_offsets, bool print_method_addresses, bool print_comments) const throw();
	void print_struct(unsigned index) throw();
	void print_anonymous_contentless_records() const throw();
	
	std::vector<unsigned> get_class_sort_order_by(SortBy by) const throw();
	
	void print_reachability_matrix() throw();
	void print_struct_indices() const throw();
};

#endif