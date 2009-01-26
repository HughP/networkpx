/*
 
 controller.m ... Controllers/Delegates for Views in ℏClipboard.
 
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


#import "controller.h"
#import <iKeyEx/KeyboardLoader.h>
#import <iKeyEx/UIKBSpecialKeyButtons.h>
#import <UIKit2/UIKeyboardImpl.h>
#import <UIKit2/UICalloutView.h>
#import <WebCore/PublicDOMInterfaces.h>
#import <UIKit/UITextView.h>
#include <objc/runtime.h>
#import "clipboard.h"
#import "views.h"

// LS = Localized string
#define LS(s) [bundle localizedStringForKey:(s) value:nil table:nil]
#define PNG(fn) [UIImage imageWithContentsOfFile:[bundle pathForResource:(fn) ofType:@"png"]]

// Some dummy interfaces 
@interface UIWebDocumentView : UIView<UIKeyboardInput>
@end
@interface UITextViewLegacy : UIView
@property(assign) NSRange* selectedRange;
@end



#pragma mark -
// Provide a concrete container of a weak reference.
//  (break the retain cycle & allows being part of a container.)
@interface WeakReference : NSObject<NSCopying> {
	NSObject* reference;
}
@property(assign) NSObject* reference;
+(id)weakReferenceWithReference:(NSObject*)ref;
-(id)initWithReference:(NSObject*)ref;
-(BOOL)isEqual:(id<NSObject>)obj;
-(NSUInteger)hash;
-(id)copyWithZone:(NSZone*)zone;
@end

@implementation WeakReference 
@synthesize reference;
+(id)weakReferenceWithReference:(NSObject*)ref { return [[[WeakReference alloc] initWithReference:ref] autorelease]; }
-(id)initWithReference:(NSObject*)ref {
	if ((self = [super init]))
		reference = ref;
	return self;
}
-(BOOL)isEqual:(id<NSObject>)obj {
	if ([obj isMemberOfClass:[WeakReference class]]) {
		// probably I should use [reference isEqual:obj->reference] for correctness,
		// but the usage of WeakReference is limited so direct comparison is OK.
		return reference == ((WeakReference*)obj)->reference;
	} else
		return NO;
}
-(NSUInteger)hash { return [reference hash]; }
-(id)copyWithZone:(NSZone*)zone { return [[WeakReference allocWithZone:zone] initWithReference:reference]; }
@end


#pragma mark -
@implementation UICalloutViewShower
@synthesize boundaryRect;
-(id)initWithView:(UIView*)instf {
	if ((self = [super init])) {
		installView = instf;
		boundaryRect = instf.bounds;
		calloutView = [[UICalloutView alloc] initWithFrame:CGRectZero];
		calloutStrings = [[NSMutableDictionary alloc] init];
	}
	return self;
}
-(void)dealloc {
	for (WeakReference* p_btn in calloutStrings) {
		UIButton* btn = (UIButton*)(p_btn.reference);
		[btn removeTarget:self
				   action:@selector(show:) forControlEvents:UIControlEventTouchDown];
		[btn removeTarget:self
				   action:@selector(hide) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchDragOutside|UIControlEventTouchCancel];
	}
	
	[calloutView release];
	[calloutStrings release];
	[super dealloc];
}


-(void)registerButton:(UIButton*)btn withCalloutString:(NSString*)str {
	if (str == nil) return;
	WeakReference* p_btn = [[WeakReference alloc] initWithReference:btn];
	if ([calloutStrings objectForKey:p_btn] == nil) {
		[btn addTarget:self 
				action:@selector(show:) forControlEvents:UIControlEventTouchDown];
		[btn addTarget:self
				action:@selector(hide) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchDragOutside|UIControlEventTouchCancel];
	}
	[calloutStrings setObject:str forKey:p_btn];
	[p_btn release];

}
-(void)show:(UIButton*)sender {
	WeakReference* p_btn = [[WeakReference alloc] initWithReference:sender];
	NSString* str = [calloutStrings objectForKey:p_btn];
	if (str != nil) {
		calloutView.title = str;
		[calloutView setAnchorPoint:[sender convertPoint:CGPointZero toView:installView]
					   boundaryRect:boundaryRect
							animate:YES];
		[installView addSubview:calloutView];
	}
	[p_btn release];
}
-(void)hide {
	[calloutView fadeOutWithDuration:0.25];
	[calloutView removeFromSuperview];
}
@end



#pragma mark -
@implementation hCLayoutController
@synthesize view, bundle;

-(id)init {
	if ((self = [super init])) {
		view = nil;
		bundle = nil;
		selectState = NO;
		selectIndex = 0;
		
		// A list of applications that pasting a multi-character string does
		// not work or even crashes. For these apps, paste char by char instead.
		multicharBlacklist = [[NSSet alloc] initWithObjects:@"com.googlecode.mobileterminal", nil];
	}
	return self;
}

-(void)dealloc {
	[bundle release];
	[multicharBlacklist release];
	[super dealloc];
}

-(void)copyText:(NSString*)txt {
	if ([txt length] > 0) {
		[view->clipboardView.clipboard addData:txt secure:[UIKeyboardImpl sharedInstance].textInputTraits.secureTextEntry];
		[view->clipboardView updateDataCache];
		[view->clipboardView reloadData];

		[view->clipboardView flashFirstRowAsBlue];
	}
}

-(void)copyText {
	// take advantage of any selection made by 3rd party programs, e.g. Clippy and ⌘.
	NSObject<UIKeyboardInput>* del = [UIKeyboardImpl sharedInstance].delegate;
	NSRange curSelection = del.selectionRange;
	if (curSelection.length > 0)
		[self copyText:[del.text substringWithRange:curSelection]];
	else
		[self copyText:del.text];
}

-(void)paste:(NSString*)txt {
	UIKeyboardImpl* impl = [UIKeyboardImpl sharedInstance];
	if ([multicharBlacklist containsObject:[[NSBundle mainBundle] bundleIdentifier]]) {
		NSUInteger txtLen = [txt length];
		for (NSUInteger i = 0; i < txtLen; ++i)
			[impl addInputString:[txt substringWithRange:NSMakeRange(i, 1)]];
	} else
		[impl addInputString:txt];
}

-(void)moveToBeginning {
	NSObject<UIKeyboardInput>* del = [UIKeyboardImpl sharedInstance].delegate;
	if ([del isKindOfClass:objc_getClass("UIFieldEditor")]) {
		[del setSelection:NSMakeRange(0,0)];
		return;
	} else if ([del isKindOfClass:[UIWebDocumentView class]]) {
		UIView* mySuperview = [(UIWebDocumentView*)del superview];
		if ([mySuperview isKindOfClass:[UITextView class]] || [mySuperview isKindOfClass:[UITextViewLegacy class]]) {
			((UITextView*)mySuperview).selectedRange = NSMakeRange(0,0);
			return;
		}
	} else if ([del isKindOfClass:[DOMElement class]]) {
		((DOMElement*)del).scrollTop = 0;
		((DOMElement*)del).scrollLeft = 0;
		[((DOMElement*)del) focus];
	}
	
	[del selectAll];
	DOMRange* range = del.selectedDOMRange;
	[range collapse:YES];
	[del setSelectedDOMRange:range affinityDownstream:NO];
}

-(void)moveToEnd {
	NSObject<UIKeyboardInput>* del = [UIKeyboardImpl sharedInstance].delegate;
	if ([del isKindOfClass:objc_getClass("UIFieldEditor")]) {
		NSUInteger txtLen = [del.text length];
		[del setSelection:NSMakeRange(txtLen,0)];
		return;
	} else if ([del isKindOfClass:[UIWebDocumentView class]]) {
		UIView* mySuperview = [(UIWebDocumentView*)del superview];
		if ([mySuperview isKindOfClass:[UITextView class]] || [mySuperview isKindOfClass:[UITextViewLegacy class]]) {
			NSUInteger txtLen = [del.text length];
			((UITextView*)mySuperview).selectedRange = NSMakeRange(txtLen,0);
			return;
		}
	} else if ([del isKindOfClass:[DOMElement class]]) {
		((DOMElement*)del).scrollTop = ((DOMElement*)del).scrollHeight;
		((DOMElement*)del).scrollLeft = ((DOMElement*)del).scrollWidth;
		[((DOMElement*)del) focus];
	}
	
	[del selectAll];
	DOMRange* range = del.selectedDOMRange;
	[range collapse:NO];
	[del setSelectedDOMRange:range affinityDownstream:NO];
}

-(void)markSelection:(UIButton*)sender {
	UIKeyboardImpl* impl = [UIKeyboardImpl sharedInstance];
	id<UIKeyboardInput> del = impl.delegate;
	NSUInteger loc = del.selectionRange.location;
	if (selectState) {
		NSString* copyStr = nil;
		// force selectedIndex <= loc.
		if (loc < selectIndex) {
			NSUInteger tmp = selectIndex;
			selectIndex = loc;
			loc = tmp;
		}
		NSString* txt = del.text;
		NSUInteger txtLen = [txt length];
		if (selectIndex < txtLen) {
			if (loc < txtLen)
				copyStr = [txt substringWithRange:NSMakeRange(selectIndex, loc-selectIndex)];
			else
				copyStr = [txt substringFromIndex:selectIndex];
		}
		[self copyText:copyStr];
		selectState = NO;
		[view->calloutShower registerButton:sender withCalloutString:LS(@"Select from here...")];
		[sender setImage:PNG(@"selectStart") forState:UIControlStateNormal];
	} else {
		selectIndex = loc;
		selectState = YES;
		[view->calloutShower registerButton:sender 
		 withCalloutString:LS([view->clipboardView isDefaultClipboard] ?
							  @"Select to here and copy" :
							  @"Select to here and add to templates")];
		[sender setImage:PNG(@"selectEnd") forState:UIControlStateNormal];
	}
}

-(void)switchClipboard:(UIKBSpecialKeyButton*)sender {
	BOOL isDefault = [view->clipboardView switchClipboard];
	if (isDefault) {
		[view->clipboardView setPlaceholderText:LS(@"Clipboard is empty")];
		[sender setImage:PNG(@"toTemplate") forState:UIControlStateNormal];
		[view->calloutShower registerButton:sender withCalloutString:LS(@"Switch to Templates")];
		[view->calloutShower registerButton:view->copyBtn withCalloutString:LS(@"Copy")];
	} else {
		[view->clipboardView setPlaceholderText:LS(@"No templates")];
		[sender setImage:PNG(@"toClipboard") forState:UIControlStateNormal];
		[view->calloutShower registerButton:sender withCalloutString:LS(@"Switch to Clipboard")];
		[view->calloutShower registerButton:view->copyBtn withCalloutString:LS(@"Add to templates")];
	}
}

@end