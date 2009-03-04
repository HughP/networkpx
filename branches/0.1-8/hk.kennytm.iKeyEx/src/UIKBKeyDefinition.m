/*
 
 UIKBKeyDefinition.m .... UIKeyDefinition struct represented as an object.
 
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

#import <iKeyEx/UIKBKeyDefinition.h>
#import <UIKit/UIGeometry.h>
#import <UIKit2/Constants.h>
#include <stdlib.h>

@implementation UIKBKeyDefinition
@synthesize value, shifted;

-(id)initWithKeyDefinition:(UIKeyDefinition)keyDef {
	if ((self = [super init])) {
		self.keyDefinition = keyDef;
	}
	return self;
}

-(id)initWithCopy:(UIKBKeyDefinition*)keyDef {
	if ((self = [super init])) {
		memcpy(&bg_area, &(keyDef->bg_area), sizeof(UIKBKeyDefinition));
		value = [value copy];
		shifted = [shifted copy];
	}
	return self;
}

-(void)dealloc {
	[value release];
	[shifted release];
	[super dealloc];
}

@dynamic keyDefinition;
-(void)setKeyDefinition:(UIKeyDefinition)keyDef {
	memcpy(&bg_area, &keyDef, sizeof(UIKBKeyDefinition));
	value = [value copy];
	shifted = [shifted copy];
}
-(UIKeyDefinition)keyDefinition {
	UIKeyDefinition retVal;
	memcpy(&retVal, &bg_area, sizeof(UIKBKeyDefinition));
	retVal.value = [value copy];
	retVal.shifted = [shifted copy];
	return retVal;
}

-(id)copyWithZone:(NSZone*)zone { return [[UIKBKeyDefinition allocWithZone:zone] initWithCopy:self]; }

#define DecodeCGRect(key) key = CGRectMake([decoder decodeFloatForKey:@#key@".x"], [decoder decodeFloatForKey:@#key@".y"], [decoder decodeFloatForKey:@#key@".w"], [decoder decodeFloatForKey:@#key@".h"])
-(id)initWithCoder:(NSCoder*)decoder {
	if ((self = [super init])) {
		DecodeCGRect(bg_area);
		DecodeCGRect(pop_bg_area);
		DecodeCGRect(pop_char_area);
		DecodeCGRect(accent_frame);
		DecodeCGRect(pop_padding);
		self.value = [decoder decodeObjectForKey:@"value"];
		self.shifted = [decoder decodeObjectForKey:@"shifted"];
		pop_type = (NSString*)[decoder decodeIntForKey:@"pop_type"];	// we assume the locations of the UIKit constants are.. well, constant.
		down_flags = [decoder decodeIntForKey:@"down_flags"];
		up_flags = [decoder decodeIntForKey:@"up_flags"];
		key_type = [decoder decodeIntForKey:@"key_type"];
	}
	return self;
}

#define EncodeCGRect(key) \
	[encoder encodeFloat:key.origin.x forKey:@#key@".x"]; \
	[encoder encodeFloat:key.origin.y forKey:@#key@".y"]; \
	[encoder encodeFloat:key.size.width forKey:@#key@".w"]; \
	[encoder encodeFloat:key.size.height forKey:@#key@".h"]

-(void)encodeWithCoder:(NSCoder*)encoder {
	EncodeCGRect(bg_area);
	EncodeCGRect(pop_bg_area);
	EncodeCGRect(pop_char_area);
	EncodeCGRect(accent_frame);
	EncodeCGRect(pop_padding);
	[encoder encodeObject:value forKey:@"value"];
	[encoder encodeObject:shifted forKey:@"shifted"];
	[encoder encodeInt:(int)pop_type forKey:@"pop_type"];
	[encoder encodeInt:down_flags forKey:@"down_flags"];
	[encoder encodeInt:up_flags forKey:@"up_flags"];
	[encoder encodeInt:key_type forKey:@"key_type"];
}

-(NSString*)description {
	return [NSString stringWithFormat:@"UIKBKeyDefinition {\
			bg_area       = %@;\
			pop_bg_area   = %@;\
			pop_char_area = %@;\
			accent_frame  = %@;\
			pop_padding   = %@;\
			value         = @\"%@\";\
			shifted       = @\"%@\";\
			down_flags    = 0x%x;\
			up_flags      = 0x%x;\
			key_type      = %d;\
			pop_type      = @\"%@\";\
}",
			NSStringFromCGRect(bg_area),
			NSStringFromCGRect(pop_bg_area),
			NSStringFromCGRect(pop_char_area),
			NSStringFromCGRect(accent_frame),
			NSStringFromCGRect(pop_padding),
			value, shifted, down_flags, up_flags, key_type, pop_type];
}



+(void)serializeArray:(NSArray*)array toFile:(NSString*)filename {
	NSUInteger count = [array count];
	UIKBKeyDefinition** keyDefs = malloc(count*sizeof(UIKBKeyDefinition*));
	UIKBKeyDefinition* bytesToSave = malloc(count*(sizeof(UIKBKeyDefinition)));
	[array getObjects:keyDefs];
	
	UIKBKeyDefinition* curBytesToSave = bytesToSave;
	UIKBKeyDefinition** curKeyDefs = keyDefs;
	
	for (NSUInteger i = 0; i < count; ++ i) {
		memcpy(curBytesToSave, *curKeyDefs, sizeof(UIKBKeyDefinition));
		++curBytesToSave;
		++curKeyDefs;
	}
	
	NSData* bytesData = [[NSData alloc] initWithBytesNoCopy:bytesToSave length:count*(sizeof(UIKBKeyDefinition)) freeWhenDone:NO];
	
	NSMutableArray* dataToSave = [[NSMutableArray alloc] initWithCapacity:count*2+1];
	[dataToSave addObject:bytesData];
	
	id zero = [[NSNumber alloc] initWithBool:NO];
	
	for (NSUInteger i = 0; i < count; ++ i) {
		[dataToSave addObject:((keyDefs[i]->value != nil) ? keyDefs[i]->value : zero)];
		[dataToSave addObject:((keyDefs[i]->shifted != nil) ? keyDefs[i]->shifted : zero)];
	}
	
	//[dataToSave writeToFile:filename atomically:YES];
	NSString* errorStr = nil;
	NSData* plistResult = [NSPropertyListSerialization dataFromPropertyList:dataToSave
																	 format:NSPropertyListBinaryFormat_v1_0
														   errorDescription:&errorStr];
	if (plistResult == nil) {
		NSLog(@"Cannot serialize keyboard definition array because: %@", errorStr);
		[errorStr release];
	} else {
		[plistResult writeToFile:filename atomically:NO];
	}
	
	[dataToSave release];
	[bytesData release];
	[zero release];
	
	free(keyDefs);
	free(bytesToSave);
}

+(NSArray*)deserializeArrayFromFile:(NSString*)filename {
	NSData* plistInput = [[NSData alloc] initWithContentsOfFile:filename];
	if (plistInput == nil)
		return nil;
	
	NSString* errorStr = nil;
	NSArray* dataToRead = [NSPropertyListSerialization propertyListFromData:plistInput
														   mutabilityOption:NSPropertyListImmutable
																	 format:NULL
														   errorDescription:&errorStr];
	[plistInput release];
	if (dataToRead == nil) {
		NSLog(@"Cannot deserialize keyboard definition array from \"%@\" because: %@", filename, errorStr);
		[errorStr release];
		return nil;
	} else if (![dataToRead isKindOfClass:[NSArray class]]) {
		NSLog(@"Cannot deserialize keyboard definition array from \"%@\" because: The property list contains an %@ instead of an NSArray.", filename, [dataToRead class]);
		return nil;
	}
	
	NSUInteger count = ([dataToRead count]-1)/2;
	UIKBKeyDefinition** keyDefsArr = malloc(count*sizeof(UIKBKeyDefinition*));
		
	int round = 0;
	BOOL firstRecord = YES;
	UIKBKeyDefinition* curBytes = NULL;
	UIKBKeyDefinition** curKeyDef = keyDefsArr;
	Class strCls = [NSString class];
	
	for (NSString* data in dataToRead) {
		if (firstRecord) {
			curBytes = (UIKBKeyDefinition*)[(NSData*)data bytes];
			firstRecord = NO;
		} else {
			BOOL isNSString = [data isKindOfClass:strCls];
			switch (round) {
				case 0:
					*curKeyDef = [UIKBKeyDefinition alloc];
					
					// don't copy the members of NSObject...
					memcpy(&((*curKeyDef)->bg_area), &(curBytes->bg_area), sizeof(UIKeyDefinition));
					
					(*curKeyDef)->value = isNSString ? [data copy] : nil;
					++ round;
					break;
				case 1:
					(*curKeyDef)->shifted = isNSString ? [data copy] : nil;
					++ round;
					++ curBytes;
					++ curKeyDef;
					round = 0;
			}
		}
	}
	
	NSArray* resultArray = [NSArray arrayWithObjects:keyDefsArr count:count];
	
	for (NSUInteger i = 0; i < count; ++ i)
		[keyDefsArr[i] release];
	
	//[dataToRead release];
	free(keyDefsArr);
	
	return resultArray;
}

+(void)fillArray:(NSArray*)array toBuffer:(UIKeyDefinition*)buffer {
	UIKeyDefinition* buf = buffer;
	for (UIKBKeyDefinition* keyDef in array) {
		memcpy(buf, &(keyDef->bg_area), sizeof(UIKeyDefinition));
		buf->value = [buf->value copy];
		buf->shifted = [buf->shifted copy];
		++ buf;
	}
}
@end