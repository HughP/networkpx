/*

GriPPushNotification ... Display Push Notification Alerts in GriP.
 
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
#import <GriP/GPExtensions.h>
#import <substrate.h>

__attribute__((visibility("hidden")))
@interface SBApplication : NSObject
-(void)setActivationSetting:(unsigned)activationSetting flag:(BOOL)flag;
-(NSString*)displayIdentifier;
-(NSString*)displayName;
@end

static GPApplicationBridge* bridge = nil;
static NSString* push, *notifies, *vinn, *view;
static IMP SBRemoteNotificationAlert_activateApplication = NULL, SBAlertItem_dismiss = NULL;


__attribute__((visibility("hidden")))
@interface FakeAlert : NSObject {}@end
@implementation FakeAlert
static FakeAlert* _sharedAlert = nil;
+(FakeAlert*)sharedAlert {
//	@synchronized(self) {
		if (_sharedAlert == nil)
			_sharedAlert = [[self alloc] init];
//	}
	return _sharedAlert;
}
+(void)releaseSharedAlert {
//	@synchronized(self) {
		SBAlertItem_dismiss(_sharedAlert, @selector(dismiss));
//		[_sharedAlert release];
//		_sharedAlert = nil;
//	}
}
- (Class)alertSheetClass { return Nil; }
- (id)alertSheet { return nil; }
- (BOOL)allowMenuButtonDismissal { return NO; }
- (BOOL)shouldShowInLockScreen { return YES; }
- (BOOL)shouldShowInEmergencyCall { return YES; }
- (BOOL)undimsScreen { return NO; }
- (BOOL)unlocksScreen { return NO; }
- (BOOL)togglesMediaControls { return NO; }
- (BOOL)dismissOnLock { return YES; }
- (BOOL)dimissOnAlertActivation { return YES; }
- (BOOL)willShowInAwayItems { return YES; }
- (void)cleanPreviousConfiguration {}
- (void)configure:(BOOL)fp8 requirePasscodeForActions:(BOOL)fp12 {}
- (id)lockLabel { return @"i can haz unlock?"; }
- (float)lockLabelFontSize { return 18; }
- (double)autoDismissInterval { return 8; }
- (void)setDisallowsUnlockAction:(BOOL)fp8 {}
- (BOOL)disallowsUnlockAction { return NO; }
- (void)performUnlockAction {}
- (void)setOrderOverSBAlert:(BOOL)fp8 {}
- (BOOL)preventLockOver { return NO; }
- (void)setPreventLockOver:(BOOL)fp8 {}
- (void)willActivate {}
- (void)didActivate {}
- (void)willRelockForButtonPress:(BOOL)fp8 {}
- (void)dismiss {}
- (void)screenWillUndim {}
- (void)willDeactivateForReason:(int)fp8 {}
- (void)didDeactivateForReason:(int)fp8 {}
- (id)awayItem { return self; }	// will this be buggy???
@end


__attribute__((visibility("hidden")))
@interface GriPPushNotificationDelegate : NSObject<GrowlApplicationBridgeDelegate> {
	NSMutableDictionary* apps;
}
-(id)init;
-(void)dealloc;
-(NSDictionary*)registrationDictionaryForGrowl;
-(void)growlNotificationTimedOut:(NSObject*)context;
-(void)growlNotificationWasClicked:(NSObject*)context;
-(NSNumber*)addApp:(SBApplication*)app;
@end
@implementation GriPPushNotificationDelegate
-(NSDictionary*)registrationDictionaryForGrowl {
	NSArray* supportedMessages = [NSArray arrayWithObject:@"Push Notification Alert"];
	return [NSDictionary dictionaryWithObjectsAndKeys:
			@"GriP Push Notification", GROWL_APP_NAME,
			supportedMessages, GROWL_NOTIFICATIONS_ALL,
			supportedMessages, GROWL_NOTIFICATIONS_DEFAULT, nil];
}
-(NSNumber*)addApp:(SBApplication*)app {
	NSNumber* iden = [NSNumber numberWithInt:(int)app];
	[apps setObject:app forKey:iden];
	return iden;
}
-(id)init {
	if ((self = [super init]))
		apps = [[NSMutableDictionary alloc] init];
	return self;
}
-(void)dealloc {
	[apps release];
	[super dealloc];
}
-(void)growlNotificationTimedOut:(NSObject*)context {
	[FakeAlert releaseSharedAlert];
	[apps removeObjectForKey:context];
}
-(void)growlNotificationWasClicked:(NSObject*)context {
	struct {
		void* isa, *_alertSheet;
		BOOL _disallowUnlockAction, _orderOverSBAlert, _preventLockOver;
		SBApplication* _app;
		void* _body, *_actionLabel;
		BOOL _showActionButton, _launched;
	} FakeAlert2;
	FakeAlert2._app = [apps objectForKey:context];
	SBRemoteNotificationAlert_activateApplication((id)&FakeAlert2, @selector(activateApplication));
	[apps removeObjectForKey:context];
}
@end



static IMP old_SBRemoteNotificationAlert_initWithApplication_body_showActionButton_actionLabel = NULL;
static id replaced_SBRemoteNotificationAlert_initWithApplication_body_showActionButton_actionLabel(id self, SEL _cmd, SBApplication* app, NSString* body, BOOL showActionButton, NSString* actionLabel) {
	// Check if the extension is enabled. If no, revert to default behavior.
	if ([bridge enabledForName:@"Push Notification Alert"]) {
		
		[app retain];
		
		NSString* appName = [app displayName];
		NSString* title2;
		
		if (showActionButton)
			title2 = [NSString stringWithFormat:vinn, (actionLabel ?: view), appName];
		else
			title2 = [NSString stringWithFormat:notifies, appName];
				
		[bridge notifyWithTitle:[push stringByAppendingString:title2]
					description:body
			   notificationName:@"Push Notification Alert"
					   iconData:[app displayIdentifier]
					   priority:0
					   isSticky:NO
				   clickContext:[(GriPPushNotificationDelegate*)bridge.growlDelegate addApp:app]];
		
		[self release];
		return [FakeAlert sharedAlert];
		
	} else
		return old_SBRemoteNotificationAlert_initWithApplication_body_showActionButton_actionLabel(self, _cmd, app, body, showActionButton, actionLabel);
	
}



static void terminator() {
	[bridge.growlDelegate release];
	[bridge release];
	[push release];
	[notifies release];
	[vinn release];
	[view release];
}

static void second_initializer() {
	atexit(&terminator);
	
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	bridge = [[GPApplicationBridge alloc] init];
	bridge.growlDelegate = [[GriPPushNotificationDelegate alloc] init];
	
	NSURL* myDictURL = [NSURL fileURLWithPath:@"/Library/MobileSubstrate/DynamicLibraries/GriPPushNotification.plist" isDirectory:NO];
	NSDictionary* localizationStrings = GPPropertyListCopyLocalizableStringsDictionary(myDictURL);
	
	push = [([localizationStrings objectForKey:@"Push"] ?: @"[Push] ") retain];
	notifies = [([localizationStrings objectForKey:@"%@ notifies"] ?: @"%@ notifies") retain];
	vinn = [([localizationStrings objectForKey:@"%@ in %@"] ?: @"%@ in %@") retain];
	view = [[[NSBundle mainBundle] localizedStringForKey:@"VIEW" value:@"View" table:@"SpringBoard"] retain];
	
	id cls = objc_getClass("SBRemoteNotificationAlert");
	
	old_SBRemoteNotificationAlert_initWithApplication_body_showActionButton_actionLabel 
	= MSHookMessage(cls, @selector(initWithApplication:body:showActionButton:actionLabel:),
					(IMP)&replaced_SBRemoteNotificationAlert_initWithApplication_body_showActionButton_actionLabel, NULL);
	
	SBRemoteNotificationAlert_activateApplication = [cls instanceMethodForSelector:@selector(activateApplication)];
	SBAlertItem_dismiss = [objc_getClass("SBAlertItem") instanceMethodForSelector:@selector(dismiss)];
	
	[pool drain];
}

void first_initializer() {
	GPStartWhenGriPIsReady(&second_initializer);
}