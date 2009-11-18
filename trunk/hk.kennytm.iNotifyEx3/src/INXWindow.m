/*
 
FILE_NAME ... FILE_DESCRIPTION

Copyright (c) 2009  KennyTM~ <kennytm@gmail.com>
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

#import "INXWindow.h"
#include <pthread.h>
#include <CoreFoundation/CoreFoundation.h>
#include <notify.h>
#import <substrate2.h>
#import <SpringBoard/SpringBoard.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit2.h>
#import <ChatKit/ChatKit.h>
#import <objc/message.h>
#include "INXCommon.h"

static pthread_once_t _INXWindow_once = PTHREAD_ONCE_INIT;
static INXWindow* _INXWindow = nil;
static INXSuperiorWindow* _INXSuperiorWindow = nil;
static int oToken, rToken;
static mach_port_t oPort;
static CFMachPortRef oPort2;
static CFRunLoopSourceRef oSource;

/*
static UIInterfaceOrientation convertAngleToInterfaceOrientation(int angular) {
	switch (angular) {
		default: return UIInterfaceOrientationPortrait;
		case -90: return UIInterfaceOrientationLandscapeLeft;
		case 90: return UIInterfaceOrientationLandscapeRight;
		case 180: return UIInterfaceOrientationPortraitUpsideDown;
	}
}

DefineObjCHook(void, SpringBoard_noteUIOrientationChanged_display_, SpringBoard* self, SEL _cmd, int changed, id display) {
	Original(SpringBoard_noteUIOrientationChanged_display_)(self, _cmd, changed, display);
	 = _INXSuperiorWindow.orientation = [self UIOrientation];
}
 */

static void oChanged(CFMachPortRef port, void* msg, CFIndex size, void* info) {
	int token = ((mach_msg_header_t*)msg)->msgh_id;
	uint64_t state;
	notify_get_state(token, &state);
	UIDeviceOrientation orientation = state;
	
	if (orientation != UIDeviceOrientationUnknown && orientation != UIDeviceOrientationFaceDown && orientation != UIDeviceOrientationFaceUp) {
		if (token == oToken)
			_INXWindow.orientation = orientation;
		else
			_INXSuperiorWindow.orientation = orientation;
	}
}

static void _INXWindowInitializer() {
	_INXWindow = [[INXWindow alloc] init];
	_INXSuperiorWindow = [[INXSuperiorWindow alloc] init];
	
	[UITextEffectsWindow sharedTextEffectsWindowAboveStatusBar].windowLevel = 3*UIWindowLevelStatusBar;
	
	/*
#if !TARGET_IPHONE_SIMULATOR
	_INXWindow.orientation = _INXSuperiorWindow.orientation = [(SpringBoard*)[UIApplication sharedApplication] UIOrientation];
	InstallObjCInstanceHook(objc_getClass("SpringBoard"), @selector(noteUIOrientationChanged:display:), SpringBoard_noteUIOrientationChanged_display_);
#endif
	 */
	
	notify_register_mach_port("com.apple.springboard.orientation", &oPort, 0, &oToken);
	notify_register_mach_port("com.apple.springboard.rawOrientation", &oPort, NOTIFY_REUSE, &rToken);
	
	oPort2 = CFMachPortCreateWithPort(NULL, oPort, oChanged, NULL, NULL);
	oSource = CFMachPortCreateRunLoopSource(NULL, oPort2, 0);
	CFRunLoopAddSource(CFRunLoopGetMain(), oSource, kCFRunLoopDefaultMode);
	CFRelease(oSource);
}

__attribute__((destructor))
static void _INXWindowDestructor() {
	_INXWindow.hidden = YES;
	_INXSuperiorWindow.hidden = YES;
	[_INXWindow release];
	[_INXSuperiorWindow release];
	_INXWindow = nil;
	_INXSuperiorWindow = nil;
	
	if (oToken != 0) {
		CFRunLoopSourceInvalidate(oSource);
		CFRelease(oPort2);
		notify_cancel(oToken);
		notify_cancel(rToken);
		oToken = rToken = 0;
	}
}

__attribute__((visibility("hidden")))
@interface INXBalloonView : UIView {
//	NSString* _str;
}
@end
@implementation INXBalloonView
static UIImage* _balloon = nil;
static UIFont* _defaultFont = nil, *_italicFont = nil;
static pthread_once_t _balloon_once = PTHREAD_ONCE_INIT;
static const CGFloat BALLOON_LCW = 21, BALLOON_TCH = 16, BALLOON_MAXWIDTH = 320;
static const CGFloat BALLOON_RPAD = 11, BALLOON_LPAD = 18, BALLOON_TPAD = 5, BALLOON_BPAD = 7;

static void _INXBalloonViewGetBalloon() {
	UIImage* balloon_inverted = [UIImage _balloonImage:YES color:YES];
	CGSize balloon_size = balloon_inverted.size;
	UIGraphicsBeginImageContext(balloon_size);
	CGContextScaleCTM(UIGraphicsGetCurrentContext(), -1, 1);
	[balloon_inverted drawAtPoint:CGPointMake(-balloon_size.width, 0)];
	_balloon = [[UIGraphicsGetImageFromCurrentImageContext() stretchableImageWithLeftCapWidth:BALLOON_LCW topCapHeight:BALLOON_TCH] retain];
	UIGraphicsEndImageContext();
	_defaultFont = [[UIFont systemFontOfSize:[UIFont systemFontSize]] retain];
	_italicFont = [[UIFont italicSystemFontOfSize:[UIFont labelFontSize]] retain];
}
__attribute__((destructor))
static void _INXBalloonViewDestroyBalloons() {
	[_balloon release];
	[_defaultFont release];
	[_italicFont release];
	_balloon = nil;
	_defaultFont = nil;
	_italicFont = nil;
}

/*
 [subject]
 [pic] <[str.....]
 */

-(id)initWithString:(NSString*)str subject:(NSString*)subject pic:(UIImage*)pic {
	if ((self = [super initWithFrame:CGRectZero])) {
		pthread_once(&_balloon_once, &_INXBalloonViewGetBalloon);
		
		CGSize picSize = pic ? pic.size : CGSizeZero;
		CGFloat balloonTextWidth = BALLOON_MAXWIDTH-BALLOON_LPAD-BALLOON_RPAD-picSize.width;
		CGSize balloonTextSize = str ? [str sizeWithFont:_defaultFont forWidth:balloonTextWidth lineBreakMode:UILineBreakModeWordWrap] : CGSizeZero;
		CGSize subjectSize = subject ? [subject sizeWithFont:_italicFont forWidth:BALLOON_MAXWIDTH lineBreakMode:UILineBreakModeWordWrap] : CGSizeZero;
		CGFloat totalHeight = subjectSize.height + MAX(picSize.height, str ? balloonTextSize.height+BALLOON_TPAD+BALLOON_BPAD : 0);
		
		UIGraphicsBeginImageContext(CGSizeMake(BALLOON_MAXWIDTH, totalHeight));
		CGContextRef c = UIGraphicsGetCurrentContext();
		CGContextSetGrayFillColor(c, 1, 1);
		[subject drawInRect:CGRectMake(0, 0, BALLOON_MAXWIDTH, subjectSize.height) withFont:_italicFont lineBreakMode:UILineBreakModeWordWrap];
		[pic drawAtPoint:CGPointMake(0, totalHeight - picSize.width)];
		if (str) {
			CGContextSetGrayFillColor(c, 0, 1);
			[_balloon drawInRect:CGRectMake(picSize.width, subjectSize.height, balloonTextSize.width+BALLOON_LPAD+BALLOON_RPAD, balloonTextSize.height+BALLOON_TPAD+BALLOON_BPAD)];
			[str drawInRect:CGRectMake(picSize.width+BALLOON_LPAD, subjectSize.height+BALLOON_TPAD, balloonTextSize.width, balloonTextSize.height) withFont:_defaultFont lineBreakMode:UILineBreakModeWordWrap];
		}
		UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
		
		self.frame = CGRectMake(0, 0, BALLOON_MAXWIDTH, totalHeight);
		UIImageView* v = [[UIImageView alloc] initWithImage:image];
		[self addSubview:v];
		[v release];
		
//		_str = [str retain];
		self.backgroundColor = [UIColor clearColor];
		[self setAccessibilityLabel:[[subject stringByAppendingString:@"\n"] stringByAppendingString:str]];
		[self setAccessibilityTraits:UIAccessibilityTraitStaticText];
		[self setIsAccessibilityElement:YES];
		
		/*
		UITapGestureRecognizer* gr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap)];
		gr.numberOfTaps = gr.numberOfFingers = 1;
		[self addGestureRecognizer:gr];
		[gr release];
		 */
	}
	return self;
}
/*
-(void)dealloc {
	[_str release];
	[super dealloc];
}
*/
/*
-(void)drawRect:(CGRect)rect {
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	CGContextScaleCTM(ctx, -1, 1);
	[_balloon drawInRect:CGRectMake(-rect.size.width, 0, rect.size.width, rect.size.height)];
	CGContextScaleCTM(ctx, -1, 1);
	[_str drawAtPoint:CGPointMake(BALLOON_LPAD, BALLOON_TPAD)
			 forWidth:320-BALLOON_LPAD-BALLOON_RPAD withFont:_defaultFont lineBreakMode:UILineBreakModeWordWrap];
}
 */
/*
-(void)copy:(id)sender {
	[UIPasteboard generalPasteboard].string = _str;
}
-(BOOL)canPerformAction:(SEL)action withSender:(id)sender { return action == @selector(copy:); }
-(BOOL)canBecomeFirstResponder { return YES; }
-(void)singleTap {
	[self becomeFirstResponder];
	
	UIMenuController* menu = [UIMenuController sharedMenuController];
	[menu setTargetRect:self.bounds inView:self];
	[menu setMenuVisible:YES animated:YES];
	
	[UICalloutBar sharedCalloutBar].window.windowLevel = UIWindowLevelStatusBar * 3;
}
*/
@end



@implementation INXWindow
@synthesize orientation = _orientation;
-(id)init {
	CGRect x_fullScreenRect = [UIScreen mainScreen].bounds;
	if ((self = [super initWithFrame:x_fullScreenRect])) {
		_fullScreenRect = x_fullScreenRect;
		
		self.autoresizesSubviews = YES;
		self.backgroundColor = [UIColor clearColor];
		
		[self setDelegate:self];
		
		self.windowLevel = UIWindowLevelStatusBar*2 + 1;
		self.hidden = NO;
	}
	return self;
}
-(void)setDelegate:(id)delegate { [super setDelegate:self]; }

// If it returns YES, it will hang SpringBoard due to SBS call.
-(BOOL)shouldWindowUseOnePartInterfaceRotationAnimation:(UIWindow*)window { return NO; }
-(UIView*)rotatingContentViewForWindow:(UIWindow*)window { return self; }
-(void)setAutorotates:(BOOL)autorotates forceUpdateInterfaceOrientation:(BOOL)orientation {}
-(void)window:(UIWindow*)window willRotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration {
	UIInterfaceOrientation oldOrientation = [self interfaceOrientation];
	BOOL wasLandscape = UIInterfaceOrientationIsLandscape(oldOrientation), isLandscape = UIInterfaceOrientationIsLandscape(interfaceOrientation);
	if (wasLandscape != isLandscape) {
		[UIView beginAnimations:@"INXWR"];
		[UIView setAnimationDuration:duration];
		CGSize selfBounds;
		if (isLandscape)
			selfBounds = CGSizeMake(_fullScreenRect.size.height, _fullScreenRect.size.width);
		else
			selfBounds = _fullScreenRect.size;
		self.bounds = CGRectMake(0, 0, selfBounds.width, selfBounds.height);
		[UIView commitAnimations];
	}
}
-(void)setOrientation:(UIInterfaceOrientation)newOrientation {
	if (_orientation != newOrientation) {
		_orientation = newOrientation;
		[self _updateToInterfaceOrientation:newOrientation animated:YES];
	}
}
-(BOOL)acceptsGlobalPoint:(CGPoint)point {
	CGPoint localPoint = [self convertPoint:point fromWindow:nil];
	for (UIView* subview in self.subviews) {
		if (!subview.hidden) {
			CGPoint viewPoint = [subview convertPoint:localPoint fromView:nil];
			if ([subview pointInside:viewPoint withEvent:nil])
				return YES;
		}
	}
	return NO;
}
+(INXWindow*)sharedWindow {
	pthread_once(&_INXWindow_once, &_INXWindowInitializer);
	return _INXWindow;
}
@end




@implementation INXSuperiorWindow
static Class _SBAccelerometerInterface;
static Ivar SBAccelerometerInterface_clients, UIControl_targetActions;
+(void)load {
	_SBAccelerometerInterface = objc_getClass("SBAccelerometerInterface");
	SBAccelerometerInterface_clients = class_getInstanceVariable(_SBAccelerometerInterface, "_clients");
	UIControl_targetActions = class_getInstanceVariable([UIControl class], "_targetActions");
}

@synthesize showsKeyboard = _showsKeyboard, interacting = _interacting;
-(id)init {
	if ((self = [super init])) {
		_kbRectPortrait = [UIKeyboard defaultFrameForInterfaceOrientation:UIInterfaceOrientationPortrait];
		_kbRectLandscape = [UIKeyboard defaultFrameForInterfaceOrientation:UIDeviceOrientationLandscapeRight];
		CGFloat t = _kbRectLandscape.origin.x; _kbRectLandscape.origin.x = _kbRectLandscape.origin.y; _kbRectLandscape.origin.y = t;
		t = _kbRectLandscape.size.width; _kbRectLandscape.size.width = _kbRectLandscape.size.height; _kbRectLandscape.size.height = t;
		
		[UIKeyboard initImplementationNow];
		_sharedKeyboard = [[UIKeyboard alloc] initWithDefaultSize];
		_sharedKeyboard.frame = _kbRectPortrait;
		_sharedKeyboard.hidden = YES;
		[_sharedKeyboard setDefaultTextInputTraits:[UITextInputTraits defaultTextInputTraits]];
		[self addSubview:_sharedKeyboard];
		[_sharedKeyboard release];
		
		self.windowLevel = UIWindowLevelStatusBar*2+2;
	}
	return self;
}
-(BOOL)acceptsGlobalPoint:(CGPoint)point { return _interacting; }
-(void)window:(UIWindow*)window willRotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration {
	[super window:window willRotateToInterfaceOrientation:interfaceOrientation duration:duration];
	UIInterfaceOrientation oldOrientation = [self interfaceOrientation];
	BOOL wasLandscape = UIInterfaceOrientationIsLandscape(oldOrientation), isLandscape = UIInterfaceOrientationIsLandscape(interfaceOrientation);
	if (wasLandscape != isLandscape) {
		[UIView beginAnimations:@"INXSWR"];
		CGFloat kbHeight, kbWidth, sbHeight;
		if (isLandscape) {
			kbHeight = _kbRectLandscape.size.height;
			kbWidth = _kbRectLandscape.size.width;
			sbHeight = _fullScreenRect.size.width;
			_sharedKeyboard.frame = _kbRectLandscape;
		} else {
			kbHeight = _kbRectPortrait.size.height;
			kbWidth = _kbRectPortrait.size.width;
			sbHeight = _fullScreenRect.size.height;
			_sharedKeyboard.frame = _kbRectPortrait;
		}
		if (_attachedToKeyboardView) {
			CGFloat h = _attachedToKeyboardView.frame.size.height;
			_attachedToKeyboardView.frame = CGRectMake(0, sbHeight-kbHeight-h, kbWidth, h);
		}
		[UIView commitAnimations];
	}
}
-(void)setShowsKeyboard:(BOOL)showsKeyboard_ {
	if (_showsKeyboard != showsKeyboard_) {
		_sharedKeyboard.hidden = !showsKeyboard_;
		_interacting = _showsKeyboard = showsKeyboard_;
		
		CATransition* trans = [CATransition animation];
		trans.type = kCATransitionPush;
		trans.subtype = showsKeyboard_ ? kCATransitionFromTop : kCATransitionFromBottom;
		trans.removedOnCompletion = YES;
		[[_sharedKeyboard layer] addAnimation:trans forKey:@"SK"];		
	}
}
+(INXSuperiorWindow*)sharedSuperiorWindow {
	pthread_once(&_INXWindow_once, &_INXWindowInitializer);
	return _INXSuperiorWindow;
}
-(void)keyboardPromptCanceled {
	[UIView beginAnimations:@"KPC" context:NULL];
	[UIView setAnimationDelegate:_attachedToKeyboardView];
	[UIView setAnimationDidStopSelector:@selector(removeFromSuperview)];
	_attachedToKeyboardView.alpha = 0;
	_attachedToKeyboardView = nil;
	self.backgroundColor = [UIColor clearColor];
	[UIView commitAnimations];
	self.showsKeyboard = NO;
	[_originalKeyWindow makeKeyWindow];
	_originalKeyWindow = nil;
}
-(BOOL)entryFieldShouldBecomeActive:(CKContentEntryView*)entryField { return YES; }
-(void)entryFieldAttachmentsChanged:(CKContentEntryView*)entryField {}
-(void)entryFieldSubjectChanged:(CKContentEntryView*)entryField {}
-(void)entryFieldDidBecomeActive:(CKContentEntryView*)entryField {}
-(BOOL)entryField:(CKContentEntryView*)entryField shouldInsertMediaObject:(CKMediaObject*)mediaObject { return YES; }
-(void)entryFieldContentChanged:(CKContentEntryView*)entryField {}
-(void)messageEntryViewSendButtonHit:(CKMessageEntryView*)entry {
	// TODO: Properly support multimedia messages (MMS)...
	objc_msgSend(_kbMsgTarget, _kbMsgSel, [[entry entryField] messageComposition].textString);
	_kbMsgTarget = nil;
	[self keyboardPromptCanceled];
}

-(void)showsKeyboardWithPromptMessage:(NSString*)message
							  subject:(NSString*)subject
								  pic:(UIImage*)pic
							   target:(id)target selector:(SEL)selector {
	_originalKeyWindow = UIApp.keyWindow;
	[[_originalKeyWindow firstResponder] resignFirstResponder];
	[self makeKeyWindow];
	self.showsKeyboard = YES;
	
	_kbMsgTarget = target;
	_kbMsgSel = selector;
	
	CGRect curRect = (self->_orientation == 90 || self->_orientation == -90) ? self->_kbRectLandscape : self->_kbRectPortrait;
	
	// Make the message balloon.
	CGFloat h = 0;
	INXBalloonView* balloon = nil;
	if (message != nil) {
		balloon = [[INXBalloonView alloc] initWithString:message subject:subject pic:pic];
		h += balloon.frame.size.height;
	}
	
	CKMessageMediaEntryView* entryView = [[CKMessageMediaEntryView alloc] initWithFrame:CGRectMake(0, h, curRect.size.width, 64)];
	entryView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	[[entryView entryField] setEntryFieldDelegate:self];
	entryView.delegate = self;
	UIButton* photoButton = [entryView photoButton];
	[photoButton setAccessibilityLabel:(NSString*)INXLocalizedCancel()];
	[photoButton accessibilitySetIdentification:@"Cancel"];
	[photoButton setImage:[UIImage imageWithContentsOfFile:@"/Applications/MobileSafari.app/closebox.png"] forState:UIControlStateNormal];
	[photoButton setImage:[UIImage imageWithContentsOfFile:@"/Applications/MobileSafari.app/closebox_pressed.png"] forState:UIControlStateHighlighted];	
	[photoButton _cancelDelayedActions];
	[object_getIvar(photoButton, UIControl_targetActions) removeAllObjects];
	[photoButton addTarget:self action:@selector(keyboardPromptCanceled) forControlEvents:UIControlEventTouchUpInside];;
	
	[self->_attachedToKeyboardView removeFromSuperview];
	CGFloat totalHeight = h+entryView.frame.size.height;
	UIView* bothContainer = [[UIView alloc] initWithFrame:CGRectMake(0, curRect.origin.y-totalHeight, curRect.size.width, totalHeight)];
	bothContainer.autoresizesSubviews = YES;
	bothContainer.backgroundColor = [UIColor clearColor];
	if (balloon) {
		[bothContainer addSubview:balloon];
		[balloon release];
	}
	[bothContainer addSubview:entryView];
	[entryView release];
	bothContainer.alpha = 0;
	[self addSubview:bothContainer];
	self->_attachedToKeyboardView = bothContainer;
	[bothContainer release];
	
	[UIView beginAnimations:@"PM" context:NULL];
	bothContainer.alpha = 1;
	self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
	[UIView commitAnimations];
	
	[[entryView entryField] tapGesture:nil];
}

+(void)setAccelerometerState:(BOOL)on {
	SBAccelerometerInterface* interface = [_SBAccelerometerInterface sharedInstance];
	SBAccelerometerClient* client = [object_getIvar(interface, SBAccelerometerInterface_clients) lastObject];
	client.updateInterval = on ? 0.1 : 0;
	[interface updateSettings];
}
@end
