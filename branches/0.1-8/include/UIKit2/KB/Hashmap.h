#ifndef UIKIT2_KB_HASHMAP_H
#define UIKIT2_KB_HASHMAP_H

#include <JavaScriptCore/wtf/HashTraits.h>

namespace KB {
	template<typename K, typename V>
	class Bucket<K,V> {
	};
	
	class IteratorToken {
	};
	
	// sizeof = 0x20.
	template<typename K, typename V>
	class Hashmap<K,V> {
	protected:
		unsigned m_size;			// 0
		unsigned m_capacity;		// 4
		unsigned m_table_size;		// 8
		unsigned m_extra_size;		// c
		unsigned m_extra_index;		// 10
		bool m_rehashing;			// 14
		WTF::HashTraits<K> m_traits;// 16? ORLY?
		Bucket<K,V>* m_table;		// 18
		Bucket<K,V>* m_extra;		// 1C
		
	public:
		template<typename K, typename V>
		bool is_bucket_filled(Bucket<K,V>*) const;
		
		void allocate_fill(unsigned);
		
		Hashmap();
		
		template<typename K, typename V> Bucket<K,V>* take_extra();
		? next_token(IteratorToken) const;
		? begin_token() const;
		? entry_for_token(IteratorToken) const;
		
		void clear();
		void rehash();
		
		template<typename K, typename V> void set(const K&, const V&);
		template<typename K, typename V> V get(const K&);
	};
	
	namespace HashFunctions {
		size_t hash(const char*);
		size_t hash(const String&);
		size_t hash(unsigned);
		size_t hash(const void*);
	}
};

#endif