/*
 
std.cy ... Some useful Cycripts.

Copyright (c) 2009  KennyTM~ <kennytm@gmail.com>
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice, 
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.
* Neither the name of the KennyTM~ nor the names of its contributors may be
  used to endorse or promote products derived from this software without
  specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

*/

// include other .cy files
if (!this.include) {
  function include(fn) {
    var t = [new NSTask init]; [t setLaunchPath:@"/usr/bin/cycript"]; [t setArguments:["-c", fn]];
    var p = [NSPipe pipe]; [t setStandardOutput:p]; [t launch]; [t waitUntilExit];  [t release];
    var s = [new NSString initWithData:[[p fileHandleForReading] readDataToEndOfFile] encoding:4];
    var r = this.eval(s.toString()); [s release]; return r;
  }
}

// Usage: dlfun("notify_post", "I*")
function dlfun(fn, encoding, altname) { var f = new Functor(dlsym(RTLD_DEFAULT, fn), encoding); if (f) this[altname || fn] = f; return f; }

dlfun("nlist", "i*^{nlist=^cCCsI}");
dlfun("memset", "^v^viI");

function FW(name, notbin) {
	var px = "/System/Library/", sx = "Frameworks/" + name + ".framework";
	var mid = [[NSFileManager defaultManager] fileExistsAtPath:px + sx] ? "" : "Private";
	return px + mid + sx + (notbin ? "" : "/" + name);
}

// Usage:
//   var f = nlsym(FW("UIKit"), "_UpdateSystemSoundActiveStatus");
//   UpdateSystemSoundActiveStatus = new Functor(f, "v");
function nlsym(path, symname) {
	var nl = new new Type("[2{nlist=^cCCsI}]"); memset(nl, 0, 24); var l = symname.length; var k = new char[l+1];
	for (var i = 0; i < l; ++ i) k[i] = symname.charCodeAt(i); k[l] = 0; nl[0][0] = k; nlist(path, nl);
	var rv = nl[0][4] + (nl[0][3] & 8 ? 1 : 0); free(nl); free(k); return rv;
}

// Usage: nlfun(FW("AudioToolbox"), "__ZL9PlaySoundmbb", "vLBB", "PlaySound")
function nlfun(path, symname, encoding, altname) { var f = new Functor(nlsym(path, symname), encoding); if (f) this[altname || symname] = f; return f; }

// Standard C functions
function CGPointMake(x, y) { return {x:x, y:y}; }
function CGSizeMake(w, h) { return {width:w, height:h}; }
function CGRectMake(x, y, w, h) { return {origin:CGPointMake(x,y), size:CGSizeMake(w, h)}; }
function NSMakeRange(loc, len) { return {location:loc, length:len}; }
CFRangeMake = NSMakeRange;
 
// Standard C types
IMP = new Type("^?"), SEL = new Type(":"), unsigned = new Type("I");
int8_t = char, int16_t = short, int32_t = long, int64_t = new Type("q");
uint8_t = new Type("C"), uint16_t = new Type("S"), uint32_t = new Type("L"), uint64_t = new Type("Q");
SInt8 = int8_t, SInt16 = int16_t, SInt32 = int32_t, SInt64 = int64_t;
UInt8 = uint8_t, UInt16 = uint16_t, UInt32 = uint32_t, UInt64 = uint64_t;
unichar = int16_t, UniChar = int16_t, wchar_t = int32_t;
size_t = NSUInteger, intptr_t = NSInteger;
BOOL = char, bool = new Type("B");
mach_port_t = int, pid_t = int32_t;
CGRect = new Type("{CGRect}"), CGSize = new Type("{CGSize}"), CGPoint = new Type("{CGPoint}");
NSRange = new Type("{NSRange}"), CFRange = new Type("{CFRange}");
CGAffineTransform = new Type("{CGAffineTransform}"), UIEdgeInsets = new Type("{UIEdgeInsets}");
 
// Standard enum values
UIControlStateNormal = 0, UIControlStateHighlighted = 1 << 0, UIControlStateDisabled = 1 << 1,
UIControlStateSelected = 1 << 2, UIControlStateApplication = 0x00FF0000, UIControlStateReserved = 0xFF000000;
  
// MobileSubstrate
dlfun("MSHookMessageEx", "v#:^?^^?");
dlfun("MSHookMessage", "^?#:^?*");
dlfun("MSHookFunction", "v^v^v^^v");
dlfun("_Z8MSLogHexPKvmPKc", "v^vL*", "MSLogHex");
 
// Declare a struct
// e.g. var CGSize = struct(CGFloat, CGFloat);
function struct(n) {
  var typestr = ["{?="];
  for (var i = 0; i < arguments.length; ++ i) {
    var arg = arguments[i];
    typestr.push(arguments[i].toString());
  }
  typestr.push("}");
  return new Type(typestr.join(""));
}
 
// Hack!
function quit() { MSHookFunction(dlsym(RTLD_DEFAULT, "readline"), new Functor(function(x){return null;}, "**"), null); }
 
// Usage: $encode("int*") --> new Type("^i").
// Cannot handle structs, unions and function pointers yet. 
function $encode(ss, dontKeepClassName) {
 function _encode(s) {
  s = s.replace(/\s{2,}/g, " ").replace(/^\s|\s$/g, "").replace(/(\W)\s|\s(\W)/g, "$1$2")
  var m;
  if ((m = /\((\*+)\)\[(\d*)\]/.exec(s))) {
    var left = s.substr(0, m.index), right = s.substr(m.index + m[0].length);
    var t = _encode(left+right), px = m[1].replace(/\*/g, "^");
    if (m[2]) return px + "[" + m[2] + t + "]";
    else      return px + "^" + t;
  } else if ((m = /\[(\d*)\]$/.exec(s))) {
    var t = _encode(s.substr(0, m.index));
    if (m[1]) return "[" + m[1] + t + "]";
    else      return "^" + t;
  } else if ((m = /\*+$/.exec(s))) {
    var t = _encode(s.substr(0, m.index));
    var px = m[0].replace(/\*/g, "^");
    if (t[0] == '1') { px = px.substr(1); t = t.substr(1); }
    return px+t;
  } else if ((m = /:(\d+)$/.exec(s))) {
    return "b" + m[1];
  } else {
    var prefix = "", longcount = 0, isunsigned = null, theType = "";
    for each (comp in s.split(/\s/)) {
      if ((mod = _encode.modifiers[comp])) prefix += mod;
      else if (comp == "unsigned") isunsigned = true;
      else if (comp == "signed")   isunsigned = false;
      else if (comp == "long")  ++ longcount;
      else if (comp == "short") -- longcount;
      else if (comp == "void") theType = "v";
      else if ((typ = this[comp])) {
        if (typ instanceof Type) theType = typ.toString();
        else theType = dontKeepClassName ? "1@" : "1@\"" + typ.toString() + "\"";
      } else theType = "{" + comp + "}";
    }
    if (theType == "" || theType == "i") {
      if (longcount < 0) theType = "s";
      else if (longcount == 1) theType = "l";
      else if (longcount >= 2) theType = "q";
    }
    if (isunsigned !== null && theType[0] !== '1' && theType[0] !== '{')
      theType = theType[isunsigned ? 'toUpperCase' : 'toLowerCase']();
    return prefix + theType;
  }
 }
 _encode.modifiers = {
  "inout": "N", "bycopy": "O", "byref": "R", "oneway": "V",
  "_Complex": "j", "in": "n", "out": "o", "const": "r"
 };
 return ss instanceof Type ? ss : new Type(_encode(ss).replace(/\^c/g, "*"));
}
 
 
/* 
Usage:
 
addMethod(UIWindow, "-(void)setAutorotates:(BOOL)autorotates forceUpdateInterfaceOrientation:(BOOL)orientation", function(autorotates, orientation){});
 
Bug: [super xxx] doesn't work by default. You need to call
  $cyr = new Super(this, @selector(...));
yourself.
*/
function addMethod(cls, decl, func) {
  if (/^\s*\+/.test(decl)) cls = cls->isa;
  var typeMatcher = /\(([^)]+)\)/g, selMatcher = /[\s\)]([^:\s]+)\s*:/g
  var typestr = "", typecount = 0;
  var selname = "";
  var m;
  while ((m = typeMatcher.exec(decl))) {
    typestr += $encode(m[1], true).toString();
    if (++typecount == 1) typestr += "@:";
  }
  if (typecount == 1) selname = /\)(.+)$/.exec(decl)[0];
  else {
    while ((m = selMatcher.exec(decl))) selname += m[1] + ":";
  }
  selname = selname.replace(/\s/g, "");
  return class_addMethod(cls, new Selector(selname), new Functor(function(self,_cmd){
    return func.apply(self,Array.prototype.slice.call(arguments,2));
  }, typestr), typestr);
}

