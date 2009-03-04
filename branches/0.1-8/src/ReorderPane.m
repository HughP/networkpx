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

// being lazy :)
#define list preferenceValue

@implementation PHReorderPane 
-(BOOL)requiresKeyboard { return NO; }
-(BOOL)drawLabel { return NO; }

@synthesize preferenceValue;
-(void)setPreferenceValue:(NSArray*)prefValue {
	if (list != prefValue) {
		[list release];
		// can I have a *deep* mutable copy instead??
		list = [prefValue mutableCopy];
		listCount = [list count];
	}
}

-(id)initWithFrame:(CGRect)frm {
	if ((self = [super initWithFrame:frm])) {
		UITableView* tbl = [[UITableView alloc] initWithFrame:frm style:UITableViewStyleGrouped];
		[self addSubview:tbl];
		[tbl release];
		tbl.dataSource = self;
		tbl.delegate = self;
		tbl.editing = YES;
	}
	return self;
}
-(void)dealloc {
	[list release];
	[super dealloc];
}

-(NSUInteger)numberOfSectionsInTableView:(UITableView*)tbl { return listCount ?: 1; }
-(NSUInteger)tableView:(UITableView*)tbl numberOfRowsInSection:(NSUInteger)sect {
	return listCount == 0 ? 0 : [[list objectAtIndex:sect] count];
}
-(UITableViewCell*)tableView:(UITableView*)tbl cellForRowAtIndexPath:(NSIndexPath*)indexPath {
	UITableViewCell* cell = [tbl dequeueReusableCellWithIdentifier:@"reord"];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:@"reord"] autorelease];
	}
	
	NSUInteger sect = indexPath.section;
	
	cell.text = [[list objectAtIndex:sect] objectAtIndex:indexPath.row];
	
	return cell;
}

-(void)tableView:(UITableView*)tableView moveRowAtIndexPath:(NSIndexPath*)fromIndexPath toIndexPath:(NSIndexPath*)toIndexPath {
	NSUInteger row0 = fromIndexPath.row, sect0 = fromIndexPath.section, sect1 = toIndexPath.section;
	NSMutableArray* oldArr = [list objectAtIndex:sect0];
	NSMutableArray* newArr = [list objectAtIndex:sect1];
	NSObject* oldObj = [oldArr objectAtIndex:row0];
	[oldArr removeObjectAtIndex:row0];
	[newArr insertObject:oldObj atIndex:toIndexPath.row];
	[tableView performSelector:@selector(reloadData) withObject:nil afterDelay:0.5];
}
-(NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section {
	if (section == listCount-1)
		return @"Not Added";
	if (listCount <= 2)
		return nil;
	else
		return [NSString stringWithFormat:@"Section %d", section+1];
}

-(UITableViewCellEditingStyle)tableView:(UITableView*)v editingStyleForRowAtIndexPath:(NSIndexPath*)ip {
	return ip.section == listCount-1 ? UITableViewCellEditingStyleInsert : UITableViewCellEditingStyleDelete;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	switch (editingStyle) {
		case UITableViewCellEditingStyleInsert:
			if (listCount > 0) {
				NSUInteger row = indexPath.row;
				NSMutableArray* removedItems = [list lastObject];
				[[list objectAtIndex:0] addObject:[removedItems objectAtIndex:row]];
				[removedItems removeObjectAtIndex:row];
			}
			break;
		case UITableViewCellEditingStyleDelete: {
			NSMutableArray* arr = [list objectAtIndex:indexPath.section];
			NSUInteger row = indexPath.row;
			NSObject* obj = [arr objectAtIndex:row];

			[arr removeObjectAtIndex:row];
			[[list lastObject] addObject:obj];
		}
			break;
		default:
			break;
	}
	[tableView reloadData];
}

-(BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
	return indexPath.section < listCount-1;
}
@end

#undef list