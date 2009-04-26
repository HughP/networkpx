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

#import <GriP/GPNibTheme.h>
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


@interface GPNibTheme ()
+(void)close:(UIButton*)button;
+(void)disclose:(UIButton*)button;
+(void)activate:(UIButton*)clickContext;
+(void)deactivate:(UIButton*)clickContext;
+(void)fire:(UIButton*)clickContext;
@end

static void GPSetFGColor(UIView* view, UIColor* fgColor) {
	if ([view respondsToSelector:@selector(setTextColor:)])
		[(UILabel*)view setTextColor:fgColor];
	else if ([view respondsToSelector:@selector(setTitleColor:forState:)])
		[(UIButton*)view setTitleColor:fgColor forState:UIControlStateNormal];
}


@implementation GPNibTheme
+(UIView*)modifyView:(UIView*)view asNew:(BOOL)asNew forMessage:(NSDictionary*)message {
	UIColor* bgColor, *fgColor;
	GPGetColorsForPriority([[message objectForKey:GRIP_PRIORITY] integerValue], &bgColor, &fgColor);
	
	GPSetFGColor([view viewWithTag:GPTheme_CloseButton], fgColor);
	GPSetFGColor([view viewWithTag:GPTheme_DisclosureButton], fgColor);
	GPSetFGColor([view viewWithTag:GPTheme_Title], fgColor);
	GPSetFGColor([view viewWithTag:GPTheme_Detail], fgColor);
	[view viewWithTag:GPTheme_Background].backgroundColor = bgColor;
	
	return view;
}
+(void)updateViewForDisclosure:(UIView*)view_ {
	CGRect bounds = view_.bounds;
	bounds.size.height += 60;
	view_.bounds = bounds;
	[view_ viewWithTag:GPTheme_DisclosureButton].hidden = YES;
}
+(void)activateView:(UIView*)view { [view viewWithTag:GPTheme_ActivationBackground].hidden = NO; }
+(void)deactivateView:(UIView*)view { [view viewWithTag:GPTheme_ActivationBackground].hidden = YES; }


-(id)initWithBundle:(NSBundle*)bundle {
	if ((self = [super init])) {
		identifiedViews = [[NSMutableDictionary alloc] init];
		selfBundle = [bundle retain];
	}
	return self;
}
-(void)display:(NSDictionary*)message {
	
	NSString* identifier = [message objectForKey:GRIP_ID];
	UIView* newView = nil;
	
	// Manufactor a the new view from nib if required. Reuse a view if identifier is given.
	BOOL isNewView = NO;
	if (identifier != nil)
		newView = [identifiedViews objectForKey:identifier];
	if (newView == nil) {
		for (UIView* view in [selfBundle loadNibNamed:@"GriPView" owner:nil options:nil])
			if ([view isKindOfClass:[UIView class]]) {
				newView = view;
				break;
			}
		isNewView = YES;
	}
	
	GPMessageWindow* window = (GPMessageWindow*)newView.window;
	if (window != nil)
		[window prepareForResizing];
	
	// make-ups.
	Class selfClass = [self class];
	{
		UIView* closeButton = [newView viewWithTag:GPTheme_CloseButton];
		if ([closeButton respondsToSelector:@selector(addTarget:action:forControlEvents:)])
			[(UIControl*)closeButton addTarget:selfClass action:@selector(close:) forControlEvents:UIControlEventTouchUpInside];
		
		UIView* disclosureButton = [newView viewWithTag:GPTheme_DisclosureButton];
		if ([disclosureButton respondsToSelector:@selector(addTarget:action:forControlEvents:)])
			[(UIControl*)disclosureButton addTarget:selfClass action:@selector(disclose:) forControlEvents:UIControlEventTouchUpInside];
		
		UIView* clickContext = [newView viewWithTag:GPTheme_ClickContext];
		if ([clickContext respondsToSelector:@selector(addTarget:action:forControlEvents:)]) {
			[(UIControl*)clickContext addTarget:selfClass action:@selector(activate:) forControlEvents:UIControlEventTouchDown|UIControlEventTouchDragEnter];
			[(UIControl*)clickContext addTarget:selfClass action:@selector(deactivate:) forControlEvents:UIControlEventTouchDragOutside|UIControlEventTouchDragExit|UIControlEventTouchUpOutside|UIControlEventTouchCancel];
			[(UIControl*)clickContext addTarget:selfClass action:@selector(fire:) forControlEvents:UIControlEventTouchUpInside];
		}
			
		
		NSObject* iconData = [message objectForKey:GRIP_ICON];
		if (iconData != nil) {
			UIView* icon = [newView viewWithTag:GPTheme_Icon];
			if ([icon respondsToSelector:@selector(setImage:)]) {
				UIImage* iconImage = GPGetSmallAppIconFromObject(iconData);
				if (iconImage != nil)
					[(UIImageView*)icon setImage:iconImage];
			}
		}
		
		NSString* title = [message objectForKey:GRIP_TITLE];
		UIView* titleLabel = [newView viewWithTag:GPTheme_Title];
		if ([titleLabel respondsToSelector:@selector(setText:)])
			[(UILabel*)titleLabel setText:title];
		
		NSString* description = [message objectForKey:GRIP_DETAIL];
		if (description == nil)
			disclosureButton.hidden = YES;
		else {
			UIView* detailTextView = [newView viewWithTag:GPTheme_Detail];
#if GRIP_JAILBROKEN
			if ([detailTextView respondsToSelector:@selector(setContentToHTMLString:)])
				[(UITextView*)detailTextView setContentToHTMLString:description];
			else
#endif
				if ([detailTextView respondsToSelector:@selector(setText:)])
					[(UITextView*)detailTextView setText:description];
				else if ([detailTextView respondsToSelector:@selector(loadHTMLString:baseURL:)])
					[(UIWebView*)detailTextView loadHTMLString:description baseURL:nil];
		}
	}
	
	// user modifications
	newView = [selfClass modifyView:newView asNew:isNewView forMessage:message];
	if (identifier != nil)
		[identifiedViews setObject:newView forKey:identifier];
		
	if (window == nil) {
		[GPMessageWindow registerWindowWithView:newView message:message];
	} else {
		[window refreshWithMessage:message];
		[window resize];
	}
}

-(void)disposeIdentifier:(NSString*)identifier {
	[identifiedViews removeObjectForKey:identifier];
}

-(void)dealloc {
	[identifiedViews release];
	[selfBundle release];
	[super dealloc];
}


+(void)close:(UIButton*)button { [(GPMessageWindow*)button.window hide:YES]; }
+(void)disclose:(UIButton*)button {
	GPMessageWindow* window = (GPMessageWindow*)button.window;
	[window stopHiding];
	[window stopTimer];
	[window forceSticky];
	[window prepareForResizing];
	[self updateViewForDisclosure:window.view];
	[window resize];
}
+(void)activate:(UIButton*)clickContext {
	GPMessageWindow* window = (GPMessageWindow*)clickContext.window;
	[window stopTimer];
	[self activateView:window.view]; 
}
+(void)deactivate:(UIButton*)clickContext {
	GPMessageWindow* window = (GPMessageWindow*)clickContext.window;
	[window restartTimer];
	[self deactivateView:window.view]; 	
}
+(void)fire:(UIButton*)clickContext { [(GPMessageWindow*)clickContext.window hide:NO]; }
@end
