/*

ClientC.h ... GriP Duplex Link Client
 
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

#ifndef GRIP_DUPLEX_CLIENTC_H
#define GRIP_DUPLEX_CLIENTC_H
#include <CoreFoundation/CoreFoundation.h>

#ifdef __cplusplus
extern "C" {
#endif
	
	enum {
		GPMessage_GetClientPortID = 0
	};
	
	typedef void(*GPDuplexClientCallback)(void* object, void* unused, CFDataRef data, SInt32 type);
	typedef struct GPDuplexClient2* GPDuplexClientRef;
	
	GPDuplexClientRef GPDuplexClient_Init();
	void GPDuplexClient_Destroy(GPDuplexClientRef client);
	
	CFStringRef GPDuplexClient_GetName(GPDuplexClientRef client);
	CFDataRef GPDuplexClient_Send(GPDuplexClientRef client, SInt32 type, CFDataRef data, Boolean expectsReturn);
	void GPDuplexClient_AddObserver(GPDuplexClientRef client, void* observer, GPDuplexClientCallback callback, SInt32 type);
	void GPDuplexClient_RemoveObserver(GPDuplexClientRef client, void* observer, GPDuplexClientCallback callback, SInt32 type);
	void GPDuplexClient_RemoveEveryObserver(GPDuplexClientRef client, void* observer, GPDuplexClientCallback callback);
	
#ifdef __cplusplus
}
#endif
#endif