/*

UIKBKeyboardFromLayoutPlist ... Convert a layout.plist to UIKBKeyboard.
 
Copyright (c) 2009, KennyTM~
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

#import <UIKit/UIKit2.h>

extern UIKBKeyboard* (*UIKBGetKeyboardByName) (NSString* name);

static inline BOOL sublayoutAutoshiftable(NSString* sublayoutKey) {
	return ([@"URL" isEqualToString:sublayoutKey] || [@"Alphabet" isEqualToString:sublayoutKey] || [@"EmailAddress" isEqualToString:sublayoutKey]);
}
static inline BOOL sublayoutLooksLikeShiftAlternate(NSString* sublayoutKey) {
	return !([@"Numbers" isEqualToString:sublayoutKey] || [@"PhonePad" isEqualToString:sublayoutKey] || [@"URLAlt" isEqualToString:sublayoutKey] || [@"EmailAddressAlt" isEqualToString:sublayoutKey]);
}
static inline NSString* sublayoutMoreAlternate(NSString* sublayoutKey) {
	if ([sublayoutKey isEqualToString:@"Alphabet"])
		return @"Numbers";
	else if ([sublayoutKey isEqualToString:@"Numbers"])
		return @"Alphabet";
	else if ([sublayoutKey hasSuffix:@"Alt"])
		return [sublayoutKey substringToIndex:[sublayoutKey length]-3];
	else
		return [sublayoutKey stringByAppendingString:@"Alt"];
}
static inline NSString* sublayoutMoreRendering(NSString* sublayoutKey) {
	if ([sublayoutKey isEqualToString:@"Alphabet"])
		return @"numbers";
	else if ([sublayoutKey isEqualToString:@"Numbers"] || [sublayoutKey hasSuffix:@"Alt"])
		return @"letters";
	else if ([sublayoutKey isEqualToString:@"URL"] || [sublayoutKey isEqualToString:@"EmailAddress"])
		return @"symbols";
	else if ([sublayoutKey isEqualToString:@"SMSAddressing"])
		return @"phonepad";
	else
		return @"numbers";
}
static inline BOOL sublayoutShiftIsPlaneChooser(NSString* sublayoutKey) {
	return ([sublayoutKey isEqualToString:@"Numbers"] || [sublayoutKey hasSuffix:@"Alt"]);
}
static inline NSString* sublayoutShiftRendering(NSString* sublayoutKey, BOOL shifted) {
	if ([@"URL" isEqualToString:sublayoutKey] || [@"Alphabet" isEqualToString:sublayoutKey] || [@"EmailAddress" isEqualToString:sublayoutKey] || [@"SMSAddressing" isEqualToString:sublayoutKey])
		return @"letters";
	else
		return shifted ? @"numbers" : @"symbols";
}
static inline NSArray* sublayoutSupportedTypes(NSString* sublayoutKey, BOOL shifted) {
	if ([@"PhonePad" isEqualToString:sublayoutKey] || [@"PhonePadAlt" isEqualToString:sublayoutKey])
		return [NSArray arrayWithObject:@"UIKeyboardTypePhonePad"];
	else if ([@"Numbers" isEqualToString:sublayoutKey] || [sublayoutKey hasSuffix:@"Alt"])
		return [NSArray arrayWithObject:@"UIKeyboardTypeNumbersAndPunctuation"];
	else if ([@"NumberPad" isEqualToString:sublayoutKey])
		return [NSArray arrayWithObject:@"UIKeyboardTypeNumberPad"];
	else {
		NSMutableArray* res = [NSMutableArray array];
		if (shifted)
			[res addObject:@"UIKeyboardTypeDefault"];
		if ([@"URL" isEqualToString:sublayoutKey])
			[res addObject:@"UIKeyboardTypeURL"];
		else if ([@"SMSAddressing" isEqualToString:sublayoutKey])
			[res addObject:@"UIKeyboardTypeNamePhonePad"];
		else if ([@"Alphabet" isEqualToString:sublayoutKey])
			[res addObject:@"UIKeyboardTypeASCIICapable"];
		else if ([@"EmailAddress" isEqualToString:sublayoutKey])
			[res addObject:@"UIKeyboardTypeEmailAddress"];
		return res;	
	}
}

#pragma mark -

static NSString* translators[] =     {@"texts", @"shiftedTexts", @"labels", @"shiftedLabels", @"popups", @"shiftedPopups"};
static NSString* referedKey[] =      {@"texts", @"texts",        @"texts",  @"shiftedTexts",  @"labels", @"shiftedLabels"};
static BOOL keyRequiresUppercase[] = {NO,       YES,             YES,       NO,               NO,        NO              };

static int translateString (NSString* key) {
	for (int i = 0; i < sizeof(translators)/sizeof(NSString*); ++ i)
		if (translators[i] == key || [translators[i] isEqualToString:key])
			return i;
	return 0;
}

static inline NSString* referedKeyOf(NSString* key) { return referedKey[translateString(key)]; }

__attribute__((pure))
static inline BOOL betterDontCapitalize(unichar c) {
	switch (c) {
		case L'ß':
		case L'ĸ':
		case L'ſ':
		case L'ς':
		case L'ϑ':
		case L'ϕ':
		case L'ϖ':
		case L'ϗ':
			return YES;
		default:
			return NO;
	}
}

static inline NSString* getUppercaseCharacter(NSString* s) {
	if ([s length] == 1 && !betterDontCapitalize([s characterAtIndex:0]))
		return [s uppercaseString];
	else
		return s;
}

static NSArray* tryUppercase(NSString* key, NSArray* srcArr) {
	if (srcArr == nil)
		return nil;
	if (keyRequiresUppercase[translateString(key)]) {
		NSMutableArray* retArr = [NSMutableArray array];
		for (NSString* s in srcArr) {
			if ([s isKindOfClass:[NSDictionary class]]) {
				NSMutableDictionary* dictCopy = [s mutableCopy];
				NSString* upStr = getUppercaseCharacter([(NSDictionary*)s objectForKey:@"text"]);
				if (upStr)
					[dictCopy setObject:upStr forKey:@"text"];
				[retArr addObject:dictCopy];
				[dictCopy release];
			} else
				[retArr addObject:getUppercaseCharacter(s)];
		}
		return retArr;
	} else
		return srcArr;
}

#define RecursionLimit 8
static NSArray* fetchTextRow(NSString* curKey, NSUInteger row, NSDictionary* sublayout, NSDictionary* layoutDict, unsigned depth) {
recurse:
	// too deep. break out by returning nothing.
	if (depth >= RecursionLimit)
		return nil;
	
	NSArray* allRows = [sublayout objectForKey:curKey];
	if ([allRows count] <= row) {
		if (![curKey isEqualToString:@"texts"]) {
			return tryUppercase(curKey, fetchTextRow(referedKeyOf(curKey), row, sublayout, layoutDict, depth+1));
		} else
			return nil;
	}
	NSArray* rowContent = [allRows objectAtIndex:row];
	
	if ([rowContent isKindOfClass:[NSArray class]])
		// really an array.
		// but ignore empty arrays.
		return [rowContent count] > 0 ? rowContent : nil;
	
	else if ([rowContent isKindOfClass:[NSString class]]) {
		if ([(NSString*)rowContent length] > 0) {
			NSString* firstChar = [(NSString*)rowContent substringToIndex:1];
			NSString* rest = [(NSString*)rowContent substringFromIndex:1];
			if (![firstChar isEqualToString:@"="]) {
				// concat'd string. split it and return
				return [rest componentsSeparatedByString:firstChar];
			} else {
				// refered object.
				// test if the row index is explicitly stated.
				NSRange leftBrac = [rest rangeOfString:@"["];
				NSString* refSublayoutKey = rest;
				NSUInteger specificRow = row;
				if (leftBrac.location != NSNotFound) {
					specificRow = [[rest substringFromIndex:leftBrac.length+leftBrac.location] integerValue];
					refSublayoutKey = [rest substringToIndex:leftBrac.location];
				}
				NSDictionary* refSublayout = sublayout;
				if ([refSublayoutKey length] != 0)
					refSublayout = [layoutDict objectForKey:refSublayoutKey];
				if (refSublayout == sublayout) {
					return tryUppercase(curKey, fetchTextRow(referedKeyOf(curKey), specificRow, refSublayout, layoutDict, depth+1));
				} else {
					row = specificRow;
					sublayout = refSublayout;
					++ depth;
					goto recurse;
				}
			}
		} else
			return nil;
	}
	
	curKey = referedKeyOf(curKey);
	++ depth;
	goto recurse;
}

static UIKBKeyplane* copyKeyplane(UIKBKeyplane* plane) {
	UIKBKeyplane* newPlane = [UIKBKeyplane keyplane];
	newPlane.keylayouts = plane.keylayouts;
	newPlane.attributes = plane.attributes;
	newPlane.supportedTypes = plane.supportedTypes;
	return newPlane;
}

static UIKBKeyplane* constructUIKBKeyplaneFromSublayout(NSMutableDictionary* layoutPlist, NSString* sublayoutKey, BOOL shifted, BOOL isLandscape) {
	NSMutableDictionary* sublayout = [layoutPlist objectForKey:sublayoutKey];
	
	NSString* shiftedName = [sublayoutKey stringByAppendingString:@"-shifted"];
	NSString* moreAltName = sublayoutMoreAlternate(sublayoutKey);
	
	if (sublayout == nil) {
		UIKBKeyplane* retval = nil;
		if ([sublayoutKey isEqualToString:@"Alphabet"]) {
			UIKBKeyboard* kb = UIKBGetKeyboardByName(isLandscape ? @"iPhone-Landscape-QWERTY" : @"iPhone-Portrait-QWERTY");
			retval = [kb keyplaneWithName:(shifted ? @"Capital-Letters" : @"Small-Letters")];
		} else if ([sublayoutKey isEqualToString:@"Numbers"]) {
			UIKBKeyboard* kb = UIKBGetKeyboardByName(isLandscape ? @"iPhone-Landscape-QWERTY" : @"iPhone-Portrait-QWERTY");
			retval = [kb keyplaneWithName:(shifted ? @"Numbers-And-Punctuation-Alternate" : @"Numbers-And-Punctuation")];
		} else if ([sublayoutKey isEqualToString:@"PhonePad"] || [sublayoutKey isEqualToString:@"PhonePadAlt"]) {
			UIKBKeyboard* kb = UIKBGetKeyboardByName(isLandscape ? @"iPhone-Landscape-PhonePad" : @"iPhone-Portrait-PhonePad");
			retval = [kb keyplaneWithName:(shifted ? @"Alternate" : @"Default")];
		} else if ([sublayoutKey isEqualToString:@"NumberPad"]) {
			UIKBKeyboard* kb = UIKBGetKeyboardByName(isLandscape ? @"iPhone-Landscape-NumberPad" : @"iPhone-Portrait-NumberPad");
			retval = [kb.keyplanes objectAtIndex:0];
		} else if ([sublayoutKey isEqualToString:@"URL"] || [sublayoutKey isEqualToString:@"EmailAddress"] || [sublayoutKey isEqualToString:@"SMSAddressing"])
			retval = copyKeyplane(constructUIKBKeyplaneFromSublayout(layoutPlist, @"Alphabet", shifted, isLandscape));
		else if ([sublayoutKey isEqualToString:@"URLAlt"] || [sublayoutKey isEqualToString:@"EmailAddressAlt"])
			retval = copyKeyplane(constructUIKBKeyplaneFromSublayout(layoutPlist, @"Numbers", shifted, isLandscape));
		else if ([sublayoutKey isEqualToString:@"SMSAddressingAlt"]) {
			UIKBKeyboard* kb = UIKBGetKeyboardByName(isLandscape ? @"iPhone-Landscape-QWERTY-NamePhonePad" : @"iPhone-Portrait-QWERTY-NamePhonePad");
			retval = [kb keyplaneWithName:@"Numbers"];
		}
		retval.name = shifted ? shiftedName : sublayoutKey;
		UIKBAttributeList* attribList = retval.attributes;
		[attribList setValue:moreAltName forName:@"more-alternate"];
		[attribList setValue:(shifted ? sublayoutKey : shiftedName) forName:@"shift-alternate"];
		return retval;
	}
	
	NSString* inherits = [sublayout objectForKey:@"inherits"];
	for (int depth = 0; depth < RecursionLimit; ++ depth) {
		if (inherits != nil) {
			NSDictionary* inherited_sublayout = [layoutPlist objectForKey:inherits];
			for (NSString* key in inherited_sublayout) {
				if ([sublayout objectForKey:key] == nil)
					[sublayout setObject:[inherited_sublayout objectForKey:key] forKey:key];
			}
			inherits = [inherited_sublayout objectForKey:@"inherits"];
		} else
			break;
	}
	
	NSNumber* rowCount = [sublayout objectForKey:@"rows"];
	unsigned rows;
	if (rowCount != nil) {
		rows = [rowCount integerValue];
		if (rows == 1)
			rows = 2;
		else if (rows == 0)
			rows = 4;
	} else
		rows = 4;
	
	// The key height in portrait is 42 px with 12 px padding. 
	// The key height in landscape is 35px with 5 px padding. 
	// So it's like 5%, 20%, 5%, 20%, etc.
	// We force the spacings to be, in priority:
	
#pragma mark Phase 1: Define the attributes.
	
	UIKBAttributeList* attribs = [UIKBAttributeList new];
	
	BOOL autoshiftable = !shifted && sublayoutAutoshiftable(sublayoutKey);
	
	NSNumber* adoptiveNumber = [sublayout objectForKey:@"usesKeyCharges"];
	BOOL adoptive;
	if (adoptiveNumber != nil)
		adoptive = [adoptiveNumber boolValue];
	else
		adoptive = autoshiftable && rows<=4;
	NSString* shiftRendering;
	NSString* requiredShiftRendering = [sublayout objectForKey:@"shiftStyle"];
	if (requiredShiftRendering != nil) {
		if ([@"123" isEqualToString:requiredShiftRendering])
			shiftRendering = @"numbers";
		else if ([@"Symbol" isEqualToString:requiredShiftRendering])
			shiftRendering = @"symbols";
		else
			shiftRendering = @"letters";
	} else
		shiftRendering = sublayoutShiftRendering(sublayoutKey, shifted);
	
	[attribs setBoolValueForName:autoshiftable forName:@"autoshift"];
	[attribs setBoolValueForName:adoptive forName:@"adaptive-keys"];
	[attribs setValue:moreAltName forName:@"more-alternate"];
	[attribs setValue:sublayoutMoreRendering(sublayoutKey) forName:@"more-rendering"];
	[attribs setValue:(shifted?@"yes":@"no") forName:@"shift"];
	[attribs setValue:(shifted?sublayoutKey:shiftedName) forName:@"shift-alternate"];
	[attribs setBoolValueForName:sublayoutShiftIsPlaneChooser(sublayoutKey) forName:@"shift-is-plane-chooser"];
	[attribs setValue:shiftRendering forName:@"shift-rendering"];
	attribs.explicit = YES;
	
	UIKBKeyplane* plane = [UIKBKeyplane keyplane];
	plane.attributes = attribs;
	plane.name = shifted ? shiftedName : sublayoutKey;
	[attribs release];
	
#pragma mark Phase 2: Arrangements.
	unsigned* counts = alloca(rows * sizeof(unsigned));
	NSObject* arrangement = [sublayout objectForKey:@"arrangement"];
	if ([arrangement isKindOfClass:[NSArray class]]) {
		NSUInteger i = 0;
		for (NSNumber* n in (NSArray*)arrangement) {
			counts[i] = [n integerValue];
			++ i;
			if (i >= rows)
				break;
		}
	} else {
		// legacy support for strings...
		NSUInteger r0 = 10, r1 = 9, r2 = 7, r3 = 3;
		if ([arrangement isKindOfClass:[NSString class]]) {
			NSString* theStr = [(NSString*)arrangement lowercaseString];
			if ([theStr hasPrefix:@"withurlrow4|"]) {
				// gcc should be able to remove the strlen during optimization.
				theStr = [theStr substringFromIndex:strlen("withurlrow4|")];
			} else if ([theStr hasSuffix:@"|withurlrow4"]) {
				theStr = [theStr substringToIndex:[theStr length]-strlen("|withurlrow4")];
			}
			
			if ([theStr isEqualToString:@"azerty"]) {
				r0 = 10; r1 = 10; r2 = 6;
			} else if ([theStr isEqualToString:@"russian"]) {
				r0 = 11; r1 = 11; r2 = 9;
			} else if ([theStr isEqualToString:@"alt"]) {
				r0 = 10; r1 = 10; r2 = 5;
			} else if ([theStr isEqualToString:@"urlalt"]) {
				r0 = 10; r1 = 6; r2 = 4;
			} else if ([theStr isEqualToString:@"japaneseqwerty"]) {
				r0 = 10; r1 = 10; r2 = 7;
			}
		}
		
		counts[rows-1] = r3;
		if (rows >= 2) counts[rows-2] = r2;
		if (rows > 3)
			counts[rows-3] = r1;
		else if (rows == 3)
			counts[1] = r1;
		counts[0] = r0;
		for (NSUInteger i = 1; i <= rows-4; ++i)
			counts[i] = r0;
	}
	
#pragma mark Phase 3: Fetch texts & stuff.
	// fetch texts & stuff.
	NSArray** texts = alloca(rows * sizeof(NSArray*));
	NSArray** shiftedTexts = alloca(rows * sizeof(NSArray*));
	NSArray** labels = alloca(rows * sizeof(NSArray*));
	NSArray** shiftedLabels = alloca(rows * sizeof(NSArray*));

#define DoFetch(var) for(unsigned i = 0; i < rows; ++ i) \
	var[i] = fetchTextRow(@#var, i, sublayout, layoutPlist, 0)
	DoFetch(texts);
	DoFetch(shiftedTexts);
	DoFetch(labels);
	DoFetch(shiftedLabels);
#undef DoFetch
		
	NSMutableArray* keylists = [NSMutableArray array];
	for (unsigned i = 0; i < rows; ++ i) {
		UIKBKeylist* list = [UIKBKeylist keylist];
		list.name = [NSString stringWithFormat:@"Row%u", i];
		
		NSArray* textArr = (shifted ? shiftedTexts : texts)[i];
		NSArray* labelArr = (shifted ? shiftedLabels : labels)[i];
		
		unsigned count = MIN([textArr count], [labelArr count]);
		
		if (count == 0) {
			continue;
		}
		
		NSMutableArray* keys = [NSMutableArray array];
		for (unsigned j = 0; j < counts[i]; ++ j) {
			UIKBKey* key = [UIKBKey key];
			if (j < count) {
				NSString* str = [textArr objectAtIndex:j];
				if ([str isKindOfClass:[NSDictionary class]])
					str = [(NSDictionary*)str objectForKey:@"text"];
				
				key.name = str;
				key.representedString = str;
				
				NSString* lbl = [labelArr objectAtIndex:j];
				if ([lbl isKindOfClass:[NSDictionary class]])
					lbl = [(NSDictionary*)lbl objectForKey:@"text"];
				key.displayString = lbl;
				if ([@" " isEqualToString:str]) {
					key.displayType = @"Space";
					key.interactionType = @"Space";
					key.name = @"Space-Key";
					key.displayString = @"Space";
				} else if ([@"\n" isEqualToString:str]) {
					key.displayType = @"Return";
					key.interactionType = @"Return";
					key.name = @"Return-Key";
					key.displayString = @"Return";
				} else if ([@"" isEqualToString:str]) {
					continue;
				} else if ([@".com" isEqualToString:str]) {
					key.displayType = @"Top-Level-Domain";
					key.interactionType = @"String-Popup";
					key.variantType = @"URL";
				} else if ([@"." isEqualToString:str] && [sublayoutKey hasPrefix:@"EmailAddress"]) {
					key.displayType = @"Top-Level-Domain";
					key.interactionType = @"String-Popup";
					key.variantType = @"email";
				} else {
					key.displayType = @"String";
					key.interactionType = @"String-Popup";
					key.name = str;
					if ([@"'" isEqualToString:str]) {
						UIKBAttributeList* attribs = [[UIKBAttributeList alloc] init];
						[attribs setValue:@"yes" forName:@"more-after"];
						key.attributes = attribs;
						[attribs release];
					}
				}
				
			} else {
				break;
			}
			[keys addObject:key];
		}
		
		list.keys = keys;
		[keylists addObject:list];
	}
	UIKBKeyset* keyset = [UIKBKeyset keyset];
	keyset.keylists = keylists;
	
	UIKBKeylayout* keylayout = [UIKBKeylayout keylayout];
	keylayout.keyset = keyset;
	
#pragma mark Phase 4: Metrics
	CGFloat* lefts = alloca(rows * sizeof(CGFloat));
	CGFloat* rights = alloca(rows * sizeof(CGFloat));
	CGFloat* horizontalSpacings = alloca(rows * sizeof(CGFloat));

	// fetch indentation.
	NSObject* indentation = [sublayout objectForKey:@"rowIndentation"];
	if ([indentation isKindOfClass:[NSArray class]]) {
		NSUInteger i = 0;
		for (NSNumber* n in (NSArray*)indentation) {
			if ([n isKindOfClass:[NSArray class]]) {
				lefts[i] = [[(NSArray*)n objectAtIndex:0] floatValue];
				rights[i] = [[(NSArray*)n lastObject] floatValue];
			} else {
				lefts[i] = rights[i] = [n floatValue];
			}
			++ i;
			if (i >= rows)
				break;
		}
	} else {
		// legacy support for strings...
		CGFloat r0 = 0, r1 = 16, r2 = 48, r3 = 80;
		if ([indentation isKindOfClass:[NSString class]]) {
			NSString* theStr = [(NSString*)indentation lowercaseString];
			if ([theStr isEqualToString:@"azerty"]) {
				r1 = 0; r2 = 64;
			} else if ([theStr isEqualToString:@"russian"]) {
				r1 = 0; r2 = 29;
			} else if ([theStr isEqualToString:@"alt"]) {
				r1 = 0;
			} else if ([theStr isEqualToString:@"tightestdefault"]) {
				r1 = 0; r2 = 42;
			}
		}
		
		lefts[rows-1] = rights[rows-1] = r3;
		if (rows >= 2) lefts[rows-2] = rights[rows-2] = r2;
		if (rows > 3)
			lefts[rows-3] = rights[rows-3] = r1;
		else if (rows == 3)
			lefts[1] = rights[1] = r1;
		lefts[0] = rights[0] = r0;
		for (NSUInteger i = 1; i <= rows-4; ++i)
			lefts[i] = rights[i] = r0;
	}
	
	// fetch horizontal spacing.
	NSObject* hSpacing = [sublayout objectForKey:@"horizontalSpacing"];
	if ([hSpacing isKindOfClass:[NSArray class]]) {
		NSUInteger i = 0;
		for (NSNumber* n in (NSArray*)hSpacing) {
			horizontalSpacings[i] = [n floatValue];
			++ i;
			if (i >= rows)
				break;
		}
	} else if (hSpacing != nil) {
		CGFloat hsp = [(NSNumber*)hSpacing floatValue];
		for (NSUInteger i = 0; i < rows; ++ i)
			horizontalSpacings[i] = hsp;
	} else
		for (NSUInteger i = 0; i < rows; ++ i)
			horizontalSpacings[i] = 1;
	if (isLandscape)
		for (NSUInteger i = 0; i < rows; ++ i)
			horizontalSpacings[i] *= 1.5f;
	
	// Convert to percentages...
	for (unsigned i = 0; i < rows; ++ i) {
		lefts[i] *= 0.3125f;
		rights[i] *= 0.3125f;
	}
	
	CGFloat totalHeightPerRow = 100.f/rows;
	CGFloat padding, height;
	if (isLandscape) {
		if (totalHeightPerRow >= 28) {
			padding = 5;
			height = totalHeightPerRow-5;
		} else if (totalHeightPerRow >= 23) {
			padding = totalHeightPerRow-23;
			height = 23;
		} else {
			padding = 0;
			height = totalHeightPerRow;
		}
	} else {
		if (totalHeightPerRow >= 25) {
			padding = 5;
			height = totalHeightPerRow-5;
		} else if (totalHeightPerRow >= 20) {
			padding = totalHeightPerRow-20;
			height = 20;
		} else {
			padding = 0;
			height = totalHeightPerRow;
		}
	}
	padding *= 100/totalHeightPerRow;
	
	NSMutableArray* refs = [NSMutableArray array];
	for (unsigned i = 0; i < rows; ++ i) {
		CGFloat width = 100 - lefts[i] - rights[i];
		
		NSString* rowName = [NSString stringWithFormat:@"Row%u", i];
		
		UIKBGeometry* geom = [UIKBGeometry geometry];
		geom.x = UIKBLengthMakePercentage(lefts[i]);
		geom.y = UIKBLengthMakePercentage(totalHeightPerRow*i);
		geom.w = UIKBLengthMakePercentage(width);
		geom.h = UIKBLengthMakePercentage(totalHeightPerRow);
		geom.paddingTop = UIKBLengthMakePercentage(padding);
		
		UIKBKeylistReference* geomref = [[UIKBKeylistReference alloc] init];
		geomref.value = geom;
		[geomref setNameElements:[NSArray arrayWithObjects:@"Keyset", rowName, @"Geometry", nil]];
		[geomref setFlags:0x43 setStartKeyIndex:0 setEndKeyIndex:0];
		[refs addObject:geomref];
		[geomref release];
		
		NSMutableArray* geoms = [NSMutableArray arrayWithCapacity:counts[i]];
		CGFloat keywidth = 100.f/counts[i];
		unsigned textsCount = [texts[i] count];
		for (unsigned j = 0; j < counts[i]; ++ j) {
			if (j >= textsCount)
				break;
			else if ([@"" isEqualToString:[(shifted ? shiftedTexts : texts)[i] objectAtIndex:j]])
				continue;
			UIKBGeometry* keygeom = [UIKBGeometry geometry];
			keygeom.x = UIKBLengthMakePercentage(j*keywidth);
			keygeom.y = UIKBLengthMakePercentage(0);
			keygeom.w = UIKBLengthMakePercentage(keywidth);
			keygeom.h = UIKBLengthMakePercentage(100);
			keygeom.paddingTop = UIKBLengthMakePixel(1);
			keygeom.paddingBottom = UIKBLengthMakePixel(1);
			keygeom.paddingLeft = UIKBLengthMakePixel(horizontalSpacings[i]);
			keygeom.paddingRight = UIKBLengthMakePixel(horizontalSpacings[i]);
			
			[geoms addObject:keygeom];
		}
		
		UIKBKeylistReference* keygeomref = [[UIKBKeylistReference alloc] init];
		keygeomref.value = geoms;
		[keygeomref setNameElements:[NSArray arrayWithObjects:@"Keyset", rowName, @"Keys", @"Geometry", nil]];
		[keygeomref setFlags:0x47 setStartKeyIndex:0 setEndKeyIndex:0];
		[refs addObject:keygeomref];
		[keygeomref release];
		
		if (lefts[i] < 5) {
			UIKBKeylistReference* popToRightRef = [[UIKBKeylistReference alloc] init];
			UIKBAttributeList* popToRightAttrib = [[UIKBAttributeList alloc] init];
			[popToRightAttrib setValue:@"right" forName:@"popup-bias"];
			popToRightRef.value = popToRightAttrib;
			[popToRightRef setFlags:0x97 setStartKeyIndex:0 setEndKeyIndex:0];
			[popToRightRef setNameElements:[NSArray arrayWithObjects:@"Keyset", rowName, @"Keys[0]", @"Attributes", nil]];
			[refs addObject:popToRightRef];
			[popToRightRef release];
			[popToRightAttrib release];
		}
		
		if (rights[i] < 5) {
			UIKBKeylistReference* popToRightRef = [[UIKBKeylistReference alloc] init];
			UIKBAttributeList* popToRightAttrib = [[UIKBAttributeList alloc] init];
			[popToRightAttrib setValue:@"left" forName:@"popup-bias"];
			popToRightRef.value = popToRightAttrib;
			[popToRightRef setFlags:0x97 setStartKeyIndex:-1 setEndKeyIndex:-1];
			[popToRightRef setNameElements:[NSArray arrayWithObjects:@"Keyset", rowName, @"Keys[-1]", @"Attributes", nil]];
			[refs addObject:popToRightRef];
			[popToRightRef release];
			[popToRightAttrib release];
		}
	}
	[keylayout setRef:refs];
	
#pragma mark Phase 6: The 5 special keys.
	UIKBKeylayout* specialLayout = [UIKBKeylayout keylayout];
	UIKBKeyset* specialKeyset = [UIKBKeyset keyset];
	NSMutableArray* specialKeys = [NSMutableArray array];
	NSMutableArray* specialKeygeoms = [NSMutableArray array];
#define UNDEF_OR_YES(key) ({ id b = [sublayout objectForKey:(key)]; (b == nil || [b boolValue]); })
	if (UNDEF_OR_YES(@"hasSpaceKey")) {
		UIKBKey* key = [UIKBKey key];
		key.representedString = @" ";
		key.displayString = key.displayType = key.interactionType = @"Space";
		key.name = @"Space-Key";
		[specialKeys addObject:key];
		
		UIKBGeometry* keygeom = [UIKBGeometry geometry];
		keygeom.x = UIKBLengthMakePercentage(isLandscape ? 20 : 25);
		keygeom.y = UIKBLengthMakePercentage(100 - height);
		keygeom.w = UIKBLengthMakePercentage(isLandscape ? 60 : 50);
		keygeom.h = UIKBLengthMakePercentage(height);
		keygeom.paddingLeft = keygeom.paddingRight = UIKBLengthMakePixel(isLandscape ? 2 : 1);
		keygeom.paddingBottom = UIKBLengthMakePixel(1);
		[specialKeygeoms addObject:keygeom];
	}
	if (UNDEF_OR_YES(@"hasInternationalKey")) {
		UIKBKey* key1 = [UIKBKey key];
		key1.representedString = key1.displayString = key1.displayType = key1.interactionType = @"International";
		key1.name = @"International-Key";
		[specialKeys addObject:key1];
		UIKBGeometry* keygeom1 = [UIKBGeometry geometry];
		keygeom1.x = UIKBLengthMakePercentage(isLandscape ? 10 : 12.5);
		keygeom1.y = UIKBLengthMakePercentage(100 - height);
		keygeom1.w = UIKBLengthMakePercentage(isLandscape ? 10 : 12.5);
		keygeom1.h = UIKBLengthMakePercentage(height);
		keygeom1.paddingLeft = keygeom1.paddingRight = UIKBLengthMakePixel(isLandscape ? 2 : 1);
		keygeom1.paddingBottom = UIKBLengthMakePixel(1);
		[specialKeygeoms addObject:keygeom1];
		
		UIKBKey* key2 = [UIKBKey key];
		key2.representedString = key2.displayString = key2.displayType = key2.interactionType = @"More";
		key2.name = @"More-Key";
		[specialKeys addObject:key2];
		UIKBGeometry* keygeom2 = [UIKBGeometry geometry];
		keygeom2.x = UIKBLengthMakePercentage(0);
		keygeom2.y = UIKBLengthMakePercentage(100 - height);
		keygeom2.w = UIKBLengthMakePercentage(isLandscape ? 10 : 12.5);
		keygeom2.h = UIKBLengthMakePercentage(height);
		keygeom2.paddingLeft = keygeom2.paddingRight = UIKBLengthMakePixel(isLandscape ? 2 : 1);
		keygeom2.paddingBottom = UIKBLengthMakePixel(1);
		[specialKeygeoms addObject:keygeom2];
	}
	if (UNDEF_OR_YES(@"hasReturnKey")) {
		UIKBKey* key = [UIKBKey key];
		key.representedString = @"\n";
		key.displayString = key.displayType = key.interactionType = @"Return";
		key.name = @"Return-Key";
		[specialKeys addObject:key];
		
		UIKBGeometry* keygeom = [UIKBGeometry geometry];
		keygeom.x = UIKBLengthMakePercentage(isLandscape ? 80 : 75);
		keygeom.y = UIKBLengthMakePercentage(100 - height);
		keygeom.w = UIKBLengthMakePercentage(isLandscape ? 20 : 25);
		keygeom.h = UIKBLengthMakePercentage(height);
		keygeom.paddingLeft = keygeom.paddingRight = UIKBLengthMakePixel(isLandscape ? 2 : 1);
		keygeom.paddingBottom = UIKBLengthMakePixel(1);
		[specialKeygeoms addObject:keygeom];		
	}
	CGFloat defaultShiftKeyWidth = isLandscape ? 12.5 : 13;
	if (UNDEF_OR_YES(@"hasShiftKey")) {
		UIKBKey* key = [UIKBKey key];
		key.representedString = key.displayString = key.displayType = key.interactionType = @"Shift";
		key.name = @"Shift-Key";
		[specialKeys addObject:key];
		
		if (!UNDEF_OR_YES(@"shiftKeyEnabled")) {
			UIKBAttributeList* shiftAttrib = [[UIKBAttributeList alloc] init];
			[shiftAttrib setValue:@"disabled" forName:@"state"];
			key.attributes = shiftAttrib;
			[shiftAttrib release];
		}
		
		UIKBGeometry* keygeom = [UIKBGeometry geometry];
		id shrow = [sublayout objectForKey:@"shiftKeyRow"];
		keygeom.x = UIKBLengthMakePercentage([[sublayout objectForKey:@"shiftKeyLeft"] floatValue] * 0.3125);
		keygeom.y = UIKBLengthMakePercentage(totalHeightPerRow*(shrow == nil ? rows-1 : [shrow integerValue]+1) - height);
		keygeom.w = UIKBLengthMakePercentage([[sublayout objectForKey:@"shiftKeyWidth"] floatValue] * 0.3125 ?: defaultShiftKeyWidth);
		keygeom.h = UIKBLengthMakePercentage(height);
		keygeom.paddingBottom = keygeom.paddingLeft = keygeom.paddingRight = UIKBLengthMakePixel(1);
		[specialKeygeoms addObject:keygeom];		
	}
	if (UNDEF_OR_YES(@"hasDeleteKey")) {
		UIKBKey* key = [UIKBKey key];
		key.representedString = key.displayString = key.displayType = key.interactionType = @"Delete";
		key.name = @"Delete-Key";
		[specialKeys addObject:key];
		
		UIKBGeometry* keygeom = [UIKBGeometry geometry];
		id shrow = [sublayout objectForKey:@"deleteKeyRow"];
		CGFloat width = [[sublayout objectForKey:@"deleteKeyWidth"] floatValue] * 0.3125 ?: defaultShiftKeyWidth;
		keygeom.x = UIKBLengthMakePercentage(100 - width - [[sublayout objectForKey:@"deleteKeyRight"] floatValue] * 0.3125);
		keygeom.y = UIKBLengthMakePercentage(totalHeightPerRow*(shrow == nil ? rows-1 : [shrow integerValue]+1) - height);
		keygeom.w = UIKBLengthMakePercentage(width);
		keygeom.h = UIKBLengthMakePercentage(height);
		keygeom.paddingBottom = keygeom.paddingLeft = keygeom.paddingRight = UIKBLengthMakePixel(1);
		[specialKeygeoms addObject:keygeom];		
	}
#undef UNDEF_OR_YES
	UIKBKeylist* specialList = [UIKBKeylist keylist];
	specialList.name = @"Ctrl";
	specialList.keys = specialKeys;
	specialKeyset.keylists = [NSArray arrayWithObject:specialList];
	specialLayout.keyset = specialKeyset;
	
	UIKBKeylistReference* specialGeomRef = [[UIKBKeylistReference alloc] init];
	specialGeomRef.value = specialKeygeoms;
	[specialGeomRef setNameElements:[NSArray arrayWithObjects:@"Keyset", @"Ctrl", @"Keys", @"Geometry", nil]];
	[specialGeomRef setFlags:0x47 setStartKeyIndex:0 setEndKeyIndex:0];
	
	UIKBKeylistReference* specialGeomRef2 = [[UIKBKeylistReference alloc] init];
	UIKBGeometry* specialGeom = [UIKBGeometry geometry];
	specialGeom.x = specialGeom.y = UIKBLengthMakePercentage(0);
	specialGeom.w = specialGeom.h = UIKBLengthMakePercentage(100);
	specialGeomRef2.value = specialGeom;
	[specialGeomRef2 setNameElements:[NSArray arrayWithObjects:@"Keyset", @"Ctrl", @"Geometry", nil]];
	[specialGeomRef2 setFlags:0x43 setStartKeyIndex:0 setEndKeyIndex:0];
	
	[specialLayout setRef:[NSArray arrayWithObjects:specialGeomRef, specialGeomRef2, nil]];
	[specialGeomRef release];
	[specialGeomRef2 release];
	
	plane.keylayouts = [NSArray arrayWithObjects:keylayout, specialLayout, nil];
	plane.supportedTypes = sublayoutSupportedTypes(sublayoutKey, shifted);
	
	return plane;
}

UIKBKeyboard* IKXUIKBKeyboardFromLayoutPlist(NSMutableDictionary* layoutPlist, NSString* whichKeyboard, BOOL isLandscape) {
	UIKBKeyboard* keyboard = [UIKBKeyboard keyboard];
	CGRect kbframe = isLandscape ? CGRectMake(0, 0, 480, 162) : CGRectMake(0, 0, 320, 216);
	keyboard.frame = kbframe;
	UIKBGeometry* geom = [UIKBGeometry geometryWithRect:kbframe];
	keyboard.geometry = geom;
	
	/* Here is the mapping between Star keyboards and layout.plist sublayouts.
	 
	 "" = {Alphabet; Numbers}
	 URL = {URL; URLAlt}
	 NamePhonePad = {SMSAddressing; SMSAddressingAlt}
	 NumberPad = {NumberPad}
	 PhonePad = {PhonePad; PhonePadAlt}	// <-- does not conform to iPhoneOS's internal usage, but whatever.
	 Email = {EmailAddress; EmailAddressAlt}
	 */
		
	UIKBKeyplane* keyplanes[4];
	unsigned keyplane_count = 4;
	
	if ([whichKeyboard isEqualToString:@"URL"]) {
		keyplanes[0] = constructUIKBKeyplaneFromSublayout(layoutPlist, @"URL", NO, isLandscape);
		keyplanes[1] = constructUIKBKeyplaneFromSublayout(layoutPlist, @"URL", YES, isLandscape);
		keyplanes[2] = constructUIKBKeyplaneFromSublayout(layoutPlist, @"URLAlt", NO, isLandscape);
		keyplanes[3] = constructUIKBKeyplaneFromSublayout(layoutPlist, @"URLAlt", YES, isLandscape);
	} else if ([whichKeyboard isEqualToString:@"NamePhonePad"]) {
		keyplanes[0] = constructUIKBKeyplaneFromSublayout(layoutPlist, @"SMSAddressing", NO, isLandscape);
		keyplanes[1] = constructUIKBKeyplaneFromSublayout(layoutPlist, @"SMSAddressing", YES, isLandscape);
		keyplanes[2] = constructUIKBKeyplaneFromSublayout(layoutPlist, @"SMSAddressingAlt", NO, isLandscape);
		keyplanes[3] = constructUIKBKeyplaneFromSublayout(layoutPlist, @"SMSAddressingAlt", YES, isLandscape);
	} else if ([whichKeyboard isEqualToString:@"NumberPad"]) {
		keyplanes[0] = constructUIKBKeyplaneFromSublayout(layoutPlist, @"NumberPad", NO, isLandscape);
		keyplane_count = 1;
	} else if ([whichKeyboard isEqualToString:@"PhonePad"]) {
		keyplanes[0] = constructUIKBKeyplaneFromSublayout(layoutPlist, @"PhonePad", NO, isLandscape);
		keyplanes[1] = constructUIKBKeyplaneFromSublayout(layoutPlist, @"PhonePadAlt", YES, isLandscape);
		keyplane_count = 2;
	} else if ([whichKeyboard isEqualToString:@"Email"]) {
		keyplanes[0] = constructUIKBKeyplaneFromSublayout(layoutPlist, @"EmailAddress", NO, isLandscape);
		keyplanes[1] = constructUIKBKeyplaneFromSublayout(layoutPlist, @"EmailAddress", YES, isLandscape);
		keyplanes[2] = constructUIKBKeyplaneFromSublayout(layoutPlist, @"EmailAddressAlt", NO, isLandscape);
		keyplanes[3] = constructUIKBKeyplaneFromSublayout(layoutPlist, @"EmailAddressAlt", YES, isLandscape);
	} else {
		keyplanes[0] = constructUIKBKeyplaneFromSublayout(layoutPlist, @"Alphabet", NO, isLandscape);
		keyplanes[1] = constructUIKBKeyplaneFromSublayout(layoutPlist, @"Alphabet", YES, isLandscape);
		keyplanes[2] = constructUIKBKeyplaneFromSublayout(layoutPlist, @"Numbers", NO, isLandscape);
		keyplanes[3] = constructUIKBKeyplaneFromSublayout(layoutPlist, @"Numbers", YES, isLandscape);
	}
	keyboard.keyplanes = [NSArray arrayWithObjects:keyplanes count:keyplane_count];
	for (unsigned i = 0; i < keyplane_count; ++ i) {
		for (UIKBKey* key in keyplanes[i].keys) {
			NSString* keyType = key.displayType;
			if (![keyType isEqualToString:@"NumberPad"] && ![keyType isEqualToString:@"String"])
				[keyboard cacheKey:key onKeyplane:keyplanes[i]];
		}
	}
	
	return keyboard;
}