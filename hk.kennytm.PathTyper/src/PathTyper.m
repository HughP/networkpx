/*
 
 PathTyper.m ... Source for the PathTyper Input Manager.
 
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

// PathTyper is a demonstration of iKeyEx on how to customize Candidate List prompts.

#import <UIKit2/UIKeyboardInputManagerAlphabet.h>
#import <UIKit2/UIKeyboardImpl.h>
#import <UIKit2/CandWord.h>
#include <stdlib.h>

@interface PathTyperManager : UIKeyboardInputManager {
	NSMutableString* inputString;
	NSMutableString* PWD;
	
	NSArray* allValidPaths;
	NSFileManager* fileManager;
		
	id<UIKeyboardInput> delegate;
	UIKeyboardImpl* impl;
	BOOL selectedDirectory;
}
-(id)init;
-(void)dealloc;
-(NSUInteger)inputCount;
@property(assign) NSUInteger inputIndex;
@property(copy,readonly) NSString* inputString;
-(void)addInput:(NSString*)str flags:(NSUInteger)flg point:(CGPoint)point;
-(void)setInput:(NSString*)str;
-(void)deleteFromInput;
-(void)textAccepted:(NSString*)str;
-(BOOL)shouldExtendPriorWord;
-(BOOL)stringEndsWord:(NSString*)character;

@property(assign) BOOL shallowPrediction;
@end



@implementation PathTyperManager

-(BOOL)shouldExtendPriorWord { return YES; }
-(BOOL)stringEndsWord:(NSString*)character { return NO; }

-(NSArray*)candidates {
	if ([allValidPaths count] == 0)
		return nil;
	
	// Chop the part of directories that's known.
	NSUInteger PWDLen = [PWD length];
	
	// Candidates must be an NSArray of CandWords, not NSString.
	NSMutableArray* resArray = [[[NSMutableArray alloc] initWithCapacity:[allValidPaths count]] autorelease];
	for (NSString* path in allValidPaths) { 
		
		BOOL isFolder = NO;
		[fileManager fileExistsAtPath:path isDirectory:&isFolder];
		
		CandWord* cw = [CandWord alloc];
		
		// append "/" if the path points to a directory.
		if (isFolder)
			cw = [cw initWithWord:[[path substringFromIndex:PWDLen] stringByAppendingString:@"/"]];
		else
			cw = [cw initWithWord:[path substringFromIndex:PWDLen]];
		[resArray addObject:cw];
		[cw release];
	}
	
	return resArray;
}

-(BOOL)usesCandidateSelection { return YES; }
-(BOOL)suppressesCandidateDisplay { return NO;}
-(CandWord*)defaultCandidate { return [[[CandWord alloc] initWithWord:inputString] autorelease]; }
-(BOOL)suppliesCompletions { return selectedDirectory; }

@dynamic shallowPrediction;
-(BOOL)shallowPrediction { return NO; }
-(void)setShallowPrediction:(BOOL)val {}


//------------------------------------------------------------------------------
// Path finding engine.

-(void)PFLog:(NSString*)funcName {
	NSLog(@"%30s, PWD=[%@], inputString=[%@]", [funcName UTF8String], PWD, inputString);
}

// Set text as marked.
-(void)PFSetMarkedText:(NSString*)text {
	NSLog(@"delegate.text=%@; text=%@; mt=%@", delegate.text, text, delegate.markedText);
	for (NSUInteger i = [text length]; i != 0; -- i) {
		NSLog(@"%d", i);
		[delegate deleteBackward];
	}
	NSLog(@"delegate.text=%@; text=%@; mt=%@", delegate.text, text, delegate.markedText);
	delegate.markedText = text;
}

// Manually confirm marked text.
-(void)PFConfirm {
//	@throw @"sosad";

	[delegate confirmMarkedText:inputString];
	[inputString setString:@""];
	
	[self PFLog:@"PFConfirm"];
}

-(BOOL)PFGenerateCandidates {
	NSString* incompletePath = [[PWD stringByAppendingString:inputString] stringByExpandingTildeInPath];
	if ([incompletePath rangeOfString:@"/"].location != NSNotFound) {
		// test completion.
		NSString* dummy = nil;
		[allValidPaths release];
		NSUInteger count = [incompletePath completePathIntoString:&dummy caseSensitive:NO matchesIntoArray:&allValidPaths filterTypes:nil];
		
		// cannot complete. fail.
		if (count == 0) {
			allValidPaths = nil;
			[PWD setString:@""];
			[self PFLog:@"PFGenerateCandidates(count==0)"];
			
			return NO;
		} else {
			[allValidPaths retain];
			
			[self PFLog:@"PFGenerateCandidates(count!=0)"];
			
			return YES;
		}
	} else {
		[self PFLog:@"PFGenerateCandidates(invalid)"];
		return NO;
	}
}

-(void)PFAppend:(unichar)chr {
	NSString* chrAsString = [NSString stringWithCharacters:&chr length:1];
	if (chr == '/') {
		// entered a "/". Push inputString to PWD.
		[PWD appendString:inputString];
		NSLog(@"pwd=%@", PWD);
		[self PFConfirm];
		NSLog(@"pwd=%@", PWD);
		[inputString setString:chrAsString];
		
		// Nothing left. Repeat from beginning.
		if (![self PFGenerateCandidates]) {
			[inputString setString:chrAsString];
			[self PFGenerateCandidates];
		}
	} else {
		[inputString appendString:chrAsString];
		if (![self PFGenerateCandidates]) {
			[inputString deleteCharactersInRange:NSMakeRange([inputString length]-1, 1)];
			[self PFConfirm];
			if (chr == '~') {
				[inputString setString:chrAsString];
				[self PFGenerateCandidates];
			} else {
				[inputString setString:@""];
			}
		}
	}
	
	[self PFLog:@"PFAppend"];
}

-(void)PFRefresh {
	// recompute the PWD & inputString.
	
	NSString* wholeString = [delegate.text substringToIndex:delegate.selectionRange.location];
	NSUInteger wholeLength = [wholeString length];
		
	NSLog(@"ws=%@", wholeString);
	
	NSUInteger smallestIndex = 0;
	NSUInteger largestIndex = wholeLength;
	
	// a valid path to feed into completePathIntoString:[etc] must either contain a / or begins with ~.
	NSUInteger tildeIndex = [wholeString rangeOfString:@"~"].location;
	NSUInteger slashIndex = [wholeString rangeOfString:@"/" options:NSBackwardsSearch].location;
	if (slashIndex == NSNotFound) {
		if (tildeIndex == NSNotFound) {
			[self PFLog:@"PFRefresh(invalid)"];
			return; 
		} else {
			smallestIndex = tildeIndex;
			largestIndex = tildeIndex+1;
		}
	} else {
		largestIndex = slashIndex+1;
	}
	
	for (; smallestIndex < largestIndex; ++ smallestIndex) {
		NSString* substr = [wholeString substringFromIndex:smallestIndex];
		NSString* potentialValidPath = nil;
		if([substr completePathIntoString:&potentialValidPath caseSensitive:NO matchesIntoArray:NULL filterTypes:nil]) {
			if (slashIndex != NSNotFound) {
				[PWD setString:[wholeString substringWithRange:NSMakeRange(smallestIndex, slashIndex-smallestIndex)]];
				[inputString setString:[wholeString substringFromIndex:slashIndex]];
			} else {
				[PWD setString:@""];
				[inputString setString:substr];
			}
			[self PFGenerateCandidates];
			[self PFSetMarkedText:inputString];
			break;
		}
	}
	
	[self PFLog:@"PFRefresh"];
}

-(void)PFDelete {
	// input string not empty, simply delete last index.
	if (![@"" isEqualToString:inputString]) {
		NSUInteger inputLength = [inputString length];
		[inputString deleteCharactersInRange:NSMakeRange(inputLength-1, 1)];
		
		// input string is now empty.
		if (inputLength == 1) {
			NSUInteger slashIndex = [PWD rangeOfString:@"/" options:NSBackwardsSearch].location;
			// PWD has remaining path components. Pop that part to input string.
			if (slashIndex != NSNotFound) {
				[inputString setString:[PWD substringFromIndex:slashIndex]];
				[PWD deleteCharactersInRange:NSMakeRange(slashIndex, [PWD length]-slashIndex)];
			
			// PWD has everything consumed. Don't bother unless PWD starts with ~
			} else {
				if ([PWD hasPrefix:@"~"]) {
					[inputString setString:PWD];
					[PWD setString:@""];
				} else {
					[PWD setString:@""];
					[self PFLog:@"PFDelete(invalid)"];
					return;
				}
			}
		}
		
		[self PFSetMarkedText:inputString];
		[self PFGenerateCandidates];
	} else {
		[self PFRefresh];
	}
	
	[self PFLog:@"PFDelete"];
}

// Blah Blah Blah /usr/local/li
//                :::::::::::^^
//                PWD        marked string
// PWD + marked string = valid path string.

/*
-(BOOL)computeAllValuePaths {
	if (![@"" isEqualToString:nil]) {
		// test completion.
		NSString* dummy = nil;
		[allValidPaths release];
		NSUInteger count = [nil completePathIntoString:&dummy caseSensitive:NO matchesIntoArray:&allValidPaths filterTypes:nil];
		[allValidPaths retain];
		
		// cannot complete. fail.
		if (count == 0) {
			[nil setString:@""];
			[PWD setString:@""];
			[markedString setString:@""];
			return NO;
		}
		return YES;
	}
	return NO;
}

-(void)backtrackValidPathFromWholeStringStopsAt:(NSUInteger)maxBacktrackStep append:(NSString*)append {
	
}

-(void)appendStringToPath:(NSString*)chr confirmMarkedText:(BOOL)conf {
	NSUInteger chrLen = [chr length];
	NSString* oldMarkedString = [markedString copy];
	
	if (![@"" isEqualToString:nil]) {
		[nil appendString:chr];
		if ([chr hasSuffix:@"/"]) {
			[markedString appendString:[chr substringToIndex:chrLen-1]];
			if (conf)
				[impl.delegate confirmMarkedText:markedString];
			[PWD appendString:markedString];
			[PWD appendString:@"/"];
			[markedString setString:@""];
		} else {
			NSUInteger slashIndex = [chr rangeOfString:@"/"].location;
			if (slashIndex != NSNotFound) {
				[markedString appendString:[chr substringToIndex:slashIndex-1]];
				if (conf)
					[impl.delegate confirmMarkedText:markedString];
				[PWD appendString:markedString];
				[PWD appendString:@"/"];
				[markedString setString:[chr substringFromIndex:slashIndex+1]];
			} else {
				[markedString appendString:chr];
			}
		}
	} else {
		[self backtrackValidPathFromWholeStringStopsAt:[chr length] append:chr];
	}
	
	if (![self computeAllValuePaths]) {
		[impl.delegate confirmMarkedText:oldMarkedString];
	}
	
	[oldMarkedString release];
}

-(void)deleteCharactersFromPath:(NSUInteger)charactersToChop {
	NSUInteger msLength = [markedString length];
	if (charactersToChop < msLength) {
		[markedString deleteCharactersInRange:NSMakeRange(msLength-charactersToChop, charactersToChop)];
	} else {
		NSUInteger vpsLength = [nil length];
		if (charactersToChop < vpsLength) {
			[nil deleteCharactersInRange:NSMakeRange(vpsLength-charactersToChop, charactersToChop)];
			NSUInteger slashIndex = [nil rangeOfString:@"/" options:NSBackwardsSearch].location;
			if (slashIndex != NSNotFound) {
				[markedString setString:[nil substringFromIndex:slashIndex+1]];
				[PWD deleteCharactersInRange:NSMakeRange(slashIndex, [PWD length]-slashIndex)];
			} else {
				[PWD setString:@""];
				[markedString setString:nil];
			}
		}
	}
	[self backtrackValidPathFromWholeStringStopsAt:charactersToChop append:nil];
	[self computeAllValuePaths];
}
*/

// The rest is pretty much about maintaining the user input state.
-(id)init {
	if ((self = [super init])) {
		PWD = [[NSMutableString alloc] init];
		inputString = [[NSMutableString alloc] init];
		fileManager = [NSFileManager defaultManager];
		impl = [UIKeyboardImpl sharedInstance];
		delegate = impl.delegate;
	}
	return self;
}
-(void)dealloc {
	[inputString release];
	[PWD release];
	[super dealloc];
}

-(NSUInteger)inputCount { return [inputString length]; }
@synthesize inputString;
@dynamic inputIndex;
-(NSUInteger)inputIndex { return [inputString length]; }
-(void)setInputIndex:(NSUInteger)newIndex {
	[self PFRefresh];
}

-(void)addInput:(NSString*)str flags:(NSUInteger)flg point:(CGPoint)point {
	NSUInteger strLen = [str length];
	unichar* chars = malloc(sizeof(unichar)*strLen);
	[str getCharacters:chars];
	for (NSUInteger i = 0; i < strLen; ++ i)
		[self PFAppend:chars[i]];
}

-(void)setInput:(NSString*)str {
	[self PFConfirm];
	[self PFRefresh];
}

-(void)deleteFromInput {
	[self PFDelete];
}

-(void)textAccepted:(NSString*)str {
	selectedDirectory = [str hasSuffix:@"/"];
	if (selectedDirectory) {
		[inputString setString:@"/"];
		[PWD appendString:[str substringToIndex:[str length]-1]];
		if (![self PFGenerateCandidates]) {
			[inputString setString:@""];
		}
	} else {
		[inputString setString:@""];
		[PWD setString:@""];
		[allValidPaths release];
		allValidPaths = nil;
	}
}

-(void)clearInput {
	delegate = [UIKeyboardImpl sharedInstance].delegate;
}

@end
