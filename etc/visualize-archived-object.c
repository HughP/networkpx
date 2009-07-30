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

#include <CoreFoundation/CoreFoundation.h>

typedef const struct _CFKeyedArchiverUID* _CFKeyedArchiverUIDRef;
CFTypeID _CFKeyedArchiverUIDGetTypeID();
unsigned _CFKeyedArchiverUIDGetValue(_CFKeyedArchiverUIDRef uid);

static void refCounter(CFPropertyListRef obj, int* refCount);
static void refCounter2(const void* key, CFPropertyListRef value, int* refCount) {
	refCounter(value, refCount);
}
static void refCounter(CFPropertyListRef obj, int* refCount) {
	CFTypeID typeID = CFGetTypeID(obj);
	if (typeID == _CFKeyedArchiverUIDGetTypeID())
		++ refCount[_CFKeyedArchiverUIDGetValue(obj)];
	else if (typeID == CFDictionaryGetTypeID()) {
		CFDictionaryApplyFunction(obj, (CFDictionaryApplierFunction)&refCounter2, refCount);
	} else if (typeID == CFArrayGetTypeID())
		CFArrayApplyFunction(obj, CFRangeMake(0, CFArrayGetCount(obj)), (CFArrayApplierFunction)&refCounter, refCount);
	// all other stuff won't affect the refcount.
}

struct printContext {
	unsigned tabs;
	const int* refCount;
	CFArrayRef objs;
};

static void printObjAsString(CFStringRef obj) {
	CFStringInlineBuffer buf;
	CFIndex len = CFStringGetLength(obj);
	CFStringInitInlineBuffer(obj, &buf, CFRangeMake(0, len));
	printf("\"");
	for (CFIndex i = 0; i < len; ++ i) {
		UniChar c = CFStringGetCharacterFromInlineBuffer(&buf, i);
		if (c == '"' || c == '\\')
			printf("\\%C", c);
		else if (c >= ' ' && c <= '\x7F')
			printf("%C", c);
		else if (c == '\t')
			printf("\\t");
		else if (c == '\n')
			printf("\\n");
		else
			printf("\\U%04x", c);
	}
	printf("\"");
}

static void printObjAsClassName(CFStringRef obj) {
	CFDataRef data = CFStringCreateExternalRepresentation(NULL, obj, 0, 0);
	printf("%.*s", (int)CFDataGetLength(data), CFDataGetBytePtr(data));
	CFRelease(data);
}

static void printObjAsNumber(CFNumberRef obj) {
	CFNumberType numType = CFNumberGetType(obj);
	union {
#define DefineValue(type) type type##Value
		DefineValue(SInt8);
		DefineValue(SInt16);
		DefineValue(SInt32);
		DefineValue(SInt64);
		DefineValue(Float32);
		DefineValue(Float64);
		char CharValue;
		short ShortValue;
		int IntValue;
		long LongValue;
		long long LongLongValue;
		float FloatValue;
		double DoubleValue;
		DefineValue(CFIndex);
		int NSIntegerValue;
		float CGFloatValue;
#undef DefineValue
	} res;
	
	CFNumberGetValue(obj, numType, &res);

#define PrintType(formatStr, t1, dummy) \
	case kCFNumber##t1##Type: \
		printf(formatStr, res.t1##Value); \
		break
	
	switch (numType) {
			PrintType("%d", SInt8, SInt8);
			PrintType("%d", SInt16, SInt16);
			PrintType("%ld", SInt32, SInt32);
			PrintType("%lld", SInt64, SInt64);
			PrintType("%g", Float32, Float32);
			PrintType("%lg", Float64, Float64);
			
		case kCFNumberCharType:
			if (res.CharValue >= ' ' && res.CharValue < '\x7F') {
				if (res.CharValue == '\'' || res.CharValue == '\\')
					printf("'\\%c'", res.CharValue);
				else
					printf("'%c'", res.CharValue);
			} else if (res.CharValue == '\t')
				printf("'\\t'");
			else if (res.CharValue == '\n')
				printf("'\\n'");
			else
				printf("'\\U%04x'", res.CharValue);
			break;
			
			PrintType("%d", Short, short);
			PrintType("%d", Int, int);
			PrintType("%ld", Long, long);
			PrintType("%lld", LongLong, long long);
			PrintType("%f", Float, float);
			PrintType("%lg", Double, double);
			PrintType("%ld", CFIndex, CFIndex);
			PrintType("%d", NSInteger, int);
			PrintType("%g", CGFloat, float);
//			PrintType("%f", Max, float);
			
		default:
			break;
	}
	
#undef PrintType
}

static void printObj(CFPropertyListRef obj, struct printContext* c);

static void printObjAsDictionaryEntry(CFStringRef key, CFPropertyListRef value, struct printContext* c) {
	for (unsigned i = 0; i < c->tabs; ++ i)
		printf("\t");
	printObjAsString(key);
	printf(" = ");
	printObj(value, c);
	printf(";\n");
}

static void printObjAsArrayEntry(CFPropertyListRef value, struct printContext* c) {
	for (unsigned i = 0; i < c->tabs; ++ i)
		printf("\t");
	printObj(value, c);
	printf(",\n");
}

static void printObjAsData(CFDataRef data) {
	printf("<");
	const UInt8* ptr = CFDataGetBytePtr(data);
	CFIndex size = CFDataGetLength(data);
	for (CFIndex i = 0; i < size; ++ i) {
		if (i != 0 && i % 4 == 0)
			printf(" ");
		printf("%02x", ptr[i]);
	}
	printf(">");
}

static bool isComplexObj(CFPropertyListRef obj) {
	CFTypeID typeID = CFGetTypeID(obj);
	if (typeID == _CFKeyedArchiverUIDGetTypeID() || typeID == CFArrayGetTypeID() || typeID == CFDataGetTypeID())
		return true;
	else if (typeID == CFStringGetTypeID() && CFStringGetLength(obj) >= 100)
		return true;
	else if (typeID == CFDictionaryGetTypeID() && !CFDictionaryContainsKey(obj, CFSTR("$classname")))
		return true;
	else
		return false;
}

struct dictionarySorterContext {
	CFStringRef* keys;
	CFPropertyListRef* values;
};
static int dictionaryComparer(const struct dictionarySorterContext* c, const unsigned* a, const unsigned* b) {
	return CFStringCompare(c->keys[*a], c->keys[*b], 0);
}

static void printObj(CFPropertyListRef obj, struct printContext* c) {
	CFTypeID typeID = CFGetTypeID(obj);
	if (typeID == _CFKeyedArchiverUIDGetTypeID()) {
		unsigned uid = _CFKeyedArchiverUIDGetValue(obj);
		CFPropertyListRef refObj = CFArrayGetValueAtIndex(c->objs, uid);
		if (CFEqual(refObj, CFSTR("$null")))
			printf("nil");
		else if (c->refCount[uid] > 1 && isComplexObj(refObj))
			printf("{CF$UID = %u;}", uid);
		else
			printObj(refObj, c);
	} else if (typeID == CFArrayGetTypeID()) {
		printf("(\n");
		++ c->tabs;
		CFArrayApplyFunction(obj, CFRangeMake(0, CFArrayGetCount(obj)), (CFArrayApplierFunction)&printObjAsArrayEntry, c);
		-- c->tabs;
		for (unsigned i = 0; i < c->tabs; ++ i)
			printf("\t");
		printf(")");
	} else if (typeID == CFDictionaryGetTypeID()) {
		CFStringRef className = CFDictionaryGetValue(obj, CFSTR("$classname"));
		if (className != NULL)
			printObjAsClassName(className);
		else {
			printf("{\n");
			++ c->tabs;
			CFIndex dictCount = CFDictionaryGetCount(obj);
			
			struct dictionarySorterContext sc;
			sc.keys = malloc(sizeof(CFStringRef)*dictCount);
			sc.values = malloc(sizeof(CFPropertyListRef)*dictCount);
			unsigned* mapping = malloc(sizeof(unsigned)*dictCount);
			for (unsigned i = 0; i < dictCount; ++ i)
				mapping[i] = i;
			CFDictionaryGetKeysAndValues(obj, (const void**)sc.keys, sc.values);
			qsort_r(mapping, dictCount, sizeof(unsigned), &sc, (int(*)(void*,const void*,const void*))&dictionaryComparer);
			for (unsigned i = 0; i < dictCount; ++ i)
				printObjAsDictionaryEntry(sc.keys[mapping[i]], sc.values[mapping[i]], c);
			free(mapping);
			free(sc.keys);
			free(sc.values);
			-- c->tabs;
			for (unsigned i = 0; i < c->tabs; ++ i)
				printf("\t");
			printf("}");
		}
	} else if (typeID == CFDataGetTypeID())
		printObjAsData(obj);
	else if (typeID == CFNumberGetTypeID())
		printObjAsNumber(obj);
	else if (typeID == CFStringGetTypeID())
		printObjAsString(obj);
	else if (typeID == CFBooleanGetTypeID())
		printf(CFBooleanGetValue(obj) ? "true" : "false");
	else if (typeID == CFDateGetTypeID()) 
		printf("/*date*/ %0.09g", CFDateGetAbsoluteTime(obj));

}

int main (int argc, const char* argv[]) {
	if (argc <= 1) {
		fprintf(stderr, "Usage: visualize-archived-object <archived-file>\n\n");
		return 0;
	}
	
	CFStringRef fileNameAsCFString = CFStringCreateWithCString(NULL, argv[1], 0);
	CFURLRef fileURL = CFURLCreateWithFileSystemPath(NULL, fileNameAsCFString, kCFURLPOSIXPathStyle, false);
	CFRelease(fileNameAsCFString);
	
	CFReadStreamRef readStream = CFReadStreamCreateWithFile(NULL, fileURL);
	CFRelease(fileURL);
	if (!readStream) {
		fprintf(stderr, "Error: Cannot open file for reading.\n\n");
		return 1;
	}
	if (!CFReadStreamOpen(readStream)) {
		fprintf(stderr, "Error: Cannot open file for reading.\n\n");
		CFRelease(readStream);
		return 2;
	}
	
	CFStringRef errStr = NULL;
	CFPropertyListRef val = CFPropertyListCreateFromStream(NULL, readStream, 0, kCFPropertyListImmutable, NULL, &errStr);
	CFReadStreamClose(readStream);
	CFRelease(readStream);
	if (errStr != NULL) {
		CFIndex strlength = CFStringGetLength(errStr)*3+1;
		char* res_cstring = malloc(strlength);
		CFStringGetCString(errStr, res_cstring, strlength, 0);
		fprintf(stderr, "Error: Cannot parse file as serialized property list.\n%s\n\n", res_cstring);
		CFRelease(errStr);
		free(res_cstring);
		if (val != NULL)
			CFRelease(val);
		return 3;
	}
	
	if (CFGetTypeID(val) != CFDictionaryGetTypeID()) {
		fprintf(stderr, "Error: Not a dictionary.");
		CFRelease(val);
		return 4;
	}
	
	CFStringRef archiver = CFDictionaryGetValue(val, CFSTR("$archiver"));
	if (archiver == NULL || !CFEqual(archiver, CFSTR("NSKeyedArchiver"))) {
		fprintf(stderr, "Error: Not encoded using an NSKeyedArchiver.");
		CFRelease(val);
		return 5;
	}
	
	CFArrayRef objs = CFDictionaryGetValue(val, CFSTR("$objects"));
	if (objs == NULL || CFGetTypeID(objs) != CFArrayGetTypeID()) {
		fprintf(stderr, "Error: $objects is not an array.");
		CFRelease(val);
		return 6;
	}
	CFIndex objsCount = CFArrayGetCount(objs);
	
	CFDictionaryRef topObj = CFDictionaryGetValue(val, CFSTR("$top"));
	if (topObj == NULL || CFGetTypeID(topObj) != CFDictionaryGetTypeID()) {
		CFShow(topObj);
		fprintf(stderr, "Error: $top is not a dictionary.");
		CFRelease(val);
		return 7;
	}
	
	int* refCount = calloc(objsCount, sizeof(int));
	CFArrayApplyFunction(objs, CFRangeMake(0, objsCount), (CFArrayApplierFunction)&refCounter, refCount);
	
	struct printContext c;
	c.tabs = 0;
	c.refCount = refCount;
	c.objs = objs;
	
	printf("%s", "top = ");
	printObj(topObj, &c);
	printf(";\n\n");
	
	for (CFIndex i = 0; i < objsCount; ++ i)
		if (refCount[i] > 1) {
			CFPropertyListRef refObj = CFArrayGetValueAtIndex(objs, i);
			if (isComplexObj(refObj)) {
				printf("/*CF$UID; referenced %u times*/ %ld = ", refCount[i], i);
				printObj(refObj, &c);
				printf(";\n\n");
			}
		}
	
	free(refCount);
	CFRelease(val);
	
	return 0;
}