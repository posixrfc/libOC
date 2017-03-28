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

@end
