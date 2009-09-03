#ifndef SUBJC_HOOK
#define SUBJC_HOOK

#if !__arm__ && !__i386__
#error Only available on x86 and ARM platforms!
#endif

#if __cplusplus
extern "C" {
#endif

#include <stdio.h>
#include <stdbool.h>
#include <objc/objc.h>

	void SubjC_initialize ();
	
	void SubjC_clear_selector_filter();
	void SubjC_blacklist_selectors(size_t count, SEL selectors[]);
	void SubjC_whitelist_selectors(size_t count, SEL selectors[]);
	
	void SubjC_clear_class_filter();
	void SubjC_blacklist_classes(size_t count, Class classes[]);
	void SubjC_whitelist_classes(size_t count, Class classes[]);
	
	void SubjC_start(FILE* f, size_t maximum_depth, bool print_arguments, bool print_return_value);
	void SubjC_end();

#if __cplusplus
}
#endif

#endif
