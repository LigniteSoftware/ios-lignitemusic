//
//  LMColour.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/8/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMColour.h"

@implementation LMColour

+ (UIColor*)ligniteRedColour {
//	return [UIColor colorWithRed:0.33 green:0.33 blue:0.33 alpha:1.0];
//	return [UIColor colorWithRed:1.00 green:0.33 blue:0.00 alpha:1.0];
	return [UIColor colorWithRed:0.69 green:0.16 blue:0.15 alpha:1.0];
}

+ (UIColor*)semiTransparentLigniteRedColour {
//	return [UIColor colorWithRed:0.69 green:0.16 blue:0.15 alpha:0.75];
	
	return [LMColour ligniteRedColour]; //Temporary fix because Philipp wants to try it
}

+ (UIColor*)darkLigniteRedColour {
	return [UIColor colorWithRed:0.33 green:0.00 blue:0.00 alpha:1.0];
}

+ (UIColor*)superLightGrayColour {
	return [UIColor colorWithRed:0.97 green:0.97 blue:0.97 alpha:1.0];
}

+ (UIColor*)controlBarGrayColour {
	return [UIColor colorWithRed:0.93 green:0.93 blue:0.93 alpha:1.0];
}

+ (UIColor*)fadedColour {
	return [UIColor colorWithRed:1.00 green: 1.00 blue: 1.00 alpha: 0.35];
}

+ (UIColor*)lightGrayBackgroundColour {
	return [UIColor colorWithRed:0.82 green:0.82 blue:0.82 alpha:1.0];
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
