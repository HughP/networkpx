/*
 
 UIKBStandardKeyboard.h ... Standard Keyboard Definitions for iKeyEx.
 
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

// This class implements the abstract class UIKBStandardKeyboard which defines
// the layout and interaction of a standard 4-row iPhone keyboard. 
// The class provides outlets to generate the background, foreground images and
// key definitions for UIKeyboardSublayout to work.

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGGeometry.h>
#import <UIKit/UITextInputTraits.h>
#import <UIKit/UIImage.h>
#import <iKeyEx/KeyboardLoader.h>


typedef enum UIKBShiftStyle {
	UIKBShiftStyleDefault,
	UIKBShiftStyleSymbol,
	UIKBShiftStyle123
} UIKBShiftStyle;



@interface UIKBStandardKeyboard : NSObject {
	NSUInteger rows;
	NSArray** texts;
	NSArray** shiftedTexts;
	NSArray** labels;
	NSArray** shiftedLabels;
	NSArray** popups;
	NSArray** shiftedPopups;
	NSUInteger* counts;
	CGFloat* lefts;
	CGFloat* rights;
	CGFloat* widths;
	CGFloat* horizontalSpacings;
	
	CGFloat verticalSpacing, verticalOffset, keyHeight, defaultHeight;
	NSUInteger maxWidthForPopupChar, totalCount;
	
@package
	BOOL landscape;
	UIKeyboardAppearance keyboardAppearance;
	CGFloat fontSize;
	
	CGSize keyboardSize;
	
	BOOL hasSpaceKey, hasInternationalKey, hasReturnKey, hasShiftKey, hasDeleteKey;
	CGFloat shiftKeyLeft, deleteKeyRight, shiftKeyWidth, deleteKeyWidth;
	BOOL shiftKeyEnabled;
	NSUInteger shiftKeyRow, deleteKeyRow;
	UIKBShiftStyle shiftStyle;
}

/*
@property(assign,readonly) BOOL landscape;
@property(assign) UIKeyboardAppearance keyboardAppearance;
@property(assign) NSUInteger rows;

-(void)setArrangement:(UIKBKeyboardArrangement)arrangement;
-(void)setArrangementWithObject:(id)obj;
-(void)setArrangementWithNumbers:(NSUInteger*)n count:(NSUInteger)k;

-(void)setRowIndentation:(UIKBKeyboardRowIndentation)metrics;
-(void)setRowIndentationWithObject:(id)obj;
-(void)setRowIndentationWithNumbers:(NSUInteger*)n count:(NSUInteger)k;

-(void)setText:(NSString*)txt forRow:(NSUInteger)row column:(NSUInteger)col;
-(void)setText:(NSString*)txt shifted:(NSString*)shift forRow:(NSUInteger)row column:(NSUInteger)col;
-(void)setText:(NSString*)txt label:(NSString*)lbl popup:(NSString*)pop forRow:(NSUInteger)row column:(NSUInteger)col;
-(void)setText:(NSString*)txt label:(NSString*)lbl popup:(NSString*)pop shifted:(NSString*)shift shiftedLabel:(NSString*)sfl shiftedPopup:(NSString*)sfp forRow:(NSUInteger)row column:(NSUInteger)col;
-(void)setTexts:(NSArray*)txts forRow:(NSUInteger)row;
-(void)setTexts:(NSArray*)txts shiftedTexts:(NSArray*)sfts forRow:(NSUInteger)row;

@property(assign) BOOL hasSpaceKey;
@property(assign) BOOL hasInternationalKey;
@property(assign) BOOL hasReturnKey;
@property(assign) BOOL hasShiftKey;
@property(assign) CGFloat shiftKeyLeft;
@property(assign) CGFloat shiftKeyWidth;
@property(assign) BOOL hasDeleteKey;
@property(assign) CGFloat deleteKeyRight;
@property(assign) CGFloat deleteKeyWidth;
@property(assign) UIKBShiftStyle shiftStyle;
@property(assign,readonly) CGSize keyboardSize;
@property(assign) BOOL shiftKeyEnabled;
@property(assign) NSInteger horizontalSpacing;
@property(assign) NSInteger verticalSpacing;
*/

-(id)initWithPlist:(NSDictionary*)layoutDict name:(NSString*)name landscape:(BOOL)landsc appearance:(UIKeyboardAppearance)appr;
-(void)dealloc;

//+(UIKBStandardKeyboard*)keyboardWithLandscape:(BOOL)landsc appearance:(UIKeyboardAppearance)appr arrangement:(UIKBKeyboardArrangement)arrangement rowIndentation:(UIKBKeyboardRowIndentation)metrics;

@property(readonly,retain,nonatomic) UIImage* image;
@property(readonly,retain,nonatomic) UIImage* shiftImage;
@property(readonly,retain,nonatomic) UIImage* fgImage;
@property(readonly,retain,nonatomic) UIImage* fgShiftImage;
@property(readonly,retain,nonatomic) NSArray* keyDefinitions;

+(UIKBStandardKeyboard*)keyboardWithBundle:(KeyboardBundle*)bdl name:(NSString*)name landscape:(BOOL)landsc appearance:(UIKeyboardAppearance)appr;
+(UIKBStandardKeyboard*)keyboardWithPlist:(NSDictionary*)layoutDict name:(NSString*)name landscape:(BOOL)landsc appearance:(UIKeyboardAppearance)appr;

@property(assign,readonly,nonatomic) CGRect shiftRect;
@property(assign,readonly,nonatomic) CGRect deleteRect;

@end
