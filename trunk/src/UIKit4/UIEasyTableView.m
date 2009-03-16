/*
 
 UIEasyTableView.m ... Table view with static arrays as delegate & data source.
 
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

#import <UIKit4/UIEasyTableView.h>

@implementation UIEasyTableView 
-(id)initWithFrame:(CGRect)frm style:(UITableViewStyle)style headers:(NSArray*)headers_ data:(NSArray*)comps, ... {
	if ((self = [super initWithFrame:frm style:style])) {
		components = [[NSMutableArray alloc] init];
		NSArray* comp;
		va_list argumentList;
		if (comps) {
			[components addObject:comps];
			va_start(argumentList, comps);
			while ((comp = va_arg(argumentList, NSArray*)))
				[components addObject:comp];
			va_end(argumentList);
		}
		self.delegate = self;
		self.dataSource = self;
		headers = [headers_ retain];
	}
	return self;
}
-(void)dealloc {
	[headers release];
	[components release];
	[super dealloc];
}

-(void)registerSelectionMonitor:(id)delegate_ action:(SEL)selector {
	delegate = delegate_;
	action = selector;
}
-(void)registerCellStyler:(id)delegate_ action:(SEL)selector {
	styler_delegate = delegate_;
	styler_action = selector;
	styler_imp = [delegate_ methodForSelector:selector];
}

-(UITableViewCell*)tableView:(UITableView*)view cellForRowAtIndexPath:(NSIndexPath*)path {
	UITableViewCell* cell = [view dequeueReusableCellWithIdentifier:@"cellID"];
	if (cell == nil)
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:@"cellID"] autorelease];
	cell.text = [[components objectAtIndex:path.section] objectAtIndex:path.row];
	if (styler_imp != NULL)
		styler_imp(styler_delegate, styler_action, view, cell, path);
	return cell;
}
-(NSInteger)numberOfSectionsInTableView:(UITableView*)view { return [components count]; }
-(NSInteger)tableView:(UITableView*)view numberOfRowsInSection:(NSInteger)section { return [[components objectAtIndex:section] count]; }
-(NSString*)tableView:(UITableView*)view titleForHeaderInSection:(NSInteger)section {
	if ([headers count] > section)
		return [headers objectAtIndex:section];
	else
		return nil;
}
-(void)tableView:(UITableView*)view didSelectRowAtIndexPath:(NSIndexPath*)path {
	[delegate performSelector:action withObject:view withObject:path];
	[view deselectRowAtIndexPath:path animated:YES];
}

@end
