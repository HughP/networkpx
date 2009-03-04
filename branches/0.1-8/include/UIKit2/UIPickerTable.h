#import <UIKit/UIView.h>

@interface UITableCell : UIView
@end

// DO NOT refer to the UIPickerTable class directly.
// Use objc_getClass("UIPickerTable") instead.
@protocol UIPickerTable
-(UITableCell*)selectedTableCell;
@end