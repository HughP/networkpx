/*

MachO_File_ObjC.cpp ... Mach-O file analyzer specialized in Objective-C support.

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
#include <tr1/unordered_map>
#include <tr1/unordered_set>
#include <algorithm>
#include <cstdio>
#include <cstring>
#include <string>
#include <cstddef>
#include <stack>
#include "pseudo_base64.h"
#include <openssl/md5.h>

using namespace std;

MachO_File_ObjC::MachO_File_ObjC(const char* path) throw(std::bad_alloc, TRException) : MachO_File(path), m_guess_data_segment(1), m_guess_text_segment(0), m_class_filter(NULL), m_method_filter(NULL), m_class_filter_extra(NULL), m_method_filter_extra(NULL) {
	retrieve_protocol_info();
	retrieve_class_info();
	retrieve_category_info();
	
	for (vector<ClassType>::iterator it = ma_classes.begin(); it != ma_classes.end(); ++ it)
		tag_propertized_methods(*it);
}

void MachO_File_ObjC::tag_propertized_methods(ClassType& cls) throw() {
	for (vector<Property>::iterator pit = cls.properties.begin(); pit != cls.properties.end(); ++ pit) {
		for (vector<Method>::iterator mit = cls.methods.begin(); mit != cls.methods.end(); ++ mit) {
			// to be a getter, the method must
			// (1) is not optional
			// (2) is not a class method
			// (3) accept no parameters (types.size() == 3)
			// (4) does not return void
			// (5) the raw name is equal to the required getter name.
			// (The first 4 rules are just to filter out unqualified methods quicker) 
			if (mit->propertize_status == Method::PS_None && !mit->optional && !mit->is_class_method && mit->types.size() == 3 && !m_record.is_void_type(mit->types[0]) && pit->getter == mit->raw_name) {
				pit->getter_vm_address = mit->vm_address;
				mit->propertize_status = Method::PS_DeclaredGetter;
				break;
			}
		}
		if (!pit->readonly) {
			for (vector<Method>::iterator mit = cls.methods.begin(); mit != cls.methods.end(); ++ mit) {
				// to be a setter, the method must
				// (1) is not optional
				// (2) is not a class method
				// (3) accept exactly one parameters (types.size() == 4)
				// (4) returns void (not even oneway void)
				// (5) the raw name is equal to the required setter name.
				if (mit->propertize_status == Method::PS_None && !mit->optional && !mit->is_class_method && mit->types.size() == 4 && m_record.is_void_type(mit->types[0]) && pit->setter == mit->raw_name) {
					pit->setter_vm_address = mit->vm_address;
					mit->propertize_status = Method::PS_DeclaredSetter;
					break;
				}
			}
		}
	}
}

void MachO_File_ObjC::propertize(ClassType& cls) throw() {
#pragma mark Phase 1: Propertization by matching setXxx: with xxx or isXxx
	// 1.1. Prepare all setters.
	vector<Method*> potential_setters;
	for (vector<Method>::iterator mit = cls.methods.begin(); mit != cls.methods.end(); ++ mit) {
		if (mit->propertize_status == Method::PS_None && !mit->optional && !mit->is_class_method && mit->types.size() == 4 && m_record.is_void_type(mit->types[0]))
			if (strncmp(mit->raw_name, "set", 3) == 0)
				potential_setters.push_back(&*mit);
	}
	
	// 1.2 Actually do the match.
	string property_name;
	bool has_getter;
	unsigned converted_property_start = cls.properties.size();
	for (vector<Method*>::iterator sit = potential_setters.begin(); sit != potential_setters.end(); ++ sit) {
		size_t potential_name_length = strlen((*sit)->raw_name) - 4;
		const char* potential_name = (*sit)->raw_name + 3;
		
		for (vector<Method>::iterator mit = cls.methods.begin(); mit != cls.methods.end(); ++ mit) {
			if (*sit != &*mit && mit->propertize_status == Method::PS_None && !mit->optional && !mit->is_class_method && mit->types.size() == 3 && mit->types[0] == (*sit)->types[3]) {
				
				if (strncmp(potential_name+1, mit->raw_name+1, potential_name_length-1) == 0 && mit->raw_name[potential_name_length] == '\0') {
					if (potential_name[0] == toupper(mit->raw_name[0])) {
						has_getter = false;
						property_name = mit->raw_name;
						goto phase_1_is_property;
					}
				} else if (strncmp(mit->raw_name, "is", 2) == 0 && strncmp(potential_name+1, mit->raw_name+3, potential_name_length-1) == 0 && mit->raw_name[potential_name_length+2] == '\0') {
					if (potential_name[0] == mit->raw_name[2]) {
						has_getter = true;
						property_name = mit->raw_name+2;
						property_name[0] = static_cast<char>(tolower(property_name[0]));
						goto phase_1_is_property;
					}
				}
				continue;
				
phase_1_is_property:
				Property prop;
				prop.name = property_name;
				prop.has_getter = has_getter;
				prop.getter = mit->raw_name;
				prop.setter = (*sit)->raw_name;
				prop.getter_vm_address = mit->vm_address;
				prop.setter_vm_address = (*sit)->vm_address;
				prop.impl_method = Property::IM_Converted;
				prop.type = mit->types[0];
				prop.retain = m_record.is_id_type(prop.type);
				if (prop.retain && property_name.size() >= strlen("delegate")) {
					string delegate_matcher = property_name.substr(property_name.size() - strlen("delegate"));
					if (delegate_matcher == "Delegate" || delegate_matcher == "delegate")
						prop.retain = false;
				}
				cls.properties.push_back(prop);
				mit->propertize_status = Method::PS_ConvertedGetter;
				(*sit)->propertize_status = Method::PS_ConvertedSetter;
				break;
			}
		}				
	}
	
#pragma mark Phase 2: Propertization by matching readonly 
	string alt_property_name;
	for (vector<Ivar>::const_iterator iit = cls.ivars.begin(); iit != cls.ivars.end(); ++ iit) {
		property_name = iit->name + strspn(iit->name, "_");
		if (property_name.substr(0, 2) == "m_")
			property_name.erase(0, 2);
		
		// If the ivar is an id, there's a chance that a converted property can specialize to it.
		if (m_record.can_dereference_to_id_type(iit->type)) {
			for (unsigned p = converted_property_start; p < cls.properties.size(); ++ p) {
				Property& prop = cls.properties[p];
				if (prop.name == property_name && m_record.are_types_compatible(prop.type, iit->type)) {
					prop.type = iit->type;	// it's ok for us to just move the type because it can never contain a struct. So refcount is unaffected.
					goto phase_2_next_ivar;
				}
			}
		}
		
		alt_property_name = "is" + property_name;
		alt_property_name[2] = static_cast<char>(toupper(alt_property_name[2]));
		
		// Now search for getters.
		for (vector<Method>::iterator mit = cls.methods.begin(); mit != cls.methods.end(); ++ mit) {
			if (mit->propertize_status == Method::PS_None && !mit->optional && !mit->is_class_method && mit->types.size() == 3 && m_record.are_types_compatible(mit->types[0], iit->type)) {
				if (mit->raw_name == property_name)
					has_getter = false;
				else if (mit->raw_name == alt_property_name)
					has_getter = true;
				else
					continue;
				Property prop;
				prop.name = property_name;
				prop.has_getter = has_getter;
				prop.readonly = true;
				prop.getter = mit->raw_name;
				prop.getter_vm_address = mit->vm_address;
				prop.impl_method = Property::IM_Converted;
				prop.type = iit->type;
				prop.retain = m_record.is_id_type(iit->type);
				cls.properties.push_back(prop);
				mit->propertize_status = Method::PS_ConvertedGetter;
				break;
			}
		}
		
phase_2_next_ivar:
		;
	}
}