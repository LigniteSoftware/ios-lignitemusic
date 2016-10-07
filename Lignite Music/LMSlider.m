//
//  LMSlider.m
//  Lignite Music
//
//  Created by Edwin Finch on 5/16/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import "LMSlider.h"

@implementation LMSlider

- (CGRect)trackRectForBounds:(CGRect)bounds {
    int barHeight = bounds.size.height/8;
	
    CGRect trackRect = CGRectMake(0, bounds.size.height/2 - barHeight/2, bounds.size.width, barHeight);
    
    return trackRect;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
