/*
 
 UIKBStandardKeyboard.m ... Standard Keyboard Definitions for iKeyEx.
 
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

#import <iKeyEx/UIKBStandardKeyboard.h>
#import <iKeyEx/common.h>
#import <iKeyEx/ImageLoader.h>
#import <iKeyEx/UIKBKeyDefinition.h>
#import <UIKit2/UIKeyboardImpl.h>
#import <UIKit2/Constants.h>
#import <UIKit/UIGraphics.h>

#pragma mark -
#pragma mark Constants

#define UIKBKeyFontSizeMultiplier 0.75f
#define UIKBKeyMaxFontSize 22.5f
#define UIKBKeyPopupMaxFontSize 45
static const CGSize UIKBKeyPopupSize = {44, 50};

#define UIKBKey_Padding 8

#define UIKBKey_height 44
static const NSUInteger UIKBKey_tops[] = {10, 64, 118, 172, UINT_MAX};
static const NSUInteger UIKBKey_bgArea_tops[] = {0, 64, 118, 172};
static const NSUInteger UIKBKey_bgArea_heights[] = {64, 54, 54, 44};

#define UIKBKey_landscape_height 38
static const NSUInteger UIKBKey_landscape_tops[] = {4, 44, 84, 124, UINT_MAX};
static const NSUInteger UIKBKey_landscape_bgArea_tops[] = {0, 45, 85, 125};
static const NSUInteger UIKBKey_landscape_bgArea_heights[] = {45, 40, 40, 37};

#define UIKBKey_rows 4
#define UIKBKey_leftMargin 5

#define UIKBKey_orientationIndentRatio (49.f/32.f)

static const CGRect UIKBKey_PopBgArea_Left = {{-14, 0}, {79, 126}};
static const CGRect UIKBKey_PopBgArea_Right = {{9, 0}, {79, 126}};
static const CGRect UIKBKey_PopBgArea_Center1 = {{0, 0}, {114, 125}};

static const CGRect UIKBKey_Landscape_PopBgArea_Left = {{-14, 0}, {85, 126}};
static const CGRect UIKBKey_Landscape_PopBgArea_Right = {{9, 0}, {85, 126}};
static const CGRect UIKBKey_Landscape_PopBgArea_Center1 = {{0, 0}, {114, 125}};

#define UIKBKey_PopBgArea_Center2_height 120
#define UIKBKey_PopBgArea_EdgeTolerance 12

#define UIKBKey_PopPadding_height (-8)
#define UIKBKey_PopPadding_PortraitLeft_width 0
#define UIKBKey_PopPadding_PortraitRight_width 4
#define UIKBKey_PopPadding_LandscapeLeft_width 2
#define UIKBKey_PopPadding_LandscapeRight_width 3
#define UIKBKey_PopPadding_Portrait_y (-8)
#define UIKBKey_PopPadding_Landscape_y (-1)
#define UIKBKey_PopPadding_PortraitLeft_x 10
#define UIKBKey_PopPadding_PortraitRight_x (-13)
#define UIKBKey_PopPadding_LandscapeLeft_x 0
#define UIKBKey_PopPadding_LandscapeRight_x (-4)

#define UIKBKey_Accent_Portrait_DeltaY (-58)
#define UIKBKey_Accent_Landscape_DeltaY (-69)
#define UIKBKey_Accent_Portrait_Spacing 54
#define UIKBKey_Accent_Landscape_Spacing 40

#define UIKBKey_Accent_Portrait_height 122
#define UIKBKey_Accent_Landscape_height 114

static const CGRect UIKBKey_Shift_Portrait_Rect = {{0, 118}, {48, 54}};
static const CGRect UIKBKey_Shift_Landscape_Rect = {{0, 85}, {76, 40}};
static const CGRect UIKBKey_Delete_Portrait_Rect = {{0, 118}, {38, 54}};
static const CGRect UIKBKey_Delete_Landscape_Rect = {{0, 85}, {76, 40}};
static const CGRect UIKBKey_Delete_Portrait_PopBgRect = {{280, 119}, {40, 41}};
static const CGRect UIKBKey_Delete_Landscape_PopBgRect = {{9, -1}, {0, 0}};
#define UIKBKey_Delete_Portrait_PopPaddingY (-12)
#define UIKBKey_Delete_Landscape_PopPaddingY (-10)
static const CGRect UIKBKey_International_Portrait_Rect = {{0, 172}, {80, 44}};
static const CGRect UIKBKey_International_Landscape_Rect = {{0, 125}, {99, 37}};
static const CGRect UIKBKey_Space_Portrait_Rect = {{80, 172}, {160, 44}};
static const CGRect UIKBKey_Space_Landscape_Rect = {{99, 125}, {283, 37}};
static const CGRect UIKBKey_Return_Portrait_Rect = {{240, 172}, {80, 44}};
static const CGRect UIKBKey_Return_Landscape_Rect = {{382, 125}, {98, 37}};

static const CGPoint UIKBKey_ABC_Portrait_Painter = {0, 173};
static const CGPoint UIKBKey_ABC_Landscape_Painter = {0, 124};
static const CGPoint UIKBKey_International_Portrait_Painter = {43, 173};
static const CGPoint UIKBKey_International_Landscape_Painter = {52, 124};

#pragma mark -
#pragma mark Auxiliary Classes and Functions

@interface UIKBKeyTexts : NSObject {
	NSString* text;
	NSString* label;
	NSString* popup;
}
@property(copy) NSString* text;
@property(copy) NSString* label;
@property(copy) NSString* popup;
+(UIKBKeyTexts*)textsEmpty;
+(UIKBKeyTexts*)textsWithText:(NSString*)txt;
+(UIKBKeyTexts*)textsWithText:(NSString*)txt label:(NSString*)lbl popup:(NSString*)pop;
@end
@implementation UIKBKeyTexts
@synthesize text, label, popup;
+(UIKBKeyTexts*)textsEmpty { return [UIKBKeyTexts textsWithText:@"" label:nil popup:nil]; }
+(UIKBKeyTexts*)textsWithText:(NSString*)txt { return [UIKBKeyTexts textsWithText:txt label:txt popup:txt]; }
+(UIKBKeyTexts*)textsWithText:(NSString*)txt label:(NSString*)lbl popup:(NSString*)pop {
	UIKBKeyTexts* this = [[[UIKBKeyTexts alloc] init] autorelease];
	this.text = txt;
	this.label = lbl;
	this.popup = pop;
	return this;
}
@end



NSArray* getItem (NSDictionary* majorDict, NSString* kbTypeKey, NSString* textTypeKey, NSUInteger itemIndex, NSUInteger maxResolveDepth) {
	// reaches max recursion limit. just give up.
	if (maxResolveDepth == 0)
		return nil;
	
	NSDictionary* kbDict = [majorDict objectForKey:kbTypeKey];
	if (![kbDict isKindOfClass:[NSDictionary class]])
		return nil;
	NSArray* textArray = [kbDict objectForKey:textTypeKey];
	
	// total reference.
	if ([textArray isKindOfClass:[NSString class]]) {
		if ([(NSString*)textArray hasPrefix:@"="]) {
			return getItem(majorDict, [(NSString*)textArray substringFromIndex:1], textTypeKey, itemIndex, maxResolveDepth-1);
		} else
			return nil;
	} else if (![textArray isKindOfClass:[NSArray class]]) {
		return nil;
	}
	
	if (itemIndex >= [textArray count])
		return nil;
	
	NSArray* retval = [textArray objectAtIndex:itemIndex];
	// partial reference.
	if ([retval isKindOfClass:[NSString class]]) {
		if ([(NSString*)retval hasPrefix:@"="]) {
			return getItem(majorDict, [(NSString*)retval substringFromIndex:1], textTypeKey, itemIndex, maxResolveDepth-1);
		} else
			return nil;
	} else if (![retval isKindOfClass:[NSArray class]]) {
		return nil;
	}
	
	return retval;
}

#pragma mark -
#pragma mark Main Implementation

@implementation UIKBStandardKeyboard

@synthesize hasSpaceKey, hasInternationalKey, hasReturnKey, hasShiftKey, hasDeleteKey;
@synthesize shiftKeyLeft, deleteKeyRight;
@synthesize shiftStyle, shiftKeyEnabled;
@synthesize keyboardAppearance, keyboardSize;

//-------------------------------------
// Obtain the keyboard image of this keyboard.
//-------------------------------------
@dynamic image, shiftImage;
-(UIImage*)imageIsShifted:(BOOL)shifted {
	CGRect frm = CGRectMake(0, 0, keyboardSize.width, keyboardSize.height);
	
	UIGraphicsBeginImageContext(keyboardSize);
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	
    CGContextClearRect(ctx, frm);
	
	UIImage* bgImage = UIKBGetImage(UIKBImageBackground, keyboardAppearance, landscape);
	[bgImage drawInRect:frm];
	
	NSUInteger height;
	const NSUInteger* tops;
	if (landscape) {
		tops = UIKBKey_landscape_tops;
		height = UIKBKey_landscape_height;
	} else {
		tops = UIKBKey_tops;
		height = UIKBKey_height;
	}
	
	// TODO: Allow customization of label font.
	UIFont* labelFont = [UIFont boldSystemFontOfSize:fontSize];
	
	NSMutableArray** myTexts = shifted ? shiftedTexts : texts;
	
	for (NSUInteger row = 0; row < UIKBKey_rows; ++ row) {
		NSUInteger curleft = lefts[row];
		if (landscape)
			curleft += UIKBKey_leftMargin;
		
		UIImage* keyImg = UIKBGetImage(UIKBImageRow0+row, keyboardAppearance, landscape);
		
		CGRect imageFrame = CGRectMake(0, tops[row], widths[row], height);
		
		for (NSUInteger i = 0; i < counts[row]; ++i, curleft += widths[row]) {
			imageFrame.origin.x = curleft;
			[keyImg drawInRect:imageFrame blendMode:kCGBlendModeCopy alpha:1];
			
			NSString* lbl = ((UIKBKeyTexts*)[myTexts[row] objectAtIndex:i]).label;
			
			// TODO: Allow customization of label color.
			[[UIColor blackColor] setFill];
			drawInCenter(lbl, CGRectInset(imageFrame, UIKBKey_Padding, UIKBKey_Padding), labelFont);
		}
	}
	
	// draw shift key & etc.
	if (hasShiftKey) {
		UIImage* shiftImg;
		if (!shiftKeyEnabled) {
			shiftImg = UIKBGetImage(UIKBImageShiftDisabled, keyboardAppearance, landscape);
		} else if (shiftStyle == UIKBShiftStyle123) {
			shiftImg = UIKBGetImage(UIKBImageShiftSymbol, keyboardAppearance, landscape);
		} else {
			shiftImg = UIKBGetImage(UIKBImageShift, keyboardAppearance, landscape);
		}
		CGBlendMode blendMode = shiftKeyEnabled ? kCGBlendModeCopy : kCGBlendModeNormal;
		[shiftImg drawAtPoint:CGPointMake(shiftKeyLeft + (landscape ? UIKBKey_leftMargin : 0), tops[2]) blendMode:blendMode alpha:1];
	}
	
	if (hasDeleteKey) {
		UIImage* deleteImg = UIKBGetImage(UIKBImageDelete, keyboardAppearance, landscape);
		[deleteImg drawAtPoint:CGPointMake(keyboardSize.width - deleteImg.size.width - deleteKeyRight, tops[2])];
	}
	
	if (hasInternationalKey) {
		UIImage* abcImg = UIKBGetImage(UIKBImageABC, keyboardAppearance, landscape);
		[abcImg drawAtPoint:(landscape ? UIKBKey_ABC_Landscape_Painter : UIKBKey_ABC_Portrait_Painter)];
		UIImage* intlImg = UIKBGetImage(UIKBImageInternational, keyboardAppearance, landscape);
		[intlImg drawAtPoint:(landscape ? UIKBKey_International_Landscape_Painter : UIKBKey_International_Portrait_Painter)];
	}
	
	if (hasSpaceKey) {
		UIImage* spaceImg = UIKBGetImage(UIKBImageSpace, keyboardAppearance, landscape);
		[spaceImg drawAtPoint:(landscape ? UIKBKey_Space_Landscape_Rect.origin : UIKBKey_Space_Portrait_Rect.origin)];
	}
	
	if (hasReturnKey) {
		UIImage* returnImg = UIKBGetImage(UIKBImageReturn, keyboardAppearance, landscape);
		[returnImg drawAtPoint:(landscape ? UIKBKey_Return_Landscape_Rect.origin : UIKBKey_Return_Portrait_Rect.origin)];
	}
	
	UIImage* retImg = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return retImg;
}
-(UIImage*)image { return [self imageIsShifted:NO]; }
-(UIImage*)shiftImage { return [self imageIsShifted:YES]; }

//-------------------------------------
// Obtain the pop-up characters map of this keyboard.
//-------------------------------------
@dynamic fgImage, fgShiftImage;
-(UIImage*)fgImageIsShifted:(BOOL)shifted {
	NSUInteger totalCount = 0;
	for (NSUInteger row = 0; row < UIKBKey_rows; ++ row)
		totalCount += counts[row];
	if (totalCount == 0)
		return nil;
	
	CGFloat maxWidth = UIKBKeyPopupSize.width;
	for (NSUInteger row = 0; row < UIKBKey_rows; ++ row)
		if (widths[row] > maxWidth+2*UIKBKey_Padding)
			maxWidth = widths[row]-2*UIKBKey_Padding;
	
	CGSize imgSize = CGSizeMake(maxWidth, totalCount*UIKBKeyPopupSize.height);
	
	UIGraphicsBeginImageContext(imgSize);
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	CGContextClearRect(ctx, CGRectMake(0, 0, imgSize.width, imgSize.height));
	
	NSMutableArray** myTexts = shifted ? shiftedTexts : texts;
	// TODO: Allow customization of popup character font & color.
	UIFont* defaultFont = [UIFont boldSystemFontOfSize:UIKBKeyPopupMaxFontSize];
	
	CGRect imgRect = CGRectMake(0, 0, 0, UIKBKeyPopupSize.height);
	for (NSUInteger row = 0; row < UIKBKey_rows; ++ row) {
		imgRect.size.width = widths[row] > UIKBKeyPopupSize.width+2*UIKBKey_Padding ? widths[row]-2*UIKBKey_Padding : UIKBKeyPopupSize.width;
		for (NSUInteger col = 0; col < counts[row]; ++ col) {
			NSString* pop = ((UIKBKeyTexts*)[myTexts[row] objectAtIndex:col]).popup;
			drawInCenter(pop, imgRect, defaultFont);
			imgRect.origin.y += UIKBKeyPopupSize.height;
		}
	}
	
	UIImage* retval = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return retval;
}
-(UIImage*)fgImage { return [self fgImageIsShifted:NO]; }
-(UIImage*)fgShiftImage { return [self fgImageIsShifted:YES]; }

//-------------------------------------
// Update the metrics.
//-------------------------------------
-(void)updateArrangment {
	CGFloat fullwidths[UIKBKey_rows];
	CGFloat curWidth = keyboardSize.width;
	if (landscape)
		curWidth -= 2*UIKBKey_leftMargin;
	
	for (NSUInteger i = 0; i < UIKBKey_rows; ++ i)
		fullwidths[i] = curWidth;
	
	fontSize = UIKBKeyMaxFontSize;
	
	for (NSUInteger row = 0; row < UIKBKey_rows; ++ row)
		fullwidths[row] -= 2*lefts[row];
	
	// compute required button widths
	for (NSUInteger row = 0; row < UIKBKey_rows; ++ row) {
		if (counts[row] == 0)
			widths[row] = 0;
		else {
			// the font size of the label is taken as the minimal from the widths.
			widths[row] = (NSUInteger)round(fullwidths[row]/counts[row]);
			CGFloat candidateFontSize = widths[row] * UIKBKeyFontSizeMultiplier;
			if (candidateFontSize < fontSize)
				fontSize = candidateFontSize;
		}
	}
}

//-------------------------------------
// Whether the keyboard is landscape. Updates metric while setting.
//-------------------------------------
@synthesize landscape;
-(void)setLandscape:(BOOL)landsc {
	if (landscape != landsc) {
		// attempt fix the lefts & widths.
		if (landsc) {
			for (NSUInteger i = 0; i < UIKBKey_rows; ++ i)
				lefts[i] = (NSUInteger)round(lefts[i] * UIKBKey_orientationIndentRatio);
			shiftKeyLeft = (NSUInteger)round(shiftKeyLeft * UIKBKey_orientationIndentRatio);
			deleteKeyRight = (NSUInteger)round(deleteKeyRight * UIKBKey_orientationIndentRatio);
			keyboardSize = [UIKeyboardImpl defaultSizeForOrientation:90];
		} else {
			for (NSUInteger i = 0; i < UIKBKey_rows; ++ i)
				lefts[i] = (NSUInteger)round(lefts[i] / UIKBKey_orientationIndentRatio);
			shiftKeyLeft = (NSUInteger)round(shiftKeyLeft / UIKBKey_orientationIndentRatio);
			deleteKeyRight = (NSUInteger)round(deleteKeyRight / UIKBKey_orientationIndentRatio);
			keyboardSize = [UIKeyboardImpl defaultSizeForOrientation:0];
		}
		
		landscape = landsc;
		[self updateArrangment];
	}
}

//-------------------------------------
// Set keyboard arrangments.
//-------------------------------------
-(void)setArrangement:(UIKBKeyboardArrangement)arrangement {
	[self setArrangementWithRow0:(arrangement&0xFF) row1:((arrangement >> 8)&0xFF) row2:((arrangement>>16) & 0xFF) row3:((arrangement>>24)&0xFF)];
}
-(void)setArrangementWithRow0:(NSUInteger)count0 row1:(NSUInteger)count1 row2:(NSUInteger)count2 row3:(NSUInteger)count3 {
	counts[0] = count0;
	counts[1] = count1;
	counts[2] = count2;
	counts[3] = count3;
	
	// avoid index out of range by adding placeholder objects.
	for (NSUInteger row = 0; row < UIKBKey_rows; ++ row) {
		for (NSUInteger lblcnt = [texts[row] count]; lblcnt < counts[row]; ++lblcnt) {
			[texts[row] addObject:[UIKBKeyTexts textsEmpty]];
			[shiftedTexts[row] addObject:[UIKBKeyTexts textsEmpty]]; 
		}
	}
	
	[self updateArrangment];
}
-(void)setArrangementWithObject:(id)obj {
	UIKBKeyboardArrangement theArrangement = UIKBKeyboardArrangementEmpty;
	if ([obj isKindOfClass:[NSArray class]]) {
		NSUInteger objcounts[UIKBKey_rows];
		NSUInteger i = 0;
		for (; i < UIKBKey_rows; ++i)
			objcounts[i] = 0;
		i = 0;
		for (NSNumber* n in (NSArray*)obj) {
			objcounts[i] = [n unsignedIntegerValue];
			++ i;
			if (i >= UIKBKey_rows)
				break;
		}
		[self setArrangementWithRow0:objcounts[0] row1:objcounts[1] row2:objcounts[2] row3:objcounts[3]];
	} else if ([obj isKindOfClass:[NSString class]]) {
		NSString* str = obj;
		if ([str hasSuffix:@"|WithURLRow4"]) {
			theArrangement |= UIKBKeyboardArrangementWithURLRow4;
			str = [str substringToIndex:([str length]-12)];
		} else if ([str hasPrefix:@"WithURLRow4|"]) {
			theArrangement |= UIKBKeyboardArrangementWithURLRow4;
			str = [str substringFromIndex:12];
		}
		
		if ([str isEqualToString:@"AZERTY"]) {
			theArrangement |= UIKBKeyboardArrangementAZERTY;
		} else if ([str isEqualToString:@"Russian"]) {
			theArrangement |= UIKBKeyboardArrangementRussian;
		} else if ([str isEqualToString:@"Alt"]) {
			theArrangement |= UIKBKeyboardArrangementAlt;
		} else if ([str isEqualToString:@"URLAlt"]) {
			theArrangement |= UIKBKeyboardArrangementURLAlt;
		} else if ([str isEqualToString:@"JapaneseQWERTY"]) {
			theArrangement |= UIKBKeyboardArrangementJapaneseQWERTY;
		} else if ([str isEqualToString:@"WithURLRow4"]) {
			theArrangement |= UIKBKeyboardArrangementWithURLRow4;
		} else {
			theArrangement |= UIKBKeyboardArrangementDefault;
		}
		
		[self setArrangement:theArrangement];
	} else {
		[self setArrangement:UIKBKeyboardArrangementDefault];
	}
}

//-------------------------------------
// Set row indentations.
//-------------------------------------
-(void)setRowIndentation:(UIKBKeyboardRowIndentation)metrics {
	[self setRowIndentationWithRow0:(metrics&0xFF) row1:((metrics >> 8)&0xFF) row2:((metrics>>16) & 0xFF) row3:((metrics>>24)&0xFF)];
}
-(void)setRowIndentationWithRow0:(NSUInteger)left0 row1:(NSUInteger)left1 row2:(NSUInteger)left2 row3:(NSUInteger)left3 {
	lefts[0] = left0;
	lefts[1] = left1;
	lefts[2] = left2;
	lefts[3] = left3;
	[self updateArrangment];
}
-(void)setRowIndentationWithObject:(id)obj {
	if ([obj isKindOfClass:[NSArray class]]) {
		NSUInteger objcounts[UIKBKey_rows];
		NSUInteger i = 0;
		for (; i < UIKBKey_rows; ++i)
			objcounts[i] = 0;
		i = 0;
		for (NSNumber* n in (NSArray*)obj) {
			objcounts[i] = [n unsignedIntegerValue];
			++ i;
			if (i >= UIKBKey_rows)
				break;
		}
		[self setRowIndentationWithRow0:objcounts[0] row1:objcounts[1] row2:objcounts[2] row3:objcounts[3]];
	} else if ([obj isKindOfClass:[NSString class]]) {
		NSString* str = obj;
		if ([str isEqualToString:@"TightestDefault"]) {
			[self setRowIndentation:(landscape ? UIKBKeyboardRowIndentationLandscapeTightestDefault : UIKBKeyboardRowIndentationTightestDefault)];
		} else if ([str isEqualToString:@"AZERTY"]) {
			[self setRowIndentation:(landscape ? UIKBKeyboardRowIndentationLandscapeAZERTY : UIKBKeyboardRowIndentationAZERTY)];
		} else if ([str isEqualToString:@"Alt"]) {
			[self setRowIndentation:(landscape ? UIKBKeyboardRowIndentationLandscapeAlt : UIKBKeyboardRowIndentationAlt)];
		} else if ([str isEqualToString:@"Russian"]) {
			[self setRowIndentation:(landscape ? UIKBKeyboardRowIndentationLandscapeRussian : UIKBKeyboardRowIndentationRussian)];
		} else {
			[self setRowIndentation:(landscape ? UIKBKeyboardRowIndentationLandscapeDefault : UIKBKeyboardRowIndentationDefault)];
		}
	} else {
		[self setRowIndentation:(landscape ? UIKBKeyboardRowIndentationLandscapeDefault : UIKBKeyboardRowIndentationDefault)];
	}
}

//-------------------------------------
// Set texts for a single key.
//-------------------------------------
-(void)setText:(NSString*)txt forRow:(NSUInteger)row column:(NSUInteger)col {
	NSString* upper = txt;
	if ([txt length] == 1)
		upper = [txt uppercaseString];
	[self setText:txt label:upper popup:upper shifted:upper shiftedLabel:upper shiftedPopup:upper forRow:row column:col];
}
-(void)setText:(NSString*)txt shifted:(NSString*)shift forRow:(NSUInteger)row column:(NSUInteger)col {
	NSString* upper1 = txt;
	if ([txt length] == 1)
		upper1 = [txt uppercaseString];
	NSString* upper2 = shift;
	if ([shift length] == 1)
		upper2 = [shift uppercaseString];
	[self setText:txt label:upper1 popup:upper1 shifted:shift shiftedLabel:upper2 shiftedPopup:upper2 forRow:row column:col];
}
-(void)setText:(NSString*)txt label:(NSString*)lbl popup:(NSString*)pop forRow:(NSUInteger)row column:(NSUInteger)col {
	NSString* upper = txt;
	if ([txt length] == 1)
		upper = [txt uppercaseString];
	[self setText:txt label:lbl popup:pop shifted:upper shiftedLabel:lbl shiftedPopup:pop forRow:row column:col];
}
-(void)setText:(NSString*)txt label:(NSString*)lbl popup:(NSString*)pop shifted:(NSString*)shift shiftedLabel:(NSString*)sfl shiftedPopup:(NSString*)sfp forRow:(NSUInteger)row column:(NSUInteger)col {
	if (row > UIKBKey_rows || col > counts[row])
		return;
	[texts[row] replaceObjectAtIndex:col withObject:[UIKBKeyTexts textsWithText:txt label:lbl popup:pop]];
	[shiftedTexts[row] replaceObjectAtIndex:col withObject:[UIKBKeyTexts textsWithText:shift label:sfl popup:sfp]];
}

//-------------------------------------
// Set texts for the whole row.
//-------------------------------------
-(void)setTexts:(NSArray*)txts forRow:(NSUInteger)row {
	NSUInteger col = 0;
	for (NSString* txt in txts) {
		if (col < counts[row])
			[self setText:txt forRow:row column:col];
		else
			break;
		++ col;
	}
	for (; col < counts[row]; ++ col) {
		[self setText:@"" label:nil popup:nil shifted:@"" shiftedLabel:nil shiftedPopup:nil forRow:row column:col];
	}
}
-(void)setTexts:(NSArray*)txts shiftedTexts:(NSArray*)sfts forRow:(NSUInteger)row {
	NSUInteger txtCount = [txts count], sftCount = [sfts count];
	for (NSUInteger col = 0; col < counts[row]; ++ col) {
		NSString* txt = col < txtCount ? [txts objectAtIndex:col] : nil;
		NSString* sft = col < sftCount ? [sfts objectAtIndex:col] : [txt uppercaseString];
		if (txt == nil) {
			if (sft == nil) {
				[self setText:@"" label:nil popup:nil shifted:@"" shiftedLabel:nil shiftedPopup:nil forRow:row column:col];
				continue;
			} else
				txt = [sft lowercaseString];
		}
		[self setText:txt shifted:sft forRow:row column:col];
	}
}

//-------------------------------------
// Initializers & deallocators.
//-------------------------------------
-(void)dealloc {
	for (NSUInteger i = 0; i < UIKBKey_rows; ++i) {
		[texts[i] release];
		[shiftedTexts[i] release];
	}
	[super dealloc];
}

-(UIKBStandardKeyboard*)init {
	if ((self = [super init])) {
		for (NSUInteger row = 0; row < UIKBKey_rows; ++ row) {
			texts[row] = [[NSMutableArray alloc] init];
			shiftedTexts[row] = [[NSMutableArray alloc] init];
		}
		hasShiftKey = hasInternationalKey = hasReturnKey = hasSpaceKey = hasDeleteKey = YES;
		shiftKeyEnabled = YES;
		shiftKeyLeft = deleteKeyRight = 0;
		shiftStyle = UIKBShiftStyleDefault;
	}
	return self;
}
+(UIKBStandardKeyboard*) keyboardWithLandscape:(BOOL)landsc appearance:(UIKeyboardAppearance)appr arrangement:(UIKBKeyboardArrangement)arrangement rowIndentation:(UIKBKeyboardRowIndentation)metrics {
	UIKBStandardKeyboard* myKeyboard = [[[UIKBStandardKeyboard alloc] init] autorelease];
	myKeyboard->keyboardAppearance = appr;
	myKeyboard->landscape = landsc;
	myKeyboard->keyboardSize = [UIKeyboardImpl defaultSizeForOrientation:(landsc ? 90 : 0)];
	[myKeyboard setArrangement:arrangement];
	[myKeyboard setRowIndentation:metrics];
	return myKeyboard;
}

//-------------------------------------
// Return an NSArray of UIKBKeyDefinition's.
//-------------------------------------
@dynamic keyDefinitions;
-(NSArray*)keyDefinitions {
	NSMutableArray* retarr = [[[NSMutableArray alloc] init] autorelease];
	
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	UIKBKeyDefinition* keydef = [[UIKBKeyDefinition alloc] init];
	
	CGFloat leftEdge = landscape ? UIKBKey_leftMargin : 0;
	
	CGFloat fgTop = 0, fgWidth;
	CGFloat popPadding_y = landscape ? UIKBKey_PopPadding_Landscape_y : UIKBKey_PopPadding_Portrait_y;
	CGFloat accentDelta = landscape ? UIKBKey_Accent_Landscape_DeltaY : UIKBKey_Accent_Portrait_DeltaY;
	CGFloat accentHeight = landscape ? UIKBKey_Accent_Landscape_height : UIKBKey_Accent_Portrait_height;
	CGFloat accentSpacing = landscape ? UIKBKey_Accent_Landscape_Spacing : UIKBKey_Accent_Portrait_Spacing;
	
	for (NSUInteger row = 0; row < UIKBKey_rows; ++ row) {
		CGFloat curLeft = lefts[row] + leftEdge;
		CGFloat curTop, curHeight;
		fgWidth = widths[row]>UIKBKeyPopupSize.width+2*UIKBKey_Padding?widths[row]-2*UIKBKey_Padding:UIKBKeyPopupSize.width;
		
		if (landscape) {
			curTop = UIKBKey_landscape_bgArea_tops[row];
			curHeight = UIKBKey_landscape_bgArea_heights[row];
		} else {
			curTop = UIKBKey_bgArea_tops[row];
			curHeight = UIKBKey_bgArea_heights[row];
		}
			
		for (NSUInteger col = 0; col < counts[row]; ++ col) {
			keydef->bg_area = CGRectMake(curLeft, curTop, widths[row], curHeight);
			keydef->pop_char_area = CGRectMake(0, fgTop, fgWidth, UIKBKeyPopupSize.height);
						
			if (widths[row] >= UIKBKeyPopupSize.width+UIKBKey_Padding) {
				keydef->pop_bg_area = CGRectMake(0, 0, widths[row]+36, UIKBKey_PopBgArea_Center2_height);
				keydef->pop_type = UIKeyboardPopImageCenter2;
				keydef->pop_padding = CGRectZero;
			} else {
				if (curLeft - leftEdge < UIKBKey_PopBgArea_EdgeTolerance) {
					keydef->pop_bg_area = landscape ? UIKBKey_Landscape_PopBgArea_Left : UIKBKey_PopBgArea_Left;
					keydef->pop_type = UIKeyboardPopImageLeft;
					keydef->pop_padding = CGRectMake(
													landscape?UIKBKey_PopPadding_LandscapeLeft_x:UIKBKey_PopPadding_PortraitLeft_x,
													popPadding_y,
													landscape?UIKBKey_PopPadding_LandscapeLeft_width:UIKBKey_PopPadding_PortraitLeft_width,
													UIKBKey_PopPadding_height
													);
				} else if (keyboardSize.width - curLeft - widths[row] - leftEdge < UIKBKey_PopBgArea_EdgeTolerance) {
					keydef->pop_bg_area = landscape ? UIKBKey_Landscape_PopBgArea_Right : UIKBKey_PopBgArea_Right;
					keydef->pop_type = UIKeyboardPopImageRight;
					keydef->pop_padding = CGRectMake(
													landscape?UIKBKey_PopPadding_LandscapeRight_x:UIKBKey_PopPadding_PortraitRight_x,
													popPadding_y,
													landscape?UIKBKey_PopPadding_LandscapeRight_width:UIKBKey_PopPadding_PortraitRight_width,
													UIKBKey_PopPadding_height
													);
				} else {
					keydef->pop_bg_area = landscape ? UIKBKey_Landscape_PopBgArea_Center1 : UIKBKey_PopBgArea_Center1;
					keydef->pop_type = UIKeyboardPopImageCenter1;
					keydef->pop_padding = CGRectMake(0, popPadding_y, 0, UIKBKey_PopPadding_height);
				}
			}
			
			keydef->accent_frame = CGRectMake(curLeft, row*accentSpacing+accentDelta, widths[row], accentHeight);
			
			NSString* kvalue = ((UIKBKeyTexts*)[texts[row] objectAtIndex:col]).text;
			
			keydef.value = kvalue;
			keydef.shifted = ((UIKBKeyTexts*)[shiftedTexts[row] objectAtIndex:col]).text;
			
			keydef->down_flags = UIKeyFlagActivateKey | UIKeyFlagPlaySound;
			keydef->up_flags = UIKeyFlagOutputValue | UIKeyFlagDeactivateKey;
			keydef->key_type = UIKeyTypeNormal;
			if ([kvalue isEqualToString:@" "]) {
				keydef->key_type = UIKeyTypeSpace;
				keydef->up_flags |= UIKeyFlagSwitchPlane;
			} else if ([kvalue isEqualToString:@"\n"]) {
				keydef->key_type = UIKeyTypeReturn;
				keydef->up_flags |= UIKeyFlagSwitchPlane;
			}
			
			curLeft += widths[row];
			fgTop += UIKBKeyPopupSize.height;
						
			UIKBKeyDefinition* newKey = [keydef copy];
			[retarr addObject:newKey];
			[newKey release];
		}
	}
	
	keydef->pop_type = nil;
	keydef->pop_char_area = keydef->accent_frame = keydef->pop_padding = CGRectZero;
	
	if (hasShiftKey && shiftKeyEnabled) {
		keydef->bg_area = landscape ? UIKBKey_Shift_Landscape_Rect : UIKBKey_Shift_Portrait_Rect;
		keydef->bg_area.origin.x = shiftKeyLeft;
		keydef->pop_bg_area = CGRectZero;
		keydef.value = @"shift";
		keydef.shifted = @"shift";
		keydef->down_flags = UIKeyFlagShiftKey | UIKeyFlagPlaySound;
		keydef->up_flags = 0;
		keydef->key_type = UIKeyTypeShift;
		[retarr addObject:[[keydef copy] autorelease]];
	}
	
	if (hasDeleteKey) {
		if (landscape) {
			keydef->bg_area = UIKBKey_Delete_Landscape_Rect;			
			keydef->pop_bg_area = UIKBKey_Delete_Landscape_PopBgRect;
		} else {
			keydef->bg_area = UIKBKey_Delete_Portrait_Rect;
			keydef->pop_bg_area = UIKBKey_Delete_Portrait_PopBgRect;			// the composite is - holy gosh - kb-std-active-bg-main.png
		}
		keydef->bg_area.origin.x = keyboardSize.width - deleteKeyRight - keydef->bg_area.size.width;
		if (!landscape) {
			keydef->pop_padding.origin.y = UIKBKey_Delete_Portrait_PopPaddingY;
		} else {
			keydef->pop_padding.origin.y = UIKBKey_Delete_Landscape_PopPaddingY;
		}
		keydef.value = @"delete";
		keydef.shifted = @"delete";
		keydef->down_flags = UIKeyFlagDeleteKey | UIKeyFlagPlaySound | UIKeyFlagActivateKey;
		keydef->up_flags = UIKeyFlagStopAutoDelete | UIKeyFlagDeactivateKey;
		keydef->key_type = UIKeyTypeDelete;
		[retarr addObject:[[keydef copy] autorelease]];
	}
	
	if (hasInternationalKey) {
		if (landscape) {
			keydef->bg_area = UIKBKey_International_Landscape_Rect;
			keydef->pop_bg_area = CGRectZero;
		} else {
			keydef->pop_bg_area = keydef->bg_area = UIKBKey_International_Portrait_Rect;
		}
		keydef.value = @"more";
		keydef.shifted = @"more";
		keydef->down_flags = UIKeyFlagInternationalKey | UIKeyFlagPlaySound;
		keydef->up_flags = UIKeyFlagChangeInputMode;
		keydef->key_type = UIKeyTypeInternational;
		[retarr addObject:[[keydef copy] autorelease]];
	}
	
	if (hasSpaceKey) {
		if (landscape) {
			keydef->bg_area = UIKBKey_Space_Landscape_Rect;
			keydef->pop_bg_area = CGRectZero;
		} else {
			keydef->pop_bg_area = keydef->bg_area = UIKBKey_Space_Portrait_Rect;
		}
		keydef.value = @" ";
		keydef.shifted = @" ";
		keydef->down_flags = UIKeyFlagActivateKey | UIKeyFlagPlaySound;
		keydef->up_flags = UIKeyFlagOutputValue | UIKeyFlagDeactivateKey | UIKeyFlagSwitchPlane;
		keydef->key_type = UIKeyTypeSpace;
		[retarr addObject:[[keydef copy] autorelease]];
	}
	
	if (hasReturnKey) {
		if (landscape) {
			keydef->bg_area = UIKBKey_Return_Landscape_Rect;
			keydef->pop_bg_area = CGRectZero;
		} else {
			keydef->pop_bg_area = keydef->bg_area = UIKBKey_Return_Portrait_Rect;
		}
		keydef.value = @"\n";
		keydef.shifted = @"\n";
		keydef->down_flags = UIKeyFlagActivateKey | UIKeyFlagPlaySound;
		keydef->up_flags = UIKeyFlagOutputValue | UIKeyFlagDeactivateKey | UIKeyFlagSwitchPlane;
		keydef->key_type = UIKeyTypeReturn;
		[retarr addObject:[[keydef copy] autorelease]];
	}
	
	[keydef release];
	[pool drain];
	
	return retarr;
}

//-------------------------------------
// Create keyboard from bundle.
//-------------------------------------
+(UIKBStandardKeyboard*)keyboardWithBundle:(KeyboardBundle*)bdl name:(NSString*)name landscape:(BOOL)landsc appearance:(UIKeyboardAppearance)appr {
	// obtain layout name from bundle
	NSString* layoutName = [bdl objectForInfoDictionaryKey:@"UIKeyboardLayoutClass"];
	if (![layoutName isKindOfClass:[NSString class]])
		return nil;
	
	NSString* layoutPath = [bdl pathForResource:layoutName ofType:nil];
	if (layoutPath == nil)
		return nil;
	
	NSDictionary* layoutDict = [NSDictionary dictionaryWithContentsOfFile:layoutPath];
	NSDictionary* layoutDefinitions = [layoutDict objectForKey:name];
	if (layoutDefinitions == nil)
		return nil;
	
	UIKBStandardKeyboard* retval = [[[UIKBStandardKeyboard alloc] init] autorelease];
	retval->keyboardAppearance = appr;
	retval->landscape = NO;
	retval->keyboardSize = [UIKeyboardImpl defaultSizeForOrientation:(landsc ? 90 : 0)];
	
	[retval setArrangementWithObject:[layoutDefinitions objectForKey:@"arrangement"]];
	[retval setRowIndentationWithObject:[layoutDefinitions objectForKey:@"rowIndentation"]];
		
	// obtain texts & shifts.
	for (NSUInteger i = 0; i < UIKBKey_rows; ++ i) {
		// TODO: This "8" recursion limit may be customized.
		// TODO: Support custom label text & popup character text as well.
		NSArray* text = getItem(layoutDict, name, @"texts", i, 8);
		NSArray* shiftedText = getItem(layoutDict, name, @"shiftedTexts", i, 8);
		
		if (shiftedText == nil) {
			[retval setTexts:text forRow:i];
		} else {
			[retval setTexts:text shiftedTexts:shiftedText forRow:i];
		}
	}
	
	// obtain other properties.
	NSNumber* val;
	val = [layoutDefinitions objectForKey:@"hasSpaceKey"];
	if ([val isKindOfClass:[NSNumber class]] || [val isKindOfClass:[NSString class]]) retval->hasSpaceKey = [val boolValue];
	
	val = [layoutDefinitions objectForKey:@"hasInternationalKey"];
	if ([val isKindOfClass:[NSNumber class]] || [val isKindOfClass:[NSString class]]) retval->hasInternationalKey = [val boolValue];
	
	val = [layoutDefinitions objectForKey:@"hasReturnKey"];
	if ([val isKindOfClass:[NSNumber class]] || [val isKindOfClass:[NSString class]]) retval->hasReturnKey = [val boolValue];
	
	val = [layoutDefinitions objectForKey:@"hasShiftKey"];
	if ([val isKindOfClass:[NSNumber class]] || [val isKindOfClass:[NSString class]]) retval->hasShiftKey = [val boolValue];
	
	val = [layoutDefinitions objectForKey:@"hasDeleteKey"];
	if ([val isKindOfClass:[NSNumber class]] || [val isKindOfClass:[NSString class]]) retval->hasDeleteKey = [val boolValue];
	
	val = [layoutDefinitions objectForKey:@"shiftKeyLeft"];
	if ([val isKindOfClass:[NSNumber class]] || [val isKindOfClass:[NSString class]]) retval->shiftKeyLeft = [val floatValue];
	
	val = [layoutDefinitions objectForKey:@"deleteKeyRight"];
	if ([val isKindOfClass:[NSNumber class]] || [val isKindOfClass:[NSString class]]) retval->deleteKeyRight = [val floatValue];
	
	val = [layoutDefinitions objectForKey:@"shiftKeyEnabled"];
	if ([val isKindOfClass:[NSNumber class]] || [val isKindOfClass:[NSString class]]) retval->shiftKeyEnabled = [val boolValue];
	
	NSString* shst = [layoutDefinitions objectForKey:@"shiftStyle"];
	if ([shst isKindOfClass:[NSString class]]) {
		if ([shst isEqualToString:@"123"])
			retval->shiftStyle = UIKBShiftStyle123;
		else
			retval->shiftStyle = UIKBShiftStyleDefault;
	}
	
	retval.landscape = landsc;
	
	return retval;
}

@end
