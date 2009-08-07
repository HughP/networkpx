/*

layout-plist-to-keyboards.m ... Convert layout.plist to .keyboard files.
 
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
#import "UIKBKeyboardFromLayoutPlist.h"
#import <stdio.h>
#import <mach-o/nlist.h>

UIKBKeyboard* (*UIKBGetKeyboardByName)(NSString*);

int main (int argc, const char* argv[]) {
	if (argc <= 1) {
		printf("Usage: layout-plist-to-keyboards <layout-plist>\n\n");
	} else {
		NSAutoreleasePool* pool = [NSAutoreleasePool new];
		
		{
			struct nlist nl[2];
			memset(nl, 0, sizeof(nl));
			nl[0].n_un.n_name = "_UIKBGetKeyboardByName";
			nlist("/System/Library/Frameworks/UIKit.framework/UIKit", nl);
			UIKBGetKeyboardByName = (UIKBKeyboard*(*)(NSString*))nl[0].n_value;
		}
		
		NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithContentsOfFile:[NSString stringWithUTF8String:argv[1]]];
		NSMutableData* data = [NSMutableData data];
		
		static NSString* const keyboards[] = {@"", @"URL", @"Email", @"NamePhonePad"};
		for (unsigned i = 0; i < 4; ++ i) {
			[data setLength:0];
			UIKBKeyboard* landscapeKeyboard = IKXUIKBKeyboardFromLayoutPlist(dict, keyboards[i], YES);
			NSKeyedArchiver* landscapeArchiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
			[landscapeArchiver encodeObject:landscapeKeyboard forKey:@"keyboard"];
			[landscapeArchiver finishEncoding];
			[data writeToFile:[NSString stringWithFormat:@"iPhone-Landscape-QWERTY%s%@.keyboard", (i==0?"":"-"), keyboards[i]] atomically:NO];
			[landscapeArchiver release];
			
			[data setLength:0];
			UIKBKeyboard* portraitKeyboard = IKXUIKBKeyboardFromLayoutPlist(dict, keyboards[i], NO);
			NSKeyedArchiver* portraitArchiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
			[portraitArchiver encodeObject:portraitKeyboard forKey:@"keyboard"];
			[portraitArchiver finishEncoding];
			[data writeToFile:[NSString stringWithFormat:@"iPhone-Portrait-QWERTY%s%@.keyboard", (i==0?"":"-"), keyboards[i]] atomically:NO];
			[portraitArchiver release];
		}
		
		[pool drain];
	}
	
	return 0;
}