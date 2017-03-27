#import <UIKit/UIKit.h>

#define UICOLOR_LINK(v) 0x##v

/**
 正确用法 UICOLOR_RGB(ABCDEF) 不区分大小写,不要0x
 */
#define UICOLOR_RGB(v)  UIColorRGB(UICOLOR_LINK(v))

/**
 正确用法 UICOLOR_RGBA(ABCDEFAA) 不区分大小写,不要0x
 */
#define UICOLOR_RGBA(V) UIColorRGBA(UICOLOR_LINK(v))

/**
 正确用法 UICOLOR_HSL(ABCDEF) 不区分大小写,不要0x
 */
#define UICOLOR_HSL(V)  UIColorHSL(UICOLOR_LINK(v))

/**
 正确用法 UICOLOR_HSLA(ABCDEFAA) 不区分大小写,不要0x
 */
#define UICOLOR_HSLA(v) UIColorHSLA(UICOLOR_LINK(v))


extern UIColor *UIColorRGB(unsigned int hex_number);
extern inline UIColor *UIColorRGBA(unsigned int hex_number);
extern inline UIColor *UIColorHSL(unsigned int hex_number);
extern inline UIColor *UIColorHSLA(unsigned int hex_number);


@interface UIColor (Ext)

+ (UIColor *)colorWithHex:(NSString *)hexColor DEPRECATED_MSG_ATTRIBUTE("Use +il_colorWithHexadecimalValue: instead");

@end
