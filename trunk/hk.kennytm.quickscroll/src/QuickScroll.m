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

#import <UIKit/UIKit.h>
#import <UIKit/UIScrollView2.h>
#import <UIKit/UIWebDocumentView.h>
#import <UIKit/UIAlertView.h>
#import <UIKit/UIView2.h>
#import <UIKit/UIAlertSheetTextField.h>
#import "substrate.h"

@interface WebPDFView : UIView
-(unsigned)totalPages;
-(unsigned)pageNumberForRect:(CGRect)rect;
@end



static CGColorRef greenColor, translucentGreenColor;
static UIImage* alertBackground;
static NSString* doneText, *scrollerText, *goText, *pageNumberText;

__attribute__((visibility("hidden")))
@interface DragView : UIView {
@package
	UIScrollView* webDocView;
	UIWebDocumentView* associatedWebView;
@private
	CGRect drawFrame, dragRegion;
	CGAffineTransform inverse_tx;
	CGSize dragShift;
}
@end
@implementation DragView
-(void)scrollTo {
	CGPoint p = CGPointApplyAffineTransform(dragRegion.origin, inverse_tx);
	[webDocView setOffset:p];
	[associatedWebView updatePDFPageNumberLabel];
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
	CGSize wdvFrame = webDocView.contentSize;
	CGFloat wdvAspectRatio = wdvFrame.height / wdvFrame.width;
	
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
	
	CGFloat sx = wdvFrame.width/drawFrame.size.width, sy = wdvFrame.height/drawFrame.size.height;
	
	CGAffineTransform tx = CGAffineTransformMake(1.f/sx, 0, 0, 1.f/sy, 1, 1);
//	inverse_tx = CGAffineTransformInvert(tx);
	inverse_tx = CGAffineTransformMake(sx, 0, 0, sy, -sx, -sy);
	
	CGRect visRect;
	visRect.origin = webDocView.offset;
	visRect.size = webDocView.frame.size;
	
	dragRegion = CGRectApplyAffineTransform(visRect, tx);
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
	
	UIView* btn = [self buttonAtIndex:0];
	
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
-(id)initWithDocumentView:(UIScrollView*)v andWebView:(UIWebDocumentView*)w {
	if ((self = [super initWithTitle:nil message:nil delegate:self cancelButtonTitle:doneText otherButtonTitles:nil])) {
		dv = [DragView new];
		dv.backgroundColor = [UIColor clearColor];
		dv->webDocView = v;
		dv->associatedWebView = w;
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
		WebDocViewScroller* alert = [[WebDocViewScroller alloc] initWithDocumentView:[webView _scroller] andWebView:webView];
		[alert layout];
		[alert release];
	} else {
		WebPDFView* pdf = WebPDF(webView);
		CGRect* rects = pageRects(pdf);
		NSString* text = [self textField].text;
		if ([text length] != 0) {
			NSInteger val = [[self textField].text integerValue]-1;
			if (val < 0)
				val = 0;
			else if (val > totalPageCount)
				val = totalPageCount-1;
			if (val != oldPage)
				[webView _setScrollerOffset:[pdf convertPoint:rects[val].origin toView:nil]];
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
		oldPage = [pdfView pageNumberForRect:[pdfView convertRect:v.visibleRect fromView:nil]];
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



static Class UIWebDocumentView_Class;
static void (*original_UIWindow__sendTouchesForEvent_)(UIWindow* self, SEL _cmd, UIEvent* event);
static void replaced_UIWindow__sendTouchesForEvent_(UIWindow* self, SEL _cmd, UIEvent* event) {
	UITouch* anyTouch = [event.allTouches anyObject];
	if (anyTouch.phase == UITouchPhaseEnded && anyTouch.tapCount == 3) {
		UIView* view = anyTouch.view;
		UIScrollView* scroller = [view _scroller];
		if (scroller != nil) {
			UIAlertView* alert = nil;
			if ([view isKindOfClass:UIWebDocumentView_Class] && WebPDF((UIWebDocumentView*)view))
				alert = [[PDFJumpToScroller alloc] initWithDocumentView:(UIWebDocumentView*)view];
			else
				alert = [[WebDocViewScroller alloc] initWithDocumentView:scroller andWebView:nil];
			[alert release];
		}
	}
	
	original_UIWindow__sendTouchesForEvent_(self, _cmd, event);
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
	
	doneText = [[localizationMap objectForKey:@"Close"] retain];
	scrollerText = [[localizationMap objectForKey:@"Scroller"] retain];
	pageNumberText = [[localizationMap objectForKey:@"Page number"] retain];
	goText = [[localizationMap objectForKey:@"Go"] retain];
	
	UIImage* img = [UIImage imageWithData:[dict objectForKey:@"AlertBackground"]];
	CGSize imgSize = img.size;
	alertBackground = [[img stretchableImageWithLeftCapWidth:imgSize.width/2 topCapHeight:imgSize.height/2] retain];
	
	UIWebDocumentView_Class = [UIWebDocumentView class];
	
	atexit(&releaseColors);
	
	original_UIWindow__sendTouchesForEvent_ = (void*)MSHookMessage([UIWindow class], @selector(_sendTouchesForEvent:), (IMP)replaced_UIWindow__sendTouchesForEvent_, NULL);
	
	[pool drain];
}
