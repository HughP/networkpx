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

namespace IKX {

	#define IKX_THIS static_cast<const Self*>(this)

	template <typename Self, size_t T_bits>
	struct CommonContent {
		bool bit (unsigned n) const {
			unsigned the_byte = n / T_bits;
			
			if (the_byte >= IKX_THIS->length())
				return false;
			else
				return (IKX_THIS->key_data()[the_byte] >> (T_bits - 1 - n%T_bits)) & 1;
		}
		
		size_t bit_length() const { return IKX_THIS->length() * T_bits; }
		
		size_t first_different_bit(const Self& other) const {
			bool i_am_shorter = IKX_THIS->length() < other.length();
			size_t limit = i_am_shorter ? IKX_THIS->length() : other.length();
			for (size_t object = 0; object < limit; ++ object) {
				unsigned diff = IKX_THIS->key_data()[object] ^ other.key_data()[object];
				if (diff) {
					size_t res = __builtin_clz(diff) + T_bits - sizeof(unsigned)*8;
					return object * T_bits + res;
				}
			}
			size_t true_limit = i_am_shorter ? other.length() : IKX_THIS->length();
			typeof(IKX_THIS->key_data()) data = i_am_shorter ? other.key_data() : IKX_THIS->key_data();
			for (size_t object = limit; object < true_limit; ++ object) {
				if (data[object]) {
					size_t res = __builtin_clz(data[object]) + T_bits - sizeof(unsigned)*8;
					return object * T_bits + res;
				}
			}
			return true_limit * T_bits;
		}
		
		bool operator==(const Self& other) const {
			return (IKX_THIS->length() == other.length() &&
					std::memcmp(IKX_THIS->key_data(), other.key_data(), IKX_THIS->length()*T_bits/8) == 0);
		}
		
		bool has_prefix(const Self& other) const {
			return (IKX_THIS->length() >= other.length() &&
					std::memcmp(IKX_THIS->key_data(), other.key_data(), other.length()*T_bits/8) == 0);
		}
	};

	struct IMEContent : public CommonContent<IMEContent, 8> {
		static const size_t kLocalCandidateLimit = 6;
		
		struct {
			char content[15];
			unsigned char length;
		} key;
		struct {
			size_t length;
			unsigned external_candidates;
			wchar_t local_candidates[kLocalCandidateLimit];
		} value;
		
		IMEContent() { std::memset(this, 0, sizeof(*this)); }
		size_t length() const { return key.length; }
		const char* key_data() const { return key.content; }
		
		template<typename U>
		void append(const IMEContent& other, U& trie) {
			if (value.length < kLocalCandidateLimit-1) {
				value.local_candidates[value.length] = other.value.local_candidates[0];
			} else if (value.length == kLocalCandidateLimit-1) {
				// Move local_candidates to external_candidates.
				value.external_candidates = trie.insert_extra_content(value.local_candidates, kLocalCandidateLimit);
				trie.insert_extra_content(other.value.local_candidates, 1);
			} else
				// FIXME: We assume candidates of the same sequence are grouped together.
				trie.insert_extra_content(other.value.local_candidates, 1);
			++ value.length;
		}
		
		template<typename U>
		const wchar_t* candidates(const U& trie) const {
			if (value.length < kLocalCandidateLimit)
				return value.local_candidates;
			else
				return trie.extra_content() + value.external_candidates;
		}
		
		IMEContent(const char* a, wchar_t b) {
			key.length = std::strlen(a);
			std::memcpy(key.content, a, key.length);
			value.length = 1;
			value.external_candidates = 0;
			value.local_candidates[0] = b;
		}
		
		bool operator<(const IMEContent& other) const {
			return key.length < other.key.length || (key.length == other.key.length && std::memcmp(key.content, other.key.content, key.length) < 0);
		}
	};

	struct PhraseContent : public CommonContent<PhraseContent, 16> {
		uint16_t len;
		uint16_t characters[15];
		
		PhraseContent() { std::memset(this, 0, sizeof(*this)); }
		size_t length() const { return len; }
		const uint16_t* key_data() const { return characters; }
		
		template<typename U>
		void append(const PhraseContent& other, U& trie) {}
	};

	//------------------------------------------------------------------------------------------------------------------------------------------

	typedef size_t Content_ID;

	struct Node {
		typedef unsigned ID;
		static const ID InvalidID = ~0u;
		
		size_t position;
		ID left;
		ID right;
		
		bool is_data() const { return left == InvalidID && right == InvalidID; }
		
		Node(size_t pos = 0, ID l = InvalidID, ID r = InvalidID) : position(pos), left(l), right(r) {}
	};

	template<typename Self, typename T>
	class CommonPatTrie {
	protected:
		bool calculate_direction(const Node& node, const T& element) const {
			if (node.position < element.bit_length())
				return element.bit(node.position);
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
		std::vector<T> prefix_search(const T& prefix, size_t limit = ~0u) const {
			std::vector<T> retval;
			if (IKX_THIS->node_list_length() != 0) {
				Node::ID top;
				Node::ID p = walk_with_top(prefix, top);
				
				const Node* _node_list = IKX_THIS->node_list();
				const T* _content_list = IKX_THIS->content_list();
				
				if (_content_list[_node_list[p].position].has_prefix(prefix)) {
					std::vector<const Node*> node_stack;
					node_stack.push_back(_node_list + top);
					
					while (!node_stack.empty()) {
						const Node* node = node_stack.back();
						node_stack.pop_back();
						
						if (node->is_data()) {
							retval.push_back(_content_list[node->position]);
							if (retval.size() >= limit)
								break;
						} else {
							node_stack.push_back(_node_list + node->left);
							node_stack.push_back(_node_list + node->right);
						}
					}
				}
			}
			return retval;
		}
		
		bool contains(const T& element, T* result = NULL) const {
			if (IKX_THIS->node_list_length() == 0) {
				return false;
			} else {
				Content_ID kid = IKX_THIS->node_list()[walk(element)].position;
				const T& res = IKX_THIS->content_list()[kid];
				if (res == element) {
					if (result != NULL) 
						*result = res;
					return true;
				} else
					return false;
			}
		}
	};

	template<typename T>
	class WritablePatTrie : public CommonPatTrie<WritablePatTrie<T>, T> {
		std::vector<wchar_t> extra_content;
		std::vector<Node> nodes;
		std::vector<T> content;
		
	public:
		const Node* node_list() const { return &(nodes.front()); }
		size_t node_list_length() const { return nodes.size(); }
		const T* content_list() const { return &(content.front()); }
		size_t content_list_length() const { return content.size(); }
		
		WritablePatTrie() {}
		
		unsigned insert_extra_content(const wchar_t* cnt, size_t count) {
			unsigned retval = extra_content.size(); 
			extra_content.reserve(retval + count);
			for (size_t i = 0; i < count; ++ i)
				extra_content.push_back(cnt[i]);
			return retval;
		}
		
		void insert(const T& element) {
			if (node_list_length() == 0) {
				content.push_back(element);
				nodes.push_back(Node(0));
			} else {
				Node::ID best = walk(element);
				T& k = content[nodes[best].position];
				size_t crit_bit_pos = element.first_different_bit(k);
				
				if (crit_bit_pos >= std::max(element.bit_length(), k.bit_length())) {
					k.append(element, *this);
					return;
				}
				
				bool elem_bit = element.bit(crit_bit_pos);
				
				nodes.push_back(Node(content.size()));
				content.push_back(element);
				
				Node::ID p = 0;
				while (true) {
					const Node& q = nodes[p];
					if (q.is_data())
						break;
					if (q.position > crit_bit_pos)
						break;
					p = element.bit(q.position) ? q.left : q.right;
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
			if (temp != 3141526535u) {
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
				extra_content.insert(extra_content.end(), w, w+actual);
			}
			
	done:
			std::fclose(f);
		}
		
		void write_to_file(const char* filename) const {
			std::FILE* f = std::fopen(filename, "wb");
			
			// Magic of our file.
			size_t temp = 3141526535u;
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
			std::fwrite(&(extra_content.front()), sizeof(wchar_t), extra_content.size(), f);
			
			std::fclose(f);
		}
	};

	template <typename T>
	class ReadonlyPatTrie : public CommonPatTrie<ReadonlyPatTrie<T>, T> {
		const wchar_t* _extra_content;
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
		
		const wchar_t* extra_content() const { return _extra_content; }
		
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
			else if (*reinterpret_cast<size_t*>(_map) != 3141526535u) {
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
			_extra_content = reinterpret_cast<const wchar_t*>(_xmap);
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
