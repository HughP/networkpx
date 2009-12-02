/*

symbolicate.m ... Symbolicate a crash log.
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

#import <Foundation/Foundation.h>
#import "symbolicate.h"
#import "RegexKitLite.h"
#include "common.h"
#import <Symbolication/Symbolication.h>
#import <UIKit/UIKit2.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>

#if !TARGET_IPHONE_SIMULATOR

enum SymbolicationMode {
	SM_CheckingMode,
	SM_BacktraceMode,
	SM_BinaryImageMode,
};

@interface BacktraceInfo : NSObject {
@package
//	NSString* binary;
	NSString* start_address;
	unsigned long long address;
}
@end
@implementation BacktraceInfo
@end


@interface ObjCInfo : NSObject {
@package
	unsigned long long impAddr;
	NSString* name;
}
@end
@implementation ObjCInfo
@end
static CFComparisonResult CompareObjCInfos(ObjCInfo* a, ObjCInfo* b) {
	return a->impAddr < b->impAddr ? kCFCompareLessThan : a->impAddr > b->impAddr ? kCFCompareGreaterThan : kCFCompareEqualTo;
}


@interface BinaryInfo : NSObject {
@package
	long long slide;	// slide = text address - actual address.
	VMUSymbolOwner* owner;
	VMUMachOHeader* header;
	NSArray* objcArray;
	NSString* path;
	NSUInteger line;
}
@end
@implementation BinaryInfo
@end


static NSString* escapeHTML(NSString* x, NSCharacterSet* escSet) {
	// Do not copy unless we're sure the string contains the characters we want to escape.
	if ([x rangeOfCharacterFromSet:escSet].location != NSNotFound) {
		NSMutableString* rx = [NSMutableString stringWithString:x];
		[rx replaceOccurrencesOfString:@"&" withString:@"&amp;" options:0 range:NSMakeRange(0, [rx length])];
		[rx replaceOccurrencesOfString:@"<" withString:@"&lt;" options:0 range:NSMakeRange(0, [rx length])];
		[rx replaceOccurrencesOfString:@">" withString:@"&gt;" options:0 range:NSMakeRange(0, [rx length])];
		return rx;
	} else {
		return x;
	}
}

static char move_as_root_path_[64];
static const char* move_as_root_path() {
	if (move_as_root_path_[0] == '\0') {
		[[[NSBundle mainBundle] pathForResource:@"move_as_root" ofType:nil] getCString:move_as_root_path_
																			 maxLength:sizeof(move_as_root_path_)
																			  encoding:NSUTF8StringEncoding];
	}
	return move_as_root_path_;
}


NSString* symbolicate(NSString* file, UIProgressHUD* hudReply) {
	NSAutoreleasePool* localPool = [[NSAutoreleasePool alloc] init];
	NSBundle* mainBundle = [NSBundle mainBundle];	// 0
	NSString* curPath = [[NSFileManager defaultManager] currentDirectoryPath];
	
	NSString* file_content = [[NSString alloc] initWithContentsOfFile:file encoding:NSUTF8StringEncoding error:NULL];
	if ([file_content length] == 0) {
		const char* file_cstr = [[curPath stringByAppendingPathComponent:file] UTF8String];
		int fds[2];
		pipe(fds);
		const char* marp = move_as_root_path();
		pid_t pid = fork();
		if (pid == 0) {
			if (fds[1] != 1) {
				dup2(fds[1], 1);
				close(fds[1]);
			}
			close(fds[0]);
			execl(marp, marp, file_cstr, NULL);
			_exit(0);
		} else if (pid != -1) {
			close(fds[1]);
			char buf[1024];
			size_t actual_size;
			NSMutableData* data = [[NSMutableData alloc] init];
			while ((actual_size = read(fds[0], buf, 1024)) > 0)
				[data appendBytes:buf length:actual_size];
			close(fds[0]);
			file_content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
			[data release];
		}		
	}
	if ([file_content length] == 0) {
		return file;
	}
	
	NSMutableArray* file_lines = [[file_content componentsSeparatedByString:@"\n"] mutableCopy];	// 1
	[file_content release];
	NSString* symbolicating = [mainBundle localizedStringForKey:@"Symbolicating (%d%%)" value:nil table:nil];	// 0
	
	[hudReply setText:[NSString stringWithFormat:symbolicating, 0]];
	CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.01, false);
	
	enum SymbolicationMode mode = SM_CheckingMode;
	
	NSMutableArray* extraInfoArr = [[NSMutableArray alloc] init];	// 1
	NSMutableDictionary* binaryImages = [[NSMutableDictionary alloc] init];	// 1
	
	for (NSString* line in file_lines) {
		BOOL isBinImg = [line isEqualToString:@"Binary Images:"];
		id extraInfo = [NSNull null];
		
		switch (mode) {
			case SM_CheckingMode:
				if ([line hasPrefix:@"Thread 0"])
					mode = SM_BacktraceMode;
				else if (isBinImg)
					goto finish;
				else
					break;
				
			case SM_BacktraceMode:
				if (isBinImg)
					mode = SM_BinaryImageMode;
				else if ([line length] > 0) {
					if ([line hasSuffix:@"Crashed:"])
						extraInfo = (id)kCFBooleanTrue;
					else if ([line hasSuffix:@":"])
						extraInfo = (id)kCFBooleanFalse;
					else {
						NSArray* res = [line captureComponentsMatchedByRegex:@"^\\d+ +.*\\S\\s+0x([0-9a-f]+) 0x([0-9a-f]+) \\+ \\d+$"];
						if ([res count] == 3) {
							NSString* matches[2];
							[res getObjects:matches range:NSMakeRange(1, 2)];
							
							BacktraceInfo* bti = [[[BacktraceInfo alloc] init] autorelease];
//							bti->binary = matches[0];
							bti->start_address = matches[1];
							bti->address = convertHexStringToLongLong([matches[0] UTF8String], [matches[0] length]);
							extraInfo = bti;
						}
					}
				}
				break;
				
			case SM_BinaryImageMode: {
				NSArray* res = [line captureComponentsMatchedByRegex:@"^ *0x([0-9a-f]+) - *[0-9a-fx]+ [ +](.+?) arm\\w*  (?:&lt;[0-9a-f]{32}&gt; )?(.+)$"];
				if ([res count] != 4)
					goto finish;
				
				[binaryImages setObject:res forKey:[res objectAtIndex:1]];
				break;
			}
		}
		
		[extraInfoArr addObject:extraInfo];
	}
	
finish:
	;
	NSCharacterSet* escSet = [NSCharacterSet characterSetWithCharactersInString:@"<>&"];

	NSUInteger i = 0, total_lines = [extraInfoArr count];
	BOOL isCrashing = NO;
	BOOL hasHeaderFromSharedCacheWithPath = [VMUMemory_File respondsToSelector:@selector(headerFromSharedCacheWithPath:)];
	NSDictionary* whiteListFile = [[NSDictionary alloc] initWithContentsOfFile:[mainBundle pathForResource:@"whitelist" ofType:@"plist"]];
	NSSet* filters = [[NSSet alloc] initWithArray:[whiteListFile objectForKey:@"Filters"]];
	NSArray* prefixFilters = [[whiteListFile objectForKey:@"PrefixFilters"] retain];
	[whiteListFile release];
	Class bicls = [BinaryInfo class];
	int last_percent = 0;
	
	for (BacktraceInfo* bti in extraInfoArr) {
		int this_percent = MIN(100, 200*i / total_lines);
		if (this_percent != last_percent) {
			last_percent = this_percent;
			[hudReply setText:[NSString stringWithFormat:symbolicating, this_percent]];
			CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.01, false);
		}
		
		if (bti == (id)kCFBooleanTrue)
			isCrashing = YES;
		else if (bti == (id)kCFBooleanFalse)
			isCrashing = NO;
		else if (bti != (id)kCFNull) {
			BinaryInfo* bi = [binaryImages objectForKey:bti->start_address];
			if (bi != nil) {					
				if (![bi isKindOfClass:bicls]) {
					NSString* matches[3];
					[(NSArray*)bi getObjects:matches range:NSMakeRange(1, 3)];
					
					VMUMachOHeader* header = nil;
					if (hasHeaderFromSharedCacheWithPath)
						header = [VMUMemory_File headerFromSharedCacheWithPath:matches[2]];
					if (header == nil)
						header = [VMUMemory_File headerWithPath:matches[2]];
					
					if (header != nil) {
						bi = [[BinaryInfo alloc] init];
						
						unsigned long long start = convertHexStringToLongLong([matches[0] UTF8String], [matches[0] length]);
						unsigned long long textStart = [[header segmentNamed:@"__TEXT"] vmaddr];
						bi->slide = textStart - start;
						bi->owner = [VMUSymbolExtractor extractSymbolOwnerFromHeader:header];
						bi->header = header;
						bi->path = matches[2];
						bi->line = 0;
						
						[binaryImages setObject:bi forKey:bti->start_address];
						[bi release];
					} else {
						[binaryImages removeObjectForKey:bti->start_address];
						goto found_nothing;
					}
				}
				
				// Try to blame the BinaryInfo.
				if (bi->line == 0 || (bi->line != ~0u && (bi->line & 0x80000000) && isCrashing)) {
					// Don't blame system libraries.
					if (!(hasHeaderFromSharedCacheWithPath && [bi->header isFromSharedCache])) {
						// Don't blame white-listed libraries.
						if ([filters containsObject:bi->path])
							bi->line = ~0u;
						else {
							// Don't blame white-listed folders.
							for (NSString* prefix in prefixFilters) {
								if ([bi->path hasPrefix:prefix]) {
									bi->line = ~0u;
									goto dont_blame;
								}
							}
							// blame.
							bi->line = i;
							// make it a secondary suspect if it isn't in the crashing thread.
							if (!isCrashing)
								bi->line |= 0x80000000;
						}
					} else
						bi->line = ~0u;
				}
			dont_blame:;
				
				NSString* extra_string = nil;
				unsigned long long addr = bti->address + bi->slide;
				
				VMUSourceInfo* srcInfo = [bi->owner sourceInfoForAddress:addr];
				if (srcInfo != nil) {
					extra_string = [NSString stringWithFormat:@"\t// %@:%u", escapeHTML([srcInfo path], escSet), [srcInfo lineNumber]];
				} else {
					VMUSymbol* sym = [bi->owner symbolForAddress:addr];
					if (sym != nil)
						extra_string = [NSString stringWithFormat:@"\t// %@ + 0x%llx", escapeHTML([sym name], escSet), addr - [sym addressRange].location];
					else {
						// Try to extract some ObjC info.
						// (Copied from MachO_File of the Peace project.)
						if (bi->objcArray == nil) {
							NSMutableArray* objcArr = [NSMutableArray array];
							
							id<VMUMemoryView> mem = [[bi->header memory] view];							
							VMUSegmentLoadCommand* dataSeg = [bi->header segmentNamed:@"__DATA"];
							long long vmdiff_data = [dataSeg fileoff] - [dataSeg vmaddr];
							VMUSegmentLoadCommand* textSeg = [bi->header segmentNamed:@"__TEXT"];
							long long vmdiff_text = [textSeg fileoff] - [textSeg vmaddr];
							
							VMUSection* clsListSect = [dataSeg sectionNamed:@"__objc_classlist"];
							
							[mem setCursor:[clsListSect offset]];
							unsigned size = (unsigned) [clsListSect size];
							for (unsigned ii = 0; ii < size; ii += 4) {
								unsigned vm_address = [mem uint32];
								unsigned long long old_location = [mem cursor];
								[mem setCursor:vm_address + 16 + vmdiff_data];
								unsigned data_loc = [mem uint32];
								[mem setCursor:data_loc + vmdiff_data];
								unsigned flag = [mem uint32];
								[mem advanceCursor:12];
								[mem setCursor:[mem uint32]+vmdiff_text];
								
								char class_method = (flag & 1) ? '+' : '-';
								NSString* class_name = [mem stringWithEncoding:NSUTF8StringEncoding];
								
								[mem setCursor:data_loc + 20 + vmdiff_data];
								unsigned baseMethod_loc = [mem uint32];
								if (baseMethod_loc != 0) {
									[mem setCursor:baseMethod_loc + 4 + vmdiff_data];
									unsigned count = [mem uint32];
									for (unsigned j = 0; j < count; ++ j) {
										ObjCInfo* info = [[ObjCInfo alloc] init];
										
										unsigned sel_name_addr = [mem uint32];
										[mem uint32];
										info->impAddr = [mem uint32] & ~1;
										unsigned long long old_loc_2 = [mem cursor];
										[mem setCursor:sel_name_addr + vmdiff_text];
										NSString* sel_name = [mem stringWithEncoding:NSUTF8StringEncoding];
										[mem setCursor:old_loc_2];
										
										info->name = [NSString stringWithFormat:@"%c[%@ %@]", class_method, class_name, sel_name];
										
										[objcArr addObject:info];
										[info release];
									}
								}
								
								[mem setCursor:old_location];
							}
							
							[objcArr sortUsingFunction:(void*)CompareObjCInfos context:NULL];
							bi->objcArray = objcArr;
						}
						
						CFIndex count = [bi->objcArray count];
						
						if (count != 0) {
							ObjCInfo* obj_to_search = [[ObjCInfo alloc] init];
							obj_to_search->impAddr = addr;
							
							CFIndex objcMatch = CFArrayBSearchValues((CFArrayRef)bi->objcArray, CFRangeMake(0, count), obj_to_search, (CFComparatorFunction)CompareObjCInfos, NULL);
							if (objcMatch >= count)
								objcMatch = count-1;
							ObjCInfo* o = [bi->objcArray objectAtIndex:objcMatch];
							if (o->impAddr > addr) {
								if (objcMatch == 0)
									o = nil;
								else
									o = [bi->objcArray objectAtIndex:objcMatch-1];
							}
							
							if (o != nil)
								extra_string = [NSString stringWithFormat:@"\t// %@ + 0x%llx", o->name, addr - o->impAddr];
						}
					}
				}
				
				if (extra_string != nil) {
					NSString* orig_line = [file_lines objectAtIndex:i];
					[file_lines replaceObjectAtIndex:i withObject:[orig_line stringByAppendingString:extra_string]];
				}
			}
		}
	found_nothing:
		
		++ i;
	}
	[filters release];
	[prefixFilters release];
	
	// Write down blame info.
	NSMutableString* blameInfo = [NSMutableString stringWithString:@"<key>blame</key><array>\n"];
	for (NSString* name in binaryImages) {
		BinaryInfo* bi = [binaryImages objectForKey:name];
		if ([bi isKindOfClass:bicls] && bi->line != ~0u)
			[blameInfo appendFormat:@"<array><string>%@</string><integer>%d</integer></array>\n", escapeHTML(bi->path, escSet), bi->line];
	}
	[blameInfo appendString:@"</array>"];
	[file_lines insertObject:blameInfo atIndex:[file_lines count]-3];
	
	NSString* symbolicatedFile = [[[file stringByDeletingPathExtension] stringByAppendingString:@".symbolicated.plist"] retain];
	NSString* lines_to_write = [file_lines componentsJoinedByString:@"\n"];
	[file_lines release];
	if ([lines_to_write writeToFile:symbolicatedFile atomically:NO encoding:NSUTF8StringEncoding error:NULL]) {
		[[NSFileManager defaultManager] removeItemAtPath:file error:NULL];
	} else {
		char temp_name[strlen("/tmp/crash_reporter.XXXXXX")+1];
		memcpy(temp_name, "/tmp/crash_reporter.XXXXXX", sizeof(temp_name));
		mktemp(temp_name);
		[lines_to_write writeToFile:[NSString stringWithUTF8String:temp_name] atomically:NO encoding:NSUTF8StringEncoding error:NULL];
		const char* actual_sym_file_path = [[curPath stringByAppendingPathComponent:symbolicatedFile] UTF8String];
		const char* actual_file_path = [[curPath stringByAppendingPathComponent:file] UTF8String];
		
		exec_move_as_root(temp_name, actual_sym_file_path, actual_file_path);
	}
	
	[extraInfoArr release];
	[binaryImages release];
	
	[localPool drain];
	
	return [symbolicatedFile autorelease];
}

void exec_move_as_root(const char* from, const char* to, const char* rem) {
	pid_t pid = fork();
	const char* path = move_as_root_path();
	if (pid == 0) {
		execl(path, path, from, to, rem, NULL);
		_exit(0);
	} else if (pid != -1) {
		int stat_loc;
		waitpid(pid, &stat_loc, 0);
	}
}

#if TEST_SYMBOLICATION

int main (int argc, const char* argv[]) {
	if (argc == 1) {
		printf("Usage: symbolicate <file-name>\n");
	} else {
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		NSString* file = [NSString stringWithUTF8String:argv[1]];
		NSString* res = symbolicate(file, nil);
		
		printf("Result written to %s.\n", [res UTF8String]);
		
		[pool drain];
	}
	return 0;
}

#endif

#endif
