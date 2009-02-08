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

typedef enum UIKBKeyboardArrangement {
	// the constants are in the format DDBBCCAA (in hexadecimal)
	// where AA is the number of buttons in 1st row, BB in 2nd, etc.
	UIKBKeyboardArrangementDefault        = 7 << 16 |  9 << 8 | 10,
	UIKBKeyboardArrangementAZERTY         = 6 << 16 | 10 << 8 | 10,
	UIKBKeyboardArrangementRussian        = 9 << 16 | 11 << 8 | 11,
	UIKBKeyboardArrangementAlt            = 5 << 16 | 10 << 8 | 10,
	UIKBKeyboardArrangementURLAlt         = 4 << 16 |  6 << 8 | 10,
	UIKBKeyboardArrangementJapaneseQWERTY = 7 << 16 | 10 << 8 | 10,
	UIKBKeyboardArrangementEmpty          = 0,
	
	UIKBKeyboardArrangementWithURLRow4 = 3 << 24
} UIKBKeyboardArrangement;

typedef enum UIKBKeyboardRowIndentation {
	// the constants are in the format DDBBCCAA (in hexadecimal)
	// where AA is the indentation for optimal widths from one side in 1st row, BB in 2nd, etc.
	UIKBKeyboardRowIndentationDefault         = 80 << 24 | 48 << 16 | 16 << 8,
	UIKBKeyboardRowIndentationTightestDefault = 80 << 24 | 42 << 16,
	UIKBKeyboardRowIndentationAZERTY          = 80 << 24 | 64 << 16,
	UIKBKeyboardRowIndentationAlt             = 80 << 24 | 48 << 16,
	UIKBKeyboardRowIndentationRussian         = 80 << 24 | 29 << 16,
	
	// in landscape mode there's a 5px margin by default.
	UIKBKeyboardRowIndentationLandscapeDefault         = 95 << 24 | 71 << 16 | 24 << 8,
	UIKBKeyboardRowIndentationLandscapeTightestDefault = 95 << 24 | 61 << 16,
	UIKBKeyboardRowIndentationLandscapeAZERTY          = 95 << 24 | 94 << 16,
	UIKBKeyboardRowIndentationLandscapeAlt             = 95 << 24 | 71 << 16,
	UIKBKeyboardRowIndentationLandscapeRussian         = 95 << 24 | 61 << 16	// same as tightest default.
} UIKBKeyboardRowIndentation;



typedef enum UIKBShiftStyle {
	UIKBShiftStyleDefault,
	UIKBShiftStyle123
} UIKBShiftStyle;




@interface UIKBStandardKeyboard : NSObject {
	NSUInteger rows;
	NSMutableArray** texts;
	NSMutableArray** shiftedTexts;
	NSUInteger* counts;
	NSUInteger* lefts;
	NSUInteger* widths;
	BOOL landscape;
	UIKeyboardAppearance keyboardAppearance;
	CGFloat fontSize;
	NSInteger horizontalSpacing, verticalSpacing;
	
	CGSize keyboardSize;
	
	BOOL hasSpaceKey, hasInternationalKey, hasReturnKey, hasShiftKey, hasDeleteKey;
	CGFloat shiftKeyLeft, deleteKeyRight, shiftKeyWidth, deleteKeyWidth;
	BOOL shiftKeyEnabled;
	UIKBShiftStyle shiftStyle;
}

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

+(UIKBStandardKeyboard*)keyboardWithLandscape:(BOOL)landsc appearance:(UIKeyboardAppearance)appr arrangement:(UIKBKeyboardArrangement)arrangement rowIndentation:(UIKBKeyboardRowIndentation)metrics;

@property(readonly,retain) UIImage* image;
@property(readonly,retain) UIImage* shiftImage;
@property(readonly,retain) UIImage* fgImage;
@property(readonly,retain) UIImage* fgShiftImage;
@property(readonly,retain) NSArray* keyDefinitions;

+(UIKBStandardKeyboard*)keyboardWithBundle:(KeyboardBundle*)bdl name:(NSString*)name landscape:(BOOL)landsc appearance:(UIKeyboardAppearance)appr;
+(UIKBStandardKeyboard*)keyboardWithPlist:(NSDictionary*)layoutDict name:(NSString*)name landscape:(BOOL)landsc appearance:(UIKeyboardAppearance)appr;
@end
