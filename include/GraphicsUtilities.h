/*
 
 GraphicsUtilities.h ... Convenient functions for manipulating bitmaps
 
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

#ifndef GRAPHICSUTITLIES_H
#define GRAPHICSUTITLIES_H

#include <CoreGraphics/CoreGraphics.h>

@class UIImage;

typedef struct GUCaps {
	CGFloat left, right, top, bottom;
} GUCaps;

CG_INLINE
GUCaps GUCapsMake(CGFloat left, CGFloat right, CGFloat top, CGFloat bottom) {
	GUCaps retval;
	retval.left = left;
	retval.right = right;
	retval.top = top;
	retval.bottom = bottom;
	return retval;
}

#define GUCreateContextAgain(c, width, height) \
rgbColorSpace = CGColorSpaceCreateDeviceRGB(); \
CGContextRef c = CGBitmapContextCreate(NULL, (width), (height), 8, 4*(width), rgbColorSpace, kCGImageAlphaPremultipliedLast); \
CGColorSpaceRelease(rgbColorSpace)

#define GUCreateContext(c, width, height) CGColorSpaceRef GUCreateContextAgain(c, width, height)

CG_INLINE
CGContextRef GUCreateContextWithImage(CGImageRef img, CGRect* rect) {
	size_t w = CGImageGetWidth(img), h = CGImageGetHeight(img);
	*rect = CGRectMake(0, 0, w, h);
	GUCreateContext(c, w, h);
	return c;
}
#define GUCreateContextWithImageAuto(img) CGRect imgRect; CGContextRef c = GUCreateContextWithImage(img, &imgRect)

#define GULuminance(red,green,blue) (0.2126*(red) + 0.7152*(green) + 0.0722*(blue))

// The return values of all CGImageRef's must be CGImageRelease'd in the caller side.


// Place two subimages next to each other.
CGImageRef GUImageCreateByConcatSubimages(CGImageRef img,
										  CGRect subRect1,
										  CGRect subRect2,
										  bool tileVertically);	// true = 1 above 2; false = 1 on the left of 2

// Scale down the foreground image and place it on top of a subimage of the background.
// Pass NULL to background if you just want a rescaling.
CGImageRef GUImageCreateByComposition(CGImageRef foreground,
									  CGImageRef background,
									  CGRect fgRect,		// fgRect's coordinate is on the subimage.
									  CGRect bgSubRect);	// bgSubRect's coordinate in on the background.

#define GUImageCreateWithSubimageScale(img, newSize, subRect) GUImageCreateByComposition((img), NULL, (subRect), {CGPointZero, (newSize)})
#define GUImageCreateWithScale(img, newSize) GUImageCreateByComposition((img), NULL, CGRectMake(0, 0, CGImageGetWidth(img), CGImageGetHeight(img)), {CGPointZero, (newSize)})

// Copy a rect of the background to somewhere else in the same image to patch some irregularity.
CGImageRef GUImageCreateWithPatching(CGImageRef img, CGRect src, CGRect target);

// Apply mask to image.
// The size of mask & src must match.
CGImageRef GUImageCreateWithMask(CGImageRef src, CGImageRef mask);
CGImageRef GUImageCreateWithCappedMask(CGImageRef src, CGImageRef mask, GUCaps caps);

// Draw CGImage with stretching.
void GUDrawImageWithCaps(CGContextRef c, CGRect rect, CGImageRef img, GUCaps caps);
CGImageRef GUImageCreateWithCaps(CGImageRef img, CGRect rect, GUCaps caps);
#define GUResizeImageWithCaps(img, rect, caps) GUCreateUIImageAndRelease(GUImageCreateWithCaps((img).CGImage, (rect), (caps)))

// Get the mean luminance of the image, weighted by opacity (alpha channel).
float GUAverageLuminance (CGImageRef img);

// Create image from PNG file.
CGImageRef GUImageCreateWithPNG(const char* filename);

// Create an image with reduced brightness
CGImageRef GUImageCreateByReducingBrightness(CGImageRef img, CGFloat reductionRatio);

// Create a UIImage and release the original CGImage.
UIImage* GUCreateUIImageAndRelease(CGImageRef img);

// Create a rounded rectangle path
CGPathRef GUPathCreateRoundRect(CGRect rect, CGFloat radius);
CGImageRef GUImageCreateByClippingToRoundRect(CGImageRef img, CGRect rect, CGFloat radius);

#endif