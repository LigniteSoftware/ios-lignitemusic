#import <UIKit/UIKit.h>

@interface UIColor (isLight)

- (CGFloat)lightness;
- (CGFloat)perceivedLightness;
- (CGFloat)perceivedLightnessW3C;
- (BOOL)isLight;
- (BOOL)isPerceivedLightW3C;
- (BOOL)isPerceivedLight;

@end