/*
 
 UIKBStandardKeyboardLayout.m ... Layout for customized standard keyboard.
 
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

#import <iKeyEx/UIKBStandardKeyboardLayout.h>
#import <iKeyEx/common.h>
#import <iKeyEx/ImageLoader.h>
#import <CoreGraphics/CGGeometry.h>
#import <UIKit/UIImageView.h>
#import <UIKit/UIGeometry.h>
#import <UIKit2/Functions.h>
#import <iKeyEx/UIKBKeyDefinition.h>
#import <stdlib.h>

#pragma mark -

@implementation UIKeyboardSublayout (UIKBStandardKeyboard2_h) 
-(void)setImageView:(UIImage*)img {
	// since m_imageView & m_shiftImageView may share the same instance,
	// it's safer to allocate another copy.
	[m_imageView release];
	m_imageView = [[UIImageView alloc] initWithImage:img];
}
-(void)setShiftImageView:(UIImage*)simg {
	[m_shiftImageView release];
	m_shiftImageView = [[UIImageView alloc] initWithImage:simg];
}

#define TryLoadFromCache(varName) \
	if (cached_##varName##Path != nil) { \
		varName = [UIImage imageWithContentsOfFile:cached_##varName##Path];\
		if (varName == nil) { \
			varName = keyboard.varName; \
			[UIImagePNGRepresentation(varName) writeToFile:cached_##varName##Path atomically:YES]; \
		} \
	} else \
		varName = keyboard.varName

+(UIKeyboardSublayout*)sublayoutWithFrame:(CGRect)frame keyboard:(UIKBStandardKeyboard*)keyboard keyDefinitionBuffer:(UIKeyDefinition**)keydef keyCountBuffer:(NSUInteger*)keyCount type:(NSString*)sublayoutType isAlt:(BOOL)isAlt {
	UIKeyboardAppearance appr = keyboard.keyboardAppearance;
	BOOL landscape = keyboard.landscape;
	
	NSString* cached_keydefPath = nil;
	NSString* cached_imagePath = nil;
	NSString* cached_shiftImagePath = nil;
	NSString* cached_fgImagePath = nil;
	NSString* cached_fgShiftImagePath = nil;
	
	NSString* mode = UIKeyboardGetCurrentInputMode();
	if ([mode hasPrefix:iKeyEx_Prefix]) {
		NSString* modeFilename = [mode substringFromIndex:iKeyEx_Prefix_length];
		// do caching.
		
		NSString* baseFilename = [NSString stringWithFormat:iKeyEx_CachePath@"%@-sublayout-%@-%d-", modeFilename, sublayoutType, landscape];
		
		cached_keydefPath = [baseFilename stringByAppendingString:@"keyDefinitions.plist"];
		
		baseFilename = [NSString stringWithFormat:@"%@%d-", baseFilename, appr]; 
		
		cached_imagePath = [baseFilename stringByAppendingString:@"image.png"];
		cached_shiftImagePath = [baseFilename stringByAppendingString:@"shiftImage.png"];
		cached_fgImagePath = [baseFilename stringByAppendingString:@"fgImage.png"];
		cached_fgShiftImagePath = [baseFilename stringByAppendingString:@"fgShiftImage.png"];
	}
	
	if (*keydef == NULL) {
		NSArray* keyDefArr = nil;
		
		if (cached_keydefPath != nil) {
			//keyDefArr = [NSKeyedUnarchiver unarchiveObjectWithFile:cached_keydefPath];
			keyDefArr = [UIKBKeyDefinition deserializeArrayFromFile:cached_keydefPath];
			if (keyDefArr == nil) {
				keyDefArr = keyboard.keyDefinitions;
				[UIKBKeyDefinition serializeArray:keyDefArr toFile:cached_keydefPath];
			}
		} else
			keyDefArr = keyboard.keyDefinitions;
		
		*keyCount = [keyDefArr count];
		*keydef = malloc(*keyCount * sizeof(UIKeyDefinition));
		
		[UIKBKeyDefinition fillArray:keyDefArr toBuffer:*keydef];
	}
	
	UIImage* image, *shiftImage, *fgImage, *fgShiftImage;
	TryLoadFromCache(image);
	TryLoadFromCache(shiftImage);
	TryLoadFromCache(fgImage);
	TryLoadFromCache(fgShiftImage);
	
	UIKeyboardSublayout* sl = [UIKeyboardSublayout compositedSublayoutWithFrame:frame
															compositeImagePaths:[NSArray arrayWithObjects:@"UIPageIndicator.png", @"UIPageIndicator.png", nil]
																		   keys:*keydef
																	  keysCount:*keyCount];
	
	[sl setUsesAutoShift:!isAlt];
	[sl setIsShiftKeyPlaneChooser:isAlt];
	
	[sl setImageView:image];
	[sl setShiftImageView:shiftImage];
	
	[sl setRegistersKeyCentroids:YES];
	[sl registerKeyCentroids];
	[sl setUsesKeyCharges:YES];
	
	[sl setCompositeImage:UIKBGetImage(UIKBImagePopupFlexible, appr, landscape) forKey:@"_pop_center2_"];
	[sl setCompositeImage:UIKBGetImage(UIKBImagePopupCenter, appr, landscape) forKey:@"_pop_center1_"];
	[sl setCompositeImage:UIKBGetImage(UIKBImagePopupLeft, appr, landscape) forKey:@"_pop_left_"];
	[sl setCompositeImage:UIKBGetImage(UIKBImagePopupRight, appr, landscape) forKey:@"_pop_right_"];
	
	[sl setCompositeImage:fgImage forKey:@"_letters_fg_main_"];
	[sl setCompositeImage:fgShiftImage forKey:@"_letters_fg_main_shift_"];
	[sl setCompositeImage:fgImage forKey:@"_letters_fg_alt_"];
	[sl setCompositeImage:fgShiftImage forKey:@"_letters_fg_alt_shift_"];
	
	// actual location of the shift.
	if (keyboard.hasShiftKey && keyboard.shiftKeyEnabled) {
		NSUInteger skl = keyboard.shiftKeyLeft;
		UIImage* shiftImg, *shiftLockImg;
		if (keyboard.shiftStyle == UIKBShiftStyle123) {
			shiftLockImg = shiftImg = UIKBGetImage(UIKBImageShift123, appr, landscape);
		} else {
			shiftImg = UIKBGetImage(UIKBImageShiftActive, appr, landscape);
			shiftLockImg = UIKBGetImage(UIKBImageShiftLocked, appr, landscape);
		}
		CGRect shiftRect = landscape ? CGRectMake(5+skl, 84, 62, 38) : CGRectMake(skl, 118, 42, 44);
		[sl setShiftButtonImage:shiftImg frame:shiftRect];
		[sl setAutoShiftButtonImage:shiftImg frame:shiftRect];
		[sl setShiftLockedButtonImage:shiftLockImg frame:shiftRect];
	}
	if (keyboard.hasDeleteKey) {
		NSUInteger dlr = keyboard.deleteKeyRight;
		CGRect delRect = landscape ? CGRectMake(keyboard.keyboardSize.width-66-dlr, 84, 66, 38) : CGRectMake(keyboard.keyboardSize.width-42-dlr, 118, 42, 43);
		[sl setDeleteButtonImage:UIKBGetImage(UIKBImageDelete, appr, landscape) frame:delRect];
		[sl setDeleteActiveButtonImage:UIKBGetImage(UIKBImageDeleteActive, appr, landscape) frame:delRect];
	}
	
	[sl addInternationalKeyIfNeeded:sublayoutType];
	
	// FIXME: Because BOOL IsTransparentKeyboardLayout(NSString*) compares the
	//        argument by POINTER instead of VALUE, the space bar & return key
	//        will *always* be opaque.
	if (keyboard.hasSpaceKey)
		[sl addSpaceKeyViewIfNeeded:sublayoutType];
	if (keyboard.hasReturnKey)
		[sl addReturnKeyViewIfNeeded:sublayoutType];
	
	return sl;
}
@end

#pragma mark -

#define CreateBuildMethod(sublayoutType, landsc, typeName, isAlt_) \
-(id)buildUIKeyboardLayout##sublayoutType { \
	UIKBStandardKeyboard* keyboard = [UIKBStandardKeyboard keyboardWithBundle:[KeyboardBundle activeBundle] \
										name:@#sublayoutType \
										landscape:landsc \
										appearance:UIKeyboardAppearanceDefault]; \
	if (keyboard == nil) \
		return [super buildUIKeyboardLayout##sublayoutType]; \
	else { \
		return [UIKeyboardSublayout sublayoutWithFrame:self.frame \
					keyboard:keyboard \
					keyDefinitionBuffer:(keyDefs+UIKBSublayout##sublayoutType) \
					keyCountBuffer:(keyCounts+UIKBSublayout##sublayoutType) \
					type:typeName \
					isAlt:isAlt_]; \
	} \
} \
 

#define CreateBuildMethodTransparent(sublayoutType, landsc, typeName, isAlt_) \
-(id)buildUIKeyboardLayout##sublayoutType##Transparent { \
	UIKBStandardKeyboard* keyboard = [UIKBStandardKeyboard keyboardWithBundle:[KeyboardBundle activeBundle] \
										name:@#sublayoutType \
										landscape:landsc \
										appearance:UIKeyboardAppearanceAlert]; \
	if (keyboard == nil) \
		return [super buildUIKeyboardLayout##sublayoutType##Transparent]; \
	else { \
		return [UIKeyboardSublayout sublayoutWithFrame:self.frame \
					keyboard:keyboard \
					keyDefinitionBuffer:(keyDefs+UIKBSublayout##sublayoutType) \
					keyCountBuffer:(keyCounts+UIKBSublayout##sublayoutType) \
					type:typeName \
					isAlt:isAlt_]; \
	} \
} \
 

#define CreateBuildMethods(sublayoutType, landsc, typeName, isAlt) \
CreateBuildMethod(sublayoutType, landsc, typeName, isAlt); \
CreateBuildMethodTransparent(sublayoutType, landsc, typeName @"trans_", isAlt);

void resizePopupImage (BOOL landscape, UIView* m_activeKeyView, UIKeyDefinition* keydef) {
	CGSize oldSize = m_activeKeyView.bounds.size;
	for (UIImageView* v in m_activeKeyView.subviews) {
		if ([v isKindOfClass:[UIImageView class]]) {
			CGRect tempBounds2 = v.frame;
			if (tempBounds2.size.height == oldSize.height) {
				tempBounds2.size.width = oldSize.width;
				tempBounds2.origin = CGPointZero;
				v.image = UIKBGetImage(UIKBImagePopupFlexible, UIKeyboardAppearanceDefault, landscape);
				v.frame = tempBounds2;
				v.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0.5 alpha:0.5];
				break;
			}
		}
	}
}

#pragma mark -

@implementation UIKBStandardKeyboardLayout
-(void)dealloc {
	for (NSUInteger i = 0; i < UIKBSublayoutCount; ++ i) {
		for (NSUInteger j = 0; j < keyCounts[i]; ++ j) {
			[keyDefs[i][j].value release];
			[keyDefs[i][j].shifted release];
			[keyDefs[i][j].pop_type release];
		}
		free(keyDefs[i]);
	}
	[super dealloc];
}
-(id)initWithFrame:(CGRect)frame {
	if ((self = [super initWithFrame:frame])) {
		for (NSUInteger i = 0; i < UIKBSublayoutCount; ++ i) {
			keyDefs[i] = NULL;
			keyCounts[i] = 0;
		}
	}
	return self;
}

CreateBuildMethods(Alphabet, NO, @"_abc_", NO);
CreateBuildMethods(Numbers, NO, @"_123_", YES);
CreateBuildMethods(PhonePad, NO, @"_phone_", NO);
CreateBuildMethods(PhonePadAlt, NO, @"_phone_alt_", YES);
CreateBuildMethods(NumberPad, NO, @"_number_pad_", NO);
CreateBuildMethods(URL, NO, @"_url_", NO);
CreateBuildMethods(URLAlt, NO, @"_url_alt_", YES);
CreateBuildMethods(SMSAddressing, NO, @"_sms_", NO);
CreateBuildMethods(SMSAddressingAlt, NO, @"_sms_alt_", YES);
CreateBuildMethods(EmailAddress, NO, @"_email_", NO);
CreateBuildMethods(EmailAddressAlt, NO, @"_email_alt_", YES);

// fix the flexible popup to make it really flexible.
// Can we hide the frame change?
-(void)activateCompositeKey:(UIKeyDefinition*)keydef {
	// can
	[super activateCompositeKey:keydef];
	if ([keydef->pop_type isEqualToString:@"_pop_center2_"])
		resizePopupImage(NO, m_activeKeyView, keydef);
}

@end

#pragma mark -

@implementation UIKBStandardKeyboardLayoutLandscape
-(void)dealloc {
	for (NSUInteger i = 0; i < UIKBSublayoutCount; ++ i)
		free(keyDefs[i]);
	[super dealloc];
}
-(id)initWithFrame:(CGRect)frame {
	if ((self = [super initWithFrame:frame])) {
		for (NSUInteger i = 0; i < UIKBSublayoutCount; ++ i) {
			keyDefs[i] = NULL;
			keyCounts[i] = 0;
		}
	}
	return self;
}

CreateBuildMethods(Alphabet, YES, @"_abc_", NO);
CreateBuildMethods(Numbers, YES, @"_123_", YES);
CreateBuildMethods(PhonePad, YES, @"_phone_", NO);
CreateBuildMethods(PhonePadAlt, YES, @"_phone_alt_", YES);
CreateBuildMethods(NumberPad, YES, @"_number_pad_", NO);
CreateBuildMethods(URL, YES, @"_url_", NO);
CreateBuildMethods(URLAlt, YES, @"_url_alt_", YES);
CreateBuildMethods(SMSAddressing, YES, @"_sms_", NO);
CreateBuildMethods(SMSAddressingAlt, YES, @"_sms_alt_", YES);
CreateBuildMethods(EmailAddress, YES, @"_email_", NO);
CreateBuildMethods(EmailAddressAlt, YES, @"_email_alt_", YES);

// fix the flexible popup to make it really flexible.
-(void)activateCompositeKey:(UIKeyDefinition*)keydef {
	[super activateCompositeKey:keydef];
	if ([keydef->pop_type isEqualToString:@"_pop_center2_"])
		resizePopupImage(YES, m_activeKeyView, keydef);
}

@end
