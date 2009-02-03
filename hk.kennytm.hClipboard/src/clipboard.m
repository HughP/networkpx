/*
 
 clipboard.m ... Persistent clipboard manager in Objective-C
 
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

#import "clipboard.h"


@implementation ClipboardEntry
@synthesize data, secure;

-(void)dealloc {
	[data release];
	[super dealloc];
}

+(ClipboardEntry*)entryWithData:(NSObject*)data_ secure:(BOOL)security {
	return [[[ClipboardEntry alloc] initWithData:data_ secure:security] autorelease];
}
+(ClipboardEntry*)entryWithData:(NSObject*)data_ { return [ClipboardEntry entryWithData:data_ secure:NO]; }
+(ClipboardEntry*)entryWithSecureData:(NSObject*)data_ { return [ClipboardEntry entryWithData:data_ secure:YES]; }
-(id)initWithData:(NSObject*)data_ secure:(BOOL)security {
	if ((self = [super init])) {
		data = [data_ retain];
		secure = security;
	}
	return self;
}

-(void)encodeWithCoder:(NSCoder*)coder {
	[coder encodeObject:data forKey:@"data"];
    [coder encodeBool:secure forKey:@"secure"];
}
-(id)initWithCoder:(NSCoder*)coder {
	if ((self = [super init])) {
		data = [[coder decodeObjectForKey:@"data"] retain];
		secure = [coder decodeBoolForKey:@"secure"];
	}
	return self;
}

-(NSString*)description {
	NSString* retval = [data description];
	if (secure)
		return [NSString stringWithFormat:@"Secure Text with %u characters", [retval length]];
	else
		return retval;
}

-(id)copyWithZone:(NSZone*)zone {
	ClipboardEntry* newSelf = [[ClipboardEntry allocWithZone:zone] init];
	if (newSelf != nil) {
		if ([data conformsToProtocol:@protocol(NSCopying)])
			newSelf->data = [data copy];
		else
			newSelf->data = [data retain];
		newSelf->secure = secure;
	}
	return newSelf;
}
@end


#define DefaultCapacity 10
#define DefaultPath @"/var/mobile/Library/Keyboard/clipboard.plist"

@implementation Clipboard

-(void)dealloc {
	[path release];
	[entries release];
	[super dealloc];
}

@synthesize path;

-(void)fixEntriesCount {
	[entries removeObjectsInRange:NSMakeRange(0, count-capacity)];
	count = capacity;
}

-(void)deriveOtherIVars {
	count = [entries count];
	if (capacity < count)
		[self fixEntriesCount];
	path = nil;
}

-(void)encodeWithCoder:(NSCoder*)coder {
    [coder encodeObject:entries forKey:@"entries"];
    [coder encodeInteger:capacity forKey:@"capacity"];	// there's no encodeUnsignedInteger? How come!
}
-(id)initWithCoder:(NSCoder*)coder {
	if ((self = [super init])) {
		entries = [[coder decodeObjectForKey:@"entries"] retain];
		if (![entries isKindOfClass:[NSMutableArray class]]) {
			[entries release];
			entries = [[NSMutableArray alloc] init];
		}
		
		capacity = [coder decodeIntegerForKey:@"capacity"];
		if (capacity == 0)
			capacity = 1;
		[self deriveOtherIVars];
	}
	return self;
}

+(Clipboard*)defaultClipboard { return [Clipboard defaultClipboardWithDefaultCapacity:DefaultCapacity]; }
+(Clipboard*)defaultClipboardWithDefaultCapacity:(NSUInteger)capac { return [Clipboard clipboardWithPath:DefaultPath defaultCapacity:capac]; }
+(Clipboard*)clipboardWithPath:(NSString*)path_ defaultCapacity:(NSUInteger)capac { return [[[Clipboard alloc] initWithPath:path_ defaultCapacity:capac] autorelease]; }
+(Clipboard*)clipboardWithPath:(NSString*)path_ { return [[[Clipboard alloc] initWithPath:path_] autorelease]; }

-(id)initDefaultClipboard { return (self = [self initWithPath:DefaultPath defaultCapacity:DefaultCapacity]); }

-(id)init { return (self = [self initWithCapacity:DefaultCapacity]); }

-(id)initWithCapacity:(NSUInteger)capac {
	if (capac == 0)
		capac = 1;
	if ((self = [super init])) {
		entries = [[NSMutableArray alloc] init];
		capacity = capac;
		[self deriveOtherIVars];
	}
	return self;
}

-(id)initWithPath:(NSString*)path_ defaultCapacity:(NSUInteger)capac {
	@try {
		Clipboard* retval = nil;
		if ((retval = [NSKeyedUnarchiver unarchiveObjectWithFile:path_]) && [retval isKindOfClass:[Clipboard class]]) {
			// initWithCoder: has done -deriveOtherIVars already.
			[self release];
			self = [retval retain];
		} else {
			NSLog(@"Clipboard file \"%@\" does not exist or cannot be loaded. An empty clipboard is used instead.", path_);
			self = [self initWithCapacity:capac];
		}
	} @catch (NSException * e) {
		if ([NSInvalidArgumentException isEqualToString:[e name]]) {
			NSLog(@"The clipboard file \"%@\" is probably corrupted. An empty clipboard is used instead.", path_);
			self = [self initWithCapacity:capac];
		} else {
			NSLog(@"Unarchiving clipboard from path \"%@\" failed!", path_);
			@throw;
		}
	}
	
	path = [path_ copy];
	return self;
}

-(id)initWithPath:(NSString*)path_ { return (self = [self initWithPath:path_ defaultCapacity:DefaultCapacity]); }

-(id)rawInit { return (self = [super init]); }

-(id)copyWithZone:(NSZone*)zone {
	Clipboard* newSelf = [[Clipboard allocWithZone:zone] rawInit];
	if (newSelf != nil) {
		newSelf->capacity = capacity;
		newSelf->entries = [entries mutableCopy];
		newSelf->count = count;
		newSelf->path = [path copy];
	}
	return newSelf;
}

-(void)addEntry:(ClipboardEntry*)entry {
	// the list of entries is empty. Directly add the entry & set the timestamps.
	if (count >= capacity)
		[entries removeObjectAtIndex:0];
	else
		++ count;
	[entries addObject:entry];
	
	[self save];
}

@synthesize count, capacity;
-(void)setCapacity:(NSUInteger)newCapac {
	if (capacity != newCapac) {
		if (newCapac == 0)
			capacity = 1;
		else
			capacity = newCapac;
		if (capacity < count) {
			[entries removeObjectsInRange:NSMakeRange(0, count-capacity)];
			count = capacity;
		}
		[self save];
	}
}

-(void)addEntriesFromClipboard:(Clipboard*)anotherClipboard {
	
	[entries addObjectsFromArray:anotherClipboard->entries];
	count = [entries count];
	if (count > capacity)
		[self fixEntriesCount];
	
	[self save];
}

-(void)erase {
	[entries removeAllObjects];
	count = 0;
	[self save];
}

-(BOOL)save { return (path != nil) ? [self saveToPath:path] : YES; }
-(BOOL)saveToPath:(NSString*)path_ { return [NSKeyedArchiver archiveRootObject:self toFile:path_]; }

-(NSObject*)dataAtIndex:(NSUInteger)index { return (index < count) ? ((ClipboardEntry*)[entries objectAtIndex:index]).data : nil; }
-(BOOL)isSecureAtIndex:(NSUInteger)index { return (index < count) ? ((ClipboardEntry*)[entries objectAtIndex:index]).secure : NO; }
-(NSObject*)dataAtReversedIndex:(NSUInteger)index { return (index < count) ? ((ClipboardEntry*)[entries objectAtIndex:count-1-index]).data : nil; }
-(BOOL)isSecureAtReversedIndex:(NSUInteger)index { return (index < count) ? ((ClipboardEntry*)[entries objectAtIndex:count-1-index]).secure : NO; }

-(void)removeEntryAtIndex:(NSUInteger)index {
	if (index < count) {
		[entries removeObjectAtIndex:index];
		-- count;
		[self save];
	}
}
-(void)removeEntryAtReversedIndex:(NSUInteger)index { [self removeEntryAtIndex:count-1-index]; }

-(void)addData:(NSObject*)data secure:(BOOL)secure {
	ClipboardEntry* newEntry = [ClipboardEntry entryWithData:data secure:secure];
	if (count >= capacity) {
		[entries removeObjectAtIndex:0];
	} else
		++ count;
	[entries addObject:newEntry];
	[self save];
}
-(void)addData:(NSObject*)data { [self addData:data secure:NO]; }
-(void)addSecureData:(NSObject*)data { [self addData:data secure:YES]; }

-(NSObject*)lastData { return ((ClipboardEntry*)[entries lastObject]).data; }
-(BOOL)lastIsSecure { return ((ClipboardEntry*)[entries lastObject]).secure; }

-(NSObject*)lastDataOfClass:(Class)cls {
	for (ClipboardEntry* entry in [entries reverseObjectEnumerator])
		if ([entry->data isKindOfClass:cls])
			return entry.data;
	return nil;
}

-(NSArray*)allData {
	NSMutableArray* retArr = [NSMutableArray arrayWithCapacity:count];
	for (ClipboardEntry* entry in entries)
		[retArr addObject:entry->data];
	return retArr;
}

-(NSArray*)allDataReversed {
	NSMutableArray* retArr = [NSMutableArray arrayWithCapacity:count];
	for (ClipboardEntry* entry in [entries reverseObjectEnumerator])
		[retArr addObject:entry->data];
	return retArr;
}

-(NSIndexSet*)allIndices { return [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, count)]; }

-(NSIndexSet*)indicesWithNonsecureData {
	NSMutableIndexSet* indices = [NSMutableIndexSet indexSet];
	NSUInteger index = 0;
	for (ClipboardEntry* entry in entries) {
		if (!entry->secure)
			[indices addIndex:index];
		++ index;
	}
	return indices;
}
-(NSIndexSet*)reversedIndicesWithNonsecureData {
	NSMutableIndexSet* indices = [NSMutableIndexSet indexSet];
	NSUInteger index = count-1;
	for (ClipboardEntry* entry in entries) {
		if (!entry->secure)
			[indices addIndex:index];
		-- index;
	}
	return indices;
}

-(NSIndexSet*)indicesWithDataOfClass:(Class)cls {
	NSMutableIndexSet* indices = [NSMutableIndexSet indexSet];
	NSUInteger index = 0;
	for (ClipboardEntry* entry in entries) {
		if ([entry->data isKindOfClass:cls])
			[indices addIndex:index];
		++ index;
	}
	return indices;	
}

-(NSString*)description { return [entries description]; }

-(void)moveEntryFromIndex:(NSUInteger)idxFrom toIndex:(NSUInteger)idxTo {
	if (idxFrom < count && idxTo < count && idxFrom != idxTo) {
		ClipboardEntry* entry = [[entries objectAtIndex:idxFrom] retain];
		[entries removeObjectAtIndex:idxFrom];
		[entries insertObject:entry atIndex:idxTo];
		[entry release];
		[self save];
	}
}

-(void)moveEntryFromReversedIndex:(NSUInteger)idxFrom toReversedIndex:(NSUInteger)idxTo {
	[self moveEntryFromIndex:count-1-idxFrom toIndex:count-1-idxTo];
}

@end
