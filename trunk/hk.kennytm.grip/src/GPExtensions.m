/*

GPExtensions.m ... Useful functions for Mobile Substrate Extensions on SpringBoard using GriP.
 
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

static void GPGriPIsReadyCallback(CFNotificationCenterRef center, void(*initializer)(), CFStringRef name, const void* object, CFDictionaryRef userInfo) {
	CFNotificationCenterRemoveEveryObserver(center, initializer);
	initializer();
}

extern void GPStartWhenGriPIsReady(void(*initializer)()) {
	CFMessagePortRef serverPort = CFMessagePortCreateRemote(NULL, CFSTR("hk.kennytm.GriP.server"));
	
	if (serverPort != NULL) {
		// GriP is already running. call the initializer directly.
		initializer();
		CFRelease(serverPort);
		
	} else {
		// GriP is not running. register for the notification and set the initializer as callback.
		CFNotificationCenterAddObserver(CFNotificationCenterGetLocalCenter(), initializer, &GPGriPIsReadyCallback, CFSTR("hk.kennytm.GriP.ready"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	}
}