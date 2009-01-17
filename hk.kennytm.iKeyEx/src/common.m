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

extern void drawInCenter(NSString* str, CGRect rect, UIFont* defaultFont) {
	// TODO: Rewrite this simple algorithm to utilize the rectangle space better.
	
	CGSize defSize = [str sizeWithFont:defaultFont];
	CGFloat paddingX, paddingY;
	CGFloat ratioX = rect.size.width / defSize.width, ratioY = rect.size.height / defSize.height;
	CGFloat ratio = ratioX;
	
	if (ratioY < ratioX)
		ratio = ratioY;
	if ([str length] == 1 || ratio > 1) {
		paddingX = (rect.size.width - defSize.width)/2;
		paddingY = (rect.size.height - defSize.height)/2;
		[str drawInRect:CGRectInset(rect, paddingX, paddingY) withFont:defaultFont];
	} else {
		UIFont* newFont = [defaultFont fontWithSize:(ratio*defaultFont.pointSize)];
		defSize = [str sizeWithFont:newFont];
		paddingX = (rect.size.width - defSize.width)/2;
		paddingY = (rect.size.height - defSize.height)/2;
		[str drawInRect:CGRectInset(rect, paddingX, paddingY) withFont:newFont];
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


extern NSString* iKeyExVersion () { return @"0.0-1"; }