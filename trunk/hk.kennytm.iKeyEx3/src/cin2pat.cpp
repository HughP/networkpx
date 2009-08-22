/*

cin2pat.cpp ... Convert a .cin file to Patricia tree dump.
 
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

#include "pattrie.hpp"
#include "cin2pat.h"
#include <fstream>
#include <string>
#include <TextInput/KBWordTrie.hpp>
#include <cstdio>
#include "ConvertUTF.h"
#include "hash.hpp"


extern "C" void IKXConvertCinToPat(const char* cin_path, const char* pat_path, const char* keys_path) {
	std::ifstream fin (cin_path);
	std::string s;
	IKX::WritablePatTrie<IKX::IMEContent> pat;
	
	std::vector<uint16_t> utf16_small_buffer;
	std::vector<std::pair<uint8_t, std::vector<uint16_t> > > keynames;
	
	enum { Default, KeyDef, CharDef } mode = Default;
	while (fin) {
		std::getline(fin, s);
		if (s.empty())
			continue;
		
		if (mode != Default) {
			if (s[0] == '%' && s.substr(s.length()-4) == " end") {
				mode = Default;
				continue;
			}
			
			const uint8_t* cstr = reinterpret_cast<const uint8_t*>(s.c_str());
			const uint8_t* keystr = cstr;
			
			size_t first_space_character = s.find_first_of(" \t");
			size_t first_nonspace_character = s.find_first_not_of(" \t", first_space_character+1);
			
			utf16_small_buffer.resize(s.length()*2);
			uint16_t* small_buffer_begin = &(utf16_small_buffer.front());
			uint16_t* small_buffer_abs_begin = small_buffer_begin;
			uint16_t* small_buffer_end = small_buffer_begin+utf16_small_buffer.size();
			const uint8_t* cstr_end = cstr + s.length();
			cstr += first_nonspace_character;
			ConvertUTF8toUTF16(&cstr, cstr_end, &small_buffer_begin, small_buffer_end, lenientConversion);
			
			if (mode == CharDef) {
				IKX::IMEContent cont (keystr, first_space_character, small_buffer_abs_begin, small_buffer_begin - small_buffer_abs_begin);
				cont.localize(pat);
				
				pat.insert(cont);
			} else if (mode == KeyDef) {
				std::vector<uint16_t> bufcpy(small_buffer_abs_begin, small_buffer_begin);
				keynames.push_back(std::pair<uint8_t, std::vector<uint16_t> >(keystr[0], bufcpy));
			}
			
			
		} else {
			if (s[0] == '%') {
				if (s == "%chardef begin")
					mode = CharDef;
				else if (s == "%keyname begin")
					mode = KeyDef;
			}
		}
	}
	
	pat.compact_extra_content();
	pat.write_to_file(pat_path);
	
	std::FILE* keys_files = std::fopen(keys_path, "wb");
	if (keys_files != NULL) {
		for (std::vector<std::pair<uint8_t, std::vector<uint16_t> > >::const_iterator cit = keynames.begin(); cit != keynames.end(); ++ cit) {
			std::fwrite(&(cit->first), 1, 1, keys_files);
			size_t sz = cit->second.size();
			std::fwrite(&sz, 1, sizeof(size_t), keys_files);
			std::fwrite(&(cit->second.front()), sz, sizeof(uint16_t), keys_files);
		}
		std::fclose(keys_files);
	}
}

extern "C" void IKXConvertPhraseToPat(const char* txt_path, const char* pat_path) {
	std::ifstream fin (txt_path);
	std::vector<uint16_t> utf16_small_buffer;
	IKX::PhraseContent cont;
	std::string s;
	
	IKX::WritablePatTrie<IKX::PhraseContent> pat;
	
	while (fin) {
		getline(fin, s);
		if (s.empty())
			continue;
		
		utf16_small_buffer.resize(s.length()*2);
		uint16_t* small_buffer_begin = &(utf16_small_buffer.front());
		uint16_t* small_buffer_end = small_buffer_begin+utf16_small_buffer.size();
		const uint8_t* cstr = reinterpret_cast<const uint8_t*>(s.c_str());
		const uint8_t* cstr_end = cstr + s.length();
		ConvertUTF8toUTF16(&cstr, cstr_end, &small_buffer_begin, small_buffer_end, lenientConversion);
		
		cont.phrase.pointer = &(utf16_small_buffer.front());
		cont.len = small_buffer_begin - cont.phrase.pointer;
		cont.localize(pat);
				
		pat.insert(cont);
	}
	
	pat.write_to_file(pat_path);
}

extern "C" void IKXConvertPhraseToHash(const char* txt_path, const char* hash_path) {
	std::vector<IKX::CharactersBucket> buckets;
	std::ifstream fin (txt_path);
	std::string s;
	
	IKX::CharactersBucket bucket;
	bucket.rank = 1;
	
	while (fin) {
		getline(fin, s);
		if (s.empty())
			continue;
		
		std::memset(bucket.chars, 0, sizeof(bucket.chars));
		uint16_t* buffer = bucket.chars;
		const uint8_t* cstr = reinterpret_cast<const uint8_t*>(s.c_str());
		
		ConvertUTF8toUTF16(&cstr, cstr + s.length(), &buffer, buffer+sizeof(bucket.chars)/sizeof(uint16_t), lenientConversion);
		
		buckets.push_back(bucket);
		
		bucket.rank += 2;
	}
	
	IKX::WritableHashTable<IKX::CharactersBucket> hash (buckets);
	hash.write_to_file(hash_path);
}

static bool sort_word(const KB::Word& a, const KB::Word& b) {
	int res = a.string().compare(b.string());
	return res < 0 || (res == 0 && a.probability() > b.probability());
}

static bool sort_word_by_freq (const KB::Word& a, const KB::Word& b) {
	float a_prob = a.probability(), b_prob = b.probability();
	return a_prob > b_prob || (a_prob == b_prob && a.string().compare(b.string()) < 0);
}

static bool word_equal(const KB::Word& a, const KB::Word& b) {
	return a.string().equal(b.string());
}

extern "C" void IKXConvertChineseWordTrieToPhrase(const char* dat_path, int longer_than_1, const char* txt_path, const char* alt_txt_path) {
	std::FILE* f = std::fopen(txt_path, "wb");
	if (f == NULL) {
		f = std::fopen(alt_txt_path, "wb");
		if (f == NULL)
			return;
	}
	
	KB::Vector<KB::Word> all_words;
	
	KB::WordTrie wt (dat_path);
	for (char c = 'a'; c <= 'z'; ++ c) {
		wt.set_search(c);
		all_words.concat(wt.words(64));
	}
	
	// Eliminate duplicate values first.
	std::sort(all_words.begin(), all_words.end(), sort_word);
	KB::Vector<KB::Word>::iterator new_iter = std::unique(all_words.begin(), all_words.end(), word_equal);
	all_words.resize(new_iter - all_words.begin());
	std::sort(all_words.begin(), all_words.end(), sort_word_by_freq);
		
	for (KB::Vector<KB::Word>::const_iterator cit = all_words.begin(); cit != all_words.end(); ++ cit) {
		const KB::String& s = cit->string();
		if (longer_than_1 == (s.size()>=4)) {
			fwrite(s.buffer(), 1, s.size(), f);
			fputc('\n', f);
		}
	}
	
	if (longer_than_1) {
		static const char compound_punctuations[] = "⋯⋯\n——\n「」\n《》\n『』\n";
		std::fwrite(compound_punctuations, 1, sizeof(compound_punctuations), f);
	} else {
		static const char punctuations[] = "，\n。\n⋯\n？\n、\n！\n「\n」\n“\n”\n：\n；\n—\n《\n》\n『\n』\n";
		std::fwrite(punctuations, 1, sizeof(punctuations), f);
	}
	
	std::fclose(f);
}

