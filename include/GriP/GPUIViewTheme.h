/*

GPUIViewTheme.h ... GriP Theme using a UIView to render the content.
 
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

#import <GriP/GPTheme.h>
#import <Foundation/NSObject.h>

@class NSDictionary, NSMutableDictionary, UIView, NSBundle, UIColor, NSString, UIButton;

@interface GPUIViewTheme : NSObject<GPTheme> {
	NSMutableDictionary* identifiedViews;
	NSBundle* selfBundle;
	UIColor* fgColors[5];
	UIColor* bgColors[5];
}
-(id)initWithBundle:(NSBundle*)bundle;
-(void)dealloc;

// these two should be "final".
-(void)display:(NSDictionary*)message;
-(void)messageClosed:(NSString*)identifier;

// subclasses can override these methods for custom behaviors.
-(void)modifyView:(UIView*)inoutView asNew:(BOOL)asNew withMessage:(NSDictionary*)message;

+(void)updateViewForDisclosure:(UIView*)view_;
+(void)activateView:(UIView*)view;
+(void)deactivateView:(UIView*)view;
@end



@interface GPUIViewTheme (TargetActions)
+(void)close:(UIView*)button;
+(void)disclose:(UIView*)button;
+(void)activate:(UIView*)clickContext;
+(void)deactivate:(UIView*)clickContext;
+(void)fire:(UIView*)clickContext;
@end


#define GPAssignUIControlAsClickContext(ctrl) ({ \
	Class rootClass = [self class]; \
	[(ctrl) addTarget:rootClass action:@selector(fire:) forControlEvents:UIControlEventTouchUpInside]; \
	[(ctrl) addTarget:rootClass action:@selector(activate:) forControlEvents:UIControlEventTouchDown|UIControlEventTouchDragEnter]; \
	[(ctrl) addTarget:rootClass action:@selector(deactivate:) forControlEvents:UIControlEventTouchDragOutside|UIControlEventTouchDragExit|UIControlEventTouchUpOutside|UIControlEventTouchCancel]; \
})
#define GPAssignUIControlAsCloseButton(ctrl) [(ctrl) addTarget:[self class] action:@selector(close:) forControlEvents:UIControlEventTouchUpInside]
#define GPAssignUIControlAsDisclosureButton(ctrl) [(ctrl) addTarget:[self class] action:@selector(disclose:) forControlEvents:UIControlEventTouchUpInside]