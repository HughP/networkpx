/*

GPRawThemeHelper.m ... Helper class for raw themes.
 
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

#import <GriP/GPRawThemeHelper.h>
#import <Foundation/Foundation.h>
#include <libkern/OSAtomic.h>
#import <GriP/common.h>
#import <GriP/Duplex/Client.h>

@implementation GPRawThemeHelper
-(id)init {
	if ((self = [super init]))
		registeredMessages = CFDictionaryCreateMutable(NULL, 0, NULL, &kCFTypeDictionaryValueCallBacks);
	return self;
}
-(void)dealloc {
	CFRelease(registeredMessages);
	[super dealloc];
}
-(int)registerMessage:(NSDictionary*)message {
	int myUID = OSAtomicIncrement32(&uid);
	CFDictionarySetValue(registeredMessages, (const void*)myUID, [NSPropertyListSerialization dataFromPropertyList:[message objectsForKeys:[NSArray arrayWithObjects:GRIP_PID, GRIP_CONTEXT, GRIP_ISURL, GRIP_MSGUID, nil]
																															notFoundMarker:@""]
																											format:NSPropertyListBinaryFormat_v1_0
																								  errorDescription:NULL]);
	return myUID;
}
-(void)dismissedMessageID:(int)msgid forAction:(SInt32)action {
	if (msgid == -1)
		return;
	NSData* dataToSend = (NSData*)CFDictionaryGetValue(registeredMessages, (const void*)msgid);
	[GPDuplexClient sendMessage:action data:dataToSend];
	CFDictionaryRemoveValue(registeredMessages, (const void*)msgid);
}
-(void)touchedMessageID:(int)msgid { [self dismissedMessageID:msgid forAction:GriPMessage_ClickedNotification]; }
-(void)ignoredMessageID:(int)msgid { [self dismissedMessageID:msgid forAction:GriPMessage_IgnoredNotification]; }
@end
