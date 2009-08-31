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
#include "hash.hpp"
#include <tr1/unordered_map>

using namespace IKX;

#include "IKXCinInputManager.h"
#import <UIKit/UIKit2.h>
#include "libiKeyEx.h"
#include "cin2pat.h"
#import <ActorKit/ActorKit.h>
#include <pthread.h>
#include <sys/time.h>



@implementation CandWord (iKeyEx_Extensions)
-(NSUInteger)length { return [[self word] length]; }
-(void)getCharacters:(unichar*)buffer { [[self word] getCharacters:buffer]; }
-(void)getCharacters:(unichar*)buffer range:(NSRange)range { [[self word] getCharacters:buffer range:range]; }
-(const char*)UTF8String { return [self wordUTF8String]; }
-(BOOL)isEqualToString:(CandWord*)another { return [[self word] isEqualToString:[another word]]; }
@end


static IMEContent makeIMEContent(NSString* prefix) {
	IMEContent retval;
	const char* prefix_utf8 = [prefix UTF8String];
	retval.key_length = std::strlen(prefix_utf8);
	if (retval.key_length > sizeof(retval.key_content))
		retval.key_length = sizeof(retval.key_content);
	std::memcpy(retval.key_content, prefix_utf8, retval.key_length);
	return retval;
}

@protocol IKXCandidateComputerProtocol
-(oneway void)computeWithInputString:(NSString*)inputString lastAcceptedCandidate:(NSString*)lastAcceptedCandidate;
@end

__attribute__((visibility("hidden")))
@interface IKXCandidateComputer : AKActor<IKXCandidateComputerProtocol> {
@private
	NSMutableArray* current_candidates;
	NSString* valid_keys[256];
	ReadonlyPatTrie<IMEContent>* pat;
	IKXPhraseCompletionTableRef phrases;
	IKXCharacterTableRef chars;
	pthread_mutex_t cclock;
	pthread_cond_t cccond;
	BOOL computing;
}
@end

@implementation IKXCandidateComputer
-(id)init {
	if ((self = [super init])) {
		current_candidates = [NSMutableArray new];
		pthread_mutex_init(&cclock, NULL);
		pthread_cond_init(&cccond, NULL);
		
//		UIProgressHUD* hud = IKXShowLoadingHUD();
		
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
		NSString* imeLang = [imeBundle objectForInfoDictionaryKey:@"IKXLanguage"] ?: @"zh-Hant";
		NSString* expectedPath = [NSString stringWithFormat:IKX_SCRAP_PATH@"/iKeyEx::cache::ime::%@.pat", imeRef];
		NSString* expectedKeysPath = [expectedPath stringByReplacingCharactersInRange:NSMakeRange([expectedPath length]-4, 4) withString:@".kns"];
		
		if (![[NSFileManager defaultManager] fileExistsAtPath:expectedPath]) {
			NSString* cinName = [imeBundle objectForInfoDictionaryKey:@"UIKeyboardInputManagerClass"];
			NSString* cinPath = [imeBundle pathForResource:cinName ofType:nil];
			IKXConvertCinToPat([cinPath UTF8String], [expectedPath UTF8String], [expectedKeysPath UTF8String]);
		}
		
		pat = new ReadonlyPatTrie<IMEContent>([expectedPath UTF8String]);
		if (pat == NULL || !pat->valid()) {
			NSLog(@"iKeyEx: Error: '%@' is not a valid Patricia trie dump.", expectedPath);
			[self release];
			return nil;
		}
		
		std::FILE* f = std::fopen([expectedKeysPath UTF8String], "rb");
		if (f != NULL) {
			while (!std::feof(f)) {
				uint8_t c;
				size_t l;
				std::fread(&c, 1, 1, f);
				std::fread(&l, 1, sizeof(size_t), f);
				unichar buffer[l];
				std::fread(buffer, l, sizeof(unichar), f);
				[valid_keys[c] release];
				valid_keys[c] = [[NSString alloc] initWithCharacters:buffer length:l];
			}
			std::fclose(f);
		}
		
		phrases = IKXPhraseCompletionTableCreate(imeLang);
		chars = IKXCharacterTableCreate(imeLang);
		
//		IKXHideLoadingHUD(hud);
	}
	return self;
}
-(void)dealloc {
	for (int i = 0; i < 256; ++i)
		[valid_keys[i] release];
	[current_candidates release];
	delete pat;
	IKXPhraseCompletionTableDealloc(phrases);
	IKXCharacterTableDealloc(chars);
	pthread_mutex_destroy(&cclock);
	pthread_cond_destroy(&cccond);
	[super dealloc];
}

-(void)prepareCompute {
	computing = YES;
	pthread_mutex_lock(&cclock);
	[current_candidates removeAllObjects];	
}

-(oneway void)computeWithInputString:(NSString*)inputString lastAcceptedCandidate:(NSString*)lastAcceptedCandidate {
	if (lastAcceptedCandidate != nil) {
		NSUInteger lac_len = [lastAcceptedCandidate length];
		NSArray* resArr = IKXPhraseCompletionTableSearch(phrases, lastAcceptedCandidate);
		
		for (NSString* res in resArr) {
			CandWord* cw = [[CandWord alloc] initWithWord:[res substringFromIndex:lac_len]];
			[current_candidates addObject:cw];
			[cw release];
		}
	} else if ([inputString length] > 0) {
		IMEContent curContent = makeIMEContent(inputString);
		std::vector<IMEContent> res = pat->prefix_search(curContent);
		
		NSMutableArray* resArr = [NSMutableArray arrayWithCapacity:res.size()];
		
		unsigned resCount = 0;
		for (std::vector<IMEContent>::const_iterator cit = res.begin(); cit != res.end(); ++ cit) {		
			const uint16_t* cands = cit->candidates_array(*pat);
			size_t cand_len = cit->candidate_string_length;
			size_t prev_i = 0;
			
			NSMutableArray* whichArr = cit->equal(curContent, *pat) ? current_candidates : resArr;
			
			for (size_t i = 0; i < cand_len; ++ i)
				if (cands[i] == 0) {
					CandWord* cw = [[CandWord alloc] initWithWord:[NSString stringWithCharacters:cands+prev_i length:i-prev_i]];
					[whichArr addObject:cw];
					[cw release];
					prev_i = i+1;
					++ resCount;
				}
			CandWord* cw = [[CandWord alloc] initWithWord:[NSString stringWithCharacters:cands+prev_i length:cand_len-prev_i]];
			[whichArr addObject:cw];
			[cw release];
			++ resCount;
			
			if (resCount > 64)
				break;
		}
		IKXCharacterTableSort(chars, current_candidates);
		IKXCharacterTableSort(chars, resArr);
		[current_candidates addObjectsFromArray:resArr];		
	}
	
	computing = NO;
	pthread_cond_signal(&cccond);
	pthread_mutex_unlock(&cclock);
}
-(BOOL)isValidKey:(unichar)c {
	return c <= 0xFF && valid_keys[c] != nil;
}
-(BOOL)containsPrefix:(NSString*)prefix {
	return pat->contains_prefix(makeIMEContent(prefix));
}
-(NSArray*)commit {
	pthread_mutex_lock(&cclock);
	if (computing) {
		struct timeval now;
		gettimeofday(&now, NULL);
		struct timespec timeout;
		timeout.tv_nsec = 0;
		timeout.tv_sec = now.tv_sec + 2;
		int err = pthread_cond_timedwait(&cccond, &cclock, &timeout);
		if (err == ETIMEDOUT)
			NSLog(@"iKeyEx: Error: The candidates list took too much time to compute.");
		else if (err != 0)
			NSLog(@"iKeyEx: Error: pthread_cond_timedwait returned %d, which should not happen. Close all windows and leave this building now.", err);
	}
	NSArray* cands = current_candidates;
	
	pthread_mutex_unlock(&cclock);
	return cands;
}
-(NSString*)displayedInputStringOf:(NSString*)s {
	NSUInteger slen = [s length];
	if (slen == 0) return nil;
	NSMutableString* res = [NSMutableString string];
	unichar buffer[slen];
	[s getCharacters:buffer];
	for (NSUInteger i = 0; i < slen; ++ i) {
		NSString* name = valid_keys[buffer[i]];
		if (name)
			[res appendString:name];
		else
			[res appendString:[s substringWithRange:NSMakeRange(i, 1)]];
	}
	return res;
}
@end




@implementation IKXCinInputManager
-(id)init {
	if ((self = [super init])) {
		input_string = [NSMutableString new];
		candidate_computer = [IKXCandidateComputer new];
		[candidate_computer startThreadDispatchQueue];
		shown_completion = disallow_completion = [[IKXConfigDictionary() objectForKey:@"DisallowCompletion"] boolValue];
	}
	return self;
}
-(void)dealloc {
	[candidate_computer release];
	[input_string release];
	[super dealloc];
}

-(NSString*)addInput:(NSString*)rawInput flags:(unsigned int)flags point:(CGPoint)pt firstDelete:(unsigned*)charsToDelete fromVariantKey:(BOOL)isVar {
	UIKeyboardImpl* impl = [UIKeyboardImpl sharedInstance];
	*charsToDelete = 0;
	NSString* input = [rawInput lowercaseString];
	unsigned input_length = [input length];
	
	if (wait_for_remaining_input)
		wait_for_remaining_input = NO;
	else if (input_length > 0 && ![impl shouldSkipCandidateSelection]) {
		unichar first_char = [input characterAtIndex:0];
		
		if (flags == 1 || isVar || ![candidate_computer isValidKey:first_char]) {
			[impl acceptCurrentCandidate];
			NSString* stringToAppend = [[self inputString] stringByAppendingString:rawInput] ?: rawInput;
			[self setInput:@""];
			return stringToAppend;			
		} 
		
		bool still_valid = [input_string length] <= valid_input_string_length;
		[input_string appendString:input];
		if (still_valid) {
			if ([candidate_computer containsPrefix:input_string])
				valid_input_string_length += input_length;
			else
				still_valid = false;
		}
		[impl setShift:NO];
		if (still_valid) {
			[candidate_computer prepareCompute];
			[[candidate_computer send] computeWithInputString:[input_string substringToIndex:valid_input_string_length] lastAcceptedCandidate:nil];
		}
	}
	
	shown_completion = NO;
	
	return input;
}
-(NSString*)deleteFromInput:(unsigned*)charsToDelete {
	unsigned input_string_length = [input_string length];
	if (input_string_length > 0) {
		[input_string deleteCharactersInRange:NSMakeRange(input_string_length-1, 1)];
		if (valid_input_string_length == input_string_length) {
			-- valid_input_string_length;
			[candidate_computer prepareCompute];
			[[candidate_computer send] computeWithInputString:[input_string substringToIndex:valid_input_string_length] lastAcceptedCandidate:nil];
		}
	}
	shown_completion = NO;
	*charsToDelete = 1;
	return nil;
}
-(NSUInteger)inputCount { return [input_string length]; }
-(NSUInteger)inputIndex { return [self inputCount]; }
-(NSString*)inputString { return [candidate_computer displayedInputStringOf:input_string]; }
-(void)setInput:(NSString*)input {
	[input_string setString:@""];
	valid_input_string_length = 0;
	[candidate_computer prepareCompute];
	[[candidate_computer send] computeWithInputString:nil lastAcceptedCandidate:nil];
	wait_for_remaining_input = NO;
	shown_completion = NO;
}
-(void)inputLocationChanged { [self clearInput]; }
-(NSString*)remainingInput {
	wait_for_remaining_input = valid_input_string_length > 0;
	return [self inputString];
}
-(BOOL)suppliesCompletions { return YES; }
-(BOOL)usesCandidateSelection { return YES; }
-(BOOL)usesAutoDeleteWord { return NO; }
-(BOOL)shouldExtendPriorWord { return NO; }

-(NSArray*)candidates {
	if ([[UIKeyboardImpl sharedInstance] shouldSkipCandidateSelection])
		return nil;
	
	return [candidate_computer commit];
}
-(void)candidateAccepted:(CandWord*)candidate {
	[candidate_computer prepareCompute];
	
	if (!shown_completion) {
		[input_string deleteCharactersInRange:NSMakeRange(0, valid_input_string_length)];
		NSUInteger final_input_length = valid_input_string_length = [input_string length];
		while (valid_input_string_length > 0) {
			if ([candidate_computer containsPrefix:[input_string substringToIndex:valid_input_string_length]])
				break;
			else
				-- valid_input_string_length;
		}
		NSString* last_accepted_candidate = nil;
		
		if (final_input_length == 0) {
			shown_completion = YES;
			last_accepted_candidate = [candidate word];
		}
		
		[[candidate_computer send] computeWithInputString:[input_string substringToIndex:valid_input_string_length] lastAcceptedCandidate:last_accepted_candidate];

	} else {
		shown_completion = disallow_completion;
		[[candidate_computer send] computeWithInputString:nil lastAcceptedCandidate:nil];
	}
}

-(void)configureKeyboard:(UIKeyboardLayout*)kb forCandidates:(NSArray*)ca {
	if ([ca count] != 0) {
		UIKeyboardImpl* impl = [UIKeyboardImpl sharedInstance];
		
		if (shown_completion) {
			[kb setLabel:UIKeyboardStringDismiss forKey:UIKeyboardKeyReturn];
			[kb setTarget:impl forKey:UIKeyboardKeyReturn];
			[kb setAction:@selector(clearInput) forKey:UIKeyboardKeyReturn];
		} else {
			NSString* confirmKey, *nextKey;
			
			if (IKXConfirmWithSpacePreference()) {
				confirmKey = UIKeyboardKeySpace;
				nextKey = UIKeyboardKeyReturn;
			} else {
				confirmKey = UIKeyboardKeyReturn;
				nextKey = UIKeyboardKeySpace;
			}
				
			[kb setLabel:UIKeyboardStringConfirm forKey:confirmKey];
			[kb setTarget:impl forKey:confirmKey];
			[kb setAction:@selector(acceptCurrentCandidate) forKey:confirmKey];
			
			[kb setLabel:UIKeyboardStringNextCandidate forKey:nextKey];
			[kb setTarget:impl forKey:nextKey];
			[kb setAction:@selector(showNextCandidates) forKey:nextKey];
		}
	}
}

-(NSString*)stringForDoubleKey:(NSString*)key {
	if ([@" " isEqualToString:key])
		return @"。";
	else
		return [super stringForDoubleKey:key];
}

-(CandWord*)defaultCandidate {
	NSArray* allCands = [self candidates];
	if ([allCands count] == 0)
		return nil;
	else
		return [allCands objectAtIndex:0];
}

-(void)setShallowPrediction:(BOOL)shallow {}

-(BOOL)stringEndsWord:(NSString*)str {
	if ([str length] == 0)
		return YES;
	return ![candidate_computer isValidKey:[str characterAtIndex:0]];
}
@end

