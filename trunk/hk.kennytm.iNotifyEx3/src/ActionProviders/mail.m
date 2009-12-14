/*
 
FILE_NAME ... FILE_DESCRIPTION

Copyright (c) 2009  KennyTM~ <kennytm@gmail.com>
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

#import <Message/Message.h>
#include "INXCommon.h"
#import <MessageUI/MessageUI2.h>
#import "INXWindow.h"

static LibraryMessage* lookupMailMessage(NSString* messageID) {
	return [[MailMessageLibrary defaultInstance] messageWithMessageID:messageID];
}

// mail.mark [viewed | not-viewed | replied | forwarded] <msgID>
void mark(NSArray* argv) {
	if ([argv count] >= 3) {
		NSString* args[2];
		[argv getObjects:args range:NSMakeRange(1, 2)];
		LibraryMessage* msg = lookupMailMessage(args[1]);
		if (msg) {
			if ([args[0] isEqualToString:@"viewed"])
				[msg markAsViewed];
			else if ([args[0] isEqualToString:@"not-viewed"])
				[msg markAsNotViewed];
			else if ([args[0] isEqualToString:@"replied"])
				[msg markAsReplied];
			else if ([args[0] isEqualToString:@"forwarded"])
				[msg markAsForwarded];
		}
	}
}

__attribute__((visibility("hidden")))
@interface INXMailComposer : UIView {
	INXSuperiorWindow* _window;
	MailComposeController* _ctrler;
}
@end
@implementation INXMailComposer
-(id)initWithContext:(MailCompositionContext*)context {
	if ((self = [super initWithFrame:CGRectZero])) {
		_window = [INXSuperiorWindow sharedSuperiorWindow];
		CGRect f = _window.bounds;
		f.origin.y += 20;
		f.size.height -= 20;
		self.frame = f;
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		self.autoresizesSubviews = YES;
		[_window addSubview:self];
		_window.interacting = YES;
		
		f.origin.y = 0;
		UINavigationBar* bar = [[UINavigationBar alloc] initWithFrame:f];
		bar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
		[bar sizeToFit];
		[self addSubview:bar];
		[bar release];
		CGFloat barHeight = bar.frame.size.height;
		f.origin.y += barHeight;
		f.size.height -= barHeight;
				
		UINavigationItem* item = [[UINavigationItem alloc] initWithTitle:@""];
		_ctrler = [[MailComposeController alloc] initForContentSize:f.size navigationItem:item showKeyboardImmediately:NO];
		[_ctrler setCompositionContext:context];
		[bar pushNavigationItem:item animated:NO];
		[item release];
		UIView* view = [_ctrler view];
		view.frame = f;
		view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[self addSubview:view];
	}
	return self;
}
-(void)dealloc {
	[_ctrler release];
	[super dealloc];
}
@end



// mail.to [<mailtoURL>]
void to(NSArray* argv) {
	NSString* s[1];
	if (INXRetrieveArguments(argv, s) >= 0) {
		NSURL* url = NULL;
		if (s[0]) {
			if (![s[0] hasPrefix:@"mailto:"])
				url = [NSURL URLWithString:[@"mailto:" stringByAppendingString:s[0]]];
			else
				url = [NSURL URLWithString:s[0]];
		}
			
		MailCompositionContext* context = [MailCompositionContext alloc];
		if (url)
			context = [context initWithURL:url];
		else
			context = [context initWithComposeType:MailCompositionContextType_NewMessage];

		INXMailComposer* composer = [[INXMailComposer alloc] initWithContext:context];
		[context release];
		[composer release];
	}
}

// mail.compose (reply|reply-all|forward) <msgID>
void compose(NSArray* argv) {
	NSString* s[2];
	if (INXRetrieveArguments(argv, s) >= 2) {
		MailCompositionContextType type = MailCompositionContextType_Draft;
		if ([s[0] isEqualToString:@"reply"])
			type = MailCompositionContextType_Reply;
		else if ([s[0] isEqualToString:@"reply-all"])
			type = MailCompositionContextType_ReplyAll;
		else if ([s[0] isEqualToString:@"forward"])
			type = MailCompositionContextType_Forward;
		
		MailCompositionContext* context = [[MailCompositionContext alloc] initWithComposeType:type originalMessage:lookupMailMessage(s[1])];
		INXMailComposer* composer = [[INXMailComposer alloc] initWithContext:context];
		[context release];
		[composer release];
	}
}
