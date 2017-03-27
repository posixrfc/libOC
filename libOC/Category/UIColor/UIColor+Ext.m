#import "UIColor+Ext.h"

struct color_field_t {
    unsigned int rh : 8;
    unsigned int gs : 8;
    unsigned int bl : 8;
    unsigned int aa : 8;
};


extern UIColor *UIColorRGB(unsigned int hex_number)
{
    return UIColorRGBA((hex_number << 8) | 0xFF);
}
extern inline UIColor *UIColorRGBA(unsigned int hex_number)
{
    struct color_field_t color_field;
    color_field.rh = (0xFF000000 & hex_number) >> 24;
    color_field.gs = (0xFF0000 & hex_number) >> 16;
    color_field.bl = (0xFF00 & hex_number) >> 8;
    color_field.aa = 0xFF & hex_number;
//#ifdef __IPHONE_10_0
//    return [UIColor colorWithDisplayP3Red:color_field.rh / 255.f green:color_field.gs / 255.f blue:color_field.bl / 255.f alpha:color_field.aa / 255.f];
//#else
    return [UIColor colorWithRed:color_field.rh / 255.f green:color_field.gs / 255.f blue:color_field.bl / 255.f alpha:color_field.aa / 255.f];
//#endif
}
extern inline UIColor *UIColorHSL(unsigned int hex_number)
{
    return UIColorHSLA((hex_number << 8) | 0xFF);
}
extern inline UIColor *UIColorHSLA(unsigned int hex_number)
{
    struct color_field_t color_field;
    color_field.rh = (0xFF000000 & hex_number) >> 24;
    color_field.gs = (0xFF0000 & hex_number) >> 16;
    color_field.bl = (0xFF00 & hex_number) >> 8;
    color_field.aa = 0xFF & hex_number;
    return [UIColor colorWithHue:color_field.rh / 255.f saturation:color_field.gs / 255.f brightness:color_field.bl / 255.f alpha:color_field.aa / 255.f];
}


@implementation UIColor (Ext)
@end
