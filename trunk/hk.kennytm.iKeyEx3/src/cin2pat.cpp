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
#include <fstream>
#include <string>

static wchar_t encode_utf8(const unsigned char x[]) {
	if (0xf0 == (x[0] & 0xf0))
		return ((x[0] & 0x7) << 18) | ((x[1] & 0x3f) << 12) | ((x[2] & 0x3f) << 6) | ((x[3] & 0x3f) << 0);
	else if (0xe0 == (x[0] & 0xe0))
		return ((x[0] & 0xf) << 12) | ((x[1] & 0x3f) << 6) | ((x[2] & 0x3f) << 0);
	else if (0xc0 == (x[0] & 0xc0))
		return ((x[0] & 0x1f) << 6) | ((x[1] & 0x3f) << 0);
	else
		return x[0];
}

extern "C" void IKXConvertCinToPat(const char* cin_path, const char* pat_path) {
	std::ifstream fin (cin_path);
	std::string s;
	IKX::WritablePatTrie<IKX::IMEContent> pat;
	
	bool in_chardef_mode = false;
	while (fin) {
		std::getline(fin, s);
		if (in_chardef_mode) {
			if (s == "%chardef end")
				break;
			
			IKX::IMEContent cont;
			
			size_t first_space_character = s.find_first_of(" \t");
			cont.key.length = std::min(first_space_character, sizeof(cont.key.content));
			std::memcpy(cont.key.content, s.c_str(), cont.key.length);
			size_t first_nonspace_character = s.find_first_not_of(" \t", first_space_character+1);
			cont.value.length = 1;
			cont.value.local_candidates[0] = encode_utf8(reinterpret_cast<const unsigned char*>(s.c_str()) + first_nonspace_character);
			
			pat.insert(cont);
		} else {
			if (s == "%chardef begin")
				in_chardef_mode = true;
		}
	}
	
	pat.write_to_file(pat_path);
}

