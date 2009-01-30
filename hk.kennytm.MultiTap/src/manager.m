/*
 
 manager.m ... Input manager for MultiTap input method.
 
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

#import <UIKit2/UIKeyboardInputManagerAlphabet.h>
#import <UIKit2/UIKeyboardImpl.h>
#import <UIKit2/CandWord.h>
#import <Foundation/Foundation.h>

#import "layout.h"

#define confirmInterval 1

extern BOOL layoutWillEnableManager;

#define buildTranslationString2(charA, charB) case charA: return charB
#define buildTranslationString3(charA, charB, charC) case charA: return charB; buildTranslationString2(charB, charC)
#define buildTranslationString4(charA, charB, chars...) case charA: return charB; buildTranslationString3(charB, chars)
#define buildTranslationString5(charA, charB, chars...) case charA: return charB; buildTranslationString4(charB, chars)
#define buildTranslationString6(charA, charB, chars...) case charA: return charB; buildTranslationString5(charB, chars)
#define buildTranslationString7(charA, charB, chars...) case charA: return charB; buildTranslationString6(charB, chars)
#define buildTranslationString8(charA, charB, chars...) case charA: return charB; buildTranslationString7(charB, chars)
#define buildTranslationString9(charA, charB, chars...) case charA: return charB; buildTranslationString8(charB, chars)
#define buildTranslationString10(charA, charB, chars...) case charA: return charB; buildTranslationString9(charB, chars)
#define buildTranslationString11(charA, charB, chars...) case charA: return charB; buildTranslationString10(charB, chars)
#define buildTranslationString12(charA, charB, chars...) case charA: return charB; buildTranslationString11(charB, chars)
#define buildTranslationString13(charA, charB, chars...) case charA: return charB; buildTranslationString12(charB, chars)
#define buildTranslationString14(charA, charB, chars...) case charA: return charB; buildTranslationString13(charB, chars)
#define buildTranslationString15(charA, charB, chars...) case charA: return charB; buildTranslationString14(charB, chars)

#define buildTranslationCaseStatement(n, def, charA, chars...) \
case def: \
	switch (previousChar) { \
		default: return charA; \
		buildTranslationString##n(charA, chars); \
	} \
	break

unichar translateTap (unichar charEntered, unichar previousChar) {
	switch (charEntered) {
			buildTranslationCaseStatement(14, '1', '.', ',', '\'', '?', '!', '"', '1', '-', '(', ')', '@', '/', ':', '_');
			buildTranslationCaseStatement( 4, '2', 'a', 'b', 'c', '2');
			buildTranslationCaseStatement( 4, '3', 'd', 'e', 'f', '3');
			buildTranslationCaseStatement( 4, '4', 'g', 'h', 'i', '4');
			buildTranslationCaseStatement( 4, '5', 'j', 'k', 'l', '5');
			buildTranslationCaseStatement( 4, '6', 'm', 'n', 'o', '6');
			buildTranslationCaseStatement( 5, '7', 'p', 'q', 'r', 's', '7');
			buildTranslationCaseStatement( 4, '8', 't', 'u', 'v', '8');
			buildTranslationCaseStatement( 5, '9', 'w', 'x', 'y', 'z', '9');
			buildTranslationCaseStatement( 3, '0', ' ', '0', '\n');
	}
	return charEntered;
}

unichar translateTapWithShift (unichar charEntered, unichar previousChar, BOOL shifted) {
	if (shifted && previousChar >= 'A' && previousChar <= 'Z')
		previousChar += ('a' - 'A');
	unichar retval = translateTap(charEntered, previousChar);
	if (shifted && retval >= 'a' && retval <= 'z')
		retval -= ('a' - 'A');
	return retval;
}

@interface MultiTapInputManager : UIKeyboardInputManagerAlphabet {
	unichar lastChar;
	unichar charToShow;
	UIKeyboardImpl* impl;
}

-(id)init;

-(void)clearInput;
-(void)addInput:(NSString*)input flags:(NSUInteger)flg point:(CGPoint)pnt;
-(void)setInput:(NSString*)input;

-(BOOL)suppressesCandidateDisplay;
-(BOOL)usesCandidateSelection;
-(void)deleteFromInput;
-(void)acceptInput;
@property(assign) NSUInteger inputIndex;
@property(assign,readonly) NSUInteger inputCount;
@property(copy,readonly) NSString* inputString;
-(void)inputLocationChanged;
-(NSString*)autocorrection;
-(NSArray*)candidates;
-(CandWord*)defaultCandidate;
@end


@implementation MultiTapInputManager
-(id)init {
	if ((self = [super init]))
		impl = [UIKeyboardImpl sharedInstance];
	return self;
}

-(void)clearInput {
	charToShow = lastChar = '\0';
}

-(void)addInput:(NSString*)input flags:(NSUInteger)flg point:(CGPoint)pnt {
	if (!layoutWillEnableManager || [input length] != 1) {
		if (lastChar != '\0') {
			[NSObject cancelPreviousPerformRequestsWithTarget:impl selector:@selector(acceptCurrentCandidate) object:nil];
			[impl acceptCurrentCandidate];
			lastChar = '\0';
		}
		[super addInput:input flags:flg point:pnt];
	} else {
		if (lastChar != '\0')
			[NSObject cancelPreviousPerformRequestsWithTarget:impl selector:@selector(acceptCurrentCandidate) object:nil];
		unichar newChar = [input characterAtIndex:0];
		if (newChar != lastChar) {
			if (lastChar != '\0')
				[impl acceptCurrentCandidate];
			lastChar = newChar;
			charToShow = '\0';
		}
		charToShow = translateTapWithShift(lastChar, charToShow, [impl isShifted]);
		[impl performSelector:@selector(acceptCurrentCandidate) withObject:nil afterDelay:confirmInterval];
	}
}

-(void)setInput:(NSString*)input {
	if (lastChar != '\0') {
		[NSObject cancelPreviousPerformRequestsWithTarget:impl selector:@selector(acceptCurrentCandidate) object:nil];
		[impl acceptCurrentCandidate];
		lastChar = '\0';
	}
	[super setInput:input];
}

// these are not important. The implementation are referenced from the assembly of TextInput_ko.
-(BOOL)suppressesCandidateDisplay { return YES; }
-(BOOL)usesCandidateSelection { return YES; }
-(void)deleteFromInput { [self clearInput]; }
-(void)acceptInput { [self clearInput]; }
@dynamic inputIndex;
-(void)setInputIndex:(NSUInteger)idx {}
-(NSUInteger)inputIndex { return lastChar == '\0' ? 0 : 1; }
@dynamic inputCount;
-(NSUInteger)inputCount { return lastChar == '\0' ? 0 : 1; }
@dynamic inputString;
-(NSString*)inputString { return lastChar == '\0' ? @"" : [NSString stringWithCharacters:&charToShow length:1]; }
-(void)inputLocationChanged { [self clearInput]; }
-(NSString*)autocorrection { return [self inputString]; }
-(NSArray*)candidates { return [NSArray arrayWithObject:[self defaultCandidate]]; }
-(CandWord*)defaultCandidate { return lastChar == '\0' ? nil : [[[CandWord alloc] initWithWord:[self inputString]] autorelease]; }
@end
