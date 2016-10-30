//
//  LMTriangleView.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/30/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import "LMTriangleView.h"

@implementation LMTriangleView

- (void)layoutSubviews {
	[super layoutSubviews];
	
	if(self.bounds.size.height == 0){
		return;
	}
	else{
		// Build a triangular path
		UIBezierPath *path = [UIBezierPath new];
		[path moveToPoint:(CGPoint){0, 0}];
		[path addLineToPoint:(CGPoint){self.bounds.size.width/2, self.bounds.size.height}];
		[path addLineToPoint:(CGPoint){self.bounds.size.width, 0}];
		//	[path addLineToPoint:(CGPoint){0, 0}];
		[path closePath];
		
		// Create a CAShapeLayer with this triangular path
		// Same size as the original imageView
		CAShapeLayer *mask = [CAShapeLayer new];
		mask.frame = self.bounds;
		mask.path = path.CGPath;
		
		// Mask the imageView's layer with this shape
		self.layer.mask = mask;
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
