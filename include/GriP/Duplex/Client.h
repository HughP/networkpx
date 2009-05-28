/*

Client.h ... GriP Duplex Link Client (Objective-C wrapper).
 
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

#ifndef GRIP_DUPLEX_CLIENT_H
#define GRIP_DUPLEX_CLIENT_H

enum {
	GPMessage_GetClientPortID = 0,
	GPMessage_ExchangeDirectMessagingFPtr = 1,
	GPMessage_UnsubscribeFromDirectMessaging = 2,
};

#ifdef __OBJC__

#import <Foundation/NSObject.h>
#include <CoreFoundation/CFMessagePort.h>
#include <pthread.h>
@class NSMutableDictionary, NSData, NSString, NSIndexSet;

@interface GPDuplexClient : NSObject {
	CFMessagePortRef clientPort, serverPort;
	CFRunLoopSourceRef clientSource;
	NSMutableDictionary* observers;
	NSString* clientPortName;
}
-(id)init;
-(void)dealloc;
-(oneway void)sendMessage:(SInt32)type data:(NSData*)data;
-(NSData*)sendMessage:(SInt32)type data:(NSData*)data expectsReturn:(BOOL)expectsReturn;
+(oneway void)sendMessage:(SInt32)type data:(NSData*)data;
+(NSData*)sendMessage:(SInt32)type data:(NSData*)data expectsReturn:(BOOL)expectsReturn;
-(void)addObserver:(id)observer selector:(SEL)selector forMessages:(NSIndexSet*)messageSet;
-(void)removeObserver:(id)observer selector:(SEL)selector;
@property(readonly,retain) NSString* name;
@end

NSIndexSet* GPIndexSetCreateWithIndices(unsigned count, ...);

#endif

#endif