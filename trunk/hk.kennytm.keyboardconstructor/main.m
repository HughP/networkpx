//
//  main.m
//  hk.kennytm.keyboardconstructor
//
//  Created by KennyTM~ on Jul 26, 09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <UIKit/UIKit2.h>
#import "UIFilePickerController3.h"

//-------------------------------------------------------------------------------------------------------------------------------------------

@interface KeyboardChooserButton : UIButton {
	UIImage* image;
	NSString* title;
	NSString* subtitle;
}
@property(retain) UIImage* image;
@property(retain) NSString* title;
@property(retain) NSString* subtitle;
@end
@implementation KeyboardChooserButton
@synthesize image, title, subtitle;
-(void)drawRect:(CGRect)rect {
	[image drawAtPoint:CGPointMake(10, 10)];
	[[UIColor blackColor] setFill];
	[title drawAtPoint:CGPointMake(176, 18) withFont:[UIFont fontWithName:@"Verdana-Bold" size:24]];
	[[UIColor grayColor] setFill];
	[subtitle drawInRect:CGRectMake(176, 50, rect.size.width-176, rect.size.height-58) withFont:[UIFont systemFontOfSize:[UIFont systemFontSize]]];
}
@end

@interface KeyboardChooser : UIViewController {}
@end
@implementation KeyboardChooser
-(id)init {
	if ((self = [super init])) {
		self.title = @"Keyboard Constructor";
	}
	return self;
}
-(void)chosen:(id)x {
	NSLog(@"%@", x);
}
/*
-(void)omg {
	UI3FilePickerController* k = [[UI3FilePickerController alloc] initWithPath:@"/Users/kennytm/" purpose:UI3FilePickerPurposeChooseFolder];
	[k onFinishTellTarget:self selector:@selector(chosen:)];
	[self presentModalViewController:k animated:YES];
	[k release];
}
 */
-(void)loadView {
	UIView* view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
	
	view.backgroundColor = [UIColor whiteColor];
	view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	
	KeyboardChooserButton* normalButton = [[KeyboardChooserButton alloc] initWithFrame:CGRectMake(0, 0, 100, 50)];
	normalButton.tag = 1;
	normalButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
	normalButton.contentMode = UIViewContentModeRedraw;
	normalButton.image = [UIImage imageNamed:@"StandardKeyboard.png"];
	normalButton.title = @"Standard";
	normalButton.subtitle = @"Keys are distributed into rows and are equally-sized.";
	[view addSubview:normalButton];
	[normalButton release];
	
	KeyboardChooserButton* advancedButton = [[KeyboardChooserButton alloc] initWithFrame:CGRectMake(0, 50, 100, 50)];
	advancedButton.tag = 2;
	advancedButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin;
	advancedButton.contentMode = UIViewContentModeRedraw;
	advancedButton.image = [UIImage imageNamed:@"AdvancedKeyboard.png"];
	advancedButton.title = @"Advanced";
	advancedButton.subtitle = @"No restriction on the key arrangements.";
	[view addSubview:advancedButton];
	[advancedButton release];
		
	self.view = view;
	[view release];
}
-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}
@end

//-------------------------------------------------------------------------------------------------------------------------------------------

@interface AppDelegate : NSObject<UIApplicationDelegate> {
	UIWindow* window;
	UINavigationController* navCtrler;
}
@end
@implementation AppDelegate
-(void)applicationDidFinishLaunching:(UIApplication*)app {
	window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	[window makeKeyAndVisible];
	
	
	KeyboardChooser* ctrler1 = [KeyboardChooser new];	
	navCtrler = [[UINavigationController alloc] initWithRootViewController:ctrler1];
	[ctrler1 release];
	
	[window addSubview:navCtrler.view];
	
}
-(void)applicationWillTerminate:(UIApplication*)app {
	[window release];
	[navCtrler release];
}
@end

//-------------------------------------------------------------------------------------------------------------------------------------------

int main(int argc, char* argv[]) {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	int retVal = UIApplicationMain(argc, argv, nil, @"AppDelegate");
	[pool drain];
	return retVal;
}