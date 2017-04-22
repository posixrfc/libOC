//
//  SatisfactionDatePicker.h
//  ilearning
//
//  Created by coderf on 17/4/21.
//  Copyright © 2017年 华为技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>

//日期选择视图
@interface iClassDatePickerView : UIView <UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate>
{
@protected
    UITableView *_tableView;//滚动控件
    UIView *_blurView;//遮罩层
    NSCalendar *_cldr;//日历
    NSDate *_crtdt;//日期
    NSInteger _selectedIndex;//选择的行
    NSInteger _currentIndex;//当前的行
    CAGradientLayer *_layer0;//渐变
    CAGradientLayer *_layer1;//渐变
@public
    __strong void (^_selectDateAction)(NSDateComponents *);//事件回调
}
@end
