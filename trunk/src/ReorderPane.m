/*
 
 ReorderPane.m ... An editing pane for reordering items
 
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

#import <PrefHooker/ReorderPane.h>
#import <UIKit/UITableView.h>


@implementation PHReorderPane 
-(BOOL)requiresKeyboard { return NO; }
-(BOOL)drawLabel { return NO; }
-(id)initWithFrame:(CGRect)frm {
	if ((self = [super initWithFrame:frm])) {
		UITableView* tbl = [[UITableView alloc] initWithFrame:frm style:UITableViewStyleGrouped];
		[self addSubview:tbl];
		[tbl release];
		tbl.dataSource = self;
		tbl.delegate = self;
		tbl.editing = YES;
		list = [[NSMutableArray alloc] initWithObjects:
				[NSMutableArray arrayWithObjects:@"1",@"3",nil],
				[NSMutableArray arrayWithObjects:@"2",@"4",nil],
				[NSMutableArray arrayWithObjects:@"6",@"12",@"18",nil],
				nil];
		listCount = [list count];
		removedItems = [[NSMutableArray alloc] init];
	}
	return self;
}
-(void)dealloc {
	[list release];
	[removedItems release];
	[super dealloc];
}

-(NSUInteger)numberOfSectionsInTableView:(UITableView*)tbl { return listCount + 1; }
-(NSUInteger)tableView:(UITableView*)tbl numberOfRowsInSection:(NSUInteger)sect {
	return sect == listCount ? [removedItems count] : [[list objectAtIndex:sect] count];
}
-(UITableViewCell*)tableView:(UITableView*)tbl cellForRowAtIndexPath:(NSIndexPath*)indexPath {
	UITableViewCell* cell = [tbl dequeueReusableCellWithIdentifier:@"reord"];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:@"reord"] autorelease];
	}
	
	NSUInteger sect = indexPath.section;
	NSArray* arr = (sect == listCount) ? removedItems : [list objectAtIndex:sect];
	
	cell.text = [arr objectAtIndex:indexPath.row];
	
	return cell;
}

-(void)tableView:(UITableView*)tableView moveRowAtIndexPath:(NSIndexPath*)fromIndexPath toIndexPath:(NSIndexPath*)toIndexPath {
	NSUInteger row0 = fromIndexPath.row, sect0 = fromIndexPath.section, sect1 = toIndexPath.section;
	NSMutableArray* oldArr = (listCount == sect0) ? removedItems : [list objectAtIndex:sect0];
	NSMutableArray* newArr = (listCount == sect1) ? removedItems : [list objectAtIndex:sect1];
	NSObject* oldObj = [oldArr objectAtIndex:row0];
	[oldArr removeObjectAtIndex:row0];
	[newArr insertObject:oldObj atIndex:toIndexPath.row];
	[tableView performSelector:@selector(reloadData) withObject:nil afterDelay:0.5];
}
-(NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section {
	if (section == listCount)
		return @"Addible";
	if (listCount <= 1)
		return nil;
	else
		return [NSString stringWithFormat:@"Row %d", section+1];
}

-(UITableViewCellEditingStyle)tableView:(UITableView*)v editingStyleForRowAtIndexPath:(NSIndexPath*)ip {
	return ip.section == [list count] ? UITableViewCellEditingStyleInsert : UITableViewCellEditingStyleDelete;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	switch (editingStyle) {
		case UITableViewCellEditingStyleInsert:
			if (listCount > 0) {
				NSUInteger row = indexPath.row;
				[[list lastObject] addObject:[removedItems objectAtIndex:row]];
				[removedItems removeObjectAtIndex:row];
			}
			break;
		case UITableViewCellEditingStyleDelete: {
			NSMutableArray* arr = [list objectAtIndex:indexPath.section];
			NSUInteger row = indexPath.row;
			NSObject* obj = [arr objectAtIndex:row];

			[arr removeObjectAtIndex:row];
			[removedItems addObject:obj];
		}
			break;
		default:
			break;
	}
	[tableView reloadData];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
	return indexPath.section < listCount;
}
@end