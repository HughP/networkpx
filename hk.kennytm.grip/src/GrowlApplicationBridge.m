/*

GrowlApplicationBridge.m ... Growl Application Bridge (as a wrapper of a shared GriP Application Bridge)
 
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

#import <GriP/GrowlApplicationBridge.h>
#import <GriP/GPApplicationBridge.h>

static GPApplicationBridge* sharedBridge = nil;

@interface GrowlApplicationBridge ()
+(GPApplicationBridge*)sharedInstance;
@end

static void GPTryTerminate () {
	[sharedBridge release];
	sharedBridge = nil;
}

@implementation GrowlApplicationBridge
+(GPApplicationBridge*)sharedInstance {
	@synchronized(self) {
		if (sharedBridge == nil) {
			atexit(&GPTryTerminate);
			sharedBridge = [[GPApplicationBridge alloc] init];
		}
	}
	return sharedBridge;
}

+(BOOL)isGrowlInstalled { return [[self sharedInstance] isGrowlInstalled]; }
+(BOOL)isGrowlRunning { return [[self sharedInstance] isGrowlRunning]; }
+(void)setGrowlDelegate:(NSObject<GrowlApplicationBridgeDelegate>*)inDelegate { return [[self sharedInstance] setGrowlDelegate:inDelegate]; }
+(NSObject<GrowlApplicationBridgeDelegate>*)growlDelegate { return [[self sharedInstance] growlDelegate]; }
+(void)notifyWithTitle:(NSString*)title description:(NSString*)description notificationName:(NSString*)notifName iconData:(NSObject*)iconData priority:(signed)priority isSticky:(BOOL)isSticky clickContext:(NSObject*)clickContext {
	[[self sharedInstance] notifyWithTitle:title description:description notificationName:notifName iconData:iconData priority:priority isSticky:isSticky clickContext:clickContext];
}
+(void)notifyWithTitle:(NSString*)title description:(NSString*)description notificationName:(NSString*)notifName iconData:(NSObject*)iconData priority:(signed)priority isSticky:(BOOL)isSticky clickContext:(NSObject*)clickContext identifier:(NSString*)identifier {
	[[self sharedInstance] notifyWithTitle:title description:description notificationName:notifName iconData:iconData priority:priority isSticky:isSticky clickContext:clickContext identifier:identifier];
}

+(void)notifyWithDictionary:(NSDictionary*)userInfo { [[self sharedInstance] notifyWithDictionary:userInfo]; }
+(BOOL)registerWithDictionary:(NSDictionary*)potentialDictionary { return [[self sharedInstance] registerWithDictionary:potentialDictionary]; }

@end