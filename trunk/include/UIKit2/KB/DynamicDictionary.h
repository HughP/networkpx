#ifndef UIKIT2_KB_DYNAMIC_DICTIONARY_H
#define UIKIT2_KB_DYNAMIC_DICTIONARY_H

#include <CoreFoundation/CFArray.h>
#include <UIKit2/KB/String.h>
#include <UIKit2/KB/Word.h>
#include <UIKit2/KB/Vector.h>
#include <UIKit2/KB/Pair.h>
#include <UIKit2/KB/FPoint.h>

namespace KB {
	// sizeof = ???
	class DynamicDictionary {
	protected:
		DynamicDictionaryImpl* m_impl;
		int m_log_level;
	public:
		DynamicDictionary();
		~DynamicDictionary();
		
		void unload();
		bool load(const String& path);
		bool store();
		void clear();
		
		unsigned short usage_count_at(unsigned) const;
		
		void increase_user_frequency(const String&, bool, bool);
		void decrease_user_frequency(const String&);
		
		? lookup(const String&, const Vector<FPoint>&, bool) const;
		? words_at(unsigned, bool) const;
		? words_with_sort_key(unsigned, bool) const;
		? lookup_offset_for_partial_sort_key(const String&, unsigned, unsigned) const;
		? sort_key_extensions_at(const String&, unsigned, Vector<Pair<unsigned char, unsigned> >&) const;
		bool matches_sort_key_completely_at(const String&, unsigned) const;
		bool suggestable_at(unsigned) const;
	};
	
};
#endif