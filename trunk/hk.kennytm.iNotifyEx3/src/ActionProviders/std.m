/*
 
std.m ... Action provider for standard actions.

Copyright (c) 2009  KennyTM~ <kennytm@gmail.com>
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

#import <SpringBoard/SpringBoard.h>
#import <UIKit/UIApplication2.h>
#include <notify.h>
#include <mach/mach.h>
#include <mach/message.h>
#import <AppSupport/AppSupport.h>
#include "INXRemoteAction.h"
#include "INXCommon.h"
#include <objc/runtime.h>

// std::open_url <URL>
extern void open_url(NSArray* argv) {
	if ([argv count] > 1) {
		NSURL* url = [NSURL URLWithString:[argv objectAtIndex:1]];
#if TARGET_IPHONE_SIMULATOR
		[[UIApplication sharedApplication] openURL:url];
#else
		[[UIApplication sharedApplication] applicationOpenURL:url];
#endif
	}
}

// std::launch <DisplayID> [<RemoteNotification>]
extern void launch(NSArray* argv) {
	NSUInteger count = [argv count];
	if (count > 1) {
		NSString* displayID = [argv objectAtIndex:1];
#if TARGET_IPHONE_SIMULATOR
		[[UIApplication sharedApplication] launchApplicationWithIdentifier:displayID suspended:NO];
#else
		NSArray* parentalControl = [(SpringBoard*)[UIApplication sharedApplication] parentalControlsDisabledApplications];
		if (![parentalControl containsObject:displayID]) {
			SBApplication* app = [[objc_getClass("SBApplicationController") sharedInstance] applicationWithDisplayIdentifier:displayID];
			if (count > 2) {
				[app setActivationSetting:8 flag:YES];	// 8 = remoteNotification.
				SBRemoteNotificationServer* server = [objc_getClass("SBRemoteNotificationServer") sharedInstance];
				NSDictionary* clientDict = [server valueForKey:@"bundleIdentifiersToClients"];
				SBRemoteNotificationClient* client = [clientDict objectForKey:displayID];
				CFPropertyListRef userInfo = INXCreateDictionaryWithString((CFStringRef)[argv objectAtIndex:2]);
				[client setLastUserInfo:(NSDictionary*)userInfo];
				if (userInfo != NULL)
					CFRelease(userInfo);
			}
			[[objc_getClass("SBUIController") sharedInstance] activateApplicationAnimated:app];
		}
#endif
	}
}

// std::darwin_notification <NotificationName>
extern void darwin_notification(NSArray* argv) {
	if ([argv count] > 1)
		notify_post([[argv objectAtIndex:1] UTF8String]);
}

// std::distributed_message <CenterName> <MessageName> [<UserInfo>]
extern void distributed_message(NSArray* argv) {
	size_t len = [argv count];
	if (len >= 3) {
		NSString* s[3];
		s[2] = nil;
		[argv getObjects:s range:NSMakeRange(1, len<=3?2:3)];
		
		CPDistributedMessagingCenter* center = [CPDistributedMessagingCenter centerNamed:s[0]];
		if (center != nil) {
			CFPropertyListRef userInfo = INXCreateDictionaryWithString((CFStringRef)s[2]);
			[center sendMessageName:s[1] userInfo:(NSDictionary*)userInfo];
			if (userInfo != NULL)
				CFRelease(userInfo);
		}
	}
}

// std::notification <MessageName> [<UserInfo>] [<ObjectPointer>]
extern void notification(NSArray* argv) {
	size_t len = [argv count];
	if (len >= 2) {
		NSString* s[3];
		s[1] = s[2] = nil;
		[argv getObjects:s range:NSMakeRange(1, len>=4?3:len-1)];
		
		id objPtr = (id)(void*)(intptr_t)[s[2] intValue];
		CFPropertyListRef userInfo = INXCreateDictionaryWithString((CFStringRef)s[1]);
		[[NSNotificationCenter defaultCenter] postNotificationName:s[0] object:objPtr userInfo:(NSDictionary*)userInfo];
		if (userInfo != NULL)
			CFRelease(userInfo);
	}
}

extern void sequence(NSArray* argv) {
	BOOL firstPassed = NO;
	for (NSString* arg in argv) {
		if (firstPassed) {
			INXPerformRemoteAction([arg UTF8String]);
		} else {
			firstPassed = YES;
		}

	}
}