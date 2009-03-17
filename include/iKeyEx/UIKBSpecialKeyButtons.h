/*
 
 UIKBSpecialKeyButtons.h .... Individual special keyboard buttons.
 
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

// These classes implement the behavior & layout of the Shift, Delete,
// International ("Globe"), Space bar and Return key on the standard keyboard.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <iKeyEx/UIKBStandardKeyboard.h>

@interface UIKBSpecialKeyButton : UIButton {
	BOOL landscape;
	UIKeyboardAppearance keyboardAppearance;
	BOOL textColorIsWhite;
	NSString* systemLocaleID;
}
@property(assign) UIKeyboardAppearance keyboardAppearance;
@property(assign) BOOL landscape;
@property(assign) BOOL textColorIsWhite;

-(UIKBSpecialKeyButton*)init;
-(void)setImagesWithNormal:(UIImage*)normal active:(UIImage*)active disabled:(UIImage*)disabled;
-(void)setImagesWithNormal:(UIImage*)normal active:(UIImage*)active;
-(void)setImagesWithNormal:(UIImage*)normal;
-(void)setText:(NSString*)titleText;
-(void)update;
-(BOOL)shouldDrillHole;
+(CGRect)defaultFrameWithLandscape:(BOOL)landsc;
@end

//------------------------------------------------------------------------------
// The "international" (globe) button for switching input mode.

@interface UIKBInternationalButton : UIKBSpecialKeyButton {
	NSDate* activationDate;
	NSTimer* longPressTimer;
}
+(UIKBInternationalButton*)buttonWithLandscape:(BOOL)landsc appearance:(UIKeyboardAppearance)appr;
@end

//------------------------------------------------------------------------------
// The space bar.

@interface UIKBSpaceBarButton : UIKBSpecialKeyButton {
	BOOL confirmCandidateOnClick;
}
@property(assign) BOOL confirmCandidateOnClick;
+(UIKBSpaceBarButton*)buttonWithLandscape:(BOOL)landsc appearance:(UIKeyboardAppearance)appr;
-(void)click;
@end

//------------------------------------------------------------------------------
// The return key.

@interface UIKBReturnKeyButton : UIKBSpecialKeyButton {
	BOOL isRoyalBlue;
	UIReturnKeyType returnKeyType;
	NSMutableArray* titles;
}
@property(assign) UIReturnKeyType returnKeyType;
+(UIKBReturnKeyButton*)buttonWithType:(UIReturnKeyType)type landscape:(BOOL)landsc appearance:(UIKeyboardAppearance)appr;
-(void)setText:(NSString*)title forType:(UIReturnKeyType)type;
-(void)dealloc;
@end

//------------------------------------------------------------------------------
// The shift key.

typedef enum UIKBShiftState {
	UIKBShiftStateNormal,
	UIKBShiftStatePressed,
	UIKBShiftStateLocked,
	UIKBShiftStateDisabled
} UIKBShiftState;

@interface UIKBShiftKeyButton : UIKBSpecialKeyButton {
	UIKBShiftState shiftState;
	UIKBShiftStyle shiftStyle;
	BOOL isHeldDown, enteredSomethingDuringHold, autolock;
}
@property(assign) UIKBShiftState shiftState;
@property(readonly,assign) BOOL isHeldDown;
@property(assign) BOOL enteredSomethingDuringHold;
@property(assign) BOOL autolock;
@property(assign) UIKBShiftStyle shiftStyle;
+(UIKBShiftKeyButton*)buttonWithLandscape:(BOOL)landsc appearance:(UIKeyboardAppearance)appr;
@end

//------------------------------------------------------------------------------
// The delete key.

@interface UIKBDeleteKeyButton : UIKBSpecialKeyButton {
	NSTimer* currentTimer;
	NSUInteger deleteCount;
}
+(UIKBDeleteKeyButton*)buttonWithLandscape:(BOOL)landsc appearance:(UIKeyboardAppearance)appr;
@end

//------------------------------------------------------------------------------
// The ABC/123 key.
// Users are expected to define the TouchDown action themselves.

@interface UIKBPlaneChooserButton : UIKBSpecialKeyButton {
	BOOL isAlt;
}
@property(assign) BOOL isAlt;
+(UIKBPlaneChooserButton*)buttonWithLandscape:(BOOL)landsc appearance:(UIKeyboardAppearance)appr;
@end

//------------------------------------------------------------------------------
// A superview for containing the UIKBSpecialKeyButton's so landscape & keyboard
// appearance can be transmitted automatically.

@interface UIKBButtonsGroup : UIView {
	BOOL landscape;
	UIKeyboardAppearance keyboardAppearance;	
}
-(UIKBButtonsGroup*)initWithLandscape:(BOOL)landsc appearance:(UIKeyboardAppearance)appr;
-(void)addSubviewWithClass:(Class)cls;
-(UIKBSpecialKeyButton*)firstSubviewWithClass:(Class)cls;
@property(assign) UIKeyboardAppearance keyboardAppearance;
@property(assign) BOOL landscape;
@end
