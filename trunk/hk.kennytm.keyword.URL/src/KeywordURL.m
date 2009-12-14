/*

KeywordURL.m ... Default URLs to Google's "I'm Feeling Lucky".
Copyright (C) 2009  KennyTM~ <kennytm@gmail.com>

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
#import <Foundation/Foundation.h>
#import <substrate2.h>

// gcc-iphone -dynamiclib KeywordURL.m -o ../deb/Library/MobileSubstrate/DynamicLibraries/hk.kennytm.KeywordURL.dylib -lsubstrate -I/Developer/Platforms/iPhoneOS.platform/Developer/usr/include -framework Foundation

static const CFStringRef KeywordURLKey = CFSTR("keyword.URL");
static const CFStringRef PrefixesKey = CFSTR("Prefixes");

static CFURLRef createMorePossibleURL(CFStringRef str) {
	CFMutableStringRef retval = NULL;
	
	CFMutableStringRef mstr = CFStringCreateMutableCopy(NULL, 0, str);
	CFStringTrimWhitespace(mstr);
	CFCharacterSetRef slashOrSpace = CFCharacterSetCreateWithCharactersInString(NULL, CFSTR(" \t/"));
	CFRange rFirstSpace;
	if (CFStringFindCharacterFromSet(mstr, slashOrSpace, CFRangeMake(0, CFStringGetLength(mstr)), 0, &rFirstSpace)) {
		CFStringRef prefix = CFStringCreateWithSubstring(NULL, mstr, CFRangeMake(0, rFirstSpace.location));
		CFDictionaryRef pfDict = CFPreferencesCopyAppValue(PrefixesKey, kCFPreferencesCurrentApplication);
		CFStringRef pdTemplate = NULL;
		if (pfDict == NULL) {
			static CFStringRef const key = CFSTR("en");
			static CFStringRef const value = CFSTR("http://en.wikipedia.org/w/index.php?title=Special%3ASearch&go=Go&search=");
			CFDictionaryRef popDict = CFDictionaryCreate(NULL, (const void**)&key, (const void**)&value, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
			CFPreferencesSetAppValue(PrefixesKey, popDict, kCFPreferencesCurrentApplication);
			CFRelease(popDict);
			if (CFEqual(key, prefix))
				pdTemplate = value;
		} else
			pdTemplate = CFDictionaryGetValue(pfDict, prefix);
		if (pdTemplate != NULL) {
			CFStringDelete(mstr, CFRangeMake(0, rFirstSpace.location+rFirstSpace.length));
			CFStringTrimWhitespace(mstr);
			CFStringRef escapedStr = CFURLCreateStringByAddingPercentEscapes(NULL, mstr, NULL, CFSTR("=@$&+;:,/?"), kCFStringEncodingUTF8);
			retval = CFStringCreateMutableCopy(NULL, 0, pdTemplate);
			CFStringAppend(retval, escapedStr);
			CFRelease(escapedStr);
		}
		if (pfDict)
			CFRelease(pfDict);
		CFRelease(prefix);
	}
	
	if (retval == NULL) {
		CFStringRef kwTemplate = CFPreferencesCopyAppValue(KeywordURLKey, kCFPreferencesCurrentApplication);
		if (kwTemplate == NULL)
			kwTemplate = CFRetain(CFSTR("http://www.google.com/search?btnI=1&q="));
		CFStringRef escapedStr = CFURLCreateStringByAddingPercentEscapes(NULL, mstr, NULL, CFSTR("=@$&+;:,/?"), kCFStringEncodingUTF8);
		retval = CFStringCreateMutableCopy(NULL, 0, kwTemplate);
		CFStringAppend(retval, escapedStr);
		CFRelease(escapedStr);
		CFRelease(kwTemplate);
	}
	CFRelease(mstr);
	
	if (retval) {
		CFURLRef url = CFURLCreateWithString(NULL, retval, NULL);
		CFRelease(retval);
		return url;
	} else {
		return NULL;
	}

}

DefineObjCHook(CFArrayRef, NSString_possibleURLsForUserTypedString, CFStringRef self, SEL _cmd) {
	CFArrayRef old = Original(NSString_possibleURLsForUserTypedString)(self, _cmd);
	CFMutableArrayRef old2;
	if (old == NULL || CFArrayGetCount(old) == 0)
		old2 = CFArrayCreateMutable(NULL, 0, &kCFTypeArrayCallBacks);
	else
		old2 = CFArrayCreateMutableCopy(NULL, 0, old);
	
	CFURLRef morePossible = createMorePossibleURL(self);
	if (morePossible) {
		if (CFArrayGetCount(old2) == 0)
			CFArrayInsertValueAtIndex(old2, 0, morePossible);
		else
			CFArrayInsertValueAtIndex(old2, 1, morePossible);
	}
	
	CFRelease(morePossible);
	
	return (CFArrayRef)[(id)old2 autorelease];
}

__attribute__((constructor))
static void init() {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	InstallObjCInstanceHook([NSString class], @selector(possibleURLsForUserTypedString), NSString_possibleURLsForUserTypedString);
	[pool drain];
}
