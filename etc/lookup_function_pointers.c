/*

lookup_function_pointers.c ... An extremely fast and simple function to replace nlist.
 
Copyright (c) 2009, KennyTM~
All rights reserved.
 
Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, 
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.
 * Neither the name of the KennyTM~ nor the names of its contributors may be
   used to endorse or promote products derived from this software without
   specific prior written permission.
 
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
*/

#include <mach-o/nlist.h>	// struct nlist
#include <mach-o/dyld.h>	// _dyld_image_count, etc.
#include <mach-o/loader.h>	// mach_header, etc.
#include <mach-o/fat.h>		// fat_header, etc.
#include <mach/mach.h>		// mach_host_self, etc.
#include <stdarg.h>
#include <stdlib.h>
#include <unistd.h>		// open
#include <fcntl.h>		// close
#include <sys/mman.h>		// mmap
#include <sys/stat.h>		// fstat

struct ImageLoaderMachO {
	void* vptr;
	// why?
#if __arm || __arm__
	void* vptr2;
#endif
	char _ImageLoader[68];
	
	const struct mach_header* fMachOData;
	const uint8_t* fLinkEditBase;
	const struct nlist* fSymbolTable;
	const char* fStrings;
	const struct dysymtab_command* fDynamicInfo;
	uintptr_t fSlide;
	// the rest are not important.
};

typedef struct ImageLoaderMachO* (*FPTR)(unsigned index);
static FPTR dyld_getIndexedImage = NULL;

static int get_image_index(const char* filename) {
	unsigned img_count = _dyld_image_count();
	size_t filename_len = strlen(filename);
	for (unsigned i = 0; i < img_count; ++ i) {
		const char* img_name = _dyld_get_image_name(i);
		size_t img_name_len = strlen(img_name);
		if (filename_len > img_name_len)
			continue;
		if (strncmp(filename, img_name - filename_len + img_name_len, filename_len) == 0)
			return i;
	}
	return -1;
}

/*
 Big big big assumptions:
 (1) dyld is at /usr/lib/dyld
 (2) there is a function called  dyld::getIndexedImage(unsigned)
 (3) it returns an ImageLoaderMachO pointer with fields compatible with above.
 (4) dyld's slide is zero.
 If any of these breaks, we're in great trouble.
 */
static int obtain_dyld() {
	int retval = 0;
	
	if (dyld_getIndexedImage == NULL) {
		int f = open("/usr/lib/dyld", O_RDONLY);
		if (f == -1)
			return -1;
		struct stat f_status;
		fstat(f, &f_status);
		char* m = (char*)mmap(NULL, f_status.st_size, PROT_READ, MAP_PRIVATE, f, 0);
		if ((int)m == -1) {
			close(f);
			return -2;
		}
		
		const struct mach_header* header = (const struct mach_header*)m;
		
		if (OSSwapBigToHostInt32(header->magic) == FAT_MAGIC) {				
			// Get our host info
			host_t                 host_self       = mach_host_self();
			unsigned               host_info_count = HOST_BASIC_INFO_COUNT;
			struct host_basic_info host_info_struct;
			kern_return_t          host_res        = host_info(host_self, HOST_BASIC_INFO, (host_info_t)&host_info_struct, &host_info_count);
			mach_port_deallocate(mach_task_self(), host_self);
			if (host_res != KERN_SUCCESS) {
				retval = -2;
				goto cleanup;
			}
			
			/* Read in the fat header */
			const struct fat_header* p_fat          = (const struct fat_header*)m;
			uint32_t                 fat_arch_count = OSSwapBigToHostInt32(p_fat->nfat_arch);
			const struct fat_arch*   arch           = (const struct fat_arch*)(p_fat+1);
			for (uint32_t i = 0; i < fat_arch_count; ++i, ++arch)
				if (OSSwapBigToHostInt32(arch->cputype) == host_info_struct.cpu_type) {
					header = (const struct mach_header*)(m + OSSwapBigToHostInt32(arch->offset));
					goto found_arch;
				}
			retval = -3;
			goto cleanup;
		}
		
found_arch:
		if (header->magic == MH_MAGIC) {
			const struct symtab_command* curcmd = (const struct symtab_command*)(header + 1);
			for (uint32_t i = 0; i < header->ncmds; ++ i) {
				if (curcmd->cmd == LC_SYMTAB) {
					const struct nlist* symbols  = (const struct nlist*)((const char*)header + curcmd->symoff);
					const char*         strings  = (const char*)header + curcmd->stroff;
					for (uint32_t j = 0; j < curcmd->nsyms; ++j, ++symbols) {
						if (strcmp(strings + symbols->n_un.n_strx, "__ZN4dyld15getIndexedImageEj") == 0) {
							dyld_getIndexedImage = (FPTR)symbols->n_value;
							retval = 0;
							goto cleanup;
						}	
					}
					retval = -4;
					goto cleanup;
				} else
					curcmd = (const struct symtab_command*)((const char*)(curcmd) + curcmd->cmdsize);
			} 
			retval = -5;
		} else
			retval = -6;
cleanup:
		munmap(m, f_status.st_size);
		close(f);
	}
	return retval;
}

static int get_image_symbol_count(const struct ImageLoaderMachO* image) {
	if (image == NULL)
		return -2;
	const struct load_command* curcmd = (const struct load_command*)(image->fMachOData + 1);
	for (unsigned i = 0; i < image->fMachOData->ncmds; ++ i) {
		if (curcmd->cmd == LC_SYMTAB)
			return ((const struct symtab_command*)curcmd)->nsyms;
		else
			curcmd = (const struct load_command*)((const char*)(curcmd) + curcmd->cmdsize);
	}
	return -1;
}

/*
 Usage:
 
 lookup_function_pointers("UIKit", "_UIKBGetKeyboardByName", &fptr, "_fntable.12345", &array, NULL);
 
 The worst case of this algorithm is O(nml), where
  - n is number of symbols in _filename_
  - m is number of symbols to be found.
  - l is the maximum string length of each symbol.
 This is the case where all symbols are undefined.
 
 If you sort the symbols in "nm -p" order and ensure all symbols are defined,
 the complexity can be reduced to O(n + ml).
 
 (In principle I could define a hash table can further reduce the worst case 
 complexity to amortized O(n+ml), but it wastes too much resource and gain a 
 little since m << n and l is small normally.)
 */
int lookup_function_pointers(const char* filename, ...) {
	if (obtain_dyld() != 0)
		return -1;
	int index = get_image_index(filename);
	if (index < 0)
		return -2;
	const struct ImageLoaderMachO* image = dyld_getIndexedImage(index);
	int symcount = get_image_symbol_count(image);
	if (symcount < 0)
		return -2 + symcount;
	
	int current_index = 0;
	va_list ap;
	va_start(ap, filename);
	const char* requested_symname;
	const char* previously_requested_symname = "";
	
	while ((requested_symname = va_arg(ap, const char*)) != NULL) {
		uint32_t* p_addr = va_arg(ap, uint32_t*);
		
		unsigned requested_symname_len1 = strlen(requested_symname) + 1;
		int scan_direction = memcmp(requested_symname, previously_requested_symname, requested_symname_len1);
		int stop_index = current_index;
		if (scan_direction >= 0) {
			for (; current_index < symcount; ++current_index)
				if (memcmp(image->fStrings+image->fSymbolTable[current_index].n_un.n_strx, requested_symname, requested_symname_len1) == 0)
					goto found;
			for (current_index = 0; current_index < stop_index; ++current_index)
				if (memcmp(image->fStrings+image->fSymbolTable[current_index].n_un.n_strx, requested_symname, requested_symname_len1) == 0)
					goto found;
		} else {
			for (; current_index >= 0; --current_index)
				if (memcmp(image->fStrings+image->fSymbolTable[current_index].n_un.n_strx, requested_symname, requested_symname_len1) == 0)
					goto found;
			for (current_index = symcount-1; current_index > stop_index; --current_index)
				if (memcmp(image->fStrings+image->fSymbolTable[current_index].n_un.n_strx, requested_symname, requested_symname_len1) == 0)
					goto found;
		}
		
		*p_addr = 0;
		continue;
		
found:
		*p_addr = image->fSymbolTable[current_index].n_value + image->fSlide;
		previously_requested_symname = requested_symname;
	}
	return 0;
}