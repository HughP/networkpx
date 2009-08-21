// Obligatory: Written in D programming language.
/*

tsi2phrs.d ... Convert tsi.src from libchewing into .phrs format.

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

import std.stdio;
import std.string;
import std.algorithm;
import std.conv;
import std.utf;

void main (string[] args) {
	if (args.length < 3) {
		writeln("Usage: tsi2phrs <tsi.src> <res.phrs>");
	} else {
		auto f = new File(args[1], "r");
		uint[string] stringFreq;
		
		// 1. Collect data from file. Consolidate if needed.
		foreach (line; f.byLine) {
			auto splitted = split(line.idup);
			auto str = splitted[0];
			if (toUTF32(str).length == 1)
				continue;
			auto hasFreq = false;
			foreach (possible_freq; splitted[1..$]) {
				if (isNumeric(possible_freq)) {
					stringFreq[str] += to!uint(possible_freq);
					hasFreq = true;
					break;
				}
			}
			if (!hasFreq && !(str in stringFreq))
				stringFreq[str] = 0;
		}
		f.close();
		
		// 2. Sort by frequency.
		auto sorted = stringFreq.keys;
		
		schwartzSort!( delegate uint(string s) { return stringFreq[s]; }, "a>b")(sorted);
		
		// 3. Print the file.
		auto g = new File(args[2], "w");
		foreach (str; sorted)
			g.writeln(str);
		g.close();
	}
}