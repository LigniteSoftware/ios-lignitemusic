//
//  LMTriangleMaskView.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/30/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMTriangleMaskView.h"

@interface LMTriangleMaskView()

@property BOOL hasSetConstraints;

@end

@implementation LMTriangleMaskView

- (UIBezierPath*)path {
	NSLog(@"Path bounds %@", NSStringFromCGRect(self.frame));
	
	UIBezierPath *path = [UIBezierPath new];
	[path moveToPoint:(CGPoint){0, 0}];
	[path addLineToPoint:(CGPoint){self.frame.size.width/2, self.frame.size.height}];
	[path addLineToPoint:(CGPoint){self.frame.size.width, 0}];
	//	[path addLineToPoint:(CGPoint){0, 0}];
	[path closePath];
	
	return path;
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	self.backgroundColor = [UIColor whiteColor];
	
	NSLog(@"Hey dawg %@", NSStringFromCGRect(self.frame));
	
	if(self.bounds.size.height == 0){
		return;
	}
	else{
		// Build a triangular path
		UIBezierPath *path = [self path];
		
		// Create a CAShapeLayer with this triangular path
		// Same size as the original imageView
		CAShapeLayer *mask = [CAShapeLayer new];
		mask.frame = self.bounds;
		mask.path = path.CGPath;
		
		// Mask the imageView's layer with this shape
		self.layer.mask = mask;
	}
}

- (void)setup {
	if(!self.hasSetConstraints){
		[self autoCenterInSuperview];
		[self autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.superview];
		[self autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.superview];
		
		self.hasSetConstraints = YES;
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
