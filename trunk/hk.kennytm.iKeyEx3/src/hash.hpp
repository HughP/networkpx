/*

hash.hpp ... Serializable hash table.
 
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

#ifndef IKEYEX_HASH_HPP
#define IKEYEX_HASH_HPP

#include <vector>
#include <string>
#include <cstdio>
#include <sys/mman.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <syslog.h>

namespace IKX {
	
	struct CharactersBucket {
		unsigned filled : 8;
		unsigned rank : 24;
		uint16_t chars[2];
		
		CharactersBucket() { std::memset(this, 0, sizeof(*this)); }
		
		uint32_t hash() const {
			return *reinterpret_cast<const uint32_t*>(chars);
		}
		int compare(const CharactersBucket& other) const {
			return std::memcmp(chars, other.chars, sizeof(chars));
		}
		bool operator!= (const CharactersBucket& other) const { return this->compare(other) != 0; }
		bool operator== (const CharactersBucket& other) const { return this->compare(other) == 0; }
	};

	// Ref: http://planetmath.org/encyclopedia/GoodHashTablePrimes.html
	static const size_t _IKX_hash_capacities[] = {
	53, 97, 193, 389, 769, 1543, 3079, 6151, 12289, 24593, 49157, 98317, 199613,
	393241, 786433, 1572869, 3145739, 6291469, 12582917,  25165843, 50331653,
	100663319, 201326611, 402653189, 805306457, 1610612741};
	
	template <typename Self, typename Bucket>
	class CommonHashTable {
	protected:
		bool _valid;
		size_t _size;

	public:
		bool valid() const { return _valid; }
		bool size() const { return _size; }
		
		bool get(Bucket& bucket) const {
			if (!_valid)
				return false;
			
			const Bucket* list = static_cast<const Self*>(this)->bucket_list();
			size_t capac = static_cast<const Self*>(this)->capacity();
			size_t expected_location = bucket.hash() % capac;
			while (true) {
				if (!list[expected_location].filled)
					return false;
				else if (list[expected_location] != bucket) {
					++ expected_location;
					if (expected_location == capac)
						expected_location = 0;
				} else {
					bucket = list[expected_location];
					return true;
				}
			}
		}
	};
	
	template <typename Bucket>
	class WritableHashTable : public CommonHashTable<WritableHashTable<Bucket>, Bucket> {
		std::vector<Bucket> buckets;
		
	public:
		const Bucket* bucket_list() const { return &(buckets.front()); }
		size_t capacity() const { return buckets.size(); }
		
		WritableHashTable(const std::vector<Bucket>& bucket_list) {
			size_t minimum_capacity = bucket_list.size() * 4 / 3;
			size_t actual_capacity = 0;
			for (unsigned i = 0; i < sizeof(_IKX_hash_capacities)/sizeof(size_t); ++ i)
				if (minimum_capacity < _IKX_hash_capacities[i]) {
					actual_capacity = _IKX_hash_capacities[i];
					break;
				}
			if (actual_capacity == 0) {
				syslog(LOG_ERR, "iKeyEx: WTF, your hash table too large!");
				this->_valid = false;
				return;
			}
			
			buckets.resize(actual_capacity);
			
			this->_size = bucket_list.size();
			this->_valid = true;
			
			// Now insert the list to the buckets.
			for (typename std::vector<Bucket>::const_iterator cit = bucket_list.begin(); cit != bucket_list.end(); ++ cit) {
				uint16_t expected_location = cit->hash() % actual_capacity;
				while (buckets[expected_location].filled) {
					++ expected_location;
					if (expected_location == actual_capacity)
						expected_location = 0;
				}
				buckets[expected_location] = *cit;
			}
		}
		
		void write_to_file(const char* filename) const {
			std::FILE* f = std::fopen(filename, "wb");
			
			size_t temp = 2718281828u;
			std::fwrite(&temp, 1, sizeof(size_t), f);
			
			std::fwrite(&this->_size, 1, sizeof(size_t), f);
			
			temp = buckets.size();
			std::fwrite(&temp, 1, sizeof(size_t), f);
			
			std::fwrite(&(buckets.front()), temp, sizeof(Bucket), f);
			
			std::fclose(f);
		}
	};
	
	template <typename Bucket>
	class ReadonlyHashTable : public CommonHashTable<ReadonlyHashTable<Bucket>, Bucket> {
		int fildes;
		size_t filesize;
		void* _map;
		size_t _capacity;
		const Bucket* _buckets;
		
	public:
		const Bucket* bucket_list() const { return _buckets; }
		size_t capacity() const { return _capacity; }
		
		ReadonlyHashTable(const char* filename) {
			fildes = open(filename, O_RDONLY);
			if (fildes < 0) {
				syslog(LOG_WARNING, "iKeyEx failed to open '%s'.", filename);
				return;
			}
			
			struct stat st;
			fstat(fildes, &st);
			filesize = st.st_size;
			
			_map = mmap(NULL, filesize, PROT_READ, MAP_SHARED, fildes, 0);
			
			if (_map == NULL)
				syslog(LOG_WARNING, "iKeyEx failed to map '%s' into memory.", filename);
			else if (*reinterpret_cast<size_t*>(_map) != 2718281828u) {
				syslog(LOG_WARNING, "The file '%s' is not a valid Hash-table cache.", filename);
				munmap(_map, filesize);
			} else
				goto valid;
			
			close(fildes);
			fildes = -1;
			return;
			
		valid:
			const char* _xmap = reinterpret_cast<const char*>(_map);
			_xmap += sizeof(size_t);
			this->_size = *reinterpret_cast<const size_t*>(_xmap);
			_xmap += sizeof(size_t);
			_capacity = *reinterpret_cast<const size_t*>(_xmap);
			_xmap += sizeof(size_t);
			_buckets = reinterpret_cast<const Bucket*>(_xmap);
		}
		
		~ReadonlyHashTable() {
			if (this->_valid) {
				munmap(_map, filesize);
				close(fildes);
			}
		}
	};
}

#endif