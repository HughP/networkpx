/*
 
 PrefsLinkHooker.m ... Preferences Hooker to dynamically create a new section to be referenced in the main screen.
 
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
#import <Preferences/PSListController.h>
#import <PrefHooker/PrefsLinkHooker.h>
#include <substrate.h>

@interface PrefsListControllerHooked : PSListController {}
-(NSArray*)old_specifiers;
-(NSArray*)specifiers;
@end

@implementation PrefsListControllerHooked
-(NSArray*)specifiers {
	if (_specifiers == nil) {
		[self old_specifiers];
		
		// Search for all bundles in /System/Library/PreferenceBundles/
		NSString* rootPath = @"/System/Library/PreferenceBundles/";
		NSMutableArray* specPlist = [NSMutableArray arrayWithObject:[NSDictionary dictionaryWithObject:@"PSGroupCell" forKey:@"cell"]];
		for (NSString* prefBundleName in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:rootPath error:NULL]) {
			if ([prefBundleName hasSuffix:@".bundle"]) {
				// If the bundle declare itself needed to be added to settings, count it in.
				NSBundle* prefBundle = [NSBundle bundleWithPath:[rootPath stringByAppendingPathComponent:prefBundleName]];
								
				if ([prefBundle objectForInfoDictionaryKey:@"PHAddToSettings"]) {
					BOOL hasIcon = ([prefBundle pathForResource:@"icon" ofType:@"png"] != nil);
					// use this instead of objectForInfoDictionaryKey: to prevent accidental localization.
					NSString* label = [[prefBundle infoDictionary] objectForKey:@"CFBundleDisplayName"];
					NSString* bundleName = [prefBundleName stringByDeletingPathExtension];
					
					if (![label isKindOfClass:[NSString class]])
						label = bundleName;
					[specPlist addObject:[NSDictionary dictionaryWithObjectsAndKeys:
											@"PSLinkCell", @"cell",
											bundleName, @"bundle",
											kCFBooleanTrue, @"isController",
											[NSNumber numberWithBool:hasIcon], @"hasIcon",
											label, @"label",
											nil
											]];
				}
			}
		}
		
		// if some bundle needs to be added, just add them.
		if ([specPlist count] > 1)
			[self addSpecifiersFromArray:SpecifiersFromPlistOnSelf(specPlist)];
	}
	return _specifiers;
}
@end



void PrefsListController_hook () {
	Class plcClass = objc_getClass("PrefsListController");
	// prevent the same method being hooked twice.
	//  (MSHookMessage will check for it, but it produces an error message in syslog but the name collision here is intensional...)
	if (![plcClass instancesRespondToSelector:@selector(old_specifiers)])
		MSHookMessage(plcClass, @selector(specifiers), [PrefsListControllerHooked instanceMethodForSelector:@selector(specifiers)], "old_");
}
