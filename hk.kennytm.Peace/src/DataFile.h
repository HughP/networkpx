/*

DataFile.h ... Memory-mapped file class
 
Copyright (C) 2009  KennyTM~

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

#ifndef DATAFILE_H
#define DATAFILE_H

#include <cstdio>
#include <exception>
#include <new>
#include <string>

class TRException : public std::exception {
private:
	char* m_error;
public:
	TRException(const char* format, ...);
	~TRException() throw();
	inline const char* what() const throw() { return m_error; }
};

class DataFile {
protected:
	char* m_data;
	off_t m_filesize;
	int m_fd;
	off_t m_location;
	
public:
	DataFile(const char* path) throw(std::bad_alloc,TRException);
	
	inline const char* data() const throw() { return m_data; }
	inline off_t filesize() const throw() { return m_filesize; }
	
	inline void seek(off_t new_location) throw() { m_location = new_location; }
	inline off_t tell() const throw() { return m_location; }
	inline void advance(off_t delta) throw() { m_location += delta; }
	inline void retreat(off_t neg_delta) throw() { m_location -= neg_delta; }
	inline void rewind() throw() { m_location = 0; }
	
	unsigned read_integer() throw();
	const char* read_string(std::size_t* p_string_length = NULL) throw();
	const char* read_ASCII_string(std::size_t* p_string_length = NULL) throw();
	const char* read_raw_data(std::size_t data_size) throw();
	
	const char* peek_ASCII_Cstring_at(off_t offset, std::size_t* p_string_length = NULL) const throw();
	inline const char* peek_ASCII_Cstring(std::size_t* p_string_length = NULL) const throw() {
		return this->peek_ASCII_Cstring_at(m_location, p_string_length);
	}
	
	template<typename T>
	const T* read_data() throw() {
		m_location += sizeof(T);
		if (m_location <= m_filesize) {
			union {
				const T* as_T_pointer;
				const char* as_char_pointer;
			} res;
			res.as_char_pointer = m_data+m_location-sizeof(T);
			return res.as_T_pointer;
		} else {
			return NULL;
		}

	}
	
	template<typename T>
	T copy_data() throw() { return *(this->read_data<T>()); }
	
	template<typename T>
	inline const T* peek_data(unsigned items_after = 0) throw() {
		if (m_location+static_cast<off_t>(items_after*sizeof(T)) <= m_filesize) {
			union {
				const T* as_T_pointer;
				const char* as_char_pointer;
			} res;
			res.as_char_pointer = m_data + m_location;
			return res.as_T_pointer + items_after;
		} else
			return NULL;
	}	
	
	template<typename T>
	inline const T* peek_data_at(off_t offset) const throw() {
		if (offset+static_cast<off_t>(sizeof(T)) <= m_filesize) {
			union {
				const T* as_T_pointer;
				const char* as_char_pointer;
			} res;
			res.as_char_pointer = m_data + offset;
			return res.as_T_pointer;
		} else
			return NULL;
	}
	
	~DataFile() throw();
};

#endif
