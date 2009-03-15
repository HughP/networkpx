/*

SBHooker-iKeyEx.m ... Global Hooker for iKeyEx.
 
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

#import <UIKit2/UIKeyboardImpl.h>
#import <UIKit2/UIKeyboardInputManager.h>
#import <UIKit2/UIKeyboardSublayout.h>
#import <UIKit2/UIKeyboardLayoutRoman.h>
#import <UIKit2/UIAccentedCharacterView.h>
#import <UIKit2/Functions.h>
#import <UIKit/UIStringDrawing.h>
#import <iKeyEx/KeyboardLoader.h>
#import <iKeyEx/common.h>
#import <iKeyEx/UIKBStandardKeyboardLayout.h>
#import <iKeyEx/UIAccentedCharacterView-setStringWidth.h>
#import <substrate.h>

//------------------------------------------------------------------------------
#pragma mark -
#pragma mark Warning-Disabling Protocol
//------------------------------------------------------------------------------

@protocol IDisableWarnings
@optional
-(id)old_initWithFrame:(CGRect)frame variants:(NSArray*)array expansion:(int)exp orientation:(int)ori;
-(void)old_showPopupVariantsForKey:(UIKeyDefinition*)keydef;
-(UIKeyDefinitionDownActionFlag)old_downActionFlagsForKey:(UIKeyDefinition*)key;
@end

//------------------------------------------------------------------------------
#pragma mark -
#pragma mark Interfaces
//------------------------------------------------------------------------------

// This class defines +sharedInstanceForInputMode: which will be swapped
// with UIKeyboardInputManager's one for providing custom input manager.
@interface UIKeyboardInputManagerHooked : UIKeyboardInputManager
+(UIKeyboardInputManager*)sharedInstanceForInputMode:(NSString*)mode;
@end

// This class defines -initWithFrame:variants:expansion:orientation: which will
// be hooked to UIAccentedCharacterView's one for providing custom variants.
@interface UIAccentedCharacterViewHooked : UIAccentedCharacterView<IDisableWarnings>
-(id)initWithFrame:(CGRect)frame variants:(NSArray*)array expansion:(int)exp orientation:(int)ori;
@end

// These classes provide custom variants.
@interface UIKeyboardLayoutRomanHooked : UIKeyboardLayoutRoman<IDisableWarnings>
-(void)showPopupVariantsForKey:(UIKeyDefinition*)keydef;
-(UIKeyDefinitionDownActionFlag)downActionFlagsForKey:(UIKeyDefinition*)key;
@end


//------------------------------------------------------------------------------
#pragma mark -
#pragma mark Global variables
//------------------------------------------------------------------------------

static NSString* currentMode = nil;			// Current input mode name, if layout is refered.
static NSString* currentOrigMode = nil;		// Refered mode name.

//------------------------------------------------------------------------------
#pragma mark -
#pragma mark Hookers
//------------------------------------------------------------------------------

// Hook for providing custom input managers.
@implementation UIKeyboardInputManagerHooked
+(UIKeyboardInputManager*)sharedInstanceForInputMode:(NSString*)mode{
	if ([mode hasPrefix:iKeyEx_Prefix]) {
		return [KeyboardBundle bundleWithModeName:mode].manager;
	} else
		return [UIKeyboardInputManagerHooked sharedInstanceForInputMode:mode];
}
@end

// Hook for providing custom layout classes.
MSHook(Class, UIKeyboardLayoutClassForInputModeInOrientation, NSString* mode, NSString* orient) {
	if (currentOrigMode != nil) {
		[currentMode release];
		[currentOrigMode release];
		currentMode = nil;
		currentOrigMode = nil;
	}
	
	if ([mode hasPrefix:iKeyEx_Prefix]) {
		KeyboardBundle* cont = [KeyboardBundle bundleWithModeName:mode];
		BOOL landsc = [orient isEqualToString:@"Landscape"];
		NSString* origMode = [KeyboardBundle referedLayoutClassForMode:mode];
		if (origMode != mode) {
			currentMode = [mode copy];
			currentOrigMode = [origMode copy];
			return _UIKeyboardLayoutClassForInputModeInOrientation(origMode, orient);
		} else
			return [cont layoutClassWithLandscape:landsc];
	} else {
		return _UIKeyboardLayoutClassForInputModeInOrientation(mode, orient);
	}
};

// Make sure refered layouts are shown correctly.
// note: MSHookFunction crashes if I hook the higher-tier UIKeyboardImageWithName instead :S
MSHook(NSBundle*, UIKeyboardBundleForInputMode, NSString* mode) {
	if (currentOrigMode != nil && [currentMode isEqualToString:mode])
		return _UIKeyboardBundleForInputMode(currentOrigMode);
	else
		return _UIKeyboardBundleForInputMode(mode);
};

// Display the correct name of the input mode on the space bar.
MSHook(NSString*, UIKeyboardLocalizedInputModeName, NSString* mode) {
	if ([mode hasPrefix:iKeyEx_Prefix]) {
		return [KeyboardBundle bundleWithModeName:mode].displayName;
	} else {
		return _UIKeyboardLocalizedInputModeName(mode);
	}
};

// Avoid the intl keyboard suddenly pop up
MSHook(BOOL, UIKeyboardLayoutDefaultTypeForInputModeIsASCIICapable, NSString* mode) {
	if ([mode hasPrefix:iKeyEx_Prefix])
		return YES;
	else
		return _UIKeyboardLayoutDefaultTypeForInputModeIsASCIICapable(mode);
}

// Take care of the WordTries
MSHook(NSString*, UIKeyboardStaticUnigramsFilePathForInputModeAndFileExtension, NSString* mode, NSString* ext) {
	if ([mode hasPrefix:iKeyEx_Prefix]) {
		NSString* refMode = [KeyboardBundle referedManagerClassForMode:mode];
		if (refMode != mode) {
			return _UIKeyboardStaticUnigramsFilePathForInputModeAndFileExtension(refMode, ext);
		} else
			return @"";
	} else
		return _UIKeyboardStaticUnigramsFilePathForInputModeAndFileExtension(mode, ext);
}
MSHook(NSString*, UIKeyboardDynamicDictionaryFile, NSString* mode) {
	if ([mode hasPrefix:iKeyEx_Prefix]) {
		NSString* refMode = [KeyboardBundle referedManagerClassForMode:mode];
		if (refMode != mode) {
			return _UIKeyboardDynamicDictionaryFile(refMode);
		} else
			return [UIKeyboardUserDirectory() stringByAppendingPathComponent:@"dynamic-text.dat"];
	} else
		return _UIKeyboardDynamicDictionaryFile(mode);
}

//------------------------------------------------------------------------------
#pragma mark -
#pragma mark Hookers for Custom Variants
//------------------------------------------------------------------------------

static NSString* lastLongPressedKey = nil;	// Record last long-pressed key.

@implementation UIKeyboardLayoutRomanHooked
// Save last long-pressed key.
-(void)showPopupVariantsForKey:(UIKeyDefinition*)key {
	lastLongPressedKey = [self inputStringForKey:key];
	[self old_showPopupVariantsForKey:key];
}

// Hook for allowing long-press actions when custom variants are present.
-(UIKeyDefinitionDownActionFlag)downActionFlagsForKey:(UIKeyDefinition*)key {
	UIKeyDefinitionDownActionFlag retFlag = [self old_downActionFlagsForKey:key];
	NSString* mode = UIKeyboardGetCurrentInputMode();
	if ([mode hasPrefix:iKeyEx_Prefix]) {
		if ([[KeyboardBundle bundleWithModeName:mode] variantsForString:[self inputStringForKey:key]] != nil)
			retFlag |= UIKeyFlagHasLongPressAction | UIKeyFlagURLDomainVariants;
	}
	return retFlag;
}
@end

// Hook for providing custom variants.
@implementation UIAccentedCharacterViewHooked
-(id)initWithFrame:(CGRect)frame variants:(NSArray*)array expansion:(int)exp orientation:(int)ori {
	int isExp = exp;
	NSArray* actualArr = array;
	NSUInteger halfCount = [actualArr count]/2;
	BOOL isLandscape = (ori == 90 || ori == -90);
	CGFloat newWidth = isLandscape ? 47 : 32;
	CGFloat mismatchCompensation = isLandscape ? 32 : 9;
	CGFloat maxWidth = [UIKeyboardImpl defaultSizeForOrientation:ori].width;
	
	NSString* mode = UIKeyboardGetCurrentInputMode();
	BOOL is_iKeyExKeyboard = [mode hasPrefix:iKeyEx_Prefix];
	if (is_iKeyExKeyboard) {
		actualArr = [[KeyboardBundle bundleWithModeName:mode] variantsForString:lastLongPressedKey];
		if (actualArr == nil)
			actualArr = array;
		else {
			// reset exp.
			isExp = exp = 0;
			halfCount = [actualArr count];
			
			NSMutableArray* dispArr = [[NSMutableArray alloc] initWithCapacity:halfCount];
			NSMutableArray* actArr = [[NSMutableArray alloc] initWithCapacity:halfCount];
			
			UIFont* varFont = [UIFont boldSystemFontOfSize:12];
			for (NSString* obj in actualArr) {
				NSString* dispString = obj;
				if ([dispString isKindOfClass:[NSArray class]]) {
					dispString = [obj objectAtIndex:0];
					[actArr addObject:[obj objectAtIndex:1]];
					[dispArr addObject:dispString];
				} else {
					[actArr addObject:obj];
					[dispArr addObject:obj];
				}
				// increase the string width if necessary.
				CGFloat thisWidth = [dispString sizeWithFont:varFont].width + 16;
				if (thisWidth > newWidth)
					newWidth = thisWidth;
			}
						
			actualArr = [actArr arrayByAddingObjectsFromArray:dispArr];
			[actArr release];
			[dispArr release];
			
			// decrease the string width if necessary.
			if (newWidth * halfCount > maxWidth)
				newWidth = maxWidth / halfCount;
		}
		// this is to fix a crashing bug in 2.2 when expansion = 0 and the
		// variants list overflow the screen.
		// Also make things list in the correct direction.
		if (exp == 0) {
			CGFloat occupiedSize = newWidth * (halfCount + 0.5);
			if (frame.origin.x + occupiedSize > maxWidth) {
				isExp = 1;
				// reverse the actual array if exp is changed.
				NSMutableArray* newArray = [actualArr mutableCopy];
				for (NSUInteger i = 0; i < halfCount/2; ++ i) {
					[newArray exchangeObjectAtIndex:i withObjectAtIndex:halfCount-1-i];
					[newArray exchangeObjectAtIndex:halfCount+i withObjectAtIndex:2*halfCount-1-i];
				}
				actualArr = newArray;
			}
		}
		
		
		if ([actualArr count] > 0) {
			NSString* firstString = [actualArr objectAtIndex:0];
			if ([firstString length] > 0) {
				unichar firstChar = [firstString characterAtIndex:0];
				if (firstChar == '.' || firstChar == '?' || firstChar == '!' || firstChar == ',' || firstChar == '\'')
					frame.origin.x += mismatchCompensation;
			}
		}
	}
	
		
	UIAccentedCharacterView* newSelf = [self old_initWithFrame:frame variants:actualArr expansion:isExp orientation:ori];
	
	if (is_iKeyExKeyboard) {
		if (isExp != exp && isExp == 1)
			[actualArr release];
		
		// the predefined m_stringWidth is too short! increase it.
		if (newSelf != nil && (newSelf->m_stringWidth < newWidth || halfCount > 10)) {
			newSelf.stringWidth = newWidth;
			[newSelf setSelectedIndex:newSelf->m_selectedIndex];
		}
	}
	
	return newSelf;
}
@end


//------------------------------------------------------------------------------
//-- DLLMain -------------------------------------------------------------------
//------------------------------------------------------------------------------

#define MSHookFunc(sym) MSHookFunction(&sym, &$##sym, (void**)&_##sym)
#define MSHookMsg(clsName, sele) MSHookMessage([clsName class], @selector(sele), [clsName##Hooked instanceMethodForSelector:@selector(sele)], "old_")

void cleanup () {
	[currentOrigMode release];
	[currentMode release];
}

void installHook () {
	atexit(&cleanup);
	
	method_exchangeImplementations(
								   class_getClassMethod([UIKeyboardInputManager class], @selector(sharedInstanceForInputMode:)),
								   class_getClassMethod([UIKeyboardInputManagerHooked class], @selector(sharedInstanceForInputMode:))
								   );
	
	currentOrigMode = nil;
	currentMode = nil;
	
	// due to the use of MSHookFunction, we can't test it in iPhone Simulator :(
	MSHookFunc(UIKeyboardLayoutClassForInputModeInOrientation);
	MSHookFunc(UIKeyboardBundleForInputMode);
	MSHookFunc(UIKeyboardLocalizedInputModeName);
	MSHookFunc(UIKeyboardLayoutDefaultTypeForInputModeIsASCIICapable);
	MSHookFunc(UIKeyboardStaticUnigramsFilePathForInputModeAndFileExtension);
	MSHookFunc(UIKeyboardDynamicDictionaryFile);
	
	MSHookMsg(UIKeyboardLayoutRoman, showPopupVariantsForKey:);
	MSHookMsg(UIKeyboardLayoutRoman, downActionFlagsForKey:);
	MSHookMsg(UIAccentedCharacterView, initWithFrame:variants:expansion:orientation:);
}