/*

AbstractARMDumbDisassembler.cpp ... Abstract ARM Dumb Disassembler

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

#include "AbstractARMDumbDisassembler.h"

static const char* const regNames[] = {"r0", "r1", "r2", "r3", "r4", "r5", "r6", "r7", "r8", "r9", "sl", "fp", "ip", "sp", "lr", "pc"};
const char* AbstractARMDumbDisassembler::register_name(unsigned i) throw() { return regNames[i]; }


using namespace std;

#define sp r[13]
#define lr r[14]
#define pc r[15]
	
void AbstractARMDumbDisassembler::store_reference (unsigned R, unsigned value, unsigned mask) throw() {
	if (R < StackSize) {
		stack[R/4] &= ~mask;
		stack[R/4] |= value&mask;
	}
}

void AbstractARMDumbDisassembler::load_reference (unsigned R, unsigned Rd, unsigned mask, bool isSigned) throw() {
	r[Rd] = dereference(R) & mask;
	if (isSigned) {
		if (r[Rd] & ((mask+1)>>1))
			r[Rd] |= ~mask;
	}
}
	
void AbstractARMDumbDisassembler::stmdb (unsigned Rd, unsigned reglist) throw() {
	unsigned start_index = r[Rd]/4 - __builtin_popcount(reglist);
	unsigned index = start_index;
	
	for (int i = 0; i < 16; ++ i) {
		if (reglist & (1<<i)) {
			if (index < StackSize)
				stack[index] = r[i];
			++ index;
		}
	}
	
	r[Rd] = start_index*4;
}
void AbstractARMDumbDisassembler::stmia (unsigned Rd, unsigned reglist) throw() {
	unsigned index = r[Rd]/4;
	
	for (int i = 0; i < 16; ++ i) {
		if (reglist & (1<<i)) {
			if (index < StackSize)
				stack[index] = r[i];
			++ index;
		}
	}
	
	r[Rd] = index*4;
}
void AbstractARMDumbDisassembler::ldmia (unsigned Rd, unsigned reglist) throw() {
	unsigned index = r[Rd]/4;
	
	// don't write back the pc register.
	for (int i = 0; i < 15; ++ i) {
		if (reglist & (1<<i)) {
			if (index < StackSize)
				r[i] = stack[index];
			++ index;
		}
	}
	
	r[Rd] = index*4;
}

static char RegListScratchMemory[4*16+1];
const char* AbstractARMDumbDisassembler::compute_reg_list (unsigned list) throw() {
	int index = 1;
	bool printed_something = false;
	RegListScratchMemory[0] = '{';
	for (unsigned i = 0; i < 16; ++ i) {
		if (list & (1<<i)) {
			if (printed_something) {
				RegListScratchMemory[index++] = ',';
				RegListScratchMemory[index++] = ' ';
			} else
				printed_something = 1;
			
			const char* name = register_name(i);
			RegListScratchMemory[index++] = name[0];
			RegListScratchMemory[index++] = name[1];
		}
	}
	RegListScratchMemory[index++] = '}';
	RegListScratchMemory[index++] = '\0';
	return RegListScratchMemory;
}

AbstractARMDumbDisassembler::AbstractARMDumbDisassembler(MachO_File& file, FILE* stream) : m_file(file), m_text_segment_index(file.segment_index_having_name("__TEXT")), m_data_segment_index(file.segment_index_having_name("__DATA")), m_stream(stream) {
	if (m_text_segment_index == -1) m_text_segment_index = 0;
	if (m_data_segment_index == -1) m_data_segment_index = 0;
}

void AbstractARMDumbDisassembler::print_references(unsigned vm_address, unsigned depth) const throw() {
#define MAX_DEPTH 8
	if (vm_address == 0)
		return;
	
	if (vm_address/4 < StackSize) {
		if (vm_address >= sp) {
			fprintf(m_stream, "sp+%d -> ", vm_address-sp);
			if (depth < MAX_DEPTH)
				this->print_references(stack[vm_address/4], depth+1);
			else
				fprintf(m_stream, "...");
		} else 
			fprintf(m_stream, "?");
	} else {
		MachO_File::StringType strtype;
		const char* str_rep = m_file.string_representation(vm_address, &strtype);
		if (str_rep != NULL) {
			MachO_File::print_string_representation(m_stream, str_rep, strtype);
			return;
		}
		
		unsigned deref = this->dereference(vm_address);
		if (deref != 0) {
			fprintf(m_stream, "&0x%x -> ", deref);
			if (depth < MAX_DEPTH)
				this->print_references(deref, depth+1);
			else
				fprintf(m_stream, "...");
		} else 
			fprintf(m_stream, "?");
	}
#undef MAX_DEPTH
}

void AbstractARMDumbDisassembler::disassemble_in_range(unsigned start_at, size_t range_bytes) {
	int guess_index = m_text_segment_index;
	m_file.seek_vm_address(start_at, &guess_index);
	
	off_t cur_file_offset = m_file.tell();
	
	size_t bytes_scanned = 0;
	unsigned cur_address = start_at;
	
	sp = StackSize-64;
	
	while (bytes_scanned < range_bytes) {
		m_file.seek(cur_file_offset);
		
		if (m_file.valid()) {
			const char* cursymbol = m_file.string_representation(cur_address);
			if (cursymbol != NULL) {
				fprintf(m_stream, "\n ;\n ; %s:\n", cursymbol);
				if (m_file.is_extern_symbol(cur_address))
					fprintf(m_stream, " ; <extern>\n");
				fprintf(m_stream, " ;\n");
			} else {
				const MachO_File::ObjCMethod* curmethod = m_file.objc_method_at_vm_address(cur_address);
				if (curmethod != NULL)
					fprintf(m_stream, "\n ;\n ; ?[%s %s]:\n ;\n", curmethod->class_name, curmethod->sel_name);
			}
		}
		
		unsigned this_bytes = this->disassemble_at(cur_address);
		
		cur_file_offset += this_bytes;
		cur_address += this_bytes;
		bytes_scanned += this_bytes;
		
		fprintf(m_stream, "\n");
	}
}