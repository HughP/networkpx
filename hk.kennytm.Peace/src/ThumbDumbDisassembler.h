/*

ThumbDumbDisassembler.h ... Thumb Dumb Disassembler

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

#ifndef THUMBDUMBDISASSEMNLER_H
#define THUMBDUMBDISASSEMNLER_H

#include "AbstractARMDumbDisassembler.h"

class ThumbDumbDisassembler : public AbstractARMDumbDisassembler {
public:
	ThumbDumbDisassembler(MachO_File& file, std::FILE* stream = stdout) : AbstractARMDumbDisassembler(file, stream) {}
	
	virtual void print_raw_instruction(unsigned vm_address, unsigned instruction, const char* decoded, bool hasR, unsigned R) const;
	virtual unsigned disassemble_at(unsigned vm_address);
};

#endif