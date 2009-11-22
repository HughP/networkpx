/*

main.m ... SQLite3 Viewer ... Minimalistic SQLite client.
Copyright (C) 2009  KennyTM~ <kennytm@gmail.com>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

#import <UIKit/UIKit.h>
#include <sqlite3.h>

@interface UISearchBar ()
-(void)setUsesEmbeddedAppearance:(BOOL)embedded;
@end


static void alert(NSString* err) {
	UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Error" message:err delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alert show];
	[alert release];
}

static void alert_sqlite3(NSString* prefix, sqlite3* db, int code) {
	alert([NSString stringWithFormat:@"%@: %s (%d)", prefix, sqlite3_errmsg(db), code]);
}

static NSString* createEscapeHTML(const char* s) {
	if (s == NULL)
		return [@"<span style='color:gray;'>(nil)</span>" retain];
	
	NSMutableString* res = [[NSMutableString alloc] initWithUTF8String:s];
	[res replaceOccurrencesOfString:@"&" withString:@"&amp;" options:0 range:NSMakeRange(0, [res length])];
	[res replaceOccurrencesOfString:@"<" withString:@"&lt;" options:0 range:NSMakeRange(0, [res length])];
	return res;
}

@interface SQLite3SQLView : UIViewController<UISearchBarDelegate> {
	sqlite3* db;
	UITextView* sqlTextView;
	UISearchBar* searchBar;
	UIWebView* resView;
}
@end
@implementation SQLite3SQLView
-(id)initWithDB:(sqlite3*)db_ {
	if ((self = [super init])) {
		db = db_;
		self.title = @"SQL";
	}
	return self;
}

-(void)loadView {
	UIView* view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
	view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	view.autoresizesSubviews = YES;
	
	static const CGFloat sbH = 44; 
	searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 100, sbH)];
	searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
	searchBar.delegate = self;
	searchBar.placeholder = @"SQL statement";
	searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
	searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
	[searchBar setUsesEmbeddedAppearance:YES];
	[view addSubview:searchBar];
	[searchBar release];
	
	resView = [[UIWebView alloc] initWithFrame:CGRectMake(0, sbH, 100, 100-sbH)];
	resView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	resView.dataDetectorTypes = UIDataDetectorTypeNone;
	[view addSubview:resView];
	[resView release];
	
	self.view = view;
	[view release];
}
-(void)focus {
	[searchBar becomeFirstResponder];
}

-(void)runSQL:(const char*)sql {
	[searchBar resignFirstResponder];
	searchBar.text = [NSString stringWithUTF8String:sql];
	
	sqlite3_stmt* stmt;
	int errcode = sqlite3_prepare_v2(db, sql, -1, &stmt, NULL);
	int colcount = -1, rowcount = 0;
	if (errcode != SQLITE_OK)
		alert_sqlite3(@"Fail to prepare SQL statement", db, errcode);
	else {
		NSMutableString* tableContent = [[NSMutableString alloc] initWithString:@"<table><thead><tr>"];
		while (1) {
			errcode = sqlite3_step(stmt);
			if (errcode == SQLITE_DONE)
				break;
			else if (errcode == SQLITE_ROW) {
				int i;
				if (colcount < 0) {
					colcount = sqlite3_column_count(stmt);
					for (i = 0; i < colcount; ++ i) {
						NSString* s = createEscapeHTML(sqlite3_column_name(stmt, i));
						[tableContent appendString:@"<th>"];
						[tableContent appendString:s];
						[tableContent appendString:@"</th>"];
						[s release];
					}
					[tableContent appendString:@"</tr></thead><tbody>"];
				}
				[tableContent appendString:@"<tr>"];
				for (int i = 0; i < colcount; ++ i) {
					NSString* s = createEscapeHTML((const char*)sqlite3_column_text(stmt, i));
					[tableContent appendString:@"<td>"];
					[tableContent appendString:s];
					[tableContent appendString:@"</td>"];
					[s release];
				}
				[tableContent appendString:@"</tr>"];
				++ rowcount;
			} else {
				alert_sqlite3(@"Fail to fetch SQL result", db, errcode);
				break;
			}
		}
		[tableContent appendFormat:@"</tbody></table>"];
		
		[resView loadHTMLString:[NSString stringWithFormat:
								 @"<html><head>"
								 @"<style>th,td{white-space:pre;border:1px solid gray;}"
								 @"table{border-collapse:collapse;}</style></head>"
								 @"<body><p>Fetched %d row%s</p>%@</body></html>",
								 rowcount, rowcount==0?"":"s", tableContent] baseURL:nil];
	}
	sqlite3_finalize(stmt);
}

-(void)searchBarTextDidBeginEditing:(UISearchBar*)sb { [sb setShowsCancelButton:YES animated:YES]; }
-(void)searchBarTextDidEndEditing:(UISearchBar*)sb { [sb setShowsCancelButton:NO animated:YES]; }
-(void)searchBarCancelButtonClicked:(UISearchBar*)sb { [sb resignFirstResponder]; }
-(void)searchBarSearchButtonClicked:(UISearchBar*)sb { [self runSQL:[sb.text UTF8String]]; }

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

@end

#pragma mark -

@interface SQLite3TableViewController : UITableViewController {
	sqlite3* db;
	NSArray* tableNames;
}
@end
@implementation SQLite3TableViewController
-(id)initWithDB:(sqlite3*)db_ {
	if ((self = [super initWithStyle:UITableViewStylePlain])) {
		self.title = @"Tables";
		UIBarButtonItem* item = [[UIBarButtonItem alloc] initWithTitle:@"SQL" style:UIBarButtonItemStyleBordered target:self action:@selector(launchSQLView)];
		self.navigationItem.rightBarButtonItem = item;
		[item release];
		
		sqlite3_stmt* stmt;
		static const char* const sql_statement = "select name from sqlite_master where type='table' order by name;";
		int res1 = sqlite3_prepare_v2(db_, sql_statement, strlen(sql_statement)+1, &stmt, NULL);
		if (res1 != SQLITE_OK)
			alert_sqlite3(@"Fail to prepare for fetching table names", db_, res1);
		else {
			NSMutableArray* names = [[NSMutableArray alloc] init];	
			while (1) {
				res1 = sqlite3_step(stmt);
				if (res1 == SQLITE_DONE)
					break;
				else if (res1 == SQLITE_ROW) {
					const char* name = (const char*)sqlite3_column_text(stmt, 0);
					[names addObject:[NSString stringWithUTF8String:name]];
				} else {
					alert_sqlite3(@"Fail to fetch table names", db_, res1);
					break;
				}
			}
			sqlite3_finalize(stmt);
			tableNames = names;
			db = db_;
		}
	}
	return self;
}
-(void)dealloc {
	[tableNames release];
	sqlite3_close(db);
	[super dealloc];
}

-(UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"."];
	if (cell == nil)
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"."] autorelease];
	cell.textLabel.text = [tableNames objectAtIndex:indexPath.row];
	return cell;
}
-(NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section { return [tableNames count]; }
-(void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
	char* sanitizedStatement = sqlite3_mprintf("select * from %Q limit 100;", [[tableNames objectAtIndex:indexPath.row] UTF8String]);
	
	SQLite3SQLView* ctrler = [[SQLite3SQLView alloc] initWithDB:db];
	[self.navigationController pushViewController:ctrler animated:YES];
	[ctrler runSQL:sanitizedStatement];
	
	sqlite3_free(sanitizedStatement);
	[ctrler release];
}

-(void)launchSQLView {
	SQLite3SQLView* ctrler = [[SQLite3SQLView alloc] initWithDB:db];
	[self.navigationController pushViewController:ctrler animated:YES];
	[ctrler focus];
	[ctrler release];
}
-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}
@end

#pragma mark -

@interface FileChooserController : UIViewController {
	UITextField* textField;
}
@end
@implementation FileChooserController
-(void)loadView {
	UIView* view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 200)];
	view.backgroundColor = [UIColor whiteColor];
	view.autoresizesSubviews = YES;
	view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	
	textField = [[UITextField alloc] initWithFrame:CGRectMake(20, 20, 60, 30)];
	textField.borderStyle = UITextBorderStyleRoundedRect;
	textField.autocorrectionType = UITextAutocorrectionTypeNo;
	textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
	textField.keyboardType = UIKeyboardTypeURL;
	textField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
	textField.text = @"/var/mobile/Library/";
	[view addSubview:textField];
	[textField release];
	
	UIButton* button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	button.frame = CGRectMake(30, 60, 40, 30);
	button.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
	[button setTitle:@"Open" forState:UIControlStateNormal];
	[button addTarget:self action:@selector(open) forControlEvents:UIControlEventTouchUpInside];
	[view addSubview:button];
	
	self.title = @"SQLite3 Viewer";
	
	self.view = view;
	[view release];
}
-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}
-(void)openURL:(NSString*)path {
	NSFileManager* fman = [NSFileManager defaultManager];
	BOOL isDir = NO;
	if (![fman fileExistsAtPath:path isDirectory:&isDir])
		alert([NSString stringWithFormat:@"File %@ does not exist.", path]);
	else if (isDir)
		alert([path stringByAppendingString:@" is a directory."]);
	else {
		sqlite3* db;
		int error = sqlite3_open([path UTF8String], &db);
		if (error != SQLITE_OK) {
			alert_sqlite3([@"Cannot open database " stringByAppendingString:path], db, error);
			sqlite3_close(db);
		} else {
			SQLite3TableViewController* ctrler = [[SQLite3TableViewController alloc] initWithDB:db];
			[self.navigationController pushViewController:ctrler animated:YES];
			[ctrler release];
		}
	}
}
-(void)open { [self openURL:textField.text]; }
@end

#pragma mark -

@interface Del : NSObject<UIApplicationDelegate> {
	UIWindow* window;
	UINavigationController* navCtrler;
	FileChooserController* fcc;
}
@end
@implementation Del
-(void)applicationDidFinishLaunching:(UIApplication*)application {
	window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	[window makeKeyAndVisible];
//	window.autoresizesSubviews = YES;
	
	fcc = [[FileChooserController alloc] init];
	navCtrler = [[UINavigationController alloc] initWithRootViewController:fcc];
//	view.frame = [UIScreen mainScreen].applicationFrame;
	[window addSubview:navCtrler.view];
	[fcc release];
}
-(void)applicationWillTerminate:(UIApplication*)application {
	[window release];
	[navCtrler release];
}
-(BOOL)application:(UIApplication*)application handleOpenURL:(NSURL*)url {
	if (!url) return NO;
	if (![[url scheme] isEqualToString:@"sqlite3"]) return NO;
	if ([navCtrler topViewController] != fcc) return NO;
	[fcc openURL:[url path]];
	return YES;
}
@end


#pragma mark -

int main (int argc, char* argv[]) {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	int r = UIApplicationMain(argc, argv, nil, @"Del");
	[pool drain];
	return r;
}