/*

GPPreferences.m ... Obtain preferences for GriP.
 
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

#import <GriP/GPPreferences.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <GriP/GrowlDefines.h>
#import <GriP/common.h>
#import <pthread.h>
#import <GraphicsUtilities.h>
#import <GriP/GPSingleton.h>
#import <GriP/GPMessageWindow.h>

static NSDictionary* preferences = nil;
static NSMutableDictionary* cachedTickets = nil;
static pthread_mutex_t appUpdateLock = PTHREAD_MUTEX_INITIALIZER;

NSDictionary* GPCopyPreferences() {
#if GRIP_JAILBROKEN
#define FILEPATH @"/Library/GriP/GPPreferences.plist"
#else
#define FILEPATH [[NSBundle mainBundle] pathForResource:@"GPPreferences" ofType:@"plist" inDirectory:nil]
#endif
	GPSingletonConstructor(preferences, {
		__NEWOBJ__ = [[NSDictionary alloc] initWithContentsOfFile:FILEPATH];
		[GPMessageWindow setMaxWidth:[[__NEWOBJ__ objectForKey:@"Width"] floatValue]];
		[GPMessageWindow setDefaultExpanded:[[__NEWOBJ__ objectForKey:@"DefaultExpanded"] boolValue]];
	}, [__NEWOBJ__ release]);
	return [preferences retain];
}

void GPFlushPreferences() {
	GPSingletonDestructor(preferences, [__NEWOBJ__ release]);
	GPSingletonDestructor(cachedTickets, [__NEWOBJ__ release]);
}

static NSString* GPTicketPathForAppName(NSString* appName) {
#if GRIP_JAILBROKEN
	return [@"/Library/GriP/Tickets/" stringByAppendingPathComponent:[appName stringByAppendingPathExtension:@"ticket"]];
#else
	return [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/%@.ticket", appName]];
#endif
}

static NSDictionary* GPGetTicket(NSString* appName) {
	GPSingletonConstructor(cachedTickets, __NEWOBJ__ = [[NSMutableDictionary alloc] init], [__NEWOBJ__ release]);
	
	// ????????????????????????????????
	NSDictionary* ticket = [[[cachedTickets retain] objectForKey:appName] retain];
#define COMMA ,
	GPSingletonConstructor(ticket, {
		__NEWOBJ__ = [[NSMutableDictionary alloc] initWithContentsOfFile:GPTicketPathForAppName(appName)];
		if (__NEWOBJ__ == nil) {
			static const NSString* const keys[] = {@"enabled" COMMA @"stealth" COMMA @"sticky" COMMA @"messages" COMMA @"log"};
			id values[] = {(NSNumber*)kCFBooleanTrue COMMA (NSNumber*)kCFBooleanFalse COMMA [NSNumber numberWithInteger:0] COMMA [NSMutableDictionary dictionary] COMMA (NSNumber*)kCFBooleanTrue};
			__NEWOBJ__ = [[NSDictionary alloc] initWithObjects:values forKeys:keys count:sizeof(keys)/sizeof(NSString*)];
		}
		[cachedTickets setObject:__NEWOBJ__ forKey:appName];
	}, [__NEWOBJ__ release]);
#undef COMMA
	[ticket release];
	[cachedTickets release];
	// ????????????????????????????????
	
	return ticket;
}

void GPUpdateRegistrationDictionaryForAppName(NSString* appName, NSDictionary* registrationDictionary) {
	NSString* appPath = GPTicketPathForAppName(appName);
	
	// can't think of a lock-free way to do so :)
	pthread_mutex_lock(&appUpdateLock);
	
	NSDictionary* ticket = GPGetTicket(appName);
	BOOL hasModification = NO;
		
	NSMutableDictionary* currentNotifs = [ticket objectForKey:@"messages"];
	NSArray* newNotifs = [registrationDictionary objectForKey:GROWL_NOTIFICATIONS_ALL];
	NSArray* defaultNotifs = [registrationDictionary objectForKey:GROWL_NOTIFICATIONS_DEFAULT];
	NSDictionary* humanReadableNames = [registrationDictionary objectForKey:GROWL_NOTIFICATIONS_HUMAN_READABLE_NAMES];
	NSDictionary* descriptions = [registrationDictionary objectForKey:GROWL_NOTIFICATIONS_DESCRIPTIONS];
	
	NSNumber* zero = [NSNumber numberWithInteger:0];
	
	for (NSString* name in newNotifs) {
		if ([currentNotifs objectForKey:name] == nil) {
			hasModification = YES;
			BOOL enabled = [defaultNotifs containsObject:name];
			NSString* hrName = [humanReadableNames objectForKey:name];
			NSString* desc = [descriptions objectForKey:name];
			static const NSString* const keys[] = {@"friendlyName", @"enabled", @"stealth", @"sticky", @"priority", @"log", @"description"};
			id values[] = {hrName, (NSNumber*)(enabled ? kCFBooleanTrue : kCFBooleanFalse), (NSNumber*)kCFBooleanFalse, zero, zero, (NSNumber*)kCFBooleanTrue, desc};
			
			int size = sizeof(keys)/sizeof(NSString*);
			id* thisKeys = keys, *thisValues = values;
			if (hrName == nil) {
				++ thisValues;
				++ thisKeys;
				-- size;
			}
			if (desc == nil)
				-- size;
			
			[currentNotifs setObject:[NSDictionary dictionaryWithObjects:thisValues forKeys:thisKeys count:size] forKey:name];
		}
	}
	if (hasModification) {
		[ticket writeToFile:appPath atomically:YES];
		[[NSFileManager defaultManager] changeFileAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
															  @"mobile", NSFileGroupOwnerAccountName,
															  @"mobile", NSFileOwnerAccountName,
															  [NSNumber numberWithUnsignedLong:0666], NSFilePosixPermissions,
															  nil]
													  atPath:appPath];
	}
	
	pthread_mutex_unlock(&appUpdateLock);
}

#define EnabledWithStealth(dict) ([[(dict) objectForKey:@"enabled"] boolValue] || (respectStealth && [[(dict) objectForKey:@"stealth"] boolValue]))
static BOOL GPCheckEnabledWithTicket(NSDictionary* ticket, NSString* msgName, NSDictionary** pMsgDict, BOOL respectStealth) {
	if (ticket == nil || !EnabledWithStealth(ticket))
		return NO;
	if (msgName == nil)
		return YES;
	NSDictionary* msgDict = [[ticket objectForKey:@"messages"] objectForKey:msgName];
	if (pMsgDict != NULL)
		*pMsgDict = msgDict;
	if (msgDict == nil || !EnabledWithStealth(msgDict))
		return NO;
	return YES;
}
#undef EnabledWithStealth

void GPModifyMessageForUserPreference(NSMutableDictionary* message) {
	NSString* appName = [message objectForKey:GRIP_APPNAME];
	NSDictionary* ticket = GPGetTicket(appName);
	NSString* msgName = [message objectForKey:GRIP_NAME];
	NSDictionary* msgDict;

	if (appName == nil || msgName == nil || !GPCheckEnabledWithTicket(ticket, msgName, &msgDict, NO)) {
		[message removeAllObjects];
		return;
	}
	
	// change the identifier to app-specific. 
	NSString* identifier = [message objectForKey:GRIP_ID];
	if (identifier != nil) {
		[message setObject:[NSString stringWithFormat:@"%@\uFDD0%@", appName, identifier] forKey:GRIP_ID];
	}
	
	NSInteger newPriority = [[msgDict objectForKey:@"priority"] integerValue];
	if (newPriority >= 1 && newPriority <= 5) {
		newPriority -= 3;
		[message setObject:[NSNumber numberWithInteger:newPriority] forKey:GRIP_PRIORITY];
	} else
		newPriority = [[message objectForKey:GRIP_PRIORITY] integerValue];
	
	NSDictionary* prefs = GPCopyPreferences();
	NSArray* priorityArray = [[prefs objectForKey:@"PerPrioritySettings"] objectAtIndex:newPriority+2];
	[prefs release];
	// Disable this message the priority is disabled.
	if (![[priorityArray objectAtIndex:GPPrioritySettings_Enabled] boolValue]) {
		[message removeAllObjects];
		return;
	}
	
	NSInteger stickyEnabled = [[msgDict objectForKey:@"sticky"] integerValue];
	if (stickyEnabled == 0)
		stickyEnabled = [[ticket objectForKey:@"sticky"] integerValue];
	if (stickyEnabled == 0)
		stickyEnabled = [[priorityArray objectAtIndex:GPPrioritySettings_Sticky] integerValue];
	
	if (stickyEnabled == 1)
		[message setObject:[NSNumber numberWithBool:YES] forKey:GRIP_STICKY];
	else if (stickyEnabled != 0)
		[message setObject:[NSNumber numberWithBool:NO] forKey:GRIP_STICKY];
}

BOOL GPCheckEnabled(NSString* appName, NSString* msgName, BOOL respectStealth) {
	return appName != nil && GPCheckEnabledWithTicket(GPGetTicket(appName), msgName, NULL, respectStealth);
}

void GPCopyColorsForPriority(int priority, UIColor** outBGColor, UIColor** outFGColor) {
	if (priority < -2) priority = -2;
	if (priority > 2) priority = 2;
	
	NSDictionary* prefs = GPCopyPreferences();
	NSArray* colorArray = [[prefs objectForKey:@"PerPrioritySettings"] objectAtIndex:(priority+2)];
	CGFloat red = [[colorArray objectAtIndex:GPPrioritySettings_Red] floatValue];
	CGFloat green = [[colorArray objectAtIndex:GPPrioritySettings_Green] floatValue];
	CGFloat blue = [[colorArray objectAtIndex:GPPrioritySettings_Blue] floatValue];
	CGFloat alpha = [[colorArray objectAtIndex:GPPrioritySettings_Alpha] floatValue];
	[prefs release];
	
	if (outBGColor != NULL)
		*outBGColor = [[UIColor alloc] initWithRed:red green:green blue:blue alpha:alpha];
	
	if (outFGColor != NULL) {
		CGFloat luminance = GULuminance(red, green, blue);
		*outFGColor = [(luminance > 0.5f ? [UIColor blackColor] : [UIColor whiteColor]) retain];
	}
}