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

#include <GriP/GPPreferences.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <GriP/GrowlDefines.h>
#import <GriP/common.h>
#import <pthread.h>
#import <GraphicsUtilities.h>

static NSDictionary* preferences = nil;
static NSMutableDictionary* tickets = nil;
static pthread_mutex_t prefLock = PTHREAD_MUTEX_INITIALIZER, appLock = PTHREAD_MUTEX_INITIALIZER;

NSDictionary* GPPreferences() {
	pthread_mutex_lock(&prefLock);
	if (preferences == nil)
#if GRIP_JAILBROKEN
		preferences = [[NSDictionary alloc] initWithContentsOfFile:@"/Library/GriP/GPPreferences.plist"];
#else
		preferences = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"GPPreferences" ofType:@"plist" inDirectory:nil]];
#endif
	pthread_mutex_unlock(&prefLock);
	return preferences;
}

void GPFlushPreferences() {
	pthread_mutex_lock(&prefLock);
	[preferences release];
	preferences = nil;
	pthread_mutex_unlock(&prefLock);
	pthread_mutex_lock(&appLock);
	[tickets release];
	tickets = nil;
	pthread_mutex_unlock(&appLock);
}

static NSMutableDictionary* GPTickets () {
	pthread_mutex_lock(&appLock);
	if (tickets == nil)
		tickets = [[NSMutableDictionary alloc] init];
	pthread_mutex_unlock(&appLock);
	return tickets;
}

static NSString* GPTicketPathForAppName(NSString* appName) {
#if GRIP_JAILBROKEN
	return [@"/Library/GriP/Tickets/" stringByAppendingPathComponent:[appName stringByAppendingPathExtension:@"ticket"]];
#else
	return [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/%@.ticket", appName]];
#endif
}

void GPUpdateRegistrationDictionaryForAppName(NSString* appName, NSDictionary* registrationDictionary) {
	NSString* appPath = GPTicketPathForAppName(appName);
	NSMutableDictionary* ticket = [[GPTickets() objectForKey:appName] retain];
	BOOL hasModification = NO;
	NSNumber* ZERO = [NSNumber numberWithInteger:0];
	
	if (ticket == nil) {
		// Set default data for a new ticket.
		hasModification = YES;
		ticket = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
				  (NSNumber*)kCFBooleanTrue, @"enabled",
				  (NSNumber*)kCFBooleanFalse, @"stealth",
				  ZERO, @"sticky",	// 0 = application defined, 1 = always sticky, else = always hide.
				  [NSMutableDictionary dictionary], @"messages",
				  (NSNumber*)kCFBooleanTrue, @"log",
				  nil];
	}
	
	NSMutableDictionary* currentNotifs = [ticket objectForKey:@"messages"];
	NSArray* newNotifs = [registrationDictionary objectForKey:GROWL_NOTIFICATIONS_ALL];
	NSArray* defaultNotifs = [registrationDictionary objectForKey:GROWL_NOTIFICATIONS_DEFAULT];
	NSDictionary* humanReadableNames = [registrationDictionary objectForKey:GROWL_NOTIFICATIONS_HUMAN_READABLE_NAMES];
	NSDictionary* descriptions = [registrationDictionary objectForKey:GROWL_NOTIFICATIONS_DESCRIPTIONS];
	
	for (NSString* name in newNotifs) {
		if ([currentNotifs objectForKey:name] == nil) {
			hasModification = YES;
			BOOL enabled = [defaultNotifs containsObject:name];
			NSString* hrName = [humanReadableNames objectForKey:name];
			NSString* desc = [descriptions objectForKey:name];
			NSMutableDictionary* messageDict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
												[NSNumber numberWithBool:enabled], @"enabled",
												kCFBooleanFalse, @"stealth",
												ZERO, @"sticky",
												ZERO, @"priority",
												kCFBooleanTrue, @"log",
												nil];
			if (hrName != nil)
				[messageDict setObject:hrName forKey:@"friendlyName"];
			if (desc != nil)
				[messageDict setObject:desc forKey:@"description"];
			
			[currentNotifs setObject:messageDict forKey:name];
			[messageDict release];
		}
	}
	if (hasModification)
		[ticket writeToFile:appPath atomically:YES];
	
	[GPTickets() setObject:ticket forKey:appName];
	
	[ticket release];
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
	NSDictionary* ticket = [GPTickets() objectForKey:appName];
	NSString* msgName = [message objectForKey:GRIP_NAME];
	NSDictionary* msgDict;

	if (appName == nil || msgName == nil || !GPCheckEnabledWithTicket(ticket, msgName, &msgDict, NO)) {
		[message removeAllObjects];
		return;
	}
	
	NSInteger newPriority = [[msgDict objectForKey:@"priority"] integerValue];
	if (newPriority >= 1 && newPriority <= 5) {
		newPriority -= 3;
		[message setObject:[NSNumber numberWithInteger:newPriority] forKey:GRIP_PRIORITY];
	} else
		newPriority = [[message objectForKey:GRIP_PRIORITY] integerValue];
	
	NSArray* priorityArray = [[GPPreferences() objectForKey:@"PerPrioritySettings"] objectAtIndex:newPriority+2];
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

BOOL GPCheckEnabled(NSString* appName, NSString* msgName) {
	return appName != nil && GPCheckEnabledWithTicket([GPTickets() objectForKey:appName], msgName, NULL, YES);
}

void GPCopyColorsForPriority(int priority, UIColor** outBGColor, UIColor** outFGColor) {
	if (priority < -2) priority = -2;
	if (priority > 2) priority = 2;
	
	NSArray* colorArray = [[GPPreferences() objectForKey:@"PerPrioritySettings"] objectAtIndex:(priority+2)];
	CGFloat red = [[colorArray objectAtIndex:GPPrioritySettings_Red] floatValue];
	CGFloat green = [[colorArray objectAtIndex:GPPrioritySettings_Green] floatValue];
	CGFloat blue = [[colorArray objectAtIndex:GPPrioritySettings_Blue] floatValue];
	CGFloat alpha = [[colorArray objectAtIndex:GPPrioritySettings_Alpha] floatValue];
	
	if (outBGColor != NULL)
		*outBGColor = [[UIColor alloc] initWithRed:red green:green blue:blue alpha:alpha];
	
	if (outFGColor != NULL) {
		CGFloat luminance = GULuminance(red, green, blue);
		*outFGColor = [(luminance > 0.5f ? [UIColor blackColor] : [UIColor whiteColor]) retain];
	}
}