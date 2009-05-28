/*

GriPTest ... Test GriP notifications.
 
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

#include <stdio.h>
#include <unistd.h>
#import <Foundation/Foundation.h>
#import <GriP/GriP.h>
#import <GriP/GPModalTableViewClient.h>

#if !TARGET_IPHONE_SIMULATOR
#define GPGriPTest main
#endif

@interface GPGriPTestDelegate : NSObject<GPModalTableViewDelegate,GrowlApplicationBridgeDelegate> {
	BOOL completed;
}
@property(assign) BOOL completed;
-(NSString*)applicationNameForGrowl;
-(NSDictionary*)registrationDictionaryForGrowl;
-(void)growlNotificationWasClicked:(NSObject*)context;
-(void)growlNotificationTimedOut:(NSObject*)context;
-(void)growlNotificationCoalesced:(NSObject*)context;
-(void)modalTableView:(GPModalTableViewClient*)client clickedButton:(NSString*)identifier;
-(void)modalTableView:(GPModalTableViewClient*)client movedItem:(NSString*)targetItem below:(NSString*)belowItem;
-(void)modalTableView:(GPModalTableViewClient*)client deletedItem:(NSString*)item;
-(void)modalTableView:(GPModalTableViewClient*)client selectedItem:(NSString*)item;
-(void)modalTableView:(GPModalTableViewClient*)client changedDescription:(NSString*)newDescription forItem:(NSString*)item;
-(void)modalTableView:(GPModalTableViewClient*)client tappedAccessoryButtonInItem:(NSString*)item;
-(void)modalTableViewDismissed:(GPModalTableViewClient*)client;
@end
@implementation GPGriPTestDelegate
@synthesize completed;
-(NSString*)applicationNameForGrowl { return @"GriP Command line utility"; }
-(NSDictionary*)registrationDictionaryForGrowl {
	return [NSDictionary dictionaryWithObjectsAndKeys:
			[NSArray arrayWithObject:@"Command line message"], GROWL_NOTIFICATIONS_ALL,
			[NSArray array], GROWL_NOTIFICATIONS_DEFAULT,
			nil];
}
-(void)growlNotificationWasClicked:(NSObject*)context {
	printf("GPGriPTest: growlNotificationWasClicked:\n");
	completed = YES;
}
-(void)growlNotificationTimedOut:(NSObject*)context {
	printf("GPGriPTest: growlNotificationTimedOut:\n");
	completed = YES;
}
-(void)growlNotificationCoalesced:(NSObject*)context {
	printf("GPGriPTest: growlNotificationCoalesced:\n");
	completed = YES;
}
-(void)modalTableView:(GPModalTableViewClient*)client clickedButton:(NSString*)identifier {
	printf("GPGriPTest: modalTableView:clickedButton: (identifier=\"%s\")\n", [identifier UTF8String]);
}
-(void)modalTableView:(GPModalTableViewClient*)client movedItem:(NSString*)targetItem below:(NSString*)belowItem {
	printf("GPGriPTest: modalTableView:movedItem:below: (targetItem=\"%s\", belowItem=\"%s\")\n", [targetItem UTF8String], [belowItem UTF8String]);
}
-(void)modalTableView:(GPModalTableViewClient*)client deletedItem:(NSString*)item {
	printf("GPGriPTest: modalTableView:deletedItem: (item=\"%s\")\n", [item UTF8String]);
}
-(void)modalTableView:(GPModalTableViewClient*)client selectedItem:(NSString*)item {
	printf("GPGriPTest: modalTableView:selectedItem: (item=\"%s\")\n", [item UTF8String]);
}
-(void)modalTableView:(GPModalTableViewClient*)client changedDescription:(NSString*)newDescription forItem:(NSString*)item {
	printf("GPGriPTest: modalTableView:changedDescription:forItem (newDescription=\"%s\", item=\"%s\")\n", [newDescription UTF8String], [item UTF8String]);
}
-(void)modalTableView:(GPModalTableViewClient*)client tappedAccessoryButtonInItem:(NSString*)item {
	printf("GPGriPTest: modalTableView:tappedAccessoryButtonInItem: (item=\"%s\")\n", [item UTF8String]);
}
-(void)modalTableViewDismissed:(GPModalTableViewClient*)client {
	printf("GPGriPTest: modalTableViewDismissed:\n");
	completed = YES;
}
@end



int GPGriPTest(int argc, char* argv[]) {
	if (argc == 1) {
		printf("Usage: GriP [<options>]\n"
			   "	where options are:\n"
			   "		-t  <title>        Title of message.\n"
			   "		-d  <description>  Description of message.\n"
			   "		-i  <icon>         File name or bundle identifier to use for the icon.\n"
			   "		-u  <url>          URL to launch when touched.\n"
			   "		-p  <priority>     Priority of message. Must be \"-2\" to \"2\"\n"
			   "		-s	               Set message as sticky.\n"
			   "		-e  <id>           Identifier (for coalescing).\n"
			   "		-a	<filename>     Display a GPTableViewAlert using filename as the dictionary.\n"
		);
	} else {
		// get options.
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		
		BOOL sticky = NO;
		NSString* title = nil;
		NSString* desc = nil;
		NSObject* icon = nil;
		id url = @"context";
		int priority = 0;
		NSString* identifier = nil;
		NSDictionary* gptvaDict = nil;
		
		GPModalTableViewClient* mtvClient = nil;
		
		int c;
		optind = 1;
		while ((c = getopt(argc, argv, "t:d:i:u:p:se:a:")) != -1) {
			switch (c) {
				case 't':
					title = [NSString stringWithUTF8String:optarg];
					break;
					
				case 'd':
					desc = [NSString stringWithUTF8String:optarg];
					break;
					
				case 'i':
					icon = [NSString stringWithUTF8String:optarg];
					icon = [NSData dataWithContentsOfFile:(NSString*)icon] ?: icon;
					break;
					
				case 'u':
					url = [NSURL URLWithString:[NSString stringWithUTF8String:optarg]];
					break;
					
				case 'p':
					sscanf(optarg, "%d", &priority);
					if (priority < -2) priority = -2;
					if (priority > 2) priority = 2;
					break;
					
				case 's':
					sticky = YES;
					break;
					
				case 'e':
					identifier = [NSString stringWithUTF8String:optarg];
					break;
					
				case 'a':
					gptvaDict = [NSDictionary dictionaryWithContentsOfFile:[NSString stringWithUTF8String:optarg]];
					break;
			}
		}
		
		GPGriPTestDelegate* delegate = [[GPGriPTestDelegate alloc] init];
		GPApplicationBridge* bridge = [[GPApplicationBridge alloc] init];
		
		if (bridge == nil) {
			printf("Error: GPApplicationBridge is not initialized. Please make sure GriP is running.\n");
			goto cleanup;
		}
		
		bridge.growlDelegate = delegate;
		
		if (![bridge enabledForName:@"Command line message"]) {
			printf("Error: I am being disabled. Nothing can be shown.\n"
				   "Please go to \"Settings\" -> \"GriP\" -> \"GriP Command line utility\" -> \"GriP Command line utility\" and turn ON \"Enabled\".\n");
			goto cleanup;
		}
		
		if (gptvaDict == nil)
			[bridge notifyWithTitle:title description:desc notificationName:@"Command line message" iconData:icon priority:priority isSticky:sticky clickContext:url identifier:identifier];
		else {
			mtvClient = [[GPModalTableViewClient alloc] initWithDictionary:gptvaDict applicationBridge:bridge name:@"Command line message"];
			mtvClient.delegate = delegate;
		}
		
		/*
		while (!delegate.completed) {
			CFRunLoopRunInMode(kCFRunLoopDefaultMode, 1, NO);
		}
		 */
		 
cleanup:
		[mtvClient release];
		[bridge release];
		[delegate release];
				
		[pool drain];
	}
	
	return 0;
}
