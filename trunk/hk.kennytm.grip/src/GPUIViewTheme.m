/*

GPNibTheme.m ... GriP Theme using .nib file to render the content.
 
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

#import <GriP/GPUIViewTheme.h>
#import <Foundation/Foundation.h>
#import <GriP/common.h>
#import <UIKit/UIKit.h>
#import <GriP/GPPreferences.h>
#import <GriP/GPMessageWindow.h>
#import <GriP/GPGetSmallAppIcon.h>

#if GRIP_JAILBROKEN
// from UIKit.framework. 3.0-compatible
@interface UITextView ()
-(void)setContentToHTMLString:(NSString*)html;
@end
#endif


@implementation GPUIViewTheme
-(void)modifyView:(UIView*)inoutView asNew:(BOOL)asNew withMessage:(NSDictionary*)message {}
+(void)updateViewForDisclosure:(UIView*)view {}
+(void)activateView:(UIView*)view {}
+(void)deactivateView:(UIView*)view {}

-(id)initWithBundle:(NSBundle*)bundle {
	if ((self = [super init])) {
		selfBundle = [bundle retain];		
		for (int i = 0; i < 5; ++ i)
			GPCopyColorsForPriority(i-2, bgColors+i, fgColors+i);
	}
	return self;
}
-(void)display:(NSDictionary*)message {
	NSString* identifier = [message objectForKey:GRIP_ID];
	UIView* newView = nil;
	
	// Manufactor a the new view from nib if required. Reuse a view if identifier is given.
	BOOL asNew = NO;
	GPMessageWindow* window = nil;
	if (identifier != nil)
		window = [GPMessageWindow windowForIdentifier:identifier];
	if (window == nil) {
		asNew = YES;
		newView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [GPMessageWindow maxWidth], 60)];
	} else
		newView = window.view;

	[window prepareForResizing];
	
	[self modifyView:newView asNew:asNew withMessage:message];
	if ([message objectForKey:GRIP_DETAIL] != nil && [GPMessageWindow defaultExpanded])
		[[self class] updateViewForDisclosure:newView];
	
	if (window == nil) {
		[GPMessageWindow registerWindowWithView:newView message:message];
	} else {
		[window refreshWithMessage:message];
		[window resize];
	}
	
	if (asNew)
		[newView release];
}

-(void)dealloc {
	for (int i = 0; i < 5; ++ i) {
		[fgColors[i] release];
		[bgColors[i] release];
	}	
	[selfBundle release];
	[super dealloc];
}
@end

@implementation GPUIViewTheme (TargetActions)
+(void)close:(UIView*)button { [(GPMessageWindow*)button.window hide:YES]; }
+(void)disclose:(UIView*)button {
	GPMessageWindow* window = (GPMessageWindow*)button.window;
	[window stopHiding];
	[window stopTimer];
	[window forceSticky];
	[window prepareForResizing];
	[self updateViewForDisclosure:window.view];
	[window resize];
}
+(void)activate:(UIView*)clickContext {
	GPMessageWindow* window = (GPMessageWindow*)clickContext.window;
	[window stopTimer];
	[self activateView:window.view]; 
}
+(void)deactivate:(UIView*)clickContext {
	GPMessageWindow* window = (GPMessageWindow*)clickContext.window;
	[window restartTimer];
	[self deactivateView:window.view]; 	
}
+(void)fire:(UIView*)clickContext { [(GPMessageWindow*)clickContext.window hide:NO]; }
@end
