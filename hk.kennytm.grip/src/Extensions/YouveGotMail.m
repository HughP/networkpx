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
@interface MailAccount : NSObject { NSString* simtest_address; }
@property(readonly) NSArray* emailAddresses;
+(NSArray*)activeAccounts;
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
@interface Message : NSObject { int simtest_rannum; }
@property(retain) NSString* subject;
@property(retain) NSString* senderAddressComment;
@property(retain) NSString* sender, *to, *cc;
@property(readonly) MailAccount* account;
@property(assign) unsigned long messageFlags;
@property(readonly) MessageBody* messageBody;
@property(readonly) NSDate* dateSent;
@property(retain) NSString* summary;
-(void)markAsViewed;
-(void)markAsNotViewed;
@property(retain) MessageStore* messageStore;
@end

@interface UIApplication ()
-(void)launchApplicationWithIdentifier:(NSString*)iden suspended:(BOOL)suspended;
@end


static GPModalTableViewClient* sharedClient = nil;


#if TARGET_IPHONE_SIMULATOR
@implementation ActivityMonitor
+(ActivityMonitor*)currentMonitor { return [[[self alloc] init] autorelease]; }
-(BOOL)gotNewMessages { return YES; }
-(void)reset {}
@end
static NSString* const randomAddresses[4] = {@"test@example.com", @"another_test@example.com", @"hello.world@test.com", @"example@qwertyuiopasdfghjklzxcvbnm.qwertyuiopasdfghjklzxcvbnm.com"};
@implementation MailAccount
-(id)initWithAddress:(NSString*)addr { if ((self = [super init])) simtest_address = [addr retain]; return self; }
-(void)dealloc { [simtest_address release]; [super dealloc]; }
-(NSArray*)emailAddresses { return [NSArray arrayWithObject:simtest_address]; }
+(NSArray*)activeAccounts { return [NSArray arrayWithObjects:[NSNull null], [NSNull null], nil]; }
@end
@implementation MessageStore
-(void)deleteMessages:(NSArray*)messages moveToTrash:(BOOL)moveToTrash {}
@end
@implementation WebMessageDocument
@dynamic htmlData, preferredCharacterSet;
-(NSData*)htmlData {
	static const char* rawHTML = "<html><head><title>title</title></head><body><p>This is a test mail message.</p><p style='font-size:120pt;'>Some huge text to let to scroll.</p><p>Rest of the message.</p></body></html>";
	return [NSData dataWithBytes:rawHTML length:strlen(rawHTML)+1];
}
-(NSString*)preferredCharacterSet { return @"utf8"; }
@end
@implementation MessageBody
-(NSArray*)htmlContent { return [NSArray arrayWithObject:[[[WebMessageDocument alloc] init] autorelease]]; }
@end
@implementation Message
@dynamic subject, sender, to, cc, messageFlags, messageStore, senderAddressComment, summary;
-(id)initWithRandomNumber:(int)x { if ((self = [super init])) simtest_rannum = x; return self; }
-(NSString*)subject {
	static NSString* const randomSubjects[4] = {@"Test", @"Very very very very very very very very long subject", @"Reply To: Re: Fw: Forward: Very very very very very very very very long subject", @"Re: Re: Fw: Fw: Re: Test"};
	return randomSubjects[simtest_rannum];
}
-(NSString*)senderAddressComment { return self.sender; }
-(NSString*)summary { return self.subject; }
-(NSString*)sender { return randomAddresses[simtest_rannum]; }
-(NSString*)to { return randomAddresses[3-simtest_rannum]; }
-(NSString*)cc { return simtest_rannum < 2 ? nil : randomAddresses[simtest_rannum]; }
-(MailAccount*)account { return [[[MailAccount alloc] initWithAddress:randomAddresses[simtest_rannum]] autorelease]; }
-(unsigned long)messageFlags { return 0x30000; }
-(MessageBody*)messageBody { return [[[MessageBody alloc] init] autorelease]; }
-(NSDate*)dateSent { return [NSDate date]; }
-(void)markAsViewed {}
-(void)markAsNotViewed {}
-(MessageStore*)messageStore { return nil; }
@end

void TestYGM () {
	NSMutableArray* allMessages = [NSMutableArray arrayWithCapacity:16];
	for (int i = 0; i < 8; ++ i)
		[allMessages addObject:[[[Message alloc] initWithRandomNumber:rand()%4] autorelease]];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"MessageStoreMessagesAdded" object:nil userInfo:[NSDictionary dictionaryWithObject:allMessages forKey:@"messages"]];
}
#endif

//------------------------------------------------------------------------------

static NSString* YGMCopyMessageBody (Message* msg) {
	WebMessageDocument* content = [msg.messageBody.htmlContent objectAtIndex:0];
	CFStringEncoding encoding = CFStringConvertIANACharSetNameToEncoding((CFStringRef)content.preferredCharacterSet);
	return (NSString*)CFStringCreateFromExternalRepresentation(NULL, (CFDataRef)content.htmlData, encoding);
}

/*
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
 */

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
	NSMutableSet* dirtyAccounts;
	CFMutableDictionaryRef messages;
	NSInteger msgid;
	Class DAMessageStore;
	pthread_mutex_t messageLock;
}
@end

@implementation YouveGotMail
-(id)init {
	if ((self = [super init])) {
		NSURL* myDictURL = [NSURL fileURLWithPath:@"/Library/MobileSubstrate/DynamicLibraries/YouveGotMail.plist" isDirectory:NO];
		NSDictionary* localizationStrings = GPPropertyListCopyLocalizableStringsDictionary(myDictURL);
		
		oneNewMail = [([localizationStrings objectForKey:@"1 new mail"] ?: @"1 new mail") retain];
		manyNewMails = [([localizationStrings objectForKey:@"%d new mails"] ?: @"%d new mails") retain];
		multipleAccounts = [[NSString stringWithFormat:@" (%@)", ([localizationStrings objectForKey:@"multiple accounts"] ?: @"multiple accounts")] retain];
		
		[localizationStrings release];
		
		messages = CFDictionaryCreateMutable(NULL, 0, NULL, &kCFTypeDictionaryValueCallBacks);
		dirtyAccounts = [[NSMutableSet alloc] init];
		msgid = 0;
		
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
	CFRelease(messages);
	CFRelease(dirtyAccounts);
	pthread_mutex_destroy(&messageLock);
	[super dealloc];
}

static void YGMConstructDescription(void* index, Message* message, CFMutableStringRef descr) {
	NSString* addrcmt = [message senderAddressComment];
	NSString* title = [message subject];
	CFStringAppend(descr, (CFStringRef)addrcmt);
	CFStringAppend(descr, CFSTR(":\n"));
	CFStringAppend(descr, (CFStringRef)title);
	CFStringAppend(descr, CFSTR("\n\n"));
}

-(void)messagesAdded:(NSNotification*)notif {
	ActivityMonitor* mon = [ActivityMonitor currentMonitor];
	
	if (!(mon.gotNewMessages || [notif.object isKindOfClass:DAMessageStore]))
		return;
		
	[mon reset];
	
	NSDictionary* userInfo = [notif userInfo];
	NSArray* theMessages = [userInfo objectForKey:@"messages"];
	CFMutableStringRef descr = CFStringCreateMutable(NULL, 0);
	
	pthread_mutex_lock(&messageLock);
	for (Message* message in theMessages) {
		// ignore read mails.
		if (message.messageFlags & 1)
			continue;
		CFDictionaryAddValue(messages, (const void*)(msgid++), message);
		[dirtyAccounts addObject:[message.account.emailAddresses objectAtIndex:0]];
	}
	pthread_mutex_unlock(&messageLock);

	// count number of new mails coming in.
	int msgCount = CFDictionaryGetCount(messages);
	NSString* accountString;
	if ([dirtyAccounts count] == 1) {
		if ([[MailAccount activeAccounts] count] > 1)
			accountString = [dirtyAccounts anyObject];
		else
			accountString = @"";
	} else
		accountString = multipleAccounts;
	
	CFDictionaryApplyFunction(messages, (CFDictionaryApplierFunction)&YGMConstructDescription, descr);
	
	NSString* title;
	if (msgCount == 1)
		title = [[NSString stringWithFormat:oneNewMail] stringByAppendingString:accountString];
	else
		title = [[NSString stringWithFormat:manyNewMails, msgCount] stringByAppendingString:accountString];
	
	[bridge notifyWithTitle:title
				description:(NSString*)descr
		   notificationName:@"You've Got Mail"
				   iconData:@"com.apple.mobilemail"
				   priority:0
				   isSticky:YES
			   clickContext:@""
				 identifier:@""];
	
	CFRelease(descr);
}

-(NSString*)applicationNameForGrowl { return @"You've Got Mail"; }
-(NSDictionary*)registrationDictionaryForGrowl {
	NSArray* names = [NSArray arrayWithObject:@"You've Got Mail"];
	return [NSDictionary dictionaryWithObjectsAndKeys:names, GROWL_NOTIFICATIONS_ALL, names, GROWL_NOTIFICATIONS_DEFAULT, nil];
}

//------------------------------------------------------------------------------

static void prepareEntriesDictionary(unsigned _msgid, Message* msg, NSMutableDictionary* entriesPerAccount) {
	NSString* account = [msg.account.emailAddresses objectAtIndex:0];
	NSMutableArray* msgs = [entriesPerAccount objectForKey:account];
	
	NSString* summary = msg.summary;
	if (summary == nil) {
		NSString* msgbody = YGMCopyMessageBody(msg);
		Class HTMLParser = objc_getClass("MFHTMLParser") ?: objc_getClass("HTMLParser");
		msg.summary = summary = objc_msgSend(HTMLParser, @selector(plainTextFromHTML:), msgbody) ?: @"";
		[msgbody release];
	}
	
	NSDictionary* entry = [NSDictionary dictionaryWithObjectsAndKeys:
						   msg.senderAddressComment, @"title",
						   msg.subject, @"subtitle",
						   (NSNumber*)kCFBooleanTrue, @"delete",
						   @"DisclosureIndicator", @"accessory",
						   [NSString stringWithFormat:@"%u", _msgid], @"id",
						   summary, @"description",
						   [NSNumber numberWithInteger:2], @"lines",
						   nil];
	if (msgs != nil)
		[msgs addObject:entry];
	else
		[entriesPerAccount setObject:[NSMutableArray arrayWithObject:entry] forKey:account];
}
static void constructEntriesArray(NSString* account, NSArray* entriesInAccount, NSMutableArray* entries) {
	[entries addObject:[NSDictionary dictionaryWithObjectsAndKeys:account, @"title", (NSNumber*)kCFBooleanTrue, @"header", nil]];
	[entries addObjectsFromArray:entriesInAccount];
}

-(NSDictionary*)constructHomeDictionary:(CFDictionaryRef)msgs {
	NSMutableArray* entries = [NSMutableArray array];
	NSMutableDictionary* entriesPerAccount = [NSMutableDictionary dictionary];
	CFDictionaryApplyFunction(msgs, (CFDictionaryApplierFunction)&prepareEntriesDictionary, entriesPerAccount);
	CFDictionaryApplyFunction((CFDictionaryRef)entriesPerAccount, (CFDictionaryApplierFunction)&constructEntriesArray, entries);
	
	return [NSDictionary dictionaryWithObjectsAndKeys:
			[NSArray arrayWithObject:[NSDictionary dictionaryWithObjectsAndKeys:
									  @"Launch Mail", @"label",
									  @"Launch Mail", @"id",
									  nil]], @"buttons",
			@"You've Got Mail", @"title",
			@"You've Got Mail", @"id",
			entries, @"entries",
			nil];
}

-(void)growlNotificationWasClicked:(NSObject*)context {
	pthread_mutex_lock(&messageLock);
		
	if (sharedClient == nil)
		sharedClient = [[GPModalTableViewClient alloc] initWithDictionary:[self constructHomeDictionary:messages] 
														applicationBridge:bridge name:@"You've Got Mail"];
	else
		[sharedClient reloadDictionary:[self constructHomeDictionary:messages] forIdentifier:@"You've Got Mail"];
		
	sharedClient.delegate = self;
	sharedClient.context = (id)messages;
	CFRelease(messages);
	messages = CFDictionaryCreateMutable(NULL, 0, NULL, &kCFTypeDictionaryValueCallBacks);
	[dirtyAccounts removeAllObjects];
	
	pthread_mutex_unlock(&messageLock);
}
-(void)growlNotificationCoalesced:(NSObject*)context {}
-(void)growlNotificationTimedOut:(NSObject*)context {
	pthread_mutex_lock(&messageLock);
	CFDictionaryRemoveAllValues(messages);
	[dirtyAccounts removeAllObjects];
	pthread_mutex_unlock(&messageLock);
}

#pragma mark -

-(void)modalTableView:(GPModalTableViewClient*)client deletedItem:(NSString*)item {
	CFMutableDictionaryRef msgs = (CFMutableDictionaryRef)client.context;
	const void* _msgid = (const void*)[item integerValue];
	Message* msg = (Message*)CFDictionaryGetValue(msgs, _msgid);
	if (msg != nil) {
		[msg.messageStore deleteMessages:[NSArray arrayWithObject:msg] moveToTrash:YES];
		CFDictionaryRemoveValue(msgs, _msgid);
	}
}

-(void)modalTableView:(GPModalTableViewClient*)client clickedButton:(NSString*)buttonID {
	if ([@"Launch Mail" isEqualToString:buttonID]) {
		[client dismiss];
		[[UIApplication sharedApplication] launchApplicationWithIdentifier:@"com.apple.mobilemail" suspended:NO];
	} else if ([@"Trash" isEqualToString:buttonID]) {
		[self modalTableView:client deletedItem:client.currentIdentifier];
		[client reloadDictionary:[self constructHomeDictionary:(CFDictionaryRef)client.context] forIdentifier:@"You've Got Mail"];
		[client pop];
	} else if ([@"Mark as Unread" isEqualToString:buttonID]) {
		[(Message*)CFDictionaryGetValue((CFDictionaryRef)client.context, (const void*)[client.currentIdentifier integerValue]) markAsNotViewed];
	}
}

-(void)modalTableViewDismissed:(GPModalTableViewClient*)client {
	sharedClient = nil;
	[client release];
}

-(void)modalTableView:(GPModalTableViewClient*)client selectedItem:(NSString*)item {
	Message* msg = (Message*)CFDictionaryGetValue((CFDictionaryRef)client.context, (const void*)[item integerValue]);
	
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
									formattedDate, @"title",
									msg.subject, @"subtitle",
									messageBody, @"description",
									(NSNumber*)kCFBooleanTrue, @"edit",
									(NSNumber*)kCFBooleanTrue, @"readonly",
									(NSNumber*)kCFBooleanTrue, @"html",
									(NSNumber*)kCFBooleanTrue, @"noselect",
									[NSNumber numberWithInteger:10], @"lines",
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
#if TARGET_IPHONE_SIMULATOR
	srand(0);
#endif
	
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	atexit(&terminate);
	youveGotMail = [[YouveGotMail alloc] init];
	[pool release];
}