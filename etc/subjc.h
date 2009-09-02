#ifndef SUBJC_HOOK
#define SUBJC_HOOK

#if !__arm__
#error Only available on ARM platforms!
#endif

#if __cplusplus
extern "C" {
#endif

#include <stdio.h>
#include <stdbool.h>
#include <objc/objc.h>

	void SubjC_initialize ();
	
	void SubjC_clear_filter();
	void SubjC_blacklist(size_t count, SEL selectors[]);
	void SubjC_whitelist(size_t count, SEL selectors[]);
	
	void SubjC_start(FILE* f, size_t maximum_depth, bool print_arguments, bool print_return_value);
	void SubjC_end();

#if __cplusplus
}
#endif

#endif
