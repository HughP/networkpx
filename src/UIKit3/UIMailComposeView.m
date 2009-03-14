/*
 
 UIMailComposeView.m ... Mail composition without leaving the application and launch MobileMail.app.
 
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
#import <UIKit3/UIUtilities.h>

@implementation UIMailComposeView
@synthesize delegate, controller;
+(BOOL)isSetupForDelivery { return [MailComposeController isSetupForDelivery]; }
-(id)init { return (self = [super initWithFrame:[UIScreen mainScreen].applicationFrame]); }
-(void)layoutSubviews { controller.view.frame = self.bounds; }
-(void)showWithURL:(NSURL*)url showKeyboardImmediately:(BOOL)showKeyboardImmediately {
	if (controller == nil) {
		controller = [[MailComposeController alloc] initForContentSize:self.bounds.size showKeyboardImmediately:showKeyboardImmediately];
		[controller setDelegate:self];
		[self addSubview:controller.view];
		[self layoutSubviews];
	}
	if (url != nil)
		[controller setupForURL:url];
}
-(void)showWithURL:(NSURL*)url { [self showWithURL:url showKeyboardImmediately:YES]; }


-(void)mailComposeControllerCompositionFinished:(id)r2 {
	if ([controller needsDelivery]) {
		[controller retain];
		[controller setDelegate:self];
		[NSThread detachNewThreadSelector:@selector(_deliverMailForController:) toTarget:self withObject:controller];
		alert = [[UIAlertView alloc] init];
		alert.title = [[NSBundle bundleWithPath:@"/Applications/MobileMail.app"] localizedStringForKey:@"SENDING" value:@"Sending" table:@"Main"];
		[alert show];
		UIActivityIndicatorView* indic = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
		[alert addSubview:indic];
		CGSize alertSize = alert.bounds.size;
		indic.center = CGPointMake(alertSize.width/2, alertSize.height/2+10);
		[indic startAnimating];
		[indic release];
	}
	if ([delegate respondsToSelector:@selector(hideMailComposeView:)])
		[delegate hideMailComposeView:self];
	else
		[self didHide];
}

-(void)mailComposeControllerDidAttemptToSend:(MailComposeController*)controller outgoingMessageDelivery:(id)delivery {
	[alert dismissWithClickedButtonIndex:0 animated:NO];
	[alert release];
}

-(void)_deliverMailForController:(MailComposeController*)controller_ {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	if ([controller_ needsDelivery])
		if (![controller_ deliverMessage]) {
			if ([delegate respondsToSelector:@selector(showMailComposeViewError:)])
				[delegate performSelectorOnMainThread:@selector(showMailComposeViewError:) withObject:controller_ waitUntilDone:YES];
		}
	[controller_ releaseOnMainThread];
	[pool drain];
}
-(void)didHide {
	[controller.view removeFromSuperview];
	[controller release];
	controller = nil;
	[self removeFromSuperview];
}
@end
