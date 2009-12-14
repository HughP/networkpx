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
#import <UIKit/UIKit2.h>
#include <notify.h>
#include <mach/mach.h>
#include <mach/message.h>
#import <AppSupport/AppSupport.h>
#include "INXRemoteAction.h"
#include "INXCommon.h"
#include <objc/runtime.h>
#import "INXWindow.h"
#import "INXIcon.h"
#include <pthread.h>

static Ivar SBRemoteNotificationServer_bundleIdentifiersToClients;
static Class _SBApplicationController, _SBRemoteNotificationServer, _SBAlertDisplay, _SBUIController;
//static pthread_once_t std_init_once = PTHREAD_ONCE_INIT;

__attribute__((constructor))
static void std_init () {
#define CLS(x) _##x = objc_getClass(#x)
	CLS(SBApplicationController);
	CLS(SBRemoteNotificationServer);
	CLS(SBAlertDisplay);
	CLS(SBUIController);
#undef CLS
	SBRemoteNotificationServer_bundleIdentifiersToClients = class_getInstanceVariable(_SBRemoteNotificationServer, "_bundleIdentifiersToClients");
	
}

// std::open_url <URL>
extern void open_url(NSArray* argv) {
	if ([argv count] > 1) {
		NSURL* url = [NSURL URLWithString:[argv objectAtIndex:1]];
#if TARGET_IPHONE_SIMULATOR
		[[UIApplication sharedApplication] openURL:url];
#else
		SBAlertDisplay* disp = [[_SBAlertDisplay alloc] init];
		[disp launchURL:url];
		[disp release];
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
			SBApplication* app = [[_SBApplicationController sharedInstance] applicationWithDisplayIdentifier:displayID];
			if (count > 2) {
				[app setActivationSetting:8 flag:YES];	// 8 = remoteNotification.
				SBRemoteNotificationServer* server = [_SBRemoteNotificationServer sharedInstance];
				NSDictionary* clientDict = object_getIvar(server, SBRemoteNotificationServer_bundleIdentifiersToClients);
				SBRemoteNotificationClient* client = [clientDict objectForKey:displayID];
				id userInfo = [[argv objectAtIndex:2] propertyList];
				[client setLastUserInfo:userInfo];
			}
			[[_SBUIController sharedInstance] activateApplicationAnimated:app];
		}
#endif
	}
}

// std::darwin_notification <NotificationName> [<NewState>]
extern void darwin_notification(NSArray* argv) {
	NSString* s[2];
	if (INXRetrieveArguments(argv, s) >= 1) {
		const char* notif = [s[0] UTF8String];
		if (s[1]) {
			int token;
			notify_register_check(notif, &token);
			notify_set_state(token, [s[1] longLongValue]);
			notify_cancel(token);
		}
		notify_post(notif);
	}
}

// std::distributed_message <CenterName> <MessageName> [<UserInfo>]
extern void distributed_message(NSArray* argv) {
	NSString* s[3];
	if (INXRetrieveArguments(argv, s) >= 2) {
		CPDistributedMessagingCenter* center = [CPDistributedMessagingCenter centerNamed:s[0]];
		if (center != nil)
			[center sendMessageName:s[1] userInfo:[s[2] propertyList]];
	}
}

// std::notification <MessageName> [<UserInfo>] [<ObjectPointer>]
extern void notification(NSArray* argv) {
	NSString* s[3];
	if (INXRetrieveArguments(argv, s) >= 1) {
		id objPtr = (id)(void*)(intptr_t)[s[2] intValue];
		[[NSNotificationCenter defaultCenter] postNotificationName:s[0] object:objPtr userInfo:[s[1] propertyList]];
	}
}

// std.sequence (action1) (action2) (action3) ...
extern void sequence(NSArray* argv) {
	BOOL firstPassed = NO;
	for (NSString* arg in argv) {
		if (firstPassed) {
			INXPerformRemoteActionWithCFString((CFStringRef)arg);
		} else {
			firstPassed = YES;
		}
	}
}


__attribute__((visibility("hidden")))
@interface OMGWTFBBQDelegate : NSObject<UIActionSheetDelegate> {
	NSString* _action;
	NSString* _placeholder;
}
@end
@implementation OMGWTFBBQDelegate
-(id)initWithAction:(NSString*)action placeholder:(NSString*)placeholder {
	if ((self = [super init])) {
		_action = [action retain];
	}
	return self;
}
-(void)dealloc {
	[_action release];
	[super dealloc];
}
-(void)actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex != actionSheet.cancelButtonIndex) {
		INXPerformRemoteActionWithCFString((CFStringRef)_action);
	}
	[self release];
}
-(void)omg:(NSString*)resp {
	NSMutableString* mr;
	if (resp) {
		mr = [resp mutableCopy];
		INXEscape((CFMutableStringRef)mr);
		[mr insertString:@"\"" atIndex:0];
		[mr appendString:@"\""];
	} else
		mr = (NSMutableString*)@"\"\"";
	NSString* actual = [_action stringByReplacingOccurrencesOfString:@"%@" withString:mr];
	if (resp)
		[mr release];
	INXPerformRemoteActionWithCFString((CFStringRef)actual);
	[self release];
}
@end

// std.confirm (action) confirmTitle [message] [normal|destructive]
extern void confirm(NSArray* argv) {
	NSString* s[4];
	if (INXRetrieveArguments(argv, s) >= 2) {
		BOOL notDestructive = [s[3] isEqualToString:@"normal"];
		OMGWTFBBQDelegate* del = [[OMGWTFBBQDelegate alloc] initWithAction:s[0]];
		UIActionSheet* sheet = [[UIActionSheet alloc] initWithTitle:s[2]
														   delegate:del
												  cancelButtonTitle:(NSString*)INXLocalizedCancel()
											 destructiveButtonTitle:(notDestructive?nil:s[1])
												  otherButtonTitles:(notDestructive?s[1]:nil), nil];
		[sheet showInView:[INXSuperiorWindow sharedSuperiorWindow]];
		[sheet release];
	}
}

// 1 line prompt
// std.prompt <placeholder> (action with $<placeholder> as that placeholder) [message] [subject] [pic]
extern void prompt(NSArray* argv) {
	NSString* s[4];
	if (INXRetrieveArguments(argv, s) >= 1) {
		OMGWTFBBQDelegate* del = [[OMGWTFBBQDelegate alloc] initWithAction:s[0]];
		UIImage* pic = INXIcon(s[3], INXIconOption_Balloon59x59);
		[[INXSuperiorWindow sharedSuperiorWindow] showsKeyboardWithPromptMessage:s[1] subject:s[2] pic:pic target:del selector:@selector(omg:)];
	}
}

extern void nop(NSArray* argv) {}
