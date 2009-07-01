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

static string synthesize_struct_name (const string& typestr_string, bool is_union) {
	string retstr = (is_union ? "XXAnonymousUnion_" : "XXAnonymousStruct_");
	
	unsigned char md5_string[MD5_DIGEST_LENGTH];
	char md5_string_extracted[MD5_DIGEST_LENGTH*4/3+2];
	MD5(reinterpret_cast<const unsigned char*>(typestr_string.c_str()), typestr_string.size(), md5_string);
	pseudo_base64_encode(md5_string, MD5_DIGEST_LENGTH, md5_string_extracted);
	
	return retstr + md5_string_extracted;
};

#define PEEK_VM_ADDR(data, type, seg) (this->peek_data_at_vm_address<type>(reinterpret_cast<unsigned>(data), &(guess_##seg##_segment)))

MachO_File_ObjC::MachO_File_ObjC(const char* path) throw(std::bad_alloc, TRException) : MachO_File(path) {
	const section* class_list_section = this->section_having_name("__DATA", "__objc_classlist");
	if (class_list_section == NULL)
		throw TRException("The file '%s' does not contain the (__DATA,__objc_classlist) section. If the file contains uses __OBJC segment, or only has categories/protocols, you should use class-dump-x instead.", path);
	unsigned class_count = class_list_section->size / sizeof(const class_t*);
	
	vector<unsigned> ivar_init_offsets;
	tr1::unordered_map<unsigned, unsigned> all_class_def_indices;	// vmaddr -> protocol.
	
	int guess_data_segment = 1, guess_text_segment = 0;
	
	vector<const class_t*> all_classes;
	vector<const class_ro_t*> all_class_data;
	tr1::unordered_map<unsigned, const protocol_t*> all_protocols;
	
	vector<vector<string> > all_property_getters, all_property_setters;
	vector<vector<const char*> > all_instance_method_names, all_instance_method_types;	// used to merge getters & setters into ObjC2 properties (phase 11).
	vector<vector<const char*> > all_ivar_types;	// used to build usage network (phase 14)
	
	//--- PART I: RAW DATA RETRIEVAL ---//
	{
	
		this->seek(class_list_section->offset + m_origin);
		
		// Phase 1: Class pointers, data and other easily obtained info.
		for (unsigned i = 0; i < class_count; ++ i) {
			ClassDefinition clsDef;
			
			// 1.1: Get class pointer.
			unsigned class_vm_addr = this->read_integer();
			const class_t* class_ptr = this->peek_data_at_vm_address<class_t>(class_vm_addr, &guess_data_segment);
			all_classes.push_back(class_ptr);
			all_class_def_indices.insert(pair<unsigned,unsigned>(class_vm_addr, class_count-1-i));
			
			// 1.2: Get class data.
			clsDef.vm_address = class_vm_addr;
			clsDef.isProtocol = false;
			clsDef.isCategory = false;
			
			const class_ro_t* class_data_ptr = PEEK_VM_ADDR(class_ptr->data, class_ro_t, data);
			all_class_data.push_back(class_data_ptr);
			
			clsDef.attributes = class_data_ptr->flags;
			clsDef.name = PEEK_VM_ADDR(class_data_ptr->name, char, text);
			ma_recognized_classes.insert(string(clsDef.name));
			
			// 1.3 Adopted protocols
			if (class_data_ptr->baseProtocols != NULL) {
				const protocol_list_t* protos = PEEK_VM_ADDR(class_data_ptr->baseProtocols, protocol_list_t, data);
				clsDef.adopted_protocols = vector<unsigned>(reinterpret_cast<const unsigned*>(&(protos->list)), reinterpret_cast<const unsigned*>(&(protos->list)) + protos->count);
			}
			
			ivar_init_offsets.push_back(class_data_ptr->instanceStart);
			ma_classes.push_back(clsDef);
		}
		
		// reverse the vectors because the classes are usually stored in reverse definition order.
		reverse(all_classes.begin(), all_classes.end());
		reverse(ivar_init_offsets.begin(), ivar_init_offsets.end());
		reverse(all_class_data.begin(), all_class_data.end());
		reverse(ma_classes.begin(), ma_classes.end());
		
		// Phase 2: Super class.
		for (unsigned i = 0; i < class_count; ++ i) {		
			const class_ro_t* class_data_ptr = all_class_data[i];
			ClassDefinition& clsDef = ma_classes[i];
			// No name if it's root class.
			if (class_data_ptr->flags & RO_ROOT)
				clsDef.superclass_name = NULL;
			else {
				clsDef.superclass_name = this->get_superclass_name(reinterpret_cast<unsigned>(all_classes[i]->superclass), clsDef.vm_address + offsetof(class_t, superclass), all_class_def_indices);
			}
		}
		
		// Phase 3: Ivars.
		all_ivar_types.resize(class_count);
		for (unsigned i = 0; i < class_count; ++ i) {
			const class_ro_t* class_data_ptr = all_class_data[i];
			ClassDefinition& clsDef = ma_classes[i];
			
			unsigned bit_count = 0;
			
			unsigned ivar_address = reinterpret_cast<unsigned>(class_data_ptr->ivars);
			if (ivar_address != 0) {
				const ivar_list_t* ivar_ptr = this->peek_data_at_vm_address<ivar_list_t>(ivar_address);
				
				unsigned current_offset = ivar_init_offsets[i];
				
				unsigned dummy;
				
				const ivar_t* cur_ivar = &ivar_ptr->first;
				for (unsigned j = 0; j < ivar_ptr->count; ++ j) {
					if (cur_ivar->offset == 0)
						continue;
					
					const char* ivar_type = PEEK_VM_ADDR(cur_ivar->type, char, text);
					string declaration = decode_type( ivar_type , dummy, PEEK_VM_ADDR(cur_ivar->name, char, text), false, 1 );
					all_ivar_types[i].push_back(ivar_type);
					
					// some wierd bit field can have -1 alignment.
					if (cur_ivar->alignment == ~0u) {
						unsigned bit_size = 0;
						sscanf(ivar_type, "b%u", &bit_size);
						bit_count += bit_size;
					} else {
						unsigned alignment = 1 << cur_ivar->alignment;
						current_offset = ((current_offset-1) & ~(alignment-1)) + alignment;
						bit_count = cur_ivar->size * 8;
					}
					
					clsDef.ivar_declarations.push_back(declaration);
					clsDef.ivar_offsets.push_back(current_offset);
					
					current_offset += bit_count / 8;
					bit_count %= 8;
					
					++ cur_ivar;
				}
			} 
		}
		
		// Phase 4: Declared properties.
		for (unsigned i = 0; i < class_count; ++ i) {
			const class_ro_t* class_data_ptr = all_class_data[i];
			ClassDefinition& clsDef = ma_classes[i];
			
			vector<string> property_getters, property_setters;
			
			unsigned properties_address = reinterpret_cast<unsigned>(class_data_ptr->baseProperties);
			if (properties_address != 0) {
				const objc_property_list* properties_ptr = this->peek_data_at_vm_address<objc_property_list>(properties_address, &guess_data_segment);
				const objc_property* cur_property = &properties_ptr->first;
				for (unsigned j = 0; j < properties_ptr->count; ++ j, ++ cur_property) {
					this->obtain_properties(cur_property, guess_text_segment, clsDef.property_names, clsDef.property_prefixes, property_getters, property_setters);
					clsDef.property_getter_address.push_back(0);
					clsDef.property_setter_address.push_back(0);
				}
			}
			
			clsDef.converted_property_start = clsDef.property_prefixes.size();
					
			all_property_getters.push_back(property_getters);
			all_property_setters.push_back(property_setters);
		}
		
		// Phase 5: Class methods.
		for (unsigned i = 0; i < class_count; ++ i) {
			const class_t* metaclass_ptr = PEEK_VM_ADDR(all_classes[i]->isa, class_t, data);
			const class_ro_t* metaclass_data_ptr = PEEK_VM_ADDR(metaclass_ptr->data, class_ro_t, data);
			ClassDefinition& clsDef = ma_classes[i];
			
			unsigned method_list_address = reinterpret_cast<unsigned>(metaclass_data_ptr->baseMethods);
			if (method_list_address != 0) {
				const method_list_t* method_list_ptr = this->peek_data_at_vm_address<method_list_t>(method_list_address, &guess_data_segment);
				const method_t* cur_method = &method_list_ptr->first;
				for (unsigned j = 0; j < method_list_ptr->count; ++ j, ++ cur_method) {
					clsDef.method_vm_addresses.push_back(reinterpret_cast<unsigned>(cur_method->imp));
					const char* method_name = PEEK_VM_ADDR(cur_method->name, char, text);
					const char* method_type = PEEK_VM_ADDR(cur_method->types, char, text);
					clsDef.method_declarations.push_back(analyze_method(method_name, method_type, "+("));
				}
			}
			
			clsDef.optional_class_method_start = -1;
			clsDef.optional_instance_method_start = -1;
			clsDef.instance_method_start = clsDef.method_declarations.size();
		}
		
		// Phase 6: Instance methods.
		for (unsigned i = 0; i < class_count; ++ i) {
			const class_ro_t* class_data_ptr = all_class_data[i];
			ClassDefinition& clsDef = ma_classes[i];
			unsigned method_list_address = reinterpret_cast<unsigned>(class_data_ptr->baseMethods);
			
			vector<const char*> instance_method_names, instance_method_types;
			
			const vector<string>& property_getters = all_property_getters[i];
			const vector<string>& property_setters = all_property_setters[i];
			
			if (method_list_address != 0) {
				const method_list_t* method_list_ptr = this->peek_data_at_vm_address<method_list_t>(method_list_address);
				const method_t* cur_method = &method_list_ptr->first;
				
				for (unsigned j = 0; j < method_list_ptr->count; ++ j, ++ cur_method) {
					clsDef.method_vm_addresses.push_back(reinterpret_cast<unsigned>(cur_method->imp));
					const char* method_name = PEEK_VM_ADDR(cur_method->name, char, text);
					const char* method_type = PEEK_VM_ADDR(cur_method->types, char, text);
					
					instance_method_names.push_back(method_name);
					instance_method_types.push_back(method_type);
					
					string method_decl;
					size_t method_type_length = strlen(method_type);
					
					// check if it is a potential property getter.
					if (!property_getters.empty()) {
						// a method that have no input and returns nothing is probably a getter.
						if (method_type_length >= 6 && strcmp(method_type+method_type_length-5, "8@0:4") == 0 && method_type[0] != 'v' && method_type[0] != 'V') {
							for (vector<string>::const_iterator cit = property_getters.begin(); cit != property_getters.end(); ++ cit) {
								if (method_name == *cit) {
									instance_method_types.back() = NULL;
									method_decl.append("// declared property getter: ");
									clsDef.property_getter_address[cit - property_getters.begin()] = reinterpret_cast<unsigned>(cur_method->imp);
									goto found_getter_or_setter;
								}
							}
						}
					}
					
					// now do the same for setters.
					if (!property_setters.empty()) {
						if (method_type_length >= 8 && (method_type[0] == 'v' || method_type[0] == 'V') && method_type[method_type_length-1] == '8' && !(method_type[method_type_length-2] >= '0' && method_type[method_type_length-2] <= '9')) {
							for (vector<string>::const_iterator cit = property_setters.begin(); cit != property_setters.end(); ++ cit) {
								if (method_name == *cit) {
									instance_method_types.back() = NULL;
									method_decl.append("// declared property setter: ");
									clsDef.property_setter_address[cit - property_setters.begin()] = reinterpret_cast<unsigned>(cur_method->imp);
									goto found_getter_or_setter;
								}
							}
						}
					}
					
					
	found_getter_or_setter:
					method_decl.append(analyze_method(method_name, method_type, "-("));
					clsDef.method_declarations.push_back(method_decl);
				}
			}
			
			all_instance_method_names.push_back(instance_method_names);
			all_instance_method_types.push_back(instance_method_types);
		}
		
		// Phase 7: Take a tea break.
		
		// Phase 8: Protocols (if exists).
		const section* proto_list_section = this->section_having_name("__DATA", "__objc_protolist");
		if (proto_list_section != NULL) {
			unsigned proto_count = proto_list_section->size / sizeof(const protocol_t*);
			this->seek(proto_list_section->offset + m_origin);
			
			for (unsigned i = 0; i < proto_count; ++ i) {
				unsigned proto_vm_addr = this->read_integer();
				
				vector<string> property_getters, property_setters;
				unsigned properties_address;
				
				const protocol_t* proto = this->peek_data_at_vm_address<protocol_t>(proto_vm_addr, &guess_data_segment);
				ClassDefinition protoDef;
				protoDef.isProtocol = true;
				protoDef.isCategory = false;
				
				// 8.1. Name.
				protoDef.name = PEEK_VM_ADDR(proto->name, char, text);
				protoDef.superclass_name = NULL;
				
				// Make sure the same protocol hasn't been declared.
				unsigned idx = ma_classes.size()-1;
				for (vector<ClassDefinition>::const_reverse_iterator crit = ma_classes.rbegin(); crit != ma_classes.rend(); ++ crit, --idx)
					if (crit->name == protoDef.name) {
						all_class_def_indices.insert(pair<unsigned,unsigned>(proto_vm_addr, idx));
						goto next_protocol;
					}
				
				all_class_def_indices.insert(pair<unsigned,unsigned>(proto_vm_addr, ma_classes.size()));
				
				// 8.2 Adopted protocols.
				if (proto->protocols != NULL) {
					const protocol_list_t* protos = PEEK_VM_ADDR(proto->protocols, protocol_list_t, data);
					protoDef.adopted_protocols = vector<unsigned>(reinterpret_cast<const unsigned*>(&(protos->list)), reinterpret_cast<const unsigned*>(&(protos->list)) + protos->count);
				}
				// 8.3 Declared properties.
				properties_address = reinterpret_cast<unsigned>(proto->instanceProperties);
				if (properties_address != 0) {
					const objc_property_list* properties_ptr = this->peek_data_at_vm_address<objc_property_list>(properties_address, &guess_data_segment);
					const objc_property* cur_property = &properties_ptr->first;
					for (unsigned j = 0; j < properties_ptr->count; ++ j, ++ cur_property)
						this->obtain_properties(cur_property, guess_text_segment, protoDef.property_names, protoDef.property_prefixes, property_getters, property_setters);
				}
				protoDef.converted_property_start = protoDef.property_prefixes.size();
				
				// 8.4 Methods.
				{
					vector<const char*> instance_method_names, instance_method_types;
					
					// 8.4.1 Required class methods
					unsigned method_list_address = reinterpret_cast<unsigned>(proto->classMethods);
					if (method_list_address != 0) {
						const method_list_t* method_list_ptr = this->peek_data_at_vm_address<method_list_t>(method_list_address);
						const method_t* cur_method = &method_list_ptr->first;
						
						for (unsigned j = 0; j < method_list_ptr->count; ++ j, ++ cur_method) {
							protoDef.method_vm_addresses.push_back(reinterpret_cast<unsigned>(cur_method->imp));
							const char* method_name = PEEK_VM_ADDR(cur_method->name, char, text);
							const char* method_type = PEEK_VM_ADDR(cur_method->types, char, text);
							protoDef.method_declarations.push_back(analyze_method(method_name, method_type, "+("));
						}
					}
					protoDef.optional_class_method_start = protoDef.method_declarations.size();
					
					// 8.4.2. Optional class methods
					method_list_address = reinterpret_cast<unsigned>(proto->optionalClassMethods);
					if (method_list_address != 0) {
						const method_list_t* method_list_ptr = this->peek_data_at_vm_address<method_list_t>(method_list_address);
						const method_t* cur_method = &method_list_ptr->first;
						
						for (unsigned j = 0; j < method_list_ptr->count; ++ j, ++ cur_method) {
							protoDef.method_vm_addresses.push_back(reinterpret_cast<unsigned>(cur_method->imp));
							const char* method_name = PEEK_VM_ADDR(cur_method->name, char, text);
							const char* method_type = PEEK_VM_ADDR(cur_method->types, char, text);
							protoDef.method_declarations.push_back(analyze_method(method_name, method_type, "+("));
						}
					}
					protoDef.instance_method_start = protoDef.method_declarations.size();
					
					// 8.4.3 Required instance methods
					method_list_address = reinterpret_cast<unsigned>(proto->instanceMethods);
					if (method_list_address != 0) {
						const method_list_t* method_list_ptr = this->peek_data_at_vm_address<method_list_t>(method_list_address);
						const method_t* cur_method = &method_list_ptr->first;
						
						for (unsigned j = 0; j < method_list_ptr->count; ++ j, ++ cur_method) {
							protoDef.method_vm_addresses.push_back(reinterpret_cast<unsigned>(cur_method->imp));
							const char* method_name = PEEK_VM_ADDR(cur_method->name, char, text);
							const char* method_type = PEEK_VM_ADDR(cur_method->types, char, text);
							
							string method_decl;
							size_t method_type_length = strlen(method_type);
							
							instance_method_names.push_back(method_name);
							instance_method_types.push_back(method_type);
							
							// check if it is a potential property getter.
							if (!property_getters.empty()) {
								// a method that have no input and returns nothing is probably a getter.
								if (method_type_length >= 6 && strcmp(method_type+method_type_length-5, "8@0:4") == 0 && method_type[0] != 'v' && method_type[0] != 'V') {
									for (vector<string>::const_iterator cit = property_getters.begin(); cit != property_getters.end(); ++ cit) {
										if (method_name == *cit) {
											instance_method_types.back() = NULL;
											method_decl.append("// declared property getter: ");
											goto found_getter_or_setter_a;
										}
									}
								}
							}
							
							// now do the same for setters.
							if (!property_setters.empty()) {
								if (method_type_length >= 8 && (method_type[0] == 'v' || method_type[0] == 'V') && method_type[method_type_length-1] == '8' && !(method_type[method_type_length-2] >= '0' && method_type[method_type_length-2] <= '9')) {
									for (vector<string>::const_iterator cit = property_setters.begin(); cit != property_setters.end(); ++ cit) {
										if (method_name == *cit) {
											instance_method_types.back() = NULL;
											method_decl.append("// declared property setter: ");
											goto found_getter_or_setter_a;
										}
									}
								}
							}
							
						found_getter_or_setter_a:
							method_decl.append(analyze_method(method_name, method_type, "-("));
							protoDef.method_declarations.push_back(method_decl);
						}
					}
					protoDef.optional_instance_method_start = protoDef.method_declarations.size();
					
					// 8.4.4 Optional instance methods
					method_list_address = reinterpret_cast<unsigned>(proto->optionalInstanceMethods);
					if (method_list_address != 0) {
						const method_list_t* method_list_ptr = this->peek_data_at_vm_address<method_list_t>(method_list_address);
						const method_t* cur_method = &method_list_ptr->first;
						
						for (unsigned j = 0; j < method_list_ptr->count; ++ j, ++ cur_method) {
							// Optional methods cannot be turned into properties :(
							protoDef.method_vm_addresses.push_back(reinterpret_cast<unsigned>(cur_method->imp));
							const char* method_name = PEEK_VM_ADDR(cur_method->name, char, text);
							const char* method_type = PEEK_VM_ADDR(cur_method->types, char, text);
							protoDef.method_declarations.push_back(analyze_method(method_name, method_type, "-("));
						}
					}
					
					all_instance_method_names.push_back(instance_method_names);
					all_instance_method_types.push_back(instance_method_types);
				}
				
				ma_classes.push_back(protoDef);
next_protocol:
				;
			}
		}
		
		// Phase 9: Categories (if exists).
		const section* cat_list_section = this->section_having_name("__DATA", "__objc_catlist");
		if (cat_list_section != NULL) {
			unsigned cat_count = cat_list_section->size / sizeof(const category_t*);
			this->seek(cat_list_section->offset + m_origin);
			
			for (unsigned i = 0; i < cat_count; ++ i) {
				unsigned cat_vm_addr = this->read_integer();
				all_class_def_indices.insert(pair<unsigned,unsigned>(cat_vm_addr, ma_classes.size()));
				
				const category_t* cat = this->peek_data_at_vm_address<category_t>(cat_vm_addr, &guess_data_segment);
				ClassDefinition catDef;
				catDef.isProtocol = false;
				catDef.isCategory = true;
				
				// 9.1 Name
				catDef.name = PEEK_VM_ADDR(cat->name, char, text);
				// 9.2 Adopted protocols
				if (cat->protocols != NULL) {
					const protocol_list_t* protos = PEEK_VM_ADDR(cat->protocols, protocol_list_t, data);
					catDef.adopted_protocols = vector<unsigned>(reinterpret_cast<const unsigned*>(&(protos->list)), reinterpret_cast<const unsigned*>(&(protos->list)) + protos->count);
				}
				// 9.3 Which class it's categorized
				catDef.superclass_name = this->get_superclass_name(reinterpret_cast<unsigned>(cat->cls), cat_vm_addr + offsetof(category_t, cls), all_class_def_indices, &(catDef.categorized_class));
				if (catDef.categorized_class != NULL)
					catDef.categorized_class->related_categories.push_back(ma_classes.size());
				
				// 9.4 Declared properties.
				vector<string> property_getters, property_setters;
				unsigned properties_address = reinterpret_cast<unsigned>(cat->instanceProperties);
				if (properties_address != 0) {
					const objc_property_list* properties_ptr = this->peek_data_at_vm_address<objc_property_list>(properties_address, &guess_data_segment);
					const objc_property* cur_property = &properties_ptr->first;
					for (unsigned j = 0; j < properties_ptr->count; ++ j, ++ cur_property) {
						this->obtain_properties(cur_property, guess_text_segment, catDef.property_names, catDef.property_prefixes, property_getters, property_setters);
						catDef.property_getter_address.push_back(0);
						catDef.property_setter_address.push_back(0);
					}
				}
				catDef.converted_property_start = catDef.property_prefixes.size();
				
				// 9.5 Methods.
				{
					vector<const char*> instance_method_names, instance_method_types;
					
					// 9.4.1 Class methods
					unsigned method_list_address = reinterpret_cast<unsigned>(cat->classMethods);
					if (method_list_address != 0) {
						const method_list_t* method_list_ptr = this->peek_data_at_vm_address<method_list_t>(method_list_address, &guess_data_segment);
						const method_t* cur_method = &method_list_ptr->first;
						for (unsigned j = 0; j < method_list_ptr->count; ++ j, ++ cur_method) {
							catDef.method_vm_addresses.push_back(reinterpret_cast<unsigned>(cur_method->imp));
							const char* method_name = PEEK_VM_ADDR(cur_method->name, char, text);
							const char* method_type = PEEK_VM_ADDR(cur_method->types, char, text);
							catDef.method_declarations.push_back(analyze_method(method_name, method_type, "+("));
						}
					}
					catDef.optional_class_method_start = -1;
					catDef.optional_instance_method_start = -1;
					catDef.instance_method_start = catDef.method_declarations.size();
					
					// 9.4.2 Instance methods.
					method_list_address = reinterpret_cast<unsigned>(cat->instanceMethods);
					
					if (method_list_address != 0) {
						const method_list_t* method_list_ptr = this->peek_data_at_vm_address<method_list_t>(method_list_address);
						const method_t* cur_method = &method_list_ptr->first;
						
						for (unsigned j = 0; j < method_list_ptr->count; ++ j, ++ cur_method) {
							catDef.method_vm_addresses.push_back(reinterpret_cast<unsigned>(cur_method->imp));
							const char* method_name = PEEK_VM_ADDR(cur_method->name, char, text);
							const char* method_type = PEEK_VM_ADDR(cur_method->types, char, text);
							
							instance_method_names.push_back(method_name);
							instance_method_types.push_back(method_type);
							
							string method_decl;
							size_t method_type_length = strlen(method_type);
							
							// check if it is a potential property getter.
							if (!property_getters.empty()) {
								// a method that have no input and returns nothing is probably a getter.
								if (method_type_length >= 6 && strcmp(method_type+method_type_length-5, "8@0:4") == 0 && method_type[0] != 'v' && method_type[0] != 'V') {
									for (vector<string>::const_iterator cit = property_getters.begin(); cit != property_getters.end(); ++ cit) {
										if (method_name == *cit) {
											instance_method_types.back() = NULL;
											method_decl.append("// declared property getter: ");
											catDef.property_getter_address[cit - property_getters.begin()] = reinterpret_cast<unsigned>(cur_method->imp);
											goto found_getter_or_setter_c;
										}
									}
								}
							}
							
							// now do the same for setters.
							if (!property_setters.empty()) {
								if (method_type_length >= 8 && (method_type[0] == 'v' || method_type[0] == 'V') && method_type[method_type_length-1] == '8' && !(method_type[method_type_length-2] >= '0' && method_type[method_type_length-2] <= '9')) {
									for (vector<string>::const_iterator cit = property_setters.begin(); cit != property_setters.end(); ++ cit) {
										if (method_name == *cit) {
											instance_method_types.back() = NULL;
											method_decl.append("// declared property setter: ");
											catDef.property_setter_address[cit - property_setters.begin()] = reinterpret_cast<unsigned>(cur_method->imp);
											goto found_getter_or_setter_c;
										}
									}
								}
							}
							
							
						found_getter_or_setter_c:
							method_decl.append(analyze_method(method_name, method_type, "-("));
							catDef.method_declarations.push_back(method_decl);
						}
					}
					
					all_instance_method_names.push_back(instance_method_names);
					all_instance_method_types.push_back(instance_method_types);
				}
				
				ma_classes.push_back(catDef);
			}
		}
		
		// Phase 10: Convert all vm addresses in adopted protocols to real indices.
		for (vector<ClassDefinition>::iterator it = ma_classes.begin(); it != ma_classes.end(); ++ it) {
			for (vector<unsigned>::iterator pit = it->adopted_protocols.begin(); pit != it->adopted_protocols.end(); ++ pit) {
				*pit = all_class_def_indices[*pit];
			}
		}
		
	}
	
	all_ivar_types.resize(ma_classes.size());
	
	//--- PART II: FURTHER DATA ANALYSIS ---//
	{
		// Phase 11: Propertize
		for (unsigned i = 0; i < ma_classes.size(); ++ i)
			propertize(ma_classes[i], all_instance_method_names[i], all_instance_method_types[i]);
		
		// Phase 12: Merge duplicate structs.
		m_has_anonymous_contentless_struct = false;
		m_has_anonymous_contentless_union = false;
		
		tr1::unordered_set<unsigned> pending_struct_list;
		for (unsigned i = 0; i < ma_struct_definitions.size(); ++ i)
			pending_struct_list.insert(i);
		vector<unsigned> pending_coalesion_list;
		
		while (!pending_struct_list.empty()) {
			for (tr1::unordered_set<unsigned>::iterator sit = pending_struct_list.begin(); sit != pending_struct_list.end(); ++ sit) {
				const StructDefinition& sd = ma_struct_definitions[*sit];
				
				for (vector<string>::const_iterator cit = sd.member_typestrings.begin(); cit != sd.member_typestrings.end(); ++ cit) {
					if (cit->at(0) == '{' || cit->at(0) == '(') {
						unsigned idx = ma_struct_indices[*cit];
						if (idx == ~1u)
							continue;
						if (idx != *sit && pending_struct_list.find(idx) != pending_struct_list.end()) {
							goto keep_it_in_pcl;
						}
					}
				}
				
				pending_coalesion_list.push_back(*sit);
				
keep_it_in_pcl:
				;
			}
			
			for (vector<unsigned>::const_iterator sit = pending_coalesion_list.begin(); sit != pending_coalesion_list.end(); ++ sit) {
				pending_struct_list.erase(*sit);
				
				StructDefinition& sd = ma_struct_definitions[*sit];
			
				bool anonymous = sd.name.empty();
				bool no_content = !sd.direct_reference && sd.member_typestrings.size() == 0;
				bool no_member_names = sd.members.empty();
				
				sd.see_also = ~0u;
				
				// struct XXAnonymousStruct;
				if (no_content && anonymous) {
					sd.see_also = ~1u;
					if (sd.is_union)
						m_has_anonymous_contentless_union = true;
					else
						m_has_anonymous_contentless_struct = true;
				}
				
				// Give content to named structs.
				else if (anonymous) {
					// Only has type signature. Identify by type sig only.
					if (no_member_names) {
						for (vector<unsigned>::const_iterator cit = pending_coalesion_list.begin(); cit != pending_coalesion_list.end(); ++ cit) {
							const StructDefinition& cd = ma_struct_definitions[*cit];
							if ((!cd.name.empty() || !cd.members.empty()) && member_typestrings_equal(sd.member_typestrings, cd.member_typestrings)) {
								sd.see_also = *cit;
								break;
							}
						}
					}
					// needs to match both type sig & member name.
					else {
						for (vector<unsigned>::const_iterator cit = pending_coalesion_list.begin(); cit != pending_coalesion_list.end(); ++ cit) {
							const StructDefinition& cd = ma_struct_definitions[*cit];
							if (!cd.name.empty() && cd.members == sd.members && member_typestrings_equal(cd.member_typestrings, sd.member_typestrings)) {
								sd.see_also = *cit;
								break;
							}
						}
					}
				}
				
				// Give name to anonymous structs
				else if (no_content) {
					for (vector<unsigned>::const_iterator cit = pending_coalesion_list.begin(); cit != pending_coalesion_list.end(); ++ cit) {
						const StructDefinition& cd = ma_struct_definitions[*cit];
						if ((cd.direct_reference || cd.member_typestrings.size() != 0) && cd.name == sd.name) {
							sd.see_also = *cit;
							break;
						}
					}
				}
				
				// Give member names
				else if (no_member_names) {
					for (vector<unsigned>::const_iterator cit = pending_coalesion_list.begin(); cit != pending_coalesion_list.end(); ++ cit) {
						const StructDefinition& cd = ma_struct_definitions[*cit];
						if (!cd.members.empty() && cd.name == sd.name && member_typestrings_equal(cd.member_typestrings, sd.member_typestrings)) {
							sd.see_also = *cit;
							break;
						}
					}
				}
				
				unsigned remap = sd.see_also, last_remap = ~0u;
				while (remap != ~0u && remap != ~1u) {
					last_remap = remap;
					remap = ma_struct_definitions[remap].see_also;
				}
				if (last_remap != ~0u) {
					ma_struct_indices[sd.typestring] = last_remap;
					increase_use_count(ma_struct_definitions[last_remap].use_count, sd.use_count);
					for (vector<string>::const_iterator cit = sd.member_typestrings.begin(); cit != sd.member_typestrings.end(); ++ cit)
						if (cit->at(0) == '{' || cit->at(0) == '(') {
							unsigned index = ma_struct_indices[*cit];
							if (index != ~0u && index != ~1u)
								decrease_use_count(ma_struct_definitions[index].use_count);
						}
				}
			}
		
			pending_coalesion_list.clear();
		}
		
		// Phase 13: Prettify struct names.
		for (tr1::unordered_map<string,unsigned>::const_iterator mit = ma_struct_indices.begin(); mit != ma_struct_indices.end(); ++ mit) {
			StructDefinition& curDef = ma_struct_definitions[mit->second];
			if (curDef.see_also == ~0u) {
				if (curDef.name.empty()) {
					if (curDef.use_count == 1)
						curDef.prettified_name = get_struct_definition(curDef, false, false);
					else
						curDef.prettified_name = synthesize_struct_name(mit->first, curDef.is_union);
				} else {
					// strip leading underscores.
					unsigned first_non_underscore = curDef.name.find_first_not_of('_');
					if (first_non_underscore == string::npos || !(curDef.name[first_non_underscore] >= 'A' && curDef.name[first_non_underscore] <= 'Z')) {
						curDef.prettified_name = curDef.name;
						continue;
					}
					curDef.prettified_name = curDef.name.substr(first_non_underscore);
				}
			}
		}
		
		// Phase 14: Build usage network.
		/*
		 There will be 2 kinds of links (arcs), weak link (compound type reference or adoption of protocol) and strong link
		 (struct usage or inheritance). The data structure should be an adjacency list, that records the user and incoming
		 link. The link granularity is class (e.g. WKQuad has 1 strong link to CGPoint, not 4).
		 
		 (Base) ---> (Derived).
		 */
		sort(ma_external_classes.begin(), ma_external_classes.end());
		vector<string>::iterator new_end = unique(ma_external_classes.begin(), ma_external_classes.end());
		ma_external_classes.resize(new_end - ma_external_classes.begin());
		ma_recognized_classes.clear();
		
		unsigned network_size = ma_classes.size() + ma_external_classes.size() + ma_struct_definitions.size();
		ma_adjlist.resize(network_size);
		ma_k_in.resize(network_size);
		fill(ma_k_in.begin(), ma_k_in.end(), pair<unsigned,unsigned>(0, 0));
		
		for (unsigned i = 0; i < network_size; ++ i) {
			int i_type = 0;
			if (i >= ma_classes.size())
				++ i_type;
			if (i >= ma_classes.size() + ma_external_classes.size())
				++ i_type;
			
			const ClassDefinition* cit = NULL;
			const StructDefinition* sit = NULL;
			const string* ext_cls = NULL;
			switch (i_type) {
				case 0: cit = &(ma_classes[i]); break;
				case 1: ext_cls = &(ma_external_classes[i - ma_classes.size()]); break;
				case 2: sit = &(ma_struct_definitions[i - ma_classes.size() - ma_external_classes.size()]); break;
			}
								
			if (i_type == 0 && cit->isCategory)
				continue;
			if (i_type == 2 && sit->see_also != ~0u)
				continue;
						
			for (unsigned j = 0; j < network_size; ++ j) {
				if (i == j)
					continue;
				
				int j_type = 0;
				if (j >= ma_classes.size())
					++ j_type;
				if (j >= ma_classes.size() + ma_external_classes.size())
					++ j_type;
				
				if (j_type == 1)
					continue;
				
				vector<pair<unsigned,unsigned> >& adjs = ma_adjlist[j];
				
				/* now there are 25 interactions to deal with:
				 BASE             DERIVED
					i -------------> j
				 (a)  class      vs    class      (strong = j inherits i;    weak = j's ivar/property has i ).
				 (b)  class      vs    category   (strong = j categorizes i;                                ).
				 (c)  class      vs    protocol   (                          weak = j's ivar/property has i ).
				 (d)  class      vs    ext. cls.  ( -- external class can never inherit or use a local class -- ).
				 (e)  class      vs    struct     (                          weak = j has direct member of i). 
				 
				 (f)  category   vs   <anything>  ( -- category can never be a base -- )
				 
				 (g)  protocol   vs    class      (   weak = j adopts i  )
				 (h)  protocol   vs    category   (   weak = j adopts i  )
				 (i)  protocol   vs    protocol   (   weak = j adopts i  )
				 (j)  protocol   vs    ext. cls.  ( -- extenal class can never adopt a local protocol -- )
				 (k)  protocol   vs    struct     ( -- structs don't care about protocls              -- )
				 
				 (l)  ext. cls.  vs    class      (strong = j inherits i;    weak = j's ivar/property has i ).
				 (m)  ext. cls.  vs    category   (strong = j categoizes i;                                 ).
				 (n)  ext. cls.  vs    protocol   (                          weak = j's ivar/property has i ).
				 (o)  ext. cls.  vs    ext. cls.  ( -- we don't know how those extenal classes strangle together -- ).
				 (p)  ext. cls.  vs    struct     (                          weak = j has direct member of i).
				 
				 (q)  struct     vs    class      (strong = j uses i as value; weak = j uses i as pointer).
				 (r)  struct     vs    category   (strong = j uses i as value; weak = j uses i as pointer).
				 (s)  struct     vs    protocol   (strong = j uses i as value; weak = j uses i as pointer).
				 (t)  struct     vs    ext. cls.  ( -- external class can never use local structs -- ).
				 (u)  struct     vs    struct     (strong = j uses i as value; weak = j uses i as pointer). */
				/* Which can be simplified into these 10 rules:
				 (1) if j is an external class, skip.
				 (2) if i is a category, skip.
				 (3) if i is a protocol & j is class-type,
					 if j adopts i, build a weak link.
				 (4) if i is class or external class, and j is a class-type,
					 (4.1) if j inherits or categorizes i, build a strong link.
					 (4.2) if j's property or ivar has i, build a weak link.
				 (5) if i is class of external class, and j is a struct,
					 if j's typestring contains @"className, build a weak link.
				 (6) if i is a struct,
					 (6.1) if j is a class-type, and j uses i directly in ivar, property or method, build a strong link. (search for `i\b not preceded by ^)
					 (6.2) else if j is a class-type, and j uses i by pointer in ivar, property or method, build a weak link. (just search for `i\b)
					 (6.3) if j is a struct, and j has a member using i directly, build a strong link.
					 (6.4) else if j is a struct, and j uses i by pointer in a member, build a weak link */
				
				const ClassDefinition* cit2 = NULL;
				const StructDefinition* sit2 = NULL;
				unsigned j_struct_id = j - ma_classes.size() - ma_external_classes.size();
				switch (j_type) {
					case 0: cit2 = &(ma_classes[j]); break;
					case 2: sit2 = &(ma_struct_definitions[j_struct_id]); break;
				}
				
				if (i_type == 0) {
					// (3)
					if (cit->isProtocol) {
						if (j_type == 0)
							if (find(cit2->adopted_protocols.begin(), cit2->adopted_protocols.end(), i) != cit2->adopted_protocols.end()) {
								adjs.push_back(pair<unsigned,unsigned>(i, LT_Weak));
								++ ma_k_in[i].first;
								continue;
							}
					}
				}
				if (i_type == 0 || i_type == 1) {
					const char* cls_name = (i_type == 0) ? cit->name : ext_cls->c_str();
					size_t cls_name_length = strlen(cls_name);
					
					if (j_type == 0) {
						// (4.1)
						if (cit2->superclass_name == cls_name) {
							adjs.push_back(pair<unsigned,unsigned>(i, LT_Strong));
							++ ma_k_in[i].second;
							continue;
						}
						// (4.2)
						else {
							const vector<const char*>& ivar_types = all_ivar_types[j];
							// Properties: The prefix should match the regexp \)\s(cls_name)[<*]
							for (vector<string>::const_iterator pit = cit2->property_prefixes.begin(); pit != cit2->property_prefixes.end(); ++ pit) {
								size_t close_paren_pos = pit->find(')');	// never -1.
								if (strncmp(pit->c_str()+close_paren_pos+2, cls_name, cls_name_length) != 0)
									continue;
								char ending = pit->at(close_paren_pos + cls_name_length + 2);								
								if (ending == '*' || ending == '<')									
									goto build_link_4_2;
							}
							// Ivars: the type should match ^[\^\[0-9]*@\"cls_name(?:<").
							for (vector<const char*>::const_iterator iit = ivar_types.begin(); iit != ivar_types.end(); ++ iit) {
								const char* at_string = *iit + strspn(*iit, "^[0123456789");
								if (at_string != NULL && at_string[0] == '@' && at_string[1] == '"' && strncmp(at_string+2, cls_name, cls_name_length) == 0) {
									if (at_string[2+cls_name_length] == '<' || at_string[2+cls_name_length] == '"')
										goto build_link_4_2;
								}
							}
							continue;
						build_link_4_2:
							adjs.push_back(pair<unsigned,unsigned>(i, LT_Weak));
							++ ma_k_in[i].first;
							continue;
						}
					}
					// (5)
					else if (j_type == 2) {
						for (vector<string>::const_iterator tit = sit2->member_typestrings.begin(); tit != sit2->member_typestrings.end(); ++ tit) {
							size_t at_pos = tit->find_first_not_of("^[0123456789");
							if (at_pos == string::npos || tit->size() == 1)
								continue;
							if (tit->at(at_pos) == '@' && tit->at(at_pos+1) == '"' && strncmp(tit->c_str()+at_pos+2, cls_name, cls_name_length) == 0) {
								char c = tit->at(at_pos + 2 + cls_name_length);
								if (c == '<' || c == '"') {
									adjs.push_back(pair<unsigned,unsigned>(i, LT_Weak));
									++ ma_k_in[i].first;
									break;
								}
							}
						}
					}
				}
				else if (i_type == 1) {
					// (6.1) & (6.2)
					if (j_type == 0) {
						unsigned prev_lt = LT_None;
						for (vector<string>::const_iterator iit = cit2->ivar_declarations.begin(); iit != cit2->ivar_declarations.end(); ++ iit) {
							prev_lt = get_struct_link_type(*iit, prev_lt, j);
							if (prev_lt == LT_Strong)
								goto build_link_6;
						}
						for (vector<string>::const_iterator iit = cit2->property_prefixes.begin(); iit != cit2->property_prefixes.end(); ++ iit) {
							prev_lt = get_struct_link_type(*iit, prev_lt, j);
							if (prev_lt == LT_Strong)
								goto build_link_6;
						}
						for (vector<string>::const_iterator iit = cit2->method_declarations.begin(); iit != cit2->method_declarations.end(); ++ iit) {
							prev_lt = get_struct_link_type(*iit, prev_lt, j);
							if (prev_lt == LT_Strong)
								goto build_link_6;
						}
					build_link_6:
						if (prev_lt != LT_None) {
							adjs.push_back(pair<unsigned,unsigned>(i, prev_lt));
							if (prev_lt == LT_Weak)
								++ ma_k_in[i].first;
							else
								++ ma_k_in[i].second;
							continue;
						}
					}
					// (6.3) & (6.4)
					else if (j_type == 2) {
						unsigned lt = LT_None;
						unsigned prev_lt = LT_None;
						
						for (vector<string>::const_iterator tit = sit2->member_typestrings.begin(); tit != sit2->member_typestrings.end(); ++ tit) {
							size_t first_brace_position = tit->find_first_of("{(");
							size_t last_brace_position = tit->find_last_of("})");
							if (first_brace_position == string::npos || last_brace_position == string::npos)
								continue;
							if (first_brace_position == 0)
								lt = LT_Strong;
							else {
								if (tit->find_last_not_of("^[0123456789", first_brace_position-1) != string::npos)
									continue;
								lt = (tit->rfind('^', first_brace_position-1) == string::npos) ? LT_Strong : LT_Weak;
							}
							if (lt <= prev_lt)
								continue;
								
							unsigned found_index = ma_struct_indices[tit->substr(first_brace_position, last_brace_position-first_brace_position+1)];
							if (found_index == j_struct_id) {
								prev_lt = lt;
								if (lt == LT_Strong)
									break;
							}
						}
						
						if (prev_lt != LT_None) {
							adjs.push_back(pair<unsigned,unsigned>(i, prev_lt));
							if (prev_lt == LT_Weak)
								++ ma_k_in[i].first;
							else 
								++ ma_k_in[i].second;
							continue;
						}
					}
				}
			}
		}
		ma_reachability_matrix = LazyReachabilityMatrix(ma_adjlist);
		
		// Phase 15: Substitute the prettified struct names in.
		for (vector<ClassDefinition>::iterator cit = ma_classes.begin(); cit != ma_classes.end(); ++ cit) {
			for (vector<StructDefinition>::iterator sit2 = ma_struct_definitions.begin(); sit2 != ma_struct_definitions.end(); ++ sit2) {
				unsigned tab_length = 1;
				while (replace_prettified_struct_names(sit2->prettified_name, tab_length, sit2->name))
					++ tab_length;
			}
			
			vector<string>::iterator sit;
			string impossible_name = "!";
			for (sit = cit->ivar_declarations.begin(); sit != cit->ivar_declarations.end(); ++ sit)
				replace_prettified_struct_names(*sit, 1, impossible_name);
			for (sit = cit->property_prefixes.begin(); sit != cit->property_prefixes.end(); ++ sit)
				replace_prettified_struct_names(*sit, 0, impossible_name);
			for (sit = cit->method_declarations.begin(); sit != cit->method_declarations.end(); ++ sit)
				replace_prettified_struct_names(*sit, 0, impossible_name);
		}
		
	}
	
}

void MachO_File_ObjC::print_class(unsigned int index, bool print_ivar_offsets, bool print_method_addresses, bool print_comments) const throw() {
	// 1. Print interface declaration.
	
	// 1.1 Print attributes
	const ClassDefinition& clsDef = ma_classes[index];
	
	if (clsDef.attributes & RO_HIDDEN) {
		if (clsDef.attributes & RO_EXCEPTION)
			printf("__attribute__((visibility(\"hidden\"),objc_exception))\n");
		else
			printf("__attribute__((visibility(\"hidden\")))\n");
	} else if (clsDef.attributes & RO_EXCEPTION) {
		printf("__attribute__((objc_exception))\n");
	}
	
	// 1.2 Print class name.
	if (clsDef.isProtocol)
		printf("@protocol %s", clsDef.name);
	else if (clsDef.isCategory)
		printf("@interface %s (%s)", clsDef.superclass_name, clsDef.name);
	else
		printf("@interface %s", clsDef.name);
	
	if (!clsDef.isCategory && !clsDef.isProtocol) {
		if (clsDef.superclass_name != NULL)
			printf(" : %s", clsDef.superclass_name);
	}
	
	// 1.4 Print adopted protocols
	if (clsDef.adopted_protocols.size() > 0) {
		printf(" <");
		bool is_first = true;
		for (vector<unsigned>::const_iterator cit = clsDef.adopted_protocols.begin(); cit != clsDef.adopted_protocols.end(); ++ cit) {
			if (is_first)
				is_first = false;
			else
				printf(", ");
			printf("%s", ma_classes[*cit].name);
		}
		printf(">");
	}
	
	// 2. Print ivars.
	if (!clsDef.isProtocol && !clsDef.isCategory) {
		printf(" {\n");
		vector<string>::const_iterator cit1 = clsDef.ivar_declarations.begin();
		if (print_ivar_offsets) {
			vector<unsigned>::const_iterator cit2 = clsDef.ivar_offsets.begin();
			for (; cit1 != clsDef.ivar_declarations.end(); ++cit1, ++cit2)
				printf("\t%s;\t// %d = 0x%02x\n", cit1->c_str(), *cit2, *cit2);
		} else
			for (; cit1 != clsDef.ivar_declarations.end(); ++cit1)
				printf("\t%s;\n", cit1->c_str());
				
		printf("}");
	}
	printf("\n");
	
	// 3. Print properties.
	vector<const char*>::const_iterator nit = clsDef.property_names.begin();
	vector<unsigned>::const_iterator git = clsDef.property_getter_address.begin(), sit = clsDef.property_setter_address.begin();
	vector<string>::const_iterator pit = clsDef.property_prefixes.begin();
	for (unsigned i = 0; pit != clsDef.property_prefixes.end(); ++ pit, ++ nit, ++ i) {
		printf("@property(%s %s;", pit->c_str(), *nit);
		if (print_method_addresses && !clsDef.isProtocol) {
			if (*git != 0)
				printf("\t// G=0x%04x", *git);
			else
				printf("\t// G=undefined");
			if (*sit != 0)
				printf(", S=0x%04x", *sit);
			++ git;
			++ sit;
		}
		if (i >= clsDef.converted_property_start)
			printf("\t// converted property");
		printf("\n");
	}
	
	// 4. Print methods.
	vector<unsigned>::const_iterator cit2 = clsDef.method_vm_addresses.begin();
	pit = clsDef.method_declarations.begin();
	bool is_optional_now = false;
	for (unsigned i = 0; pit != clsDef.method_declarations.end(); ++ pit, ++ i) {
		if (!is_optional_now && ((i == clsDef.optional_class_method_start && i != clsDef.instance_method_start) || i == clsDef.optional_instance_method_start)) {
			printf("@optional\n");
			is_optional_now = true;
		}
		else if (is_optional_now && i == clsDef.instance_method_start && i != clsDef.optional_instance_method_start) {
			printf("@required\n");
			is_optional_now = false;
		}
		if (print_comments || pit->size() < 2 || pit->substr(0, 2) != "//") {
			printf("%s;", pit->c_str());
			if (print_method_addresses && !clsDef.isProtocol) {
				printf("\t// 0x%04x", *cit2);
				++ cit2;
			}
			printf("\n");
		}
	}

	printf("@end\n\n");
}

void MachO_File_ObjC::print_struct(unsigned int index) throw() {
	const StructDefinition& curDef = ma_struct_definitions[index];
	
	if (curDef.see_also != ~0u || (curDef.use_count == 1 && (curDef.member_typestrings.size() != 0 || curDef.direct_reference) && curDef.name.empty()))
		return;
	
	if (!curDef.is_union && !curDef.direct_reference && curDef.member_typestrings.size() == 0 && (curDef.prettified_name.size() < 2 || curDef.prettified_name.substr(0, 2) != "NS") && curDef.name[curDef.name.size()-1] != '>')
		printf("typedef struct %s* %sRef;\n\n", curDef.name.c_str(), curDef.prettified_name.c_str());
	else
		printf("%s;\n\n", get_struct_definition(curDef, true, true).c_str());
}

void MachO_File_ObjC::print_anonymous_contentless_records() const throw() {
	if (m_has_anonymous_contentless_struct)
		printf("typedef struct XXAnonymousStruct XXAnonymousStruct;\n\n");
	if (m_has_anonymous_contentless_union)
		printf("typedef union XXAnonymousUnion XXAnonymousUnion;\n\n");
}

bool MachO_File_ObjC::InheritSorter::operator() (unsigned i, unsigned j) const throw() {
	const ClassDefinition& cdi = mf.ma_classes[i], &cdj = mf.ma_classes[j];
	// both are protocols. If j uses i, then j < i. Otherwise, sort by index order.
	if (cdi.isProtocol && cdj.isProtocol) {
		if (find(cdj.adopted_protocols.begin(), cdj.adopted_protocols.end(), i) != cdj.adopted_protocols.end())
			return true;
		else if (find(cdi.adopted_protocols.begin(), cdi.adopted_protocols.end(), j) == cdj.adopted_protocols.end())
			return false;
		else
			return i < j;
	}
	
	// protocols always come first.
	else if (cdi.isProtocol)
		return true;
	
	else if (cdj.isProtocol)
		return false;
	
	// both are normal classes. sort by inheritance. if j.superclass == i, then i < j.
	else if (!cdi.isCategory && !cdj.isCategory) {
		if (cdi.name == cdj.superclass_name)
			return true;
		else if (cdj.name == cdi.superclass_name)
			return false;
		else
			return i < j;
	}
	
	// sort by normal order.
	else
		return i < j;
}
bool MachO_File_ObjC::NormalSorter::operator() (unsigned i, unsigned j) const throw() {
	const ClassDefinition& cdi = mf.ma_classes[i], &cdj = mf.ma_classes[j];
	if (cdi.isProtocol == cdj.isProtocol)
		return i < j;
	else if (cdi.isProtocol)
		return true;
	else
		return false;
}
bool MachO_File_ObjC::AlphabeticSorter::operator() (unsigned i, unsigned j) const throw() {
	const ClassDefinition& cdi = mf.ma_classes[i], &cdj = mf.ma_classes[j];
	if (cdi.isProtocol == cdj.isProtocol) {
		if (cdi.isCategory == cdj.isCategory)
			return strcmp(cdi.name, cdj.name) < 0;
		else if (cdi.isCategory)
			return strcmp(cdi.superclass_name, cdj.name) < 0;
		else
			return strcmp(cdi.name, cdj.superclass_name) < 0;
	} else if (cdi.isProtocol)
		return true;
	else
		return false;
}

vector<unsigned> MachO_File_ObjC::get_class_sort_order_by(SortBy by) const throw() {
	vector<unsigned> return_order (ma_classes.size());
	for (unsigned i = 0; i < ma_classes.size(); ++ i)
		return_order[i] = i;
	
	switch (by) {
		case SB_Inherit:
			sort(return_order.begin(), return_order.end(), InheritSorter(*this));
			break;
		case SB_Alphabetic:
			sort(return_order.begin(), return_order.end(), AlphabeticSorter(*this));
			break;
		default:
			sort(return_order.begin(), return_order.end(), NormalSorter(*this));
			break;
	}
	
	return return_order;
}

void MachO_File_ObjC::print_reachability_matrix() throw() {
	for (unsigned i = 0; i < ma_adjlist.size(); ++ i) {
		printf("%3u [%3u, %3u] = ", i, ma_k_in[i].first, ma_k_in[i].second);
		if (i < ma_classes.size()) {
			if (ma_classes[i].isProtocol)
				printf("(proto ) ");
			else if (ma_classes[i].isCategory)
				printf("(categ ) ");
			else
				printf("(class ) ");
			printf("%s : %s\n", ma_classes[i].name, ma_classes[i].superclass_name ?: "--");
		} else if (i < ma_classes.size() + ma_external_classes.size()) {
			printf("(extern) %s\n", ma_external_classes[i - ma_classes.size()].c_str());
		} else {
			printf("(struct) %s\n", ma_struct_definitions[i - ma_classes.size() - ma_external_classes.size()].prettified_name.c_str());
		}
	}
	for (unsigned i = 0; i < ma_adjlist.size(); ++ i) {
		printf("\n%3u -> ", i);
		for (vector<pair<unsigned, unsigned> >::const_iterator cit = ma_adjlist[i].begin(); cit != ma_adjlist[i].end(); ++ cit)
			printf("%3u(%c) ", cit->first, "-WS"[cit->second]);
	}
	printf("\n\n");
	printf("     ");
	for (unsigned i = 0; i < ma_reachability_matrix.size(); ++ i) {
		if (i < 100)
			printf(" ");
		else
			printf("%u", (i / 100) % 10);
		if (i % 10 == 9)
			printf(" ");
	}
	printf("\n     ");
	for (unsigned i = 0; i < ma_reachability_matrix.size(); ++ i) {
		if (i < 10)
			printf(" ");
		else
			printf("%u", (i / 10) % 10);
		if (i % 10 == 9)
			printf(" ");
	}
	printf("\n     ");
	for (unsigned i = 0; i < ma_reachability_matrix.size(); ++ i) {
		printf("%u", i % 10);
		if (i % 10 == 9)
			printf(" ");
	}
	printf("\n");
	for (unsigned i = 0; i < ma_reachability_matrix.size(); ++ i) {
		printf("%3u: ", i);
		for (unsigned j = 0; j < ma_reachability_matrix.size(); ++ j) {
			printf("%c", "-WS"[ma_reachability_matrix.reach(i,j)]);
			if (j % 10 == 9)
				printf(" ");
		}
		printf("\n");
	}
}

void MachO_File_ObjC::print_struct_indices() const throw() {
	for (tr1::unordered_map<string,unsigned>::const_iterator cit = ma_struct_indices.begin(); cit != ma_struct_indices.end(); ++ cit) {
		printf("%3d: %s\n", cit->second, cit->first.c_str());
	}
}