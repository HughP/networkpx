/*
 
 dump-artwork.m ... Dump artwork from UIKit.
 
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

#import <mach-o/nlist.h>	// struct nlist
#import <Foundation/Foundation.h>
#import <stdio.h>
#import <UIKit/UIKit.h>

struct MappedImageInfo {
	NSString* name;	// 0
	// Required by input:
	unsigned* indices; // 4
	NSString** filenames; // 8
	unsigned count; // c
	// Output:
	int fildes; // 10
	unsigned filesize;	// 14
	void* map;	// 18
};	// sizeof = 0x1c.

void UIRegisterMappedImageSet(struct MappedImageInfo* info, NSString* path);
@interface UIImage (UIImagePrivate)
+(UIImage*)applicationImageNamed:(NSString*)name;
@end

void dump(const struct MappedImageInfo* info, NSString* srcpath, NSFileManager* man) {
	[man createDirectoryAtPath:info->name withIntermediateDirectories:NO attributes:nil error:NULL];
	[man changeCurrentDirectoryPath:info->name];
	if (info->filenames != NULL)
		for (unsigned j = 0; j < info->count; ++ j) {
			UIImage* image = [UIImage applicationImageNamed:info->filenames[j]];
			NSData* imageSrc = UIImagePNGRepresentation(image);
			[imageSrc writeToFile:info->filenames[j] atomically:NO];
		}
	[man changeCurrentDirectoryPath:@".."];
}

int main(int argc, const char* argv[]) {
	NSAutoreleasePool* pool = [NSAutoreleasePool new];
	unsigned retval = 0;
	
	NSFileManager* man = [NSFileManager defaultManager];
	
	if (argc == 2) {
		printf("Usage: dump-artwork\n\n");
	} else {
		NSBundle* uikitBundle = [NSBundle bundleWithIdentifier:@"com.apple.UIKit"];
		struct MappedImageInfo* mappedImageSets, *EmojiMappedImageSet;
		
		struct nlist symbols[3];
		memset(symbols, 0, sizeof(symbols));
		symbols[0].n_un.n_name = "_mappedImageSets";
		symbols[1].n_un.n_name = "_EmojiMappedImageSet";
		nlist([[uikitBundle executablePath] UTF8String], symbols);
		mappedImageSets = (struct MappedImageInfo*)symbols[0].n_value;
		EmojiMappedImageSet = (struct MappedImageInfo*)symbols[1].n_value;
		
		NSString* uikitBundlePath = [uikitBundle bundlePath];
		
		if (mappedImageSets != NULL) {
			for (unsigned i = 0; i < 3; ++ i)
				dump(mappedImageSets+i,
					 [[uikitBundlePath stringByAppendingPathComponent:mappedImageSets[i].name] stringByAppendingPathExtension:@"artwork"],
					 man);
		}
		if (EmojiMappedImageSet != NULL)
			dump(EmojiMappedImageSet, [[uikitBundlePath stringByAppendingPathComponent:EmojiMappedImageSet->name] stringByAppendingPathExtension:@"artwork"], man);	
	}
	
	[pool drain];
	return retval;
}