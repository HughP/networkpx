/*

ThumbDumbDisassembler.cpp ... Thumb Dumb Disassembler

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

#include "ThumbDumbDisassembler.h"

// This gotta go to TDWTF, I bet.
#if 0
{
#endif
#define Nibble1111 0xF
	
#define Nibble1110 0xE
#define Nibble111_ 0xE
	
#define Nibble1101 0xD
#define Nibble11_1 0xD
	
#define Nibble1100 0xC
#define Nibble110_ 0xC
#define Nibble11_0 0xC
#define Nibble11__ 0xC
	
#define Nibble1011 0xB
#define Nibble1_11 0xB
	
#define Nibble1010 0xA
#define Nibble101_ 0xA
#define Nibble1_10 0xA
#define Nibble1_1_ 0xA
	
#define Nibble1001 9
#define Nibble10_1 9
#define Nibble1_01 9
#define Nibble1__1 9
	
#define Nibble1000 8
#define Nibble100_ 8
#define Nibble10_0 8
#define Nibble10__ 8
#define Nibble1_00 8
#define Nibble1_0_ 8
#define Nibble1__0 8
#define Nibble1___ 8
	
#define Nibble0111 7
#define Nibble_111 7
	
#define Nibble0110 6
#define Nibble011_ 6
#define Nibble_110 6
#define Nibble_11_ 6
	
#define Nibble0101 5
#define Nibble01_1 5
#define Nibble_101 5
#define Nibble_1_1 5
	
#define Nibble0100 4
#define Nibble010_ 4
#define Nibble01_0 4
#define Nibble01__ 4
#define Nibble_100 4
#define Nibble_10_ 4
#define Nibble_1_0 4
#define Nibble_1__ 4
	
#define Nibble0011 3
#define Nibble0_11 3
#define Nibble_011 3
#define Nibble__11 3
	
#define Nibble0010 2
#define Nibble001_ 2
#define Nibble0_10 2
#define Nibble0_1_ 2
#define Nibble_010 2
#define Nibble_01_ 2
#define Nibble__10 2
#define Nibble__1_ 2
	
#define Nibble0001 1
#define Nibble00_1 1
#define Nibble0_01 1
#define Nibble0__1 1
#define Nibble_001 1
#define Nibble_0_1 1
#define Nibble__01 1
#define Nibble___1 1
	
#define Nibble0000 0
#define Nibble000_ 0
#define Nibble00_0 0
#define Nibble00__ 0
#define Nibble0_00 0
#define Nibble0_0_ 0
#define Nibble0__0 0
#define Nibble0___ 0
#define Nibble_000 0
#define Nibble_00_ 0
#define Nibble_0_0 0
#define Nibble_0__ 0
#define Nibble__00 0
#define Nibble__0_ 0
#define Nibble___0 0
#define Nibble____ 0
	
#define _(n3, n2, n1, n0) (((Nibble##n3)<<12)|((Nibble##n2)<<8)|((Nibble##n1)<<4)|(Nibble##n0))
#if 0
}
#endif

#define sp r[13]
#define lr r[14]
#define pc r[15]

static const char* const ops_cond[] = {"eq","ne","cs","cc","mi","pl","vs","vc","hi","ls","ge","lt","gt","le","al","??"};
static const char* const ops_dp3[] = {"mov", "cmp", "add", "sub"};
static const char* const ops_dp4[] = {"lsl", "lsr", "asr"};
static const char* const ops_dp5[] = {"and", "eor", "lsl", "lsr", "asr", "adc", "sbc", "ror", "tst", "neg", "cmp", "cmn", "orr", "mul", "bic", "mvn"};
static const char* const ops_dp8[] = {"add", "cmp", "mov"};
static const char* const ops_ls1[] = {"str", "ldr", "strb", "ldrb", "strh", "ldrh"};
static const char* const ops_ls2[] = {"str", "strh", "strb", "ldrsb", "ldr", "ldrh", "ldrb", "ldrsh"};

void ThumbDumbDisassembler::print_raw_instruction(unsigned vm_address, unsigned instruction, const char* decoded, bool hasR, unsigned R) const {
	fprintf(m_stream, "%08x\t%s%04x\t%-48s", vm_address, (instruction&0xFFFF0000?"":"    "), instruction, decoded);
	if (hasR) {
		fprintf(m_stream, "; %8x = ", R);
		this->print_references(R);
	}
}

unsigned ThumbDumbDisassembler::disassemble_at(unsigned vm_address) {
	pc = vm_address+4;
#define Print(x) this->print_raw_instruction(vm_address, instruction, decoded, true, (x))
#define PrintWithoutComments this->print_raw_instruction(vm_address, instruction, decoded, false, 0)
	
	unsigned instruction = m_file.read_integer();
	unsigned instr2 = instruction >> 16;
	instruction &= 0xFFFF;
	
	char decoded[80];
	unsigned op_code;
	const char* op;
	
	// Conditional branch
	if ( (instruction & _(1111,____,____,____)) == _(1101,____,____,____) ) {
		op_code = (instruction & _(____,1111,____,____)) >> 8;
		op = ops_cond[op_code];
		
		unsigned imm = (instruction & _(____,____,1111,1111));
		int delta = imm << 1;
		if (imm & (1<<7))
			delta |= ~_(____,___1,1111,1111);
		
		unsigned jump = pc + delta;
		snprintf(decoded, 80, "b%-7s 0x%x", op, jump);
		
		Print(jump);
		
		// Unconditional branch
	} else if ( (instruction & _(111_,1___,____,____)) == _(111_,0___,____,____) ) {
		op_code = (instruction & _(___1,1___,____,____));
		unsigned imm = (instruction & _(____,_111,1111,1111));
		
		int delta = imm << 1;
		if (imm & (1<<10))
			delta |= ~_(____,1111,1111,1111);
		
		if (!op_code) {
			// a simple unconditional branch.
			unsigned jump = pc + delta;
			snprintf(decoded, 80, "b        0x%x", jump);
			
			Print(jump);
			
		} else {
			// need to read one more instruction.
			instruction |= instr2 << 16;
			
			if ( (instr2 & _(111_,1___,____,____)) == _(111_,1___,____,____) ) {
				op_code = instr2 & (1<<12);
				unsigned imm2 = instr2 & _(____,_111,1111,1111);
				unsigned jump = (delta << 11 | imm2<<1) + pc;
				
				if (!op_code)
					jump &= ~3;
				
				snprintf(decoded, 80, "%-8s 0x%x", op_code?"bl":"blx", jump);
				Print(jump);
				
			} else {
				snprintf(decoded, 80, "  ?");
				PrintWithoutComments;
			}
			
			// we assume the bl/blx will return something.
			// NULL is the best thing we can predict.
			r[0] = 0;
			
			return 4;
		}
		
		// Branch with Exchange
	} else if ( (instruction & _(1111,1111,____,____)) == _(0100,0111,____,____) ) {
		op_code = (instruction & (1<<7));
		unsigned Rm = (instruction & _(____,____,_111,1___)) >> 3;
		
		snprintf(decoded, 80, "blx      %s", register_name(Rm));
		Print(r[Rm]);
		
		r[0] = 0;
		
		// Data-processing, format 1
	} else if ( (instruction & _(1111,11__,____,____)) == _(0001,10__,____,____) ) {
		op_code = (instruction & (1<<9));
		op = op_code ? "sub" : "add";
		
		unsigned Rm = (instruction & _(____,___1,11__,____)) >> 6;
		unsigned Rn = (instruction & _(____,____,__11,1___)) >> 3;
		unsigned Rd = (instruction & _(____,____,____,_111));
		
		snprintf(decoded, 80, "%-8s %s, %s, %s", op, register_name(Rd), register_name(Rn), register_name(Rm));
		r[Rd] = op_code ? (r[Rn] - r[Rm]) : (r[Rn] + r[Rm]);
		
		Print(r[Rd]);
		
		// Data-processing, format 2
	} else if ( (instruction & _(1111,11__,____,____)) == _(0001,11__,____,____) ) {
		op_code = (instruction & (1<<9));
		
		op = op_code ? "sub" : "add";
		unsigned imm = (instruction & _(____,___1,11__,____)) >> 6;
		unsigned Rn  = (instruction & _(____,____,__11,1___)) >> 3;
		unsigned Rd  = (instruction & _(____,____,____,_111));
		
		snprintf(decoded, 80, "%-8s %s, %s, #%d", op, register_name(Rd), register_name(Rn), imm);
		r[Rd] = op_code ? (r[Rn] - imm) : (r[Rn] + imm);
		
		Print(r[Rd]);
		
		// Data-processing, format 3
	} else if ( (instruction & _(111_,____,____,____)) == _(001_,____,____,____) ) {
		op_code = (instruction & _(___1,1___,____,____)) >> 11;
		op = ops_dp3[op_code];
		
		unsigned RdRn = (instruction & _(____,_111,____,____)) >> 8;
		unsigned imm = (instruction & _(____,____,1111,1111));
		
		snprintf(decoded, 80, "%-8s %s, #%d", op, register_name(RdRn), imm);
		
		switch (op_code) {
			case 2: r[RdRn] += imm; break;
			case 3: r[RdRn] -= imm; break;
			case 0: r[RdRn] = imm; break;
		}
		
		Print(r[RdRn]);
		
		// Data-processing, format 4
	} else if ( (instruction & _(111_,____,____,____)) == _(000_,____,____,____) ) {
		op_code = (instruction & _(___1,1___,____,____)) >> 11;
		op = ops_dp4[op_code];
		
		unsigned imm = (instruction & _(____,_111,11__,____)) >> 6;
		unsigned Rm  = (instruction & _(____,____,__11,1___)) >> 3;
		unsigned Rd  = (instruction & _(____,____,____,_111));
		
		snprintf(decoded, 80, "%-8s %s, %s, #%d", op, register_name(Rd), register_name(Rm), imm);
		
		switch (op_code) {
			case 0: r[Rd] = r[Rm] << imm; break;
			case 1: r[Rd] = ((unsigned)r[Rm]) >> imm; break;
			case 2: r[Rd] = r[Rm] >> imm; break;
		}
		
		Print(r[Rd]);
		
		// Data-processing, format 5
	} else if ( (instruction & _(1111,11__,____,____)) == _(0100,00__,____,____) ) {
		op_code = (instruction & _(____,__11,11__,____)) >> 6;
		op = ops_dp5[op_code];
		
		unsigned Rm = (instruction & _(____,____,__11,1___)) >> 3;
		unsigned Rd = (instruction & _(____,____,____,_111));
		
		snprintf(decoded, 80, "%-8s %s, %s", op, register_name(Rd), register_name(Rm));
		
		switch (op_code) {
			case 15: r[Rd] = ~r[Rm]; break;
				// FIXME: check carry flag.
			case 5: r[Rd] += r[Rm]; break;
			case 6: r[Rd] -= r[Rm]; break;
			case 9: r[Rd] = -r[Rm]; break;
			case 13: r[Rd] *= r[Rm]; break;
			case 2: r[Rd] <<= r[Rm]; break;
			case 3: r[Rd] = ((unsigned)r[Rd]) >> r[Rm]; break;
			case 4: r[Rd] >>= r[Rm]; break;
			case 7: r[Rd] = ror((unsigned)r[Rd], r[Rm]); break;
			case 0: r[Rd] &= r[Rm]; break;
			case 1: r[Rd] ^= r[Rm]; break;
			case 12: r[Rd] |= r[Rm]; break;
			case 14: r[Rd] &= ~r[Rm]; break;
		}
		
		Print(r[Rd]);
		
		// Data-processing, format 6
	} else if ( (instruction & _(1111,____,____,____)) == _(1010,____,____,____) ) {
		op_code = (instruction & (1<<11));
		
		unsigned Rd =  (instruction & _(____,_111,____,____)) >> 8;
		unsigned imm = (instruction & _(____,____,1111,1111)) * 4;
		
		snprintf(decoded, 80, "add      %s, %s, #%d", register_name(Rd), op_code?"sp":"pc", imm);
		r[Rd] = (op_code?sp:pc) + imm;
		
		Print(r[Rd]);
		
		// Data-processing, format 7
	} else if ( (instruction & _(1111,1111,____,____)) == _(1011,0000,____,____) ) {
		op_code = (instruction & (1<<7));
		
		unsigned imm = (instruction & _(____,____,_111,1111)) * 4;
		
		snprintf(decoded, 80, "%-8s sp, sp, #%d", op_code ? "sub" : "add", imm);
		if (op_code)
			sp -= imm;
		else
			sp += imm;
		
		PrintWithoutComments;
		
		// Data-processing, format 8
	} else if ( (instruction & _(1111,11__,____,____)) == _(0100,01__,____,____) ) {
		op_code = (instruction & _(____,__11,____,____)) >> 8;
		op = ops_dp8[op_code];
		
		unsigned Rm = (instruction & _(____,____,_111,1___)) >> 3;
		unsigned RdRn = (instruction & _(____,____,____,_111)) | (instruction & (1<<7))>>4;
		
		snprintf(decoded, 80, "%-8s %s, %s", op, register_name(RdRn), register_name(Rm));
		
		// don't change pc while instrumenting the program flow.
		if (RdRn != 15) {
			switch (op_code) {
				case 2: r[RdRn] = r[Rm]; break;
				case 0: r[RdRn] += r[Rm]; break;
			}
			
			Print(r[RdRn]);
		} else {
			switch (op_code) {
				case 2: Print(r[Rm]); break;
				case 0: Print(pc + r[Rm]); break;
			}
		}
		
		// Load & Store, format 1
	} else if ( (op_code = ((instruction & _(1111,1___,____,____)) >> 11)) >= 12 && op_code <= 17 ) {
		op_code -= 12;
		op = ops_ls1[op_code];
		
		unsigned imm = (instruction & _(____,_111,11__,____)) >> 6;
		int mask;
		switch (op_code & ~1) {
			case 0: imm *= 4; mask = 0xFFFFFFFF; break;
			case 4: imm *= 2; mask = 0xFFFF; break;
			default: mask = 0xFF; break;
		}
		unsigned Rn = (instruction & _(____,____,__11,1___)) >> 3;
		unsigned Rd = (instruction & _(____,____,____,_111));
		
		snprintf(decoded, 80, "%-8s %s, [%s, #%d]", op, register_name(Rd), register_name(Rn), imm);
		
		if (op_code & 1)
			this->load_reference(r[Rn]+imm, Rd, mask); 
		else
			this->store_reference(r[Rn]+imm, r[Rd], mask);
		
		Print(r[Rd] & mask);
		
		// Load & Store, format 2
	} else if ( (instruction & _(1111,____,____,____)) == _(0101,____,____,____) ) {
		op_code = (instruction & _(____,111_,____,____)) >> 9;
		op = ops_ls2[op_code];
		
		unsigned Rm = (instruction & _(____,___1,11__,____)) >> 6;
		unsigned Rn = (instruction & _(____,____,__11,1___)) >> 3;
		unsigned Rd = (instruction & _(____,____,____,_111));
		
		int mask, isSigned = (op_code == 3 || op_code == 7);
		switch (op_code) {
			case 4: 
			case 0: mask = 0xFFFFFFFF; break;
			case 5:
			case 7: 
			case 1: mask = 0xFFFF; break;
			case 6:
			case 3: 
			case 2: mask = 0xFF; break;
		}
		
		snprintf(decoded, 80, "%-8s %s, [%s, %s]", op, register_name(Rd), register_name(Rn), register_name(Rm));
		
		if (op_code >= 3)
			this->load_reference(r[Rn]+r[Rm], Rd, mask, isSigned);
		else
			this->store_reference(r[Rn]+r[Rm], r[Rd], mask);
		
		Print(r[Rd] & (isSigned ? ~0 : mask));
		
		// Load & Store, format 3
	} else if ( (instruction & _(1111,1___,____,____)) == _(0100,1___,____,____) ) {
		unsigned Rd  = (instruction & _(____,_111,____,____)) >> 8;
		unsigned imm = (instruction & _(____,____,1111,1111)) * 4;
		
		snprintf(decoded, 80, "ldr      %s, [pc, #%d]", register_name(Rd), imm);
		this->load_reference((pc&~3) + imm, Rd);
		
		Print(r[Rd]);
		
		// Load & Store, format 4
	} else if ( (instruction & _(1111,____,____,____)) == _(1001,____,____,____) ) {
		op_code = (instruction & (1<<11));
		
		unsigned  Rd = (instruction & _(____,_111,____,____)) >> 8;
		unsigned imm = (instruction & _(____,____,1111,1111)) * 4;
		snprintf(decoded, 80, "%-8s %s, [sp, #%d]", op_code?"ldr":"str", register_name(Rd), imm);
		
		if (op_code) {
			this->load_reference(sp + imm, Rd);
		} else {
			this->store_reference(sp + imm, r[Rd]);
		}
		
		Print(r[Rd]);
		
		// Load/Store multiple, format 1
	} else if ( (instruction & _(1111,____,____,____)) == _(1100,____,____,____) ) {
		op_code = (instruction & (1<<11));
		
		unsigned Rd = (instruction & _(____,_111,____,____)) >> 8;
		unsigned reglist = (instruction & _(____,____,1111,1111));
		
		snprintf(decoded, 80, "%-8s %s, %s", op_code?"ldmia":"stmia", register_name(Rd), compute_reg_list(reglist));
		
		if (op_code)
			ldmia(Rd, reglist);
		else
			stmia(Rd, reglist);
		
		PrintWithoutComments;
		
		// Load/Store multiple, format 2
	} else if ( (instruction & _(1111,_11_,____,____)) == _(1011,_10_,____,____) ) {
		op_code = (instruction & (1<<11));
		
		unsigned reglist = (instruction & _(____,____,1111,1111));
		if (instruction & (1<<8)) {
			if (op_code)	// pop
				reglist |= (1<<15);
			else {
				reglist |= (1<<14);
				fprintf(m_stream, "\n\n");
			}
		}
		
		snprintf(decoded, 80, "%-8s %s", op_code?"pop":"push", compute_reg_list(reglist));
		
		if (op_code)
			ldmia(13, reglist);
		else
			stmdb(13, reglist);
		
		PrintWithoutComments;
		
		if (reglist & (1 << 15))
			fprintf(m_stream, "\n");
		
		// Exception-generating instructions, or undefined instructions.
	} else {
		snprintf(decoded, 80, "  ?");
		PrintWithoutComments;
	}
	
	return 2;
}
