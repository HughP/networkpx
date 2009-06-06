/*

GPModalTableViewServer.m ... GriP Modal Table View Server.
 
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

#import <GriP/common.h>
#import <GriP/Duplex/Server.h>
#import <libkern/OSAtomic.h>
#import <GriP/GPPreferences.h>
#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import <GriP/GPModalTableViewController.h>
#import <objc/runtime.h>

static CFMutableDictionaryRef identifiedAlerts = NULL;
static int currentAlertUID = 0;


struct RCMBContext {
	GPModalTableViewNavigationController* controller;
	int currentAlertUID_copied;
	unsigned currentDistance;
};

static void GPModalTableViewSearchForMostRecentIdentifiedAlert (int uid, GPModalTableViewNavigationController* controller, struct RCMBContext* context) {
	unsigned distance = context->currentAlertUID_copied - uid;
	if (distance < context->currentDistance) {
		context->currentDistance = distance;
		context->controller = controller;
	}
}

static IMP original_clickedMenuButton = NULL, original_restartDimTimer = NULL;
static void replaced_clickedMenuButton (id self, SEL _cmd) {
	/*
	 // doesn't work?
	if (GPGetLocked())
		original_clickedMenuButton(self, _cmd);
	else
	 */
	{
		struct RCMBContext context = {nil, currentAlertUID, UINT_MAX};
		CFDictionaryApplyFunction(identifiedAlerts, (CFDictionaryApplierFunction)&GPModalTableViewSearchForMostRecentIdentifiedAlert, &context);
		[context.controller sendDismissMessage];
	}
}
static void replaced_restartDimTimer (id self, SEL _cmd, float duration) {
	original_restartDimTimer(self, _cmd, 0x7f7fffff);	// == FLOAT_MAX
}

static void GPModalTableViewHookSpringBoard () {
	// Hook some SpringBoard commands so that:
	//  - Pressing the Home button will dismiss the active Modal Table View instead of closing the active app
	//  - The lock screen will appear indefinitely until all Modal Table View are dismissed.
#if !TARGET_IPHONE_SIMULATOR
	if (CFDictionaryGetCount(identifiedAlerts) == 0) {
		original_clickedMenuButton = method_setImplementation(class_getInstanceMethod(objc_getClass("SBUIController"), @selector(clickedMenuButton)), (IMP)&replaced_clickedMenuButton);
		original_restartDimTimer = method_setImplementation(class_getInstanceMethod(objc_getClass("SBAwayController"), @selector(restartDimTimer:)), (IMP)&replaced_restartDimTimer);
	}
#endif
}

static void GPModalTableViewUnhookSpringBoard() {
#if !TARGET_IPHONE_SIMULATOR
	if (CFDictionaryGetCount(identifiedAlerts) == 0) {
		method_setImplementation(class_getInstanceMethod(objc_getClass("SBUIController"), @selector(clickedMenuButton)), original_clickedMenuButton);
		Class _SBAwayController = objc_getClass("SBAwayController");
		method_setImplementation(class_getInstanceMethod(_SBAwayController, @selector(restartDimTimer:)), original_restartDimTimer);
		original_restartDimTimer(objc_msgSend(_SBAwayController, @selector(sharedAwayController)), @selector(restartDimTimer:), 0x41000000);
	}
#endif
}


struct GPTVAActuallyShowAlert_Context {
	NSArray* array;
	int alertUID;
};

static void GPTVAActuallyShowAlert(CFRunLoopTimerRef timer, struct GPTVAActuallyShowAlert_Context* context) {
	GPModalTableViewHookSpringBoard();
	
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	GPModalTableViewNavigationController* navCtrler = [[GPModalTableViewNavigationController alloc] initWithDictionary:[context->array objectAtIndex:1]];
	navCtrler.uid = [NSNumber numberWithInt:context->alertUID];
	navCtrler.clientPortID = [context->array objectAtIndex:0];
	CFDictionaryAddValue(identifiedAlerts, (const void*)context->alertUID, navCtrler);
	[context->array release];
	free(context);
	[pool drain];
}

#define AssignArray(maxCount) \
array = [NSPropertyListSerialization propertyListFromData:(NSData*)data mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:NULL];\
if (![array isKindOfClass:[NSArray class]] || [array count] < (maxCount)) break

static inline GPModalTableViewNavigationController* GPGetModalTableViewNagivationController (NSArray* array) {
	NSNumber* uid = [array objectAtIndex:0];
	if ([uid respondsToSelector:@selector(integerValue)])
		return (GPModalTableViewNavigationController*)CFDictionaryGetValue(identifiedAlerts, (const void*)[uid integerValue]);
	else
		return nil;
}
 

CFDataRef GPModalTableViewServerCallback (CFMessagePortRef serverPort, SInt32 type, CFDataRef data, void* info) {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	CFDataRef retData = NULL;
	NSArray* array = nil;
	
	switch (type) {
		case GPTVAMessage_Show: {
			AssignArray(4);
			
			if (!GPCheckEnabled([array objectAtIndex:2], [array objectAtIndex:3], NO))
				break;
			
			int alertUID = OSAtomicIncrement32(&currentAlertUID);
			
			struct GPTVAActuallyShowAlert_Context* context = malloc(sizeof(struct GPTVAActuallyShowAlert_Context));
			context->array = [array retain];
			context->alertUID = alertUID;
			CFRunLoopTimerContext timerContext = {0, context, NULL, NULL, NULL};
			
			CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
			
			// Don't let the slow creation of the alert view delay our reply.
			CFRunLoopTimerRef constructorTimer = CFRunLoopTimerCreate(NULL, now+0.1, 0, 0, 0,
																	  (CFRunLoopTimerCallBack)&GPTVAActuallyShowAlert,
																	  &timerContext);
			CFRunLoopAddTimer(CFRunLoopGetCurrent(), constructorTimer, kCFRunLoopCommonModes);
			CFRelease(constructorTimer);
			
			retData = CFDataCreate(NULL, (const UInt8*)&alertUID, sizeof(int));
			break;
		}
			
		case GPTVAMessage_Push:
			AssignArray(2);
			[GPGetModalTableViewNagivationController(array) pushDictionary:[array objectAtIndex:1]];
			break;
			
		case GPTVAMessage_Pop:
			AssignArray(1);
			[GPGetModalTableViewNagivationController(array) pop];
			break;
			
		case GPTVAMessage_Reload:
			AssignArray(2);
			[GPGetModalTableViewNagivationController(array) updateToDictionary:[array objectAtIndex:1] forIdentifier:([array count] >= 3 ? [array objectAtIndex:2] : nil)];
			break;
			
		case GPTVAMessage_UpdateEntry:
			AssignArray(3);
			[GPGetModalTableViewNagivationController(array) updateItem:[array objectAtIndex:1] toEntry:[array objectAtIndex:2]];
			break;
			
		case GPTVAMessage_CheckVisible: {
			BOOL res = NO;
			if (data != NULL)
				res = ((GPModalTableViewNavigationController*)CFDictionaryGetValue(identifiedAlerts, *(const void**)CFDataGetBytePtr(data))).visible;
			retData = CFDataCreate(NULL, (const UInt8*)&res, sizeof(BOOL));
			break;
		}
			
		case GPTVAMessage_GetCurrentIdentifier: {
			if (data != NULL) {
				NSString* string = ((GPModalTableViewNavigationController*)CFDictionaryGetValue(identifiedAlerts, *(const void**)CFDataGetBytePtr(data))).topViewController.identifier;
				retData = CFDataCreate(NULL, (const UInt8*)[string UTF8String], [string length]+1);
			}
			break;
		}
			
		case GPTVAMessage_Dismiss: {
			const char* pid = (const char*)CFDataGetBytePtr(data);
			const void* alertUID = *(const void**)pid;
			pid += sizeof(const void*);
			[((GPModalTableViewNavigationController*)CFDictionaryGetValue(identifiedAlerts, alertUID)) animateOut];
			CFDictionaryRemoveValue(identifiedAlerts, alertUID);
			CFStringRef string = CFStringCreateWithCString(NULL, pid, kCFStringEncodingUTF8);
			CFDataRef data = CFDataCreate(NULL, (const UInt8*)&alertUID, sizeof(int));
			GPServerForwardMessage(string, type, data, NULL);
			CFRelease(data);
			CFRelease(string);
			GPModalTableViewUnhookSpringBoard();
			break;
		}
			
		case GPTVAMessage_UpdateButtons:
			AssignArray(2);
			[GPGetModalTableViewNagivationController(array) updateButtons:[array objectAtIndex:1] forIdentifier:([array count] >= 3 ? [array objectAtIndex:2] : nil)];
			break;
			
		default:
			break;
	}
	[pool drain];
	return retData;
}

void GPStopModalTableViewServer() {
	CFRelease(identifiedAlerts);
}

void GPStartModalTableViewServer() {
	CFDictionaryValueCallBacks callbacks = {0, NULL, kCFTypeDictionaryValueCallBacks.release, NULL, NULL};
	identifiedAlerts = CFDictionaryCreateMutable(NULL, 0, NULL, &callbacks);
}