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
#include <tr1/unordered_map>
#include <map>
#include <tr1/unordered_set>
#include <new>
#include <algorithm>
#include <string>
#include "DataFile.h"

class MachO_File_Simple : public DataFile {
public:
	struct ObjCMethod{
		const char* class_name;
		const char* sel_name;
		const char* types;
		bool is_class_method;
	};
	
protected:
	std::vector<const load_command*> ma_load_commands;
	std::vector<const segment_command*> ma_segments;
	std::vector<const section*> ma_sections;
	
	bool m_is_valid;
	off_t m_origin;
	off_t m_crypt_begin, m_crypt_end;
	
public:
	inline bool valid() const throw() { return m_is_valid; }
	MachO_File_Simple(const char* path, const char* arch = "any");
	
	off_t to_file_offset (unsigned vm_address, int* p_guess_segment = NULL) const throw();
	unsigned to_vm_address (off_t file_offset, int* p_guess_segment = NULL) const throw();
	
	// try to dereference this vm_address.
	unsigned dereference(unsigned vm_address) const throw();
	int segment_index_having_name(const char* name) const;
	const section* section_having_name (const char* segment_name, const char* section_name) const;
	
	template<typename T>
	inline const T* peek_data_at_vm_address(unsigned vm_address, int* p_guess_segment = NULL) const throw() {
		off_t file_offset = this->to_file_offset(vm_address, p_guess_segment);
		return file_offset != 0 ? this->peek_data_at<T>(file_offset) : NULL;
	}
	
	inline void seek_vm_address(unsigned vm_address, int* p_guess_segment = NULL) throw() {
		this->seek(this->to_file_offset(vm_address, p_guess_segment));
	}
	
	inline void for_each_section (void(*p_func)(const section*)) const {
		if (m_is_valid)
			std::for_each(ma_sections.begin(), ma_sections.end(), p_func);
	}
		
	std::vector<std::string> linked_libraries(const std::string& sysroot) const;
	std::tr1::unordered_set<std::string> linked_libraries_recursive(const std::string& sysroot) const;
	
	const char* self_path() const throw();
	
	inline bool encrypted() const throw() { return m_crypt_begin != m_crypt_end; }
	inline bool file_offset_encrypted(off_t offset) const throw() { return offset >= m_crypt_begin && offset < m_crypt_end; }
	inline bool vm_address_encrypted(unsigned vm_address, int* p_guess_segment = NULL) { return file_offset_encrypted(to_file_offset(vm_address, p_guess_segment)); } 
	
	inline unsigned text_segment_vm_adress() const { return m_is_valid ? ma_segments[segment_index_having_name("__TEXT")]->vmaddr : 0; }
};

//------------------------------------------------------------------------------

class MachO_File : public MachO_File_Simple {
private:
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
	std::tr1::unordered_map<unsigned,const char*> ma_symbol_references;
	std::tr1::unordered_map<unsigned,const char*> ma_cfstrings;
	
	std::tr1::unordered_map<unsigned,const char*> ma_objc_classes;
	std::tr1::unordered_map<unsigned,const char*> ma_objc_selectors;
	
	std::tr1::unordered_map<unsigned,ObjCMethod> ma_objc_methods;
	
	std::tr1::unordered_set<unsigned> ma_is_external_symbol;
	std::tr1::unordered_map<unsigned,unsigned> ma_library_ordinals;
	
	std::vector<std::string> ma_string_store;
	
	// 10.6 compressed mach-o formats.
	void bind(uint32_t size) throw();
	void process_export_trie_node(off_t start, off_t cur, off_t end, const std::string& prefix);
	void process_export_trie(off_t start, off_t end) throw();
	
public:
	enum StringType {
		MOST_Symbol,
		MOST_CFString,
		MOST_CString,
		MOST_ObjCSelector,
		MOST_ObjCClass,
		MOST_ObjCProtocol,
		MOST_ObjCIvar,
		MOST_ObjCMethod
	};
	
	MachO_File(const char* path, const char* arch = "any");
	
	// try to obtain a string related to this vm_address.
	const char* string_representation (unsigned vm_address, StringType* p_strtype = NULL) const throw();
	const char* nearest_string_representation (unsigned vm_address, unsigned* offset, StringType* p_strtype = NULL) const throw();
	
	static void print_string_representation(std::FILE* stream, const char* str, StringType strtype = MOST_Symbol) throw();
	
	inline bool is_extern_symbol(unsigned vm_address) const throw() {
		return ma_is_external_symbol.find(vm_address) != ma_is_external_symbol.end();
	}
	
	inline bool is_symbol(unsigned vm_address) const throw() {
		return ma_symbol_references.find(vm_address) != ma_symbol_references.end();
	}
	
	unsigned address_of_symbol(const char* sym) const throw();
	
	const ObjCMethod* objc_method_at_vm_address(unsigned vm_address) const throw();
	
	const char* library_of_relocated_symbol(unsigned vm_address) const throw();
	
	void for_each_symbol (void(*p_func)(unsigned addr, const char* symbol, StringType type, void* context), void* context) const;
};

#endif
