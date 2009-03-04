#import <WebCore/PublicDOMInterfaces.h>
#import <CoreGraphics/CGGeometry.h>

@class UIView;

@interface DOMNode (UIWebViewAdditions)
- (CGRect)boundingBoxAtPoint:(CGPoint)pt;
- (CGRect)convertRect:(CGRect)rect toView:(UIView*)view;
@end