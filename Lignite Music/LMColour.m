//
//  LMColour.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/8/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMColour.h"

#define LIGNITE_RED [UIColor colorWithRed:0.69 green:0.16 blue:0.15 alpha:1.0]
#define FADED_COLOUR [UIColor colorWithRed:1.00 green: 1.00 blue: 1.00 alpha: 0.35]

@implementation LMColour

+ (UIColor*)ligniteRedColour {
	return LIGNITE_RED;
}

+ (UIColor*)fadedColour {
	return FADED_COLOUR;
}

+ (UIColor*)lightGrayBackgroundColour {
	return [UIColor colorWithRed:0.82 green:0.82 blue:0.82 alpha:1.0];
}

@end
