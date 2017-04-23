#import "UIImage+Ext.h"

@implementation UIImage (Ext)

+ (UIImage *)imageWithPath:(const char *)path
{
    if (NULL == path) {
        return nil;
    }
    if (0 == strlen(path)) {
        return nil;
    }
    NSString *const ocPath = [NSString stringWithUTF8String:path];
    if ([ocPath hasPrefix:@"/"]) {
        return [[UIImage alloc] initWithContentsOfFile:ocPath];
    }
    const NSInteger pathLen = ocPath.length;
    NSString *fileTail = nil;
    NSString *realPath = nil;
    if (3 < pathLen)
    {
        fileTail = [[ocPath substringFromIndex:pathLen - 4] lowercaseString];
        if ([fileTail isEqual:@".png"] || [fileTail isEqual:@".jpg"] || [fileTail isEqual:@".gif"])
        {
            realPath = ocPath;
        }
        else if ([fileTail isEqual:@"jpeg"] || [fileTail isEqual:@"tiff"])
        {
            realPath = ocPath;
        }
    }
    NSBundle *const bundle = [NSBundle mainBundle];
    if (nil != realPath)
    {
        NSString *imgPath = [bundle pathForResource:[ocPath substringToIndex:pathLen - 4] ofType:[ocPath substringFromIndex:pathLen - 4]];
        return [[UIImage alloc] initWithContentsOfFile:imgPath];
    }
    NSString *screenScale = [NSString stringWithFormat:@"%1.f", [[UIScreen mainScreen] scale]];
    realPath = [NSString stringWithFormat:@"%@@%@x", ocPath, screenScale];
    NSArray<NSString *> *const fileExts = @[@"png", @"PNG", @"jpg", @"JPG", @"gif", @"GIF", @"bmp", @"BMP", @"jpeg", @"JPEG", @"tiff", @"TIFF"];
    for (NSInteger i = 0, cnt = fileExts.count; i < cnt; i++)
    {
        NSString *imgPath = [bundle pathForResource:realPath ofType:[fileExts objectAtIndex:i]];
        if (nil != imgPath) {
            return [[UIImage alloc] initWithContentsOfFile:imgPath];
        }
    }
    screenScale = [screenScale isEqual:@"2"] ? @"3" : @"2";
    realPath = [NSString stringWithFormat:@"%@@%@x", ocPath, screenScale];
    for (NSInteger i = 0, cnt = fileExts.count; i < cnt; i++)
    {
        NSString *imgPath = [bundle pathForResource:realPath ofType:[fileExts objectAtIndex:i]];
        if (nil != imgPath) {
            return [[UIImage alloc] initWithContentsOfFile:imgPath];
        }
    }
    realPath = ocPath;
    for (NSInteger i = 0, cnt = fileExts.count; i < cnt; i++)
    {
        NSString *imgPath = [bundle pathForResource:realPath ofType:[fileExts objectAtIndex:i]];
        if (nil != imgPath) {
            return [[UIImage alloc] initWithContentsOfFile:imgPath];
        }
    }
    return [[UIImage alloc] initWithContentsOfFile:[bundle pathForResource:ocPath ofType:nil]];
}

+ (UIImage *)resizableImageNamed:(const char *)path;
{
    UIImage *img = [UIImage imageWithPath:path];
	if (nil == img) {
		return nil;
	}
    const CGSize imgSize = CGSizeMake(img.size.width * .5 - .5, img.size.height * .5 - .5);
	UIEdgeInsets edge = UIEdgeInsetsMake(imgSize.height, imgSize.width, imgSize.height, imgSize.width);
    return [img resizableImageWithCapInsets:edge resizingMode:UIImageResizingModeTile];
}
+ (UIImage *)imageWithSize:(CGSize)size fillColor:(UIColor *)color
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