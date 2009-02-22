#import <UIKit/UIView.h>

// Technically these should go to WebCore instead of UIKit. But for simplicity let's put it here.
@interface WebView
-(NSDictionary*)elementAtPoint:(CGPoint)pt;
@end

@interface UIWebDocumentView : UIView
-(WebView*)webView;
@end