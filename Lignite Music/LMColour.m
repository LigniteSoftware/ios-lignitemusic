//
//  LMColour.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/8/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMColour.h"
#import "LMThemeEngine.h"

@implementation LMColour

+ (UIColor*)colour:(UIColor*)colour brightnessLevel:(CGFloat)amount {
	
	CGFloat hue, saturation, brightness, alpha;
	if ([colour getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha]) {
		brightness += (amount - 1.0);
		brightness = MAX(MIN(brightness, 1.0), 0.0);
		return [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:alpha];
	}
	
	CGFloat white;
	if ([colour getWhite:&white alpha:&alpha]) {
		white += (amount - 1.0);
		white = MAX(MIN(white, 1.0), 0.0);
		return [UIColor colorWithWhite:white alpha:alpha];
	}
	
	return nil;
}

+ (LMColour*)colourWithHexString:(NSString*)hexString {
	NSString *colourString = [[hexString stringByReplacingOccurrencesOfString:@"#" withString:@""] uppercaseString];
	
	CGFloat alpha, red, blue, green;
	
	switch([colourString length]){
		case 3: //#RGB
			alpha = 1.0f;
			red   = [self colourComponentFrom:colourString start:0 length:1];
			green = [self colourComponentFrom:colourString start:1 length:1];
			blue  = [self colourComponentFrom:colourString start:2 length:1];
			break;
		case 4: //#ARGB
			alpha = [self colourComponentFrom:colourString start:0 length:1];
			red   = [self colourComponentFrom:colourString start:1 length:1];
			green = [self colourComponentFrom:colourString start:2 length:1];
			blue  = [self colourComponentFrom:colourString start:3 length:1];
			break;
		case 6: //#RRGGBB
			alpha = 1.0f;
			red   = [self colourComponentFrom:colourString start:0 length:2];
			green = [self colourComponentFrom:colourString start:2 length:2];
			blue  = [self colourComponentFrom:colourString start:4 length:2];
			break;
		case 8: //#AARRGGBB
			alpha = [self colourComponentFrom:colourString start:0 length:2];
			red   = [self colourComponentFrom:colourString start:2 length:2];
			green = [self colourComponentFrom:colourString start:4 length:2];
			blue  = [self colourComponentFrom:colourString start:6 length:2];
			break;
		default:
			[NSException raise:@"Invalid color value" format:@"Color value %@ is invalid. It should be a hex value of the form #RBG, #ARGB, #RRGGBB, or #AARRGGBB", hexString];
			break;
	}
	
	return (LMColour*)[UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

+ (CGFloat)colourComponentFrom:(NSString *)string start:(NSUInteger)start length:(NSUInteger)length {
	NSString *substring = [string substringWithRange: NSMakeRange(start, length)];
	
	NSString *fullHex = (length == 2) ? substring : [NSString stringWithFormat:@"%@%@", substring, substring];
	unsigned hexComponent;
	[[NSScanner scannerWithString: fullHex] scanHexInt: &hexComponent];
	
	return hexComponent / 255.0;
}

+ (LMColour*)colourWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha {
	return (LMColour*)[UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

+ (LMColour*)whiteColour {
	return (LMColour*)[UIColor whiteColor];
}

+ (LMColour*)blackColour {
	return (LMColour*)[UIColor blackColor];
}

+ (LMColour*)clearColour {
	return (LMColour*)[UIColor clearColor];
}

+ (UIColor*)mainColour {
	return [LMThemeEngine mainColour];
}

+ (UIColor*)mainColourDark {
	return [LMColour colour:[LMThemeEngine mainColour] brightnessLevel:0.7];
}

+ (UIColor*)successGreenColour {
	return [UIColor colorWithRed:33/255.0 green:175/255.0 blue:67/255.0 alpha:1.0];
}

+ (UIColor*)superLightGreyColour {
	return [UIColor colorWithRed:0.96 green:0.96 blue:0.96 alpha:1.0];
}

+ (UIColor*)controlBarGrayColour {
	return [UIColor colorWithRed:0.90 green:0.90 blue:0.90 alpha:1.0];;
}

+ (UIColor*)verticalControlBarGrayColour {
	return [LMColour lightGrayBackgroundColour];
}

+ (UIColor*)fadedColour {
	return [UIColor colorWithRed:1.00 green: 1.00 blue: 1.00 alpha: 0.35];
}

+ (UIColor*)lightGrayBackgroundColour {
	return [UIColor colorWithRed:0.79 green:0.79 blue:0.79 alpha:1.0];
}

+ (UIColor*)darkGrayColour {
	return [UIColor colorWithRed:0.33 green:0.33 blue:0.33 alpha:1.0];
}

+ (UIColor*)superDarkGrayColour {
	return [UIColor colorWithRed:0.25 green:0.25 blue:0.25 alpha:1.0];
}

+ (UIColor*)randomColour {
	return [UIColor colorWithRed:(0.1)*(arc4random_uniform(9)+1) green:(0.1)*(arc4random_uniform(9)+1) blue:(0.1)*(arc4random_uniform(9)+1) alpha:1.0];
}

@end
