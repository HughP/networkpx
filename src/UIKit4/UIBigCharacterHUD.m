/*
 
 UIBigCharacterHUD.m ... HUD with a big character and a message.
 
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

#import <UIKit/UIKit.h>
#import <UIKit4/UIBigCharacterHUD.h>
#import <GraphicsUtilities.h>

#define MESSAGE_HEIGHT 32

@implementation UIBigCharacterHUD;
@dynamic message, title;
-(id)initWithFrame:(CGRect)frm {
	if ((self = [super initWithFrame:frm])) {
		UIGraphicsBeginImageContext(frm.size);
		CGContextRef c = UIGraphicsGetCurrentContext();
		CGPathRef path = GUPathCreateRoundRect(CGRectMake(0, 0, frm.size.width, frm.size.height), 10);
		[[UIColor colorWithWhite:0 alpha:0.77] setFill];
		CGContextAddPath(c, path);
		CGContextFillPath(c);
		UIImageView* background = [[UIImageView alloc] initWithImage:UIGraphicsGetImageFromCurrentImageContext()];
		CGPathRelease(path);
		UIGraphicsEndImageContext();
		
		[self addSubview:background];
		[background release];
		
		messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, frm.size.height-MESSAGE_HEIGHT, frm.size.width, MESSAGE_HEIGHT)];
		messageLabel.textColor = [UIColor whiteColor];
		messageLabel.backgroundColor = [UIColor clearColor];
		messageLabel.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
		messageLabel.textAlignment = UITextAlignmentCenter;
		messageLabel.numberOfLines = 2;
		messageLabel.lineBreakMode = UILineBreakModeMiddleTruncation;
		[self addSubview:messageLabel];
		[messageLabel release];
		
		titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, frm.size.width, frm.size.height-MESSAGE_HEIGHT)];
		titleLabel.textColor = [UIColor whiteColor];
		titleLabel.backgroundColor = [UIColor clearColor];
		titleLabel.textAlignment = UITextAlignmentCenter;
		titleLabel.font = [UIFont boldSystemFontOfSize:(frm.size.height-MESSAGE_HEIGHT)*0.9];
		[self addSubview:titleLabel];
		[titleLabel release];
	}
	
	return self;
}

-(NSString*)message { return messageLabel.text; }
-(void)setMessage:(NSString*)msg { messageLabel.text = msg; }

-(NSString*)title { return titleLabel.text; }
-(void)setTitle:(NSString*)title { titleLabel.text = title; }

@end
