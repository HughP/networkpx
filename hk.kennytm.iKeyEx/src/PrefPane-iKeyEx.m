/*
 
 PrefPane-iKeyEx.m ... Preference Pane for iKeyEx.
 
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

#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <Foundation/Foundation.h>
#import <iKeyEx/common.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>	// chown

@interface iKeyExClearCacheListController : PSListController {}
-(NSArray*)specifiers;
-(void)clearCache:(PSSpecifier*)spec;
@end
@implementation iKeyExClearCacheListController
-(NSArray*)specifiers {
	if (_specifiers == nil) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"ClearCache" target:self] retain];
		
		if (![_specifier propertyForKey:@"hasSublayoutCache"]) {
			[self removeSpecifierID:@"sublayout"];
		}
		if (![_specifier propertyForKey:@"hasTrieCache"]) {
			[self removeSpecifierID:@"trie"];
		}
		
		// correct the title.
		[_title release];
		_title = [_specifier.name retain];
	}
	return _specifiers;
}
-(void)clearCache:(PSSpecifier*)spec {
	// construct the file name pattern we're going to remove.
	NSString* removingNamePrefix = [NSString stringWithFormat:iKeyEx_CachePrefix@"%@-%@-", _specifier.identifier, spec.identifier];
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
@end



@interface iKeyExListController : PSListController {}
-(NSArray*)specifiers;
-(NSString*)keyboardsValue:(PSSpecifier*)spec;
-(void)chmod;
@end

@implementation iKeyExListController
-(NSArray*)specifiers {
	if (_specifiers == nil) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"iKeyEx" target:self] retain];
	
		NSMutableArray* specPlist = [[NSMutableArray alloc] init];
		
		// find all iKeyEx Keybaords.		
		for (NSString* keyboardBundleName in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:iKeyEx_KeyboardsPath error:NULL]) {
			if (![keyboardBundleName hasSuffix:@".keyboard"])
				continue;
			
			NSBundle* bundle = [NSBundle bundleWithPath:[iKeyEx_KeyboardsPath stringByAppendingPathComponent:keyboardBundleName]];
			if (bundle == nil)
				continue;
			
			NSString* modeName = [keyboardBundleName stringByDeletingPathExtension];
			NSString* dispName = [bundle objectForInfoDictionaryKey:@"CFBundleDisplayName"];
			
			if (dispName == nil)
				dispName = modeName;
			
			NSString* layoutMethod = [bundle objectForInfoDictionaryKey:@"UIKeyboardLayoutClass"];
			NSString* imeMethod = [bundle objectForInfoDictionaryKey:@"UIKeyboardInputManagerClass"];
			NSMutableDictionary* curSpec = [[NSMutableDictionary alloc] initWithObjectsAndKeys:dispName, @"label", modeName, @"id", nil];
			BOOL insertCell = NO;
			
			NSString* prefBundleName = [bundle objectForInfoDictionaryKey:@"PSBundle"];
			if (prefBundleName != nil) {
				[curSpec setObject:[[@"../../.."iKeyEx_KeyboardsPath stringByAppendingPathComponent:keyboardBundleName]
																	 stringByAppendingPathComponent:prefBundleName]
							forKey:@"bundle"];
				[curSpec setObject:kCFBooleanTrue forKey:@"isController"];
				insertCell = YES;
			} 
			if ([layoutMethod isKindOfClass:[NSString class]] && ([layoutMethod hasSuffix:@".plist"] || [layoutMethod hasSuffix:@".sublayout"])) {
				[curSpec setObject:(NSNumber*)kCFBooleanTrue forKey:@"hasSublayoutCache"];
				if (prefBundleName == nil)
					[curSpec setObject:@"iKeyExClearCacheListController" forKey:@"detail"];
				insertCell = YES;
			}
			if ([imeMethod isKindOfClass:[NSString class]] && ([imeMethod hasSuffix:@".cin"])) {
				[curSpec setObject:(NSNumber*)kCFBooleanTrue forKey:@"hasTrieCache"];
				if (prefBundleName == nil)
					[curSpec setObject:@"iKeyExClearCacheListController" forKey:@"detail"];
				insertCell = YES;
			}
			
			if (insertCell) {
				[curSpec setObject:@"PSLinkCell" forKey:@"cell"];
				[specPlist addObject:curSpec];
			}
			
			[curSpec release];
		}
		
		[self insertContiguousSpecifiers:SpecifiersFromPlistOnSelf(specPlist) afterSpecifierID:@":SpecificPreferenceItems"];
		
		[specPlist release];
	}
	return _specifiers;
}

-(NSString*)keyboardsValue:(PSSpecifier*)spec {
	return [NSString stringWithFormat:@"%d", [[[NSUserDefaults standardUserDefaults] arrayForKey:@"AppleKeyboards"] count]];
}

-(void)chmod {
	system("/usr/bin/iKeyEx-KBMan fixperm");
}

-(void)clearImageCache {
	NSFileManager* man = [NSFileManager defaultManager];
	NSString* oldPath = [man currentDirectoryPath];
	[man changeCurrentDirectoryPath:iKeyEx_DataDirectory];
	NSArray* files = [man contentsOfDirectoryAtPath:@"." error:NULL];
	NSError* error = nil;
	// check one by one if the file has the desired prefix. If yes, delete that file.
	for (NSString* filename in files) {
		if ([filename hasPrefix:iKeyEx_CachePrefix] && [@"png" isEqualToString:[filename pathExtension]]) {
			if (![man removeItemAtPath:filename error:&error]) {
				NSLog(@"Cannot remove %@ when clearing image cache: %@", filename, error);
				error = nil;
			}
		}
	}
	[man changeCurrentDirectoryPath:oldPath];
}
@end
