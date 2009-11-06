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
#import <substrate2.h>
#import <SpringBoard/SpringBoard.h>

__attribute__((visibility("hidden")))
@interface INXWindow : UIWindow {
	int _orientation;
	CGRect _fullScreenRect;
}
@property(assign,nonatomic) int orientation;
@end

static pthread_once_t _INXWindow_once = PTHREAD_ONCE_INIT;
static INXWindow* _INXWindow = nil;


@implementation INXWindow
@synthesize orientation = _orientation;
-(id)init {
	CGRect x_fullScreenRect = [UIScreen mainScreen].bounds;
	if ((self = [super initWithFrame:x_fullScreenRect])) {
		_fullScreenRect = x_fullScreenRect;
	}
	return self;
}
-(void)setOrientation:(int)newOrientation {
	if (_orientation != newOrientation) {
		
		_orientation = newOrientation;
	}
}

-(BOOL)acceptsGlobalPoint:(CGPoint)point {
	NSLog(@"%@", NSStringFromCGPoint(point));
	for (UIView* subview in self.subviews) {
		CGPoint localPoint = [subview convertPoint:point fromView:nil];
		if ([subview pointInside:localPoint withEvent:nil])
			return YES;
	}
	return NO;
}
@end



DefineObjCHook(void, SpringBoard_noteUIOrientationChanged_display_, SpringBoard* self, SEL _cmd, int changed, id display) {
	Original(SpringBoard_noteUIOrientationChanged_display_)(self, _cmd, changed, display);
	_INXWindow.orientation = [self UIOrientation];
}

static void _INXWindowInitializer () {
	_INXWindow = [[INXWindow alloc] init];
#if TARGET_IPHONE_SIMULATOR
	_INXWindow.backgroundColor = [UIColor colorWithRed:0 green:1 blue:0 alpha:0.5];
	UIButton* testButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	testButton.frame = CGRectMake(40, 100, 200, 200);
	[_INXWindow addSubview:testButton];
#endif
	_INXWindow.windowLevel = UIWindowLevelStatusBar + 1;

#if !TARGET_IPHONE_SIMULATOR
	InstallObjCInstanceHook(objc_getClass("SpringBoard"), @selector(noteUIOrientationChanged:display:), SpringBoard_noteUIOrientationChanged_display_);
#endif
}

extern UIWindow* INXGetWindow() {
	pthread_once(&_INXWindow_once, &_INXWindowInitializer);
	return _INXWindow;
}
