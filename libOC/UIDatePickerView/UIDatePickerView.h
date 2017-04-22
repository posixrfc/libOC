#import <UIKit/UIKit.h>

@interface UIDatePickerView : UIView <UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate>
{
@protected
    UITableView *_tableView;
    UIView *_blurView;
    NSCalendar *_cldr;
    NSDate *_crtdt;
    NSInteger _selectedIndex;
    NSInteger _currentIndex;
    CAGradientLayer *_layer0;
    CAGradientLayer *_layer1;
@public
    __strong void (^_selectDateAction)(NSDateComponents *);
}
@end
