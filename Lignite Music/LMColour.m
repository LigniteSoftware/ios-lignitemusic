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

+ (LMColour*)colourWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha {
	return (LMColour*)[UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

+ (UIColor*)mainColour {
	return [LMThemeEngine mainColour];
}

+ (UIColor*)successGreenColour {
	return [UIColor colorWithRed:33/255.0 green:175/255.0 blue:67/255.0 alpha:1.0];
}

+ (UIColor*)semiTransparentLigniteRedColour {
//	return [UIColor colorWithRed:0.69 green:0.16 blue:0.15 alpha:0.75];
	
	return [LMColour mainColour]; //Temporary fix because Philipp wants to try it
}

+ (UIColor*)darkLigniteRedColour {
	return [UIColor colorWithRed:0.33 green:0.00 blue:0.00 alpha:1.0];
}

+ (UIColor*)superLightGrayColour {
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
