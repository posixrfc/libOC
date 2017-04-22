//
//  SatisfactionDatePicker.m
//  ilearning
//
//  Created by coderf on 17/4/21.
//  Copyright © 2017年 华为技术有限公司. All rights reserved.
//

#import "iClassDatePickerView.h"

@implementation iClassDatePickerView
//初始化方法
- (instancetype)init
{
    return [self initWithFrame:CGRectZero];
}
//初始化方法
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (nil == self) {
        return nil;
    }
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, frame.size.height, frame.size.width) style:UITableViewStylePlain];
    _tableView.transform = CGAffineTransformRotate(_tableView.transform, -M_PI_2);
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.backgroundColor = [UIColor whiteColor];
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.showsVerticalScrollIndicator = NO;
    [self addSubview:_tableView];
    
    _blurView = [[UIView alloc] initWithFrame:self.bounds];
    _blurView.backgroundColor = [UIColor clearColor];
    _blurView.userInteractionEnabled = NO;
    _layer0 = [CAGradientLayer layer];
    [_blurView.layer addSublayer:_layer0];
    _layer1 = [CAGradientLayer layer];
    [_blurView.layer addSublayer:_layer1];
    [self addSubview:_blurView];
    
    _selectedIndex = _currentIndex = 512;
    _cldr = [NSCalendar currentCalendar];
    _crtdt = [NSDate date];
    return self;
}
//设置各控件位置尺寸
- (void)layoutSubviews
{
    [super layoutSubviews];
    [_blurView setFrame:self.bounds];
    CGRect rct = _blurView.bounds;
    rct.size.width /= 3;
    _layer0.frame = rct;
    _layer0.colors = @[(id)[[[UIColor whiteColor] colorWithAlphaComponent:.7f] CGColor], (id)[[[UIColor whiteColor] colorWithAlphaComponent:0.f] CGColor]];
    _layer0.locations = @[@(0.5f)];
    _layer0.startPoint = CGPointMake(0, 0.5);
    _layer0.endPoint = CGPointMake(1.f, 0.5);
    
    rct.origin.x = rct.size.width + rct.size.width;
    _layer1.frame = rct;
    _layer1.colors = @[(id)[[[UIColor whiteColor] colorWithAlphaComponent:.7f] CGColor], (id)[[[UIColor whiteColor] colorWithAlphaComponent:0.f] CGColor]];
    _layer1.locations = @[@(0.5f)];
    _layer1.startPoint = CGPointMake(1.f, 0.5);
    _layer1.endPoint = CGPointMake(0, 0.5);
    
    _tableView.transform = CGAffineTransformIdentity;
    CGSize size = self.size;
    _tableView.rowHeight = size.height;
    _tableView.frame = CGRectMake(0, 0, size.height, size.width);
    _tableView.center = _blurView.center;
    _tableView.transform = CGAffineTransformRotate(_tableView.transform, -M_PI_2);
    NSIndexPath *indexpath = [NSIndexPath indexPathForRow:_selectedIndex inSection:0];
    [_tableView selectRowAtIndexPath:indexpath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
    [self tableView:_tableView didSelectRowAtIndexPath:indexpath];
}
//获取组数
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}
//获取每组行数
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1024;
}
//获取每行显示图
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NSString"];
    if (nil == cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"NSString"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        CGSize size = CGSizeMake(6.5, tableView.rowHeight);
        CGFloat tmp = size.height - size.width - size.width;
        UILabel *introLab = [[UILabel alloc] initWithFrame:CGRectMake(size.width, size.width, tmp, tmp)];
        introLab.tag = NSNotFound;
        introLab.numberOfLines = 2;
        [[cell contentView] addSubview:introLab];
        introLab.textAlignment = NSTextAlignmentCenter;
        introLab.layer.cornerRadius = tmp / 2;
        introLab.layer.masksToBounds = YES;
        introLab.layer.backgroundColor = [[UIColor clearColor] CGColor];
        
        introLab.textColor = UICOLOR_RGB(333333);
        introLab.font = [UIFont systemFontOfSize:14];
        
        introLab.textColor = UICOLOR_RGB(333333);
        introLab.font = [UIFont systemFontOfSize:10];
        introLab.transform = CGAffineTransformRotate(CGAffineTransformIdentity, M_PI_2);
    }
    UILabel *introLab = [[cell contentView] viewWithTag:NSNotFound];
    NSDate *date = [_crtdt dateByAddingTimeInterval:(indexPath.row - _currentIndex) * 86400];
    NSDateComponents *cmps = [_cldr components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear | NSCalendarUnitWeekday fromDate:date];
    NSString *weekString = nil;
    switch (_cldr.firstWeekday)
    {
        case 1:
            weekString = [[_cldr shortWeekdaySymbols] objectAtIndex:cmps.weekday - 1];
            break;
            
        case 2:
            weekString = [[_cldr shortWeekdaySymbols] objectAtIndex:cmps.weekday == 7 ? 0 : cmps.weekday];
            break;
            
        case 7:
            weekString = [[_cldr shortWeekdaySymbols] objectAtIndex:cmps.weekday > 6 ? cmps.weekday - 6 : cmps.weekday];
            break;
            
        default:
            throwExecption;
    }
    NSString *dayString = [NSString stringWithFormat:@"%zd", cmps.day];
    NSInteger weekLen = weekString.length, dayLen = dayString.length;
    NSString *titleString = [[dayString stringByAppendingString:@"\n"] stringByAppendingString:weekString];
    NSMutableAttributedString *mas = [[NSMutableAttributedString alloc] initWithString:titleString];
    [mas addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:14] range:NSMakeRange(0, dayLen)];
    [mas addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:10] range:NSMakeRange(dayLen + 1, weekLen)];
    if (indexPath.row == _selectedIndex)
    {
        introLab.layer.backgroundColor = [UICOLOR_RGB(FF4C4C) CGColor];
        [mas addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0, titleString.length)];
    }
    else
    {
        introLab.layer.backgroundColor = [[UIColor clearColor] CGColor];
        [mas addAttribute:NSForegroundColorAttributeName value:UICOLOR_RGB(333333) range:NSMakeRange(0, titleString.length)];
    }
    introLab.attributedText = mas;
    return cell;
}
//选择一行
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == _selectedIndex) {
        return;
    }
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    UILabel *introLab = [[cell contentView] viewWithTag:NSNotFound];
    introLab.layer.backgroundColor = [UICOLOR_RGB(FF4C4C) CGColor];
    NSMutableAttributedString *mas = [[NSMutableAttributedString alloc] initWithAttributedString:introLab.attributedText];
    [mas addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0, mas.length)];
    introLab.attributedText = mas;
    _selectedIndex = indexPath.row;
    [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    if (nil == _selectDateAction) {
        return;
    }
    NSDate *date = [_crtdt dateByAddingTimeInterval:(_selectedIndex - _currentIndex) * 86400];
    NSDateComponents *cmps = [_cldr components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear | NSCalendarUnitWeekday fromDate:date];
    _selectDateAction(cmps);
}
//取消选择一行
- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    UILabel *introLab = [[cell contentView] viewWithTag:NSNotFound];
    introLab.layer.backgroundColor = [[UIColor clearColor] CGColor];
    NSMutableAttributedString *mas = [[NSMutableAttributedString alloc] initWithAttributedString:introLab.attributedText];
    [mas addAttribute:NSForegroundColorAttributeName value:UICOLOR_RGB(333333) range:NSMakeRange(0, mas.length)];
    introLab.attributedText = mas;
}
@end
