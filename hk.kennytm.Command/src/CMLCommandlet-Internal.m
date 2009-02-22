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

@implementation CMLCommandlet
+(void)showActionMenuForWebTexts:(UIWebTexts*)txts {
	UIActionSheetPro* sheet = [[UIActionSheetPro alloc] initWithNumberOfRows:3];
	sheet.title = [txts description];
	
	[sheet addButtonAtRow:0 withTitle:@"Cut" image:nil destructive:NO cancel:NO];
	[sheet addButtonAtRow:0 withTitle:@"Copy" image:nil destructive:NO cancel:NO];
	[sheet addButtonAtRow:0 withTitle:@"Paste" image:nil destructive:NO cancel:NO];
	[sheet addButtonAtRow:1 withTitle:@"Google" image:nil destructive:YES cancel:NO];
	[sheet addButtonAtRow:1 withTitle:@"Twitter" image:nil destructive:NO cancel:NO];
	[sheet addButtonAtRow:1 withTitle:@"翻譯" image:nil destructive:NO cancel:NO];
	[sheet addButtonAtRow:2 withTitle:@"Undo" image:nil destructive:NO cancel:NO];
	[sheet addButtonAtRow:2 withTitle:@"Redo" image:nil destructive:NO cancel:NO];
	[sheet addButtonAtRow:2 withTitle:@"Cancel" image:nil destructive:NO cancel:YES];
	
	[sheet showWithWebTexts:txts inView:[txts.view.window.subviews objectAtIndex:0]];
	
	UILogViewHierarchy(sheet);
	[sheet release];
}
@end;