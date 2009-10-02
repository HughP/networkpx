/*

CrashReporterDelegate ... Crash Reporter's AppDelegate.
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
#import "CrashLogsTableController.h"
#import "reporter.h"

@interface CrashReporterDelegate : NSObject<UIApplicationDelegate> {
	UIWindow* _win;
	UINavigationController* _navCtrler;
}
@end

@implementation CrashReporterDelegate
-(void)applicationDidFinishLaunching:(UIApplication*)app {
	_win = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	[_win makeKeyAndVisible];
	
	CrashLogsTableController* firstCtrler = [[CrashLogsTableController alloc] initWithStyle:UITableViewStylePlain];
	/*
	CrashLogViewController* firstCtrler = [[CrashLogViewController alloc] init];
	firstCtrler.file = @"/Users/kennytm/Downloads/Untitled2.plist";
	 */
	firstCtrler.title = [[NSBundle mainBundle] localizedStringForKey:@"Crash Reporter" value:nil table:nil];
	_navCtrler = [[UINavigationController alloc] initWithRootViewController:firstCtrler];
	[firstCtrler release];
	
	[_win addSubview:_navCtrler.view];
}
-(void)applicationWillTerminate:(UIApplication*)application {
	[_win release];
	[_navCtrler release];
}
-(void)applicationDidReceiveMemoryWarning:(UIApplication*)application {
	[ReporterLine flushReporters];
}
@end
