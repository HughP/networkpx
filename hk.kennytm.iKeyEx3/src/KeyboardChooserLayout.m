/*

FILE_NAME ... DESCRIPTION
 
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

#import <iKeyEx/ImageLoader.h>
#import <iKeyEx/UIKBSound.h>
#import <iKeyEx/UIKBInfo.h>
#import <UIKit/UIKit.h>
#import <UIKit2/UIKeyboardLayout.h>
#import <UIKit2/Functions.h>
#import <UIKit2/UIKeyboardImpl.h>
#import <UIKit4/UIEasyTableView.h>

@interface KeyboardChooserLayout : UIKeyboardLayout {
	NSArray* inputModes;
	UIEasyTableView* table;
	NSInteger checkedMode;
	UIKeyboardImpl* impl;
	UIView* blackLine;
}
-(id)initWithFrame:(CGRect)frm;
-(void)showKeyboardType:(UIKeyboardType)kbtype withAppearance:(UIKeyboardAppearance)appr;
-(void)refresh;
-(void)layoutSubviews;
-(void)dealloc;
-(void)tableView:(UITableView*)view styleCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)path;
-(void)tableView:(UITableView*)view didSelectRowAtIndexPath:(NSIndexPath*)path;
@end

@implementation KeyboardChooserLayout
-(id)initWithFrame:(CGRect)frm {
	if ((self = [super initWithFrame:frm])) {
		impl = [UIKeyboardImpl sharedInstance];
		blackLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frm.size.width, 1)];
		blackLine.backgroundColor = [UIColor blackColor];
		[self addSubview:blackLine];
		[blackLine release];
		self.backgroundColor = [UIColor clearColor];
		[self refresh];
	}
	return self;
}
-(void)showKeyboardType:(UIKeyboardType)kbtype withAppearance:(UIKeyboardAppearance)appr {
	[self refresh];
}
-(void)refresh {
	[inputModes release];
	inputModes = [UIKeyboardGetActiveInputModes() retain];
	checkedMode = [inputModes indexOfObject:[impl inputModeLastChosen]];
	[table removeFromSuperview];
	
	NSMutableArray* titles = [[NSMutableArray alloc] init];
	for (NSString* mode in inputModes)
		[titles addObject:UIKBGetKeyboardDisplayName(mode)];
	
	CGRect bounds = self.bounds;
	table = [[UIEasyTableView alloc] initWithFrame:CGRectMake(0, 1, bounds.size.width, bounds.size.height-1)
											 style:UITableViewStyleGrouped
										   headers:nil
											  data:titles, nil];
	[titles release];
	
	[table registerCellStyler:self action:@selector(tableView:styleCell:atIndexPath:)];
	[table registerSelectionMonitor:self action:@selector(tableView:didSelectRowAtIndexPath:)];
	[self addSubview:table];
	[table release];
	[table reloadData];
	[table scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:checkedMode inSection:0]
				 atScrollPosition:UITableViewScrollPositionMiddle
						 animated:NO];
}
-(void)layoutSubviews {
	CGRect bounds = self.bounds;
	table.frame = CGRectMake(0, 1, bounds.size.width, bounds.size.height-1);
	blackLine.frame = CGRectMake(0, 0, bounds.size.width, 1);
}
-(void)dealloc {
	[inputModes release];
	[super dealloc];
}

-(void)tableView:(UITableView*)view styleCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)path {
	cell.accessoryType = (path.row == checkedMode) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
}
-(void)tableView:(UITableView*)view didSelectRowAtIndexPath:(NSIndexPath*)path {
	[UIKBSound play];
	[impl setInputMode:[inputModes objectAtIndex:path.row]];
	[impl showInputModeIndicator];
	[impl setInputModeLastChosenPreference];
}
@end

