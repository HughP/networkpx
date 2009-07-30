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
	struct Property {
		std::string name;
		std::string synthesized_to;
		std::string getter;
		std::string setter;
		unsigned getter_vm_address;
		unsigned setter_vm_address;
		
		// these are from the attributes
		ObjCTypeRecord::TypeIndex type;		// T
		bool has_getter;	// G
		bool has_setter;	// S
		bool copy;			// C
		bool retain;		// &
		bool readonly;		// R
		bool nonatomic;		// N
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
		
		Property() : getter_vm_address(0), setter_vm_address(0), has_getter(false), has_setter(false), copy(false), retain(false), readonly(false), nonatomic(false), impl_method(IM_None), gc_strength(GC_None) {}
		
		std::string format(const ObjCTypeRecord& record, const MachO_File_ObjC& self, bool print_method_addresses, bool print_comments) const throw();
	};
	
	struct Ivar {
		ObjCTypeRecord::TypeIndex type;
		const char* name;
		unsigned offset;
	};
	
	struct Method {
		unsigned vm_address;
		enum {
			PS_None,
			PS_DeclaredGetter,
			PS_DeclaredSetter,
			PS_ConvertedGetter,
			PS_ConvertedSetter
		} propertize_status;
		const char* raw_name;
		
		// -(double)sumOfArray:(const double*)array count:(unsigned)count will be split into this form:
		// types = double, id, SEL, const double*, unsigned.
		// components = "", "", "", sumOfArray, count
		// -(id)copy will be split into this form:
		// types = id, id, SEL
		// components = "", "", ""
		bool is_class_method;
		bool optional;
		
		std::vector<ObjCTypeRecord::TypeIndex> types;
		std::vector<std::string> components;
		std::vector<std::string> argname;
		
		Method() : vm_address(0), propertize_status(PS_None), components(3) {}
		
		std::string format(const ObjCTypeRecord& record, const MachO_File_ObjC& self, bool print_method_addresses, bool print_comments) const throw();
	};
	
	struct ClassType {
		enum {
			CT_Protocol,
			CT_Class,
			CT_Category
		} type;
		
		unsigned vm_address;
		
		ObjCTypeRecord::TypeIndex type_index;
		
		const char* name;
		uint32_t attributes;
		const char* superclass_name;		// category name if isCategory.
		
		std::vector<Ivar> ivars;
		std::vector<Property> properties;
		std::vector<Method> methods;
				
		std::vector<unsigned> adopted_protocols;
		
		std::string format(const ObjCTypeRecord& record, const MachO_File_ObjC& self, bool print_method_addresses, bool print_comments, bool print_ivar_offsets, bool sort_methods_alphabetically, bool show_only_exported_classes) const throw();
	};
	
	friend class Method_AlphabeticSorter;
	friend class Property_AlphabeticSorter;
	friend class ClassType;
	
//-------------------------------------------------------------------------------------------------------------------------------------------
	
	int m_guess_data_segment, m_guess_text_segment;
	
	unsigned m_class_count, m_protocol_count, m_category_count;
	std::vector<ClassType> ma_classes;	// classes, categories & protocols.
	std::tr1::unordered_map<unsigned, unsigned> ma_classes_vm_address_index;	// vm_addr -> index in ma_classes
	std::tr1::unordered_map<ObjCTypeRecord::TypeIndex, std::string> ma_include_paths;
	
	ObjCTypeRecord m_record;
	
	void adopt_protocols(ClassType& cls, const protocol_list_t* protocols) throw();
	void add_properties(ClassType& cls, const objc_property_list* prop_list) throw();
	void add_methods(ClassType& cls, const method_list_t* method_list_ptr, bool class_method, bool optional) throw();
	
	const char* get_superclass_name(unsigned superclass_addr, unsigned pointer_to_superclass_addr, ObjCTypeRecord::TypeIndex& superclass_index) throw();
	const char* get_cstring(const void* vmaddr, int* guess_segment, unsigned symaddr, unsigned symoffset, const char* defsym) const throw();
	
	void retrieve_protocol_info() throw();
	void retrieve_class_info() throw();
	void retrieve_category_info() throw();
	
	void tag_propertized_methods(ClassType& cls) throw();
	
	void propertize(ClassType& cls) throw();
	
//-------------------------------------------------------------------------------------------------------------------------------------------
	
	pcre* m_class_filter, *m_method_filter;
	pcre_extra* m_class_filter_extra, *m_method_filter_extra;
	std::vector<std::string> m_kill_prefix;
	
	bool name_killable(const char* name, size_t length, bool check_kill_prefix) const throw();
		
	friend bool mfoc_AlphabeticSorter(const ClassType* a, const ClassType* b) throw();
	
	std::vector<std::string> ma_string_store;	// store C-strings.
	
//-------------------------------------------------------------------------------------------------------------------------------------------
	
public:
	enum SortBy {
		SB_None,
		SB_Inherit,
		SB_Alphabetic
	};
	
	MachO_File_ObjC(const char* path) throw(std::bad_alloc, TRException);
	~MachO_File_ObjC() throw() {
		if (m_class_filter != NULL) pcre_free(m_class_filter);
		if (m_method_filter != NULL) pcre_free(m_method_filter);
		if (m_class_filter_extra != NULL) pcre_free(m_class_filter_extra);
		if (m_method_filter_extra != NULL) pcre_free(m_method_filter_extra);
	}
	
	unsigned total_class_type_count() const throw() { return ma_classes.size(); }
	unsigned class_count() const throw() { return m_class_count; }
	unsigned categories_count() const throw() { return m_category_count; }
	unsigned protocols_count() const throw() { return m_protocol_count; }
	
	void print_class_type(SortBy sort_by, bool print_method_addresses, bool print_comments, bool print_ivar_offsets, bool sort_methods_alphabetically, bool show_only_exported_classes) const throw();
	
	void set_pointers_right_aligned(bool right_aligned = true) throw() { m_record.pointers_right_aligned = right_aligned; }
	void set_prettify_struct_names(bool prettify_struct_names = true) throw() { m_record.prettify_struct_names = prettify_struct_names; }
	void set_class_filter(const char* regexp);
	void set_method_filter(const char* regexp);
	void set_kill_prefix(const std::vector<std::string>& kill_prefix) { m_kill_prefix = kill_prefix; }
	
	void propertize() throw() {
		for (std::vector<ClassType>::iterator it = ma_classes.begin(); it != ma_classes.end(); ++ it)
			propertize(*it);
	}
	
	void print_struct_declaration(SortBy sort_by) const throw();
	
	void write_header_files(const char* filename, bool print_method_addresses, bool print_comments, bool print_ivar_offsets, bool sort_methods_alphabetically, bool show_only_exported_classes) const throw();
	
//-------------------------------------------------------------------------------------------------------------------------------------------
	
	void print_all_types() const throw();
	void print_network() const throw() { m_record.print_network(); }
	void print_extern_symbols() const throw();
};

#endif
