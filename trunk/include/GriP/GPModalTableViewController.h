/*
 
 GPModalTableViewController.h ... Modal Table View Controllers.
 
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

#import <UIKit/UITableViewController.h>
#import <CoreFoundation/CFArray.h>
#import <CoreGraphics/CGGeometry.h>

@class UIWindow, NSDictionary, UITableView, UIToolbar, UITextView, NSArray, NSMutableArray, UIBarButtonItem, GPModalTableViewObject, UINavigationController, GPModalTableViewController;
@protocol UITextViewDelegate, UITextFieldDelegate, ABPeoplePickerNavigationControllerDelegate;

@interface GPModalTableViewNavigationController : UIViewController {
	NSNumber* uid;
	NSString* clientPortID;
	NSMutableDictionary* toolbarButtons;
	UIToolbar* toolbar;
	UINavigationController* navCtrler;
	
	NSBundle* themeBundle;
	NSDictionary* themeInfoDict;
}
@property(retain) NSNumber* uid;
@property(retain) NSString* clientPortID;
@property(readonly,assign,nonatomic) BOOL visible;
-(id)initWithDictionary:(NSDictionary*)dictionary;
-(void)dealloc;
-(void)pushDictionary:(NSDictionary*)dictionary;
-(void)pop;
-(void)updateToDictionary:(NSDictionary*)dictionary forIdentifier:(NSString*)identifier;
-(void)updateItem:(NSString*)identifier toEntry:(NSDictionary*)entry;
-(void)updateButtons:(NSArray*)buttons forIdentifier:(NSString*)identifier;
-(void)animateOut;
@property(retain,readonly) GPModalTableViewController* topViewController;
-(void)sendDismissMessage;

-(UIImage*)imageWithName:(NSString*)name;
-(id)objectForKey:(NSString*)key;
-(UIColor*)colorForKey:(NSString*)key;
@end


//------------------------------------------------------------------------------

@interface GPModalTableViewController : UITableViewController<ABPeoplePickerNavigationControllerDelegate> {
	// views:
	UIToolbar* toolbar;
	UITextView* activeTextView;
	// data:
	NSMutableArray* entries;
	CFArrayRef sectionIndices;
	CGFloat lastRowHeight;
	GPModalTableViewObject* activeABObject;
	NSString* identifier;
	GPModalTableViewNavigationController* rootCtrler;
}
-(id)initWithDictionary:(NSDictionary*)dictionary controller:(GPModalTableViewNavigationController*)rootCtrler_;
-(void)updateDictionary:(NSDictionary*)dictionary;
-(void)dealloc;
@property(retain) NSString* identifier;

// actions
-(void)updateItem:(NSString*)identifier toEntry:(NSDictionary*)entry;
-(void)endEditingWithCheck:(NSString*)identifier;
-(void)endEditing;

-(void)appendABValue:(CFTypeRef)value;
@end
