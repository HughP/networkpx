/*

XXHooker-GriP ... GriP Hook to SpringBoard & Preferences.
 
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

#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <GriP/GPPreferences.h>
#import <GriP/GPMessageWindow.h>
#import <GriP/Duplex/Server.h>
#import <GriP/common.h>
#import <GriP/GrowlApplicationBridge.h>
#import <GriP/GPTheme.h>
#import <PrefHooker/PrefsLinkHooker.h>

static NSObject<GPTheme>* activeTheme = nil;

static CFDataRef GriPCallback (CFMessagePortRef serverPort, SInt32 type, CFDataRef data, void* info) {
	switch (type) {
		case GriPMessage_FlushPreferences:
			GPFlushPreferences();
			[activeTheme release];
			activeTheme = nil;
			break;
			
		case GriPMessage_ShowMessage:
			if (activeTheme == nil) {
				NSBundle* activeThemeBundle = [NSBundle bundleWithPath:[@"/Library/GriP/Themes/" stringByAppendingPathComponent:[GPPreferences() objectForKey:@"ActiveTheme"]]];
				NSString* themeType = [activeThemeBundle objectForInfoDictionaryKey:@"GPThemeType"];
				if (themeType == nil || [@"OBJC" isEqualToString:themeType])
					activeTheme = [[[activeThemeBundle principalClass] alloc] init];
			}
			if ([activeTheme respondsToSelector:@selector(display:)]) {
				NSMutableDictionary* messageDict = [NSPropertyListSerialization propertyListFromData:(NSData*)data mutabilityOption:NSPropertyListMutableContainersAndLeaves format:NULL errorDescription:NULL];
				GPModifyMessageForUserPreference(messageDict);
				if ([messageDict count] != 0)
					[activeTheme display:messageDict];
			}
			break;
			
		case GriPMessage_ClickedNotification:
		case GriPMessage_IgnoredNotification: {
			NSArray* array = [NSPropertyListSerialization propertyListFromData:(NSData*)data mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:NULL];
			if ([array isKindOfClass:[NSArray class]] && [array count] >= 2) {
				CFStringRef pid = (CFStringRef)[array objectAtIndex:0];
				CFDataRef context = (CFDataRef)[array objectAtIndex:1];
				
				CFMessagePortRef clientPort = CFMessagePortCreateRemote(NULL, pid);
				if (clientPort != NULL) {
					CFMessagePortSendRequest(clientPort, type, context, 1, 0, NULL, NULL);
					CFRelease(clientPort);
				}
			}
			break;
		}
			
		case GriPMessage_UpdateTicket: {
			NSArray* array = [NSPropertyListSerialization propertyListFromData:(NSData*)data mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:NULL];
			if ([array isKindOfClass:[NSArray class]] && [array count] >= 2) {
				NSString* appName = [array objectAtIndex:0];
				NSDictionary* regDictionary = [array objectAtIndex:1];
				if ([appName isKindOfClass:[NSString class]] && [regDictionary isKindOfClass:[NSDictionary class]])
					GPUpdateRegistrationDictionaryForAppName(appName, regDictionary);
			}
			break;
		}
				
		default:
			break;
	}

	return NULL;
}

 
static void terminate () {
	GPStopServer();
	[GPMessageWindow _cleanup];
	[activeTheme release];
	GPFlushPreferences();
}
	
	 
void initialize () {
	CFStringRef bundleID = CFBundleGetIdentifier(CFBundleGetMainBundle());
	if
#if TARGET_IPHONE_SIMULATOR
		(1)
#else
		(kCFCompareEqualTo == CFStringCompare(bundleID, CFSTR("com.apple.springboard"), 0))
#endif
	{
	
		if (GPStartServer() != 0) {
			NSLog(@"Cannot start GriP server -- probably another instance of GriP is already running.");
			return;
		}
		
		GPSetAlternateHandler(&GriPCallback, GriPMessage__Start, GriPMessage__End);
		
#if TARGET_IPHONE_SIMULATOR
		activeTheme = [[objc_getClass("GPDefaultTheme") alloc] init];
#endif
		
		atexit(&terminate);
	
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		[GPMessageWindow _initialize];
		[pool drain];
		
	} else {
		PrefsListController_hook();
	}
}