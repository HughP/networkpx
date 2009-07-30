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

@interface ImageAndTitleButton : UIButton {
	UIImage* image;
	NSString* title;
	NSString* subtitle;
	CGSize imageSize;
}
@property(retain) UIImage* image;
@property(retain) NSString* title;
@property(retain) NSString* subtitle;
@end
@implementation ImageAndTitleButton
@synthesize image, title, subtitle;
-(void)setImage:(UIImage*)img {
	if (image != img) {
		[image release];
		image = [img retain];
		imageSize = img.size;
	}
}
-(void)drawRect:(CGRect)rect {
	CGFloat top = floorf((rect.size.height-imageSize.height)/2);
	[image drawAtPoint:CGPointMake(10, top)];
	[[UIColor blackColor] setFill];
	[title drawAtPoint:CGPointMake(imageSize.width+20, top+8) withFont:[UIFont fontWithName:@"Verdana-Bold" size:24]];
	[[UIColor grayColor] setFill];
	[subtitle drawInRect:CGRectMake(imageSize.width+20, top+40, rect.size.width-imageSize.width-20, rect.size.height-top-40) withFont:[UIFont systemFontOfSize:[UIFont systemFontSize]]];
}
-(void)dealloc {
	[image release];
	[title release];
	[subtitle release];
	[super dealloc];
}
@end

//-------------------------------------------------------------------------------------------------------------------------------------------

@interface KCLayout : NSObject {
	KCPlanes* planes[4];
}
@end
@implementation KCLayout
@end


@interface KCProject : NSObject<NSCoder> {
	KCLayout* layouts[6];
	NSString* filename;
}
@property(retain) NSString* filename;
+(KCProject*)emptyProjectWithFilename:(NSString*)fn;
+(KCProject*)projectWithFilename:(NSString*)fn;
-(BOOL)save;
@end
@implementation KCProject
@synthesize filename;
static NSString* const correspondingLayoutNames[] = {@"Default", @"PhonePad", @"URL", @"NamePhonePad", @"NumberPad", @"Email"};
+(KCProject*)emptyProjectWithFilename:(NSString*)fn {
	KCProject* retval = [[self new] autorelease];
	retval.filename = fn;
	return retval;
}
+(KCProject*)projectWithFilename:(NSString*)fn {
	KCProject* retval = [NSKeyedUnarchiver unarchiveObjectWithFile:fn];
	retval.filename = fn;
	return retval;
}
-(void)encodeWithCoder:(NSCoder*)encoder {
	for (unsigned i = 0; i < 6; ++ i)
		[encoder encodeObject:layouts[i] forKey:correspondingLayoutNames[i]];
}
-(id)initWithCoder:(NSCoder*)decoder {
	if ((self = [super init]))
		for (unsigned i = 0; i < 6; ++ i) {
			layouts[i] = [decoder decodeObjectForKey:correspondingLayoutNames[i]];
			if (layouts[i] == nil)
				layouts[i] = [KCLayout new];
			else
				[layouts[i] retain];
		}
	return self;
}
-(id)init { return (self = [self initWithCoder:nil]); }
-(void)dealloc {
	for (unsigned i = 0; i < 6; ++ i)
		[layouts[i] release];
	[filename release];
}
-(BOOL)save {
	return [NSKeyedArchiver archiveRootObject:self toFile:filename];
}
@end


static NSString* currentProjectPath = nil;

@interface ProjectChooser : UIViewController {}
@end
@implementation ProjectChooser
-(id)init {
	if ((self = [super init]))
		self.title = @"Keyboard Constructor";
	return self;
}
-(void)opened:(NSString*)filename {
	currentProjectPath = [filename retain];
}
-(void)newed:(NSString*)filename {
	currentProjectPath = [filename retain];
	
}

-(void)openKCProj {
	UI3FilePickerController* k = [[UI3FilePickerController alloc] initWithPath:NSHomeDirectory() purpose:UI3FilePickerPurposeOpen autoExtension:@"kcproj"];
	[k onFinishTellTarget:self selector:@selector(opened:)];
	[self presentModalViewController:k animated:YES];
	[k release];
}
-(void)newKCProj {
	UI3FilePickerController* k = [[UI3FilePickerController alloc] initWithPath:NSHomeDirectory() purpose:UI3FilePickerPurposeSave autoExtension:@"kcproj"];
	[k onFinishTellTarget:self selector:@selector(newed:)];
	[self presentModalViewController:k animated:YES];
	[k release];
}
-(void)loadView {
	UIView* view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
	
	view.backgroundColor = [UIColor whiteColor];
	view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	
	ImageAndTitleButton* openButton = [[ImageAndTitleButton alloc] initWithFrame:CGRectMake(0, 50, 100, 50)];
	openButton.tag = UI3FilePickerPurposeOpen;
	openButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin;
	openButton.contentMode = UIViewContentModeRedraw;
	openButton.image = [UIImage imageNamed:@"open.png"];
	openButton.title = @"Open";
	openButton.subtitle = @"Open and edit existing keyboard layout project.";
	[openButton addTarget:self action:@selector(openKCProj) forControlEvents:UIControlEventTouchUpInside];
	[view addSubview:openButton];
	[openButton release];
	
	ImageAndTitleButton* newButton = [[ImageAndTitleButton alloc] initWithFrame:CGRectMake(0, 0, 100, 50)];
	newButton.tag = UI3FilePickerPurposeSave;
	newButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
	newButton.contentMode = UIViewContentModeRedraw;
	newButton.image = [UIImage imageNamed:@"new.png"];
	newButton.title = @"New";
	newButton.subtitle = @"Create a new keyboard layout project.";
	[newButton addTarget:self action:@selector(newKCProj) forControlEvents:UIControlEventTouchUpInside];
	[view addSubview:newButton];
	[newButton release];
	
	self.view = view;
	[view release];
}
-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation { return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown; }
@end


//-------------------------------------------------------------------------------------------------------------------------------------------

@interface KeyboardChooser : UIViewController {}
@end
@implementation KeyboardChooser
-(id)init {
	if ((self = [super init])) {
		
	}
	return self;
}
-(void)chosen:(id)x {
	NSLog(@"%@", x);
}
-(void)loadView {
	UIView* view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
	
	view.backgroundColor = [UIColor whiteColor];
	view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	
	ImageAndTitleButton* normalButton = [[ImageAndTitleButton alloc] initWithFrame:CGRectMake(0, 0, 100, 50)];
	normalButton.tag = 1;
	normalButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
	normalButton.contentMode = UIViewContentModeRedraw;
	normalButton.image = [UIImage imageNamed:@"StandardKeyboard.png"];
	normalButton.title = @"Standard";
	normalButton.subtitle = @"Keys are distributed into rows and are equally-sized.";
	[view addSubview:normalButton];
	[normalButton release];
	
	ImageAndTitleButton* advancedButton = [[ImageAndTitleButton alloc] initWithFrame:CGRectMake(0, 50, 100, 50)];
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
	
	
	ProjectChooser* ctrler1 = [ProjectChooser new];	
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