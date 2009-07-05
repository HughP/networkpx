/*

MachO_File_ObjC_retrieval ... Retrieve ObjC data from Mach-O file.

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
#include "objc-runtime-new.h"
#include "balanced_substr.h"
#include "string_util.h"
#include <cstring>
#include <cstddef>

using namespace std;

#define PEEK_VM_ADDR(data, type, seg) (this->peek_data_at_vm_address<type>(reinterpret_cast<unsigned>(data), &(m_guess_##seg##_segment)))

void MachO_File_ObjC::adopt_protocols(ClassType& cls, const protocol_list_t* protocols) throw() {
	unsigned start = cls.adopted_protocols.size();
	cls.adopted_protocols.resize(start + protocols->count);
	for (unsigned i = 0; i < protocols->count; ++ i) {
		unsigned index = ma_classes_vm_address_index[reinterpret_cast<unsigned>(protocols->list[i])];
		cls.adopted_protocols[start + i] = index;
		// This will create strong cycles :(
		m_record.add_strong_link(cls.type_index, ma_classes[index].type_index);
	}
}

void MachO_File_ObjC::add_properties(ClassType& cls, const objc_property_list* prop_list) throw() {
	unsigned start = cls.properties.size();
	cls.properties.resize(start + prop_list->count);
	const objc_property* cur_property = &prop_list->first;
	for (unsigned i = 0; i < prop_list->count; ++ i, ++ cur_property) {
		Property& prop = cls.properties[start + prop_list->count - i - 1];	// Note that the initial declaration order is the reverse of layout order.
		
		prop.name = PEEK_VM_ADDR(cur_property->name, char, text);
		
		const char* property_type = PEEK_VM_ADDR(cur_property->attributes, char, text);
		while (*property_type != '\0') {
			switch (*property_type) {
				case 'T': {
					const char* type_start = ++property_type;
					while (*property_type != ',' && *property_type != '\0')
						property_type = skip_balanced_substring(property_type);
					prop.type = m_record.parse(string(type_start, property_type), false);
					m_record.add_strong_link(cls.type_index, prop.type);
					break;
				}
					
				case 'G': {
					prop.has_getter = true;
					const char* getter_start = ++property_type;
					property_type += strcspn(property_type, ",");
					prop.getter = string(getter_start, property_type);
					break;
				}
					
				case 'S': {
					prop.has_setter = true;
					const char* setter_start = ++property_type;
					property_type += strcspn(property_type, ",");
					prop.setter = string(setter_start, property_type);
					break;
				}
					
				case 'C':
					prop.copy = true;
					++ property_type;
					break;
					
				case '&':
					prop.retain = true;
					++ property_type;
					break;
					
				case 'R':
					prop.readonly = true;
					++ property_type;
					break;
					
				case 'N':
					prop.nonatomic = true;
					++ property_type;
					break;
					
				case 'D':
					prop.impl_method = Property::IM_Dynamic;
					++ property_type;
					break;
					
				case 'V': {
					prop.impl_method = Property::IM_Synthesized;
					const char* synth_start = ++property_type;
					property_type += strcspn(property_type, ",");
					prop.synthesized_to = string(synth_start, property_type);
					break;
				}
					
				case 'P':
					prop.gc_strength = Property::GC_Strong;
					++ property_type;
					break;
					
				case 'W':
					prop.gc_strength = Property::GC_Weak;
					++ property_type;
					break;
					
				default:
					++ property_type;
					break;
			}
		}
		
		if (!prop.has_getter)
			prop.getter = prop.name;
		if (!prop.has_setter) {
			prop.setter = "set" + prop.name + ":";
			prop.setter[3] = static_cast<char>(toupper(prop.setter[3]));
		}
	}
}

void MachO_File_ObjC::add_methods(ClassType& cls, const method_list_t* method_list_ptr, bool class_method, bool optional) throw() {
	unsigned start = cls.methods.size();
	cls.methods.resize(start + method_list_ptr->count);
	const method_t* cur_method = &method_list_ptr->first;
	
	for (unsigned i = 0; i < method_list_ptr->count; ++ i, ++ cur_method) {
		Method& method = cls.methods[start + method_list_ptr->count - i - 1];
		method.is_class_method = class_method;
		method.optional = optional;
		
		method.raw_name = PEEK_VM_ADDR(cur_method->name, char, text);
		method.vm_address = reinterpret_cast<unsigned>(cur_method->imp);
		
		// split raw_name into components separated by colons.
		const char* first_colon = method.raw_name;
		const char* prev_colon;
		while (true) {
			prev_colon = first_colon;
			first_colon = strchr(first_colon, ':');
			if (first_colon == NULL)
				break;
			method.components.push_back(string(prev_colon, first_colon));
			++ first_colon;
		}
		
		// split method types into type strings and build strong links.
		const char* method_type = PEEK_VM_ADDR(cur_method->types, char, text);
		while (*method_type != '\0') {
			const char* type_begin = method_type;
			while (!(*method_type >= '0' && *method_type <= '9'))
				method_type = skip_balanced_substring(method_type);
			ObjCTypeRecord::TypeIndex index = m_record.parse(string(type_begin, method_type), false);
			method.types.push_back(index);
			m_record.add_strong_link(cls.type_index, index);
			while (*method_type >= '0' && *method_type <= '9')
				++ method_type;
		}
		
		// from each component, create an argument name.
		method.argname.resize(method.components.size());
		string potential_argname;
		for (unsigned j = 3; j < method.components.size(); ++ j) {
			if (method.components[j].empty())
				// Component is empty. Just call it some generic "arg123". 
				potential_argname = numeric_format("arg%u", j-2);
			else {
				const char* component_c_string = method.components[j].c_str();
				
				// (1) applicationWillTerminate: -> application, etc.
				unsigned modal_verb_length;
				const char* modal_verb_position = find_first_common_modal_word(component_c_string, &modal_verb_length);
				if (modal_verb_position != NULL) {
					if (strncmp(component_c_string, "set", 3) == 0)	// setShouldHandleCookies: -> handleCookies, setAnimationDidStopSelector: -> stopSelector.
						potential_argname = string(modal_verb_position + modal_verb_length);
					else
						potential_argname = string(component_c_string, modal_verb_position);
				}
				
				// (2) actionSheet:didDismissWithButtonIndex: -> buttonIndex, etc.
				else {
					const char* preposition_position = find_word_after_last_common_preposition(component_c_string);
					if (preposition_position != NULL && *preposition_position != '\0')
						potential_argname = string(preposition_position);
				
				// (3) in general, just use the last word.
					else
						potential_argname = last_word_before(component_c_string, component_c_string + method.components[j].size());
				}
			}
			
			lowercase_first_word(potential_argname);
			articlize_keyword(potential_argname);
			
			// search if the argname has been used already. If yes, add a number after it.
			
			bool has_collision;
			do {
				has_collision = false;
				for (unsigned k = 3; k < j; ++ k) {
					if (method.argname[k] == potential_argname) {
						has_collision = true;
						potential_argname += numeric_format("%u", j-2);
						break;
					}
				}
			} while (has_collision);
			
			method.argname[j] = potential_argname;
		}
	}
}

static inline string make_include_path (const char* lib_path) {
	const char* last_slash = strrchr(lib_path, '/');
	if (last_slash == NULL) {
		const char* last_dot = strrchr(lib_path, '.');
		string inc_path = last_dot == NULL ? lib_path : string(lib_path, last_dot);
		return inc_path + ".h";
	} else {
		string inc_path = lib_path;
		size_t last_slash_position = last_slash - lib_path;
		size_t next_last_slash = inc_path.rfind('/', last_slash_position-1);
		if (next_last_slash != string::npos) {
			size_t framework_position = inc_path.find(".framework/", next_last_slash);
			if (framework_position != string::npos) {
				string actual_inc_path = inc_path.substr(next_last_slash+1, framework_position-next_last_slash-1);
				actual_inc_path.push_back('/');
				if (actual_inc_path == "CoreFoundation/")
					actual_inc_path = "Foundation/";
				return actual_inc_path;
			}
		}
		inc_path.erase(0, last_slash_position);
		if (inc_path.substr(0, 3) == "lib")
		inc_path.erase(0, 3);
		size_t last_dot_position = inc_path.rfind('.');
		if (last_dot_position != string::npos)
		inc_path.erase(last_dot_position);
		inc_path += ".h";
		return inc_path;
	}
}

const char* MachO_File_ObjC::get_superclass_name(unsigned superclass_addr, unsigned pointer_to_superclass_addr, ObjCTypeRecord::TypeIndex& superclass_index) throw() {
	if (superclass_addr == 0) {
		// superclass should be an external class. read from relocation entry.
		const char* ext_name = this->string_representation(pointer_to_superclass_addr);
		// strip the _OBJC_CLASS_$_ beginning if there is one.
		if (ext_name != NULL && strncmp(ext_name, "_OBJC_CLASS_$_", strlen("_OBJC_CLASS_$_")) == 0)
			ext_name += strlen("_OBJC_CLASS_$_");
		superclass_index = m_record.add_external_objc_class(ext_name);
		
		const char* lib_path = library_of_relocated_symbol(pointer_to_superclass_addr);
		if (lib_path != NULL)
			ma_include_paths[superclass_index] = make_include_path(lib_path);
		return ext_name;
	} else {
		// superclass should be an internal class. search from vm addresses.
		tr1::unordered_map<unsigned,unsigned>::const_iterator cit = ma_classes_vm_address_index.find(superclass_addr);
		if (cit == ma_classes_vm_address_index.end()) {
			// actually an extenal class :(. Search again from reloc entry.
			const char* ext_name = this->string_representation(superclass_addr);
			if (ext_name != NULL && strncmp(ext_name, "_OBJC_CLASS_$_", strlen("_OBJC_CLASS_$_")) == 0)
				ext_name += strlen("_OBJC_CLASS_$_");
			superclass_index = m_record.add_external_objc_class(ext_name);
			
			const char* lib_path = library_of_relocated_symbol(superclass_addr);
			if (lib_path != NULL)
				ma_include_paths[superclass_index] = make_include_path(lib_path);
			return ext_name;
		} else {
			superclass_index = ma_classes[cit->second].type_index;
			return ma_classes[cit->second].name;
		}
	}
}

//-------------------------------------------------------------------------------------------------------------------------------------------

void MachO_File_ObjC::retrieve_protocol_info() throw() {
	const section* proto_list_section = this->section_having_name("__DATA", "__objc_protolist");
	if (proto_list_section == NULL)
		return;
	
	m_protocol_count = proto_list_section->size / sizeof(const protocol_t*);
	this->seek(proto_list_section->offset + m_origin);
	
	vector<const protocol_t*> all_protocols;
	
#pragma mark Phase 1: Get VM address, build index and get simple properties.
	unsigned proto_start_index = ma_classes.size();
	for (unsigned i = 0; i < m_protocol_count ; ++ i) {
		ClassType cls;
		
		cls.vm_address = this->read_integer();
		const protocol_t* proto = this->peek_data_at_vm_address<protocol_t>(cls.vm_address, &m_guess_data_segment);
		
		if (proto == NULL)
			continue;
		
		cls.name = PEEK_VM_ADDR(proto->name, char, text);
		
		// Make sure the same protocol hasn't been declared.
		for (unsigned j = proto_start_index; j < ma_classes.size(); ++ j) {
			if (ma_classes[j].name == cls.name && ma_classes[j].type == ClassType::CT_Protocol) {
				ma_classes_vm_address_index.insert(pair<unsigned,unsigned>(cls.vm_address, j));
				goto next_protocol;
			}
		}
		
		cls.attributes = 0;
		cls.superclass_name = NULL;
		cls.type_index = m_record.add_objc_protocol(cls.name);
		cls.type = ClassType::CT_Protocol;
		
		all_protocols.push_back(proto);
		
		ma_classes_vm_address_index.insert(pair<unsigned,unsigned>(cls.vm_address, ma_classes.size()));
		ma_classes.push_back(cls);
		
next_protocol:;
	}
	
	m_protocol_count = ma_classes.size() - proto_start_index;
	
	for (unsigned i = 0; i < m_protocol_count; ++ i) {
		const protocol_t* proto = all_protocols[i];
		ClassType& cls = ma_classes[proto_start_index + i];
		
#pragma mark Phase 2: Protocol adoption.
		if (proto->protocols != NULL)
			adopt_protocols(cls, PEEK_VM_ADDR(proto->protocols, protocol_list_t, data));

#pragma mark Phase 3: Declared properties.
		if (proto->instanceProperties != NULL)
			add_properties(cls, PEEK_VM_ADDR(proto->instanceProperties, objc_property_list, data));
		
#pragma mark Phase 4: Methods.
		if (proto->classMethods != NULL)
			add_methods(cls, PEEK_VM_ADDR(proto->classMethods, method_list_t, data), true, false);
		if (proto->instanceMethods != NULL)
			add_methods(cls, PEEK_VM_ADDR(proto->instanceMethods, method_list_t, data), false, false);
		if (proto->optionalClassMethods != NULL)
			add_methods(cls, PEEK_VM_ADDR(proto->optionalClassMethods, method_list_t, data), true, true);
		if (proto->optionalInstanceMethods != NULL)
			add_methods(cls, PEEK_VM_ADDR(proto->optionalInstanceMethods, method_list_t, data), false, true);
	}
}

void MachO_File_ObjC::retrieve_class_info() throw() {
	const section* class_list_section = this->section_having_name("__DATA", "__objc_classlist");
	if (class_list_section == NULL)		
		return;
	
	m_class_count = class_list_section->size / sizeof(const class_t*);
	this->seek(class_list_section->offset + m_origin);
	
	vector<const class_t*> all_class_ptr;
	vector<const class_ro_t*> all_class_data_ptr;
	
#pragma mark Phase 1: Class pointers, data and other necessary preprocessing.
	unsigned class_start_index = ma_classes.size();
	for (unsigned i = 0; i < m_class_count; ++ i) {
		ClassType cls;
		
		cls.vm_address = this->read_integer();
		cls.type = ClassType::CT_Class;
		
		const class_t* class_ptr = this->peek_data_at_vm_address<class_t>(cls.vm_address, &m_guess_data_segment);
		if (class_ptr == NULL)
			continue;
		
		const class_ro_t* class_data_ptr = PEEK_VM_ADDR(class_ptr->data, class_ro_t, data);
		if (class_data_ptr == NULL)
			continue;
		
		all_class_ptr.push_back(class_ptr);
		all_class_data_ptr.push_back(class_data_ptr);
		
		cls.attributes = class_data_ptr->flags;
		cls.name = PEEK_VM_ADDR(class_data_ptr->name, char, text);
		cls.type_index = m_record.add_internal_objc_class(cls.name);
		
		ma_classes_vm_address_index.insert( pair<unsigned,unsigned>(cls.vm_address, ma_classes.size()) );
		ma_classes.push_back(cls);
	}
	
	m_class_count = ma_classes.size() - class_start_index;
	
	for (unsigned i = 0; i < m_class_count; ++ i) {
#pragma mark Phase 2: Superclass.
		ClassType& cls = ma_classes[i + class_start_index];
		const class_t* class_ptr = all_class_ptr[i];
		const class_ro_t* class_data_ptr = all_class_data_ptr[i];
		
		if (cls.attributes & RO_ROOT)
			cls.superclass_name = NULL;
		else {
			ObjCTypeRecord::TypeIndex superclass_index;
			cls.superclass_name = get_superclass_name(reinterpret_cast<unsigned>(class_ptr->superclass), cls.vm_address + offsetof(class_t, superclass), superclass_index);
			m_record.add_strong_class_link(cls.type_index, superclass_index);
		}
		
#pragma mark Phase 3: Protocol adoption.
		if (class_data_ptr->baseProtocols != NULL)
			adopt_protocols(cls, PEEK_VM_ADDR(class_data_ptr->baseProtocols, protocol_list_t, data));
		
#pragma mark Phase 4: Ivars. 
		// Since ivars are unique to classes, we don't write a separate method.
		if (class_data_ptr->ivars != NULL) {
			const ivar_list_t* ivar_ptr = PEEK_VM_ADDR(class_data_ptr->ivars, ivar_list_t, data);
			const ivar_t* cur_ivar = &ivar_ptr->first;
			for (unsigned j = 0; j < ivar_ptr->count; ++ j, ++ cur_ivar) {
				if (cur_ivar->offset == 0)
					continue;				
			
				Ivar ivar;
				ivar.name = PEEK_VM_ADDR(cur_ivar->name, char, text);
				const char* ivar_type = PEEK_VM_ADDR(cur_ivar->type, char, text);
				ivar.type = m_record.parse(ivar_type, true);
				ivar.offset = *PEEK_VM_ADDR(cur_ivar->offset, unsigned, text);
				
				m_record.add_strong_link(cls.type_index, ivar.type);
				
				cls.ivars.push_back(ivar);
			}
		}
		
#pragma mark Phase 5: Declared properties
		if (class_data_ptr->baseProperties != NULL)
			add_properties(cls, PEEK_VM_ADDR(class_data_ptr->baseProperties, objc_property_list, data));

#pragma mark Phase 6: Class methods
		const class_t* metaclass_ptr = PEEK_VM_ADDR(class_ptr->isa, class_t, data);
		const class_ro_t* metaclass_data_ptr = PEEK_VM_ADDR(metaclass_ptr->data, class_ro_t, data);
		if (metaclass_data_ptr->baseMethods != NULL)
			add_methods(cls, PEEK_VM_ADDR(metaclass_data_ptr->baseMethods, method_list_t, data), true, false);
		
#pragma mark Phase 7: Instance methods
		if (class_data_ptr->baseMethods != NULL)
			add_methods(cls, PEEK_VM_ADDR(class_data_ptr->baseMethods, method_list_t, data), false, false);
	}
}

void MachO_File_ObjC::retrieve_category_info() throw() {
	const section* cat_list_section = this->section_having_name("__DATA", "__objc_catlist");
	if (cat_list_section != NULL) {
		unsigned cat_count = cat_list_section->size / sizeof(const category_t*);
		this->seek(cat_list_section->offset + m_origin);
		
		unsigned cat_start_index = ma_classes.size();
		for (unsigned i = 0; i < cat_count; ++ i) {
#pragma mark Phase 1: Get VM address, build index and get simple properties.
			ClassType cls;
			
			cls.vm_address = this->read_integer();
			const category_t* cat = this->peek_data_at_vm_address<category_t>(cls.vm_address, &m_guess_data_segment);
			if (cat == NULL)
				continue;
			
			cls.type = ClassType::CT_Category;
			cls.attributes = 0;
			cls.name = PEEK_VM_ADDR(cat->name, char, text);
			
			unsigned superclass_index;
			cls.superclass_name = get_superclass_name(reinterpret_cast<unsigned>(cat->cls), cls.vm_address + offsetof(category_t, cls), superclass_index);
			cls.type_index = m_record.add_objc_category(cls.name, cls.superclass_name);
			m_record.add_strong_class_link(cls.type_index, superclass_index);
			
#pragma mark Phase 2: Protocol adoption
			if (cat->protocols != NULL)
				adopt_protocols(cls, PEEK_VM_ADDR(cat->protocols, protocol_list_t, data));
			
#pragma mark Phase 3: Declared properties
			if (cat->instanceProperties != NULL)
				add_properties(cls, PEEK_VM_ADDR(cat->instanceProperties, objc_property_list, data));
			
#pragma mark Phase 4: Methods
			if (cat->classMethods != NULL)
				add_methods(cls, PEEK_VM_ADDR(cat->classMethods, method_list_t, data), true, false);
			if (cat->instanceMethods != NULL)
				add_methods(cls, PEEK_VM_ADDR(cat->instanceMethods, method_list_t, data), false, false);
			
			ma_classes_vm_address_index.insert(pair<unsigned,unsigned>(cls.vm_address, ma_classes.size()));
			ma_classes.push_back(cls);
			
		}
		
		m_category_count = ma_classes.size() - cat_start_index;
	}
}
