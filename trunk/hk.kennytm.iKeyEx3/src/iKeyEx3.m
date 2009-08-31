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
#import <substrate2.h>
#import "CMLSelection.h"
#import <objc/message.h>
#import <WebCore/wak/WebCoreThread.h>
#include <pthread.h>

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
				
				return [NSString stringWithFormat:@"iKeyEx:%@-%@-%@", layoutRef, orientation, typeName[type]];
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

struct createKeyboardLayoutArgs {
	NSData* retData;
	NSBundle* bundle;
	NSString* keyboardName;
	NSString* expectedPath;
};

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
				retData = [NSData dataWithContentsOfFile:keyboardPath];
			} else if ([layoutClass hasSuffix:@".plist"]) {
//				UIProgressHUD* hud = IKXShowLoadingHUD();	
				
				NSString* layoutPath = [bundle pathForResource:layoutClass ofType:nil];
				NSMutableDictionary* layoutDict = [NSMutableDictionary dictionaryWithContentsOfFile:layoutPath];
				if (orientation == nil)
					orientation = extractOrientation(keyboardName, lastDash);
				UIKBKeyboard* keyboard = IKXUIKBKeyboardFromLayoutPlist(layoutDict, [keyboardName substringFromIndex:lastDash+1], [@"Landscape" isEqualToString:orientation]);
				NSMutableData* dataToSave = [NSMutableData data];
				NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:dataToSave];
				[archiver encodeObject:keyboard forKey:@"keyboard"];
				[archiver finishEncoding];
				[dataToSave writeToFile:expectedPath atomically:NO];
				[archiver release];
				retData = dataToSave;
				
//				IKXHideLoadingHUD(hud);
			}
		}
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
	BOOL hasLongAction = [@"International" isEqualToString:key.interactionType];
	if (!hasLongAction) {
		NSString* input = key.representedString;
		if ([input hasPrefix:@"<"] && [input hasSuffix:@">"] && ![input isEqualToString:@"<Esc>"])
			hasLongAction = YES;
	}
	return Original(UIKeyboardLayoutStar_downActionFlagsForKey_)(self, _cmd, key) | (hasLongAction ? 0x80 : 0);
}

DefineObjCHook(unsigned, UIKeyboardLayoutRoman_downActionFlagsForKey_, UIKeyboardLayoutRoman* self, SEL _cmd, void* key) {
	return Original(UIKeyboardLayoutRoman_downActionFlagsForKey_)(self, _cmd, key) | ([self typeForKey:key] == 7 ? 0x80 : 0);
}

static int longPressedInternationalKey = 0;

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

static CFMutableDictionaryRef cachedColors = NULL;

DefineHook(UIKBThemeRef, UIKBThemeCreate, UIKBKeyboard* keyboard, UIKBKey* key, int x) {
	UIKBThemeRef theme = Original(UIKBThemeCreate)(keyboard, key, x);
	if (theme != NULL) {
		NSDictionary* traits = [key.attributes valueForName:@"iKeyEx:traits"];
		if (traits != nil) {
			NSString* font = [traits objectForKey:@"font"];
			if (font != nil)
				theme->fontName = (CFStringRef)font;
			
			NSArray* color = [traits objectForKey:@"color"];
			if (color != nil) {
				NSUInteger componentsCount = [color count];
				if (componentsCount != 0) {
					CGColorRef newColor = (CGColorRef)CFDictionaryGetValue(cachedColors, color);
					if (newColor == NULL) {
						CGFloat components[4] = {1, 1, 1, 1};
						CGColorSpaceRef space = NULL;

						switch (componentsCount) {
							case 2:
								components[1] = [[color objectAtIndex:0] floatValue];
							case 1:
								space = CGColorSpaceCreateDeviceGray();
								components[0] = [[color objectAtIndex:0] floatValue];
								break;
						
							default:
								components[3] = [[color objectAtIndex:3] floatValue];
							case 3:
								space = CGColorSpaceCreateDeviceRGB();
								components[0] = [[color objectAtIndex:0] floatValue];
								components[1] = [[color objectAtIndex:1] floatValue];
								components[2] = [[color objectAtIndex:2] floatValue];
								break;
						}
						
						newColor = CGColorCreate(space, components);
						CFDictionarySetValue(cachedColors, color, newColor);
						CGColorRelease(newColor);
					}
					theme->symbolColor = newColor;
				}
			}
			
			id sizeScale = [traits objectForKey:@"size"];
			if (sizeScale != nil) {
				CGFloat size = [sizeScale floatValue];
				if (size <= 0)
					size = 1;
				theme->fontSize *= size;
				if (theme->fontSize < theme->minFontSize)
					theme->minFontSize = theme->fontSize;
			}
		}
	}
	return theme;
}

//------------------------------------------------------------------------------

typedef NSString* (*ControlAction) (id<UIKeyboardInput> delegate, UIKeyboardImpl* impl, NSString* input);

static void moveSelectionPointTo(id<UIKeyboardInput> delegate, UIKeyboardImpl* impl, CGFloat offset, CGFloat y_multiple) {
	CGRect curRect = [(UIDefaultKeyboardInput*)delegate caretRect];
	CGRect newLoc = CGRectMake(curRect.origin.x, curRect.origin.y + offset + y_multiple * curRect.size.height, 1, 1);
	if ([delegate isKindOfClass:[UIView class]]) {
		[impl prepareForSelectionChange];
		
		[impl setSelectionWithPoint:newLoc.origin];
		[[(UIView*)delegate _scroller] scrollRectToVisible:newLoc animated:YES];
	} else {
		WebThreadLock();
		[(DOMNode*)delegate setSelectionWithPoint:newLoc.origin];
//		[delegate scrollIntoViewIfNeeded:YES];
		WebThreadUnlock();
	}
}

static NSString* caEsc  (id<UIKeyboardInput> delegate, UIKeyboardImpl* impl, NSString* input) {
	if ([delegate isKindOfClass:[UIResponder class]])
		[(UIResponder*)delegate resignFirstResponder];
	return nil;
}
static NSString* caLeft (id<UIKeyboardInput> delegate, UIKeyboardImpl* impl, NSString* input) {
	NSRange curRange = getSelection(delegate, NULL);
	if (curRange.location != NSNotFound) {
		if (curRange.length != 0) {
			curRange.length = 0;
		} else
			curRange.location --;
		if (curRange.location >= 0)
			setSelection(delegate, curRange);
	}
	return nil;
}
static NSString* caRight(id<UIKeyboardInput> delegate, UIKeyboardImpl* impl, NSString* input) {
	NSRange curRange = getSelection(delegate, NULL);
	if (curRange.location != NSNotFound) {
		if (curRange.length != 0) {
			curRange.location += curRange.length;
			curRange.length = 0;
		} else
			curRange.location ++;
		if (curRange.location <= [delegate.text length])
			setSelection(delegate, curRange);
	}
	return nil;
}
static NSString* caUp   (id<UIKeyboardInput> delegate, UIKeyboardImpl* impl, NSString* input) {
	moveSelectionPointTo(delegate, impl, 0, -1);
	return nil;
}
static NSString* caDown (id<UIKeyboardInput> delegate, UIKeyboardImpl* impl, NSString* input) {
	moveSelectionPointTo(delegate, impl, 1, 1);
	return nil;	
}
static NSString* caHome (id<UIKeyboardInput> delegate, UIKeyboardImpl* impl, NSString* input) {
	setSelection(delegate, NSMakeRange(0, 0));
	return nil;
}
static NSString* caEnd  (id<UIKeyboardInput> delegate, UIKeyboardImpl* impl, NSString* input) {
	setSelection(delegate, NSMakeRange([delegate.text length], 0));
	return nil;
}
static NSString* caDel  (id<UIKeyboardInput> delegate, UIKeyboardImpl* impl, NSString* input) {
	NSRange curRange = getSelection(delegate, NULL);
	if (curRange.length == 0) {
		if (curRange.location >= [delegate.text length])
			return nil;
		++ curRange.location;
		setSelection(delegate, curRange);
	}
	[impl handleDelete];
	return nil;
}
static NSString* caPgUp (id<UIKeyboardInput> delegate, UIKeyboardImpl* impl, NSString* input) {
	CGFloat frameHeight = 1;
	if ([delegate isKindOfClass:[UIView class]])
		frameHeight = ((UIView*)delegate).superview.frame.size.height;
	moveSelectionPointTo(delegate, impl, -frameHeight, 0);
	return nil;	
}
static NSString* caPgDn (id<UIKeyboardInput> delegate, UIKeyboardImpl* impl, NSString* input) {
	CGFloat frameHeight = 1;
	if ([delegate isKindOfClass:[UIView class]])
		frameHeight = ((UIView*)delegate).superview.frame.size.height;
	moveSelectionPointTo(delegate, impl, frameHeight, 1);
	return nil;
}
static NSString* caKP   (id<UIKeyboardInput> delegate, UIKeyboardImpl* impl, NSString* input) {
	NSString* actualString = [input substringWithRange:NSMakeRange(2, [input length]-3)];
	if ([@"Enter" isEqualToString:actualString]) return @"\n";
	else if ([@"Plus" isEqualToString:actualString]) return @"+";
	else if ([@"Minus" isEqualToString:actualString]) return @"-";
	else if ([@"Multiply" isEqualToString:actualString]) return @"*";
	else if ([@"Divide" isEqualToString:actualString]) return @"/";
	else if ([@"Point" isEqualToString:actualString]) return @".";
	else return actualString;
}
static NSString* caApp  (id<UIKeyboardInput> delegate, UIKeyboardImpl* impl, NSString* input) {
	[[UIMenuController sharedMenuController] setMenuVisible:YES animated:YES];
	return nil;
}
static NSString* caShift(id<UIKeyboardInput> delegate, UIKeyboardImpl* impl, NSString* input) {
	[impl toggleShift];
	return nil;
}

static NSString* const keys[] = {
@"<Esc>",	// = \x1B
@"<Up>", @"<Down>", @"<Left>", @"<Right>",
@"<F1>", @"<F2>", @"<F3>", @"<F4>", @"<F5>", @"<F6>", @"<F7>", @"<F8>", @"<F9>", @"<F10>", @"<F11>", @"<F12>",
@"<Home>", @"<End>", @"<Insert>", @"<Del>", @"<PageUp>", @"<PageDown>",
@"<k0>", @"<k1>", @"<k2>", @"<k3>", @"<k4>", @"<k5>", @"<k6>", @"<k7>", @"<k8>", @"<k9>",
@"<kPlus>", @"<kMinus>", @"<kMultiply>", @"<kDivide>", @"<kPoint>", @"<kEnter>",
@"<ShiftL>", @"<ShiftR>", @"<CtrlL>", @"<CtrlR>", @"<AltL>", @"<AltR>", @"<MetaL>", @"<MetaR>",
@"<WinL>", @"<WinR>", @"<App>",
@"<SuperL>", @"<SuperR>", @"<HyperL>", @"<HyperR>", @"<CapsLock>", @"<PrintScreen>", @"<Pause>", @"<ScrollLock>",
};

#define CSI @"\x1B["
#define SS3 @"\x1BO"

static NSString* const keyANSI[] = {
@"\x1B",
CSI@"A", CSI@"B", CSI@"D", CSI@"C",
SS3@"P", SS3@"Q", SS3@"R", SS3@"S", CSI@"15~", CSI@"17~", CSI@"18~", CSI@"19~", CSI@"20~", CSI@"21~", CSI@"23~", CSI@"24~",
CSI@"1~", CSI@"4~", CSI@"2~", CSI@"3~", CSI@"5~", CSI@"6~",
SS3@"p", SS3@"q", SS3@"r", SS3@"s", SS3@"t", SS3@"u", SS3@"v", SS3@"w", SS3@"x", SS3@"y",
@"+", SS3@"m", @"*", @"/", SS3@"n", SS3@"M",
@"<ShiftL>", @"<ShiftR>", @"[CTRL]", @"[CTRL]", @"<AltL>", @"<AltR>", @"<MetaL>", @"<MetaR>",
@"<WinL>", @"<WinR>", @"<App>",
@"<SuperL>", @"<SuperR>", @"<HyperL>", @"<HyperR>", @"<CapsLock>", @"<PrintScreen>", @"<Pause>", @"<ScrollLock>",
};

#undef CSI
#undef SS3

static NSString* const keyX11[] = {
@"\uFF1B",
@"\uFF52", @"\uFF54", @"\uFF51", @"\uFF53",
@"\uFFBE", @"\uFFBF", @"\uFFC0", @"\uFFC1", @"\uFFC2", @"\uFFC3", @"\uFFC4", @"\uFFC5", @"\uFFC6", @"\uFFC7", @"\uFFC8", @"\uFFC9",
@"\uFF50", @"\uFF57", @"\uFF63", @"\uFFFF", @"\uFF55", @"\uFF56",
@"\uFFB0", @"\uFFB1", @"\uFFB2", @"\uFFB3", @"\uFFB4", @"\uFFB5", @"\uFFB6", @"\uFFB7", @"\uFFB8", @"\uFFB9",
@"\uFFBA", @"\uFFAD", @"\uFFAA", @"\uFFAF", @"\uFFAE", @"\uFF8D",
@"\uFFE1", @"\uFFE2", @"\uFFE3", @"\uFFE4", @"\uFFE9", @"\uFFEA", @"\uFFE7", @"\uEEE8",
@"\uFF5B", @"\uFF5C", @"\uFF5D",
@"\uFFEB", @"\uFFEC", @"\uFFED", @"\uFFEE", @"\uFFE5", @"\uFF61", @"\uFF13", @"\uFF14",
};

static ControlAction const keyNormal[] = {
caEsc,
caUp, caDown, caLeft, caRight,
NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 
caHome, caEnd, NULL, caDel, caPgUp, caPgDn,
caKP, caKP, caKP, caKP, caKP, caKP, caKP, caKP, caKP, caKP, 
caKP, caKP, caKP, caKP, caKP, caKP, 
caShift, caShift, NULL, NULL, NULL, NULL, NULL, NULL, 
NULL, NULL, caApp,
NULL, NULL, NULL, NULL, caShift, NULL, NULL, NULL,
};

//-------------------------------------------------------------------------------------------------------------------------------------------

static CFRunLoopTimerRef delayTimer = NULL;
static NSString* sendControlAction(id<UIKeyboardInput> delegate, UIKeyboardImpl* impl, NSString* input, UIKBKey* key);

struct sendControlActionProxyStruct {
	id<UIKeyboardInput> delegate;
	UIKeyboardImpl* impl;
	NSString* input;
	UIKBKey* key;
};

static void sendControlActionProxy (CFRunLoopTimerRef timer, struct sendControlActionProxyStruct* info) {
	if (delayTimer)
		sendControlAction(info->delegate, info->impl, info->input, info->key);
}

static NSString* sendControlAction(id<UIKeyboardInput> delegate, UIKeyboardImpl* impl, NSString* input, UIKBKey* key) {	
	IKXAppType appType = IKXAppTypeOfCurrentApplication();
	if (appType == IKXAppTypeANSI) {
		static CFDictionaryRef ctrlAnsiTable = NULL;
		if (!ctrlAnsiTable)
			ctrlAnsiTable = CFDictionaryCreate(NULL, (const void**)keys, (const void**)keyANSI, sizeof(keys)/sizeof(keys[0]), &kCFTypeDictionaryKeyCallBacks, NULL);
		NSString* actualString = (NSString*)CFDictionaryGetValue(ctrlAnsiTable, input);
		if (actualString != nil) {
			UIApplication* termapp = [UIApplication sharedApplication];
			if ([termapp respondsToSelector:@selector(handleInputFromMenu:)]) {
				objc_msgSend(termapp, @selector(handleInputFromMenu:), actualString);
				return nil;
			} else
				return actualString;
		}	
	} else if (appType == IKXAppTypeX11) {
		static CFDictionaryRef ctrlVncTable = NULL;
		if (!ctrlVncTable)
			ctrlVncTable = CFDictionaryCreate(NULL, (const void**)keys, (const void**)keyX11, sizeof(keys)/sizeof(keys[0]), &kCFTypeDictionaryKeyCallBacks, NULL);
		NSString* actualString = (NSString*)CFDictionaryGetValue(ctrlVncTable, input);
		if (actualString != nil)
			return actualString;
	} else {
		static CFDictionaryRef ctrlNormalTable = NULL;
		if (ctrlNormalTable == NULL)
			ctrlNormalTable = CFDictionaryCreate(NULL, (const void**)keys, (const void**)keyNormal, sizeof(keys)/sizeof(keys[0]), &kCFTypeDictionaryKeyCallBacks, NULL);
		ControlAction action = CFDictionaryGetValue(ctrlNormalTable, input);
		if (action != nil)
			return action(delegate, impl, input);
	}
	return input;
}

DefineObjCHook(void, UIKeyboardLayoutStar_sendStringAction_forKey_, UIKeyboardLayoutStar* self, SEL _cmd, NSString* input, UIKBKey* key) {
	if (delayTimer) {
		CFRunLoopTimerRef oldTimer = delayTimer;
		delayTimer = NULL;
		
		CFRunLoopTimerContext ctx;
		ctx.version = 0;
		CFRunLoopTimerGetContext(oldTimer, &ctx);
		struct sendControlActionProxyStruct* st = (struct sendControlActionProxyStruct*)ctx.info;
		if (st) {
			[st->delegate release];
			[st->impl release];
			[st->input release];
			[st->key release];
			free(st);
		}
		
		CFRunLoopTimerInvalidate(oldTimer);
		CFRelease(oldTimer);
		return;
	}
	
	if ([input hasPrefix:@"<"] && [input hasSuffix:@">"]) {
		UIKeyboardImpl* impl = [UIKeyboardImpl sharedInstance];
		id<UIKeyboardInput> del = [impl delegate];
		input = sendControlAction(del, impl, input, key);
		if (input == nil)
			return;
	}
	Original(UIKeyboardLayoutStar_sendStringAction_forKey_)(self, _cmd, input, key);
}

DefineObjCHook(void, UIKeyboardLayoutStar_longPressAction, UIKeyboardLayoutStar* self, SEL _cmd) {
	UIKBKey* activeKey = [self activeKey];
	if (activeKey != nil && [@"International" isEqualToString:activeKey.interactionType]) {
		longPressedInternationalKey = 1;
		[self cancelTouchTracking];
	} else {
		NSString* input = activeKey.representedString;
		if ([input hasPrefix:@"<"] && [input hasSuffix:@">"]) {
			UIKeyboardImpl* impl = [UIKeyboardImpl sharedInstance];
			id<UIKeyboardInput> delegate = [impl delegate];
			
			struct sendControlActionProxyStruct* st = malloc(sizeof(struct sendControlActionProxyStruct));
			st->delegate = [delegate retain];
			st->impl = [impl retain];
			st->input = [input retain];
			st->key = [activeKey retain];
			CFRunLoopTimerContext ctx;
			memset(&ctx, 0, sizeof(ctx));
			ctx.info = st;
			delayTimer = CFRunLoopTimerCreate(NULL, CFAbsoluteTimeGetCurrent(), 0.125, 0, 0, (CFRunLoopTimerCallBack)sendControlActionProxy, &ctx);
			CFRunLoopAddTimer(CFRunLoopGetMain(), delayTimer, kCFRunLoopDefaultMode);
		} else
			Original(UIKeyboardLayoutStar_longPressAction)(self, _cmd);
	}
}

//------------------------------------------------------------------------------

#if TARGET_IPHONE_SIMULATOR
#define N_ARM_THUMB_DEF 0
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
	
	cachedColors = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
	
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
	InstallHook(UIKBThemeCreate);
	
	Class UIKeyboardLayoutStar_class = objc_getClass("UIKeyboardLayoutStar");
	Class UIKeyboardLayoutRoman_class = [UIKeyboardLayoutRoman class];
	Class UIKeyboardImpl_class = [UIKeyboardImpl class];
	
	InstallObjCInstanceHook(UIKeyboardLayoutStar_class, @selector(downActionFlagsForKey:), UIKeyboardLayoutStar_downActionFlagsForKey_);
	InstallObjCInstanceHook(UIKeyboardLayoutRoman_class, @selector(downActionFlagsForKey:), UIKeyboardLayoutRoman_downActionFlagsForKey_);
	InstallObjCInstanceHook(UIKeyboardLayoutStar_class, @selector(longPressAction), UIKeyboardLayoutStar_longPressAction);
	InstallObjCInstanceHook(UIKeyboardLayoutRoman_class, @selector(longPressAction), UIKeyboardLayoutRoman_longPressAction);
	InstallObjCInstanceHook(UIKeyboardImpl_class, @selector(setInputModeToNextInPreferredList), UIKeyboardImpl_setInputModeToNextInPreferredList);
	
	InstallObjCInstanceHook(UIKeyboardLayoutStar_class, @selector(sendStringAction:forKey:), UIKeyboardLayoutStar_sendStringAction_forKey_);
		
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