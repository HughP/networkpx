/*
 
 PrefHooker-iKeyEx-InternationalKeyboardController.m ... Preferences Hooker to include iKeyEx keyboards in International Keyboards.
 
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


#import <PrefHooker/InternationalKeyboardController.h>
#import <Preferences/PSSpecifier.h>
#import <iKeyEx/common.h>
#import <iKeyEx/KeyboardLoader.h>
#import <CoreGraphics/CGGeometry.h>

// These are to mute the warnings about undefined messages.
@protocol PSRootControllerProtocol<NSObject>
-(PSListController*)lastController;
@end

@protocol LanguageSelectorProtocol<NSObject>
+(id<LanguageSelectorProtocol>)sharedInstance;
-(NSString*)currentLanguage;
@end



@implementation InternationalKeyboardControllerHooked
-(NSArray*)specifiers {
	if (_specifiers == nil) {
		// activate the list first.
		[self old_specifiers];
		
		Class LanguageSelector = objc_getClass("LanguageSelector");
		
		NSBundle* localizationBundle = [NSBundle bundleWithPath:@"/System/Library/PreferenceBundles/iKeyEx.bundle/"];
		
		NSMutableArray* result = [[NSMutableArray alloc] initWithObjects:
								  [PSSpecifier groupSpecifierWithName:[localizationBundle localizedStringForKey:@"Keyboards for Current Language" value:nil table:nil]],
								  nil];
		
		// add keyboards for current language in.
		NSString* currentLocalePrefix = [[[LanguageSelector sharedInstance] currentLanguage] substringToIndex:2];
		NSUInteger separator = 0;
		for (PSSpecifier* spec in _specifiers) {
			if (spec->cellType == PSSwitchCell && ![spec.identifier hasPrefix:currentLocalePrefix])
				break;
			++separator;
		}
		[result addObjectsFromArray:[_specifiers subarrayWithRange:NSMakeRange(1, separator-1)]];
		
		// add iKeyEx keyboards in.
		[result addObject:[PSSpecifier groupSpecifierWithName:[localizationBundle localizedStringForKey:@"iKeyEx Keyboards" value:nil table:nil]]];
		
		NSFileManager* manager = [NSFileManager defaultManager];
		NSString* rootPath = iKeyEx_KeyboardsPath;
		
		for (NSString* keyboardBundleName in [manager contentsOfDirectoryAtPath:rootPath error:NULL]) {
			if (![keyboardBundleName hasSuffix:@".keyboard"])
				continue;
			
			NSBundle* bundle = [NSBundle bundleWithPath:[rootPath stringByAppendingPathComponent:keyboardBundleName]];
			if (bundle == nil)
				continue;
			
			NSString* modeName = [keyboardBundleName stringByDeletingPathExtension];
			NSString* dispName = [bundle objectForInfoDictionaryKey:@"CFBundleDisplayName"];
			
			if (dispName == nil)
				dispName = modeName;
			
			PSSpecifier* toggle = [PSSpecifier preferenceSpecifierNamed:dispName
																 target:self
																	set:@selector(setValueForIKeyExKeyboard:specifier:)
																	get:@selector(valueForIKeyExKeyboard:)
																 detail:Nil
																   cell:PSSwitchCell
																   edit:Nil];
			[toggle setProperty:[iKeyEx_Prefix stringByAppendingString:modeName] forKey:@"id"];
			
			[result addObject:toggle];
		}
		
		// add rest of the keyboards.
		[result addObject:[PSSpecifier groupSpecifierWithName:[localizationBundle localizedStringForKey:@"Other Built-in Keyboards" value:nil table:nil]]];
		[result addObjectsFromArray:[_specifiers subarrayWithRange:NSMakeRange(separator, [_specifiers count]-separator)]];
		
		// confirm our construction.
		[_specifiers release];
		_specifiers = result;
	}
	
	return _specifiers;
}
-(NSNumber*)valueForIKeyExKeyboard:(PSSpecifier*)sender {
	if (_keyboardsDictionary == nil)
		[self _readKeyboards];
	
	NSNumber* retval = [_keyboardsDictionary objectForKey:[sender identifier]];
	if (retval == nil)
		return [NSNumber numberWithBool:NO];
	else {
		/*if ([_keyboardsDictionary count] <= 1 && [retval boolValue]) {
		 [sender setProperty:(void*)kCFBooleanFalse forKey:@"enabled"];
		 _disabledSpecifier = [sender retain];
		 [[_rootController lastController] reloadSpecifier:sender];
		 }*/
		return retval;
	}
}

-(void)setValueForIKeyExKeyboard:(NSNumber*)value specifier:(PSSpecifier*)sender {
	// Apple devs, if you're going to store BOOLs anyway, why not just use an NSSet?
	if ([value boolValue])
		[_keyboardsDictionary setObject:value forKey:[sender identifier]];
	else {
		NSString* sid = [sender identifier];
		[_keyboardsDictionary removeObjectForKey:sid];
		
		// if the mode to be removed is the currently active mode, reset it to something else
		// (if not, the whole keyboard list will be wiped out and restored to ["en_US"].
		BOOL replaceKLC = NO, replaceKLU = NO;
		
		NSUserDefaults* prefsPrefs = [NSUserDefaults standardUserDefaults];
		if ([sid isEqualToString:[prefsPrefs stringForKey:@"KeyboardLastChosen"]])
			replaceKLC = YES;
		if ([sid isEqualToString:[prefsPrefs stringForKey:@"KeyboardLastUsed"]])
			replaceKLU = YES;
		if (replaceKLC || replaceKLU) {
			NSString* anykey = nil;
			for (NSString* key in _keyboardsDictionary) {
				anykey = key;
				break;
			}
			if (replaceKLC)
				[prefsPrefs setObject:anykey forKey:@"KeyboardLastChosen"];
			if (replaceKLU)
				[prefsPrefs setObject:anykey forKey:@"KeyboardLastUsed"];
		}
	}
	[self _writeKeyboards];
	// make sure at least 1 keyboard is selected.
	if ([_keyboardsDictionary count] == 1) {
		if (_disabledSpecifier == nil) {
			NSString* theID = [[_keyboardsDictionary keyEnumerator] nextObject];
			PSListController* lastCont = [_rootController lastController];
			_disabledSpecifier = [[lastCont specifierForID:theID] retain];
			[_disabledSpecifier setProperty:(void*)kCFBooleanFalse forKey:@"enabled"];
			[lastCont reloadSpecifier:_disabledSpecifier];
		}
	} else {
		if (_disabledSpecifier != nil) {
			[_disabledSpecifier setProperty:(void*)kCFBooleanTrue forKey:@"enabled"];
			[[_rootController lastController] reloadSpecifier:_disabledSpecifier];
			[_disabledSpecifier release];
			_disabledSpecifier = nil;
		}
	}
}

@end


// Don't let -keyboardExistsForLanguage: delete our keyboards.
@implementation LanguageSelectorHooked
-(BOOL)keyboardExistsForLanguage:(NSString*)lang {
	if ([lang hasPrefix:iKeyEx_Prefix])
		return YES;
	else
		return [self old_keyboardExistsForLanguage:lang];
}
@end
