/*

ClientC.c ... GriP Duplex Link Client
 
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

#include <GriP/Duplex/ClientC.h>
#include <GriP/common.h>
#include <GriP/CFExtensions.h>

struct GPDuplexClient2 {
	unsigned refcount;
	CFMessagePortRef clientPort, serverPort;
	CFRunLoopSourceRef clientSource;
	CFMutableDictionaryRef observers;
};

struct GPDataAndType {
	CFDataRef data;
	SInt32 type;
};

static inline void GPDuplexClientExtractObserver(CFDataRef observerData, void** observer, GPDuplexClientCallback* callback) {
	const UInt8* observerPointer = CFDataGetBytePtr(observerData);
	*observer = *(void**)observerPointer;
	*callback = *(GPDuplexClientCallback*)(observerPointer+sizeof(void*));
}
static inline CFDataRef GPDuplexClientCreateObserver(void* observer, GPDuplexClientCallback callback) {
	struct { void* a; GPDuplexClientCallback b; } bytes = {observer, callback};
	return CFDataCreate(NULL, (const UInt8*)&bytes, sizeof(void*)+sizeof(GPDuplexClientCallback));
}

static void GPDuplexClientInformObserver (CFDataRef observerData, const struct GPDataAndType* dataAndType) {
	void* observer;
	GPDuplexClientCallback callback;
	GPDuplexClientExtractObserver(observerData, &observer, &callback);
	callback(observer, NULL, dataAndType->data, dataAndType->type);
}

static CFDataRef GPClientCallback (CFMessagePortRef serverPort_, SInt32 type, CFDataRef data, void* info) {
	switch (type) {
		default: {
			CFNumberRef typeNumber = CFNumberCreate(NULL, kCFNumberSInt32Type, &type);
			CFSetRef observerSet = CFDictionaryGetValue(((GPDuplexClientRef)info)->observers, typeNumber);
			CFRelease(typeNumber);
			
			struct GPDataAndType dataAndType = {data, type};
			CFSetApplyFunction(observerSet, (CFSetApplierFunction)&GPDuplexClientInformObserver, &dataAndType);
			
			break;
		}
	}
	return NULL;
}

extern GPDuplexClientRef GPDuplexClient_Create() {
	CFRunLoopRef runLoop = CFRunLoopGetCurrent();
	GPDuplexClientRef client = calloc(1, sizeof(GPDuplexClientRef));
	client->refcount = 1;
	client->observers = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
	
	// (1) Obtain the server port.
	client->serverPort = CFMessagePortCreateRemote(NULL, CFSTR("hk.kennytm.GriP.server"));
	if (client->serverPort == NULL) {
		CFShow(CFSTR("GPDuplexClient_Init(): Cannot create server port. Is GriP running?"));
		GPDuplexClient_Release(client);
		return NULL;
	}
	
	// (2) ask the server port for a unique ID.
	CFDataRef pidData = NULL;
	SInt32 errorCode = CFMessagePortSendRequest(client->serverPort, GPMessage_GetClientPortID, NULL, 1, 1, kCFRunLoopDefaultMode, &pidData);
	if (errorCode != kCFMessagePortSuccess || pidData == NULL) {
		CFLog(4, CFSTR("GPDuplexClient_Init(): Cannot obtain a unique client port ID from server. Error code = %d and pidData = %@."), errorCode, pidData);
		if (pidData != NULL)
			CFRelease(pidData);
		GPDuplexClient_Release(client);
		return NULL;
	}
	
	// (3) Create client port from UID.
	const char* clientPortCString = (const char*)CFDataGetBytePtr(pidData);
	CFStringRef clientPortName = CFStringCreateWithCString(NULL, clientPortCString, kCFStringEncodingUTF8);
	CFMessagePortContext clientContext = {0, client, NULL, NULL, NULL};
	Boolean shouldFreeInfo = false;
	client->clientPort = CFMessagePortCreateLocal(NULL, clientPortName, &GPClientCallback, &clientContext, &shouldFreeInfo);
	if (shouldFreeInfo || client->clientPort == NULL) {
		CFLog(4, CFSTR("GPDuplexClient_Init(): Cannot create client port with port name %@."), clientPortName);
		CFRelease(clientPortName);
		CFRelease(pidData);
		GPDuplexClient_Release(client);
		return NULL;
	}
	CFRelease(clientPortName);
	
	// (4) Add client port to run loop.
	client->clientSource = CFMessagePortCreateRunLoopSource(NULL, client->clientPort, 0);
	CFRunLoopAddSource(runLoop, client->clientSource, kCFRunLoopDefaultMode);
	
	CFRelease(pidData);
	
	CFLog(4, CFSTR("create client = %@"), client->clientPort);
	
	return client;
}

extern void GPDuplexClient_Release(GPDuplexClientRef client) {
	if (client != NULL) {
		CFLog(4, CFSTR("release client = %@"), client->clientPort);
		if (--(client->refcount) != 0)
		 	return;
		
		if (client->serverPort != NULL)
			CFRelease(client->serverPort);
		if (client->clientPort != NULL) {
			CFMessagePortInvalidate(client->clientPort);
			if (client->clientSource != NULL)
				CFRelease(client->clientSource);
			CFRelease(client->clientPort);
		}
		CFRelease(client->observers);
		free(client);
	}
}

extern GPDuplexClientRef GPDuplexClient_Retain(GPDuplexClientRef client) {
	if (client != NULL)
		++(client->refcount);
	return client;
}

extern CFStringRef GPDuplexClient_GetName(GPDuplexClientRef client) { return CFMessagePortGetName(client->clientPort); }

extern CFDataRef GPDuplexClient_Send(GPDuplexClientRef client, SInt32 type, CFDataRef data, Boolean expectsReturn) {
	CFMessagePortRef serverPort;
	if (client != NULL)
		serverPort = client->serverPort;
	else {
		serverPort = CFMessagePortCreateRemote(NULL, CFSTR("hk.kennytm.GriP.server"));
		if (serverPort == NULL) {
			CFShow(CFSTR("GPDuplexClient_Send(): Cannot create server port. Is GriP running?"));
			return NULL;
		}
	}
	
	if (expectsReturn) {
		CFDataRef retData = NULL;
		SInt32 errorCode = CFMessagePortSendRequest(serverPort, type, data, 4, 1, kCFRunLoopDefaultMode, &retData);
		if (client == NULL)
			CFRelease(serverPort);
		if (errorCode != kCFMessagePortSuccess) {
			CFLog(4, CFSTR("GPDuplexClient_Send(): Cannot send data %@ of type %d to server. Returning NULL. Error code = %d"), data, type, errorCode);
			if (retData != NULL) {
				CFRelease(retData);
				retData = NULL;
			}
		}
		return retData;
	} else {
		SInt32 errorCode = CFMessagePortSendRequest(serverPort, type, data, 4, 0, NULL, NULL);
		if (client == NULL)
			CFRelease(serverPort);
		if (errorCode != kCFMessagePortSuccess) {
			CFLog(4, CFSTR("GPDuplexClient_Send(): Cannot send data %@ of type %d to server. Error code = %d"), data, type, errorCode);
		}
		return NULL;
	}
}

// FIXME: Make these thread-safe / re-entrant.
extern void GPDuplexClient_AddObserver(GPDuplexClientRef client, void* observer, GPDuplexClientCallback callback, SInt32 type) {
	if (client != NULL) {
		CFNumberRef typeNumber = CFNumberCreate(NULL, kCFNumberSInt32Type, &type);
		CFMutableSetRef observerSet = (CFMutableSetRef)CFDictionaryGetValue(client->observers, typeNumber);
		Boolean needRelease = false;
		if (observerSet == NULL) {
			needRelease = true;
			observerSet = CFSetCreateMutable(NULL, 0, &kCFTypeSetCallBacks);
		}
		
		CFDataRef observerData = GPDuplexClientCreateObserver(observer, callback);
		CFSetAddValue(observerSet, observerData);
		CFRelease(observerData);
		
		CFDictionarySetValue(client->observers, typeNumber, observerSet);
		if (needRelease)
			CFRelease(observerSet);
		
		CFRelease(typeNumber);
	}
}

static void GPDuplexClient_RemoveObserverWithNumberAndObserverSet(GPDuplexClientRef client, void* observer, GPDuplexClientCallback callback, CFNumberRef typeNumber, CFMutableSetRef observerSet) {
	CFDataRef observerData = GPDuplexClientCreateObserver(observer, callback);
	CFSetRemoveValue(observerSet, observerData);
	if (CFSetGetCount(observerSet) == 0)
		CFDictionaryRemoveValue(client->observers, typeNumber);
}

extern void GPDuplexClient_RemoveEveryObserver(GPDuplexClientRef client, void* observer, GPDuplexClientCallback callback) {
	if (client != NULL) {
		CFIndex count = CFDictionaryGetCount(client->observers);
		CFNumberRef* typeNumbers = malloc(count * sizeof(CFNumberRef));
		CFMutableSetRef* observerSets = malloc(count * sizeof(CFMutableSetRef));
		CFDictionaryGetKeysAndValues(client->observers, (const void**)typeNumbers, (const void**)observerSets);
		
		for (CFIndex i = 0; i < count; ++ i)
			GPDuplexClient_RemoveObserverWithNumberAndObserverSet(client, observer, callback, typeNumbers[i], observerSets[i]);
		
		free(typeNumbers);
		free(observerSets);
	}
}

extern void GPDuplexClient_RemoveObserver(GPDuplexClientRef client, void* observer, GPDuplexClientCallback callback, SInt32 type) {
	if (client != NULL) {
		CFNumberRef typeNumber = CFNumberCreate(NULL, kCFNumberSInt32Type, &type);
		GPDuplexClient_RemoveObserverWithNumberAndObserverSet(client, observer, callback, typeNumber, (CFMutableSetRef)CFDictionaryGetValue(client->observers, typeNumber));
		CFRelease(typeNumber);
	}
}
