#ifndef PCRE_H
#define PCRE_H

extern "C" {
	
	#include <stdlib.h>

	typedef void pcre;
	typedef void pcre_extra;

	pcre *pcre_compile(const char *, int, const char **, int *,
					  const unsigned char *);

	pcre_extra *pcre_study(const pcre *, int, const char **);

	int  pcre_exec(const pcre *, const pcre_extra *, const char*,
					   int, int, int, int *, int);
	
#ifndef VPCOMPAT
	extern void (*pcre_free)(void *);
#else
	extern void pcre_free(void *);
#endif
	
}

#endif
