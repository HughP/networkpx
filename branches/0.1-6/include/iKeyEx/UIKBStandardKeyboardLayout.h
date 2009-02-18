/*
 
 UIKBStandardKeyboardLayout.h ... Layout for customized standard keyboard.
 
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

#import <UIKit2/UIKeyboardSublayout.h>
#import <UIKit2/UIKeyboardLayoutQWERTY.h>
#import <UIKit2/UIKeyboardLayoutQWERTYLandscape.h>
#import <CoreGraphics/CGGeometry.h>
#import <iKeyEx/UIKBStandardKeyboard.h>

@interface UIKeyboardSublayout (UIKBStandardKeyboard2_h) 
-(void)setImageView:(UIImage*)img;
-(void)setShiftImageView:(UIImage*)simg;
+(UIKeyboardSublayout*)sublayoutWithFrame:(CGRect)frame
								 keyboard:(UIKBStandardKeyboard*)keyboard
					  keyDefinitionBuffer:(UIKeyDefinition**)keydef
						   keyCountBuffer:(NSUInteger*)keyCount
									 type:(NSString*)sublayoutType
									isAlt:(BOOL)isAlt;
@end



typedef enum UIKBSublayoutType {
	UIKBSublayoutAlphabet,
	UIKBSublayoutNumbers,
	UIKBSublayoutPhonePad,
	UIKBSublayoutPhonePadAlt,
	UIKBSublayoutNumberPad,
	UIKBSublayoutURL,
	UIKBSublayoutURLAlt,
	UIKBSublayoutSMSAddressing,
	UIKBSublayoutSMSAddressingAlt,
	UIKBSublayoutEmailAddress,
	UIKBSublayoutEmailAddressAlt,
	
	UIKBSublayoutCount
} UIKBSublayoutType;


@interface UIKBStandardKeyboardLayout : UIKeyboardLayoutQWERTY {
	UIKeyDefinition* keyDefs[UIKBSublayoutCount];
	NSUInteger keyCounts[UIKBSublayoutCount];
	NSDictionary* plist;
}
@end

@interface UIKBStandardKeyboardLayoutLandscape : UIKeyboardLayoutQWERTYLandscape {
	UIKeyDefinition* keyDefs[UIKBSublayoutCount];
	NSUInteger keyCounts[UIKBSublayoutCount];
	NSDictionary* plist;
}
@end
