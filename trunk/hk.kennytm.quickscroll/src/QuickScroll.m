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

@interface WebPDFView : NSObject
-(unsigned)totalPages;
-(unsigned)pageNumberForRect:(CGRect)rect;
@end

__attribute__((pure))
static inline CGAffineTransform CGAffineTransformMakeTransformBetweenCGRects(CGRect from, CGRect to) {
	CGFloat sx = to.size.width/from.size.width, sy = to.size.height/from.size.height;
	return CGAffineTransformMake(sx, 0, 0, sy, to.origin.x - sx * from.origin.x, to.origin.y - sx * from.origin.y);
}

static CGColorRef greenColor, translucentGreenColor;
static UIImage* alertBackground;
static NSString* doneText, *scrollerText, *goText, *pageNumberText;

__attribute__((visibility("hidden")))
@interface DragView : UIView {
	UIWebDocumentView* webDocView;
	CGRect wdvFrame, drawFrame, dragRegion;
	CGAffineTransform inverse_tx;
	BOOL touchMoved;
	CGSize dragShift;
}
@property(assign) UIWebDocumentView* webDocView;
@end
@implementation DragView
@synthesize webDocView;
-(void)scrollTo {
	CGPoint p = CGPointApplyAffineTransform(dragRegion.origin, inverse_tx);
	[webDocView _setScrollerOffset:p];
	[webDocView updatePDFPageNumberLabel];
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
-(void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
	CGPoint lastPoint = [[touches anyObject] locationInView:self];
	if (!CGRectContainsPoint(dragRegion, lastPoint)) {
		dragRegion.origin = CGPointMake(lastPoint.x - dragRegion.size.width/2, lastPoint.y - dragRegion.size.height/2);
		[self correctDragRegion];
		dragShift = CGSizeMake(dragRegion.size.width/2, dragRegion.size.height/2);
	} else
		dragShift = CGSizeMake(lastPoint.x - dragRegion.origin.x, lastPoint.y - dragRegion.origin.y);
}
-(void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event {
	[self setNeedsDisplay];
	[self scrollTo];
}
-(void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event {
	CGPoint lastPoint = [[touches anyObject] locationInView:self];
	dragRegion.origin = CGPointMake(lastPoint.x - dragShift.width, lastPoint.y - dragShift.height);
	[self correctDragRegion];
	[self setNeedsDisplay];
	[self scrollTo];
}
-(void)setFrame:(CGRect)newFrame {
	wdvFrame = webDocView.frame;
	CGFloat wdvAspectRatio = wdvFrame.size.height / wdvFrame.size.width;
	
	// Page is like a long rectangle.
	if (wdvAspectRatio > 2.5f)
		wdvAspectRatio = 2.5f;
	else if (wdvAspectRatio < 0.5f)
		wdvAspectRatio = 0.5f;
	
	// Solve these equations:
	// [1] height * width = AREA
	// [2] height / width = wdvAspectRatio
	CGPoint oldOrigin = newFrame.origin;
	static const CGFloat AREA = 16000;
	CGFloat height = sqrtf(AREA * wdvAspectRatio);
	drawFrame = CGRectIntegral(CGRectMake(oldOrigin.x, oldOrigin.y, AREA / height, height));
	
	[super setFrame:CGRectInset(drawFrame, -1, -1)];
	drawFrame.origin = CGPointMake(1, 1);
	
	CGAffineTransform tx = CGAffineTransformMakeTransformBetweenCGRects(wdvFrame, drawFrame);
	inverse_tx = CGAffineTransformInvert(tx);
	
	dragRegion = CGRectApplyAffineTransform(webDocView.visibleBounds, tx);
}
-(void)drawRect:(CGRect)rect {
	CGContextRef c = UIGraphicsGetCurrentContext();
	CGContextSetStrokeColorWithColor(c, greenColor);
	CGContextSetFillColorWithColor(c, translucentGreenColor);
	CGRect dragRegionBlownUp = dragRegion;
	if (dragRegionBlownUp.size.width < 8) {
		dragRegionBlownUp.origin.x -= 4-dragRegionBlownUp.size.width/2;
		dragRegionBlownUp.size.width = 8;
	}
	if (dragRegionBlownUp.size.height < 8) {
		dragRegionBlownUp.origin.y -= 4-dragRegionBlownUp.size.height/2;
		dragRegionBlownUp.size.height = 8;
	}
	dragRegionBlownUp = CGRectIntegral(dragRegionBlownUp);
	CGContextFillRect(c, dragRegionBlownUp);
	CGContextStrokeRectWithWidth(c, dragRegionBlownUp, 2);
}
@end


__attribute__((visibility("hidden")))
@interface WebDocViewScroller : UIAlertView {
	DragView* dv;
	CGRect selfFrame, buttonFrame;
	BOOL layoutDetermined;
}
@end
@implementation WebDocViewScroller
-(void)drawRect:(CGRect)rect {
	[alertBackground drawInRect:rect];
}
-(void)layout {
	[super layout];
	
	UIThreePartButton* btn = [self buttonAtIndex:0];
	
	if (!layoutDetermined) {
		CGRect btnFrame = btn.frame;
		dv.frame = CGRectMake(btnFrame.origin.x, btnFrame.origin.x, 0, 0);
		CGRect dvFrame = dv.frame;
		buttonFrame = CGRectMake(dvFrame.origin.x, dvFrame.size.height + dvFrame.origin.y + 8, dvFrame.size.width, btnFrame.size.height);
		selfFrame = CGRectMake(0, 0, dvFrame.size.width + 2*dvFrame.origin.x, buttonFrame.origin.y + dvFrame.origin.y + btnFrame.size.height);
		layoutDetermined = YES;
	}
	
	self.frame = selfFrame;
	btn.frame = buttonFrame;
}
-(id)initWithDocumentView:(UIWebDocumentView*)v {
	if ((self = [super initWithTitle:nil message:nil delegate:self cancelButtonTitle:doneText otherButtonTitles:nil])) {
		dv = [DragView new];
		dv.backgroundColor = [UIColor clearColor];
		dv.webDocView = v;
		[self addSubview:dv];
		[dv release];
		
		[self show];
	}
	return self;
}
@end


static ptrdiff_t pdfOffset = 0;
static WebPDFView* WebPDF(UIWebDocumentView* view) {
	if (pdfOffset == 0) {
		Ivar ivar = class_getInstanceVariable([UIWebDocumentView class], "_pdf");
		pdfOffset = ivar_getOffset(ivar);
	}
	return *(WebPDFView**)((char*)view + pdfOffset);
}

static ptrdiff_t pageRectsOffset = 0;
static CGRect* pageRects(WebPDFView* view) {
	if (pageRectsOffset == 0) {
		Ivar ivar = class_getInstanceVariable([view class], "_pageRects");
		pageRectsOffset = ivar_getOffset(ivar);
	}
	return *(CGRect**)((char*)view + pageRectsOffset);
}


__attribute__((visibility("hidden")))
@interface PDFJumpToScroller : UIAlertView {
	unsigned totalPageCount, oldPage;
	UIWebDocumentView* webView;
}
@end
@implementation PDFJumpToScroller
-(void)_buttonClicked:(UIView*)button {
	int buttonID = button.tag;
	[super _buttonClicked:button];
	if (buttonID == 1) {
		WebDocViewScroller* alert = [[WebDocViewScroller alloc] initWithDocumentView:webView];
		[alert layout];
		[alert release];
	} else {
		CGRect* rects = pageRects(WebPDF(webView));
		NSString* text = [self textField].text;
		if ([text length] != 0) {
			NSInteger val = [[self textField].text integerValue]-1;
			if (val < 0)
				val = 0;
			else if (val > totalPageCount)
				val = totalPageCount-1;
			if (val != oldPage)
				[webView _setScrollerOffset:rects[val].origin];
		}
		[webView updatePDFPageNumberLabel];
	}
}
-(id)initWithDocumentView:(UIWebDocumentView*)v {
	if ((self = [super initWithTitle:nil message:nil delegate:self cancelButtonTitle:scrollerText otherButtonTitles:goText, nil])) {
		// Get current page.
		webView = v;
		WebPDFView* pdfView = WebPDF(v);
		totalPageCount = [pdfView totalPages];
		oldPage = [pdfView pageNumberForRect:v.visibleRect];
		self.message = [NSString stringWithFormat:@"%@ (1 - %u):", pageNumberText, totalPageCount];
		UITextField* textField = [self addTextFieldWithValue:[NSString stringWithFormat:@"%u", oldPage] label:nil];
		-- oldPage;
		textField.keyboardType = UIKeyboardTypeNumberPad;
		textField.textAlignment = UITextAlignmentCenter;
		[self show];
	}
	return self;
}
@end


static void (*original_touchesEnded_withEvent_)(UIWebDocumentView* self, SEL _cmd, NSSet* touches, UIEvent* event);
static void replaced_touchesEnded_withEvent_(UIWebDocumentView* self, SEL _cmd, NSSet* touches, UIEvent* event) {
	if ([[touches anyObject] tapCount] == 3) {
		UIAlertView* alert;
		if (WebPDF(self))
			alert = [[PDFJumpToScroller alloc] initWithDocumentView:self];
		else
			alert = [[WebDocViewScroller alloc] initWithDocumentView:self];
		[alert release];
	}
	original_touchesEnded_withEvent_(self, _cmd, touches, event);
}


static void releaseColors() {
	CGColorRelease(greenColor);
	CGColorRelease(translucentGreenColor);
	[alertBackground release];
	[doneText release];
	[goText release];
	[pageNumberText release];
	[scrollerText release];
}


void initialize() {
	NSAutoreleasePool* pool = [NSAutoreleasePool new];
	
	static const CGFloat greenComponents[4] = {0, 1, 0, 1};
	static const CGFloat translucentGreenComponents[4] = {0, 1, 0, 0.25f};
	CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
	
	greenColor = CGColorCreate(rgbColorSpace, greenComponents);
	translucentGreenColor = CGColorCreate(rgbColorSpace, translucentGreenComponents);
	
	CGColorSpaceRelease(rgbColorSpace);
	
	
#if TARGET_IPHONE_SIMULATOR
	NSDictionary* dict = [NSDictionary dictionaryWithContentsOfFile:@"/Users/kennytm/XCodeProjects/iKeyEx/svn/trunk/hk.kennytm.quickscroll/deb/Library/MobileSubstrate/DynamicLibraries/QuickScroll.plist"];
#else
	NSDictionary* dict = [NSDictionary dictionaryWithContentsOfFile:@"/Library/MobileSubstrate/DynamicLibraries/QuickScroll.plist"];
#endif
	NSDictionary* localizationDictionary = [dict objectForKey:@"Localization"];
		
	NSArray* preferedLocalization = [NSBundle preferredLocalizationsFromArray:[localizationDictionary allKeys]]; 
	NSDictionary* localizationMap = nil;
	for (NSString* loc in preferedLocalization) {
		NSDictionary* curMap = [localizationDictionary objectForKey:loc];
		if (curMap != nil) {
			localizationMap = curMap;
			break;
		}
	}
	if (localizationMap == nil)
		localizationMap = [localizationDictionary objectForKey:@"en"];
	
	doneText = [[localizationMap objectForKey:@"Done"] retain];
	scrollerText = [[localizationMap objectForKey:@"Scroller"] retain];
	pageNumberText = [[localizationMap objectForKey:@"Page number"] retain];
	goText = [[localizationMap objectForKey:@"Go"] retain];
	
	UIImage* img = [UIImage imageWithData:[dict objectForKey:@"AlertBackground"]];
	CGSize imgSize = img.size;
	alertBackground = [[img stretchableImageWithLeftCapWidth:imgSize.width/2 topCapHeight:imgSize.height/2] retain];
	
	atexit(&releaseColors);
	
	original_touchesEnded_withEvent_ = (void*)MSHookMessage([UIWebDocumentView class], @selector(touchesEnded:withEvent:), (IMP)replaced_touchesEnded_withEvent_, NULL);
	
	[pool drain];
}
