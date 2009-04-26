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
#import <GraphicsUtilities.h>

#define PADDING 3
#define PADDING_BOTTOM 5
#define ICON_SIZE 29

@implementation GPDefaultTheme
+(UIView*)modifyView:(UIView*)view asNew:(BOOL)asNew forMessage:(NSDictionary*)message {
	view = [GPNibTheme modifyView:view asNew:asNew forMessage:message];
	
	UILabel* titleLabel = (UILabel*)[view viewWithTag:GPTheme_Title];
	
	// resize the frame's height to fit all title text.
	CGFloat actualHeight = [[message objectForKey:GRIP_TITLE] sizeWithFont:titleLabel.font constrainedToSize:CGSizeMake(titleLabel.bounds.size.width, 60)].height;
	if (actualHeight < ICON_SIZE + PADDING + PADDING_BOTTOM)
		actualHeight = ICON_SIZE;
	
	UITextView* detailView = (UITextView*)[view viewWithTag:GPTheme_Detail];
	detailView.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
	CGRect detailFrame = detailView.frame;
	
	CGRect oldFrame = view.frame;
	oldFrame.size.height = actualHeight + PADDING + PADDING_BOTTOM + detailFrame.size.height - 1;
	view.frame = oldFrame;
	
	UIView* titleAndViews = [view viewWithTag:GPTheme_TitleAndViews];
	oldFrame = titleAndViews.frame;
	oldFrame.size.height = actualHeight; 
	titleAndViews.frame = oldFrame;
	
	detailFrame.origin.y = actualHeight + PADDING - 1;
	detailView.frame = detailFrame;
		
	UIImageView* bgView = (UIImageView*)[view viewWithTag:GPTheme_Background];
	
	UIColor* bgColor = [bgView.backgroundColor colorWithAlphaComponent:0.8f];
	UIColor* frameColor = titleLabel.textColor;
	bgView.backgroundColor = [UIColor clearColor];
		
	UIGraphicsBeginImageContext(CGSizeMake(16, 16));
	CGContextRef c = UIGraphicsGetCurrentContext();
	
	// draw background.
	[frameColor setStroke];
	[bgColor setFill];
	CGContextSetShadow(c, CGSizeMake(2,-2), 2);
	CGContextSetLineWidth(c, 0.5);
	
	CGPathRef roundRectPath = GUPathCreateRoundRect(CGRectMake(1, 1, 11, 11), 4);
	CGContextAddPath(c, roundRectPath);
	CGContextDrawPath(c, kCGPathFillStroke);
	
	bgView.image = [UIGraphicsGetImageFromCurrentImageContext() stretchableImageWithLeftCapWidth:6 topCapHeight:6];
	bgView.frame = bgView.superview.bounds;	// meh. "Disabling autoresizing subviews not available prior to iPhoneOS 3.0". This causes a disturbing "enlarging" effect in <3.x.
	
	CGContextClearRect(c, CGRectMake(0, 0, 15, 15));
	
	// draw the hover frame.
	CGContextSetLineWidth(c, 2);
	
	CGContextAddPath(c, roundRectPath);
	CGContextStrokePath(c);
	
	UIImageView* activeView = (UIImageView*)[view viewWithTag:GPTheme_ActivationBackground];
	activeView.image = [UIGraphicsGetImageFromCurrentImageContext() stretchableImageWithLeftCapWidth:6 topCapHeight:6];
	activeView.frame = CGRectInset(activeView.superview.bounds, -PADDING, -PADDING);
	
	CGPathRelease(roundRectPath);
	
	UIGraphicsEndImageContext();
		
	return view;
}
@end