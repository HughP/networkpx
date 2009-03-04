#ifndef UIKIT2_KB_STRING_H
#define UIKIT2_KB_STRING_H

#include <CoreFoundation/CFString.h>
#include <Foundation/NSString.h>
#include <UIKit2/KB/Vector.h>

typedef unsigned dchar_t;

namespace KB {
	// sizeof = 0x20
	class String {
	public:
		typedef unsigned char StringBufferType;
	protected:
		unsigned short m_size;				// 0
		unsigned short m_capacity;			// 2
		unsigned short m_length;			// 4
		unsigned short m_sort_key_length;	// 6
		StringBufferType m_buffer_type;		// 8
		char* m_buffer;						// c
		char m_static_buffer[16];			// 10
	public:
		String();
		String(const String&);
		String(const char*, unsigned short src_length, unsigned short capacity);
		String(const char*, unsigned short src_length);
		String(StringBufferType, const char*, unsigned short size, unsigned short length, unsigned short sort_key_length);
		String(const char*);
		String(unsigned capacity);
		
		~String();
		
		void clear();
		void compute_sort_key_length();
		void compute_length();
		unsigned size_for_length(unsigned short) const;
		
		char at(unsigned short) const;	// utf8 position.
		char operator[](unsigned short) const;
		char& operator[](unsigned short);
		
		int compare(const String&) const;	// uses strcmp internally.
		
		void in_place_swap(char from, char to);
		
		bool starts_with(const String&, bool is_case_sensitive = true) const;
		bool ends_with(const String&, bool is_case_sensitive = true) const;
		
		UTF32Char character_at(unsigned short) const;
		
		unsigned short find_first_of(const String&, unsigned short start_loc) const;
		bool contains(const String&) const;
		unsigned short find_first_not_of(const String&, unsigned short start_loc) const;
		unsigned short find_last_of(const String&, unsigned short start_loc) const;
		unsigned short find_last_not_of(const String&, unsigned short start_loc) const;
		
		void ensure_capacity(unsigned short);
		void reserve(unsigned short);
		void initialize(const char*, unsigned short src_length, unsigned short capacity);
		void internalize_buffer();
		
		void resize(unsigned short capacity, char filler);
		void append(dchar_t character);
		void append(const char*);
		void append_float(float);	// the float will be formatted to %.2f
		void append(const String&);
		void append(const char*, unsigned short new_capacity);
		
		String& operator+=(dchar_t character);
		String& operator+=(const char*);
		String& operator+=(const String&);
		
		String substr(unsigned short pos, unsigned short length) const;
		String substr_to_pos(unsigned short) const;
		String substr_from_pos(unsigned short) const;
		String substr_chopped(unsigned short length_to_chop) const;
		
		String trim(const String& space) const;	// e.g. "xxx12xx456xxxx".trim("x") == "12xx456"
		String remove(const String&) const;
		
		String operator+(dchar_t character) const;
		String operator+(const char*) const;
		String operator+(const String&) const;
		
		bool equal(const String&, bool is_case_sensitive = true) const;
		
		String& operator=(char);
		String& operator=(const char*);
		String& operator=(const String&);
	};
	
	// sizeof = 0x24
	class UTF8Iterator {
	protected:
		String m_string;
		unsigned short m_position;
		unsigned short m_sort_key_position;
	public:
		UTF8Iterator(const String&);
		void reset();
		dchar_t prev();
		dchar_t next();
	};
	
	bool is_uppercase(dchar_t);
	String substr_to_pos_UTF8(const String&, unsigned short);
	
	String utf8_string(NSString*);
	String utf8_string(CFStringRef);
	CFStringRef cf_string(const String&);
	NSString* ns_string(const String&);	// autorelease'd.
	
	void lower_string(String&);
	void upper_string(String&);
	String lower_character(dchar_t);
	String upper_character(dchar_t);
	
	dchar_t convert_to_ascii(dchar_t);
	bool keyboard_sort_key_match(unsigned char, unsigned char);
	unsigned compute_sort_key(const String&, unsigned char*, int);
	unsigned compute_sort_key(const String&);
	
	bool string_has_accented_roman(const String&);
	bool strings_have_same_accents(const String&, const String&);
	//void* atomize_stem(const String&)
	//bool keyboard_match(const String&, const String&);
	
	
	
};
#endif