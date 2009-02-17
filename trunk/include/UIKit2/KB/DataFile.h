#ifndef UIKIT2_KB_DATAFILE_H
#define UIKIT2_KB_DATAFILE_H

#include <UIKit2/KB/Vector.h>
#include <UIKit2/KB/String.h>
// #include <fcntl.h>
// #include <unistd.h>

namespace KB {
	// sizeof = 0x14.
	class DataFile {
		int m_oflag;			// 0
		mode_t m_mode;		// 4
		bool m_file_opened;	// 8
		int m_file_handle;		// c
		const char* m_filename;	// 10
	public:
		// Note: DataFile opens files using open(), not fopen().
		DataFile(const char* filename, int oflag, mode_t mode);
	};
	
	// sizeof = 0x14 (?)
	class WritableDataFile : public DataFile {
	public:
		typedef int Flags;
		WritableDataFile(const char* filename, Flags flags);
		~WritableDataFile();
		
		// write_data() will write things unformatted.
		void write_data(const char* data, int length);
		// all the following are wrappers to write_data()
		void write_unsigned_char(unsigned char);
		// integers are stored as BIG ENDIAN.
		void write_unsigned_int(unsigned int);
		void write_string(const String&, bool appendNull = false);
	};
	
	// sizeof = 0x28
	class MappedDataFile : public DataFile {
		size_t m_length;		// 14
		size_t m_map_size;		// 18
		int m_protection_mode;	// 1c
		bool m_need_sync;			// 20
		char* m_data;				// 24
	public:
		MappedDataFile(const char* filename, int oflag, mode_t mode, int protection_mode);
		void sync();
		void map(void*);
		bool resize(int);
	};
	
	// sizeof = 0x34
	class ReadOnlyDataFile : public MappedDataFile {
		void (*m_parser)(const ReadOnlyDataFile&, Vector<char*>&);	// 28
		int m_parsed_data_capacity;	// 2c
		char** m_parsed_data;		// 30
	public:
		ReadOnlyDataFile(const char* filename, void(*parser)(const ReadOnlyDataFile&, Vector<char*>&));
		~ReadOnlyDataFile();
		// these are unformatted reads
		String read_null_terminated_string(unsigned offset);
		unsigned read_unsigned_int(unsigned offset);
		unsigned char read_unsigned_char(unsigned offset);
	};
	
	size_t compute_map_length(unsigned);
	void null_parser(const ReadOnlyDataFile&, Vector<char*>&);	// a parser that does nothing.
	
	unsigned int unsigned_int_at(const char*);
};

#endif