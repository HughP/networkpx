#ifndef UNISTD_H
#define UNISTD_H
#ifndef _MSC_VER
#include_next <unistd.h>
#else
#include <direct.h>
static inline int mkdir (const char* path, int mode) { return _mkdir(path); }
#endif
#endif
