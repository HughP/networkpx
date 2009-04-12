/*

GriPTest ... Test GriP notifications.
 
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

#include <stdio.h>
#import <Foundation/Foundation.h>
#import <GriP/GrowlApplicationBridge.h>

int
#if TARGET_IPHONE_SIMULATOR
xmain
#else
main
#endif
(int argc, char* argv[]) {
	if (argc < 2) {
		printf("Usage: GriPTest <title> [<detail>] [<url>] [<icon>]\n");
	} else {
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		NSString* title = [NSString stringWithUTF8String:argv[1]];
		NSString* detail = nil;
		NSString* icon = nil;
		NSURL* url = nil;
		if (argc >= 3) detail = [NSString stringWithUTF8String:argv[2]];
		if (argc >= 4) url = [NSURL URLWithString:[NSString stringWithUTF8String:argv[3]]];
		if (argc >= 5) icon = [NSString stringWithUTF8String:argv[4]];
		
		NSDictionary* regDict = [NSDictionary dictionaryWithObjectsAndKeys:
								 [NSArray arrayWithObject:@"whatever"], GROWL_NOTIFICATIONS_ALL,
								 [NSArray arrayWithObject:@"whatever"], GROWL_NOTIFICATIONS_DEFAULT,
								 @"hehehaha", GROWL_APP_NAME,
								 nil];
		
		if ([GrowlApplicationBridge isGrowlRunning]) {
			[GrowlApplicationBridge registerWithDictionary:regDict];
			[GrowlApplicationBridge setGrowlDelegate:url];
			[GrowlApplicationBridge notifyWithTitle:title description:detail notificationName:@"whatever" iconData:icon priority:0 isSticky:NO clickContext:@""];
		} else
			printf("GriP is not running!\n");
		
		[pool drain];
	}
	
	return 0;
}
