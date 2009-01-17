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
#include <signal.h>

void insertObjectIntoSortedArrayUsingSelector (id obj, NSMutableArray* array, SEL sele) {
	NSUInteger indexToInsert = [array count];
	// call the IMP directly for efficiency...
	IMP comparer = [obj instanceMethodForSelector:sele];
	for (id curObj in [array reverseObjectEnumerator]) {
		if ((NSComparisonResult)comparer(obj, sele, curObj) != NSOrderedAscending)
			break;
		-- indexToInsert;
	}
	[array insertObject:obj atIndex:indexToInsert];
}

void reverseArray (NSMutableArray* array) {
	NSUInteger count = [array count];
	for (NSUInteger i = 0; i < count/2; ++ i) {
		[array exchangeObjectAtIndex:i withObjectAtIndex:count-1-i]; 
	}
}




@implementation ClipboardEntry
@synthesize data, timestamp;

-(void)dealloc {
	[data release];
	[timestamp release];
	[super dealloc];
}

+(ClipboardEntry*)entryWithData:(NSObject*)data_ { return [ClipboardEntry entryWithData:data_ timestamp:[NSDate date]]; }
+(ClipboardEntry*)entryWithData:(NSObject*)data_ timestamp:(NSDate*)time {
	return [[[ClipboardEntry alloc] initWithData:data_ timestamp:time] autorelease];
}
-(id)initWithData:(NSObject*)data_ timestamp:(NSDate*)time {
	if ((self = [super init])) {
		data = [data_ retain];
		timestamp = [time retain];
	}
	return self;
}

-(void)encodeWithCoder:(NSCoder*)coder {
	[coder encodeObject:timestamp forKey:@"timestamp"];
    [coder encodeObject:data forKey:@"data"];
}
-(id)initWithCoder:(NSCoder*)coder {
	if ((self = [super init])) {
		timestamp = [[coder decodeObjectForKey:@"timestamp"] retain];
		data = [[coder decodeObjectForKey:@"data"] retain];
	}
	return self;
}
-(NSComparisonResult)compare:(ClipboardEntry*)entry { return [timestamp compare:entry->timestamp]; }

-(NSString*)description { return [NSString stringWithFormat:@"%@ (%@)", [data description], [timestamp description]]; }

-(id)copyWithZone:(NSZone*)zone {
	ClipboardEntry* newSelf = [[ClipboardEntry allocWithZone:zone] init];
	if (newSelf != nil) {
		if ([data conformsToProtocol:@protocol(NSCopying)])
			newSelf->data = [data copy];
		else
			newSelf->data = [data retain];
		newSelf->timestamp = [timestamp copy];
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

-(void)deriveDates {
	if (count > 0) {
		latestDate = ((ClipboardEntry*)[entries lastObject])->timestamp;
		oldestDate = ((ClipboardEntry*)[entries objectAtIndex:0])->timestamp;
	} else {
		latestDate = oldestDate = nil;
	}
}

-(void)fixEntriesCount {
	[entries removeObjectsInRange:NSMakeRange(0, count-capacity)];
	count = capacity;
}

-(void)deriveOtherIVars {
	count = [entries count];
	if (capacity < count)
		[self fixEntriesCount];
	path = nil;
	[self deriveDates];
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
		} else
			self = [self initWithCapacity:capac];
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
		// dates are weak-ref, so don't copy.
		[newSelf deriveDates];
	}
	return newSelf;
}

-(void)addEntry:(ClipboardEntry*)entry {
	// the list of entries is empty. Directly add the entry & set the timestamps.
	if (count == 0) {
		[entries addObject:entry];
		oldestDate = latestDate = entry->timestamp;
		count = 1;
		
	// the list is not yet full. Insert the entry and sort, then recompute the timestamps.
	} else if (count < capacity) {
		insertObjectIntoSortedArrayUsingSelector(entry, entries, @selector(compare:));
		if ([latestDate earlierDate:entry->timestamp])
			latestDate = entry->timestamp;
		if ([entry->timestamp earlierDate:oldestDate])
			oldestDate = entry->timestamp;
		++ count;
		
	// the list is full already. Discard old info.
	} else {
		// the entry to be added is newest. just discard the oldest and insert the newest.
		if ([latestDate earlierDate:entry->timestamp]) {
			[entries removeObjectAtIndex:0];
			[entries addObject:entry];
			latestDate = entry->timestamp;
			oldestDate = ((ClipboardEntry*)[entries objectAtIndex:0])->timestamp;
		}
		// the entry to be added is not older than oldest.
		// discard the oldest and insert with sort.
		if ([oldestDate earlierDate:entry->timestamp]) {
			[entries removeObjectAtIndex:0];
			insertObjectIntoSortedArrayUsingSelector(entry, entries, @selector(compare:));
			oldestDate = ((ClipboardEntry*)[entries objectAtIndex:0])->timestamp;
		}
	}
	
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
			oldestDate = ((ClipboardEntry*)[entries objectAtIndex:0])->timestamp;
		}
		[self save];
	}
}

-(void)addEntriesFromClipboard:(Clipboard*)anotherClipboard {
	NSMutableArray* resultingArray = [[NSMutableArray alloc] init];
	NSEnumerator* enum1 = [entries reverseObjectEnumerator];
	NSEnumerator* enum2 = [anotherClipboard->entries reverseObjectEnumerator];
	
	// Implemented from C++'s merge().
	ClipboardEntry* e1 = [enum1 nextObject];
	ClipboardEntry* e2 = [enum2 nextObject];
	 
	count = 0;
	while (count < capacity) {
		// we are exhausted. copy all their data to here.
		if (e1 == nil) {
			for (; count < capacity && e2 != nil; ++ count) {
				[resultingArray addObject:e2];
				e2 = [enum2 nextObject];
			}
			break;
		
		// they are exhausted. copy all our data to here.
		} else if (e2 == nil) {
			for (; count < capacity && e1 != nil; ++ count) {
				[resultingArray addObject:e1];
				e1 = [enum1 nextObject];
			}
			break;

		// both still have entries left. compare & select the latest one to add.
		} else {
			if ([e1->timestamp earlierDate:e2->timestamp])
				[resultingArray addObject:e2];
			else
				[resultingArray addObject:e1];
			++ count;
		}
	}
	
	reverseArray(resultingArray);
	[entries release];
	entries = resultingArray;
	[self deriveDates];
	[self save];
}

-(void)erase {
	[entries removeAllObjects];
	count = 0;
	oldestDate = latestDate = nil;
	[self save];
}

-(BOOL)save { return (path != nil) ? [self saveToPath:path] : YES; }
-(BOOL)saveToPath:(NSString*)path_ { return [NSKeyedArchiver archiveRootObject:self toFile:path_]; }

-(NSObject*)dataAtIndex:(NSUInteger)index { return (index < count) ? ((ClipboardEntry*)[entries objectAtIndex:index]).data : nil; }
-(NSDate*)timestampAtIndex:(NSUInteger)index { return (index < count) ? ((ClipboardEntry*)[entries objectAtIndex:index]).timestamp : nil; }
-(NSObject*)dataAtReversedIndex:(NSUInteger)index { return (index < count) ? ((ClipboardEntry*)[entries objectAtIndex:count-1-index]).data : nil; }
-(NSDate*)timestampAtReversedIndex:(NSUInteger)index { return (index < count) ? ((ClipboardEntry*)[entries objectAtIndex:count-1-index]).timestamp : nil; }

-(void)removeEntryAtIndex:(NSUInteger)index {
	if (index < count) {
		[entries removeObjectAtIndex:index];
		-- count;
		if (count > 0) {
			if (index == count) {
				latestDate = ((ClipboardEntry*)[entries lastObject])->timestamp;
			}
			if (index == 0) {
				oldestDate = ((ClipboardEntry*)[entries objectAtIndex:0])->timestamp;
			}
		} else {
			latestDate = oldestDate = nil;
		}
		[self save];
	}
}
-(void)removeEntryAtReversedIndex:(NSUInteger)index { [self removeEntryAtIndex:count-1-index]; }

-(void)updateEntryAtIndex:(NSUInteger)index {
	if (index < count-1) {
		ClipboardEntry* entry = [[entries objectAtIndex:index] retain];
		entry.timestamp = [NSDate date];
		[entries removeObjectAtIndex:index];
		[entries addObject:entry];
		if (index == 0) {
			oldestDate = ((ClipboardEntry*)[entries objectAtIndex:0])->timestamp;
		}
		latestDate = entry->timestamp;
		[entry release];
		[self save];
	}
}
-(void)updateEntryAtReversedIndex:(NSUInteger)index { [self updateEntryAtIndex:count-1-index]; }

-(void)addData:(NSObject*)data {
	ClipboardEntry* newEntry = [ClipboardEntry entryWithData:data];
	latestDate = newEntry->timestamp;
	if (count >= capacity) {
		[entries removeObjectAtIndex:0];
		if (count > 1)
			oldestDate = ((ClipboardEntry*)[entries objectAtIndex:0])->timestamp;
	} else
		++ count;
	[entries addObject:newEntry];
	[self save];
}

-(NSObject*)lastData { return ((ClipboardEntry*)[entries lastObject]).data; }
-(NSDate*)lastTimestamp { return ((ClipboardEntry*)[entries lastObject]).timestamp; }

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

-(NSArray*)allDataOfClass:(Class)cls {
	NSMutableArray* retArr = [NSMutableArray array];
	for (ClipboardEntry* entry in entries) {
		if ([entry->data isKindOfClass:cls])
			[retArr addObject:entry->data];
	}
	return retArr;
}

-(NSArray*)allDataReversedOfClass:(Class)cls {
	NSMutableArray* retArr = [NSMutableArray array];
	for (ClipboardEntry* entry in [entries reverseObjectEnumerator]) {
		if ([entry->data isKindOfClass:cls])
			[retArr addObject:entry->data];
	}
	return retArr;
}

-(NSString*)description { return [entries description]; }

@end
