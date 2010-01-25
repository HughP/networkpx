#!/usr/bin/env python3.1
#
# print-struct-members.py ... Print member variables of structs for use in IDA Pro.
# 
# Copyright (C) 2010  KennyTM~
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

import sys;
import inspect;
import re;
from xml.dom.minidom import parse;


# Useful functions


def splat(s):
	return re.findall("_\\w+", s)

def get_class_with_name(name):
	class_list = inspect.getmembers(sys.modules[__name__], lambda z: inspect.isclass(z) and z.__name__==name)
	if len(class_list) != 0:
		return class_list[0][1]
	else:
		return None	


# GXElement objects, representing elements in the GCC-XML file.


class GXElement(object):
	def __init__(self, elem):
		self.identity = elem.getAttribute("id")
	def declaration(self):
		return ""
	def link(self, elements):
		pass
	def __hash__(self):
		return hash(self.identity)


class GXFundamentalType(GXElement):
	type_prefix = ""
	def __init__(self, elem):
		GXElement.__init__(self, elem)
		self.name = elem.getAttribute("name")
		
	def type_name(self, name, non_vtable):
		return self.type_prefix + self.name + ("$ " if not non_vtable else " ") + name
		
	def dependent_typedefs(self):
		return frozenset()


class GXStruct(GXFundamentalType):
	type_prefix = "struct "
	def __init__(self, elem):
		GXFundamentalType.__init__(self, elem)
		self.bases = splat(elem.getAttribute("bases"))
		self.members = splat(elem.getAttribute("members"))
		self.has_vtable = None
		self.incomplete = elem.getAttribute("incomplete") == "1"
		
	def declaration(self):
		head = [self.type_name("", not self.has_vtable), "{\n"]
		if self.incomplete:
			head.append("\t/* incomplete! */\n")
		head.extend("\t" + b.type_name("$super" + str(i), not b.has_vtable) + ";\n" for i, b in enumerate(self.base_elements))
		head.extend("\t" + m.declaration() + "\n" for m in self.member_elements)
		head.append("};")
		if self.has_vtable:
			head.extend(("\n", self.type_prefix, self.name, " {\n\tvoid **$vtable;\n\t", self.type_name("$self", False), ";\n};"))
		return "".join(head)
		
	def link(self, elements):
		self.base_elements = tuple(elements[x] for x in self.bases)
		self.member_elements = tuple(elements[x] for x in self.members if isinstance(elements[x], GXField))
				
	def compute_vtable(self, elements):
		if self.has_vtable is None:
			for b in self.base_elements:
				if b.compute_vtable(elements):
					self.has_vtable = True
					return True
			for m in self.members:
				elem = elements[m]
				if isinstance(elem, GXMethod) and elem.is_virtual:
					self.has_vtable = True
					return True
			self.has_vtable = False
		return self.has_vtable
		
	def dependent_structs(self):
		retval = set(self.base_elements)
		for field in self.member_elements:
			member = field.source_element
			if isinstance(member, GXStruct):
				retval.add(member)
			else:
				first_struct_member = member
				while isinstance(first_struct_member, (GXArrayType, GXCvQualifiedType, GXStruct)):
					if isinstance(first_struct_member, GXStruct):
						retval.add(first_struct_member)
						break
					else:
						first_struct_member = first_struct_member.base_element
		return retval
	

class GXClass(GXStruct):
	pass
class GXUnion(GXStruct):
	type_prefix = "union "


class GXEnumeration(GXFundamentalType):
	type_prefix = "enum "
	def __init__(self, elem):
		GXFundamentalType.__init__(self, elem)
		self.enums = ((child.getAttribute("name"), child.getAttribute("init")) for child in elem.childNodes if child.nodeType == 1)
		
	def declaration(self):
		head = ["enum ", self.name, " {\n"]
		head.extend("\t" + x[0] + " = " + x[1] + ",\n" for x in self.enums)
		head.append("};")
		return "".join(head)
	

class GXPointerType(GXElement):
	star = "*"
	def __init__(self, elem):
		GXElement.__init__(self, elem)
		self.base = elem.getAttribute("type")
		
	def type_name(self, name, non_vtable):
		if isinstance(self.base_element, (GXArrayType, GXFunctionType)):
			return self.base_element.type_name("(" + self.star + name + ")", True)
		else:
			return self.base_element.type_name(self.star + name, True)
	
	def link(self, elements):
		self.base_element = elements[self.base]
		
	def dependent_typedefs(self):
		return self.base_element.dependent_typedefs()

class GXReferenceType(GXPointerType):
#	star = "&"
	pass
	
	
class GXArrayType(GXElement):
	def __init__(self, elem):
		GXElement.__init__(self, elem)
		self.base = elem.getAttribute("type")
		try:
			self.length = str(int(elem.getAttribute("max")) + 1)
		except ValueError:
			self.length = "0"
		
	def type_name(self, name, non_vtable):
		return self.base_element.type_name(name + "[" + self.length + "]", True)
		
	def link(self, elements):
		self.base_element = elements[self.base]
	
	def dependent_typedefs(self):
		return self.base_element.dependent_typedefs()
	

class GXTypedef(GXFundamentalType):
	def __init__(self, elem):
		GXFundamentalType.__init__(self, elem)
		self.source_type = elem.getAttribute("type")

	def declaration(self):
		return "typedef " + self.source_element.type_name(self.name, True) + ";"
	
	def link(self, elements):
		self.source_element = elements[self.source_type]

	def dependent_typedefs(self):
		return frozenset((self,))


class GXCvQualifiedType(GXElement):
	def __init__(self, elem):
		GXElement.__init__(self, elem)
		const_volatile = []
		if elem.getAttribute("const") == "1":
			const_volatile.append("const ")
		if elem.getAttribute("volatile") == "1":
			const_volatile.append("volatile ")
		self.qual = "".join(const_volatile)
		self.base = elem.getAttribute("type");
	
	def type_name(self, name, non_vtable):
		return self.base_element.type_name(self.qual + name, True)
	
	def link(self, elements):
		self.base_element = elements[self.base]
		
	def dependent_typedefs(self):
		return self.base_element.dependent_typedefs()


class GXMethod(GXElement):
	def __init__(self, elem):
		GXElement.__init__(self, elem)
		self.is_virtual = elem.getAttribute("virtual") == "1"
		
class GXDestructor(GXMethod):
	pass
class GXOperatorMethod(GXMethod):
	pass
	

class GXField(GXElement):
	def __init__(self, elem):
		GXElement.__init__(self, elem)
		self.name = elem.getAttribute("name")
		self.source_type = elem.getAttribute("type")
		self.bits = elem.getAttribute("bits")
	
	def declaration(self):
		decl = self.source_element.type_name(self.name, True)
		if self.bits:
			decl = decl + " : " + self.bits
		return decl + ";"
	
	def link(self, elements):
		self.source_element = elements[self.source_type]
		
	def dependent_typedefs(self):
		return self.source_element.dependent_typedefs()



class _GXAArgument(object):
	def __init__(self, elem):
		self.base = elem.getAttribute("type")
	def link(self, elements):
		self.base_element = elements[self.base]
	def typ(self):
		return self.base_element.type_name("", True)
	def dependent_typedefs(self):
		return self.base_element.dependent_typedefs()
		
class _GXAEllipsis(object):
	def __init__(self, elem):
		pass
	def link(self, elements):
		pass
	def typ(self):
		return "..."
	def dependent_typedefs(self):
		return frozenset()

class _GXAClass(_GXAArgument):
	def __init__(self, typid):
		self.base = typid
	def typ(self):
		return self.base_element.type_name("*this", True)

class GXFunctionType(GXElement):
	def __init__(self, elem):
		GXElement.__init__(self, elem)
		self.returns = elem.getAttribute("returns")
		self.arguments = list(get_class_with_name("_GXA" + a.tagName)(a) for a in elem.childNodes if a.nodeType == 1)
	
	def type_name(self, name, non_vtable):
		arglist = (t.typ() for t in self.arguments)
		return self.return_element.type_name(name + "(" + ", ".join(arglist) + ")", True)
	
	def link(self, elements):
		self.return_element = elements[self.returns]
		for x in self.arguments:
			x.link(elements)
	
	def dependent_typedefs(self):
		retval = [x.dependent_typedefs() for x in self.arguments]
		retval.append(self.return_element.dependent_typedefs())
		return frozenset.union(*retval)

class GXMethodType(GXFunctionType):
	def __init__(self, elem):
		GXFunctionType.__init__(self, elem)
		basetype = elem.getAttribute("basetype")
		self.arguments.insert(0, _GXAClass(basetype))

class GXConstructor(GXElement):
	pass
class GXVariable(GXElement):
	pass

# Topological sort functions, from http://www.logarithmic.net/pfh-files/blog/01208083168/sort.py
# 
# >>>>>>>>>>>>>>>>>>>> BEGIN >>>>>>>>>>>>>>>>>>>>
# 
#   Tarjan's algorithm and topological sorting implementation in Python
#
#   by Paul Harrison
#  
#   Public domain, do with it as you will
#

def strongly_connected_components(graph):
    """ Find the strongly connected components in a graph using
        Tarjan's algorithm.
        
        graph should be a dictionary mapping node names to
        lists of successor nodes.
        """
    
    result = [ ]
    stack = [ ]
    low = { }
        
    def visit(node):
        if node in low: return
	
        num = len(low)
        low[node] = num
        stack_pos = len(stack)
        stack.append(node)
	
        for successor in graph[node]:
            visit(successor)
            low[node] = min(low[node], low[successor])
        
        if num == low[node]:
            component = tuple(stack[stack_pos:])
            del stack[stack_pos:]
            result.append(component)
            for item in component:
                low[item] = len(graph)
    
    for node in graph:
        visit(node)
    
    return result


def topological_sort(graph):
    count = { }
    for node in graph:
        count[node] = 0
    for node in graph:
        for successor in graph[node]:
            count[successor] += 1
    
    ready = [ node for node in graph if count[node] == 0 ]
    
    result = [ ]
    while ready:
        node = ready.pop(-1)
        result.append(node)
        
        for successor in graph[node]:
            count[successor] -= 1
            if count[successor] == 0:
                ready.append(successor)
    
    return result


def robust_topological_sort(graph):
    """ First identify strongly connected components,
        then perform a topological sort on these components. """
    
    components = strongly_connected_components(graph)
    
    node_component = { }
    for component in components:
        for node in component:
            node_component[node] = component
    
    component_graph = { }
    for component in components:
        component_graph[component] = [ ]
    
    for node in graph:
        node_c = node_component[node]
        for successor in graph[node]:
            successor_c = node_component[successor]
            if node_c != successor_c:
                component_graph[node_c].append(successor_c) 
    
    return topological_sort(component_graph)

#
# <<<<<<<<<<<<<<<<<<<<< END <<<<<<<<<<<<<<<<<<<<<
#


def analyze(doc):
	gcc_elements = {}
	first_child = doc.firstChild
	assert first_child.tagName == "GCC_XML"
	
	# pass 1: read all interesting elements.
	for elem in first_child.childNodes:
		if elem.nodeType != 1:
			continue
		the_class = get_class_with_name("GX" + elem.tagName)
		if the_class is None:
			continue
		the_element = the_class(elem)
		gcc_elements[the_element.identity] = the_element
		
	# pass 2: linking.
	for elem in gcc_elements.values():
		elem.link(gcc_elements)
	
	# pass 3:
	#   (a) determine if some structs are virtual.
	#   (b) collect all typedefs and structs as a graph.
	gcc_structs = {}
	gcc_typedefs = {}
	for elem in gcc_elements.values():
		if isinstance(elem, GXTypedef):
			gcc_typedefs[elem] = elem.dependent_typedefs()
		elif isinstance(elem, GXStruct):
			if elem.name.find("_type_info_pseudo") == -1 or elem.name[:2] != "__": 
				elem.compute_vtable(gcc_elements)
				gcc_structs[elem] = elem.dependent_structs()
			
	# pass 4.1: print all enums first.
	for element in gcc_elements.values():
		if isinstance(element, GXEnumeration):
			print (element.declaration(), "\n")
	
	# pass 4.2: perform topological sort and output the typedefs and structs.
	gcc_structs_sorted = robust_topological_sort(gcc_structs)
	gcc_structs_sorted.reverse()
	gcc_typedefs_sorted = robust_topological_sort(gcc_typedefs)
	gcc_typedefs_sorted.reverse()
	for elem in gcc_typedefs_sorted:
		print (elem[0].declaration(), "\n")
	for elem in gcc_structs_sorted:
		print (elem[0].declaration(), "\n")
			

def main(argv=None):
	if argv is None:
		argv = sys.argv
	if len(argv) < 2:
		print ("Usage: print-struct-members.py <xml-file>")
	else:
		doc = parse(argv[1])
		try:
			analyze(doc)
		finally:
			doc.unlink()

if __name__ == "__main__":
	main()