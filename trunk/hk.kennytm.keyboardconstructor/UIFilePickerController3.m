

#import "UIFilePickerController3.h"
#import <unistd.h>

@interface UITableView ()
-(NSArray*)indexPathsForSelectedRows;
@end


__attribute__((visibility("hidden")))
@interface UI3FPTableController : UITableViewController<UIAlertViewDelegate> {
	NSString* path;
	NSArray* files;
	NSArray* isdir;
	UI3FilePickerPurpose purpose;
	UISearchBar* headerView;
}
-(void)scrollTo:(NSString*)fn;
@end

@interface UI3FilePickerController ()
-(void)doneSelecting:(id)res;
-(void)setCommonItems:(UI3FPTableController*)tbl;
@property(readonly) UITextField* sharedTextField;
@end

@implementation UI3FPTableController
-(id)initWithPath:(NSString*)path_ purpose:(UI3FilePickerPurpose)purpose_ {
	if ((self = [super initWithStyle:UITableViewStylePlain])) {
		path = [path_ retain];
		purpose = purpose_;
		
		NSFileManager* fman = [NSFileManager defaultManager];
		NSString* oldPath = [fman currentDirectoryPath];
		[fman changeCurrentDirectoryPath:path_];
		files = [[[fman contentsOfDirectoryAtPath:path_ error:NULL] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] retain];
		
		NSMutableArray* finalisdir = [NSMutableArray array];
		for (NSString* filename in files) {
			BOOL is_dir;
			[fman fileExistsAtPath:filename isDirectory:&is_dir];
			[finalisdir addObject:(NSNumber*)(is_dir ? kCFBooleanTrue : kCFBooleanFalse)];
		}
		isdir = [finalisdir copy];
		[fman changeCurrentDirectoryPath:oldPath];
		
		UITableView* myTableView = self.tableView;
		if (purpose == UI3FilePickerPurposeOpenMultiple) {
			myTableView.editing = YES;
			myTableView.allowsSelectionDuringEditing = YES;
		}
		
		UINavigationItem* navItem = self.navigationItem;
		self.title = navItem.prompt = [path_ lastPathComponent];
	}
	return self;
}
-(void)dealloc {
	[path release];
	[files release];
	[isdir release];
	[super dealloc];
}
-(NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
	return [files count];
}
-(UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
	NSInteger row = indexPath.row;
	BOOL file_isdir = [isdir objectAtIndex:row] == (NSNumber*)kCFBooleanTrue;
	NSString* filename = [files objectAtIndex:row];
	
	NSString* iden = file_isdir ? @"folder.png" : @"file.png";
	
	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:iden];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:iden] autorelease];
		cell.imageView.image = [UIImage imageNamed:iden];
		if (file_isdir)
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	UILabel* txtLbl = cell.textLabel;
	txtLbl.text = filename;
	txtLbl.lineBreakMode = UILineBreakModeMiddleTruncation;
	
	return cell;
}
-(void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
	NSInteger row = indexPath.row;
	UI3FilePickerController* navCtrler = (UI3FilePickerController*)self.navigationController;
	if ([isdir objectAtIndex:row] == (NSNumber*)kCFBooleanTrue) {
		UI3FPTableController* tbl = [[UI3FPTableController alloc] initWithPath:[path stringByAppendingPathComponent:[files objectAtIndex:row]] purpose:purpose];
		[navCtrler setCommonItems:tbl];
		[navCtrler pushViewController:tbl animated:YES];
		[tbl release];
	} else if (purpose == UI3FilePickerPurposeOpen)
		[navCtrler doneSelecting:[path stringByAppendingPathComponent:[files objectAtIndex:row]]];
	else if (purpose == UI3FilePickerPurposeSave)
		navCtrler.sharedTextField.text = [files objectAtIndex:row];
}
-(UITableViewCellEditingStyle)tableView:(UITableView*)tableView editingStyleForRowAtIndexPath:(NSIndexPath*)indexPath {
	if (purpose == UI3FilePickerPurposeOpenMultiple && [isdir objectAtIndex:indexPath.row] != (NSNumber*)kCFBooleanTrue)
		return 3;
	else
		return 0;
}
-(void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	UITextField* sharedTextField = ((UI3FilePickerController*)self.navigationController).sharedTextField;
	[sharedTextField removeFromSuperview];
	CGRect rect = CGRectMake(0, 0, self.tableView.bounds.size.width-128, 24);
	UIView* titleView = [[UIView alloc] initWithFrame:rect];
	sharedTextField.frame = rect;
	titleView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	titleView.autoresizesSubviews = YES;
	[titleView addSubview:sharedTextField];
	self.navigationItem.titleView = titleView;
	[titleView release];
}
-(void)sendDoneMessage {
	UITableView* view = self.tableView;
	id res;
	switch (purpose) {
		default:
			res = [NSMutableArray array];
			for (NSIndexPath* indexPath in [view indexPathsForSelectedRows])
				[res addObject:[path stringByAppendingPathComponent:[files objectAtIndex:indexPath.row]]];
			if ([res count] == 0)
				res = nil;
			break;
			
		case UI3FilePickerPurposeChooseFolder:
			res = path;
			break;
			
		case UI3FilePickerPurposeSave:
			res = ((UI3FilePickerController*)self.navigationController).sharedTextField.text;
			if ([res length] == 0)
				res = nil;
			else if ([files containsObject:res]) {
				UIAlertView* overrideAlert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Override “%@”?", nil), res]
																		message:nil
																	   delegate:self
															  cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
															  otherButtonTitles:NSLocalizedString(@"Override", nil), nil];
				[overrideAlert show];
				[overrideAlert release];
				res = nil;
			}
			if (res != nil)
				res = [path stringByAppendingPathComponent:res];
			break;
	}
	if (res != nil)
		[(UI3FilePickerController*)self.navigationController doneSelecting:res];
}
-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation { return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown; }

static CFComparisonResult CaseInsensitiveComparator(NSString* a, NSString* b, void* context) { return (NSComparisonResult)[a caseInsensitiveCompare:b]; }
-(void)scrollTo:(NSString*)fn {
	NSInteger cnt = [files count];
	CFIndex index = CFArrayBSearchValues((CFArrayRef)files, CFRangeMake(0, cnt), fn, (CFComparatorFunction)&CaseInsensitiveComparator, NULL);
	if (index == cnt)
		-- index;
	[self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

-(void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)index {
	if (index == 1)
		[(UI3FilePickerController*)self.navigationController doneSelecting:[path stringByAppendingPathComponent:((UI3FilePickerController*)self.navigationController).sharedTextField.text]];
}
@end



@implementation UI3FilePickerController
@synthesize sharedTextField;
-(void)setCommonItems:(UI3FPTableController*)tbl {
	tbl.toolbarItems = sharedToolbarItems;
	if (purpose != UI3FilePickerPurposeOpen) {
		UIBarButtonItem* item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:(purpose == UI3FilePickerPurposeSave ? UIBarButtonSystemItemSave : UIBarButtonSystemItemDone)
																			  target:tbl action:@selector(sendDoneMessage)];
		tbl.navigationItem.rightBarButtonItem = item;
		[item release];
	}
}

-(void)switchToPath:(NSString*)rootPath animated:(BOOL)animated {
	NSMutableArray* controllers = [NSMutableArray array];
	NSString* curPath = @"";
	for (NSString* comp in [[rootPath stringByStandardizingPath] pathComponents]) {
		curPath = [curPath stringByAppendingPathComponent:comp];
		UI3FPTableController* tbl = [[UI3FPTableController alloc] initWithPath:curPath purpose:purpose];
		[self setCommonItems:tbl];
		[controllers addObject:tbl];
		[tbl release];
	}
	[self setViewControllers:controllers animated:animated];
}

-(void)cancel { [self dismissModalViewControllerAnimated:YES]; }
-(void)popUntilRoot { [self popToRootViewControllerAnimated:YES]; }
-(void)moveToHome { [self switchToPath:NSHomeDirectory() animated:YES]; }
-(NSArray*)sharedToolbarItems { return sharedToolbarItems; }
-(void)doneSelecting:(id)res {
	[target performSelector:sel withObject:res];
	[self cancel];
}

-(id)initWithPath:(NSString*)rootPath purpose:(UI3FilePickerPurpose)purpose_ {
	if ((self = [super init])) {
		self.toolbarHidden = NO;
		purpose = purpose_;
		
		sharedTextField = [UITextField new];
		sharedTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
		sharedTextField.autocorrectionType = UITextAutocorrectionTypeNo;
		sharedTextField.placeholder = NSLocalizedString(@"File name", nil);
		sharedTextField.borderStyle = UITextBorderStyleRoundedRect;
		sharedTextField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		sharedTextField.returnKeyType = UIReturnKeyGo;
		sharedTextField.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
		sharedTextField.delegate = self;
		
		UIBarButtonItem* cancelBtn = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(cancel)];
		UIBarButtonItem* rootBtn = [[UIBarButtonItem alloc] initWithTitle:@"/" style:UIBarButtonItemStyleBordered target:self action:@selector(popUntilRoot)];
		UIBarButtonItem* homeBtn = [[UIBarButtonItem alloc] initWithTitle:@"~" style:UIBarButtonItemStyleBordered target:self action:@selector(moveToHome)];
		UIBarButtonItem* flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL];
		sharedToolbarItems = [[NSArray alloc] initWithObjects:cancelBtn, flexibleSpace, rootBtn, homeBtn, nil];
		[cancelBtn release];
		[rootBtn release];
		[homeBtn release];
		[flexibleSpace release];
		
		[self switchToPath:rootPath animated:NO];
	}
	return self;
}
-(void)dealloc {
	[sharedToolbarItems release];
	[sharedTextField release];
	[super dealloc];
}
-(void)onFinishTellTarget:(id)target_ selector:(SEL)sel_ {
	target = target_;
	sel = sel_;
}

-(BOOL)textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string {
	[(UI3FPTableController*)self.topViewController scrollTo:[textField.text stringByReplacingCharactersInRange:range withString:string]];
	return YES;
}

-(BOOL)textFieldShouldReturn:(UITextField*)textField {
	[textField resignFirstResponder];
	return YES;
}

@end