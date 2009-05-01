/*

GPApplicationBridgeC.m ... GriP Application Bridge
 
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

#include <GriP/GPApplicationBridgeC.h>
#include <GriP/Duplex/ClientC.h>
#include <GriP/common.h>
#include <GriP/CFPropertyListCreateBinaryData.h>
#include <GriP/GrowlDefines.h>

#define IS(obj, type) ((obj) != NULL && CFGetTypeID(obj) == CF##type##GetTypeID())
#define SET(obj, key) CFDictionarySetValue(filteredDictionary, GRIP_##key, (obj))

struct GPApplicationBridge2 {
	struct GPApplicationBridgeCDelegate sharedDelegate;
	CFDictionaryRef cachedRegistrationDictionary;
	CFStringRef appName;
	GPDuplexClientRef duplex;
};

static void GPABMessageClickedOrIgnored(GPApplicationBridgeRef bridge, void* usused, CFDataRef contextData, SInt32 type) {
	if (bridge != NULL) {
		CFTypeRef context = CFPropertyListCreateFromXMLData(NULL, contextData, kCFPropertyListImmutable, NULL);
		if (context != NULL) {
			if (type == GriPMessage_ClickedNotification) {
				if (bridge->sharedDelegate.touched != NULL)
					bridge->sharedDelegate.touched(bridge->sharedDelegate.object, NULL, context);
			} else {
				if (bridge->sharedDelegate.ignored != NULL)
					bridge->sharedDelegate.ignored(bridge->sharedDelegate.object, NULL, context);
			}
			CFRelease(context);
		}
	}
}


extern void GPApplicationBridge_Destroy(GPApplicationBridgeRef bridge) {
	if (bridge != NULL) {
		if (bridge->sharedDelegate.object != NULL)
			CFRelease(bridge->sharedDelegate.object);
		if (bridge->cachedRegistrationDictionary != NULL)
			CFRelease(bridge->cachedRegistrationDictionary);
		if (bridge->appName != NULL)
			CFRelease(bridge->appName);
		GPDuplexClient_Destroy(bridge->duplex);
		free(bridge);
	}
}

extern GPApplicationBridgeRef GPApplicationBridge_Init() {
	GPApplicationBridgeRef bridge = calloc(1, sizeof(struct GPApplicationBridge2));
	
	bridge->duplex = GPDuplexClient_Init();
	if (bridge->duplex != NULL) {
		GPDuplexClient_AddObserver(bridge->duplex, bridge, (GPDuplexClientCallback)&GPABMessageClickedOrIgnored, GriPMessage_ClickedNotification);
		GPDuplexClient_AddObserver(bridge->duplex, bridge, (GPDuplexClientCallback)&GPABMessageClickedOrIgnored, GriPMessage_IgnoredNotification);
	}
	
	CFBundleRef mainBundle = CFBundleGetMainBundle();
	bridge->appName = CFBundleGetValueForInfoDictionaryKey(mainBundle, kCFBundleExecutableKey);
	if (bridge->appName == NULL) {
		CFURLRef bundleURL = CFBundleCopyBundleURL(mainBundle);
		CFStringRef lastPathComponent = CFURLCopyLastPathComponent(bundleURL);
		CFRelease(bundleURL);
		CFRange theDot = CFStringFind(lastPathComponent, CFSTR("."), kCFCompareBackwards);
		if (theDot.location != kCFNotFound) {
			bridge->appName = CFStringCreateWithSubstring(NULL, lastPathComponent, CFRangeMake(0, theDot.location));
			CFRelease(lastPathComponent);
		} else
			bridge->appName = lastPathComponent;
	} else {
		if (CFGetTypeID(bridge->appName) == CFStringGetTypeID())
			CFRetain(bridge->appName);
		else
			bridge->appName = NULL;
	}
	
	CFURLRef regDictPath = CFBundleCopyResourceURL(mainBundle, CFSTR("Growl Registration Ticket"), CFSTR("growlRegDict"), NULL);
	if (regDictPath != NULL) {
		CFReadStreamRef stream = CFReadStreamCreateWithFile(NULL, regDictPath);
		CFRelease(regDictPath);
		if (CFReadStreamOpen(stream)) {
			CFPropertyListRef dict = CFPropertyListCreateFromStream(NULL, stream, 0, kCFPropertyListImmutable, NULL, NULL);
			CFReadStreamClose(stream);
			GPApplicationBridge_Register(bridge, dict);
			CFRelease(dict);
		}																	
		CFRelease(stream);
	}
	
	return bridge;
}

// FIXME: Find some SDK-compatible check to give an accurate result.
extern Boolean GPApplicationBridge_CheckInstalled(GPApplicationBridgeRef bridge) { return GPApplicationBridge_CheckRunning(bridge); }

// FIXME: Currently this check relies on the fact that only GriP has implemented the GPDuplexClient class.
//        what if other people are start using it? Then this method is no longer useful.
extern Boolean GPApplicationBridge_CheckRunning(GPApplicationBridgeRef bridge) {
	return bridge != NULL && bridge->duplex != NULL;
}

GPApplicationBridgeCDelegate GPApplicationBridge_GetDelegate(GPApplicationBridgeRef bridge) {
	if (bridge != NULL)
		return bridge->sharedDelegate;
	else
		return kGPApplicationBridge_EmptyDelegate;
}

void GPApplicationBridge_SetDelegate(GPApplicationBridgeRef bridge, GPApplicationBridgeCDelegate delegate) {
	if (!GPApplicationBridge_CheckRunning(bridge))
		return;
	
	if (bridge->sharedDelegate.object != delegate.object) {
		if (bridge->sharedDelegate.object != NULL)
			CFRelease(bridge->sharedDelegate.object);
		CFRetain(delegate.object);
	}
	bridge->sharedDelegate = delegate;
	
	// try to replace app name.
	if (delegate.applicationName != NULL) {
		CFStringRef potentialAppName = delegate.applicationName(delegate.object);
		if (IS(potentialAppName, String)) {
			if (bridge->appName != NULL)
				CFRelease(bridge->appName);
			bridge->appName = CFRetain(potentialAppName);
		}
	}
	
	// try to replace the reg dict.
	if (delegate.registrationDictionary != NULL)
		GPApplicationBridge_Register(bridge, delegate.registrationDictionary(delegate.object));
	
	// we don't care about the app icon.
	
	// tell the delegate we're ready.
	if (delegate.ready != NULL)	
		delegate.ready(delegate.object);
}

void GPApplicationBridge_SendMessage(GPApplicationBridgeRef bridge, CFStringRef title, CFStringRef description, CFStringRef name,
									 CFTypeRef iconData, signed priority, Boolean isSticky, CFPropertyListRef clickContext, CFStringRef identifier) {
	if (bridge == NULL || bridge->duplex == NULL || bridge->appName == NULL)
		return;
	
	CFMutableDictionaryRef filteredDictionary = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
		
	SET(GPDuplexClient_GetName(bridge->duplex), PID);
	SET(bridge->appName, APPNAME);
	
	if (IS(title, String))       SET(title, TITLE);
	if (IS(description, String)) SET(description, DETAIL);
	if (IS(name, String))        SET(name, NAME);
	if (IS(iconData, String) ||
		IS(iconData, Data))      SET(iconData, ICON);
	
	if (priority < -2) priority = -2;
	else if (priority > 2) priority = 2;
	CFNumberRef priorityNumber = CFNumberCreate(NULL, kCFNumberSInt32Type, &priority);
	SET(priorityNumber, PRIORITY);
	CFRelease(priorityNumber);
	SET(isSticky ? kCFBooleanTrue : kCFBooleanFalse, STICKY);
	
	if (IS(clickContext, URL)) {
		SET(CFURLGetString(clickContext), CONTEXT);
		SET(kCFBooleanTrue, ISURL);
	} else if (CFPropertyListIsValid(clickContext, kCFPropertyListBinaryFormat_v1_0))
		SET(clickContext, CONTEXT);
	else
		fprintf(stderr, "clickContext is not a property list object. It will be ignored.");
	
	if (IS(identifier, String))  SET(identifier, ID);
	
	CFDataRef dataToSend = CFPropertyListCreateBinaryData(filteredDictionary);
	CFRelease(filteredDictionary);
	if (dataToSend != NULL) {
		GPDuplexClient_Send(bridge->duplex, GriPMessage_ShowMessage, dataToSend, false);
		CFRelease(dataToSend);
	}
}

Boolean GPApplicationBridge_Register(GPApplicationBridgeRef bridge, CFDictionaryRef potentialDictionary) {
	if (IS(potentialDictionary, Dictionary)) {
		if (!IS(CFDictionaryGetValue(potentialDictionary, GROWL_NOTIFICATIONS_ALL),     Array))      return false;
		if (!IS(CFDictionaryGetValue(potentialDictionary, GROWL_NOTIFICATIONS_DEFAULT), Array))      return false;
		CFDictionaryRef tmp = CFDictionaryGetValue(potentialDictionary, GROWL_NOTIFICATIONS_HUMAN_READABLE_NAMES);
		if (!(tmp == NULL || CFGetTypeID(tmp) == CFDictionaryGetTypeID())) return false;
		tmp = CFDictionaryGetValue(potentialDictionary, GROWL_NOTIFICATIONS_DESCRIPTIONS);
		if (!(tmp == NULL || CFGetTypeID(tmp) == CFDictionaryGetTypeID())) return false;
		
		CFStringRef newAppName = CFDictionaryGetValue(potentialDictionary, GROWL_APP_NAME);
		if (newAppName != NULL && bridge->appName != newAppName) {
			if (CFGetTypeID(newAppName) == CFStringGetTypeID()) {
				if (bridge->appName != NULL)
					CFRelease(bridge->appName);
				bridge->appName = CFRetain(newAppName);
			} else
				return false;
		}
		
		CFTypeRef updateRawArray[2] = {bridge->appName, potentialDictionary};
		CFArrayRef updateArray = CFArrayCreate(NULL, updateRawArray, 2, &kCFTypeArrayCallBacks);
		CFDataRef updateData = CFPropertyListCreateBinaryData(updateArray);
		CFRelease(updateArray);
		if (updateData == NULL)
			return false;
		
		if (bridge->cachedRegistrationDictionary != NULL)
			CFRelease(bridge->cachedRegistrationDictionary);
		bridge->cachedRegistrationDictionary = CFRetain(potentialDictionary);
		GPDuplexClient_Send(bridge->duplex, GriPMessage_UpdateTicket, updateData, false);
		CFRelease(updateData);
		
		return true;
	} else
		return false;
}

Boolean GPApplicationBridge_CheckEnabled(GPApplicationBridgeRef bridge, CFStringRef name) {
	if (bridge != NULL && bridge->appName != NULL) {
		CFTypeRef rawArrayToSend[2];
		rawArrayToSend[0] = bridge->appName;
		rawArrayToSend[1] = name;
		CFArrayRef arrayToSend = CFArrayCreate(NULL, rawArrayToSend, (name == NULL) ? 1 : 2, &kCFTypeArrayCallBacks);
		CFDataRef dataToSend = CFPropertyListCreateBinaryData(arrayToSend);
		CFRelease(arrayToSend);
		CFDataRef dataReceived = GPDuplexClient_Send(bridge->duplex, GriPMessage_CheckEnabled, dataToSend, true);
		CFRelease(dataToSend);
		Boolean retval = false;
		if (dataReceived != NULL) 
			retval = *(Boolean*)CFDataGetBytePtr(dataReceived);
		CFRelease(dataReceived);
		return retval;
	} else
		return false;
}