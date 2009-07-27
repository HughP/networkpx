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