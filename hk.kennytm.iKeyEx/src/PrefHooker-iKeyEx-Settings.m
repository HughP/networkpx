/*
 
 PrefHooker-iKeyEx-Settings.h ... Preferences Hooker to dynamically create a new section to be referenced in the main screen.
 
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

#import <PrefHooker/Settings.h>
#import <Foundation/Foundation.h>
#import <Preferences/PSSpecifier.h>

#import <UIKit2/Functions.h>

#define PHMagic @"KennyTM~:PrefHooker:Settings"

static NSMutableArray* sectionsToInsert = nil;

void PHInsertSection (NSString* bundlePath, NSString* xLabel, BOOL hasIcon) {
	if (!sectionsToInsert) 
		sectionsToInsert = [[NSMutableArray alloc] init];
	[sectionsToInsert addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 @"PSLinkCell", @"cell",
								 // hack?
								 [@"../../../" stringByAppendingString:bundlePath], @"bundle",
								 kCFBooleanTrue, @"isController",
								 [NSNumber numberWithBool:hasIcon], @"hasIcon",
								 xLabel, @"label",
								 nil
								 ]];
}

@implementation PrefsListControllerHooked
-(NSArray*)specifiers {
	NSArray* oldSpecifiers = [self old_specifiers];
	
	if (sectionsToInsert == nil)
		return oldSpecifiers;
	
	BOOL hasInsertedSomething = NO;
	for (PSSpecifier* spec in [oldSpecifiers reverseObjectEnumerator]) {
		if ([PHMagic isEqualToString:spec.identifier]) {
			hasInsertedSomething = YES;
			break;
		}
	}
	
	if (!hasInsertedSomething) {
		PSSpecifier* separator = [PSSpecifier emptyGroupSpecifier];
		[separator setProperty:PHMagic forKey:PSIDKey];
		[self addSpecifier:separator];
	}
		
	[self addSpecifiersFromArray:SpecifiersFromPlist(
													 [NSDictionary dictionaryWithObject:sectionsToInsert forKey:@"items"],
													 nil, self, nil, [NSBundle mainBundle], NULL, NULL, self, NULL
													 )];
	[sectionsToInsert release];
	sectionsToInsert = nil;
	
	return [self old_specifiers];
}
@end
