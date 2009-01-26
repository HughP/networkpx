/*
 
 UIAccentedCharacterView-setStringWidth.m ... Set string width for UIAccentedCharacterView.
 
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

#import <iKeyEx/UIAccentedCharacterView-setStringWidth.h>
#import <UIKit2/UIAccentedKeyCapStringView.h>
#import <UIKit2/Functions.h>
#include <objc/runtime.h>

@implementation UIAccentedCharacterView (setStringWidth)
-(CGFloat)stringWidth { return m_stringWidth; }
-(void)setStringWidth:(CGFloat)newWidth {
	Ivar tubeRect_ivar = class_getInstanceVariable([UIAccentedCharacterView class], "m_tubeRect");
	if (tubeRect_ivar == Nil)
		return;
	
	if (newWidth != m_stringWidth) {
		UIAccentedKeyCapStringView* popupView = nil;
		object_getInstanceVariable(self, "m_popupView", (void**)&popupView);
		if (popupView == nil)
			popupView = [self.subviews objectAtIndex:0];

		[popupView setStringWidth:newWidth];
		
		UIAccentedKeyCapStringView* selectedView = nil;
		object_getInstanceVariable(self, "m_selectedView", (void**)&selectedView);
		
		[selectedView setStringWidth:newWidth];
		
		m_stringWidth = newWidth;
		
		CGFloat totalWidth = 46 + newWidth*m_count;
		CGFloat excess = 0;
				
		if (m_expansion) {
			excess = totalWidth - m_tubeRect.size.width;
			if (excess > m_tubeRect.origin.x+23) {
				// TODO: make it use internal functions.
				[m_grabberImage release];
				m_grabberImage = [_UIImageWithName(@"kb-accented-mid-grabber.png") retain];
				excess = m_tubeRect.origin.x+23;
			}
		}
		
		CGRect tmpFrame;
		if (selectedView != nil) {
			tmpFrame = selectedView.frame;
			tmpFrame.size.width = newWidth;
			selectedView.frame = tmpFrame;
		} else
			tmpFrame = CGRectZero;
		
		if (popupView != nil) {
			tmpFrame = popupView.frame;
			tmpFrame.size.width = totalWidth;
			tmpFrame.origin.x -= excess;
			popupView.frame = tmpFrame;
		}
		
		m_tubeRect.size.width = totalWidth;
		m_tubeRect.origin.x -= excess;
	}
}
@end