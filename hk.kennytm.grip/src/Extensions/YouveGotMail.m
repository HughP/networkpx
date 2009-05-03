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

//#import <substrate.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <GriP/NSString-stringByEscapingXMLEntities.h>
#import <GriP/GrowlApplicationBridge.h>
#import <GriP/GPApplicationBridge.h>

//------------------------------------------------------------------------------

__attribute__((visibility("hidden")))
@interface ActivityMonitor : NSObject
+(ActivityMonitor*)currentMonitor;
-(BOOL)gotNewMessages;
-(void)reset;
@end

__attribute__((visibility("hidden")))
@interface MailAccount : NSObject
-(NSArray*)emailAddresses;
@end

__attribute__((visibility("hidden")))
@interface Message : NSObject
@property(retain) NSString* subject;
@property(retain) NSString* sender;
-(MailAccount*)account;
@end

@interface UIApplication ()
-(void)launchApplicationWithIdentifier:(NSString*)iden suspended:(BOOL)suspended;
@end

//------------------------------------------------------------------------------

__attribute__((visibility("hidden")))
@interface YouveGotMail : NSObject <GrowlApplicationBridgeDelegate> {
	GPApplicationBridge* bridge;
	NSString* oneNewMail, *manyNewMails;
}
-(id)init;
-(void)dealloc;
-(void)messagesAdded:(NSNotification*)notif;

-(NSString*)applicationNameForGrowl;
-(NSDictionary*)registrationDictionaryForGrowl;
@end

@implementation YouveGotMail
-(id)init {
	if ((self = [super init])) {
		NSDictionary* localizations = [[NSDictionary dictionaryWithContentsOfFile:@"/Library/MobileSubstrate/DynamicLibraries/YouveGotMail.plist"] objectForKey:@"Localizations"];
		NSString* preferredLocalization = [[NSBundle preferredLocalizationsFromArray:[localizations allKeys]] objectAtIndex:0];
		NSDictionary* localizationStrings = [localizations objectForKey:preferredLocalization];
		if (localizationStrings == nil)
			localizationStrings = [localizations objectForKey:@"en"];
		oneNewMail = [[localizationStrings objectForKey:@"1 new mail"] retain];
		manyNewMails = [[localizationStrings objectForKey:@"%d new mails"] retain];
		
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
	[super dealloc];
}
-(void)messagesAdded:(NSNotification*)notif {
	ActivityMonitor* mon = [ActivityMonitor currentMonitor];
	if ([mon gotNewMessages]) {
		[mon reset];
		
		NSDictionary* userInfo = [notif userInfo];
		NSArray* messages = [userInfo objectForKey:@"messages"];
		
		NSMutableDictionary* newMessagesForEachMail = [[NSMutableDictionary alloc] init];
		
		// analyze each new email and format into readable form.
		for (Message* message in messages) {
			NSArray* account = [[message account] emailAddresses];
			
			NSString* strippedSender = message.sender;
			NSUInteger addrPart = [strippedSender rangeOfString:@"<"].location;
			if (addrPart != NSNotFound)
				strippedSender = [strippedSender substringToIndex:addrPart];
			NSMutableString* formattedLine = [NSMutableString stringWithFormat:@"<p><b>%@</b><br />%@</p>",
											  [strippedSender stringByEscapingXMLEntities], [message.subject stringByEscapingXMLEntities]];
						
			NSMutableString* lines = [newMessagesForEachMail objectForKey:account];
			if (lines != nil) {
				[lines appendString:formattedLine];
			} else {
				[newMessagesForEachMail setObject:formattedLine forKey:account];
			}
		}
		
		// merge together the new emails from each mail account into one single string.
		NSMutableString* mergedString = [[NSMutableString alloc] init];
		for (NSArray* account in newMessagesForEachMail) {
			[mergedString appendFormat:@"<p align='right'><b><i>%@</i></b></p>%@", [account objectAtIndex:0], [newMessagesForEachMail objectForKey:account]];
		}
		
		[newMessagesForEachMail release];
		
		NSUInteger newMsgCount = [messages count];
		NSString* title = newMsgCount == 1 ? oneNewMail : [NSString stringWithFormat:manyNewMails, newMsgCount];
		
		[bridge notifyWithTitle:title description:mergedString notificationName:@"You've Got Mail" iconData:@"com.apple.mobilemail" priority:0 isSticky:NO clickContext:@""];
		
		[mergedString release];
	}
}

-(NSString*)applicationNameForGrowl { return @"You've Got Mail"; }
-(NSDictionary*)registrationDictionaryForGrowl {
	NSArray* names = [NSArray arrayWithObject:@"You've Got Mail"];
	return [NSDictionary dictionaryWithObjectsAndKeys:names, GROWL_NOTIFICATIONS_ALL, names, GROWL_NOTIFICATIONS_DEFAULT, nil];
}
-(void)growlNotificationWasClicked:(NSObject*)context {
	[[UIApplication sharedApplication] launchApplicationWithIdentifier:@"com.apple.mobilemail" suspended:NO];
}
@end

//------------------------------------------------------------------------------

static YouveGotMail* youveGotMail = nil;

static void terminate () {
	[youveGotMail release];
	youveGotMail = nil;
}

void initialize () {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	atexit(&terminate);
	youveGotMail = [[YouveGotMail alloc] init];
	[pool release];
}