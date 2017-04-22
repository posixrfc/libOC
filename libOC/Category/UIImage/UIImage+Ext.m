//
//  UIImage+CYExtra.m
//  GTW
//
//  Created by fQQ1770750695 on 15/3/27.
//  Copyright (c) 2015年 xcode. All rights reserved.
//

#import "UIImage+Ext.h"

@implementation UIImage (Ext)

+ (UIImage *)resizableImageWithImageName:(NSString *)imageName
{
    UIImage *im = [UIImage imageNamed:imageName];
    const CGSize is = CGSizeMake(im.size.width * .5, im.size.height * .5);
    return [im resizableImageWithCapInsets:UIEdgeInsetsMake(is.height, is.width, is.height, is.width) resizingMode:UIImageResizingModeTile];
}
+ (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size
{
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}
@end
