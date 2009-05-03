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

#import <GriP/GPDefaultTheme.h>
#import <UIKit/UIKit.h>
#import <GriP/common.h>
#import <GriP/GPGetSmallAppIcon.h>
#import <GraphicsUtilities.h>

#if GRIP_JAILBROKEN
@interface UITextView ()
-(void)setContentToHTMLString:(NSString*)html;
@end
#endif

__attribute__((visibility("hidden")))
@interface GPDTStaticView : UIView {
	NSString* title;
	id icon;
	UIColor* fgColor;
@package
	CGRect iconRect, titleRect;
}
@property(retain) NSString* title;
@property(retain) id icon;
@property(retain) UIColor* fgColor;
-(void)drawRect:(CGRect)rect;
-(void)dealloc;
@end
@implementation GPDTStaticView
@synthesize title, icon, fgColor;
-(void)drawRect:(CGRect)rect {	
	if (icon != nil) {
		if ([icon isKindOfClass:[UIImage class]])
			[icon drawInRect:iconRect];
		else {
			// must be a NSString* here.
			[icon drawInRect:iconRect withFont:[UIFont systemFontOfSize:27.5f] lineBreakMode:UILineBreakModeWordWrap alignment:UITextAlignmentCenter];
		}
	}
	if (title != nil) {
		[fgColor setFill];
		[title drawInRect:titleRect withFont:[UIFont boldSystemFontOfSize:[UIFont systemFontSize]] lineBreakMode:UILineBreakModeMiddleTruncation];
	}
}
-(void)dealloc {
	[title release];
	[icon release];
	[fgColor release];
	[super dealloc];
}
@end


__attribute__((visibility("hidden")))
@interface GPDTWrapperView : UIView {
	UIButton* clickContext, *closeButton, *disclosureButton;
	UITextView* descriptionView;
	UIImageView* backgroundView;
	GPDTStaticView* staticView;
	BOOL disclosed;
}
-(id)init;
-(void)setTitle:(NSString*)title icon:(UIImage*)icon description:(NSString*)description fgColor:(UIColor*)fgColor activeImage:(UIImage*)activeImage bgImage:(UIImage*)bgImage;
-(void)disclose;
@end
@implementation GPDTWrapperView
-(id)init {
	if ((self = [super init])) {
		self.backgroundColor = [UIColor clearColor];
		
		backgroundView = [[UIImageView alloc] init];
		backgroundView.contentMode = UIViewContentModeScaleToFill;
		backgroundView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
		[self addSubview:backgroundView];
		[backgroundView release];
		
		// activeView is the border that appears when pressing on the title / icon.
		clickContext = [[UIButton alloc] init];
		GPAssignUIControlAsClickContextForTheme(clickContext, GPDefaultTheme);
		[self addSubview:clickContext];
		[clickContext release];
		
		// staticView is the icon + string.
		staticView = [[GPDTStaticView alloc] init];
		staticView.backgroundColor = [UIColor clearColor];
		staticView.userInteractionEnabled = NO;
		[self addSubview:staticView];
		[staticView release];
		
		// close button
		closeButton = [[UIButton alloc] init];
		GPAssignUIControlAsCloseButtonForTheme(closeButton, GPDefaultTheme);
		[closeButton setTitle:@"\u00D7" forState:UIControlStateNormal];
		closeButton.showsTouchWhenHighlighted = YES;
		[self addSubview:closeButton];
		[closeButton release];
		
		// disclosure button
		disclosureButton = [[UIButton alloc] init];
		GPAssignUIControlAsDisclosureButtonForTheme(disclosureButton, GPDefaultTheme);
		[disclosureButton setTitle:@"\u25BC" forState:UIControlStateNormal];
		disclosureButton.showsTouchWhenHighlighted = YES;
		[self addSubview:disclosureButton];
		[disclosureButton release];
		
		// the description UITextView.
		// argh. we really need to find a replacement of this UITextView. it bloats up the memory a lot.
		descriptionView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
		descriptionView.contentMode = UIViewContentModeScaleToFill;
		descriptionView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
		descriptionView.backgroundColor = [UIColor clearColor];
		descriptionView.editable = NO;
		[self addSubview:descriptionView];
		[descriptionView release];
	}
	return self;
}

-(void)setTitle:(NSString*)title_ icon:(id)icon_ description:(NSString*)description fgColor:(UIColor*)fgColor_ activeImage:(UIImage*)activeImage bgImage:(UIImage*)bgImage {
	// horizontally,
	//   0 --  20 == close button
	//  20 --  49 == icon
	//  54 -- 134 == title
	// 134 -- 154 == disclosure button.
	
	staticView.title = title_;
	staticView.icon = icon_;
	staticView.fgColor = fgColor_;
	
	backgroundView.image = bgImage;
	[clickContext setBackgroundImage:activeImage forState:UIControlStateHighlighted];
	
	CGFloat titleWidth = 80;
	CGFloat titleLeft = 54;
	if (icon_ == nil) {
		titleWidth = 114;
		titleLeft = 20;
	}
	if (description == nil)
		titleWidth += 20;
	
	// measure the height required by the title.
	UIFont* titleFont = [UIFont boldSystemFontOfSize:[UIFont systemFontSize]];
	CGFloat actualTitleHeight = (title_ == nil) ? 31 : [title_ sizeWithFont:titleFont constrainedToSize:CGSizeMake(titleWidth, 54) lineBreakMode:UILineBreakModeMiddleTruncation].height;
	CGFloat titleHeight = MAX(actualTitleHeight, 31);
	
	CGFloat iconTop = ceilf((titleHeight - 29)/2)+1;
	CGFloat titleTop = ceilf((titleHeight - actualTitleHeight)/2)+1;
	
	staticView->iconRect = CGRectMake(20, iconTop, 29, 29);
	staticView->titleRect = CGRectMake(titleLeft, titleTop, titleWidth, actualTitleHeight);
	
	CGRect descriptionFrame = descriptionView.frame;
	
	self.autoresizesSubviews = NO;
	self.frame = backgroundView.frame = staticView.frame = CGRectMake(0, 0, 160, titleHeight+5+descriptionFrame.size.height);
	clickContext.frame = CGRectMake(0, 0, 160, titleHeight+5);
	closeButton.frame = CGRectMake(0, 0, 20, titleHeight);
	if (!(disclosureButton.hidden = (disclosed || description == nil)))
		disclosureButton.frame = CGRectMake(134, 0, 26, titleHeight);
	descriptionView.frame = CGRectMake(0, titleHeight, 154, descriptionFrame.size.height);
	self.autoresizesSubviews = YES;
	
	descriptionView.textColor = fgColor_;
#if GRIP_JAILBROKEN
	[descriptionView setContentToHTMLString:[description stringByReplacingOccurrencesOfString:@"\n" withString:@"<br/>"]];
#else
	descriptionView.text = description;
#endif
	
	[staticView setNeedsDisplay];
}

-(void)disclose {
	disclosed = YES;
	disclosureButton.hidden = YES;
	CGRect myFrame = self.frame;
	myFrame.size.height += 60;
	self.frame = myFrame;
}
@end


@implementation GPDefaultTheme
-(id)initWithBundle:(NSBundle*)bundle {
	if ((self = [super initWithBundle:bundle])) {
		UIGraphicsBeginImageContext(CGSizeMake(16, 16));
		CGContextRef c = UIGraphicsGetCurrentContext();
		CGContextSetShadow(c, CGSizeMake(2.5f,-2.5f), 2.5f);
		
		for (int i = 0; i < 5; ++ i) {
			CGContextClearRect(c, CGRectMake(0, 0, 16, 16));
			CGContextSetLineWidth(c, 0.5);
			[fgColors[i] setStroke];
			[bgColors[i] setFill];
			CGContextAddEllipseInRect(c, CGRectMake(1, 1, 10, 10));
			CGContextDrawPath(c, kCGPathFillStroke);
			
			bgImages[i] = [[UIGraphicsGetImageFromCurrentImageContext() stretchableImageWithLeftCapWidth:6 topCapHeight:6] retain];
			
			CGContextClearRect(c, CGRectMake(0, 0, 16, 16));
			CGContextSetLineWidth(c, 2);
			CGContextStrokeEllipseInRect(c, CGRectMake(1, 1, 10, 10));
			
			activeImages[i] = [[UIGraphicsGetImageFromCurrentImageContext() stretchableImageWithLeftCapWidth:6 topCapHeight:6] retain];
		}
		
		UIGraphicsEndImageContext();
	}
	return self;
}
-(void)dealloc {
	for (int i = 0; i < 5; ++ i) {
		[bgImages[i] release];
		[activeImages[i] release];
	}
	[super dealloc];
}


-(void)modifyView:(UIView*)view asNew:(BOOL)asNew withMessage:(NSDictionary*)message {
	[super modifyView:view asNew:asNew withMessage:message];
	
	NSString* title = [message objectForKey:GRIP_TITLE];
	NSString* description = [message objectForKey:GRIP_DETAIL];
	id icon = [message objectForKey:GRIP_ICON];
	if (!GPStringIsEmoji(icon))
		icon = GPGetSmallAppIcon(icon);
	int priorityIndex = [[message objectForKey:GRIP_PRIORITY] integerValue]+2;
	
	if (asNew) {
		[view addSubview:[[[GPDTWrapperView alloc] init] autorelease]];
	}
	
	GPDTWrapperView* v = [view.subviews objectAtIndex:0];
	[v setTitle:title icon:icon description:description fgColor:fgColors[priorityIndex] activeImage:activeImages[priorityIndex] bgImage:bgImages[priorityIndex]];
	view.frame = v.frame;
}

+(void)updateViewForDisclosure:(UIView*)view {
	GPDTWrapperView* v = [view.subviews objectAtIndex:0];
	[v disclose];
	view.frame = v.frame;	
}
@end