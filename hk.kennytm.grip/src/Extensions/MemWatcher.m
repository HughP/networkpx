/*

MemWatcher.m ... Memory Watcher for GriP
 
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

#import <GriP/GriP.h>
#include <sys/sysctl.h>
#include <libkern/OSMemoryNotification.h>
#include <CoreFoundation/CoreFoundation.h>

NSString* const names[3] = {@"Memory at Warning level", @"Memory at Urgent level", @"Memory at Critical level"};
NSString* const englishFormats[3] = {@"Memory Warning (%d%%)", @"Memory Urgent (%d%%)", @"Memory Critical (%d%%)"};

@interface MemoryWatcher : NSObject {
	GPApplicationBridge* memWatcherBridge;
	NSString* formats[3];
	NSData* thisIcon;
}
-(id)init;
-(void)dealloc;
-(void)receivedMemoryWarning;
@end

void ReceivedMemoryWarningCallback (CFNotificationCenterRef center, MemoryWatcher* observer, CFStringRef name, const void* object, CFDictionaryRef userInfo) {
	[observer receivedMemoryWarning];
}


@implementation MemoryWatcher
-(id)init {
	if ((self = [super init])) {
		memWatcherBridge = [[GPApplicationBridge alloc] init];
		[memWatcherBridge registerWithDictionary:[NSDictionary dictionaryWithObjectsAndKeys:
												  @"Memory Watcher", GROWL_APP_NAME,
												  [NSArray arrayWithObjects:names count:3], GROWL_NOTIFICATIONS_ALL,
												  [NSArray arrayWithObjects:(names+1) count:2], GROWL_NOTIFICATIONS_DEFAULT,
												  nil]];
		if (memWatcherBridge.enabled) {
			NSBundle* thisBundle = [NSBundle bundleForClass:[self class]];
			thisIcon = [[NSData alloc] initWithContentsOfFile:[thisBundle pathForResource:@"icon" ofType:@"png"]];
			for (int i = 0; i < 3; ++ i)
				formats[i] = [[thisBundle localizedStringForKey:englishFormats[i] value:nil table:nil] retain];
			
			CFStringRef notifName = CFStringCreateWithCString(NULL, kOSMemoryNotificationName, kCFStringEncodingUTF8);
			CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), self, (CFNotificationCallback)&ReceivedMemoryWarningCallback, notifName, NULL, 0);
			CFRelease(notifName);
			
		} else {
			[self release];
			return nil;
		}
	}
	return self;
}

-(void)dealloc {
	CFNotificationCenterRemoveEveryObserver(CFNotificationCenterGetDarwinNotifyCenter(), self);
	
	[memWatcherBridge release];
	[thisIcon release];
	for (int i = 0; i < 3; ++ i)
		[formats[i] release];
	
	[super dealloc];
}


-(void)receivedMemoryWarning {
	int memPercent;
	size_t dummy = sizeof(int);
	sysctlbyname("kern.memorystatus_level", &memPercent, &dummy, NULL, 0);
	OSMemoryNotificationLevel level = OSMemoryNotificationCurrentLevel() - 1;
	if (level < 0)
		return;
	
	[memWatcherBridge notifyWithTitle:[NSString stringWithFormat:formats[level], memPercent]
						  description:nil
					 notificationName:names[level]
							 iconData:thisIcon
							 priority:0
							 isSticky:NO
						 clickContext:nil];
}
@end