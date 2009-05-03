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

CFMessagePortCallBack serverCallback = NULL;


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

		// (1) Obtain the server port if necessary.
		if (serverCallback == NULL) {
			serverPort = CFMessagePortCreateRemote(NULL, CFSTR("hk.kennytm.GriP.server"));
			if (serverPort == NULL) {
				NSLog(@"-[GPDuplexClient init]: Cannot create server port. Is GriP running?");
				[self release];
				return nil;
			}
		}
			
		// (2) ask the server port for a unique ID.
		NSData* clientBundleID = [[[NSBundle mainBundle] bundleIdentifier] dataUsingEncoding:NSUTF8StringEncoding];
		NSData* pidData = [GPDuplexClient sendMessage:GPMessage_GetClientPortID data:clientBundleID expectsReturn:YES withServerPort:serverPort];
		if (pidData == nil) {
			NSLog(@"-[GPDuplexClient init]: Cannot obtain a unique client port ID from server.");
			[self release];
			return nil;
		}
		
		// (3) check if direct messaging is supported.
		clientPortName = [[NSString alloc] initWithData:(NSData*)pidData encoding:NSUTF8StringEncoding];
		if (serverCallback != NULL || [clientPortName rangeOfString:@".direct."].location != NSNotFound) {
			NSMutableData* clientFPtrData = [NSMutableData dataWithBytes:&GPClientCallback length:sizeof(CFMessagePortCallBack)];
			[clientFPtrData appendData:pidData];
			NSData* serverFPtrData = [GPDuplexClient sendMessage:GPMessage_ExchangeDirectMessagingFPtr data:clientFPtrData expectsReturn:(serverCallback == NULL) withServerPort:serverPort];
			
			if (serverCallback == NULL) {
				if (serverFPtrData == NULL) {
					NSLog(@"-[GPDuplexClient init]: Cannot establish direct messaging although such a possibility exists. Reverted back to CFMessagePort messaging.");
				} else {
					serverCallback = *(CFMessagePortCallBack*)[serverFPtrData bytes];
					return self;
				}
			} else
				return self;
		}
			
		// (4) Create client port from UID.
		CFMessagePortContext clientContext = {0, self, NULL, NULL, NULL};
		Boolean shouldFreeInfo = false;
		clientPort = CFMessagePortCreateLocal(NULL, (CFStringRef)clientPortName, &GPClientCallback, &clientContext, &shouldFreeInfo);
		if (shouldFreeInfo || clientPort == NULL) {
			NSLog(@"-[GPDuplexClient init]: Cannot create client port with port name %@.", clientPortName);
			[self release];
			return nil;
		}
			
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
	if (serverCallback != NULL)
		[GPDuplexClient sendMessage:GPMessage_UnsubscribeFromDirectMessaging data:[clientPortName dataUsingEncoding:NSUTF8StringEncoding] expectsReturn:NO withServerPort:nil];
	
	[clientPortName release];
	[observers release];
	[super dealloc];
}

@synthesize name=clientPortName;

+(NSData*)sendMessage:(SInt32)type data:(NSData*)data expectsReturn:(BOOL)expectsReturn withServerPort:(CFMessagePortRef)serverPort {
	NSData* retData = nil;
	CFStringRef mode = expectsReturn ? kCFRunLoopDefaultMode : NULL;
	CFDataRef* pRetData = expectsReturn ? (CFDataRef*)&retData : NULL;
	CFTimeInterval recvTimeout = expectsReturn ? 1 : 0;
	
	if (serverCallback != NULL) {
		retData = (NSData*)serverCallback(NULL, type, (CFDataRef)data, NULL);
	} else {
		SInt32 errorCode = CFMessagePortSendRequest(serverPort, type, (CFDataRef)data, 1, recvTimeout, mode, pRetData);
		if (errorCode != kCFMessagePortSuccess) {
			NSLog(@"-[GPDuplexClient sendMessage:data:expectsReturn:]: Cannot send data %@ of type %d to server. Returning nil. Error code = %d", data, type, errorCode);
			[retData release];
			retData = nil;
		}
	}
	
	return [retData autorelease];
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
	
	[observers setObject:observerSet forKey:typeNumber];
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
