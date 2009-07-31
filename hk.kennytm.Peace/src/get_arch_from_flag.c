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

#include "get_arch_from_flag.h"
#include <string.h>

static const struct arch_flag arch_flags[] = {
	{ "any",	CPU_TYPE_ANY,	  CPU_SUBTYPE_MULTIPLE },
	{ "little",	CPU_TYPE_ANY,	  CPU_SUBTYPE_LITTLE_ENDIAN },
	{ "big",	CPU_TYPE_ANY,	  CPU_SUBTYPE_BIG_ENDIAN },

	/* 64-bit Mach-O architectures */

	/* architecture families */
	{ "ppc64",     CPU_TYPE_POWERPC64, CPU_SUBTYPE_POWERPC_ALL },
	{ "x86_64",    CPU_TYPE_X86_64, CPU_SUBTYPE_X86_64_ALL },
	/* specific architecture implementations */
	{ "ppc970-64", CPU_TYPE_POWERPC64, CPU_SUBTYPE_POWERPC_970 },

	/* 32-bit Mach-O architectures */

	/* architecture families */
	{ "ppc",    CPU_TYPE_POWERPC, CPU_SUBTYPE_POWERPC_ALL },
	{ "i386",   CPU_TYPE_I386,    CPU_SUBTYPE_I386_ALL },
	{ "m68k",   CPU_TYPE_MC680x0, CPU_SUBTYPE_MC680x0_ALL },
	{ "hppa",   CPU_TYPE_HPPA,    CPU_SUBTYPE_HPPA_ALL },
	{ "sparc",	CPU_TYPE_SPARC,   CPU_SUBTYPE_SPARC_ALL },
	{ "m88k",   CPU_TYPE_MC88000, CPU_SUBTYPE_MC88000_ALL },
	{ "i860",   CPU_TYPE_I860,    CPU_SUBTYPE_I860_ALL },
	{ "veo",    CPU_TYPE_VEO,     CPU_SUBTYPE_VEO_ALL },
	{ "arm",    CPU_TYPE_ARM,     CPU_SUBTYPE_ARM_ALL },
	/* specific architecture implementations */
	{ "ppc601", CPU_TYPE_POWERPC, CPU_SUBTYPE_POWERPC_601 },
	{ "ppc603", CPU_TYPE_POWERPC, CPU_SUBTYPE_POWERPC_603 },
	{ "ppc603e",CPU_TYPE_POWERPC, CPU_SUBTYPE_POWERPC_603e },
	{ "ppc603ev",CPU_TYPE_POWERPC,CPU_SUBTYPE_POWERPC_603ev },
	{ "ppc604", CPU_TYPE_POWERPC, CPU_SUBTYPE_POWERPC_604 },
	{ "ppc604e",CPU_TYPE_POWERPC, CPU_SUBTYPE_POWERPC_604e },
	{ "ppc750", CPU_TYPE_POWERPC, CPU_SUBTYPE_POWERPC_750 },
	{ "ppc7400",CPU_TYPE_POWERPC, CPU_SUBTYPE_POWERPC_7400 },
	{ "ppc7450",CPU_TYPE_POWERPC, CPU_SUBTYPE_POWERPC_7450 },
	{ "ppc970", CPU_TYPE_POWERPC, CPU_SUBTYPE_POWERPC_970 },
	{ "i486",   CPU_TYPE_I386,    CPU_SUBTYPE_486 },
	{ "i486SX", CPU_TYPE_I386,    CPU_SUBTYPE_486SX },
	{ "pentium",CPU_TYPE_I386,    CPU_SUBTYPE_PENT }, /* same as i586 */
	{ "i586",   CPU_TYPE_I386,    CPU_SUBTYPE_586 },
	{ "pentpro", CPU_TYPE_I386, CPU_SUBTYPE_PENTPRO }, /* same as i686 */
	{ "i686",   CPU_TYPE_I386, CPU_SUBTYPE_PENTPRO },
	{ "pentIIm3",CPU_TYPE_I386, CPU_SUBTYPE_PENTII_M3 },
	{ "pentIIm5",CPU_TYPE_I386, CPU_SUBTYPE_PENTII_M5 },
	{ "pentium4",CPU_TYPE_I386, CPU_SUBTYPE_PENTIUM_4 },
	{ "m68030", CPU_TYPE_MC680x0, CPU_SUBTYPE_MC68030_ONLY },
	{ "m68040", CPU_TYPE_MC680x0, CPU_SUBTYPE_MC68040 },
	{ "hppa7100LC", CPU_TYPE_HPPA,  CPU_SUBTYPE_HPPA_7100LC },
	{ "veo1",   CPU_TYPE_VEO,     CPU_SUBTYPE_VEO_1 },
	{ "veo2",   CPU_TYPE_VEO,     CPU_SUBTYPE_VEO_2 },
	{ "veo3",   CPU_TYPE_VEO,     CPU_SUBTYPE_VEO_3 },
	{ "veo4",   CPU_TYPE_VEO,     CPU_SUBTYPE_VEO_4 },
	{ "armv4t", CPU_TYPE_ARM,     CPU_SUBTYPE_ARM_V4T},
	{ "armv5",  CPU_TYPE_ARM,     CPU_SUBTYPE_ARM_V5TEJ},
	{ "xscale", CPU_TYPE_ARM,     CPU_SUBTYPE_ARM_XSCALE},
	{ "armv6",  CPU_TYPE_ARM,     CPU_SUBTYPE_ARM_V6 },
	{ "armv7",  CPU_TYPE_ARM,     CPU_SUBTYPE_ARM_V7 },
	{ NULL,	0,		  0 }
};

int get_arch_from_flag(const char *name, struct arch_flag *arch_flag) {
	unsigned long i;
	
	for(i = 0; arch_flags[i].name != NULL; i++){
	    if(strcmp(arch_flags[i].name, name) == 0){
			if(arch_flag != NULL)
				*arch_flag = arch_flags[i];
			return(1);
	    }
	}
	return(0);
}
