/*

QuickScroll.m ... Quickly scroll through a WebView.
 
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

#import <UIKit/UIKit2.h>
#import "substrate.h"

__attribute__((pure))
static inline CGAffineTransform CGAffineTransformMakeTransformBetweenCGRects(CGRect from, CGRect to) {
	CGAffineTransform tx = CGAffineTransformMakeTranslation(-from.origin.x, -from.origin.y);
	tx = CGAffineTransformConcat(tx, CGAffineTransformMakeScale(to.size.width/from.size.width, to.size.height/from.size.height));
	tx = CGAffineTransformConcat(tx, CGAffineTransformMakeTranslation(to.origin.x, to.origin.y));
	return tx;
}

@interface DragView : UIView {
	UIWebDocumentView* webDocView;
	CGRect wdvFrame, drawFrame, dragRegion;
	CGAffineTransform tx, inverse_tx;
	BOOL touchMoved;
	CGSize dragShift;
	CGColorRef whiteColor, greenColor, translucentGreenColor;
}
@property(assign) UIWebDocumentView* webDocView;
@end
@implementation DragView
@synthesize webDocView;
-(void)scrollTo {
	//	CGPoint dragOrigin = CGPointMake(dragRegion.origin.x - shift.width, dragRegion.origin.y - shift.height);
	CGPoint p = CGPointApplyAffineTransform(dragRegion.origin, inverse_tx);
	[webDocView _setScrollerOffset:p];
}
-(void)computeDragRegion {
	dragRegion = CGRectApplyAffineTransform(webDocView.visibleBounds, tx);
	/*
	 CGPoint origOrigin = dragRegion.origin;
	 if (dragRegion.size.height < 24) {
	 dragRegion.origin.y -= 12 - dragRegion.size.height/2;
	 dragRegion.size.height = 24;
	 }
	 if (dragRegion.size.width < 24) {
	 dragRegion.origin.x -= 12 - dragRegion.size.width/2;
	 dragRegion.size.width = 24;
	 }
	 shift = CGSizeMake(dragRegion.origin.x - origOrigin.x, dragRegion.origin.y - origOrigin.y);
	 */
	whiteColor = CGColorRetain([UIColor whiteColor].CGColor);
	greenColor = CGColorRetain([UIColor greenColor].CGColor);
	translucentGreenColor = CGColorCreateCopyWithAlpha(greenColor, 0.5);
}
-(void)dealloc {
	CGColorRelease(whiteColor);
	CGColorRelease(greenColor);
	CGColorRelease(translucentGreenColor);
	[super dealloc];
}
-(void)correctDragRegion {
	if (dragRegion.origin.x < drawFrame.origin.x)
		dragRegion.origin.x = drawFrame.origin.x;
	else if (dragRegion.origin.x + dragRegion.size.width > drawFrame.origin.x + drawFrame.size.width)
		dragRegion.origin.x = drawFrame.origin.x + drawFrame.size.width - dragRegion.size.width;
	
	if (dragRegion.origin.y < drawFrame.origin.y)
		dragRegion.origin.y = drawFrame.origin.y;
	else if (dragRegion.origin.y + dragRegion.size.height > drawFrame.origin.y + drawFrame.size.height)
		dragRegion.origin.y = drawFrame.origin.y + drawFrame.size.height - dragRegion.size.height;
}
-(void)bringDragRegionToContaingPoint:(CGPoint)pt {
	dragRegion.origin = CGPointMake(pt.x - dragRegion.size.width/2, pt.y - dragRegion.size.height/2);
	[self correctDragRegion];
}

-(void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
	CGPoint lastPoint = [[touches anyObject] locationInView:self];
	if (!CGRectContainsPoint(dragRegion, lastPoint)) {
		[self bringDragRegionToContaingPoint:lastPoint];
		dragShift = CGSizeMake(dragRegion.size.width/2, dragRegion.size.height/2);
	} else
		dragShift = CGSizeMake(lastPoint.x - dragRegion.origin.x, lastPoint.y - dragRegion.origin.y);
}
-(void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event {
	CGPoint lastPoint = [[touches anyObject] locationInView:self];
	dragRegion.origin = CGPointMake(lastPoint.x - dragShift.width, lastPoint.y - dragShift.height);
	[self correctDragRegion];
	[self setNeedsDisplay];
	[self scrollTo];
}
-(void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event {
	[self setNeedsDisplay];
	[self scrollTo];
}

-(void)computeFrames {
	wdvFrame = webDocView.frame;
	CGRect myFrame = self.frame;
	CGFloat wdvAspectRatio = wdvFrame.size.height / wdvFrame.size.width;
	CGFloat myAspectRatio = myFrame.size.height / myFrame.size.width;
	CGSize targetSize;
	
	if (wdvAspectRatio >= myAspectRatio) {
		// Page is like a long rectangle.
		if (wdvAspectRatio > 2.5f)
			wdvAspectRatio = 2.5f;
		targetSize.height = myFrame.size.height;
		targetSize.width = targetSize.height / wdvAspectRatio;
	} else {
		if (wdvAspectRatio < 0.5f)
			wdvAspectRatio = 0.5f;
		targetSize.width = myFrame.size.width;
		targetSize.height = targetSize.width * wdvAspectRatio;
	}
	
	drawFrame.size = targetSize;
	drawFrame.origin = CGPointMake( (myFrame.size.width - targetSize.width)/2, (myFrame.size.height - targetSize.height)/2 );
	
	tx = CGAffineTransformMakeTransformBetweenCGRects(wdvFrame, drawFrame);
	inverse_tx = CGAffineTransformInvert(tx);
	
	[self computeDragRegion];
}
-(void)drawRect:(CGRect)rect {
	CGContextRef c = UIGraphicsGetCurrentContext();
	CGContextSetStrokeColorWithColor(c, whiteColor);
	CGContextStrokeRect(c, CGRectInset(drawFrame, 0.5f, 0.5f));
	CGContextSetStrokeColorWithColor(c, greenColor);
	CGContextSetFillColorWithColor(c, translucentGreenColor);
	CGContextFillRect(c, dragRegion);
	CGContextStrokeRectWithWidth(c, dragRegion, 2);
}
@end


@interface WebDocViewScroller : UIAlertView {
	
}
@end
@implementation WebDocViewScroller
-(CGRect)frame { return CGRectMake(0, 0, 284, 284); }
-(id)initWithDocumentView:(UIWebDocumentView*)v {
	if ((self = [super initWithTitle:nil message:nil delegate:self cancelButtonTitle:@"Done" otherButtonTitles:nil])) {
		[self show];
		
		UIThreePartButton* btn = [self buttonAtIndex:0];
		CGRect frm = btn.frame;
		CGRect availableRegion = frm;
		frm.origin.y = 284 - frm.origin.y - frm.size.height;
		availableRegion.size.height = frm.origin.y - availableRegion.origin.y - 8;
		btn.frame = frm;
		
		DragView* dv = [[DragView alloc] initWithFrame:availableRegion];
		dv.backgroundColor = [UIColor clearColor];
		dv.webDocView = v;
		[dv computeFrames];
		[self addSubview:dv];
		[dv release];
	}
	return self;
}
@end


static void (*original_touchesEnded_withEvent_)(UIWebDocumentView* self, SEL _cmd, NSSet* touches, UIEvent* event) = NULL;
static void replaced_touchesEnded_withEvent_(UIWebDocumentView* self, SEL _cmd, NSSet* touches, UIEvent* event) {
	if ([[touches anyObject] tapCount] == 3) {
		WebDocViewScroller* alert = [[WebDocViewScroller alloc] initWithDocumentView:self];
		[alert release];
	}
	original_touchesEnded_withEvent_(self, _cmd, touches, event);
}


void initialize() {
	original_touchesEnded_withEvent_ = (void*)MSHookMessage([UIWebDocumentView class], @selector(touchesEnded:withEvent:), (IMP)replaced_touchesEnded_withEvent_, NULL);
}
