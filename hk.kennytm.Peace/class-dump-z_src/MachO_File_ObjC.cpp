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
#include "hash_combine.h"

using namespace std;

// Note: this is copied from C++'s hash<string>.
// But as you can see, this function is O(length) instead of O(1)... (Although strcmp is also O(length).)
static inline size_t string_hasher(const char* str) {
	size_t res = 0;
	while (*str != '\0') 
		res = res*131 + *str++;
	return res;
}

#if _TR1_FUNCTIONAL || _MSC_VER
namespace std 
#ifndef _MSC_VER
{
	namespace tr1
#endif
#else
	namespace boost
#endif
	{
		template<>
		struct hash< ::MachO_File_ObjC::ReducedProperty> : public unary_function< ::MachO_File_ObjC::ReducedProperty, size_t> {
			size_t operator() (const ::MachO_File_ObjC::ReducedProperty& p) const throw() {
				size_t retval = 0;
				hash_combine(retval, p.name);
				hash_combine(retval, p.type);
				hash_combine(retval, p.has_getter*32 + p.has_setter*16 + p.copy*8 + p.retain*4 + p.readonly*2 + p.nonatomic);
				if (p.has_setter)
					hash_combine(retval, p.getter);
				if (p.has_getter)
					hash_combine(retval, p.setter);
				return retval;
			}
		};
		
		template<>
		struct hash< ::MachO_File_ObjC::ReducedMethod> : public unary_function< ::MachO_File_ObjC::ReducedMethod, size_t> {
			size_t operator() (const ::MachO_File_ObjC::ReducedMethod& m) const throw() {
				size_t retval = 0;
				hash_combine(retval, string_hasher(m.raw_name));
				hash_combine(retval, m.is_class_method);
				hash_combine(retval, m.types);
				return retval;
			}
		};
#if _TR1_FUNCTIONAL
	}
#endif
}

struct MachO_File_ObjC::OverlapperType {
	bool defined;
	std::tr1::unordered_set<ReducedProperty> properties;
	std::tr1::unordered_set<ReducedMethod> methods;
	OverlapperType() : defined(false) {}
	void union_with(const ClassType& cls) throw();
	void union_with(const OverlapperType& ovlp) throw();
	static void recursive_union_with_protocols(unsigned i, std::vector<OverlapperType>& overlappers, const std::vector<ClassType>& classes) throw();
	void localize(ObjCTypeRecord& local, const ObjCTypeRecord& remote) throw();
};

#pragma mark -

MachO_File_ObjC::MachO_File_ObjC(const char* path, bool perform_reduced_analysis, const char* arch) : MachO_File(path, arch), m_guess_data_segment(1), m_guess_text_segment(0), m_class_filter(NULL), m_method_filter(NULL), m_class_filter_extra(NULL), m_method_filter_extra(NULL), m_arch(arch), m_has_whitespace(false), m_hide_cats(false), m_hide_dogs(false), m_hints_file(NULL) {
	if (perform_reduced_analysis) {
		retrieve_reduced_class_info();
	} else {
		retrieve_protocol_info();
		retrieve_class_info();
		retrieve_category_info();
	}
	
	for (vector<ClassType>::iterator it = ma_classes.begin(); it != ma_classes.end(); ++ it)
		tag_propertized_methods(*it);
	
	if (!perform_reduced_analysis)
		m_record.create_short_circuit_weak_links();
}

void MachO_File_ObjC::tag_propertized_methods(ClassType& cls) throw() {
	for (vector<Property>::iterator pit = cls.properties.begin(); pit != cls.properties.end(); ++ pit) {
		for (vector<Method>::iterator mit = cls.methods.begin(); mit != cls.methods.end(); ++ mit) {
			// to be a getter, the method must
			// (1) not be a class method
			// (2) accept no parameters (types.size() == 3)
			// (3) does not return void
			// (4) the raw name is equal to the required getter name.
			// (The first 3 rules are just to filter out unqualified methods quicker) 
			if (mit->propertize_status == PS_None && !mit->is_class_method && mit->types.size() == 3 && !m_record.is_void_type(mit->types[0]) && pit->getter == mit->raw_name) {
				pit->getter_vm_address = mit->vm_address;
				if (mit->optional)
					pit->optional = true;
				mit->propertize_status = PS_DeclaredGetter;
				break;
			}
		}
		if (!pit->readonly) {
			for (vector<Method>::iterator mit = cls.methods.begin(); mit != cls.methods.end(); ++ mit) {
				// to be a setter, the method must
				// (1) not be a class method
				// (2) accept exactly one parameters (types.size() == 4)
				// (3) returns void (not even oneway void)
				// (4) the raw name is equal to the required setter name.
				if (mit->propertize_status == PS_None && !mit->is_class_method && mit->types.size() == 4 && m_record.is_void_type(mit->types[0]) && pit->setter == mit->raw_name) {
					pit->setter_vm_address = mit->vm_address;
					if (mit->optional)
						pit->optional = true;
					mit->propertize_status = PS_DeclaredSetter;
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
		if (mit->propertize_status == PS_None && !mit->is_class_method && mit->types.size() == 4 && m_record.is_void_type(mit->types[0]))
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
			if (*sit != &*mit && mit->propertize_status == PS_None && (*sit)->optional == mit->optional && !mit->is_class_method && mit->types.size() == 3 && mit->types[0] == (*sit)->types[3]) {
				
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
				prop.optional = mit->optional;
				prop.impl_method = Property::IM_Converted;
				prop.type = mit->types[0];
				prop.retain = m_record.is_id_type(prop.type);
				if (prop.retain && property_name.size() >= strlen("delegate")) {
					string delegate_matcher = property_name.substr(property_name.size() - strlen("delegate"));
					if (delegate_matcher == "Delegate" || delegate_matcher == "delegate")
						prop.retain = false;
				}
				cls.properties.push_back(prop);
				mit->propertize_status = PS_ConvertedGetter;
				(*sit)->propertize_status = PS_ConvertedSetter;
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
			if (mit->propertize_status == PS_None && !mit->is_class_method && mit->types.size() == 3 && m_record.are_types_compatible(mit->types[0], iit->type)) {
				if (mit->raw_name == property_name)
					has_getter = false;
				else if (mit->raw_name == alt_property_name)
					has_getter = true;
				else
					continue;
				Property prop;
				prop.name = property_name;
				prop.has_getter = has_getter;
				prop.optional = mit->optional;
				prop.readonly = true;
				prop.getter = mit->raw_name;
				prop.getter_vm_address = mit->vm_address;
				prop.impl_method = Property::IM_Converted;
				prop.type = iit->type;
				prop.retain = m_record.is_id_type(iit->type);
				cls.properties.push_back(prop);
				mit->propertize_status = PS_ConvertedGetter;
				break;
			}
		}
		
phase_2_next_ivar:
		;
	}
}

#pragma mark -
void MachO_File_ObjC::OverlapperType::union_with(const MachO_File_ObjC::ClassType& cls) throw() {
	defined = true;
	properties.insert(cls.properties.begin(), cls.properties.end());
	methods.insert(cls.methods.begin(), cls.methods.end());
}

void MachO_File_ObjC::OverlapperType::union_with(const MachO_File_ObjC::OverlapperType& cls) throw() {
	defined = true;
	properties.insert(cls.properties.begin(), cls.properties.end());
	methods.insert(cls.methods.begin(), cls.methods.end());
}

void MachO_File_ObjC::OverlapperType::localize(ObjCTypeRecord& local, const ObjCTypeRecord& remote) throw() {
	if (&local == &remote)
		return;

	// Since the unordered_set's iterator is equivalent to a const_iterator, we have to construct a new unordered_set.
	tr1::unordered_set<ReducedMethod> old_methods;
	methods.swap(old_methods);
	for (tr1::unordered_set<ReducedMethod>::const_iterator mit = old_methods.begin(); mit != old_methods.end(); ++ mit) {
		ReducedMethod m = *mit;
		const vector<ObjCTypeRecord::TypeIndex>& types = mit->types;
		for (unsigned i = 0; i < types.size(); ++ i)
			m.types[i] = local.parse(remote.encoding_of_type(types[i]), false);
		methods.insert(m);
	}
}

void MachO_File_ObjC::recursive_union_with_protocols(unsigned i, std::vector<OverlapperType>& overlappers) const throw() {
	OverlapperType& ovlp = overlappers[i];
	if (!ovlp.defined) {
		const ClassType& cls = ma_classes[i];
		ovlp.union_with(cls);
		for (vector<unsigned>::const_iterator cit = cls.adopted_protocols.begin(); cit != cls.adopted_protocols.end(); ++ cit) {
			recursive_union_with_protocols(*cit, overlappers);
			ovlp.union_with(overlappers[*cit]);
		}	
	}
}
void MachO_File_ObjC::recursive_union_with_superclasses(ObjCTypeRecord::TypeIndex ti, tr1::unordered_map<ObjCTypeRecord::TypeIndex, OverlapperType>& superclass_overlappers, const char* sysroot) throw() {
	OverlapperType& ovlp = superclass_overlappers[ti];
	if (!ovlp.defined) {
		tr1::unordered_map<ObjCTypeRecord::TypeIndex, unsigned>::const_iterator cit = ma_classes_typeindex_index.find(ti);
		// Super class is internal. 
		if (cit != ma_classes_typeindex_index.end()) {
			const ClassType& cls = ma_classes[cit->second];
			ovlp.union_with(cls);
			if (!(cls.attributes & RO_ROOT)) {
				recursive_union_with_superclasses(cls.superclass_index, superclass_overlappers, sysroot);
				ovlp.union_with(superclass_overlappers[cls.superclass_index]);
			}
		// Super class is probably external.
		} else {
			tr1::unordered_map<ObjCTypeRecord::TypeIndex, const char*>::const_iterator lit = ma_lib_path.find(ti);
			if (lit != ma_lib_path.end()) {
				const char* libpath = lit->second;
				tr1::unordered_map<const char*, MachO_File_ObjC*>::iterator loaded_lib = ma_loaded_libraries.find(libpath);
				if (loaded_lib == ma_loaded_libraries.end()) {
					size_t sysroot_len = strlen(sysroot);
					bool sysroot_ends_with_slash = sysroot[sysroot_len-1] == '/';				
					char* the_path = reinterpret_cast<char*>(alloca(sysroot_len + strlen(libpath) + 1));
					memcpy(the_path, sysroot, sysroot_len);
					strcpy(the_path+sysroot_len, libpath+(libpath[0]=='/'&&sysroot_ends_with_slash));
					MachO_File_ObjC* mf = NULL;
					try {
						mf = new MachO_File_ObjC(the_path, true, m_arch);
					} catch (...) {
						mf = NULL;
					}
					loaded_lib = ma_loaded_libraries.insert( pair<const char*, MachO_File_ObjC*>(libpath, mf) ).first;
				}
				
				MachO_File_ObjC* mf = loaded_lib->second;
				if (mf != NULL) {
					tr1::unordered_map<ObjCTypeRecord::TypeIndex, OverlapperType> remote_superclass_overlappers;
					ObjCTypeRecord::TypeIndex remote_index = mf->m_record.parse(m_record.encoding_of_type(ti), false);
					mf->recursive_union_with_superclasses(remote_index, remote_superclass_overlappers, sysroot);
					for (tr1::unordered_map<ObjCTypeRecord::TypeIndex, OverlapperType>::iterator tit = remote_superclass_overlappers.begin(); tit != remote_superclass_overlappers.end(); ++ tit) {
						tit->second.localize(m_record, mf->m_record);
						ObjCTypeRecord::TypeIndex local_index = m_record.parse(mf->m_record.encoding_of_type(tit->first), false);
						superclass_overlappers[local_index].union_with(tit->second);
					}
				}
			}
		}
	}
}

void MachO_File_ObjC::hide_overlapping_methods(ClassType& target, const OverlapperType& reference, MachO_File_ObjC::HiddenMethodType hiding_method) throw() {
	for (vector<Property>::iterator it = target.properties.begin(); it != target.properties.end(); ++ it)
		if (it->hidden == PS_None && reference.properties.find(*it) != reference.properties.end())
			it->hidden = hiding_method;
	for (vector<Method>::iterator it = target.methods.begin(); it != target.methods.end(); ++ it)
		if (it->propertize_status == PS_None && reference.methods.find(*it) != reference.methods.end())
			it->propertize_status = hiding_method;
}

void MachO_File_ObjC::hide_overlapping_methods(bool hide_super, bool hide_proto, const char* sysroot) throw() {
	if (hide_proto) {
		// Construct Overlappers for protocols.
		vector<OverlapperType> protocol_overlappers (m_protocol_count);
		for (unsigned i = 0; i < m_protocol_count; ++ i)
			recursive_union_with_protocols(i, protocol_overlappers);
		
		// Now actually hide the methods.
		for (vector<ClassType>::iterator it = ma_classes.begin(); it != ma_classes.end(); ++ it)
			for (vector<unsigned>::const_iterator pit = it->adopted_protocols.begin(); pit != it->adopted_protocols.end(); ++ pit)
				hide_overlapping_methods(*it, protocol_overlappers[*pit], PS_AdoptingProtocol);
	}
	
	if (hide_super) {
		tr1::unordered_map<ObjCTypeRecord::TypeIndex, OverlapperType> superclass_overlappers;
		for (unsigned i = m_protocol_count; i < ma_classes.size(); ++ i)
			recursive_union_with_superclasses(ma_classes[i].superclass_index, superclass_overlappers, sysroot);
		
		for (unsigned i = m_protocol_count; i < ma_classes.size(); ++ i) {
			ClassType& cls = ma_classes[i];
			hide_overlapping_methods(cls, superclass_overlappers[cls.superclass_index], PS_Inherited);
		}
	}
}
