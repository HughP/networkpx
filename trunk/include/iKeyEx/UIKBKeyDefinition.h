/*
 
 UIKBKeyDefinition.h .... UIKeyDefinition struct represented as an object.
 
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

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGGeometry.h>
#import <UIKit2/CDStructures.h>

// Note: sizeof(UIKBKeyDefinition) == sizeof(NSObject) + sizeof(UIKeyDefinition).
@interface UIKBKeyDefinition : NSObject<NSCopying, NSCoding> {
@public
	CGRect bg_area;
	CGRect pop_bg_area;
	CGRect pop_char_area;
	CGRect accent_frame;
	CGRect pop_padding;
@protected
	NSString* value;
	NSString* shifted;
@public
	enum UIKeyDefinitionDownActionFlag down_flags;
	enum UIKeyDefinitionUpActionFlag up_flags;
	enum UIKeyType key_type;
@protected
	NSString* pop_type;
}
@property(copy) NSString* value;
@property(copy) NSString* shifted;
@property(copy) NSString* pop_type;

-(id)initWithKeyDefinition:(UIKeyDefinition)keyDef;
-(id)initWithCopy:(UIKBKeyDefinition*)keyDef;
-(void)dealloc;

@property(assign) UIKeyDefinition keyDefinition;

-(id)copyWithZone:(NSZone*)zone;

-(id)initWithCoder:(NSCoder*)decoder;
-(void)encodeWithCoder:(NSCoder*)encoder;

-(NSString*)description;


+(void)serializeArray:(NSArray*)array toFile:(NSString*)filename;
+(NSArray*)deserializeArrayFromFile:(NSString*)filename;
+(void)fillArray:(NSArray*)array toBuffer:(UIKeyDefinition*)buffer;
@end;