/*
 
 UIActionSheetPro.h ... More flexible UIActionSheet
 
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

#import <Foundation/NSObject.h>
#import <UIKit/UIAlert.h>
@class NSString, NSMutableArray, UIImage, UIButton, UIWebTexts, UIView;

// Note: Although UIActionSheetPro inherits from UIActionSheet, 
//       you should *not* call any standard messages.
@interface UIActionSheetPro : UIActionSheet {
	BOOL isLandscape;
	NSUInteger rows;
	NSMutableArray** buttons;
	UIView* buttonsGroup;
	NSUInteger* cancelButtonsCount;
}
-(id)initWithNumberOfRows:(NSUInteger)rows;
-(UIButton*)addButtonAtRow:(NSUInteger)row withTitle:(NSString*)title image:(UIImage*)image destructive:(BOOL)destructive cancel:(BOOL)cancel;
-(void)showWithWebTexts:(UIWebTexts*)texts inView:(UIView*)view;
@end

// overloaded private methods.
@interface UIActionSheetPro()
-(void)layout;
-(void)_createTitleLabelIfNeeded;
@end
