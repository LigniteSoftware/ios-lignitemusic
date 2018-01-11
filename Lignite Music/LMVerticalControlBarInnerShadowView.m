//
//  LMVerticalControlBarInnerShadowView.m
//  Lignite Music
//
//  Created by Edwin Finch on 6/10/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>

#import "LMVerticalControlBarInnerShadowView.h"
#import "LMTriangleInnerShadowView.h"
#import "LMTriangleView.h"
#import "LMColour.h"

@interface LMVerticalControlBarInnerShadowView()

@property LMTriangleView *triangleView;
@property LMTriangleInnerShadowView *triangleInnerShadowView;

@end

@implementation LMVerticalControlBarInnerShadowView

- (void)layoutSubviews {
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;
		
		self.backgroundColor = [UIColor clearColor];
				
		self.triangleView = [LMTriangleView newAutoLayoutView];
		self.triangleView.maskDirection = LMTriangleMaskDirectionUpwards;
		self.triangleView.triangleColour = [LMColour verticalControlBarGreyColour];
		[self addSubview:self.triangleView];
		
		CGFloat triangleHeight = 20.0f;
		CGFloat halfTriangleWidth = (triangleHeight);
		
		[self.triangleView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self withOffset:1];
		[self.triangleView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self withOffset:(self.frame.size.width/2) - halfTriangleWidth];
		[self.triangleView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.triangleView withMultiplier:2.0];
		[self.triangleView autoSetDimension:ALDimensionHeight toSize:triangleHeight];

		self.triangleInnerShadowView = [LMTriangleInnerShadowView newAutoLayoutView];
		self.triangleInnerShadowView.backgroundColor = [UIColor clearColor];
		//		self.triangleInnerShadowView.hidden = YES;
		[self addSubview:self.triangleInnerShadowView];
		
		[self.triangleInnerShadowView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.triangleView];
		[self.triangleInnerShadowView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.triangleView];
		[self.triangleInnerShadowView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.triangleView];
		[self.triangleInnerShadowView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.triangleView];
	}
	
	[super layoutSubviews];
}

- (void)drawInnerShadowInContext:(CGContextRef)context
						withPath:(CGPathRef)path
					 shadowColor:(CGColorRef)shadowColor
						  offset:(CGSize)offset
					  blurRadius:(CGFloat)blurRadius {
	
	CGContextSaveGState(context);
	
	CGContextAddPath(context, path);
	CGContextClip(context);
	
	CGColorRef opaqueShadowColor = CGColorCreateCopyWithAlpha(shadowColor, 1.0);
	
	CGContextSetAlpha(context, CGColorGetAlpha(shadowColor));
	CGContextBeginTransparencyLayer(context, NULL);
	CGContextSetShadowWithColor(context, offset, blurRadius, opaqueShadowColor);
	CGContextSetBlendMode(context, kCGBlendModeSourceOut);
	CGContextSetFillColorWithColor(context, opaqueShadowColor);
	CGContextAddPath(context, path);
	CGContextFillPath(context);
	CGContextEndTransparencyLayer(context);
	
	CGContextRestoreGState(context);
	
	CGColorRelease(opaqueShadowColor);
}

- (UIBezierPath*)path {
	UIBezierPath *path = [UIBezierPath new];
	
	CGFloat centerPoint = self.triangleView.frame.origin.x + self.triangleView.frame.size.width/2;
	
	[path moveToPoint:(CGPoint){centerPoint, self.triangleView.frame.origin.y}];
	[path addLineToPoint:(CGPoint){centerPoint + self.triangleView.frame.size.width/2, 0}];
	[path addLineToPoint:(CGPoint){self.frame.size.width, 0}];
	[path addLineToPoint:(CGPoint){self.frame.size.width, self.frame.size.height}];
	[path addLineToPoint:(CGPoint){0, self.frame.size.height}];
	[path addLineToPoint:(CGPoint){0, 0}];
	[path addLineToPoint:(CGPoint){centerPoint - self.triangleView.frame.size.width/2, 0}];
	
	[path closePath];
	
	return path;
}


- (void)drawRect:(CGRect)rect {
	[super drawRect:rect];
	
	[self drawInnerShadowInContext:UIGraphicsGetCurrentContext() withPath:[self path].CGPath shadowColor:[UIColor lightGrayColor].CGColor offset:CGSizeMake(0, 0) blurRadius:10];
}

@end
