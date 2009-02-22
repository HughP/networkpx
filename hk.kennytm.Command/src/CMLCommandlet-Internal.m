/*
 
 CMLCommandlet-Internal.m ... Internal API for manipulating ⌘lets.
 
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


#import <Command/CMLCommandlet.h>
#import <UIKit2/UIAlert.h>
#import <UIKit3/UIUtilities.h>
#import <UIKit3/UIActionSheetPro.h>
#import <UIKit/UIKit.h>

@interface UIGlassButton : UIButton @end


@implementation CMLCommandlet
+(void)dismissWithButton:(UIButton*)btn {
	NSLog(@"%@", [btn currentTitle]);
}

+(void)showActionMenuForWebTexts:(UIWebTexts*)txts {
	UIActionSheet* sheet = [[UIActionSheet alloc] initWithTitle:@"\n\n\n\n\n\n"
													   delegate:nil
											  cancelButtonTitle:@"Cancel"
										 destructiveButtonTitle:nil
											  otherButtonTitles:@"Unicode", nil];
	wchar_t symbols[] = L"!@#$%^&*()`~-=[]\\;',./«»_+{}|:\"<>?¿¡•€£¥₩¢°±µ½§␀";
	NSUInteger width = 320/12, height = 28;
	NSUInteger left0 = (320 - width*12)/2;
	NSUInteger left = left0;
	NSUInteger top = 0;
	UIView* glassButtonsContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 10, width*12, height*4)];
	for (wchar_t* c = symbols; *c != '\0'; ++ c) {
		UIButton* btn = [[UIButton alloc] initWithFrame:CGRectMake(left, top, width, height)];
		[btn setTitle:[NSString stringWithCharacters:(unichar*)c length:1] forState:UIControlStateNormal];
		btn.showsTouchWhenHighlighted = YES;
		[btn setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
		[btn addTarget:self action:@selector(dismissWithButton:) forControlEvents:UIControlEventTouchUpInside];
		[glassButtonsContainer addSubview:btn];
		[btn release];
		left += width;
		if (left >= width*12) {
			left = left0;
			top += height;
		}
	}
	[sheet addSubview:glassButtonsContainer];
	
	[sheet showInView:[txts.view.window.subviews objectAtIndex:0]];
	
	UILogViewHierarchy(sheet);
	[sheet release];
}
@end;