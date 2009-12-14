/*

Hook.m ... Hook for Don't Scroll To Top.
Copyright (C) 2009  KennyTM~ <kennytm@gmail.com>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

#import <substrate2.h>
#import <UIKit/UIKit.h>
#include <notify.h>

static BOOL enabled;
static int x;

static void updateEnabled(CFNotificationCenterRef center, void* observer, CFStringRef name, const void* object, CFDictionaryRef userInfo) {
	uint64_t state;
	int token;
	notify_register_check("hk.kennytm.DontScrollToTop.enabled", &token);
	notify_get_state(token, &state);
	notify_cancel(token);
	enabled = (state != 0);
}

DefineObjCHook(void, UIWindow__statusBarMouseDown_, id self, SEL _cmd, void* event) {
	if (enabled)
		Original(UIWindow__statusBarMouseDown_)(self, _cmd, event);
}
DefineObjCHook(void, UIApplication_statusBarMouseDown_, id self, SEL _cmd, void* event) {
	if (enabled)
		Original(UIApplication_statusBarMouseDown_)(self, _cmd, event);
}

static void installHooks(CFNotificationCenterRef center, void* observer, CFStringRef name, const void* object, CFDictionaryRef userInfo) {
	CFNotificationCenterRemoveObserver(CFNotificationCenterGetLocalCenter(), &x, CFSTR("UIApplicationDidFinishLaunchingNotification"), NULL);
	
	updateEnabled(NULL, NULL, NULL, NULL, NULL);
	
	InstallObjCInstanceHook([UIWindow class], @selector(_statusBarMouseDown:), UIWindow__statusBarMouseDown_);
	InstallObjCInstanceHook([(UIApplication*)object class], @selector(statusBarMouseDown:), UIApplication_statusBarMouseDown_);
	
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, updateEnabled, CFSTR("hk.kennytm.DontScrollToTop.enabled"), NULL, 0);
	
}

__attribute__((constructor))
static void initialize() {
	CFNotificationCenterAddObserver(CFNotificationCenterGetLocalCenter(), &x, installHooks, CFSTR("UIApplicationDidFinishLaunchingNotification"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
}
