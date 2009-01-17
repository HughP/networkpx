/*
 
 ImageLoader.h ... Load predefined images for iKeyEx.
 
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
 

#import <UIKit/UITextInputTraits.h>
#include <stdlib.h>

@class UIImage;

typedef enum UIKBImageClassType {
	UIKBImageBackground,
	UIKBImageRow0,
	UIKBImageRow1,
	UIKBImageRow2,
	UIKBImageRow3,
	UIKBImageShift,
	UIKBImageShiftActive,
	UIKBImageShiftLocked,
	UIKBImageShiftDisabled,
	UIKBImageInternational,
	UIKBImageInternationalActive,
	UIKBImageSpace,
	UIKBImageSpaceActive,
	UIKBImageReturn,
	UIKBImageReturnActive,
	UIKBImageReturnBlue,
	UIKBImageDelete,
	UIKBImageDeleteActive,
	UIKBImageABC,
	UIKBImage123,
	UIKBImageShiftSymbol,
	UIKBImageShift123,
	UIKBImagePopupFlexible,
	UIKBImagePopupCenter,
	UIKBImagePopupLeft,
	UIKBImagePopupRight,
	UIKBImageActiveBackground,
	
	UIKBImageTypesCount
} UIKBImageClassType;

void UIKBInitializeImageCache();	// Call this before invoking any UIKBGetImage().
void UIKBClearImageCache();			// Call this when UIKBGetImage() is no longer needed. Any subsequent UIKBGetImage() call will be invalid. 
void UIKBReleaseImageCahce();		// Release the cache without invalidating the use of UIKBGetImage(). Call this to get some memory back.

// Get a predefined image.
UIImage* UIKBGetImage(UIKBImageClassType type, UIKeyboardAppearance appearance, BOOL landscape);