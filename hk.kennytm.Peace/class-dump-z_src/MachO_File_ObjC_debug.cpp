/*

MachO_File_ObjC_debug.cpp ... Just for debugging.

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

#include "MachO_File_ObjC.h"
#include <cstdio>

using namespace std;

void MachO_File_ObjC::print_all_types() const throw() {
	printf("// Parsed %lu types.\n\n", static_cast<unsigned long>(m_record.types_count()));
	
	for (unsigned i = 0; i < m_record.types_count(); ++ i) {
		printf("%s;\n", m_record.format(i, "", 0, true, m_dont_typedef).c_str());
	}
	printf("\n");
}

void MachO_File_ObjC::print_extern_symbols() const throw() {
	printf("// Found %lu external symbols.\n\n", ma_include_paths.size());
	
	for (tr1::unordered_map<ObjCTypeRecord::TypeIndex, string>::const_iterator cit = ma_include_paths.begin(); cit != ma_include_paths.end(); ++ cit) {
		std::tr1::unordered_map<ObjCTypeRecord::TypeIndex, const char*>::const_iterator lit = ma_lib_path.find(cit->first);
		printf("%s:\t%s\t(%s)\n", cit->second.c_str(), m_record.name_of_type(cit->first).c_str(), lit == ma_lib_path.end() ? "-" : lit->second);
	}
	printf("\n");
}

namespace {
	struct PCITreeNode {
		PCITreeNode* nextSibling;
		PCITreeNode* firstChild;
		PCITreeNode* lastChild;
		
		const char* name;
		bool isChild;
		
		PCITreeNode(const char* name_) : nextSibling(NULL), firstChild(NULL), lastChild(NULL), name(name_), isChild(false) {}
		
		void print(int level = 1) const throw() {
			for (int i = 0; i < level; ++ i)
				printf("*");
			printf(" [[%s]]\n", name);
			for (const PCITreeNode* child = firstChild; child != NULL; child = child->nextSibling)
				child->print(level + 1);
		}
	};
}

void MachO_File_ObjC::print_class_inheritance() const throw() {
	typedef tr1::unordered_map<ObjCTypeRecord::TypeIndex, PCITreeNode> Tree;
	
	Tree tree;
	
	for (vector<ClassType>::const_iterator cit = ma_classes.begin(); cit != ma_classes.end(); ++ cit) {
		if (cit->type != ClassType::CT_Class)
			continue;
		
		Tree::iterator curnode_iter = tree.insert(Tree::value_type(cit->type_index, PCITreeNode(cit->name))).first;
		
		if (cit->superclass_name != NULL) {
			// The superclass is not yet in the tree. So create an element.
			Tree::iterator super_iter = tree.insert(Tree::value_type(cit->superclass_index, PCITreeNode(cit->superclass_name))).first;
			
			// Append myself to the end of the superclass's list.
			PCITreeNode& n = curnode_iter->second;
			PCITreeNode& s = super_iter->second;
			
			n.isChild = true;
			
			if (s.firstChild == NULL) {
				s.firstChild = &n;
				s.lastChild = &n;
			} else {
				s.lastChild->nextSibling = &n;
				s.lastChild = &n;
			}
		}
	}
	
	// Find all root nodes and print the result.
	for (Tree::iterator tit = tree.begin(); tit != tree.end(); ++ tit) {
		PCITreeNode& r = tit->second;
		if (!r.isChild)
			r.print();
	}
}
