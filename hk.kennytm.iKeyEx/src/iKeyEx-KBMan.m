/*
 
 iKeyEx-KBMan.m ... Utility for iKeyEx keyboard package management.
 
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
#include <stdio.h>
#include <string.h>

static const char* Usage = "Usage:\n\
iKeyEx-KBMan <command> [<kbid>]\n\
\n\
Available commands:\n\
	remove      Remove the specified keyboard from the preferences.\n\
	removeall   Remove all iKeyEx keyboards from the preferences.\n\
	purge       Clear automatically generated cache of the specified keyboard.\n\
<kbid> is same as the input mode name without the \"iKeyEx:\" prefix.";

#define GlobalPreferences @"/var/mobile/Library/Preferences/.GlobalPreferences.plist"
#define PreferencesPreferences @"/var/mobile/Library/Preferences/com.apple.Preferences.plist"

// TODO: Lock the preference files during read/write. (Use CFPreferences API?)
int main (int argc, const char* argv[]) {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	if (argc == 1)
		printf(Usage);
	else {
		if (!strcmp("remove", argv[1])) {
			if (argc == 2)
				printf("Please specify the <kbid> for remove. If you want to remove all iKeyEx keyboards, use the \"removeall\" command instead.");
			else {
				NSString* inputModeName = [NSString stringWithUTF8String:argv[2]];
				if (![inputModeName hasPrefix:@"iKeyEx:"]) {
					inputModeName = [@"iKeyEx:" stringByAppendingString:inputModeName];
				}
				
				NSDictionary* globalPrefsDict = [NSDictionary dictionaryWithContentsOfFile:GlobalPreferences];
				NSArray* appleKeyboards = [globalPrefsDict objectForKey:@"AppleKeyboards"];
				
				NSUInteger specifiedIndex = [appleKeyboards indexOfObject:inputModeName];
				if (specifiedIndex != NSNotFound) {
					NSMutableArray* mutableAppleKeyboards = [appleKeyboards mutableCopy];
					NSMutableDictionary* mutableGlobalPrefsDict = [globalPrefsDict mutableCopy];
					[mutableAppleKeyboards removeObjectAtIndex:specifiedIndex];
					if ([mutableAppleKeyboards count] == 0)
						[mutableAppleKeyboards addObject:@"en_US"];
					[mutableGlobalPrefsDict setObject:mutableAppleKeyboards forKey:@"AppleKeyboards"];
					[mutableGlobalPrefsDict writeToFile:GlobalPreferences atomically:YES];
					
					NSMutableDictionary* prefsPrefsDict = [NSMutableDictionary dictionaryWithContentsOfFile:PreferencesPreferences];
					NSString* firstKeyboard = [mutableAppleKeyboards objectAtIndex:0];
					BOOL prefsPrefsModified = NO;
					if ([inputModeName isEqualToString:[prefsPrefsDict objectForKey:@"KeyboardLastChosen"]]) {
						[prefsPrefsDict setObject:firstKeyboard forKey:@"KeyboardLastChosen"];
						prefsPrefsModified = YES;
					}
					if ([inputModeName isEqualToString:[prefsPrefsDict objectForKey:@"KeyboardLastUsed"]]) {
						[prefsPrefsDict setObject:firstKeyboard forKey:@"KeyboardLastUsed"];
						prefsPrefsModified = YES;
					}
					if (prefsPrefsModified)
						[prefsPrefsDict writeToFile:PreferencesPreferences atomically:YES];
					
					[mutableAppleKeyboards release];
					[mutableGlobalPrefsDict release];
				}
			}
			
		} else if (!strcmp("removeall", argv[1])) {
			NSMutableDictionary* mutableGlobalPrefsDict = [NSMutableDictionary dictionaryWithContentsOfFile:GlobalPreferences];
			NSMutableArray* mutableAppleKeyboards = [[mutableGlobalPrefsDict objectForKey:@"AppleKeyboards"] mutableCopy];
			NSUInteger* removableIndices = malloc([mutableAppleKeyboards count]*sizeof(NSUInteger));
			NSUInteger removableIndicesCount = 0, curIndex = 0;
			for (NSString* inputMode in mutableAppleKeyboards) {
				if ([inputMode hasPrefix:@"iKeyEx:"])
					removableIndices[removableIndicesCount++] = curIndex;
				++ curIndex;
			}
			
			if (removableIndicesCount > 0) {
				[mutableAppleKeyboards removeObjectsFromIndices:removableIndices numIndices:removableIndicesCount];
				if ([mutableAppleKeyboards count] == 0)
					[mutableAppleKeyboards addObject:@"en_US"];
				[mutableGlobalPrefsDict setObject:mutableAppleKeyboards forKey:@"AppleKeyboards"];
				[mutableGlobalPrefsDict writeToFile:GlobalPreferences atomically:YES];
				
				NSMutableDictionary* prefsPrefsDict = [NSMutableDictionary dictionaryWithContentsOfFile:PreferencesPreferences];
				NSString* firstKeyboard = [mutableAppleKeyboards objectAtIndex:0];
				BOOL prefsPrefsModified = NO;
				if ([[prefsPrefsDict objectForKey:@"KeyboardLastChosen"] hasPrefix:@"iKeyEx:"]) {
					[prefsPrefsDict setObject:firstKeyboard forKey:@"KeyboardLastChosen"];
					prefsPrefsModified = YES;
				}
				if ([[prefsPrefsDict objectForKey:@"KeyboardLastUsed"] hasPrefix:@"iKeyEx:"]) {
					[prefsPrefsDict setObject:firstKeyboard forKey:@"KeyboardLastUsed"];
					prefsPrefsModified = YES;
				}
				if (prefsPrefsModified)
					[prefsPrefsDict writeToFile:PreferencesPreferences atomically:YES];
			}
			
			[mutableAppleKeyboards release];
			free(removableIndices);
			
		} else if (!strcmp("purge", argv[1])) {
			if (argc == 2)
				printf("Please specify the <kbid> for purge.");
			else {
				NSString* inputModeName = [NSString stringWithUTF8String:argv[2]];
				if ([inputModeName hasPrefix:@"iKeyEx:"]) {
					inputModeName = [inputModeName substringFromIndex:7];
				}
				
				NSString* rmCommand = [NSString stringWithFormat:@"rm /var/mobile/Library/Keyboard/iKeyEx/cache/%@-*", inputModeName];
				system([rmCommand UTF8String]);
			}
			
		} else {
			printf("Unregconized command: %s", argv[1]);
		}
	}

	printf("\n\n");
	
	[pool drain];
	return 0;
}