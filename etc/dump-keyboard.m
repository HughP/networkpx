/*

dump-keyboard.c ... Dump UIKit UIKBKeyboards
 
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

int lookup_function_pointers(const char*, ...);

struct fnentry {
	const char* name;
	id (*fptr)(void);
};

int xmain (int argc, const char* argv[]) {
	if (argc < 2) {
		printf("Usage: dump-keyboard <symbol-of-fntable> [<keyboard-count> = 148]\n\n");
		return 0;
	}
	
	NSAutoreleasePool* pool = [NSAutoreleasePool new];
	
	const char* fnsym = argv[1];
	int kbcount = argc >= 3 ? atoi(argv[2]) : 148;
	struct fnentry* table = NULL;
	
	int err = lookup_function_pointers("UIKit", fnsym, &table, NULL);
	
	NSMutableData* sharedData = [NSMutableData data];
	
	if (table != NULL) {
		for (int i = 0; i < kbcount; ++ i) {
			fprintf(stderr, "Writing %s...\n", table[i].name);
			[sharedData setLength:0];
			NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:sharedData];
			[archiver encodeObject:table[i].fptr() forKey:@"keyboard"];
			[archiver finishEncoding];
			[sharedData writeToFile:[[NSString stringWithFormat:@"~/Documents/%s.keyboard", table[i].name] stringByExpandingTildeInPath] atomically:NO];
			[archiver release];
		}
	} else
		fprintf(stderr, "Cannot find symbol %s. Error code = %d.\n\n", fnsym, err);
	
	[pool drain];
	
	return 0;
}