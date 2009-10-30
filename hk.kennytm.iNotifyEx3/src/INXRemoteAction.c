/*
 
INXRemoteAction.m ... Remote action.

Copyright (c) 2009  KennyTM~ <kennytm@gmail.com>
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

#include "INXCommon.h"
#include "INXRemoteAction.h"
#include <dlfcn.h>
#include <CoreFoundation/CoreFoundation.h>
#include <ctype.h>
#include "balanced_substr.h"

static CFArrayRef parseActionStringIntoArgv(const char* actionString) {
	CFMutableArrayRef res = CFArrayCreateMutable(NULL, 0, &kCFTypeArrayCallBacks);
	
	const char* lastActionString = actionString;
	while (*actionString != '\0') {
		lastActionString = actionString;
		actionString = skip_balanced_argument(actionString);
		
		int argLen = actionString-lastActionString;
		if (*lastActionString == '"' && *(actionString-1) == '"') {
			++ lastActionString;
			argLen -= 2;
		}
		
		CFStringRef s = CFStringCreateWithFormat(NULL, NULL, CFSTR("%.*s"), argLen, lastActionString);
		CFArrayAppendValue(res, s);
		CFRelease(s);
		
		while (isspace(*actionString))
			++ actionString;
	}
	
	return res;
}

#if TEST_ARGV
int main (int argc, const char* argv[]) {
	CFArrayRef a = parseActionStringIntoArgv(argv[1]);
	CFShow(a);
	CFRelease(a);
	return 0;
}
#else

#define INXCopyCString(res, str) \
const char* res##_s = CFStringGetCStringPtr(str, 0); \
bool res##_b = false; \
if (res##_s == NULL) { \
  CFIndex l = CFStringGetLength(str); \
  if (l > 64) { \
    res##_s = malloc(l+1); res##_b = true; \
  } else \
    res##_s = alloca(l+1); \
  CFStringGetCString(str, (char*)res##_s, l+1, 0); \
}

#define INXFreeCString(res) \
if (res##_b) free((char*)res##_s)

#define INXSTR(res) (res##_s)

extern void INXPerformRemoteAction(const char* actionString) {
	CFArrayRef argv = parseActionStringIntoArgv(actionString);
	if (CFArrayGetCount(argv) > 0) {
		CFStringRef command = CFArrayGetValueAtIndex(argv, 0);
		CFRange namespaceSep = CFStringFind(command, CFSTR("::"), 0);
		CFStringRef namespace;
		if (namespaceSep.location == kCFNotFound)
			namespace = CFRetain(CFSTR("std"));
		else {
			namespace = CFStringCreateWithSubstring(NULL, command, CFRangeMake(0, namespaceSep.location));
			CFStringRef newCmd = CFStringCreateWithSubstring(NULL, command, CFRangeMake(namespaceSep.location+namespaceSep.length, CFStringGetLength(command)-(namespaceSep.location+namespaceSep.length)));
			CFRelease(command);
			command = newCmd;
			
			if (CFStringFind(namespace, CFSTR("/"), 0).location != kCFNotFound) {
				CFRelease(namespace);
				namespace = CFRetain(CFSTR("std"));
			}
		}
		
		CFStringRef path = CFStringCreateWithFormat(NULL, 0, CFSTR(INXRoot"/ActionProviders/%@.dylib"), namespace);
		INXCopyCString(ns, path);
		
		void* handle = dlopen(INXSTR(ns), RTLD_LAZY|RTLD_LOCAL|RTLD_FIRST);
		
		if (handle == NULL)
			INXLog("iNotifyEx: Action provider module '%s' cannot be loaded.", INXSTR(ns));
		else {
			INXCopyCString(cmd, command);
			
			void(*actionFunc)(CFArrayRef) = (void(*)(CFArrayRef))dlsym(handle, INXSTR(cmd));
			if (actionFunc == NULL)
				INXLog("iNotifyEx: Action '%s' not found in module '%s'.", INXSTR(cmd), INXSTR(ns));
			else
				actionFunc(argv);
			INXFreeCString(cmd);
			
			dlclose(handle);
		}
		
		INXFreeCString(ns);
		CFRelease(path);
		CFRelease(namespace);
		CFRelease(command);
	}
	CFRelease(argv);
}

#endif
