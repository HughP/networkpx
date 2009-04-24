/*

GPDefaultTheme.m ... Default Theme of GriP.
 
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

#import <GriP/GrowlDefines.h>
#import <GriP/GPMessageWindow.h>
#import <GriP/GPPreferences.h>
#import <GriP/common.h>
#import <UIKit/UIKit.h>
#import <GraphicsUtilities.h>
#import <GriP/GPGetSmallAppIcon.h>

// from UIKit.framework. 3.0-compatible
@interface UITextView ()
-(void)setContentToHTMLString:(NSString*)html;
@end

//------------------------------------------------------------------------------
#pragma mark -

@class GPDefaultThemeView;

__attribute__((visibility("hidden")))
@interface UITextViewForGPDefaultTheme : UITextView {}
-(void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event;
-(void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event;
@end
@implementation UITextViewForGPDefaultTheme
-(void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
	[(GPMessageWindow*)self.superview.superview stopTimer];
	[super touchesBegan:touches withEvent:event];
}
-(void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event {
	[(GPDefaultThemeView*)self.superview.superview restartTimer];
	[super touchesEnded:touches withEvent:event];
}
@end



//------------------------------------------------------------------------------
#pragma mark -

@interface GPDefaultThemeView : UIView {
	UIImageView* activeView;
	UITextViewForGPDefaultTheme* detailTextView;
	UIImageView* backgroundView;
	UIButton* clickingContext;
}
-(id)initWithTitle:(NSString*)title detail:(NSString*)detail icon:(NSObject*)iconData backgroundColor:(UIColor*)bgColor frameColor:(UIColor*)frameColor;

-(void)showActiveView;
-(void)hideActiveView;
-(void)close;
-(void)expand:(UIButton*)sender;
@end

// Rule: Max size should be 240x120.
#define CLOSE_BUTTON_SIZE 20
#define DISCLOSURE_BUTTON_SIZE 20
#define ICON_PADDING 5

#define VIEW_WIDTH 160
#define LEFT_PADDING 3	// == TOP_PADDING
#define RIGHT_PADDING 3
#define BOTTOM_PADDING 6

@implementation GPDefaultThemeView
-(void)showActiveView { activeView.hidden = NO; [(GPMessageWindow*)self.superview stopTimer]; }
-(void)hideActiveView { activeView.hidden = YES; [(GPMessageWindow*)self.superview restartTimer]; }
-(void)close { [(GPMessageWindow*)self.superview hide:YES]; }
-(void)expand:(UIButton*)sender {
	[UIView beginAnimations:@"GPDDV-Expand" context:NULL];
	CGRect oldBounds;
#define IncreaseHeight(viewRect) oldBounds=viewRect;oldBounds.size.height+=60;viewRect=oldBounds
	IncreaseHeight(self.bounds);
	IncreaseHeight(detailTextView.frame);
	IncreaseHeight(backgroundView.frame);
#undef IncreaseHeight
	[UIView commitAnimations];
	oldBounds = clickingContext.frame;
	oldBounds.size.width += DISCLOSURE_BUTTON_SIZE;
	clickingContext.frame = oldBounds;
	[self.superview layoutSubviews];
	[(GPMessageWindow*)self.superview stopTimer];
	[sender removeFromSuperview];
}
-(void)fire { [(GPMessageWindow*)self.superview hide:NO]; }

-(id)initWithTitle:(NSString*)title detail:(NSString*)detail icon:(NSObject*)iconData backgroundColor:(UIColor*)bgColor frameColor:(UIColor*)frameColor {
	CGFloat occupiedWidth = CLOSE_BUTTON_SIZE;		// for the close button (×).
	CGFloat titleLeftPadding = CLOSE_BUTTON_SIZE+LEFT_PADDING;
	if (detail != nil)
		occupiedWidth += DISCLOSURE_BUTTON_SIZE;	// for the detail disclosure button (▼).
	if (iconData != nil) {
		occupiedWidth += 29+ICON_PADDING;	// assume the icon is 29x29.
		titleLeftPadding += 29+ICON_PADDING;
	}
	
	UIFont* titleFont = [UIFont boldSystemFontOfSize:[UIFont systemFontSize]];
	CGSize titleSize = (title != nil) ? [title sizeWithFont:titleFont constrainedToSize:CGSizeMake(VIEW_WIDTH-(LEFT_PADDING+RIGHT_PADDING)-occupiedWidth, INFINITY)] : CGSizeZero;
	// No more than 60px please.
	if (titleSize.height > 60)
		titleSize.height = 60;
	// But at least big enough to enclose the icon.
	if (iconData != nil && titleSize.height < 29)
		titleSize.height = 29;
	else if (titleSize.height < 25)
		titleSize.height = 25;
	
	if ((self = [super initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, LEFT_PADDING+BOTTOM_PADDING+titleSize.height)])) {		
		self.backgroundColor = [UIColor clearColor];
		
		// the icon is referring to an app icon. Dereference it.
		UIImage* iconImage = nil;
		if ([iconData isKindOfClass:[NSString class]]) {
			iconImage = GPGetSmallAppIcon((NSString*)iconData);
		
		// create the UIImage from data.
		} else if ([iconData isKindOfClass:[NSData class]]) {
			CGDataProviderRef dataProvider = CGDataProviderCreateWithCFData((CFDataRef)iconData);
			CGImageRef image = CGImageCreateWithPNGDataProvider(dataProvider, NULL, NO, kCGRenderingIntentDefault);
			iconImage = [UIImage imageWithCGImage:image];
			CGImageRelease(image);
			CGDataProviderRelease(dataProvider);
		}

		// draw background
		UIGraphicsBeginImageContext(CGSizeMake(15,15));
		CGContextRef c = UIGraphicsGetCurrentContext();
		
		[frameColor setStroke];
		[bgColor setFill];
		CGContextSetShadow(c, CGSizeMake(1,-1), 2);
		CGContextSetLineWidth(c, 1);
		CGContextStrokeEllipseInRect(c, CGRectMake(1, 1, 11, 11));
		CGContextFillEllipseInRect(c, CGRectMake(1, 1, 11, 11));
		
		UIImage* backgroundImage = [[UIGraphicsGetImageFromCurrentImageContext() stretchableImageWithLeftCapWidth:6 topCapHeight:6] retain];
		
		CGContextClearRect(c, CGRectMake(0, 0, 15, 15));
		
		// draw the hover frame.
		CGContextSetLineWidth(c, 2);
		CGContextStrokeEllipseInRect(c, CGRectMake(1, 1, 11, 11));
		
		UIImage* activeImage = [[UIGraphicsGetImageFromCurrentImageContext() stretchableImageWithLeftCapWidth:6 topCapHeight:6] retain];
		UIGraphicsEndImageContext();
		
		// add background view.
		backgroundView = [[UIImageView alloc] initWithImage:backgroundImage];
		backgroundView.frame = CGRectMake(0, 0, VIEW_WIDTH, LEFT_PADDING+BOTTOM_PADDING + titleSize.height);
		[self addSubview:backgroundView];
		[backgroundView release];

		// add (hidden) active image.
		activeView = [[UIImageView alloc] initWithImage:activeImage];
		activeView.frame = CGRectMake(0, 0, VIEW_WIDTH, LEFT_PADDING+BOTTOM_PADDING + titleSize.height);
		activeView.hidden = YES;
		[self addSubview:activeView];
		[activeView release];
		
		// add clicking context.
		clickingContext = [UIButton buttonWithType:UIButtonTypeCustom];
		clickingContext.frame = CGRectMake(LEFT_PADDING+CLOSE_BUTTON_SIZE, LEFT_PADDING, VIEW_WIDTH-LEFT_PADDING-RIGHT_PADDING-occupiedWidth+(iconImage==nil?0:29+ICON_PADDING), titleSize.height);
		[clickingContext addTarget:self action:@selector(showActiveView) forControlEvents:UIControlEventTouchDown|UIControlEventTouchDragEnter];
		[clickingContext addTarget:self action:@selector(hideActiveView) forControlEvents:UIControlEventTouchDragOutside|UIControlEventTouchDragExit|UIControlEventTouchUpOutside|UIControlEventTouchCancel];
		[clickingContext addTarget:self action:@selector(fire) forControlEvents:UIControlEventTouchUpInside];
		[self addSubview:clickingContext];
		
		// add icon.
		if (iconImage != nil) {
			UIImageView* iconView = [[UIImageView alloc] initWithImage:iconImage];
			iconView.frame = CGRectMake(LEFT_PADDING+CLOSE_BUTTON_SIZE, LEFT_PADDING, 29, 29);
			[self addSubview:iconView];
			[iconView release];
		}

		// add title.
		UILabel* titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(titleLeftPadding, LEFT_PADDING, titleSize.width, titleSize.height)];
		titleLabel.font = titleFont;
		titleLabel.numberOfLines = 0;
		titleLabel.textColor = frameColor;
		titleLabel.backgroundColor = [UIColor clearColor];
		titleLabel.text = title;
		[self addSubview:titleLabel];
		[titleLabel release];
				
		// add close button.
		UIButton* closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
		closeButton.frame = CGRectMake(LEFT_PADDING, LEFT_PADDING, CLOSE_BUTTON_SIZE, titleSize.height);
		closeButton.showsTouchWhenHighlighted = YES;
		[closeButton setTitle:@"×" forState:UIControlStateNormal];
		[closeButton setTitleColor:frameColor forState:UIControlStateNormal];
		[closeButton addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside];
		[self addSubview:closeButton];
		
		if (detail != nil) {
			// add disclosure button.
			UIButton* disclosureButton = [UIButton buttonWithType:UIButtonTypeCustom];
			disclosureButton.frame = CGRectMake(VIEW_WIDTH-DISCLOSURE_BUTTON_SIZE-RIGHT_PADDING, LEFT_PADDING, DISCLOSURE_BUTTON_SIZE, titleSize.height);
			disclosureButton.showsTouchWhenHighlighted = YES;
			[disclosureButton setTitle:@"▼" forState:UIControlStateNormal];
			[disclosureButton setTitleColor:frameColor forState:UIControlStateNormal];
			[disclosureButton addTarget:self action:@selector(expand:) forControlEvents:UIControlEventTouchUpInside];
			[self addSubview:disclosureButton];
			
			// add (hidden) detail text view.
			detailTextView = [[UITextViewForGPDefaultTheme alloc] initWithFrame:CGRectMake(LEFT_PADDING, LEFT_PADDING+titleSize.height, VIEW_WIDTH-LEFT_PADDING-RIGHT_PADDING, 1)];
			detailTextView.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
			detailTextView.textColor = frameColor;
			detailTextView.editable = NO;
			detailTextView.backgroundColor = [UIColor clearColor];
			[detailTextView setContentToHTMLString:[detail stringByReplacingOccurrencesOfString:@"\n" withString:@"<br />"]];
			[self addSubview:detailTextView];
			[detailTextView release];
		}
	}
	return self;
}
@end

//------------------------------------------------------------------------------
#pragma mark -

@interface GPDefaultTheme : NSObject {}
-(void)display:(NSDictionary*)message;
@end

@implementation GPDefaultTheme
-(void)display:(NSDictionary*)message {
	// Obtain color for priority.
	
	int priority = [[message objectForKey:GRIP_PRIORITY] integerValue]+2;
	NSArray* colorArray = [[GPPreferences() objectForKey:@"BackgroundColors"] objectAtIndex:priority];
	CGFloat red = [[colorArray objectAtIndex:0] floatValue];
	CGFloat green = [[colorArray objectAtIndex:1] floatValue];
	CGFloat blue = [[colorArray objectAtIndex:2] floatValue];
	CGFloat luminance = GULuminance(red, green, blue);
	
	UIColor* displayColor = [UIColor colorWithRed:red green:green blue:blue alpha:0.8f];
	UIColor* frameColor = (luminance > 0.5) ? [UIColor blackColor] : [UIColor whiteColor];
	
	GPDefaultThemeView* view = [[GPDefaultThemeView alloc] initWithTitle:[message objectForKey:GRIP_TITLE]
																  detail:[message objectForKey:GRIP_DETAIL]
																	icon:[message objectForKey:GRIP_ICON]
														 backgroundColor:displayColor
															  frameColor:frameColor];
	 
	[GPMessageWindow windowWithView:view message:message];
	[view release];
}

@end