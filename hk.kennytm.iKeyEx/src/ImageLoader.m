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

#import <iKeyEx/common.h>
#import <iKeyEx/ImageLoader.h>
#import <UIKit2/Functions.h>
#import <UIKit2/UIKeyboardInputManager.h>
#import <UIKit/UIImage.h>
#import <UIKit/UIGraphics.h>
#import <CoreGraphics/CGGeometry.h>
#include <pthread.h>
#include <stdlib.h>
#include <GraphicsUtilities.h>

static NSMutableDictionary* cache;
static NSMutableDictionary* brightnesses = nil;

//------------------------------------------------------------------------------
#pragma mark -
#pragma mark Constants
//------------------------------------------------------------------------------

static const CGRect BackgroundRect1_Portrait = {{159, 0}, {2, 172}};
static const CGRect BackgroundRect2_Portrait = {{79, 172}, {2, 44}};
static const CGRect BackgroundRectT_Portrait = {{159, 0}, {2, 216}};
static const CGRect BackgroundRect_Landscape = {{238, 0}, {4, 162}};

static const GUCaps KeyCaps = {8,8,8,8};

static const CGRect KeyRect_Key_Portrait = {{225, 10}, {30, 43}};
static const CGRect KeyRect_ISrc_Portrait = {{7, 13}, { 1, 17}};
static const CGRect KeyRect_ITrg_Portrait = {{8, 13}, {15, 17}};
#define KeyRect_Key_Portrait_DeltaY 54
static const CGRect KeyRect_Mask_Portrait = {{1, 1}, {28, 41}};
#define KeyRect_Mask_Radius 5.5f

static const CGRect KeyRect_Key_Landscape = {{336, 4}, {43, 38}};
static const CGRect KeyRect_ISrc_Landscape = {{13, 11}, { 1, 17}};
static const CGRect KeyRect_ITrg_Landscape = {{14, 11}, {15, 17}};
#define KeyRect_Key_Landscape_DeltaY 40
static const CGRect KeyRect_Mask_Landscape = {{1, 2}, {41, 35}};


static const CGRect KeyRect1_Portrait = {{224, 10}, {8, 44}};
static const CGRect KeyRect2_Portrait = {{249, 10}, {7, 44}};
static const CGRect KeyRect1_Ladnscape = {{334, 4}, {9, 38}};
static const CGRect KeyRect2_Ladnscape = {{373, 4}, {8, 38}};

static const CGRect ShiftRect_Portrait = {{0, 118}, {42, 44}};
static const CGRect ShiftSubrect_Portrait = {{1, 1}, {40, 41}};
static const CGRect ShiftRect_Mask_Portrait = {{1.5, 1.5}, {39, 40}};

static const CGRect ShiftRect_Landscape = {{5, 84}, {62, 38}};
static const CGRect ShiftSubRect_Landscape = {{5, 0}, {62, 40}};

static const CGRect ShiftDrawRect_Portrait = {{1, 1}, {40, 41}};

static const CGRect ShiftRect_Mask_Landscape = {{2, 1}, {56, 36}};
static const CGRect ShiftDrawRect_Landscape = {{-6, -5}, {76, 42.75}};	// -5 counted from bottom, not top. 


static const CGSize InternationalSize_Portrait = {37, 43};
static const CGSize InternationalSize_Landscape = {47, 38};

static const CGRect SpaceRect_Portrait = {{0, 0}, {160, 44}};
static const CGRect SpaceRect_Landscape = {{0, 0}, {283, 38}};
static const CGRect SpaceEtchRect_Portrait = {{-2, 0}, {246, 9}};
static const CGRect SpaceEtchRect_Landscape = {{0, 1}, {381, 8}};

static const CGRect ReturnRect_Portrait = {{0, 0}, {80, 44}};
static const CGRect ReturnRect_Landscape = {{0, 0}, {98, 38}};
static const CGRect ReturnEtchRect_Portrait = {{-162, 0}, {246, 9}};
static const CGRect ReturnEtchRect_Landscape = {{-283, 1}, {381, 8}};

static const CGRect DeleteRect_Portrait = {{278, 118}, {42, 44}};
static const CGRect DeleteRect_Landscape = {{415, 84}, {62, 38}};
static const CGRect DeleteSubRect_Landscape = {{-1, 0}, {62, 38}};

//------------------------------------------------------------------------------
#pragma mark -
#pragma mark Initializer & Terminators
//------------------------------------------------------------------------------

// Call these functions once in a lifetime only.
void UIKBInitializeImageCache () {
	brightnesses = [[NSMutableDictionary alloc] initWithContentsOfFile:iKeyEx_InternalCachePath@"brightnesses.plist"];
	cache = [[NSMutableDictionary alloc] initWithCapacity:4*UIKBImageTypesCount];
}

void UIKBClearImageCache() {
	[brightnesses writeToFile:iKeyEx_InternalCachePath@"brightnesses.plist" atomically:NO];
	[brightnesses release];
	[cache release];
}

// Call this when you feel lack of memory / all 
void UIKBReleaseImageCache() {
	[cache release];
	cache = [[NSMutableDictionary alloc] initWithCapacity:4*UIKBImageTypesCount];
}

//------------------------------------------------------------------------------
#pragma mark -
#pragma mark Get Image
//------------------------------------------------------------------------------

#if TARGET_IPHONE_SIMULATOR

#define TryLoadCacheBegin {
#define TryLoadCacheEnd }

#else

#define TryLoadCacheBegin \
retimg = _UIImageWithName(cacheName); \
if (retimg == nil) { \
	cachePath = [iKeyEx_InternalCachePath stringByAppendingString:cacheName]; \
	retimg = [UIImage imageWithContentsOfFile:cachePath]; \
} \
if (retimg == nil) {

#define TryLoadCacheEnd [UIImagePNGRepresentation(retimg) writeToFile:(cachePath) atomically:NO]; }

#endif

// really really long function.
UIImage* constructImage(UIKBImageClassType actualType) {
	UIImage* retimg = nil;
	NSNumber* keyNum = [NSNumber numberWithUnsignedInteger:actualType];
	CGImageRef img = NULL;
	NSString* cacheName;
	NSString* srcName;
	NSString* cachePath;
	BOOL isLandscape, isTransparent, isActive;
	NSUInteger whichRow;
	
	switch (actualType) {
		default:
			return nil;
			
		case UIKBImageBackground:
			cacheName = @"kb-ext-background.png";
			TryLoadCacheBegin;
			img = GUImageCreateByConcatSubimages(_UIImageWithName(@"kb-std-azerty.png").CGImage,
												 BackgroundRect1_Portrait,
												 BackgroundRect2_Portrait,
												 YES);
			retimg = GUCreateUIImageAndRelease(img);
			TryLoadCacheEnd;
			return retimg;
			
		case UIKBImageBackground|UIKBImageWithTransparent: 
			cacheName = @"kb-ext-background-transparent.png";
			TryLoadCacheBegin;
			img = CGImageCreateWithImageInRect(_UIImageWithName(@"kb-std-azerty-transparent.png").CGImage,
											   BackgroundRectT_Portrait);
			retimg = GUCreateUIImageAndRelease(img);
			TryLoadCacheEnd;
			return retimg;
			
		case UIKBImageBackground|UIKBImageWithLandscape:
		case UIKBImageBackground|UIKBImageWithLandscape|UIKBImageWithTransparent:
			cacheName = ((actualType & UIKBImageWithTransparent) ?
						 @"kb-ext-background-landscape-transparent.png" :
						 @"kb-ext-background-landscape.png");
			TryLoadCacheBegin;
			srcName = ((actualType & UIKBImageWithTransparent) ?
					   @"kb-std-landscape-transparent-azerty.png" :
					   @"kb-std-landscape-azerty.png");
			img = CGImageCreateWithImageInRect(_UIImageWithName(srcName).CGImage, BackgroundRect_Landscape);
			retimg = GUCreateUIImageAndRelease(img);
			TryLoadCacheEnd;
			return retimg;
			
		case UIKBImageKeyRow0:
		case UIKBImageKeyRow1:
		case UIKBImageKeyRow2:
			// whoever creates these inconsistent naming schemes should be banned from software designing immediately.
			cacheName = @"kb-ext-key.png";
			srcName = @"kb-std-azerty.png";
			goto key_namesComputed;
		case UIKBImageKeyRow0|UIKBImageWithTransparent:
		case UIKBImageKeyRow1|UIKBImageWithTransparent:
		case UIKBImageKeyRow2|UIKBImageWithTransparent:
			cacheName = @"kb-ext-key-transparent.png";
			srcName = @"kb-std-azerty-transparent.png";
			goto key_namesComputed;
		case UIKBImageKeyRow0|UIKBImageWithLandscape:
		case UIKBImageKeyRow1|UIKBImageWithLandscape:
		case UIKBImageKeyRow2|UIKBImageWithLandscape:
			cacheName = @"kb-ext-key-landscape.png";
			srcName = @"kb-std-landscape-azerty.png";
			goto key_namesComputed;
		case UIKBImageKeyRow0|UIKBImageWithLandscape|UIKBImageWithTransparent:
		case UIKBImageKeyRow1|UIKBImageWithLandscape|UIKBImageWithTransparent:
		case UIKBImageKeyRow2|UIKBImageWithLandscape|UIKBImageWithTransparent:
			cacheName = @"kb-ext-key-landscape-transparent.png";
			srcName = @"kb-std-landscape-transparent-azerty.png";
key_namesComputed:
			if (!(retimg = _UIImageWithName(cacheName))) {
				whichRow = (actualType & ~(UIKBImageWithLandscape|UIKBImageWithTransparent)) - UIKBImageKeyRow0;
				cacheName = [cacheName stringByReplacingOccurrencesOfString:@"-key" withString:[NSString stringWithFormat:@"-key-row%d",whichRow]];
				TryLoadCacheBegin;
				isLandscape = (actualType & UIKBImageWithLandscape) != 0;			
				CGRect imgRect = isLandscape ? KeyRect_Key_Landscape : KeyRect_Key_Portrait;
				imgRect.origin.y += whichRow * (isLandscape ? KeyRect_Key_Landscape_DeltaY : KeyRect_Key_Portrait_DeltaY);
				// Get the key
				CGImageRef ikey = CGImageCreateWithImageInRect(_UIImageWithName(srcName).CGImage, imgRect);
				// Cover the letter.
				CGImageRef premask = GUImageCreateWithPatching(ikey,
															   isLandscape ? KeyRect_ISrc_Landscape : KeyRect_ISrc_Portrait,
															   isLandscape ? KeyRect_ITrg_Landscape : KeyRect_ITrg_Portrait);
				img = GUImageCreateByClippingToRoundRect(premask,
														 isLandscape ? KeyRect_Mask_Landscape : KeyRect_Mask_Portrait,
														 KeyRect_Mask_Radius);
				
				retimg = GUCreateUIImageAndRelease(img);
				CGImageRelease(premask);
				CGImageRelease(ikey);
				TryLoadCacheEnd;
			}
			return retimg;
			
		case UIKBImageKeyRow3:
		case UIKBImageKeyRow3|UIKBImageWithLandscape:
		case UIKBImageKeyRow3|UIKBImageWithTransparent:
		case UIKBImageKeyRow3|UIKBImageWithTransparent|UIKBImageWithLandscape:
			retimg = _UIImageWithName([NSString stringWithFormat:@"kb-key%@-space-small%@-light-enabled.png",
									   (actualType & UIKBImageWithLandscape) ? @"-landscape" : @"-portrait",
									   (actualType & UIKBImageWithTransparent) ? @"-gray" : @"-steel-blue"]);
			return [retimg stretchableImageWithLeftCapWidth:(NSUInteger)(retimg.size.width/2) topCapHeight:0];
			
		case UIKBImageShift:
		case UIKBImageShiftDisabled:
		case UIKBImageShift|UIKBImageWithLandscape:
			cacheName = [NSString stringWithFormat:@"kb-ext-shift%@%@.png",
						 (actualType & UIKBImageWithLandscape) ? @"-landscape" : @"",
						 (actualType == UIKBImageShiftDisabled) ? @"-disabled" : @""];
			srcName = [NSString stringWithFormat:@"kb-std%@%@.png",
					   (actualType & UIKBImageWithLandscape) ? @"-landscape" : @"",
					   (actualType == UIKBImageShiftDisabled) ? @"-sms" : @"-azerty"];
			TryLoadCacheBegin;
			CGImageRef premask = CGImageCreateWithImageInRect(_UIImageWithName(srcName).CGImage,
															  (actualType & UIKBImageWithLandscape) ? ShiftRect_Landscape : ShiftRect_Portrait);
			img = GUImageCreateByClippingToRoundRect(premask, 
													 (actualType & UIKBImageWithLandscape) ? ShiftRect_Mask_Landscape : ShiftRect_Mask_Portrait,
													 KeyRect_Mask_Radius);
			retimg = GUCreateUIImageAndRelease(img);
			CGImageRelease(premask);
			TryLoadCacheEnd;
			return retimg;
			
		case UIKBImageShiftActive:
			cacheName = @"kb-ext-shift-active.png";
			srcName = @"kb-std-shift.png";
			goto shiftPortrait_namesComputed;
		case UIKBImageShiftLocked:
			cacheName = @"kb-ext-shift-locked.png";
			srcName = @"kb-std-shift-locked.png";
shiftPortrait_namesComputed:
			TryLoadCacheBegin;
			CGImageRef src = _UIImageWithName(srcName).CGImage;
			GUCreateContext(c, ShiftRect_Portrait.size.width, ShiftRect_Portrait.size.height);
			CGContextDrawImage(c, ShiftSubrect_Portrait, _UIImageWithName(@"kb-std-shift.png").CGImage);
			CGContextDrawImage(c, ShiftSubrect_Portrait, src);
			CGImageRef combinedImg = CGBitmapContextCreateImage(c);
			retimg = GUCreateUIImageAndRelease(GUImageCreateByClippingToRoundRect(combinedImg,
																				  ShiftRect_Mask_Portrait,
																				  KeyRect_Mask_Radius));
			CGImageRelease(combinedImg);
			CGContextRelease(c);
			TryLoadCacheEnd;
			return retimg;
			
		case UIKBImageShiftActive|UIKBImageWithLandscape:
			cacheName = @"kb-ext-shift-active-landscape.png";
			srcName = @"kb-std-landscape-shift.png";
			goto shiftLandscape_namesComputed;
		case UIKBImageShiftLocked|UIKBImageWithLandscape:
			cacheName = @"kb-ext-shift-locked-landscape.png";
			srcName = @"kb-std-landscape-shift-locked.png";
shiftLandscape_namesComputed:
			TryLoadCacheBegin;
			// well, we could make it without creating the subimage, but for maintainence let's just do it...
			CGImageRef subsrc = CGImageCreateWithImageInRect(_UIImageWithName(srcName).CGImage, ShiftSubRect_Landscape);
			CGImageRef combined = GUImageCreateByComposition(subsrc,
															 UIKBGetImage(UIKBImageShift, UIKeyboardAppearanceDefault, YES).CGImage,
															 CGRectMake(0, 0, ShiftRect_Landscape.size.width, ShiftRect_Landscape.size.height),
															 CGRectMake(0, 0, ShiftRect_Landscape.size.width, ShiftRect_Landscape.size.height));
			retimg = GUCreateUIImageAndRelease(GUImageCreateByClippingToRoundRect(combined, ShiftRect_Mask_Landscape, KeyRect_Mask_Radius));
			CGImageRelease(subsrc);
			CGImageRelease(combined);
			TryLoadCacheEnd;
			return retimg;
			
		case UIKBImageShift|UIKBImageWithTransparent:
			return _UIImageWithName(@"kb-std-shift-transparent.png");
		case UIKBImageShiftActive|UIKBImageWithTransparent:
			return _UIImageWithName(@"kb-std-shift-active-transparent.png");
		case UIKBImageShiftLocked|UIKBImageWithTransparent:
			return _UIImageWithName(@"kb-std-shift-locked-transparent.png");
		case UIKBImageShiftDisabled|UIKBImageWithTransparent:
			return _UIImageWithName(@"kb-std-shift-disabled-transparent.png");
			
		case UIKBImageShiftDisabled|UIKBImageWithLandscape:
			cacheName = @"kb-ext-shift-disabled-landscape.png";
			TryLoadCacheBegin;
			CGImageRef premask = CGImageCreateWithImageInRect(_UIImageWithName(@"kb-std-landscape-sms-shift.png").CGImage, ShiftSubRect_Landscape);
			retimg = GUCreateUIImageAndRelease(GUImageCreateByClippingToRoundRect(premask, ShiftRect_Mask_Landscape, KeyRect_Mask_Radius));
			CGImageRelease(premask);
			TryLoadCacheEnd;
			return retimg;
			
		case UIKBImageShift|UIKBImageWithLandscape|UIKBImageWithTransparent:
			cacheName = @"kb-ext-shift-landscape-transparent.png";
			srcName = @"kb-std-landscape-shift-transparent.png";
			goto shiftLandscapeTransparent_namesComputed;
		case UIKBImageShiftActive|UIKBImageWithLandscape|UIKBImageWithTransparent:
			cacheName = @"kb-ext-shift-active-landscape-transparent.png";
			srcName = @"kb-std-landscape-shift-active-transparent.png";
			goto shiftLandscapeTransparent_namesComputed;
		case UIKBImageShiftLocked|UIKBImageWithLandscape|UIKBImageWithTransparent:
			cacheName = @"kb-ext-shift-locked-landscape-transparent.png";
			srcName = @"kb-std-landscape-shift-locked-transparent.png";
			goto shiftLandscapeTransparent_namesComputed;
		case UIKBImageShiftDisabled|UIKBImageWithLandscape|UIKBImageWithTransparent:
			cacheName = @"kb-ext-shift-disabled-landscape-transparent.png";
			srcName = @"kb-std-landscape-transparent-sms-shift.png";
shiftLandscapeTransparent_namesComputed:
			TryLoadCacheBegin;
			img = CGImageCreateWithImageInRect(_UIImageWithName(srcName).CGImage, ShiftSubRect_Landscape);
			retimg = GUCreateUIImageAndRelease(img);
			TryLoadCacheEnd;
			return retimg;
			
		case UIKBImageInternational:
			return _UIImageWithName(@"kb-std-intl-globe.png");
		case UIKBImageInternationalActive:
			return _UIImageWithName(@"kb-std-intl-globe-active.png");
		case UIKBImageInternational|UIKBImageWithTransparent:
			return _UIImageWithName(@"kb-std-transparent-intl-globe.png");
		case UIKBImageInternationalActive|UIKBImageWithTransparent:
		case UIKBImageInternationalActive|UIKBImageWithLandscape|UIKBImageWithTransparent:
			isLandscape = (actualType & UIKBImageWithLandscape) != 0;
			cacheName = isLandscape ? @"kb-ext-international-landscape-transparent" : @"kb-ext-international-transparent";
			TryLoadCacheBegin;
			CGRect imgRect = CGRectZero;
			imgRect.size = isLandscape ? InternationalSize_Landscape : InternationalSize_Portrait;
			retimg = GUCreateUIImageAndRelease(GUImageCreateByComposition(_UIImageWithName(isLandscape ? @"kb-std-landscape-transparent-intl-globe-active.png" :  @"kb-std-transparent-intl-globe-active.png").CGImage,
																		  UIKBGetImage(UIKBImageInternationalActive, UIKBImageWithTransparent, isLandscape).CGImage,
																		  imgRect, imgRect));
			TryLoadCacheEnd;
			return retimg;
		case UIKBImageInternational|UIKBImageWithLandscape:
			return _UIImageWithName(@"kb-std-landscape-intl-globe.png");
		case UIKBImageInternationalActive|UIKBImageWithLandscape:
			return _UIImageWithName(@"kb-std-landscape-intl-globe-active.png");
		case UIKBImageInternational|UIKBImageWithLandscape|UIKBImageWithTransparent:
			return _UIImageWithName(@"kb-std-landscape-transparent-intl-globe.png");
			
		case UIKBImageSpace:
			return _UIImageWithName(@"kb-key-portrait-space-steel-blue-light-enabled.png");
		case UIKBImageSpaceActive:
			return _UIImageWithName(@"kb-key-portrait-space-steel-blue-light-pressed.png");
			
		case UIKBImageSpace|UIKBImageWithTransparent:
			cacheName = @"kb-ext-space-transparent.png";
			srcName = @"kb-key-portrait-space-gray-light-enabled.png";
			goto spaceEtch_namesComputed;
		case UIKBImageSpaceActive|UIKBImageWithTransparent:
			cacheName = @"kb-ext-space-active-transparent.png";
			srcName = @"kb-key-portrait-space-gray-light-pressed.png";
			goto spaceEtch_namesComputed;
		case UIKBImageSpace|UIKBImageWithLandscape|UIKBImageWithTransparent:
			cacheName = @"kb-ext-space-landscape-transparent.png";
			srcName = @"kb-key-landscape-space-gray-light-enabled.png";
			goto spaceEtch_namesComputed;
		case UIKBImageSpaceActive|UIKBImageWithLandscape|UIKBImageWithTransparent:
			cacheName = @"kb-ext-space-active-landscape-transparent.png";
			srcName = @"kb-key-landscape-space-gray-light-pressed.png";
spaceEtch_namesComputed:
			TryLoadCacheBegin;
			isLandscape = (actualType & UIKBImageWithLandscape) != 0;
			retimg = GUCreateUIImageAndRelease(GUImageCreateByComposition(_UIImageWithName(isLandscape ? @"kb-std-landscape-transparent-space-return-etch.png" : @"kb-std-transparent-space-return-etch.png").CGImage,
																		  _UIImageWithName(srcName).CGImage,
																		  isLandscape ? SpaceEtchRect_Landscape : SpaceEtchRect_Portrait,
																		  isLandscape ? SpaceRect_Landscape : SpaceRect_Portrait));
			TryLoadCacheEnd;
			return retimg;
		case UIKBImageSpace|UIKBImageWithLandscape:
			return _UIImageWithName(@"kb-key-landscape-space-steel-blue-light-enabled.png");
		case UIKBImageSpaceActive|UIKBImageWithLandscape:
			return _UIImageWithName(@"kb-key-landscape-space-steel-blue-light-pressed.png");
		
		case UIKBImageReturn:
			return _UIImageWithName(@"kb-key-portrait-return-steel-blue-dark-enabled.png");
		case UIKBImageReturnActive:
			return _UIImageWithName(@"kb-key-portrait-return-steel-blue-dark-pressed.png");
		case UIKBImageReturnBlue:
			return _UIImageWithName(@"kb-key-portrait-return-royal-blue-enabled.png");
		case UIKBImageReturn|UIKBImageWithLandscape:
			return _UIImageWithName(@"kb-key-landscape-return-steel-blue-dark-enabled.png");
		case UIKBImageReturnActive|UIKBImageWithLandscape:
			return _UIImageWithName(@"kb-key-landscape-return-steel-blue-dark-pressed.png");
		case UIKBImageReturnBlue|UIKBImageWithLandscape:
			return _UIImageWithName(@"kb-key-landscape-return-royal-blue-enabled.png");

		case UIKBImageReturn|UIKBImageWithTransparent:
			cacheName = @"kb-ext-return-transparent.png";
			srcName = @"kb-key-portrait-return-gray-dark-enabled.png";
			goto returnEtch_namesComputed;
		case UIKBImageReturnActive|UIKBImageWithTransparent:
			cacheName = @"kb-ext-return-active-transparent.png";
			srcName = @"kb-key-portrait-return-gray-dark-pressed.png";
			goto returnEtch_namesComputed;
		case UIKBImageReturnBlue|UIKBImageWithTransparent:
			cacheName = @"kb-ext-return-blue-transparent.png";
			srcName = @"kb-key-portrait-return-royal-blue-alert-enabled.png";
			goto returnEtch_namesComputed;
		case UIKBImageReturn|UIKBImageWithLandscape|UIKBImageWithTransparent:
			cacheName = @"kb-ext-return-landscape-transparent.png";
			srcName = @"kb-key-landscape-return-gray-dark-enabled.png";
			goto returnEtch_namesComputed;
		case UIKBImageReturnActive|UIKBImageWithLandscape|UIKBImageWithTransparent:
			cacheName = @"kb-ext-return-active-landscape-transparent.png";
			srcName = @"kb-key-landscape-return-gray-dark-pressed.png";
			goto returnEtch_namesComputed;
		case UIKBImageReturnBlue|UIKBImageWithLandscape|UIKBImageWithTransparent:
			cacheName = @"kb-ext-return-blue-landscape-transparent.png";
			srcName = @"kb-key-landscape-return-royal-blue-alert-enabled.png";
returnEtch_namesComputed:
			TryLoadCacheBegin;
			isLandscape = (actualType & UIKBImageWithLandscape) != 0;
			retimg = GUCreateUIImageAndRelease(GUImageCreateByComposition(_UIImageWithName(isLandscape ? @"kb-std-landscape-transparent-space-return-etch.png" : @"kb-std-transparent-space-return-etch.png").CGImage,
																		  _UIImageWithName(srcName).CGImage,
																		  isLandscape ? ReturnEtchRect_Landscape : ReturnEtchRect_Portrait,
																		  isLandscape ? ReturnRect_Landscape : ReturnRect_Portrait));
			TryLoadCacheEnd;
			return retimg;
			
		case UIKBImageDelete:
		case UIKBImageDeleteActive:
			cacheName = (actualType == UIKBImageDeleteActive) ? @"kb-ext-delete.png" : @"kb-ext-delete-active.png";
			TryLoadCacheBegin;
			img = CGImageCreateWithImageInRect(_UIImageWithName((actualType != UIKBImageDeleteActive) ? @"kb-std-azerty.png" : @"kb-std-active-bg-main.png").CGImage,
											   DeleteRect_Portrait);
			retimg = GUCreateUIImageAndRelease(GUImageCreateByClippingToRoundRect(img, ShiftRect_Mask_Portrait, KeyRect_Mask_Radius));
			CGImageRelease(img);
			TryLoadCacheEnd;
			return retimg;
			
		case UIKBImageDelete|UIKBImageWithTransparent:	
			return _UIImageWithName(@"kb-std-delete-transparent.png");
		case UIKBImageDeleteActive|UIKBImageWithTransparent:
			return _UIImageWithName(@"kb-std-delete-active-transparent.png");
			
		case UIKBImageDelete|UIKBImageWithLandscape:
			cacheName = @"kb-ext-delete-landscape.png";
			TryLoadCacheBegin;
			img = CGImageCreateWithImageInRect(_UIImageWithName(@"kb-std-landscape-azerty.png").CGImage, DeleteRect_Landscape);
			retimg = GUCreateUIImageAndRelease(GUImageCreateByClippingToRoundRect(img, ShiftRect_Mask_Landscape, KeyRect_Mask_Radius));
			CGImageRelease(img);
			TryLoadCacheEnd;
			return retimg;
			
		case UIKBImageDeleteActive|UIKBImageWithLandscape:
		case UIKBImageDelete|UIKBImageWithLandscape|UIKBImageWithTransparent:
		case UIKBImageDeleteActive|UIKBImageWithLandscape|UIKBImageWithTransparent:
			isActive = (actualType&~(UIKBImageWithTransparent|UIKBImageWithLandscape)) == UIKBImageDeleteActive;
			isTransparent = (actualType&UIKBImageWithTransparent) != 0;
			cacheName = [NSString stringWithFormat:@"kb-ext-delete%@-landscape%@.png",
						 isActive ? @"-active" : @"",
						 isTransparent ? @"-transparent" : @""];
			TryLoadCacheBegin;
			srcName = [NSString stringWithFormat:@"kb-std-landscape-delete%@%@.png",
					   isActive ? @"-active" : @"",
					   isTransparent ? @"-transparent" : @""];
			img = CGImageCreateWithImageInRect(_UIImageWithName(srcName).CGImage, DeleteSubRect_Landscape);
			if (!isTransparent) {
				CGImageRef premask = img;
				img = GUImageCreateByClippingToRoundRect(img, ShiftRect_Mask_Landscape, KeyRect_Mask_Radius);;// GUImageCreateWithCappedMask(premask, masks[(actualType&UIKBImageWithTransparent)?1:0], KeyCaps);
				CGImageRelease(premask);
			}
			retimg = GUCreateUIImageAndRelease(img);
			TryLoadCacheEnd;
			return retimg;
			
		case UIKBImageABC: return _UIImageWithName(@"kb-std-intl-abc.png");
		case UIKBImage123: return _UIImageWithName(@"kb-std-intl-123.png");
		case UIKBImageABC|UIKBImageWithTransparent: return _UIImageWithName(@"kb-std-transparent-intl-abc.png");
		case UIKBImage123|UIKBImageWithTransparent: return _UIImageWithName(@"kb-std-transparent-intl-123.png");			
		case UIKBImageABC|UIKBImageWithLandscape: return _UIImageWithName(@"kb-std-landscape-intl-abc.png");
		case UIKBImage123|UIKBImageWithLandscape: return _UIImageWithName(@"kb-std-landscape-intl-123.png");
		case UIKBImageABC|UIKBImageWithLandscape|UIKBImageWithTransparent: return _UIImageWithName(@"kb-std-landscape-transparent-intl-abc.png");
		case UIKBImage123|UIKBImageWithLandscape|UIKBImageWithTransparent: return _UIImageWithName(@"kb-std-landscape-transparent-intl-123.png");
			
		case UIKBImageShift123:
			cacheName = @"kb-ext-shift-123.png";
			srcName = @"kb-std-alt-shift.png";
			goto shiftSymbol_namesComputed;
		case UIKBImageShiftSymbol:
			cacheName = @"kb-ext-shift-symbol.png";
			srcName = @"kb-std-alt.png";
			goto shiftSymbol_namesComputed;
		case UIKBImageShift123|UIKBImageWithTransparent:	
			cacheName = @"kb-ext-shift-123-transparent.png";
			srcName = @"kb-std-alt-shift-transparent.png";
			goto shiftSymbol_namesComputed;
		case UIKBImageShiftSymbol|UIKBImageWithTransparent:	
			cacheName = @"kb-ext-shift-symbol-transparent.png";
			srcName = @"kb-std-alt-transparent.png";
			goto shiftSymbol_namesComputed;
		case UIKBImageShift123|UIKBImageWithLandscape:
			cacheName = @"kb-ext-shift-123-landscape.png";
			srcName = @"kb-std-alt-landscape-shift.png";
			goto shiftSymbol_namesComputed;
		case UIKBImageShiftSymbol|UIKBImageWithLandscape:
			cacheName = @"kb-ext-shift-symbol-landscape.png";
			srcName = @"kb-std-alt-landscape.png";
			goto shiftSymbol_namesComputed;
		case UIKBImageShift123|UIKBImageWithLandscape|UIKBImageWithTransparent:
			cacheName = @"kb-ext-shift-123-landscape-transparent.png";
			srcName = @"kb-std-alt-shift-landscape-transparent.png";
			goto shiftSymbol_namesComputed;
		case UIKBImageShiftSymbol|UIKBImageWithLandscape|UIKBImageWithTransparent:	
			cacheName = @"kb-ext-shift-symbol-landscape-transparent.png";
			srcName = @"kb-std-alt-landscape-transparent.png";
shiftSymbol_namesComputed:
			TryLoadCacheBegin;
			isLandscape = (actualType & UIKBImageWithLandscape) != 0;
			CGImageRef premask = CGImageCreateWithImageInRect(_UIImageWithName(srcName).CGImage, isLandscape ? ShiftRect_Landscape : ShiftRect_Portrait);
			retimg = GUCreateUIImageAndRelease(GUImageCreateByClippingToRoundRect(premask,
																				  isLandscape ? ShiftRect_Mask_Landscape : ShiftRect_Mask_Portrait,
																				  KeyRect_Mask_Radius));
			CGImageRelease(premask);
			TryLoadCacheEnd;
			return retimg;
			
		case UIKBImagePopupFlexible:
		case UIKBImagePopupFlexible|UIKBImageWithTransparent:
			return _UIImageWithName(@"kb-std-active-bg-pop-center-wide.png");
		case UIKBImagePopupCenter:
		case UIKBImagePopupCenter|UIKBImageWithTransparent:
			return _UIImageWithName(@"kb-std-active-bg-pop-center.png");
		case UIKBImagePopupLeft:
		case UIKBImagePopupLeft|UIKBImageWithTransparent:
			return _UIImageWithName(@"kb-std-active-bg-pop-left.png");
		case UIKBImagePopupRight:
		case UIKBImagePopupRight|UIKBImageWithTransparent:
			return _UIImageWithName(@"kb-std-active-bg-pop-right.png");
			
		case UIKBImagePopupFlexible|UIKBImageWithLandscape:
		case UIKBImagePopupFlexible|UIKBImageWithLandscape|UIKBImageWithTransparent:
			return _UIImageWithName(@"kb-std-landscape-active-bg-pop-center-wide.png");
		case UIKBImagePopupCenter|UIKBImageWithLandscape:
		case UIKBImagePopupCenter|UIKBImageWithLandscape|UIKBImageWithTransparent:
			return _UIImageWithName(@"kb-std-landscape-active-bg-pop-center.png");
		case UIKBImagePopupLeft|UIKBImageWithLandscape:
		case UIKBImagePopupLeft|UIKBImageWithLandscape|UIKBImageWithTransparent:
			return _UIImageWithName(@"kb-std-landscape-active-bg-pop-left.png");
		case UIKBImagePopupRight|UIKBImageWithLandscape:
		case UIKBImagePopupRight|UIKBImageWithLandscape|UIKBImageWithTransparent:
			return _UIImageWithName(@"kb-std-landscape-active-bg-pop-right.png");
			
		case UIKBImageActiveBackground:
		case UIKBImageActiveBackground|UIKBImageWithTransparent:
		case UIKBImageActiveBackground|UIKBImageWithLandscape:
		case UIKBImageActiveBackground|UIKBImageWithLandscape|UIKBImageWithTransparent:
			return nil;
	}
}

extern
float UIKBGetBrightness(UIKBImageClassType type, UIKeyboardAppearance appearance, BOOL landscape) {
	NSNumber* keyInt = [NSNumber numberWithInt:type|(appearance?UIKBImageWithTransparent:0)|(landscape?UIKBImageWithLandscape:0)];
	NSNumber* obj = [brightnesses objectForKey:keyInt];
	if (obj != nil)
		return [obj floatValue];
	else {
		float b = GUAverageLuminance(UIKBGetImage(type, appearance, landscape).CGImage);
		[brightnesses setObject:[NSNumber numberWithFloat:b] forKey:keyInt];
		return b;
	}
}

extern 
UIImage* UIKBGetImage(UIKBImageClassType type, UIKeyboardAppearance appearance, BOOL landscape) {
	ptrdiff_t actualType = type;
	if (landscape)
		actualType |= UIKBImageWithLandscape;
	if (appearance == UIKeyboardAppearanceAlert)
		actualType |= UIKBImageWithTransparent;
	
	NSNumber* key = [NSNumber numberWithInteger:actualType];
	UIImage* retImg = [cache objectForKey:key];
	if (retImg == nil) {
		retImg = constructImage(actualType);
		[cache setObject:retImg forKey:key];
	}
	
	return retImg;
}
