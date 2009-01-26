/*
 
 datasource.h ... Datasource for hCClipboardView in ℏClipboard.
 
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


#import <Foundation/Foundation.h>
#import <UIKit/UITableView.h>

@class Clipboard;

@interface hCClipboardDataSource : NSObject<UITableViewDataSource> {
	Clipboard* clipboard;
	NSArray* dataCache;
	NSIndexSet* filteredSet;
	BOOL supportsEmoji, usesPrefix, secure;
}
@property(retain) Clipboard* clipboard;
@property(assign,readonly) NSArray* dataCache;
@property(assign) BOOL usesPrefix;
@property(assign,getter=isSecure) BOOL secure;
-(BOOL)switchClipboard;
-(void)updateDataCache;

-(id)init;
-(void)dealloc;

-(NSInteger)numberOfSectionsInTableView:(UITableView*)tbl;
-(NSInteger)tableView:(UITableView*)tbl numberOfRowsInSection:(NSInteger)section;
-(UITableViewCell*)tableView:(UITableView*)tbl cellForRowAtIndexPath:(NSIndexPath*)indexPath;
-(void)tableView:(UITableView*)tbl commitEditingStyle:(UITableViewCellEditingStyle)style forRowAtIndexPath:(NSIndexPath*)indexPath;
@end
