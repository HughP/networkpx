#ifndef UIKIT2_KB_WORD_H
#define UIKIT2_KB_WORD_H

#include <UIKit2/KB/String.h>
#include <UIKit2/KB/Vector.h>

namespace KB {
	// sizeof = 0x58
	class Word : public String {
	private:
		String m_20;
		float m_40;
		int m_44;
		unsigned m_flags;
		unsigned m_4c;
		unsigned m_capitalization_flag;
		int m_54;
	public:
		Word();
		Word(const String&);
		Word(const Word&);
		
		void set_custom_capitalization();
		String capitalized_string() const;
		
		static Word empty_word();
		
		Word& operator=(const Word&);
	};
	
	bool word_greater_or_equal_omega(const Word&, const Word&);
	Word word_with_string(const Vector<Word>&, const String&, bool);
	Word word_vector_contains_string(const Vector<Word>&, const String&, bool);
	
};

#endif