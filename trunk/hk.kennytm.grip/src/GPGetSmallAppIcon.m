/*

GPGetSmallAppIcon.m ... Cross-firmware solution to get an application small icon.
 
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

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#if GRIP_JAILBROKEN

@interface SBApplication : NSObject
-(NSString*)pathForIcon;	// safe
-(BOOL)isSystemApplication;	// safe
-(BOOL)isPrerenderedIcon;	// not safe for < 2.1
@end
@interface SBApplicationIcon : NSObject
-(SBApplication*)application;	// safe
-(UIImage*)smallIcon;			// not safe for < 3.0
@end
@interface SBIconModel : NSObject
+(SBIconModel*)sharedInstance;	// safe
-(SBApplicationIcon*)iconForDisplayIdentifier:(NSString*)bundleIdentifier;	// safe
@end
@interface UIImage (ApplicationPrivate)
-(UIImage*)_smallApplicationIconImagePrecomposed:(BOOL)precomposed;	// safe
@end

typedef struct __CGImageSource* CGImageSourceRef;
CGImageSourceRef CGImageSourceCreateWithData(CFDataRef data, CFDictionaryRef options);
CGImageRef CGImageSourceCreateImageAtIndex(CGImageSourceRef isrc, size_t index, CFDictionaryRef options);

static CFDictionaryRef settingIcons = NULL;
static void GPReleaseSettingIcons () { if (settingIcons != NULL) { CFRelease(settingIcons); settingIcons = NULL; } }

UIImage* GPGetSmallAppIcon (NSString* bundleIdentifier) {
	if (settingIcons == nil) {
		// For some unknown reason... if I create the settingIcons dictionary as an NSDictionary* instead of CFDictionaryRef, 
		// SpringBoard crashes.
		static const CFStringRef values[] = {
			CFSTR("/System/Library/PreferenceBundles/AccountSettings/ContactsSettings.bundle/icon.png"),
			CFSTR("/System/Library/PreferenceBundles/AccountSettings/MobileCalSettings.bundle/icon.png"),
			CFSTR("/System/Library/PreferenceBundles/AccountSettings/MobileMailSettings.bundle/icon.png"),
			CFSTR("/System/Library/PreferenceBundles/AirPortSettings.bundle/icon.png"),
			CFSTR("/System/Library/PreferenceBundles/MobileSlideShowSettings.bundle/icon.png"),
			CFSTR("/System/Library/PreferenceBundles/MusicSettings.bundle/icon.png"),
			CFSTR("/System/Library/PreferenceBundles/ScheduleSettings.bundle/icon.png"),
			CFSTR("/System/Library/PreferenceBundles/VPNPreferences.bundle/icon.png"),
			CFSTR("/System/Library/PreferenceBundles/VideoSettings.bundle/icon.png"),
			CFSTR("/System/Library/PreferenceBundles/Wallpaper.bundle/icon.png"),
			CFSTR("/Applications/Preferences.app/Safari.png"),
			CFSTR("/Applications/Preferences.app/iPod.png"),
			CFSTR("/Applications/Preferences.app/AppStore.png"),
			CFSTR("/Applications/Preferences.app/Camera.png"),
			CFSTR("/Applications/Preferences.app/iTunes.png"),
			CFSTR("/Applications/Preferences.app/Settings-Air.png"),
			CFSTR("/Applications/Preferences.app/Settings-Display.png"),
			CFSTR("/Applications/Preferences.app/Settings-Sound.png"),
			CFSTR("/Applications/Preferences.app/Settings.png"),
			CFSTR("/Applications/Preferences.app/YouTube.png")
		};
		static const CFStringRef keys[] = {
			CFSTR("com.apple.MobileAddressBook"),
			CFSTR("com.apple.mobilecal"),
			CFSTR("com.apple.mobilemail"),
			CFSTR("(WiFi)"),
			CFSTR("com.apple.mobileslideshow"),
			CFSTR("(music)"),
			CFSTR("(schedule)"),
			CFSTR("(VPN)"),
			CFSTR("(video)"),
			CFSTR("(wallpaper)"),
			CFSTR("com.apple.mobilesafari"),
			CFSTR("com.apple.mobileipod"),
			CFSTR("com.apple.AppStore"),
			CFSTR("(camera)"),
			CFSTR("com.apple.MobileStore"),
			CFSTR("(airplane)"),
			CFSTR("(display)"),
			CFSTR("(sound)"),
			CFSTR("com.apple.Preferences"),
			CFSTR("com.apple.youtube")
		};
		settingIcons = CFDictionaryCreate(NULL, (const void**)keys, (const void**)values, sizeof(keys)/sizeof(CFStringRef), &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
		atexit(&GPReleaseSettingIcons);
	}
	
	NSString* path = (NSString*)CFDictionaryGetValue(settingIcons, bundleIdentifier);
	UIImage* retimg = nil;
	if (path != nil)
		retimg = [[UIImage alloc] initWithContentsOfFile:path];
	else {
		Class SBIconModel = objc_getClass("SBIconModel");
		SBApplicationIcon* icon = [[SBIconModel sharedInstance] iconForDisplayIdentifier:bundleIdentifier];
		if ([icon respondsToSelector:@selector(smallIcon)])
			retimg = [[icon smallIcon] retain];
		else {
			SBApplication* app = [icon application];
			BOOL isPrerendered = [app isSystemApplication];
			if (!isPrerendered && [app respondsToSelector:@selector(isPrerenderedIcon)])
				isPrerendered = [app isPrerenderedIcon];
			
			retimg = [[[UIImage imageWithContentsOfFile:[app pathForIcon]] _smallApplicationIconImagePrecomposed:isPrerendered] retain];
		}
	}
	return [retimg autorelease];
}

#else

// This won't return a 29x29 icon, but it's sufficient since the theme should resize it to 29x29 anyway.
UIImage* GPGetSmallAppIcon(NSString* bundleIdentifier) {
	return [UIImage imageWithContentsOfFile:[[NSBundle bundleWithIdentifier:bundleIdentifier] pathForResource:@"icon" ofType:@"png"]];
}

#endif

UIImage* GPGetSmallAppIconFromObject(NSObject* object) {
	if ([object isKindOfClass:[NSString class]]) {
#define str (NSString*)object
		if (GPStringIsEmoji(str)) {
			UIGraphicsBeginImageContext(CGSizeMake(29, 29));
			[str drawInRect:iconRect withFont:[UIFont systemFontOfSize:27.5f] lineBreakMode:UILineBreakModeWordWrap alignment:UITextAlignmentCenter];
			UIImage* retimg = UIGraphicsGetImageFromCurrentImageContext();
			UIGraphicsEndImageContext();
			return retimg;
		} else
			return GPGetSmallAppIcon(str);
#undef str
	} else if ([object isKindOfClass:[NSData class]])
		return [UIImage imageWithData:(NSData*)object];
	else
		return nil;
}
