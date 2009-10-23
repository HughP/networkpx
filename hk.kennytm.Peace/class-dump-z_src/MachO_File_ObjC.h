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
#include "objc_type.h"
#include "string_util.h"
#include <cstdlib>
#include <pcre.h>

class MachO_File_ObjC : public MachO_File {
private:
	enum HiddenMethodType {
		PS_None,
		PS_DeclaredGetter,
		PS_DeclaredSetter,
		PS_ConvertedGetter,
		PS_ConvertedSetter,
		PS_AdoptingProtocol,
		PS_Inherited,
	};
	
public:
	enum SortBy {
		SB_None,
		SB_Inherit,
		SB_Alphabetic,
		SB_AlphabeticAlt,
	};	
	
public:
	// These 2 are public *only* because I knew no way to refer to these structs in std::tr1::hash<T>.
	struct ReducedProperty {
		std::string name;
		std::string getter;
		std::string setter;
		
		// these are from the attributes
		ObjCTypeRecord::TypeIndex type;		// T
		
		bool has_getter;	// G
		bool has_setter;	// S
		bool copy;			// C
		bool retain;		// &
		bool readonly;		// R
		bool nonatomic;		// N
		
		ReducedProperty() : has_getter(false), has_setter(false), copy(false), retain(false), readonly(false), nonatomic(false) {}
		bool operator==(const ReducedProperty& other) const throw() {
			return name==other.name &&
				has_getter==other.has_getter && (!has_getter || getter==other.getter) &&
				has_setter==other.has_setter && (!has_setter || setter==other.setter) &&
				copy==other.copy && retain==other.retain && readonly==other.readonly && nonatomic==other.nonatomic;
		}
	};
	
	struct ReducedMethod {
		const char* raw_name;
		bool is_class_method;
		std::vector<ObjCTypeRecord::TypeIndex> types;
		
		bool operator==(const ReducedMethod& other) const throw() {
			return is_class_method==other.is_class_method && types==other.types && strcmp(raw_name, other.raw_name)==0;
		}
	};
	
private:
	struct Property : public ReducedProperty {
		std::string synthesized_to;
		unsigned getter_vm_address;
		unsigned setter_vm_address;
		
		HiddenMethodType hidden;
		bool optional;
		
		enum {
			IM_None,
			IM_Synthesized,	// V
			IM_Dynamic,		// D
			IM_Converted
		} impl_method;
		enum {
			GC_None,
			GC_Strong,		// P
			GC_Weak			// W
		} gc_strength;
		
		Property() : ReducedProperty(), getter_vm_address(0), setter_vm_address(0), hidden(PS_None), optional(false), impl_method(IM_None), gc_strength(GC_None) {}
		
		std::string format(const ObjCTypeRecord& record, const MachO_File_ObjC& self, bool print_method_addresses, int print_comments) const throw();
	};
	
	struct Ivar {
		ObjCTypeRecord::TypeIndex type;
		const char* name;
		unsigned offset;
		bool is_private;
	};
	
	struct Method : public ReducedMethod {
		unsigned vm_address;
		HiddenMethodType propertize_status;
		
		// -(double)sumOfArray:(const double*)array count:(unsigned)count will be split into this form:
		// types = double, id, SEL, const double*, unsigned.
		// components = "", "", "", sumOfArray, count
		// -(id)copy will be split into this form:
		// types = id, id, SEL
		// components = "", "", ""
		bool optional;
		
		std::vector<std::string> components;
		std::vector<std::string> argname;
		
		Method() : vm_address(0), propertize_status(PS_None), components(3) {}
		
		std::string format(const ObjCTypeRecord& record, const MachO_File_ObjC& self, bool print_method_addresses, int print_comments) const throw();
	};
	
	struct ClassType {
		enum {
			CT_Protocol,
			CT_Class,
			CT_Category,
		} type;
		
		unsigned vm_address;
		
		ObjCTypeRecord::TypeIndex type_index;
		ObjCTypeRecord::TypeIndex superclass_index;
		
		const char* name;
		uint32_t attributes;
		const char* superclass_name;		// category name if isCategory.
		
		std::vector<Ivar> ivars;
		std::vector<Property> properties;
		std::vector<Method> methods;
				
		std::vector<unsigned> adopted_protocols;
		
		std::string format(const ObjCTypeRecord& record, const MachO_File_ObjC& self, bool print_method_addresses, int print_comments, bool print_ivar_offsets, MachO_File_ObjC::SortBy sort_by, bool show_only_exported_classes) const throw();
	};
	
	struct OverlapperType;
	
	friend struct Method_AlphabeticSorter;
	friend struct Property_AlphabeticSorter;
	friend struct Method_AlphabeticAltSorter;
	friend struct ClassType;
	
//-------------------------------------------------------------------------------------------------------------------------------------------
	
	int m_guess_data_segment, m_guess_text_segment;
	
	unsigned m_class_count, m_protocol_count, m_category_count;
	std::vector<ClassType> ma_classes;	// classes, categories & protocols.
	std::tr1::unordered_map<unsigned, unsigned> ma_classes_vm_address_index;	// vm_addr -> index in ma_classes
	std::tr1::unordered_map<ObjCTypeRecord::TypeIndex, unsigned> ma_classes_typeindex_index;	// class name -> index in ma_classes.
	std::tr1::unordered_map<ObjCTypeRecord::TypeIndex, std::string> ma_include_paths;
	std::tr1::unordered_map<ObjCTypeRecord::TypeIndex, const char*> ma_lib_path;
	
	std::tr1::unordered_map<const char*, MachO_File_ObjC*> ma_loaded_libraries;
	
	ObjCTypeRecord m_record;
	
	void adopt_protocols(ClassType& cls, const protocol_list_t* protocols) throw();
	void add_properties(ClassType& cls, const objc_property_list* prop_list) throw();
	void add_methods(ClassType& cls, const method_list_t* method_list_ptr, bool class_method, bool optional, bool reduced_method = false) throw();
	
	const char* get_superclass_name(unsigned superclass_addr, unsigned pointer_to_superclass_addr, ObjCTypeRecord::TypeIndex& superclass_index) throw();
	const char* get_cstring(const void* vmaddr, int* guess_segment, unsigned symaddr, unsigned symoffset, const char* defsym) const throw();
	
	void retrieve_protocol_info() throw();
	void retrieve_class_info() throw();
	void retrieve_reduced_class_info() throw();
	void retrieve_category_info() throw();
	
	void tag_propertized_methods(ClassType& cls) throw();
	
	void propertize(ClassType& cls) throw();
	void hide_overlapping_methods(ClassType& target, const OverlapperType& reference, HiddenMethodType hiding_method) throw();
	
	void recursive_union_with_protocols(unsigned i, std::vector<OverlapperType>& overlappers) const throw();
	void recursive_union_with_superclasses(ObjCTypeRecord::TypeIndex ti, std::tr1::unordered_map<ObjCTypeRecord::TypeIndex, OverlapperType>& superclass_overlappers, const char* sysroot) throw();
	
//-------------------------------------------------------------------------------------------------------------------------------------------
	
	pcre* m_class_filter, *m_method_filter;
	pcre_extra* m_class_filter_extra, *m_method_filter_extra;
	std::vector<std::string> m_kill_prefix;
	
	bool name_killable(const char* name, size_t length, bool check_kill_prefix) const throw();
		
	friend bool mfoc_AlphabeticSorter(const ClassType* a, const ClassType* b) throw();
	
	std::vector<std::string> ma_string_store;	// store C-strings.
	std::vector<Method> ma_method_store;
	std::vector<Property> ma_property_store;
	
	const char* m_arch;
	bool m_has_whitespace, m_hide_cats, m_hide_dogs;
	
//-------------------------------------------------------------------------------------------------------------------------------------------
	
public:	
	MachO_File_ObjC(const char* path, bool perform_reduced_analysis = false, const char* arch = "any");
	~MachO_File_ObjC() throw() {
		if (m_class_filter != NULL) pcre_free(m_class_filter);
		if (m_method_filter != NULL) pcre_free(m_method_filter);
		if (m_class_filter_extra != NULL) pcre_free(m_class_filter_extra);
		if (m_method_filter_extra != NULL) pcre_free(m_method_filter_extra);
		for (std::tr1::unordered_map<const char*, MachO_File_ObjC*>::iterator it = ma_loaded_libraries.begin(); it != ma_loaded_libraries.end(); ++ it)
			delete it->second;
	}
	
	unsigned total_class_type_count() const throw() { return ma_classes.size(); }
	unsigned class_count() const throw() { return m_class_count; }
	unsigned categories_count() const throw() { return m_category_count; }
	unsigned protocols_count() const throw() { return m_protocol_count; }
	
	void print_class_type(SortBy sort_by, bool print_method_addresses, int print_comments, bool print_ivar_offsets, SortBy sort_methods_by, bool show_only_exported_classes) const throw();
	
	void set_pointers_right_aligned(bool right_aligned = true) throw() { m_record.pointers_right_aligned = right_aligned; }
	void set_prettify_struct_names(bool prettify_struct_names = true) throw() { m_record.prettify_struct_names = prettify_struct_names; }
	void set_class_filter(const char* regexp);
	void set_method_filter(const char* regexp);
	void set_kill_prefix(const std::vector<std::string>& kill_prefix) { m_kill_prefix = kill_prefix; }
	void set_method_has_whitespace(bool has_whitespace = true) throw() { m_has_whitespace = has_whitespace; }
	void set_hide_cats_and_dogs(bool hide_cats, bool hide_dogs) throw() { m_hide_cats = hide_cats; m_hide_dogs = hide_dogs; }
	
	void propertize() throw() {
		for (std::vector<ClassType>::iterator it = ma_classes.begin(); it != ma_classes.end(); ++ it)
			propertize(*it);
	}
	void hide_overlapping_methods(bool hide_super, bool hide_proto, const char* sysroot) throw();
	
	void print_struct_declaration(SortBy sort_by) const throw();
	
	void write_header_files(const char* filename, bool print_method_addresses, int print_comments, bool print_ivar_offsets, SortBy sort_by, bool show_only_exported_classes) const throw();
	
//-------------------------------------------------------------------------------------------------------------------------------------------
	
	void print_all_types() const throw();
	void print_network() const throw() { m_record.print_network(); }
	void print_extern_symbols() const throw();
	void print_class_inheritance() const throw();
};

#endif
