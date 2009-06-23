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
#import <GriP/GPApplicationBridge.h>
#import <UIKit/UIApplication.h>
#import <GriP/GPSingleton.h>
#import <GriP/GPMessageQueue.h>
#import <GriP/GPModalTableViewServer.h>
#import <GriP/GPMessageLog.h>
#import <GriP/GPMessageLogUI.h>

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
static GPApplicationBridge* loopbackBridge = nil;

static CFDataRef GriPCallback (CFMessagePortRef serverPort, SInt32 type, CFDataRef data, void* info) {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
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
			NSArray* dequeuedMessages = (NSArray*)GPCopyAndDequeueMessages(0);
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
				CFMutableArrayRef dequeuedMessageUIDs = CFArrayCreateMutable(NULL, 0, NULL);
				for (NSDictionary* messageDict in dequeuedMessages) {
					CFArrayAppendValue(dequeuedMessageUIDs, [messageDict objectForKey:GRIP_MSGUID]);
					[activeTheme display:messageDict];
				}
				GPMessageLogShowMessages(dequeuedMessageUIDs);
				CFRelease(dequeuedMessageUIDs);
			}
			[dequeuedMessages release];
			break;
		}
					
		case GriPMessage_EnqueueMessage: {
			NSMutableDictionary* messageDict = [NSPropertyListSerialization propertyListFromData:(NSData*)data mutabilityOption:NSPropertyListMutableContainers format:NULL errorDescription:NULL];
			GPMessageLogAddMessage((CFMutableDictionaryRef)messageDict);
			array = [messageDict objectsForKeys:[NSArray arrayWithObjects:GRIP_PID, GRIP_CONTEXT, GRIP_ISURL, GRIP_MSGUID, nil] notFoundMarker:(NSNumber*)kCFBooleanFalse];
			
			GPModifyMessageForUserPreference(messageDict);
			if ([messageDict count] != 0) {
				NSArray* dismissedMessages = (NSArray*)GPEnqueueMessage((CFDictionaryRef)messageDict);
				CFMutableArrayRef dismissedMessageUIDs[2] = {CFArrayCreateMutable(NULL, 0, NULL), CFArrayCreateMutable(NULL, 0, NULL)};				
				for (NSDictionary* message in dismissedMessages) {
					int priorityIndex = [[message objectForKey:GRIP_PRIORITY] integerValue]+2;
					CFNotificationSuspensionBehavior suspensionBehavior = GPCurrentSuspensionBehaviorForPriorityIndex(priorityIndex);
					NSArray* arr = [message objectsForKeys:[NSArray arrayWithObjects:GRIP_PID, GRIP_CONTEXT, GRIP_ISURL, (NSNull*)kCFNull, nil] notFoundMarker:(NSNumber*)kCFBooleanFalse];
					NSData* arrData = [NSPropertyListSerialization dataFromPropertyList:arr format:NSPropertyListBinaryFormat_v1_0 errorDescription:NULL];
					GriPCallback(NULL, suspensionBehavior == CFNotificationSuspensionBehaviorCoalesce ? GriPMessage_CoalescedNotification : GriPMessage_IgnoredNotification,
								 (CFDataRef)arrData, NULL);
					CFArrayAppendValue(dismissedMessageUIDs[suspensionBehavior == CFNotificationSuspensionBehaviorCoalesce ? 1 : 0], [message objectForKey:GRIP_MSGUID]);
				}
				GPMessageLogResolveMessages(dismissedMessageUIDs[0], GriPMessage_IgnoredNotification);
				GPMessageLogResolveMessages(dismissedMessageUIDs[1], GriPMessage_CoalescedNotification);
				CFRelease(dismissedMessageUIDs[0]);
				CFRelease(dismissedMessageUIDs[1]);
				[dismissedMessages release];
				goto dequeue_messages;
			}
			
			// fall through as an ignored message if it remains unhandled.
			type = GriPMessage_IgnoredNotification;
			if (array == nil)
				break;
			
			goto ignored_message;
		}
			
		case GriPMessage_ResolveMultipleMessages:
			array = [NSPropertyListSerialization propertyListFromData:(NSData*)data mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:NULL];
			if ([array isKindOfClass:[NSArray class]] && [array count] >= 3) {
				SInt32 notifType = [[array objectAtIndex:0] integerValue];
				for (NSData* dataToSend in [array objectAtIndex:2])
					GriPCallback(NULL, notifType, (CFDataRef)dataToSend, NULL);
				GPMessageLogResolveMessages((CFArrayRef)[array objectAtIndex:1], notifType);
			}
			break;
			
		case GriPMessage_ClickedNotification:
		case GriPMessage_IgnoredNotification:
		case GriPMessage_CoalescedNotification:
			array = [NSPropertyListSerialization propertyListFromData:(NSData*)data mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:NULL];
			if ([array isKindOfClass:[NSArray class]] && [array count] >= 4)
ignored_message:
			{
				NSObject* contextObject = [array objectAtIndex:1];
				
				NSString* pid = [array objectAtIndex:0];
				NSData* context = [NSPropertyListSerialization dataFromPropertyList:contextObject format:NSPropertyListBinaryFormat_v1_0 errorDescription:NULL];
				BOOL isURL = [[array objectAtIndex:2] boolValue];
				NSString* lastObject = [array lastObject];
				if ((CFBooleanRef)lastObject != kCFBooleanFalse)
					GPMessageLogResolveMessages((CFArrayRef)[NSArray arrayWithObject:lastObject], type);
				
				if (contextObject == (NSNull*)kCFBooleanFalse)
					break;
				
				if (isURL) {
					if (type != GriPMessage_ClickedNotification)
						break;
					else
						type = GriPMessage_LaunchURL;
				}
				
				if (!GPServerForwardMessage((CFStringRef)pid, type, (CFDataRef)context, NULL) && isURL) {
					NSURL* url = [NSURL URLWithString:(NSString*)[array objectAtIndex:1]];
#if GRIP_JAILBROKEN
					SpringBoard* springBoard = (SpringBoard*)[UIApplication sharedApplication];
					if ([springBoard respondsToSelector:@selector(applicationOpenURL:asPanel:publicURLsOnly:)])
						[springBoard applicationOpenURL:url asPanel:NO publicURLsOnly:NO];
					else if ([springBoard respondsToSelector:@selector(applicationOpenURL:publicURLsOnly:)])
						[springBoard applicationOpenURL:url publicURLsOnly:NO];
					else
#endif
						[[UIApplication sharedApplication] openURL:url];
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
					retval = GPCheckEnabled(appName, appMsg, YES);
				}
			}
			retData = CFDataCreate(NULL, (const UInt8*)&retval, sizeof(BOOL));
			break;
		}
			
		case GriPMessage_ShowMessageLog:
			GPMessageLogShow(loopbackBridge, @"Show Message Log");
			break;
			
		default:
			break;
	}

	[pool drain];
	return retData;
}

#if GRIP_JAILBROKEN
static IMP original_launchSucceeded = NULL, original_exitedCommon = NULL;

__attribute__((visibility("hidden")))
@interface SBApplication : NSObject
-(NSString*)displayIdentifier;
@end

static void GPUpdateGamingForDisplayID(NSString* displayID);

// I don't know how these will interact with Backgrounder. Hopefully not badly.
static void GP_SBApplication_launchSucceeded(SBApplication* self, SEL _cmd, BOOL unknown) {
	GPUpdateGamingForDisplayID([self displayIdentifier]);
	original_launchSucceeded(self, _cmd, unknown);
}
static void GP_SBApplication_exitedCommon(SBApplication* self, SEL _cmd) {
	GPUpdateGamingForDisplayID(nil);
	original_exitedCommon(self, _cmd);
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

static void GPDisplayOnOff (CFNotificationCenterRef center, void* observer, CFStringRef name, const void* object, CFDictionaryRef userInfo) {
	Boolean locked = (CFStringCompare(name, CFSTR("SBDidTurnOnDisplayNotification"), 0) != kCFCompareEqualTo);
	GPSetLocked(locked);
	if (!locked)
		GriPCallback(NULL, GriPMessage_DequeueMessages, NULL, NULL);
}

static void terminate () {
	[loopbackBridge release];
	CFNotificationCenterRemoveObserver(CFNotificationCenterGetLocalCenter(), &MemoryAlertObserver,
									   (CFStringRef)UIApplicationDidReceiveMemoryWarningNotification, NULL);
	CFNotificationCenterRemoveEveryObserver(CFNotificationCenterGetDarwinNotifyCenter(), &DisplayOnOffObserver);
	GPStopServer();
	GPStopModalTableViewServer();
	[GPMessageWindow _cleanup];
	[activeTheme release];
	GPFlushPreferences();
}
	
	 
void GPStartGriPServer () {
		if (GPStartServer() != 0) {
			CFShow(CFSTR("Cannot start GriP server -- probably another instance of GriP is already running."));
			return;
		}
	
	GPMessageLogStartNewSession();
		
		GPSetAlternateHandler(&GriPCallback, GriPMessage__Start, GriPMessage__End);
		if (objc_getClass("GPModalTableViewNavigationController") != Nil) {
			GPSetAlternateHandler(&GPModalTableViewServerCallback, GPTVAMessage__Start, GPTVAMessage__End);
		}
		atexit(&terminate);
		
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		[GPMessageWindow _initialize];
		
		// Notify any waiting MS extensions that GriP is ready.
		CFNotificationCenterRef localCenter = CFNotificationCenterGetLocalCenter();		
		CFNotificationCenterPostNotification(localCenter, CFSTR("hk.kennytm.GriP.ready"), NULL, NULL, false);
		
		// Set to suspension when screen is locked.
		// ** Only available for >=2.1 **
		CFNotificationCenterRef darwinCenter = CFNotificationCenterGetDarwinNotifyCenter();
		CFNotificationCenterAddObserver(darwinCenter, &DisplayOnOffObserver, &GPDisplayOnOff, CFSTR("SBDidTurnOnDisplayNotification"), NULL, 0);
		CFNotificationCenterAddObserver(darwinCenter, &DisplayOnOffObserver, &GPDisplayOnOff, CFSTR("SBDidTurnOffDisplayNotification"), NULL, 0);
		
#if GRIP_JAILBROKEN
		Class SBApplication_class = objc_getClass("SBApplication");
	SEL whichLaunchSucceeded = [SBApplication_class instancesRespondToSelector:@selector(launchSucceeded:)] ? @selector(launchSucceeded:) : @selector(launchSucceeded);
	original_launchSucceeded = MSHookMessage(SBApplication_class, whichLaunchSucceeded, (IMP)&GP_SBApplication_launchSucceeded, NULL);
		original_exitedCommon = MSHookMessage(SBApplication_class, @selector(exitedCommon), (IMP)&GP_SBApplication_exitedCommon, NULL);
#endif
		GPStartModalTableViewServer();
	
	NSArray* loopbackMessages = [NSArray arrayWithObject:@"Show Message Log"];
	loopbackBridge = [[GPApplicationBridge alloc] init];
	[loopbackBridge registerWithDictionary:[NSDictionary dictionaryWithObjectsAndKeys:
											@"GriP SpringBoard Hook", GROWL_APP_NAME,
											loopbackMessages, GROWL_NOTIFICATIONS_ALL,
											loopbackMessages, GROWL_NOTIFICATIONS_DEFAULT,
											nil]];
	
		[pool drain];
}