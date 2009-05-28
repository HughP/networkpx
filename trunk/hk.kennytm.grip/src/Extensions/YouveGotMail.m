/*

YouveGotMail.m ... New Mail notifier for GriP
 
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
#import <CoreFoundation/CoreFoundation.h>
#import <UIKit/UIKit.h>
#import <GriP/NSString-stringByEscapingXMLEntities.h>
#import <GriP/GrowlApplicationBridge.h>
#import <GriP/GPApplicationBridge.h>
#import <GriP/GPExtensions.h>
#import <GriP/GPModalTableViewClient.h>
#import <pthread.h>

//------------------------------------------------------------------------------

__attribute__((visibility("hidden")))
@interface ActivityMonitor : NSObject
+(ActivityMonitor*)currentMonitor;
@property(readonly) BOOL gotNewMessages;
-(void)reset;
@end

__attribute__((visibility("hidden")))
@interface MailAccount : NSObject
@property(readonly) NSArray* emailAddresses;
@end

__attribute__((visibility("hidden")))
@interface MailMimePart : NSObject
-(NSString*)decodeTextPlain;
@end

__attribute__((visibility("hidden")))
@interface MessageStore : NSObject
-(void)deleteMessages:(NSArray*)messages moveToTrash:(BOOL)moveToTrash;
@end


__attribute__((visibility("hidden")))
@interface WebMessageDocument : NSObject
@property(retain) NSData* htmlData;
@property(retain) NSString* preferredCharacterSet;
@end

__attribute__((visibility("hidden")))
@interface MessageBody : NSObject
@property(readonly) NSArray* htmlContent;
@end

__attribute__((visibility("hidden")))
@interface Message : NSObject
@property(retain) NSString* subject;
@property(retain) NSString* senderAddressComment;
@property(retain) NSString* sender, *to, *cc;
@property(readonly) MailAccount* account;
@property(assign) unsigned long messageFlags;
@property(readonly) MessageBody* messageBody;
@property(readonly) NSDate* dateSent;
-(void)markAsViewed;
-(void)markAsNotViewed;
@property(retain) MessageStore* messageStore;
@end

@interface UIApplication ()
-(void)launchApplicationWithIdentifier:(NSString*)iden suspended:(BOOL)suspended;
@end

//------------------------------------------------------------------------------

static NSString* YGMCopyMessageBody (Message* msg) {
	WebMessageDocument* content = [msg.messageBody.htmlContent objectAtIndex:0];
	CFStringEncoding encoding = CFStringConvertIANACharSetNameToEncoding((CFStringRef)content.preferredCharacterSet);
	return (NSString*)CFStringCreateFromExternalRepresentation(NULL, (CFDataRef)content.htmlData, encoding);
}

static Message* YGMGetMessageFromItem (GPModalTableViewClient* client, NSString* item, NSString** pAccount, int* pIndex) {
	int exclLoc = [item rangeOfString:@"!"].location;
	if (exclLoc != NSNotFound) {
		int index = [item integerValue];
		NSString* account = [item substringFromIndex:exclLoc+1];
		if (pIndex != NULL)
			*pIndex = index;
		if (pAccount != NULL)
			*pAccount = account;
		return [[client.context objectForKey:account] objectAtIndex:index];
	} else
		return nil;
}

/*
static void YGMAppendMessageToString(Message* message, NSMutableString* string) {
	NSString* strippedSender = message.sender;
	NSUInteger addrPart = [strippedSender rangeOfString:@"<"].location;
	if (addrPart != NSNotFound)
		strippedSender = [strippedSender substringToIndex:addrPart];
	NSString* formattedLine = [NSString stringWithFormat:@"<p><b>%@</b><br />%@</p>",
							   [strippedSender stringByEscapingXMLEntities], [message.subject stringByEscapingXMLEntities]];
	
	[string appendString:formattedLine];
}
*/

__attribute__((visibility("hidden")))
@interface YouveGotMail : NSObject <GrowlApplicationBridgeDelegate, GPModalTableViewDelegate> {
	GPApplicationBridge* bridge;
	NSString* oneNewMail, *manyNewMails, *newMails, *multipleAccounts;
	NSMutableDictionary* newMessagesForEachMail;
	Class DAMessageStore;
	pthread_mutex_t messageLock;
}
-(id)init;
-(void)dealloc;
-(void)messagesAdded:(NSNotification*)notif;

-(NSDictionary*)constructHomeDictionary:(NSDictionary*)nm4em;

-(NSString*)applicationNameForGrowl;
-(NSDictionary*)registrationDictionaryForGrowl;
-(void)growlNotificationWasClicked:(NSObject*)context;
-(void)growlNotificationTimedOut:(NSObject*)context;
@end

@implementation YouveGotMail
-(id)init {
	if ((self = [super init])) {
		NSURL* myDictURL = [NSURL fileURLWithPath:@"/Library/MobileSubstrate/DynamicLibraries/YouveGotMail.plist" isDirectory:NO];
		NSDictionary* localizationStrings = GPPropertyListCopyLocalizableStringsDictionary(myDictURL);
		
		oneNewMail = [[localizationStrings objectForKey:@"1 new mail (%@)"] retain];
		manyNewMails = [[localizationStrings objectForKey:@"%d new mails (%@)"] retain];
		multipleAccounts = [[localizationStrings objectForKey:@"multiple accounts"] retain];
		
		[localizationStrings release];
		
		newMessagesForEachMail = [[NSMutableDictionary alloc] init];
		
		DAMessageStore = objc_getClass("DAMessageStore");
		
		pthread_mutex_init(&messageLock, NULL);
		
		bridge = [[GPApplicationBridge alloc] init];
		bridge.growlDelegate = self;
		NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
		[center addObserver:self selector:@selector(messagesAdded:) name:@"MessageStoreMessagesAdded" object:nil];		// for 2.x
		[center addObserver:self selector:@selector(messagesAdded:) name:@"MailMessageStoreMessagesAdded" object:nil];	// for 3.x
	}
	return self;
}
-(void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[bridge release];
	[oneNewMail release];
	[manyNewMails release];
	[multipleAccounts release];
	[newMessagesForEachMail release];
	pthread_mutex_destroy(&messageLock);
	[super dealloc];
}
-(void)messagesAdded:(NSNotification*)notif {
	ActivityMonitor* mon = [ActivityMonitor currentMonitor];
	
	if (!(mon.gotNewMessages || [notif.object isKindOfClass:DAMessageStore]))
			return;
			
		NSDictionary* userInfo = [notif userInfo];
		NSArray* messages = [userInfo objectForKey:@"messages"];
	
	pthread_mutex_lock(&messageLock);
		// insert all messeages into each account's set.
		for (Message* message in messages) {
			// ignore read mails.
			if (message.messageFlags & 1)
				continue;
			NSString* account = [message.account.emailAddresses objectAtIndex:0];
			NSMutableArray* messages = [newMessagesForEachMail objectForKey:account];
			if (messages != nil)
				[messages addObject:message];
			else
				[newMessagesForEachMail setObject:[NSMutableArray arrayWithObject:message] forKey:account];
		}
	pthread_mutex_unlock(&messageLock);

	// count number of new mails coming in.
	int msgCount = 0;
	NSString* accountString = multipleAccounts;
	if ([newMessagesForEachMail count] == 1)
		accountString = [[newMessagesForEachMail keyEnumerator] nextObject];
	
	for (NSArray* messages in newMessagesForEachMail)
		msgCount += [[newMessagesForEachMail objectForKey:messages] count];
	NSString* title;
	if (msgCount == 1)
		title = [NSString stringWithFormat:oneNewMail, accountString];
	else
		title = [NSString stringWithFormat:manyNewMails, msgCount, accountString];
	
	[bridge notifyWithTitle:title
				description:nil
		   notificationName:@"You've Got Mail"
				   iconData:@"com.apple.mobilemail"
				   priority:0
				   isSticky:NO
			   clickContext:@""
				 identifier:@""];
}

-(NSString*)applicationNameForGrowl { return @"You've Got Mail"; }
-(NSDictionary*)registrationDictionaryForGrowl {
	NSArray* names = [NSArray arrayWithObject:@"You've Got Mail"];
	return [NSDictionary dictionaryWithObjectsAndKeys:names, GROWL_NOTIFICATIONS_ALL, names, GROWL_NOTIFICATIONS_DEFAULT, nil];
}

-(NSDictionary*)constructHomeDictionary:(NSDictionary*)nm4em {
	NSMutableArray* entries = [NSMutableArray array];
	for (NSString* account in nm4em) {
		[entries addObject:[NSDictionary dictionaryWithObjectsAndKeys:account, @"title", (NSNumber*)kCFBooleanTrue, @"header", nil]];
		int i = 0;
		for (Message* msg in [nm4em objectForKey:account]) {
			[entries addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								msg.senderAddressComment, @"title",
								msg.subject, @"subtitle",
								(NSNumber*)kCFBooleanTrue, @"candelete",
								@"DisclosureIndicator", @"accessory",
								[NSString stringWithFormat:@"%d!%@", i, account], @"id",
								nil]];
			++ i;
		}
	}
	
	return [NSDictionary dictionaryWithObjectsAndKeys:
			[NSArray arrayWithObject:[NSDictionary dictionaryWithObjectsAndKeys:
									  @"Launch Mail", @"label",
									  @"Launch Mail", @"id",
									  nil]], @"buttons",
			@"You've Got Mail", @"title",
			entries, @"entries",
			nil];
}

-(void)growlNotificationWasClicked:(NSObject*)context {
	pthread_mutex_lock(&messageLock);
		
	GPModalTableViewClient* client = [[GPModalTableViewClient alloc] initWithDictionary:[self constructHomeDictionary:newMessagesForEachMail]
																	  applicationBridge:bridge name:@"You've Got Mail"];
	client.delegate = self;
	client.context = newMessagesForEachMail;
	[newMessagesForEachMail release];
	newMessagesForEachMail = [[NSMutableDictionary alloc] init];
	
	pthread_mutex_unlock(&messageLock);
}
-(void)growlNotificationCoalesced:(NSObject*)context {}
-(void)growlNotificationTimedOut:(NSObject*)context {
	pthread_mutex_lock(&messageLock);
	[newMessagesForEachMail removeAllObjects];
	pthread_mutex_unlock(&messageLock);
}


-(void)modalTableView:(GPModalTableViewClient*)client deletedItem:(NSString*)item {
	NSString* account;
	int index;
	Message* msg = YGMGetMessageFromItem(client, item, &account, &index);
	if (msg != nil) {
		[msg.messageStore deleteMessages:[NSArray arrayWithObject:msg] moveToTrash:YES];

		NSMutableArray* arr = [client.context objectForKey:account];
		if ([arr count] == 1)
			[client.context removeObjectForKey:account];
		else
			[arr removeObjectAtIndex:index];
	}
}

-(void)modalTableView:(GPModalTableViewClient*)client clickedButton:(NSString*)buttonID {
	if ([@"Launch Mail" isEqualToString:buttonID]) {
		[client dismiss];
		[[UIApplication sharedApplication] launchApplicationWithIdentifier:@"com.apple.mobilemail" suspended:NO];
	} else {
		NSString* item = client.currentIdentifier;
		Message* msg = YGMGetMessageFromItem(client, item, NULL, NULL);
		if (msg != nil) {
			if ([@"Mark as Unread" isEqualToString:buttonID])
				[msg markAsNotViewed];
			else if ([@"Trash" isEqualToString:buttonID]) {
				[self modalTableView:client deletedItem:item];
				[client pop];
			}
		}
	}
}

-(void)modalTableViewDismissed:(GPModalTableViewClient*)client {
	[client release];
}
	
-(void)modalTableView:(GPModalTableViewClient*)client selectedItem:(NSString*)item {
	Message* msg = YGMGetMessageFromItem(client, item, NULL, NULL);
	
	if (msg != nil) {
		NSBundle* mainBundle = [NSBundle mainBundle];
		NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateStyle:NSDateFormatterLongStyle];
		[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
		NSString* formattedDate = [dateFormatter stringFromDate:msg.dateSent];
		[dateFormatter release];
		NSString* messageBody = YGMCopyMessageBody(msg);
		
		[msg markAsViewed];
		
#define LSBTN(str,def) [NSDictionary dictionaryWithObjectsAndKeys:[mainBundle localizedStringForKey:(str) value:(def) table:@"Main"], @"label", (def), @"id", nil]
		
		NSMutableArray* entries = [NSMutableArray arrayWithObjects:
								   [NSDictionary dictionaryWithObjectsAndKeys:
									[mainBundle localizedStringForKey:@"FROM_HEADER" value:@"From:" table:@"Main"], @"title",
									msg.sender, @"subtitle",
									(NSNumber*)kCFBooleanTrue, @"compact",
									(NSNumber*)kCFBooleanTrue, @"noselect",
									nil],
								   [NSDictionary dictionaryWithObjectsAndKeys:
									[mainBundle localizedStringForKey:@"TO_HEADER" value:@"To:" table:@"Main"], @"title",
									msg.to, @"subtitle",
									(NSNumber*)kCFBooleanTrue, @"compact",
									(NSNumber*)kCFBooleanTrue, @"noselect",
									nil],
								   [NSDictionary dictionaryWithObjectsAndKeys:
									msg.subject, @"title",
									formattedDate, @"subtitle",
									messageBody, @"description",
									(NSNumber*)kCFBooleanTrue, @"edit",
									(NSNumber*)kCFBooleanTrue, @"readonly",
									(NSNumber*)kCFBooleanTrue, @"html",
									(NSNumber*)kCFBooleanTrue, @"noselect",
									[NSNumber numberWithInteger:0], @"lines",
									nil],
								   nil];
		NSString* cc = msg.cc;
		if ([cc length] > 0)
			[entries insertObject:[NSDictionary dictionaryWithObjectsAndKeys:
								   [mainBundle localizedStringForKey:@"CC_HEADER" value:@"Cc:" table:@"Main"], @"title",
								   cc, @"subtitle",
								   (NSNumber*)kCFBooleanTrue, @"compact",
								   (NSNumber*)kCFBooleanTrue, @"noselect",
								   nil] atIndex:1];
		
		[client pushDictionary:[NSDictionary dictionaryWithObjectsAndKeys:
								(NSNumber*)kCFBooleanTrue, @"backButton",
								entries, @"entries",
								@"New mails", @"title",
								[NSArray arrayWithObjects:
								 LSBTN(@"MARK_AS_UNREAD", @"Mark as Unread"),
								 @"Trash",
		/* LSBTN(@"REPLY", @"Reply"),
		 LSBTN(@"REPLY_ALL", @"Reply All"),
		 LSBTN(@"FORWARD", @"Forward"), */
								 nil], @"buttons",
								item, @"id",
								nil]];
		[messageBody release];
	}
}

@end

//------------------------------------------------------------------------------

static YouveGotMail* youveGotMail = nil;

static void terminate () {
	[youveGotMail release];
	youveGotMail = nil;
}

extern void initialize () {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	atexit(&terminate);
	youveGotMail = [[YouveGotMail alloc] init];
	[pool release];
}