/*
 
 UIKBInfo.m ... Info about Keyboard Modes.
 
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
#import <iKeyEx/UIKBInfo.h>
#import <iKeyEx/KeyboardLoader.h>
#import <iKeyEx/common.h>
#import <UIKit2/Functions.h>

extern NSString* UIKBGetKeyboardDisplayName(NSString* inputMode) {
	// an iKeyEx keyboard.
	if ([inputMode hasPrefix:iKeyEx_Prefix]) {
		return [KeyboardBundle bundleWithModeName:inputMode].displayName;
	// a standard keyboard.
	} else {
		NSLocale* curLocale = [NSLocale currentLocale];
		
		if ([inputMode isEqualToString:@"emoji"]) {
			return @"Emoji";
		} else {
			NSRange locRange = [inputMode rangeOfString:@"-"];
			if (locRange.location == NSNotFound) {
				return [curLocale displayNameForKey:NSLocaleIdentifier value:inputMode];
			} else {
				NSString* localeStr = [curLocale displayNameForKey:NSLocaleIdentifier value:[inputMode substringToIndex:locRange.location]];
				NSString* type = [@"UI" stringByAppendingString:[inputMode substringFromIndex:locRange.location]];
				return [NSString stringWithFormat:@"%@ (%@)", localeStr, UIKeyboardLocalizedString(type, [curLocale localeIdentifier], nil)];
			}
		}
	}
}

extern NSString* UIKBGetInputManagerDisplayName(NSString* inputMode) {
	return UIKBGetKeyboardDisplayName(inputMode);
}