#import <Foundation/NSObject.h>

@class UIButton;

@interface UIKBSound : NSObject {}
+(void)play;
+(void)registerButton:(UIButton*)btn;
@end
