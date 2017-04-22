//
//  UIImage+CYExtra.h
//  GTW
//
//  Created by fQQ1770750695 on 15/3/27.
//  Copyright (c) 2015年 xcode. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Ext)

#define UIImageLINK(v) #v
#define UIImageGET(v) [UIImage imageWithPath:UIImageLINK(v)]
+ (UIImage *)imageWithPath:(const char *)path;

+ (UIImage *)resizableImageWithImageName:(NSString *)imageName;

@end
