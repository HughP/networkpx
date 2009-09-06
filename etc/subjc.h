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
	
	enum SubjC_FilterType {
		SubjC_Deny,
		SubjC_Allow
	};
	
	void SubjC_clear_filters();
	void SubjC_filter_method(enum SubjC_FilterType blacklist, Class class_, SEL selector);
	void SubjC_filter_class(enum SubjC_FilterType blacklist, Class class_);
	void SubjC_filter_selector(enum SubjC_FilterType blacklist, SEL selector);
	void SubjC_default_filter_type(enum SubjC_FilterType blacklist);
		
	void SubjC_start(FILE* f, size_t maximum_depth, bool print_arguments, bool print_return_value);
	void SubjC_end();

#if __cplusplus
}
#endif

#endif
