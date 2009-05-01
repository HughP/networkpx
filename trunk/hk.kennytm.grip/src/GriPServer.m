/*

GriPServer ... GriP Server / GriP Hook to SpringBoard & Preferences.
 
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

#include <pthread.h>
#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <GriP/GPPreferences.h>
#import <GriP/GPMessageWindow.h>
#import <GriP/Duplex/Server.h>
#import <GriP/common.h>
#import <GriP/GrowlApplicationBridge.h>
#import <GriP/GPTheme.h>
#import <PrefHooker/PrefsLinkHooker.h>
#import <UIKit/UIApplication.h>

#if GRIP_JAILBROKEN
@interface SpringBoard : UIApplication
-(void)applicationOpenURL:(NSURL*)url publicURLsOnly:(BOOL)publicsOnly;	// only in >=3.0
-(void)applicationOpenURL:(NSURL*)url asPanel:(BOOL)asPanel publicURLsOnly:(BOOL)publicsOnly;	// only in <3.0
@end
#else
#import <GriP/GPDefaultTheme.h>
#endif

static pthread_mutex_t atLock = PTHREAD_MUTEX_INITIALIZER;
static NSObject<GPTheme>* activeTheme = nil;
static const int MemoryAlertObserver = 12345678;

static void GPMemoryAlert (CFNotificationCenterRef center, void* observer, CFStringRef name, const void* object, CFDictionaryRef userInfo) {
	GPFlushPreferences();
	pthread_mutex_lock(&atLock);
	[activeTheme release];
	activeTheme = nil;
	pthread_mutex_unlock(&atLock);
}

static CFDataRef GriPCallback (CFMessagePortRef serverPort, SInt32 type, CFDataRef data, void* info) {
	CFDataRef retData = NULL;
	NSArray* array = nil;
	
	switch (type) {
		case GriPMessage_FlushPreferences:
			// basically the same action.
			GPMemoryAlert(NULL, NULL, NULL, NULL, NULL);
			break;
			
		case GriPMessage_ShowMessage: {
			pthread_mutex_lock(&atLock);
			if (activeTheme == nil) {
#if GRIP_JAILBROKEN
				NSBundle* activeThemeBundle = [NSBundle bundleWithPath:[@"/Library/GriP/Themes/" stringByAppendingPathComponent:[GPPreferences() objectForKey:@"ActiveTheme"]]];
				NSString* themeType = [activeThemeBundle objectForInfoDictionaryKey:@"GPThemeType"];
				if (themeType == nil || [@"OBJC" isEqualToString:themeType])
					activeTheme = [[[activeThemeBundle principalClass] alloc] initWithBundle:activeThemeBundle];
#else
				activeTheme = [[GPDefaultTheme alloc] initWithBundle:[NSBundle mainBundle]];
#endif
			}
			BOOL willDisplay = [activeTheme respondsToSelector:@selector(display:)];
			pthread_mutex_unlock(&atLock);
			
			NSMutableDictionary* messageDict = [NSPropertyListSerialization propertyListFromData:(NSData*)data mutabilityOption:NSPropertyListMutableContainers format:NULL errorDescription:NULL];
			
			if (willDisplay) {
				GPModifyMessageForUserPreference(messageDict);
				if ([messageDict count] != 0) {
					[activeTheme display:messageDict];
					break;
				}
			}
			
			// fall through as an ignored message if it remained unhandled.
			type = GriPMessage_IgnoredNotification;
			NSObject* context = [messageDict objectForKey:GRIP_CONTEXT];
			if (context == nil)
				break;
			array = [messageDict objectsForKeys:[NSArray arrayWithObjects:GRIP_PID, GRIP_CONTEXT, GRIP_ISURL, nil] notFoundMarker:@""];
			
			goto ignored_message;
		}
			
		case GriPMessage_ClickedNotification:
		case GriPMessage_IgnoredNotification:
			array = [NSPropertyListSerialization propertyListFromData:(NSData*)data mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:NULL];
ignored_message:
			if ([array isKindOfClass:[NSArray class]] && [array count] >= 3) {
				CFStringRef pid = (CFStringRef)[array objectAtIndex:0];
				CFDataRef context = (CFDataRef)[NSPropertyListSerialization dataFromPropertyList:[array objectAtIndex:1] format:NSPropertyListBinaryFormat_v1_0 errorDescription:NULL];
				BOOL isURL = [[array objectAtIndex:2] boolValue];
				
				CFMessagePortRef clientPort = CFMessagePortCreateRemote(NULL, pid);
				if (isURL && type == GriPMessage_ClickedNotification) {
					NSURL* url = [NSURL URLWithString:(NSString*)[array objectAtIndex:1]];
#if GRIP_JAILBROKEN
					SpringBoard* springBoard = (SpringBoard*)[UIApplication sharedApplication];
					if ([springBoard respondsToSelector:@selector(applicationOpenURL:asPanel:publicURLsOnly:)])
						[springBoard applicationOpenURL:url asPanel:NO publicURLsOnly:NO];
					else if ([springBoard respondsToSelector:@selector(applicationOpenURL:publicURLsOnly:)])
						[springBoard applicationOpenURL:url publicURLsOnly:NO];
#else
					[[UIApplication sharedApplication] openURL:url];
#endif
				} else if (clientPort != NULL) {
					CFMessagePortSendRequest(clientPort, type, context, 1, 0, NULL, NULL);
					CFRelease(clientPort);
				}
			}
			break;
			
		case GriPMessage_UpdateTicket:
			array = [NSPropertyListSerialization propertyListFromData:(NSData*)data mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:NULL];
			if ([array isKindOfClass:[NSArray class]] && [array count] >= 2) {
				NSString* appName = [array objectAtIndex:0];
				NSDictionary* regDictionary = [array objectAtIndex:1];
				if ([appName isKindOfClass:[NSString class]] && [regDictionary isKindOfClass:[NSDictionary class]])
					GPUpdateRegistrationDictionaryForAppName(appName, regDictionary);
			}
			break;
			
		case GriPMessage_CheckEnabled: {
			array = [NSPropertyListSerialization propertyListFromData:(NSData*)data mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:NULL];
			BOOL retval = NO;
			if ([array isKindOfClass:[NSArray class]]) {
				NSUInteger arrCount = [array count];
				if (arrCount >= 1) {
					NSString* appName = [array objectAtIndex:0];
					NSString* appMsg = arrCount >= 2 ? [array objectAtIndex:1] : nil;
					retval = GPCheckEnabled(appName, appMsg);
				}
			}
			retData = CFDataCreate(NULL, (const UInt8*)&retval, sizeof(BOOL));
			break;
		}
			
		case GriPMessage_DisposeIdentifier:
			if ([activeTheme respondsToSelector:@selector(messageClosed:)]) {
				NSString* identifier = [[NSString alloc] initWithData:(NSData*)data encoding:NSUTF8StringEncoding];
				[activeTheme messageClosed:identifier];
				[identifier release];
			}
			break;

		default:
			break;
	}

	return retData;
}

 
static void terminate () {
	CFNotificationCenterRemoveObserver(CFNotificationCenterGetLocalCenter(), &MemoryAlertObserver,
									   (CFStringRef)UIApplicationDidReceiveMemoryWarningNotification, NULL);
	GPStopServer();
	[GPMessageWindow _cleanup];
	[activeTheme release];
	GPFlushPreferences();
}
	
	 
void GPStartGriPServer () {
#if GRIP_JAILBROKEN
	CFStringRef bundleID = CFBundleGetIdentifier(CFBundleGetMainBundle());
	if (kCFCompareEqualTo == CFStringCompare(bundleID, CFSTR("com.apple.springboard"), 0)) {
#endif
	
		if (GPStartServer() != 0) {
			CFShow(CFSTR("Cannot start GriP server -- probably another instance of GriP is already running."));
			return;
		}
		
		GPSetAlternateHandler(&GriPCallback, GriPMessage__Start, GriPMessage__End);
		atexit(&terminate);
		
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		[GPMessageWindow _initialize];
		
		// Notify any waiting MS extensions that GriP is ready.
		CFNotificationCenterRef localCenter = CFNotificationCenterGetLocalCenter();
		
		CFNotificationCenterPostNotification(localCenter, CFSTR("hk.kennytm.GriP.ready"), NULL, NULL, false);
		CFNotificationCenterAddObserver(localCenter, &MemoryAlertObserver, &GPMemoryAlert,
										(CFStringRef)UIApplicationDidReceiveMemoryWarningNotification,
										NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
		
		[pool drain];
		
#if GRIP_JAILBROKEN
	} else {
		PrefsListController_hook();
	}
#endif
}