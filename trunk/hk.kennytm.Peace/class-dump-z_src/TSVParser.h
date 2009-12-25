/*

TSVParser.h ... Read & write Tab-separated tables.
Copyright (C) 2009  KennyTM~ <kennytm@gmail.com>

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

#include <string>
#include <tr1/unordered_map>
#include <vector>
#include <cstdio>

class TSVFile {
public:
	typedef int TableID;
	static const TableID invalid_table = -1;

	typedef int RowID;
	static const RowID invalid_row = -1;
	
private:	
	struct TSVTable {
		std::string title;
		std::string comment;
		std::tr1::unordered_map<std::string, TSVFile::RowID> row_map;
		std::vector<std::pair<std::vector<std::string>, std::string> > rows;
		
		TSVTable(const std::string& title_) : title(title_) {}
	};
	
	std::tr1::unordered_map<std::string, TableID> table_map;
	std::vector<TSVTable> tables;
	
	RowID add_row_for_table_common(TableID tableID, const std::string& header, const std::vector<std::string>& row, bool* already_exists);
	
public:
	TSVFile(const char* file);
	
	TableID add_table(const std::string& title, bool* already_exists = NULL);
	TableID find_table(const std::string& title) const;
	
	void add_table_comment(TableID tableID, const std::string& comment) { this->tables[tableID].comment += "; " + comment + "\n"; }
	RowID add_row_for_table(TableID tableID, const std::string& header, bool* already_exists = NULL);
	RowID add_row_for_table(TableID tableID, const std::vector<std::string>& row, bool* already_exists = NULL);
	RowID find_row_for_table(TableID tableID, const std::string& header) const;
	void add_row_comment_for_table(TableID tableID, RowID rowID, const std::string& comment) { 
		this->tables[tableID].rows[rowID].second += "; " + comment + "\n";
	}
	
	const std::vector<std::string>& get_row_for_table(TableID table, RowID row) const { return this->tables[table].rows[row].first; }
	std::vector<std::string>& get_row_for_table(TableID table, RowID row) { return this->tables[table].rows[row].first; }
	
	void write(const char* filename) const;
	void write(std::FILE* f) const;
};
