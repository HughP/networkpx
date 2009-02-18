/*
 
 L33tTyper.m ... Source for the L33tTyper Input Manager.
 
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

// L33tTyper is a demonstration of iKeyEx on how to customize AutoCorrection prompts.

#import <Foundation/Foundation.h>
#import <UIKit2/UIKeyboardInputManagerAlphabet.h>
#include <stdlib.h>
#include <time.h>

NSString* translateString (NSString* str);

@interface L33tTyperManager : UIKeyboardInputManagerAlphabet {
	NSMutableString* inputString;
	NSUInteger inputIndex;
}
-(id)init;
-(void)dealloc;
-(NSString*)autocorrection;
@property(assign) NSUInteger inputIndex;
@property(copy,readonly) NSString* inputString;
-(void)addInput:(NSString*)str flags:(NSUInteger)flg point:(CGPoint)point;
-(void)setInput:(NSString*)str;
-(void)deleteFromInput;
-(void)textAccepted:(NSString*)str;
-(void)acceptInput;
-(BOOL)shouldExtendPriorWord;
@end

@implementation L33tTyperManager
@synthesize inputIndex, inputString;

// The input manager provides the AutoCorrection by overloading this function.
// In our case the result is simply a transliteration of the input string.
-(NSString*)autocorrection { return translateString(inputString); }

// Return YES if we want to account for neighboring characters as well. 
-(BOOL)shouldExtendPriorWord { return YES; }

// The rest is pretty much about maintaining the user input state.
-(id)init {
	if ((self = [super init])) {
		inputString = [[NSMutableString alloc] init];
		inputIndex = 0;
		srand(time(NULL));
	}
	return self;
}
-(void)dealloc {
	[inputString release];
	[super dealloc];
}


-(NSUInteger)inputCount { return [inputString length]; }

-(void)addInput:(NSString*)str flags:(NSUInteger)flg point:(CGPoint)point {
	[inputString insertString:str atIndex:inputIndex];
	++ inputIndex;
}

-(void)setInput:(NSString*)str {
	if (str != nil) {
		inputIndex = [str length];
		[inputString setString:str];
	} else {
		inputIndex = 0;
		[inputString setString:@""];
	}
}

-(void)deleteFromInput {
	-- inputIndex;
	[inputString deleteCharactersInRange:NSMakeRange(inputIndex, 1)];
}

-(void)textAccepted:(NSString*)str {
	inputIndex = 0;
	[inputString setString:@""];
}
-(void)acceptInput {
	inputIndex = 0;
	[inputString setString:@""];
	
}

@end

#pragma mark -
#pragma mark Transliteration Procedures

#define BuildCaseStatements3()
#define BuildCaseStatements4(a)       case 2: return @a
#define BuildCaseStatements5(b,a)     case 3: return @b; BuildCaseStatements4(a)
#define BuildCaseStatements6(c,a...)  case 4: return @c; BuildCaseStatements5(a)
#define BuildCaseStatements7(c,a...)  case 5: return @c; BuildCaseStatements6(a)
#define BuildCaseStatements8(c,a...)  case 6: return @c; BuildCaseStatements7(a)
#define BuildCaseStatements9(c,a...)  case 7: return @c; BuildCaseStatements8(a)
#define BuildCaseStatements10(c,a...) case 8: return @c; BuildCaseStatements9(a)
#define BuildCaseStatements11(c,a...) case 9: return @c; BuildCaseStatements10(a)

#define BuildTranslationForChar(mod, count, low, up, lowstr, upstr, def, etc...) \
case low: \
case up: \
switch (randNum % mod) { \
default: return @def; \
case 0: return @lowstr; \
case 1: return @upstr; \
BuildCaseStatements##count(etc); \
} \
break

// Random transliteration of a single character to L33tspeak.
NSString* translateChar (unichar c) {
	unsigned int randNum = rand();
	switch (c) {
		default:
			return [NSString stringWithCharacters:&c length:1];
			
			BuildTranslationForChar(20, 6, 'a', 'A', "a", "A", "4", "@", "/\\", "/-\\");
			BuildTranslationForChar(5,  5, 'b', 'B', "b", "B", "6", "13", "|3");
			BuildTranslationForChar(4,  3, 'c', 'C', "c", "C", "(");
			BuildTranslationForChar(10, 4, 'd', 'D', "d", "D", "|)", "c|");
			BuildTranslationForChar(20, 4, 'e', 'E', "e", "E", "3", "&");
			BuildTranslationForChar(5,  5, 'f', 'F', "f", "F", "ph", "PH", "|=");
			BuildTranslationForChar(10, 3, 'g', 'G', "g", "G", "9");
			BuildTranslationForChar(6,  4, 'h', 'H', "h", "H", "|-|", "#");
			BuildTranslationForChar(10, 4, 'i', 'I', "i", "I", "1", "|");
			BuildTranslationForChar(3,  3, 'j', 'J', "j", "J", "_/");
			BuildTranslationForChar(6,  4, 'k', 'K', "k", "K", "|<", "|(");
			BuildTranslationForChar(20, 3, 'l', 'L', "l", "L", "1");
			BuildTranslationForChar(6,  4, 'm', 'M', "m", "M", "|V|", "/\\/\\");
			BuildTranslationForChar(6,  4, 'n', 'N', "n", "N", "|\\|", "^");
			BuildTranslationForChar(20, 4, 'o', 'O', "o", "O", "0", "()");
			BuildTranslationForChar(6,  6, 'p', 'P', "p", "P", "|>", "9", "17", "|7");
			BuildTranslationForChar(3,  3, 'q', 'Q', "q", "Q", "9");
			BuildTranslationForChar(10, 4, 'r', 'R', "r", "R", "2", "|2");
			BuildTranslationForChar(20, 6, 's', 'S', "s", "S", "5", "$", "z", "Z");
			BuildTranslationForChar(20, 4, 't', 'T', "t", "T", "7", "+");
			BuildTranslationForChar(4,  3, 'u', 'U', "u", "U", "|_|");
			BuildTranslationForChar(4,  3, 'v', 'V', "v", "V", "\\/");
			BuildTranslationForChar(10, 5, 'w', 'W', "w", "W", "\\/\\/", "vv", "VV");
			BuildTranslationForChar(3,  3, 'x', 'X', "x", "X", "><");
			BuildTranslationForChar(6,  5, 'y', 'Y', "y", "Y", "j", "J", "`/");
			BuildTranslationForChar(20, 4, 'z', 'Z', "z", "Z", "2", "7_");
	}
}

// Transliterate the whole string into L33tSpeak.
NSString* translateString (NSString* str) {
	NSUInteger len = [str length];
	unichar* charArr = malloc(sizeof(unichar) * len);
	[str getCharacters:charArr];
	NSMutableString* resStr = [[[NSMutableString alloc] init] autorelease];
	for (NSUInteger i = 0; i < len; ++ i)
		[resStr appendString:translateChar(charArr[i])];
	return resStr;
}
