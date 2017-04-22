#import <UIKit/UIKit.h>

@interface UIImage (Ext)

#define UIImageLINK(v) #v
#define UIImageGET(v) [UIImage imageWithPath:UIImageLINK(v)]
+ (UIImage *)imageWithPath:(const char *)path;

+ (UIImage *)resizableImageWithImageName:(NSString *)imageName;

@end
