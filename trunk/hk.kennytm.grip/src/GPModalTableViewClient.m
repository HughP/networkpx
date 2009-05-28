/*

FILE_NAME ... DESCRIPTION
 
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

#import <GriP/GPModalTableViewClient.h>
#import <GriP/GPApplicationBridge.h>
#import <Foundation/Foundation.h>
#import <GriP/Duplex/Client.h>
#import <GriP/common.h>

@interface GPApplicationBridge (GetDuplex)
@property(readonly,assign,nonatomic) GPDuplexClient* duplex;
@property(readonly,assign,nonatomic) NSString* appName;
@end
@implementation GPApplicationBridge (GetDuplex)
-(GPDuplexClient*)duplex { return duplex; }
-(NSString*)appName { return appName; }
@end


@implementation GPModalTableViewClient
-(void)received:(NSData*)data type:(SInt32)type {
	if (uid == -1)
		return;
	NSArray* arr = [NSPropertyListSerialization propertyListFromData:data mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:NULL];
	if ([arr isKindOfClass:[NSArray class]] && [arr count] <= 3) {
		NSNumber* decodedArr[] = {nil, nil, nil};
		[arr getObjects:decodedArr];
		if (uid == [decodedArr[0] integerValue]) {
			SEL delegateMethods[] = {
				@selector(modalTableView:clickedButton:),
				@selector(modalTableView:movedItem:below:),
				@selector(modalTableView:deletedItem:),
				@selector(modalTableView:selectedItem:),
				@selector(modalTableViewDismissed:),
				@selector(modalTableView:tappedAccessoryButtonInItem:),
				@selector(modalTableView:changedDescription:forItem:)
			};
			if ([delegate respondsToSelector:delegateMethods[type-GPTVAMessage_ButtonClicked]])
				objc_msgSend(delegate, delegateMethods[type-GPTVAMessage_ButtonClicked], self, decodedArr[1], decodedArr[2]);
		}
	}
}

@synthesize delegate, context;
-(id)initWithDictionary:(NSDictionary*)dictionary applicationBridge:(GPApplicationBridge*)bridge name:(NSString*)name {
	if (name == nil || ![bridge enabledForName:name])
		return nil;
	
	if ((self = [super init])) {
		duplex = [bridge.duplex retain];
		
		NSData* uidData = [duplex sendMessage:GPTVAMessage_Show
										 data:[NSPropertyListSerialization dataFromPropertyList:[NSArray arrayWithObjects:duplex.name, dictionary, bridge.appName, name, nil]
																						 format:NSPropertyListBinaryFormat_v1_0
																			   errorDescription:NULL]
								expectsReturn:YES];
		if (uidData == nil) {
			[self release];
			return nil;
		}
		
		NSIndexSet* messages = GPIndexSetCreateWithIndices(7,
														   GPTVAMessage_ButtonClicked,
														   GPTVAMessage_MovedItem,
														   GPTVAMessage_Deleted,
														   GPTVAMessage_Selected,
														   GPTVAMessage_Dismiss,
														   GPTVAMessage_AccessoryTouched,
														   GPTVAMessage_DescriptionChanged);
		[duplex addObserver:self selector:@selector(received:type:) forMessages:messages];
		[messages release];
		
		uid = -1;
		[uidData getBytes:&uid length:sizeof(int)];
	}
	return self;
}
-(void)pushDictionary:(NSDictionary*)dictionary {
	if (uid == -1)
		return;
	[duplex sendMessage:GPTVAMessage_Push data:[NSPropertyListSerialization dataFromPropertyList:[NSArray arrayWithObjects:[NSNumber numberWithInt:uid], dictionary, nil]
																							format:NSPropertyListBinaryFormat_v1_0 errorDescription:NULL]];
}
-(void)reloadDictionary:(NSDictionary*)dictionary forIdentifier:(NSString*)identifier {
	if (uid != -1) {
		id rawArray[3] = {[NSNumber numberWithInt:uid], dictionary, identifier};
		[duplex sendMessage:GPTVAMessage_Reload data:[NSPropertyListSerialization dataFromPropertyList:[NSArray arrayWithObjects:rawArray count:(identifier == nil ? 2 : 3)]
																								format:NSPropertyListBinaryFormat_v1_0 errorDescription:NULL]];
	}
}
-(void)updateButtons:(NSArray*)buttons forIdentifier:(NSString*)identifier {
	if (uid != -1) {
		id rawArray[3] = {[NSNumber numberWithInt:uid], buttons, identifier};
		[duplex sendMessage:GPTVAMessage_UpdateButtons data:[NSPropertyListSerialization dataFromPropertyList:[NSArray arrayWithObjects:rawArray count:(identifier == nil ? 2 : 3)]
																									   format:NSPropertyListBinaryFormat_v1_0 errorDescription:NULL]];
	}
}
-(void)pop {
	if (uid != -1)
		[duplex sendMessage:GPTVAMessage_Pop data:[NSPropertyListSerialization dataFromPropertyList:[NSArray arrayWithObject:[NSNumber numberWithInt:uid]]
																							 format:NSPropertyListBinaryFormat_v1_0 errorDescription:NULL]];
}

@dynamic visible;
-(BOOL)isVisible {
	BOOL visibleValue = NO;
	if (uid != -1) {
		[[duplex sendMessage:GPTVAMessage_CheckVisible
						data:[NSData dataWithBytes:&uid length:sizeof(int)]
			   expectsReturn:YES] getBytes:&visibleValue length:sizeof(BOOL)];
	}
	return visibleValue;
}
@dynamic currentIdentifier;
-(NSString*)currentIdentifier {
	if (uid != -1)
		return [[[NSString alloc] initWithData:[duplex sendMessage:GPTVAMessage_GetCurrentIdentifier
															  data:[NSData dataWithBytes:&uid length:sizeof(int)]
													 expectsReturn:YES] 
									  encoding:NSUTF8StringEncoding] autorelease];
		
	else
		return nil;
}

-(void)dismiss {
	if (uid != -1) {
		NSMutableData* dataToSend = [NSMutableData dataWithBytes:&uid length:sizeof(int)];
		NSString* duplexName = duplex.name;
		[dataToSend appendBytes:[duplexName UTF8String] length:[duplexName length]+1];
		[duplex sendMessage:GPTVAMessage_Dismiss data:dataToSend];
		uid = -1;
	}
}

-(void)dealloc {
	[duplex removeObserver:self selector:@selector(received:type:)];
	[duplex release];
	[context release];
	[super dealloc];
}
@end