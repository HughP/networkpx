/*

AbstractARMDumbDisassembler.h ... Abstract ARM Dumb Disassembler

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

#ifndef ABSTRACTARMDUMBDISASSEMBLER_H
#define ABSTRACTARMDUMBDISASSEMBLER_H

#include "MachO_File.h"
#include <cstdio>

class AbstractARMDumbDisassembler {
protected:
	static const unsigned StackSize = (0x1000/sizeof(int));
	// >= 400 = stack overflow. Anything >= 400 is pc-relative, and anything < 400 is stack-relative.

	unsigned r[16];
	unsigned stack[StackSize];
	
	MachO_File& m_file;
	int m_text_segment_index, m_data_segment_index;
	std::FILE* m_stream;
	
	// some convenient functions....
	static inline unsigned ror (unsigned value, int shift) throw() { shift &= 31; return (value >> shift) | (value << (32 - shift)); }
	
	inline unsigned dereference (unsigned R) const throw() { return (R < StackSize) ? stack[R/sizeof(unsigned)] : m_file.dereference(R); }
	
	void store_reference (unsigned R, unsigned value, unsigned mask = ~0) throw();
	void load_reference (unsigned R, unsigned Rd, unsigned mask = ~0, bool isSigned = false) throw();
	
	void stmdb (unsigned Rd, unsigned reglist) throw();
	void stmia (unsigned Rd, unsigned reglist) throw();
	void ldmia (unsigned Rd, unsigned reglist) throw();
	
	static const char* compute_reg_list (unsigned list) throw();
	
public:
	AbstractARMDumbDisassembler(MachO_File& file, std::FILE* stream = stdout);
	
	virtual void print_raw_instruction(unsigned vm_address, unsigned instruction, const char* decoded, bool hasR = false, unsigned R = 0) const = 0;
	
	void print_references(unsigned vm_address, unsigned depth = 0) const throw();
	
	// disassemble current instruction and print into stream.
	// returns number of bytes advanced.
	virtual unsigned disassemble_at(unsigned current_vm_address) = 0;
	
	// note: these are vm_addresses.
	void disassemble_in_range(unsigned start_at, size_t range_bytes);
	
	static const char* register_name(unsigned i) throw();
};

#endif