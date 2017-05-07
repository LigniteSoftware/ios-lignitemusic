//
//  LMExpandableInnerShadowView.m
//  Lignite Music
//
//  Created by Edwin Finch on 5/7/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>

#import "LMExpandableInnerShadowView.h"
#import "LMTriangleInnerShadowView.h"
#import "LMTriangleView.h"
#import "LMColour.h"

@interface LMExpandableInnerShadowView()

@property LMTriangleView *testView;
@property LMTriangleInnerShadowView *triangleInnerShadowView;

@end

@implementation LMExpandableInnerShadowView

- (void)layoutSubviews {
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;
		
		self.testView = [LMTriangleView newAutoLayoutView];
		self.testView.maskDirection = LMTriangleMaskDirectionUpwards;
		self.testView.triangleColour = [LMColour superLightGrayColour];
		[self addSubview:self.testView];
		
		CGFloat triangleWidthFactorial = 0.15;
		CGFloat halfTriangleWidth = (self.frame.size.width*triangleWidthFactorial)/2;
		
		CGFloat widthPerItem = self.frame.size.width/self.flowLayout.itemsPerRow;
		CGFloat column = self.flowLayout.indexOfItemDisplayingDetailView % self.flowLayout.itemsPerRow;
		
		[self.testView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self withOffset:0];
		[self.testView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self withOffset:(column * widthPerItem) + halfTriangleWidth + 15];
		[self.testView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:triangleWidthFactorial];
		[self.testView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:0.05];
		
		self.triangleInnerShadowView = [LMTriangleInnerShadowView newAutoLayoutView];
		self.triangleInnerShadowView.backgroundColor = [UIColor clearColor];
		[self addSubview:self.triangleInnerShadowView];
		
		[self.triangleInnerShadowView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.testView];
		[self.triangleInnerShadowView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.testView];
		[self.triangleInnerShadowView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.testView];
		[self.triangleInnerShadowView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.testView];
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
	
	CGFloat centerPoint = self.testView.frame.origin.x + self.testView.frame.size.width/2;
	
	[path moveToPoint:(CGPoint){centerPoint, self.testView.frame.origin.y}];
	[path addLineToPoint:(CGPoint){centerPoint + self.testView.frame.size.width/2, 0}];
	[path addLineToPoint:(CGPoint){self.frame.size.width + 10, 0}];
	[path addLineToPoint:(CGPoint){self.frame.size.width + 10, self.frame.size.height}];
	[path addLineToPoint:(CGPoint){-10, self.frame.size.height}];
	[path addLineToPoint:(CGPoint){-10, 0}];
	[path addLineToPoint:(CGPoint){centerPoint - self.testView.frame.size.width/2, 0}];

	[path closePath];
	
	return path;
}


- (void)drawRect:(CGRect)rect {
	[super drawRect:rect];
	
	NSLog(@"test frame %@", NSStringFromCGRect(self.testView.frame));
	
	
	[self drawInnerShadowInContext:UIGraphicsGetCurrentContext() withPath:[self path].CGPath shadowColor:[UIColor lightGrayColor].CGColor offset:CGSizeMake(0, 0) blurRadius:10];
}

@end
