/*
 
 prefs.m ... Preference Pane for ℏClipboard.
 
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
#import <Preferences/PSSpecifier.h>
#import <iKeyEx/common.h>

#define PREFSDICT_PATH iKeyEx_KeyboardsPath@"/hClipboard.keyboard/Preferences.plist"

@interface hClipboardListController : PSListController {
	NSMutableDictionary* prefsDict;
}
-(NSArray*)specifiers;
-(NSNumber*)getValue:(PSSpecifier*)spec;
-(void)setValue:(NSNumber*)val forSpecifier:(PSSpecifier*)spec;
-(id)initForContentSize:(CGSize)size;
-(void)dealloc;
-(void)deleteClipboard:(PSSpecifier*)spec;
@end

@implementation hClipboardListController
-(id)initForContentSize:(CGSize)size {
	if ((self = [super initForContentSize:size])) {
		prefsDict = [[NSMutableDictionary alloc] initWithContentsOfFile:PREFSDICT_PATH];
	}
	return self;
}
-(void)dealloc {
	[prefsDict release];
	[super dealloc];
}

-(NSArray*)specifiers {
	if (_specifiers == nil)
		_specifiers = [[self loadSpecifiersFromPlistName:@"hClipboard" target:self] retain];
	return _specifiers;
}

-(NSNumber*)getValue:(PSSpecifier*)spec { return [prefsDict objectForKey:spec.identifier]; }
-(void)setValue:(NSNumber*)val forSpecifier:(PSSpecifier*)spec {
	[prefsDict setObject:val forKey:spec.identifier];
	[prefsDict writeToFile:PREFSDICT_PATH atomically:NO];
}

-(void)deleteClipboard:(PSSpecifier*)spec {
	NSString* fileName = [iKeyEx_DataDirectory stringByAppendingPathComponent:
						  [[spec propertyForKey:@"filename"] stringByAppendingPathExtension:@"plist"]
						  ];
	NSError* error = nil;
	if (![[NSFileManager defaultManager] removeItemAtPath:fileName error:&error]) {
		NSLog(@"Cannot remove %@: %@", fileName, error);
	}
}
@end

