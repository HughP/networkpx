/*
 
 libiKeyEx.m ... iKeyEx support functions.
 
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
#import <UIKit/UIKit2.h>
#import "libiKeyEx.h"
#include <libkern/OSAtomic.h>
#include <pthread.h>
#import <AppSupport/AppSupport.h>
#include <sys/types.h>
#include <sys/stat.h>

extern BOOL IKXIsiKeyExMode(NSString* modeString) {
	return [modeString hasPrefix:@"iKeyEx:"];
}
extern BOOL IKXIsInternalMode(NSString* modeString) {
	return [modeString hasPrefix:@"iKeyEx:__"];
}

static IKXAppType _IKXCurrentAppType = IKXAppTypeError;

#if TARGET_IPHONE_SIMULATOR
static const CFStringRef _IKXPreferenceDomain;
#endif

extern CFStringRef IKXPreferenceDomain() {
#if TARGET_IPHONE_SIMULATOR
	if (_IKXPreferenceDomain == NULL) {
		CFStringRef tmp = CPCopySharedResourcesPreferencesDomainForDomain(CFSTR("hk.kennytm.iKeyEx3"));
		if (!OSAtomicCompareAndSwapPtrBarrier(NULL, (void*)tmp, (void*volatile*)&_IKXPreferenceDomain)) {
			if (tmp)
				CFRelease(tmp);
		}
	}
	return _IKXPreferenceDomain;
#else
	return CFSTR("/var/mobile/Library/Preferences/hk.kennytm.iKeyEx3");
#endif
}

extern void IKXFlushConfigDictionary() {
	CFStringRef domain = IKXPreferenceDomain();
	CFPreferencesAppSynchronize(domain);
	if (geteuid() == 0) {
		// force the prefs file to be owned by mobile:mobile and world-read/writable. damnit.
		const char* filename = [[(NSString*)domain stringByAppendingPathExtension:@"plist"] UTF8String];
		chmod(filename, 0666);
		chown(filename, 501, 501);	// hack: assumes mobile:mobile == 501:501.
	}
}

extern id IKXConfigCopy(NSString* key) { return (id)CFPreferencesCopyAppValue((CFStringRef)key, IKXPreferenceDomain()); }
extern BOOL IKXConfigGetBool(NSString* key, BOOL defaultValue) {
	Boolean valid;
	BOOL retval = CFPreferencesGetAppBooleanValue((CFStringRef)key, IKXPreferenceDomain(), &valid);
	return valid ? retval : defaultValue;
}
extern int IKXConfigGetInt(NSString* key, int defaultValue) {
	Boolean valid;
	int retval = CFPreferencesGetAppIntegerValue((CFStringRef)key, IKXPreferenceDomain(), &valid);
	return valid ? retval : defaultValue;
}
extern void IKXConfigSet(NSString* key, id value) {
	CFPreferencesSetAppValue((CFStringRef)key, value, IKXPreferenceDomain());
	if ([key isEqualToString:@"AppleKeyboards"])
		IKXConfigReverseSyncAppleKeyboards(value);
}
extern void IKXConfigSetBool(NSString* key, BOOL value) { IKXConfigSet(key, (id)(value ? kCFBooleanTrue : kCFBooleanFalse)); }
extern void IKXConfigSetInt(NSString* key, int value) { IKXConfigSet(key, [NSNumber numberWithInt:value]); }

extern void IKXConfigReverseSyncAppleKeyboards(NSArray* value) {
	UIKeyboardImpl* impl = [UIKeyboardImpl sharedInstance];
	NSArray* currentActiveModes = UIKeyboardGetActiveInputModes();
	if (![currentActiveModes isEqualToArray:value]) {
		UIKeyboardSetActiveInputModes(value);
		[impl setInputModePreference];
		if (![value containsObject:UIKeyboardGetCurrentInputMode()])
			[impl setInputMode:[value objectAtIndex:0]];
	}
}

//------------------------------------------------------------------------------

extern NSString* IKXLayoutReference(NSString* modeString) {
	if ([modeString isEqualToString:@"iKeyEx:__KeyboardChooser"])
		return @"__KeyboardChooser";
	else {
		NSDictionary* modes = IKXConfigCopy(@"modes");
		NSString* rv = [[modes objectForKey:modeString] objectForKey:@"layout"];
		[modes release];
		return rv;		
	}
}

extern NSString* IKXInputManagerReference(NSString* modeString) {
	if ([modeString isEqualToString:@"iKeyEx:__KeyboardChooser"])
		return @"=en_US";
	else {
		NSDictionary* modes = IKXConfigCopy(@"modes");
		NSString* rv = [[modes objectForKey:modeString] objectForKey:@"manager"];
		[modes release];
		return rv;
	}
}

extern NSBundle* IKXLayoutBundle(NSString* layoutReference) {
	return [NSBundle bundleWithPath:[NSString stringWithFormat:IKX_LIB_PATH@"/Keyboards/%@.keyboard", layoutReference]];
}

extern NSBundle* IKXInputManagerBundle(NSString* imeReference) {
	return [NSBundle bundleWithPath:[NSString stringWithFormat:IKX_LIB_PATH@"/InputManagers/%@.ime", imeReference]];
}

//------------------------------------------------------------------------------

extern void IKXPlaySound() {
	[UIHardware _playSystemSound:0x450];
}

extern NSString* IKXNameOfMode(NSString* modeString) {
	if (IKXIsiKeyExMode(modeString)) {
		NSDictionary* modes = IKXConfigCopy(@"modes");
		NSString* rv = [[modes objectForKey:modeString] objectForKey:@"name"];
		[modes release];
		return rv;
	} else {
		if ([modeString isEqualToString:@"emoji"])
			return @"Emoji";
		else if ([modeString isEqualToString:@"intl"])
			return @"QWERTY";
		else {
			NSLocale* curLocale = [NSLocale currentLocale];
			NSRange locRange = [modeString rangeOfString:@"-"];
			if (locRange.location == NSNotFound) {
				return [curLocale displayNameForKey:NSLocaleIdentifier value:modeString] ?: modeString;
			} else {
				NSString* localeStr = [curLocale displayNameForKey:NSLocaleIdentifier value:[modeString substringToIndex:locRange.location]];
				if ([modeString hasPrefix:@"zh"]) {
					NSUInteger firstOpen = [localeStr rangeOfString:@"("].location;
					if (firstOpen != NSNotFound)
						localeStr = [localeStr substringWithRange:NSMakeRange(firstOpen+1, [localeStr length]-2-firstOpen)];
				}
				NSString* type = [@"UI" stringByAppendingString:[modeString substringFromIndex:locRange.location]];
				return [NSString stringWithFormat:@"%@ (%@)", localeStr, UIKeyboardLocalizedString(type, modeString, nil)];
			}
		}
	}
}

//------------------------------------------------------------------------------

extern IKXAppType IKXAppTypeOfCurrentApplication() {
	// Make sure Error is not returned if a flush happened during calculation.
	while (_IKXCurrentAppType == IKXAppTypeError) {
		NSString* appID = [[[NSBundle mainBundle] bundleIdentifier] lowercaseString];
		NSDictionary* appTypes = IKXConfigCopy(@"appTypes");
		NSSet* ansiApps = [NSSet setWithArray:[appTypes objectForKey:@"ANSI"]];
		if (![ansiApps count])
			ansiApps = [NSSet setWithObject:@"com.googlecode.mobileterminal"];
		if ([ansiApps containsObject:appID])
			_IKXCurrentAppType = IKXAppTypeANSI;
		else {
			NSSet* vncApps = [NSSet setWithArray:[appTypes objectForKey:@"VNC"]];
			// Note: I haven't tested on every one of these...
			if (![vncApps count])
				vncApps = [NSSet setWithObjects:
						   @"com.jugaari.teleport",
						   @"dk.mochasoft.vnc",
						   @"dk.mochasoft.vnclite",
						   @"com.logmein.ignition",
						   @"com.readpixel.remotetap",
						   @"com.pratikkumar.remotejr",
						   @"com.clickgamer.vncpocketoffice",
						   @"com.robohippo.hipporemote",
						   @"com.leptonic.airmote",
						   nil];
			if ([vncApps containsObject:appID])
				_IKXCurrentAppType = IKXAppTypeX11;
			else
				_IKXCurrentAppType = IKXAppTypeNormal;
		}
		[appTypes release];
	}
	return _IKXCurrentAppType;
}

//------------------------------------------------------------------------------

extern NSString* IKXLocalizedString(NSString* key) {
	static NSBundle* sysBundle = nil;
	if (!sysBundle) {
		NSBundle* temp_sysBundle = [[NSBundle alloc] initWithPath:IKX_PREFS_PATH];
		if (!OSAtomicCompareAndSwapPtrBarrier(nil, temp_sysBundle, (void*volatile*)&sysBundle))
			[temp_sysBundle release];
	}
	return [sysBundle localizedStringForKey:key value:nil table:@"iKeyEx"] ?: key;
}

//------------------------------------------------------------------------------

extern UIProgressHUD* IKXShowLoadingHUD() {
	UIWindow* topLevelWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	topLevelWindow.windowLevel = UIWindowLevelAlert;
	topLevelWindow.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
	
	UIProgressHUD* hud = [[UIProgressHUD alloc] init];
	[hud setText:IKXLocalizedString(@"Loading iKeyEx")];	
	[hud showInView:topLevelWindow];	
/*
	UIProgressView* pv = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
	pv.tag = 193;
	[hud addSubview:pv];
	[pv release];
*/
	topLevelWindow.hidden = NO;
	
	return hud;
	// intentional retainCount +1 for topLevelWindow.
}

extern void IKXHideLoadingHUD(UIProgressHUD* hud) {
	UIWindow* hudWin = hud.window;
	[hud hide];
	[hud release];
	hudWin.hidden = YES;
	[hudWin release];
}

extern void IKXRefreshLoadingHUDWithPercentage(int percentage, UIProgressHUD* hud) {
//	[[hud viewWithTag:193] setProgress:percentage*0.01f];
	[hud setText:[NSString stringWithFormat:@"%@ (%d%%)", IKXLocalizedString(@"Loading iKeyEx"), percentage]];
	CFRunLoopRunInMode(CFSTR("UITrackingRunLoopMode"), 0, YES);

}

// 1 <hide>
//       <show>