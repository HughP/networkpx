/*

crc32.h ... Computes CRC-32 checksum using Red Hat's crc32.c

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

#ifndef CRC32_H
#define CRC32_H

#include <stdint.h>
#include <cstdlib>
#include "pseudo_base64.h"

extern "C" uint32_t crc32 (uint32_t crc, const unsigned char *buf, std::size_t len);

// result should be long enough to hold 11 characters.
void crc32_b64(const char* value, std::size_t length, char* result) {
	uint32_t crc = crc32(0, reinterpret_cast<const unsigned char*>(value), length);
	pseudo_base64_encode(reinterpret_cast<const unsigned char*>(&crc), sizeof(crc), result);
}

#endif