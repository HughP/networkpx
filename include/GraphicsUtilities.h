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
CGContextRef c = CGBitmapContextCreate(NULL, (width), (height), 8, 4*(width), rgbColorSpace, kCGImageAlphaPremultipliedFirst); \
CGColorSpaceRelease(rgbColorSpace)

#define GUCreateContext(c, width, height) CGColorSpaceRef GUCreateContextAgain(c, width, height)

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

// Get the mean luminance of the image, weighted by opacity (alpha channel).
float GUAverageLuminance (CGImageRef img);

// Create image from PNG file.
CGImageRef GUImageCreateWithPNG(const char* filename);

// Create an image with reduced brightness
CGImageRef GUImageCreateByReducingBrightness(CGImageRef img, CGFloat reductionRatio);

// Create a UIImage and release the original CGImage.
UIImage* GUCreateUIImageAndRelease(CGImageRef img);

#endif