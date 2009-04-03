/*

MachO_File.h ... Mach-O file

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

#ifndef MACH_O_FILE_H
#define MACH_O_FILE_H

#include <mach-o/loader.h>
#include <mach-o/nlist.h>
#include <mach-o/reloc.h>
#include <cstdio>
#include <vector>
#include <ext/hash_map>
#include <ext/hash_set>
#include <new>
#include "DataFile.h"

class MachO_File : public DataFile {
public:
	struct ObjCMethod{
		const char* class_name;
		const char* sel_name;
		const char* types;
	};
	
private:
	std::vector<const load_command*> ma_load_commands;
	std::vector<const segment_command*> ma_segments;
	std::vector<const section*> ma_sections;
	
	const struct nlist* ma_symbols;
	std::size_t m_symbols_length;
	
	const unsigned* ma_indirect_symbols;
	std::size_t m_indirect_symbols_length;
	
	const char* ma_strings;
	
	const char* ma_cstrings;
	unsigned m_cstring_vmaddr;
	unsigned m_cstring_table_size;
	
	const relocation_info* ma_relocations;
	unsigned m_relocations_length;
	
	// VMAddress :-> string
	__gnu_cxx::hash_map<unsigned,const char*> ma_symbol_references;
	__gnu_cxx::hash_map<unsigned,const char*> ma_cfstrings;
	__gnu_cxx::hash_map<unsigned,const char*> ma_objc_classes;
	__gnu_cxx::hash_map<unsigned,const char*> ma_objc_selectors;
	
	__gnu_cxx::hash_map<unsigned,ObjCMethod> ma_objc_methods;
	
	__gnu_cxx::hash_set<unsigned> ma_is_extern_symbol;
	
	bool m_is_valid;
	
public:
	enum StringType {
		MOST_Symbol,
		MOST_CFString,
		MOST_CString,
		MOST_ObjCSelector,
		MOST_ObjCClass,
		MOST_ObjCProtocol,
		MOST_ObjCIvar
	};
	
	inline bool valid() const throw() { return m_is_valid; }
	
	MachO_File(const char* path) throw(std::bad_alloc,TRException);
	
	// try to obtain a string related to this vm_address.
	const char* string_representation (unsigned vm_address, StringType* p_strtype = NULL) const throw();
	
	static void print_string_representation(std::FILE* stream, const char* str, StringType strtype = MOST_Symbol) throw();
	
	unsigned to_file_offset (unsigned vm_address, int* p_guess_segment = NULL) const throw();
	unsigned to_vm_address (unsigned file_offset, int* p_guess_segment = NULL) const throw();
	
	// try to dereference this vm_address.
	unsigned dereference(unsigned vm_address) const throw();
	int segment_index_having_name(const char* name) const;
	const section* section_having_name (const char* segment_name, const char* section_name) const;
	
	template<typename T>
	inline const T* peek_data_at_vm_address(unsigned vm_address, int* p_guess_segment = NULL) const throw() {
		unsigned file_offset = this->to_file_offset(vm_address, p_guess_segment);
		return file_offset != 0 ? this->peek_data_at<T>(file_offset) : NULL;
	}
	
	inline void seek_vm_address(unsigned vm_address, int* p_guess_segment = NULL) throw() {
		this->seek(this->to_file_offset(vm_address, p_guess_segment));
	}
	
	inline void for_each_section (void(*p_func)(const section*)) const {
		if (m_is_valid)
			for_each(ma_sections.begin(), ma_sections.end(), p_func);
	}
	
	inline bool is_extern_symbol(unsigned vm_address) const throw() {
		return ma_is_extern_symbol.find(vm_address) != ma_is_extern_symbol.end();
	}
	
	const ObjCMethod* objc_method_at_vm_address(unsigned vm_address) const throw();
};

#endif