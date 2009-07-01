/*

FILE_NAME ... DESCRIPTION

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

#include "lazy_reachability_matrix.h"
#include <algorithm>

using namespace std;

LazyReachabilityMatrix::LazyReachabilityMatrix(const vector<vector<pair<unsigned, unsigned> > >& adjacency_list) throw() :
	adjlist(&adjacency_list), network_size(adjacency_list.size()), visited(network_size, 0), reachability(network_size*network_size, 0) {}

void LazyReachabilityMatrix::union_(const unsigned copy_to, const unsigned copy_from, const unsigned max_level) {
	for (unsigned i = 0; i < network_size; ++ i) {
		unsigned fi = copy_from * network_size + i, ti = copy_to * network_size + i;
		if (reachability[ti] < max_level)
			if (reachability[ti] < reachability[fi]) {
				if (reachability[fi] <= max_level)
					reachability[ti] = reachability[fi];
				else
					reachability[ti] = max_level;
			}
	}
}

void LazyReachabilityMatrix::visit(std::pair<unsigned, unsigned> vl, vector<pair<unsigned,unsigned> >& ancestors) throw() {
	unsigned current_min_level = vl.second;
	
	// Every ancestors of the DFS tree can reach v.
	for (vector<pair<unsigned,unsigned> >::const_reverse_iterator rcit = ancestors.rbegin(); rcit != ancestors.rend(); ++ rcit) {
		if (vl.first == rcit->first)
			break;
		unsigned matrix_index = rcit->first * network_size + vl.first;
		if (current_min_level > rcit->second)
			current_min_level = rcit->second;
		if (reachability[matrix_index] < current_min_level)
			reachability[matrix_index] = current_min_level;
	}
	
	if (visited[vl.first]) {
		// and also v's reachable nodes.
		current_min_level = vl.second;
		for (vector<pair<unsigned,unsigned> >::const_reverse_iterator rcit = ancestors.rbegin(); rcit != ancestors.rend(); ++ rcit) {
			if (vl.first == rcit->first)
				break;
			if (current_min_level > rcit->second)
				current_min_level = rcit->second;
			union_(rcit->first, vl.first, current_min_level);
		}
	} else {
		visited[vl.first] = 1;
		
		ancestors.push_back(vl);
		for (vector<pair<unsigned, unsigned> >::const_iterator cit = (*adjlist)[vl.first].begin(); cit != (*adjlist)[vl.first].end(); ++ cit)
			visit(*cit, ancestors);
		ancestors.pop_back();
	}
}

unsigned LazyReachabilityMatrix::reach(unsigned from, unsigned to) throw() {
	if (!visited[from]) {
		vector<pair<unsigned,unsigned> > anc;
		visit(pair<unsigned,unsigned>(from, ~0u), anc);
	}
	return reachability[from * network_size + to];
}