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

//------------------------------------------------------------------------------

#include "pattrie.hpp"
#include "cin2pat.h"
#include <algorithm>
#include <vector>
#include <functional>
#include <queue>
#include <fstream>
#include <string>
#include <tr1/unordered_map>
#import <Foundation/Foundation.h>
#import "libiKeyEx.h"
#import <UIKit/UIKit-Structs.h>

extern "C" IKXPhraseCompletionTableRef IKXPhraseCompletionTableCreate(NSString* language) {
	NSString* tableName = [[[IKXConfigDictionary() objectForKey:@"phrase"] objectForKey:language] objectAtIndex:0] ?: @"__Internal";
	
	NSString* tableFn = [tableName stringByAppendingPathExtension:@"phrs"];
	NSFileManager* fman = [NSFileManager defaultManager];
	
	NSString* srcPath = [NSString stringWithFormat:IKX_LIB_PATH@"/Phrase/%@/%@", language, tableFn];
	NSString* altPath = [NSString stringWithFormat:IKX_SCRAP_PATH@"/iKeyEx::cache::phrase::%@::%@", language, tableFn];
	if ([fman fileExistsAtPath:altPath]) {
		if ([fman fileExistsAtPath:srcPath])
			[fman removeItemAtPath:altPath error:NULL];
		else {
			if (![fman moveItemAtPath:altPath toPath:srcPath error:NULL])
				srcPath = altPath;
		}
	}
	
	NSString* cachePath = [altPath stringByAppendingPathExtension:@"pat"];
	if (![fman fileExistsAtPath:cachePath]) {
		// Try to create a cache file.
		if (![fman fileExistsAtPath:srcPath]) {
			// Oops even the source is absent. Try to create one if it's an internal table.
			if ([tableName isEqualToString:@"__Internal"]) {
				// Yes it's an internal table. Perform conversion.
				NSString* datFn0 = [NSString stringWithFormat:@"Pinyin-Unigrams-%@", language];
				NSString* phrasePath = [UIKeyboardBundleForInputMode(language) pathForResource:datFn0 ofType:@"dat"];
				IKXConvertChineseWordTrieToPhrase([phrasePath UTF8String], 1, [srcPath UTF8String], [altPath UTF8String]);
				if (![fman fileExistsAtPath:srcPath])
					srcPath = altPath;
			} else {
				// Nothing can be done. Fail.
				NSLog(@"iKeyEx: Error: The file '%@' does not exist. Please check if the config is sane.", srcPath);
				return NULL;
			}
		}
		
		// The srcPath should now confirmed to be exist, or is constructed. Now convert it to pattrie dump.
		IKXConvertPhraseToPat([srcPath UTF8String], [cachePath UTF8String]);
	}
	
	// The cache should now exist. Now just new the pattrie and return.
	return new IKX::ReadonlyPatTrie<IKX::PhraseContent>([cachePath UTF8String]);
}

extern "C" void IKXPhraseCompletionTableDealloc(IKXPhraseCompletionTableRef completionTable) {
	delete completionTable;
}

namespace {
	struct keyed_sorter : public std::binary_function<unsigned, unsigned, bool> {
		const std::vector<unsigned>& pos;
		keyed_sorter(const std::vector<unsigned>& pos_) : pos(pos_) {}
		bool operator()(unsigned x, unsigned y) const {
			return pos[x] < pos[y];
		}
	};
	
	struct PhraseRankPair {
		unsigned _content_index, _resArr_index;
		
		PhraseRankPair(unsigned content_index, unsigned resArr_index) : _content_index(content_index), _resArr_index(resArr_index) {}
		bool operator< (const PhraseRankPair& other) const { return _content_index > other._content_index; }
		unsigned index() const { return _resArr_index; }
	};
}

extern "C" NSArray* IKXPhraseCompletionTableSearch(IKXPhraseCompletionTableRef completionTable, NSString* prefix) {
	if (completionTable == NULL || !completionTable->valid())
		return nil;
	
	std::vector<unsigned> pos;
	
	size_t prefix_len = [prefix length];
	unichar prefix_str[prefix_len];
	[prefix getCharacters:prefix_str];
	IKX::PhraseContent prefix_cont (prefix_str, prefix_len);
	
	std::vector<IKX::PhraseContent> res = completionTable->prefix_search(prefix_cont, &pos);
	
	std::vector<unsigned> iota (res.size());
	for (unsigned i = 0; i < res.size(); ++ i)
		iota[i] = i;
	
	std::sort(iota.begin(), iota.end(), keyed_sorter(pos));
	
	NSMutableArray* resArr = [NSMutableArray arrayWithCapacity:res.size()];
	for (unsigned i = 0; i < res.size(); ++ i) {
		const IKX::PhraseContent& cont = res[iota[i]];
		const uint16_t* complete = cont.key_data(*completionTable);
		[resArr addObject:[NSString stringWithCharacters:complete length:cont.length()]];
	}
	
	return resArr;
}

extern "C" IKXCharacterTableRef IKXCharacterTableCreate(NSString* language) {
	NSString* tableName = [[[IKXConfigDictionary() objectForKey:@"phrase"] objectForKey:language] objectAtIndex:1] ?: @"__Internal";
	
	NSString* tableFn = [tableName stringByAppendingPathExtension:@"chrs"];
	NSFileManager* fman = [NSFileManager defaultManager];
	
	NSString* srcPath = [NSString stringWithFormat:IKX_LIB_PATH@"/Phrase/%@/%@", language, tableFn];
	NSString* altPath = [NSString stringWithFormat:IKX_SCRAP_PATH@"/iKeyEx::cache::phrase::%@::%@", language, tableFn];
	if ([fman fileExistsAtPath:altPath]) {
		if ([fman fileExistsAtPath:srcPath])
			[fman removeItemAtPath:altPath error:NULL];
		else {
			if (![fman moveItemAtPath:altPath toPath:srcPath error:NULL])
				srcPath = altPath;
		}
	}
	
	if (![fman fileExistsAtPath:srcPath]) {
		if ([tableName isEqualToString:@"__Internal"]) {
			NSString* datFn0 = [NSString stringWithFormat:@"singleChar-Unigrams-%@", language];
			NSString* phrasePath = [UIKeyboardBundleForInputMode(language) pathForResource:datFn0 ofType:@"dat"];
			IKXConvertChineseWordTrieToPhrase([phrasePath UTF8String], 0, [srcPath UTF8String], [altPath UTF8String]);
			if (![fman fileExistsAtPath:srcPath])
				srcPath = altPath;
		} else {
			// Nothing can be done. Fail.
			NSLog(@"iKeyEx: Error: The file '%@' does not exist. Please check if the config is sane.", srcPath);
			return NULL;
		}
	}
		
	IKXCharacterTableRef retval = new std::tr1::unordered_map<std::string, unsigned>;
	std::ifstream fin ([srcPath UTF8String]);
	std::string s;
	unsigned i = 0;
	while (fin) {
		std::getline(fin, s);
		if (!s.empty())
			retval->insert(std::pair<std::string, unsigned>(s, i++));
	}
	
	return retval;
}

static NSComparisonResult chars_table_sorter(NSString* a, NSString* b, IKXCharacterTableRef charTable) {
	const char* au = [a UTF8String], *bu = [b UTF8String];
	std::tr1::unordered_map<std::string, unsigned>::const_iterator ait = charTable->find(au), bit = charTable->find(bu);
	
	if (ait == charTable->end()) {
		if (bit == charTable->end())
			return std::strcmp(au, bu);
		else
			return NSOrderedDescending;
	} else if (bit == charTable->end())
		return NSOrderedAscending;
	else {
		return ait->second < bit->second ? NSOrderedAscending : ait->second > bit->second ? NSOrderedDescending : NSOrderedSame;
	}
}

extern "C" void IKXCharacterTableSort(IKXCharacterTableRef charTable, NSMutableArray* chars) {
	if (charTable == NULL || chars == nil || charTable->empty())
		return;
	[chars sortUsingFunction:reinterpret_cast<NSComparisonResult(*)(id,id,void*)>(chars_table_sorter) context:charTable];
	// Remove duplicated values.
	NSMutableIndexSet* indicesToRemove = [NSMutableIndexSet indexSet];
	NSString* lastObject = nil;
	NSUInteger i = 0;
	for (NSString* thisObject in chars) {
		if ([lastObject isEqualToString:thisObject])
			[indicesToRemove addIndex:i];
		++ i;
		lastObject = thisObject;
	}
	[chars removeObjectsAtIndexes:indicesToRemove];
}

extern "C" void IKXCharacterTableDealloc(IKXCharacterTableRef charTable) {
	delete charTable;
}
