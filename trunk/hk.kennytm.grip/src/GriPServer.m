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
#import <GriP/GPSingleton.h>
#import <GriP/GPMessageQueue.h>

#if GRIP_JAILBROKEN
#import <substrate.h>
__attribute__((visibility("hidden")))
@interface SpringBoard : UIApplication
-(void)applicationOpenURL:(NSURL*)url publicURLsOnly:(BOOL)publicsOnly;	// only in >=3.0
-(void)applicationOpenURL:(NSURL*)url asPanel:(BOOL)asPanel publicURLsOnly:(BOOL)publicsOnly;	// only in <3.0
@end
#else
#import <GriP/GPDefaultTheme.h>
#endif

static NSObject<GPTheme>* activeTheme = nil;
static const int MemoryAlertObserver = 12345678, DisplayOnOffObserver = 87654321;

static CFDataRef GriPCallback (CFMessagePortRef serverPort, SInt32 type, CFDataRef data, void* info) {
	CFDataRef retData = NULL;
	NSArray* array = nil;
	
	switch (type) {
		case GriPMessage_FlushPreferences:
			GPFlushPreferences();
			GPSingletonDestructor(activeTheme, {
				// Currently there's so safe way to force a hard flush.
				// the latest attempt results in this:
				/*
				 #0  0x300c7760 in _unload_image ()
				 #1  0x300c1238 in unmap_image ()
				 #2  0x2fe02eb0 in __dyld__ZN4dyld11removeImageEP11ImageLoader ()
				 #3  0x2fe031a8 in __dyld__ZN4dyld20garbageCollectImagesEv ()
				 #4  0x2fe0a7dc in __dyld_dlclose ()
				 #5  0x3148ee48 in dlclose ()
				 #6  0x3029d93a in _CFBundleDlfcnUnload ()
				 */
				/*
				if (data != NULL) {
					// hard flush required.
					[GPMessageWindow _closeAllWindows];
					Class cls = [__NEWOBJ__ class];
					[__NEWOBJ__ release];
					[[NSBundle bundleForClass:cls] unload];
				} else
				 */
					[__NEWOBJ__ release];
			});
			break;
			
		case GriPMessage_DequeueMessages:
dequeue_messages:
		{
			NSArray* dequeuedMessages = (NSArray*)GPCopyAndDequeueMessages();
			if ([dequeuedMessages count] != 0) {
			
#if GRIP_JAILBROKEN
				GPSingletonConstructor(activeTheme, {
					NSDictionary* prefs = GPCopyPreferences();
					NSBundle* activeThemeBundle = [NSBundle bundleWithPath:[@"/Library/GriP/Themes/" stringByAppendingPathComponent:[prefs objectForKey:@"ActiveTheme"]]];
					[prefs release];
					NSString* themeType = [activeThemeBundle objectForInfoDictionaryKey:@"GPThemeType"];
					if (themeType == nil || [@"OBJC" isEqualToString:themeType])
						__NEWOBJ__ = [[[activeThemeBundle principalClass] alloc] initWithBundle:activeThemeBundle];
				}, [__NEWOBJ__ release]);
#else
				GPSingletonConstructor(activeTheme, __NEWOBJ__ = [[GPDefaultTheme alloc] initWithBundle:[NSBundle mainBundle]], [__NEWOBJ__ release]);
#endif
				for (NSDictionary* messageDict in dequeuedMessages)
					[activeTheme display:messageDict];
			}
			[dequeuedMessages release];
			break;
		}
					
		case GriPMessage_EnqueueMessage: {
			NSMutableDictionary* messageDict = [NSPropertyListSerialization propertyListFromData:(NSData*)data mutabilityOption:NSPropertyListMutableContainers format:NULL errorDescription:NULL];
			GPModifyMessageForUserPreference(messageDict);
			if ([messageDict count] != 0) {
				GPEnqueueMessage((CFDictionaryRef)messageDict);
				goto dequeue_messages;
			}
			
			// fall through as an ignored message if it remains unhandled.
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
			if ([array isKindOfClass:[NSArray class]] && [array count] >= 3)
ignored_message:
			{
				NSString* pid = [array objectAtIndex:0];
				NSData* context = [NSPropertyListSerialization dataFromPropertyList:[array objectAtIndex:1] format:NSPropertyListBinaryFormat_v1_0 errorDescription:NULL];
				BOOL isURL = [[array objectAtIndex:2] boolValue];
				
				if (isURL) {
					if (type != GriPMessage_ClickedNotification)
						break;
					else
						type = GriPMessage_LaunchURL;
				}
				
				if (!GPServerForwardMessage((CFStringRef)pid, type, (CFDataRef)context) && isURL) {
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

#if GRIP_JAILBROKEN
__attribute__((visibility("hidden")))
@interface SBApplication : NSObject
-(NSString*)displayIdentifier;
-(void)launchSucceeded;
-(void)exitedCommon;
-(void)hk_kennytm_grip_launchSucceeded;
-(void)hk_kennytm_grip_exitedCommon;
@end

static void GPUpdateGamingForDisplayID(NSString* displayID);

// I don't know how these will interact with Backgrounder. Hopefully not badly.
static void GP_SBApplication_launchSucceeded(SBApplication* self, SEL _cmd) {
	GPUpdateGamingForDisplayID([self displayIdentifier]);
	[self hk_kennytm_grip_launchSucceeded];
}
static void GP_SBApplication_exitedCommon(SBApplication* self, SEL _cmd) {
	GPUpdateGamingForDisplayID(nil);
	[self hk_kennytm_grip_exitedCommon];
}

static void GPUpdateGamingForDisplayID(NSString* displayID) {
	if (displayID == nil)
		GPSetGaming(false);
	else {
		NSDictionary* prefs = GPCopyPreferences();
		BOOL gaming = [[prefs objectForKey:@"GameModeApps"] containsObject:displayID];
		GPSetGaming(gaming);
		[prefs release];
	}
	GriPCallback(NULL, GriPMessage_DequeueMessages, NULL, NULL);
}
#endif

static void GPMemoryAlert (CFNotificationCenterRef center, void* observer, CFStringRef name, const void* object, CFDictionaryRef userInfo) {
	// basically the same action.
	GriPCallback(NULL, GriPMessage_FlushPreferences, NULL, NULL);
}

static void GPDisplayOnOff (CFNotificationCenterRef center, void* observer, CFStringRef name, const void* object, CFDictionaryRef userInfo) {
	Boolean locked = (CFStringCompare(name, CFSTR("SBDidTurnOnDisplayNotification"), 0) != kCFCompareEqualTo);
	GPSetLocked(locked);
	if (!locked)
		GriPCallback(NULL, GriPMessage_DequeueMessages, NULL, NULL);
}
 
static void terminate () {
	CFNotificationCenterRemoveObserver(CFNotificationCenterGetLocalCenter(), &MemoryAlertObserver,
									   (CFStringRef)UIApplicationDidReceiveMemoryWarningNotification, NULL);
	CFNotificationCenterRemoveEveryObserver(CFNotificationCenterGetDarwinNotifyCenter(), &DisplayOnOffObserver);
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
		
		// Set to suspension when screen is locked.
		// ** Only available for >=2.1 **
		CFNotificationCenterRef darwinCenter = CFNotificationCenterGetDarwinNotifyCenter();
		CFNotificationCenterAddObserver(darwinCenter, &DisplayOnOffObserver, &GPDisplayOnOff, CFSTR("SBDidTurnOnDisplayNotification"), NULL, 0);
		CFNotificationCenterAddObserver(darwinCenter, &DisplayOnOffObserver, &GPDisplayOnOff, CFSTR("SBDidTurnOffDisplayNotification"), NULL, 0);
		
#if GRIP_JAILBROKEN
		Class SBApplication_class = objc_getClass("SBApplication");
		MSHookMessage(SBApplication_class, @selector(launchSucceeded), (IMP)&GP_SBApplication_launchSucceeded, "hk_kennytm_grip_");
		MSHookMessage(SBApplication_class, @selector(exitedCommon), (IMP)&GP_SBApplication_exitedCommon, "hk_kennytm_grip_");
#endif
		
		[pool drain];
		
#if GRIP_JAILBROKEN
	} else {
		PrefsListController_hook();
	}
#endif
}