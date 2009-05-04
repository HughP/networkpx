/*
 
 UIUtilities.m ... Convenient functions for UI elements
 
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

#import <UIKit3/UIUtilities.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIView.h>
#import <UIKit/UIGeometry.h>
#import <UIKit2/UIPickerTable.h>
#ifdef UIUTILITIES_SHOW_WEBTEXT
#import <WebCore/PublicDOMInterfaces.h>
#import <WebCore/wak/WebCoreThread.h>
#import <UIKit2/UIWebDocumentView.h>
#import <UIKit2/DOMNode-UIWebViewAdditions.h>
#import <WebKit/mac/Misc/WebLocalizableStrings.h>

static WebLocalizableStringsBundle UIKitLocalizableStringsBundle = {"com.apple.UIKit", nil};

@implementation UIWebTexts
@synthesize text, linkLabel, URL, alt, imageURL, title, view, rect, userInfo;
-(void)dealloc {
	[text release];
	[linkLabel release];
	[URL release];
	[alt release];
	[imageURL release];
	[title release];
	[super dealloc];
}
-(NSString*)description {
	return [NSString stringWithFormat:@"text=%@, linkLabel=%@, URL=%@, alt=%@, imageURL=%@, title=%@, rect=%@, userInfo=%d",
			text, linkLabel, URL, alt, imageURL, title, NSStringFromCGRect(rect), userInfo];
}
@end
#endif

extern
NSString* UITextOf(UIView* v) {
	if ([v isKindOfClass:objc_getClass("UIPickerTable")]) {
		return UITextOf([(UIView<UIPickerTable>*)v selectedTableCell]);
	}
	
	const SEL titleSelectors[] = {@selector(title), @selector(currentTitle), @selector(text), @selector(prompt)};
	for (int i = 0; i < sizeof(titleSelectors)/sizeof(SEL); ++i) {
		if ([v respondsToSelector:titleSelectors[i]]) {
			NSString* result = [v performSelector:titleSelectors[i]];
			if (result)
				return result;
		}
	}
	return nil;
}


void UILogViewHierarchyWithDots(UIView* v, NSString* dots) {
	NSLog(@"%@%@\t(frame=%@, text=%@, tag=%d)", dots, v, NSStringFromCGRect(v.frame), UITextOf(v), v.tag);
	NSString* moreDots = [dots stringByAppendingString:@".."];
	for (UIView* w in v.subviews) {
		UILogViewHierarchyWithDots(w, moreDots);
	}
}

extern void UILogViewHierarchy (UIView* v) { UILogViewHierarchyWithDots(v, @""); }

extern void UILogSuperviews (UIView* v) {
	NSMutableString* tildes = [NSMutableString string];
	UIView* w = v;
	while (w != nil) {
		NSLog(@"%@%@\t(frame=%@, text=%@, tag=%d)", tildes, w, NSStringFromCGRect(w.frame), UITextOf(w), w.tag);
		w = w.superview;
		[tildes appendString:@"~~"];
	}
}

#ifdef UIUTILITIES_SHOW_WEBTEXT
UIWebTexts* UITextsAtPoint(UIView* view, CGPoint pt) {
	UIWebTexts* retval = [[[UIWebTexts alloc] init] autorelease];
	if ([view isKindOfClass:[UIWebDocumentView class]]) {
		WebThreadLock();
		NSDictionary* dict = [[(UIWebDocumentView*)view webView] elementAtPoint:pt];
		DOMNode* node = [dict objectForKey:@"WebElementDOMNode"];
		while ([node.nodeName hasPrefix:@"#"]) {
			node = node.parentNode;
			if (node == nil)
				break;
		}
		retval.text = node.textContent;
		retval.rect = [node convertRect:[node boundingBoxAtPoint:pt] toView:nil];
		WebThreadUnlock();
		retval.linkLabel = [dict objectForKey:@"WebElementLinkLabel"];
		retval.URL = [dict objectForKey:@"WebElementLinkURL"];
		retval.alt = [dict objectForKey:@"WebElementImageAltString"];
		retval.imageURL = [dict objectForKey:@"WebElementImageURL"];
		retval.title = [dict objectForKey:@"WebElementTitle"];

	} else {
		retval.text = UITextOf(view);
		retval.rect = [view convertRect:view.bounds toView:nil];
	}
	retval.view = view;
	return retval;
}

NSString* UILocalizedString(const char* str) {
	return WebLocalizedString(&UIKitLocalizableStringsBundle, str);
}
#endif