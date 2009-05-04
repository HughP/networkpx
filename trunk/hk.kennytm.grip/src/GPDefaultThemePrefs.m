/*

FILE_NAME ... DESCRIPTION
 
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
#import <GriP/common.h>
#import <GriP/Duplex/Client.h>

@interface GPDefaultThemePrefsListController : PSListController {
	NSNumber* width;
}
-(id)initForContentSize:(CGSize)size;
-(void)dealloc;
-(void)suspend;
-(NSArray*)specifiers;
@property(retain) NSNumber* width;
@end
@implementation GPDefaultThemePrefsListController
@synthesize width;
-(id)initForContentSize:(CGSize)size {
	if ((self = [super initForContentSize:size])) {
		width = [[[NSDictionary dictionaryWithContentsOfFile:GRIP_PREFDICT] objectForKey:@"Width"] retain];
	}
	return self;
}
-(void)dealloc {
	[width release];
	[super dealloc];
}
-(void)suspend {
	NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithContentsOfFile:GRIP_PREFDICT];
	[dict setObject:width forKey:@"Width"];
	[dict writeToFile:GRIP_PREFDICT atomically:NO];
	[GPDuplexClient sendMessage:GriPMessage_FlushPreferences data:nil];
	[super suspend];
}
-(NSArray*)specifiers {
	if (_specifiers == nil) {
		NSLog(@"%@", [self bundle]);
		_specifiers = [[self loadSpecifiersFromPlistName:@"Customize" target:self] retain];
	}
	return _specifiers;
}
@end

