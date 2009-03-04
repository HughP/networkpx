#import <Foundation/NSObject.h>
#import <UIKit/UITextInputTraits.h>

@class UIColor;

@protocol UITextInputTraits_Private <NSObject, UITextInputTraits>
- (void)takeTraitsFrom:(id)fp8;
@property(assign) BOOL acceptsEmoji;
@property(assign) BOOL contentsIsSingleValue;
@property(retain) id textSuggestionDelegate;
@property(assign) int textSelectionBehavior;
@property(assign) int textLoupeVisibility;
@property(assign) unsigned insertionPointWidth;
@property(retain) UIColor* insertionPointColor;
@property(assign) CFCharacterSetRef textTrimmingSet;
@end

