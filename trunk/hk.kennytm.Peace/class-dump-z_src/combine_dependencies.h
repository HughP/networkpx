/*

combine_dependencies.h ... Just a convenient function used in 2 different modules.

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

#ifndef COMBINE_DEPENDENCIES_H
#define COMBINE_DEPENDENCIES_H

static void combine_dependencies( std::tr1::unordered_map<ObjCTypeRecord::TypeIndex, ObjCTypeRecord::EdgeStrength>& a, const std::tr1::unordered_map<ObjCTypeRecord::TypeIndex, ObjCTypeRecord::EdgeStrength>& b, std::tr1::unordered_map<ObjCTypeRecord::TypeIndex, unsigned>* p_ma_k_in = NULL, std::tr1::unordered_map<ObjCTypeRecord::TypeIndex, unsigned>* p_ma_strong_k_in = NULL ) {
	for (std::tr1::unordered_map<ObjCTypeRecord::TypeIndex, ObjCTypeRecord::EdgeStrength>::const_iterator bit = b.begin(); bit != b.end(); ++ bit) {
		std::pair<std::tr1::unordered_map<ObjCTypeRecord::TypeIndex, ObjCTypeRecord::EdgeStrength>::iterator, bool> res = a.insert(*bit);
		if (!res.second) {
			if (res.first->second < bit->second) {
				if (p_ma_strong_k_in != NULL && res.first->second < ObjCTypeRecord::ES_StrongIndirect)
					++ (*p_ma_strong_k_in)[bit->first];
				res.first->second = bit->second;
			}
		} else {
			if (p_ma_k_in != NULL)
				++ (*p_ma_k_in)[bit->first];
			if (p_ma_strong_k_in != NULL && bit->second >= ObjCTypeRecord::ES_StrongIndirect)
				++ (*p_ma_strong_k_in)[bit->first];
		}
	}
}

#endif
