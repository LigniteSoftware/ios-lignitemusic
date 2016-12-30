//
//  LMGrabberView.m
//  Lignite Music
//
//  Created by Edwin Finch on 12/13/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMGrabberView.h"
#import "LMExtras.h"
#import "LMAppIcon.h"

@interface LMGrabberView()

@property UIImageView *grabberImageView;

@end

@implementation LMGrabberView

- (void)layoutSubviews {
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;
		
		if(!self.grabberIcon){
			self.grabberIcon = [LMAppIcon imageForIcon:LMIconGrabRectangle];
		}
		
		CGFloat cornerRadius = 0.024*WINDOW_FRAME.size.width;
		
		// Create the path (with only the top-left corner rounded)
		UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds
													   byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight
															 cornerRadii:CGSizeMake(cornerRadius, cornerRadius)];
		
		// Create the shape layer and set its path
		CAShapeLayer *maskLayer = [CAShapeLayer layer];
		maskLayer.frame = self.bounds;
		maskLayer.path = maskPath.CGPath;
		
		// Set the newly created shape layer as the mask for the image view's layer
		self.layer.mask = maskLayer;
		
		self.grabberImageView = [UIImageView newAutoLayoutView];
		self.grabberImageView.image = self.grabberIcon;
		self.grabberImageView.contentMode = UIViewContentModeScaleAspectFit;
		self.grabberImageView.userInteractionEnabled = YES;
		[self addSubview:self.grabberImageView];
		
		[self.grabberImageView autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.grabberImageView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[self.grabberImageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:(1.0/2.0)];
		[self.grabberImageView autoAlignAxisToSuperviewAxis:ALAxisVertical];
	}
	
	[super layoutSubviews];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
