/*
 
 emojiComposer.m ... Compose an emoji-like image.
 
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

#import "emojiComposer.h"
#import <iKeyEx/common.h>
#import <UIKit/UIKit.h>

static const BOOL isWhite[] = {YES, NO};

UIImage* hCComposeEmoji(hCEmojiBackground background, NSBundle* bundle, int number) {
	NSString* numStr = [NSString stringWithFormat:@"%d", number];
	NSString* savePath = [NSString stringWithFormat:iKeyEx_CachePath@"hClipboard-emoji-bg%d-%@.png", background, numStr];
	UIImage* tryLoad = [UIImage imageWithContentsOfFile:savePath];
	if (tryLoad != nil)
		return tryLoad;
	CGRect rect = CGRectMake(0, 0, 24, 24);
	
	UIGraphicsBeginImageContext(rect.size);
	[[UIImage imageWithContentsOfFile:[bundle pathForResource:[NSString stringWithFormat:@"bg%d", background] ofType:@"png"]] drawInRect:rect];
	[(isWhite[background]?[UIColor whiteColor]:[UIColor blackColor]) setFill];
	drawInCenter(numStr, CGRectInset(rect, 3, 3), [UIFont fontWithName:@"Helvetica-Bold" size:14]);
	UIImage* retimg = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	[UIImagePNGRepresentation(retimg) writeToFile:savePath atomically:NO];
	
	return retimg;
}