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
#import <GriP/GrowlDefines.h>
#import <GriP/common.h>
#import <pthread.h>

static NSDictionary* preferences = nil;
static pthread_mutex_t prefLock = PTHREAD_MUTEX_INITIALIZER;

NSDictionary* GPPreferences() {
	pthread_mutex_lock(&prefLock);
	if (preferences == nil)
		preferences = [[NSDictionary alloc] initWithContentsOfFile:@"/Library/GriP/Preferences.plist"];
	pthread_mutex_unlock(&prefLock);
	return preferences;
}

void GPFlushPreferences() {
	pthread_mutex_lock(&prefLock);
	[preferences release];
	preferences = nil;
	pthread_mutex_unlock(&prefLock);
}

static NSString* GPTicketPathForAppName(NSString* appName) {
	return [@"/Library/GriP/Tickets/" stringByAppendingPathComponent:[appName stringByAppendingPathExtension:@"ticket"]];
}

void GPUpdateRegistrationDictionaryForAppName(NSString* appName, NSDictionary* registrationDictionary) {
	NSString* appPath = GPTicketPathForAppName(appName);
	NSMutableDictionary* ticket = [[NSMutableDictionary alloc] initWithContentsOfFile:appPath];
	BOOL hasModification = NO;
	if (ticket == nil) {
		// Set default data for a new ticket.
		hasModification = YES;
		ticket = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
				  [NSNumber numberWithBool:YES], @"enabled",
				  [NSNumber numberWithInteger:0], @"context",	// 0 = application defined, 1 = enable if possible, else = always disable.
				  [NSNumber numberWithInteger:0], @"sticky",	// 0 = application defined, 1 = always sticky, else = always hide.
				  [NSMutableDictionary dictionary], @"messages",
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
			NSMutableDictionary* messageDict = [[NSMutableDictionary alloc] initWithCapacity:3];
			[messageDict setObject:[NSNumber numberWithBool:enabled] forKey:@"enabled"];
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
	[ticket release];
}

void GPModifyMessageForUserPreference(NSMutableDictionary* message) {
	NSString* appName = [message objectForKey:GRIP_APPNAME];
	NSDictionary* ticket = [NSDictionary dictionaryWithContentsOfFile:GPTicketPathForAppName(appName)];
	if (ticket == nil || ![[ticket objectForKey:@"enabled"] boolValue]) {
		[message removeAllObjects];
		return;
	}
	
	NSDictionary* msgDict = [[ticket objectForKey:@"messages"] objectForKey:[message objectForKey:GRIP_NAME]];
	if (msgDict == nil || ![[msgDict objectForKey:@"enabled"] boolValue]) {
		[message removeAllObjects];
		return;
	}
	
	NSInteger stickyEnabled = [[msgDict objectForKey:@"sticky"] integerValue];
	if (stickyEnabled == 0)
		stickyEnabled = [[ticket objectForKey:@"sticky"] integerValue];
	
	if (stickyEnabled == 1)
		[message setObject:[NSNumber numberWithBool:NO] forKey:GRIP_STICKY];
	else if (stickyEnabled != 0)
		[message setObject:[NSNumber numberWithBool:YES] forKey:GRIP_STICKY];
	
	NSInteger contextEnabled = [[msgDict objectForKey:@"context"] integerValue];
	if (contextEnabled == 0)
		contextEnabled = [[msgDict objectForKey:@"context"] integerValue];
	if (contextEnabled != 0 && contextEnabled != 1)
		[message removeObjectForKey:GRIP_CONTEXT];
	
	NSInteger newPriority = [[msgDict objectForKey:@"priority"] integerValue];
	if (newPriority >= -2 && newPriority <= 2)
		[message setObject:[NSNumber numberWithInteger:newPriority] forKey:GRIP_PRIORITY];
}