#ifndef UIKIT2_KB_WORD_TRIE_H
#define UIKIT2_KB_WORD_TRIE_H

#ifndef __cplusplus
#warning Please compile with C++!
#endif

#include <JavaScriptCore/wtf/RefPtr.h>
#include <JavaScriptCore/wtf/Vector.h>
#include <UIKit2/KB/String.h>
#include <UIKit2/KB/Word.h>

namespace KB {
	class ReadOnlyDataFile;
	class WordTrie;
	typedef int TrieSearchType;
	
	// sizeof = 0x20
	class WordTrieNode {
		unsigned m_retain_count;		// 0
		ReadOnlyDataFile* m_datafile;	// 4
		char* m_data;					// 8
		const char* m_next;				// c
		unsigned m_search_type;			// 10
		PackedTrieSibling m_sibling;	// 14
		WTF::ListRefPtr<KB::WordTrieNode> m_1c;	// 1c
		
		// 0x18
	 
		WordTrieNode(ReadOnlyDataFile*, const char*, TrieSearchType);
		WordTrieNode();
		WordTrieNode(ReadOnlyDataFile*);
		??? advance(unsigned char, TrieSearchType) const;
	};
	
	// sizeof == 0x50
	class WordTrieSearch {
		WTF::Vector<WTF::RefPtr<KB::WordTrieNode> > m_states;	// 0
	    TrieSearchType m_type;			// c
	    String m_string;	// 10
	    String m_sort_key;	// 30
		
		void clear();
	};
	
	// sizeof == 8
	struct PackedTrieSibling {
		// 0
	    union {
	        unsigned int whole;
	        struct {
				unsigned int child_offset32:21;
			    unsigned int has_words:1;			// 2 (&20)
			    unsigned int has_freq:1;			// 2 (&40)
			    unsigned int more_siblings:1;		// 2 (&80)
			    unsigned int sort_key:8;			// 3
			} fields;
	        struct {
				unsigned int child_offset32:21;
			    unsigned int has_freq_or_words:2;
			    unsigned int more_siblings:1;
			    unsigned int sort_key:8;			// 3
			} file_fields;
	    } sortNchild;
		// 4
	    union {
	        unsigned int whole;
	        struct {
				unsigned int word_offset:23;
			    unsigned int word_is_0freq:1;
			    unsigned int compacted_freq:8;		// 7
			} fields;
	    } freqNword;
		
		const char* parse_trie_sibling_binary(const char*);
	};
	
	// sizeof == 0x908
	class TrieSiblingSparseArrayCache {
	    unsigned m_loaded_from_offset32;	// 0
	    int m_num_tags;						// 4
	    unsigned char m_tag_list[256];		// 8
	    PackedTrieSibling m_values[256];	// 108
		
		void load(const WordTrie&, unsigned offset);
	};
	
	// sizeof = 0x12c4
	class WordTrie {
		ReadOnlyDataFile *m_index;		// 0
		ReadOnlyDataFile *m_words;		// 4
		unsigned m_word_count;			// 8
		WTF::RefPtr<WordTrieNode> m_root;	// c
		WordTrieSearch m_search;			// 10
		WordTrieSearch m_saved_search;		// 60
		bool m_returns_words_shorter_than_search;	// b0
		bool m_valid;								// b1
		TrieSiblingSparseArrayCache m_root_array_cache;	// b4
		TrieSiblingSparseArrayCache m_deep_array_cache;	// 9bc
	public:
		// the first 4 bytes of a WordTrie file must be 00-00-00-01.
		bool magic_number_ok(const ReadOnlyDataFile*) const;
		
		Word word_at(unsigned offset, unsigned& retval) const;
	
		bool perform_match_check_on_words();
		bool string_matches_search(const String&) const;
		
		float probability_sum_for_siblings_at(unsigned offset) const;
		float packed_trie_node_for_sort_key(PackedTrieSibling& sibling, const String& str, unsigned offset, int index = 0) const;
		
		void fill_vector_with_trie_siblings_at(unsigned offset, Vector<DictionaryOffsets>& v) const;
		void add_matching_words_for_node(Vector<Word>&, WordTrieNode*, unsigned, bool) const;
		Vector<Word> words_for_offset(unsigned) const;
		
		void unload();
		
		virtual ~WordTrie();
		WordTrie();
		
		// recursive call involved!
		void recurse_matching_words_for_node(Vector<Word>&, WordTrieNode*, unsigned, bool) const;
		
		Vector<Word> words(int, TrieSearchType);
		Vector<Word> words(TrieSearchType);
		
		void recurse_returning_words_with_constraints(Vector<Word>&, WordTrieNode*, int, unsigned, double, double&);
		
		Vector<Word> words(int, unsigned, double);
		
		void restore_search();
		void save_search();
		void init_search();
		void set_search(const String&, TrieSearchType);
		Word lookup(const String&, TrieSearchType);
		
		// returns successful or not.
		bool load(const String& filename);
		
		WordTrie(const String& filename);
		
	};
	
};

#endif