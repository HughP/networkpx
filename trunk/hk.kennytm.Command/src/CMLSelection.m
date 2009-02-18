/*
 
 CMLUndoManager.h ... Set selection to a UIKeyboardInput.
 
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

#import <Command/CMLSelection.h>
#import <Foundation/NSObject.h>
#import <UIKit2/UIKeyboardInput.h>
#import <UIKit2/UIKeyboardImpl.h>
#import <UIKit/UIView.h>
#import <UIKit/UITextView.h>
#import <WebCore/PublicDOMInterfaces.h>

@interface UIWebDocumentView : UIView<UIKeyboardInput>
@end
@interface UITextViewLegacy : UIView
@property(assign) NSRange* selectedRange;
@end

// Note: setSelection won't verify if newRange is valid.
void setSelection(NSObject<UIKeyboardInput>* del, NSRange newRange) {
	if ([del isKindOfClass:objc_getClass("UIFieldEditor")]) {
		[del setSelection:newRange];
		return;
	} else if ([del isKindOfClass:[UIWebDocumentView class]]) {
		UIView* mySuperview = [(UIWebDocumentView*)del superview];
		if ([mySuperview isKindOfClass:[UITextView class]] || [mySuperview isKindOfClass:[UITextViewLegacy class]]) {
			((UITextView*)mySuperview).selectedRange = newRange;
			return;
		}
	} else if ([del isKindOfClass:[DOMElement class]]) {
		if ([del respondsToSelector:@selector(setSelectionRange:end:)]) {
			// <input type="text"/> and <textarea/> support this safer and faster method.
			[del setSelectionRange:newRange.location end:newRange.location+newRange.length];
		} else {
			DOMRange* range = del.selectedDOMRange;
			// retain to avoid container suddenly disappeared.
			// rather memory leak than crash.
			[range setStart:[range.startContainer retain] offset:newRange.location];
			[range setEnd:[range.endContainer retain] offset:newRange.location+newRange.length];
			[del setSelectedDOMRange:range affinityDownstream:YES];
		}
	}
}

void setSelectionToCurrentDelegate(NSRange newRange) { setSelection([UIKeyboardImpl sharedInstance].delegate, newRange); }

NSRange getSelection(NSObject<UIKeyboardInput>* del, NSString** selectedText) {
	NSRange retval = del.selectionRange;
	DOMRange* domRange = del.selectedDOMRange;
	if (retval.location == NSNotFound) {
		retval = NSMakeRange(domRange.startOffset, domRange.endOffset - domRange.startOffset);
	}
	if (selectedText != NULL) {
		*selectedText = [domRange toString];
	}
	return retval;
}

NSRange getSelectionFromCurrentDelegate(NSString** selectedText) { return getSelection([UIKeyboardImpl sharedInstance].delegate, selectedText); }