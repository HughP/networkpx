/*

GPApplicationBridge.h ... GriP Application Bridge
 
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

#ifndef GRIP_GPAPPLICATIONBRIDGEC_H
#define GRIP_GPAPPLICATIONBRIDGEC_H

#ifdef __cplusplus
extern "C" {
#endif
	
#include <stdlib.h>
#include <CoreFoundation/CoreFoundation.h>

	typedef struct GPApplicationBridge2* GPApplicationBridgeRef;
	
	typedef struct GPApplicationBridgeCDelegate {
		CFTypeRef object;
		CFDictionaryRef (*registrationDictionary)(CFTypeRef object);
		CFStringRef (*applicationName)(CFTypeRef object);
		void (*ready)(CFTypeRef object);
		void (*touched)(CFTypeRef object, void* unused, CFPropertyListRef clickContext);
		void (*ignored)(CFTypeRef object, void* unused, CFPropertyListRef clickContext);
	} GPApplicationBridgeCDelegate;
	
#define kGPApplicationBridge_EmptyDelegate (GPApplicationBridgeCDelegate){NULL, NULL, NULL, NULL, NULL, NULL}
	
	GPApplicationBridgeRef GPApplicationBridge_Create();
	GPApplicationBridgeRef GPApplicationBridge_Retain(GPApplicationBridgeRef bridge);
	void GPApplicationBridge_Release(GPApplicationBridgeRef bridge);
	
	// backward compatibility.
#define GPApplicationBridge_Init GPApplicationBridge_Create
#define GPApplicationBridge_Destroy GPApplicationBridge_Release
	
	void GPApplicationBridge_SetDelegate(GPApplicationBridgeRef bridge, GPApplicationBridgeCDelegate delegate);
	GPApplicationBridgeCDelegate GPApplicationBridge_GetDelegate(GPApplicationBridgeRef bridge);
	
	void GPApplicationBridge_SendMessage(GPApplicationBridgeRef bridge, CFStringRef title, CFStringRef description, CFStringRef name,
										 CFTypeRef iconData, signed priority, Boolean isSticky, CFPropertyListRef clickContext, CFStringRef identifier);
	
	Boolean GPApplicationBridge_Register(GPApplicationBridgeRef bridge, CFDictionaryRef potentialDictionary);
	
	Boolean GPApplicationBridge_CheckInstalled(GPApplicationBridgeRef bridge);
	Boolean GPApplicationBridge_CheckRunning(GPApplicationBridgeRef bridge);
	
	Boolean GPApplicationBridge_CheckEnabled(GPApplicationBridgeRef bridge, CFStringRef name);

#ifdef __cplusplus
}
#endif
#endif