/*
 
 MailCrashLog.m ... Library for mailing crash log and relevant information to developer.
 
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

#import <UIKit3/UIMailComposeView.h>
#import <MessageUI/MailComposeController.h>
#import <UIKit3/UIUtilities.h>
#import <MailCrashLog.h>
#include <stdio.h>

#define REQUIRE_APP_SWITCHING [MailComposeController isSetupForDelivery]

@implementation MailCrashLogManager
@synthesize view;
@dynamic controller;
-(MailComposeController*)controller { return view.controller; }


+(BOOL)requireAppSwitching { return REQUIRE_APP_SWITCHING; }

-(id)initWithView:(UIView*)superview emailAddress:(NSString*)targetEmail subject:(NSString*)subject_ body:(NSString*)body_ {
	NSURL* mailURL = [NSURL URLWithString:[NSString stringWithFormat:@"mailto:%@?subject=%@&body=%@",
										   targetEmail,
										   [subject_ stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
										   [body_ stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];	
	if ((self = [super init])) {
		CGRect frame;
		if (superview == nil) {
			frame = [UIScreen mainScreen].applicationFrame;
			superview = [UIApplication sharedApplication].keyWindow;
		} else
			frame = superview.bounds;
		
		view = [[UIMailComposeView alloc] initWithFrame:frame];
		[superview addSubview:view];
		[view showWithURL:mailURL showKeyboardImmediately:NO];
	}
	
#if !defined(TARGET_IPHONE_SIMULATOR) || !TARGET_IPHONE_SIMULATOR
	if (!REQUIRE_APP_SWITCHING) {
		[[UIApplication sharedApplication] openURL:mailURL];
		return nil;
	}
#endif
	
	return self;
}

-(void)dealloc {
	[view release];
	[super dealloc];
}

-(void)attachFile:(NSString*)path {
	[view.controller addInlineAttachmentAtPath:path includeDirectoryContents:NO]; 
}
-(void)attachData:(NSData*)data withFilename:(NSString*)newFilename { 
	[self attachData:data withFilename:newFilename mimeType:@"application/octet-stream"]; 
}

-(void)attachData:(NSData*)data withFilename:(NSString*)newFilename mimeType:(NSString*)mimeType { 
	[view.controller addInlineAttachmentWithData:data preferredFilename:newFilename mimeType:mimeType]; 
}

-(void)attachOutputOfCommandLine:(const char*)commandline withFilename:(NSString*)newFilename {
#define BUFFER_SIZE 4096
	char buffer[BUFFER_SIZE];
	NSMutableData* data = [[NSMutableData alloc] init];
	FILE* f = popen(commandline, "r");
	while (!feof(f)) {
		size_t bytesRead = fread(buffer, 1, BUFFER_SIZE, f);
		[data appendBytes:buffer length:bytesRead];
	}
	pclose(f);
#undef BUFFER_SIZE
	[self attachData:data withFilename:newFilename mimeType:@"text/plain"];
	[data release];
}

@end
