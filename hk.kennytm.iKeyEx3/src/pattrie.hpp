/*
 
 pattrie.hpp ... Patricia tree implementation.
 
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

#ifndef IKX_PATTRIE_HPP
#define IKX_PATTRIE_HPP

#include <sys/mman.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <algorithm>
#include <cstring>
#include <vector>
#include <cstdio>
#include <syslog.h>
#include <queue>

namespace IKX {

	#define IKX_THIS static_cast<const Self*>(this)

	template <typename Self, size_t T_bits>
	struct CommonContent {
		template <typename U>
		bool bit (unsigned n, const U& trie) const {
			unsigned the_byte = n / T_bits;
			
			if (the_byte >= IKX_THIS->length())
				return false;
			else
				return (IKX_THIS->key_data(trie)[the_byte] >> (T_bits - 1 - n%T_bits)) & 1;
		}
		
		size_t bit_length() const { return IKX_THIS->length() * T_bits; }
		
		template <typename U>
		size_t first_different_bit(const Self& other, const U& trie) const {
			bool i_am_shorter = IKX_THIS->length() < other.length();
			size_t limit = i_am_shorter ? IKX_THIS->length() : other.length();
			typeof(IKX_THIS->key_data(trie)) my_key_data = IKX_THIS->key_data(trie), other_key_data = other.key_data(trie);
			for (size_t object = 0; object < limit; ++ object) {
				unsigned diff = my_key_data[object] ^ other_key_data[object];
				if (diff) {
					size_t res = __builtin_clz(diff) + T_bits - sizeof(unsigned)*8;
					return object * T_bits + res;
				}
			}
			size_t true_limit = i_am_shorter ? other.length() : IKX_THIS->length();
			typeof(IKX_THIS->key_data(trie)) data = i_am_shorter ? other_key_data : my_key_data;
			for (size_t object = limit; object < true_limit; ++ object) {
				if (data[object]) {
					size_t res = __builtin_clz(data[object]) + T_bits - sizeof(unsigned)*8;
					return object * T_bits + res;
				}
			}
			return true_limit * T_bits;
		}
		
		template <typename U>
		bool equal(const Self& other, const U& trie) const {
			return (IKX_THIS->length() == other.length() &&
					std::memcmp(IKX_THIS->key_data(trie), other.key_data(trie), IKX_THIS->length()*T_bits/8) == 0);
		}
		
		template <typename U>
		bool has_prefix(const Self& other, const U& trie) const {
			return (IKX_THIS->length() >= other.length() &&
					std::memcmp(IKX_THIS->key_data(trie), other.key_data(trie), other.length()*T_bits/8) == 0);
		}
	};

	struct IMEContent : public CommonContent<IMEContent, 8> {
		static const size_t kLocalCandidateStringLength = sizeof(const uint16_t*)/sizeof(uint16_t);
		
		char key_content[9];
		unsigned char key_length : 7;
		
		unsigned char candidate_is_pointer : 1;
		uint16_t candidate_string_length;
		union {
			uint32_t external;
			uint16_t local[kLocalCandidateStringLength];
			const uint16_t* pointer;	// Assume 32-bit system.
		} candidates;
		
		IMEContent() { std::memset(this, 0, sizeof(*this)); }
		size_t length() const { return key_length; }
		
		template <typename U>
		const char* key_data(const U&) const { return key_content; }
		
		template<typename U>
		void append(const IMEContent& other, U& trie) {
			const uint16_t* other_cands = other.candidates_array(trie);
			if (candidate_string_length + other.candidate_string_length < kLocalCandidateStringLength) {
				candidates.local[candidate_string_length] = 0;
				for (unsigned i = 0; i < other.candidate_string_length; ++ i)
					candidates.local[candidate_string_length + 1 + i] = other_cands[i];
			} else if (candidate_string_length <= kLocalCandidateStringLength) {
				candidates.external = trie.append_extra_content(candidates.local, candidate_string_length);
				trie.append_separator_to_extra_content();
				trie.append_extra_content(other_cands, other.candidate_string_length);
			} else {
				uint16_t* tmp = candidate_string_length < 128 ? reinterpret_cast<uint16_t*>(alloca(candidate_string_length*sizeof(uint16_t))) : new uint16_t[candidate_string_length];
				
				std::memcpy(tmp, trie.extra_content() + candidates.external, candidate_string_length*sizeof(uint16_t));
				trie.delete_extra_content(candidates.external, candidate_string_length);
				candidates.external = trie.append_extra_content(tmp, candidate_string_length);
				trie.append_separator_to_extra_content();
				trie.append_extra_content(other_cands, other.candidate_string_length);
				
				if (candidate_string_length >= 128)
					delete[] tmp;
			}
			candidate_string_length += 1 + other.candidate_string_length;
		}
		
		template<typename U>
		const uint16_t* candidates_array(const U& trie) const {
			if (candidate_is_pointer)
				return candidates.pointer;
			if (candidate_string_length <= kLocalCandidateStringLength)
				return candidates.local;
			else
				return trie.extra_content() + candidates.external;
		}
		
		template<typename U>
		void localize(U& trie) {
			if (candidate_is_pointer) {
				candidate_is_pointer = 0;
				if (candidate_string_length <= kLocalCandidateStringLength)
					std::memcpy(candidates.local, candidates.pointer, candidate_string_length * sizeof(uint16_t));
				else
					candidates.external = trie.append_extra_content(candidates.pointer, candidate_string_length);
			}
		}
		
		IMEContent(const uint8_t* key, size_t keylen, const uint16_t* ptr, size_t pxlen) : key_length(std::min(keylen, sizeof(key_content))), candidate_is_pointer(1), candidate_string_length(pxlen) {
			std::memcpy(key_content, key, key_length);
			candidates.pointer = ptr;
		}
		
		IMEContent(const char* key) : key_length(std::min(std::strlen(key), sizeof(key_content))), candidate_is_pointer(0), candidate_string_length(0) {
			std::memcpy(key_content, key, key_length);
		}
		
		bool operator<(const IMEContent& other) const {
			return key_length < other.key_length || (key_length == other.key_length && std::memcmp(key_content, other.key_content, key_length) < 0);
		}
		
		unsigned extra_content_index() const { return !candidate_is_pointer && candidate_string_length > kLocalCandidateStringLength ? candidates.external : ~0u; }
		void set_extra_content_index(unsigned new_index) { candidates.external = new_index; }
		size_t extra_content_length() const { return candidate_string_length; }
	};

	struct PhraseContent : public CommonContent<PhraseContent, 16> {
		static const size_t kLocalCandidateStringLength = sizeof(const uint16_t*)/sizeof(uint16_t);
		
		uint8_t len;
		bool is_pointer;
		__attribute__((packed))
		union {
			uint32_t external;
			uint16_t local[kLocalCandidateStringLength];
			const uint16_t* pointer;
		} phrase;
			
		PhraseContent() { std::memset(this, 0, sizeof(*this)); }
		PhraseContent(const uint16_t* ptr, size_t pxlen) : len(pxlen), is_pointer(true) { phrase.pointer = ptr; }
		size_t length() const { return len; }
		
		template<typename U>
		const uint16_t* key_data(const U& trie) const {
			if (is_pointer)
				return phrase.pointer;
			else if (len <= kLocalCandidateStringLength)
				return phrase.local;
			else
				return trie.extra_content() + phrase.external;
		}
		
		template<typename U>
		void append(const PhraseContent& other, U& trie) {}
		
		unsigned extra_content_index() const { return is_pointer || len <= kLocalCandidateStringLength ? ~0u : phrase.external; }
		void set_extra_content_index(unsigned new_index) { phrase.external = new_index; }
		size_t extra_content_length() const { return len; }
				
		template<typename U>
		void localize(U& trie) {
			if (len <= kLocalCandidateStringLength)
				std::memcpy(phrase.local, phrase.pointer, len * sizeof(uint16_t));
			else
				phrase.external = trie.append_extra_content(phrase.pointer, len);
		}
		
		template<typename U>
		const uint16_t* phrase_string(const U& trie) const {
			return key_data(trie);
		}
	};

	//------------------------------------------------------------------------------------------------------------------------------------------

	typedef size_t Content_ID;

	struct Node {
		typedef unsigned ID;
		static const ID InvalidID = 0xFFFFFF;
		
		unsigned short position : 16;
		__attribute__((packed))
		unsigned left : 24;
		unsigned right : 24;
				
		bool is_data() const { return right == InvalidID; }
		unsigned data() const { return position | left << 16; }
		void set_data(unsigned d) { position = d & 0xFFFF; left = d >> 16; }
		
		Node(unsigned d) : right(InvalidID) { set_data(d); }
	};

	template<typename Self, typename T>
	class CommonPatTrie {
	protected:
		bool calculate_direction(const Node& node, const T& element) const {
			if (node.position < element.bit_length())
				return element.bit(node.position, *IKX_THIS);
			else
				return false;
		}
		
		Node::ID walk(const T& element) const {
			Node::ID cur_node = 0;
			const Node* my_node_list = IKX_THIS->node_list();
			while (true) {
				const Node& node = my_node_list[cur_node];
				if (node.is_data())
					return cur_node;
				else
					cur_node = calculate_direction(node, element) ? node.left : node.right;
			}
		}
		
		Node::ID walk_with_top(const T& element, Node::ID& top) const {
			Node::ID cur_node = top = 0;
			const Node* my_node_list = IKX_THIS->node_list();
			while (true) {
				const Node& node = my_node_list[cur_node];
				if (node.is_data())
					return cur_node;
				else {
					cur_node = calculate_direction(node, element) ? node.left : node.right;
					if (node.position < element.bit_length())
						top = cur_node;
				}
			}
		}
		
	public:
		/// Return a vector of elements that matches the specified prefix.
		std::vector<T> prefix_search(const T& prefix, std::vector<unsigned>* content_indices = NULL) const {
			std::vector<T> retval;
			if (IKX_THIS->node_list_length() != 0) {
				Node::ID top;
				Node::ID p = walk_with_top(prefix, top);
				
				const Node* _node_list = IKX_THIS->node_list();
				const T* _content_list = IKX_THIS->content_list();
				
				if (_content_list[_node_list[p].data()].has_prefix(prefix, *IKX_THIS)) {
					std::queue<const Node*> node_stack;
					node_stack.push(_node_list + top);
					
					while (!node_stack.empty()) {
						const Node* node = node_stack.front();
						node_stack.pop();
						
						if (node->is_data()) {
							retval.push_back(_content_list[node->data()]);
							if (content_indices != NULL)
								content_indices->push_back(node->data());
						} else {
							node_stack.push(_node_list + node->left);
							node_stack.push(_node_list + node->right);
						}
					}
				}
			}
			return retval;
		}
		
		bool contains_prefix(const T& prefix) const {
			if (IKX_THIS->node_list_length() == 0)
				return false;
			else
				return IKX_THIS->content_list()[IKX_THIS->node_list()[walk(prefix)].data()].has_prefix(prefix, IKX_THIS);
		}
		
		bool contains(const T& element, T* result = NULL, unsigned* index = NULL) const {
			if (IKX_THIS->node_list_length() == 0)
				return false;
			else {
				unsigned content_index = IKX_THIS->node_list()[walk(element)].data();
				const T& res = IKX_THIS->content_list()[content_index];
				if (res.equal(element, *IKX_THIS)) {
					if (result != NULL)
						*result = res;
					if (index != NULL)
						*index = content_index;
					return true;
				} else
					return false;
			}
		}
	};

	template<typename T>
	class WritablePatTrie : public CommonPatTrie<WritablePatTrie<T>, T> {
		std::vector<uint16_t> extra_content_list;
		std::vector<Node> nodes;
		std::vector<T> content;
		
	public:
		const Node* node_list() const { return &(nodes.front()); }
		size_t node_list_length() const { return nodes.size(); }
		const T* content_list() const { return &(content.front()); }
		size_t content_list_length() const { return content.size(); }
		
		WritablePatTrie() {}
		
		unsigned append_extra_content(const uint16_t* cnt, size_t length) {
			unsigned retval = extra_content_list.size();
			if (length == 1)
				extra_content_list.push_back(*cnt);
			else
				extra_content_list.insert(extra_content_list.end(), cnt, cnt+length);
			return retval;
		}
		void append_separator_to_extra_content() {
			extra_content_list.push_back(0);
		}
		void delete_extra_content(unsigned index, size_t length) {
			if (extra_content_list.size() == index + length)
				extra_content_list.resize(index);
		}
		void compact_extra_content() {
			std::vector<uint16_t> old_extra_content = extra_content_list;
			extra_content_list.clear();
			for (typename std::vector<T>::iterator it = content.begin(); it != content.end(); ++ it) {
				unsigned old_index = it->extra_content_index();
				if (old_index != ~0u)
					it->set_extra_content_index(append_extra_content(&(old_extra_content[old_index]), it->extra_content_length()));
			}
		}
		const uint16_t* extra_content() const { return &(extra_content_list.front()); }
		
		void insert(const T& element) {
			if (node_list_length() == 0) {
				content.push_back(element);
				nodes.push_back(Node(0));
			} else {
				Node::ID best = walk(element);
				T& k = content[nodes[best].data()];
				size_t crit_bit_pos = element.first_different_bit(k, *this);
				
				if (crit_bit_pos >= std::max(element.bit_length(), k.bit_length())) {
					k.append(element, *this);
					return;
				}
				
				bool elem_bit = element.bit(crit_bit_pos, *this);
				
				nodes.push_back(Node(content.size()));
				content.push_back(element);
//				content.back().localize(*this);
				
				Node::ID p = 0;
				while (true) {
					const Node& q = nodes[p];
					if (q.is_data())
						break;
					if (q.position > crit_bit_pos)
						break;
					p = element.bit(q.position, *this) ? q.left : q.right;
				}
				
				nodes.push_back(nodes[p]);
				Node& p_node = nodes[p];
				(elem_bit ? p_node.right : p_node.left) = nodes.size()-1;
				(elem_bit ? p_node.left : p_node.right) = nodes.size()-2;
				p_node.position = crit_bit_pos;
			}
		}
		
		WritablePatTrie(const char* filename) {
			std::FILE* f = std::fopen(filename, "rb");
			if (f == NULL) {
				syslog(LOG_WARNING, "iKeyEx failed to open '%s'.", filename);
				return;
			}
			
			size_t temp;
			std::fread(&temp, sizeof(size_t), 1, f);
			if (temp != 3141592654u) {
				syslog(LOG_WARNING, "The file '%s' is not a valid Patricia-tree cache.", filename);
				goto done;
			}
			
			std::fread(&temp, sizeof(size_t), 1, f);
			nodes.resize(temp);
			std::fread(&(nodes.front()), sizeof(Node), temp, f);
			
			std::fread(&temp, sizeof(size_t), 1, f);
			content.resize(temp);
			std::fread(&(content.front()), sizeof(T), temp, f);
			
			while (!feof(f)) {
				wchar_t w[256];
				size_t actual = std::fread(w, sizeof(wchar_t), 256, f);
				extra_content_list.insert(extra_content_list.end(), w, w+actual);
			}
			
	done:
			std::fclose(f);
		}
		
		void write_to_file(const char* filename) const {
			std::FILE* f = std::fopen(filename, "wb");
			
			// Magic of our file.
			size_t temp = 3141592654u;
			std::fwrite(&temp, sizeof(size_t), 1, f);
			
			// Nodes.
			temp = nodes.size();
			std::fwrite(&temp, sizeof(size_t), 1, f);
			std::fwrite(&(nodes.front()), sizeof(Node), temp, f);
			
			// Content.
			temp = content.size();
			std::fwrite(&temp, sizeof(size_t), 1, f);
			std::fwrite(&(content.front()), sizeof(T), temp, f);
			
			// Extra contents.
			std::fwrite(&(extra_content_list.front()), sizeof(uint16_t), extra_content_list.size(), f);
			
			std::fclose(f);
		}
	};

	template <typename T>
	class ReadonlyPatTrie : public CommonPatTrie<ReadonlyPatTrie<T>, T> {
		const uint16_t* _extra_content;
		size_t _nodes_size;
		const Node* _nodes;
		size_t _content_size;
		const T* _content;
		
		void* _map;
		int fildes;
		size_t filesize;
		
	public:
		const Node* node_list() const { return _nodes; }
		size_t node_list_length() const { return _nodes_size; }
		const T* content_list() const { return _content; }
		size_t content_list_length() const { return _content_size; }
		
		const uint16_t* extra_content() const { return _extra_content; }
		
		bool valid() const { return fildes >= 0; }
		
		ReadonlyPatTrie(const char* filename) {
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
			else if (*reinterpret_cast<size_t*>(_map) != 3141592654u) {
				syslog(LOG_WARNING, "The file '%s' is not a valid Patricia-tree cache.", filename);
				munmap(_map, filesize);
			} else
				goto valid;
			
			close(fildes);
			fildes = -1;
			return;
				
		valid:
			const char* _xmap = reinterpret_cast<const char*>(_map);
			_xmap += sizeof(size_t);
			_nodes_size = *reinterpret_cast<const size_t*>(_xmap);
			_xmap += sizeof(size_t);
			_nodes = reinterpret_cast<const Node*>(_xmap);
			_xmap += _nodes_size * sizeof(Node);
			_content_size = *reinterpret_cast<const size_t*>(_xmap);
			_xmap += sizeof(size_t);
			_content = reinterpret_cast<const T*>(_xmap);
			_xmap += _content_size * sizeof(T);
			_extra_content = reinterpret_cast<const uint16_t*>(_xmap);
		}
		
		~ReadonlyPatTrie() {
			if (valid()) {
				munmap(_map, filesize);
				close(fildes);
			}
		}
		
	};
}

#endif
#if 0

wchar_t encode_utf8(unsigned char x[]) {
	if (0xf0 == (x[0] & 0xf0))
		return ((x[0] & 0x7) << 18) | ((x[1] & 0x3f) << 12) | ((x[2] & 0x3f) << 6) | ((x[3] & 0x3f) << 0);
	else if (0xe0 == (x[0] & 0xe0))
		return ((x[0] & 0xf) << 12) | ((x[1] & 0x3f) << 6) | ((x[2] & 0x3f) << 0);
	else if (0xc0 == (x[0] & 0xc0))
		return ((x[0] & 0x1f) << 6) | ((x[1] & 0x3f) << 0);
	else
		return x[0];
}

int main(int argc, const char* argv[]) {
	
	/*
	WritablePatTrie<IMEContent> changjie;

	char x[31];
	unsigned char y[4*6];
	
	std::FILE* f = fopen("cj2.cin", "r");
	
	while (!feof(f)) {
		fscanf(f, "%s %s\n", x, y);
		changjie.insert(IMEContent(x, encode_utf8(y)));
	}
	
	fclose(f);
	
	changjie.write_to_file("cj.pat");
	 */
	 
	ReadonlyPatTrie<IMEContent> pat("cj.pat");
	
	std::vector<IMEContent> kl = pat.prefix_search(IMEContent(argv[1], 0));
	if (kl.empty()) {
		printf("Not found.\n");
	} else {
		for (size_t j = 0; j < kl.size(); ++ j) {
			const IMEContent& k = kl[j];
			
			printf("%6.*s: ", k.key.length, k.key.content);
			
			const wchar_t* cand = k.candidates(pat);
			size_t cand_count = k.value.length;
			for (size_t i = 0; i < cand_count; ++ i)
				printf("%04x ", cand[i]);
			printf("\n");
		}
	}
	
	/*
	pat.insert(IMEContent("hello", L'A'));
	pat.insert(IMEContent("hello", L'B'));
	pat.insert(IMEContent("omg", L'C'));
	*/
	
	/*
	std::printf(".%C\n", pat.get_exact(IMEContent("hello", 0))->value.local_candidates[0]);
	std::printf(".%C\n", pat.get_exact(IMEContent("hello", 0))->value.local_candidates[1]);
	
	//	std::printf(".%C\n", pat.get_exact(IMEContent("hell", 0))->value.local_candidates[0]);
	std::printf(".%C\n", pat.get_exact(IMEContent("omg", 0))->value.local_candidates[0]);
	
	// pat.write_to_file("hello.txt");
	 */
	
	return 0;
}

#endif

