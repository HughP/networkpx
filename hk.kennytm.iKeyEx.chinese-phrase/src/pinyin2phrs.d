// Obligatory: Written in D programming language.
/*

pinyin2phrs.d ... Convert phrase_lib.txt from scim-pinyin into .phrs format.

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
import std.typetuple;
import std.array;

struct TTSU {
	string st;
	uint fr;

	this(string s, uint f) { st = s; fr = f; }
}

void main (string[] args) {
	if (args.length < 3) {
		writeln("Usage: pinyin2phrs <pinyin.txt> <res.phrs>");
	} else {
		auto inCharsMode = true;
		auto f = new File(args[1], "r");
		
		auto freqsAppender = appender!(TTSU[])(null);
		
		foreach (line; f.byLine) {
			if (inCharsMode) {
				if (line == "0")
					inCharsMode = false;
			} else {
				auto firstTab = line.indexOf('\t');
				auto str = line[0..firstTab];
				if (toUTF32(str).length == 1)
					break;
				auto rest = line[firstTab+1..$];
				auto freq = parse!uint(rest);
				freqsAppender.put(TTSU(str.idup, freq));
			}
		}
		f.close();
		
		auto res = freqsAppender.data;
		sort!( (a,b){ return a.fr > b.fr; } )(res);
		
		auto g = new File(args[2], "w");
		foreach (pair; res)
			g.writeln(pair.st);
		g.close();
	}

}