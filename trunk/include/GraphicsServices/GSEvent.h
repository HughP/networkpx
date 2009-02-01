/*
 
 GSEvent.h ... Graphics Services Events.
 
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

#ifndef GRAPHICSSERVICES_GSEVENT_H
#define GRAPHICSSERVICES_GSEVENT_H

#include <CoreFoundation/CoreFoundation.h>
#include <CoreGraphics/CGGeometry.h>
#include <GraphicsServices/GSWindow.h>

typedef struct __CFRuntimeBase {
	void* _isa; 
    uint16_t _info;
    uint16_t _rc;
} CFRuntimeBase;
typedef UInt32 SystemSoundID;

// Ref WebCore::PlatformMouseEvent::PlatformMouseEvent + 0xBC, assuming no change in ordering.
typedef enum GSEventFlags {
	kGSEventFlagMaskShift     = 1 << 17,
	kGSEventFlagMaskControl   = 1 << 18,
	kGSEventFlagMaskAlternate = 1 << 19,
	kGSEventFlagMaskCommand   = 1 << 20
} GSEventFlags;

typedef enum GSEventType {
	// Mouse event constants
	kGSEventLeftMouseDown    = 1,
	kGSEventLeftMouseUp      = 2,
	kGSEventMouseMoved       = 5,
	kGSEventLeftMouseDragged = 6,
	
	kGSEventKeyEventUnknown0 = 10,
	kGSEventKeyEventUnknown1 = 11,
	
	kGSEventScrollWheel = 22,
	
	kGSEventSetSensitivity = 1003,
	kGSEventHandBackTestResult = 1005,
	kGSEventRotateSimulator = 1011,
	kGSEventLockDevice = 1014,
	
	kGSEventVibrate = 1100,
	kGSEventSetBacklightFactor = 1102,
	kGSEventSetBacklightLevel = 1103,
	
	kGSEventApplicationStarted = 2000,
	kGSEventFinishedLaunching = 2002,
	kGSEventForceQuit = 2003,
	kGSEventApplicationSuspended = 2004,
	kGSEventApplicationOpenURL = 2006,
	kGSEventQuitTopApplication = 2009,
	kGSEventApplicationWillSuspend = 2010,
	kGSEventApplicationSuspendedSettingsUpdated = 2011,
	kGSEventApplicationWantsToSuspend = 2012,

	kGSEventResetIdleTimer = 2200,	
	kGSEventResetIdleDuration = 2201,
	
	kGSEventMouse = 3001,

	// this can be combined.
	kGSShouldRouteToFrontMost = 1 << 17
} GSEventType;

typedef UInt32 GSEventSubtype;

typedef struct GSHandInfo {
	int internalSubtype;	// 0x0 == 0x38
	short deltaX, deltaY;	// 2, 4 = 0x3C, 0x3E
	CGPoint _0x40;
	float width;			// 0x10 == 0x48
	float _0x4C;
	float height;			// 0x18 == 0x50
	float _0x54;
	unsigned char _0x58;
	unsigned char pathInfosCount;	// 0x21 == 0x59
} GSHandInfo;	// sizeof = 0x24.

typedef struct GSPathInfo {
	unsigned char pathIndex;		// 0x0 = 0x5C
	unsigned char pathIdentity;		// 0x1 = 0x5D
	unsigned char pathProximity;	// 0x2 = 0x5E
	float pathPressure;				// 0x4 = 0x60
	CGFloat pathMajorRadius;		// 0x8 = 0x64
	CGPoint pathLocation;			// 0xC = 0x68
	GSWindowRef pathWindow;			// 0x14 = 0x70
} GSPathInfo;	// sizeof = 0x18.

typedef struct GSAccessoryKeyStateInfo {
	int _1, _2;
} GSAccessoryKeyStateInfo;

   
typedef struct GSEventRecord {
	GSEventType type; // 0x8
	GSEventSubtype subtype;	// 0xC
	CGPoint location; 	// 0x10
	CGPoint windowLocation;	// 0x18
	CFTimeInterval time;	// 0x20
	GSEventFlags flags;
	unsigned short number;
	CFIndex size; // 0x2c	
} GSEventRecord;

typedef struct __GSEvent {
	CFRuntimeBase _base;
	GSEventRecord record;
} GSEvent;
typedef struct __GSEvent* GSEventRef;



// struct inheritance anyone???
typedef struct GSEventMouse {
	GSEvent _super;
	GSHandInfo handInfo;
	GSPathInfo pathInfos[];	// path infos are arranged from innermost to outermost.
} GSEventMouse;

typedef struct GSEventScrollWheel {
	GSEvent _super;
	int deltaY, deltaX;
} GSEventScrollWheel;

typedef struct GSEventAccelerometer {
	GSEvent _super;
	int axisX, axisY, axisZ;
} GSEventAccelerometer;

typedef struct GSEventDevice {
	GSEvent _super;
	int orientation;
} GSEventDevice;

typedef struct GSEventKey {
	GSEvent _super;
	UniChar keycode, characterIgnoringModifier, character;	// 0x38, 0x3A, 0x3C
	short characterSet;		// 0x3E
	Boolean isKeyRepeating;	// 0x40
} GSEventKey;

typedef struct GSEventAccessoryKey {
	GSEvent _super;
	GSAccessoryKeyStateInfo info;
} GSEventAccessoryKey;



GSEventType GSEventGetType(GSEventRef event);
void GSEventSetType(GSEventRef event, GSEventType type);
GSEventSubtype GSEventGetSubType(GSEventRef event);
unsigned short GSEventGetEventNumber(GSEventRef event);


void __GSEventClassInitialize();
// always return __kGSEventTypeID
CFTypeID GSEventGetTypeID();
GSEventRef GSEventCopy(GSEventRef event);

GSEventRef GSEventCreateAccessoryKeyStateEvent(GSEventRef oldEvent);	// TODO: ***signature not confirmed***

void GSEventRecordGetRecordWithPlist(CFDictionaryRef plist, GSEventRecord* record);
const void* GSEventRecordGetRecordDataWithPlist(CFDictionaryRef plist);
CFDictionaryRef GSEventCreatePlistRepresentation(GSEventRef event);
GSEventRef GSEventCreateWithPlist(CFDictionaryRef plist);

void GSEventRegisterFindWindowCallBack(GSWindowRef(*callback)(CGPoint));
void GSEventSetLocationInWindow(GSEventRef event, CGPoint loc);
void GSEventSetKeyWindow(GSWindowRef window);	// The window will be CFRetained.
GSWindowRef GSEventGetKeyWindow();


GSHandInfo GSEventGetHandInfo(GSEventRef event);
GSPathInfo GSEventGetPathInfoAtIndex(GSEventRef event, CFIndex index);
void GSEventSetPathInfoAtIndex(GSPathInfo pathInfo, GSEventRef event, CFIndex index);	// TODO: ***signature not confirmed***
GSWindowRef GSEventGetWindowForPathInfo(GSEventRef event, GSPathInfo pathInfo);	// TODO: ***signature not confirmed***
GSWindowRef GSEventGetWindow(GSEventRef event);


void GSEventDisableHandEventCoalescing(Boolean disable);
void GSEventSetHandInfoScale(GSEventRef event, float scale);

Boolean GSEventShouldRouteToFrontMost(GSEventRef event);
void GSEventRemoveShouldRouteToFrontMost(GSEventRef event);

CGFloat GSEventGetDeltaX(GSEventRef event);
CGFloat GSEventGetDeltaY(GSEventRef event);
void GSEventSetDeltaX(GSEventRef event, CGFloat deltaX);
void GSEventSetDeltaY(GSEventRef event, CGFloat deltaY);
int GSEventAccelerometerAxisX(GSEventRef event);
int GSEventAccelerometerAxisY(GSEventRef event);
int GSEventAccelerometerAxisZ(GSEventRef event);
int GSEventDeviceOrientation(GSEventRef event);
int GSEventGetClickCount(GSEventRef event);	// always return 1.

Boolean GSEventIsHandEvent (GSEventRef event);
Boolean GSEventIsChordingHandEvent(GSEventRef event);
CGPoint GSEventGetInnerMostPathPosition(GSEventRef event);
CGPoint GSEventGetOuterMostPathPosition(GSEventRef event);

CFStringRef GSEventCopyCharacters(GSEventRef event);
CFStringRef GSEventCopyCharactersIgnoringModifiers(GSEventRef event);
short GSEventGetCharacterSet(GSEventRef event);
GSEventFlags GSEventGetModifierFlags(GSEventRef event);
Boolean GSEventIsKeyRepeating(GSEventRef event);
UniChar GSEventIsKeyCharacterEventType(GSEventRef event, UniChar targetChar);
Boolean GSEventIsTabKeyEvent(GSEventRef event);
UniChar GSEventGetKeyCode(GSEventRef event);

GSEventRecord _GSEventGetGSEventRecord(GSEventRef event);



void GSEventRunModal(Boolean modal);
void GSEventRun();
void GSEventStopModal();
// Probably these should go into GSRunLoop or sth like that.
//   GSEventPushRunLoopMode();
//   GSEventPopRunLoopMode();
Boolean GSEventQueueContainsMouseEvent();

void GSEventRegisterEventCallBack(Boolean(*callback)(GSEventRef));	// TODO: ***signature not confirmed***


// TODO: ***signature not confirmed***
uint64_t GSCurrentEventTimestamp();
CFTimeInterval _GSEventConvertFromMachTime(uint64_t);
CFTimeInterval GSEventGetTimestamp(GSEventRef event);


// shouldn't these be in AudioServices?
// TODO: ***signatures not confirmed***
SystemSoundID _GSEventGetSoundActionID(CFStringRef filename);
SystemSoundID GSEventPrimeSoundAtPath(CFStringRef filename);	// call this instead of _GSEventGetSoundActionID to guard against NULL filename.
void _GSEventPlayAlertOrSystemSoundAtPath(CFStringRef filename, Boolean loop, Boolean alert);
void GSEventPlaySoundAtPath(CFStringRef filename);
void GSEventLoopSoundAtPath(CFStringRef filename);
void GSEventPlayAlertSoundAtPath(CFStringRef filename);
void GSEventStopSoundAtPath(Boolean unknown);	// this parameter is feed into AudioServicesStopSystemSound which Google returns 0 results.
void GSEventPlaySoundLoopAtPath(CFStringRef filename);

GSAccessoryKeyStateInfo GSEventGetAccessoryKeyStateInfo(GSEventRef event);

// Dunno what's that. Better not mess with it.
//   GSEventSendOutOfLineData();

Boolean GSEventIsForceQuitEvent(GSEventRef event);

void GSSendEvent(GSEventRecord* record, mach_port_t port);
void GSSendSystemEvent(GSEventRecord* record);
mach_port_t GSCopyPurpleSystemEventPort();
mach_port_t GSCopyPurpleApplicationPort();

void _GSSendApplicationLaunchStatusEvent(GSEventType eventType);
void GSEventFinishedLaunching();
void _GSEventApplicationStarted();
void GSEventInitialize();
void GSSendApplicationWantsToSuspendEvent(int unknown, const char*);
void GSSendApplicationWillSuspendEvent(int unknown, const char*);
// TODO: resolve signature:
//   void GSSendApplicationSuspendedSettingsUpdatedEvent(...);
//   void GSSendApplicationSuspendedEvent(...);
//   void GSSendAppPreferencesChanged(...);
//   void GSEventSendApplicationOpenURL(...);
void GSEventQuitTopApplication();

void GSEventRotateSimulator(int unknown);
void GSEventRestoreSensitivity();
void GSEventSetSensitivity(int sensitivity);
void GSEventHandBackTestResult(CFPropertyListRef plist);

void GSEventSetBacklightLevel(float level);
void GSEventSetBacklightFactor(int factor);
void GSEventVibrateForDuration(float secs);
void GSEventStopVibrator();


// _GSCreateSyntheticKeyEvent();
// _GSPostSyntheticKeyEvent();
void GSEventLockDevice();
// GSEventResetIdleDuration(1,2);

#endif