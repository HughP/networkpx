/*

Client.m ... GriP Duplex Link Client.
 
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

#import <GriP/Duplex/Client.h>
#import <Foundation/Foundation.h>

typedef struct {
	id observer;
	SEL selector;
} GPObserver;

@interface GPDuplexClient ()
-(void)removeObserver:(id)observer selector:(SEL)selector forMessageNumber:(NSNumber*)msgNumber;
@property(readonly,retain) NSMutableDictionary* observers;
+(NSData*)sendMessage:(SInt32)type data:(NSData*)data expectsReturn:(BOOL)expectsReturn withServerPort:(CFMessagePortRef)serverPort;
@end

static CFDataRef GPClientCallback (CFMessagePortRef serverPort_, SInt32 type, CFDataRef data, void* info) {
	switch (type) {
		default: {
			NSSet* observerSet = [((GPDuplexClient*)info).observers objectForKey:[NSNumber numberWithInteger:type]];
			for (NSValue* observer in observerSet) {
				GPObserver obs;
				[observer getValue:&obs];
				[obs.observer performSelector:obs.selector withObject:(NSData*)data withObject:(id)type];
			}
			break;
		}
	}
	return NULL;
}

@implementation GPDuplexClient
@synthesize observers;
-(id)init {
	CFRunLoopRef runLoop = CFRunLoopGetCurrent();

	if ((self = [super init])) {
		observers = [[NSMutableDictionary alloc] init];
		
		// (1) Obtain the server port.
		serverPort = CFMessagePortCreateRemote(NULL, CFSTR("hk.kennytm.GriP.server"));
		if (serverPort == NULL) {
			NSLog(@"-[GPDuplexClient initWithCFRunLoop:]: Cannot create server port. Is GriP running?");
			[self release];
			return nil;
		}
		
		// (2) ask the server port for a unique ID.
		CFDataRef pidData = NULL;
		SInt32 errorCode = CFMessagePortSendRequest(serverPort, GPMessage_GetClientPortID, NULL, 1, 1, kCFRunLoopDefaultMode, &pidData);
		if (errorCode != kCFMessagePortSuccess || pidData == NULL) {
			NSLog(@"-[GPDuplexClient initWithCFRunLoop:]: Cannot obtain a unique client port ID from server. Error code = %d and pidData = %@.", errorCode, pidData);
			if (pidData != NULL)
				CFRelease(pidData);
			[self release];
			return nil;
		}
		
		// (3) Create client port from UID.
		const char* clientPortCString = (const char*)CFDataGetBytePtr(pidData);
		CFStringRef clientPortName = CFStringCreateWithCString(NULL, clientPortCString, kCFStringEncodingUTF8);
		CFMessagePortContext clientContext = {0, self, NULL, NULL, NULL};
		Boolean shouldFreeInfo = false;
		clientPort = CFMessagePortCreateLocal(NULL, clientPortName, &GPClientCallback, &clientContext, &shouldFreeInfo);
		if (shouldFreeInfo || clientPort == NULL) {
			NSLog(@"-[GPDuplexClient initWithCFRunLoop:]: Cannot create client port with port name %@.", clientPortName);
			CFRelease(clientPortName);
			CFRelease(pidData);
			[self release];
			return nil;
		}
		CFRelease(clientPortName);
		
		// (4) Add client port to run loop.
		clientSource = CFMessagePortCreateRunLoopSource(NULL, clientPort, 0);
		CFRunLoopAddSource(runLoop, clientSource, kCFRunLoopDefaultMode);
		
		// (5) Register client port to the server.
		//     (Currently not needed.)
		/*
		errorCode = CFMessagePortSendRequest(serverPort, GPMessage_RegisterClientPort, pidData, 1, 0, NULL, NULL);
		if (errorCode != kCFMessagePortSuccess)
			NSLog(@"-[GPDuplexClient initWithCFRunLoop:]: Cannot register client port to the server. You may need to release this duplix client. Error code = %d", errorCode);
		 */
		CFRelease(pidData);
	}
	return self;
}

-(void)dealloc {
	if (serverPort != NULL)
		CFRelease(serverPort);
	if (clientPort != NULL) {
		CFMessagePortInvalidate(clientPort);
		if (clientSource != NULL)
			CFRelease(clientSource);
		CFRelease(clientPort);
	}
	[observers release];
	[super dealloc];
}

@dynamic name;
-(NSString*)name { return (NSString*)CFMessagePortGetName(clientPort); }

+(NSData*)sendMessage:(SInt32)type data:(NSData*)data expectsReturn:(BOOL)expectsReturn withServerPort:(CFMessagePortRef)serverPort {
	if (expectsReturn) {
		NSData* retData = nil;
		SInt32 errorCode = CFMessagePortSendRequest(serverPort, type, (CFDataRef)data, 1, 1, kCFRunLoopDefaultMode, (CFDataRef*)&retData);
		if (errorCode != kCFMessagePortSuccess) {
			NSLog(@"-[GPDuplexClient sendMessage:data:expectsReturn:]: Cannot send data to server. Returning nil. Error code = %d", errorCode);
			[retData release];
			retData = nil;
		}
		return [retData autorelease];
	} else {
		SInt32 errorCode = CFMessagePortSendRequest(serverPort, type, (CFDataRef)data, 1, 0, NULL, NULL);
		if (errorCode != kCFMessagePortSuccess) {
			NSLog(@"-[GPDuplexClient sendMessage:data:expectsReturn:]: Cannot send data to server. Error code = %d", errorCode);
		}
		return nil;
	}
}


-(oneway void)sendMessage:(SInt32)type data:(NSData*)data { [self sendMessage:type data:data expectsReturn:NO]; }
+(oneway void)sendMessage:(SInt32)type data:(NSData*)data { [self sendMessage:type data:data expectsReturn:NO]; }
-(NSData*)sendMessage:(SInt32)type data:(NSData*)data expectsReturn:(BOOL)expectsReturn {
	return [[self class] sendMessage:type data:data expectsReturn:expectsReturn withServerPort:serverPort];
}
+(NSData*)sendMessage:(SInt32)type data:(NSData*)data expectsReturn:(BOOL)expectsReturn {
	CFMessagePortRef serverPort = CFMessagePortCreateRemote(NULL, CFSTR("hk.kennytm.GriP.server"));
	if (serverPort == NULL) {
		NSLog(@"+[GPDuplexClient sendMessage:data:expectsReturn:]: Cannot create server port. Is GriP running?");
		return nil;
	} else {
		NSData* retData = [self sendMessage:type data:data expectsReturn:expectsReturn withServerPort:serverPort];
		CFRelease(serverPort);
		return retData;
	}
}


// FIXME: Make these thread-safe / re-entrant.
-(void)addObserver:(id)observer selector:(SEL)selector forMessage:(SInt32)type {
	GPObserver obs = {observer, selector};
	NSNumber* typeNumber = [NSNumber numberWithInteger:type];
	NSValue* observerObject = [NSValue valueWithBytes:&obs objCType:@encode(GPObserver)];
	NSMutableSet* observerSet = [observers objectForKey:typeNumber];
	if (observerSet == nil)
		observerSet = [NSMutableSet setWithObject:observerObject];
	else
		[observerSet addObject:observerObject];
	@synchronized(observers) {
		[observers setObject:observerSet forKey:typeNumber];
	}
}
-(void)removeObserver:(id)observer selector:(SEL)selector {
	// use -allKeys to allow us to modify observers.
	for (NSNumber* typeNumber in [observers allKeys])
		[self removeObserver:observer selector:(SEL)selector forMessageNumber:typeNumber];
}
-(void)removeObserver:(id)observer selector:(SEL)selector forMessage:(SInt32)type {
	[self removeObserver:observer selector:selector forMessageNumber:[NSNumber numberWithInteger:type]];
}
-(void)removeObserver:(id)observer selector:(SEL)selector forMessageNumber:(NSNumber*)typeNumber {
	@synchronized(observers) {
		NSMutableSet* observerSet = [observers objectForKey:typeNumber];
		GPObserver obs = {observer, selector};
		[observerSet removeObject:[NSValue valueWithBytes:&obs objCType:@encode(GPObserver)]];
		if ([observerSet count] == 0)
			[observers removeObjectForKey:typeNumber];
		else
			[observers setObject:observerSet forKey:typeNumber];
	}
}
@end
