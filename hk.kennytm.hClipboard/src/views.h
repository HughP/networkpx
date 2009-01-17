/*
 
 views.h ... Views and Layouts in ℏClipboard.
 
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
#import <UIKit2/UIKeyboardLayout.h>


@class hCClipboardDataSource, Clipboard, UIKBButtonsGroup, UICalloutView, hCLayoutController, UICalloutViewShower, UIKBSpecialKeyButton;



// a UITableView that displays clipboard data.
@interface hCClipboardView : UITableView<UITableViewDelegate> {
	hCClipboardDataSource* datasource;
	id _target;
	SEL _action;
	BOOL flash0thRow;
	UILabel* emptyClipboardIndicator;
}
-(id)initWithFrame:(CGRect)frm;
@property(retain) Clipboard* clipboard;
-(BOOL)isDefaultClipboard;
-(void)setTarget:(id)target action:(SEL)action;
-(void)setPlaceholderText:(NSString*)txt;

-(void)flashFirstRow;
-(BOOL)switchClipboard;
@end




// a transparent vertical toolbar
@interface hCVerticalToolBar : UIView {
	NSUInteger columns;
}
@property(assign) NSUInteger columns;
-(void)layoutSubviews;
-(UIButton*)addButtonWithImage:(UIImage*)img target:(id)target action:(SEL)action;
@end



// the keyboard layout for ℏClipboard.
@interface hCLayout : UIKeyboardLayout {
@package
	hCVerticalToolBar* toolbar;
	hCClipboardView* clipboardView;
	UICalloutViewShower* calloutShower;
	UIButton* copyBtn;
@protected
	UIButton* markSelBtn;
	UIImageView* backgroundView;
	UIKBButtonsGroup* spBtnGroup;
	hCLayoutController* controller;
	UIKeyboardAppearance keyboardAppearance;
	UIKBSpecialKeyButton* switchClipboardButton;
}
-(id)initWithFrame:(CGRect)frm;
-(void)layoutSubviews;
@property(readonly,assign) hCClipboardView* clipboardView;
@end