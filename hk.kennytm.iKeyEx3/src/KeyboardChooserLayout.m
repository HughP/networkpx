/*

KeyboardChooserLayout.m ... Keyboard chooser layout.
 
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
#import <UIKit/UIKit2.h>
#import "libiKeyEx.h"

@interface KeyboardChooserLayout : UIKeyboardLayout<UITableViewDelegate, UITableViewDataSource> {
	NSArray* inputModes;
	UITableView* table;
	NSInteger checkedMode;
	UIKeyboardImpl* impl;
	UIView* blackLine;
}
@end

@implementation KeyboardChooserLayout
-(void)refresh {
	[inputModes release];
	inputModes = [UIKeyboardGetActiveInputModes() retain];
	checkedMode = [inputModes indexOfObject:[impl inputModeLastChosen]];
	
	[table reloadData];
	[table scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:checkedMode inSection:0]
				 atScrollPosition:UITableViewScrollPositionMiddle
						 animated:NO];
}

-(BOOL)shouldShowIndicator { return NO; }

-(id)initWithFrame:(CGRect)frm {
	if ((self = [super initWithFrame:frm])) {
		impl = [UIKeyboardImpl sharedInstance];
		blackLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frm.size.width, 1)];
		blackLine.backgroundColor = [UIColor blackColor];
		blackLine.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
		[self addSubview:blackLine];
		[blackLine release];
		self.backgroundColor = [UIColor clearColor];
		[self refresh];
		table = [[UITableView alloc] initWithFrame:CGRectMake(0, 1, frm.size.width, frm.size.height-1) style:UITableViewStyleGrouped];
		table.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		table.delegate = self;
		table.dataSource = self;
		[self addSubview:table];
		[table release];
		self.autoresizesSubviews = YES;
	}
	return self;
}

-(UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
	NSInteger row = indexPath.row;
	UITableViewCell* cachedCell = [tableView dequeueReusableCellWithIdentifier:@"."];
	if (cachedCell == nil)
		cachedCell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"."] autorelease];
	cachedCell.textLabel.text = IKXNameOfMode([inputModes objectAtIndex:row]);
	cachedCell.accessoryType = (row == checkedMode) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
	return cachedCell;
}
-(NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
	return [inputModes count];
}

-(void)showKeyboardType:(UIKeyboardType)kbtype withAppearance:(UIKeyboardAppearance)appr {
	[self refresh];
}
-(void)dealloc {
	[inputModes release];
	[super dealloc];
}

-(void)tableView:(UITableView*)view didSelectRowAtIndexPath:(NSIndexPath*)path {
	IKXPlaySound();
	NSUInteger row = path.row;
	NSString* mode = [inputModes objectAtIndex:row];
	if (row == checkedMode) {
		// Fix issue 499.
		NSString* fixup_mode = @"fr";
		if ([mode isEqualToString:fixup_mode])
			fixup_mode = @"en_US";
		[impl setInputMode:fixup_mode];
	}
	[impl setInputMode:mode];
	[impl showInputModeIndicator];
	[impl setInputModeLastChosenPreference];
}
@end

