/*

GPMessageWindow.m ... Message Window for typical GriP styles.
 
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

#import <objc/runtime.h>
#import <GriP/GPPreferences.h>
#import <GriP/GPMessageWindow.h>
#import <GriP/Duplex/Client.h>
#import <GriP/common.h>
#import <GriP/GPRawThemeHelper.h>
#import <math.h>

#if GRIP_JAILBROKEN
__attribute__((visibility("hidden")))
@interface SBStatusBarController : NSObject
+(SBStatusBarController*)sharedStatusBarController;
-(UIWindow*)statusBarWindow;
@end

__attribute__((visibility("hidden")))
@interface SpringBoard : UIApplication
-(int)UIOrientation;
@end
#endif

static NSMutableArray* occupiedGaps = nil;
static NSMutableArray* unreleasedMessageWindows = nil;
#if GRIP_JAILBROKEN
static Class $SBStatusBarController = Nil;
#endif

static const int _oriented_locations_matrix[4][4] = {
{2, 0, 3, 1},  // -90 (status bar on the left)
{0, 1, 2, 3},  //   0 (normal)
{1, 3, 0, 2},  //  90 (status bar on the right)
{3, 2, 1, 0}}; // 180 (upside-down)

static const int _orientation_angles[4] = {0, 180, 90, -90};

static NSComparisonResult compareHeight(GPMessageWindow* win1, GPMessageWindow* win2, void* context) {
	if (win1->currentGap.y < win2->currentGap.y)
		return NSOrderedAscending;
	else if (win1->currentGap.y > win2->currentGap.y)
		return NSOrderedDescending;
	else 
		return NSOrderedSame;
}

static CGFloat _maxWidth = 160;
static UIColor* _backgroundColor = nil;

@implementation GPMessageWindow
@synthesize view;

+(void)_initialize {
	occupiedGaps = [[NSMutableArray alloc] init];
	unreleasedMessageWindows = [[NSMutableArray alloc] init];
#if GRIP_JAILBROKEN
	$SBStatusBarController = objc_getClass("SBStatusBarController");
#endif
}
+(void)_cleanup {
	[occupiedGaps release];
	[unreleasedMessageWindows release];
	[_backgroundColor release];
}
+(void)_closeAllWindows {
	NSArray* unreleasedMessageWindowsCopy = [unreleasedMessageWindows copy];
	[unreleasedMessageWindowsCopy makeObjectsPerformSelector:@selector(_forceRelease)];
	[unreleasedMessageWindowsCopy release];
}

+(void)_removeGap:(GPGap)gap {
	[occupiedGaps removeObject:[NSValue valueWithBytes:&gap objCType:@encode(GPGap)]];
}
+(GPGap)_createGapWithHeight:(CGFloat)height pageHeight:(CGFloat)pageHeight {
	GPGap potentialGap;
	potentialGap.y = 0;
	potentialGap.h = height;
	
	// search a suitable location to display the window...
	NSUInteger gapIndex = 0;
	for (NSValue* v in occupiedGaps) {
		GPGap occupiedGap;
		[v getValue:&occupiedGap];
		if (occupiedGap.y >= potentialGap.y + potentialGap.h) {
			// make sure the window doesn't cross page boundary.
			CGFloat topPage, bottomPage;
			modff(potentialGap.y/pageHeight, &topPage);
			CGFloat bottomPagePercent = modff((potentialGap.y+potentialGap.h)/pageHeight, &bottomPage);
			if (topPage == bottomPage || (bottomPagePercent == 0 && bottomPage-topPage == 1))
				break;
			else
				potentialGap.y = bottomPage*pageHeight;
		} else {
			potentialGap.y = occupiedGap.y + occupiedGap.h;
			++ gapIndex;
		}
	}
	
	CGFloat topPage, bottomPage;
	modff(potentialGap.y/pageHeight, &topPage);
	CGFloat bottomPagePercent = modff((potentialGap.y+potentialGap.h)/pageHeight, &bottomPage);
	if (topPage != bottomPage && (bottomPagePercent != 0 || bottomPage-topPage != 1))
		potentialGap.y = bottomPage*pageHeight;
	
	[occupiedGaps insertObject:[NSValue valueWithBytes:&potentialGap objCType:@encode(GPGap)] atIndex:gapIndex];
	return potentialGap;
}
-(void)_releaseMyself {
	[self release];
	if (hiding) {
		self.hidden = YES;
		[view removeFromSuperview];
		[GPMessageWindow _removeGap:currentGap];
		[unreleasedMessageWindows removeObject:self];
	}	
}
-(void)_forceRelease {
	[self stopTimer];
	hiding = YES;
	[self retain];
	[identitifer release];
	identitifer = nil;
	[self _releaseMyself];
}

+(CGFloat)maxWidth { return _maxWidth; }
+(void)setMaxWidth:(CGFloat)maxWidth { _maxWidth = floorf(maxWidth); }
+(UIColor*)backgroundColor { return _backgroundColor; }
+(void)setBackgroundColor:(UIColor*)backgroundColor {
	if (backgroundColor != _backgroundColor) {
		[_backgroundColor release];
		_backgroundColor = [backgroundColor retain];
	}
}

-(void)_layoutWithAnimation:(BOOL)animate {
	// obtain the current screen size & subtract the status bar from the screen.
	// (can't use [UIScreen mainScreen].applicationFrame because that returns
	//  SpringBoard's application frame and that's clearly not what we want.)
#if GRIP_JAILBROKEN
	CGRect currentScreenFrame = [UIScreen mainScreen].bounds;
	UIWindow* statusBar = [[$SBStatusBarController sharedStatusBarController] statusBarWindow];
	if (statusBar != nil) {
		CGRect statusFrame = statusBar.frame;
		if (statusFrame.size.width == currentScreenFrame.size.width) {
			if (statusFrame.origin.y == 0)
				currentScreenFrame.origin.y = statusFrame.size.height;
			currentScreenFrame.size.height -= statusFrame.size.height;
		} else {
			if (statusFrame.origin.x == 0)
				currentScreenFrame.origin.x = statusFrame.size.width;
			currentScreenFrame.size.width -= statusFrame.size.width;
		}
	}
#else
	CGRect currentScreenFrame = [UIScreen mainScreen].applicationFrame;	
#endif	
	
	UIApplication* app = [UIApplication sharedApplication];
	int uiOrientation;
#if GRIP_JAILBROKEN
	if ([app respondsToSelector:@selector(UIOrientation)])
		uiOrientation = [(SpringBoard*)app UIOrientation];
	else
#endif
		uiOrientation = _orientation_angles[app.statusBarOrientation-1];
	
	BOOL isLandscape = uiOrientation == 90 || uiOrientation == -90;
	CGFloat pageHeight = isLandscape ? currentScreenFrame.size.width : currentScreenFrame.size.height;
	
	CGSize viewSize = view.frame.size;
	[GPMessageWindow _removeGap:currentGap];
	currentGap = [GPMessageWindow _createGapWithHeight:viewSize.height pageHeight:pageHeight];
	
	// move box to next column(s) if it overflows height boundary
	CGFloat actualGapPage;
	CGFloat actualGapY = modff(currentGap.y/pageHeight, &actualGapPage)*pageHeight;
	actualGapPage *= _maxWidth;
	
	// create frame of window.
	CGRect estimatedFrame = CGRectMake(actualGapPage, actualGapY, _maxWidth, viewSize.height);
	
	// switch estimation box orientation if necessary.
	if (isLandscape)
		estimatedFrame = CGRectMake(estimatedFrame.origin.y, estimatedFrame.origin.x, estimatedFrame.size.height, estimatedFrame.size.width);
	
	NSDictionary* prefs = GPCopyPreferences();
	NSInteger location = [[prefs objectForKey:@"Location"] integerValue];
	[prefs release];
		
	NSInteger adjustedLocation = _oriented_locations_matrix[uiOrientation/90+1][location];
		
	// flip horizontal alignment if on the right.
	if (adjustedLocation & 1)
		estimatedFrame.origin.x = currentScreenFrame.size.width - estimatedFrame.size.width - estimatedFrame.origin.x;
	
	// flip vertical position if at the bottom.
	if (adjustedLocation & 2)
		estimatedFrame.origin.y = currentScreenFrame.size.height - estimatedFrame.size.height - estimatedFrame.origin.y;
	
	estimatedFrame.origin.x += currentScreenFrame.origin.x;
	estimatedFrame.origin.y += currentScreenFrame.origin.y;
		
	// change frame smoothly, if required.
	// frankly speaking... I don't know what I'm doing here.
	self.frame = estimatedFrame;
	UIView* transformerView = [self.subviews objectAtIndex:0];
	transformerView.bounds = CGRectMake(0, 0, _maxWidth, viewSize.height);
	transformerView.center = CGPointMake(estimatedFrame.size.width/2, estimatedFrame.size.height/2);
	transformerView.transform = CGAffineTransformMakeRotation(uiOrientation*M_PI/180);
	view.frame = CGRectMake(0, 0, _maxWidth, viewSize.height);
	
	if (animate)
		[UIView commitAnimations];
}

+(void)arrangeWindows {
	// we need to arrange the windows with increasing gap position.
	// so sort it first. (there is a sorted array (RBTree/AVRTree) structure in ObjC right? right?)
	[unreleasedMessageWindows sortUsingFunction:&compareHeight context:NULL];
	[unreleasedMessageWindows makeObjectsPerformSelector:@selector(prepareForResizing)];
	[unreleasedMessageWindows makeObjectsPerformSelector:@selector(resize)];
}

+(GPMessageWindow*)registerWindowWithView:(UIView*)view_ message:(NSDictionary*)message {
	GPMessageWindow* window = [[self alloc] initWithView:view_ message:message];
	if (window != nil) {
		[unreleasedMessageWindows addObject:window];
		[window release];
	}
	return window;
}

+(GPMessageWindow*)windowForIdentifier:(NSString*)identifier {
	for (GPMessageWindow* window in unreleasedMessageWindows)
		if ([window->identitifer isEqualToString:identifier])
			return window;
	return nil;
}

-(id)initWithView:(UIView*)view_ message:(NSDictionary*)message {
	if ((self = [super init])) {
		helper = [[GPRawThemeHelper alloc] init];
		UIView* transformerView = [[UIView alloc] init];
		[transformerView addSubview:view_];
		[self addSubview:transformerView];
		[transformerView release];
		view = view_;
		[self _layoutWithAnimation:NO];
		helperUID = -1;
		[self refreshWithMessage:message];
		self.windowLevel = UIWindowLevelStatusBar*2;
		self.hidden = NO;
		identitifer = [[message objectForKey:GRIP_ID] retain];
		if (_backgroundColor)
			self.backgroundColor = _backgroundColor;
	}
	return self;
}

-(void)refreshWithMessage:(NSDictionary*)message {
	[self stopHiding];
	
	[helper dismissedMessageID:helperUID forAction:GriPMessage_CoalescedNotification];
	helperUID = [helper registerMessage:message];
	priority = [[message objectForKey:GRIP_PRIORITY] integerValue];
	
	if (!forceSticky) {
		[self stopTimer];
		sticky = [[message objectForKey:GRIP_STICKY] boolValue];
		[self _startTimer];
	}
}

-(void)prepareForResizing {
	[UIView beginAnimations:@"GPMW-Move" context:NULL];
}
-(void)resize { [self _layoutWithAnimation:YES]; }

-(void)restartTimer {
	[self stopTimer];
	[self _startTimer];
}
-(void)_startTimer {
	if (!sticky) {
		
		NSDictionary* prefs = GPCopyPreferences();
		NSTimeInterval interval = [[[[prefs objectForKey:@"PerPrioritySettings"] objectAtIndex:priority+2] objectAtIndex:GPPrioritySettings_Timer] doubleValue];
		hideTimer = [[NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(hide) userInfo:nil repeats:NO] retain];
		[prefs release];
	}
}
-(void)stopTimer {
	if (!sticky) {
		[hideTimer invalidate];
		[hideTimer release];
		hideTimer = nil;
	}
}

-(void)stopHiding {
	hiding = NO;
	self.hidden = NO;
	self.alpha = 1;
}

-(void)hide { [self hide:YES]; }

-(void)hide:(BOOL)ignored {
	[helper dismissedMessageID:helperUID forAction:(ignored ? GriPMessage_IgnoredNotification : GriPMessage_ClickedNotification)];
	
	[self stopTimer];
	hiding = YES;
	[self retain];
	
	[UIView beginAnimations:@"GPMW-Hide" context:NULL];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(_releaseMyself)];
	[UIView setAnimationDuration:0.5];
	self.alpha = 0;
	[UIView commitAnimations];
}

-(void)forceSticky {
	sticky = YES;
	forceSticky = YES;
	[self stopTimer];
}

-(void)dealloc {
	[self stopTimer];
	[helper release];
	[identitifer release];
	[super dealloc];
}

@end