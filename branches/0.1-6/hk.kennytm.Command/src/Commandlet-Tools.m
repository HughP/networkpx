/*
 
 Commandlet-Tools.m ... Tools for ⌘lets.
 
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
#import <UIKit/UIApplication.h>
#include <CoreFoundation/CoreFoundation.h>
#include <stdio.h>

static const char* Usage = "Usage:\n\
Commandlet-Tools <command> [<arguments>]\n\
\n\
Available commands:\n\
\turl     Open an URL.\n\n";

static const char* urlUsage = "url Usage:\n\
\t(1) Commandlet-Tools url <url>\n\
\t(2) Commandlet-Tools url <host> <subpage>\n\
\t(3) Commandlet-Tools url <host> <subpage> <paramKey1> <paramValue1> ...\n\
When you use the 2nd or 3rd form, those parameters will be automatically escaped.\n\n";

int main (int argc, const char* argv[]) {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	if (argc == 1)
		printf(Usage);
	else {
		if (!strcmp("url", argv[1])) {
			if (argc == 2)
				printf(urlUsage);
			else {
				NSMutableString* resultString = [NSMutableString stringWithUTF8String:argv[2]];
				if (argc >= 4) {
					// input:       `~!@#$%^&*()_+-=[]\\{}|;':\",./<>?
					// default:    %20%60~!@%23$%25%5E&*()_+-=%5B%5D%5C%7B%7D%7C;':%22,./%3C%3E?
					// encodeURI:  %20%60~!@#$%25%5E&*()_+-=%5B%5D%5C%7B%7D%7C;':%22,./%3C%3E?
					// encURIComp: %20%60~!%40%23%24%25%5E%26*()_%2B-%3D%5B%5D%5C%7B%7D%7C%3B'%3A%22%2C.%2F%3C%3E%3F
					// enc-def:    leave # 
					// comp-def:   also @$&+=;:,/?
					CFStringRef cfString;
					CFStringRef encodedString;
					if (!strcmp(argv[3], "?")) {
						cfString = CFStringCreateWithCString(NULL, argv[3], kCFStringEncodingUTF8);
						encodedString = CFURLCreateStringByAddingPercentEscapes(NULL, cfString, CFSTR("#"), NULL, kCFStringEncodingUTF8);
						if (![resultString hasSuffix:@"/"] && ![encodedString hasPrefix:@"/"])
							[resultString appendString:@"/"];
						[resultString appendString:(NSString*)encodedString];
						CFRelease(encodedString);
						CFRelease(cfString);
					}
					
					for (int i = 4; i < argc; ++ i) {
						if (i % 2 == 0) {
							[resultString appendString:(i==4)?@"?":@"&"];
						} else {
							[resultString appendString:@"="];
						}
						
						cfString = CFStringCreateWithCString(NULL, argv[i], kCFStringEncodingUTF8);
						encodedString = CFURLCreateStringByAddingPercentEscapes(NULL, cfString, NULL, CFSTR("@$&+=;:,/?"), kCFStringEncodingUTF8);
						[resultString appendString:(NSString*)encodedString];
						CFRelease(encodedString);
						CFRelease(cfString);
					}
				}
				UIApplication* app = [[UIApplication alloc] init];
				[app openURL:[NSURL URLWithString:resultString]];
				[app release];
			}
		} else {
			printf("Unregconized command: %s", argv[1]);
		}
	}
	
	[pool drain];
	return 0;
}