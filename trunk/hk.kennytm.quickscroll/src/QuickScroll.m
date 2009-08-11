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
#import <UIKit/UIScroller.h>
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
enum { locClose, locScroller, locPageNumber, locGo, loc_Count };
static NSString* const locKeys[] = {@"Close", @"Scroller", @"Page number", @"Go"};
static NSString* locTexts[loc_Count];


__attribute__((visibility("hidden")))
@interface DragView : UIView {
@package
	UIScrollView* webDocView;
	UIWebDocumentView* associatedWebView;
@private
	CGRect dragRegion;
	CGAffineTransform inverse_tx;
	CGSize dragShift, drawSize, drawShift;
}
@end
@implementation DragView
-(void)scrollTo {
	CGPoint p = CGPointApplyAffineTransform(dragRegion.origin, inverse_tx);
	[webDocView setOffset:CGPointMake(p.x - drawShift.width, p.y - drawShift.height)];
	[associatedWebView updatePDFPageNumberLabel];
}
-(void)correctDragRegion {
	if (dragRegion.origin.x < 1)
		dragRegion.origin.x = 1;
	else if (dragRegion.origin.x + dragRegion.size.width > drawSize.width)
		dragRegion.origin.x = drawSize.width - dragRegion.size.width;
	
	if (dragRegion.origin.y < 1)
		dragRegion.origin.y = 1;
	else if (dragRegion.origin.y + dragRegion.size.height > drawSize.height)
		dragRegion.origin.y = drawSize.height - dragRegion.size.height;
}
-(void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
	CGPoint lastPoint = [[touches anyObject] locationInView:self];
//	if (!CGRectContainsPoint(dragRegion, lastPoint)) {
	if (lastPoint.x < dragRegion.origin.x || lastPoint.x > dragRegion.origin.x + dragRegion.size.width || lastPoint.y < dragRegion.origin.y || lastPoint.y > dragRegion.origin.y + dragRegion.size.height) {
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
	
	if ([webDocView respondsToSelector:@selector(contentInset)]) {
		UIEdgeInsets insets = webDocView.contentInset;
		drawShift = CGSizeMake(insets.left, insets.top);
		wdvFrame.width += insets.left + insets.right;
		wdvFrame.height += insets.top + insets.bottom;
	} else
		drawShift = CGSizeMake(0, 0);
	
	CGFloat wdvAspectRatio = wdvFrame.height / wdvFrame.width;
	
	// Page is like a long rectangle.
	if (wdvAspectRatio > 2.5f)
		wdvAspectRatio = 2.5f;
	else if (wdvAspectRatio < 0.5f)
		wdvAspectRatio = 0.5f;
	
	// Solve these equations:
	// [1] height * width = AREA
	// [2] height / width = wdvAspectRatio
	static const CGFloat AREA = 16000;
	CGFloat height = sqrtf(AREA * wdvAspectRatio);
	drawSize = CGSizeMake(AREA / height, height);
	
	CGFloat sx = wdvFrame.width/drawSize.width, sy = wdvFrame.height/drawSize.height;
	
	drawSize.width = (long)(drawSize.width + 1);
	drawSize.height = (long)(drawSize.height + 1);
	[super setFrame:CGRectMake(newFrame.origin.x-1, newFrame.origin.y-1, drawSize.width + 1, drawSize.height + 1)];
	
	CGAffineTransform tx = CGAffineTransformMake(1.f/sx, 0, 0, 1.f/sy, 1, 1);
	inverse_tx = CGAffineTransformMake(sx, 0, 0, sy, -sx, -sy);
	
	CGRect dragRegion0 = webDocView.bounds;
	dragRegion0.origin.x += drawShift.width;
	dragRegion0.origin.y += drawShift.height;
	dragRegion = CGRectApplyAffineTransform(dragRegion0, tx);
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
	dragRegionBlownUp.origin.x = (long)(dragRegionBlownUp.origin.x);
	dragRegionBlownUp.origin.y = (long)(dragRegionBlownUp.origin.y);
	dragRegionBlownUp.size.width = (long)(dragRegionBlownUp.size.width);
	dragRegionBlownUp.size.height = (long)(dragRegionBlownUp.size.height);
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
+(WebDocViewScroller*)showWithScrollView:(UIScrollView*)v webView:(UIWebDocumentView*)w {
	CGSize contentSize = v.contentSize, bounds = v.bounds.size;
	if (contentSize.width <= bounds.width && contentSize.height <= bounds.height)
		return nil;
	
	WebDocViewScroller* x = [self new];
	if (x != nil) {
		[x addButtonWithTitle:locTexts[locClose]];
		DragView* dv = [DragView new];
		if (dv != nil) {
			dv.backgroundColor = [UIColor clearColor];
			dv->webDocView = v;
			dv->associatedWebView = w;
		}
		[x addSubview:dv];
		x->dv =dv;
		[x show];
		[x release];
	}
	return x;
}
@end

static inline ptrdiff_t offsetForClassAndName(Class cls, const char* str) {
	return ivar_getOffset(class_getInstanceVariable(cls, str));
}



static ptrdiff_t pdfOffset = 0;
static inline WebPDFView* WebPDF(UIWebDocumentView* view) {
	if (pdfOffset == 0)
		pdfOffset = offsetForClassAndName([UIWebDocumentView class], "_pdf");
	return *(WebPDFView**)((char*)view + pdfOffset);
}

static ptrdiff_t pageRectsOffset = 0;
static inline CGRect* pageRects(WebPDFView* view) {
	if (pageRectsOffset == 0)
		pageRectsOffset = offsetForClassAndName([view class], "_pageRects");
	return *(CGRect**)((char*)view + pageRectsOffset);
}


__attribute__((visibility("hidden")))
@interface PDFJumpToScroller : UIAlertView {
	unsigned totalPageCount, oldPage;
	UIWebDocumentView* webView;
	WebPDFView* pdfView;
}
@end
@implementation PDFJumpToScroller
-(void)_buttonClicked:(UIView*)button {
	int buttonID = button.tag;
	[super _buttonClicked:button];
	if (buttonID == 1) {
		[[WebDocViewScroller showWithScrollView:[webView _scroller] webView:webView] layout];
	} else {
		CGRect* rects = pageRects(pdfView);
		NSString* text = [self textField].text;
		if ([text length] != 0) {
			NSInteger val = [[self textField].text integerValue];
			if (val < 1)
				val = 1;
			else if (val >= totalPageCount)
				val = totalPageCount;
			if (val != oldPage)
				[webView _setScrollerOffset:[pdfView convertPoint:rects[val-1].origin toView:nil]];
		}
		[webView updatePDFPageNumberLabel];
	}
}
+(void)showWithWebView:(UIWebDocumentView*)v pdfView:(WebPDFView*)pdfView_ {
	unsigned pageCount = [pdfView_ totalPages];
	if (pageCount > 0) {
		PDFJumpToScroller* x = [self new];
		if (x != nil) {
			[x addButtonWithTitle:locTexts[locScroller]];
			[x addButtonWithTitle:locTexts[locGo]];
			x->webView = v;
			x->pdfView = pdfView_;
			x->totalPageCount = pageCount;
			x.message = [NSString stringWithFormat:@"%@ (1 – %u):", locTexts[locPageNumber], pageCount];
			x->oldPage = [pdfView_ pageNumberForRect:[pdfView_ convertRect:v.visibleRect fromView:nil]];
			UITextField* textField = [x addTextFieldWithValue:[NSString stringWithFormat:@"%u", x->oldPage] label:nil];
			textField.keyboardType = UIKeyboardTypeNumberPad;
			textField.textAlignment = UITextAlignmentCenter;
			[x show];
			[x release];
		}
	}
}
@end



static void (*original_UIWindow__sendTouchesForEvent_)(UIWindow* self, SEL _cmd, UIEvent* event);
static void replaced_UIWindow__sendTouchesForEvent_(UIWindow* self, SEL _cmd, UIEvent* event) {
	if (self.windowLevel < UIWindowLevelAlert) {
		NSArray* allTouchesArray = [event.allTouches allObjects];
		int allTouchesCount = [allTouchesArray count];
		UITouch* allTouches[allTouchesCount];
		[allTouchesArray getObjects:allTouches];
		for (int i = 0; i < allTouchesCount; ++ i) {
			UITouch* anyTouch = allTouches[i];
			if (anyTouch.phase == UITouchPhaseEnded && anyTouch.tapCount >= 3) {
				UIScrollView* view = nil;
				UIView* prevView = anyTouch.view;
				while (prevView != nil) {
					if ((view = [prevView _scroller]))
						break;
					else
						prevView = prevView.superview;
				}
				if (view != nil) {
					if ([prevView isKindOfClass:[UIWebDocumentView class]]) { 
						WebPDFView* pdfView = WebPDF((UIWebDocumentView*)prevView);
						if (pdfView != nil) {
							[PDFJumpToScroller showWithWebView:(UIWebDocumentView*)prevView pdfView:pdfView];
							break;
						}
					}
					[WebDocViewScroller showWithScrollView:view webView:nil];
					break;
				}
			}
		}
	}
	original_UIWindow__sendTouchesForEvent_(self, _cmd, event);
}


static void releaseColors() {
	[alertBackground release];
	CGColorRelease(greenColor);
	CGColorRelease(translucentGreenColor);
	for (int i = 0; i < 4; ++ i)
		[locTexts[i] release];
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
		
	NSArray* preferedLocalization = [NSBundle preferredLocalizationsFromArray:[localizationDictionary allKeys]] ; 
	NSDictionary* localizationMap = nil;
	int pLK = [preferedLocalization count];
	NSString* locs[pLK];
	[preferedLocalization getObjects:locs];
	for (int i = 0; i < pLK; ++ i) {
		localizationMap = [localizationDictionary objectForKey:locs[i]];
		if (localizationMap != nil)
			break;
	}
	
	for (int i = 0; i < 4; ++ i)
		locTexts[i] = [[localizationMap objectForKey:locKeys[i]] retain];
		
	UIImage* img = [UIImage imageWithData:[dict objectForKey:@"AlertBackground"]];
	CGSize imgSize = img.size;
	alertBackground = [[img stretchableImageWithLeftCapWidth:imgSize.width/2 topCapHeight:imgSize.height/2] retain];
	
	atexit(&releaseColors);
	
	original_UIWindow__sendTouchesForEvent_ = (void*)MSHookMessage([UIWindow class], @selector(_sendTouchesForEvent:), (IMP)replaced_UIWindow__sendTouchesForEvent_, NULL);
	
	[pool drain];
}
