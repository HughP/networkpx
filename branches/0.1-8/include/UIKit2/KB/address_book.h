#ifndef UIKIT2_KB_ADDRESS_BOOK_H
#define UIKIT2_KB_ADDRESS_BOOK_H

#include <UIKit2/KB/String.h>
#include <UIKit2/KB/Hashmap.h>
#include <UIKit2/KB/Vector.h>
#include <CoreFoundation/CFString.h>

namespace KB {
	void fill_contacts(Hashmap<String,int>&, CFStringRef);
	Vector<String> matchable_strings_from_address_book();
};

#endif