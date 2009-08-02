/*

iKeyEx3.m ... iKeyEx hooking interface.
 
Copyright (c) 2009, KennyTM~
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

#if TARGET_IPHONE_SIMULATOR
#define IKX_SCRAP_PATH @"/Users/kennytm/XCodeProjects/iKeyEx/svn/trunk/hk.kennytm.iKeyEx3/deb/var/mobile/Library/Keyboard"
#define IKX_LIB_PATH @"/Users/kennytm/XCodeProjects/iKeyEx/svn/trunk/hk.kennytm.iKeyEx3/deb/Library/iKeyEx"
#else
#define IKX_SCRAP_PATH @"/var/mobile/Library/Keyboard"
#define IKX_LIB_PATH @"/Library/iKeyEx"
#endif

// Use substrate.h on iPhoneOS, and APELite on x86/ppc for debugging.
#ifdef __arm__
#import <substrate.h>
#elif __i386__ || __ppc__
extern void* APEPatchCreate(const void* original, const void* replacement);
#define MSHookFunction(original, replacement, result) (*(result) = APEPatchCreate((original), (replacement)))
#else
#error Not supported in non-ARM/i386/PPC system.
#endif

#define DefineHook(rettype, funcname, ...) \
rettype funcname (__VA_ARGS__); \
static rettype (*original_##funcname) (__VA_ARGS__); \
static rettype replaced_##funcname (__VA_ARGS__)

#define InstallHook(funcname) MSHookFunction(&funcname, &replaced_##funcname, &original_##funcname)

#import <Foundation/Foundation.h>
#import <pthread.h>

//------------------------------------------------------------------------------

static BOOL IKXIsInternalMode(NSString* modeString) {
	return [modeString hasPrefix:@"iKeyEx3."];
}

static NSDictionary* _IKXConfigDictionary;
static pthread_mutex_t _IKXConfigDictionaryLock = PTHREAD_MUTEX_INITIALIZER;
static NSDictionary* IKXConfigDictionary() {
	pthread_mutex_lock(&_IKXConfigDictionaryLock);
	if (_IKXConfigDictionary == nil)
		_IKXConfigDictionary = [[NSDictionary alloc] initWithContentsOfFile:IKX_SCRAP_PATH@"/iKeyEx3-Config.plist"];
	pthread_mutex_unlock(&_IKXConfigDictionaryLock);
	return _IKXConfigDictionary;
}

static void IKXFlushConfigDictionary() {
	pthread_mutex_lock(&_IKXConfigDictionaryLock);
	[_IKXConfigDictionary release];
	_IKXConfigDictionary = nil;
	pthread_mutex_unlock(&_IKXConfigDictionaryLock);
}

//------------------------------------------------------------------------------

static NSString* IKXLayoutReference(NSString* modeString) {
	return [[[IKXConfigDictionary() objectForKey:@"modes"] objectForKey:modeString] objectForKey:@"layout"];
}

static NSBundle* IKXLayoutBundle(NSString* layoutReference) {
	return [NSBundle bundleWithPath:[NSString stringWithFormat:IKX_LIB_PATH@"/Keyboards/%@.keyboard", layoutReference]];
}

//------------------------------------------------------------------------------

DefineHook(BOOL, UIKeyboardInputModeUsesKBStar, NSString* modeString) {
	static CFMutableDictionaryRef cache = NULL;
	
	if (IKXIsInternalMode(modeString))
		return original_UIKeyboardInputModeUsesKBStar(modeString);
	else {
		if (cache == NULL)
			cache = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, NULL);
		
		int retval;
		if (CFDictionaryGetValueIfPresent(cache, modeString, (const void**)&retval))
			return retval;
		
		NSString* layoutRef = IKXLayoutReference(modeString);
		if ([layoutRef characterAtIndex:0] == '=')	// Refered layout.
			retval = original_UIKeyboardInputModeUsesKBStar([layoutRef substringFromIndex:1]);
		else {
			NSString* layoutClass = [IKXLayoutBundle(layoutRef) objectForInfoDictionaryKey:@"UIKeyboardLayoutClass"];
			if (![layoutClass isKindOfClass:[NSString class]])	// Portrait & Landscape are different. 
				retval = NO;
			else if ([layoutClass characterAtIndex:0] == '=')	// Refered layout.
				retval = original_UIKeyboardInputModeUsesKBStar([layoutClass substringFromIndex:1]);
			else	// layout.plist & star.keyboards both use KBStar. otherwise it is custom code.
				retval = [layoutClass rangeOfString:@"."].location != NSNotFound;
		}
		
		CFDictionarySetValue(cache, modeString, (const void*)retval);
		return retval;
	}
}

//------------------------------------------------------------------------------

DefineHook(Class, UIKeyboardLayoutClassForInputModeInOrientation, NSString* modeString, NSString* orientation) {
	static NSMutableDictionary* portrait_cache = nil, *landscape_cache = nil;
	
	if (IKXIsInternalMode(modeString))
		return original_UIKeyboardLayoutClassForInputModeInOrientation(modeString, orientation);
	
	else {
		BOOL isLandscape = [orientation isEqualToString:@"Landscape"];
		
		if (portrait_cache == nil)
			portrait_cache = [NSMutableDictionary new];
		if (landscape_cache == nil)
			landscape_cache = [NSMutableDictionary new];
		
		Class retval = [(isLandscape ? landscape_cache : portrait_cache) objectForKey:modeString];
		if (retval != Nil)
			return retval;
		
		NSString* layoutRef = IKXLayoutReference(modeString);
		if ([layoutRef characterAtIndex:0] == '=')	// Refered layout.
			retval = original_UIKeyboardLayoutClassForInputModeInOrientation([layoutRef substringFromIndex:1], orientation);
		else {
			NSBundle* layoutBundle = IKXLayoutBundle(layoutRef);
			id layoutClass = [layoutBundle objectForInfoDictionaryKey:@"UIKeyboardLayoutClass"];
			if ([layoutClass isKindOfClass:[NSDictionary class]])	// Portrait & Landscape are different. 
				layoutClass = [layoutClass objectForKey:orientation];
			
			if ([layoutClass characterAtIndex:0] == '=')	// Refered layout.
				retval = original_UIKeyboardLayoutClassForInputModeInOrientation([layoutClass substringFromIndex:1], orientation);
			else if ([layoutClass rangeOfString:@"."].location == NSNotFound) {	// Just a class.
				[layoutBundle load];
				retval = NSClassFromString(layoutClass);
			} else
				retval = [UIKeyboardLayoutStar class];
		}
	}
}

//------------------------------------------------------------------------------

void initialize () {
	InstallHook(UIKeyboardInputModeUsesKBStar);
	InstallHook(UIKeyboardLayoutClassForInputModeInOrientation);
}