/*

LocalizationStatusHelper.c ... Print the translation status of each localizations in a bundle.

Copyright (C) 2009  KennyTM~

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

#include <CoreFoundation/CoreFoundation.h>
#include <unistd.h>
#include <stdio.h>
#include <dirent.h>

static void addKeysToSet (CFStringRef keys, void* values, CFMutableSetRef context) {
	CFSetAddValue(context, keys);
}

struct languagesAndKeys {
	CFMutableArrayRef languages;
	CFMutableArrayRef keys;
	CFIndex count;
};

static void printHeader(CFStringRef language, void* context) {
	char* ptr = (char*)CFStringGetCStringPtr(language, kCFStringEncodingUTF8);
	if (ptr == NULL) {
		CFIndex langLen = CFStringGetLength(language);
		ptr = alloca(langLen*4);
		CFStringGetCString(language, ptr, langLen*4, kCFStringEncodingUTF8);
	}
	printf(" *%s* ||", ptr);
}
static void printLeftCol(CFStringRef key) {
	char* ptr = (char*)CFStringGetCStringPtr(key, kCFStringEncodingUTF8);
	if (ptr == NULL) {
		CFIndex langLen = CFStringGetLength(key);
		ptr = alloca(langLen*4);
		CFStringGetCString(key, ptr, langLen*4, kCFStringEncodingUTF8);
	}
	printf("|| %s ||", ptr);
}

static void printTickIfExists(CFSetRef keySet, CFStringRef key) {
	if (CFSetGetValue(keySet, key) != NULL)
		printf(" \xE2\x9C\x93 ||");
	else
		printf(" ||");
}

static void printSupportedLanguages(CFStringRef key, struct languagesAndKeys* context) {
	printLeftCol(key);
	CFArrayApplyFunction(context->keys, CFRangeMake(0, context->count), (CFArrayApplierFunction)&printTickIfExists, (void*)key);
	printf("\n");
}



int main (int argc, const char* argv[]) {
	if (argc == 1) {
		printf("Usage: LocalizationStatusHelper <bundle-path>\n");
	} else {
		if (chdir(argv[1]) == -1) {
			printf("Cannot change directory to %s", argv[1]);
			perror("");
			return 0;
		}
		
		DIR* dir = opendir(".");
		if (dir == NULL) {
			printf("Cannot open %s for reading", argv[1]);
			perror("");
			return 0;
		}
		
		struct languagesAndKeys sk;
		
		sk.languages = CFArrayCreateMutable(NULL, 0, &kCFTypeArrayCallBacks);
		sk.keys = CFArrayCreateMutable(NULL, 0, &kCFTypeArrayCallBacks);
		
		CFMutableSetRef unionKeys = CFSetCreateMutable(NULL, 0, &kCFTypeSetCallBacks);
		
		struct dirent* dp;
		// Scan for the directory.
		while ((dp = readdir(dir)) != NULL) {
			if (dp->d_type == DT_DIR) {
				CFStringRef dirName = CFStringCreateWithCString(NULL, dp->d_name, kCFStringEncodingUTF8);
				
				// Check if it's an lproj.
				if (CFStringHasSuffix(dirName, CFSTR(".lproj"))) {
					CFMutableSetRef langKeys = CFSetCreateMutable(NULL, 0, &kCFTypeSetCallBacks);
					
					// Scan for strings files.
					chdir(dp->d_name);
					DIR* subdir = opendir(".");
					if (subdir != NULL) {
						struct dirent* dp2;
						while ((dp2 = readdir(subdir)) != NULL) {
							// Ignore linked strings files.
							if (dp2->d_type == DT_REG) {
								CFStringRef stringsName = CFStringCreateWithCString(NULL, dp2->d_name, kCFStringEncodingUTF8);
								// Ignore non-strings files.
								if (CFStringHasSuffix(stringsName, CFSTR(".strings"))) {
									// Convert to 
									CFURLRef stringsURL = CFURLCreateWithFileSystemPath(NULL, stringsName, kCFURLPOSIXPathStyle, false);
									CFReadStreamRef stringsStream = CFReadStreamCreateWithFile(NULL, stringsURL);
									CFRelease(stringsURL);
									CFReadStreamOpen(stringsStream);
									CFPropertyListRef strings = CFPropertyListCreateFromStream(NULL, stringsStream, 0, kCFPropertyListImmutable, NULL, NULL);
									CFReadStreamClose(stringsStream);
									CFRelease(stringsStream);
									CFDictionaryApplyFunction(strings, (CFDictionaryApplierFunction)&addKeysToSet, langKeys);
									CFDictionaryApplyFunction(strings, (CFDictionaryApplierFunction)&addKeysToSet, unionKeys);
									CFRelease(strings);
								}
								CFRelease(stringsName);
							}
						}
						closedir(subdir);
					}
					chdir("..");
					
					CFStringRef langCode = CFStringCreateWithSubstring(NULL, dirName, CFRangeMake(0, CFStringGetLength(dirName)-6));
					CFArrayAppendValue(sk.languages, langCode);
					CFArrayAppendValue(sk.keys, langKeys);
					CFRelease(langKeys);
					CFRelease(langCode);
				}
				CFRelease(dirName);
			}
		}
		closedir(dir);
		
		sk.count = CFArrayGetCount(sk.languages);
		
		printf("|| *Key* ||");
		CFArrayApplyFunction(sk.languages, CFRangeMake(0, sk.count), (CFArrayApplierFunction)&printHeader, NULL);
		printf("\n");
		
		CFSetApplyFunction(unionKeys, (CFSetApplierFunction)&printSupportedLanguages, &sk);
		
		CFRelease(sk.keys);
		CFRelease(sk.languages);
		CFRelease(unionKeys);
	}
	
	return 0;
}