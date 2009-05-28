/*
 
 GPModalTableViewController.m ... Modal Table View Controllers.
 
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
#import <UIKit/UIKit.h>
#import <GriP/Duplex/Server.h>
#import <GriP/common.h>
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/ABPeoplePickerNavigationController.h>
#import <GriP/GPModalTableViewSupport.h>
#import <GriP/GPModalTableViewController.h>


@interface UITextView ()
-(NSString*)contentAsHTMLString;
@end
@interface GPModalTableViewNavigationController ()
-(void)toolbarButtonClicked:(UIBarButtonItem*)item;
@end


@implementation GPModalTableViewNavigationController
static UIWindow* window = nil;
static UIViewController* masterController = nil;
static UIViewController* deepestController = nil;

@synthesize uid, clientPortID;
@dynamic visible;
-(id)initWithDictionary:(NSDictionary*)dictionary {
	if ((self = [super init])) {
		toolbarButtons = [[NSMutableDictionary alloc] init];
		
		BOOL isWindowNil = window == nil;
		if (isWindowNil) {
			window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
			window.windowLevel = UIWindowLevelAlert;
			window.exclusiveTouch = YES;
			masterController = [[UIViewController alloc] init];
			[window addSubview:masterController.view];
			window.hidden = NO;
			deepestController = masterController;
		} else
			deepestController = deepestController.modalViewController;
		
		GPModalTableViewController* controller = [[GPModalTableViewController alloc] initWithDictionary:dictionary controller:self];
		navCtrler = [[UINavigationController alloc] initWithRootViewController:controller];
		UIBarButtonItem* closeButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(sendDismissMessage)];
		controller.navigationItem.leftBarButtonItem = closeButtonItem;
		[closeButtonItem release];
		[controller release];
		
		[deepestController presentModalViewController:self animated:YES];
	}
	return self;
}
-(void)pushDictionary:(NSDictionary*)dictionary {
	GPModalTableViewController* controller = [[GPModalTableViewController alloc] initWithDictionary:dictionary controller:self];
	[navCtrler pushViewController:controller animated:YES];
	[controller release];
}
-(void)pop {
	[navCtrler popViewControllerAnimated:YES];
}
-(void)animateOut {
	deepestController = deepestController.parentViewController;
	[self dismissModalViewControllerAnimated:YES];
}
-(void)dealloc {
	if (deepestController == nil) {
		//[masterController.view removeFromSuperview];
		[masterController release];
		masterController = nil;
		[window release];
		window = nil;
	}
	[uid release];
	[clientPortID release];
	[navCtrler release];
	[toolbarButtons release];
	[super dealloc];
}
-(GPModalTableViewController*)viewControllerWithIdentifier:(NSString*)identifier {
	if (identifier == nil)
		return (GPModalTableViewController*)navCtrler.topViewController;
	else {
		for (GPModalTableViewController* controller in [navCtrler.viewControllers reverseObjectEnumerator])
			if ([controller.identifier isEqualToString:identifier])
				return controller;
		return nil;
	}
}
-(BOOL)visible { return !window.hidden; }
-(void)updateItem:(NSString*)identifier toEntry:(NSDictionary*)entry { [(GPModalTableViewController*)navCtrler.topViewController updateItem:identifier toEntry:entry]; }

-(void)updateButtons:(NSArray*)newButtons forIdentifier:(NSString*)identifier {
	if (newButtons != nil) {
		[toolbarButtons setObject:newButtons forKey:identifier];
		if (![((GPModalTableViewController*)navCtrler.topViewController).identifier isEqualToString:identifier])
			return;
	} else
		newButtons = [toolbarButtons objectForKey:identifier];
	
	
	static NSString* const systemToolbarItems[] = {
		@"Done", @"Cancel", @"Edit", @"Save", @"Add",
		@"FlexibleSpace", @"FixedSpace",
		@"Compose", @"Reply", @"Action", @"Organize",
		@"Bookmarks", @"Search", @"Refresh", @"Stop",
		@"Camera", @"Trash",
		@"Play", @"Pause", @"Rewind", @"FastForward"
	};
	
	BOOL hasFlexibleSpace = NO;
	UIBarButtonItem* forceAlignRightItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL];
	NSMutableArray* toolbarItems = [[NSMutableArray alloc] initWithObjects:forceAlignRightItem, nil];
	[forceAlignRightItem release];
	int i = 0;
	for (id buttonObject in newButtons) {
		UIBarButtonItem* item = [UIBarButtonItem alloc];
		BOOL isBlue = NO;
		if ([buttonObject isKindOfClass:[NSDictionary class]]) {
			isBlue = [[buttonObject objectForKey:@"blue"] boolValue];
			buttonObject = [buttonObject objectForKey:@"label"];
		}
		if (buttonObject == nil)
			buttonObject = @"FlexibleSpace";
		
		int systemToolbarIndex = GPFindString((NSString*)buttonObject, systemToolbarItems, sizeof(systemToolbarItems)/sizeof(NSString*));
		if (systemToolbarIndex >= 0) {
			item = [item initWithBarButtonSystemItem:systemToolbarIndex target:self action:@selector(toolbarButtonClicked:)];
			if (systemToolbarIndex == UIBarButtonSystemItemFlexibleSpace && !hasFlexibleSpace) {
				hasFlexibleSpace = YES;
				[toolbarItems removeObjectAtIndex:0];
			}
		} else {
			if ([@"ActivityIndicator" isEqualToString:buttonObject]) {
				UIActivityIndicatorView* activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
				[activityIndicatorView startAnimating];
				item = [item initWithCustomView:activityIndicatorView];
				[activityIndicatorView release];
			} else
				item = [item initWithTitle:buttonObject style:UIBarButtonItemStyleBordered target:self action:@selector(toolbarButtonClicked:)];
		}
		
		item.tag = i;
		item.style = isBlue ? UIBarButtonItemStyleDone : UIBarButtonItemStyleBordered;
		[toolbarItems addObject:item];
		[item release];
		++ i;
	}
	[toolbar setItems:toolbarItems animated:YES];
	[toolbarItems release];
	
}
-(void)toolbarButtonClicked:(UIBarButtonItem*)item {
	id buttonObject = [[toolbarButtons objectForKey:((GPModalTableViewController*)navCtrler.topViewController).identifier] objectAtIndex:item.tag];
	NSString* buttonID;
	if ([buttonObject isKindOfClass:[NSString class]])
		buttonID = buttonObject;
	else
		buttonID = [buttonObject objectForKey:@"id"];
	GPServerForwardMessage((CFStringRef)clientPortID, GPTVAMessage_ButtonClicked,
						   (CFDataRef)[NSPropertyListSerialization dataFromPropertyList:[NSArray arrayWithObjects:uid, buttonID, nil]
																				 format:NSPropertyListBinaryFormat_v1_0
																	   errorDescription:NULL], NULL);
}
-(void)sendDismissMessage {
	CFMutableDataRef dataToSend = CFDataCreateMutable(NULL, 0);
	int rawUid = [uid intValue];
	CFDataAppendBytes(dataToSend, (const UInt8*)&rawUid, sizeof(int));
	CFDataAppendBytes(dataToSend, (const UInt8*)[clientPortID UTF8String], [clientPortID length]+1);
	GPServerCallback(NULL, GPTVAMessage_Dismiss, dataToSend, NULL);
	CFRelease(dataToSend);
}

-(void)updateToDictionary:(NSDictionary*)dictionary forIdentifier:(NSString*)identifier {
	GPModalTableViewController* ctrler = [self viewControllerWithIdentifier:identifier];
	[ctrler updateDictionary:dictionary];
	[ctrler.tableView reloadData];
}
-(void)loadView {
	CGRect selfFrame = masterController.view.bounds;
	
	UIView* mainView = [[UIView alloc] initWithFrame:selfFrame];
	self.view = mainView;
	[mainView release];
	
	toolbar = [[UIToolbar alloc] initWithFrame:selfFrame];
	toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
	[toolbar sizeToFit];
	
	CGFloat toolbarHeight = toolbar.frame.size.height;
	selfFrame.size.height -= toolbarHeight;
	toolbar.frame = CGRectMake(0, selfFrame.size.height, selfFrame.size.width, toolbarHeight);
	[mainView addSubview:toolbar];
	[toolbar release];
	
	[navCtrler viewWillAppear:NO];
	UIView* navView = navCtrler.view;
	navView.frame = selfFrame;
	[mainView insertSubview:navView atIndex:0];
	[navCtrler viewDidAppear:NO];
}
@end
	


@implementation GPModalTableViewController
@synthesize identifier;
-(void)loadView { self.view = [[[UIView alloc] init] autorelease]; }

#define ActualIndex(indexPath) ((int)CFArrayGetValueAtIndex(sectionIndices, (indexPath).section) + 1 + (indexPath).row)
#define ActualObjectAtIndex(index) ((GPModalTableViewObject*)[entries objectAtIndex:(int)(index)])
#define ActualObject(indexPath) ActualObjectAtIndex(ActualIndex(indexPath))
#define ForwardMessage(message, restOfArray...) ({ \
	GPServerForwardMessage((CFStringRef)rootCtrler.clientPortID, \
						   (message), (CFDataRef)[NSPropertyListSerialization dataFromPropertyList:[NSArray arrayWithObjects:rootCtrler.uid, restOfArray, nil] \
																							format:NSPropertyListBinaryFormat_v1_0  \
																				  errorDescription:NULL], NULL); \
})

-(id)initWithDictionary:(NSDictionary*)dictionary controller:(GPModalTableViewNavigationController*)rootCtrler_ {
	if ((self = [super initWithStyle:UITableViewStylePlain])) {
		rootCtrler = rootCtrler_;
		[self updateDictionary:dictionary];
	}
	return self;
}
-(void)updateDictionary:(NSDictionary*)dictionary {
	[self endEditing];
	NSString* title = self.title = [dictionary objectForKey:@"title"];
	NSString* iden = self.identifier = [dictionary objectForKey:@"id"] ?: title;
	[rootCtrler updateButtons:[dictionary objectForKey:@"buttons"] forIdentifier:iden];
	
	[entries release];
	entries = [[NSMutableArray alloc] init];
	if (sectionIndices != NULL)
		CFRelease(sectionIndices);
	sectionIndices = CFArrayCreateMutable(NULL, 0, NULL);
	NSMutableDictionary* imageCache = [[NSMutableDictionary alloc] init];
	int i = 0;
	for (NSDictionary* entry in [dictionary objectForKey:@"entries"]) {
		GPModalTableViewObject* object = [[GPModalTableViewObject alloc] initWithEntry:entry imageCache:imageCache];
		if (i == 0 && !object->header) {
			GPModalTableViewObject* headerObject = [GPModalTableViewObject newEmptyHeaderObject];
			[entries addObject:headerObject];
			[headerObject release];
			++i;
			CFArrayAppendValue(sectionIndices, (const void*)0);
		}
		[entries addObject:object];
		[object release];
		if (object->header)
			CFArrayAppendValue(sectionIndices, (const void*)i);
		++i;
	}
	[imageCache release];
}
-(void)dealloc {
	[entries release];
	[identifier release];
	CFRelease(sectionIndices);
	[super dealloc];
}

#pragma mark -

-(void)showAddressBook:(UIButton*)button {
	[self endEditing];
	
	activeTextView = (UITextView*)[button.superview viewWithTag:1966];
	activeABObject = ActualObjectAtIndex(button.tag);
	ABPeoplePickerNavigationController* addressBookController = [[ABPeoplePickerNavigationController alloc] init];
	addressBookController.peoplePickerDelegate = self;
	addressBookController.displayedProperties = [NSArray arrayWithObject:[NSNumber numberWithInt:activeABObject->addressbook]];
	[self presentModalViewController:addressBookController animated:YES];
	[addressBookController release];
}

-(void)updateItem:(NSString*)itemIdentifier toEntry:(NSDictionary*)entry {
	[self endEditing];
	for (GPModalTableViewObject* object in entries)
		if ([object->identifier isEqualToString:itemIdentifier])
			[object updateWithEntry:entry imageCache:nil];
}

-(void)endEditingWithCheck:(NSString*)itemIdentifier {
	if (activeTextView == nil)
		return;
	
	UITableView* table = self.tableView;
	table.scrollEnabled = YES;
	self.navigationItem.rightBarButtonItem = nil;
	
	NSIndexPath* indexPath = [table indexPathForCell:(UITableViewCell*)activeTextView.superview.superview.superview];
	if (indexPath == nil)
		return;
	
	GPModalTableViewObject* object = ActualObject(indexPath);
	
	if (itemIdentifier == nil || [itemIdentifier isEqualToString:object->identifier]) {
		[activeTextView resignFirstResponder];
		NSString* detail = (object->html && object->lines != 1) ? [activeTextView contentAsHTMLString] : activeTextView.text;
		object.detail = detail;
		ForwardMessage(GPTVAMessage_DescriptionChanged, detail, object->identifier);
		activeTextView = nil;
		[table scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
	}
	
}

-(void)endEditing { [self endEditingWithCheck:nil]; }

#pragma mark -

// Until I'm 100% sure auto-rotation works on 3.x... No autorotate for 3.x.
/*-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
	if (orientation == UIInterfaceOrientationPortrait)
		return YES;
	else
		return [[UIDevice currentDevice].systemVersion hasPrefix:@"2."];
}*/

-(void)viewDidLoad {
	UITableView* table = self.tableView;
	table.editing = YES;
	table.allowsSelectionDuringEditing = YES;
	
	// check if we are on the top level. if yes, add a close button.
}
-(void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[rootCtrler updateButtons:nil forIdentifier:self.identifier];
}

#pragma mark -
#pragma mark UITableViewDataSource

-(UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
	int index = ActualIndex(indexPath);
	GPModalTableViewObject* object = ActualObjectAtIndex(index);
	
	BOOL useSimpleCell = object->subtitle == nil && object->detail == nil && !object->edit;
	NSString* uidString = useSimpleCell ? @"SimpleUID" : object.uidString;
	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:uidString];
	
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:uidString] autorelease];
		object->dirty = YES;
	}
	
	if (object->dirty) {
		cell.tag = useSimpleCell;
		cell.hidesAccessoryWhenEditing = NO;
		if (object->addressbook != 0 && object->edit) {
			UIButton* abButton = [UIButton buttonWithType:UIButtonTypeContactAdd];
			[abButton addTarget:self action:@selector(showAddressBook:) forControlEvents:UIControlEventTouchUpInside];
			abButton.tag = index;
			cell.accessoryView = abButton;
			if ([cell respondsToSelector:@selector(setEditingAccessoryView:)])
				[cell setEditingAccessoryView:abButton];
		} else {
			cell.accessoryView = nil;
			if ([cell respondsToSelector:@selector(setEditingAccessoryView:)]) {
				[cell setEditingAccessoryView:nil];
				[cell setEditingAccessoryType:object->accessoryType];
			}
			cell.accessoryType = object->accessoryType;			
		}
		cell.showsReorderControl = object->reorder;
		cell.selectionStyle = object->noselect ? UITableViewCellSelectionStyleNone : UITableViewCellSelectionStyleBlue;
		if (useSimpleCell) {
			cell.text = object->title;
			cell.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
			cell.image = object->icon;
			lastRowHeight = 36;
		} else {
			UIView* contentView = cell.contentView;
			[[contentView.subviews lastObject] removeFromSuperview];
			CGRect curFrame = CGRectInset(contentView.bounds, 8, 8);
			GPModalTableViewContentView* contentSubview = [[GPModalTableViewContentView alloc] initWithFrame:curFrame];
			[contentView addSubview:contentSubview];
			[contentSubview setObject:object withController:self];
			contentSubview.autoresizesSubviews = YES;
			contentSubview.contentMode = UIViewContentModeScaleToFill;
			contentSubview.autoresizingMask = UIViewAutoresizingFlexibleWidth;
			contentSubview.userInteractionEnabled = object->edit;
			lastRowHeight = contentSubview.frame.size.height + 9;
			[contentSubview release];
		}
		object->dirty = NO;
	}
	
	return cell;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView*)tableView { return CFArrayGetCount(sectionIndices); }
-(NSInteger)tableView:(UITableView*)view numberOfRowsInSection:(NSInteger)section {
	if (section == CFArrayGetCount(sectionIndices)-1) {
		return [entries count] - (int)CFArrayGetValueAtIndex(sectionIndices, section) - 1;
	} else {
		int indices[2];
		CFArrayGetValues(sectionIndices, CFRangeMake(section, 2), (const void**)indices);
		return indices[1] - indices[0] - 1;
	}
}
-(NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section {
	return ActualObjectAtIndex(CFArrayGetValueAtIndex(sectionIndices, section))->title;
}

-(void)tableView:(UITableView*)tableView moveRowAtIndexPath:(NSIndexPath*)fromIndexPath toIndexPath:(NSIndexPath*)toIndexPath {
	int fromIndex = ActualIndex(fromIndexPath);
	int toIndex = ActualIndex(toIndexPath);
	GPModalTableViewObject* fromObject = [ActualObjectAtIndex(fromIndex) retain];
	GPModalTableViewObject* toObject = ActualObjectAtIndex(toIndex);
	[entries removeObjectAtIndex:fromIndex];
	[entries insertObject:fromObject atIndex:toIndex];
	[fromObject release];
	ForwardMessage(GPTVAMessage_MovedItem, fromObject->identifier, toObject->identifier);
}
-(void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		int index = ActualIndex(indexPath);
		ForwardMessage(GPTVAMessage_Deleted, ActualObjectAtIndex(index)->identifier);
		[entries removeObjectAtIndex:index];
		[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationLeft];
	}
}
-(BOOL)tableView:(UITableView*)tableView canMoveRowAtIndexPath:(NSIndexPath*)indexPath {
	return ActualObject(indexPath)->reorder;
}

#pragma mark -
#pragma mark UITableViewDelegate

-(CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
	[self tableView:tableView cellForRowAtIndexPath:indexPath];
	return 1 + lastRowHeight;
}
-(NSIndexPath*)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath*)indexPath {
	[self endEditing];
	return ActualObject(indexPath)->noselect ? nil : indexPath;
}
-(void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
	ForwardMessage(GPTVAMessage_Selected, ActualObject(indexPath)->identifier);
	/*
	static NSString* fn = @"Untitled2";
	fn = (fn == @"Untitled2") ? @"Untitled1" : @"Untitled2";
	[rootCtrler pushDictionary:[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:fn ofType:@"plist"]]];
	 */
}

-(UITableViewCellEditingStyle)tableView:(UITableView*)tableView editingStyleForRowAtIndexPath:(NSIndexPath*)indexPath {
	return ActualObject(indexPath)->candelete ? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleNone;
}
-(void)tableView:(UITableView*)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath*)indexPath {
	ForwardMessage(GPTVAMessage_AccessoryTouched, ActualObject(indexPath)->identifier);
}

#pragma mark -
#pragma mark UITextFieldDelegate & UITextViewDelegate

-(BOOL)textViewShouldBeginEditing:(UITextView*)textView {
	UIBarButtonItem* doneButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(endEditing)];
	self.navigationItem.rightBarButtonItem = doneButtonItem;
	[doneButtonItem release];
	activeTextView = textView;
	
	UITableView* table = self.tableView;
	table.scrollEnabled = NO;
	[table deselectRowAtIndexPath:[table indexPathForSelectedRow] animated:NO];
	CGRect cellFrame = textView.superview.superview.superview.frame;
	UIInterfaceOrientation curOrientation = self.interfaceOrientation;
	CGFloat keyboardHeight = ((curOrientation == UIInterfaceOrientationLandscapeLeft || curOrientation == UIInterfaceOrientationLandscapeRight) ? 160 : 240);
	CGFloat maximumY = table.contentSize.height - keyboardHeight + MIN(cellFrame.size.height, keyboardHeight);
	if (cellFrame.origin.y > maximumY)
		cellFrame.origin.y = maximumY;
	
	[table setContentOffset:cellFrame.origin animated:YES];
	return YES;
}
-(BOOL)textFieldShouldBeginEditing:(UITextField*)textField { return [self textViewShouldBeginEditing:(UITextView*)textField]; }

#pragma mark -
#pragma mark ABPeoplePickerNavigationControllerDelegate

-(void)appendABValue:(CFTypeRef)value {
	CFStringRef currentString = (CFStringRef)(activeABObject->html ? [activeTextView contentAsHTMLString] : activeTextView.text);
	CFStringRef finalString;
	if (currentString == NULL || CFStringGetLength(currentString) == 0)
		finalString = CFCopyDescription(value);
	else
		finalString = CFStringCreateWithFormat(NULL, NULL, CFSTR("%@, %@"), currentString, value);
	objc_msgSend(activeTextView, activeABObject->html ? @selector(setContentToHTMLString:) : @selector(setText:), finalString);
	[self endEditing];
	CFRelease(finalString);
}

-(BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController*)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person {
	CFTypeRef value = ABRecordCopyValue(person, activeABObject->addressbook);
	if (value == NULL)
		return NO;
	if ((ABPersonGetTypeOfProperty(activeABObject->addressbook) & kABMultiValueMask) && ABMultiValueGetCount(value) == 1) {
		ABMultiValueRef multivalue = value;
		value = ABMultiValueCopyValueAtIndex(multivalue, 0);
		CFRelease(multivalue);
	} else {
		CFRelease(value);
		return YES;
	}
	
	[self appendABValue:value];
	CFRelease(value);
	[peoplePicker dismissModalViewControllerAnimated:YES];
	
	return NO;
}
-(BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController*)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)mvidentifier {
	CFTypeRef value = ABRecordCopyValue(person, property);
	if (ABPersonGetTypeOfProperty(property) & kABMultiValueMask) {
		ABMultiValueRef multivalue = value;
		value = ABMultiValueCopyValueAtIndex(multivalue, ABMultiValueGetIndexForIdentifier(multivalue, mvidentifier));
		CFRelease(multivalue);
	}
	[self appendABValue:value];
	CFRelease(value);
	[peoplePicker dismissModalViewControllerAnimated:YES];
	
	return NO;	
}
-(void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController*)peoplePicker {
	[peoplePicker dismissModalViewControllerAnimated:YES];
}

@end
