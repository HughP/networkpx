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
static CGImageRef masks[2];
static NSMutableDictionary* brightnesses = nil;

//------------------------------------------------------------------------------
#pragma mark -
#pragma mark Constants
//------------------------------------------------------------------------------

static const CGRect BackgroundRect1_Portrait = {{159, 0}, {2, 172}};
static const CGRect BackgroundRect2_Portrait = {{79, 172}, {2, 44}};
static const CGRect BackgroundRectT_Portrait = {{159, 0}, {2, 216}};
static const CGRect BackgroundRect_Landscape = {{238, 0}, {4, 162}};

static const GUCaps KeyCaps = {7, 7, 7, 7};

static const CGRect KeyRect_Key_Portrait = {{225, 10}, {30, 43}};
static const CGRect KeyRect_ISrc_Portrait = {{ 9, 13}, {4, 17}};
static const CGRect KeyRect_ITrg_Portrait = {{13, 13}, {4, 17}};

static const CGRect KeyRect_Key_Landscape = {{336, 4}, {43, 36}};
static const CGRect KeyRect_ISrc_Landscape = {{15, 9}, {4, 17}};
static const CGRect KeyRect_ITrg_Landscape = {{19, 9}, {4, 17}};

static const CGRect KeyRect1_Portrait = {{224, 10}, {8, 44}};
static const CGRect KeyRect2_Portrait = {{249, 10}, {7, 44}};
static const CGRect KeyRect1_Ladnscape = {{334, 4}, {9, 38}};
static const CGRect KeyRect2_Ladnscape = {{373, 4}, {8, 38}};

static const CGRect ShiftRect_Portrait = {{0, 118}, {42, 43}};
static const CGRect ShiftDrawRect_Portrait = {{1, 1}, {40, 41}};
static const CGRect ShiftRect_Landscape = {{6, 84}, {58, 38}};
static const CGRect ShiftDrawRect_Landscape = {{-6, -5}, {76, 42.75}};	// -5 counted from bottom, not top. 
static const CGRect ShiftSubRect_Landscape = {{6, 0}, {58, 38}};

static const CGSize InternationalSize_Portrait = {37, 43};
static const CGSize InternationalSize_Landscape = {47, 38};

static const CGRect SpaceRect_Portrait = {{0, 0}, {160, 44}};
static const CGRect SpaceRect_Landscape = {{0, 0}, {283, 38}};
static const CGRect SpaceEtchRect_Portrait = {{-2, 0}, {246, 9}};
static const CGRect SpaceEtchRect_Landscape = {{0, 0}, {381, 8}};

static const CGRect ReturnRect_Portrait = {{0, 0}, {80, 44}};
static const CGRect ReturnRect_Landscape = {{0, 0}, {98, 38}};
static const CGRect ReturnEtchRect_Portrait = {{-162, 0}, {246, 9}};
static const CGRect ReturnEtchRect_Landscape = {{-283, 0}, {381, 8}};

static const CGRect DeleteRect_Portrait = {{278, 118}, {42, 43}};
static const CGRect DeleteRect_Landscape = {{416, 84}, {57, 38}};
static const CGRect DeleteSubRect_Landscape = {{2, 0}, {57, 38}};

//------------------------------------------------------------------------------
#pragma mark -
#pragma mark Initializer & Terminators
//------------------------------------------------------------------------------

// Call these functions once in a lifetime only.
void UIKBInitializeImageCache () {
#if TARGET_IPHONE_SIMULATOR
	masks[0] = CGImageRetain([UIImage imageNamed:@"key.png"].CGImage);
	masks[1] = CGImageRetain([UIImage imageNamed:@"key-transparent.png"].CGImage);
#else
	masks[0] = GUImageCreateWithPNG("/Library/iKeyEx/Masks/key.png");
	masks[1] = GUImageCreateWithPNG("/Library/iKeyEx/Masks/key-transparent.png");
#endif
	brightnesses = [[NSMutableDictionary alloc] initWithContentsOfFile:iKeyEx_InternalCachePath@"brightnesses.plist"];
	cache = [[NSMutableDictionary alloc] initWithCapacity:4*UIKBImageTypesCount];
}

void UIKBClearImageCache() {
	[brightnesses writeToFile:iKeyEx_InternalCachePath@"brightnesses.plist" atomically:NO];
	[brightnesses release];
	CGImageRelease(masks[0]);
	CGImageRelease(masks[1]);
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
#define TrySetBrightness

#else

#define TryLoadCacheBegin \
retimg = _UIImageWithName(cacheName); \
if (retimg == nil) { \
	cachePath = [iKeyEx_InternalCachePath stringByAppendingString:cacheName]; \
	retimg = [UIImage imageWithContentsOfFile:cachePath]; \
} \
if (retimg == nil) {

#define TryLoadCacheEnd [UIImagePNGRepresentation(retimg) writeToFile:(cachePath) atomically:NO]; }

#define TrySetBrightness \
if (![brightnesses objectForKey:keyNum]) { \
	[brightnesses setObject:[NSNumber numberWithFloat:GUAverageLuminance(retimg.CGImage)] forKey:keyNum]; \
	[brightnesses writeToFile:iKeyEx_InternalCachePath@"brightnesses.plist" atomically:NO]; \
}

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
			TrySetBrightness;
			return retimg;
			
		case UIKBImageBackground|UIKBImageWithTransparent: 
			cacheName = @"kb-ext-background-transparent.png";
			TryLoadCacheBegin;
			img = CGImageCreateWithImageInRect(_UIImageWithName(@"kb-std-azerty-transparent.png").CGImage,
											   BackgroundRectT_Portrait);
			retimg = GUCreateUIImageAndRelease(img);
			TryLoadCacheEnd;
			TrySetBrightness;
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
			TrySetBrightness;
			return retimg;
			
		case UIKBImageKey:
			// whoever creates these inconsistent naming schemes should be banned from software designing immediately.
			cacheName = @"kb-ext-key.png";
			srcName = @"kb-std-azerty.png";
			goto key_namesComputed;
		case UIKBImageKey|UIKBImageWithTransparent:
			cacheName = @"kb-ext-key-transparent.png";
			srcName = @"kb-std-azerty-transparent.png";
			goto key_namesComputed;
		case UIKBImageKey|UIKBImageWithLandscape:
			cacheName = @"kb-ext-key-landscape.png";
			srcName = @"kb-std-landscape-azerty.png";
			goto key_namesComputed;
		case UIKBImageKey|UIKBImageWithLandscape|UIKBImageWithTransparent:
			cacheName = @"kb-ext-key-landscape-transparent.png";
			srcName = @"kb-std-landscape-transparent-azerty.png";
key_namesComputed:
			TryLoadCacheBegin;
			isLandscape = (actualType & UIKBImageWithLandscape) != 0;			
			// Get the "I" key.
			CGImageRef ikey = CGImageCreateWithImageInRect(_UIImageWithName(srcName).CGImage, 
														   isLandscape ? KeyRect_Key_Landscape : KeyRect_Key_Portrait);
			// Cover the "I" letter.
			CGImageRef premask = GUImageCreateWithPatching(ikey,
														   isLandscape ? KeyRect_ISrc_Landscape : KeyRect_ISrc_Portrait,
														   isLandscape ? KeyRect_ITrg_Landscape : KeyRect_ITrg_Portrait);
			img = GUImageCreateWithCappedMask(premask, masks[(actualType&UIKBImageWithTransparent)?1:0], KeyCaps);
			
			retimg = GUCreateUIImageAndRelease(img);
			CGImageRelease(premask);
			CGImageRelease(ikey);
			TryLoadCacheEnd;
			TrySetBrightness;
			return retimg;
			
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
			img = GUImageCreateWithCappedMask(premask, masks[0], KeyCaps);
			retimg = GUCreateUIImageAndRelease(img);
			CGImageRelease(premask);
			TryLoadCacheEnd;
			return retimg;
			
		case UIKBImageShiftActive:
		case UIKBImageShiftActive|UIKBImageWithLandscape:
			isLandscape = (actualType & UIKBImageWithLandscape) != 0;
			cacheName = isLandscape ? @"kb-ext-shift-active-landscape.png" : @"kb-ext-shift-active.png";
			TryLoadCacheBegin;
			CGRect imgRect = isLandscape ? ShiftRect_Landscape : ShiftRect_Portrait;
			GUCreateContext(c, imgRect.size.width, imgRect.size.height);
			GUDrawImageWithCaps(c, CGRectMake(0, 0, imgRect.size.width, imgRect.size.height), masks[0], KeyCaps);
			CGContextSetBlendMode(c, kCGBlendModeSourceIn);
			CGContextDrawImage(c, isLandscape ? ShiftDrawRect_Landscape : ShiftDrawRect_Portrait,
							   _UIImageWithName(isLandscape ? @"kb-std-landscape-shift.png" : @"kb-std-shift.png").CGImage);
			img = CGBitmapContextCreateImage(c);
			retimg = GUCreateUIImageAndRelease(img);
			CGContextRelease(c);
			TryLoadCacheEnd;
			return retimg;
			
		case UIKBImageShiftLocked:
		case UIKBImageShiftLocked|UIKBImageWithLandscape:
			isLandscape = (actualType & UIKBImageWithLandscape) != 0;
			cacheName = isLandscape ? @"kb-ext-shift-locked-landscape.png" : @"kb-ext-shift-locked.png";
			TryLoadCacheBegin;
			CGSize imgSize = isLandscape ? ShiftRect_Landscape.size : ShiftRect_Portrait.size;
			img = GUImageCreateByComposition(_UIImageWithName(isLandscape ? @"kb-std-landscape-shift-locked.png" : @"kb-std-shift-locked.png").CGImage,
											 UIKBGetImage(UIKBImageShift, UIKeyboardAppearanceDefault, isLandscape).CGImage,
											 isLandscape ? ShiftDrawRect_Landscape : ShiftDrawRect_Portrait,
											 CGRectMake(0, 0, imgSize.width, imgSize.height));
			retimg = GUCreateUIImageAndRelease(img);
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
			img = GUImageCreateWithCappedMask(premask, masks[0], KeyCaps);
			retimg = GUCreateUIImageAndRelease(img);
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
			img = GUImageCreateByComposition(_UIImageWithName(isLandscape ? @"kb-std-landscape-transparent-intl-globe-active.png" :  @"kb-std-transparent-intl-globe-active.png").CGImage,
											 UIKBGetImage(UIKBImageInternationalActive, UIKBImageWithTransparent, isLandscape).CGImage,
											 imgRect, imgRect);
			retimg = GUCreateUIImageAndRelease(img);
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
			img = GUImageCreateByComposition(_UIImageWithName(isLandscape ? @"kb-std-landscape-transparent-space-return-etch.png" : @"kb-std-transparent-space-return-etch.png").CGImage,
											 _UIImageWithName(srcName).CGImage,
											 isLandscape ? SpaceEtchRect_Landscape : SpaceEtchRect_Portrait,
											 isLandscape ? SpaceRect_Landscape : SpaceRect_Portrait);
			retimg = GUCreateUIImageAndRelease(img);
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
			img = GUImageCreateByComposition(_UIImageWithName(isLandscape ? @"kb-std-landscape-transparent-space-return-etch.png" : @"kb-std-transparent-space-return-etch.png").CGImage,
											 _UIImageWithName(srcName).CGImage,
											 isLandscape ? ReturnEtchRect_Landscape : ReturnEtchRect_Portrait,
											 isLandscape ? ReturnRect_Landscape : ReturnRect_Portrait);
			retimg = GUCreateUIImageAndRelease(img);
			TryLoadCacheEnd;
			return retimg;
			
		case UIKBImageDelete:
		case UIKBImageDeleteActive:
			cacheName = (actualType == UIKBImageDeleteActive) ? @"kb-ext-delete.png" : @"kb-ext-delete-active.png";
			TryLoadCacheBegin;
			img = CGImageCreateWithImageInRect(_UIImageWithName((actualType == UIKBImageDeleteActive) ? @"kb-std-azerty.png" : @"kb-std-active-bg-main.png").CGImage,
											   DeleteRect_Portrait);
			retimg = GUCreateUIImageAndRelease(img);
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
			retimg = GUCreateUIImageAndRelease(img);
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
				img = GUImageCreateWithCappedMask(premask, masks[(actualType&UIKBImageWithTransparent)?1:0], KeyCaps);
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
			
		case UIKBImageShiftSymbol:
			cacheName = @"kb-ext-shift-symbol.png";
			srcName = @"kb-std-alt.png";
			goto shiftSymbol_namesComputed;
		case UIKBImageShift123:
			cacheName = @"kb-ext-shift-123.png";
			srcName = @"kb-std-alt-shift.png";
			goto shiftSymbol_namesComputed;
		case UIKBImageShiftSymbol|UIKBImageWithTransparent:	
			cacheName = @"kb-ext-shift-symbol-transparent.png";
			srcName = @"kb-std-alt-transparent.png";
			goto shiftSymbol_namesComputed;
		case UIKBImageShift123|UIKBImageWithTransparent:	
			cacheName = @"kb-ext-shift-123-transparent.png";
			srcName = @"kb-std-alt-shift-transparent.png";
			goto shiftSymbol_namesComputed;
		case UIKBImageShiftSymbol|UIKBImageWithLandscape:
			cacheName = @"kb-ext-shift-symbol-landscape.png";
			srcName = @"kb-std-alt-landscape.png";
			goto shiftSymbol_namesComputed;
		case UIKBImageShift123|UIKBImageWithLandscape:
			cacheName = @"kb-ext-shift-123-landscape.png";
			srcName = @"kb-std-alt-landscape-shift.png";
			goto shiftSymbol_namesComputed;
		case UIKBImageShiftSymbol|UIKBImageWithLandscape|UIKBImageWithTransparent:
			cacheName = @"kb-ext-shift-symbol-landscape-transparent.png";
			srcName = @"kb-std-alt-landscape-shift-transparent.png";
			goto shiftSymbol_namesComputed;
		case UIKBImageShift123|UIKBImageWithLandscape|UIKBImageWithTransparent:	
			cacheName = @"kb-ext-shift-123-landscape-transparent.png";
			srcName = @"kb-std-alt-shift-landscape-transparent.png";
shiftSymbol_namesComputed:
			TryLoadCacheBegin;
			isLandscape = (actualType & UIKBImageWithLandscape) != 0;
			CGImageRef premask = CGImageCreateWithImageInRect(_UIImageWithName(srcName).CGImage, isLandscape ? ShiftRect_Landscape : ShiftRect_Portrait);
			img = GUImageCreateWithCappedMask(premask, masks[(actualType&UIKBImageWithTransparent)?1:0], KeyCaps);
			retimg = GUCreateUIImageAndRelease(img);
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
	if ([obj respondsToSelector:@selector(floatValue)])
		return [obj floatValue];
	else
		return NAN;
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
