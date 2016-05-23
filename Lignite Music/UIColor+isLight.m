#import "UIColor+isLight.h"

@implementation UIColor (isLight)

- (BOOL)isLight
{
    return [self lightness] >= .7;
}

- (CGFloat)lightness
{
    CGFloat hue, saturation, brightness, alpha;
    [self getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];
    CGFloat lightness = (2 - saturation) * brightness / 2;

    return lightness;
}

- (BOOL)isPerceivedLight
{
    return [self perceivedLightness] >= .5;
}

- (CGFloat)perceivedLightness
{
    CGFloat red, green, blue, alpha;
    [self getRed:&red green:&green blue:&blue alpha:&alpha];
    CGFloat lightness = 0.2126 * red + 0.7152 * green + 0.0722 * blue;

    return lightness;
}

- (BOOL)isPerceivedLightW3C
{
    return [self perceivedLightnessW3C] >= .5;
}

- (CGFloat)perceivedLightnessW3C
{
    CGFloat red, green, blue, alpha;
    [self getRed:&red green:&green blue:&blue alpha:&alpha];
    CGFloat lightness = 0.299 * red + 0.587 * green + 0.114 * blue;

    return lightness;
}

@end
