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
#include <unistd.h>
#import <iKeyEx/common.h>

static const char* Usage = "Usage:\n\
iKeyEx-KBMan <command> [<kbid>]\n\
\n\
Available commands:\n\
\tadd         Add the specified keyboard to the preferences.\n\
\tremove      Remove the specified keyboard from the preferences.\n\
\tremoveall   Remove all iKeyEx keyboards from the preferences.\n\
\tpurge       Clear automatically generated cache of the specified keyboard.\n\
\tpurgeall    Clear all generated cache from iKeyEx.\n\
\tfixperm     Fix the owner and permission in the /var/mobile/Library/Keyboard/ folder.\n\
<kbid> is same as the input mode name without the \"iKeyEx:\" prefix.\n\n";

#define GlobalPreferences @"/var/mobile/Library/Preferences/.GlobalPreferences.plist"
#define PreferencesPreferences @"/var/mobile/Library/Preferences/com.apple.Preferences.plist"

// copied from PrefPane-iKeyEx.m
void clearCache(NSString* removingNamePrefix) {
	// collect all files having the in the target directory.
	NSFileManager* man = [NSFileManager defaultManager];
	NSString* oldPath = [man currentDirectoryPath];
	[man changeCurrentDirectoryPath:iKeyEx_DataDirectory];
	NSArray* files = [man contentsOfDirectoryAtPath:@"." error:NULL];
	NSError* error = nil;
	// check one by one if the file has the desired prefix. If yes, delete that file.
	for (NSString* filename in files) {
		if ([filename hasPrefix:removingNamePrefix]) {
			if (![man removeItemAtPath:filename error:&error]) {
				NSLog(@"Cannot remove %@ when clearing \"%@\": %@", filename, removingNamePrefix, error);
				error = nil;
			}
		}
	}
	[man changeCurrentDirectoryPath:oldPath];
}

// TODO: Lock the preference files during read/write. (Use CFPreferences API?)
int main (int argc, const char* argv[]) {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	// Reduce permission except when required.
	uid_t euid = geteuid();
	seteuid(getuid());
	
	if (argc == 1)
		printf(Usage);
	else {
		if (!strcmp("remove", argv[1])) {
			if (argc == 2)
				printf("Please specify the <kbid> for remove. If you want to remove all iKeyEx keyboards, use the \"removeall\" command instead.\n\n");
			else {
				NSString* inputModeName = [NSString stringWithUTF8String:argv[2]];
				if (![inputModeName hasPrefix:@"iKeyEx:"]) {
					inputModeName = [@"iKeyEx:" stringByAppendingString:inputModeName];
				}
				
				NSMutableDictionary* globalPrefsDict = [NSMutableDictionary dictionaryWithContentsOfFile:GlobalPreferences];
				NSMutableArray* appleKeyboards = [[globalPrefsDict objectForKey:@"AppleKeyboards"] mutableCopy];
				
				NSUInteger specifiedIndex = [appleKeyboards indexOfObject:inputModeName];
				if (specifiedIndex != NSNotFound) {
					[appleKeyboards removeObjectAtIndex:specifiedIndex];
					if ([appleKeyboards count] == 0)
						[appleKeyboards addObject:@"en_US"];
					[globalPrefsDict setObject:appleKeyboards forKey:@"AppleKeyboards"];
					[globalPrefsDict writeToFile:GlobalPreferences atomically:NO];
					
					NSMutableDictionary* prefsPrefsDict = [NSMutableDictionary dictionaryWithContentsOfFile:PreferencesPreferences];
					NSString* firstKeyboard = [appleKeyboards objectAtIndex:0];
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
						[prefsPrefsDict writeToFile:PreferencesPreferences atomically:NO];
				}
				
				[appleKeyboards release];
				
			}
			
		} else if (!strcmp("removeall", argv[1])) {
			NSMutableDictionary* globalPrefsDict = [NSMutableDictionary dictionaryWithContentsOfFile:GlobalPreferences];
			NSMutableArray* appleKeyboards = [[globalPrefsDict objectForKey:@"AppleKeyboards"] mutableCopy];
			NSMutableIndexSet* removableIndices = [NSMutableIndexSet indexSet];
			NSUInteger curIndex = 0;
			for (NSString* inputMode in appleKeyboards) {
				if ([inputMode hasPrefix:@"iKeyEx:"])
					[removableIndices addIndex:curIndex];
				++ curIndex;
			}
			
			if ([removableIndices count] > 0) {
				[appleKeyboards removeObjectsAtIndexes:removableIndices];
				if ([appleKeyboards count] == 0)
					[appleKeyboards addObject:@"en_US"];
				[globalPrefsDict setObject:appleKeyboards forKey:@"AppleKeyboards"];
				[globalPrefsDict writeToFile:GlobalPreferences atomically:NO];
				
				NSMutableDictionary* prefsPrefsDict = [NSMutableDictionary dictionaryWithContentsOfFile:PreferencesPreferences];
				NSString* firstKeyboard = [appleKeyboards objectAtIndex:0];
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
					[prefsPrefsDict writeToFile:PreferencesPreferences atomically:NO];
			}
			
			[appleKeyboards release];
			
		} else if (!strcmp("purge", argv[1])) {
			if (argc == 2)
				printf("Please specify the <kbid> for purge. If you want to purge everything, use the \"purgeall\" command instead.\n\n");
			else {
				NSString* inputModeName = [NSString stringWithUTF8String:argv[2]];
				if ([inputModeName hasPrefix:@"iKeyEx:"]) {
					inputModeName = [inputModeName substringFromIndex:7];
				}
				clearCache([NSString stringWithFormat:iKeyEx_CachePrefix@"%@-", inputModeName]);
			}
			
		} else if (!strcmp("purgeall", argv[1])) {

			clearCache(iKeyEx_CachePrefix);
			
		} else if (!strcmp("add", argv[1])) {
			if (argc == 2)
				printf("Please specify the <kbid> to add.\n\n");
			else {
				NSString* inputModeName = [NSString stringWithUTF8String:argv[2]];
				if (![inputModeName hasPrefix:@"iKeyEx:"]) {
					inputModeName = [@"iKeyEx:" stringByAppendingString:inputModeName];
				}
				
				NSMutableDictionary* globalPrefsDict = [NSMutableDictionary dictionaryWithContentsOfFile:GlobalPreferences];
				NSMutableArray* appleKeyboards = [[globalPrefsDict objectForKey:@"AppleKeyboards"] mutableCopy];
				
				if (![appleKeyboards containsObject:inputModeName]) {
					// which is impossible
					if ([appleKeyboards count] == 0)
						[appleKeyboards addObject:@"en_US"];
					[appleKeyboards insertObject:inputModeName atIndex:1];
					
					[globalPrefsDict setObject:appleKeyboards forKey:@"AppleKeyboards"];
					[globalPrefsDict writeToFile:GlobalPreferences atomically:NO];
				}
				
				[appleKeyboards release];
			}
			
		} else if (!strcmp("fixperm", argv[1])) {
			
			// Acquire root permission.
			seteuid(euid);
			
			NSError* error = nil;
			NSFileManager* man = [NSFileManager defaultManager];
			NSString* oldPath = [man currentDirectoryPath];
			[man changeCurrentDirectoryPath:@"/var/mobile/Library/Keyboard/"];
			
			NSDictionary* attr = [NSDictionary dictionaryWithObjectsAndKeys:
								  @"mobile", NSFileOwnerAccountName,
								  @"mobile", NSFileGroupOwnerAccountName,
								  [NSNumber numberWithUnsignedLong:0755], NSFilePosixPermissions,
								  nil];
			if (![man setAttributes:attr ofItemAtPath:@"." error:&error]) {
				NSLog(@"Cannot change owner and permission of \".\": %@", error);
				error = nil;
			}
			
			attr = [NSDictionary dictionaryWithObjectsAndKeys:
					@"mobile", NSFileOwnerAccountName,
					@"mobile", NSFileGroupOwnerAccountName,
					[NSNumber numberWithUnsignedLong:0644], NSFilePosixPermissions,
					nil];
			
			NSArray* files = [man contentsOfDirectoryAtPath:@"." error:NULL];
			for (NSString* filename in files) {
				if (![man setAttributes:attr ofItemAtPath:filename error:&error]) {
					NSLog(@"Cannot change owner and permission of \"%@\": %@", filename, error);
					error = nil;
				}
			}
			[man changeCurrentDirectoryPath:oldPath];
			
		} else {
			printf("Unregconized command: %s\n\n", argv[1]);
		}
	}
	
	[pool drain];
	return 0;
}