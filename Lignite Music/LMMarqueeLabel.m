//
//  LMMarqueeLabel.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/6/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import "LMMarqueeLabel.h"

#define DISPLAY_FONT_MINIMUM 6
#define DISPLAY_FONT_MAXIMUM 100

@implementation LMMarqueeLabel

+ (UIFont*)fontToFitHeight:(CGFloat)height {
	CGFloat adjustment = 1.0;
	
	UIFont *tempFont = nil;
	NSString *testString = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
	
	NSInteger tempMin = 6;
	NSInteger tempMax = 256;
	NSInteger mid = 0;
	NSInteger difference = 0;
	
	NSString *fontName = @"HelveticaNeue-Light";
	
	while (tempMin <= tempMax) {
		mid = tempMin + (tempMax - tempMin) / 2;
		tempFont = [UIFont fontWithName:fontName size:mid];
		difference = height - [testString sizeWithAttributes:@{
																	 NSFontAttributeName:tempFont
																	 }].height;
		
		if (mid == tempMin || mid == tempMax) {
			if (difference < 0) {
				return [UIFont fontWithName:fontName size:(mid - 1)*adjustment];
			}
			
			return [UIFont fontWithName:fontName size:mid*adjustment];
		}
		
		if (difference < 0) {
			tempMax = mid - 1;
		} else if (difference > 0) {
			tempMin = mid + 1;
		} else {
			return [UIFont fontWithName:fontName size:mid*adjustment];
		}
	}
	
	return [UIFont fontWithName:fontName size:mid*adjustment];
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	self.font = [LMMarqueeLabel fontToFitHeight:self.frame.size.height];
}

@end
