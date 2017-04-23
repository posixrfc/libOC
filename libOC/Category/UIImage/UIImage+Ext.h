#import <UIKit/UIKit.h>

#define UIIMAGE_LINK(v) #v
@interface UIImage (Ext)

#define UIIMAGE_GET(v) [UIImage imageWithPath:UIIMAGE_LINK(v)]
+ (UIImage *)imageWithPath:(const char *)path;

#define UIIMAGE_RESIZE(v) [UIImage resizableImageNamed:UIIMAGE_LINK(v)]
+ (UIImage *)resizableImageNamed:(const char *)path;

+ (UIImage *)imageWithSize:(CGSize)size fillColor:(UIColor *)color;

@end
