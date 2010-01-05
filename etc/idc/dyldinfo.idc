/*

dyldinfo.idc ... Make IDA Pro 5.x able to recognize the DYLD_INFO[_ONLY] command.

Copyright (C) 2010  KennyTM~

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

#define	LC_SEGMENT	0x1
#define LC_DYLD_INFO 0x22
#define LC_DYLD_INFO_ONLY 0x80000022

#define BIND_OPCODE_MASK					0xF0
#define BIND_IMMEDIATE_MASK					0x0F
#define BIND_OPCODE_DONE					0x00
#define BIND_OPCODE_SET_DYLIB_ORDINAL_IMM			0x10
#define BIND_OPCODE_SET_DYLIB_ORDINAL_ULEB			0x20
#define BIND_OPCODE_SET_DYLIB_SPECIAL_IMM			0x30
#define BIND_OPCODE_SET_SYMBOL_TRAILING_FLAGS_IMM		0x40
#define BIND_OPCODE_SET_TYPE_IMM				0x50
#define BIND_OPCODE_SET_ADDEND_SLEB				0x60
#define BIND_OPCODE_SET_SEGMENT_AND_OFFSET_ULEB			0x70
#define BIND_OPCODE_ADD_ADDR_ULEB				0x80
#define BIND_OPCODE_DO_BIND					0x90
#define BIND_OPCODE_DO_BIND_ADD_ADDR_ULEB			0xA0
#define BIND_OPCODE_DO_BIND_ADD_ADDR_IMM_SCALED			0xB0
#define BIND_OPCODE_DO_BIND_ULEB_TIMES_SKIPPING_ULEB		0xC0

#include <idc.idc>

static read_uleb (f) {
	auto res, bit, c;
	res = 0;
	bit = 0;
	do {
		c = fgetc(f);
		res = res | ((c & 0x7f) << bit);
		bit = bit + 7;
	} while (c & 0x80);
	return res;
}

// Read NULL-terminated string.
static read_string (f) {
	auto str, c;
	str = "";
	while (c = fgetc(f))
		str = str + c;
	return str;
}

static find_seg_addr(seg) {
	extern first_seg, cmd_count, seg_0, seg_1, seg_2;
	auto cmd_ea, i, seg_index, vm;
	
	if (seg == 0 && seg_0 != -1) return seg_0;
	else if (seg == 1 && seg_1 != -1) return seg_1;
	else if (seg == 2 && seg_2 != -1) return seg_2;
	
	cmd_ea = first_seg + 28;
	seg_index = 0;
	
	for (i = 0; i < cmd_count; ++ i) {
		if (Dword(cmd_ea) == LC_SEGMENT) {
			if (seg_index == seg) {
				vm = Dword(cmd_ea + 24);
				if (seg == 0) seg_0 = vm;
				else if (seg == 1) seg_1 = vm;
				else if (seg == 2) seg_2 = vm;
				return vm;
			}
			++ seg_index;
		}
		cmd_ea = cmd_ea + Dword(cmd_ea + 4);
	}
}

static patch(ea, sym) {
	auto target;
	if (Dword(ea) == 0) {
		PatchDword(ea, LocByName(sym));
		OpOffset(ea, 0);
	}
}

static bind(f, seek, size) {
	auto libord, sym, addr, end;
	auto imm, opcode, c, count, skip, i;
	
	if (seek == 0 || size == 0)
		return;
		
	fseek(f, seek, 0);
	libord = 0;
	sym = "";
	addr = 0;
	end = seek + size;
	
	while (ftell(f) < end) {
		c = fgetc(f);
		imm = c & BIND_IMMEDIATE_MASK;
		opcode = c & BIND_OPCODE_MASK;
		
		if (opcode == BIND_OPCODE_SET_DYLIB_ORDINAL_ULEB || opcode == BIND_OPCODE_SET_ADDEND_SLEB) {
			read_uleb(f);
		} else if (opcode == BIND_OPCODE_SET_SYMBOL_TRAILING_FLAGS_IMM) {
			sym = read_string(f);
		} else if (opcode == BIND_OPCODE_SET_SEGMENT_AND_OFFSET_ULEB) {
			addr = find_seg_addr(imm) + read_uleb(f);
		} else if (opcode == BIND_OPCODE_ADD_ADDR_ULEB) {
			addr = addr + read_uleb(f);
		} else if (opcode == BIND_OPCODE_DO_BIND) {
			patch(addr, sym);
			addr = addr + 4;
		} else if (opcode == BIND_OPCODE_DO_BIND_ADD_ADDR_ULEB) {
			patch(addr, sym);
			addr = addr + 4 + read_uleb(f);
		} else if (opcode == BIND_OPCODE_DO_BIND_ADD_ADDR_IMM_SCALED) {
			patch(addr, sym);
			addr = addr + (imm+1)*4;
		} else if (opcode == BIND_OPCODE_DO_BIND_ULEB_TIMES_SKIPPING_ULEB) {
			count = read_uleb(f);
			skip = read_uleb(f);
			for (i = 0; i < count; ++ i) {
				patch(addr, sym);
				addr = addr + 4 + skip;
			}
		}
	}
}

static find_origin(f, first_seg) {
	auto cpu_type, cpu_subtype, magic, endian, nfat_arch, i;
	auto check_cpu_type, check_cpu_subtype;
	magic = readlong(f, 0);
	if (magic == 0xCAFEBABE)
		endian = 0;
	else if (magic == 0xBEBAFECA)
		endian = 1;
	else
		return 0;
	
	cpu_type = Dword(first_seg + 4);
	cpu_subtype = Dword(first_seg + 8);
	
	nfat_arch = readlong(f, endian);
	for (i = 0; i < nfat_arch; ++ i) {
		check_cpu_type = readlong(f, endian);
		check_cpu_subtype = readlong(f, endian);
		if (check_cpu_type == cpu_type && check_cpu_subtype == cpu_subtype)
			return readlong(f, endian);
		else {
			readlong(f, endian);
			readlong(f, endian);
			readlong(f, endian);
		}
	}
	return 0;
}

static main () {
	extern first_seg, cmd_count, seg_0, seg_1, seg_2;
	auto i, cmd_ea, cmd_type, cmd_size, m_origin, f;
	
	seg_0 = seg_1 = seg_2 = -1;
	
	first_seg = FirstSeg();
	if (Dword(first_seg) != 0xFEEDFACE) {
		Warning("Not a valid 32-bit Mach-O binary!");
		return;
	}
	
	cmd_count = Dword(first_seg + 16);
	cmd_ea = first_seg + 28;
	// Search for LC_DYLD_INFO or LC_DYLD_INFO_ONLY command.
	for (i = 0; i < cmd_count; ++ i) {
		cmd_type = Dword(cmd_ea);
		cmd_size = Dword(cmd_ea+4);
		if (cmd_type == LC_DYLD_INFO || cmd_type == LC_DYLD_INFO_ONLY) {
			m_origin = 0;
			
			// Make sure we handle fat files correctly.
			f = fopen(GetInputFilePath(), "rb");
			m_origin = find_origin(f, first_seg);
			
			bind(f, m_origin + Dword(cmd_ea + 16), Dword(cmd_ea + 20));
			bind(f, m_origin + Dword(cmd_ea + 24), Dword(cmd_ea + 28));
			bind(f, m_origin + Dword(cmd_ea + 32), Dword(cmd_ea + 36));
			
			fclose(f);
			return;
		}
		cmd_ea = cmd_ea + cmd_size;
	}
	Warning("Cannot find DYLD_INFO[_ONLY] command. Nothing to fix.");
}
