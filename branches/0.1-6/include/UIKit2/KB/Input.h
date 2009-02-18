#ifndef UIKIT2_KB_INPUT_H
#define UIKIT2_KB_INPUT_H

#include <UIKit2/KB/String.h>
#include <UIKit2/KB/FPoint.h>

namespace KB {
	class Input {
		String m_string;
		unsigned m_unsigned;
		FPoint m_point;
	public:
		Input();
		Input(const String& str, unsigned unk, const FPoint& point);
		Input(const Input&);
		Input& operator= (const Input&);
	};
};


#endif