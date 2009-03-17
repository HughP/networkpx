/*
 
 UIActionSheetPro.h ... More flexible UIActionSheet
 
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

#import <UIKit3/UIActionSheetPro.h>
#import <Foundation/Foundation.h>
#import <UIKit2/Functions.h>
#import <UIKit2/UIAlert.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <UIKit3/UIUtilities.h>
#import <GraphicsUtilities.h>

#define SPACING 7
#define PADDING SPACING
#define BUTTON_HEIGHT 30

UIButton* UIActionSheetButton(NSString* title, UIImage* image, BOOL destructive, BOOL cancel) {
	NSString* imageName = @"UINavigationBarDefaultButton.png";
	NSString* pressedImageName = @"UINavigationBarDefaultButtonPressed.png";
	if (cancel) {
		imageName = @"UINavigationBarBlackOpaqueButton.png";
		pressedImageName = @"UINavigationBarBlackButtonPressed.png";
	} else if (destructive) {
		imageName = @"UINavigationBarRemoveButton.png";
		pressedImageName = @"UINavigationBarRemoveButtonPressed.png";
	}
	
	UIImage* normalImage = _UIImageWithName(imageName);
	UIImage* pressedImage = _UIImageWithName(pressedImageName);
	
	UIImage* stretchedImage = [normalImage stretchableImageWithLeftCapWidth:(NSUInteger)(normalImage.size.width)/2 topCapHeight:0];
	UIImage* stretchedPressedImage = [pressedImage stretchableImageWithLeftCapWidth:(NSUInteger)(pressedImage.size.width)/2 topCapHeight:0];
	
	UIButton* retbtn = [UIButton buttonWithType:UIButtonTypeCustom];
	[retbtn setBackgroundImage:stretchedImage forState:UIControlStateNormal];
	[retbtn setBackgroundImage:stretchedPressedImage forState:UIControlStateHighlighted];
	[retbtn setImage:image forState:UIControlStateNormal];
	[retbtn setTitle:title forState:UIControlStateNormal];
	[retbtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	[retbtn setTitleShadowColor:[UIColor colorWithWhite:0 alpha:0.23] forState:UIControlStateNormal];
	retbtn.titleShadowOffset = CGSizeMake(0, -1);
	retbtn.font = [UIFont boldSystemFontOfSize:14];
	retbtn.frame = CGRectMake(0, 0, 0, BUTTON_HEIGHT);
	
	retbtn.tag = destructive ? 2 : cancel ? 1 : 0;
	
	return retbtn;
}


@implementation UIActionSheetPro
-(id)initWithNumberOfRows:(NSUInteger)rows_ {
	if ((self = [super init])) {
		rows = rows_;
		buttons = malloc(rows_ * sizeof(NSMutableArray*));
		for (NSUInteger i = 0; i < rows_; ++ i)
			buttons[i] = [[NSMutableArray alloc] init];
		cancelButtonsCount = calloc(rows_, sizeof(NSUInteger));
		self.titleMaxLineCount = 3;
	}
	return self;
}
-(void)dealloc {
	for (NSUInteger i = 0; i < rows; ++ i)
		[buttons[i] release];
	free(buttons);
	free(cancelButtonsCount);
	[super dealloc];
}


-(UIButton*)addButtonAtRow:(NSUInteger)row withTitle:(NSString*)title image:(UIImage*)image destructive:(BOOL)destructive cancel:(BOOL)cancel {
	if (row >= rows)
		return nil;
	UIButton* btn = UIActionSheetButton(title, image, destructive, cancel);
	[buttons[row] addObject:btn];
	if (cancel) {
		cancelButtonsCount[row] += 2;
		[btn addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
	}
	return btn;
}

-(void)_createTitleLabelIfNeeded {
	[super _createTitleLabelIfNeeded];
	((UILabel*)object_getIvar(self, class_getInstanceVariable([self class], "_titleLabel"))).lineBreakMode = UILineBreakModeMiddleTruncation;
}

-(void)layout {
	[super layout];
	
	CGRect oldRect = self.frame;
	CGFloat h = rows*(BUTTON_HEIGHT+SPACING);
	
	if (buttonsGroup == nil) {
		buttonsGroup = [[UIView alloc] initWithFrame:CGRectMake(0, oldRect.size.height, oldRect.size.width, h)];
		for (NSUInteger i = 0; i < rows; ++ i) {
			NSUInteger count = [buttons[i] count];
			if (count == 0)
				continue;
			NSUInteger buttonDelta = (oldRect.size.width - 2*PADDING + SPACING) / (count + cancelButtonsCount[i]);
			NSUInteger buttonWidth = buttonDelta - SPACING;
			NSUInteger buttonLeft = PADDING;
			for (UIButton* btn in buttons[i]) {
				if (btn.tag == 1) {
					btn.frame = CGRectMake(buttonLeft, i*(BUTTON_HEIGHT+SPACING), buttonWidth+2*buttonDelta, BUTTON_HEIGHT);
					buttonLeft += 3*buttonDelta;
				} else {
					btn.frame = CGRectMake(buttonLeft, i*(BUTTON_HEIGHT+SPACING), buttonWidth, BUTTON_HEIGHT);
					buttonLeft += buttonDelta;
				}
				[buttonsGroup addSubview:btn];
			}
		}
		[self addSubview:buttonsGroup];
		[buttonsGroup release];
	}

	oldRect.origin.y -= h;
	oldRect.size.height += h;
	
	self.frame = oldRect;
}

-(void)showWithWebTexts:(UIWebTexts*)texts inView:(UIView*)view {
	self.title = [texts description];
	[self setDimView:UIDimViewWithHole(texts.rect)];
	[super showInView:view];
}

@end



extern UIView* UIDimViewWithHole(CGRect holeRect) {
	UIScreen* screen = [UIScreen mainScreen];
	CGRect screenSize = screen.bounds;
	CGRect viewBounds = screen.applicationFrame;
	CGRect adjustedHoleRect = CGRectOffset(CGRectInset(holeRect, -2, -2),
										   viewBounds.origin.x-screenSize.origin.x,
										   viewBounds.origin.y-screenSize.origin.y);
	UIGraphicsBeginImageContext(screenSize.size);
	CGContextRef c = UIGraphicsGetCurrentContext();
	[[UIColor colorWithWhite:0 alpha:0.5f] setFill];
	CGContextFillRect(c, CGRectMake(0, 0, screenSize.size.width, screenSize.size.height));
	CGPathRef path = GUPathCreateRoundRect(adjustedHoleRect, 2);
	CGContextAddPath(c, path);
	[[UIColor clearColor] setFill];
	CGContextSetBlendMode(c, kCGBlendModeCopy);
	CGContextFillPath(c);
	UIImageView* v = [[[UIImageView alloc] initWithImage:UIGraphicsGetImageFromCurrentImageContext()] autorelease];
	v.frame = screenSize;
	CGPathRelease(path);
	UIGraphicsEndImageContext();
	return v;
}