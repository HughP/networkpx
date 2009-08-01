#ifndef SYS_MMAN_H
#define SYS_MMAN_H
#ifndef _MSC_VER
#include_next <sys/mman.h>
#else
#include <windows.h>
#include <io.h>
#include <unordered_map>

static std::tr1::unordered_map<LPVOID, HANDLE> _filemappings;

#define	PROT_NONE	0x00	/* [MC2] no permissions */
#define	PROT_READ	0x01	/* [MC2] pages can be read */
#define	PROT_WRITE	0x02	/* [MC2] pages can be written */
#define	PROT_EXEC	0x04	/* [MC2] pages can be executed */
#define	MAP_SHARED	0x0001		/* [MF|SHM] share changes */
#define	MAP_PRIVATE	0x0002		/* [MF|SHM] changes are private */
#define MAP_FAILED	((void *)-1)	/* [MF|SHM] mmap failed */

static inline void print_error(const char* z) {
	LPTSTR s = NULL;
	DWORD err = GetLastError();
	FormatMessage(FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM, NULL, err, 0, reinterpret_cast<char*>(&s), 0, NULL);
	fprintf(stderr, "\n//*** %s: Win32 Error %x: %s\n\n", z, err, s);
	LocalFree(s);
}

static inline void* mmap(void* addr, size_t len, int prot, int flags, int fildes, off_t off) {
	DWORD protect, access = FILE_MAP_READ;
	if (prot & PROT_WRITE) {
		access = FILE_MAP_WRITE;
		if (prot & PROT_EXEC) {
			protect = PAGE_EXECUTE_READWRITE;
			access |= FILE_MAP_EXECUTE;
		} else
			protect = PAGE_READWRITE;
	} else if (prot & PROT_EXEC) {
		protect = PAGE_EXECUTE_READ;
		access |= FILE_MAP_EXECUTE;
	} else
		protect = PAGE_READONLY;

	HANDLE hFile = reinterpret_cast<HANDLE>(_get_osfhandle(fildes));
	HANDLE h = CreateFileMapping(hFile, NULL, protect, 0, len, NULL);
	if (h == 0) {
		print_error("CreateFileMapping");
		return MAP_FAILED;
	}
	
	LPVOID res = MapViewOfFile(h, access, 0, off, len);
	if (res == NULL) {
		print_error("MapViewOfFile");
		CloseHandle(h);
		return MAP_FAILED;
	}
	_filemappings[res] = h;

	return res;
}

static inline void munmap(void* addr, size_t len) {
	UnmapViewOfFile(addr);
	std::tr1::unordered_map<LPVOID, HANDLE>::iterator it = _filemappings.find(addr);
	if (it != _filemappings.end()) {
		CloseHandle(it->second);
		_filemappings.erase(it);
	}
}
#endif
#endif
