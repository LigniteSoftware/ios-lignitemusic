//
//  LMTriangleContainerView.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/30/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMTriangleContainerView.h"

@interface LMTriangleContainerView()

@property LMTriangleMaskView *triangleMaskView;

@end

@implementation LMTriangleContainerView

- (void)layoutSubviews {
	[super layoutSubviews];
	
	if(!self.triangleMaskView){
		self.backgroundColor = [UIColor clearColor];
		
		self.triangleMaskView = [LMTriangleMaskView newAutoLayoutView];
        self.triangleMaskView.maskDirection = self.maskDirection;
		self.triangleMaskView.triangleColour = self.triangleColour;
		self.triangleMaskView.frame = self.frame;
		
	
		// make new layer to contain shadow and masked image
		CALayer* containerLayer = [CALayer layer];
//		if(self.outerShadows){
//			containerLayer.shadowColor = [UIColor blackColor].CGColor;
//			containerLayer.shadowRadius = self.frame.size.height/8;
//			containerLayer.shadowOffset = CGSizeMake(0.0f, 0.0f);
//			containerLayer.shadowOpacity = 0.25f;
//			containerLayer.shadowPath = [self.triangleMaskView path].CGPath;
//		}
		containerLayer.backgroundColor = [UIColor clearColor].CGColor;
		
		// add masked image layer into container layer so that it's shadowed
		[containerLayer addSublayer:self.triangleMaskView.layer];
		containerLayer.frame = self.frame;
		
		[self.layer addSublayer:containerLayer];
	}
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
