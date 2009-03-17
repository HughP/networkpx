/*
 
 5RowQWERTY.m ... Source for the 5 Row QWERTY layout.
 
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

#import <Foundation/Foundation.h>
#import <iKeyEx/UIKBStandardKeyboardLayout.h>
#import <UIKit2/UIKeyboardImpl.h>
#import <UIKit2/UIKeyboardInput.h>
#import <Command/CMLSelection.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@protocol IDisableWarning
@optional
-(void)handleInputFromMenu:(NSString*)menu;
-(void)removeTextLoupe;
@end

static BOOL numpadInFront;
static BOOL isMobileTerminal = NO;
static id<IDisableWarning> mobileTerminalApplication = nil;
static BOOL canSendActiveKey = NO, cancelNextAction = NO;

// We replace the layout instead of the input manager because the input manager cannot catch all input strings.
// Here we are mixing layout.plist with custom code. To use custom code, subclass the UIKBStandardKeyboardLayout{Landscape} class,
//  then in the initializer (-initWithFrame:), fill in the content of layout.plist into the ivar "plist". 
// You DON'T have to release this plist in -dealloc since the superclass will do it for you.

@interface FiveRowQWERTYLayout : UIKBStandardKeyboardLayout {}
+(BOOL)sendControlAction:(NSString*)str;

-(id)initWithFrame:(CGRect)frm;
-(void)sendStringAction:(NSString*)str forKey:(UIKeyDefinition*)keydef;
-(void)longPressAction;
-(void)deactivateActiveKeys;
@end

@implementation FiveRowQWERTYLayout
+(BOOL)sendControlAction:(NSString*)str {
	if (canSendActiveKey)
		[self performSelector:_cmd withObject:str afterDelay:0.125];
	
	if (isMobileTerminal) {
		[mobileTerminalApplication handleInputFromMenu:str];
		return YES;
	} else {
		UIKeyboardImpl* impl = [UIKeyboardImpl sharedInstance];
		UIView<UIKeyboardInput,IDisableWarning>* del = (UIView<UIKeyboardInput,IDisableWarning>*)impl.delegate;
		
		if ([str length] == 1) {
			// esc
			if ([del isKindOfClass:[UIView class]])
				[[del superview] resignFirstResponder];
			else
				[del resignFirstResponder];
			return YES;
		} else if ([str length] >= 3) {
			unichar action = [str characterAtIndex:2];
			CGRect curRect;
			NSRange curRange;
			CGFloat frameHeight;
			
			switch (action) {
				default:
					return NO;
					
					// up
				case 'A':
					curRect = del.caretRect;
					[del updateSelectionWithPoint:CGPointMake(curRect.origin.x, curRect.origin.y-1)];
					// kill the text loupe if there's one.
					if ([del respondsToSelector:@selector(removeTextLoupe)])
						[del removeTextLoupe];
					break;
					
					// down
				case 'B':
					curRect = del.caretRect;
					[del updateSelectionWithPoint:CGPointMake(curRect.origin.x, curRect.origin.y + curRect.size.height + 1)];
					if ([del respondsToSelector:@selector(removeTextLoupe)])
						[del removeTextLoupe];
					break;
					
					// right (can't use moveForward: because DOMElement ignores it...)
				case 'C':
					curRange = getSelection(del, NULL);
					if (curRange.location == NSNotFound)
						return YES;
					if (curRange.length != 0) {
						curRange.location += curRange.length;
						curRange.length = 0;
					} else
						curRange.location ++;
					if (curRange.location <= [del.text length])
						setSelection(del, curRange);
					break;
					
					// left
				case 'D':
					curRange = getSelection(del, NULL);
					if (curRange.location == NSNotFound)
						return YES;
					if (curRange.length != 0) {
						curRange.length = 0;
					} else
						curRange.location --;
					if (curRange.location >= 0)
						setSelection(del, curRange);
					break;
					
					// forward delete
				case '3':
					curRange = getSelection(del, NULL);
					if (curRange.location == NSNotFound)
						return YES;
					if (curRange.length == 0) {
						if (curRange.location == [del.text length])
							return YES;
						setSelection(del, NSMakeRange(curRange.location+1, 0));
					}
					[del deleteBackward];
					break;
					
					// home
				case '1':
					setSelection(del, NSMakeRange(0, 0));
					break;
					
					// end
				case '4':
					setSelection(del, NSMakeRange([del.text length], 0));
					break;
					
					// page up
				case '5':
					curRect = del.caretRect;
					frameHeight = curRect.size.height;
					if ([del isKindOfClass:[UIView class]])
						frameHeight = del.superview.frame.size.height;
					
					[del updateSelectionWithPoint:CGPointMake(0, curRect.origin.y - frameHeight)];
					if ([del respondsToSelector:@selector(removeTextLoupe)])
						[del removeTextLoupe];
					break;
					
					// page down
				case '6':
					curRect = del.caretRect;
					frameHeight = curRect.size.height;
					if ([del isKindOfClass:[UIView class]])
						frameHeight = del.superview.frame.size.height;
					
					[del updateSelectionWithPoint:CGPointMake(0, curRect.origin.y + frameHeight)];
					if ([del respondsToSelector:@selector(removeTextLoupe)])
						[del removeTextLoupe];
					break;
			}
			
			// avoid the caret moving out of screen.
			setSelection(del, getSelection(del, NULL));
			
			// avoid the shift state being modified.
			impl.shift = numpadInFront;
			
			return YES;
		} else
			return NO;
	}
}

-(id)initWithFrame:(CGRect)frm {
	if ((self = [super initWithFrame:frm])) {
		[plist release];
		plist = [[NSDictionary alloc] initWithContentsOfFile:[[KeyboardBundle activeBundle] pathForResource:@"layout" ofType:@"plist"]];
		numpadInFront = [@"NumPad" isEqualToString:[plist objectForKey:@"altPlane"]];
	}
	return self;
}
-(void)sendStringAction:(NSString*)str forKey:(UIKeyDefinition*)keydef {
	if (cancelNextAction) {
		cancelNextAction = NO;
		return;
	}
	
	if ([str hasPrefix:@"\x1b"])
		if ([FiveRowQWERTYLayout sendControlAction:str])
			return;
	[super sendStringAction:str forKey:keydef];
}
-(void)longPressAction {
	NSString* input = [self inputStringForKey:[self activeKey]];
	if ([input hasPrefix:@"\x1b"]) {
		canSendActiveKey = YES;
		[FiveRowQWERTYLayout sendControlAction:input];
		return;
	}
	[super longPressAction];
}
-(void)deactivateActiveKeys {
	if (canSendActiveKey) {
		canSendActiveKey = NO;
		cancelNextAction = YES;
	}
	[super deactivateActiveKeys];
}
@end


@interface FiveRowQWERTYLayoutLandscape : UIKBStandardKeyboardLayoutLandscape {} @end
@implementation FiveRowQWERTYLayoutLandscape @end

#define AddMethod(sel) tmp = class_getInstanceMethod(frqlorig, @selector(sel)); \
class_addMethod(frqll, @selector(sel), \
				method_getImplementation(tmp), \
				method_getTypeEncoding(tmp))

void init () {
	// OK so we're discriminating MobileTerminal again...
	isMobileTerminal = [[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.googlecode.mobileterminal"];
	if (isMobileTerminal)
		mobileTerminalApplication = [objc_getClass("MobileTerminal") application];
	
	// The implementation for Landscape is the same, so we'll addMethod them instead.
	Class frqll = [FiveRowQWERTYLayoutLandscape class];
	Class frqlorig = [FiveRowQWERTYLayout class];
	Method tmp;
	
	AddMethod(initWithFrame:);
	AddMethod(sendStringAction:forKey:);
	AddMethod(longPressAction);
	AddMethod(deactivateActiveKeys);
}