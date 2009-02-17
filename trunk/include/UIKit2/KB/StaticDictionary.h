#ifndef UIKIT2_KB_STATIC_DICTIONARY_H
#define UIKIT2_KB_STATIC_DICTIONARY_H

#include <CoreFoundation/CFArray.h>
#include <UIKit2/KB/String.h>
#include <UIKit2/KB/Word.h>
#include <UIKit2/KB/Vector.h>
#include <UIKit2/KB/WordTrie.h>

namespace KB {
	// sizeof = ???
	class StaticDictionary : public WordTrie {
	protected:
		// void** $vtable @ 0;
		int m_10c0;
	public:
		StaticDictionary();
		virtual ~StaticDictionary();
		
		void unload();
		bool load(const String& path);
		
		void restore_search();
		void save_search();
		
		void charged_key_probabilities(const String&, CFArrayRef) const;
		
		bool contains(const String&, bool) const;
		
		Vector<Word> lookup_suggestions(const String&) const;
		Vector<Word> lookup_candidates(const String&, unsigned, unsigned) const;
	};
	
};
#endif