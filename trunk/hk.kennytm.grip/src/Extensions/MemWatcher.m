/*

MemWatcher.c ... Memory Watcher for GriP
 
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

#import <GriP/GPExtensions.h>
#import <GriP/GriP.h>
#import <sys/sysctl.h>
#if !TARGET_IPHONE_SIMULATOR
#import <libkern/OSMemoryNotification.h>
#endif
#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>

static CFStringRef const names[3] = {CFSTR("Memory Warning"), CFSTR("Memory Urgent"), CFSTR("Memory Critical")};
static GPApplicationBridge* memWatcherBridge = nil;
static CFStringRef localizedFormats[3] = {NULL, NULL, NULL};

static void terminator () {
	if (memWatcherBridge != NULL) {
		CFNotificationCenterRemoveEveryObserver(CFNotificationCenterGetDarwinNotifyCenter(), memWatcherBridge);
		[memWatcherBridge release];
	}
	for (int i = 0; i < 3; ++ i)
		if (localizedFormats[i] != NULL) {
			CFRelease(localizedFormats[i]);
			localizedFormats[i] = NULL;
		}
}

static void ReceivedMemoryWarningCallback (CFNotificationCenterRef center, void* observer, CFStringRef name, const void* object, CFDictionaryRef userInfo) {
	int memPercent = 0;
	size_t dummy = sizeof(int);
	sysctlbyname("kern.memorystatus_level", &memPercent, &dummy, NULL, 0);
#if !TARGET_IPHONE_SIMULATOR
	OSMemoryNotificationLevel level = OSMemoryNotificationCurrentLevel() - 1;
#else
	int level = 1;
#endif
	if (level < 0)
		return;
	
	CFStringRef formattedString = CFStringCreateWithFormat(NULL, NULL, localizedFormats[level], memPercent);
	UniChar iconChar = 0xe252;
	CFStringRef iconString = CFStringCreateWithCharacters(NULL, &iconChar, 1);
	[memWatcherBridge notifyWithTitle:(NSString*)formattedString
						  description:nil
					 notificationName:(NSString*)names[level]
							 iconData:(NSString*)iconString
							 priority:0
							 isSticky:NO
						 clickContext:nil];
	CFRelease(formattedString);
	CFRelease(iconString);
}

static void second_initializer () {
	atexit(&terminator);
	
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	memWatcherBridge = [[GPApplicationBridge alloc] init];
	
	if (memWatcherBridge != NULL) {
		CFArrayRef allArray = CFArrayCreate(NULL, (const void**)names, 3, &kCFTypeArrayCallBacks);			/// !!!!
		CFArrayRef defaultArray = CFArrayCreate(NULL, (const void**)(names+1), 2, &kCFTypeArrayCallBacks);
		
		static NSString* const keys[3] = {GROWL_APP_NAME, GROWL_NOTIFICATIONS_ALL, GROWL_NOTIFICATIONS_DEFAULT};
		CFTypeRef values[3] = {CFSTR("Memory Watcher"), allArray, defaultArray};
		
		// callbacks are used just to let GPApplicationBridge_Register see them...
		CFDictionaryRef regDict = CFDictionaryCreate(NULL, (const void**)keys, (const void**)values, 3, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
		[memWatcherBridge registerWithDictionary:(NSDictionary*)regDict];

		CFRelease(allArray);
		CFRelease(defaultArray);
		CFRelease(regDict);
		
		if (memWatcherBridge.enabled) {
#if !TARGET_IPHONE_SIMULATOR
			CFURLRef url = CFURLCreateWithFileSystemPath(NULL, CFSTR("/Library/MobileSubstrate/DynamicLibraries/MemoryWatcher.plist"), kCFURLPOSIXPathStyle, false);
#else
			CFURLRef url = CFBundleCopyResourceURL(CFBundleGetMainBundle(), CFSTR("MemoryWatcher"), CFSTR("plist"), NULL);
#endif
			CFDictionaryRef localizableStrings = GPPropertyListCopyLocalizableStringsDictionary(url);
			CFRelease(url);
			for (int i = 0; i < 3; ++ i)
				localizedFormats[i] = CFStringCreateWithFormat(NULL, NULL, CFSTR("%@ (%%d%%%%)"), CFDictionaryGetValue(localizableStrings, names[i]));
			CFRelease(localizableStrings);
#if !TARGET_IPHONE_SIMULATOR			
			CFStringRef notifName = CFStringCreateWithCString(NULL, kOSMemoryNotificationName, kCFStringEncodingUTF8);
			CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), memWatcherBridge, &ReceivedMemoryWarningCallback, notifName, NULL, 0);
			CFRelease(notifName);
#else
			CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), memWatcherBridge, &ReceivedMemoryWarningCallback, CFSTR("kennytm.memorywatcher.test"), NULL, 0);
#endif
		} else {
			terminator();
		}
	}
	
	[pool drain];
}

void first_initializer () {
	GPStartWhenGriPIsReady(&second_initializer);
}