/*

GPMessageLogUI.m ... Display message log.
 
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

#import <Foundation/Foundation.h>
#import <GriP/common.h>
#import <GriP/Duplex/Client.h>
#import <GriP/GPMessageLogUI.h>
#import <GriP/GPModalTableViewClient.h>

@interface GPModalTableViewClient (GetDuplex)
@property(readonly) GPDuplexClient* duplex;
@end
@implementation GPModalTableViewClient (GetDuplex)
-(GPDuplexClient*)duplex { return duplex; }
@end



static GPModalTableViewClient* sharedClient = nil;

static inline NSInteger compareDate(NSDate* ra, NSDate* rb) {
	if (ra == rb && ra == nil)
		return NSNotFound;
	else if (ra == nil)
		return NSOrderedAscending;
	else if (rb == nil)
		return NSOrderedDescending;
	else
		return [rb compare:ra];
}

static NSInteger compareByDate (id a, id b, void* context) {
	NSInteger res = compareDate([a objectForKey:GRIP_RESOLVEDATE], [b objectForKey:GRIP_RESOLVEDATE]);
	if (res == NSNotFound) {
		res = compareDate([a objectForKey:GRIP_SHOWDATE], [b objectForKey:GRIP_SHOWDATE]);
		if (res == NSNotFound) {
			res = compareDate([a objectForKey:GRIP_QUEUEDATE], [b objectForKey:GRIP_QUEUEDATE]);
			if (res == NSNotFound)
				res = NSOrderedSame;
		}
	}
	return res;
}

#if GRIP_JAILBROKEN
#define GETLOCALIZATIONBUNDLE [NSBundle bundleWithPath:@"/System/Library/PreferenceBundles/GriP.bundle/"]
#else
#define GETLOCALIZATIONBUNDLE [NSBundle mainBundle]
#endif
#define BUTTONIZE(str) [NSDictionary dictionaryWithObjectsAndKeys:(str), @"id", [localizationBundle localizedStringForKey:(str) value:nil table:@"GriP"], @"label", nil]

static NSString* simplifyDate(NSDate* date, NSDate* today, NSDateFormatter* shortFormatter, NSDateFormatter* longFormatter) {
	NSTimeInterval interval = [date timeIntervalSinceDate:today];
	if (interval >= 0 && interval < 86400)
		return [shortFormatter stringFromDate:date];
	else
		return [longFormatter stringFromDate:date];
}

static NSDictionary* constructHomeDictionary (NSDictionary* logDict) {
	NSBundle* localizationBundle = GETLOCALIZATIONBUNDLE;
	
	NSArray* logEntries = [[logDict allValues] sortedArrayUsingFunction:&compareByDate context:NULL];
	NSMutableArray* entries = [NSMutableArray array];
	NSString* statusString = [localizationBundle localizedStringForKey:@"Status" value:nil table:@"GriP"];
	
	NSCalendar* curCal = [NSCalendar currentCalendar];
	NSDateComponents* todayComponents = [curCal components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:[NSDate date]];
	[todayComponents setHour:0];
	[todayComponents setMinute:0];
	[todayComponents setSecond:0];
	NSDate* today = [curCal dateFromComponents:todayComponents];
	NSDateFormatter* shortFormatter = [[NSDateFormatter alloc] init];
	NSDateFormatter* longFormatter = [[NSDateFormatter alloc] init];
	[shortFormatter setDateStyle:NSDateFormatterNoStyle];
	[shortFormatter setTimeStyle:NSDateFormatterMediumStyle];
	[longFormatter setDateStyle:NSDateFormatterMediumStyle];
	[longFormatter setTimeStyle:NSDateFormatterMediumStyle];
	
	NSString* at = [localizationBundle localizedStringForKey:@"at" value:nil table:@"GriP"];
	
	BOOL hasResolvedHeader = NO;
	for (NSDictionary* logEntry in logEntries) {
		NSDate* resolveDate = [logEntry objectForKey:GRIP_RESOLVEDATE];
		if (!hasResolvedHeader && resolveDate != nil) {
			hasResolvedHeader = YES;
			[entries addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								[localizationBundle localizedStringForKey:@"Resolved messages" value:nil table:@"GriP"], @"title",
								(NSNumber*)kCFBooleanTrue, @"header",
								nil]];
		}
		
		NSMutableDictionary* entry = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
									  [logEntry objectForKey:GRIP_MSGUID], @"id",
									  @"DisclosureIndicator", @"accessory",
									  [NSString stringWithFormat:@"%@: %@%@", statusString,
									   [localizationBundle localizedStringForKey:[logEntry objectForKey:GRIP_STATUS] value:nil table:@"GriP"],
									   (resolveDate ? [NSString stringWithFormat:
													   @", %@ %@", at,
													   simplifyDate(resolveDate, today, shortFormatter, longFormatter)]: @"")], @"subtitle",
									  nil];
		id temp = [logEntry objectForKey:GRIP_TITLE];
		if (temp != nil)
			[entry setObject:temp forKey:@"title"];
		temp = [logEntry objectForKey:GRIP_ICON];
		if (temp != nil)
			[entry setObject:temp forKey:@"icon"];
		temp = [logEntry objectForKey:GRIP_DETAIL];
		if (temp != nil) {
			[entry setObject:temp forKey:@"description"];
			[entry setObject:[NSNumber numberWithInt:3] forKey:@"lines"];
		}
		
		[entries addObject:entry];
		[entry release];
	}
	
	[shortFormatter release];
	[longFormatter release];
	
	return [NSDictionary dictionaryWithObjectsAndKeys:
			entries, @"entries",
			[localizationBundle localizedStringForKey:@"GriP Message Log" value:nil table:@"GriP"], @"title",
			@"home", @"id",
			[NSArray arrayWithObjects:BUTTONIZE(@"Coalesce all"), @"FixedSpace", BUTTONIZE(@"Ignore all"), BUTTONIZE(@"Touch all"), nil], @"buttons",
			nil];
}

static NSDictionary* constructDetailDictionary(NSDictionary* message) {
	NSBundle* localizationBundle = GETLOCALIZATIONBUNDLE;
	NSMutableArray* entries = [[NSMutableArray alloc] init];
	
	static NSString* const rawKeys[] = {
		GRIP_TITLE, GRIP_ICON, GRIP_DETAIL, GRIP_STATUS, GRIP_APPNAME, GRIP_NAME,
		GRIP_PRIORITY, GRIP_STICKY, GRIP_ISURL, GRIP_CONTEXT, 
		GRIP_MSGUID, GRIP_PID, GRIP_ID, GRIP_QUEUEDATE, GRIP_SHOWDATE, GRIP_RESOLVEDATE
	};
	
	NSArray* keys = [NSArray arrayWithObjects:rawKeys count:sizeof(rawKeys)/sizeof(NSString*)];
	NSArray* objects = [message objectsForKeys:keys notFoundMarker:(NSNull*)kCFNull];
	id rawObjects[sizeof(rawKeys)/sizeof(NSString*)];
//	memset_pattern4(rawObjects, kCFNull, sizeof(rawObjects));
	[objects getObjects:rawObjects];
	
	static NSString* const names[] = {
		//     0        1          2          3            4                5
		@"Title", @"Icon", @"Detail", @"Status", @"App name", @"Message name",
		//        6          7       8    9 (Context)
		@"Priority", @"Sticky", @"URL", nil, 
		//         10                   11                12
		@"Message ID", @"Client port name", @"Coalescent ID", 
		//         13             14               15
		@"Queue date", @"Shown date", @"Resolve date"
	};
	
	for (int i = 0; i < sizeof(rawKeys)/sizeof(NSString*); ++ i) {
		if (i == 9)
			continue;
		id subtitle = rawObjects[i];
		if (subtitle == (NSNull*)kCFNull)
			continue;
		
		NSString* title = [[localizationBundle localizedStringForKey:names[i] value:nil table:@"GriP"] stringByAppendingString:@": "];
		
		switch (i) {
			case 3:	// status
				subtitle = [localizationBundle localizedStringForKey:subtitle value:nil table:@"GriP"];
				break;
			case 6: {	// priority
				static NSString* const priorityStrings[5] = {@"Very low", @"Moderate", @"Normal", @"High", @"Emergency"};
				NSInteger priority = [subtitle integerValue];
				subtitle = [NSString stringWithFormat:@"%@ (%d)",
							[localizationBundle localizedStringForKey:priorityStrings[priority+2] value:nil table:@"GriP"],
							priority];
				break;
			}
			case 7:	// sticky
				subtitle = [subtitle boolValue] ? @"✓" : @"✗";
				break;
			case 8:	// URL + context
				if ([subtitle boolValue]) {
					subtitle = rawObjects[9];
					if (subtitle == (NSNull*)kCFNull)
						goto next;
				} else
					goto next;
				break;
				
			case 13:
			case 14:
			case 15:	// the dates
				subtitle = [subtitle description];
				break;
				
			default:
				break;
		}
		
		NSDictionary* entry = [[NSDictionary alloc] initWithObjectsAndKeys:
							   title, @"title", 
							   subtitle, @"subtitle",
							   (NSNumber*)kCFBooleanTrue, @"compact",
							   (NSNumber*)kCFBooleanTrue, @"noselect",
							   nil];
		[entries addObject:entry];
		[entry release];
next:
		;
	}
	
	NSDictionary* retdict = [NSDictionary dictionaryWithObjectsAndKeys:
							 entries, @"entries",
							 (rawObjects[0] ?: @""), @"title",
							 rawObjects[10], @"id",
							 (rawObjects[15] == (NSNumber*)kCFNull
							  ? [NSArray arrayWithObjects:BUTTONIZE(@"Coalesce"), @"FixedSpace", BUTTONIZE(@"Ignore"), BUTTONIZE(@"Touch"), nil]
							  : [NSArray array]), @"buttons",
							 nil];
	[entries release];
	return retdict;
}


@interface GPMessageLogDelegate : NSObject<GPModalTableViewDelegate>
@end
@implementation GPMessageLogDelegate
-(void)modalTableViewDismissed:(GPModalTableViewClient*)client {
	sharedClient = nil;
	[client release];
	[self release];
}
-(void)modalTableView:(GPModalTableViewClient*)client selectedItem:(NSString*)item {
	[client pushDictionary:constructDetailDictionary([client.context objectForKey:item])];
}
-(void)modalTableView:(GPModalTableViewClient*)client clickedButton:(NSString*)identifier {
	SInt32 message = GriPMessage_IgnoredNotification;
	if ([identifier hasPrefix:@"Touch"])
		message = GriPMessage_ClickedNotification;
	else if ([identifier hasPrefix:@"Ignore"])
		message = GriPMessage_IgnoredNotification;
	else if ([identifier hasPrefix:@"Coalesce"])
		message = GriPMessage_CoalescedNotification;
	if ([identifier hasSuffix:@"all"]) {
		// Collect all unresolved messages
		NSMutableArray* unresolvedMessages = [[NSMutableArray alloc] init];
		NSMutableArray* unresolvedMessageData = [[NSMutableArray alloc] init];
		for (NSDictionary* dict in [client.context objectEnumerator]) {
			if ([dict objectForKey:GRIP_RESOLVEDATE] == nil) {
				[unresolvedMessages addObject:[dict objectForKey:GRIP_MSGUID]];
				[unresolvedMessageData addObject:[NSPropertyListSerialization dataFromPropertyList:[dict objectsForKeys:[NSArray arrayWithObjects:GRIP_PID, GRIP_CONTEXT, GRIP_ISURL, (NSNull*)kCFNull, nil] notFoundMarker:(NSNumber*)kCFBooleanFalse]
																							format:NSPropertyListBinaryFormat_v1_0
																				  errorDescription:NULL]];
			}
		}
		
		[client.duplex sendMessage:GriPMessage_ResolveMultipleMessages data:[NSPropertyListSerialization dataFromPropertyList:[NSArray arrayWithObjects:
																															   [NSNumber numberWithInt:message],
																															   unresolvedMessages,
																															   unresolvedMessageData,
																															   nil]
																													   format:NSPropertyListBinaryFormat_v1_0
																											 errorDescription:NULL]];
		[unresolvedMessages release];
		[unresolvedMessageData release];
		
	} else {
		[client.duplex sendMessage:message data:[NSPropertyListSerialization dataFromPropertyList:[[client.context objectForKey:client.currentIdentifier]
																								   objectsForKeys:[NSArray arrayWithObjects:GRIP_PID, GRIP_CONTEXT, GRIP_ISURL, GRIP_MSGUID, nil]
																								   notFoundMarker:(NSNumber*)kCFBooleanFalse]
																						   format:NSPropertyListBinaryFormat_v1_0
																				 errorDescription:NULL]];
	}
}
@end

#if GRIP_JAILBROKEN
#define MESSAGELOGFILE @"/Library/GriP/GPMessageLog.plist"
#else
#define MESSAGELOGFILE [[NSBundle mainBundle] pathForResource:@"GPMessageLog" ofType:@"plist"]
#endif

void GPMessageLogShow(GPApplicationBridge* bridge, NSString* name) {
	if (sharedClient == nil) {
		NSDictionary* logDict = [NSDictionary dictionaryWithContentsOfFile:MESSAGELOGFILE];
		sharedClient = [[GPModalTableViewClient alloc] initWithDictionary:constructHomeDictionary(logDict) applicationBridge:bridge name:name];
		sharedClient.delegate = [[GPMessageLogDelegate alloc] init];
		sharedClient.context = logDict;
	}
}

void GPMessageLogRefresh(CFArrayRef modifiedMessages) {
	if (sharedClient != nil) {
		NSDictionary* logDict = [NSDictionary dictionaryWithContentsOfFile:MESSAGELOGFILE];
		[sharedClient reloadDictionary:constructHomeDictionary(logDict) forIdentifier:@"home"];
		sharedClient.context = logDict;
		NSString* identifier = sharedClient.currentIdentifier;
		if ([(NSArray*)modifiedMessages containsObject:identifier]) {
			[sharedClient reloadDictionary:constructDetailDictionary([logDict objectForKey:identifier]) forIdentifier:identifier];
		}
	}
}