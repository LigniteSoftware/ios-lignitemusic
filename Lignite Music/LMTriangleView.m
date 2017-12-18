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

- (instancetype)init {
	self = [super init];
	if(self) {
		self.triangleColour = [UIColor whiteColor];
//		self.outerShadows = YES;
	}
	return self;
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	if(!self.triangleColour){
		self.triangleColour = [UIColor whiteColor];
	}
	
	self.backgroundColor = [UIColor clearColor];
	
//	if(!self.outerShadows){
//		self.backgroundColor = self.triangleColour;
//	}
	
	if(self.bounds.size.height == 0){
		return;
	}
	else{
		if(!self.triangleContainerView){
			self.triangleContainerView = [LMTriangleContainerView newAutoLayoutView];
            self.triangleContainerView.maskDirection = self.maskDirection;
			self.triangleContainerView.triangleColour = self.triangleColour;
//			self.triangleContainerView.outerShadows = self.outerShadows;
			
			[self addSubview:self.triangleContainerView];
			
			[self.triangleContainerView autoCentreInSuperview];
			[self.triangleContainerView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self];
			[self.triangleContainerView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self];
		}
		
	}
}

//- (void)drawInnerShadowInContext:(CGContextRef)context
//						withPath:(CGPathRef)path
//					 shadowColor:(CGColorRef)shadowColor
//						  offset:(CGSize)offset
//					  blurRadius:(CGFloat)blurRadius {
//	
//	CGContextSaveGState(context);
//	
//	CGContextAddPath(context, path);
//	CGContextClip(context);
//	
//	CGColorRef opaqueShadowColor = CGColorCreateCopyWithAlpha(shadowColor, 1.0);
//	
//	CGContextSetAlpha(context, CGColorGetAlpha(shadowColor));
//	CGContextBeginTransparencyLayer(context, NULL);
//	CGContextSetShadowWithColor(context, offset, blurRadius, opaqueShadowColor);
//	CGContextSetBlendMode(context, kCGBlendModeSourceOut);
//	CGContextSetFillColorWithColor(context, opaqueShadowColor);
//	CGContextAddPath(context, path);
//	CGContextFillPath(context);
//	CGContextEndTransparencyLayer(context);
//	
//	CGContextRestoreGState(context);
//	
//	CGColorRelease(opaqueShadowColor);
//}
//
//- (UIBezierPath*)path {
//	UIBezierPath *path = [UIBezierPath new];
//
//	[path moveToPoint:(CGPoint){ self.frame.size.width/2, 0 }];
//	[path addLineToPoint:(CGPoint){ self.frame.size.width, self.frame.size.height }];
//	[path addLineToPoint:(CGPoint){ self.superview.frame.size.width/2, self.frame.size.height + 10 }];
//	[path addLineToPoint:(CGPoint){ -self.superview.frame.size.width/2, self.frame.size.height + 10 }];
//	[path addLineToPoint:(CGPoint){ 0, self.frame.size.height }];
//	
//	[path closePath];
//	
//	return path;
//}
//
//- (void)drawRect:(CGRect)rect {
//	[super drawRect:rect];
//	
//	NSLog(@"%@", NSStringFromCGRect(self.frame));
//	
//	if(!self.outerShadows){
//		[self drawInnerShadowInContext:UIGraphicsGetCurrentContext() withPath:[self path].CGPath shadowColor:[UIColor lightGrayColor].CGColor offset:CGSizeMake(0, 0) blurRadius:10];
//	}
//}

@end
