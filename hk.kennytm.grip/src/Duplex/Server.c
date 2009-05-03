/*

Server.c ... GriP Duplex Link Server
 
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

#include <CoreFoundation/CoreFoundation.h>
#include <GriP/Duplex/Client.h>
#include <stdio.h>
#include <libkern/OSAtomic.h>

#define MaxStringLength (strlen("hk.kennytm.GriP.client.")+(sizeof(unsigned)*2))

static int clientPortID = 0;
static CFMessagePortRef serverPort = NULL;
static CFRunLoopSourceRef serverSource = NULL;
struct GPAlternativeHandler {
	CFMessagePortCallBack handler;
	SInt32 start;
	SInt32 end;
};
static CFMutableArrayRef alternateHandlers = NULL;
static CFMutableDictionaryRef directMessagingFPtrs = NULL;

// static Boolean CFStringEqual (CFStringRef a, CFStringRef b) { return CFStringCompare(a, b, 0) == kCFCompareEqualTo; }



extern CFDataRef GPServerCallback(CFMessagePortRef serverPort, SInt32 type, CFDataRef data, void* reserved2) {
	if (type == GPMessage_GetClientPortID) {
		int portID = OSAtomicIncrement32(&clientPortID);
		
		const char* formatString = "hk.kennytm.GriP.client.%x";
		
		// test if direct messaging is possible. if yes, favor direct messaging if avoiding clogging the tubes
		if (data != NULL) {
			// it is already a direct message.
			if (serverPort == NULL) {
				formatString = "hk.kennytm.GriP.direct.%x";
			} else {
				CFStringRef clientBundleIDString = CFStringCreateFromExternalRepresentation(NULL, data, kCFStringEncodingUTF8);
				CFStringRef serverBundleIDString = CFBundleGetIdentifier(CFBundleGetMainBundle());
				if (kCFCompareEqualTo == CFStringCompare(clientBundleIDString, serverBundleIDString, 0)) {
					formatString = "hk.kennytm.GriP.direct.%x";
				}
				CFRelease(clientBundleIDString);
			}
		}
		
		char clientName[MaxStringLength+1];
		memset(clientName, 0, MaxStringLength+1);
		int actualLength = snprintf(clientName, MaxStringLength, formatString, portID);
		return CFDataCreate(NULL, (const UInt8*)clientName, actualLength+1);
		
	} else if (type == GPMessage_ExchangeDirectMessagingFPtr) {
		
		const char* clientPortID = (const char*)CFDataGetBytePtr(data);
		CFMessagePortCallBack clientFPtr = *(CFMessagePortCallBack*)clientPortID;
		clientPortID += sizeof(CFMessagePortCallBack);
		CFStringRef clientPortIDString = CFStringCreateWithCString(NULL, clientPortID, kCFStringEncodingUTF8);
		CFDictionarySetValue(directMessagingFPtrs, clientPortIDString, clientFPtr);
		CFRelease(clientPortIDString);
		
		const void* callbackPointer = &GPServerCallback;
		return CFDataCreate(NULL, (const UInt8*)&callbackPointer, sizeof(CFMessagePortCallBack));
		
	} else if (type == GPMessage_UnsubscribeFromDirectMessaging) {
		
		// Note: this function will cause the string to include the NULL terminator as well. :[
		//   CFStringRef clientPortID = CFStringCreateFromExternalRepresentation(NULL, data, kCFStringEncodingUTF8);
		
		CFStringRef clientPortID = CFStringCreateWithCString(NULL, (const char*)CFDataGetBytePtr(data), kCFStringEncodingUTF8);
		CFDictionaryRemoveValue(directMessagingFPtrs, clientPortID);
		CFRelease(clientPortID);
		
	} else {
		for (int i = CFArrayGetCount(alternateHandlers)-1; i >= 0; -- i) {
			struct GPAlternativeHandler* altHandler = (struct GPAlternativeHandler*)CFDataGetBytePtr( (CFDataRef)CFArrayGetValueAtIndex(alternateHandlers, i) );
			if (type >= altHandler->start && type <= altHandler->end)
				return (altHandler->handler)(serverPort, type, data, reserved2);
		}
	}
	return NULL;
}

#pragma mark -

int GPStartServer() {
	// clientPorts = CFSetCreateMutable(NULL, 0, &kCFTypeSetCallBacks);
	alternateHandlers = CFArrayCreateMutable(NULL, 0, &kCFTypeArrayCallBacks);
	directMessagingFPtrs = CFDictionaryCreateMutable(NULL, 0, &kCFCopyStringDictionaryKeyCallBacks, NULL);
	
	// (1) Create server port.
	CFMessagePortRef serverPort = CFMessagePortCreateLocal(NULL, CFSTR("hk.kennytm.GriP.server"), &GPServerCallback, NULL, NULL);
	if (serverPort == NULL) {
		CFShow(CFSTR("GPStartServer: Cannot create server port. Is GriP already running?"));
		return -1;
	}
	
	// (2) Create source from port and add to run loop.
	serverSource = CFMessagePortCreateRunLoopSource(NULL, serverPort, 0);
	CFRunLoopAddSource(CFRunLoopGetCurrent(), serverSource, kCFRunLoopDefaultMode);
	
	return 0;
}

void GPStopServer() {
	if (serverPort != NULL) {
		CFMessagePortInvalidate(serverPort);
		if (serverSource != NULL)
			CFRelease(serverSource);
		CFRelease(serverPort);
	}
	if (alternateHandlers != NULL)
		CFRelease(alternateHandlers);
	if (directMessagingFPtrs != NULL)
		CFRelease(directMessagingFPtrs);
}

void GPSetAlternateHandler(CFMessagePortCallBack handler, SInt32 startMessage, SInt32 endMessage) {
	struct GPAlternativeHandler handlerStruct = {handler, startMessage, endMessage};
	CFDataRef handlerData = CFDataCreate(NULL, (const UInt8*)&handlerStruct, sizeof(struct GPAlternativeHandler));
	CFArrayAppendValue(alternateHandlers, handlerData);
	CFRelease(handlerData);
}

Boolean GPServerForwardMessage(CFStringRef clientPortID, SInt32 type, CFDataRef data) {
	CFMessagePortCallBack clientFPtr = (CFMessagePortCallBack)CFDictionaryGetValue(directMessagingFPtrs, clientPortID);
	if (clientFPtr != NULL) {
		clientFPtr(NULL, type, data, NULL);
		return true;
	} else {
		CFMessagePortRef clientPort = CFMessagePortCreateRemote(NULL, clientPortID);
		if (clientPort != NULL) {
			CFMessagePortSendRequest(clientPort, type, data, 1, 0, NULL, NULL);
			CFRelease(clientPort);
			return true;
		} else
			return false;
	}
}