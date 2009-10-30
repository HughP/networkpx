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
#include <CoreFoundation/CFLogUtilities.h>
#include <ctype.h>
#include "balanced_substr.h"
#include <libkern/OSAtomic.h>

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
		
		CFStringRef s = CFStringCreateWithBytes(NULL, (const UInt8*)lastActionString, argLen, kCFStringEncodingUTF8, false);
		if (s != NULL) {
			CFArrayAppendValue(res, s);
			CFRelease(s);
		}
		
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

static CFMutableDictionaryRef _loadedLibs = NULL;

extern void INXPerformRemoteAction(const char* actionString) {
	static CFMutableDictionaryRef _loadedSyms = NULL;
	
	CFArrayRef argv = parseActionStringIntoArgv(actionString);
	if (CFArrayGetCount(argv) > 0) {
		// sanitize the command first...
		CFStringRef rawcommand = CFArrayGetValueAtIndex(argv, 0);
		CFRange namespaceSep = CFStringFind(rawcommand, CFSTR("."), kCFCompareBackwards);
		
		CFMutableStringRef namespace, command;
		if (namespaceSep.location == kCFNotFound) {
			namespace = CFStringCreateMutableCopy(NULL, 0, CFSTR("std"));
			command = CFStringCreateMutableCopy(NULL, 0, rawcommand);
		} else {
			CFStringRef ns = CFStringCreateWithSubstring(NULL, rawcommand, CFRangeMake(0, namespaceSep.location));
			namespace = CFStringCreateMutableCopy(NULL, 0, ns);
			CFRelease(ns);
			ns = CFStringCreateWithSubstring(NULL, rawcommand,
											 CFRangeMake(namespaceSep.location+namespaceSep.length,
														 CFStringGetLength(rawcommand)-(namespaceSep.location+namespaceSep.length)));
			command = CFStringCreateMutableCopy(NULL, 0, ns);
			CFRelease(ns);
		}
		
		// Replace all "/" with ".".
		CFStringFindAndReplace(namespace, CFSTR("/"), CFSTR("."), CFRangeMake(0, CFStringGetLength(namespace)), 0);
		// Replace all non-alphabetic characters with _.
		CFCharacterSetRef nonalphaset = CFCharacterSetCreateInvertedSet(NULL, CFCharacterSetGetPredefined(kCFCharacterSetAlphaNumeric));
		CFRange curRange = CFRangeMake(0, CFStringGetLength(command));
		CFRange foundRange;
		while (CFStringFindCharacterFromSet(command, nonalphaset, curRange, 0, &foundRange)) {
			CFStringReplace(command, foundRange, CFSTR("_"));
			curRange.length = curRange.length + curRange.location - foundRange.location - foundRange.length + 1;
			curRange.location = foundRange.location + 1;
		}
		CFRelease(nonalphaset);
		
		// Try to find cached funcptr.
		if (_loadedSyms == NULL) {
			CFMutableDictionaryRef _tmpLoadedSyms = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, NULL);
			if (!OSAtomicCompareAndSwapPtrBarrier(NULL, _tmpLoadedSyms, (void*volatile*)&_loadedSyms))
				CFRelease(_tmpLoadedSyms);
		}
		void(*actionFunc)(CFArrayRef);
		
		CFStringRef commandcopy = CFStringCreateCopy(NULL, command);
		CFStringAppend(command, CFSTR("`"));
		CFStringAppend(command, namespace);
		
		// Funcptr not cached yet. Try to load the dylib.
		if (!CFDictionaryGetValueIfPresent(_loadedSyms, command, (const void**)&actionFunc)) {
			if (_loadedLibs == NULL) {
				CFMutableDictionaryRef _tmpLoadedLibs = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, NULL);
				if (!OSAtomicCompareAndSwapPtrBarrier(NULL, _tmpLoadedLibs, (void*volatile*)&_loadedLibs))
					CFRelease(_tmpLoadedLibs);
			}
			
			// Dylib not cached yet. Try to load it.
			void* handle;
			if (!CFDictionaryGetValueIfPresent(_loadedLibs, namespace, (const void**)&handle)) {
				CFStringRef path = CFStringCreateWithFormat(NULL, 0, CFSTR(INXRoot"/Action Providers/%@.dylib"), namespace);
				INXCopyCString(ns, path);
				handle = dlopen(INXSTR(ns), RTLD_LAZY|RTLD_LOCAL|RTLD_FIRST);
				INXFreeCString(ns);
				CFDictionaryAddValue(_loadedLibs, namespace, handle);
			}
			
			if (handle == NULL)
				CFLog(kCFLogLevelWarning, CFSTR("iNotifyEx: Action provider module '%@' cannot be loaded."), namespace);
			else {
				INXCopyCString(cmd, commandcopy);
				actionFunc = (void(*)(CFArrayRef))dlsym(handle, INXSTR(cmd));
				INXFreeCString(cmd);
				
				CFDictionaryAddValue(_loadedSyms, command, actionFunc);
			}
		}
		
		if (actionFunc == NULL) {
			CFLog(kCFLogLevelWarning, CFSTR("iNotifyEx: Action '%@.%@' not found."), namespace, command);
		} else {
			actionFunc(argv);
		}
		
		CFRelease(commandcopy);
		CFRelease(command);
		CFRelease(namespace);
	}
	CFRelease(argv);
}

#endif
