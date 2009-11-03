/*

classDump.cy ... Runtime class dumper for Cycript.
Copyright (C) 2009  KennyTM~ <kennytm@gmail.com>

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

function $ot_Type(p_encoding) {
	var a = $ot_Type.split_balanced_substring(p_encoding[0]);
	this.type = a[0][0];
	p_encoding[0] = a[1];
	
	this.subtype = null;
	this.extra = null;
	this.refable = false;
	
	// id: @, @"abc", @"<abc>", @"abc<def>".
	if (this.type === '@') {
		if (a[1][0] === '"') {
			a = $ot_Type.split_balanced_substring(a[1]);
			this.extra = a[0].substr(1, a[0].length-2);
			p_encoding[0] = a[1];
		}
		
	// bitfield: b123
	} else if (this.type === 'b') {
		var intPart = /^\d+/.exec(a[1])[0];
		this.extra = intPart - 0;
		p_encoding[0] = a[1].substr(intPart.length);
	
	// nullary type e.g. int, long, char
	} else if (this.type in $ot_Type.nullary_map) {
		
	// unary type e.g. oneway void, char*, _Complex double
	} else if (this.type in $ot_Type.unary_map) {
		this.subtype = new $ot_Type(p_encoding);
	
	// Array [123x]
	} else if (this.type === '[') {
		var m = /^\[(\d+)(.+)\]$/.exec(a[0]);
		this.extra = m[1] - 0;
		this.subtype = new $ot_Type([m[2]]);
	
	// Unions & structs {?=123}
	} else if (this.type in $ot_Type.struct_map) {
		var anonhead = /^[\x7b\x28](?:\?|\$_\d+)(=?[\x29\x7d])?/.exec(a[0]);
		if (anonhead) {
			if (!anonhead[1])
				this.extra = "...";
		} else {
			this.extra = "";
			a[1] = a[0].substr(1);
			while(a[1][0] !== '=' && !(a[1][0] in $ot_Type.struct_close_map)) {
				a = $ot_Type.split_balanced_substring(a[1]);
				this.extra += a[0];
			}
			if (this.extra === "__sFILE")
				this.extra = "FILE";
			else {
				this.extra = this.extra.replace(/^_+/, "");
				if (a[1][0] in $ot_Type.struct_close_map || a[1][1] in $ot_Type.struct_close_map)
					this.refable = /^[A-Z]{3}/.test(this.extra) && this.extra.substr(0,2) != "NS";
			}
		}
	}
}

/** Split a string by balanced substring, e.g.
 f("abcde") = ["a", "bcde"]
 f("(abc)de") = ["(abc)", "de"]
 f("'ab(c'd)e") = ["'ab(c'", "d)e"]
 */
$ot_Type.split_balanced_substring = function(s) {
	var l = s.length;
	var balance = 0;
	var escmode = false, qmode = 0;
	for (var i = 0; i < l; ++ i) {
		switch (s[i]) {
			case '[': case '{': case '(': case '<':
				if (!qmode) ++ balance;
				else escmode = false;
				break;
				
			case ']': case '}': case ')': case '>':
				if (!qmode) -- balance;
				else escmode = false;
				break;
				
			case '"': case "'":
				var contra = s[i] == '"' ? 1 : 2;
				if (qmode === contra || escmode) escmode = false;
				else {
					if ((qmode = qmode ? 0 : 3-contra)) ++ balance;
					else -- balance;
				}
				break;
				
			case '\\':
				if (qmode) escmode = !escmode;
				break;
				
			default:
				if (qmode) escmode = false;
				break;
		}
		if (balance <= 0)
			return [s.substr(0, i+1), s.substr(i+1)];
	}
	return [s, ""];
}

$ot_Type.nullary_map = {
	'#': 'Class', '%': 'NXAtom', '*': 'char*', ':': 'SEL', 
	'?': '/*function-pointer*/ void', '@': 'id', 'B': 'bool',
	'C': 'unsigned char', 'I': 'unsigned', 'L': 'unsigned long', 
	'S': 'unsigned short', 'Q': 'unsigned long long', 'c': 'BOOL',
	'd': 'double', 'f': 'float', 'i': 'int', 'l': 'long', 'q': 'long long',
	's': 'short', 'v': 'void'
};

$ot_Type.unary_map = {
	'!': "/*gc-invisibile*/", 'N': "inout", 'O': "bycopy", 'R': "byref", 
	'V': "oneway", 'j': "_Complex", 'n': "in", 'o': "out", 'r': "const",
	'^': null
};

$ot_Type.struct_map = {'{': 'struct', '(': 'union'};
$ot_Type.struct_close_map = {'}': null, ')': null};

// left <space> middle <identifier> right
$ot_Type.prototype.decode_0 = function() {
	var tmp;
	var res = {left:"", middle:"", right:""};
	if (this.type === '@') {
		if (!this.extra)
			res.left = "id";
		else if (this.extra[0] === '<')
			res.left = "id" + this.extra;
		else {
			res.left = this.extra;
			res.middle = "*";
		}
	} else if (this.type === '*') {
		res.left = "char";
		res.middle = "*";
	} else if ((tmp = $ot_Type.nullary_map[this.type])) {
		res.left = tmp;
	} else if (this.type === '^') {
		res = this.subtype.decode_0();
		if (this.subtype.type == '[') {
			res.middle += "(*"
			res.right = ")" + res.right;
		} else {
			if (this.subtype.refable)
				res.left += "Ref";
			else
				res.middle += "*";
		}
	} else if ((tmp = $ot_Type.unary_map[this.type])) {
		res = this.subtype.decode_0();
		res.left = tmp + " " + res.left;
	} else if (this.type === '[') {
		res = this.subtype.decode_0();
		res.right = "[" + this.extra + "]" + res.right;
	} else if ((tmp = $ot_Type.struct_map[this.type])) {
		if (!this.extra)
			res.left = tmp + " {}";
		else if (this.extra === "...")
			res.left = tmp + " { ... }";
		else
			res.left = this.extra;
	} else if (this.type === 'b') {
		res.left = "int";
		res.right = " : " + this.extra;
	}
	return res;
}

$ot_Type.prototype.decode_1 = function(name) {
	var res = this.decode_0(false);
	if (!name)
		name = "";
	if (name || res.middle)
		return res.left + " " + res.middle + name + res.right;
	else
		return res.left + res.right;
}

function decodeType(encoding, name, str_left) {
	if (str_left instanceof Array)
		str_left[0] = encoding;
	else
		str_left = [encoding];
	var T = new $ot_Type(str_left);
	return T.decode_1(name);
}

function dumpIvar(obj) {
	var p_outCount = new new Type("I");
	var ivarList = class_copyIvarList([obj class], p_outCount);
	var outCount = *p_outCount;
	var ivarStatements = [];
	free(p_outCount);
	for (var i = 0; i < outCount; ++ i) {
		var ivar = ivarList[i];
		var name = ivar_getName(ivar);
		var enc = ivar_getTypeEncoding(ivar);
		ivarStatements.push(decodeType(enc, name));
	}
	free(ivarList);
	return "\t" + ivarStatements.join(";\n\t") + ";\n";
}

function dumpMethods(obj, re) {
	var cls = [obj class];
	var sym = class_isMetaClass(cls) ? '+' : '-';
	var p_outCount = new new Type("I");
	var methodList = class_copyMethodList(cls, p_outCount);
	var outCount = *p_outCount;
	var methodStatements = [];
	free(p_outCount);
	
	var tmp;
	for (var i = 0; i < outCount; ++ i) {
		var method = methodList[i];
		var name = sel_getName(method_getName(method));
		if (re && !re.test(name))
			continue;
		
		var typeEnc = method_getTypeEncoding(method);
		var rest = [typeEnc];
		var exploded = [];
		while (rest[0]) {
			exploded.push(decodeType(rest[0], null, rest));
			var digits = /^\d+/.exec(rest[0])[0];
			rest[0] = rest[0].substr(digits.length);
		}
		
		methodStatements.push(sym + "(" + exploded[0] + ")");
		var l = exploded.length;
		if (l == 3)
			methodStatements.push(name);
		else {
			var name_exploded = name.split(/:/);
			for (var j = 3; j < l; ++ j) {
				methodStatements.push(name_exploded[j-3] + ":(" + exploded[j] + ")arg" + (j-2));
				if (j != l-1)
					methodStatements.push(" ");
			}
		}
		
		methodStatements.push(";\n");
	}
	
	free(methodList);
	return methodStatements.join("");
}

function classDump(obj, re) {
	var cls = [obj class];
	var dumpRes = ["@interface ", cls.toString(), " : ", class_getSuperclass(cls).toString()];
	
	var p_outCount = new new Type("I");
	var prots = class_copyProtocolList(cls, p_outCount);
	var outCount = *p_outCount;
	free(p_outCount);
	var protlist = [];
	for (var i = 0; i < outCount; ++ i)
		protlist.push(protocol_getName(prots[i]));
	free(prots);
	if (protlist.length) {
		dumpRes.push("<" + protlist.join(", ") + ">");
	}
	
	if (!re) {
		dumpRes.push(" {\n");
		dumpRes.push(dumpIvar(cls));
		dumpRes.push("}\n");
	} else
		dumpRes.push("\n");
	
	dumpRes.push(dumpMethods(cls->isa, re));
	dumpRes.push(dumpMethods(cls, re));
	dumpRes.push("@end\n");
	
	return dumpRes.join("");
}
