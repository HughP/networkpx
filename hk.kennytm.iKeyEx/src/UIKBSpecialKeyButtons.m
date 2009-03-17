/*
 
 UIKBSpecialKeyButtons.m .... Individual special keyboard buttons.
 
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


#import <iKeyEx/UIKBSpecialKeyButtons.h>
#import <iKeyEx/common.h>
#import <iKeyEx/UIKBSound.h>
#import <iKeyEx/ImageLoader.h>
#import <UIKit2/UIKeyboardImpl.h>
#import <UIKit2/Functions.h>

static const BOOL UIKBReturnKeyBlues[] = {NO, YES, YES, YES, YES, YES, YES, YES, YES, YES, NO};
static const CGFloat UIKBKeyButtonFontSize = 16;
static const CGFloat UIKBColor_SteelBlueDark[] = {0.322, 0.361, 0.412, 1};
static const CGFloat UIKBColor_White50Percent[] = {1, 1, 1, 0.5};
static const CGFloat UIKBColor_Black50Percent[] = {0, 0, 0, 0.5};
static const CGFloat UIKBColor_Gray37Percent[] = {0.375, 0.375, 0.375, 1};

// KLS stands for "Keyboard Localized String"
// UIKeyboardLocalizedString crashes whenever the key is unregconized, so maybe we should construct a safer alternative with inline functions?
#define KLS(x) UIKeyboardLocalizedString(@"UI-"x, systemLocaleID, nil)

// TODO: Replace Space Bar & Return Key as a wrapper of UIKeyboardSpaceKeyView & UIKeyboardReturnKeyView

#pragma mark -
//------------------------------------------------------------------------------
// The base class of all _special_ key buttons on the iPhone keyboard.

@implementation UIKBSpecialKeyButton

@synthesize keyboardAppearance;
-(void)setKeyboardAppearance:(UIKeyboardAppearance)appearence {
	if (keyboardAppearance != appearence) {
		keyboardAppearance = appearence;
		[self update];
	}
}

@synthesize landscape;
-(void)setLandscape:(BOOL)landsc {
	if (landsc != landscape) {
		landscape = landsc;
		[self update];
	}
}

-(UIKBSpecialKeyButton*)init {
	if ((self = [super init])) {
		landscape = NO;
		keyboardAppearance = UIKeyboardAppearanceDefault;
		
		[self setTitleColor:UIColorWith(UIKBColor_White50Percent) forState:UIControlStateDisabled];
		[self setTextColorIsWhite:YES];
		
		self.font = [UIFont boldSystemFontOfSize:UIKBKeyButtonFontSize];
		self.lineBreakMode = UILineBreakModeWordWrap;
		self.backgroundColor = [UIColor clearColor];
		
		systemLocaleID = [[[NSLocale systemLocale] localeIdentifier] retain];
		
		[UIKBSound registerButton:self];
	}
	return self;
}

-(void)setImagesWithNormal:(UIImage*)normal active:(UIImage*)active disabled:(UIImage*)disabled {
	[self setBackgroundImage:normal forState:UIControlStateNormal];
	[self setBackgroundImage:active forState:UIControlStateHighlighted];
	[self setBackgroundImage:disabled forState:UIControlStateDisabled];
}
-(void)setImagesWithNormal:(UIImage*)normal active:(UIImage*)active { [self setImagesWithNormal:normal active:active disabled:normal]; }
-(void)setImagesWithNormal:(UIImage*)normal { [self setImagesWithNormal:normal active:normal disabled:normal]; }

-(BOOL)textColorIsWhite { return textColorIsWhite; }
-(void)setTextColorIsWhite:(BOOL)isWhiteAtNormalState {
	if (isWhiteAtNormalState) {
		[self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
		[self setTitleShadowColor:UIColorWith(UIKBColor_Black50Percent) forState:UIControlStateNormal];
		self.titleShadowOffset = CGSizeMake(0, -1);
	} else {
		if (keyboardAppearance == UIKeyboardAppearanceAlert) {
			[self setTitleColor:UIColorWith(UIKBColor_Gray37Percent) forState:UIControlStateNormal];
		} else {
			[self setTitleColor:UIColorWith(UIKBColor_SteelBlueDark) forState:UIControlStateNormal];
		}
		[self setTitleShadowColor:UIColorWith(UIKBColor_White50Percent) forState:UIControlStateNormal];
		self.titleShadowOffset = CGSizeMake(0, 1);
	}
	textColorIsWhite = isWhiteAtNormalState;
}
-(void)setText:(NSString*)titleText {
	[self setTitle:titleText forState:UIControlStateNormal];
	[self update];
	
}
-(void)update {
	[self setTextColorIsWhite:textColorIsWhite];
	
	UIFont* tempFont = [UIFont boldSystemFontOfSize:UIKBKeyButtonFontSize];
	
	CGFloat evalWidth = [self.currentTitle sizeWithFont:tempFont].width;
	CGFloat widthRatio = (self.frame.size.width - 16)/evalWidth;
	if (!(widthRatio <= 1)) widthRatio = 1;
	if (widthRatio < 1 && widthRatio > 0)
		self.font = [tempFont fontWithSize:(UIKBKeyButtonFontSize * widthRatio)];
	else
		self.font = tempFont;
	
}

-(BOOL)shouldDrillHole { return NO; }

+(CGRect)defaultFrameWithLandscape:(BOOL)landsc { return CGRectNull; }

-(void)dealloc {
	[systemLocaleID release];
	[super dealloc];
}
@end


#pragma mark -
//------------------------------------------------------------------------------
// The "international" (globe) button for switching input mode.

@implementation UIKBInternationalButton
-(void)update {
	[self setImagesWithNormal:UIKBGetImage(UIKBImageInternational, keyboardAppearance, landscape)
					   active:UIKBGetImage(UIKBImageInternationalActive, keyboardAppearance, landscape)];
	
	self.frame = [UIKBInternationalButton defaultFrameWithLandscape:landscape];
	
	[super update];
}

-(void)timeForLongPress {
	[self cancelTimeForLongPress];
	activationDate = [[NSDate alloc] init];
	longPressTimer = [[NSTimer scheduledTimerWithTimeInterval:1 target:[UIKBSound class] selector:@selector(play) userInfo:nil repeats:NO] retain];
	
}
-(void)cancelTimeForLongPress {
	[longPressTimer invalidate];
	[longPressTimer release];
	longPressTimer = nil;
	[activationDate release];
	activationDate = nil;
}

-(void)setInputModeToNextInPreferredList {
	UIKeyboardImpl* impl = [UIKeyboardImpl sharedInstance];
	if ([activationDate timeIntervalSinceNow] <= -1) {
		[impl setInputModeLastChosenPreference];
		[impl setInputMode:iKeyEx_KeyboardChooser];
	} else
		[impl setInputModeToNextInPreferredList];
		
	[activationDate release];
	activationDate = nil;
}
-(void)dealloc {
	[self cancelTimeForLongPress];
	[super dealloc];
}

-(UIKBInternationalButton*)init {
	if ((self = (UIKBInternationalButton*)[super init])) {
		[self addTarget:self action:@selector(timeForLongPress) forControlEvents:UIControlEventTouchDown];
		[self addTarget:self action:@selector(setInputModeToNextInPreferredList) forControlEvents:UIControlEventTouchUpInside];
		[self addTarget:self action:@selector(cancelTimeForLongPress) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragOutside];
		[self update];
	}
	return self;
}

+(UIKBInternationalButton*)buttonWithLandscape:(BOOL)landsc appearance:(UIKeyboardAppearance)appr {
	UIKBInternationalButton* myButton = [[[UIKBInternationalButton alloc] init] autorelease];
	myButton->landscape = landsc;
	myButton->keyboardAppearance = appr;
	[myButton update];
	return myButton;
}

+(CGRect)defaultFrameWithLandscape:(BOOL)landsc { return landsc ? CGRectMake(52, 124, 47, 38) : CGRectMake(43, 173, 37, 43); }
@end


#pragma mark -
//------------------------------------------------------------------------------
// The space bar.

@implementation UIKBSpaceBarButton

@synthesize confirmCandidateOnClick;

-(void)click {
	UIKeyboardImpl* impl = [UIKeyboardImpl sharedInstance];
	
	if([[impl candidateList] count] > 0) {
		if (confirmCandidateOnClick)
			[impl acceptCurrentCandidate];
		else
			[impl showNextCandidates];
	} else
		[impl handleStringInput:@" "];
}

-(void)update {
	[self setImagesWithNormal:UIKBGetImage(UIKBImageSpace, keyboardAppearance, landscape)
					   active:UIKBGetImage(UIKBImageSpaceActive, keyboardAppearance, landscape)];
	
	self.frame = [UIKBSpaceBarButton defaultFrameWithLandscape:landscape];
	
	[super update];
}

-(UIKBSpaceBarButton*)init {
	if ((self = (UIKBSpaceBarButton*)[super init])) {
		confirmCandidateOnClick = NO;
		self.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 3, 0);
		[self setText:KLS(@"Space")];
		[self setTextColorIsWhite:NO];
		[self addTarget:self action:@selector(click) forControlEvents:UIControlEventTouchUpInside];
	}
	return self;
}
+(UIKBSpaceBarButton*)buttonWithLandscape:(BOOL)landsc appearance:(UIKeyboardAppearance)appr {
	UIKBSpaceBarButton* myButton = [[[UIKBSpaceBarButton alloc] init] autorelease];
	myButton->landscape = landsc;
	myButton->keyboardAppearance = appr;
	[myButton update];
	return myButton;
}

+(CGRect)defaultFrameWithLandscape:(BOOL)landsc { return landsc ? CGRectMake(99, 125, 283, 38) : CGRectMake(80, 172, 160, 44); }
@end


#pragma mark -
//------------------------------------------------------------------------------
// The return key.

@implementation UIKBReturnKeyButton

-(void)update {
	[self setImagesWithNormal:UIKBGetImage(isRoyalBlue?UIKBImageReturnBlue:UIKBImageReturn, keyboardAppearance, landscape)
					   active:UIKBGetImage(UIKBImageReturnActive, keyboardAppearance, landscape)
					 disabled:UIKBGetImage(UIKBImageReturn, keyboardAppearance, landscape)];
	
	self.frame = [UIKBReturnKeyButton defaultFrameWithLandscape:landscape];
	
	[super update];
}

@dynamic returnKeyType;
-(UIReturnKeyType)returnKeyType { return returnKeyType; }
-(void)setReturnKeyType:(UIReturnKeyType)type {
	if (type != returnKeyType && type >= 0 && type <= UIReturnKeyEmergencyCall) {
		[self setText:[titles objectAtIndex:type]];
		if (isRoyalBlue != UIKBReturnKeyBlues[type]) {
			isRoyalBlue = UIKBReturnKeyBlues[type];
			[self update];
		}
		returnKeyType = type;
	}
}

-(void)setText:(NSString*)title forType:(UIReturnKeyType)type {
	if (type >= 0 && type <= UIReturnKeyEmergencyCall) {
		[titles replaceObjectAtIndex:type withObject:title];
		if (type == returnKeyType)
			[self setText:title];
	}
}

-(void)onClick {
	UIKeyboardImpl* impl = [UIKeyboardImpl sharedInstance];
	
	if([[impl candidateList] count] > 0) {
		[impl acceptCurrentCandidate];
	} else {
		[impl handleStringInput:@"\n"];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"UIKeyboardReturnKeyPressed" object:nil];
	}
}

-(UIKBReturnKeyButton*)init {
	if ((self = (UIKBReturnKeyButton*)[super init])) {
		NSString* returnStr = KLS(@"Return");
		titles = [[NSMutableArray alloc] initWithObjects:returnStr, 
				  KLS(@"Go"),
				  @"Google",
				  KLS(@"Join"),
				  KLS(@"Next"),
				  KLS(@"Route"),
				  KLS(@"Search"),
				  KLS(@"Send"),
				  @"Yahoo",
				  KLS(@"Done"),
				  KLS(@"EmergencyCall"), nil];
		isRoyalBlue = NO;
		returnKeyType = UIReturnKeyDefault;
		self.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 3, 0);
		[self setText:returnStr];
		[self addTarget:self action:@selector(onClick) forControlEvents:UIControlEventTouchUpInside];
	}
	return self;
}
+(UIKBReturnKeyButton*)buttonWithType:(UIReturnKeyType)type landscape:(BOOL)landsc appearance:(UIKeyboardAppearance)appr {
	UIKBReturnKeyButton* myButton = [[[UIKBReturnKeyButton alloc] init] autorelease];
	myButton->landscape = landsc;
	myButton->keyboardAppearance = appr;
	if (type != myButton.returnKeyType)
		myButton.returnKeyType = type;
	[myButton update];
	return myButton;
}
-(void)dealloc {
	[titles release];
	[super dealloc];
}
+(CGRect)defaultFrameWithLandscape:(BOOL)landsc { return landsc ? CGRectMake(382, 125, 98, 38) : CGRectMake(240, 172, 80, 44); }
@end


#pragma mark -
//------------------------------------------------------------------------------
// The shift key.

@implementation UIKBShiftKeyButton
-(void)update {
	// the positioning of the shift key is a mess....
	
	UIKBImageClassType shiftKeyImg;
	UIKBImageClassType shiftKeyImgDisabled;
	
	if (shiftStyle == UIKBShiftStyle123) {
		shiftKeyImgDisabled = shiftKeyImg = UIKBImageShiftSymbol;
	} else {
		shiftKeyImg = UIKBImageShift;
		shiftKeyImgDisabled = UIKBImageShiftDisabled;
	}
	
	shiftKeyImg += shiftState;
	
	UIImage* normImg = UIKBGetImage(shiftKeyImg, keyboardAppearance, landscape);
	
	[self setImagesWithNormal:normImg];
	[self setBackgroundImage:UIKBGetImage(shiftKeyImgDisabled, keyboardAppearance, landscape) forState:UIControlStateDisabled];
	
	CGRect myFrame = [UIKBShiftKeyButton defaultFrameWithLandscape:landscape];
	myFrame.size = normImg.size;
	self.frame = myFrame;
	[super update];
}

@synthesize shiftState;
-(void)setShiftState:(UIKBShiftState)ste {
	if (shiftState != ste) {
		shiftState = ste;
		
		UIKeyboardImpl* impl = [UIKeyboardImpl sharedInstance];
		switch (ste) {
			default:
				if ([impl isShifted])
					[impl setShift:NO];
				break;
			case UIKBShiftStatePressed:
				if (![impl isShifted])
					[impl setShift:YES];
				break;
			case UIKBShiftStateLocked:
				if (![impl isShiftLocked])
					[impl setShiftLocked];
				break;
		}
		
		[self update];
	}
}

@synthesize shiftStyle;
-(void)setShiftStyle:(UIKBShiftStyle)style {
	if (shiftStyle != style) {
		shiftStyle = style;
		[self update];
	}
}

@synthesize isHeldDown;
@synthesize enteredSomethingDuringHold;
@synthesize autolock;

-(void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)evt {
	if (isHeldDown)
		return;
	
	isHeldDown = YES;
	enteredSomethingDuringHold = NO;
	
	UIKeyboardImpl* impl = [UIKeyboardImpl sharedInstance];
	if (!autolock && [impl shiftLockPreference]) {
		UITouch* anyTouch = [[evt allTouches] anyObject];
		if (anyTouch.tapCount >= 2 && anyTouch.tapCount % 2 == 0) {
			self.shiftState = UIKBShiftStateLocked;
			return;
		}
	}
	
	switch (shiftState) {
		default:
			self.shiftState = UIKBShiftStatePressed;
			break;
		case UIKBShiftStatePressed:
		case UIKBShiftStateLocked:
			self.shiftState = UIKBShiftStateNormal;
			break;
	}
}

-(void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)evt {
	if (!isHeldDown)
		return;
	if (enteredSomethingDuringHold && shiftState == UIKBShiftStatePressed)
		self.shiftState = UIKBShiftStateNormal;
	isHeldDown = NO;
}

-(UIKBShiftKeyButton*)init {
	if ((self = (UIKBShiftKeyButton*)[super init])) {
		self.multipleTouchEnabled = NO;
		isHeldDown = NO;
	}
	return self;
}

+(UIKBShiftKeyButton*)buttonWithLandscape:(BOOL)landsc appearance:(UIKeyboardAppearance)appr {
	UIKBShiftKeyButton* myButton = [[[UIKBShiftKeyButton alloc] init] autorelease];
	myButton->landscape = landsc;
	myButton->keyboardAppearance = appr;
	[myButton update];
	return myButton;
}

-(BOOL)shouldDrillHole { return !self.hidden; }
// TODO: replace the size 0*0 with better numbers.
+(CGRect)defaultFrameWithLandscape:(BOOL)landsc { return landsc ? CGRectMake(5, 84, 0, 0) : CGRectMake(0, 118, 0, 0); }
@end


#pragma mark -
//------------------------------------------------------------------------------
// The delete key.

@implementation UIKBDeleteKeyButton
-(void)update {
	[self setImagesWithNormal:UIKBGetImage(UIKBImageDelete, keyboardAppearance, landscape)
					   active:UIKBGetImage(UIKBImageDeleteActive, keyboardAppearance, landscape)];
	
	self.frame = [UIKBDeleteKeyButton defaultFrameWithLandscape:landscape];
	
	[super update];
}

-(void)handleDelete:(NSTimer*)timer {
	if (timer != nil)
		[UIKBSound play];
	[[UIKeyboardImpl sharedInstance] handleDelete];
}
-(void)onKeyUp {
	if (currentTimer != nil) {
		[currentTimer invalidate];
		[currentTimer release];
		currentTimer = nil;
		//deleteCount = 0;
	}
}

-(void)continueDelete:(NSTimer*)timer {
	[self onKeyUp];
	currentTimer = [[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(handleDelete:) userInfo:nil repeats:YES] retain];
}

// TODO: Support auto delete. (hold down delete key for ~2 seconds to delete words instead of characters, in ~0.5 second interval.)
-(void)onKeyDown {
	[self onKeyUp];
	[self handleDelete:nil];
	currentTimer = [[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(continueDelete:) userInfo:nil repeats:NO] retain];
}
-(void)dealloc {
	[self onKeyUp];
	[super dealloc];
}

-(UIKBDeleteKeyButton*)init {
	if ((self = (UIKBDeleteKeyButton*)[super init])) {
		currentTimer = nil;
		[self addTarget:self action:@selector(onKeyDown) forControlEvents:UIControlEventTouchDown];
		[self addTarget:self action:@selector(onKeyUp) forControlEvents:UIControlEventTouchUpInside];
		[self update];
	}
	return self;
}

+(UIKBDeleteKeyButton*)buttonWithLandscape:(BOOL)landsc appearance:(UIKeyboardAppearance)appr {
	UIKBDeleteKeyButton* myButton = [[[UIKBDeleteKeyButton alloc] init] autorelease];
	myButton->landscape = landsc;
	myButton->keyboardAppearance = appr;
	[myButton update];
	return myButton;
}
+(CGRect)defaultFrameWithLandscape:(BOOL)landsc { return landsc ? CGRectMake(414, 84, 66, 38) : CGRectMake(278, 118, 42, 43); }
@end


#pragma mark -
//------------------------------------------------------------------------------
// The ABC/123 key.

@implementation UIKBPlaneChooserButton

-(void)update {
	[self setImagesWithNormal:UIKBGetImage(isAlt?UIKBImageABC:UIKBImage123, keyboardAppearance, landscape)];
	self.frame = [UIKBPlaneChooserButton defaultFrameWithLandscape:landscape];
	
	[super update];
}

@dynamic landscape, keyboardAppearance;

@synthesize isAlt;
-(void)setIsAlt:(BOOL)ste {
	if (ste != isAlt) {
		isAlt = ste;
		[self update];
	}
}

-(void)toggleState {
	isAlt = !isAlt;
	[self update];
}

-(UIKBPlaneChooserButton*)init {
	if ((self = (UIKBPlaneChooserButton*)[super init])) {
		isAlt = YES;
		[self addTarget:self action:@selector(toggleState) forControlEvents:UIControlEventTouchDown];
	}
	return self;
}

+(UIKBPlaneChooserButton*)buttonWithLandscape:(BOOL)landsc appearance:(UIKeyboardAppearance)appr {
	UIKBPlaneChooserButton* myButton = [[[UIKBPlaneChooserButton alloc] init] autorelease];
	myButton->landscape = landsc;
	myButton->keyboardAppearance = appr;
	[myButton update];
	return myButton;
}

+(CGRect)defaultFrameWithLandscape:(BOOL)landsc { return landsc ? CGRectMake(0, 124, 52, 38) : CGRectMake(0, 173, 43, 43); }

-(void)dealloc { [super dealloc]; }
@end


#pragma mark -
//------------------------------------------------------------------------------
// A superview for containing the UIKBSpecialKeyButton's so landscape & keyboard
// appearance can be transmitted automatically.

@implementation UIKBButtonsGroup
@synthesize keyboardAppearance, landscape;
-(void)setKeyboardAppearance:(UIKeyboardAppearance)appr {
	if (keyboardAppearance != appr) {
		keyboardAppearance = appr;
		for (UIKBSpecialKeyButton* sv in self.subviews) {
			if ([sv respondsToSelector:@selector(setKeyboardAppearance:)])
				[sv setKeyboardAppearance:appr];
		}
	}
}
-(void)setLandscape:(BOOL)landsc {
	if (landscape != landsc) {
		landscape = landsc;
		for (UIKBSpecialKeyButton* sv in self.subviews) {
			if ([sv respondsToSelector:@selector(setLandscape:)])
				[sv setLandscape:landsc];
		}
		CGSize mySize = [UIKeyboardImpl defaultSizeForOrientation:(landsc ? 90 : 0)];
		self.frame = CGRectMake(0, 0, mySize.width, mySize.height);
	}
}

-(UIKBButtonsGroup*)initWithLandscape:(BOOL)landsc appearance:(UIKeyboardAppearance)appr {
	CGSize mySize = [UIKeyboardImpl defaultSizeForOrientation:(landsc ? 90 : 0)];
	if ((self = (UIKBButtonsGroup*)[super initWithFrame:CGRectMake(0, 0, mySize.width, mySize.height)])) {
		landscape = landsc;
		keyboardAppearance = appr;
		self.userInteractionEnabled = YES;
	}
	return self;
}
-(void)addSubviewWithClass:(Class)cls {
	UIKBSpecialKeyButton* v = [[cls alloc] init];
	v.landscape = landscape;
	v.keyboardAppearance = keyboardAppearance;
	[self addSubview:v];
	[v release];
}
-(UIKBSpecialKeyButton*)firstSubviewWithClass:(Class)cls {
	for (UIKBSpecialKeyButton* sv in self.subviews) {
		if ([sv isKindOfClass:cls])
			return sv;
	}
	return nil;
}
@end