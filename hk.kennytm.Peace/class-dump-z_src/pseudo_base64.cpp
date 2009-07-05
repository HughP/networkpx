/*

pseudo_base64.cpp ... Base-64 encoder, uses _ and $ instead of + and /.

Copyright (C) 2009  KennyTM~

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

#include <cstring>
using namespace std;

static const char codepad[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_$";

union CodeBlock {
	struct {
		unsigned int a : 8;
		unsigned int b : 8;
		unsigned int c : 8;
	} as_chars;
	struct {
		unsigned int a : 6;
		unsigned int b : 6;
		unsigned int c : 6;
		unsigned int d : 6;
	} as_codes;
};

void pseudo_base64_encode (const unsigned char* input, size_t length, char* output_buffer) throw() {
	unsigned i = 0;
	for (; i+3 <= length; i += 3) {
		CodeBlock blk;
		blk.as_chars.a = *input++;
		blk.as_chars.b = *input++;
		blk.as_chars.c = *input++;
		*output_buffer++ = codepad[blk.as_codes.a];
		*output_buffer++ = codepad[blk.as_codes.b];
		*output_buffer++ = codepad[blk.as_codes.c];
		*output_buffer++ = codepad[blk.as_codes.d];
	}
	CodeBlock last_block;
	switch (length - i) {
		case 1:
			last_block.as_chars.a = *input++;
			last_block.as_chars.b = 0;
			*output_buffer++ = codepad[last_block.as_codes.a];
			*output_buffer++ = codepad[last_block.as_codes.b];
			break;
		case 2:
			last_block.as_chars.a = *input++;
			last_block.as_chars.b = *input++;
			last_block.as_chars.c = 0;
			*output_buffer++ = codepad[last_block.as_codes.a];
			*output_buffer++ = codepad[last_block.as_codes.b];
			*output_buffer++ = codepad[last_block.as_codes.c];
			break;
		default:
			break;
	}
	*output_buffer = '\0';
}
