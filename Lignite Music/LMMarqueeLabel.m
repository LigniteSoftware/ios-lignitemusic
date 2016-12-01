//
//  LMMarqueeLabel.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/6/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import "LMMarqueeLabel.h"

#define DISPLAY_FONT_MINIMUM 6
#define DISPLAY_FONT_MAXIMUM 50

@implementation LMMarqueeLabel

- (UIFont*)fontToFitHeight {
	float minimumFontSize = DISPLAY_FONT_MINIMUM;
	float maximumFontSize = DISPLAY_FONT_MAXIMUM;
	float fontSizeAverage = 0;
	float textAndLabelHeightDifference = 0;
	
	while(minimumFontSize <= maximumFontSize){
		fontSizeAverage = minimumFontSize + (maximumFontSize - minimumFontSize) / 2;
		if(self.text){
			float labelHeight = self.frame.size.height;
			float testStringHeight = [self.text sizeWithAttributes:@{
																	 NSFontAttributeName: [self.font fontWithSize:fontSizeAverage]
																	 }].height;
			
			textAndLabelHeightDifference = labelHeight - testStringHeight;
			
			if(fontSizeAverage == minimumFontSize || fontSizeAverage == maximumFontSize){
				return [self.font fontWithSize:fontSizeAverage- (textAndLabelHeightDifference < 0)];
			}
			if(textAndLabelHeightDifference < 0){
				maximumFontSize = fontSizeAverage - 1;
			}
			else if(textAndLabelHeightDifference > 0){
				minimumFontSize = fontSizeAverage + 1;
			}
			else{
				return [self.font fontWithSize:fontSizeAverage];
			}
		}
	}
	return [self.font fontWithSize:fontSizeAverage-2];
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	self.font = [self fontToFitHeight];
}

@end
