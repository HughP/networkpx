/*

MachO_File.cpp ... Mach-O file

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

#include <sys/mman.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <mach-o/fat.h>
#include "MachO_File.h"

using namespace std;
using namespace __gnu_cxx;

static void fprint_with_escape (FILE* stream, const char* s) {
	while (true) {
		switch (*s) {
			case '\0': return;
			case '\t': fputs("\\t", stream); break;
			case '\n': fputs("\\n", stream); break;
			case '\\': fputs("\\\\", stream); break;
			case '"': fputs("\\\"", stream); break;
			case '\a': fputs("\\a", stream); break;
			case '\b': fputs("\\b", stream); break;
			case '\f': fputs("\\f", stream); break;
			case '\r': fputs("\\r", stream); break;
			case '\v': fputs("\\v", stream); break;
			default:
				if (*s < ' ' || *s > '~')
					fprintf(stream, "\\x%02x", (unsigned char)*s);
				else
					fputc(*s, stream);
				break;
		}
		++ s;
	}
}

static bool nlist_compare(const struct nlist* a, const struct nlist* b) { return a->n_value < b->n_value; }
static const char* print_string_representation_format_strings_prefix[] = {"", "CFSTR(\"", "\"", "@selector(", "(Class)", "@protocol(", "/*ivar*/"};
static const char* print_string_representation_format_strings_suffix[] = {"", "\")", "\"", ")", "", ")", ""};


MachO_File::MachO_File(const char* path) throw(bad_alloc,TRException) : DataFile(path), m_symbols_length(0), m_indirect_symbols_length(0), m_cstring_vmaddr(0), ma_strings(NULL), ma_symbols(NULL), ma_indirect_symbols(NULL), ma_cstrings(NULL), m_origin(0) {
	const mach_header* mp_header = this->read_data<mach_header>();
	
	if (OSSwapBigToHostInt32(mp_header->magic) == FAT_MAGIC) {
		::std::fprintf(stderr, "Warning: Universal (fat) binary detected. thumb-ddis will always disassemble with the first architecture, no matter it's actually ARM or not. To be sure, unbundle the object with 'lipo -extract armv6'.\n");
		this->retreat(sizeof(mach_header) - sizeof(fat_header));
		const fat_arch* arch = this->read_data<fat_arch>();
		m_origin = OSSwapBigToHostInt32(arch->offset);
		this->seek(m_origin);
		mp_header = this->read_data<mach_header>();
	}
	
	if (mp_header->magic != MH_MAGIC) {
		m_is_valid = false;
		return;
	} else
		m_is_valid = true;
	
	// analyze the load commands.
	ma_load_commands.reserve(mp_header->ncmds);
	
	for (unsigned i = 0; i < mp_header->ncmds; ++ i) {
		const load_command* p_cur_cmd = this->read_data<load_command>();
		ma_load_commands.push_back(p_cur_cmd);
		
		switch (p_cur_cmd->cmd) {
			case LC_SEGMENT: {
				off_t old_location = this->tell();
				this->advance(sizeof(segment_command)-sizeof(load_command));
				
				const segment_command* p_cur_seg = reinterpret_cast<const segment_command*>(p_cur_cmd);
				ma_segments.push_back(p_cur_seg);
				
				for (unsigned j = 0; j < p_cur_seg->nsects; ++ j)
					ma_sections.push_back(this->read_data<section>());
				
				this->seek(old_location);
				break;
			}
				
			case LC_SYMTAB: {
				off_t old_location = this->tell();
				
				const symtab_command* p_cur_symtab = reinterpret_cast<const symtab_command*>(p_cur_cmd);
				
				this->seek(m_origin + p_cur_symtab->symoff);
				ma_symbols = this->peek_data<struct nlist>();
				m_symbols_length = p_cur_symtab->nsyms;
				
				this->seek(m_origin + p_cur_symtab->stroff);
				ma_strings = this->peek_data<char>();
				
				this->seek(old_location);
				break;
			}
				
			case LC_DYSYMTAB: {
				off_t old_location = this->tell();
				
				const dysymtab_command* p_cur_dysymtab = reinterpret_cast<const dysymtab_command*>(p_cur_cmd);
				
				this->seek(m_origin + p_cur_dysymtab->indirectsymoff);
				ma_indirect_symbols = this->peek_data<unsigned>();
				m_indirect_symbols_length = p_cur_dysymtab->nindirectsyms;
				
				this->seek(m_origin + p_cur_dysymtab->extreloff);
				ma_relocations = this->peek_data<relocation_info>();
				m_relocations_length = p_cur_dysymtab->nextrel;
				
				this->seek(old_location);
				break;
			}
		}
		
		this->advance(p_cur_cmd->cmdsize - sizeof(load_command));
	}
	
	for (unsigned i = 0; i < m_symbols_length; ++ i) {
		ma_symbol_references[ma_symbols[i].n_value & ~1] = ma_strings + ma_symbols[i].n_un.n_strx;
		if (ma_symbols[i].n_type & N_EXT)
			ma_is_extern_symbol.insert(ma_symbols[i].n_value & ~1);
	}
	
	for (unsigned i = 0; i < m_relocations_length; ++ i)
		ma_symbol_references[ma_relocations[i].r_address & ~1] = ma_strings + ma_symbols[ma_relocations[i].r_symbolnum].n_un.n_strx;
	
	// analyze the sections (to short-cut the indirect symbols)
	for (vector<const section*>::const_iterator cit = ma_sections.begin(); cit != ma_sections.end(); ++ cit) {
		const section* s = *cit;
		unsigned sect_type = s->flags & SECTION_TYPE;
		switch (sect_type) {
			case S_NON_LAZY_SYMBOL_POINTERS:
			case S_LAZY_SYMBOL_POINTERS:
			case S_SYMBOL_STUBS: {
				unsigned stride = (sect_type == S_SYMBOL_STUBS) ? s->reserved2 : 4;
				unsigned end_index = s->reserved1 + s->size/stride;
				
				for (unsigned i = s->reserved1, vm_address = s->addr; i < end_index; ++ i, vm_address += stride)
					ma_symbol_references[vm_address & ~1] = ma_strings + ma_symbols[ma_indirect_symbols[i]].n_un.n_strx;
				
				break;
			}
				
			case S_CSTRING_LITERALS:
				this->seek(m_origin + s->offset);
				ma_cstrings = this->peek_data<char>();
				m_cstring_vmaddr = s->addr;
				m_cstring_table_size = s->size;
				break;
				
			default:
				if (!strncmp(s->sectname, "__cfstring", 16)) {
					this->seek(m_origin + s->offset + 8);
					for (unsigned i = 0; i < s->size; i += 16) {
						unsigned vm_address = this->read_integer();
						this->advance(12);
						
						ma_cfstrings[s->addr + i] = ma_cstrings + vm_address - m_cstring_vmaddr;
					}
				} else if (!strncmp(s->sectname, "__class_list", 16) || !strncmp(s->sectname, "__objc_classlist", 16)) {
					int sid_data = 1, sid_text = 0;
					this->seek(m_origin + s->offset);
					for (unsigned i = 0; i < s->size; i += 4) {
						unsigned vm_address = this->read_integer();
						off_t old_location = this->tell();

						this->seek_vm_address(vm_address + 16, &sid_data);		// get to the data field class.
						unsigned data_loc = this->read_integer();

						this->seek_vm_address(data_loc + 16, &sid_data);		// get to the name field of the data.
						this->seek_vm_address(this->read_integer(), &sid_text);	// resolve the location of the string.
						
						ObjCMethod m;
						m.class_name = this->peek_data<char>();
						ma_objc_classes[vm_address] = m.class_name;
						
						this->seek_vm_address(data_loc + 20, &sid_data);		// get to the baseMethod field of the data.
						unsigned baseMethod_loc = this->read_integer();
						if (baseMethod_loc != 0) {
							this->seek_vm_address(baseMethod_loc + 4, &sid_data);	// get to the count field of the data.
							unsigned count = this->read_integer();
								
							for (unsigned j = 0; j < count; ++ j) {
								m.sel_name = this->peek_data_at_vm_address<char>(this->read_integer(), &sid_text);
								m.types = this->peek_data_at_vm_address<char>(this->read_integer(), &sid_text);
								ma_objc_methods[this->read_integer() & ~1] = m;
							}
						}
						
						this->seek(old_location);
					}
				} else if (!strncmp(s->sectname, "__objc_selrefs", 16)) {
					this->seek(m_origin + s->offset);
					
					for (unsigned i = 0; i < s->size; i += 4) {
						unsigned vm_address = this->read_integer();
						ma_objc_selectors[vm_address] = this->peek_data_at_vm_address<char>(vm_address);
					}
				}
				
				
				
				break;
		}
	}
}
		
// try to obtain a string related to this vm_address.
const char* MachO_File::string_representation (unsigned vm_address, MachO_File::StringType* p_strtype) const throw() {
	if (!m_is_valid) {
		if (p_strtype != NULL)
			*p_strtype = MOST_CString;
		return this->peek_ASCII_Cstring_at(vm_address);
	}
	
	if (vm_address == 0)
		return NULL;
	
	hash_map<unsigned,const char*>::const_iterator cit;
	
#define TrySearchIn(table, stringType) \
cit = (table).find(vm_address); \
if (cit != (table).end()) { \
if (p_strtype != NULL) *p_strtype = (stringType); \
return cit->second; \
}
	
	TrySearchIn(ma_cfstrings, MOST_CFString);
	TrySearchIn(ma_symbol_references, MOST_Symbol);
	TrySearchIn(ma_objc_classes, MOST_ObjCClass);
	TrySearchIn(ma_objc_selectors, MOST_ObjCSelector);
	
#undef TrySearchIn
	
	if (m_cstring_vmaddr <= vm_address && m_cstring_vmaddr+m_cstring_table_size >= vm_address) {
		if (p_strtype != NULL)
			*p_strtype = MOST_CString;
		return ma_cstrings + vm_address - m_cstring_vmaddr;
	}
	
	return NULL;
}
	
void MachO_File::print_string_representation(FILE* stream, const char* str, MachO_File::StringType strtype) throw() {
	fputs(print_string_representation_format_strings_prefix[strtype], stream);
	fprint_with_escape(stream, str);
	fputs(print_string_representation_format_strings_suffix[strtype], stream);		
}

unsigned MachO_File::to_file_offset (unsigned vm_address, int* p_guess_segment) const throw() {
	if (!m_is_valid)
		return vm_address;
	
	const segment_command* seg;
	if (p_guess_segment != NULL) {
		seg = ma_segments[*p_guess_segment];
		if (seg->vmaddr <= vm_address && seg->vmaddr + seg->vmsize > vm_address)
			return m_origin + vm_address - seg->vmaddr + seg->fileoff;
	}
	
	unsigned i = 0;
	for (vector<const segment_command*>::const_iterator cit = ma_segments.begin(); cit != ma_segments.end(); ++ cit) {
		seg = *cit;
		if (seg->vmaddr <= vm_address && seg->vmaddr + seg->vmsize > vm_address) {
			if (p_guess_segment != NULL)
				*p_guess_segment = i;
			return m_origin + vm_address - seg->vmaddr + seg->fileoff;
		}
		++ i;
	}
	return 0;
}

unsigned MachO_File::to_vm_address (unsigned file_offset, int* p_guess_segment) const throw() {
	if (!m_is_valid)
		return file_offset;
	
	file_offset -= m_origin;
	
	const segment_command* seg;
	if (p_guess_segment != NULL) {
		seg = ma_segments[*p_guess_segment];
		if (seg->fileoff <= file_offset && seg->fileoff + seg->filesize > file_offset)
			return file_offset + seg->vmaddr - seg->fileoff;
	}
	
	unsigned i = 0;
	for (vector<const segment_command*>::const_iterator cit = ma_segments.begin(); cit != ma_segments.end(); ++ cit) {
		seg = *cit;
		if (seg->fileoff <= file_offset && seg->fileoff + seg->filesize > file_offset) {
			if (p_guess_segment != NULL)
				*p_guess_segment = i;
			return file_offset + seg->vmaddr - seg->fileoff;
		}
		++ i;
	}
	return 0;
}

// try to dereference this vm_address.
unsigned MachO_File::dereference(unsigned vm_address) const throw() {
	static int last_deref_section = 0;
	const unsigned* ptr = this->peek_data_at_vm_address<unsigned>(vm_address, &last_deref_section);
	if (ptr == NULL)
		return 0;
	else
		return *ptr;
}

int MachO_File::segment_index_having_name(const char* name) const {
	int i = 0;
	if (m_is_valid) {
		for (vector<const segment_command*>::const_iterator cit = ma_segments.begin(); cit != ma_segments.end(); ++ cit) {
			if (!strncmp((*cit)->segname, name, 16))
				return i;
			++ i;
		}
	}
	return -1;
}
const section* MachO_File::section_having_name (const char* segment_name, const char* section_name) const {
	if (m_is_valid) {
		for (vector<const section*>::const_iterator cit = ma_sections.begin(); cit != ma_sections.end(); ++ cit) {
			if (!strncmp((*cit)->segname, segment_name, 16) && !strncmp((*cit)->sectname, section_name, 16))
				return *cit;
		}
	}
	return NULL;
}

const MachO_File::ObjCMethod* MachO_File::objc_method_at_vm_address(unsigned vm_address) const throw() {
	if (m_is_valid) {
		hash_map<unsigned,MachO_File::ObjCMethod>::const_iterator cit = ma_objc_methods.find(vm_address);
		if (cit == ma_objc_methods.end())
			return NULL;
		else
			return &(cit->second);
	} else
		return NULL;
}
