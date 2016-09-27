//
//  LMLabel.m
//  Lignite Music
//
//  Created by Edwin Finch on 9/27/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import "LMLabel.h"

#define DISPLAY_FONT_MINIMUM 6
#define DISPLAY_FONT_MAXIMUM 50

@interface LMLabel ()

@end

@implementation LMLabel

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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
