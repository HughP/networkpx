/*

GPApplicationBridge.m ... GriP Application Bridge
 
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
#import <GriP/Duplex/Client.h>
#import <GriP/common.h>
#import <UIKit/UIKit.h>

@interface GPApplicationBridge ()
-(void)messageClickedOrIgnored:(NSData*)contextData type:(SInt32)type;
@end


@implementation GPApplicationBridge
-(void)dealloc {
	[sharedDelegate release];
	[cachedRegistrationDictionary release];
	[appName release];
	[duplex release];
	[super dealloc];
}
-(id)init {
	if ((self = [super init])) {
		NSBundle* mainBundle = [NSBundle mainBundle];
		if (cachedRegistrationDictionary == nil) {
			NSString* regDictPath = [mainBundle pathForResource:@"Growl Registration Ticket" ofType:@"growlRegDict"];
			if (regDictPath != nil) 
				cachedRegistrationDictionary = [[NSDictionary alloc] initWithContentsOfFile:regDictPath];
		}
		if (appName == nil) {
			appName = [[mainBundle objectForInfoDictionaryKey:@"CFBundleExecutableName"] retain];
			if (![appName isKindOfClass:[NSString class]]) {
				[appName release];
				appName = nil;
			}
		}
		if (duplex == nil) {
			duplex = [[GPDuplexClient alloc] init];
			if (duplex == nil) {
				NSLog(@"GPTryInitialize: Cannot initialize duplex client. Is GriP installed?");
			} else {
				[duplex addObserver:self selector:@selector(messageClickedOrIgnored:type:) forMessage:GriPMessage_ClickedNotification];
				[duplex addObserver:self selector:@selector(messageClickedOrIgnored:type:) forMessage:GriPMessage_IgnoredNotification];
			}
		}
	}
	return self;
}

-(void)messageClickedOrIgnored:(NSData*)contextData type:(SInt32)type {
	NSObject* context = [NSPropertyListSerialization propertyListFromData:contextData mutabilityOption:kCFPropertyListImmutable format:NULL errorDescription:NULL];
	if (context != nil) {
		if (type == GriPMessage_ClickedNotification) {
			if ([sharedDelegate respondsToSelector:@selector(growlNotificationWasClicked:)])
				[sharedDelegate growlNotificationWasClicked:context];
		} else {
			if ([sharedDelegate respondsToSelector:@selector(growlNotificationTimedOut:)])
				[sharedDelegate growlNotificationTimedOut:context];
		}
	}
}

@dynamic installed, running;
-(BOOL)isGrowlInstalled {
	// FIXME: Find some SDK-compatible check to give an accurate result.
	return [self isGrowlRunning];
}
-(BOOL)isGrowlRunning {
	// FIXME: Currently this check relies on the fact that only GriP has implemented the GPDuplexClient class.
	//        what if other people are start using it? Then this method is no longer useful.
	return duplex != nil;
}
@synthesize growlDelegate=sharedDelegate;
-(void)setGrowlDelegate:(NSObject<GrowlApplicationBridgeDelegate>*)inDelegate {
	if (![self isGrowlRunning])
		return;
	
	if (sharedDelegate != inDelegate) {
		[sharedDelegate release];
		sharedDelegate = [inDelegate retain];
	}
	
	// try to replace the reg dict.
	if ([inDelegate respondsToSelector:@selector(registrationDictionaryForGrowl)])
		[self registerWithDictionary:[inDelegate registrationDictionaryForGrowl]];
	
	// try to replace app name.
	if ([inDelegate respondsToSelector:@selector(applicationNameForGrowl)]) {
		NSString* potentialAppName = [inDelegate applicationNameForGrowl];
		if ([potentialAppName isKindOfClass:[NSString class]]) {
			[appName release];
			appName = [potentialAppName retain];
		}
	}
	
	// we don't care about the app icon.
	
	// tell the delegate we're ready.
	if ([inDelegate respondsToSelector:@selector(growlIsReady)])
		[inDelegate growlIsReady];
}

-(void)notifyWithTitle:(NSString*)title description:(NSString*)description notificationName:(NSString*)notifName iconData:(NSObject*)iconData priority:(signed)priority isSticky:(BOOL)isSticky clickContext:(NSObject*)clickContext {
	[self notifyWithTitle:title description:description notificationName:notifName iconData:iconData priority:priority isSticky:isSticky clickContext:clickContext identifier:nil];
}

-(void)notifyWithTitle:(NSString*)title description:(NSString*)description notificationName:(NSString*)notifName iconData:(NSObject*)iconData priority:(signed)priority isSticky:(BOOL)isSticky clickContext:(NSObject*)clickContext identifier:(NSString*)identifier {
	if (duplex == nil)
		return;
	
	NSMutableDictionary* filteredDictionary = [[NSMutableDictionary alloc] init];
	[filteredDictionary setObject:duplex.name forKey:GRIP_PID];
	
	if ([title isKindOfClass:[NSString class]])
		[filteredDictionary setObject:title forKey:GRIP_TITLE];
	if ([description isKindOfClass:[NSString class]])
		[filteredDictionary setObject:description forKey:GRIP_DETAIL];
	if ([notifName isKindOfClass:[NSString class]])
		[filteredDictionary setObject:notifName forKey:GRIP_NAME];
	if ([iconData isKindOfClass:[UIImage class]])
		[filteredDictionary setObject:UIImagePNGRepresentation((UIImage*)iconData) forKey:GRIP_ICON];
	else if ([iconData isKindOfClass:[NSData class]] || [iconData isKindOfClass:[NSString class]])
		[filteredDictionary setObject:iconData forKey:GRIP_ICON];
	if (priority < -2) priority = -2;
	if (priority > 2) priority = 2;
	[filteredDictionary setObject:[NSNumber numberWithInteger:priority] forKey:GRIP_PRIORITY];
	[filteredDictionary setObject:[NSNumber numberWithBool:isSticky] forKey:GRIP_STICKY];
	if (clickContext != nil) {
		NSString* errorDescription = nil;
		NSData* contextData = [NSPropertyListSerialization dataFromPropertyList:clickContext format:NSPropertyListBinaryFormat_v1_0 errorDescription:&errorDescription];
		if (contextData == nil) {
			NSLog(@"clickContext cannot be serialized into property list data: %@.", errorDescription);
			[errorDescription release];
		} else
			[filteredDictionary setObject:contextData forKey:GRIP_CONTEXT];
	}
	if ([identifier isKindOfClass:[NSString class]])
		[filteredDictionary setObject:identifier forKey:GRIP_ID];
	
	[duplex sendMessage:GriPMessage_ShowMessage data:[NSPropertyListSerialization dataFromPropertyList:filteredDictionary format:NSPropertyListBinaryFormat_v1_0 errorDescription:NULL]];
	
	[filteredDictionary release];
}

-(void)notifyWithDictionary:(NSDictionary*)userInfo {
	NSNumber* priority = [userInfo objectForKey:GROWL_NOTIFICATION_PRIORITY];
	signed numericPriority = 0;
	if ([priority respondsToSelector:@selector(integerValue)])
		numericPriority = [priority integerValue];
	
	NSNumber* sticky = [userInfo objectForKey:GROWL_NOTIFICATION_STICKY];
	BOOL numericSticky = NO;
	if ([sticky respondsToSelector:@selector(boolValue)] && [sticky boolValue])
		numericSticky = YES;
	
	[self notifyWithTitle:[userInfo objectForKey:GROWL_NOTIFICATION_TITLE]
			  description:[userInfo objectForKey:GROWL_NOTIFICATION_DESCRIPTION]
		 notificationName:[userInfo objectForKey:GROWL_NOTIFICATION_NAME]
				 iconData:[userInfo objectForKey:GROWL_NOTIFICATION_ICON]
				 priority:numericPriority
				 isSticky:numericSticky
			 clickContext:[userInfo objectForKey:GROWL_NOTIFICATION_CLICK_CONTEXT]
			   identifier:[userInfo objectForKey:GROWL_NOTIFICATION_IDENTIFIER]];
}

-(BOOL)registerWithDictionary:(NSDictionary*)potentialDictionary {
	if ([potentialDictionary isKindOfClass:[NSDictionary class]] &&
		[[potentialDictionary objectForKey:GROWL_NOTIFICATIONS_ALL] isKindOfClass:[NSArray class]] &&
		[[potentialDictionary objectForKey:GROWL_NOTIFICATIONS_DEFAULT] isKindOfClass:[NSArray class]]) {
		[cachedRegistrationDictionary release];
		cachedRegistrationDictionary = [potentialDictionary retain];
		return YES;
	}
	return NO;
}

@end


@implementation NSURL (GriP_DelegateSupport)
-(void)growlNotificationWasClicked:(NSObject*)context {
	UIApplication* app = [UIApplication sharedApplication];
	if (app == nil)
		app = [[[UIApplication alloc] init] autorelease];
	[app openURL:self];
}
@end