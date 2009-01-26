/*
 
 clipboard.h ... Persistent clipboard manager in Objective-C
 
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


#import <Foundation/Foundation.h>



@interface ClipboardEntry : NSObject<NSCoding,NSCopying> {
	@package
		NSObject* data;
		BOOL secure;
}
+(ClipboardEntry*)entryWithData:(NSObject*)data_ secure:(BOOL)security;
+(ClipboardEntry*)entryWithData:(NSObject*)data_;
+(ClipboardEntry*)entryWithSecureData:(NSObject*)data_;
-(id)initWithData:(NSObject*)data_ secure:(BOOL)security;
@property(retain) NSObject* data;
@property(assign,getter=isSecure) BOOL secure;

-(void)encodeWithCoder:(NSCoder*)coder;
-(id)initWithCoder:(NSCoder*)coder;
-(NSString*)description;
-(id)copyWithZone:(NSZone*)zone;
@end




@interface Clipboard : NSObject<NSCoding,NSCopying> {
	NSMutableArray* entries;		// entries will be sorted by time with lastObject as the newest one.
	NSUInteger capacity;
	NSString* path;
	NSUInteger count;
}

-(void)encodeWithCoder:(NSCoder*)coder;
-(id)initWithCoder:(NSCoder*)coder;

// obtain the default clipboard located at ~/Library/Keyboard/clipboard.plist
//  (the only relevant location the default sandbox allows read&write :< ).
+(Clipboard*)defaultClipboard;
+(Clipboard*)defaultClipboardWithDefaultCapacity:(NSUInteger)capac;

// obtain the clipboard located at specified path.
+(Clipboard*)clipboardWithPath:(NSString*)path_;
+(Clipboard*)clipboardWithPath:(NSString*)path_ defaultCapacity:(NSUInteger)capac;

// initialize an empty clipboard with default capacity (10 entries).
-(id)init;

// initialize the default clipboard.
-(id)initDefaultClipboard;

// initialize an empty clipboard with specified capacity.
-(id)initWithCapacity:(NSUInteger)capac;

// initialize and load clipboard from specified path.
// if no files is in path_, an empty clipboard with default parameters is allocated and saved there.
-(id)initWithPath:(NSString*)path_;
-(id)initWithPath:(NSString*)path_ defaultCapacity:(NSUInteger)capac;

// Support copying a clipboard.
-(id)copyWithZone:(NSZone*)zone;

// obtain clipboard data & timestamp at index.
-(NSObject*)dataAtIndex:(NSUInteger)index;
-(BOOL)isSecureAtIndex:(NSUInteger)index;
-(NSObject*)dataAtReversedIndex:(NSUInteger)index;
-(BOOL)isSecureAtReversedIndex:(NSUInteger)index;

// remove clipboard entry at index.
-(void)removeEntryAtIndex:(NSUInteger)index;
-(void)removeEntryAtReversedIndex:(NSUInteger)index;

// push new data to clipboard.
-(void)addData:(NSObject*)data secure:(BOOL)secure;
-(void)addData:(NSObject*)data;
-(void)addSecureData:(NSObject*)data;

// moving entries
-(void)moveEntryFromIndex:(NSUInteger)idxFrom toIndex:(NSUInteger)idxTo;
-(void)moveEntryFromReversedIndex:(NSUInteger)idxFrom toReversedIndex:(NSUInteger)idxTo;

// obtain latest data & timestamp from clipboard.
-(NSObject*)lastData;
-(BOOL)lastIsSecure;
-(NSObject*)lastNonsecureData;

// obtain the latest data of specified class.
-(NSObject*)lastDataOfClass:(Class)cls;

// obtain all data from clipboard.
-(NSArray*)allData;
-(NSArray*)allDataReversed;

// obtain indices that match the specified conditions
-(NSIndexSet*)allIndices;
-(NSIndexSet*)indicesWithNonsecureData;
-(NSIndexSet*)indicesWithDataOfClass:(Class)cls;

// save the clipboard. Does nothing and return YES if path == nil.
// returns if the process succeed or not.
-(BOOL)save;
// save clipboard to specified path. 
-(BOOL)saveToPath:(NSString*)path;

// clipboard path.
@property(copy) NSString* path;

// erase the whole clipboard.
-(void)erase;

// add (merge) entries from another clipboard.
-(void)addEntriesFromClipboard:(Clipboard*)anotherClipboard;

// add entry with predefined timestamp. You're not recommended to call this unless
// there's old clipboard data you want to merge in.
-(void)addEntry:(ClipboardEntry*)entry;

// some information of the clipboard.
@property(readonly,assign) NSUInteger count;
@property(assign) NSUInteger capacity;

-(NSString*)description;

@end
