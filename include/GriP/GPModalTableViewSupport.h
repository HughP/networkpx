/*
 
 GPModalTableViewSupport.h ... Modal Table View Support Classes.
 
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

/// NOT TO BE USED OUTSIDE OF THE GriP SERVER

#import <AddressBook/ABRecord.h>
#import <Foundation/NSObject.h>
#import <UIKit/UITableView.h>
#import <UIKit/UITextInputTraits.h>

@class NSString, NSArray, NSDictionary, NSMutableDictionary, GPModalTableViewController;

__attribute__((visibility("hidden")))
@interface GPModalTableViewObject : NSObject {
@package
	NSString* title;
	NSString* subtitle;
	NSString* identifier;
	id icon;
	NSString* detail;
	UITableViewCellAccessoryType accessoryType;
	NSString* placeholder;
	int lines;
	UIKeyboardType keyboard;
	int uid;
	ABPropertyID addressbook;
	BOOL header;
	BOOL noselect;
	BOOL reorder;
	BOOL edit;
	BOOL secure;
	BOOL html;
	BOOL readonly;
	BOOL compact;
	BOOL candelete;
	BOOL dirty;
}
@property(retain) NSString* detail;
@property(retain,readonly,nonatomic) NSString* uidString;

-(id)initWithEntry:(NSDictionary*)entry imageCache:(NSMutableDictionary*)cache;
+(GPModalTableViewObject*)newEmptyHeaderObject;
-(void)updateWithEntry:(NSDictionary*)entry imageCache:(NSMutableDictionary*)cache;
-(void)dealloc;
-(NSString*)description;
@end



static inline int GPFindString(NSString* string, NSString* const array[], int arrayCount) {
	if (string == nil)
		return -2;
	for (--arrayCount; arrayCount >= 0; --arrayCount)
		if ([array[arrayCount] isEqualToString:string])
			break;
	return arrayCount;
}


__attribute__((visibility("hidden")))
@interface GPModalTableViewContentView : UIView {
	GPModalTableViewObject* object;
}
-(void)setObject:(GPModalTableViewObject*)newObject withController:(GPModalTableViewController*)controller;
-(void)dealloc;
@end
