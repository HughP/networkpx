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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit2.h>
#import "UIKBKeyboardFromLayoutPlist.h"
#import <objc/runtime.h>
#import "libiKeyEx.h"
#import <mach-o/nlist.h>
#import "IKXCinInputManager.h"

// Use substrate.h on iPhoneOS, and APELite on x86/ppc for debugging.
#ifdef __arm__
#import <substrate.h>
#define REGPARM3 
#elif __i386__ || __ppc__
extern void* APEPatchCreate(const void* original, const void* replacement);
#define MSHookFunction(original, replacement, result) (*(result) = APEPatchCreate((original), (replacement)))
IMP MSHookMessage(Class _class, SEL sel, IMP imp, const char* prefix);
#define REGPARM3 __attribute__((regparm(3)))
#else
#error Not supported in non-ARM/i386/PPC system.
#endif

#define Original(funcname) original_##funcname

#define DefineHook(rettype, funcname, ...) \
rettype funcname (__VA_ARGS__); \
static rettype (*original_##funcname) (__VA_ARGS__); \
static rettype replaced_##funcname (__VA_ARGS__)

#define DefineObjCHook(rettype, funcname, ...) \
static rettype (*original_##funcname) (__VA_ARGS__); \
static rettype replaced_##funcname (__VA_ARGS__)

#define DefineHiddenHook(rettype, funcname, ...) \
static rettype (*funcname) (__VA_ARGS__); \
REGPARM3 static rettype (*original_##funcname) (__VA_ARGS__); \
REGPARM3 static rettype replaced_##funcname (__VA_ARGS__)

int lookup_function_pointers(const char* filename, ...);

#define InstallHook(funcname) MSHookFunction(funcname, replaced_##funcname, (void**)&original_##funcname)
#define InstallObjCInstanceHook(cls, sel, delimited_name) original_##delimited_name = (void*)MSHookMessage(cls, sel, (IMP)replaced_##delimited_name, NULL)
#define InstallObjCClassHook(cls, sel, delimited_name) original_##delimited_name = (void*)method_setImplementation(class_getClassMethod(cls, sel), (IMP)replaced_##delimited_name)

extern NSString* UIKeyboardDynamicDictionaryFile(NSString* mode);

UIKBKeyboard* (*UIKBGetKeyboardByName)(NSString* name);

//------------------------------------------------------------------------------

DefineHook(BOOL, UIKeyboardInputModeUsesKBStar, NSString* modeString) {
	if (!IKXIsiKeyExMode(modeString))
		return Original(UIKeyboardInputModeUsesKBStar)(modeString);
	else {
		NSString* layoutRef = IKXLayoutReference(modeString);
		if ([layoutRef characterAtIndex:0] == '=')	// Refered layout.
			return Original(UIKeyboardInputModeUsesKBStar)([layoutRef substringFromIndex:1]);
		else {
			NSString* layoutClass = [IKXLayoutBundle(layoutRef) objectForInfoDictionaryKey:@"UIKeyboardLayoutClass"];
			if (![layoutClass isKindOfClass:[NSString class]])	// Portrait & Landscape are different. 
				return NO;
			else if ([layoutClass characterAtIndex:0] == '=')	// Refered layout.
				return Original(UIKeyboardInputModeUsesKBStar)([layoutClass substringFromIndex:1]);
			else	// layout.plist & star.keyboards both use KBStar. otherwise it is custom code.
				return [layoutClass rangeOfString:@"."].location != NSNotFound;
		}
	}
}

//------------------------------------------------------------------------------

DefineHook(Class, UIKeyboardLayoutClassForInputModeInOrientation, NSString* modeString, NSString* orientation) {
	if (!IKXIsiKeyExMode(modeString))
		return Original(UIKeyboardLayoutClassForInputModeInOrientation)(modeString, orientation);
	
	else {
		NSString* layoutRef = IKXLayoutReference(modeString);		
		if ([layoutRef characterAtIndex:0] == '=')	// Refered layout.
			return Original(UIKeyboardLayoutClassForInputModeInOrientation)([layoutRef substringFromIndex:1], orientation);
		else {
			NSBundle* layoutBundle = IKXLayoutBundle(layoutRef);
			id layoutClass = [layoutBundle objectForInfoDictionaryKey:@"UIKeyboardLayoutClass"];
			if ([layoutClass isKindOfClass:[NSDictionary class]])	// Portrait & Landscape are different. 
				layoutClass = [layoutClass objectForKey:orientation];
			
			if ([layoutClass characterAtIndex:0] == '=')	// Refered layout.
				return Original(UIKeyboardLayoutClassForInputModeInOrientation)([layoutClass substringFromIndex:1], orientation);
			else if ([layoutClass rangeOfString:@"."].location == NSNotFound) {	// Just a class.
				BOOL loaded = [layoutBundle load];
				
				Class retval = NSClassFromString(layoutClass);
				if (retval != Nil)
					return retval;
				retval = [layoutBundle principalClass];
				if (retval != Nil)
					return retval;
				NSLog(@"iKeyEx: Layout class '%@' not found. (loaded=%d)", layoutClass, loaded);
			} else
				NSLog(@"iKeyEx: Unknown layout class.");
				
			// Note: UIKeyboardLayoutQWERTY[Landscape] crashes the simulator.
			return objc_getClass("UIKeyboardLayoutEmoji");
		}
	}
}

//------------------------------------------------------------------------------

DefineHook(NSString*, UIKeyboardGetKBStarKeyboardName, NSString* mode, NSString* orientation, UIKeyboardType type, UIKeyboardAppearance appearance) {
	if (type == UIKeyboardTypeNumberPad || type == UIKeyboardTypePhonePad || !IKXIsiKeyExMode(mode))
		return Original(UIKeyboardGetKBStarKeyboardName)(mode, orientation, type, appearance);
	else {
		NSString* layoutRef = IKXLayoutReference(mode);
		if ([layoutRef characterAtIndex:0] == '=')	// Refered layout
			return Original(UIKeyboardGetKBStarKeyboardName)([layoutRef substringFromIndex:1], orientation, type, appearance);
		else {
			NSBundle* layoutBundle = IKXLayoutBundle(layoutRef);
			id layoutClass = [layoutBundle objectForInfoDictionaryKey:@"UIKeyboardLayoutClass"];
			if ([layoutClass isKindOfClass:[NSDictionary class]])	// Portrait & Landscape are different. 
				layoutClass = [layoutClass objectForKey:orientation];
			
			if ([layoutClass characterAtIndex:0] == '=')	// Refered layout.
				return Original(UIKeyboardGetKBStarKeyboardName)([layoutClass substringFromIndex:1], orientation, type, appearance);
			else {
				// iPhone-orient-mode-type
				static NSString* const typeName[] = {
					@"",
					@"",
					@"",
					@"URL",
					@"NumberPad",
					@"PhonePad",
					@"NamePhonePad",
					@"Email"
				};
				
				return [NSString stringWithFormat:@"%@-%@-%@", mode, orientation, typeName[type]];
			}
		}
	}
}

//------------------------------------------------------------------------------

// Note: this function is also cross-refed by UIKeyboardInputManagerClassForInputMode & UIKeyboardStaticUnigramsFilePathForInputModeAndFileExtension
// Let's hope no other input managers use this function...
DefineHook(NSBundle*, UIKeyboardBundleForInputMode, NSString* mode) {
	if (!IKXIsiKeyExMode(mode))
		return Original(UIKeyboardBundleForInputMode)(mode);
	else {
		NSString* layoutRef = IKXLayoutReference(mode);
		if ([layoutRef characterAtIndex:0] == '=')
			return Original(UIKeyboardBundleForInputMode)([layoutRef substringFromIndex:1]);
		else
			return IKXLayoutBundle(layoutRef);
	}
}

//------------------------------------------------------------------------------

static NSString* extractOrientation (NSString* keyboardName, unsigned lastDash) {
	unsigned secondLastDash = [keyboardName rangeOfString:@"-" options:NSBackwardsSearch range:NSMakeRange(0, lastDash)].location;
	return [keyboardName substringWithRange:NSMakeRange(secondLastDash+1, lastDash-secondLastDash-1)];
}

static NSString* standardizedKeyboardName (NSString* keyboardName) {
	// The keyboardName is now in the form iKeyEx:Colemak-Portrait-Email.
	// We need to convert it to iPhone-Portrait-QWERTY-Email.keyboard.
	unsigned lastDash = [keyboardName rangeOfString:@"-" options:NSBackwardsSearch].location;
	NSString* orientation = extractOrientation(keyboardName, lastDash);
	if (lastDash == [keyboardName length])
		return [NSString stringWithFormat:@"iPhone-%@-QWERTY", orientation];
	else
		return [NSString stringWithFormat:@"iPhone-%@-QWERTY-%@", orientation, [keyboardName substringFromIndex:lastDash+1]];
}

DefineHiddenHook(NSData*, GetKeyboardDataFromBundle, NSString* keyboardName, NSBundle* bundle) {
	if (!IKXIsiKeyExMode(keyboardName))
		return Original(GetKeyboardDataFromBundle)(keyboardName, bundle);
	else {
		NSString* expectedPath = [NSString stringWithFormat:IKX_SCRAP_PATH@"/iKeyEx::cache::layout::%@.keyboard", keyboardName];
		NSData* retData = [NSData dataWithContentsOfFile:expectedPath];
		if (retData == nil) {
			NSString* layoutClass = [bundle objectForInfoDictionaryKey:@"UIKeyboardLayoutClass"];
			unsigned lastDash = [keyboardName rangeOfString:@"-" options:NSBackwardsSearch].location;
			NSString* orientation = nil;
			if ([layoutClass isKindOfClass:[NSDictionary class]])
				layoutClass = [(NSDictionary*)layoutClass objectForKey:(orientation = extractOrientation(keyboardName, lastDash))];
			
			if ([layoutClass hasSuffix:@".keyboards"]) {
				NSString* keyboardPath = [NSString stringWithFormat:@"%@/%@/%@.keyboard", [bundle resourcePath], layoutClass, standardizedKeyboardName(keyboardName)];
				NSFileManager* fman = [NSFileManager defaultManager];
				if ([fman fileExistsAtPath:keyboardPath])
					[fman linkItemAtPath:keyboardPath toPath:expectedPath error:NULL];
				return [NSData dataWithContentsOfFile:keyboardPath];
			} else if ([layoutClass hasSuffix:@".plist"]) {
				NSString* layoutPath = [bundle pathForResource:layoutClass ofType:nil];
				NSMutableDictionary* layoutDict = [NSMutableDictionary dictionaryWithContentsOfFile:layoutPath];
				if (orientation == nil)
					orientation = extractOrientation(keyboardName, lastDash);
				UIKBKeyboard* keyboard = IKXUIKBKeyboardFromLayoutPlist(layoutDict, [keyboardName substringFromIndex:lastDash], [@"Landscape" isEqualToString:orientation]);
				NSMutableData* dataToSave = [NSMutableData data];
				NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:dataToSave];
				[archiver encodeObject:keyboard forKey:@"keyboard"];
				[archiver finishEncoding];
				[dataToSave writeToFile:expectedPath atomically:NO];
				[archiver release];
				return dataToSave;
			} else
				return nil;
		} else
			return retData;
	}
}

//------------------------------------------------------------------------------

DefineHook(Class, UIKeyboardInputManagerClassForInputMode, NSString* mode) {
	if (!IKXIsiKeyExMode(mode))
		return Original(UIKeyboardInputManagerClassForInputMode)(mode);
	else {
		NSString* imeRef = IKXInputManagerReference(mode);
		if ([imeRef characterAtIndex:0] == '=')	// Refered IME.
			return Original(UIKeyboardInputManagerClassForInputMode)([imeRef substringFromIndex:1]);
		else {
			NSBundle* imeBundle = IKXInputManagerBundle(imeRef);
			NSString* imeClass = [imeBundle objectForInfoDictionaryKey:@"UIKeyboardInputManagerClass"];
			if ([imeClass characterAtIndex:0] == '=')	// Refered IME.
				return Original(UIKeyboardInputManagerClassForInputMode)([imeClass substringFromIndex:1]);
			else if ([imeClass hasSuffix:@".cin"]) {
				return [IKXCinInputManager class];
			} else	// class name
				return (imeClass != nil) ? [imeBundle classNamed:imeClass] : [imeBundle principalClass];
		}
	}
}

//------------------------------------------------------------------------------

NSString* UIKeyboardUserDirectory();
DefineHook(NSString*, UIKeyboardDynamicDictionaryFile, NSString* mode) {
	if (!IKXIsiKeyExMode(mode))
		return Original(UIKeyboardDynamicDictionaryFile)(mode);
	else {
		NSString* imeRef = IKXInputManagerReference(mode);
		if ([imeRef characterAtIndex:0] == '=')	// Refered IME.
			return Original(UIKeyboardDynamicDictionaryFile)([imeRef substringFromIndex:1]);
		else {
			NSString* imeClass = [IKXInputManagerBundle(imeRef) objectForInfoDictionaryKey:@"UIKeyboardInputManagerClass"];
			if ([imeClass characterAtIndex:0] == '=')	// Refered IME.
				return Original(UIKeyboardDynamicDictionaryFile)([imeRef substringFromIndex:1]);
			else 
				return [UIKeyboardUserDirectory() stringByAppendingPathComponent:@"dynamic-text.dat"];
		}
	}
}

//------------------------------------------------------------------------------

DefineHook(NSString*, UIKeyboardStaticUnigramsFilePathForInputModeAndFileExtension, NSString* mode, NSString* ext) {
	if (!IKXIsiKeyExMode(mode))
		return Original(UIKeyboardStaticUnigramsFilePathForInputModeAndFileExtension)(mode, ext);
	else {
		NSString* imeRef = IKXInputManagerReference(mode);
		if ([imeRef characterAtIndex:0] == '=')	// Refered IME.
			return Original(UIKeyboardStaticUnigramsFilePathForInputModeAndFileExtension)([imeRef substringFromIndex:1], ext);
		else {
			NSString* imeClass = [IKXInputManagerBundle(imeRef) objectForInfoDictionaryKey:@"UIKeyboardInputManagerClass"];
			if ([imeClass characterAtIndex:0] == '=')	// Refered IME.
				return Original(UIKeyboardStaticUnigramsFilePathForInputModeAndFileExtension)([imeRef substringFromIndex:1], ext);
			else 
				return Original(UIKeyboardStaticUnigramsFilePathForInputModeAndFileExtension)(@"en_US", ext);
		}
	}
}

//------------------------------------------------------------------------------

static CFDictionaryRef GetOriginalVariants(NSString* str);

DefineHook(CFDictionaryRef, UIKeyboardRomanAccentVariants, NSString* str, NSString* lang) {
	NSString* curMode = UIKeyboardGetCurrentInputMode();
	if (!IKXIsiKeyExMode(curMode)) {
		return Original(UIKeyboardRomanAccentVariants)(str, lang);
	} else {
		static CFMutableDictionaryRef cache = NULL;
		
		if (cache == NULL)
			cache = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
		CFMutableDictionaryRef dict = NULL;
		if (CFDictionaryGetValueIfPresent(cache, curMode, (const void**)&dict)) {
			if (dict == NULL)
				return nil;
			else {
				CFDictionaryRef retval = CFDictionaryGetValue(dict, str);
				if (retval == NULL) {
					retval = GetOriginalVariants(str);
					CFDictionaryAddValue(dict, str, retval);
				}
				return retval == (CFDictionaryRef)kCFNull ? NULL : retval;
			}
			
		} else {
			NSString* layoutRef = IKXLayoutReference(curMode);
			if ([layoutRef characterAtIndex:0] == '=')
				return Original(UIKeyboardRomanAccentVariants)(str, [curMode substringFromIndex:1]);
			
			NSBundle* bundle = IKXLayoutBundle(layoutRef);
			NSString* path = [bundle pathForResource:@"variants" ofType:@"plist"];
			NSDictionary* rawDict = [NSDictionary dictionaryWithContentsOfFile:path];
			CFMutableDictionaryRef resDict = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
			
			for (NSString* key in rawDict) {
				NSMutableArray* keycaps = [NSMutableArray array];
				NSMutableArray* strings = [NSMutableArray array];
				for (id x in [rawDict objectForKey:key]) {
					if ([x isKindOfClass:[NSArray class]]) {
						[keycaps addObject:[x objectAtIndex:0]];
						[strings addObject:[x objectAtIndex:1]];
					} else {
						[keycaps addObject:x];
						[strings addObject:x];
					}
				}
				NSDictionary* keyDict = [NSDictionary dictionaryWithObjectsAndKeys:keycaps, @"Keycaps", strings, @"Strings", @"right", @"Direction", nil];
				CFDictionarySetValue(resDict, key, keyDict);
			}
			CFDictionaryAddValue(cache, curMode, resDict);
			CFRelease(resDict);
			
			CFDictionaryRef retval = CFDictionaryGetValue(resDict, str);
			if (retval == NULL) {
				retval = GetOriginalVariants(str);
				CFDictionaryAddValue(resDict, str, retval);
			}
			return retval == (CFDictionaryRef)kCFNull ? NULL : retval;
		}
	}
}

static CFDictionaryRef GetOriginalVariants(NSString* str) {
	NSObject* locObj = UIKeyboardLocalizedObject([NSString stringWithFormat:@"Roman-Accent-%@", str], nil, nil, nil);
	if ([locObj isKindOfClass:[NSDictionary class]]) {
		CFDictionaryRef retval = Original(UIKeyboardRomanAccentVariants)(str, @"en");
		if (retval != NULL)
			return retval;
	}
	return (CFDictionaryRef)kCFNull;
}

//------------------------------------------------------------------------------

DefineHook(NSString*, UIKeyboardLocalizedInputModeName, NSString* mode) {
	if (!IKXIsiKeyExMode(mode))
		return Original(UIKeyboardLocalizedInputModeName)(mode);
	else
		return IKXNameOfMode(mode);
}

//------------------------------------------------------------------------------

DefineHook(BOOL, UIKeyboardLayoutDefaultTypeForInputModeIsASCIICapable, NSString* mode) {
	if (!IKXIsiKeyExMode(mode))
		return Original(UIKeyboardLayoutDefaultTypeForInputModeIsASCIICapable)(mode);
	else
		return YES;
}

//------------------------------------------------------------------------------

DefineObjCHook(unsigned, UIKeyboardLayoutStar_downActionFlagsForKey_, UIKeyboardLayoutStar* self, SEL _cmd, UIKBKey* key) {
	return Original(UIKeyboardLayoutStar_downActionFlagsForKey_)(self, _cmd, key) | ([@"International" isEqualToString:key.interactionType] ? 0x80 : 0);
}

DefineObjCHook(unsigned, UIKeyboardLayoutRoman_downActionFlagsForKey_, UIKeyboardLayoutRoman* self, SEL _cmd, void* key) {
	return Original(UIKeyboardLayoutRoman_downActionFlagsForKey_)(self, _cmd, key) | ([self typeForKey:key] == 7 ? 0x80 : 0);
}

static int longPressedInternationalKey = 0;
DefineObjCHook(void, UIKeyboardLayoutStar_longPressAction, UIKeyboardLayoutStar* self, SEL _cmd) {
	UIKBKey* activeKey = [self activeKey];
	if (activeKey != nil && [@"International" isEqualToString:activeKey.interactionType]) {
		longPressedInternationalKey = 1;
		[self cancelTouchTracking];
	} else
		Original(UIKeyboardLayoutStar_longPressAction)(self, _cmd);
}

DefineObjCHook(void, UIKeyboardLayoutRoman_longPressAction, UIKeyboardLayoutRoman* self, SEL _cmd) {
	void* activeKey = [self activeKey];
	if (activeKey != NULL && [self typeForKey:activeKey] == 7) {
		longPressedInternationalKey = 1;
		[self cancelTouchTracking];
	} else
		Original(UIKeyboardLayoutRoman_longPressAction)(self, _cmd);
}

DefineObjCHook(void, UIKeyboardImpl_setInputModeToNextInPreferredList, UIKeyboardImpl* self, SEL _cmd) {
	if (longPressedInternationalKey == IKXKeyboardChooserPreference()) {
		[self setInputModeLastChosenPreference];
		[self setInputMode:@"iKeyEx:__KeyboardChooser"];
	} else
		Original(UIKeyboardImpl_setInputModeToNextInPreferredList)(self, _cmd);
	longPressedInternationalKey = 0;
}

//------------------------------------------------------------------------------

DefineHiddenHook(id, LookupLocalizedObject, NSString* key, NSString* mode, id unknown, id unknown2) {
	if (key == nil)
		return nil;
	if (mode == nil)
		mode = UIKeyboardGetCurrentInputMode();
	if (!IKXIsiKeyExMode(mode))
		return Original(LookupLocalizedObject)(key, mode, unknown, unknown2);
	else {
		static CFMutableDictionaryRef cache = NULL;
		if (cache == NULL)
			cache = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
		
		NSString* layoutRef = IKXLayoutReference(mode);
		CFTypeRef modeDict = CFDictionaryGetValue(cache, mode);
		BOOL isReferedLayout = [layoutRef characterAtIndex:0] == '=';
		
		if (modeDict == NULL) {
			if (isReferedLayout) {
				modeDict = [layoutRef substringFromIndex:1];
				CFDictionaryAddValue(cache, mode, modeDict);
			} else {
				NSBundle* bundle = IKXLayoutBundle(layoutRef);
				NSString* stringsPath = [bundle pathForResource:@"strings" ofType:@"plist"];
				modeDict = (CFDictionaryRef)[NSDictionary dictionaryWithContentsOfFile:stringsPath] ?: (CFDictionaryRef)kCFNull;
				CFDictionaryAddValue(cache, mode, modeDict);
			}
		}
		
		if (modeDict == kCFNull)
			return Original(LookupLocalizedObject)(key, isReferedLayout ? [layoutRef substringFromIndex:1] : nil, unknown, unknown2);
		else if (CFGetTypeID(modeDict) == CFStringGetTypeID())
			return Original(LookupLocalizedObject)(key, (NSString*)modeDict, unknown, unknown2);
		else
			return (id)CFDictionaryGetValue(modeDict, key) ?: Original(LookupLocalizedObject)(key, isReferedLayout ? [layoutRef substringFromIndex:1] : nil, unknown, unknown2);
	}
}

//------------------------------------------------------------------------------

DefineHook(NSArray*, UIKeyboardGetSupportedInputModes) {
	return [Original(UIKeyboardGetSupportedInputModes)() arrayByAddingObjectsFromArray:[[IKXConfigDictionary() objectForKey:@"modes"] allKeys]];
}

//------------------------------------------------------------------------------

#if TARGET_IPHONE_SIMULATOR
void nlist(const char*, struct nlist[]);
#endif

static void fixInputMode () {
	if ([@"iKeyEx:__KeyboardChooser" isEqualToString:UIKeyboardGetCurrentInputMode()]) {
		UIKeyboardImpl* impl = [UIKeyboardImpl sharedInstance];
		[impl setInputMode:[impl inputModeLastChosen]];
	}
}

void initialize () {
	NSAutoreleasePool* pool = [NSAutoreleasePool new];
	
	struct nlist nl[4];
	memset(nl, 0, sizeof(nl));
	nl[0].n_un.n_name = "_GetKeyboardDataFromBundle";
	nl[1].n_un.n_name = "_UIKBGetKeyboardByName";
	nl[2].n_un.n_name = "_LookupLocalizedObject";
	nlist([[[NSBundle bundleForClass:[UIApplication class]] executablePath] UTF8String], nl);
	GetKeyboardDataFromBundle = (void*)(nl[0].n_value + (nl[0].n_desc & N_ARM_THUMB_DEF ? 1 : 0));
	UIKBGetKeyboardByName = (void*)(nl[1].n_value + (nl[0].n_desc & N_ARM_THUMB_DEF ? 1 : 0));
	LookupLocalizedObject = (void*)(nl[2].n_value + (nl[0].n_desc & N_ARM_THUMB_DEF ? 1 : 0));
	
	InstallHook(UIKeyboardInputModeUsesKBStar);
	InstallHook(UIKeyboardLayoutClassForInputModeInOrientation);
	InstallHook(GetKeyboardDataFromBundle);
	InstallHook(UIKeyboardGetKBStarKeyboardName);
	InstallHook(UIKeyboardBundleForInputMode);
	InstallHook(UIKeyboardInputManagerClassForInputMode);
	InstallHook(UIKeyboardDynamicDictionaryFile);
	InstallHook(UIKeyboardStaticUnigramsFilePathForInputModeAndFileExtension);
	InstallHook(UIKeyboardRomanAccentVariants);
	InstallHook(UIKeyboardLocalizedInputModeName);
	InstallHook(UIKeyboardLayoutDefaultTypeForInputModeIsASCIICapable);
	InstallHook(LookupLocalizedObject);
	InstallHook(UIKeyboardGetSupportedInputModes);
	
	Class UIKeyboardLayoutStar_class = objc_getClass("UIKeyboardLayoutStar");
	Class UIKeyboardLayoutRoman_class = [UIKeyboardLayoutRoman class];
	Class UIKeyboardImpl_class = [UIKeyboardImpl class];
	
	InstallObjCInstanceHook(UIKeyboardLayoutStar_class, @selector(downActionFlagsForKey:), UIKeyboardLayoutStar_downActionFlagsForKey_);
	InstallObjCInstanceHook(UIKeyboardLayoutRoman_class, @selector(downActionFlagsForKey:), UIKeyboardLayoutRoman_downActionFlagsForKey_);
	InstallObjCInstanceHook(UIKeyboardLayoutStar_class, @selector(longPressAction), UIKeyboardLayoutStar_longPressAction);
	InstallObjCInstanceHook(UIKeyboardLayoutRoman_class, @selector(longPressAction), UIKeyboardLayoutRoman_longPressAction);
	InstallObjCInstanceHook(UIKeyboardImpl_class, @selector(setInputModeToNextInPreferredList), UIKeyboardImpl_setInputModeToNextInPreferredList);
	
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL,
									(CFNotificationCallback)IKXFlushConfigDictionary,
									CFSTR("hk.kennytm.iKeyEx3.FlushConfigDictionary"),
									NULL, CFNotificationSuspensionBehaviorDrop);
	CFNotificationCenterAddObserver(CFNotificationCenterGetLocalCenter(), NULL,
									(CFNotificationCallback)fixInputMode,
									CFSTR("UIApplicationWillTerminateNotification"),
									NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
	
	[pool drain];
}