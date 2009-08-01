/*

hash_combine.h ... Combine 2 hash values using Boost's algorithm.

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

#ifndef BOOST_FUNCTIONAL_HASH_HASH_HPP

#ifndef HASH_COMBINE_H
#define HASH_COMBINE_H

template <typename T>
static inline void hash_combine(size_t& seed, const T& v) {
	seed ^= 0x9e3779b9 + (seed << 6) + (seed >> 2) + std::tr1::hash<T>()(v);
}

#if _MSC_VER
#include <vector>
namespace std {
	namespace tr1 {
		template <typename U>
		struct hash<::std::vector<U> > : public unary_function<::std::vector<U>, size_t> {
			size_t operator() (const ::std::vector<U>& v) {
				size_t res = 0;
				for (::std::vector<U>::const_iterator cit = v.begin(); cit != v.end(); ++ cit)
					hash_combine(res, *cit);
				return res;
			}
		};
	}
}
#endif

#endif

#endif
