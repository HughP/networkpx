/*
 
 UIBadgeView.m ... Controllable badge
 
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

#import <UIKit3/UIBadgeView.h>
#import <UIKit/UIKit.h>
#import <UIKit2/Functions.h>

#define HEIGHT 28
#define WIDTH  27

@implementation UIBadgeView
-(id)initWithFrame:(CGRect)frm {
	if ((self = [super initWithFrame:CGRectMake(frm.origin.x, frm.origin.y, WIDTH, HEIGHT)])) {
		background = [[UIImageView alloc] initWithImage:_UIImageWithName(@"UIButtonBarBadgeOff.png")];
		alterate = [[UIImageView alloc] initWithImage:_UIImageWithName(@"UIButtonBarBadgeOn.png")];
		alterate.hidden = YES;
		[self addSubview:background];
		[self addSubview:alterate];
		[background release];
		[alterate release];
		
		label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, WIDTH, HEIGHT)];
		label.textColor = [UIColor whiteColor];
		label.backgroundColor = [UIColor clearColor];
		label.font = [UIFont boldSystemFontOfSize:11];
		label.textAlignment = UITextAlignmentCenter;
		
		[self addSubview:label];
		[label release];
	}
	return self;
	
}
@dynamic text;
-(NSString*)text { return label.text; }
-(void)setText:(NSString*)text { label.text = text; }
-(void)setInteger:(NSInteger)integer { label.text = [NSString stringWithFormat:@"%d", integer]; }

@synthesize state;
-(void)setState:(BOOL)state_ {
	if (state != state_) {
		background.hidden = state_;
		alterate.hidden = !state_;
		state = state_;
	}
}
@end