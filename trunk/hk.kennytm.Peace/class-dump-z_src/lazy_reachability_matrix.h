/*

transitive_closure.h ... Computes the transitive closure matrix for the class usage network in class-dump-z.

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

#ifndef TRANSITIVE_CLOSURE_H
#define TRANSITIVE_CLOSURE_H

#include <vector>

class LazyReachabilityMatrix {
	// input
	const std::vector<std::vector<std::pair<unsigned, unsigned> > >* adjlist;	// id, level.
	unsigned network_size;
	
	std::vector<char> visited;
	std::vector<unsigned> reachability;	// the content is the maximum lowest level you can reach in every possible path.
	
	void union_(const unsigned to, const unsigned from, const unsigned max_level);
	
	void visit(std::pair<unsigned, unsigned> vl, std::vector<std::pair<unsigned,unsigned> >& ancestors) throw();
	
public:
	LazyReachabilityMatrix() {}
	LazyReachabilityMatrix(const std::vector<std::vector<std::pair<unsigned, unsigned> > >& adjacency_list) throw();
	
	unsigned size() const throw() { return network_size; }
	
	unsigned reach(unsigned from, unsigned to) throw();
};
#endif