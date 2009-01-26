/*
 
 common.m ... Miscellaneous functions for iKeyEx.
 
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

#import <iKeyEx/common.h>
#import <UIKit2/Functions.h>
#import <UIKit/UIGraphics.h>
#import <UIKit/UIStringDrawing.h>
#import <UIKit/UIFont.h>
#import <CoreGraphics/CGContext.h>
#include <pthread.h>
#import <objc/runtime.h>
#include <string.h>
#include <stdio.h>



static unsigned subclassSequence = 0;

CGSize computeActualSizeToFitRows(NSString* str, CGRect rect, UIFont* defaultFont, CGSize strSize, CGFloat rows) {
	CGFloat invRows = 1.f/rows;
	CGFloat predictedWidth = strSize.width * invRows;
	CGFloat targetHeight = rows*strSize.height;
	CGFloat widthAmendment = INFINITY;
	NSUInteger strLen = [str length];
	for (NSUInteger i = 0; i < strLen; ++ i) {
		CGFloat curWidth = [[str substringWithRange:NSMakeRange(i, 1)] sizeWithFont:defaultFont].width;
		if (curWidth < widthAmendment)
			widthAmendment = curWidth;
	}
	widthAmendment *= invRows;
	
	do {
		CGSize experimentalResult = [str sizeWithFont:defaultFont
									constrainedToSize:CGSizeMake(predictedWidth, FLT_MAX)
										lineBreakMode:UILineBreakModeWordWrap];
		CGFloat heightDifference = experimentalResult.height - targetHeight;
		
		// the height reaches target. Stop.
		if (heightDifference <= 0)
			return experimentalResult;
		
		// the height is >=2 rows too large. Enlarge the prediction at least by ((excessRows - 1) / rows)*predictedWidth
		else if (heightDifference > strSize.height)
			predictedWidth *= (experimentalResult.height/strSize.height - 1)*invRows;
		
		// the height is just 1 row too large.
		// take away 1 char at a time and see the effect.
		else
			predictedWidth += widthAmendment;
	} while (YES);
}

#import <UIKit/UIGeometry.h>
extern void drawInCenter(NSString* str, CGRect rect, UIFont* defaultFont) {
	NSUInteger strLen = [str length];
	CGSize strSize = [str sizeWithFont:defaultFont];
	
	// (1) Try to fit into 1 line.
	if (strLen == 1 || strSize.width <= rect.size.width) {
		UIFont* newFont;
		if (strSize.height >= rect.size.height)
			newFont = [defaultFont fontWithSize:defaultFont.pointSize*rect.size.height/strSize.height];
		else
			newFont = defaultFont;
		
		CGPoint p = CGPointMake(rect.origin.x+(rect.size.width-strSize.width)/2, rect.origin.y+(rect.size.height-strSize.height)/2);
		[str drawAtPoint:p withFont:defaultFont];
		
		// (2) Compute the number of rows required to minimize the area wasted.
	} else {
		// assume  w = strSize.width,    h = strSize.height,
		//        rw = rect.size.width, rh = rect.size.height
		//
		// ratio of area wasted of having N rows is
		//    = 1 - N^2 * rw/rh * h/w.
		// so the optimal number of rows is
		//   N = sqrt(w/h * rh/rw).
		
		CGFloat aspectRatioRatio = (strSize.width * rect.size.height) / (strSize.height * rect.size.width);
		CGFloat sqrtARR = sqrt(aspectRatioRatio);
		CGFloat rowCount = floor(sqrtARR);
		if (sqrtARR - rowCount > 0.7)
			rowCount += 1;
		
		CGSize size;
		
		if (rowCount == 1)
			size = strSize;
		else
			size = computeActualSizeToFitRows(str, rect, defaultFont, strSize, rowCount);
		size.width += 4;
		size.height += 4;
		
		CGFloat ratio = fmin(rect.size.width/size.width, rect.size.height/size.height);
		CGFloat xInset = (rect.size.width - ratio*size.width)/2;
		CGFloat yInset = (rect.size.height - ratio*size.height)/2;
		
		UIFont* newFont = [defaultFont fontWithSize:(ratio * defaultFont.pointSize)];
		[str drawInRect:CGRectInset(rect, xInset, yInset)
			   withFont:newFont
		  lineBreakMode:UILineBreakModeWordWrap
			  alignment:UITextAlignmentCenter];
	}
}

Class createSubclassCopy (Class superclass) {
	const char* clsName = class_getName(superclass);
	size_t newNameLen = strlen(clsName) + 10;
	char* newName = malloc(newNameLen+1);
	snprintf(newName, newNameLen, "%s%u", clsName, subclassSequence);
	++subclassSequence;
	Class newClass = objc_allocateClassPair(superclass, newName, 0);
	objc_registerClassPair(newClass);
	free(newName);
	return newClass;
}


extern NSString* iKeyExVersion () { return @"0.1-3"; }


#import <UIKit/UIView.h>
void UILogViewHierarchyWithDots(UIView* v, NSString* dots) {
	NSLog(@"%@%@\t(frame=%@)", dots, v, NSStringFromCGRect(v.frame));
	NSString* moreDots = [dots stringByAppendingString:@".."];
	for (UIView* w in v.subviews) {
		UILogViewHierarchyWithDots(w, moreDots);
	}
}

extern void UILogViewHierarchy (UIView* v) { UILogViewHierarchyWithDots(v, @""); }