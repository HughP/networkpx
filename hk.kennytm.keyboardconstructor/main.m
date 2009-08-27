//
//  main.m
//  hk.kennytm.keyboardconstructor
//
//  Created by KennyTM~ on Aug 26, 09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Preferences/Preferences.h>
#import <UIKit/UIKit2.h>

@interface ProjectChooser : PSListController
{
}
@end
@implementation ProjectChooser
-(NSArray*)specifiers {
	if (self->_specifiers == nil) {
		self->_specifiers = [[NSArray arrayWithObjects:
							  [PSSpecifier emptyGroupSpecifier],
							  [PSSpecifier preferenceSpecifierNamed:@"me" target:nil set:NULL get:NULL detail:Nil cell:PSEditTextCell edit:Nil],
							  nil] retain];
	}
	return self->_specifiers;
}
@end



#pragma mark -
//------------------------------------------------------------------------------------------------------------------------------------------

@interface RootCtrler : PSRootController
@end
@implementation RootCtrler
-(void)setupRootListForSize:(CGSize)size {
	PSSpecifier* spec = [PSSpecifier emptyGroupSpecifier];
	spec.name = @"Keyboard constructor";
	
	ProjectChooser* chooser = [[ProjectChooser alloc] initForContentSize:size];
	chooser.rootController = self;
	chooser.parentController = self;
	[spec setTarget:chooser];
	[chooser viewWillBecomeVisible:spec];
	
	[self pushController:chooser];
	[chooser release];
}
@end




@interface KCAppDel : NSObject<UIApplicationDelegate> {
	RootCtrler* ctrler;
	UIWindow* window;
}
@end
@implementation KCAppDel
-(void)changeOrientation {
	UIInterfaceOrientation orientation = [UIDevice currentDevice].orientation;
	[[UIApplication sharedApplication] setStatusBarOrientation:orientation animated:YES];
	[window _updateToInterfaceOrientation:orientation duration:1 force:YES];
}
-(void)applicationDidFinishLaunching:(UIApplication*)app {
	window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
	ctrler = [[RootCtrler alloc] initWithTitle:@"1" identifier:@"hk.kennytm.keyboardconstructor"];
	[window addSubview:[ctrler contentView]];
	[window makeKeyAndVisible];
	NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
	[center addObserver:self selector:@selector(changeOrientation) name:@"UIApplicationOrientationDidChangeNotification" object:nil];
}
-(void)applicationWillTerminate:(UIApplication*)app {
	[window release];
	[ctrler release];
}
@end

#pragma mark -
//------------------------------------------------------------------------------------------------------------------------------------------

int main (int argc, const char* argv[]) {
	NSAutoreleasePool* pool = [NSAutoreleasePool new];
	int r = UIApplicationMain(argc, argv, nil, @"KCAppDel");
	[pool drain];
	return r;
}