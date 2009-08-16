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

#define IKXCININPUTMANAGER_MM

#include "pattrie.hpp"

using namespace IKX;
typedef ReadonlyPatTrie<IMEContent> __IKXCinInputManagerPatTrie;

#include "IKXCinInputManager.h"
#import <UIKit/CandWord.h>
#import <UIKit/UIKeyboardLayout.h>
#import <UIKit/UIKeyboardImpl.h>
#include "libiKeyEx.h"
#include "cin2pat.h"

#define IKXLog(format, ...) NSLog(@"%s: " @format, __FUNCTION__, ## __VA_ARGS__)

@implementation CandWord (IKXCinInputManagerExtension)
-(NSComparisonResult)compare:(CandWord*)other {
	return [[self word] localizedCompare:[other word]];
}
@end


@implementation IKXCinInputManager
-(id)init {
	if ((self = [super init])) {
		ime_string = [NSMutableString new];
		
		NSString* mode = UIKeyboardGetCurrentInputMode();
		NSString* imeRef;
		while (true) {
			imeRef = IKXInputManagerReference(mode);
			if ([imeRef characterAtIndex:0] == '=')
				mode = [imeRef substringFromIndex:1];
			else
				break;
		}
		NSBundle* imeBundle = IKXInputManagerBundle(imeRef);
		NSString* expectedPath = [NSString stringWithFormat:@"%@/iKeyEx::cache::ime::%@.pat", IKX_SCRAP_PATH, imeRef];
		
		if (![[NSFileManager defaultManager] fileExistsAtPath:expectedPath]) {
			NSString* cinName = [imeBundle objectForInfoDictionaryKey:@"UIKeyboardInputManagerClass"];
			NSString* cinPath = [imeBundle pathForResource:cinName ofType:nil];
			IKXConvertCinToPat([cinPath UTF8String], [expectedPath UTF8String]);
		}
		
		pat = new ReadonlyPatTrie<IMEContent>([expectedPath UTF8String]);
		if (pat == NULL || !pat->valid()) {
			[self release];
			return nil;
		}
	}
	return self;
}
-(void)dealloc {
	[ime_string release];
	delete pat;
	[super dealloc];
}

-(void)clearInput {
	[ime_string setString:@""];
}
-(void)inputLocationChanged {
	[self clearInput];
}
-(NSString*)inputString {
	return ime_string;
}
-(void)textAccepted:(id)txt {
	[self clearInput];
}
-(NSUInteger)inputCount {
	return [ime_string length];
}
-(NSUInteger)inputIndex {
	return [self inputCount];
}
-(NSString*)addInput:(NSString*)input flags:(unsigned int)flags point:(CGPoint)pt firstDelete:(unsigned*)wtf fromVariantKey:(BOOL)isVar {
	[ime_string appendString:[input lowercaseString]];
	return ime_string;
}
/*
-(BOOL)stringEndsWord:(NSString*)string {
	return NO;
}
 */
-(NSArray*)candidates {
	IMEContent curContent;
	curContent.key.length = [ime_string length];
	
	if (curContent.key.length == 0)
		return nil;
	else if (curContent.key.length > 31)
		curContent.key.length = 31;
	
	memcpy(curContent.key.content, [ime_string UTF8String], curContent.key.length);
	
	std::vector<IMEContent> res = pat->prefix_search(curContent);
	
	NSMutableArray* resArr = [NSMutableArray arrayWithCapacity:res.size()];
	
	for (std::vector<IMEContent>::const_iterator cit = res.begin(); cit != res.end(); ++ cit) {
		const wchar_t* candidate_ptr;
		if (cit->value.external_candidates != 0)
			candidate_ptr = pat->extra_content() + cit->value.external_candidates;
		else
			candidate_ptr = cit->value.local_candidates;
		
		for (unsigned i = 0; i < cit->value.length; ++i) {
			wchar_t cand = candidate_ptr[i];
			NSString* candStr;
			if (cand > 0xFFFF) {
				unichar two_bytes[2];
				two_bytes[0] = ((cand >> 10) & ~0x40) | 0xd800;
				two_bytes[1] = (cand & 0x3ff) | 0xdc00;
				candStr = [NSString stringWithCharacters:two_bytes length:2];
			} else
				candStr = [NSString stringWithCharacters:reinterpret_cast<const unichar*>(&cand) length:1];
				
			CandWord* wi = [[CandWord alloc] initWithWord:candStr];
			[resArr addObject:wi];
			[wi release];
		}
	}
	[resArr sortUsingSelector:@selector(compare:)];
	
	return resArr;
}
-(NSUInteger)defaultCandidateIndex {
	return 0;
}
/*
-(void)candidateAccepted:(CandWord*)wi {
}
 */
-(NSString*)remainingInput {
	return ime_string;
}
-(BOOL)suppliesCompletions {
	return YES;
}
-(id)deleteFromInput:(unsigned*)x {
	[super deleteFromInput:x];
	[ime_string deleteCharactersInRange:NSMakeRange([ime_string length]-*x, *x)];
	return ime_string;
}

-(void)configureKeyboard:(UIKeyboardLayout*)kb forCandidates:(id)ca {
	if ([ca count] != 0) {
		UIKeyboardImpl* impl = [UIKeyboardImpl sharedInstance];
		
		[kb setLabel:UIKeyboardStringConfirm forKey:UIKeyboardKeyReturn];
		[kb setTarget:impl forKey:UIKeyboardKeyReturn];
		[kb setAction:@selector(acceptCurrentCandidate) forKey:UIKeyboardKeyReturn];
		
		[kb setLabel:UIKeyboardStringConfirm forKey:UIKeyboardKeySpace];
		[kb setTarget:impl forKey:UIKeyboardKeySpace];
		[kb setAction:@selector(acceptCurrentCandidate) forKey:UIKeyboardKeySpace];
	}
}


-(BOOL)usesCandidateSelection { return YES; }
-(BOOL)suppressesCandidateDisplay { return NO; }
-(BOOL)suppressCompletionsForFieldEditor { return NO; }



//-(CandWord*)defaultCandidate { return [[self candidates] objectAtIndex:[self defaultCandidateIndex]]; }
/*
-(void)setAutoCorrects:(BOOL)autocor {}
-(void)setKeyboardMatchType:(int)type {}

-(void)addToTypingHistory:(NSString*)string {}
-(void)increaseUserFrequency:(NSString*)string {}
-(void)decreaseUserFrequency:(NSString*)string {}

-(void)configureKeyboard:(id)kb forAutocorrection:(id)ac {}
-(NSString*)shadowTyping { return nil; }
-(NSString*)autocorrection { return nil; }

-(void)deleteFromStrokeHistory:(BOOL)sh {}


-(void)setCalculatesChargedKeyProbabilities:(BOOL)doCalc {}
-(BOOL)canHandleKeyHitTest { return NO; }
-(void)clearAllCentroids {}
-(void)registerCentroid:(CGPoint)cg forKey:(id)key {}
-(void)setShift:(BOOL)shifted {}
-(void)setAutoShift:(BOOL)autoshifted {}
-(void)clearKeyAreas{}
-(void)registerKeyArea:(CGPoint)keyArea withRadii:(CGPoint)radii forKeyCode:(unichar)keyCode forLowerKey:(id)lc forUpperKey:(id)uc {}
-(BOOL)shouldExtendPriorWord { return NO; }
-(BOOL)supportsSetPhraseBoundary { return NO; }
 */
@end

