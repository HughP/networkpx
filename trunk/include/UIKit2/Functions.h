/*
 #import <UIKit/UIImage.h>
#import <Foundation/NSString.h>
#import <Foundation/NSBundle.h>
 */

#import <objc/objc.h>

@class UIImage, NSString, NSBundle;

UIImage* _UIImageWithName(NSString* name);
void UIKeyboardClearKeyCentroids();
NSString* UIKeyboardGetCurrentInputMode();
void UIKeyboardSetCurrentInputMode(NSString* mode);
NSBundle* UIKeyboardBundleForInputMode(NSString* mode);
NSString* UIKeyboardLocalizedInputModeName(NSString* mode);
Class UIKeyboardLayoutClassForInputModeInOrientation(NSString* inputMode, NSString* orientationString);
NSString* UIKeyboardLocalizedString (NSString* objID, NSString* locale, NSBundle* bundle);
BOOL UIKeyboardLayoutDefaultTypeForInputModeIsASCIICapable(NSString* mode);
BOOL UIKeyboardRequiresInternationalKey();