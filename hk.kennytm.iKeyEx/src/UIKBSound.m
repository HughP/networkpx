#import <iKeyEx/UIKBSound.h>
#import <UIKit/UIButton.h>

@interface UIHardware : NSObject
+(void)_playSystemSound:(unsigned long)soundID;
@end

@implementation UIKBSound
+(void)play {
	// TODO: Make this portable.
	[UIHardware _playSystemSound:1103];
}
+(void)registerButton:(UIButton*)btn {
	[btn addTarget:[UIKBSound class] action:@selector(play) forControlEvents:UIControlEventTouchDown];
}
@end
