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
#import <UIKit/UIKit.h>

@implementation GPApplicationBridge
-(void)dealloc {
	if (bridge != NULL)
		GPApplicationBridge_Destroy(bridge);
	[super dealloc];
}
-(id)init {
	if ((self = [super init])) {
		bridge = GPApplicationBridge_Init();
		if (bridge == NULL) {
			[self release];
			return nil;
		}
	}
	return self;
}

@dynamic installed, running;
-(BOOL)isGrowlInstalled { return GPApplicationBridge_CheckInstalled(bridge); }
-(BOOL)isGrowlRunning { return GPApplicationBridge_CheckRunning(bridge); }

@dynamic growlDelegate;
-(void)setGrowlDelegate:(NSObject<GrowlApplicationBridgeDelegate>*)inDelegate {
	GPApplicationBridgeCDelegate del;
	del.object = inDelegate;
	
#define SETDEL(key, sel, type) \
	if ([inDelegate respondsToSelector:@selector(sel)]) \
		del.key = type[inDelegate methodForSelector:@selector(sel)]; \
	else \
		del.key = NULL
	
	SETDEL(registrationDictionary, registrationDictionaryForGrowl, (CFDictionaryRef(*)(CFTypeRef)));
	SETDEL(applicationName,        applicationNameForGrowl,        (CFStringRef(*)(CFTypeRef)));
	SETDEL(ready,                  growlIsReady,                   (void(*)(CFTypeRef)));
	SETDEL(touched,                growlNotificationWasClicked:,   (void(*)(CFTypeRef,void*,CFPropertyListRef)));
	SETDEL(ignored,                growlNotificationTimedOut:,     (void(*)(CFTypeRef,void*,CFPropertyListRef)));
	
#undef SETDEL
	
	GPApplicationBridge_SetDelegate(bridge, del);
}
-(NSObject<GrowlApplicationBridgeDelegate>*)growlDelegate {
	return (NSObject<GrowlApplicationBridgeDelegate>*)GPApplicationBridge_GetDelegate(bridge).object;
}

-(void)notifyWithTitle:(NSString*)title description:(NSString*)description notificationName:(NSString*)notifName iconData:(id)iconData priority:(signed)priority isSticky:(BOOL)isSticky clickContext:(NSObject*)clickContext {
	[self notifyWithTitle:title description:description notificationName:notifName iconData:iconData priority:priority isSticky:isSticky clickContext:clickContext identifier:nil];
}
-(void)notifyWithTitle:(NSString*)title description:(NSString*)description notificationName:(NSString*)notifName iconData:(id)iconData priority:(signed)priority isSticky:(BOOL)isSticky clickContext:(NSObject*)clickContext identifier:(NSString*)identifier {
	if ([iconData isKindOfClass:[UIImage class]])
		iconData = UIImagePNGRepresentation(iconData);
	GPApplicationBridge_SendMessage(bridge, (CFStringRef)title, (CFStringRef)description, (CFStringRef)notifName, iconData, priority, isSticky, (CFPropertyListRef)clickContext, (CFStringRef)identifier);
}

-(void)notifyWithDictionary:(NSDictionary*)userInfo {
	if (![userInfo isKindOfClass:[NSDictionary class]])
		return;
	
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
	return GPApplicationBridge_Register(bridge, (CFDictionaryRef)potentialDictionary);
}

@dynamic enabled;
-(BOOL)enabled { return GPApplicationBridge_CheckEnabled(bridge, NULL); }
-(BOOL)enabledForName:(NSString*)notifName { return GPApplicationBridge_CheckEnabled(bridge, (CFStringRef)notifName); }
@end