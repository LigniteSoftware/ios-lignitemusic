//
//  LMTriangleView.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/30/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMTriangleView.h"
#import "LMTriangleContainerView.h"

@interface LMTriangleView()

@property LMTriangleContainerView *triangleContainerView;

@end

@implementation LMTriangleView

- (void)layoutSubviews {
	[super layoutSubviews];
	
	self.backgroundColor = [UIColor clearColor];
	
	if(self.bounds.size.height == 0){
		return;
	}
	else{
		if(!self.triangleContainerView){
			self.triangleContainerView = [LMTriangleContainerView newAutoLayoutView];
            self.triangleContainerView.upwards = self.pointingUpwards;
			
			[self addSubview:self.triangleContainerView];
			
			[self.triangleContainerView autoCenterInSuperview];
			[self.triangleContainerView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self];
			[self.triangleContainerView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self];
		}
		
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
