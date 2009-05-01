/*

Client.m ... GriP Duplex Link Client (Objective-C wrapper).
 
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

@implementation GPDuplexClient
-(id)init {
	if ((self = [super init])) {
		client = GPDuplexClient_Init();
		if (client == NULL) {
			[self release];
			return nil;
		}
	}
	return self;
}

-(void)dealloc {
	GPDuplexClient_Destroy(client);
	[super dealloc];
}

@dynamic name;
-(NSString*)name { return (NSString*)GPDuplexClient_GetName(client); }

-(oneway void)sendMessage:(SInt32)type data:(NSData*)data { GPDuplexClient_Send(client, type, (CFDataRef)data, false); }
+(oneway void)sendMessage:(SInt32)type data:(NSData*)data { GPDuplexClient_Send(NULL, type, (CFDataRef)data, false); }
-(NSData*)sendMessage:(SInt32)type data:(NSData*)data expectsReturn:(BOOL)expectsReturn { return (NSData*)GPDuplexClient_Send(client, type, (CFDataRef)data, true); }
+(NSData*)sendMessage:(SInt32)type data:(NSData*)data expectsReturn:(BOOL)expectsReturn { return (NSData*)GPDuplexClient_Send(NULL, type, (CFDataRef)data, false); }

-(void)addObserver:(id)observer selector:(SEL)selector forMessage:(SInt32)type {
	GPDuplexClient_AddObserver(client, observer, (GPDuplexClientCallback)[observer methodForSelector:selector], type);
}
-(void)removeObserver:(id)observer selector:(SEL)selector {
	GPDuplexClient_RemoveEveryObserver(client, observer, (GPDuplexClientCallback)[observer methodForSelector:selector]);
}
-(void)removeObserver:(id)observer selector:(SEL)selector forMessage:(SInt32)type {
	GPDuplexClient_RemoveObserver(client, observer, (GPDuplexClientCallback)[observer methodForSelector:selector], type);
}
@end
