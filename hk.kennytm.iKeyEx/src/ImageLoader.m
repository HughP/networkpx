/*
 
 ImageLoader.m ... Load predefined images for iKeyEx.
 
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

#import <iKeyEx/ImageLoader.h>
#import <UIKit2/Functions.h>
#import <UIKit2/UIKeyboardInputManager.h>
#import <UIKit/UIImage.h>
#import <UIKit/UIGraphics.h>
#import <CoreGraphics/CGGeometry.h>
#include <pthread.h>
#include <stdlib.h>

static UIImage* cache[4 * UIKBImageTypesCount];
static pthread_mutex_t mutexList[4 * UIKBImageTypesCount];
static pthread_mutex_t firstMutex = PTHREAD_MUTEX_INITIALIZER;

#define LOCK(x)   if(pthread_mutex_lock(&(x)))return 
#define UNLOCK(x) if(pthread_mutex_unlock(&(x)))return

#define WithLandscape UIKBImageTypesCount
#define WithTransparent (UIKBImageTypesCount*2)

//------------------------------------------------------------------------------
#pragma mark -
#pragma mark Constants
//------------------------------------------------------------------------------

static const CGRect BackgroundClipper1_Portrait = {{0, 0}, {1, 200}};
static const CGRect BackgroundClipper2_Portrait = {{0, 200}, {1, 16}};
static const CGPoint BackgroundPainter1_Portrait = {0, 0};
static const CGPoint BackgroundPainter2_Portrait = {-80, 0};

static const CGRect BackgroundClipper1_Landscape = {{0, 0}, {1, 140}};
static const CGRect BackgroundClipper2_Landscape = {{0, 140}, {1, 22}};
static const CGPoint BackgroundPainter1_Landscape = {0, 0};
static const CGPoint BackgroundPainter2_Landscape = {-100, 0};

static const CGRect KeyClipper1_Portrait = {{0, 0}, {7, 44}};
static const CGRect KeyClipper2_Portrait = {{7, 0}, {8, 44}};
static const CGPoint KeyRow0Painter1_Portrait = {0, -10};
static const CGPoint KeyRow0Painter2_Portrait = {-17, -10};
static const CGPoint KeyRow1Painter1_Portrait = {-16, -64};
static const CGPoint KeyRow1Painter2_Portrait = {-33, -64};
static const CGPoint KeyRow2Painter1_Portrait = {-48, -118};
static const CGPoint KeyRow2Painter2_Portrait = {-65, -118};
static const CGPoint KeyRow3Painter1_Portrait = {-80, -172};
static const CGPoint KeyRow3Painter2_Portrait = {-225, -172};

static const CGRect KeyClipper1_Landscape = {{0, 0}, {8, 38}};
static const CGRect KeyClipper2_Landscape = {{8, 0}, {9, 38}};
static const CGPoint KeyRow0Painter1_Landscape = {-5, -4};
static const CGPoint KeyRow0Painter2_Landscape = {-35, -4};
static const CGPoint KeyRow1Painter1_Landscape = {-29, -44};
static const CGPoint KeyRow1Painter2_Landscape = {-59, -44};
static const CGPoint KeyRow2Painter1_Landscape = {-76, -84};
static const CGPoint KeyRow2Painter2_Landscape = {-106, -84};
static const CGPoint KeyRow3Painter1_Landscape = {-99, -124};
static const CGPoint KeyRow3Painter2_Landscape = {-177, -124};

static const CGPoint ShiftPainter_Portrait = {0, -118};
static const CGPoint ShiftTransparentPainter_Portrait = {0, 0};
static const CGPoint ShiftLockedTransparentPainter_Portrait = {0, 1};
static const CGPoint ShiftPainter_Landscape = {-5, -84};
static const CGPoint ShiftDisabledPainter_Landscape = {-5, 0};
static const CGRect ShiftActiveScaler_Landscape = {{-5, 1}, {76, 40}};

static const CGPoint SpaceEtchPainter_Portrait = {-2, 35};
static const CGPoint SpaceEtchPainter_Landscape = {0, 29};
static const CGPoint ReturnEtchPainter_Portrait = {-162, 35};
static const CGPoint ReturnEtchPainter_Landscape = {-283, 29};

static const CGPoint DeletePainter_Portrait = {-278, -118};
static const CGPoint DeletePainter_Landscape = {-414, -84};

static const CGRect PopupClipper1_Portrait = {{0, 0}, {25, 120}};
static const CGRect PopupClipper2_Portrait = {{25, 0}, {24, 120}};
static const CGPoint PopupPainter1_Portrait = {0, 0};
static const CGPoint PopupPainter2_Portrait = {25-55, 0};
static const CGRect PopupClipper1_Landscape = {{0, 0}, {27, 120}};
static const CGRect PopupClipper2_Landscape = {{27, 0}, {26, 120}};
static const CGPoint PopupPainter1_Landscape = {0, 0};
static const CGPoint PopupPainter2_Landscape = {27-73, 0};

static const CGSize BackgroundSize_Portrait = {1, 216};
static const CGSize BackgroundSize_Landscape = {1, 162};
static const CGSize KeySize_Portrait = {15, 44};
static const CGSize KeySize_Landscape = {17, 38};

static const CGSize ShiftSize_Portrait = {42, 44};
static const CGSize ShiftSize_Landscape = {62, 38};
static const CGSize InternationalSize_Portrait = {37, 43};
static const CGSize InternationalSize_Landscape = {47, 38};
static const CGSize SpaceSize_Portrait = {160, 44};
static const CGSize SpaceSize_Landscape = {283, 38};
static const CGSize ReturnSize_Portrait = {80, 44};
static const CGSize ReturnSize_Landscape = {98, 38};
static const CGSize DeleteSize_Portrait = {42, 43};
static const CGSize DeleteSize_Landscape = {66, 38};

static const CGSize PopupSize_Portrait = {79, 120};
static const CGSize PopupSize_Landscape = {99, 120};

static const CGFloat KeyCapSize_Portrait = 7;
static const CGFloat KeyCapSize_Landscape = 8;
static const CGFloat PopupCapSize_Portrait = 24;
static const CGFloat PopupCapSize_Landscape = 26;

//------------------------------------------------------------------------------
#pragma mark -
#pragma mark Convenient Functions
//------------------------------------------------------------------------------


UIImage* obtain_2part_image (UIImage* image, const CGSize size, const CGRect firstClip, const CGPoint firstPaint, const CGRect secondClip, const CGPoint secondPaint) {
	UIGraphicsBeginImageContext(size);
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	CGContextClearRect(ctx, CGRectMake(0, 0, size.width, size.height));
	CGContextSaveGState(ctx);
	CGContextClipToRect(ctx, firstClip);
	[image drawAtPoint:firstPaint];
	CGContextRestoreGState(ctx);
	CGContextSaveGState(ctx);
	CGContextClipToRect(ctx, secondClip);
	[image drawAtPoint:secondPaint];
	UIImage* result = UIGraphicsGetImageFromCurrentImageContext();
	CGContextRestoreGState(ctx);
	UIGraphicsEndImageContext();
	return result;
}

UIImage* obtain_2part_stretchable_image (UIImage* image, const CGSize size, const CGRect firstClip, const CGPoint firstPaint, const CGRect secondClip, const CGPoint secondPaint, const CGFloat leftCap) {
	return [obtain_2part_image(image, size, firstClip, firstPaint, secondClip, secondPaint) stretchableImageWithLeftCapWidth:leftCap topCapHeight:0];
}

UIImage* obtain_image (UIImage* image, const CGSize size, const CGPoint paint) {
	UIGraphicsBeginImageContext(size);
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	CGContextClearRect(ctx, CGRectMake(0, 0, size.width, size.height));
	[image drawAtPoint:paint];
	UIImage* result = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return result;
}

UIImage* compose_image (UIImage* image, UIImage* background, const CGSize size, const CGPoint frontPaint, const CGPoint backPaint) {
	UIGraphicsBeginImageContext(size);
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	CGContextClearRect(ctx, CGRectMake(0, 0, size.width, size.height));
	[background drawAtPoint:backPaint];
	[image drawAtPoint:frontPaint];
	UIImage* result = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return result;
}

UIImage* scale_image (UIImage* image, const CGSize size, const CGRect scale) {
	UIGraphicsBeginImageContext(size);
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	CGContextClearRect(ctx, CGRectMake(0, 0, size.width, size.height));
	[image drawInRect:scale];
	UIImage* result = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return result;
}

UIImage* compose_scale_image (UIImage* image, UIImage* background, const CGSize size, const CGRect scale, const CGPoint backPaint) {
	UIGraphicsBeginImageContext(size);
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	CGContextClearRect(ctx, CGRectMake(0, 0, size.width, size.height));
	[background drawAtPoint:backPaint];
	[image drawInRect:scale];
	UIImage* result = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return result;
}

//------------------------------------------------------------------------------
#pragma mark -
#pragma mark Initializer & Terminators
//------------------------------------------------------------------------------

// Call these functions once in a lifetime only.
void UIKBInitializeImageCache () {
	LOCK(firstMutex); {
		memset(cache, 0, sizeof(cache));
		for (ptrdiff_t i = 0; i < 4 * UIKBImageTypesCount; ++ i)
			pthread_mutex_init(mutexList+i, NULL);
	} UNLOCK(firstMutex);
}

void UIKBClearImageCache() {
	LOCK(firstMutex); {
		for (ptrdiff_t i = 0; i < 4 * UIKBImageTypesCount; ++ i)
			[cache[i] release];
		for (ptrdiff_t i = 0; i < 4 * UIKBImageTypesCount; ++ i)
			pthread_mutex_destroy(mutexList+i);
	} UNLOCK(firstMutex);
}

// Call this when you feel lack of memory / all 
void UIKBReleaseImageCache() {
	LOCK(firstMutex); {
		for (ptrdiff_t i = 0; i < 4 * UIKBImageTypesCount; ++ i) {
			[cache[i] release];
			cache[i] = nil;
		}
	} UNLOCK(firstMutex);
}

//------------------------------------------------------------------------------
#pragma mark -
#pragma mark Get Image
//------------------------------------------------------------------------------

// really really long function.
UIImage* constructImage(UIKBImageClassType actualType) {
	switch (actualType) {
		default:
			return nil;
			
		case UIKBImageBackground:
			return obtain_2part_image(_UIImageWithName(@"kb-std.png"), BackgroundSize_Portrait, BackgroundClipper1_Portrait, BackgroundPainter1_Portrait, BackgroundClipper2_Portrait, BackgroundPainter2_Portrait);
		case UIKBImageBackground+WithTransparent: 
			return obtain_2part_image(_UIImageWithName(@"kb-std-transparent.png"), BackgroundSize_Portrait, BackgroundClipper1_Portrait, BackgroundPainter1_Portrait, BackgroundClipper2_Portrait, BackgroundPainter2_Portrait);
		case UIKBImageBackground+WithLandscape:
			return obtain_2part_image(_UIImageWithName(@"kb-std-landscape.png"), BackgroundSize_Landscape, BackgroundClipper1_Landscape, BackgroundPainter1_Landscape, BackgroundClipper2_Landscape, BackgroundPainter2_Landscape);
		case UIKBImageBackground+WithLandscape+WithTransparent:
			return obtain_2part_image(_UIImageWithName(@"kb-std-landscape-transparent.png"), BackgroundSize_Landscape, BackgroundClipper1_Landscape, BackgroundPainter1_Landscape, BackgroundClipper2_Landscape, BackgroundPainter2_Landscape);
			
		case UIKBImageRow0:
			return obtain_2part_stretchable_image(_UIImageWithName(@"kb-std.png"), KeySize_Portrait, KeyClipper1_Portrait, KeyRow0Painter1_Portrait, KeyClipper2_Portrait, KeyRow0Painter2_Portrait, KeyCapSize_Portrait);
		case UIKBImageRow1:
			return obtain_2part_stretchable_image(_UIImageWithName(@"kb-std.png"), KeySize_Portrait, KeyClipper1_Portrait, KeyRow1Painter1_Portrait, KeyClipper2_Portrait, KeyRow1Painter2_Portrait, KeyCapSize_Portrait);
		case UIKBImageRow2:
			return obtain_2part_stretchable_image(_UIImageWithName(@"kb-std.png"), KeySize_Portrait, KeyClipper1_Portrait, KeyRow2Painter1_Portrait, KeyClipper2_Portrait, KeyRow2Painter2_Portrait, KeyCapSize_Portrait);
		case UIKBImageRow3:
			return obtain_2part_stretchable_image(_UIImageWithName(@"kb-std.png"), KeySize_Portrait, KeyClipper1_Portrait, KeyRow3Painter1_Portrait, KeyClipper2_Portrait, KeyRow3Painter2_Portrait, KeyCapSize_Portrait);
		case UIKBImageRow0+WithTransparent:
			return obtain_2part_stretchable_image(_UIImageWithName(@"kb-std-transparent.png"), KeySize_Portrait, KeyClipper1_Portrait, KeyRow0Painter1_Portrait, KeyClipper2_Portrait, KeyRow0Painter2_Portrait, KeyCapSize_Portrait);
		case UIKBImageRow1+WithTransparent:
			return obtain_2part_stretchable_image(_UIImageWithName(@"kb-std-transparent.png"), KeySize_Portrait, KeyClipper1_Portrait, KeyRow1Painter1_Portrait, KeyClipper2_Portrait, KeyRow1Painter2_Portrait, KeyCapSize_Portrait);
		case UIKBImageRow2+WithTransparent:
			return obtain_2part_stretchable_image(_UIImageWithName(@"kb-std-transparent.png"), KeySize_Portrait, KeyClipper1_Portrait, KeyRow2Painter1_Portrait, KeyClipper2_Portrait, KeyRow2Painter2_Portrait, KeyCapSize_Portrait);
		case UIKBImageRow3+WithTransparent:
			return obtain_2part_stretchable_image(_UIImageWithName(@"kb-std-alt-transparent.png"), KeySize_Portrait, KeyClipper1_Portrait, KeyRow3Painter1_Portrait, KeyClipper2_Portrait, KeyRow3Painter2_Portrait, KeyCapSize_Portrait);	
		case UIKBImageRow0+WithLandscape:
			return obtain_2part_stretchable_image(_UIImageWithName(@"kb-std-landscape.png"), KeySize_Landscape, KeyClipper1_Landscape, KeyRow0Painter1_Landscape, KeyClipper2_Landscape, KeyRow0Painter2_Landscape, KeyCapSize_Landscape);
		case UIKBImageRow1+WithLandscape:
			return obtain_2part_stretchable_image(_UIImageWithName(@"kb-std-landscape.png"), KeySize_Landscape, KeyClipper1_Landscape, KeyRow1Painter1_Landscape, KeyClipper2_Landscape, KeyRow1Painter2_Landscape, KeyCapSize_Landscape);
		case UIKBImageRow2+WithLandscape:
			return obtain_2part_stretchable_image(_UIImageWithName(@"kb-std-landscape.png"), KeySize_Landscape, KeyClipper1_Landscape, KeyRow2Painter1_Landscape, KeyClipper2_Landscape, KeyRow2Painter2_Landscape, KeyCapSize_Landscape);
		case UIKBImageRow3+WithLandscape:
			return obtain_2part_stretchable_image(_UIImageWithName(@"kb-std-landscape-email-alt.png"), KeySize_Landscape, KeyClipper1_Landscape, KeyRow3Painter1_Landscape, KeyClipper2_Landscape, KeyRow3Painter2_Landscape, KeyCapSize_Landscape);
		case UIKBImageRow0+WithLandscape+WithTransparent:
			return obtain_2part_stretchable_image(_UIImageWithName(@"kb-std-landscape-transparent.png"), KeySize_Landscape, KeyClipper1_Landscape, KeyRow0Painter1_Landscape, KeyClipper2_Landscape, KeyRow0Painter2_Landscape, KeyCapSize_Landscape);
		case UIKBImageRow1+WithLandscape+WithTransparent:
			return obtain_2part_stretchable_image(_UIImageWithName(@"kb-std-landscape-transparent.png"), KeySize_Landscape, KeyClipper1_Landscape, KeyRow1Painter1_Landscape, KeyClipper2_Landscape, KeyRow1Painter2_Landscape, KeyCapSize_Landscape);
		case UIKBImageRow2+WithLandscape+WithTransparent:
			return obtain_2part_stretchable_image(_UIImageWithName(@"kb-std-landscape-transparent.png"), KeySize_Landscape, KeyClipper1_Landscape, KeyRow2Painter1_Landscape, KeyClipper2_Landscape, KeyRow2Painter2_Landscape, KeyCapSize_Landscape);
		case UIKBImageRow3+WithLandscape+WithTransparent:	// es un lío
			return [compose_image(
								  obtain_2part_image(_UIImageWithName(@"kb-std-landscape-transparent-intl-globe-active.png"),
													 KeySize_Landscape, KeyClipper1_Landscape, CGPointZero, KeyClipper2_Landscape, CGPointMake(-30, 0)),
								  _UIImageWithName(@"kb-std-landscape-transparent.png"), KeySize_Landscape, CGPointZero, KeyRow3Painter1_Landscape
								  ) stretchableImageWithLeftCapWidth:KeyCapSize_Landscape topCapHeight:0];
			
			
		case UIKBImageShift:
			return obtain_image(_UIImageWithName(@"kb-std.png"), ShiftSize_Portrait, ShiftPainter_Portrait);
		case UIKBImageShiftActive:
			return obtain_image(_UIImageWithName(@"kb-std-active-bg-main.png"), ShiftSize_Portrait, ShiftPainter_Portrait);
		case UIKBImageShiftLocked:
			// no deadlock arised because two different mutexes are used.
			return compose_image(_UIImageWithName(@"kb-std-shift-locked.png"), UIKBGetImage(UIKBImageShift, UIKeyboardAppearanceDefault, NO), ShiftSize_Portrait, CGPointMake(1,1), CGPointZero);
		case UIKBImageShiftDisabled:
			return obtain_image(_UIImageWithName(@"kb-std-sms.png"), ShiftSize_Portrait, ShiftPainter_Portrait);
		case UIKBImageShift+WithTransparent:
			return obtain_image(_UIImageWithName(@"kb-std-qzerty-transparent.png"), ShiftSize_Portrait, ShiftPainter_Portrait);
		case UIKBImageShiftActive+WithTransparent:
			return obtain_image(_UIImageWithName(@"kb-std-shift-active-transparent.png"), ShiftSize_Portrait, ShiftTransparentPainter_Portrait);
		case UIKBImageShiftLocked+WithTransparent:
			return obtain_image(_UIImageWithName(@"kb-std-shift-locked-transparent.png"), ShiftSize_Portrait, ShiftLockedTransparentPainter_Portrait);
		case UIKBImageShiftDisabled+WithTransparent:
			return obtain_image(_UIImageWithName(@"kb-std-shift-disabled-transparent.png"), ShiftSize_Portrait, ShiftTransparentPainter_Portrait);
		case UIKBImageShift+WithLandscape:
			return obtain_image(_UIImageWithName(@"kb-std-landscape.png"), ShiftSize_Landscape, ShiftPainter_Landscape);
		case UIKBImageShiftActive+WithLandscape:
			return compose_scale_image(_UIImageWithName(@"kb-std-landscape-shift.png"), UIKBGetImage(UIKBImageShift, UIKeyboardAppearanceDefault, YES), ShiftSize_Landscape, ShiftActiveScaler_Landscape, CGPointZero);
		case UIKBImageShiftLocked+WithLandscape:
			return compose_scale_image(_UIImageWithName(@"kb-std-landscape-shift-locked.png"), UIKBGetImage(UIKBImageShift, UIKeyboardAppearanceDefault, YES), ShiftSize_Landscape, ShiftActiveScaler_Landscape, CGPointZero);
		case UIKBImageShiftDisabled+WithLandscape:
			return compose_image(_UIImageWithName(@"kb-std-landscape-sms-shift.png"), UIKBGetImage(UIKBImageShift, UIKeyboardAppearanceDefault, YES), ShiftSize_Landscape, ShiftDisabledPainter_Landscape, CGPointZero);
		case UIKBImageShift+WithLandscape+WithTransparent:
			return compose_image(_UIImageWithName(@"kb-std-landscape-shift-transparent.png"), _UIImageWithName(@"kb-std-landscape-transparent.png"), ShiftSize_Landscape, ShiftDisabledPainter_Landscape, ShiftPainter_Landscape);
		case UIKBImageShiftActive+WithLandscape+WithTransparent:
			return obtain_image(_UIImageWithName(@"kb-std-landscape-shift-active-transparent.png"), ShiftSize_Landscape, ShiftDisabledPainter_Landscape);
		case UIKBImageShiftLocked+WithLandscape+WithTransparent:
			return obtain_image(_UIImageWithName(@"kb-std-landscape-shift-locked-transparent.png"), ShiftSize_Landscape, ShiftDisabledPainter_Landscape);
		case UIKBImageShiftDisabled+WithLandscape+WithTransparent:
			return obtain_image(_UIImageWithName(@"kb-std-landscape-transparent-sms-shift.png"), ShiftSize_Landscape, ShiftDisabledPainter_Landscape);
			
		case UIKBImageInternational:
			return _UIImageWithName(@"kb-std-intl-globe.png");
		case UIKBImageInternationalActive:
			return _UIImageWithName(@"kb-std-intl-globe-active.png");
		case UIKBImageInternational+WithTransparent:
			return _UIImageWithName(@"kb-std-transparent-intl-globe.png");
		case UIKBImageInternationalActive+WithTransparent:
			return compose_image(_UIImageWithName(@"kb-std-transparent-intl-globe-active.png"), UIKBGetImage(UIKBImageInternational, UIKeyboardAppearanceAlert, NO), InternationalSize_Portrait, CGPointZero, CGPointZero);
		case UIKBImageInternational+WithLandscape:
			return _UIImageWithName(@"kb-std-landscape-intl-globe.png");
		case UIKBImageInternationalActive+WithLandscape:
			return _UIImageWithName(@"kb-std-landscape-intl-globe-active.png");
		case UIKBImageInternational+WithLandscape+WithTransparent:
			return _UIImageWithName(@"kb-std-landscape-transparent-intl-globe.png");
		case UIKBImageInternationalActive+WithLandscape+WithTransparent:
			return compose_image(_UIImageWithName(@"kb-std-landscape-transparent-intl-globe-active.png"), UIKBGetImage(UIKBImageInternational, UIKeyboardAppearanceAlert, YES), InternationalSize_Landscape, CGPointZero, CGPointZero);
			
		case UIKBImageSpace:
			return _UIImageWithName(@"kb-key-portrait-space-steel-blue-light-enabled.png");
		case UIKBImageSpaceActive:
			return _UIImageWithName(@"kb-key-portrait-space-steel-blue-light-pressed.png");
		case UIKBImageSpace+WithTransparent:
			return compose_image(_UIImageWithName(@"kb-key-portrait-space-gray-light-enabled.png"), _UIImageWithName(@"kb-std-transparent-space-return-etch.png"), SpaceSize_Portrait, CGPointZero, SpaceEtchPainter_Portrait);
		case UIKBImageSpaceActive+WithTransparent:
			return compose_image(_UIImageWithName(@"kb-key-portrait-space-gray-light-pressed.png"), _UIImageWithName(@"kb-std-transparent-space-return-etch.png"), SpaceSize_Portrait, CGPointZero, SpaceEtchPainter_Portrait);
		case UIKBImageSpace+WithLandscape:
			return _UIImageWithName(@"kb-key-landscape-space-steel-blue-light-enabled.png");
		case UIKBImageSpaceActive+WithLandscape:
			return _UIImageWithName(@"kb-key-landscape-space-steel-blue-light-pressed.png");
		case UIKBImageSpace+WithLandscape+WithTransparent:
			return compose_image(_UIImageWithName(@"kb-key-landscape-space-gray-light-enabled.png"), _UIImageWithName(@"kb-std-landscape-transparent-space-return-etch.png"), SpaceSize_Landscape, CGPointZero, SpaceEtchPainter_Landscape);
		case UIKBImageSpaceActive+WithLandscape+WithTransparent:
			return compose_image(_UIImageWithName(@"kb-key-landscape-space-gray-light-pressed.png"), _UIImageWithName(@"kb-std-landscape-transparent-space-return-etch.png"), SpaceSize_Landscape, CGPointZero, SpaceEtchPainter_Landscape);
			
		case UIKBImageReturn:
			return _UIImageWithName(@"kb-key-portrait-return-steel-blue-dark-enabled.png");
		case UIKBImageReturnActive:
			return _UIImageWithName(@"kb-key-portrait-return-steel-blue-dark-pressed.png");
		case UIKBImageReturnBlue:
			return _UIImageWithName(@"kb-key-portrait-return-royal-blue-enabled.png");
		case UIKBImageReturn+WithTransparent:
			return compose_image(_UIImageWithName(@"kb-key-portrait-return-gray-dark-enabled.png"), _UIImageWithName(@"kb-std-transparent-space-return-etch.png"), ReturnSize_Portrait, CGPointZero, ReturnEtchPainter_Portrait);
		case UIKBImageReturnActive+WithTransparent:
			return compose_image(_UIImageWithName(@"kb-key-portrait-return-gray-dark-pressed.png"), _UIImageWithName(@"kb-std-transparent-space-return-etch.png"), ReturnSize_Portrait, CGPointZero, ReturnEtchPainter_Portrait);
		case UIKBImageReturnBlue+WithTransparent:
			return compose_image(_UIImageWithName(@"kb-key-portrait-return-royal-blue-alert-enabled.png"), _UIImageWithName(@"kb-std-transparent-space-return-etch.png"), ReturnSize_Portrait, CGPointZero, ReturnEtchPainter_Portrait);
		case UIKBImageReturn+WithLandscape:
			return _UIImageWithName(@"kb-key-landscape-return-steel-blue-dark-enabled.png");
		case UIKBImageReturnActive+WithLandscape:
			return _UIImageWithName(@"kb-key-landscape-return-steel-blue-dark-pressed.png");
		case UIKBImageReturnBlue+WithLandscape:
			return _UIImageWithName(@"kb-key-landscape-return-royal-blue-enabled.png");
		case UIKBImageReturn+WithLandscape+WithTransparent:
			return compose_image(_UIImageWithName(@"kb-key-landscape-return-gray-dark-enabled.png"), _UIImageWithName(@"kb-std-landscape-transparent-space-return-etch.png"), ReturnSize_Landscape, CGPointZero, ReturnEtchPainter_Landscape);
		case UIKBImageReturnActive+WithLandscape+WithTransparent:
			return compose_image(_UIImageWithName(@"kb-key-landscape-return-gray-dark-pressed.png"), _UIImageWithName(@"kb-std-landscape-transparent-space-return-etch.png"), ReturnSize_Landscape, CGPointZero, ReturnEtchPainter_Landscape);
		case UIKBImageReturnBlue+WithLandscape+WithTransparent:
			return compose_image(_UIImageWithName(@"kb-key-landscape-return-royal-blue-alert-enabled.png"), _UIImageWithName(@"kb-std-landscape-transparent-space-return-etch.png"), ReturnSize_Landscape, CGPointZero, ReturnEtchPainter_Landscape);
			
		case UIKBImageDelete:
			return obtain_image(_UIImageWithName(@"kb-std.png"), DeleteSize_Portrait, DeletePainter_Portrait);
		case UIKBImageDeleteActive:	
			return obtain_image(_UIImageWithName(@"kb-std-active-bg-main.png"), DeleteSize_Portrait, DeletePainter_Portrait);
		case UIKBImageDelete+WithTransparent:	
			return _UIImageWithName(@"kb-std-delete-transparent.png");
		case UIKBImageDeleteActive+WithTransparent:
			return _UIImageWithName(@"kb-std-delete-active-transparent.png");
		case UIKBImageDelete+WithLandscape:
			return obtain_image(_UIImageWithName(@"kb-std-landscape.png"), DeleteSize_Landscape, DeletePainter_Landscape);
		case UIKBImageDeleteActive+WithLandscape:
			return _UIImageWithName(@"kb-std-landscape-delete-active.png");
		case UIKBImageDelete+WithLandscape+WithTransparent:
			return _UIImageWithName(@"kb-std-landscape-delete-transparent.png");
		case UIKBImageDeleteActive+WithLandscape+WithTransparent:
			return _UIImageWithName(@"kb-std-landscape-delete-active-transparent.png");
			
		case UIKBImageABC: return _UIImageWithName(@"kb-std-intl-abc.png");
		case UIKBImage123: return _UIImageWithName(@"kb-std-intl-123.png");
		case UIKBImageABC+WithTransparent: return _UIImageWithName(@"kb-std-transparent-intl-abc.png");
		case UIKBImage123+WithTransparent: return _UIImageWithName(@"kb-std-transparent-intl-123.png");			
		case UIKBImageABC+WithLandscape: return _UIImageWithName(@"kb-std-landscape-intl-abc.png");
		case UIKBImage123+WithLandscape: return _UIImageWithName(@"kb-std-landscape-intl-123.png");
		case UIKBImageABC+WithLandscape+WithTransparent: return _UIImageWithName(@"kb-std-landscape-transparent-intl-abc.png");
		case UIKBImage123+WithLandscape+WithTransparent: return _UIImageWithName(@"kb-std-landscape-transparent-intl-123.png");
			
		case UIKBImageShiftSymbol:
			return obtain_image(_UIImageWithName(@"kb-std-alt.png"), ShiftSize_Portrait, ShiftPainter_Portrait);
		case UIKBImageShift123:
			return obtain_image(_UIImageWithName(@"kb-std-alt-shift.png"), ShiftSize_Portrait, ShiftPainter_Portrait);
		case UIKBImageShiftSymbol+WithTransparent:	
			return obtain_image(_UIImageWithName(@"kb-std-alt-transparent.png"), ShiftSize_Portrait, ShiftPainter_Portrait);
		case UIKBImageShift123+WithTransparent:	
			return obtain_image(_UIImageWithName(@"kb-std-alt-shift-transparent.png"), ShiftSize_Portrait, ShiftPainter_Portrait);		
		case UIKBImageShiftSymbol+WithLandscape:
			return obtain_image(_UIImageWithName(@"kb-std-alt-landscape.png"), ShiftSize_Landscape, ShiftPainter_Landscape);
		case UIKBImageShift123+WithLandscape:
			return obtain_image(_UIImageWithName(@"kb-std-alt-landscape-shift.png"), ShiftSize_Landscape, ShiftPainter_Landscape);
		case UIKBImageShiftSymbol+WithLandscape+WithTransparent:	
			return obtain_image(_UIImageWithName(@"kb-std-alt-landscape-transparent.png"), ShiftSize_Landscape, ShiftPainter_Landscape);
		case UIKBImageShift123+WithLandscape+WithTransparent:	
			return obtain_image(_UIImageWithName(@"kb-std-alt-shift-landscape-transparent.png"), ShiftSize_Landscape, ShiftPainter_Landscape);		
			
		case UIKBImagePopupFlexible:
		case UIKBImagePopupFlexible+WithTransparent:
			//return obtain_2part_stretchable_image(_UIImageWithName(@"kb-std-active-bg-pop-center-wide.png"), PopupSize_Portrait, PopupClipper1_Portrait, PopupPainter1_Portrait, PopupClipper2_Portrait, PopupPainter2_Portrait, PopupCapSize_Portrait);
			return [_UIImageWithName(@"kb-std-active-bg-pop-center-wide.png") stretchableImageWithLeftCapWidth:79/2 topCapHeight:0];
		case UIKBImagePopupCenter:
		case UIKBImagePopupCenter+WithTransparent:
			return _UIImageWithName(@"kb-std-active-bg-pop-center.png");
		case UIKBImagePopupLeft:
		case UIKBImagePopupLeft+WithTransparent:
			return _UIImageWithName(@"kb-std-active-bg-pop-left.png");
		case UIKBImagePopupRight:
		case UIKBImagePopupRight+WithTransparent:
			return _UIImageWithName(@"kb-std-active-bg-pop-right.png");
			
		case UIKBImagePopupFlexible+WithLandscape:
		case UIKBImagePopupFlexible+WithLandscape+WithTransparent:
			//return obtain_2part_stretchable_image(_UIImageWithName(@"kb-std-landscape-active-bg-pop-center-wide.png"), PopupSize_Landscape, PopupClipper1_Landscape, PopupPainter1_Landscape, PopupClipper2_Landscape, PopupPainter2_Landscape, PopupCapSize_Landscape);
			return [_UIImageWithName(@"kb-std-landscape-active-bg-pop-center-wide.png") stretchableImageWithLeftCapWidth:99/2 topCapHeight:0];
		case UIKBImagePopupCenter+WithLandscape:
		case UIKBImagePopupCenter+WithLandscape+WithTransparent:
			return _UIImageWithName(@"kb-std-landscape-active-bg-pop-center.png");
		case UIKBImagePopupLeft+WithLandscape:
		case UIKBImagePopupLeft+WithLandscape+WithTransparent:
			return _UIImageWithName(@"kb-std-landscape-active-bg-pop-left.png");
		case UIKBImagePopupRight+WithLandscape:
		case UIKBImagePopupRight+WithLandscape+WithTransparent:
			return _UIImageWithName(@"kb-std-landscape-active-bg-pop-right.png");
			
		case UIKBImageActiveBackground:
		case UIKBImageActiveBackground+WithTransparent:
			return _UIImageWithName(@"kb-std-active-bg-main.png");
		case UIKBImageActiveBackground+WithLandscape:
		case UIKBImageActiveBackground+WithLandscape+WithTransparent:
			return _UIImageWithName(@"kb-std-landscape-active-bg-main.png");
	}
}

extern 
UIImage* UIKBGetImage(UIKBImageClassType type, UIKeyboardAppearance appearance, BOOL landscape) {
	ptrdiff_t actualType = type;
	if (landscape)
		actualType += WithLandscape;
	if (appearance == UIKeyboardAppearanceAlert)
		actualType += WithTransparent;
	
	// use @synchronized instead of pthread_mutex?
	LOCK(mutexList[type])nil; {
		if (cache[actualType] == nil)
			cache[actualType] = [constructImage(actualType) retain];
	} UNLOCK(mutexList[type])nil;
	
	return cache[actualType];
}
