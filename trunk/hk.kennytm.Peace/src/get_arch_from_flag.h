/*
 * Copyright (c) 1999 Apple Computer, Inc. All rights reserved.
 *
 * @APPLE_LICENSE_HEADER_START@
 * 
 * This file contains Original Code and/or Modifications of Original Code
 * as defined in and that are subject to the Apple Public Source License
 * Version 2.0 (the 'License'). You may not use this file except in
 * compliance with the License. Please obtain a copy of the License at
 * http://www.opensource.apple.com/apsl/ and read it before using this
 * file.
 * 
 * The Original Code and all software distributed under the License are
 * distributed on an 'AS IS' basis, WITHOUT WARRANTY OF ANY KIND, EITHER
 * EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES,
 * INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE, QUIET ENJOYMENT OR NON-INFRINGEMENT.
 * Please see the License for the specific language governing rights and
 * limitations under the License.
 * 
 * @APPLE_LICENSE_HEADER_END@
 */

#ifndef GET_ARCH_FROM_FLAG_H
#define GET_ARCH_FROM_FLAG_H

#include <mach-o/typedef.h>

#if __cplusplus
extern "C" {
#endif
	
	/*
	 *	Machine types known by all.
	 */
	
#define CPU_TYPE_ANY		((cpu_type_t) -1)
	
#define CPU_TYPE_VAX		((cpu_type_t) 1)
#define CPU_TYPE_ROMP		((cpu_type_t) 2)
#define CPU_TYPE_NS32032	((cpu_type_t) 4)
#define CPU_TYPE_NS32332        ((cpu_type_t) 5)
#define	CPU_TYPE_MC680x0	((cpu_type_t) 6)
#define CPU_TYPE_I386		((cpu_type_t) 7)
#define CPU_TYPE_X86_64		((cpu_type_t) (CPU_TYPE_I386 | CPU_ARCH_ABI64))
#define CPU_TYPE_MIPS		((cpu_type_t) 8)
#define CPU_TYPE_NS32532        ((cpu_type_t) 9)
#define CPU_TYPE_HPPA           ((cpu_type_t) 11)
#define CPU_TYPE_ARM		((cpu_type_t) 12)
#define CPU_TYPE_MC88000	((cpu_type_t) 13)
#define CPU_TYPE_SPARC		((cpu_type_t) 14)
#define CPU_TYPE_I860		((cpu_type_t) 15) // big-endian
#define	CPU_TYPE_I860_LITTLE	((cpu_type_t) 16) // little-endian
#define CPU_TYPE_RS6000		((cpu_type_t) 17)
#define CPU_TYPE_MC98000	((cpu_type_t) 18)
#define CPU_TYPE_POWERPC	((cpu_type_t) 18)
#define CPU_ARCH_ABI64		 0x1000000
#define CPU_TYPE_POWERPC64	((cpu_type_t)(CPU_TYPE_POWERPC | CPU_ARCH_ABI64))
#define CPU_TYPE_VEO		((cpu_type_t) 255)
	
	/*
	 *	Machine subtypes (these are defined here, instead of in a machine
	 *	dependent directory, so that any program can get all definitions
	 *	regardless of where is it compiled).
	 */
	
	/*
	 * Capability bits used in the definition of cpu_subtype.
	 */
#define CPU_SUBTYPE_MASK       0xff000000      /* mask for feature flags */
#define CPU_SUBTYPE_LIB64      0x80000000      /* 64 bit libraries */
	
	
	/*
	 *	Object files that are hand-crafted to run on any
	 *	implementation of an architecture are tagged with
	 *	CPU_SUBTYPE_MULTIPLE.  This functions essentially the same as
	 *	the "ALL" subtype of an architecture except that it allows us
	 *	to easily find object files that may need to be modified
	 *	whenever a new implementation of an architecture comes out.
	 *
	 *	It is the responsibility of the implementor to make sure the
	 *	software handles unsupported implementations elegantly.
	 */
#define	CPU_SUBTYPE_MULTIPLE	((cpu_subtype_t) -1)
	
	
	/*
	 *	VAX subtypes (these do *not* necessary conform to the actual cpu
	 *	ID assigned by DEC available via the SID register).
	 */
	
#define	CPU_SUBTYPE_VAX_ALL	((cpu_subtype_t) 0) 
#define CPU_SUBTYPE_VAX780	((cpu_subtype_t) 1)
#define CPU_SUBTYPE_VAX785	((cpu_subtype_t) 2)
#define CPU_SUBTYPE_VAX750	((cpu_subtype_t) 3)
#define CPU_SUBTYPE_VAX730	((cpu_subtype_t) 4)
#define CPU_SUBTYPE_UVAXI	((cpu_subtype_t) 5)
#define CPU_SUBTYPE_UVAXII	((cpu_subtype_t) 6)
#define CPU_SUBTYPE_VAX8200	((cpu_subtype_t) 7)
#define CPU_SUBTYPE_VAX8500	((cpu_subtype_t) 8)
#define CPU_SUBTYPE_VAX8600	((cpu_subtype_t) 9)
#define CPU_SUBTYPE_VAX8650	((cpu_subtype_t) 10)
#define CPU_SUBTYPE_VAX8800	((cpu_subtype_t) 11)
#define CPU_SUBTYPE_UVAXIII	((cpu_subtype_t) 12)
	
	/*
	 *	ROMP subtypes.
	 */
	
#define	CPU_SUBTYPE_RT_ALL	((cpu_subtype_t) 0)
#define CPU_SUBTYPE_RT_PC	((cpu_subtype_t) 1)
#define CPU_SUBTYPE_RT_APC	((cpu_subtype_t) 2)
#define CPU_SUBTYPE_RT_135	((cpu_subtype_t) 3)
	
	/*
	 *	32032/32332/32532 subtypes.
	 */
	
#define	CPU_SUBTYPE_MMAX_ALL	    ((cpu_subtype_t) 0)
#define CPU_SUBTYPE_MMAX_DPC	    ((cpu_subtype_t) 1)	/* 032 CPU */
#define CPU_SUBTYPE_SQT		    ((cpu_subtype_t) 2)
#define CPU_SUBTYPE_MMAX_APC_FPU    ((cpu_subtype_t) 3)	/* 32081 FPU */
#define CPU_SUBTYPE_MMAX_APC_FPA    ((cpu_subtype_t) 4)	/* Weitek FPA */
#define CPU_SUBTYPE_MMAX_XPC	    ((cpu_subtype_t) 5)	/* 532 CPU */
	
	/*
	 *	I386 subtypes.
	 */
	
#define	CPU_SUBTYPE_I386_ALL	((cpu_subtype_t) 3)
#define	CPU_SUBTYPE_X86_64_ALL	CPU_SUBTYPE_I386_ALL
#define CPU_SUBTYPE_386		((cpu_subtype_t) 3)
#define CPU_SUBTYPE_486		((cpu_subtype_t) 4)
#define CPU_SUBTYPE_486SX	((cpu_subtype_t) 4 + 128)
#define CPU_SUBTYPE_586		((cpu_subtype_t) 5)
#define CPU_SUBTYPE_INTEL(f, m)	((cpu_subtype_t) (f) + ((m) << 4))
#define CPU_SUBTYPE_PENT	CPU_SUBTYPE_INTEL(5, 0)
#define CPU_SUBTYPE_PENTPRO	CPU_SUBTYPE_INTEL(6, 1)
#define CPU_SUBTYPE_PENTII_M3	CPU_SUBTYPE_INTEL(6, 3)
#define CPU_SUBTYPE_PENTII_M5	CPU_SUBTYPE_INTEL(6, 5)
#define CPU_SUBTYPE_PENTIUM_4	CPU_SUBTYPE_INTEL(10, 0)
	
#define CPU_SUBTYPE_INTEL_FAMILY(x)	((x) & 15)
#define CPU_SUBTYPE_INTEL_FAMILY_MAX	15
	
#define CPU_SUBTYPE_INTEL_MODEL(x)	((x) >> 4)
#define CPU_SUBTYPE_INTEL_MODEL_ALL	0
	
	/*
	 *	Mips subtypes.
	 */
	
#define	CPU_SUBTYPE_MIPS_ALL	((cpu_subtype_t) 0)
#define CPU_SUBTYPE_MIPS_R2300	((cpu_subtype_t) 1)
#define CPU_SUBTYPE_MIPS_R2600	((cpu_subtype_t) 2)
#define CPU_SUBTYPE_MIPS_R2800	((cpu_subtype_t) 3)
#define CPU_SUBTYPE_MIPS_R2000a	((cpu_subtype_t) 4)
	
	/*
	 * 	680x0 subtypes
	 *
	 * The subtype definitions here are unusual for historical reasons.
	 * NeXT used to consider 68030 code as generic 68000 code.  For
	 * backwards compatability:
	 * 
	 *	CPU_SUBTYPE_MC68030 symbol has been preserved for source code
	 *	compatability.
	 *
	 *	CPU_SUBTYPE_MC680x0_ALL has been defined to be the same
	 *	subtype as CPU_SUBTYPE_MC68030 for binary comatability.
	 *
	 *	CPU_SUBTYPE_MC68030_ONLY has been added to allow new object
	 *	files to be tagged as containing 68030-specific instructions.
	 */
	
#define	CPU_SUBTYPE_MC680x0_ALL		((cpu_subtype_t) 1)
#define CPU_SUBTYPE_MC68030		((cpu_subtype_t) 1) /* compat */
#define CPU_SUBTYPE_MC68040		((cpu_subtype_t) 2) 
#define	CPU_SUBTYPE_MC68030_ONLY	((cpu_subtype_t) 3)
	
	/*
	 *	HPPA subtypes for Hewlett-Packard HP-PA family of
	 *	risc processors. Port by NeXT to 700 series. 
	 */
	
#define	CPU_SUBTYPE_HPPA_ALL		((cpu_subtype_t) 0)
#define CPU_SUBTYPE_HPPA_7100		((cpu_subtype_t) 0) /* compat */
#define CPU_SUBTYPE_HPPA_7100LC		((cpu_subtype_t) 1)
	
	/* 
	 * 	Acorn subtypes - Acorn Risc Machine port done by
	 *		Olivetti System Software Laboratory
	 */
	
#define	CPU_SUBTYPE_ARM_ALL		((cpu_subtype_t) 0)
#define CPU_SUBTYPE_ARM_A500_ARCH	((cpu_subtype_t) 1)
#define CPU_SUBTYPE_ARM_A500		((cpu_subtype_t) 2)
#define CPU_SUBTYPE_ARM_A440		((cpu_subtype_t) 3)
#define CPU_SUBTYPE_ARM_M4		((cpu_subtype_t) 4)
#define CPU_SUBTYPE_ARM_V4T		((cpu_subtype_t) 5)
#define CPU_SUBTYPE_ARM_V6		((cpu_subtype_t) 6)
#define CPU_SUBTYPE_ARM_V5TEJ		((cpu_subtype_t) 7)
#define CPU_SUBTYPE_ARM_XSCALE		((cpu_subtype_t) 8)
#define CPU_SUBTYPE_ARM_V7 ((cpu_subtype_t) 9)
	
	/*
	 *	MC88000 subtypes
	 */
#define	CPU_SUBTYPE_MC88000_ALL	((cpu_subtype_t) 0)
#define CPU_SUBTYPE_MMAX_JPC	((cpu_subtype_t) 1)
#define CPU_SUBTYPE_MC88100	((cpu_subtype_t) 1)
#define CPU_SUBTYPE_MC88110	((cpu_subtype_t) 2)
	
	/*
	 *	MC98000 (PowerPC) subtypes
	 */
#define	CPU_SUBTYPE_MC98000_ALL	((cpu_subtype_t) 0)
#define CPU_SUBTYPE_MC98601	((cpu_subtype_t) 1)
	
	/*
	 *	I860 subtypes
	 */
#define CPU_SUBTYPE_I860_ALL	((cpu_subtype_t) 0)
#define CPU_SUBTYPE_I860_860	((cpu_subtype_t) 1)
	
	/*
	 * 	I860 subtypes for NeXT-internal backwards compatability.
	 *	These constants will be going away.  DO NOT USE THEM!!!
	 */
#define CPU_SUBTYPE_LITTLE_ENDIAN	((cpu_subtype_t) 0)
#define CPU_SUBTYPE_BIG_ENDIAN		((cpu_subtype_t) 1)
	
	/*
	 *	I860_LITTLE subtypes
	 */
#define	CPU_SUBTYPE_I860_LITTLE_ALL	((cpu_subtype_t) 0)
#define	CPU_SUBTYPE_I860_LITTLE	((cpu_subtype_t) 1)
	
	/*
	 *	RS6000 subtypes
	 */
#define	CPU_SUBTYPE_RS6000_ALL	((cpu_subtype_t) 0)
#define CPU_SUBTYPE_RS6000	((cpu_subtype_t) 1)
	
	/*
	 *	Sun4 subtypes - port done at CMU
	 */
#define	CPU_SUBTYPE_SUN4_ALL		((cpu_subtype_t) 0)
#define CPU_SUBTYPE_SUN4_260		((cpu_subtype_t) 1)
#define CPU_SUBTYPE_SUN4_110		((cpu_subtype_t) 2)
	
#define	CPU_SUBTYPE_SPARC_ALL		((cpu_subtype_t) 0)
	
	/*
	 *      PowerPC subtypes
	 */
#define CPU_SUBTYPE_POWERPC_ALL		((cpu_subtype_t) 0)
#define CPU_SUBTYPE_POWERPC_601		((cpu_subtype_t) 1)
#define CPU_SUBTYPE_POWERPC_602		((cpu_subtype_t) 2)
#define CPU_SUBTYPE_POWERPC_603		((cpu_subtype_t) 3)
#define CPU_SUBTYPE_POWERPC_603e	((cpu_subtype_t) 4)
#define CPU_SUBTYPE_POWERPC_603ev	((cpu_subtype_t) 5)
#define CPU_SUBTYPE_POWERPC_604		((cpu_subtype_t) 6)
#define CPU_SUBTYPE_POWERPC_604e	((cpu_subtype_t) 7)
#define CPU_SUBTYPE_POWERPC_620		((cpu_subtype_t) 8)
#define CPU_SUBTYPE_POWERPC_750		((cpu_subtype_t) 9)
#define CPU_SUBTYPE_POWERPC_7400	((cpu_subtype_t) 10)
#define CPU_SUBTYPE_POWERPC_7450	((cpu_subtype_t) 11)
#define CPU_SUBTYPE_POWERPC_970		((cpu_subtype_t) 100)
	
	/*
	 * VEO subtypes
	 * Note: the CPU_SUBTYPE_VEO_ALL will likely change over time to be defined as
	 * one of the specific subtypes.
	 */
#define CPU_SUBTYPE_VEO_1	((cpu_subtype_t) 1)
#define CPU_SUBTYPE_VEO_2	((cpu_subtype_t) 2)
#define CPU_SUBTYPE_VEO_3	((cpu_subtype_t) 3)
#define CPU_SUBTYPE_VEO_4	((cpu_subtype_t) 4)
#define CPU_SUBTYPE_VEO_ALL	CPU_SUBTYPE_VEO_2
	
	struct arch_flag {
		const char* name;
		cpu_type_t cputype;
		cpu_subtype_t cpusubtype;
	};

	int get_arch_from_flag(const char *name, struct arch_flag *arch_flag);
	
#if __cplusplus
}
#endif

#endif
