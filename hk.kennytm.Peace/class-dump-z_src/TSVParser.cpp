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

#include "TSVParser.h"
#include <fstream>
#include <algorithm>
#include <sstream>
#include <iterator>

TSVFile::TableID TSVFile::add_table(const std::string& title, bool* already_exists) {
	std::pair<std::tr1::unordered_map<std::string, TableID>::iterator, bool> ir 
		= this->table_map.insert(std::pair<std::string, TableID>(title, this->tables.size()));
	
	if (already_exists != NULL)
		*already_exists = !ir.second;
	if (ir.second)
		this->tables.push_back(TSVFile::TSVTable(title));
	
	return ir.first->second;
}

TSVFile::TableID TSVFile::find_table(const std::string& title) const {
	std::tr1::unordered_map<std::string, TableID>::const_iterator cit = this->table_map.find(title);
	if (cit == this->table_map.end())
		return TSVFile::invalid_table;
	else
		return cit->second;
}

TSVFile::RowID TSVFile::add_row_for_table_common(TSVFile::TableID tableID, const std::string& header, const std::vector<std::string>& row, bool* already_exists) {
	TSVFile::TSVTable& table = this->tables[tableID];
	std::pair<std::tr1::unordered_map<std::string, RowID>::iterator, bool> ir
		= table.row_map.insert(std::pair<std::string, RowID>(header, table.rows.size()));
	if (already_exists != NULL)
		*already_exists = !ir.second;
	if (ir.second) {
		table.rows.push_back(std::pair<std::vector<std::string>, std::string>(row, ""));
	}
	
	return ir.first->second;	
}

TSVFile::RowID TSVFile::add_row_for_table(TSVFile::TableID tableID, const std::vector<std::string>& row, bool* already_exists) {
	if (row.empty())
		return TSVFile::invalid_row;
	return this->add_row_for_table_common(tableID, row.front(), row, already_exists);
}

TSVFile::RowID TSVFile::add_row_for_table(TSVFile::TableID tableID, const std::string& header, bool* already_exists) {
	return this->add_row_for_table_common(tableID, header, std::vector<std::string>(1, header), already_exists);
}

TSVFile::RowID TSVFile::find_row_for_table(TSVFile::TableID tableID, const std::string& header) const {
	const TSVFile::TSVTable& table = this->tables[tableID];
	std::tr1::unordered_map<std::string, RowID>::const_iterator cit = table.row_map.find(header);
	if (cit == table.row_map.end())
		return TSVFile::invalid_row;
	else
		return cit->second;
}

void TSVFile::write(std::FILE* f) const {
	if (f != NULL) {
		for (std::vector<TSVTable>::const_iterator cit = this->tables.begin(); cit != this->tables.end(); ++ cit) {
			std::fprintf(f, "@%s\n%s", cit->title.c_str(), cit->comment.c_str());
			for (std::vector<std::pair<std::vector<std::string>, std::string> >::const_iterator cit2 = cit->rows.begin(); cit2 != cit->rows.end(); ++ cit2) {
				bool isFirst = true;
				for (std::vector<std::string>::const_iterator cit3 = cit2->first.begin(); cit3 != cit2->first.end(); ++ cit3) {
					if (isFirst)
						isFirst = false;
					else
						std::fputc('\t', f);
					std::fputs(cit3->c_str(), f);
				}
				std::fputc('\n', f);
				std::fputs(cit2->second.c_str(), f);
			}
			std::fputc('\n', f);
		}
		std::fclose(f);		
	}
}

void TSVFile::write(const char* filename) const {
	std::FILE* f = std::fopen(filename, "w");
	if (f != NULL) {
		std::fprintf(f, "; %s: Hints file for class-dump-z\n", filename);
		std::fputs("\n\n", f);
		this->write(f);
		std::fclose(f);
	}
}

TSVFile::TSVFile(const char* filename) {
	if (filename != NULL) {
		std::string s;
		std::ifstream f (filename);
		TSVFile::TableID currentTableID = TSVFile::invalid_table;
		TSVFile::RowID currentRowID = TSVFile::invalid_row;
		std::vector<std::string> row;
		while (!!f) {
			std::getline(f, s);
			size_t l = s.size();
			if (l == 0)
				continue;
			else if (s[0] == ';') {
				if (currentTableID != TSVFile::invalid_table) {
					s.push_back('\n');
					if (currentRowID != TSVFile::invalid_row) {
						// row comment
						this->tables[currentTableID].rows[currentRowID].second += s;
					} else {
						// table comment.
						this->tables[currentTableID].comment += s;
					}
				}
			} else if (s[0] == '@') {
				currentTableID = this->add_table(s.substr(1, l-1));
				currentRowID = TSVFile::invalid_row;
			} else if (currentTableID != TSVFile::invalid_table) {
				row.clear();
				size_t prev_i = 0;
				for (size_t i = 0; i < l; ++ i) {
					if (s[i] == '\t') {
						row.push_back(s.substr(prev_i, i-prev_i));
						prev_i = i+1;
					}
				}
				row.push_back(s.substr(prev_i, l-prev_i));
				
				currentRowID = this->add_row_for_table(currentTableID, row);
			}
		}
	}
}

#ifdef TEST_TSV
int main () {
	TSVFile f ("123.hints");
	f.write(stdout);
	return 0;
}
#endif
